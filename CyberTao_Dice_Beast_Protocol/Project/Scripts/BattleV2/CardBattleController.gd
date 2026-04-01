extends Node
class_name CardBattleController

## 卡牌战斗状态机（v0.1.79：卡牌战斗层深化）
## 能量系统 + 双牌堆抽牌 + 5 种敌方行为模式 + 敌方意图预告
## 持久牌组 + 战斗胜利选牌构筑
## 新增：毒素/抽牌/反击/连击 4种卡牌 + buff/multi_attack 2种敌方行为 + 2个新遭遇

signal battle_started(player_hp: int, enemy_hp: int, enemy_name: String)
signal hand_changed(hand: Array, energy: int, max_energy: int)
signal card_played(card_index: int, card_name: String, effect_text: String)
signal enemy_acted(action_text: String)
signal enemy_intent_changed(intent_text: String)
signal turn_resolved(player_hp: int, enemy_hp: int, battle_turn: int)
signal battle_ended(victory: bool, player_hp_remaining: int)
signal victory_reward(reward_text: String)
signal reward_cards_offered(options: Array)
signal reward_card_selected(card: Dictionary)
signal card_upgrade_completed(old_card: Dictionary, new_card: Dictionary)
signal energy_grown(old_max: int, new_max: int)

enum BattleState { IDLE, PLAYER_TURN, ENEMY_TURN, VICTORY, DEFEAT, REWARD_SELECT }

# --- 战斗核心状态 ---
var state: BattleState = BattleState.IDLE
var player_hp: int = 0
var player_max_hp: int = 0
var enemy_hp: int = 0
var enemy_max_hp: int = 0
var enemy_atk: int = 2
var enemy_name: String = ""
var encounter_id: String = ""
var battle_turn: int = 0
var def_bonus: int = 0

# --- 能量系统 ---
var energy: int = 0
var max_energy: int = 3
const INITIAL_MAX_ENERGY: int = 3
const MAX_ENERGY_CAP: int = 5

# --- 牌组系统（参考旧 Deck.gd 双牌堆） ---
var draw_pile: Array[Dictionary] = []
var discard_pile: Array[Dictionary] = []
var hand: Array[Dictionary] = []
const HAND_DRAW_COUNT: int = 3
const HAND_MAX: int = 6

# --- 敌方行为系统 ---
var _enemy_pattern: Array[String] = []
var _enemy_pattern_index: int = 0
var _enemy_def_bonus: int = 0
var _next_enemy_intent: String = ""

# --- 状态效果 ---
var _poison_turns: int = 0		# 敌方中毒剩余回合
var _poison_dmg: int = 2		# 每回合毒素伤害
var _counter_dmg: int = 0		# 反击伤害（下次敌方攻击时触发）

# --- 持久牌组（跨战斗保留） ---
var persistent_deck: Array[Dictionary] = []
var _deck_initialized: bool = false

# --- 奖励选牌 ---
var _reward_options: Array[Dictionary] = []
const REWARD_CHOICES: int = 3

# ======== 牌库定义 ========

static func _build_deck() -> Array[Dictionary]:
	var deck: Array[Dictionary] = []
	# 斩击 x2 (cost 1, 3 伤害)
	deck.append({"name": "斩击", "type": "attack", "cost": 1, "value": 3, "upgraded": false})
	deck.append({"name": "斩击", "type": "attack", "cost": 1, "value": 3, "upgraded": false})
	# 重击 x1 (cost 2, 5 伤害)
	deck.append({"name": "重击", "type": "attack", "cost": 2, "value": 5, "upgraded": false})
	# 防御 x2 (cost 1, 减伤 2)
	deck.append({"name": "防御", "type": "defend", "cost": 1, "value": 2, "upgraded": false})
	deck.append({"name": "防御", "type": "defend", "cost": 1, "value": 2, "upgraded": false})
	# 修复 x1 (cost 1, 回复 2)
	deck.append({"name": "修复", "type": "heal", "cost": 1, "value": 2, "upgraded": false})
	# 连斩 x2 (cost 1, 2 伤害)
	deck.append({"name": "连斩", "type": "attack", "cost": 1, "value": 2, "upgraded": false})
	deck.append({"name": "连斩", "type": "attack", "cost": 1, "value": 2, "upgraded": false})
	# 猛攻 x1 (cost 3, 8 伤害)
	deck.append({"name": "猛攻", "type": "attack", "cost": 3, "value": 8, "upgraded": false})
	# 急救 x1 (cost 2, 回复 4)
	deck.append({"name": "急救", "type": "heal", "cost": 2, "value": 4, "upgraded": false})
	return deck

