# ============================================================
# Map.gd - 地图界面（线性分支Roguelike）
# 显示节点路线，点击进入战斗/事件
# Enhanced: CRT overlay, neon glow animations, animated connections,
#           player sprite, EVA borders, atmospheric particles, BGM
# ============================================================
extends Control

var node_buttons: Array[Button] = []
var info_label: Label
var hp_label: Label
var gold_label: Label
var deck_btn: Button
var current_node_glow_tween: Tween
var particle_labels: Array[Label] = []
var connection_lines: Array[ColorRect] = []

func _ready() -> void:
	_build_ui()
	AudioManager.play_bgm_generated("map")

func _build_ui() -> void:
	# 背景 - dark atmospheric
	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.02, 0.08)
	add_child(bg)

	# Subtle background circuit pattern
	_create_circuit_bg()

	# Floating data bit particles
	_create_atmospheric_particles()

	# 标题
	var title := Label.new()
	title.text = "═══ 道 境 路 线 图 ═══"
	title.position = Vector2(0, 20)
	title.size = Vector2(1280, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0, 0.9, 1))
	title.add_theme_color_override("font_shadow_color", Color(0, 0.4, 0.8, 0.4))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	add_child(title)

	# Run信息
	var run_label := Label.new()
	run_label.text = "第 " + str(GameState.run_number) + " 轮探索"
	run_label.position = Vector2(0, 64)
	run_label.size = Vector2(1280, 40)
	run_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	run_label.add_theme_font_size_override("font_size", 16)
	run_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	add_child(run_label)

	# 传承卡提示
	if GameState.legacy_card != "":
		var lc_label := Label.new()
		lc_label.text = "传承卡已继承"
		lc_label.position = Vector2(0, 88)
		lc_label.size = Vector2(1280, 30)
		lc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lc_label.add_theme_font_size_override("font_size", 14)
		lc_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
		add_child(lc_label)

	# 节点容器 - 线性路线
	var route_container := Control.new()
	route_container.position = Vector2(0, 140)
	route_container.size = Vector2(1280, 360)
	add_child(route_container)

	# 连接线 - animated dashed effect
	for i in range(GameState.map_nodes.size() - 1):
		var line := ColorRect.new()
		line.position = Vector2(240 + i * 280, 110)
		line.size = Vector2(200, 4)
		line.color = Color(0.3, 0.15, 0.5, 0.5)
		route_container.add_child(line)
		connection_lines.append(line)

	# Animate connection lines with color shift
	_animate_connection_lines()

	# 地图节点按钮
	for i in range(GameState.map_nodes.size()):
		var node_data: Dictionary = GameState.map_nodes[i]
		var btn := Button.new()
		btn.text = node_data["name"]
		btn.position = Vector2(80 + i * 280, 40)
		btn.size = Vector2(240, 140)
		btn.add_theme_font_size_override("font_size", 16)

		# 样式根据状态
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(6)
		sb.set_border_width_all(4)

		if node_data["completed"]:
			# 已完成 - 灰色
			sb.bg_color = Color(0.1, 0.1, 0.12, 0.6)
			sb.border_color = Color(0.3, 0.3, 0.3, 0.5)
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			btn.disabled = true
		elif i == GameState.current_node_index:
			# 当前可进入 - 霓虹高亮 with glow
			sb.bg_color = Color(0.08, 0.03, 0.15, 0.9)
			sb.border_color = Color(0, 0.8, 1, 0.8)
			sb.shadow_color = Color(0, 0.6, 1, 0.4)
			sb.shadow_size = 6
			btn.add_theme_color_override("font_color", Color(0, 0.95, 1))
		else:
			# 未来节点 - 暗淡
			sb.bg_color = Color(0.05, 0.03, 0.1, 0.7)
			sb.border_color = Color(0.2, 0.1, 0.3, 0.4)
			btn.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))
			btn.disabled = true

		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("disabled", sb)

		# 节点类型图标
		var icon_text := ""
		match node_data["type"]:
			"battle": icon_text = "⚔ 战斗"
			"event_then_battle": icon_text = "📜 事件→战斗"
			"boss": icon_text = "💀 Boss"
			_: icon_text = "？"
		var type_lbl := Label.new()
		type_lbl.text = icon_text
		type_lbl.position = Vector2(10, 90)
		type_lbl.size = Vector2(220, 30)
		type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		type_lbl.add_theme_font_size_override("font_size", 12)
		type_lbl.add_theme_color_override("font_color", Color(0.6, 0.5, 0.7))
		type_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(type_lbl)

		var idx := i
		btn.pressed.connect(_on_node_pressed.bind(idx))
		route_container.add_child(btn)
		node_buttons.append(btn)

		# Neon glow animation on current node
		if i == GameState.current_node_index and not node_data["completed"]:
			_animate_current_node_glow(btn, sb)

	# Player sprite on current node
	_add_player_sprite(route_container)

	# 玩家状态面板 - EVA styled borders
	var status_panel := Panel.new()
	status_panel.position = Vector2(40, 540)
	status_panel.size = Vector2(1200, 100)
	var sp_sb := StyleBoxFlat.new()
	sp_sb.bg_color = Color(0.04, 0.02, 0.1, 0.85)
	sp_sb.border_color = Color(0.4, 0.1, 0.6, 0.6)
	sp_sb.set_border_width_all(2)
	sp_sb.border_width_top = 3
	sp_sb.set_corner_radius_all(2)
	sp_sb.shadow_color = Color(0.3, 0.05, 0.5, 0.3)
	sp_sb.shadow_size = 4
	status_panel.add_theme_stylebox_override("panel", sp_sb)
	add_child(status_panel)

	# EVA-style top accent line on status panel
	var accent_line := ColorRect.new()
	accent_line.position = Vector2(2, 0)
	accent_line.size = Vector2(1196, 2)
	accent_line.color = Color(0.9, 0.5, 0.1, 0.6)
	status_panel.add_child(accent_line)

	hp_label = Label.new()
	hp_label.text = "❤ 生命: " + str(GameState.player_hp) + "/" + str(GameState.player_max_hp)
	hp_label.position = Vector2(30, 16)
	hp_label.add_theme_font_size_override("font_size", 20)
	hp_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	status_panel.add_child(hp_label)

	gold_label = Label.new()
	gold_label.text = "◆ 金币: " + str(GameState.player_gold)
	gold_label.position = Vector2(360, 16)
	gold_label.add_theme_font_size_override("font_size", 20)
	gold_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	status_panel.add_child(gold_label)

	var deck_info := Label.new()
	deck_info.text = "◈ 牌组: " + str(GameState.player_deck.size()) + "张"
	deck_info.position = Vector2(640, 16)
	deck_info.add_theme_font_size_override("font_size", 20)
	deck_info.add_theme_color_override("font_color", Color(0.5, 0.7, 1))
	status_panel.add_child(deck_info)

	# 查看牌组按钮 - styled
	deck_btn = Button.new()
	deck_btn.text = "查看/编辑牌组"
	deck_btn.position = Vector2(920, 16)
	deck_btn.size = Vector2(240, 60)
	deck_btn.add_theme_font_size_override("font_size", 16)
	deck_btn.add_theme_color_override("font_color", Color(0, 0.9, 1))
	var deck_sb := StyleBoxFlat.new()
	deck_sb.bg_color = Color(0.06, 0.03, 0.12, 0.8)
	deck_sb.border_color = Color(0, 0.6, 0.8, 0.5)
	deck_sb.set_border_width_all(2)
	deck_sb.set_corner_radius_all(4)
	deck_btn.add_theme_stylebox_override("normal", deck_sb)
	var deck_sb_h := deck_sb.duplicate() as StyleBoxFlat
	deck_sb_h.border_color = Color(0, 0.9, 1, 0.8)
	deck_sb_h.shadow_color = Color(0, 0.5, 0.8, 0.3)
	deck_sb_h.shadow_size = 4
	deck_btn.add_theme_stylebox_override("hover", deck_sb_h)
	deck_btn.pressed.connect(_on_deck_pressed)
	status_panel.add_child(deck_btn)

	# Bottom separator
	var sep_line := ColorRect.new()
	sep_line.position = Vector2(40, 648)
	sep_line.size = Vector2(1200, 2)
	sep_line.color = Color(0.4, 0.1, 0.6, 0.3)
	add_child(sep_line)

	# 提示文字
	info_label = Label.new()
	info_label.text = "选择下一个节点继续探索..."
	info_label.position = Vector2(0, 660)
	info_label.size = Vector2(1280, 40)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	add_child(info_label)

	# CRT shader overlay
	var crt_overlay := ColorRect.new()
	crt_overlay.set_anchors_preset(PRESET_FULL_RECT)
	crt_overlay.z_index = 90
	crt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var crt_mat := ShaderMaterial.new()
	crt_mat.shader = load("res://Shaders/crt.gdshader")
	crt_overlay.material = crt_mat
	add_child(crt_overlay)

	# 检查是否全部完成
	if GameState.current_node_index >= GameState.MAX_NODES:
		info_label.text = "所有节点已完成！前往最终战斗..."
		# 直接切换，绕过 is_transitioning 锁（可能在上一次过渡中未重置）
		Global.is_transitioning = false
		get_tree().change_scene_to_file(Global.SCENE_VICTORY)

