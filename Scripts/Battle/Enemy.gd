# ============================================================
# Enemy.gd - 敌人数据与AI行为（重构版）
# ============================================================
class_name EnemyUnit
extends RefCounted

## 敌人类型
enum EnemyType { GRUNT_GHOST, GRUNT_SWARM, GRUNT_THIEF, ELITE_PUPPET, ELITE_OBSESSION, BOSS }

## 敌人AI行为
enum AIAction { ATTACK, DEFEND, SUMMON, BUFF, SPECIAL }

## 基础属性
var enemy_name: String = "未知敌人"
var enemy_type: EnemyType = EnemyType.GRUNT_GHOST
var hp: int = 20
var max_hp: int = 20
var shield: int = 0
var attack_power: int = 3
var defense_power: int = 2

## Boss专用 - 阶段
var boss_phase: int = 1
var phase_threshold: float = 0.5

## 召唤物列表
var summons: Array[Dictionary] = []

## 回合计数（用于AI决策模式）
var turn_count: int = 0

## 下一步行动（预告机制）
var next_action: AIAction = AIAction.ATTACK
var next_action_value: int = 0
var next_action_multi_hit: int = 0
var next_action_aoe: bool = false
var next_action_status: Dictionary = {}

## 状态效果列表 [{"type":"burn","value":2,"turns":2}]
var statuses: Array[Dictionary] = []

## 初始化敌人
static func create_enemy(type: EnemyType) -> EnemyUnit:
	var enemy := EnemyUnit.new()
	match type:
		EnemyType.GRUNT_GHOST:
			enemy.enemy_name = "数据游魂"
			enemy.hp = 28
			enemy.max_hp = 28
			enemy.attack_power = 5
			enemy.defense_power = 4
		EnemyType.GRUNT_SWARM:
			enemy.enemy_name = "代码虫群"
			enemy.hp = 18
			enemy.max_hp = 18
			enemy.attack_power = 3
			enemy.defense_power = 2
		EnemyType.GRUNT_THIEF:
			enemy.enemy_name = "数据窃贼"
			enemy.hp = 22
			enemy.max_hp = 22
			enemy.attack_power = 6
			enemy.defense_power = 5
		EnemyType.ELITE_PUPPET:
			enemy.enemy_name = "欲望傀儡"
			enemy.hp = 48
			enemy.max_hp = 48
			enemy.attack_power = 7
			enemy.defense_power = 6
		EnemyType.ELITE_OBSESSION:
			enemy.enemy_name = "扭曲执念"
			enemy.hp = 55
			enemy.max_hp = 55
			enemy.attack_power = 5
			enemy.defense_power = 8
		EnemyType.BOSS:
			enemy.enemy_name = "旧我·被欲望扭曲者"
			enemy.hp = 80
			enemy.max_hp = 80
			enemy.attack_power = 8
			enemy.defense_power = 10
			enemy.phase_threshold = 0.5
	enemy.enemy_type = type
	enemy.turn_count = 0
	enemy._decide_next_action()
	return enemy

## 重置行动附加字段
func _reset_action_extras() -> void:
	next_action_multi_hit = 0
	next_action_aoe = false
	next_action_status = {}

## AI决策：决定下一步行动
func _decide_next_action() -> void:
	turn_count += 1
	_reset_action_extras()
	var hp_ratio := float(hp) / float(max_hp)

	match enemy_type:
		EnemyType.GRUNT_GHOST:
			# Pattern: atk5 → atk5 → def4 → cycle
			var phase := (turn_count - 1) % 3
			if phase == 2:
				next_action = AIAction.DEFEND
				next_action_value = defense_power
			else:
				next_action = AIAction.ATTACK
				next_action_value = attack_power

		EnemyType.GRUNT_SWARM:
			# Turn 1: SUMMON
			# Then: atk3x2 → atk3x2 → SUMMON → cycle (3-turn cycle after turn 1)
			if turn_count == 1:
				next_action = AIAction.SUMMON
				next_action_value = 1
			else:
				var phase := (turn_count - 2) % 3
				if phase == 2:
					next_action = AIAction.SUMMON
					next_action_value = 1
				else:
					next_action = AIAction.ATTACK
					next_action_value = attack_power
					next_action_multi_hit = 2

		EnemyType.GRUNT_THIEF:
			# Pattern: atk6 → atk6+steal_energy(SPECIAL) → def5 → cycle
			var phase := (turn_count - 1) % 3
			if phase == 0:
				next_action = AIAction.ATTACK
				next_action_value = attack_power
			elif phase == 1:
				next_action = AIAction.SPECIAL
				next_action_value = attack_power
			else:
				next_action = AIAction.DEFEND
				next_action_value = defense_power

		EnemyType.ELITE_PUPPET:
			_decide_puppet_action(hp_ratio)

		EnemyType.ELITE_OBSESSION:
			_decide_obsession_action(hp_ratio)

		EnemyType.BOSS:
			_decide_boss_action(hp_ratio)

