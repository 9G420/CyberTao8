# ============================================================
# CardReward.gd - STS式战斗胜利奖励界面
# 横幅 "战斗胜利!" → 金币奖励动画 → 3选1大卡展示
# ============================================================
extends Control

var reward_cards: Array[String] = []
var card_panels: Array[Panel] = []
var banner_label: Label
var gold_label: Label
var gold_reward: int = 0
var skip_btn: Button
var continue_btn: Button
var card_picked: bool = false

func _ready() -> void:
	_build_bg()
	_generate_rewards()
	_play_victory_sequence()

func _build_bg() -> void:
	# 暗色背景
	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.02, 0.06)
	add_child(bg)

	# 背景装饰粒子
	var ambient_chars: String = "道☯◎△▽⚡✦"
	for i in range(12):
		var lbl := Label.new()
		lbl.text = ambient_chars[randi() % ambient_chars.length()]
		lbl.position = Vector2(randf() * 1280, randf() * 720)
		lbl.add_theme_font_size_override("font_size", randi_range(16, 36))
		lbl.add_theme_color_override("font_color", Color(0.1, 0.05, 0.2, randf_range(0.03, 0.08)))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lbl)

	# CRT overlay
	var crt_overlay := ColorRect.new()
	crt_overlay.set_anchors_preset(PRESET_FULL_RECT)
	crt_overlay.z_index = 90
	crt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crt_overlay.color = Color(0, 0, 0, 0)
	var crt_shader = load("res://Shaders/crt.gdshader")
	if crt_shader:
		var crt_mat := ShaderMaterial.new()
		crt_mat.shader = crt_shader
		crt_overlay.material = crt_mat
	add_child(crt_overlay)

func _generate_rewards() -> void:
	# 金币奖励
	gold_reward = randi_range(10, 25) + GameState.map_current_floor * 2

	# 生成3张奖励卡 (偏向缺少的类型)
	var pool: Array = GameState.available_pool.duplicate()
	if pool.is_empty():
		return

	# 统计牌组类型分布
	var type_counts := {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}
	for path in GameState.player_deck:
		var cd: CardData = load(path) if ResourceLoader.exists(path) else null
		if cd:
			type_counts[cd.card_type] = type_counts.get(cd.card_type, 0) + 1

	# 加权选取
	var weighted: Array[Dictionary] = []
	for path in pool:
		var cd: CardData = load(path) if ResourceLoader.exists(path) else null
		if cd == null:
			continue
		var type_w: float = 1.0 / (1.0 + type_counts.get(cd.card_type, 0))
		var rarity_w: float = 1.0 + cd.rarity * 0.3
		weighted.append({"path": path, "weight": type_w * rarity_w})

	weighted.sort_custom(func(a, b): return a["weight"] > b["weight"])
	var candidates: Array = weighted.slice(0, mini(9, weighted.size()))
	candidates.shuffle()

	for i in range(mini(3, candidates.size())):
		reward_cards.append(candidates[i]["path"])

