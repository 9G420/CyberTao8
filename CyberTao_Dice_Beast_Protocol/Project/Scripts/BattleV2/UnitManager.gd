extends Node
class_name UnitManager

signal units_changed
signal unit_moved(unit_id: String, from_cell: Vector2i, to_cell: Vector2i)

var units_by_id: Dictionary = {}
var units_by_cell: Dictionary = {}
var board_manager: Node = null

func spawn_unit(unit_id: String, payload: Dictionary, cell: Vector2i) -> void:
	var unit_state: Dictionary = {
		"id": unit_id,
		"cell": cell,
		"hp": int(payload.get("max_hp", 1)),
		"max_hp": int(payload.get("max_hp", 1)),
		"atk": int(payload.get("atk", 0)),
		"def": int(payload.get("def", 0)),
		"move_range": int(payload.get("move_range", 1)),
		"attack_range": int(payload.get("attack_range", 1)),
		"owner": String(payload.get("owner", "player")),
		"tags": payload.get("tags", []),
		"terrain_affinity": String(payload.get("terrain_affinity", "")),
		"display_name": String(payload.get("display_name", "")),
	}
	units_by_id[unit_id] = unit_state
	units_by_cell[cell] = unit_id
	if board_manager:
		board_manager.set_unit_cell(unit_id, cell)
	emit_signal("units_changed")

func move_unit(unit_id: String, target_cell: Vector2i) -> void:
	if not units_by_id.has(unit_id):
		return
	var state: Dictionary = units_by_id[unit_id]
	var old_cell: Vector2i = state["cell"]
	units_by_cell.erase(old_cell)
	if board_manager:
		board_manager.clear_unit_cell(old_cell)
	state["cell"] = target_cell
	units_by_id[unit_id] = state
	units_by_cell[target_cell] = unit_id
	if board_manager:
		board_manager.set_unit_cell(unit_id, target_cell)
	emit_signal("unit_moved", unit_id, old_cell, target_cell)
	emit_signal("units_changed")

func apply_damage(unit_id: String, amount: int) -> bool:
	if not units_by_id.has(unit_id):
		return false
	var state: Dictionary = units_by_id[unit_id]
	var next_hp: int = max(0, int(state["hp"]) - amount)
	state["hp"] = next_hp
	units_by_id[unit_id] = state
	if next_hp <= 0:
		despawn_unit(unit_id)
		return true
	emit_signal("units_changed")
	return false

func despawn_unit(unit_id: String) -> void:
	if not units_by_id.has(unit_id):
		return
	var state: Dictionary = units_by_id[unit_id]
	var old_cell: Vector2i = state["cell"]
	units_by_cell.erase(old_cell)
	if board_manager:
		board_manager.clear_unit_cell(old_cell)
	units_by_id.erase(unit_id)
	emit_signal("units_changed")

func get_unit(unit_id: String) -> Dictionary:
	return units_by_id.get(unit_id, {})

func get_player_units() -> Array[String]:
	var result: Array[String] = []
	for uid in units_by_id.keys():
		var state: Dictionary = units_by_id[uid]
		if String(state.get("owner", "")) == "player":
			result.append(String(uid))
	return result

func get_player_hero_units() -> Array[String]:
	var result: Array[String] = []
	for uid in units_by_id.keys():
		var unit_id: String = String(uid)
		if is_player_hero_unit(unit_id):
			result.append(unit_id)
	return result

func is_player_hero_unit(unit_id: String) -> bool:
	var unit: Dictionary = get_unit(unit_id)
	if unit.is_empty():
		return false
	if String(unit.get("owner", "")) != "player":
		return false
	return not is_summoned_unit(unit)

func is_summoned_unit(unit: Dictionary) -> bool:
	if unit.is_empty():
		return false
	var tags: Array = unit.get("tags", [])
	return tags.has("summoned")

func clear_all_units() -> void:
	units_by_id.clear()
	units_by_cell.clear()
	if board_manager:
		board_manager.occupied_cells.clear()
	emit_signal("units_changed")
