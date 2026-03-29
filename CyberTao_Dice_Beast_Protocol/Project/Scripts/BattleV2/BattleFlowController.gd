extends Node
class_name BattleFlowController

signal setup_completed
signal phase_changed(phase_name: String)
signal move_completed(unit_id: String, from_cell: Vector2i, to_cell: Vector2i)
signal attack_completed(attacker_id: String, defender_id: String, damage: int, killed: bool)
signal enemy_attack_completed(attacker_id: String, defender_id: String, damage: int, killed: bool, target_cell: Vector2i)
signal summon_completed(unit_id: String, path_cells_created: Array[Vector2i], spawn_cell: Vector2i)
signal round_changed(round_number: int)
signal terrain_damage_triggered(unit_id: String, cell: Vector2i, damage: int, terrain_type: String)
signal item_picked_up(unit_id: String, item_id: String, effect_text: String, cell: Vector2i)
signal enemy_action_announced(unit_id: String, action_type: String, detail: String)
signal enemy_turn_ended
signal encounter_triggered(unit_id: String, encounter_id: String, cell: Vector2i)
signal encounter_resolved(encounter_id: String, cell: Vector2i)
signal card_battle_started(encounter_id: String, enemy_name: String, enemy_hp: int, enemy_atk: int, unit_id: String, player_hp: int, player_max_hp: int)
signal card_battle_ended(encounter_id: String, cell: Vector2i, victory: bool, player_hp_remaining: int)
signal heal_cell_triggered(unit_id: String, cell: Vector2i, heal_amount: int, actual_heal: int)
signal event_cell_triggered(unit_id: String, cell: Vector2i, event_id: String, effect_text: String)

const DiceManager = preload("res://Scripts/BattleV2/DiceManager.gd")
const BoardManager = preload("res://Scripts/BattleV2/BoardManager.gd")
const UnitManager = preload("res://Scripts/BattleV2/UnitManager.gd")
const ActionResolver = preload("res://Scripts/BattleV2/ActionResolver.gd")
const BuffManager = preload("res://Scripts/BattleV2/BuffManager.gd")
const BattleAI = preload("res://Scripts/BattleV2/BattleAI.gd")
const AttackRuleHelper = preload("res://Scripts/BattleV2/AttackRuleHelper.gd")
const VictoryRuleHelper = preload("res://Scripts/BattleV2/VictoryRuleHelper.gd")
const UnitData = preload("res://Scripts/Data/UnitData.gd")
const ItemEffectLibrary = preload("res://Scripts/BattleV2/ItemEffectLibrary.gd")

enum BattlePhase {
	BOOT,
	PLAYER_ROLL,
	PLAYER_ACTION,
	ENCOUNTER,
	ENEMY_ROLL,
	ENEMY_ACTION,
	RESOLUTION,
	VICTORY,
	DEFEAT,
}

var current_phase: BattlePhase = BattlePhase.BOOT
var round_index: int = 0
var _summon_counter: int = 0
var _encounter_unit_id: String = ""
var _encounter_id: String = ""
var _encounter_cell: Vector2i = Vector2i(-1, -1)

var dice_manager: DiceManager
var board_manager: BoardManager
var unit_manager: UnitManager
var action_resolver: ActionResolver
var buff_manager: BuffManager
var battle_ai: BattleAI

func _ready() -> void:
	_bootstrap()

func _bootstrap() -> void:
	dice_manager = DiceManager.new()
	board_manager = BoardManager.new()
	unit_manager = UnitManager.new()
	action_resolver = ActionResolver.new()
	buff_manager = BuffManager.new()
	battle_ai = BattleAI.new()

	add_child(dice_manager)
	add_child(board_manager)
	add_child(unit_manager)
	add_child(action_resolver)
	add_child(buff_manager)
	add_child(battle_ai)

	action_resolver.board_manager = board_manager
	action_resolver.unit_manager = unit_manager
	action_resolver.buff_manager = buff_manager
	unit_manager.board_manager = board_manager
	battle_ai.board_manager = board_manager
	battle_ai.unit_manager = unit_manager
	battle_ai.action_resolver = action_resolver

	board_manager.build_test_board(Vector2i(8, 8))
	_spawn_debug_units()
	_spawn_debug_terrain()
	_spawn_debug_items()
	_spawn_debug_encounters()
	_spawn_debug_heal_cells()
	_spawn_debug_event_cells()
	current_phase = BattlePhase.PLAYER_ROLL
	round_index = 1
	emit_signal("setup_completed")
	emit_signal("phase_changed", _phase_name(current_phase))

