extends Node
class_name ItemEffectLibrary

static func execute(effect_id: String, context: Dictionary) -> Dictionary:
	match effect_id:
		"heal_and_cleanse":
			return _heal_and_cleanse(context)
		"gain_move_and_attack_boost":
			return _gain_move_and_attack_boost(context)
		"random_crest_gain":
			return _random_crest_gain(context)
		_:
			return {
				"ok": false,
				"reason": "unknown_item_effect",
			}

static func _heal_and_cleanse(context: Dictionary) -> Dictionary:
	var unit_id: String = String(context.get("unit_id", "unit"))
	return {
		"ok": true,
		"effect": "heal_and_cleanse",
		"heal": 2,
		"remove_negative_status": 1,
		"log": unit_id + " recovered with patch tea.",
	}

static func _gain_move_and_attack_boost(context: Dictionary) -> Dictionary:
	var unit_id: String = String(context.get("unit_id", "unit"))
	return {
		"ok": true,
		"effect": "gain_move_and_attack_boost",
		"crest_bonus": {
			"move": 1,
		},
		"temporary_attack_bonus": 1,
		"log": unit_id + " got overclocked by a bone pickup.",
	}

static func _random_crest_gain(context: Dictionary) -> Dictionary:
	var unit_id: String = String(context.get("unit_id", "unit"))
	var options: Array[String] = ["attack", "defend", "skill"]
	var picked: String = options[randi() % options.size()]
	return {
		"ok": true,
		"effect": "random_crest_gain",
		"crest_bonus": {
			picked: 1,
		},
		"log": unit_id + " opened a glitch snack box and gained " + picked + ".",
	}
