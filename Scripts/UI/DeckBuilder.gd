# ============================================================
# DeckBuilder.gd - 牌组构筑界面（v5 完整适配102张卡池）
# 类型筛选标签 + 费用/稀有度排序 + 点击查看详情
# 关键词/多段/X费/消耗/固有/保留 完整显示
# CRT overlay 安全处理（透明fallback）
# ============================================================
extends Control

var deck_container: GridContainer
var scroll_ref: ScrollContainer
var info_label: RichTextLabel
var back_btn: Button
var summary_label: Label
var card_panels: Array[PanelContainer] = []

# 筛选/排序状态
var current_filter: int = -1  # -1=全部, 0=ATTACK, 1=DEFENSE, 2=SUMMON, 3=SPELL, 4=POWER
var current_sort: int = 0     # 0=费用升序, 1=稀有度降序, 2=类型分组
var filter_buttons: Array[Button] = []
var sort_buttons: Array[Button] = []

# 预加载牌组数据（避免重复load）
var _deck_data: Array[Dictionary] = []  # [{path, card_data}]

func _ready() -> void:
	_preload_deck_data()
	_build_ui()

func _preload_deck_data() -> void:
	_deck_data.clear()
	for card_path in GameState.player_deck:
		var cd: CardData = load(card_path) if ResourceLoader.exists(card_path) else null
		_deck_data.append({"path": card_path, "card_data": cd})

func _build_ui() -> void:
	# 背景
	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.02, 0.08)
	add_child(bg)

	# Atmospheric background elements
	_create_atmospheric_bg()

	# 标题 with EVA styling
	var title := Label.new()
	title.text = "═══ 牌 组 构 筑 ═══"
	title.position = Vector2(0, 6)
	title.size = Vector2(1280, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0, 0.9, 1))
	title.add_theme_color_override("font_shadow_color", Color(0, 0.4, 0.7, 0.4))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	add_child(title)

	# 统计摘要
	summary_label = Label.new()
	summary_label.position = Vector2(0, 38)
	summary_label.size = Vector2(1280, 26)
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_label.add_theme_font_size_override("font_size", 13)
	summary_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	add_child(summary_label)
	_update_summary()

	# === 筛选标签行 (y:62) ===
	var filter_y := 62
	var filter_labels := ["全部", "攻击", "防御", "召唤", "术法", "能力"]
	var filter_colors := [
		Color(0, 0.9, 1),       # 全部-青
		Color(1, 0.4, 0.3),     # 攻击-红
		Color(0.3, 0.8, 1),     # 防御-蓝
		Color(0.7, 0.5, 1),     # 召唤-紫
		Color(0.4, 1, 0.6),     # 术法-绿
		Color(1, 0.85, 0.2),    # 能力-金
	]
	var fx := 40
	for i in range(filter_labels.size()):
		var fb := Button.new()
		fb.text = filter_labels[i]
		fb.position = Vector2(fx, filter_y)
		fb.size = Vector2(80, 28)
		fb.add_theme_font_size_override("font_size", 12)
		var filter_idx := i - 1  # -1=全部, 0..4=types
		fb.pressed.connect(_on_filter_changed.bind(filter_idx))
		_style_filter_button(fb, filter_colors[i], i == 0)
		add_child(fb)
		filter_buttons.append(fb)
		fx += 88

	# === 排序按钮 (右侧) ===
	var sort_labels := ["费用↑", "稀有度↓", "按类型"]
	var sx := 810
	for i in range(sort_labels.size()):
		var sb_btn := Button.new()
		sb_btn.text = sort_labels[i]
		sb_btn.position = Vector2(sx, filter_y)
		sb_btn.size = Vector2(80, 28)
		sb_btn.add_theme_font_size_override("font_size", 12)
		sb_btn.pressed.connect(_on_sort_changed.bind(i))
		_style_sort_button(sb_btn, i == 0)
		add_child(sb_btn)
		sort_buttons.append(sb_btn)
		sx += 88

	# 分隔线
	var sep := ColorRect.new()
	sep.position = Vector2(40, 94)
	sep.size = Vector2(1200, 1)
	sep.color = Color(0.3, 0.15, 0.5, 0.3)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep)

	# 滚动容器
	scroll_ref = ScrollContainer.new()
	scroll_ref.position = Vector2(40, 98)
	scroll_ref.size = Vector2(1200, 480)
	add_child(scroll_ref)

	deck_container = GridContainer.new()
	deck_container.columns = 4
	deck_container.add_theme_constant_override("h_separation", 18)
	deck_container.add_theme_constant_override("v_separation", 18)
	scroll_ref.add_child(deck_container)

	# 填充卡牌
	_refresh_card_grid()

	# 信息标签（底部详情区）
	info_label = RichTextLabel.new()
	info_label.bbcode_enabled = true
	info_label.position = Vector2(40, 594)
	info_label.size = Vector2(800, 80)
	info_label.add_theme_font_size_override("normal_font_size", 13)
	info_label.add_theme_color_override("default_color", Color(0.6, 0.6, 0.7))
	var info_sb := StyleBoxFlat.new()
	info_sb.bg_color = Color(0.03, 0.02, 0.07, 0.6)
	info_sb.border_color = Color(0.2, 0.1, 0.3, 0.3)
	info_sb.set_border_width_all(1)
	info_sb.content_margin_left = 10
	info_sb.content_margin_top = 6
	info_sb.content_margin_right = 10
	info_sb.content_margin_bottom = 6
	info_label.add_theme_stylebox_override("normal", info_sb)
	add_child(info_label)
	info_label.text = "点击卡牌查看详情。使用上方标签筛选类型，右侧按钮排序。"

	# 返回按钮
	back_btn = UIFactory.make_cyan_button("返回地图", 260, 56)
	back_btn.position = Vector2(960, 620)
	back_btn.pressed.connect(_on_back)
	add_child(back_btn)

	# CRT shader overlay — 必须先设透明color再赋material
	var crt_overlay := ColorRect.new()
	crt_overlay.set_anchors_preset(PRESET_FULL_RECT)
	crt_overlay.color = Color(0, 0, 0, 0)  # 安全fallback：shader失败不会白屏
	crt_overlay.z_index = 6
	crt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var crt_shader = load("res://Shaders/crt.gdshader")
	if crt_shader:
		var crt_mat := ShaderMaterial.new()
		crt_mat.shader = crt_shader
		crt_overlay.material = crt_mat
	add_child(crt_overlay)