func is_battle_over() -> bool:
	return current_phase == BattlePhase.VICTORY or current_phase == BattlePhase.DEFEAT

func start_player_roll() -> void:
	if current_phase != BattlePhase.PLAYER_ROLL:
		return
	if is_battle_over():
		return
	dice_manager.roll_turn_dice()
	current_phase = BattlePhase.PLAYER_ACTION
	emit_signal("phase_changed", _phase_name(current_phase))

func enter_player_action() -> void:
	current_phase = BattlePhase.PLAYER_ACTION
	emit_signal("phase_changed", _phase_name(current_phase))

func start_enemy_roll() -> void:
	current_phase = BattlePhase.ENEMY_ROLL
	dice_manager.roll_turn_dice()
	emit_signal("phase_changed", _phase_name(current_phase))

func enter_enemy_action() -> void:
	current_phase = BattlePhase.ENEMY_ACTION
	emit_signal("phase_changed", _phase_name(current_phase))

func mark_victory() -> void:
	current_phase = BattlePhase.VICTORY
	emit_signal("phase_changed", _phase_name(current_phase))

func mark_defeat() -> void:
	current_phase = BattlePhase.DEFEAT
	emit_signal("phase_changed", _phase_name(current_phase))

func spawn_demo_path() -> void:
	var owner_id: String = "player"
	for x in range(1, 4):
		board_manager.add_path_cell(Vector2i(x, 6), owner_id)

func _spawn_debug_units() -> void:
	# 玩家单位 1：刀盾狗（前排坦克，路径适性）
	var dog_data := load("res://Data/Units/blade_shield_dog.tres") as UnitData
	if dog_data:
		unit_manager.spawn_unit(dog_data.unit_id, {
			"max_hp": dog_data.max_hp,
			"atk": dog_data.atk,
			"def": dog_data.def,
			"move_range": dog_data.move_range,
			"attack_range": dog_data.attack_range,
			"owner": "player",
			"tags": dog_data.meme_tags,
			"terrain_affinity": dog_data.terrain_affinity,
			"display_name": dog_data.unit_name,
		}, Vector2i(0, 6))
	# 玩家单位 2：灵狐骇客（控制型，陷阱适性）
	var fox_data := load("res://Data/Units/hacker_fox.tres") as UnitData
	if fox_data:
		unit_manager.spawn_unit(fox_data.unit_id, {
			"max_hp": fox_data.max_hp,
			"atk": fox_data.atk,
			"def": fox_data.def,
			"move_range": fox_data.move_range,
			"attack_range": fox_data.attack_range,
			"owner": "player",
			"tags": fox_data.meme_tags,
			"terrain_affinity": fox_data.terrain_affinity,
			"display_name": fox_data.unit_name,
		}, Vector2i(1, 7))
	# 玩家单位 3：鸦机术士（远程控场，高台适性）
	var crow_data := load("res://Data/Units/crow_caster.tres") as UnitData
	if crow_data:
		unit_manager.spawn_unit(crow_data.unit_id, {
			"max_hp": crow_data.max_hp,
			"atk": crow_data.atk,
			"def": crow_data.def,
			"move_range": crow_data.move_range,
			"attack_range": crow_data.attack_range,
			"owner": "player",
			"tags": crow_data.meme_tags,
			"terrain_affinity": crow_data.terrain_affinity,
			"display_name": crow_data.unit_name,
		}, Vector2i(0, 5))
	# 敌方单位 1
	var enemy_data_1: Dictionary = {
		"max_hp": 5,
		"atk": 2,
		"def": 0,
		"move_range": 1,
		"attack_range": 1,
		"owner": "enemy",
		"tags": ["grunt"],
		"display_name": "哨兵甲",
	}
	unit_manager.spawn_unit("enemy_grunt_1", enemy_data_1, Vector2i(3, 4))
	# 敌方单位 2
	var enemy_data_2: Dictionary = {
		"max_hp": 4,
		"atk": 3,
		"def": 0,
		"move_range": 1,
		"attack_range": 1,
		"owner": "enemy",
		"tags": ["grunt"],
		"display_name": "哨兵乙",
	}
	unit_manager.spawn_unit("enemy_grunt_2", enemy_data_2, Vector2i(5, 3))