# ======== 奖励卡池（不在初始牌组中的可获得卡牌） ========

static func _build_reward_pool() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	# 穿刺 (cost 2, 4 伤害，无视敌方防御)
	pool.append({"name": "穿刺", "type": "pierce", "cost": 2, "value": 4, "upgraded": false})
	# 铁壁 (cost 2, 防御 4)
	pool.append({"name": "铁壁", "type": "defend", "cost": 2, "value": 4, "upgraded": false})
	# 吸血斩 (cost 2, 3 伤害 + 回复 1)
	pool.append({"name": "吸血斩", "type": "lifesteal", "cost": 2, "value": 3, "heal_value": 1, "upgraded": false})
	# 超频修复 (cost 3, 回复 6)
	pool.append({"name": "超频修复", "type": "heal", "cost": 3, "value": 6, "upgraded": false})
	# 电弧 (cost 1, 2 伤害 + 下回合敌方 ATK-1)
	pool.append({"name": "电弧", "type": "shock", "cost": 1, "value": 2, "upgraded": false})
	# 强化斩击 (cost 1, 4 伤害)
	pool.append({"name": "强化斩击", "type": "attack", "cost": 1, "value": 4, "upgraded": false})
	# 双重防御 (cost 1, 防御 3)
	pool.append({"name": "双重防御", "type": "defend", "cost": 1, "value": 3, "upgraded": false})
	# 毒素注入 (cost 1, 施加毒素 3 回合)
	pool.append({"name": "毒素注入", "type": "poison", "cost": 1, "value": 3, "upgraded": false})
	# 能量虹吸 (cost 0, 抽 2 张牌)
	pool.append({"name": "能量虹吸", "type": "draw", "cost": 0, "value": 2, "upgraded": false})
	# 反击 (cost 1, 防御 2 + 反击 3)
	pool.append({"name": "反击", "type": "counter", "cost": 1, "value": 3, "def_value": 2, "upgraded": false})
	# 裂空斩 (cost 2, 3 连击各 2 伤害)
	pool.append({"name": "裂空斩", "type": "combo", "cost": 2, "value": 2, "hits": 3, "upgraded": false})
	# 初始牌组中的牌也可以作为奖励出现
	pool.append({"name": "斩击", "type": "attack", "cost": 1, "value": 3, "upgraded": false})
	pool.append({"name": "重击", "type": "attack", "cost": 2, "value": 5, "upgraded": false})
	pool.append({"name": "防御", "type": "defend", "cost": 1, "value": 2, "upgraded": false})
	pool.append({"name": "修复", "type": "heal", "cost": 1, "value": 2, "upgraded": false})
	pool.append({"name": "猛攻", "type": "attack", "cost": 3, "value": 8, "upgraded": false})
	pool.append({"name": "急救", "type": "heal", "cost": 2, "value": 4, "upgraded": false})
	return pool

# ======== 遭遇敌方数据 ========

