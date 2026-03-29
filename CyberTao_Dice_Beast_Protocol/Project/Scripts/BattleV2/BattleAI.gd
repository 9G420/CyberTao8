extends Node
class_name BattleAI

var board_manager: Node
var unit_manager: Node
var action_resolver: Node

func plan_enemy_turn() -> Array[Dictionary]:
	return []

func pick_forward_move(unit_id: String, candidate_cells: Array[Vector2i]) -> Vector2i:
	if candidate_cells.is_empty():
		return Vector2i(-1, -1)
	return candidate_cells[0]
