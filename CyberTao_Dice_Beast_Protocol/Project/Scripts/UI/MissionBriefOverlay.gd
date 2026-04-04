extends CanvasLayer
class_name MissionBriefOverlay

var _root: ColorRect
var _panel: Panel
var _tag_label: Label
var _title_label: Label
var _subtitle_label: Label
var _body_label: Label
var _footer_label: Label
var _confirm_button: Button
var _is_open: bool = false

func _init() -> void:
	layer = 20

func _ready() -> void:
	_root = ColorRect.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.color = Color(0.01, 0.02, 0.05, 0.88)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.visible = false
	add_child(_root)

	_panel = Panel.new()
	_panel.position = Vector2(220, 110)
	_panel.size = Vector2(840, 500)
	_panel.add_theme_stylebox_override("panel", CyberStyle.make_panel_bg())
	_root.add_child(_panel)

	_tag_label = _make_label(Vector2(36, 28), Vector2(768, 28), 15, CyberStyle.ACCENT_ORANGE)
	_panel.add_child(_tag_label)

	_title_label = _make_label(Vector2(36, 64), Vector2(768, 46), 30, CyberStyle.TEXT_PRIMARY)
	_panel.add_child(_title_label)

	_subtitle_label = _make_label(Vector2(36, 118), Vector2(768, 30), 16, CyberStyle.ACCENT_CYAN)
	_panel.add_child(_subtitle_label)

	_body_label = _make_label(Vector2(36, 176), Vector2(768, 180), 18, CyberStyle.TEXT_PRIMARY)
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_panel.add_child(_body_label)

	_footer_label = _make_label(Vector2(36, 382), Vector2(768, 56), 14, CyberStyle.TEXT_SECONDARY)
	_footer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_footer_label)

	_confirm_button = Button.new()
	_confirm_button.position = Vector2(624, 444)
	_confirm_button.size = Vector2(180, 36)
	_confirm_button.text = "继续"
	_confirm_button.add_theme_font_size_override("font_size", 15)
	_confirm_button.pressed.connect(_close_overlay)
	CyberStyle.style_button(_confirm_button, "cyan")
	_panel.add_child(_confirm_button)

func show_briefing(tag_text: String, title_text: String, subtitle_text: String, body_text: String, footer_text: String, button_text: String = "继续") -> void:
	_tag_label.text = tag_text
	_title_label.text = title_text
	_subtitle_label.text = subtitle_text
	_body_label.text = body_text
	_footer_label.text = footer_text
	_confirm_button.text = button_text
	_root.visible = true
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_is_open = true

func is_open() -> bool:
	return _is_open

func _close_overlay() -> void:
	_root.visible = false
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_open = false

func _make_label(pos: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