static func get_encounter_enemy_data(enc_id: String, current_floor: int = 1) -> Dictionary:
	var base: Dictionary = {}
	match enc_id:
		"encounter_01":
			base = {
				"name": "异常哨兵", "hp": 8, "atk": 2,
				"pattern": ["attack", "attack", "defend_attack", "heavy_attack"],
			}
		"encounter_02":
			base = {
				"name": "赛博游魂", "hp": 6, "atk": 3,
				"pattern": ["attack", "heavy_attack", "attack"],
			}
		"encounter_03":
			base = {
				"name": "暗网爬虫", "hp": 12, "atk": 1,
				"pattern": ["defend_attack", "defend_attack", "heavy_attack", "attack"],
			}
		"encounter_04":
			base = {
				"name": "脉冲猎手", "hp": 5, "atk": 4,
				"pattern": ["heavy_attack", "attack", "attack"],
			}
		"encounter_05":
			base = {
				"name": "数据幽灵", "hp": 9, "atk": 2,
				"pattern": ["attack", "defend_attack", "heavy_attack", "heavy_attack", "attack"],
			}
		"encounter_06":
			base = {
				"name": "量子分裂体", "hp": 7, "atk": 2,
				"pattern": ["attack", "buff", "multi_attack", "attack", "heavy_attack"],
			}
		"encounter_07":
			base = {
				"name": "赛博巫医", "hp": 11, "atk": 2,
				"pattern": ["buff", "defend_attack", "heal", "heavy_attack", "attack"],
			}
		"encounter_boss_01":
			base = {
				"name": "零号协议", "hp": 20, "atk": 3, "is_boss": true,
				"pattern": ["attack", "defend_attack", "heavy_attack", "heal", "attack", "mega_attack"],
			}
		_:
			base = {
				"name": "未知敌人", "hp": 5, "atk": 2,
				"pattern": ["attack", "attack"],
			}
	# 层间难度缩放：第1层=基准，第2层 HP+30%/ATK+1，第3层 HP+60%/ATK+2
	var floor_offset: int = max(0, current_floor - 1)
	if floor_offset > 0:
		base["hp"] = int(ceil(float(int(base["hp"])) * (1.0 + 0.3 * float(floor_offset))))
		base["atk"] = int(base["atk"]) + floor_offset
	return base

# ======== 战斗流程 ========

func start_battle(enc_id: String, p_hp: int, p_max_hp: int, current_floor: int = 1) -> void:
	encounter_id = enc_id
	var enemy_data: Dictionary = get_encounter_enemy_data(enc_id, current_floor)
	enemy_name = String(enemy_data["name"])
	enemy_hp = int(enemy_data["hp"])
	enemy_max_hp = enemy_hp
	enemy_atk = int(enemy_data["atk"])
	_enemy_pattern = []
	var raw_pattern: Array = enemy_data.get("pattern", ["attack"])
	for p in raw_pattern:
		_enemy_pattern.append(String(p))
	_enemy_pattern_index = 0
	_enemy_def_bonus = 0
	_poison_turns = 0
	_counter_dmg = 0
	player_hp = p_hp
	player_max_hp = p_max_hp
	def_bonus = 0
	battle_turn = 1
	energy = max_energy
	_reward_options = []
	# 首次战斗时初始化持久牌组，后续战斗复用
	if not _deck_initialized:
		persistent_deck = _build_deck()
		_deck_initialized = true
	# 从持久牌组复制到抽牌堆
	draw_pile = []
	for card in persistent_deck:
		draw_pile.append(card.duplicate())
	_shuffle_pile(draw_pile)
	discard_pile = []
	hand = []
	state = BattleState.PLAYER_TURN
	emit_signal("battle_started", player_hp, enemy_hp, enemy_name)
	_draw_hand()
	_update_enemy_intent()