func _update_summary() -> void:
	var atk_count := 0
	var def_count := 0
	var sum_count := 0
	var spl_count := 0
	var pow_count := 0
	var avg_cost := 0.0
	var valid := 0
	for entry in _deck_data:
		var cd: CardData = entry["card_data"]
		if cd:
			valid += 1
			var c: int = cd.cost if cd.cost >= 0 else 0
			avg_cost += c
			match cd.card_type:
				CardData.CardType.ATTACK: atk_count += 1
				CardData.CardType.DEFENSE: def_count += 1
				CardData.CardType.SUMMON: sum_count += 1
				CardData.CardType.SPELL: spl_count += 1
				CardData.CardType.POWER: pow_count += 1
	if valid > 0:
		avg_cost = avg_cost / float(valid)
	var total := _deck_data.size()
	summary_label.text = (
		"牌组: " + str(total) + "张 | "
		+ "攻击:" + str(atk_count) + " 防御:" + str(def_count)
		+ " 召唤:" + str(sum_count) + " 术法:" + str(spl_count)
		+ " 能力:" + str(pow_count)
		+ " | 均费:" + ("%.1f" % avg_cost)
	)

func _get_filtered_sorted_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in _deck_data:
		var cd: CardData = entry["card_data"]
		if current_filter == -1:
			result.append(entry)
		elif cd and cd.card_type == current_filter:
			result.append(entry)
		elif cd == null and current_filter == -1:
			result.append(entry)
	# 排序
	match current_sort:
		0:  # 费用升序
			result.sort_custom(func(a, b):
				var ca: CardData = a["card_data"]
				var cb: CardData = b["card_data"]
				if ca == null: return false
				if cb == null: return true
				var cost_a: int = ca.cost if ca.cost >= 0 else 99
				var cost_b: int = cb.cost if cb.cost >= 0 else 99
				if cost_a != cost_b: return cost_a < cost_b
				return ca.card_name < cb.card_name
			)
		1:  # 稀有度降序
			result.sort_custom(func(a, b):
				var ca: CardData = a["card_data"]
				var cb: CardData = b["card_data"]
				if ca == null: return false
				if cb == null: return true
				if ca.rarity != cb.rarity: return ca.rarity > cb.rarity
				return ca.card_name < cb.card_name
			)
		2:  # 类型分组
			result.sort_custom(func(a, b):
				var ca: CardData = a["card_data"]
				var cb: CardData = b["card_data"]
				if ca == null: return false
				if cb == null: return true
				if ca.card_type != cb.card_type: return ca.card_type < cb.card_type
				if ca.cost != cb.cost: return ca.cost < cb.cost
				return ca.card_name < cb.card_name
			)
	return result

