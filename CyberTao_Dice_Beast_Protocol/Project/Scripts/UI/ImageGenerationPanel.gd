extends Panel
class_name ImageGenerationPanel

var _service = null

var _api_key_input: LineEdit
var _api_key_status: Label
var _prompt_input: TextEdit
var _size_option: OptionButton
var _quality_option: OptionButton
var _generate_button: Button
var _status_label: Label
var _output_path_label: Label
var _preview_rect: TextureRect

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(860, 560)
	size = Vector2(860, 560)
	pivot_offset = Vector2(430, 280)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()

func bind_service(next_service) -> void:
	_service = next_service
	if _service == null:
		return
	if not _service.generation_started.is_connected(_on_generation_started):
		_service.generation_started.connect(_on_generation_started)
	if not _service.generation_succeeded.is_connected(_on_generation_succeeded):
		_service.generation_succeeded.connect(_on_generation_succeeded)
	if not _service.generation_failed.is_connected(_on_generation_failed):
		_service.generation_failed.connect(_on_generation_failed)
	_sync_from_service()

func open() -> void:
	_sync_from_service()
	mouse_filter = Control.MOUSE_FILTER_STOP
	UITransitions.popup(self)

func close() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITransitions.close(self)

func is_open() -> bool:
	return visible

func _build_ui() -> void:
	add_theme_stylebox_override("panel", CyberStyle.make_panel_bg(CyberStyle.BORDER_CYAN, 12))

	var title := Label.new()
	title.text = "OpenAI 生图"
	title.position = Vector2(0, 16)
	title.size = Vector2(860, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", CyberStyle.TEXT_TITLE)
	add_child(title)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.position = Vector2(748, 16)
	close_button.size = Vector2(88, 30)
	close_button.add_theme_font_size_override("font_size", 12)
	close_button.pressed.connect(close)
	CyberStyle.style_button(close_button, "cyan")
	add_child(close_button)

	var key_label := Label.new()
	key_label.text = "API Key"
	key_label.position = Vector2(28, 64)
	key_label.size = Vector2(96, 24)
	key_label.add_theme_font_size_override("font_size", 14)
	key_label.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY)
	add_child(key_label)

	_api_key_input = LineEdit.new()
	_api_key_input.position = Vector2(120, 60)
	_api_key_input.size = Vector2(470, 32)
	_api_key_input.secret = true
	_api_key_input.placeholder_text = "sk-..."
	_style_text_input(_api_key_input)
	add_child(_api_key_input)

	var save_key_button := Button.new()
	save_key_button.text = "保存 Key"
	save_key_button.position = Vector2(604, 60)
	save_key_button.size = Vector2(108, 32)
	save_key_button.add_theme_font_size_override("font_size", 12)
	save_key_button.pressed.connect(_on_save_key_pressed)
	CyberStyle.style_button(save_key_button, "orange")
	add_child(save_key_button)

	var clear_key_button := Button.new()
	clear_key_button.text = "清空本机 Key"
	clear_key_button.position = Vector2(720, 60)
	clear_key_button.size = Vector2(116, 32)
	clear_key_button.add_theme_font_size_override("font_size", 12)
	clear_key_button.pressed.connect(_on_clear_key_pressed)
	CyberStyle.style_button(clear_key_button, "cyan")
	add_child(clear_key_button)

	_api_key_status = Label.new()
	_api_key_status.position = Vector2(120, 96)
	_api_key_status.size = Vector2(716, 22)
	_api_key_status.add_theme_font_size_override("font_size", 11)
	_api_key_status.add_theme_color_override("font_color", CyberStyle.TEXT_SECONDARY)
	add_child(_api_key_status)

	var prompt_label := Label.new()
	prompt_label.text = "Prompt"
	prompt_label.position = Vector2(28, 132)
	prompt_label.size = Vector2(96, 24)
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY)
	add_child(prompt_label)

	_prompt_input = TextEdit.new()
	_prompt_input.position = Vector2(28, 160)
	_prompt_input.size = Vector2(360, 180)
	_prompt_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_prompt_input.placeholder_text = "例如：赛博道士，霓虹骨骰，未来东方卡牌立绘，细节丰富。"
	_style_text_input(_prompt_input)
	add_child(_prompt_input)

	var size_label := Label.new()
	size_label.text = "尺寸"
	size_label.position = Vector2(28, 356)
	size_label.size = Vector2(48, 24)
	size_label.add_theme_font_size_override("font_size", 14)
	size_label.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY)
	add_child(size_label)

	_size_option = OptionButton.new()
	_size_option.position = Vector2(82, 352)
	_size_option.size = Vector2(150, 32)
	_style_option_button(_size_option)
	add_child(_size_option)

	var quality_label := Label.new()
	quality_label.text = "质量"
	quality_label.position = Vector2(248, 356)
	quality_label.size = Vector2(48, 24)
	quality_label.add_theme_font_size_override("font_size", 14)
	quality_label.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY)
	add_child(quality_label)

	_quality_option = OptionButton.new()
	_quality_option.position = Vector2(300, 352)
	_quality_option.size = Vector2(88, 32)
	_style_option_button(_quality_option)
	add_child(_quality_option)

	_generate_button = Button.new()
	_generate_button.text = "生成图片"
	_generate_button.position = Vector2(28, 400)
	_generate_button.size = Vector2(360, 40)
	_generate_button.add_theme_font_size_override("font_size", 14)
	_generate_button.pressed.connect(_on_generate_pressed)
	CyberStyle.style_button(_generate_button, "orange")
	add_child(_generate_button)

	_status_label = Label.new()
	_status_label.position = Vector2(28, 454)
	_status_label.size = Vector2(360, 44)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 12)
	_status_label.add_theme_color_override("font_color", CyberStyle.TEXT_SECONDARY)
	add_child(_status_label)

	_output_path_label = Label.new()
	_output_path_label.position = Vector2(28, 506)
	_output_path_label.size = Vector2(804, 38)
	_output_path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_output_path_label.add_theme_font_size_override("font_size", 11)
	_output_path_label.add_theme_color_override("font_color", CyberStyle.TEXT_MUTED)
	add_child(_output_path_label)

	var preview_title := Label.new()
	preview_title.text = "预览"
	preview_title.position = Vector2(436, 132)
	preview_title.size = Vector2(120, 24)
	preview_title.add_theme_font_size_override("font_size", 14)
	preview_title.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY)
	add_child(preview_title)

	var preview_frame := Panel.new()
	preview_frame.position = Vector2(436, 160)
	preview_frame.size = Vector2(396, 316)
	preview_frame.add_theme_stylebox_override("panel", CyberStyle.make_panel_bg(CyberStyle.BORDER_ORANGE, 8))
	add_child(preview_frame)

	_preview_rect = TextureRect.new()
	_preview_rect.position = Vector2(12, 12)
	_preview_rect.size = Vector2(372, 292)
	_preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_frame.add_child(_preview_rect)

	var note_label := Label.new()
	note_label.text = "图片会保存到 user://generated_images，下次启动仍可复用本机保存的 Key。"
	note_label.position = Vector2(436, 486)
	note_label.size = Vector2(396, 44)
	note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_label.add_theme_font_size_override("font_size", 11)
	note_label.add_theme_color_override("font_color", CyberStyle.TEXT_SECONDARY)
	add_child(note_label)

