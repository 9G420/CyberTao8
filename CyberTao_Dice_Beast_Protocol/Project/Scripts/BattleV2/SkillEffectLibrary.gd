extends Node
class_name SkillEffectLibrary

static func execute(effect_id: String, context: Dictionary) -> Dictionary:
	match effect_id:
		"my_blade_and_shield":
			return _my_blade_and_shield(context)
		"rough_counter":
			return _rough_counter(context)
		"ghost_shift":
			return _ghost_shift(context)
		"steal_signal":
			return _steal_signal(context)
		"direct_chop":
			return _direct_chop(context)
		"jam_burst":
			return _jam_burst(context)
		_:
			return {
				"ok": false,
				"reason": "unknown_effect",
			}

static func _my_blade_and_shield(context: Dictionary) -> Dictionary:
	var source_unit: Dictionary = context.get("source_unit", {})
	if source_unit.is_empty():
		return {
			"ok": false,
			"reason": "missing_source_unit",
		}
	return {
		"ok": true,
		"effect": "grant_guard",
		"shield_gain": 2,
		"retaliate_until_turn_end": true,
		"log": String(source_unit.get("id", "unit")) + " braced with blade and shield.",
	}

static func _rough_counter(context: Dictionary) -> Dictionary:
	var source_unit: Dictionary = context.get("source_unit", {})
	var target_unit: Dictionary = context.get("target_unit", {})
	if source_unit.is_empty() or target_unit.is_empty():
		return {
			"ok": false,
			"reason": "missing_target",
		}
	return {
		"ok": true,
		"effect": "counter_strike",
		"damage": 2,
		"push_cells": 1,
		"log": String(source_unit.get("id", "unit")) + " slammed back " + String(target_unit.get("id", "target")) + ".",
	}

static func _ghost_shift(context: Dictionary) -> Dictionary:
	var source_unit: Dictionary = context.get("source_unit", {})
	var target_cell: Vector2i = context.get("target_cell", Vector2i(-1, -1))
	if source_unit.is_empty():
		return {
			"ok": false,
			"reason": "missing_source_unit",
		}
	return {
		"ok": true,
		"effect": "ghost_shift",
		"spawn_path_at_origin": true,
		"target_cell": target_cell,
		"log": String(source_unit.get("id", "unit")) + " shifted through a ghost-link.",
	}

static func _steal_signal(context: Dictionary) -> Dictionary:
	var source_unit: Dictionary = context.get("source_unit", {})
	var target_unit: Dictionary = context.get("target_unit", {})
	if source_unit.is_empty() or target_unit.is_empty():
		return {
			"ok": false,
			"reason": "missing_target",
		}
	return {
		"ok": true,
		"effect": "steal_signal",
		"steal_random_crest": 1,
		"apply_status": {
			"type": "jammed",
			"value": 1,
			"turns": 1,
		},
		"log": String(source_unit.get("id", "unit")) + " disrupted " + String(target_unit.get("id", "target")) + ".",
	}

static func _direct_chop(context: Dictionary) -> Dictionary:
	var source_unit: Dictionary = context.get("source_unit", {})
	var target_unit: Dictionary = context.get("target_unit", {})
	if source_unit.is_empty() or target_unit.is_empty():
		return {
			"ok": false,
			"reason": "missing_target",
		}
	var bonus_damage: int = 1 if context.get("target_is_controlled", false) else 0
	return {
		"ok": true,
		"effect": "direct_chop",
		"damage": 2 + bonus_damage,
		"log": String(source_unit.get("id", "unit")) + " chopped into " + String(target_unit.get("id", "target")) + ".",
	}

static func _jam_burst(context: Dictionary) -> Dictionary:
	var source_unit: Dictionary = context.get("source_unit", {})
	var target_unit: Dictionary = context.get("target_unit", {})
	if source_unit.is_empty() or target_unit.is_empty():
		return {
			"ok": false,
			"reason": "missing_target",
		}
	return {
		"ok": true,
		"effect": "jam_burst",
		"damage": 1,
		"apply_status": {
			"type": "jammed",
			"value": 1,
			"turns": 1,
		},
		"log": String(source_unit.get("id", "unit")) + " triggered a jam burst on " + String(target_unit.get("id", "target")) + ".",
	}
