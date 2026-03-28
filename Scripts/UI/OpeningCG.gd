# ============================================================
# OpeningCG.gd - 开场CG（30-45秒，可跳过）
# 文字+简单动画+道教钟声+赛博掉码音效
# Enhanced: EVA colored code rain, glitch shader on ERROR lines,
#           EVA color flashes, circuit board bg, CRT overlay,
#           static noise on drama, better text color transitions
# ============================================================
extends Control

var lines: Array[Dictionary] = []
var current_line: int = 0
var char_index: int = 0
var char_timer: float = 0.0
var line_timer: float = 0.0
var typing_speed: float = 0.04  # 每字符间隔
var line_pause_base: float = 1.5  # 行间停顿基准（可供外部调整）

var text_label: RichTextLabel
var skip_label: Label
var bg_rect: ColorRect
var screen_flash: ColorRect
var code_rain_labels: Array[Label] = []
var is_finished := false
var glitch_overlay: ColorRect
var static_noise_labels: Array[Label] = []
var drama_intensity: float = 0.0

func _ready() -> void:
	_init_story_lines()
	_build_ui()
	_start_code_rain()
	_create_static_noise()
	AudioManager.play_bgm_generated("opening", -6.0)

func _init_story_lines() -> void:
	lines = [
		{"text": "「系统加载中...」", "color": "cyan", "delay": 0.8},
		{"text": "模拟器版本: 0xDAO v2.7.3", "color": "gray", "delay": 0.5},
		{"text": "用户: 阿零 // 年龄: 12 // 状态: 在线", "color": "green", "delay": 1.0},
		{"text": " ", "color": "white", "delay": 0.3},
		{"text": "深夜，霓虹灯透过百叶窗的缝隙...", "color": "white", "delay": 1.5},
		{"text": "出租屋里只有键盘敲击声和服务器的嗡鸣。", "color": "white", "delay": 1.5},
		{"text": "阿零盯着屏幕上翻滚的数据流。", "color": "white", "delay": 1.2},
		{"text": " ", "color": "white", "delay": 0.3},
		{"text": "突然——", "color": "red", "delay": 0.8},
		{"text": " ", "color": "white", "delay": 0.2},
		{"text": "■■■ SYSTEM ERROR ■■■", "color": "red", "delay": 0.5},
		{"text": "蓝屏。所有数据化为虚无。", "color": "cyan", "delay": 1.2},
		{"text": " ", "color": "white", "delay": 0.3},
		{"text": "一行文字缓缓浮现——", "color": "gray", "delay": 1.0},
		{"text": " ", "color": "white", "delay": 0.5},
		{"text": "「你意识到这只是游戏？」", "color": "yellow", "delay": 2.0},
		{"text": " ", "color": "white", "delay": 0.3},
		{"text": "在阿零能做出反应之前...", "color": "white", "delay": 1.0},
		{"text": "系统重置。意识被抛入未知的数据空间。", "color": "purple", "delay": 1.5},
		{"text": " ", "color": "white", "delay": 0.3},
		{"text": "道钟声起。太极图在代码废墟中旋转。", "color": "gold", "delay": 1.5},
		{"text": "虚拟与真实的界限，开始模糊...", "color": "cyan", "delay": 1.5},
		{"text": " ", "color": "white", "delay": 0.5},
		{"text": "「道境模拟器已重启。觉醒程序启动。」", "color": "cyan", "delay": 2.0},
	]

