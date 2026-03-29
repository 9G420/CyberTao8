extends Node
class_name CardBattleController

## 卡牌战斗状态机（Day 9b）
## 独立于 BattleFlowController，只通过信号与棋盘层通信
## 旧项目参考判断：旧 BattleManager.gd（2500+ 行）数据结构过于复杂，
## 包含阴阳系统/召唤/多状态/98 张卡池等——当前原型不复用，仅参考 energy/手牌概念。
## Day 10 可参考旧项目的 Deck.gd 双牌堆结构和 CardData.gd 费用模型。

signal battle_started(player_hp: int, enemy_hp: int, enemy_name: String)
signal card_played(card_index: int, card_name: String, effect_text: String)
signal enemy_acted(action_text: String)
signal turn_resolved(player_hp: int, enemy_hp: int, battle_turn: int)
signal battle_ended(victory: bool, player_hp_remaining: int)

enum BattleState { IDLE, PLAYER_TURN, ENEMY_TURN, VICTORY, DEFEAT }

var state: BattleState = BattleState.IDLE
var player_hp: int = 0
var player_max_hp: int = 0
var enemy_hp: int = 0
var enemy_max_hp: int = 0
var enemy_atk: int = 2
var enemy_name: String = ""
var def_bonus: int = 0
var battle_turn: int = 0
var encounter_id: String = ""

# 固定手牌（Day 9 原型，Day 10 改为抽牌+费用）
var hand: Array[Dictionary] = []

## 遭遇敌方数据映射（从 BattleFlowController 剥离至此）
static func get_encounter_enemy_data(enc_id: String) -> Dictionary:
	match enc_id:
		"encounter_01":
			return {"name": "异常哨兵", "hp": 6, "atk": 2}
		"encounter_02":
			return {"name": "赛博游魂", "hp": 4, "atk": 3}
	return {"name": "未知敌人", "hp": 4, "atk": 2}

func start_battle(enc_id: String, p_hp: int, p_max_hp: int) -> void:
	encounter_id = enc_id
	var enemy_data: Dictionary = get_encounter_enemy_data(enc_id)
	enemy_name = enemy_data["name"]
	enemy_hp = int(enemy_data["hp"])
	enemy_max_hp = enemy_hp
	enemy_atk = int(enemy_data["atk"])
	player_hp = p_hp
	player_max_hp = p_max_hp
	def_bonus = 0
	battle_turn = 1
	state = BattleState.PLAYER_TURN
	_build_hand()
	emit_signal("battle_started", player_hp, enemy_hp, enemy_name)

func _build_hand() -> void:
	hand = [
		{"name": "斩击", "type": "attack", "value": 3, "desc": "造成 3 点伤害"},
		{"name": "重击", "type": "attack", "value": 5, "desc": "造成 5 点伤害"},
		{"name": "防御", "type": "defend", "value": 2, "desc": "本回合减伤 2"},
		{"name": "修复", "type": "heal", "value": 2, "desc": "回复 2 HP"},
		{"name": "连斩", "type": "attack", "value": 2, "desc": "造成 2 点伤害"},
	]

func play_card(index: int) -> void:
	if state != BattleState.PLAYER_TURN:
		return
	if index < 0 or index >= hand.size():
		return
	var card: Dictionary = hand[index]
	var effect_text: String = ""
	# 重置上回合防御加成
	def_bonus = 0
	match card["type"]:
		"attack":
			var dmg: int = card["value"]
			enemy_hp = max(0, enemy_hp - dmg)
			effect_text = card["name"] + " → 对 " + enemy_name + " 造成 " + str(dmg) + " 伤害"
		"defend":
			def_bonus = card["value"]
			effect_text = card["name"] + " → 防御 +" + str(card["value"])
		"heal":
			var actual: int = min(card["value"], player_max_hp - player_hp)
			player_hp = min(player_max_hp, player_hp + card["value"])
			effect_text = card["name"] + " → 回复 " + str(actual) + " HP"
	emit_signal("card_played", index, card["name"], effect_text)
	# 检查敌方是否被击杀
	if enemy_hp <= 0:
		state = BattleState.VICTORY
		emit_signal("turn_resolved", player_hp, enemy_hp, battle_turn)
		emit_signal("battle_ended", true, player_hp)
		return
	# 敌方行动
	state = BattleState.ENEMY_TURN
	_enemy_act()
	# 检查玩家是否被击杀
	if player_hp <= 0:
		state = BattleState.DEFEAT
		emit_signal("turn_resolved", player_hp, enemy_hp, battle_turn)
		emit_signal("battle_ended", false, 0)
		return
	# 下一回合
	battle_turn += 1
	state = BattleState.PLAYER_TURN
	emit_signal("turn_resolved", player_hp, enemy_hp, battle_turn)

func _enemy_act() -> void:
	var actual_dmg: int = max(1, enemy_atk - def_bonus)
	player_hp = max(0, player_hp - actual_dmg)
	var text: String = enemy_name + " 攻击 → " + str(actual_dmg) + " 伤害"
	if def_bonus > 0:
		text += "（已减免）"
	emit_signal("enemy_acted", text)

func flee() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	state = BattleState.DEFEAT
	player_hp = max(0, player_hp - 1)
	emit_signal("battle_ended", false, player_hp)

func is_active() -> bool:
	return state == BattleState.PLAYER_TURN or state == BattleState.ENEMY_TURN