## 欲望傀儡 AI
func _decide_puppet_action(hp_ratio: float) -> void:
	# Below 40% HP: alternate DEFEND 6 and ATTACK 7
	if hp_ratio <= 0.4:
		if turn_count % 2 == 0:
			next_action = AIAction.ATTACK
			next_action_value = attack_power
		else:
			next_action = AIAction.DEFEND
			next_action_value = defense_power
		return
	# Turn 1: BUFF atk+3
	if turn_count == 1:
		next_action = AIAction.BUFF
		next_action_value = 3
		return
	# Turns 2-4 cycle: atk7, atk7, atk14, then back to 2-pattern
	var phase := (turn_count - 2) % 3
	if phase == 0 or phase == 1:
		next_action = AIAction.ATTACK
		next_action_value = attack_power
	else:  # phase == 2
		next_action = AIAction.ATTACK
		next_action_value = attack_power * 2  # heavy strike 14

## 扭曲执念 AI
func _decide_obsession_action(_hp_ratio: float) -> void:
	# Every 3rd turn: SUMMON (max 2)
	if turn_count % 3 == 0:
		next_action = AIAction.SUMMON
		next_action_value = 1
		return
	# Other turns: 2-turn sub-cycle among non-summon turns
	# Count non-summon turns to determine sub-phase
	# Non-summon turns are turn_count where turn_count % 3 != 0
	# Sub-pattern: atk5+corruption3 → atk8 → def8 (3-step among non-summon)
	var non_summon_index := _count_non_summon_turns()
	var sub_phase := non_summon_index % 3
	if sub_phase == 0:
		next_action = AIAction.ATTACK
		next_action_value = attack_power
		next_action_status = {"type": "corruption", "value": 3}
	elif sub_phase == 1:
		next_action = AIAction.ATTACK
		next_action_value = 8
	else:
		next_action = AIAction.DEFEND
		next_action_value = defense_power

func _count_non_summon_turns() -> int:
	# Count how many non-summon turns have occurred up to current turn_count
	var count := 0
	for t in range(1, turn_count + 1):
		if t % 3 != 0:
			count += 1
	return count - 1  # zero-indexed for current turn

## Boss专用AI
func _decide_boss_action(_hp_ratio: float) -> void:
	# Check phase transition
	if hp <= 40 and boss_phase == 1:
		boss_phase = 2
		next_action = AIAction.SPECIAL
		next_action_value = 6
		next_action_aoe = true
		return

	if boss_phase == 1:
		# Phase 1: Turn 1 summon two, then cycle turns 2-4
		if turn_count == 1:
			next_action = AIAction.SUMMON
			next_action_value = 2  # summon two
			return
		var phase := (turn_count - 2) % 3
		if phase == 0:
			# Turn 2: ATTACK 10 + corruption 3
			next_action = AIAction.ATTACK
			next_action_value = 10
			next_action_status = {"type": "corruption", "value": 3}
		elif phase == 1:
			# Turn 3: ATTACK 8 x2
			next_action = AIAction.ATTACK
			next_action_value = 8
			next_action_multi_hit = 2
		else:
			# Turn 4: DEFEND 10 (+ heal 5 in execute)
			next_action = AIAction.DEFEND
			next_action_value = 10
	else:
		# Phase 2: 4-turn cycle A-D
		var p2_turn := (turn_count - 1) % 4
		if p2_turn == 0:
			# Turn A: ATTACK 12
			next_action = AIAction.ATTACK
			next_action_value = 12
		elif p2_turn == 1:
			# Turn B: ATTACK 6 x3
			next_action = AIAction.ATTACK
			next_action_value = 6
			next_action_multi_hit = 3
		elif p2_turn == 2:
			# Turn C: SPECIAL burn_summons
			next_action = AIAction.SPECIAL
			next_action_value = 0
		else:
			# Turn D: SUMMON + ATTACK 8
			next_action = AIAction.SUMMON
			next_action_value = 8

