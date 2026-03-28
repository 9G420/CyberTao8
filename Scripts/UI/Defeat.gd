# ============================================================
# Defeat.gd - 失败画面
# 可选择重开或带传承卡重试
# Enhanced: glitch shader overlay, blood-red vignette, shake animation,
#           static noise bg, CRT with increased intensity, neon buttons,
#           defeat BGM/SFX
# ============================================================
extends Control

var defeat_label: Label
var shake_timer: float = 0.0
var shake_active: bool = true
var noise_labels: Array[Label] = []

func _ready() -> void:
	_build_ui()
	AudioManager.play_sfx_generated("glitch")

func _build_ui() -> void:
	# 深红背景
	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.02, 0.02)
	add_child(bg)

	# Static noise background
	_create_static_noise()

	# Blood-red vignette effect
	var vignette := ColorRect.new()
	vignette.set_anchors_preset(PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.z_index = 10
	# Use a StyleBoxFlat to simulate vignette with shadow
	var vig_sb := StyleBoxFlat.new()
	vig_sb.bg_color = Color(0, 0, 0, 0)
	vig_sb.shadow_color = Color(0.5, 0.0, 0.05, 0.5)
	vig_sb.shadow_size = 120
	vig_sb.set_corner_radius_all(0)
	vignette.add_theme_stylebox_override("panel", vig_sb) # Won't work on ColorRect, use border approach
	add_child(vignette)

	# Vignette edges (top, bottom, left, right gradients approximated with ColorRects)
	for edge_data in [
		{"pos": Vector2(0, 0), "sz": Vector2(1280, 100), "col": Color(0.3, 0.0, 0.02, 0.5)},
		{"pos": Vector2(0, 620), "sz": Vector2(1280, 100), "col": Color(0.3, 0.0, 0.02, 0.5)},
		{"pos": Vector2(0, 0), "sz": Vector2(80, 720), "col": Color(0.3, 0.0, 0.02, 0.4)},
		{"pos": Vector2(1200, 0), "sz": Vector2(80, 720), "col": Color(0.3, 0.0, 0.02, 0.4)},
	]:
		var edge := ColorRect.new()
		edge.position = edge_data["pos"]
		edge.size = edge_data["sz"]
		edge.color = edge_data["col"]
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(edge)

	# Glitch shader overlay (replaces simple ColorRect flicker)
	var glitch_overlay := ColorRect.new()
	glitch_overlay.set_anchors_preset(PRESET_FULL_RECT)
	glitch_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glitch_overlay.color = Color(0, 0, 0, 0)  # Transparent fallback if shader fails
	glitch_overlay.z_index = 5
	var glitch_shader = load("res://Shaders/glitch.gdshader")
	if glitch_shader:
		var glitch_mat := ShaderMaterial.new()
		glitch_mat.shader = glitch_shader
		glitch_mat.set_shader_parameter("glitch_intensity", 0.0)
		glitch_overlay.material = glitch_mat
		add_child(glitch_overlay)
		# Animate glitch shader with subtle pulsing intensity
		var glitch_tween := create_tween().set_loops()
		glitch_tween.tween_method(func(v: float):
			glitch_mat.set_shader_parameter("glitch_intensity", v)
		, 0.02, 0.12, 0.8)
		glitch_tween.tween_method(func(v: float):
			glitch_mat.set_shader_parameter("glitch_intensity", v)
		, 0.12, 0.04, 0.5)
		glitch_tween.tween_method(func(v: float):
			glitch_mat.set_shader_parameter("glitch_intensity", v)
		, 0.04, 0.15, 0.3)
		glitch_tween.tween_method(func(v: float):
			glitch_mat.set_shader_parameter("glitch_intensity", v)
		, 0.15, 0.02, 0.6)
	else:
		glitch_overlay.color = Color(0, 0, 0, 0)
		add_child(glitch_overlay)

	# 败北文字 with shake animation
	defeat_label = Label.new()
	defeat_label.text = "意 识 崩 溃"
	defeat_label.position = Vector2(0, 160)
	defeat_label.size = Vector2(1280, 100)
	defeat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	defeat_label.add_theme_font_size_override("font_size", 56)
	defeat_label.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))
	defeat_label.add_theme_color_override("font_shadow_color", Color(0.5, 0.0, 0.0, 0.6))
	defeat_label.add_theme_constant_override("shadow_offset_x", 4)
	defeat_label.add_theme_constant_override("shadow_offset_y", 4)
	defeat_label.add_theme_color_override("font_outline_color", Color(0.6, 0.0, 0.0, 0.4))
	defeat_label.add_theme_constant_override("outline_size", 2)
	defeat_label.z_index = 10
	add_child(defeat_label)

	var sub_label := Label.new()
	sub_label.text = "SYSTEM CRASH // 模拟器强制终止"
	sub_label.position = Vector2(0, 250)
	sub_label.size = Vector2(1280, 40)
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.add_theme_font_size_override("font_size", 18)
	sub_label.add_theme_color_override("font_color", Color(0.5, 0.2, 0.2))
	sub_label.z_index = 10
	add_child(sub_label)

	# Neon separator
	var sep := ColorRect.new()
	sep.position = Vector2(300, 300)
	sep.size = Vector2(680, 2)
	sep.color = Color(0.6, 0.1, 0.15, 0.4)
	sep.z_index = 10
	add_child(sep)

	# 描述
	var desc := Label.new()
	desc.text = "你的意识在数据洪流中碎裂...\n但道境模拟器记录了你的痕迹。\n传承卡将保留最后的记忆碎片。"
	desc.position = Vector2(240, 340)
	desc.size = Vector2(800, 120)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 18)
	desc.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.z_index = 10
	add_child(desc)

	# 战斗统计
	var stats := Label.new()
	stats.text = "战斗胜利: " + str(GameState.battles_won) + " | 探索深度: " + str(GameState.map_current_floor + 1)
	stats.position = Vector2(0, 490)
	stats.size = Vector2(1280, 40)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 16)
	stats.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	stats.z_index = 10
	add_child(stats)

	# 按钮 - neon styled
	var btn_container := HBoxContainer.new()
	btn_container.position = Vector2(300, 560)
	btn_container.size = Vector2(680, 70)
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 40)
	btn_container.z_index = 20
	add_child(btn_container)

	var retry_btn: Button = UIFactory.make_cyan_button("传承重试", 200, 56)
	retry_btn.add_theme_font_size_override("font_size", 20)
	retry_btn.pressed.connect(_on_retry_legacy)
	btn_container.add_child(retry_btn)

	var restart_btn: Button = UIFactory.make_dim_button("重新开始", 200, 56)
	restart_btn.add_theme_font_size_override("font_size", 20)
	restart_btn.pressed.connect(_on_restart)
	btn_container.add_child(restart_btn)

	var title_btn: Button = UIFactory.make_dim_button("返回标题", 200, 56)
	title_btn.add_theme_font_size_override("font_size", 20)
	title_btn.pressed.connect(_on_title)
	btn_container.add_child(title_btn)

	# CRT shader overlay with increased intensity
	var crt_overlay := ColorRect.new()
	crt_overlay.set_anchors_preset(PRESET_FULL_RECT)
	crt_overlay.z_index = 6
	crt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crt_overlay.color = Color(0, 0, 0, 0)  # Transparent fallback if shader fails
	var crt_shader = load("res://Shaders/crt.gdshader")
	if crt_shader:
		var crt_mat := ShaderMaterial.new()
		crt_mat.shader = crt_shader
		crt_mat.set_shader_parameter("scanline_intensity", 0.28)
		crt_mat.set_shader_parameter("noise_band_intensity", 0.15)
		crt_mat.set_shader_parameter("vignette_intensity", 0.65)
		crt_mat.set_shader_parameter("flicker_intensity", 0.04)
		crt_overlay.material = crt_mat
	add_child(crt_overlay)

	# Stop shake after a delay
	await get_tree().create_timer(3.0).timeout
	shake_active = false