## 放置调试用地形格
func _spawn_debug_terrain() -> void:
	# 高台格：棋盘中部偏上，2 格
	board_manager.add_terrain_cell(Vector2i(2, 4), "high_ground")
	board_manager.add_terrain_cell(Vector2i(2, 5), "high_ground")
	# 陷阱格：玩家前进路线上，2 格
	board_manager.add_terrain_cell(Vector2i(1, 5), "trap")
	board_manager.add_terrain_cell(Vector2i(3, 6), "trap")

## 放置调试用道具格
func _spawn_debug_items() -> void:
	# 补丁凉茶：回复 2 HP，位于中部（值得绕路去拿）
	board_manager.add_item_cell(Vector2i(4, 5), "patch_tea_cache")
	# 超频骨头：+1 MOVE crest，位于前进路线上
	board_manager.add_item_cell(Vector2i(2, 6), "overclock_bone")

## 放置调试用遭遇格（橙红警告色，踩上触发遭遇信号）
func _spawn_debug_encounters() -> void:
	# 遭遇格 1：玩家前进路线中段，难以绕过
	board_manager.add_encounter_cell(Vector2i(4, 4), "encounter_01")
	# 遭遇格 2：偏侧翼，可选择绕行或主动踩入
	board_manager.add_encounter_cell(Vector2i(6, 5), "encounter_02")

## 放置调试用恢复格（蓝白色，持久回复，可重复踩）
func _spawn_debug_heal_cells() -> void:
	# 恢复格 1：玩家路线侧翼，值得绕路回复
	board_manager.add_heal_cell(Vector2i(5, 6), 2)
	# 恢复格 2：棋盘深处，冒险奖励
	board_manager.add_heal_cell(Vector2i(1, 3), 3)

## 放置调试用事件格（黄紫色，一次性随机效果）
func _spawn_debug_event_cells() -> void:
	# 事件格 1：中路必经之路
	board_manager.add_event_cell(Vector2i(3, 5), "random_event")
	# 事件格 2：侧翼探索奖励
	board_manager.add_event_cell(Vector2i(6, 3), "random_event")
	# 事件格 3：玩家出发路线附近
	board_manager.add_event_cell(Vector2i(4, 6), "random_event")

## 单位进入格子后检查陷阱地形，触发 1 点伤害（陷阱适性单位免疫）
func _check_terrain_trap(unit_id: String, cell: Vector2i) -> void:
	if board_manager.get_terrain_type(cell) != "trap":
		return
	# 陷阱适性单位免疫陷阱伤害
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if String(unit.get("terrain_affinity", "")) == "trap":
		return
	var trap_damage: int = 1
	var killed: bool = unit_manager.apply_damage(unit_id, trap_damage)
	emit_signal("terrain_damage_triggered", unit_id, cell, trap_damage, "trap")
	if killed:
		_check_battle_outcome()

## 结束玩家回合：清空资源池，进入敌方回合。
func end_player_turn() -> void:
	if current_phase != BattlePhase.PLAYER_ACTION:
		return
	if is_battle_over():
		return
	dice_manager.reset_for_turn()
	_start_enemy_turn()

## 启动敌方回合：掷骰 -> 延迟 -> 执行敌方行动
func _start_enemy_turn() -> void:
	# 检查是否还有存活的敌方单位
	var enemy_units: Array[String] = battle_ai.get_enemy_units()
	if enemy_units.is_empty():
		# 没有敌方单位，直接推进到下一玩家回合
		_advance_to_next_player_round()
		return
	current_phase = BattlePhase.ENEMY_ROLL
	emit_signal("phase_changed", _phase_name(current_phase))
	dice_manager.roll_turn_dice()
	await get_tree().create_timer(0.8).timeout
	if is_battle_over():
		return
	_execute_enemy_actions()

## 获取单位显示名称（用于意图广播）
func _get_unit_display_name(unit_id: String) -> String:
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	var name: String = String(unit.get("display_name", ""))
	if name == "":
		name = unit_id
	return name