## 执行当前行动，返回描述字典
func execute_action() -> Dictionary:
	var result := {
		"action": next_action,
		"value": next_action_value,
		"text": "",
		"damage_to_player": 0,
		"shield_gained": 0,
		"summon": false,
		"special_effect": "",
		"multi_hit": next_action_multi_hit,
		"aoe": next_action_aoe,
		"apply_status": next_action_status.duplicate(),
		"heal_amount": 0,
		"steal_energy": 0,
		"burn_summons": 0,
	}

	match next_action:
		AIAction.ATTACK:
			var dmg := calc_outgoing_damage(next_action_value)
			if next_action_multi_hit > 0:
				result["damage_to_player"] = dmg
				result["multi_hit"] = next_action_multi_hit
				result["text"] = enemy_name + " 发动攻击！造成 " + str(dmg) + " x" + str(next_action_multi_hit) + " 点伤害"
			else:
				result["damage_to_player"] = dmg
				result["text"] = enemy_name + " 发动攻击！造成 " + str(dmg) + " 点伤害"
			if not next_action_status.is_empty():
				result["text"] += "，附加" + str(next_action_status.get("value", 0)) + "点" + next_action_status.get("type", "") + "效果"

		AIAction.DEFEND:
			shield += next_action_value
			result["shield_gained"] = next_action_value
			result["text"] = enemy_name + " 进入防御姿态！获得 " + str(next_action_value) + " 护盾"
			# Boss phase 1 defend also heals 5
			if enemy_type == EnemyType.BOSS and boss_phase == 1:
				var heal_val := 5
				hp = mini(hp + heal_val, max_hp)
				result["heal_amount"] = heal_val
				result["text"] += "，恢复 " + str(heal_val) + " HP"

		AIAction.BUFF:
			attack_power += next_action_value
			result["text"] = enemy_name + " 强化了自身！攻击力+" + str(next_action_value)

		AIAction.SUMMON:
			result["summon"] = true
			_execute_summon(result)

		AIAction.SPECIAL:
			_execute_special(result)

	# 决定下一步行动（预告）
	_decide_next_action()
	return result

func _execute_summon(result: Dictionary) -> void:
	match enemy_type:
		EnemyType.GRUNT_SWARM:
			if summons.size() < 2:
				summons.append({"name": "代码虫", "hp": 3, "attack": 4})
				result["text"] = enemy_name + " 召唤了代码虫！"
			else:
				# Max summons reached, attack instead
				result["summon"] = false
				var dmg := calc_outgoing_damage(attack_power)
				result["damage_to_player"] = dmg
				result["multi_hit"] = 2
				result["text"] = enemy_name + " 无法召唤更多，转而攻击！造成 " + str(dmg) + " x2 点伤害"
		EnemyType.ELITE_OBSESSION:
			if summons.size() < 2:
				summons.append({"name": "心魔碎片", "hp": 6, "attack": 4})
				result["text"] = enemy_name + " 召唤了心魔碎片！"
			else:
				result["summon"] = false
				var dmg := calc_outgoing_damage(attack_power)
				result["damage_to_player"] = dmg
				result["text"] = enemy_name + " 无法召唤更多，转而攻击！造成 " + str(dmg) + " 点伤害"
		EnemyType.BOSS:
			if boss_phase == 1 and next_action_value == 2:
				# Turn 1: summon two with taunt
				for i in 2:
					summons.append({"name": "欲望碎片", "hp": 8, "attack": 3, "taunt": true})
				result["text"] = enemy_name + " 召唤了两个欲望碎片！"
			elif boss_phase == 2:
				# Phase 2 Turn D: summon + attack 8
				summons.append({"name": "心魔碎片", "hp": 5, "attack": 3})
				var dmg := calc_outgoing_damage(8)
				result["damage_to_player"] = dmg
				result["text"] = enemy_name + " 召唤了心魔碎片并攻击！造成 " + str(dmg) + " 点伤害"
			else:
				summons.append({"name": "心魔碎片", "hp": 5, "attack": 3})
				result["text"] = enemy_name + " 召唤了心魔碎片！"
		_:
			summons.append({"name": "心魔碎片", "hp": 5, "attack": 3})
			result["text"] = enemy_name + " 召唤了心魔碎片！"

func _execute_special(result: Dictionary) -> void:
	match enemy_type:
		EnemyType.GRUNT_THIEF:
			# Attack + steal 1 energy
			var dmg := calc_outgoing_damage(next_action_value)
			result["damage_to_player"] = dmg
			result["steal_energy"] = 1
			result["special_effect"] = "steal_energy"
			result["text"] = enemy_name + " 发动窃取！造成 " + str(dmg) + " 点伤害，窃取1点能量"
		EnemyType.BOSS:
			if boss_phase == 2 and next_action_value == 0:
				# Phase 2 Turn C: burn_summons
				result["burn_summons"] = 2
				result["special_effect"] = "burn_summons"
				result["text"] = enemy_name + " 释放心魔之火！灼烧所有玩家召唤物（2回合）"
			elif next_action_aoe:
				# Phase transition
				result["special_effect"] = "boss_phase2"
				result["damage_to_player"] = next_action_value
				result["aoe"] = true
				attack_power += 4
				result["text"] = "「旧我」爆发！进入第二阶段——心魔觉醒！全场 " + str(next_action_value) + " 伤害，攻击力+4"
			else:
				result["damage_to_player"] = next_action_value
				result["text"] = enemy_name + " 释放特殊攻击！造成 " + str(next_action_value) + " 点伤害"
				result["special_effect"] = "aoe"
		_:
			result["damage_to_player"] = next_action_value
			result["text"] = enemy_name + " 释放特殊攻击！造成 " + str(next_action_value) + " 点伤害"

