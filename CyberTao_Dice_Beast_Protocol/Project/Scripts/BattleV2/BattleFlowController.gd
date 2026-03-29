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

const DiceManager = preload("res://Scripts/BattleV2/DiceManager.gd")
const BoardManager = preload("res://Scripts/BattleV2/BoardManager.gd")
const UnitManager = preload("res://Scripts/BattleV2/UnitManager.gd")
const ActionResolver = preload("res://Scripts/BattleV2/ActionResolver.gd")
const BuffManager = preload("res://Scripts/BattleV2/BuffManager.gd")
const BattleAI = preload("res://Scripts/BattleV2/BattleAI.gd")
const AttackRuleHelper = preload("res://Scripts/BattleV2/AttackRuleHelper.gd")
const VictoryRuleHelper = preload("res://Scripts/BattleV2/VictoryRuleHelper.gd")
const UnitData = preload("res://Scripts/Data/UnitData.gd")

enum BattlePhase {
	BOOT,
	PLAYER_ROLL,
	PLAYER_ACTION,
	ENEMY_ROLL,
	ENEMY_ACTION,
	RESOLUTION,
	VICTORY,
	DEFEAT,
}

var current_phase: BattlePhase = BattlePhase.BOOT
var round_index: int = 0
var _summon_counter: int = 0

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
		}, Vector2i(0, 6))
	var enemy_data := {
		"max_hp": 5,
		"atk": 2,
		"def": 0,
		"move_range": 1,
		"attack_range": 1,
		"owner": "enemy",
		"tags": ["grunt"],
	}
	unit_manager.spawn_unit("enemy_debug_grunt", enemy_data, Vector2i(3, 4))

## 放置调试用地形格
func _spawn_debug_terrain() -> void:
	# 高台格：棋盘中部偏上，2 格
	board_manager.add_terrain_cell(Vector2i(2, 4), "high_ground")
	board_manager.add_terrain_cell(Vector2i(2, 5), "high_ground")
	# 陷阱格：玩家前进路线上，2 格
	board_manager.add_terrain_cell(Vector2i(1, 5), "trap")
	board_manager.add_terrain_cell(Vector2i(3, 6), "trap")

## 单位进入格子后检查陷阱地形，触发 1 点伤害
func _check_terrain_trap(unit_id: String, cell: Vector2i) -> void:
	if board_manager.get_terrain_type(cell) != "trap":
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
	await get_tree().create_timer(0.5).timeout
	if is_battle_over():
		return
	_execute_enemy_actions()

## 执行敌方行动：遍历每个敌方单位，尝试攻击或移动
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
		# 优先检查相邻是否有玩家单位可攻击
		var adjacent_players: Array[Vector2i] = battle_ai.get_adjacent_player_cells(cell)
		if adjacent_players.size() > 0 and dice_manager.can_pay({"attack": 1}):
			dice_manager.pay({"attack": 1})
			var target_cell: Vector2i = adjacent_players[0]
			var defender_id: String = String(unit_manager.units_by_cell[target_cell])
			var defender: Dictionary = unit_manager.get_unit(defender_id)
			var damage: int = AttackRuleHelper.calc_basic_damage(unit, defender)
			var killed: bool = unit_manager.apply_damage(defender_id, damage)
			emit_signal("enemy_attack_completed", uid, defender_id, damage, killed, target_cell)
			_check_battle_outcome()
			await get_tree().create_timer(0.4).timeout
			continue
		# 没有相邻目标则朝最近玩家移动
		if dice_manager.can_pay({"move": 1}):
			var target_player_cell: Vector2i = battle_ai.find_nearest_player_cell(cell)
			if target_player_cell.x >= 0:
				var move_cell: Vector2i = battle_ai.pick_move_toward(cell, target_player_cell)
				if move_cell.x >= 0:
					dice_manager.pay({"move": 1})
					unit_manager.move_unit(uid, move_cell)
					# 敌方移动后检查陷阱地形
					_check_terrain_trap(uid, move_cell)
					await get_tree().create_timer(0.3).timeout
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
						var refreshed_unit: Dictionary = unit_manager.get_unit(uid)
						var defender2: Dictionary = unit_manager.get_unit(def_id)
						var dmg: int = AttackRuleHelper.calc_basic_damage(refreshed_unit, defender2)
						var killed2: bool = unit_manager.apply_damage(def_id, dmg)
						emit_signal("enemy_attack_completed", uid, def_id, dmg, killed2, atk_target_cell)
						_check_battle_outcome()
						await get_tree().create_timer(0.4).timeout
	# 敌方回合结束，推进到下一玩家回合
	if not is_battle_over():
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
	# Calculate damage and apply
	var defender: Dictionary = unit_manager.get_unit(defender_id)
	var damage: int = AttackRuleHelper.calc_basic_damage(attacker, defender)
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
	_spawn_debug_units()
	_spawn_debug_terrain()
	current_phase = BattlePhase.PLAYER_ROLL
	round_index = 1
	emit_signal("round_changed", round_index)
	emit_signal("phase_changed", _phase_name(current_phase))