func _create_circuit_bg() -> void:
	# Subtle circuit board pattern using thin lines
	for i in range(8):
		var h_line := ColorRect.new()
		h_line.position = Vector2(0, 80 + i * 90)
		h_line.size = Vector2(1280, 1)
		h_line.color = Color(0.08, 0.04, 0.15, 0.15)
		h_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(h_line)
	for i in range(12):
		var v_line := ColorRect.new()
		v_line.position = Vector2(60 + i * 110, 0)
		v_line.size = Vector2(1, 720)
		v_line.color = Color(0.06, 0.03, 0.12, 0.12)
		v_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(v_line)

func _create_atmospheric_particles() -> void:
	var data_chars := "01道阴阳◎△▽"
	for i in range(20):
		var lbl := Label.new()
		lbl.text = data_chars[randi() % data_chars.length()]
		lbl.position = Vector2(randf() * 1280, randf() * 720)
		lbl.add_theme_font_size_override("font_size", randi_range(8, 14))
		lbl.add_theme_color_override("font_color", Color(0, 0.5, 0.7, randf_range(0.05, 0.15)))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lbl)
		move_child(lbl, 1)
		particle_labels.append(lbl)

func _animate_connection_lines() -> void:
	for i in range(connection_lines.size()):
		var line: ColorRect = connection_lines[i]
		var tween := create_tween().set_loops()
		tween.tween_property(line, "color", Color(0.5, 0.2, 0.7, 0.6), 1.2 + i * 0.3)
		tween.tween_property(line, "color", Color(0.15, 0.4, 0.6, 0.4), 1.2 + i * 0.3)