## 执行敌方行动：遍历每个敌方单位，尝试攻击或移动（含意图广播和加长停顿）
func _execute_enemy_actions() -> void:
	current_phase = BattlePhase.ENEMY_ACTION
	emit_signal("phase_changed", _phase_name(current_phase))
	var enemy_units: Array[String] = battle_ai.get_enemy_units()
	for uid in enemy_units:
		if is_battle_over():
			break
		var unit: Dictionary = unit_manager.get_unit(uid)
		if unit.is_empty():
			continue
		var cell: Vector2i = unit["cell"]
		var unit_name: String = _get_unit_display_name(uid)
		# 优先检查相邻是否有玩家单位可攻击
		var adjacent_players: Array[Vector2i] = battle_ai.get_adjacent_player_cells(cell)
		if adjacent_players.size() > 0 and dice_manager.can_pay({"attack": 1}):
			dice_manager.pay({"attack": 1})
			var target_cell: Vector2i = adjacent_players[0]
			var defender_id: String = String(unit_manager.units_by_cell[target_cell])
			var defender_name: String = _get_unit_display_name(defender_id)
			# 广播攻击意图，给玩家预读时间
			emit_signal("enemy_action_announced", uid, "attack", unit_name + " → 攻击 " + defender_name)
			await get_tree().create_timer(0.6).timeout
			if is_battle_over():
				break
			var defender: Dictionary = unit_manager.get_unit(defender_id)
			var damage: int = _calc_damage_with_terrain(unit, defender)
			var killed: bool = unit_manager.apply_damage(defender_id, damage)
			emit_signal("enemy_attack_completed", uid, defender_id, damage, killed, target_cell)
			_check_battle_outcome()
			await get_tree().create_timer(0.7).timeout
			continue
		# 没有相邻目标则朝最近玩家移动
		if dice_manager.can_pay({"move": 1}):
			var target_player_cell: Vector2i = battle_ai.find_nearest_player_cell(cell)
			if target_player_cell.x >= 0:
				var move_cell: Vector2i = battle_ai.pick_move_toward(cell, target_player_cell)
				if move_cell.x >= 0:
					# 广播移动意图
					emit_signal("enemy_action_announced", uid, "move", unit_name + " → 移动")
					await get_tree().create_timer(0.5).timeout
					if is_battle_over():
						break
					dice_manager.pay({"move": 1})
					unit_manager.move_unit(uid, move_cell)
					# 敌方移动后检查陷阱地形
					_check_terrain_trap(uid, move_cell)
					await get_tree().create_timer(0.6).timeout
					if is_battle_over():
						break
					# 如果该敌方单位已被陷阱击杀，跳过后续攻击
					if unit_manager.get_unit(uid).is_empty():
						continue
					# 移动后再检查是否进入攻击范围
					var new_adjacent: Array[Vector2i] = battle_ai.get_adjacent_player_cells(move_cell)
					if new_adjacent.size() > 0 and dice_manager.can_pay({"attack": 1}):
						dice_manager.pay({"attack": 1})
						var atk_target_cell: Vector2i = new_adjacent[0]
						var def_id: String = String(unit_manager.units_by_cell[atk_target_cell])
						var def_name: String = _get_unit_display_name(def_id)
						# 广播追击攻击意图
						var refreshed_unit: Dictionary = unit_manager.get_unit(uid)
						emit_signal("enemy_action_announced", uid, "attack", unit_name + " → 攻击 " + def_name)
						await get_tree().create_timer(0.6).timeout
						if is_battle_over():
							break
						var defender2: Dictionary = unit_manager.get_unit(def_id)
						var dmg: int = _calc_damage_with_terrain(refreshed_unit, defender2)
						var killed2: bool = unit_manager.apply_damage(def_id, dmg)
						emit_signal("enemy_attack_completed", uid, def_id, dmg, killed2, atk_target_cell)
						_check_battle_outcome()
						await get_tree().create_timer(0.7).timeout
	# 敌方回合结束
	if not is_battle_over():
		emit_signal("enemy_turn_ended")
		await get_tree().create_timer(0.5).timeout
		_advance_to_next_player_round()

## 推进到下一个玩家回合
func _advance_to_next_player_round() -> void:
	dice_manager.reset_for_turn()
	round_index += 1
	current_phase = BattlePhase.PLAYER_ROLL
	emit_signal("round_changed", round_index)
	emit_signal("phase_changed", _phase_name(current_phase))

func get_reachable_cells_for(unit_id: String) -> Array[Vector2i]:
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if unit.is_empty():
		var empty: Array[Vector2i] = []
		return empty
	# No highlights if no MOVE resource available
	var move_available: int = int(dice_manager.crest_pool.get("move", 0))
	if move_available <= 0:
		var empty: Array[Vector2i] = []
		return empty
	var cell: Vector2i = unit["cell"]
	var move_range: int = int(unit.get("move_range", 1))
	return board_manager.get_reachable_cells(cell, move_range)

