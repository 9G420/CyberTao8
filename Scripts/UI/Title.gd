# ============================================================
# Title.gd - 标题画面
# 霓虹雨夜出租屋背景 + Logo + 菜单
# Enhanced: CRT overlay, floating taiji, matrix rain, glitch overlay,
#           neon glow pulsing, scanline separator, improved city
# ============================================================
extends Control

var glitch_timer: float = 0.0
var title_label: Label
var subtitle_label: Label
var rain_particles: GPUParticles2D
var taiji_sprite: TextureRect
var taiji_frame: int = 0
var taiji_timer: float = 0.0
var matrix_rain_labels: Array[Label] = []
var glitch_overlay: ColorRect
var glitch_overlay_timer: float = 0.0
var scanline_separator: ColorRect
var scanline_phase: float = 0.0
var title_glow_tween: Tween

func _ready() -> void:
	_build_ui()
	AudioManager.play_bgm_generated("title")

func _build_ui() -> void:
	# 深色背景 - AI资产优先
	var _ai_title_bg := AssetLoader.get_ui_texture("title_bg", 1280, 720)
	if _ai_title_bg:
		var bg_tex := TextureRect.new()
		bg_tex.set_anchors_preset(PRESET_FULL_RECT)
		bg_tex.stretch_mode = TextureRect.STRETCH_SCALE
		bg_tex.texture = _ai_title_bg
		bg_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(bg_tex)
	else:
		var bg := ColorRect.new()
		bg.set_anchors_preset(PRESET_FULL_RECT)
		bg.color = Color(0.02, 0.01, 0.06)
		add_child(bg)

	# 雨夜城市背景色块（模拟建筑轮廓）- 仅在无AI资产时显示
	if not AssetLoader.use_ai_assets:
		_create_city_silhouette()

	# Matrix rain effect (behind main content)
	_create_matrix_rain()

	# 霓虹雨粒子
	rain_particles = GPUParticles2D.new()
	rain_particles.amount = 100
	rain_particles.lifetime = 1.5
	rain_particles.position = Vector2(640, 0)
	var rain_mat := ParticleProcessMaterial.new()
	rain_mat.direction = Vector3(0, 1, 0)
	rain_mat.gravity = Vector3(0, 800, 0)
	rain_mat.initial_velocity_min = 200.0
	rain_mat.initial_velocity_max = 400.0
	rain_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	rain_mat.emission_box_extents = Vector3(640, 1, 1)
	rain_mat.scale_min = 0.5
	rain_mat.scale_max = 1.0
	rain_mat.color = Color(0.4, 0.5, 1.0, 0.3)
	rain_particles.process_material = rain_mat
	rain_particles.visibility_rect = Rect2(-640, 0, 1280, 800)
	add_child(rain_particles)

	# 标题 with enhanced neon glow
	title_label = Label.new()
	title_label.text = "虚拟道境·像素觉醒"
	title_label.position = Vector2(0, 120)
	title_label.size = Vector2(1280, 100)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color(0, 0.95, 1))
	title_label.add_theme_color_override("font_shadow_color", Color(0.8, 0.2, 1, 0.6))
	title_label.add_theme_constant_override("shadow_offset_x", 4)
	title_label.add_theme_constant_override("shadow_offset_y", 4)
	title_label.add_theme_color_override("font_outline_color", Color(0, 0.6, 1, 0.5))
	title_label.add_theme_constant_override("outline_size", 3)
	add_child(title_label)
	_start_title_neon_pulse()

	# Animated scan-line separator under title
	scanline_separator = ColorRect.new()
	scanline_separator.position = Vector2(240, 190)
	scanline_separator.size = Vector2(800, 3)
	scanline_separator.color = Color(0, 0.8, 1, 0.6)
	add_child(scanline_separator)

	# 英文副标题
	subtitle_label = Label.new()
	subtitle_label.text = "CyberTao: Pixel Awakening"
	subtitle_label.position = Vector2(0, 200)
	subtitle_label.size = Vector2(1280, 60)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 24)
	subtitle_label.add_theme_color_override("font_color", Color(1, 0.4, 0.8, 0.8))
	add_child(subtitle_label)

	# 版本号
	var ver := Label.new()
	ver.text = "DEMO v0.1 // 道境模拟器 初始化中..."
	ver.position = Vector2(0, 250)
	ver.size = Vector2(1280, 40)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_font_size_override("font_size", 14)
	ver.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	add_child(ver)

	# 太极符号 (floating, generated texture, slowly rotating)
	taiji_sprite = TextureRect.new()
	var _ai_taiji_t := AssetLoader.get_ui_texture("taiji", 80, 80)
	taiji_sprite.texture = _ai_taiji_t if _ai_taiji_t else PixelArtGenerator.generate_taiji_symbol(80, 0)
	taiji_sprite.position = Vector2(600, 290)
	taiji_sprite.size = Vector2(80, 80)
	taiji_sprite.pivot_offset = Vector2(40, 40)
	taiji_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(taiji_sprite)

	# 菜单按钮
	var btn_container := VBoxContainer.new()
	btn_container.position = Vector2(460, 440)
	btn_container.size = Vector2(360, 240)
	btn_container.add_theme_constant_override("separation", 20)
	add_child(btn_container)

	var btn_new := _make_neon_button("新 游 戏")
	btn_new.pressed.connect(_on_new_game)
	btn_container.add_child(btn_new)

	var btn_continue := _make_neon_button("继续游戏")
	btn_continue.pressed.connect(_on_continue)
	btn_container.add_child(btn_continue)

	var btn_quit := _make_neon_button("退    出")
	btn_quit.pressed.connect(_on_quit)
	btn_container.add_child(btn_quit)

	# 底部装饰线
	var line := ColorRect.new()
	line.position = Vector2(200, 680)
	line.size = Vector2(880, 2)
	line.color = Color(0, 0.5, 1, 0.3)
	add_child(line)

	var copyright := Label.new()
	copyright.text = "© 2026 CyberTao Project // 模拟器版本 0xDAO"
	copyright.position = Vector2(0, 690)
	copyright.size = Vector2(1280, 30)
	copyright.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copyright.add_theme_font_size_override("font_size", 12)
	copyright.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
	add_child(copyright)

	# Subtle glitch overlay (occasionally flickers)
	glitch_overlay = ColorRect.new()
	glitch_overlay.set_anchors_preset(PRESET_FULL_RECT)
	glitch_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glitch_overlay.z_index = 80
	var glitch_shader_mat := ShaderMaterial.new()
	glitch_shader_mat.shader = load("res://Shaders/glitch.gdshader")
	glitch_shader_mat.set_shader_parameter("glitch_intensity", 0.0)
	glitch_overlay.material = glitch_shader_mat
	add_child(glitch_overlay)

	# CRT shader overlay
	var crt_overlay := ColorRect.new()
	crt_overlay.set_anchors_preset(PRESET_FULL_RECT)
	crt_overlay.z_index = 90
	crt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var crt_mat := ShaderMaterial.new()
	crt_mat.shader = load("res://Shaders/crt.gdshader")
	crt_overlay.material = crt_mat
	add_child(crt_overlay)