func _refresh_card_grid() -> void:
	# 清空
	for child in deck_container.get_children():
		child.queue_free()
	card_panels.clear()

	var data := _get_filtered_sorted_data()
	for entry in data:
		var cd: CardData = entry["card_data"]
		var path: String = entry["path"]
		var panel := _create_card_display(cd, path)
		deck_container.add_child(panel)
		card_panels.append(panel)

	# 滚动回顶部
	scroll_ref.scroll_vertical = 0

func _on_filter_changed(filter_idx: int) -> void:
	current_filter = filter_idx
	# 更新按钮样式
	var filter_colors := [
		Color(0, 0.9, 1), Color(1, 0.4, 0.3), Color(0.3, 0.8, 1),
		Color(0.7, 0.5, 1), Color(0.4, 1, 0.6), Color(1, 0.85, 0.2),
	]
	for i in range(filter_buttons.size()):
		_style_filter_button(filter_buttons[i], filter_colors[i], (i - 1) == filter_idx)
	_refresh_card_grid()

func _on_sort_changed(sort_idx: int) -> void:
	current_sort = sort_idx
	for i in range(sort_buttons.size()):
		_style_sort_button(sort_buttons[i], i == sort_idx)
	_refresh_card_grid()

func _style_filter_button(btn: Button, accent: Color, active: bool) -> void:
	var sb := StyleBoxFlat.new()
	if active:
		sb.bg_color = Color(accent.r * 0.2, accent.g * 0.2, accent.b * 0.2, 0.8)
		sb.border_color = Color(accent.r, accent.g, accent.b, 0.9)
		btn.add_theme_color_override("font_color", accent)
	else:
		sb.bg_color = Color(0.06, 0.03, 0.12, 0.6)
		sb.border_color = Color(0.3, 0.15, 0.5, 0.3)
		btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h: StyleBoxFlat = sb.duplicate() as StyleBoxFlat
	sb_h.border_color = Color(accent.r, accent.g, accent.b, 0.7)
	btn.add_theme_stylebox_override("hover", sb_h)

func _style_sort_button(btn: Button, active: bool) -> void:
	var sb := StyleBoxFlat.new()
	if active:
		sb.bg_color = Color(0.1, 0.06, 0.18, 0.8)
		sb.border_color = Color(0, 0.9, 1, 0.7)
		btn.add_theme_color_override("font_color", Color(0, 0.9, 1))
	else:
		sb.bg_color = Color(0.06, 0.03, 0.12, 0.6)
		sb.border_color = Color(0.2, 0.1, 0.3, 0.3)
		btn.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h: StyleBoxFlat = sb.duplicate() as StyleBoxFlat
	sb_h.border_color = Color(0, 0.8, 1, 0.6)
	btn.add_theme_stylebox_override("hover", sb_h)

func _create_atmospheric_bg() -> void:
	for i in range(6):
		var h_line := ColorRect.new()
		h_line.position = Vector2(0, 100 + i * 120)
		h_line.size = Vector2(1280, 1)
		h_line.color = Color(0.06, 0.03, 0.12, 0.15)
		h_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(h_line)
	for corner_data in [
		{"pos": Vector2(10, 10), "sz": Vector2(30, 2)},
		{"pos": Vector2(10, 10), "sz": Vector2(2, 30)},
		{"pos": Vector2(1240, 10), "sz": Vector2(30, 2)},
		{"pos": Vector2(1268, 10), "sz": Vector2(2, 30)},
		{"pos": Vector2(10, 708), "sz": Vector2(30, 2)},
		{"pos": Vector2(10, 680), "sz": Vector2(2, 30)},
		{"pos": Vector2(1240, 708), "sz": Vector2(30, 2)},
		{"pos": Vector2(1268, 680), "sz": Vector2(2, 30)},
	]:
		var mark := ColorRect.new()
		mark.position = corner_data["pos"]
		mark.size = corner_data["sz"]
		mark.color = Color(0.4, 0.1, 0.6, 0.3)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(mark)

