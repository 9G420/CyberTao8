extends Node
class_name VictoryRuleHelper

static func is_unit_alive(unit: Dictionary) -> bool:
	if unit.is_empty():
		return false
	return int(unit.get("hp", 0)) > 0

static func count_units_for_owner(unit_manager: Node, owner_id: String) -> int:
	if unit_manager == null:
		return 0
	var total: int = 0
	for unit_id in unit_manager.units_by_id.keys():
		var state: Dictionary = unit_manager.get_unit(String(unit_id))
		if state.is_empty():
			continue
		if String(state.get("owner", "")) != owner_id:
			continue
		if not is_unit_alive(state):
			continue
		total += 1
	return total

static func has_units_for_owner(unit_manager: Node, owner_id: String) -> bool:
	return count_units_for_owner(unit_manager, owner_id) > 0

static func get_battle_outcome(unit_manager: Node) -> String:
	var player_alive: bool = has_units_for_owner(unit_manager, "player")
	var enemy_alive: bool = has_units_for_owner(unit_manager, "enemy")
	if player_alive and enemy_alive:
		return ""
	if player_alive:
		return "VICTORY"
	if enemy_alive:
		return "DEFEAT"
	return "DRAW"

static func describe_unit_hp(unit: Dictionary) -> String:
	if unit.is_empty():
		return "-/-"
	return str(int(unit.get("hp", 0))) + "/" + str(int(unit.get("max_hp", 0)))