func _sync_from_service() -> void:
	if _service == null:
		_api_key_status.text = "未绑定生图服务"
		return
	_rebuild_option_items(_size_option, _service.get_supported_sizes(), _service.default_size)
	_rebuild_option_items(_quality_option, _service.get_supported_qualities(), _service.default_quality)
	match _service.get_api_key_source():
		"saved":
			_api_key_status.text = "当前 Key 来源：本机已保存（%s）" % _service.get_masked_api_key()
		"env":
			_api_key_status.text = "当前 Key 来源：环境变量（%s）" % _service.get_masked_api_key()
		_:
			_api_key_status.text = "当前未配置 Key。可在这里保存，或使用 OPENAI_API_KEY 环境变量。"

func _style_text_input(control: Control) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.05, 0.10, 0.96)
	bg.border_color = CyberStyle.BORDER_CYAN
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(6)
	if control is LineEdit:
		var line_edit := control as LineEdit
		line_edit.add_theme_stylebox_override("normal", bg)
		line_edit.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY)
		line_edit.add_theme_color_override("font_placeholder_color", CyberStyle.TEXT_MUTED)
	elif control is TextEdit:
		var text_edit := control as TextEdit
		text_edit.add_theme_stylebox_override("normal", bg)
		text_edit.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY)