## Attempt to move a player unit, paying 1 MOVE crest. Returns true on success.
func try_move_unit(unit_id: String, target_cell: Vector2i) -> bool:
	if is_battle_over():
		return false
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if unit.is_empty():
		return false
	if String(unit.get("owner", "")) != "player":
		return false
	# Verify target is reachable
	var reachable: Array[Vector2i] = get_reachable_cells_for(unit_id)
	var found: bool = false
	for rc in reachable:
		if rc == target_cell:
			found = true
			break
	if not found:
		return false
	# Pay 1 MOVE crest
	var cost: Dictionary = {"move": 1}
	if not dice_manager.can_pay(cost):
		return false
	dice_manager.pay(cost)
	var old_cell: Vector2i = unit["cell"]
	unit_manager.move_unit(unit_id, target_cell)
	emit_signal("move_completed", unit_id, old_cell, target_cell)
	# 检查陷阱地形
	_check_terrain_trap(unit_id, target_cell)
	# 检查道具拾取（单位存活时）
	if not unit_manager.get_unit(unit_id).is_empty():
		_check_item_pickup(unit_id, target_cell)
	# 检查恢复格（单位存活时）
	if not unit_manager.get_unit(unit_id).is_empty():
		_check_heal_cell(unit_id, target_cell)
	# 检查事件格（单位存活时）
	if not unit_manager.get_unit(unit_id).is_empty():
		_check_event_cell(unit_id, target_cell)
	# 检查遭遇格（单位存活时）
	if not unit_manager.get_unit(unit_id).is_empty():
		_check_encounter(unit_id, target_cell)
	return true

## Return attackable cells for a player unit. Empty if no ATTACK crest available.
func get_attackable_cells_for(unit_id: String) -> Array[Vector2i]:
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if unit.is_empty():
		var empty: Array[Vector2i] = []
		return empty
	var attack_available: int = int(dice_manager.crest_pool.get("attack", 0))
	if attack_available <= 0:
		var empty: Array[Vector2i] = []
		return empty
	return action_resolver.get_attackable_cells(unit_id)

## Attempt to attack a target at target_cell, paying 1 ATTACK crest. Returns true on success.
func try_attack_unit(attacker_id: String, target_cell: Vector2i) -> bool:
	if is_battle_over():
		return false
	var attacker: Dictionary = unit_manager.get_unit(attacker_id)
	if attacker.is_empty():
		return false
	if String(attacker.get("owner", "")) != "player":
		return false
	# Verify target cell is attackable
	var attackable: Array[Vector2i] = get_attackable_cells_for(attacker_id)
	var found: bool = false
	for ac in attackable:
		if ac == target_cell:
			found = true
			break
	if not found:
		return false
	# Identify defender
	if not unit_manager.units_by_cell.has(target_cell):
		return false
	var defender_id: String = String(unit_manager.units_by_cell[target_cell])
	# Pay 1 ATTACK crest
	var cost: Dictionary = {"attack": 1}
	if not dice_manager.can_pay(cost):
		return false
	dice_manager.pay(cost)
	# Calculate damage and apply (含地形适性加成)
	var defender: Dictionary = unit_manager.get_unit(defender_id)
	var damage: int = _calc_damage_with_terrain(attacker, defender)
	var killed: bool = unit_manager.apply_damage(defender_id, damage)
	emit_signal("attack_completed", attacker_id, defender_id, damage, killed)
	# Check for battle end after attack
	_check_battle_outcome()
	return true

func _check_battle_outcome() -> void:
	var outcome: String = VictoryRuleHelper.get_battle_outcome(unit_manager)
	if outcome == "VICTORY":
		mark_victory()
	elif outcome == "DEFEAT" or outcome == "DRAW":
		mark_defeat()

## 计算含地形适性加成的伤害值
## 路径适性：防御方站在路径格上时 DEF +1
func _calc_damage_with_terrain(attacker: Dictionary, defender: Dictionary) -> int:
	var def_bonus: int = 0
	var defender_cell: Vector2i = defender.get("cell", Vector2i(-1, -1))
	if String(defender.get("terrain_affinity", "")) == "path":
		if board_manager.path_cells.has(defender_cell):
			def_bonus = 1
	var raw_attack: int = int(attacker.get("atk", 0))
	var raw_defense: int = int(defender.get("def", 0)) + def_bonus
	return max(1, raw_attack - raw_defense)

