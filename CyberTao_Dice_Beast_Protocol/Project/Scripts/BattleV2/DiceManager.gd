extends Node
class_name DiceManager

signal dice_rolled(results: Array[String], crest_pool: Dictionary)

enum CrestType {
	SUMMON,
	MOVE,
	ATTACK,
	DEFEND,
	SKILL,
	TRICK,
}

const TURN_DICE_COUNT: int = 3
const DICE_FACE_DIR: String = "res://Data/Dice"
const DEFAULT_FACES: Array[String] = ["summon", "move", "attack", "defend", "skill", "trick"]

var last_roll_results: Array[String] = []
var last_roll_effects: Array[String] = []
var crest_pool: Dictionary = {
	"summon": 0,
	"move": 0,
	"attack": 0,
	"defend": 0,
	"skill": 0,
	"trick": 0,
}
var _faces_by_type: Dictionary = {}

func _ready() -> void:
	_load_face_data()

func roll_turn_dice() -> Array[String]:
	if _faces_by_type.is_empty():
		_load_face_data()
	last_roll_results.clear()
	last_roll_effects.clear()
	var possible_faces: Array[String] = _get_face_type_choices()
	var roll_context: Dictionary = {"attack_faces": 0}
	for _i in range(TURN_DICE_COUNT):
		var idx: int = randi() % possible_faces.size()
		var face_type: String = possible_faces[idx]
		last_roll_results.append(face_type)
		var face_data: DiceFaceData = _get_face_data(face_type)
		var crest_gain: int = 1
		if face_data != null:
			crest_gain = max(1, int(face_data.crest_value))
		_add_crest(face_type, crest_gain)
		if face_type == "attack":
			roll_context["attack_faces"] = int(roll_context.get("attack_faces", 0)) + 1
		_apply_roll_face_effect(face_type, face_data, roll_context)
	# Guarantee at least 1 MOVE per roll for prototype playability
	if int(crest_pool.get("move", 0)) <= 0:
		crest_pool["move"] = 1
		last_roll_effects.append("failsafe:+1 move")
	emit_signal("dice_rolled", last_roll_results.duplicate(), crest_pool.duplicate())
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
	last_roll_effects.clear()
	for key in crest_pool.keys():
		crest_pool[key] = 0

func reset_for_turn() -> void:
	last_roll_results.clear()
	last_roll_effects.clear()
	for key in crest_pool.keys():
		crest_pool[key] = 0

func _load_face_data() -> void:
	_faces_by_type.clear()
	var dir: DirAccess = DirAccess.open(DICE_FACE_DIR)
	if dir == null:
		return
	for fname in dir.get_files():
		if not fname.ends_with(".tres"):
			continue
		var path: String = DICE_FACE_DIR + "/" + fname
		var res: Resource = load(path)
		if not (res is DiceFaceData):
			continue
		var face_data: DiceFaceData = res as DiceFaceData
		var face_type: String = String(face_data.face_type)
		if face_type == "":
			continue
		if not _faces_by_type.has(face_type):
			_faces_by_type[face_type] = []
		(_faces_by_type[face_type] as Array).append(face_data)

func _get_face_type_choices() -> Array[String]:
	var result: Array[String] = []
	for face_type in _faces_by_type.keys():
		result.append(String(face_type))
	if result.is_empty():
		for face_type in DEFAULT_FACES:
			result.append(face_type)
	return result

func _get_face_data(face_type: String) -> DiceFaceData:
	if not _faces_by_type.has(face_type):
		return null
	var entries: Array = _faces_by_type[face_type]
	if entries.is_empty():
		return null
	return entries[randi() % entries.size()] as DiceFaceData

func _apply_roll_face_effect(face_type: String, face_data: DiceFaceData, roll_context: Dictionary) -> void:
	if face_data == null:
		return
	var effect_id: String = String(face_data.grants_effect_id)
	if effect_id == "":
		return
	match effect_id:
		"grant_move_bonus":
			_add_crest("move", 1)
			last_roll_effects.append(face_type + "->+1 move")
		"grant_trick_bonus":
			_add_crest("trick", 1)
			last_roll_effects.append(face_type + "->+1 trick")
		"grant_skill_bonus":
			_add_crest("skill", 1)
			last_roll_effects.append(face_type + "->+1 skill")
		"grant_defend_bonus":
			_add_crest("defend", 1)
			last_roll_effects.append(face_type + "->+1 defend")
		"grant_pressure_attack":
			var attack_faces: int = int(roll_context.get("attack_faces", 0))
			if attack_faces >= 2 and attack_faces % 2 == 0:
				_add_crest("attack", 1)
				last_roll_effects.append(face_type + "->combo +1 attack")
		"grant_random_crest":
			var pool: Array[String] = ["move", "attack", "skill"]
			var picked: String = pool[randi() % pool.size()]
			_add_crest(picked, 1)
			last_roll_effects.append(face_type + "->+1 " + picked)
		_:
			pass

func _add_crest(crest_type: String, amount: int) -> void:
	var next_val: int = int(crest_pool.get(crest_type, 0)) + amount
	crest_pool[crest_type] = max(0, next_val)
