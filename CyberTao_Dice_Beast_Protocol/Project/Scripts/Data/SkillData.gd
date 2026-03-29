extends Resource
class_name SkillData

@export var skill_id: String = ""
@export var skill_name: String = ""
@export_multiline var description: String = ""
@export var crest_cost: Dictionary = {}
@export var target_type: String = "enemy"
@export var target_pattern: String = "single"
@export var cast_range: int = 1
@export var effect_script_id: String = ""
@export var cooldown: int = 0
@export var consumes_action: bool = true
@export var once_per_turn: bool = false
@export var required_traits: Array[String] = []