func _create_static_noise() -> void:
	var noise_chars := "█▓▒░╪╬╫┃━"
	for i in range(40):
		var lbl := Label.new()
		lbl.text = noise_chars[randi() % noise_chars.length()]
		lbl.position = Vector2(randf() * 1280, randf() * 720)
		lbl.add_theme_font_size_override("font_size", randi_range(8, 16))
		lbl.add_theme_color_override("font_color", Color(0.3, 0.08, 0.08, randf_range(0.03, 0.1)))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lbl)
		noise_labels.append(lbl)

func _make_defeat_button(text: String, font_color: Color, border_color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(200, 60)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_hover_color", font_color.lightened(0.3))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.02, 0.05, 0.8)
	sb.border_color = border_color
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.2)
	sb.shadow_size = 3
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.border_color = Color(font_color.r, font_color.g, font_color.b, 0.8)
	sb_h.shadow_size = 6
	sb_h.shadow_color = Color(font_color.r, font_color.g, font_color.b, 0.3)
	btn.add_theme_stylebox_override("hover", sb_h)
	return btn

func _process(delta: float) -> void:
	# Shake animation on defeat label
	if shake_active and is_instance_valid(defeat_label):
		shake_timer += delta
		if shake_timer > 0.05:
			shake_timer = 0.0
			defeat_label.position.x = randf_range(-6, 6)

	# Animate static noise
	for lbl in noise_labels:
		if randf() < 0.02:
			lbl.position = Vector2(randf() * 1280, randf() * 720)
			var noise_chars := "█▓▒░╪╬╫┃━"
			lbl.text = noise_chars[randi() % noise_chars.length()]

func _on_retry_legacy() -> void:
	# 带传承卡重试
	var legacy := ""
	if GameState.player_deck.size() > 0:
		var deck_idx: int = randi() % GameState.player_deck.size()
		legacy = GameState.player_deck[deck_idx] as String
	GameState.start_new_run_with_legacy(legacy)
	Global.is_transitioning = false
	get_tree().change_scene_to_file(Global.SCENE_MAP)

func _on_restart() -> void:
	GameState.legacy_card = ""
	GameState.start_new_game()
	Global.is_transitioning = false
	get_tree().change_scene_to_file(Global.SCENE_OPENING)

func _on_title() -> void:
	Global.is_transitioning = false
	get_tree().change_scene_to_file(Global.SCENE_TITLE)