func _animate_current_node_glow(_btn: Button, sb: StyleBoxFlat) -> void:
	current_node_glow_tween = create_tween().set_loops()
	current_node_glow_tween.tween_method(func(v: float):
		sb.border_color = Color(0, 0.6 + v * 0.4, 1, 0.6 + v * 0.3)
		sb.shadow_color = Color(0, 0.4 + v * 0.4, 1, 0.2 + v * 0.3)
		sb.shadow_size = int(4 + v * 6)
	, 0.0, 1.0, 1.0)
	current_node_glow_tween.tween_method(func(v: float):
		sb.border_color = Color(0, 0.6 + v * 0.4, 1, 0.6 + v * 0.3)
		sb.shadow_color = Color(0, 0.4 + v * 0.4, 1, 0.2 + v * 0.3)
		sb.shadow_size = int(4 + v * 6)
	, 1.0, 0.0, 1.0)

func _add_player_sprite(route_container: Control) -> void:
	if GameState.current_node_index < GameState.map_nodes.size():
		var _ai_p := AssetLoader.get_character_sprite("player", 0)
		var player_tex: ImageTexture = _ai_p if _ai_p else PixelArtGenerator.generate_character_sprite("player", 0)
		var player_icon := TextureRect.new()
		player_icon.texture = player_tex
		player_icon.position = Vector2(176 + GameState.current_node_index * 280, 2)
		player_icon.size = Vector2(32, 42)
		player_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		player_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		route_container.add_child(player_icon)
		# Gentle bob animation
		var bob_tween := create_tween().set_loops()
		bob_tween.tween_property(player_icon, "position:y", -2.0, 0.8).set_trans(Tween.TRANS_SINE)
		bob_tween.tween_property(player_icon, "position:y", 2.0, 0.8).set_trans(Tween.TRANS_SINE)

func _process(delta: float) -> void:
	# Animate floating data particles
	for lbl in particle_labels:
		lbl.position.y -= delta * randf_range(15, 40)
		if lbl.position.y < -20:
			lbl.position.y = 740
			lbl.position.x = randf() * 1280

func _on_node_pressed(idx: int) -> void:
	if idx != GameState.current_node_index:
		return
	var node_data: Dictionary = GameState.map_nodes[idx]
	GameState.save_game()

	match node_data["type"]:
		"battle", "boss":
			Global.change_scene(Global.SCENE_BATTLE)
		"event_then_battle":
			Global.change_scene(Global.SCENE_EVENT)
		_:
			Global.change_scene(Global.SCENE_BATTLE)

func _on_deck_pressed() -> void:
	Global.change_scene(Global.SCENE_DECK_BUILDER)