func _create_card_display(card_data: CardData, card_path: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(260, 340)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.04, 0.12, 0.8)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 8
	sb.content_margin_top = 6
	sb.content_margin_right = 8
	sb.content_margin_bottom = 6

	# Card type color for the top strip
	var type_color := Color(0.3, 0.15, 0.5, 0.6)
	if card_data:
		match card_data.card_type:
			CardData.CardType.ATTACK: type_color = Color(1, 0.4, 0.3, 0.9)
			CardData.CardType.DEFENSE: type_color = Color(0.3, 0.8, 1, 0.9)
			CardData.CardType.SUMMON: type_color = Color(0.7, 0.5, 1, 0.9)
			CardData.CardType.SPELL: type_color = Color(0.4, 1, 0.6, 0.9)
			CardData.CardType.POWER: type_color = Color(1, 0.85, 0.2, 0.9)

	if card_data:
		match card_data.yinyang:
			0:  # Yin - purple
				sb.border_color = Color(0.4, 0.1, 0.6, 0.6)
				sb.shadow_color = Color(0.3, 0.05, 0.5, 0.2)
			1:  # Yang - orange
				sb.border_color = Color(0.7, 0.4, 0.1, 0.6)
				sb.shadow_color = Color(0.5, 0.3, 0.05, 0.2)
			_:  # Neutral
				sb.border_color = Color(0.3, 0.15, 0.5, 0.5)
				sb.shadow_color = Color(0.2, 0.1, 0.3, 0.15)
		sb.shadow_size = 5
	else:
		sb.border_color = Color(0.3, 0.15, 0.5, 0.5)

	panel.add_theme_stylebox_override("panel", sb)

	# Hover
	var normal_border := sb.border_color
	panel.mouse_entered.connect(func():
		sb.border_color = Color(0, 0.9, 1, 0.8)
		sb.shadow_size = 8
		sb.shadow_color = Color(0, 0.5, 0.8, 0.3)
	)
	panel.mouse_exited.connect(func():
		sb.border_color = normal_border
		sb.shadow_size = 5
		sb.shadow_color = Color(normal_border.r, normal_border.g, normal_border.b, 0.2)
	)

	# 点击查看详情
	if card_data:
		panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_show_card_detail(card_data)
		)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	if card_data:
		# Card type colored strip at top
		var type_strip := ColorRect.new()
		type_strip.custom_minimum_size = Vector2(0, 4)
		type_strip.color = type_color
		type_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(type_strip)

		# Card art (larger and more prominent)
		var card_art := TextureRect.new()
		var _ai_db_card := AssetLoader.get_card_art(card_data.card_type, card_data.yinyang, card_data.rarity, card_path.hash(), card_data.card_id)
		card_art.texture = _ai_db_card if _ai_db_card else PixelArtGenerator.generate_card_art(
			card_data.card_type, card_data.yinyang, card_data.rarity, card_path.hash()
		)
		card_art.custom_minimum_size = Vector2(180, 100)
		card_art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vbox.add_child(card_art)

		# Cost orb overlay (top-left of card art)
		var cost_orb := _create_cost_orb(card_data)
		card_art.add_child(cost_orb)

		# 卡名（稀有度颜色）
		var name_lbl := Label.new()
		name_lbl.text = card_data.card_name
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", card_data.get_rarity_color())
		name_lbl.clip_text = true
		vbox.add_child(name_lbl)

		# 类型 | 阴阳 | 费用
		var cost_text: String = "X" if card_data.cost == -1 else str(card_data.cost)
		var info_lbl := Label.new()
		info_lbl.text = card_data.get_type_text() + " | " + card_data.get_yinyang_text() + " | " + cost_text + "算力"
		info_lbl.add_theme_font_size_override("font_size", 13)
		info_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		vbox.add_child(info_lbl)

		# 数值行（含多段显示）
		var stats_text := ""
		match card_data.card_type:
			CardData.CardType.ATTACK:
				if card_data.multi_hit > 0:
					stats_text = "⚔" + str(card_data.attack_power) + " x" + str(card_data.multi_hit)
				else:
					stats_text = "⚔" + str(card_data.attack_power)
			CardData.CardType.DEFENSE:
				stats_text = "🛡" + str(card_data.defense_power)
			CardData.CardType.SUMMON:
				stats_text = "⚔" + str(card_data.attack_power) + " ♥" + str(card_data.summon_hp)
			CardData.CardType.SPELL:
				stats_text = "✦术法"
			CardData.CardType.POWER:
				stats_text = "⚡永久效果"
		var stats_lbl := Label.new()
		stats_lbl.text = stats_text
		stats_lbl.add_theme_font_size_override("font_size", 16)
		stats_lbl.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
		vbox.add_child(stats_lbl)

		# 关键词标签（消耗/固有/保留/弃牌触发）
		var kw_text := card_data.get_keywords_text()
		if kw_text != "":
			var kw_lbl := Label.new()
			kw_lbl.text = kw_text
			kw_lbl.add_theme_font_size_override("font_size", 12)
			kw_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 0.8))
			vbox.add_child(kw_lbl)

		# Description text
		var desc_lbl := Label.new()
		desc_lbl.text = card_data.description
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.custom_minimum_size = Vector2(240, 0)
		vbox.add_child(desc_lbl)
	else:
		var err := Label.new()
		err.text = "数据损坏"
		err.add_theme_font_size_override("font_size", 14)
		err.add_theme_color_override("font_color", Color(0.5, 0.3, 0.3))
		vbox.add_child(err)

	panel.add_child(vbox)
	return panel