func _create_city_silhouette() -> void:
	# Enhanced pixel-art building silhouettes with more variety
	var buildings := [
		{"x": 0, "w": 120, "h": 360, "c": Color(0.04, 0.02, 0.08)},
		{"x": 100, "w": 60, "h": 280, "c": Color(0.035, 0.02, 0.065)},
		{"x": 130, "w": 80, "h": 440, "c": Color(0.05, 0.03, 0.09)},
		{"x": 220, "w": 160, "h": 320, "c": Color(0.04, 0.02, 0.07)},
		{"x": 340, "w": 50, "h": 380, "c": Color(0.045, 0.025, 0.085)},
		{"x": 400, "w": 100, "h": 500, "c": Color(0.06, 0.03, 0.1)},
		{"x": 480, "w": 40, "h": 260, "c": Color(0.035, 0.02, 0.07)},
		{"x": 520, "w": 240, "h": 280, "c": Color(0.03, 0.02, 0.06)},
		{"x": 700, "w": 70, "h": 420, "c": Color(0.045, 0.025, 0.08)},
		{"x": 780, "w": 140, "h": 400, "c": Color(0.05, 0.02, 0.08)},
		{"x": 880, "w": 50, "h": 300, "c": Color(0.038, 0.022, 0.072)},
		{"x": 940, "w": 100, "h": 340, "c": Color(0.04, 0.03, 0.07)},
		{"x": 1010, "w": 40, "h": 480, "c": Color(0.055, 0.025, 0.095)},
		{"x": 1060, "w": 220, "h": 460, "c": Color(0.05, 0.02, 0.09)},
	]
	var window_colors := [
		Color(1, 0.3, 0.6, 0.5), Color(0, 0.8, 1, 0.5), Color(0.5, 0, 1, 0.5),
		Color(1, 0.6, 0.2, 0.4), Color(0.2, 1, 0.5, 0.35), Color(0.8, 0.8, 0.2, 0.3),
	]
	for b in buildings:
		var rect := ColorRect.new()
		rect.position = Vector2(b["x"], 720 - b["h"])
		rect.size = Vector2(b["w"], b["h"])
		rect.color = b["c"]
		add_child(rect)
		# 霓虹窗户 - more rows, more color variety
		var win_rows := int(b["h"] / 50)
		var win_cols := int(b["w"] / 30)
		for i in range(win_rows):
			for j in range(win_cols):
				if randf() > 0.35:
					var win := ColorRect.new()
					win.size = Vector2(8, 6)
					win.position = Vector2(12 + j * int(b["w"] * 0.3), 16 + i * 50)
					var color_idx: int = randi() % window_colors.size()
					win.color = window_colors[color_idx]
					rect.add_child(win)

