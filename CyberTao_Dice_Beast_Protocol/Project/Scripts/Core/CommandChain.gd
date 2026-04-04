extends Resource
class_name CommandChain

@export var commands: Array[Resource] = []

func clear_chain() -> void:
	commands.clear()

func add_command(command: Resource) -> void:
	if command == null:
		return
	commands.append(command)

func is_empty() -> bool:
	return commands.is_empty()