## 检查并执行道具拾取
func _check_item_pickup(unit_id: String, cell: Vector2i) -> void:
	if not board_manager.item_cells.has(cell):
		return
	var item_id: String = String(board_manager.item_cells[cell])
	board_manager.item_cells.erase(cell)
	var effect_text: String = _apply_item_effect(item_id, unit_id)
	emit_signal("item_picked_up", unit_id, item_id, effect_text, cell)
	board_manager.emit_signal("board_changed")

## 获取遭遇敌方数据（Day 9：卡牌战斗原型）
func get_encounter_enemy_data(encounter_id: String) -> Dictionary:
	match encounter_id:
		"encounter_01":
			return {"name": "异常哨兵", "hp": 6, "atk": 2}
		"encounter_02":
			return {"name": "赛博游魂", "hp": 4, "atk": 3}
	return {"name": "未知敌人", "hp": 4, "atk": 2}

## 检查遭遇格：玩家单位踩到遭遇格时触发遭遇，进入 ENCOUNTER 暂停状态
func _check_encounter(unit_id: String, cell: Vector2i) -> void:
	if not board_manager.encounter_cells.has(cell):
		return
	var encounter_id: String = String(board_manager.encounter_cells[cell])
	# 保存当前遭遇上下文（供 resolve_encounter 使用）
	_encounter_unit_id = unit_id
	_encounter_id = encounter_id
	_encounter_cell = cell
	# 进入 ENCOUNTER 暂停状态（棋盘禁止操作）
	current_phase = BattlePhase.ENCOUNTER
	emit_signal("phase_changed", _phase_name(current_phase))
	# 触发遭遇信号（UI 层用于显示反馈）
	emit_signal("encounter_triggered", unit_id, encounter_id, cell)
	# 触发卡牌战斗信号（Day 9）
	var enemy_data: Dictionary = get_encounter_enemy_data(encounter_id)
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	var p_hp: int = int(unit.get("hp", 1))
	var p_max_hp: int = int(unit.get("max_hp", 1))
	emit_signal("card_battle_started", encounter_id, enemy_data["name"], enemy_data["hp"], enemy_data["atk"], unit_id, p_hp, p_max_hp)

## 遭遇结算：根据卡牌战斗结果清除遭遇格，处理胜败后果，回到 PLAYER_ACTION
## victory=true：清除遭遇格，同步回复 HP
## victory=false：单位受 2 点惩罚伤害，遭遇格仍清除（原型不重复战斗）
func resolve_encounter(victory: bool = true, player_hp_remaining: int = -1) -> void:
	if current_phase != BattlePhase.ENCOUNTER:
		return
	var resolved_id: String = _encounter_id
	var resolved_cell: Vector2i = _encounter_cell
	var unit_id: String = _encounter_unit_id
	# 清除遭遇格（已完成的遭遇不再触发）
	board_manager.clear_encounter_cell(resolved_cell)
	# 处理战斗结果
	if victory:
		# 同步卡牌战斗后的 HP 到棋盘单位
		if player_hp_remaining >= 0:
			var unit: Dictionary = unit_manager.get_unit(unit_id)
			if not unit.is_empty():
				unit["hp"] = player_hp_remaining
				unit_manager.units_by_id[unit_id] = unit
				unit_manager.emit_signal("units_changed")
	else:
		# 败北惩罚：单位受 2 点伤害
		if player_hp_remaining >= 0:
			var unit: Dictionary = unit_manager.get_unit(unit_id)
			if not unit.is_empty():
				unit["hp"] = max(1, player_hp_remaining)
				unit_manager.units_by_id[unit_id] = unit
				unit_manager.emit_signal("units_changed")
		else:
			var killed: bool = unit_manager.apply_damage(unit_id, 2)
			if killed:
				_check_battle_outcome()
	# 清空遭遇上下文
	_encounter_unit_id = ""
	_encounter_id = ""
	_encounter_cell = Vector2i(-1, -1)
	# 发送卡牌战斗结束信号
	emit_signal("card_battle_ended", resolved_id, resolved_cell, victory, player_hp_remaining)
	# 回到玩家行动阶段
	current_phase = BattlePhase.PLAYER_ACTION
	emit_signal("encounter_resolved", resolved_id, resolved_cell)
	emit_signal("phase_changed", _phase_name(current_phase))

