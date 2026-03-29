extends Node
class_name AttackRuleHelper

static func calc_basic_damage(attacker: Dictionary, defender: Dictionary) -> int:
	var raw_attack: int = int(attacker.get("atk", 0))
	var raw_defense: int = int(defender.get("def", 0))
	return max(1, raw_attack - raw_defense)

static func is_melee_unit(unit: Dictionary) -> bool:
	return int(unit.get("attack_range", 1)) <= 1

static func can_attack(attacker: Dictionary, defender: Dictionary) -> bool:
	if attacker.is_empty() or defender.is_empty():
		return false
	if String(attacker.get("owner", "")) == String(defender.get("owner", "")):
		return false
	return int(attacker.get("hp", 0)) > 0 and int(defender.get("hp", 0)) > 0