## ============================================================
## 状态效果处理
## ============================================================

func apply_status(status_type: String, value: int, turns: int) -> void:
	# Check if status already exists, stack or refresh
	for s in statuses:
		if s["type"] == status_type:
			if status_type == "corruption":
				s["value"] += value  # corruption stacks additively
			else:
				s["value"] = max(s["value"], value)
				s["turns"] = max(s["turns"], turns)
			return
	statuses.append({"type": status_type, "value": value, "turns": turns})

func process_turn_start_statuses() -> Dictionary:
	# Returns {"damage": N, "skip_turn": bool}
	var result := {"damage": 0, "skip_turn": false}
	var to_remove: Array[int] = []
	for i in statuses.size():
		var s := statuses[i]
		match s["type"]:
			"corruption":
				result["damage"] += s["value"]
				s["value"] -= 1
				if s["value"] <= 0:
					to_remove.append(i)
			"burn":
				result["damage"] += 2
				s["turns"] -= 1
				if s["turns"] <= 0:
					to_remove.append(i)
			"stun":
				result["skip_turn"] = true
				to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		statuses.remove_at(idx)
	return result

func get_status_value(status_type: String) -> int:
	for s in statuses:
		if s["type"] == status_type:
			return s["value"]
	return 0

func has_status(status_type: String) -> bool:
	for s in statuses:
		if s["type"] == status_type:
			return true
	return false

func clear_negative_statuses() -> void:
	statuses = statuses.filter(func(s: Dictionary) -> bool: return s["type"] not in ["corruption", "burn", "weak", "vulnerable", "stun"])

## ============================================================
## 伤害计算
## ============================================================

## 计算输出伤害（受weak影响）
func calc_outgoing_damage(base: int) -> int:
	var dmg := base
	if has_status("weak"):
		dmg = int(float(dmg) * 0.75)
	return max(0, dmg)

## 受到伤害（受vulnerable影响，先扣护盾）
func take_damage(amount: int) -> int:
	var actual := amount
	if has_status("vulnerable"):
		actual = int(float(actual) * 1.5)
	if shield > 0:
		if shield >= actual:
			shield -= actual
			return 0
		else:
			actual -= shield
			shield = 0
	hp = max(0, hp - actual)
	return actual

## 是否死亡
func is_dead() -> bool:
	return hp <= 0

## ============================================================
## 意图显示
## ============================================================

## 获取下一步行动预告文本
func get_intent_text() -> String:
	match next_action:
		AIAction.ATTACK:
			var txt := "意图：攻击 " + str(next_action_value)
			if next_action_multi_hit > 0:
				txt += " x" + str(next_action_multi_hit)
			if not next_action_status.is_empty():
				txt += " +" + next_action_status.get("type", "")
			return txt
		AIAction.DEFEND:
			var txt := "意图：防御 " + str(next_action_value)
			if enemy_type == EnemyType.BOSS and boss_phase == 1:
				txt += " +回复"
			return txt
		AIAction.BUFF:
			return "意图：强化"
		AIAction.SUMMON:
			if enemy_type == EnemyType.BOSS and boss_phase == 2:
				return "意图：召唤+攻击"
			return "意图：召唤"
		AIAction.SPECIAL:
			if enemy_type == EnemyType.GRUNT_THIEF:
				return "意图：窃取 " + str(next_action_value)
			elif enemy_type == EnemyType.BOSS:
				if next_action_aoe:
					return "意图：？？？（危险）"
				else:
					return "意图：心魔之火"
			return "意图：？？？"
		_:
			return ""

## 获取意图图标颜色
func get_intent_color() -> Color:
	match next_action:
		AIAction.ATTACK:
			if next_action_multi_hit >= 3:
				return Color(1.0, 0.1, 0.1)  # bright red for multi-hit
			return Color(1.0, 0.3, 0.3)
		AIAction.DEFEND:
			return Color(0.3, 0.6, 1.0)
		AIAction.BUFF:
			return Color(1.0, 0.8, 0.2)
		AIAction.SUMMON:
			return Color(0.3, 1.0, 0.5)
		AIAction.SPECIAL:
			return Color(0.8, 0.2, 0.8)
		_:
			return Color(0.8, 0.2, 0.8)
