# ============================================================
# Victory.gd - 胜利/觉醒结局画面
# 全屏白光+太极旋转+模拟器裂开效果
# Enhanced: EVA cross of light, generated taiji texture, particle burst,
#           glitch shader crack, CRT overlay, neon achievement panel,
#           SFX/bell, gold/white/purple color scheme
# ============================================================
extends Control

var phase: int = 0
var timer: float = 0.0
var taichi_sprite: TextureRect
var taichi_frame: int = 0
var crack_labels: Array[Label] = []
var glitch_overlay: ColorRect
var crt_overlay: ColorRect

func _ready() -> void:
	_build_ui()
	_start_sequence()

func _build_ui() -> void:
	# 黑色背景
	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color.BLACK
	add_child(bg)

	# Glitch shader overlay for crack effect (starts hidden)
	# ★ 安全: 先设透明色再赋material，防止shader失败时白屏
	glitch_overlay = ColorRect.new()
	glitch_overlay.set_anchors_preset(PRESET_FULL_RECT)
	glitch_overlay.color = Color(0, 0, 0, 0)
	glitch_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glitch_overlay.z_index = 5
	var glitch_shader = load("res://Shaders/glitch.gdshader")
	if glitch_shader:
		var glitch_mat := ShaderMaterial.new()
		glitch_mat.shader = glitch_shader
		glitch_mat.set_shader_parameter("glitch_intensity", 0.0)
		glitch_overlay.material = glitch_mat
	add_child(glitch_overlay)

	# CRT overlay — 安全处理
	crt_overlay = ColorRect.new()
	crt_overlay.set_anchors_preset(PRESET_FULL_RECT)
	crt_overlay.color = Color(0, 0, 0, 0)
	crt_overlay.z_index = 6
	crt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var crt_shader = load("res://Shaders/crt.gdshader")
	if crt_shader:
		var crt_mat := ShaderMaterial.new()
		crt_mat.shader = crt_shader
		crt_overlay.material = crt_mat
	add_child(crt_overlay)

