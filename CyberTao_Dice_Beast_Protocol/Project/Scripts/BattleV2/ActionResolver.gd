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

func try_pickup(cell: Vector2i, unit_id: String) -> bool:
	if board_manager == null or buff_manager == null:
		return false
	if not board_manager.item_cells.has(cell):
		return false
	var item_id: String = String(board_manager.item_cells[cell])
	buff_manager.apply_pickup(item_id, unit_id)
	board_manager.item_cells.erase(cell)
	return true
