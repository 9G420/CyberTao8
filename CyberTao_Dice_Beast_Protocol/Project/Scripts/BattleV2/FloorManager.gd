extends Node
class_name FloorManager

const UnitData = preload("res://Scripts/Data/UnitData.gd")
const BoardGenerator = preload("res://Scripts/BattleV2/BoardGenerator.gd")
const VictoryRuleHelper = preload("res://Scripts/BattleV2/VictoryRuleHelper.gd")

const MAX_FLOOR: int = 3
const REVIVE_HP_RATIO: float = 0.5
const FLOOR_HEAL_RATIO: float = 0.3
const PLAYER_UNIT_SPAWNS: Array[Dictionary] = [
	{"path": "res://Data/Units/blade_shield_dog.tres", "cell": Vector2i(0, 10)},
	{"path": "res://Data/Units/hacker_fox.tres", "cell": Vector2i(1, 11)},
]

var dice_manager: Node = null
var board_manager: Node = null
var unit_manager: Node = null
var buff_manager: Node = null

var current_floor: int = 1

func snapshot_player_hp() -> Dictionary:
	var snapshot: Dictionary = {}
	var player_ids: Array[String] = unit_manager.get_player_units()
	for uid in player_ids:
		var unit: Dictionary = unit_manager.get_unit(uid)
		if unit.is_empty() or int(unit.get("hp", 0)) <= 0:
			continue
		var tags: Array = unit.get("tags", [])
		if tags.has("summoned"):
			continue
		snapshot[uid] = {"hp": int(unit["hp"]), "max_hp": int(unit["max_hp"]), "alive": true}
	return snapshot

func advance_floor(board_size: Vector2i, summon_counter_reset: Callable) -> int:
	var hp_snapshot: Dictionary = snapshot_player_hp()
	dice_manager.reset_for_battle()
	buff_manager.clear_all()
	unit_manager.clear_all_units()
	board_manager.clear_board()
	board_manager.build_test_board(board_size)
	summon_counter_reset.call()
	current_floor += 1
	_spawn_player_units_with_hp(hp_snapshot)
	BoardGenerator.generate_board(board_manager, unit_manager, board_size, current_floor)
	return current_floor

func spawn_initial_player_units() -> void:
	for entry in PLAYER_UNIT_SPAWNS:
		var cell: Vector2i = entry["cell"]
		_spawn_player_unit_from_path(String(entry["path"]), cell)

func _spawn_player_units_with_hp(hp_snapshot: Dictionary) -> void:
	for entry in PLAYER_UNIT_SPAWNS:
		var data := load(String(entry["path"])) as UnitData
		if data == null:
			continue
		var spawn_hp: int = data.max_hp
		var spawn_max_hp: int = data.max_hp
		if hp_snapshot.has(data.unit_id):
			var saved: Dictionary = hp_snapshot[data.unit_id]
			spawn_max_hp = int(saved["max_hp"])
			var heal_amount: int = int(ceil(float(spawn_max_hp) * FLOOR_HEAL_RATIO))
			spawn_hp = mini(int(saved["hp"]) + heal_amount, spawn_max_hp)
		else:
			spawn_hp = maxi(int(ceil(float(spawn_max_hp) * REVIVE_HP_RATIO)), 1)
		var cell: Vector2i = entry["cell"]
		_spawn_player_unit(data, cell, spawn_max_hp, spawn_hp)

func _spawn_player_unit_from_path(res_path: String, cell: Vector2i) -> void:
	var data := load(res_path) as UnitData
	if data == null:
		return
	_spawn_player_unit(data, cell)

func _spawn_player_unit(data: UnitData, cell: Vector2i, spawn_max_hp: int = -1, spawn_hp: int = -1) -> void:
	var next_max_hp: int = data.max_hp if spawn_max_hp < 0 else spawn_max_hp
	unit_manager.spawn_unit(data.unit_id, {
		"max_hp": next_max_hp,
		"atk": data.atk,
		"def": data.def,
		"move_range": data.move_range,
		"attack_range": data.attack_range,
		"owner": "player",
		"tags": data.meme_tags,
		"terrain_affinity": data.terrain_affinity,
		"display_name": data.unit_name,
	}, cell)
	if spawn_hp < 0 or spawn_hp == next_max_hp:
		return
	var unit: Dictionary = unit_manager.get_unit(data.unit_id)
	if unit.is_empty():
		return
	unit["hp"] = clampi(spawn_hp, 0, next_max_hp)
	unit_manager.units_by_id[data.unit_id] = unit
	unit_manager.emit_signal("units_changed")

func get_current_floor() -> int:
	return current_floor

func get_max_floor() -> int:
	return MAX_FLOOR

func reset_floor() -> void:
	current_floor = 1

func try_unlock_boss() -> Array[Vector2i]:
	var cells_to_unlock: Array[Vector2i] = []
	for cell in board_manager.locked_encounters.keys():
		cells_to_unlock.append(cell)
	for cell in cells_to_unlock:
		board_manager.unlock_encounter(cell)
	return cells_to_unlock

func warp_hero_to_boss(boss_cell: Vector2i) -> Dictionary:
	var hero_id: String = ""
	for uid in unit_manager.units_by_id.keys():
		var u: Dictionary = unit_manager.get_unit(String(uid))
		if String(u.get("owner", "")) != "player":
			continue
		var tags: Array = u.get("tags", [])
		if not tags.has("summoned"):
			hero_id = String(uid)
			break
	if hero_id == "":
		return {}
	var dirs: Array[Vector2i] = [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]
	for dir in dirs:
		var adj: Vector2i = boss_cell + dir
		if adj.x < 0 or adj.x >= board_manager.board_size.x or adj.y < 0 or adj.y >= board_manager.board_size.y:
			continue
		if board_manager.occupied_cells.has(adj):
			continue
		unit_manager.move_unit(hero_id, adj)
		return {"hero_id": hero_id, "target_cell": adj}
	return {}

func spawn_portal_near(cell: Vector2i) -> Vector2i:
	var candidates: Array[Vector2i] = [
		cell + Vector2i(0, 1),
		cell + Vector2i(1, 0),
		cell + Vector2i(-1, 0),
		cell + Vector2i(0, -1),
	]
	for c in candidates:
		if board_manager.is_in_bounds(c) and not board_manager.occupied_cells.has(c):
			board_manager.add_portal_cell(c)
			return c
	board_manager.add_portal_cell(cell)
	return cell

func check_portal(unit_id: String, cell: Vector2i) -> Dictionary:
	if not board_manager.portal_cells.has(cell):
		return {}
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if unit.is_empty() or String(unit.get("owner", "")) != "player":
		return {}
	board_manager.clear_portal_cell(cell)
	if current_floor < MAX_FLOOR:
		return {"action": "floor_clear"}
	return {"action": "game_won"}
