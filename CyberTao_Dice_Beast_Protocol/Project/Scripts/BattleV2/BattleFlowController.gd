extends Node
class_name BattleFlowController

signal setup_completed
signal phase_changed(phase_name: String)
signal move_completed(unit_id: String, from_cell: Vector2i, to_cell: Vector2i)
signal attack_completed(attacker_id: String, defender_id: String, damage: int, killed: bool)
signal round_changed(round_number: int)

const DiceManager = preload("res://Scripts/BattleV2/DiceManager.gd")
const BoardManager = preload("res://Scripts/BattleV2/BoardManager.gd")
const UnitManager = preload("res://Scripts/BattleV2/UnitManager.gd")
const ActionResolver = preload("res://Scripts/BattleV2/ActionResolver.gd")
const BuffManager = preload("res://Scripts/BattleV2/BuffManager.gd")
const BattleAI = preload("res://Scripts/BattleV2/BattleAI.gd")
const AttackRuleHelper = preload("res://Scripts/BattleV2/AttackRuleHelper.gd")
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
	current_phase = BattlePhase.PLAYER_ROLL
	round_index = 1
	emit_signal("setup_completed")
	emit_signal("phase_changed", _phase_name(current_phase))

func start_player_roll() -> void:
	if current_phase != BattlePhase.PLAYER_ROLL:
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
	unit_manager.spawn_unit("enemy_debug_grunt", enemy_data, Vector2i(7, 1))

## End the player's turn: clear crest pool, advance round, return to PLAYER_ROLL.
func end_player_turn() -> void:
	if current_phase != BattlePhase.PLAYER_ACTION:
		return
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
