extends Control

const BattleFlowController = preload("res://Scripts/BattleV2/BattleFlowController.gd")

var _battle_flow: BattleFlowController

func _ready() -> void:
	_build_debug_view()
	_battle_flow = BattleFlowController.new()
	add_child(_battle_flow)

func _build_debug_view() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.06, 0.1)
	add_child(bg)

	var title := Label.new()
	title.text = "CyberTao: Dice Beast Protocol"
	title.position = Vector2(0, 56)
	title.size = Vector2(1280, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.56, 0.26))
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Parallel rebuild scaffold active"
	subtitle.position = Vector2(0, 104)
	subtitle.size = Vector2(1280, 28)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.9, 0.86))
	add_child(subtitle)

	var info := RichTextLabel.new()
	info.position = Vector2(240, 180)
	info.size = Vector2(800, 260)
	info.bbcode_enabled = true
	info.fit_content = false
	info.scroll_active = false
	info.add_theme_font_size_override("normal_font_size", 18)
	info.append_text("[center]New project scaffold ready.[/center]\n")
	info.append_text("[center]- BattleV2 managers[/center]\n")
	info.append_text("[center]- Data resources[/center]\n")
	info.append_text("[center]- Future board combat prototype[/center]")
	add_child(info)