func _create_matrix_rain() -> void:
	# Enhanced matrix rain effect with more characters and better flow
	var rain_chars := "道德经太极阴阳01符箓仙ABCDEF虚拟{}[]<>∞☯◎△▽●○仁义礼智信"
	for i in range(30):
		var lbl := Label.new()
		lbl.text = rain_chars[randi() % rain_chars.length()]
		lbl.position = Vector2(randf() * 1280, randf() * 720)
		lbl.add_theme_font_size_override("font_size", randi_range(10, 18))
		var alpha := randf_range(0.08, 0.3)
		var col_pick := randf()
		if col_pick < 0.5:
			lbl.add_theme_color_override("font_color", Color(0, 0.4, 0.2, alpha))
		elif col_pick < 0.75:
			lbl.add_theme_color_override("font_color", Color(0, 0.2, 0.5, alpha))
		else:
			lbl.add_theme_color_override("font_color", Color(0.3, 0.1, 0.4, alpha))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lbl)
		move_child(lbl, 1)
		matrix_rain_labels.append(lbl)

func _start_title_neon_pulse() -> void:
	title_glow_tween = create_tween().set_loops()
	title_glow_tween.tween_method(_set_title_glow, 0.0, 1.0, 1.5)
	title_glow_tween.tween_method(_set_title_glow, 1.0, 0.0, 1.5)

func _set_title_glow(t: float) -> void:
	if not is_instance_valid(title_label):
		return
	var cyan := Color(0, 0.95, 1)
	var _pink := Color(1, 0.3, 0.8)
	title_label.add_theme_color_override("font_color", cyan.lerp(Color(0.5, 0.95, 1), t * 0.3))
	title_label.add_theme_color_override("font_shadow_color", Color(0.8, 0.2, 1, 0.4 + t * 0.4))
	title_label.add_theme_constant_override("shadow_offset_x", 4 + int(t * 2))
	title_label.add_theme_constant_override("shadow_offset_y", 4 + int(t * 2))

func _make_neon_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(360, 50)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color(0, 0.9, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 0.4, 0.8))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.02, 0.1, 0.8)
	sb.border_color = Color(0, 0.5, 1, 0.6)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.shadow_color = Color(0, 0.4, 0.8, 0.3)
	sb.shadow_size = 4
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := StyleBoxFlat.new()
	sb_h.bg_color = Color(0.1, 0.02, 0.15, 0.9)
	sb_h.border_color = Color(1, 0.3, 0.7, 0.8)
	sb_h.set_border_width_all(2)
	sb_h.set_corner_radius_all(4)
	sb_h.shadow_color = Color(1, 0.2, 0.6, 0.4)
	sb_h.shadow_size = 6
	btn.add_theme_stylebox_override("hover", sb_h)
	var sb_p := StyleBoxFlat.new()
	sb_p.bg_color = Color(0.2, 0.05, 0.2, 1.0)
	sb_p.border_color = Color(1, 0.5, 0.8, 1.0)
	sb_p.set_border_width_all(4)
	sb_p.set_corner_radius_all(4)
	sb_p.shadow_color = Color(1, 0.3, 0.7, 0.5)
	sb_p.shadow_size = 8
	btn.add_theme_stylebox_override("pressed", sb_p)
	return btn

