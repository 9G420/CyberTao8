extends Resource
class_name CombatCommand

@export var command_type: String = "wait"
@export var unit_id: String = ""
@export var target_cell: Vector2i = Vector2i(-1, -1)
@export var value: int = 1
@export var patches: Array[Resource] = []

func setup(next_type: String, next_unit_id: String, next_target_cell: Vector2i = Vector2i(-1, -1), next_value: int = 1) -> CombatCommand:
	command_type = next_type
	unit_id = next_unit_id
	target_cell = next_target_cell
	value = next_value
	return self