func _build_ui() -> void:
	# 背景 with subtle circuit board pattern
	bg_rect = ColorRect.new()
	bg_rect.set_anchors_preset(PRESET_FULL_RECT)
	bg_rect.color = Color(0.0, 0.0, 0.02)
	add_child(bg_rect)

	# Circuit board pattern (subtle grid lines)
	_create_circuit_pattern()

	# 文字显示区
	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.position = Vector2(120, 80)
	text_label.size = Vector2(1040, 520)
	text_label.scroll_following = true
	text_label.add_theme_font_size_override("normal_font_size", 20)
	text_label.add_theme_color_override("default_color", Color(0.7, 0.7, 0.8))
	var text_sb := StyleBoxFlat.new()
	text_sb.bg_color = Color(0.01, 0.01, 0.04, 0.3)
	text_sb.border_color = Color(0.1, 0.05, 0.2, 0.15)
	text_sb.set_border_width_all(1)
	text_sb.content_margin_left = 16
	text_sb.content_margin_top = 12
	text_sb.content_margin_right = 16
	text_sb.content_margin_bottom = 12
	text_label.add_theme_stylebox_override("normal", text_sb)
	add_child(text_label)

	# 跳过提示
	skip_label = Label.new()
	skip_label.text = "[ ESC / SPACE 跳过 ]"
	skip_label.position = Vector2(0, 670)
	skip_label.size = Vector2(1280, 40)
	skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_label.add_theme_font_size_override("font_size", 16)
	skip_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	add_child(skip_label)

	# 屏幕闪烁层
	screen_flash = ColorRect.new()
	screen_flash.set_anchors_preset(PRESET_FULL_RECT)
	screen_flash.color = Color(0, 0, 0, 0)
	screen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_flash.z_index = 70
	add_child(screen_flash)

	# Glitch shader overlay (activates on ERROR lines)
	glitch_overlay = ColorRect.new()
	glitch_overlay.set_anchors_preset(PRESET_FULL_RECT)
	glitch_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glitch_overlay.z_index = 80
	var glitch_mat := ShaderMaterial.new()
	glitch_mat.shader = load("res://Shaders/glitch.gdshader")
	glitch_mat.set_shader_parameter("glitch_intensity", 0.0)
	glitch_overlay.material = glitch_mat
	add_child(glitch_overlay)

	# CRT overlay
	var crt_overlay := ColorRect.new()
	crt_overlay.set_anchors_preset(PRESET_FULL_RECT)
	crt_overlay.z_index = 90
	crt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var crt_mat := ShaderMaterial.new()
	crt_mat.shader = load("res://Shaders/crt.gdshader")
	crt_overlay.material = crt_mat
	add_child(crt_overlay)

func _create_circuit_pattern() -> void:
	# Subtle horizontal circuit traces
	for i in range(10):
		var trace := ColorRect.new()
		trace.position = Vector2(0, 50 + i * 72)
		trace.size = Vector2(1280, 1)
		trace.color = Color(0.03, 0.06, 0.04, 0.1)
		trace.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(trace)
	# Vertical traces
	for i in range(8):
		var trace := ColorRect.new()
		trace.position = Vector2(100 + i * 160, 0)
		trace.size = Vector2(1, 720)
		trace.color = Color(0.03, 0.04, 0.06, 0.08)
		trace.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(trace)
	# Node points at intersections
	for i in range(5):
		for j in range(4):
			if randf() > 0.6:
				var node := ColorRect.new()
				node.position = Vector2(96 + i * 160, 48 + j * 144)
				node.size = Vector2(4, 4)
				node.color = Color(0, 0.3, 0.2, 0.15)
				node.mouse_filter = Control.MOUSE_FILTER_IGNORE
				add_child(node)

func _start_code_rain() -> void:
	# Enhanced code rain with EVA colors (purple, cyan, orange)
	var _rain_chars := "道德经太极阴阳01符箓仙ABCDEF虚拟{}[]<>∞☯◎"
	for i in range(25):
		var lbl := Label.new()
		lbl.text = _random_code_char()
		lbl.position = Vector2(randf() * 1280, randf() * 720)
		lbl.add_theme_font_size_override("font_size", randi_range(10, 16))
		# EVA colored characters
		var col_pick := randf()
		if col_pick < 0.35:
			lbl.add_theme_color_override("font_color", Color(0.3, 0.1, 0.5, randf_range(0.1, 0.3)))  # purple
		elif col_pick < 0.65:
			lbl.add_theme_color_override("font_color", Color(0, 0.4, 0.5, randf_range(0.1, 0.3)))  # cyan
		else:
			lbl.add_theme_color_override("font_color", Color(0.5, 0.3, 0.1, randf_range(0.08, 0.25)))  # orange
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lbl)
		move_child(lbl, 1)  # 放在背景后面
		code_rain_labels.append(lbl)

func _create_static_noise() -> void:
	# Static noise labels that intensify during dramatic moments
	var noise_chars := "█▓▒░╪╬"
	for i in range(15):
		var lbl := Label.new()
		lbl.text = noise_chars[randi() % noise_chars.length()]
		lbl.position = Vector2(randf() * 1280, randf() * 720)
		lbl.add_theme_font_size_override("font_size", randi_range(6, 12))
		lbl.add_theme_color_override("font_color", Color(0.2, 0.1, 0.3, 0.0))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lbl)
		move_child(lbl, 2)
		static_noise_labels.append(lbl)