func _process(delta: float) -> void:
	# Title neon glow pulsing (modulate)
	glitch_timer += delta
	if glitch_timer > 3.0 + randf() * 2.0:
		glitch_timer = 0.0
		_title_glitch()

	# Subtle glitch overlay flicker
	glitch_overlay_timer += delta
	if glitch_overlay_timer > 4.0 + randf() * 3.0:
		glitch_overlay_timer = 0.0
		_trigger_glitch_overlay()

	# Title label pulse
	if title_label:
		var pulse := sin(Time.get_ticks_msec() / 1000.0) * 0.1
		title_label.modulate.a = 0.9 + pulse

	# Floating taiji symbol - slow rotation via regenerating texture
	taiji_timer += delta
	if taiji_timer >= 0.1:
		taiji_timer = 0.0
		taiji_frame = (taiji_frame + 1) % 60
		if is_instance_valid(taiji_sprite):
			if not AssetLoader.use_ai_assets:
				taiji_sprite.texture = PixelArtGenerator.generate_taiji_symbol(80, taiji_frame)
			else:
				taiji_sprite.rotation_degrees = taiji_frame * 6.0
			# Gentle float bob
			taiji_sprite.position.y = 290 + sin(Time.get_ticks_msec() / 800.0) * 6.0

	# Matrix rain animation
	for lbl in matrix_rain_labels:
		lbl.position.y += delta * randf_range(60, 140)
		if lbl.position.y > 740:
			lbl.position.y = -30
			lbl.position.x = randf() * 1280
			var rain_chars := "道德经太极阴阳01符箓仙ABCDEF虚拟{}[]<>∞☯◎△▽●○"
			lbl.text = rain_chars[randi() % rain_chars.length()]

	# Animated scanline separator
	scanline_phase += delta * 3.0
	if is_instance_valid(scanline_separator):
		var scan_alpha := 0.3 + sin(scanline_phase) * 0.3
		var scan_r := 0.0 + sin(scanline_phase * 0.7) * 0.1
		scanline_separator.color = Color(scan_r, 0.6 + sin(scanline_phase * 1.3) * 0.2, 1.0, scan_alpha)

func _trigger_glitch_overlay() -> void:
	if not is_instance_valid(glitch_overlay) or glitch_overlay.material == null:
		return
	var mat: ShaderMaterial = glitch_overlay.material as ShaderMaterial
	var tween := create_tween()
	tween.tween_method(func(v: float): mat.set_shader_parameter("glitch_intensity", v), 0.0, 0.25, 0.08)
	tween.tween_method(func(v: float): mat.set_shader_parameter("glitch_intensity", v), 0.25, 0.0, 0.2)

func _title_glitch() -> void:
	var orig_pos := title_label.position
	var tween: Tween = create_tween()
	tween.tween_property(title_label, "position:x", orig_pos.x + randf_range(-10, 10), 0.05)
	tween.tween_property(title_label, "position:x", orig_pos.x, 0.05)
	tween.tween_property(title_label, "modulate", Color(1, 0.3, 0.5), 0.03)
	tween.tween_property(title_label, "modulate", Color.WHITE, 0.1)

func _on_new_game() -> void:
	AudioManager.play_sfx_generated("click")
	AudioManager.stop_bgm(0.5)
	GameState.start_new_game()
	Global.change_scene(Global.SCENE_OPENING)

func _on_continue() -> void:
	if GameState.load_game():
		Global.change_scene(Global.SCENE_MAP)
	else:
		# 没有存档，开始新游戏
		_on_new_game()

func _on_quit() -> void:
	get_tree().quit()
