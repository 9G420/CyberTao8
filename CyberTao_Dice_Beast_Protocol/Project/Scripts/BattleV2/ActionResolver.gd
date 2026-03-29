extends Node
class_name ActionResolver

var board_manager: Node
var unit_manager: Node
var buff_manager: Node

func try_move(unit_id: String, target_cell: Vector2i) -> bool:
	if board_manager == null or unit_manager == null:
		return false
	if not board_manager.is_cell_free(target_cell):
		return false
	unit_manager.move_unit(unit_id, target_cell)
	return true

func try_attack(attacker_id: String, defender_id: String) -> bool:
	if unit_manager == null:
		return false
	var attacker: Dictionary = unit_manager.get_unit(attacker_id)
	var defender: Dictionary = unit_manager.get_unit(defender_id)
	if attacker.is_empty() or defender.is_empty():
		return false
	var attack_value: int = max(0, int(attacker.get("atk", 0)) - int(defender.get("def", 0)))
	if attack_value <= 0:
		attack_value = 1
	unit_manager.apply_damage(defender_id, attack_value)
	return true

func get_attackable_cells(unit_id: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if unit_manager == null or board_manager == null:
		return cells
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if unit.is_empty():
		return cells
	var origin: Vector2i = unit.get("cell", Vector2i(-1, -1))
	var attack_range: int = int(unit.get("attack_range", 1))
	# 高台加成：站在高台上攻击范围 +1
	if board_manager.get_terrain_type(origin) == "high_ground":
		attack_range += 1
	if attack_range <= 0:
		return cells
	var owner: String = String(unit.get("owner", "player"))
	for candidate in _cells_in_manhattan_range(origin, attack_range):
		if not board_manager.is_in_bounds(candidate):
			continue
		if not unit_manager.units_by_cell.has(candidate):
			continue
		var target_id: String = String(unit_manager.units_by_cell[candidate])
		var target_unit: Dictionary = unit_manager.get_unit(target_id)
		if target_unit.is_empty():
			continue
		if String(target_unit.get("owner", "")) == owner:
			continue
		cells.append(candidate)
	return cells

func _cells_in_manhattan_range(origin: Vector2i, attack_range: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in range(origin.x - attack_range, origin.x + attack_range + 1):
		for y in range(origin.y - attack_range, origin.y + attack_range + 1):
			var candidate := Vector2i(x, y)
			var distance: int = absi(candidate.x - origin.x) + absi(candidate.y - origin.y)
			if distance <= 0 or distance > attack_range:
				continue
			result.append(candidate)
	return result

func try_pickup(cell: Vector2i, unit_id: String) -> bool:
	if board_manager == null or buff_manager == null:
		return false
	if not board_manager.item_cells.has(cell):
		return false
	var item_id: String = String(board_manager.item_cells[cell])
	buff_manager.apply_pickup(item_id, unit_id)
	board_manager.item_cells.erase(cell)
	return true