func _create_cost_orb(card_data: CardData) -> Control:
	var orb := Control.new()
	orb.position = Vector2(2, 2)
	orb.custom_minimum_size = Vector2(28, 28)
	orb.size = Vector2(28, 28)
	orb.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Orb background circle
	var orb_bg := ColorRect.new()
	orb_bg.position = Vector2.ZERO
	orb_bg.size = Vector2(28, 28)
	orb_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Color based on card type
	match card_data.card_type:
		CardData.CardType.ATTACK: orb_bg.color = Color(0.8, 0.15, 0.1, 0.9)
		CardData.CardType.DEFENSE: orb_bg.color = Color(0.1, 0.4, 0.8, 0.9)
		CardData.CardType.SUMMON: orb_bg.color = Color(0.5, 0.2, 0.8, 0.9)
		CardData.CardType.SPELL: orb_bg.color = Color(0.1, 0.7, 0.3, 0.9)
		CardData.CardType.POWER: orb_bg.color = Color(0.8, 0.65, 0.05, 0.9)
		_: orb_bg.color = Color(0.3, 0.3, 0.3, 0.9)
	orb.add_child(orb_bg)

	# Cost label
	var cost_lbl := Label.new()
	var cost_str: String = "X" if card_data.cost == -1 else str(card_data.cost)
	cost_lbl.text = cost_str
	cost_lbl.add_theme_font_size_override("font_size", 14)
	cost_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	cost_lbl.position = Vector2(0, 0)
	cost_lbl.size = Vector2(28, 28)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	orb.add_child(cost_lbl)

	return orb

func _show_card_detail(cd: CardData) -> void:
	info_label.clear()
	var rarity_names := ["普通", "罕见", "稀有"]
	var rarity_colors := ["gray", "cyan", "magenta"]
	var r_idx: int = clampi(cd.rarity, 0, 2)

	var cost_str: String = "X(全算力)" if cd.cost == -1 else str(cd.cost)
	var header: String = "[color=" + rarity_colors[r_idx] + "]【" + cd.card_name + "】[/color]"
	header += " [color=gray]" + rarity_names[r_idx] + " " + cd.get_type_text() + " | "
	header += cd.get_yinyang_text() + " | " + cost_str + "算力[/color]\n"

	var desc: String = "[color=white]" + cd.description + "[/color]"

	# 关键词
	var kw := cd.get_keywords_text()
	if kw != "":
		desc += "  [color=yellow][" + kw + "][/color]"

	# 召唤被动
	if cd.summon_passive != "":
		desc += "  [color=green]被动:" + cd.summon_passive + "[/color]"

	info_label.append_text(header + desc)

func _make_deck_button(text: String, font_color: Color, border_color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_hover_color", font_color.lightened(0.3))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.03, 0.12, 0.8)
	sb.border_color = border_color
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.2)
	sb.shadow_size = 3
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.border_color = Color(font_color.r, font_color.g, font_color.b, 0.8)
	sb_h.shadow_size = 6
	btn.add_theme_stylebox_override("hover", sb_h)
	return btn

func _on_back() -> void:
	Global.change_scene(Global.SCENE_MAP)