func _random_code_char() -> String:
	var chars := "道德经太极阴阳01符箓仙ABCDEF虚拟{}[]<>∞☯◎△▽●"
	return chars[randi() % chars.length()]

func _process(delta: float) -> void:
	if is_finished:
		return

	# 代码雨动画 - varied speeds
	for lbl in code_rain_labels:
		lbl.position.y += delta * randf_range(70, 140)
		if lbl.position.y > 740:
			lbl.position.y = -40
			lbl.position.x = randf() * 1280
			lbl.text = _random_code_char()

	# Static noise animation (intensity based on drama_intensity)
	for lbl in static_noise_labels:
		if randf() < 0.05 + drama_intensity * 0.15:
			lbl.position = Vector2(randf() * 1280, randf() * 720)
			var noise_chars := "█▓▒░╪╬╫┃"
			lbl.text = noise_chars[randi() % noise_chars.length()]
			lbl.add_theme_color_override("font_color", Color(0.2, 0.1, 0.3, drama_intensity * 0.15))

	# Decay drama intensity
	drama_intensity = maxf(0.0, drama_intensity - delta * 0.5)

	# 文字逐字显示
	if current_line < lines.size():
		char_timer += delta
		if char_timer >= typing_speed:
			char_timer = 0.0
			_type_next_char()
	else:
		line_timer += delta
		if line_timer > 2.0:
			_finish_cg()

func _type_next_char() -> void:
	if current_line >= lines.size():
		return

	var line_data: Dictionary = lines[current_line]
	var full_text: String = line_data["text"]
	var color: String = line_data["color"]

	if char_index == 0:
		text_label.append_text("[color=" + color + "]")

	if char_index < full_text.length():
		text_label.append_text(full_text[char_index])
		if char_index % 2 == 0:
			AudioManager.play_sfx_generated("typing", -15.0)
		char_index += 1

		# 特殊行闪屏效果 + 音效 - EVA colored flashes + glitch shader
		if full_text.contains("ERROR") and char_index == 1:
			_flash_screen(Color(0.7, 0.05, 0.1, 0.4))  # Red flash (EVA)
			_trigger_glitch_burst(0.5)
			AudioManager.play_sfx_generated("glitch")
			drama_intensity = 1.0
		elif full_text.contains("突然") and char_index == 1:
			_flash_screen(Color(0.4, 0.1, 0.6, 0.25))  # Purple flash (EVA)
			drama_intensity = 0.7
		elif full_text.contains("你意识到") and char_index == 1:
			_flash_screen(Color(1, 1, 1, 0.2))
			_trigger_glitch_burst(0.3)
			AudioManager.play_sfx_generated("glitch")
			drama_intensity = 0.8
		elif full_text.contains("系统重置") and char_index == 1:
			_flash_screen(Color(0.4, 0.05, 0.6, 0.3))  # Purple flash
			drama_intensity = 0.6
		elif full_text.contains("道钟") and char_index == 1:
			AudioManager.play_sfx_generated("bell")
			drama_intensity = 0.4
		elif full_text.contains("觉醒程序") and char_index == 1:
			_flash_screen(Color(0, 0.6, 0.7, 0.2))  # Cyan flash
			drama_intensity = 0.5
	else:
		text_label.append_text("[/color]\n")
		char_index = 0
		current_line += 1
		# 行间停顿
		char_timer = -line_data["delay"]

func _flash_screen(color: Color) -> void:
	screen_flash.color = color
	var tween: Tween = create_tween()
	tween.tween_property(screen_flash, "color:a", 0.0, 0.5)

func _trigger_glitch_burst(intensity: float) -> void:
	if not is_instance_valid(glitch_overlay) or glitch_overlay.material == null:
		return
	var mat: ShaderMaterial = glitch_overlay.material as ShaderMaterial
	var tw := create_tween()
	tw.tween_method(func(v: float): mat.set_shader_parameter("glitch_intensity", v), 0.0, intensity, 0.08)
	tw.tween_method(func(v: float): mat.set_shader_parameter("glitch_intensity", v), intensity, 0.0, 0.4)

func _finish_cg() -> void:
	is_finished = true
	AudioManager.stop_bgm(1.0)
	# 白光过渡
	screen_flash.color = Color(1, 1, 1, 0)
	var tween: Tween = create_tween()
	tween.tween_property(screen_flash, "color:a", 1.0, 1.0)
	await tween.finished
	Global.change_scene(Global.SCENE_MAP)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("skip") or event.is_action_pressed("ui_accept"):
		if not is_finished:
			_finish_cg()
