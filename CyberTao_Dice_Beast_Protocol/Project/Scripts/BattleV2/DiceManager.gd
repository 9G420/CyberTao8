extends Node
class_name DiceManager

enum CrestType {
	SUMMON,
	MOVE,
	ATTACK,
	DEFEND,
	SKILL,
	TRICK,
}

const TURN_DICE_COUNT: int = 3

var last_roll_results: Array[String] = []
var crest_pool: Dictionary = {
	"summon": 0,
	"move": 0,
	"attack": 0,
	"defend": 0,
	"skill": 0,
	"trick": 0,
}

func roll_turn_dice() -> Array[String]:
	last_roll_results.clear()
	var possible_faces: Array[String] = ["summon", "move", "attack", "defend", "skill", "trick"]
	for _i in range(TURN_DICE_COUNT):
		var idx: int = randi() % possible_faces.size()
		var face: String = possible_faces[idx]
		last_roll_results.append(face)
		crest_pool[face] = int(crest_pool.get(face, 0)) + 1
	return last_roll_results

func can_pay(costs: Dictionary) -> bool:
	for key in costs.keys():
		var current: int = int(crest_pool.get(key, 0))
		var required: int = int(costs[key])
		if current < required:
			return false
	return true

func pay(costs: Dictionary) -> bool:
	if not can_pay(costs):
		return false
	for key in costs.keys():
		crest_pool[key] = int(crest_pool.get(key, 0)) - int(costs[key])
	return true

func reset_for_battle() -> void:
	last_roll_results.clear()
	for key in crest_pool.keys():
		crest_pool[key] = 0
