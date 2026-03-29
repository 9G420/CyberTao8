extends Node
class_name CardBattleController

## 卡牌战斗状态机（Day 13：构筑成长版）
## 能量系统 + 双牌堆抽牌 + 3 种敌方行为模式 + 敌方意图预告
## 持久牌组 + 战斗胜利选牌构筑
## 参考旧项目 Deck.gd 双牌堆结构、CardData.gd 费用模型

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
	deck.append({"name": "斩击", "type": "attack", "cost": 1, "value": 3})
	deck.append({"name": "斩击", "type": "attack", "cost": 1, "value": 3})
	# 重击 x1 (cost 2, 5 伤害)
	deck.append({"name": "重击", "type": "attack", "cost": 2, "value": 5})
	# 防御 x2 (cost 1, 减伤 2)
	deck.append({"name": "防御", "type": "defend", "cost": 1, "value": 2})
	deck.append({"name": "防御", "type": "defend", "cost": 1, "value": 2})
	# 修复 x1 (cost 1, 回复 2)
	deck.append({"name": "修复", "type": "heal", "cost": 1, "value": 2})
	# 连斩 x2 (cost 1, 2 伤害)
	deck.append({"name": "连斩", "type": "attack", "cost": 1, "value": 2})
	deck.append({"name": "连斩", "type": "attack", "cost": 1, "value": 2})
	# 猛攻 x1 (cost 3, 8 伤害)
	deck.append({"name": "猛攻", "type": "attack", "cost": 3, "value": 8})
	# 急救 x1 (cost 2, 回复 4)
	deck.append({"name": "急救", "type": "heal", "cost": 2, "value": 4})
	return deck

# ======== 奖励卡池（不在初始牌组中的可获得卡牌） ========

static func _build_reward_pool() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	# 穿刺 (cost 2, 4 伤害，无视敌方防御)
	pool.append({"name": "穿刺", "type": "pierce", "cost": 2, "value": 4})
	# 铁壁 (cost 2, 防御 4)
	pool.append({"name": "铁壁", "type": "defend", "cost": 2, "value": 4})
	# 吸血斩 (cost 2, 3 伤害 + 回复 1)
	pool.append({"name": "吸血斩", "type": "lifesteal", "cost": 2, "value": 3})
	# 超频修复 (cost 3, 回复 6)
	pool.append({"name": "超频修复", "type": "heal", "cost": 3, "value": 6})
	# 电弧 (cost 1, 2 伤害 + 下回合敌方 ATK-1)
	pool.append({"name": "电弧", "type": "shock", "cost": 1, "value": 2})
	# 强化斩击 (cost 1, 4 伤害)
	pool.append({"name": "强化斩击", "type": "attack", "cost": 1, "value": 4})
	# 双重防御 (cost 1, 防御 3)
	pool.append({"name": "双重防御", "type": "defend", "cost": 1, "value": 3})
	# 初始牌组中的牌也可以作为奖励出现
	pool.append({"name": "斩击", "type": "attack", "cost": 1, "value": 3})
	pool.append({"name": "重击", "type": "attack", "cost": 2, "value": 5})
	pool.append({"name": "防御", "type": "defend", "cost": 1, "value": 2})
	pool.append({"name": "修复", "type": "heal", "cost": 1, "value": 2})
	pool.append({"name": "猛攻", "type": "attack", "cost": 3, "value": 8})
	pool.append({"name": "急救", "type": "heal", "cost": 2, "value": 4})
	return pool

# ======== 遭遇敌方数据 ========

static func get_encounter_enemy_data(enc_id: String) -> Dictionary:
	match enc_id:
		"encounter_01":
			return {
				"name": "异常哨兵", "hp": 8, "atk": 2,
				"pattern": ["attack", "attack", "defend_attack", "heavy_attack"],
			}
		"encounter_02":
			return {
				"name": "赛博游魂", "hp": 6, "atk": 3,
				"pattern": ["attack", "heavy_attack", "attack"],
			}
	return {
		"name": "未知敌人", "hp": 5, "atk": 2,
		"pattern": ["attack", "attack"],
	}

# ======== 战斗流程 ========

func start_battle(enc_id: String, p_hp: int, p_max_hp: int) -> void:
	encounter_id = enc_id
	var enemy_data: Dictionary = get_encounter_enemy_data(enc_id)
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
			# 吸血斩：造成伤害并回复 1 HP
			var actual_dmg: int = max(1, value - _enemy_def_bonus)
			enemy_hp = max(0, enemy_hp - actual_dmg)
			_enemy_def_bonus = 0
			var heal_val: int = 1
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
		"heavy_attack":
			var heavy_dmg: int = enemy_atk * 2
			var actual_dmg: int = max(1, heavy_dmg - def_bonus)
			player_hp = max(0, player_hp - actual_dmg)
			text = enemy_name + " 重击 → " + str(actual_dmg) + " 伤害！"
			if def_bonus > 0:
				text += "（已减免）"
		"defend_attack":
			_enemy_def_bonus = 2
			var actual_dmg: int = max(1, enemy_atk - def_bonus)
			player_hp = max(0, player_hp - actual_dmg)
			text = enemy_name + " 防御+攻击 → " + str(actual_dmg) + " 伤害，敌方防御+2"
			if def_bonus > 0:
				text += "（已减免）"
	emit_signal("enemy_acted", text)

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
	# 进入选牌奖励阶段（不立即结束战斗）
	_generate_reward_options()
	state = BattleState.REWARD_SELECT
	emit_signal("reward_cards_offered", _reward_options)

func _generate_reward_options() -> void:
	var pool: Array[Dictionary] = _build_reward_pool()
	_reward_options = []
	# 随机选取 REWARD_CHOICES 张不重复的卡牌
	var indices: Array[int] = []
	for i in range(pool.size()):
		indices.append(i)
	# Fisher-Yates 洗牌
	for i in range(indices.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var tmp: int = indices[i]
		indices[i] = indices[j]
		indices[j] = tmp
	var count: int = min(REWARD_CHOICES, pool.size())
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

func get_deck_size() -> int:
	return persistent_deck.size()

func reset_persistent_deck() -> void:
	persistent_deck = _build_deck()
	_deck_initialized = true

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
