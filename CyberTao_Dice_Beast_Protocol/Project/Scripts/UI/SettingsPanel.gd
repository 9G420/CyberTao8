extends Panel
class_name SettingsPanel

signal settings_closed

var display_settings: Node = null
var resolution_option: OptionButton
var mode_option: OptionButton

func _ready() -> void:
	custom_minimum_size = Vector2(400, 320)
	size = Vector2(400, 320)
	pivot_offset = Vector2(200, 160)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build_ui()

func bind_display_settings(ds: Node) -> void:
	display_settings = ds
	_sync_from_settings()

func _build_ui() -> void:
	add_theme_stylebox_override("panel", CyberStyle.make_panel_bg(CyberStyle.BORDER_CYAN, 10))

	var title := Label.new()
	title.text = "显示设置"
	title.position = Vector2(0, 14)
	title.size = Vector2(400, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", CyberStyle.TEXT_TITLE)
	add_child(title)

	# 分隔线
	var sep := ColorRect.new()
	sep.position = Vector2(30, 48)
	sep.size = Vector2(340, 1)
	sep.color = Color(0.0, 0.7, 0.9, 0.2)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep)

	var res_label := Label.new()
	res_label.text = "分辨率"
	res_label.position = Vector2(30, 60)
	res_label.size = Vector2(120, 28)
	res_label.add_theme_font_size_override("font_size", 15)
	res_label.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY)
	add_child(res_label)

	resolution_option = OptionButton.new()
	resolution_option.position = Vector2(160, 56)
	resolution_option.size = Vector2(200, 34)
	resolution_option.add_item("1280 x 720", 0)
	resolution_option.add_item("1600 x 900", 1)
	resolution_option.add_item("1920 x 1080", 2)
	add_child(resolution_option)

	var mode_label := Label.new()
	mode_label.text = "窗口模式"
	mode_label.position = Vector2(30, 108)
	mode_label.size = Vector2(120, 28)
	mode_label.add_theme_font_size_override("font_size", 15)
	mode_label.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY)
	add_child(mode_label)

	mode_option = OptionButton.new()
	mode_option.position = Vector2(160, 104)
	mode_option.size = Vector2(200, 34)
	mode_option.add_item("窗口化", 0)
	mode_option.add_item("全屏", 1)
	mode_option.add_item("无边框窗口", 2)
	add_child(mode_option)

	var apply_btn := Button.new()
	apply_btn.text = "应用"
	apply_btn.position = Vector2(30, 170)
	apply_btn.size = Vector2(160, 40)
	apply_btn.add_theme_font_size_override("font_size", 14)
	apply_btn.pressed.connect(_on_apply_pressed)
	CyberStyle.style_button(apply_btn, "orange")
	add_child(apply_btn)

	var reset_btn := Button.new()
	reset_btn.text = "恢复默认"
	reset_btn.position = Vector2(210, 170)
	reset_btn.size = Vector2(160, 40)
	reset_btn.add_theme_font_size_override("font_size", 14)
	reset_btn.pressed.connect(_on_reset_pressed)
	CyberStyle.style_button(reset_btn, "cyan")
	add_child(reset_btn)

	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.position = Vector2(120, 230)
	close_btn.size = Vector2(160, 40)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(_on_close_pressed)
	CyberStyle.style_button(close_btn, "cyan")
	add_child(close_btn)

func _sync_from_settings() -> void:
	if display_settings == null:
		return
	var res: Vector2i = display_settings.current_resolution
	for i in range(display_settings.RESOLUTIONS.size()):
		var r: Vector2i = display_settings.RESOLUTIONS[i]
		if r.x == res.x and r.y == res.y:
			resolution_option.selected = i
			break
	mode_option.selected = int(display_settings.current_mode)

func _on_apply_pressed() -> void:
	if display_settings == null:
		return
	var res_idx: int = resolution_option.selected
	if res_idx >= 0 and res_idx < display_settings.RESOLUTIONS.size():
		display_settings.current_resolution = display_settings.RESOLUTIONS[res_idx]
	display_settings.current_mode = mode_option.selected
	display_settings.apply_settings()
	display_settings.save_settings()

func _on_reset_pressed() -> void:
	if display_settings == null:
		return
	display_settings.reset_to_defaults()
	_sync_from_settings()
	display_settings.apply_settings()
	display_settings.save_settings()

func _on_close_pressed() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITransitions.close(self)
	emit_signal("settings_closed")

func open() -> void:
	_sync_from_settings()
	mouse_filter = Control.MOUSE_FILTER_STOP
	UITransitions.popup(self)