func _play_victory_sequence() -> void:
	AudioManager.play_sfx_generated("victory")

	# ── 阶段1: 胜利横幅 ──
	var banner_bg := ColorRect.new()
	banner_bg.position = Vector2(0, 0)
	banner_bg.size = Vector2(1280, 720)
	banner_bg.color = Color(0, 0, 0, 0.5)
	banner_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_bg.modulate.a = 0
	banner_bg.name = "BannerDim"
	add_child(banner_bg)

	# 横幅面板
	var banner_panel := Panel.new()
	banner_panel.position = Vector2(290, 60)
	banner_panel.size = Vector2(700, 70)
	var bp_sb := StyleBoxFlat.new()
	bp_sb.bg_color = Color(0.1, 0.06, 0.02, 0.92)
	bp_sb.border_color = Color(0.8, 0.6, 0.15, 0.8)
	bp_sb.set_border_width_all(3)
	bp_sb.border_width_bottom = 5
	bp_sb.set_corner_radius_all(3)
	bp_sb.shadow_color = Color(0.9, 0.7, 0.2, 0.35)
	bp_sb.shadow_size = 8
	banner_panel.add_theme_stylebox_override("panel", bp_sb)
	banner_panel.modulate.a = 0
	banner_panel.scale = Vector2(0.5, 0.5)
	banner_panel.pivot_offset = Vector2(350, 35)
	add_child(banner_panel)

	# 顶部金线
	var top_line := ColorRect.new()
	top_line.position = Vector2(3, 0)
	top_line.size = Vector2(694, 2)
	top_line.color = Color(1, 0.85, 0.3, 0.6)
	top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_panel.add_child(top_line)

	banner_label = Label.new()
	banner_label.text = "战 斗 胜 利 ！"
	banner_label.position = Vector2(0, 0)
	banner_label.size = Vector2(700, 70)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_label.add_theme_font_size_override("font_size", 36)
	banner_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	banner_label.add_theme_color_override("font_shadow_color", Color(0.5, 0.3, 0, 0.5))
	banner_label.add_theme_constant_override("shadow_offset_x", 2)
	banner_label.add_theme_constant_override("shadow_offset_y", 3)
	banner_panel.add_child(banner_label)

	# 横幅缩放入场动画
	var banner_tw: Tween = banner_panel.create_tween()
	banner_tw.set_parallel(true)
	banner_tw.tween_property(banner_panel, "modulate:a", 1.0, 0.5)
	banner_tw.tween_property(banner_panel, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	banner_tw.tween_property(banner_bg, "modulate:a", 1.0, 0.3)
	await banner_tw.finished

	await get_tree().create_timer(0.6).timeout

	# ── 阶段2: 金币奖励 ──
	GameState.player_gold += gold_reward

	gold_label = Label.new()
	gold_label.text = "◆ +" + str(gold_reward) + " 金币"
	gold_label.position = Vector2(0, 150)
	gold_label.size = Vector2(1280, 44)
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 24)
	gold_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	gold_label.add_theme_color_override("font_shadow_color", Color(0.5, 0.35, 0.0, 0.4))
	gold_label.add_theme_constant_override("shadow_offset_x", 1)
	gold_label.add_theme_constant_override("shadow_offset_y", 2)
	gold_label.modulate.a = 0
	add_child(gold_label)

	var gold_tw: Tween = gold_label.create_tween()
	gold_tw.tween_property(gold_label, "modulate:a", 1.0, 0.4)
	await gold_tw.finished

	AudioManager.play_sfx_generated("bell")
	await get_tree().create_timer(0.5).timeout

	# ── 阶段3: "选择一张卡牌" 横幅 ──
	var pick_banner := Label.new()
	pick_banner.text = "── 选择一张卡牌加入牌组 ──"
	pick_banner.position = Vector2(0, 200)
	pick_banner.size = Vector2(1280, 36)
	pick_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pick_banner.add_theme_font_size_override("font_size", 20)
	pick_banner.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	pick_banner.modulate.a = 0
	add_child(pick_banner)

	var pb_tw: Tween = pick_banner.create_tween()
	pb_tw.tween_property(pick_banner, "modulate:a", 1.0, 0.3)
	await pb_tw.finished

	# ── 阶段4: 3张大卡展示 ──
	_show_reward_cards()

	# ── 跳过按钮 ──
	skip_btn = UIFactory.make_arrow_button("跳过奖励 →", 200, 44)
	skip_btn.position = Vector2(540, 640)
	skip_btn.modulate.a = 0
	skip_btn.pressed.connect(_on_skip)
	add_child(skip_btn)

	var skip_tw: Tween = skip_btn.create_tween()
	skip_tw.tween_property(skip_btn, "modulate:a", 1.0, 0.3)

