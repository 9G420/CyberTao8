extends Panel
class_name SettingsPanel

signal settings_closed

var display_settings: Node = null
var audio_manager: Node = null
var resolution_option: OptionButton
var mode_option: OptionButton

var _bgm_slider: HSlider
var _sfx_slider: HSlider
var _bgm_toggle: CheckButton
var _sfx_toggle: CheckButton

func _ready() -> void:
	custom_minimum_size = Vector2(440, 520)
	size = Vector2(440, 520)
	pivot_offset = Vector2(220, 260)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build_ui()

func bind_display_settings(ds: Node) -> void:
	display_settings = ds
	_sync_from_settings()

func bind_audio_manager(am: Node) -> void:
	audio_manager = am
	_sync_audio_from_manager()

# --- UI Construction ---
func _build_ui() -> void:
	add_theme_stylebox_override("panel", CyberStyle.make_panel_bg(CyberStyle.BORDER_CYAN, 10))

	# --- 标题 ---
	var title := Label.new()
	title.text = "设置"
	title.position = Vector2(0, 14)
	title.size = Vector2(440, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", CyberStyle.TEXT_TITLE)
	add_child(title)

	var sep1 := ColorRect.new()
	sep1.position = Vector2(30, 48)
	sep1.size = Vector2(380, 1)
	sep1.color = Color(0.0, 0.7, 0.9, 0.2)
	sep1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep1)

	# --- 显示设置 ---
	var res_label := Label.new()
	res_label.text = "分辨率"
	res_label.position = Vector2(30, 60)
	res_label.size = Vector2(120, 28)
	res_label.add_theme_font_size_override("font_size", 15)
	res_label.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY)
	add_child(res_label)

	resolution_option = OptionButton.new()
	resolution_option.position = Vector2(170, 56)
	resolution_option.size = Vector2(230, 34)
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
	mode_option.position = Vector2(170, 104)
	mode_option.size = Vector2(230, 34)
	mode_option.add_item("窗口化", 0)
	mode_option.add_item("全屏", 1)
	mode_option.add_item("无边框窗口", 2)
	add_child(mode_option)

	# --- 音效设置 分隔 ---
	var audio_header := Label.new()
	audio_header.text = "音效设置"
	audio_header.position = Vector2(30, 158)
	audio_header.size = Vector2(380, 28)
	audio_header.add_theme_font_size_override("font_size", 17)
	audio_header.add_theme_color_override("font_color", CyberStyle.TEXT_TITLE)
	add_child(audio_header)

	var sep2 := ColorRect.new()
	sep2.position = Vector2(30, 186)
	sep2.size = Vector2(380, 1)
	sep2.color = Color(0.0, 0.7, 0.9, 0.2)
	sep2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep2)

	# BGM 音量
	var bgm_vol_label := Label.new()
	bgm_vol_label.text = "BGM 音量"
	bgm_vol_label.position = Vector2(30, 200)
	bgm_vol_label.size = Vector2(120, 28)
	bgm_vol_label.add_theme_font_size_override("font_size", 15)
	bgm_vol_label.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY)
	add_child(bgm_vol_label)

	_bgm_slider = HSlider.new()
	_bgm_slider.position = Vector2(170, 200)
	_bgm_slider.size = Vector2(230, 28)
	_bgm_slider.min_value = 0.0
	_bgm_slider.max_value = 100.0
	_bgm_slider.step = 1.0
	_bgm_slider.value = 18.0
	_style_slider(_bgm_slider)
	_bgm_slider.value_changed.connect(_on_bgm_slider_changed)
	add_child(_bgm_slider)

	# SFX 音量
	var sfx_vol_label := Label.new()
	sfx_vol_label.text = "SFX 音量"
	sfx_vol_label.position = Vector2(30, 244)
	sfx_vol_label.size = Vector2(120, 28)
	sfx_vol_label.add_theme_font_size_override("font_size", 15)
	sfx_vol_label.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY)
	add_child(sfx_vol_label)

	_sfx_slider = HSlider.new()
	_sfx_slider.position = Vector2(170, 244)
	_sfx_slider.size = Vector2(230, 28)
	_sfx_slider.min_value = 0.0
	_sfx_slider.max_value = 100.0
	_sfx_slider.step = 1.0
	_sfx_slider.value = 35.0
	_style_slider(_sfx_slider)
	_sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	add_child(_sfx_slider)

	# BGM 开关
	var bgm_tog_label := Label.new()
	bgm_tog_label.text = "BGM 开关"
	bgm_tog_label.position = Vector2(30, 290)
	bgm_tog_label.size = Vector2(120, 28)
	bgm_tog_label.add_theme_font_size_override("font_size", 15)
	bgm_tog_label.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY)
	add_child(bgm_tog_label)

	_bgm_toggle = CheckButton.new()
	_bgm_toggle.position = Vector2(170, 288)
	_bgm_toggle.size = Vector2(80, 32)
	_bgm_toggle.button_pressed = true
	_bgm_toggle.toggled.connect(_on_bgm_toggle_toggled)
	add_child(_bgm_toggle)

	# SFX 开关
	var sfx_tog_label := Label.new()
	sfx_tog_label.text = "SFX 开关"
	sfx_tog_label.position = Vector2(30, 334)
	sfx_tog_label.size = Vector2(120, 28)
	sfx_tog_label.add_theme_font_size_override("font_size", 15)
	sfx_tog_label.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY)
	add_child(sfx_tog_label)

	_sfx_toggle = CheckButton.new()
	_sfx_toggle.position = Vector2(170, 332)
	_sfx_toggle.size = Vector2(80, 32)
	_sfx_toggle.button_pressed = true
	_sfx_toggle.toggled.connect(_on_sfx_toggle_toggled)
	add_child(_sfx_toggle)

	# --- 按钮 ---
	var apply_btn := Button.new()
	apply_btn.text = "应用"
	apply_btn.position = Vector2(30, 395)
	apply_btn.size = Vector2(175, 40)
	apply_btn.add_theme_font_size_override("font_size", 14)
	apply_btn.pressed.connect(_on_apply_pressed)
	CyberStyle.style_button(apply_btn, "orange")
	add_child(apply_btn)

	var reset_btn := Button.new()
	reset_btn.text = "恢复默认"
	reset_btn.position = Vector2(230, 395)
	reset_btn.size = Vector2(175, 40)
	reset_btn.add_theme_font_size_override("font_size", 14)
	reset_btn.pressed.connect(_on_reset_pressed)
	CyberStyle.style_button(reset_btn, "cyan")
	add_child(reset_btn)

	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.position = Vector2(140, 455)
	close_btn.size = Vector2(160, 40)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(_on_close_pressed)
	CyberStyle.style_button(close_btn, "cyan")
	add_child(close_btn)

