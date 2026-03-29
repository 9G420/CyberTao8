extends Node
class_name UnitManager

var units_by_id: Dictionary = {}
var units_by_cell: Dictionary = {}

func spawn_unit(unit_id: String, payload: Dictionary, cell: Vector2i) -> void:
	var unit_state: Dictionary = {
		"id": unit_id,
		"cell": cell,
		"hp": int(payload.get("max_hp", 1)),
		"max_hp": int(payload.get("max_hp", 1)),
		"atk": int(payload.get("atk", 0)),
		"def": int(payload.get("def", 0)),
		"owner": String(payload.get("owner", "player")),
		"tags": payload.get("tags", []),
	}
	units_by_id[unit_id] = unit_state
	units_by_cell[cell] = unit_id

func move_unit(unit_id: String, target_cell: Vector2i) -> void:
	if not units_by_id.has(unit_id):
		return
	var state: Dictionary = units_by_id[unit_id]
	var old_cell: Vector2i = state["cell"]
	units_by_cell.erase(old_cell)
	state["cell"] = target_cell
	units_by_id[unit_id] = state
	units_by_cell[target_cell] = unit_id

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
	return false

func despawn_unit(unit_id: String) -> void:
	if not units_by_id.has(unit_id):
		return
	var state: Dictionary = units_by_id[unit_id]
	var old_cell: Vector2i = state["cell"]
	units_by_cell.erase(old_cell)
	units_by_id.erase(unit_id)

func get_unit(unit_id: String) -> Dictionary:
	return units_by_id.get(unit_id, {})