func _show_reward_cards() -> void:
	if reward_cards.is_empty():
		_show_continue_button()
		return

	var card_count: int = reward_cards.size()
	var card_w: float = 220.0
	var card_h: float = 360.0
	var spacing: float = 40.0
	var total_w: float = card_count * card_w + (card_count - 1) * spacing
	var start_x: float = (1280.0 - total_w) * 0.5

	for i in range(card_count):
		var card_path: String = reward_cards[i]
		var cd: CardData = load(card_path) if ResourceLoader.exists(card_path) else null
		if cd == null:
			continue

		var panel := _create_reward_card(cd, card_path, i)
		var target_x: float = start_x + i * (card_w + spacing)
		panel.position = Vector2(target_x, 250)
		panel.modulate.a = 0
		panel.scale = Vector2(0.7, 0.7)
		panel.pivot_offset = Vector2(card_w * 0.5, card_h * 0.5)
		add_child(panel)
		card_panels.append(panel)

		# 依次入场动画 (带延迟)
		var delay: float = i * 0.15
		var tw: Tween = panel.create_tween()
		tw.tween_interval(delay)
		tw.set_parallel(false)
		tw.tween_property(panel, "modulate:a", 1.0, 0.3)
		tw.set_parallel(true)
		tw.tween_property(panel, "scale", Vector2(1, 1), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _create_reward_card(cd: CardData, card_path: String, _idx: int) -> Panel:
	var card_w: float = 220.0
	var card_h: float = 360.0

	var panel := Panel.new()
	panel.size = Vector2(card_w, card_h)

	# 卡牌边框颜色根据卡牌自身色 (每张卡唯一)
	var accent: Color = cd.card_color
	if accent == Color.WHITE or accent == Color.BLACK:
		match cd.card_type:
			CardData.CardType.ATTACK: accent = Color(0.8, 0.25, 0.2)
			CardData.CardType.DEFENSE: accent = Color(0.2, 0.5, 0.8)
			CardData.CardType.SPELL: accent = Color(0.6, 0.3, 0.8)
			CardData.CardType.POWER: accent = Color(0.8, 0.7, 0.2)
			CardData.CardType.SUMMON: accent = Color(0.2, 0.7, 0.35)
			_: accent = Color(0.5, 0.5, 0.5)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r * 0.12 + 0.03, accent.g * 0.12 + 0.02, accent.b * 0.12 + 0.05, 0.92)
	sb.border_color = accent
	sb.set_border_width_all(3)
	sb.border_width_top = 4
	sb.set_corner_radius_all(6)
	sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.3)
	sb.shadow_size = 6
	panel.add_theme_stylebox_override("panel", sb)

	# 费用宝珠 (左上角)
	var cost_str: String = "X" if cd.cost == -1 else str(cd.cost)
	var cost_lbl := Label.new()
	cost_lbl.text = cost_str
	cost_lbl.position = Vector2(8, 6)
	cost_lbl.size = Vector2(32, 32)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_lbl.add_theme_font_size_override("font_size", 18)
	cost_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 1))
	panel.add_child(cost_lbl)

	# 费用背景圆
	var cost_bg := ColorRect.new()
	cost_bg.position = Vector2(8, 6)
	cost_bg.size = Vector2(30, 30)
	cost_bg.color = Color(0.15, 0.08, 0.3, 0.8)
	cost_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_bg.z_index = -1
	panel.add_child(cost_bg)

	# 卡面缩略图 (用card_id作为seed, 保证每张卡像素画独特)
	var card_art := TextureRect.new()
	var art_seed: int = cd.card_id.hash() if cd.card_id != "" else card_path.hash()
	var _ai_art := AssetLoader.get_card_art(cd.card_type, cd.yinyang, cd.rarity, art_seed, cd.card_id)
	card_art.texture = _ai_art if _ai_art else PixelArtGenerator.generate_card_art(
		cd.card_type, cd.yinyang, cd.rarity, art_seed
	)
	card_art.position = Vector2(50, 40)
	card_art.size = Vector2(120, 120)
	card_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.add_child(card_art)

	# 分隔线
	var sep := ColorRect.new()
	sep.position = Vector2(12, 165)
	sep.size = Vector2(card_w - 24, 1)
	sep.color = Color(accent.r, accent.g, accent.b, 0.4)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sep)

	# 卡名
	var name_lbl := Label.new()
	name_lbl.text = cd.card_name
	name_lbl.position = Vector2(0, 170)
	name_lbl.size = Vector2(card_w, 28)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", cd.get_rarity_color())
	panel.add_child(name_lbl)

	# 类型 | 阴阳
	var type_lbl := Label.new()
	type_lbl.text = cd.get_type_text() + " | " + cd.get_yinyang_text()
	type_lbl.position = Vector2(0, 196)
	type_lbl.size = Vector2(card_w, 20)
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_font_size_override("font_size", 12)
	type_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	panel.add_child(type_lbl)

	# 描述
	var desc_lbl := Label.new()
	desc_lbl.text = cd.description
	desc_lbl.position = Vector2(12, 220)
	desc_lbl.size = Vector2(card_w - 24, 50)
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.clip_text = true
	panel.add_child(desc_lbl)

	# 数值
	var stats_text: String = ""
	match cd.card_type:
		CardData.CardType.ATTACK:
			if cd.multi_hit > 0:
				stats_text = "伤害: " + str(cd.attack_power) + " ×" + str(cd.multi_hit)
			else:
				stats_text = "伤害: " + str(cd.attack_power)
		CardData.CardType.DEFENSE:
			stats_text = "护盾: " + str(cd.defense_power)
		CardData.CardType.SUMMON:
			stats_text = "攻: " + str(cd.attack_power) + "  血: " + str(cd.summon_hp)
		CardData.CardType.SPELL:
			stats_text = "术法效果"
		CardData.CardType.POWER:
			stats_text = "永久效果"

	var stats_lbl := Label.new()
	stats_lbl.text = stats_text
	stats_lbl.position = Vector2(0, 275)
	stats_lbl.size = Vector2(card_w, 22)
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.add_theme_font_size_override("font_size", 14)
	stats_lbl.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
	panel.add_child(stats_lbl)

	# 关键词
	var kw: String = cd.get_keywords_text()
	if kw != "":
		var kw_lbl := Label.new()
		kw_lbl.text = kw
		kw_lbl.position = Vector2(0, 296)
		kw_lbl.size = Vector2(card_w, 18)
		kw_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kw_lbl.add_theme_font_size_override("font_size", 11)
		kw_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 0.8))
		panel.add_child(kw_lbl)

	# 选择按钮
	var pick_btn: Button = UIFactory.make_green_button("选择此卡", 180, 38)
	pick_btn.position = Vector2((card_w - 180) * 0.5, card_h - 48)
	var path_copy: String = card_path
	pick_btn.pressed.connect(_on_pick_card.bind(path_copy, panel))
	panel.add_child(pick_btn)

	# ── 悬停缩放效果 (STS风格) ──
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var _sb_ref: StyleBoxFlat = sb
	var _normal_border: Color = sb.border_color
	var _bright_border := Color(
		clampf(accent.r + 0.3, 0.0, 1.0),
		clampf(accent.g + 0.3, 0.0, 1.0),
		clampf(accent.b + 0.3, 0.0, 1.0), 1.0)
	var _hover_active: Array[bool] = [false]
	var _rest_y: Array[float] = [250.0]
	panel.mouse_entered.connect(func():
		if not _hover_active[0]:
			_rest_y[0] = panel.position.y
		_hover_active[0] = true
		var tw: Tween = panel.create_tween()
		tw.set_parallel(true)
		tw.tween_property(panel, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(panel, "position:y", _rest_y[0] - 10, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_sb_ref.border_color = _bright_border
		_sb_ref.shadow_size = 12
	)
	panel.mouse_exited.connect(func():
		_hover_active[0] = false
		var tw: Tween = panel.create_tween()
		tw.set_parallel(true)
		tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(panel, "position:y", _rest_y[0], 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_sb_ref.border_color = _normal_border
		_sb_ref.shadow_size = 6
	)

	return panel

func _on_pick_card(card_path: String, _panel: Panel) -> void:
	if card_picked:
		return
	card_picked = true

	# 加入牌组
	GameState.player_deck.append(card_path)
	GameState.available_pool.erase(card_path)

	# 获得卡名
	var cd: CardData = load(card_path) if ResourceLoader.exists(card_path) else null
	var card_name: String = cd.card_name if cd else "未知"

	# 禁用所有选择按钮 + 其他卡牌淡出
	for p in card_panels:
		if p == _panel:
			# 选中的卡牌高亮动画
			var tw: Tween = p.create_tween()
			tw.tween_property(p, "modulate", Color(1, 1, 0.8, 1), 0.3)
		else:
			var tw: Tween = p.create_tween()
			tw.tween_property(p, "modulate:a", 0.3, 0.4)
		# 禁用按钮
		for child in p.get_children():
			if child is Button:
				child.disabled = true

	# 隐藏跳过按钮
	if skip_btn:
		skip_btn.visible = false

	# 显示获得提示
	var got_lbl := Label.new()
	got_lbl.text = "已获得: " + card_name
	got_lbl.position = Vector2(0, 620)
	got_lbl.size = Vector2(1280, 36)
	got_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	got_lbl.add_theme_font_size_override("font_size", 20)
	got_lbl.add_theme_color_override("font_color", Color(0.3, 1, 0.5))
	got_lbl.modulate.a = 0
	add_child(got_lbl)

	var lbl_tw: Tween = got_lbl.create_tween()
	lbl_tw.tween_property(got_lbl, "modulate:a", 1.0, 0.3)
	await lbl_tw.finished

	await get_tree().create_timer(0.8).timeout
	_proceed_to_map()

func _on_skip() -> void:
	if card_picked:
		return
	card_picked = true
	_proceed_to_map()

func _proceed_to_map() -> void:
	GameState.advance_node()
	GameState.save_game()
	Global.is_transitioning = false
	get_tree().change_scene_to_file(Global.SCENE_MAP)

func _show_continue_button() -> void:
	continue_btn = UIFactory.make_ribbon_button("继续", 220, 50)
	continue_btn.position = Vector2(530, 400)
	continue_btn.pressed.connect(_proceed_to_map)
	add_child(continue_btn)