func _style_option_button(option: OptionButton) -> void:
	option.add_theme_stylebox_override("normal", CyberStyle.make_btn_normal())
	option.add_theme_stylebox_override("hover", CyberStyle.make_btn_hover())
	option.add_theme_stylebox_override("pressed", CyberStyle.make_btn_pressed())
	option.add_theme_stylebox_override("focus", CyberStyle.make_btn_hover())
	option.add_theme_color_override("font_color", CyberStyle.BTN_TEXT)

func _rebuild_option_items(option: OptionButton, items: Array[String], selected_text: String) -> void:
	option.clear()
	var selected_index: int = 0
	for i in range(items.size()):
		option.add_item(items[i], i)
		if items[i] == selected_text:
			selected_index = i
	option.selected = selected_index

func _selected_size() -> String:
	return _size_option.get_item_text(_size_option.selected)

func _selected_quality() -> String:
	return _quality_option.get_item_text(_quality_option.selected)

func _save_key_if_present(show_success: bool) -> bool:
	if _service == null:
		_set_status("生图服务未初始化。", true)
		return false
	var input_key: String = _api_key_input.text.strip_edges()
	if input_key == "":
		if not _service.has_api_key():
			_set_status("请先填写 OpenAI API Key。", true)
			return false
		return true
	var save_err: int = _service.set_api_key(input_key)
	_api_key_input.text = ""
	_sync_from_service()
	if save_err != OK:
		_set_status("Key 已应用，但本地保存失败: %s" % error_string(save_err), true)
		return true
	if show_success:
		_set_status("Key 已保存到本机配置。", false)
	return true

func _set_status(message: String, is_error: bool) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override(
		"font_color",
		CyberStyle.TEXT_WARN if is_error else CyberStyle.TEXT_SECONDARY
	)

func _on_save_key_pressed() -> void:
	_save_key_if_present(true)

func _on_clear_key_pressed() -> void:
	if _service == null:
		return
	var clear_err: int = _service.clear_saved_api_key()
	_sync_from_service()
	if clear_err != OK:
		_set_status("本机 Key 清空失败: %s" % error_string(clear_err), true)
		return
	_set_status("本机保存的 Key 已清空。", false)

func _on_generate_pressed() -> void:
	if _service == null:
		_set_status("生图服务未初始化。", true)
		return
	if not _save_key_if_present(false):
		return

	var save_defaults_err: int = _service.set_defaults(_selected_size(), _selected_quality())
	if save_defaults_err != OK:
		_set_status("参数已应用，但默认值保存失败: %s" % error_string(save_defaults_err), true)

	_generate_button.disabled = true
	var result: Dictionary = await _service.generate_image(
		_prompt_input.text,
		_selected_size(),
		_selected_quality()
	)
	_generate_button.disabled = false

	if bool(result.get("ok", false)):
		var texture := result.get("texture") as Texture2D
		_preview_rect.texture = texture
		_output_path_label.text = "输出文件：%s" % String(result.get("absolute_path", ""))
		var revised_prompt: String = String(result.get("revised_prompt", "")).strip_edges()
		if revised_prompt != "":
			_set_status("生成完成。模型润色后的提示词：%s" % revised_prompt, false)
		else:
			_set_status("生成完成。", false)
		return

	_set_status(String(result.get("error", "生成失败。")), true)

func _on_generation_started(_prompt: String, size: String, quality: String) -> void:
	_output_path_label.text = ""
	_set_status("正在生成 %s / %s 图片，请稍候..." % [size, quality], false)

func _on_generation_succeeded(_prompt: String, _save_path: String, absolute_path: String) -> void:
	_output_path_label.text = "输出文件：%s" % absolute_path

func _on_generation_failed(message: String) -> void:
	_set_status(message, true)