func _shuffle_pile(pile: Array[Dictionary]) -> void:
	for i in range(pile.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var tmp: Dictionary = pile[i]
		pile[i] = pile[j]
		pile[j] = tmp

func _draw_hand() -> void:
	var to_draw: int = min(HAND_DRAW_COUNT, HAND_MAX - hand.size())
	for _i in range(to_draw):
		if draw_pile.is_empty():
			_reshuffle()
		if draw_pile.is_empty():
			break
		hand.append(draw_pile.pop_back())
	emit_signal("hand_changed", hand, energy, max_energy)

func _reshuffle() -> void:
	for card in discard_pile:
		draw_pile.append(card)
	discard_pile = []
	_shuffle_pile(draw_pile)

func _discard_hand() -> void:
	for card in hand:
		discard_pile.append(card)
	hand = []

# ======== 玩家操作 ========

func play_card(index: int) -> void:
	if state != BattleState.PLAYER_TURN:
		return
	if index < 0 or index >= hand.size():
		return
	var card: Dictionary = hand[index]
	var cost: int = int(card.get("cost", 1))
	if cost > energy:
		return
	energy -= cost
	# 从手牌移除并放入弃牌堆
	hand.remove_at(index)
	discard_pile.append(card)
	var effect_text: String = _resolve_card(card)
	emit_signal("card_played", index, String(card["name"]), effect_text)
	emit_signal("hand_changed", hand, energy, max_energy)
	# 检查敌方是否被击杀
	if enemy_hp <= 0:
		_win()
		return

func end_turn() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	# 弃掉剩余手牌
	_discard_hand()
	# 重置玩家防御
	def_bonus = 0
	# 毒素结算（敌方回合开始前）
	if _poison_turns > 0:
		enemy_hp = max(0, enemy_hp - _poison_dmg)
		_poison_turns -= 1
		var poison_text: String = "毒素发作 → " + str(_poison_dmg) + " 伤害"
		if _poison_turns > 0:
			poison_text += "（剩余 " + str(_poison_turns) + " 回合）"
		else:
			poison_text += "（毒素消散）"
		emit_signal("enemy_acted", poison_text)
		if enemy_hp <= 0:
			_win()
			return
	# 敌方行动
	state = BattleState.ENEMY_TURN
	_enemy_act()
	# 检查玩家是否被击杀
	if player_hp <= 0:
		_lose()
		return
	# 下一回合
	battle_turn += 1
	energy = max_energy
	state = BattleState.PLAYER_TURN
	_draw_hand()
	_advance_enemy_pattern()
	_update_enemy_intent()
	emit_signal("turn_resolved", player_hp, enemy_hp, battle_turn)

func flee() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	state = BattleState.DEFEAT
	player_hp = max(0, player_hp - 1)
	emit_signal("battle_ended", false, player_hp)

# ======== 卡牌效果结算 ========

func _resolve_card(card: Dictionary) -> String:
	var card_type: String = String(card["type"])
	var value: int = int(card["value"])
	var card_name: String = String(card["name"])
	match card_type:
		"attack":
			var actual_dmg: int = max(1, value - _enemy_def_bonus)
			enemy_hp = max(0, enemy_hp - actual_dmg)
			_enemy_def_bonus = 0
			if actual_dmg < value:
				return card_name + " → " + str(actual_dmg) + " 伤害（敌方减免）"
			return card_name + " → " + str(actual_dmg) + " 伤害"
		"pierce":
			# 穿刺：无视敌方防御
			enemy_hp = max(0, enemy_hp - value)
			_enemy_def_bonus = 0
			return card_name + " → " + str(value) + " 穿透伤害"
		"lifesteal":
			# 吸血斩：造成伤害并回复 HP（升级后回复更多）
			var actual_dmg: int = max(1, value - _enemy_def_bonus)
			enemy_hp = max(0, enemy_hp - actual_dmg)
			_enemy_def_bonus = 0
			var heal_val: int = int(card.get("heal_value", 1))
			player_hp = min(player_max_hp, player_hp + heal_val)
			return card_name + " → " + str(actual_dmg) + " 伤害，回复 " + str(heal_val) + " HP"
		"shock":
			# 电弧：造成伤害 + 降低敌方下回合攻击力
			var actual_dmg: int = max(1, value - _enemy_def_bonus)
			enemy_hp = max(0, enemy_hp - actual_dmg)
			_enemy_def_bonus = 0
			enemy_atk = max(1, enemy_atk - 1)
			return card_name + " → " + str(actual_dmg) + " 伤害，敌方 ATK-1"
		"defend":
			def_bonus += value
			return card_name + " → 防御 +" + str(value) + "（当前 " + str(def_bonus) + "）"
		"heal":
			var actual: int = min(value, player_max_hp - player_hp)
			player_hp = min(player_max_hp, player_hp + value)
			return card_name + " → 回复 " + str(actual) + " HP"
		"poison":
			# 毒素：对敌方施加持续伤害（叠加回合数）
			_poison_turns += value
			return card_name + " → 施加毒素 " + str(_poison_dmg) + "伤/" + str(_poison_turns) + "回合"
		"draw":
			# 抽牌：额外抽牌
			var drawn: int = 0
			for _i in range(value):
				if draw_pile.is_empty():
					_reshuffle()
				if draw_pile.is_empty():
					break
				hand.append(draw_pile.pop_back())
				drawn += 1
			emit_signal("hand_changed", hand, energy, max_energy)
			return card_name + " → 抽 " + str(drawn) + " 张牌"
		"counter":
			# 反击：获得防御 + 设置反击伤害
			var def_val: int = int(card.get("def_value", 2))
			def_bonus += def_val
			_counter_dmg += value
			return card_name + " → 防御+" + str(def_val) + "，反击蓄力 " + str(_counter_dmg)
		"combo":
			# 连击：多次攻击，每次独立计算防御减免
			var hits: int = int(card.get("hits", 3))
			var total_dmg: int = 0
			for _i in range(hits):
				var hit_dmg: int = max(1, value - _enemy_def_bonus)
				enemy_hp = max(0, enemy_hp - hit_dmg)
				total_dmg += hit_dmg
				_enemy_def_bonus = max(0, _enemy_def_bonus - value)
			return card_name + " → " + str(hits) + "连击 共 " + str(total_dmg) + " 伤害"
	return ""

# ======== 敌方行为系统 ========

func _enemy_act() -> void:
	var action: String = _enemy_pattern[_enemy_pattern_index]
	var text: String = ""
	match action:
		"attack":
			var actual_dmg: int = max(1, enemy_atk - def_bonus)
			player_hp = max(0, player_hp - actual_dmg)
			text = enemy_name + " 攻击 → " + str(actual_dmg) + " 伤害"
			if def_bonus > 0:
				text += "（已减免）"
			text += _resolve_counter()
		"heavy_attack":
			var heavy_dmg: int = enemy_atk * 2
			var actual_dmg: int = max(1, heavy_dmg - def_bonus)
			player_hp = max(0, player_hp - actual_dmg)
			text = enemy_name + " 重击 → " + str(actual_dmg) + " 伤害！"
			if def_bonus > 0:
				text += "（已减免）"
			text += _resolve_counter()
		"defend_attack":
			_enemy_def_bonus = 2
			var actual_dmg: int = max(1, enemy_atk - def_bonus)
			player_hp = max(0, player_hp - actual_dmg)
			text = enemy_name + " 防御+攻击 → " + str(actual_dmg) + " 伤害，敌方防御+2"
			if def_bonus > 0:
				text += "（已减免）"
			text += _resolve_counter()
		"heal":
			var heal_val: int = 3
			var actual_heal: int = min(heal_val, enemy_max_hp - enemy_hp)
			enemy_hp = min(enemy_max_hp, enemy_hp + heal_val)
			text = enemy_name + " 修复 → 回复 " + str(actual_heal) + " HP"
		"mega_attack":
			var mega_dmg: int = enemy_atk * 3
			var actual_dmg: int = max(1, mega_dmg - def_bonus)
			player_hp = max(0, player_hp - actual_dmg)
			text = enemy_name + " 超载重击 → " + str(actual_dmg) + " 伤害！！"
			if def_bonus > 0:
				text += "（已减免）"
			text += _resolve_counter()
		"buff":
			enemy_atk += 1
			text = enemy_name + " 强化 → ATK+" + str(enemy_atk) + "！"
		"multi_attack":
			var hit_atk: int = max(1, int(float(enemy_atk) * 0.6))
			var total_dmg: int = 0
			for _i in range(2):
				var actual_dmg: int = max(1, hit_atk - def_bonus)
				player_hp = max(0, player_hp - actual_dmg)
				total_dmg += actual_dmg
			text = enemy_name + " 连续攻击 → 2击共 " + str(total_dmg) + " 伤害"
			if def_bonus > 0:
				text += "（已减免）"
			text += _resolve_counter()
	emit_signal("enemy_acted", text)

## 反击结算：如果有反击蓄力且敌方执行了攻击，触发反击
func _resolve_counter() -> String:
	if _counter_dmg <= 0:
		return ""
	var dmg: int = _counter_dmg
	enemy_hp = max(0, enemy_hp - dmg)
	_counter_dmg = 0
	return "\n反击！→ " + str(dmg) + " 伤害"

func _advance_enemy_pattern() -> void:
	_enemy_pattern_index = (_enemy_pattern_index + 1) % _enemy_pattern.size()

func _update_enemy_intent() -> void:
	var next_action: String = _enemy_pattern[_enemy_pattern_index]
	match next_action:
		"attack":
			_next_enemy_intent = "意图：攻击（" + str(enemy_atk) + " 伤害）"
		"heavy_attack":
			_next_enemy_intent = "意图：重击（" + str(enemy_atk * 2) + " 伤害）"
		"defend_attack":
			_next_enemy_intent = "意图：防御+攻击"
		"heal":
			_next_enemy_intent = "意图：修复（回复 HP）"
		"mega_attack":
			_next_enemy_intent = "意图：超载重击（" + str(enemy_atk * 3) + " 伤害）⚠"
		"buff":
			_next_enemy_intent = "意图：强化（ATK+1）"
		"multi_attack":
			var hit_atk: int = max(1, int(float(enemy_atk) * 0.6))
			_next_enemy_intent = "意图：连续攻击（" + str(hit_atk) + "x2）"
		_:
			_next_enemy_intent = "意图：未知"
	emit_signal("enemy_intent_changed", _next_enemy_intent)

# ======== 胜败结算 ========

func _win() -> void:
	state = BattleState.VICTORY
	emit_signal("turn_resolved", player_hp, enemy_hp, battle_turn)
	# 胜利奖励：随机 crest 提示
	var reward_types: Array[String] = ["move", "attack", "defend", "skill", "trick", "summon"]
	var picked: String = reward_types[randi() % reward_types.size()]
	emit_signal("victory_reward", picked.to_upper() + "+1")
	# 能量成长：每次遭遇胜利 +1，Boss 胜利 +2（上限 MAX_ENERGY_CAP）
	var old_max: int = max_energy
	var growth: int = 2 if is_boss_encounter() else 1
	max_energy = min(MAX_ENERGY_CAP, max_energy + growth)
	if max_energy > old_max:
		emit_signal("energy_grown", old_max, max_energy)
	# 进入选牌奖励阶段（不立即结束战斗）
	_generate_reward_options()
	state = BattleState.REWARD_SELECT
	emit_signal("reward_cards_offered", _reward_options)

func _generate_reward_options() -> void:
	var pool: Array[Dictionary] = _build_reward_pool()
	_reward_options = []
	# Boss 战胜利提供更多选择（4 张而非 3 张）
	var choice_count: int = REWARD_CHOICES
	if is_boss_encounter():
		choice_count = 4
	# 随机选取 choice_count 张不重复的卡牌
	var indices: Array[int] = []
	for i in range(pool.size()):
		indices.append(i)
	# Fisher-Yates 洗牌
	for i in range(indices.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var tmp: int = indices[i]
		indices[i] = indices[j]
		indices[j] = tmp
	var count: int = min(choice_count, pool.size())
	for i in range(count):
		_reward_options.append(pool[indices[i]])

func select_reward_card(index: int) -> void:
	if state != BattleState.REWARD_SELECT:
		return
	if index < 0 or index >= _reward_options.size():
		return
	var selected_card: Dictionary = _reward_options[index]
	persistent_deck.append(selected_card.duplicate())
	emit_signal("reward_card_selected", selected_card)
	_finish_battle(true)

func skip_reward() -> void:
	if state != BattleState.REWARD_SELECT:
		return
	_finish_battle(true)

func _finish_battle(victory: bool) -> void:
	if victory:
		state = BattleState.VICTORY
	else:
		state = BattleState.DEFEAT
	emit_signal("battle_ended", victory, player_hp)

func get_reward_options() -> Array[Dictionary]:
	return _reward_options

# ======== 卡牌升级系统 ========

## 返回指定卡牌的升级版本（值提升，费用不变，名称加"+"后缀）
## 升级规则参考 STS：数值提升约 30%~50%，费用不变
static func get_card_upgrade(card: Dictionary) -> Dictionary:
	var up: Dictionary = card.duplicate()
	up["upgraded"] = true
	var base_name: String = String(card["name"])
	up["name"] = base_name + "+"
	match base_name:
		"斩击":
			up["value"] = 4
		"重击":
			up["value"] = 7
		"防御":
			up["value"] = 3
		"修复":
			up["value"] = 3
		"连斩":
			up["value"] = 3
		"猛攻":
			up["value"] = 11
		"急救":
			up["value"] = 6
		"穿刺":
			up["value"] = 6
		"铁壁":
			up["value"] = 6
		"吸血斩":
			up["value"] = 4
			up["heal_value"] = 2
		"超频修复":
			up["value"] = 9
		"电弧":
			up["value"] = 3
		"强化斩击":
			up["value"] = 6
		"双重防御":
			up["value"] = 4
		"毒素注入":
			up["value"] = 4
		"能量虹吸":
			up["value"] = 3
		"反击":
			up["value"] = 4
			up["def_value"] = 3
		"裂空斩":
			up["value"] = 3
			up["hits"] = 3
		_:
			# 未知牌：默认 value+1
			up["value"] = int(card.get("value", 0)) + 1
	return up

## 获取持久牌组中所有可升级卡牌的索引列表
func get_upgradeable_indices() -> Array[int]:
	var indices: Array[int] = []
	for i in range(persistent_deck.size()):
		if not persistent_deck[i].get("upgraded", false):
			indices.append(i)
	return indices

## 升级持久牌组中指定索引的卡牌（原地替换）
func upgrade_deck_card(deck_index: int) -> void:
	if state != BattleState.REWARD_SELECT:
		return
	if deck_index < 0 or deck_index >= persistent_deck.size():
		return
	var old_card: Dictionary = persistent_deck[deck_index]
	if old_card.get("upgraded", false):
		return
	var new_card: Dictionary = get_card_upgrade(old_card)
	persistent_deck[deck_index] = new_card
	emit_signal("card_upgrade_completed", old_card, new_card)
	_finish_battle(true)

func get_deck_size() -> int:
	return persistent_deck.size()

func reset_persistent_deck() -> void:
	persistent_deck = _build_deck()
	_deck_initialized = true
	max_energy = INITIAL_MAX_ENERGY

func _lose() -> void:
	state = BattleState.DEFEAT
	emit_signal("turn_resolved", player_hp, enemy_hp, battle_turn)
	emit_signal("battle_ended", false, 0)

func is_active() -> bool:
	return state == BattleState.PLAYER_TURN or state == BattleState.ENEMY_TURN or state == BattleState.REWARD_SELECT

func get_draw_count() -> int:
	return draw_pile.size()

func get_discard_count() -> int:
	return discard_pile.size()

## 判断当前战斗是否为 Boss 遭遇
func is_boss_encounter() -> bool:
	var data: Dictionary = get_encounter_enemy_data(encounter_id)
	return data.get("is_boss", false)

## 通关层奖励：不经过战斗，直接进入选牌/升级阶段
func offer_floor_reward() -> void:
	_reward_options = []
	_generate_reward_options()
	state = BattleState.REWARD_SELECT
	emit_signal("reward_cards_offered", _reward_options)