func _start_sequence() -> void:
	# Play victory bell SFX
	AudioManager.play_sfx_generated("bell")

	# 阶段1: 白光爆发 + EVA cross of light
	phase = 1
	_create_eva_cross_of_light()

	var flash := ColorRect.new()
	flash.set_anchors_preset(PRESET_FULL_RECT)
	flash.color = Color(1, 1, 1, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.name = "Flash"
	flash.z_index = 50
	add_child(flash)
	var tween: Tween = create_tween()
	tween.tween_property(flash, "color:a", 1.0, 1.0)
	tween.tween_property(flash, "color:a", 0.0, 2.0)
	await tween.finished

	# 阶段2: 太极旋转 (generated texture)
	phase = 2
	AudioManager.play_sfx_generated("bell")
	taichi_sprite = TextureRect.new()
	var _ai_taiji_v := AssetLoader.get_ui_texture("taiji", 120, 120)
	taichi_sprite.texture = _ai_taiji_v if _ai_taiji_v else PixelArtGenerator.generate_taiji_symbol(120, 0)
	taichi_sprite.position = Vector2(580, 260)
	taichi_sprite.size = Vector2(120, 120)
	taichi_sprite.pivot_offset = Vector2(60, 60)
	taichi_sprite.modulate.a = 0.0
	add_child(taichi_sprite)

	# Fade in taiji
	var fade_in := create_tween()
	fade_in.tween_property(taichi_sprite, "modulate:a", 1.0, 0.5)
	await fade_in.finished

	# Spin taiji with generated frames
	var spin_time := 0.0
	var spin_duration := 5.0
	while spin_time < spin_duration:
		await get_tree().process_frame
		spin_time += get_process_delta_time()
		taichi_frame = (taichi_frame + 1) % 60
		if is_instance_valid(taichi_sprite):
			if not AssetLoader.use_ai_assets:
				taichi_sprite.texture = PixelArtGenerator.generate_taiji_symbol(120, taichi_frame)
			else:
				taichi_sprite.rotation_degrees = taichi_frame * 6.0

	# 阶段3: 觉醒文本 + particle burst
	phase = 3
	if is_instance_valid(taichi_sprite):
		taichi_sprite.queue_free()

	# Particle burst on awakening text reveal
	_create_particle_burst(Vector2(640, 240), 24, Color(1, 0.9, 0.5, 0.8))

	var awakening := Label.new()
	awakening.text = "觉     醒"
	awakening.position = Vector2(0, 200)
	awakening.size = Vector2(1280, 120)
	awakening.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	awakening.add_theme_font_size_override("font_size", 60)
	awakening.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	awakening.add_theme_color_override("font_shadow_color", Color(0.8, 0.6, 0.2, 0.5))
	awakening.add_theme_constant_override("shadow_offset_x", 3)
	awakening.add_theme_constant_override("shadow_offset_y", 3)
	awakening.add_theme_color_override("font_outline_color", Color(1, 0.8, 0.3, 0.4))
	awakening.add_theme_constant_override("outline_size", 2)
	awakening.modulate.a = 0
	add_child(awakening)

	AudioManager.play_sfx_generated("bell")

	var tw2: Tween = create_tween()
	tw2.tween_property(awakening, "modulate:a", 1.0, 1.5)
	await tw2.finished

	# 模拟器裂开效果 + glitch shader
	_show_crack_effect()
	_trigger_screen_crack_glitch()
	await get_tree().create_timer(1.5).timeout

	# 阶段4: 结局文本
	phase = 4
	var ending_text := RichTextLabel.new()
	ending_text.bbcode_enabled = true
	ending_text.position = Vector2(200, 340)
	ending_text.size = Vector2(880, 160)
	ending_text.add_theme_font_size_override("normal_font_size", 18)
	ending_text.add_theme_color_override("default_color", Color(0.7, 0.7, 0.8))
	ending_text.append_text("[center]「旧我」已被击败。模拟器的裂缝中，你看到了真实。\n\n[color=cyan]还有更深层副本...[/color]\n[color=gray]道境并非终点。觉醒只是开始。[/color][/center]")
	add_child(ending_text)

	# 成就显示
	await get_tree().create_timer(2.0).timeout
	_show_achievements()

	# 按钮
	await get_tree().create_timer(1.0).timeout
	_show_buttons()

func _create_eva_cross_of_light() -> void:
	# Vertical beam of cross
	var v_beam := ColorRect.new()
	v_beam.position = Vector2(636, 0)
	v_beam.size = Vector2(8, 720)
	v_beam.color = Color(0.95, 0.9, 1, 0.0)
	v_beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v_beam)

	# Horizontal beam of cross
	var h_beam := ColorRect.new()
	h_beam.position = Vector2(0, 356)
	h_beam.size = Vector2(1280, 8)
	h_beam.color = Color(0.95, 0.9, 1, 0.0)
	h_beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(h_beam)

	# Soft glow around vertical beam
	var v_glow := ColorRect.new()
	v_glow.position = Vector2(620, 0)
	v_glow.size = Vector2(40, 720)
	v_glow.color = Color(0.4, 0.1, 0.6, 0.0)
	v_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v_glow)

	# Soft glow around horizontal beam
	var h_glow := ColorRect.new()
	h_glow.position = Vector2(0, 340)
	h_glow.size = Vector2(1280, 40)
	h_glow.color = Color(0.4, 0.1, 0.6, 0.0)
	h_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(h_glow)

	# Animate cross appearing and fading
	var cross_tw := create_tween()
	cross_tw.set_parallel(true)
	cross_tw.tween_property(v_beam, "color:a", 0.9, 0.8)
	cross_tw.tween_property(h_beam, "color:a", 0.9, 0.8)
	cross_tw.tween_property(v_glow, "color:a", 0.3, 0.8)
	cross_tw.tween_property(h_glow, "color:a", 0.3, 0.8)
	cross_tw.chain().set_parallel(true)
	cross_tw.tween_property(v_beam, "color:a", 0.0, 2.5)
	cross_tw.tween_property(h_beam, "color:a", 0.0, 2.5)
	cross_tw.tween_property(v_glow, "color:a", 0.0, 2.5)
	cross_tw.tween_property(h_glow, "color:a", 0.0, 2.5)

func _create_particle_burst(center: Vector2, count: int, color: Color) -> void:
	for i in range(count):
		var p := ColorRect.new()
		p.size = Vector2(4, 4)
		p.position = center
		p.color = color
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(p)
		var angle := randf() * TAU
		var dist := randf_range(60, 200)
		var target := center + Vector2(cos(angle), sin(angle)) * dist
		var tw := create_tween().set_parallel(true)
		tw.tween_property(p, "position", target, randf_range(0.6, 1.5)).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "modulate:a", 0.0, randf_range(0.8, 1.8))
		tw.chain().tween_callback(p.queue_free)

func _show_crack_effect() -> void:
	# 模拟屏幕裂缝
	var crack_chars := ["╱", "╲", "│", "─", "╳", "╱", "╲"]
	for i in range(12):
		var lbl := Label.new()
		var crack_idx: int = randi() % crack_chars.size()
		lbl.text = crack_chars[crack_idx]
		lbl.position = Vector2(560 + randf_range(-200, 200), 160 + randf_range(-60, 160))
		lbl.add_theme_font_size_override("font_size", randi_range(24, 48))
		lbl.add_theme_color_override("font_color", Color(1, 1, 1, randf_range(0.3, 0.8)))
		lbl.rotation = randf_range(-0.5, 0.5)
		add_child(lbl)
		crack_labels.append(lbl)