## 检查恢复格：玩家单位踩到恢复格时回复 HP（持久，不消失）
func _check_heal_cell(unit_id: String, cell: Vector2i) -> void:
	if not board_manager.heal_cells.has(cell):
		return
	var heal_amount: int = int(board_manager.heal_cells[cell])
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if unit.is_empty():
		return
	var current_hp: int = int(unit.get("hp", 0))
	var max_hp: int = int(unit.get("max_hp", 1))
	if current_hp >= max_hp:
		# 已满血，不触发回复
		return
	var actual_heal: int = min(heal_amount, max_hp - current_hp)
	unit["hp"] = current_hp + actual_heal
	unit_manager.units_by_id[unit_id] = unit
	unit_manager.emit_signal("units_changed")
	emit_signal("heal_cell_triggered", unit_id, cell, heal_amount, actual_heal)

## 检查事件格：玩家单位踩到事件格时触发随机效果（一次性，踩后消失）
func _check_event_cell(unit_id: String, cell: Vector2i) -> void:
	if not board_manager.event_cells.has(cell):
		return
	var event_id: String = String(board_manager.event_cells[cell])
	# 消耗事件格（一次性）
	board_manager.clear_event_cell(cell)
	# 随机决定效果（3 种可能）
	var roll: int = randi() % 3
	var effect_text: String = ""
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if unit.is_empty():
		return
	match roll:
		0:
			# 正面：回复 1 HP
			var current_hp: int = int(unit.get("hp", 0))
			var max_hp: int = int(unit.get("max_hp", 1))
			var actual_heal: int = min(1, max_hp - current_hp)
			if actual_heal > 0:
				unit["hp"] = current_hp + actual_heal
				unit_manager.units_by_id[unit_id] = unit
				unit_manager.emit_signal("units_changed")
			effect_text = "HP+1"
		1:
			# 正面：随机获得 1 crest
			var crest_types: Array[String] = ["move", "attack", "defend", "skill", "trick", "summon"]
			var picked: String = crest_types[randi() % crest_types.size()]
			var current: int = int(dice_manager.crest_pool.get(picked, 0))
			dice_manager.crest_pool[picked] = current + 1
			effect_text = picked.to_upper() + "+1"
		2:
			# 负面：受到 1 点伤害
			var killed: bool = unit_manager.apply_damage(unit_id, 1)
			effect_text = "HP-1"
			if killed:
				_check_battle_outcome()
	emit_signal("event_cell_triggered", unit_id, cell, event_id, effect_text)

## 执行道具效果并返回效果描述
func _apply_item_effect(item_id: String, unit_id: String) -> String:
	var context: Dictionary = {"unit_id": unit_id}
	var effect_id: String = ""
	# 从 item_id 映射到 effect_id
	match item_id:
		"patch_tea_cache":
			effect_id = "heal_and_cleanse"
		"overclock_bone":
			effect_id = "gain_move_and_attack_boost"
		"glitch_snack_box":
			effect_id = "random_crest_gain"
		_:
			return ""
	var result: Dictionary = ItemEffectLibrary.execute(effect_id, context)
	if not result.get("ok", false):
		return ""
	# 应用效果
	var effect: String = String(result.get("effect", ""))
	match effect:
		"heal_and_cleanse":
			var heal: int = int(result.get("heal", 0))
			var unit: Dictionary = unit_manager.get_unit(unit_id)
			if not unit.is_empty():
				var new_hp: int = min(int(unit.get("hp", 0)) + heal, int(unit.get("max_hp", 1)))
				unit["hp"] = new_hp
				unit_manager.units_by_id[unit_id] = unit
				unit_manager.emit_signal("units_changed")
			return "HP+" + str(heal)
		"gain_move_and_attack_boost":
			var crest_bonus: Dictionary = result.get("crest_bonus", {})
			for crest_type in crest_bonus.keys():
				var amount: int = int(crest_bonus[crest_type])
				var current: int = int(dice_manager.crest_pool.get(crest_type, 0))
				dice_manager.crest_pool[crest_type] = current + amount
			return "MOVE+1"
		"random_crest_gain":
			var crest_bonus: Dictionary = result.get("crest_bonus", {})
			var gained_type: String = ""
			for crest_type in crest_bonus.keys():
				var amount: int = int(crest_bonus[crest_type])
				var current: int = int(dice_manager.crest_pool.get(crest_type, 0))
				dice_manager.crest_pool[crest_type] = current + amount
				gained_type = String(crest_type)
			return gained_type.to_upper() + "+1"
	return ""

