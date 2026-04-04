extends Node
class_name CommandExecutor

var battle_flow: Node = null

func execute_chain(chain: Resource) -> Dictionary:
	var result: Dictionary = {
		"ok": true,
		"executed": 0,
		"failed_index": -1,
		"failed_type": "",
	}
	if chain == null or chain.commands.is_empty():
		return result
	for i in range(chain.commands.size()):
		var command: Resource = chain.commands[i]
		var ok: bool = await _execute_single(command)
		if not ok:
			result["ok"] = false
			result["failed_index"] = i
			result["failed_type"] = command.command_type if command != null else ""
			return result
		result["executed"] = int(result["executed"]) + 1
	return result

func _execute_single(command: Resource) -> bool:
	if command == null or battle_flow == null:
		return false
	var t: String = command.command_type
	match t:
		"move":
			if not battle_flow.has_method("validate_move") or not battle_flow.has_method("try_move_unit"):
				return false
			if not bool(battle_flow.validate_move(command.unit_id, command.target_cell)):
				return false
			await battle_flow.try_move_unit(command.unit_id, command.target_cell)
			return true
		"attack":
			if not battle_flow.has_method("try_attack_unit"):
				return false
			return bool(battle_flow.try_attack_unit(command.unit_id, command.target_cell))
		"summon":
			if not battle_flow.has_method("try_summon"):
				return false
			return bool(battle_flow.try_summon(command.unit_id, command.target_cell))
		"defend":
			if not battle_flow.has_method("try_use_defend_crest"):
				return false
			return bool(battle_flow.try_use_defend_crest(command.unit_id))
		"skill":
			if not battle_flow.has_method("try_use_skill_crest"):
				return false
			return bool(battle_flow.try_use_skill_crest(command.unit_id))
		"trick":
			if not battle_flow.has_method("try_use_trick_crest"):
				return false
			return bool(battle_flow.try_use_trick_crest())
		"wait":
			return true
	return false