func _trigger_screen_crack_glitch() -> void:
	if not is_instance_valid(glitch_overlay) or glitch_overlay.material == null:
		return
	var mat: ShaderMaterial = glitch_overlay.material as ShaderMaterial
	AudioManager.play_sfx_generated("glitch")
	var tw := create_tween()
	tw.tween_method(func(v: float): mat.set_shader_parameter("glitch_intensity", v), 0.0, 0.6, 0.15)
	tw.tween_method(func(v: float): mat.set_shader_parameter("glitch_intensity", v), 0.6, 0.15, 0.4)
	tw.tween_method(func(v: float): mat.set_shader_parameter("glitch_intensity", v), 0.15, 0.3, 0.2)
	tw.tween_method(func(v: float): mat.set_shader_parameter("glitch_intensity", v), 0.3, 0.0, 0.5)

func _show_achievements() -> void:
	var ach_panel := Panel.new()
	ach_panel.position = Vector2(300, 510)
	ach_panel.size = Vector2(680, 120)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.03, 0.1, 0.85)
	sb.border_color = Color(1, 0.8, 0.3, 0.7)
	sb.set_border_width_all(2)
	sb.border_width_top = 3
	sb.set_corner_radius_all(2)
	sb.shadow_color = Color(1, 0.7, 0.2, 0.3)
	sb.shadow_size = 6
	ach_panel.add_theme_stylebox_override("panel", sb)
	add_child(ach_panel)

	# EVA-style top accent
	var accent := ColorRect.new()
	accent.position = Vector2(2, 0)
	accent.size = Vector2(676, 2)
	accent.color = Color(0.4, 0.1, 0.6, 0.8)
	ach_panel.add_child(accent)

	var ach_title := Label.new()
	ach_title.text = "══ 成就解锁 ══"
	ach_title.position = Vector2(0, 6)
	ach_title.size = Vector2(680, 36)
	ach_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ach_title.add_theme_font_size_override("font_size", 16)
	ach_title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	ach_title.add_theme_color_override("font_shadow_color", Color(0.6, 0.4, 0, 0.4))
	ach_title.add_theme_constant_override("shadow_offset_x", 1)
	ach_title.add_theme_constant_override("shadow_offset_y", 1)
	ach_panel.add_child(ach_title)

	var ach_text := ""
	if GameState.achievements["first_awakening"]:
		ach_text += "★ 首次觉醒  "
	if GameState.achievements["yinyang_master"]:
		ach_text += "★ 阴阳大师  "
	if GameState.achievements["no_damage_boss"]:
		ach_text += "★ 完美觉醒  "
	if ach_text == "":
		ach_text = "★ 首次觉醒"

	var ach_lbl := Label.new()
	ach_lbl.text = ach_text
	ach_lbl.position = Vector2(20, 44)
	ach_lbl.size = Vector2(640, 60)
	ach_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ach_lbl.add_theme_font_size_override("font_size", 18)
	ach_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.95))
	ach_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ach_panel.add_child(ach_lbl)

func _show_buttons() -> void:
	var btn_container := HBoxContainer.new()
	btn_container.position = Vector2(200, 650)
	btn_container.size = Vector2(880, 60)
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 30)
	add_child(btn_container)

	# 战斗奖励按钮（3选1选卡）
	var reward_btn := _make_victory_button("选择奖励卡牌", Color(0.3, 1, 0.5))
	reward_btn.pressed.connect(_on_claim_reward)
	btn_container.add_child(reward_btn)

	var next_btn := _make_victory_button("继续下一轮（传承）", Color(1, 0.85, 0.3))
	next_btn.pressed.connect(_on_next_run)
	btn_container.add_child(next_btn)

	var title_btn := _make_victory_button("返回标题", Color(0.6, 0.6, 0.7))
	title_btn.pressed.connect(_on_title)
	btn_container.add_child(title_btn)

func _make_victory_button(text: String, font_color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.custom_minimum_size = Vector2(280, 50)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.03, 0.12, 0.8)
	sb.border_color = Color(1, 0.7, 0.2, 0.5)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.shadow_color = Color(1, 0.6, 0.1, 0.2)
	sb.shadow_size = 3
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.border_color = Color(1, 0.8, 0.3, 0.8)
	sb_h.shadow_size = 6
	btn.add_theme_stylebox_override("hover", sb_h)
	return btn

func _on_claim_reward() -> void:
	# 设置当前节点为奖励模式，跳转到Event场景的REWARD阶段
	var node_data := GameState.get_current_node()
	if node_data.size() > 0:
		node_data["_reward_mode"] = true
	get_tree().change_scene_to_file(Global.SCENE_EVENT)

func _on_next_run() -> void:
	# 选择传承卡（简化：自动选择牌组中最后一张）
	var legacy := ""
	if GameState.player_deck.size() > 0:
		legacy = GameState.player_deck.back() as String
	GameState.start_new_run_with_legacy(legacy)
	Global.change_scene(Global.SCENE_MAP)

func _on_title() -> void:
	Global.change_scene(Global.SCENE_TITLE)