# --- Slider styling helper ---
func _style_slider(slider: HSlider) -> void:
	var track_sb := StyleBoxFlat.new()
	track_sb.bg_color = Color(0.08, 0.08, 0.16, 0.9)
	track_sb.border_color = CyberStyle.BORDER_CYAN
	track_sb.set_border_width_all(1)
	track_sb.set_corner_radius_all(3)
	track_sb.content_margin_top = 4
	track_sb.content_margin_bottom = 4
	slider.add_theme_stylebox_override("slider", track_sb)
	var grabber_sb := StyleBoxFlat.new()
	grabber_sb.bg_color = CyberStyle.ACCENT_CYAN
	grabber_sb.set_corner_radius_all(4)
	slider.add_theme_stylebox_override("grabber_area", grabber_sb)
	slider.add_theme_stylebox_override("grabber_area_highlight", grabber_sb)

# --- Sync helpers ---
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

func _sync_audio_from_manager() -> void:
	if audio_manager == null:
		return
	_bgm_slider.value = audio_manager.get_bgm_volume() * 100.0
	_sfx_slider.value = audio_manager.get_sfx_volume() * 100.0
	_bgm_toggle.button_pressed = audio_manager.is_bgm_enabled()
	_sfx_toggle.button_pressed = audio_manager.is_sfx_enabled()

# --- Signal callbacks ---
func _on_bgm_slider_changed(value: float) -> void:
	if audio_manager != null:
		audio_manager.set_bgm_volume(value / 100.0)

func _on_sfx_slider_changed(value: float) -> void:
	if audio_manager != null:
		audio_manager.set_sfx_volume(value / 100.0)

func _on_bgm_toggle_toggled(pressed: bool) -> void:
	if audio_manager != null:
		audio_manager.set_bgm_enabled(pressed)

func _on_sfx_toggle_toggled(pressed: bool) -> void:
	if audio_manager != null:
		audio_manager.set_sfx_enabled(pressed)

func _on_apply_pressed() -> void:
	if display_settings != null:
		var res_idx: int = resolution_option.selected
		if res_idx >= 0 and res_idx < display_settings.RESOLUTIONS.size():
			display_settings.current_resolution = display_settings.RESOLUTIONS[res_idx]
		display_settings.current_mode = mode_option.selected
		display_settings.apply_settings()
		display_settings.save_settings()
	if audio_manager != null:
		audio_manager.set_bgm_volume(_bgm_slider.value / 100.0)
		audio_manager.set_sfx_volume(_sfx_slider.value / 100.0)
		audio_manager.set_bgm_enabled(_bgm_toggle.button_pressed)
		audio_manager.set_sfx_enabled(_sfx_toggle.button_pressed)

func _on_reset_pressed() -> void:
	if display_settings != null:
		display_settings.reset_to_defaults()
		_sync_from_settings()
		display_settings.apply_settings()
		display_settings.save_settings()
	_bgm_slider.value = 18.0
	_sfx_slider.value = 35.0
	_bgm_toggle.button_pressed = true
	_sfx_toggle.button_pressed = true
	if audio_manager != null:
		audio_manager.set_bgm_volume(0.18)
		audio_manager.set_sfx_volume(0.35)
		audio_manager.set_bgm_enabled(true)
		audio_manager.set_sfx_enabled(true)

func _on_close_pressed() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITransitions.close(self)
	emit_signal("settings_closed")

func open() -> void:
	_sync_from_settings()
	_sync_audio_from_manager()
	mouse_filter = Control.MOUSE_FILTER_STOP
	UITransitions.popup(self)