## 获取以指定单位为原点的可召唤格（空闲相邻格）。如果 SUMMON crest 不足返回空。
func get_summon_cells_for(unit_id: String) -> Array[Vector2i]:
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if unit.is_empty():
		var empty: Array[Vector2i] = []
		return empty
	var summon_available: int = int(dice_manager.crest_pool.get("summon", 0))
	if summon_available <= 0:
		var empty: Array[Vector2i] = []
		return empty
	var cell: Vector2i = unit["cell"]
	return board_manager.get_free_neighbors(cell)

## 尝试在指定格执行召唤：铺路 + 生成召唤单位。消耗 1 SUMMON crest。
func try_summon(origin_unit_id: String, target_cell: Vector2i) -> bool:
	if is_battle_over():
		return false
	if current_phase != BattlePhase.PLAYER_ACTION:
		return false
	var origin_unit: Dictionary = unit_manager.get_unit(origin_unit_id)
	if origin_unit.is_empty():
		return false
	if String(origin_unit.get("owner", "")) != "player":
		return false
	# 检查 target_cell 是否在可召唤范围内
	var summon_cells: Array[Vector2i] = get_summon_cells_for(origin_unit_id)
	var found: bool = false
	for sc in summon_cells:
		if sc == target_cell:
			found = true
			break
	if not found:
		return false
	# 支付 1 SUMMON crest
	var cost: Dictionary = {"summon": 1}
	if not dice_manager.can_pay(cost):
		return false
	dice_manager.pay(cost)
	# 铺路：target_cell 标记为玩家路径格
	board_manager.add_path_cell(target_cell, "player")
	# 尝试在 target_cell 的方向上再延伸 1 格路径
	var extended_paths: Array[Vector2i] = [target_cell]
	var ext_neighbors: Array[Vector2i] = board_manager.get_free_neighbors(target_cell)
	if ext_neighbors.size() > 0:
		# 选择距离原点更远的方向延伸
		var origin_cell: Vector2i = origin_unit["cell"]
		var best_ext: Vector2i = ext_neighbors[0]
		var best_dist: int = absi(ext_neighbors[0].x - origin_cell.x) + absi(ext_neighbors[0].y - origin_cell.y)
		for ext in ext_neighbors:
			var d: int = absi(ext.x - origin_cell.x) + absi(ext.y - origin_cell.y)
			if d > best_dist:
				best_dist = d
				best_ext = ext
		board_manager.add_path_cell(best_ext, "player")
		extended_paths.append(best_ext)
	# 在 target_cell 上生成召唤单位
	_summon_counter += 1
	var summon_id: String = "summoned_fox_" + str(_summon_counter)
	var summon_data: Dictionary = {
		"max_hp": 4,
		"atk": 2,
		"def": 0,
		"move_range": 2,
		"attack_range": 1,
		"owner": "player",
		"tags": ["summoned", "fox"],
	}
	unit_manager.spawn_unit(summon_id, summon_data, target_cell)
	emit_signal("summon_completed", summon_id, extended_paths, target_cell)
	return true

func _phase_name(phase: BattlePhase) -> String:
	match phase:
		BattlePhase.BOOT:
			return "BOOT"
		BattlePhase.PLAYER_ROLL:
			return "PLAYER_ROLL"
		BattlePhase.PLAYER_ACTION:
			return "PLAYER_ACTION"
		BattlePhase.ENCOUNTER:
			return "ENCOUNTER"
		BattlePhase.ENEMY_ROLL:
			return "ENEMY_ROLL"
		BattlePhase.ENEMY_ACTION:
			return "ENEMY_ACTION"
		BattlePhase.RESOLUTION:
			return "RESOLUTION"
		BattlePhase.VICTORY:
			return "VICTORY"
		BattlePhase.DEFEAT:
			return "DEFEAT"
	return "UNKNOWN"

## Restart the battle: clear all state and re-spawn units at initial positions.
func restart_battle() -> void:
	dice_manager.reset_for_battle()
	unit_manager.clear_all_units()
	board_manager.clear_board()
	board_manager.build_test_board(Vector2i(8, 8))
	_summon_counter = 0
	_encounter_unit_id = ""
	_encounter_id = ""
	_encounter_cell = Vector2i(-1, -1)
	_spawn_debug_units()
	_spawn_debug_terrain()
	_spawn_debug_items()
	_spawn_debug_encounters()
	_spawn_debug_heal_cells()
	_spawn_debug_event_cells()
	current_phase = BattlePhase.PLAYER_ROLL
	round_index = 1
	emit_signal("round_changed", round_index)
	emit_signal("phase_changed", _phase_name(current_phase))
