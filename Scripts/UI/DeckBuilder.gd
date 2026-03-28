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

# ============================================================
# 每张卡独特UI: 用 card_id hash 生成独特色调/边框/装饰/布局
# ============================================================

## 从 card_id 提取确定性伪随机浮点 [0,1)
static func _hash_f(seed_str: String, salt: int) -> float:
	var h: int = (seed_str + str(salt)).hash()
	if h < 0:
		h = -h
	return float(h % 10000) / 10000.0

## 从 hash 生成独特色调 (HSV hue shift)
static func _card_unique_hue(card_id: String) -> float:
	return _hash_f(card_id, 7) * 360.0

## 从 hash 生成独特亮度偏移
static func _card_bright_offset(card_id: String) -> float:
	return _hash_f(card_id, 13) * 0.12 - 0.06  # [-0.06, +0.06]

func _create_card_display(card_data: CardData, card_path: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(260, 340)

	if not card_data:
		var sb_err := StyleBoxFlat.new()
		sb_err.bg_color = Color(0.08, 0.04, 0.04, 0.8)
		sb_err.border_color = Color(0.4, 0.1, 0.1, 0.5)
		sb_err.set_border_width_all(2)
		sb_err.set_corner_radius_all(4)
		sb_err.content_margin_left = 8
		sb_err.content_margin_top = 6
		sb_err.content_margin_right = 8
		sb_err.content_margin_bottom = 6
		panel.add_theme_stylebox_override("panel", sb_err)
		var err_vbox := VBoxContainer.new()
		var err := Label.new()
		err.text = "数据损坏"
		err.add_theme_font_size_override("font_size", 14)
		err.add_theme_color_override("font_color", Color(0.5, 0.3, 0.3))
		err_vbox.add_child(err)
		panel.add_child(err_vbox)
		return panel

	# ── 每张卡的独特种子 ──
	var cid: String = card_data.card_id if card_data.card_id != "" else card_path
	var unique_hue: float = _card_unique_hue(cid)
	var bright_off: float = _card_bright_offset(cid)
	var h1: float = _hash_f(cid, 1)
	var h2: float = _hash_f(cid, 2)
	var h3: float = _hash_f(cid, 3)
	var h4: float = _hash_f(cid, 4)
	var h5: float = _hash_f(cid, 5)
	var h6: float = _hash_f(cid, 6)

	# ── 类型基础色 ──
	var type_base_r: float = 0.3
	var type_base_g: float = 0.15
	var type_base_b: float = 0.5
	match card_data.card_type:
		CardData.CardType.ATTACK:
			type_base_r = 0.7
			type_base_g = 0.15
			type_base_b = 0.12
		CardData.CardType.DEFENSE:
			type_base_r = 0.1
			type_base_g = 0.3
			type_base_b = 0.65
		CardData.CardType.SUMMON:
			type_base_r = 0.45
			type_base_g = 0.15
			type_base_b = 0.65
		CardData.CardType.SPELL:
			type_base_r = 0.1
			type_base_g = 0.55
			type_base_b = 0.25
		CardData.CardType.POWER:
			type_base_r = 0.6
			type_base_g = 0.5
			type_base_b = 0.08

	# 每张卡对类型基础色做独特偏移
	var shift_r: float = (h1 - 0.5) * 0.15
	var shift_g: float = (h2 - 0.5) * 0.15
	var shift_b: float = (h3 - 0.5) * 0.15
	var bg_r: float = clampf(type_base_r * 0.12 + shift_r * 0.3 + bright_off, 0.02, 0.2)
	var bg_g: float = clampf(type_base_g * 0.12 + shift_g * 0.3 + bright_off, 0.01, 0.18)
	var bg_b: float = clampf(type_base_b * 0.12 + shift_b * 0.3 + bright_off, 0.02, 0.22)

	# ── 边框色: 阴阳 + 独特偏移 ──
	var border_r: float = type_base_r
	var border_g: float = type_base_g
	var border_b: float = type_base_b
	match card_data.yinyang:
		0:  # Yin - 偏冷
			border_r = clampf(border_r * 0.6 + h4 * 0.1, 0.1, 0.8)
			border_g = clampf(border_g * 0.5 + h5 * 0.15, 0.05, 0.6)
			border_b = clampf(border_b + 0.2 + h6 * 0.1, 0.3, 1.0)
		1:  # Yang - 偏暖
			border_r = clampf(border_r + 0.2 + h4 * 0.1, 0.4, 1.0)
			border_g = clampf(border_g * 0.7 + h5 * 0.2, 0.1, 0.8)
			border_b = clampf(border_b * 0.4 + h6 * 0.05, 0.02, 0.4)
		_:  # 中性 - 保持类型色
			border_r = clampf(border_r + (h4 - 0.5) * 0.2, 0.15, 0.9)
			border_g = clampf(border_g + (h5 - 0.5) * 0.2, 0.1, 0.8)
			border_b = clampf(border_b + (h6 - 0.5) * 0.2, 0.15, 0.9)

	# ── 稀有度影响边框宽度和圆角 ──
	var border_w: int = 2 + card_data.rarity
	var corner_r: int = 3 + int(h1 * 6.0)  # 3~8 独特圆角
	var shadow_sz: int = 3 + card_data.rarity * 3 + int(h2 * 3.0)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(bg_r, bg_g, bg_b, 0.85)
	sb.border_color = Color(border_r, border_g, border_b, 0.7 + float(card_data.rarity) * 0.12)
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(corner_r)
	sb.shadow_color = Color(border_r, border_g, border_b, 0.15 + float(card_data.rarity) * 0.1)
	sb.shadow_size = shadow_sz
	sb.content_margin_left = 8
	sb.content_margin_top = 6
	sb.content_margin_right = 8
	sb.content_margin_bottom = 6

	# 稀有卡: 不对称边框 (上边更粗)
	if card_data.rarity >= 1:
		sb.border_width_top = border_w + 2
	if card_data.rarity >= 2:
		sb.border_width_bottom = border_w + 1

	panel.add_theme_stylebox_override("panel", sb)

	# ── Hover: 用该卡的独特色高亮 ──
	var normal_border := sb.border_color
	var hover_col := Color(
		clampf(border_r + 0.3, 0.0, 1.0),
		clampf(border_g + 0.3, 0.0, 1.0),
		clampf(border_b + 0.3, 0.0, 1.0), 0.95)
	panel.mouse_entered.connect(func():
		sb.border_color = hover_col
		sb.shadow_size = shadow_sz + 5
		sb.shadow_color = Color(hover_col.r, hover_col.g, hover_col.b, 0.35)
	)
	panel.mouse_exited.connect(func():
		sb.border_color = normal_border
		sb.shadow_size = shadow_sz
		sb.shadow_color = Color(border_r, border_g, border_b, 0.15 + float(card_data.rarity) * 0.1)
	)

	# ── 点击查看详情 ──
	panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_show_card_detail(card_data)
	)

	# ── 卡牌内容 VBox ──
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	# ── 顶部色条: 独特渐变用两段拼接 ──
	var strip_h := HBoxContainer.new()
	strip_h.custom_minimum_size = Vector2(0, 5)
	strip_h.add_theme_constant_override("separation", 0)
	var strip_left := ColorRect.new()
	strip_left.custom_minimum_size = Vector2(0, 5)
	strip_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip_left.color = Color(border_r, border_g, border_b, 0.9)
	strip_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var strip_right := ColorRect.new()
	strip_right.custom_minimum_size = Vector2(0, 5)
	strip_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# 右半用独特偏移色
	strip_right.color = Color(
		clampf(border_r + shift_r, 0.0, 1.0),
		clampf(border_g + shift_g, 0.0, 1.0),
		clampf(border_b + shift_b, 0.0, 1.0), 0.7)
	strip_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip_h.add_child(strip_left)
	strip_h.add_child(strip_right)
	vbox.add_child(strip_h)

	# ── 卡面图片 ──
	var art_container := Control.new()
	art_container.custom_minimum_size = Vector2(240, 110)
	art_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 图片背景 (每张卡独特底色)
	var art_bg := ColorRect.new()
	art_bg.position = Vector2.ZERO
	art_bg.size = Vector2(240, 110)
	art_bg.color = Color(bg_r * 1.5, bg_g * 1.5, bg_b * 1.5, 0.4)
	art_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_container.add_child(art_bg)

	# 独特装饰线条 (每张卡不同位置/方向)
	_add_unique_deco(art_container, cid, Color(border_r, border_g, border_b, 0.2))

	var card_art := TextureRect.new()
	var _ai_db_card := AssetLoader.get_card_art(card_data.card_type, card_data.yinyang, card_data.rarity, card_path.hash(), card_data.card_id)
	card_art.texture = _ai_db_card if _ai_db_card else PixelArtGenerator.generate_card_art(
		card_data.card_type, card_data.yinyang, card_data.rarity, card_path.hash()
	)
	card_art.position = Vector2(30, 5)
	card_art.size = Vector2(180, 100)
	card_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_container.add_child(card_art)

	# 费用球 (独特形状)
	var cost_orb := _create_cost_orb(card_data, cid)
	art_container.add_child(cost_orb)

	vbox.add_child(art_container)

	# ── 卡名区: 独特底色条 ──
	var name_panel := Panel.new()
	name_panel.custom_minimum_size = Vector2(0, 28)
	var name_sb := StyleBoxFlat.new()
	name_sb.bg_color = Color(border_r * 0.15, border_g * 0.15, border_b * 0.15, 0.5)
	name_sb.set_corner_radius_all(2)
	name_sb.content_margin_left = 4
	name_sb.content_margin_top = 2
	name_sb.content_margin_right = 4
	name_sb.content_margin_bottom = 2
	name_panel.add_theme_stylebox_override("panel", name_sb)
	var name_lbl := Label.new()
	name_lbl.text = card_data.card_name
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", card_data.get_rarity_color())
	name_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	name_lbl.add_theme_constant_override("shadow_offset_x", 1)
	name_lbl.add_theme_constant_override("shadow_offset_y", 1)
	name_lbl.clip_text = true
	name_panel.add_child(name_lbl)
	vbox.add_child(name_panel)

	# ── 类型/阴阳/费用 行 (独特文字颜色) ──
	var cost_text: String = "X" if card_data.cost == -1 else str(card_data.cost)
	var info_lbl := Label.new()
	info_lbl.text = card_data.get_type_text() + " | " + card_data.get_yinyang_text() + " | " + cost_text + "算力"
	info_lbl.add_theme_font_size_override("font_size", 12)
	info_lbl.add_theme_color_override("font_color", Color(
		clampf(border_r * 0.6 + 0.3, 0.3, 0.8),
		clampf(border_g * 0.6 + 0.3, 0.3, 0.8),
		clampf(border_b * 0.6 + 0.3, 0.3, 0.8), 0.8))
	vbox.add_child(info_lbl)

	# ── 数值行: 类型特化显示, 独特强调色 ──
	var stats_color := Color(
		clampf(type_base_r + 0.4 + shift_r, 0.4, 1.0),
		clampf(type_base_g + 0.3 + shift_g, 0.3, 1.0),
		clampf(type_base_b + 0.2 + shift_b, 0.2, 1.0))
	var stats_text := ""
	match card_data.card_type:
		CardData.CardType.ATTACK:
			if card_data.multi_hit > 0:
				stats_text = "⚔ " + str(card_data.attack_power) + " x" + str(card_data.multi_hit)
			else:
				stats_text = "⚔ " + str(card_data.attack_power)
		CardData.CardType.DEFENSE:
			stats_text = "🛡 " + str(card_data.defense_power)
		CardData.CardType.SUMMON:
			stats_text = "⚔ " + str(card_data.attack_power) + "  ♥ " + str(card_data.summon_hp)
		CardData.CardType.SPELL:
			stats_text = "✦ 术法效果"
		CardData.CardType.POWER:
			stats_text = "⚡ 永久增益"
	var stats_lbl := Label.new()
	stats_lbl.text = stats_text
	stats_lbl.add_theme_font_size_override("font_size", 15)
	stats_lbl.add_theme_color_override("font_color", stats_color)
	vbox.add_child(stats_lbl)

	# ── 关键词徽标 (有则显示, 独特底色) ──
	var kw_text := card_data.get_keywords_text()
	if kw_text != "":
		var kw_panel := Panel.new()
		kw_panel.custom_minimum_size = Vector2(0, 18)
		var kw_sb := StyleBoxFlat.new()
		kw_sb.bg_color = Color(0.5, 0.4, 0.1, 0.25 + h5 * 0.15)
		kw_sb.set_corner_radius_all(2)
		kw_sb.content_margin_left = 4
		kw_sb.content_margin_top = 1
		kw_sb.content_margin_bottom = 1
		kw_panel.add_theme_stylebox_override("panel", kw_sb)
		var kw_lbl := Label.new()
		kw_lbl.text = kw_text
		kw_lbl.add_theme_font_size_override("font_size", 11)
		kw_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 0.9))
		kw_panel.add_child(kw_lbl)
		vbox.add_child(kw_panel)

	# ── 描述 (独特文字色) ──
	var desc_lbl := Label.new()
	desc_lbl.text = card_data.description
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(
		0.55 + bright_off, 0.55 + bright_off, 0.65 + bright_off, 0.9))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.custom_minimum_size = Vector2(240, 0)
	vbox.add_child(desc_lbl)

	# ── 底部装饰线 (独特) ──
	var bottom_line := ColorRect.new()
	bottom_line.custom_minimum_size = Vector2(0, 2)
	bottom_line.color = Color(border_r, border_g, border_b, 0.3 + h3 * 0.2)
	bottom_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bottom_line)

	panel.add_child(vbox)
	return panel

## 在卡面图区域内添加独特装饰线/点
func _add_unique_deco(container: Control, cid: String, col: Color) -> void:
	var d1: float = _hash_f(cid, 20)
	var d2: float = _hash_f(cid, 21)
	var d3: float = _hash_f(cid, 22)
	var d4: float = _hash_f(cid, 23)
	var d5: float = _hash_f(cid, 24)

	# 水平线
	var hl := ColorRect.new()
	hl.position = Vector2(d1 * 60.0, 10.0 + d2 * 90.0)
	hl.size = Vector2(80.0 + d3 * 120.0, 1)
	hl.color = Color(col.r, col.g, col.b, 0.15 + d4 * 0.15)
	hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(hl)

	# 垂直线
	var vl := ColorRect.new()
	vl.position = Vector2(180.0 + d5 * 50.0, d1 * 40.0)
	vl.size = Vector2(1, 40.0 + d2 * 50.0)
	vl.color = Color(col.r, col.g, col.b, 0.1 + d3 * 0.15)
	vl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(vl)

	# 角标点 (稀有度越高越多)
	if d4 > 0.4:
		var dot := ColorRect.new()
		dot.position = Vector2(d5 * 220.0, d1 * 100.0)
		dot.size = Vector2(3, 3)
		dot.color = Color(col.r + 0.2, col.g + 0.2, col.b + 0.2, 0.3)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(dot)
	if d2 > 0.5:
		var dot2 := ColorRect.new()
		dot2.position = Vector2(d3 * 200.0 + 20.0, d4 * 90.0 + 5.0)
		dot2.size = Vector2(2, 2)
		dot2.color = Color(col.r, col.g, col.b, 0.25)
		dot2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(dot2)

func _create_cost_orb(card_data: CardData, cid: String) -> Panel:
	var orb := Panel.new()
	orb.position = Vector2(3, 3)
	orb.size = Vector2(30, 30)
	orb.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 独特圆角 (每张卡不同)
	var orb_round: int = 8 + int(_hash_f(cid, 30) * 8.0)  # 8~15
	var orb_sb := StyleBoxFlat.new()
	orb_sb.set_corner_radius_all(orb_round)

	# 费用球颜色: 类型基色 + 独特偏移
	var orb_shift: float = _hash_f(cid, 31) * 0.15 - 0.075
	match card_data.card_type:
		CardData.CardType.ATTACK:
			orb_sb.bg_color = Color(0.75 + orb_shift, 0.12, 0.08, 0.92)
		CardData.CardType.DEFENSE:
			orb_sb.bg_color = Color(0.08, 0.35 + orb_shift, 0.75, 0.92)
		CardData.CardType.SUMMON:
			orb_sb.bg_color = Color(0.45 + orb_shift, 0.15, 0.75, 0.92)
		CardData.CardType.SPELL:
			orb_sb.bg_color = Color(0.08, 0.6 + orb_shift, 0.28, 0.92)
		CardData.CardType.POWER:
			orb_sb.bg_color = Color(0.75 + orb_shift, 0.6, 0.05, 0.92)
		_:
			orb_sb.bg_color = Color(0.3, 0.3, 0.3, 0.92)

	orb_sb.border_color = Color(1, 1, 1, 0.3 + _hash_f(cid, 32) * 0.2)
	orb_sb.set_border_width_all(1)
	orb_sb.content_margin_left = 0
	orb_sb.content_margin_right = 0
	orb_sb.content_margin_top = 0
	orb_sb.content_margin_bottom = 0
	orb.add_theme_stylebox_override("panel", orb_sb)

	var cost_lbl := Label.new()
	var cost_str: String = "X" if card_data.cost == -1 else str(card_data.cost)
	cost_lbl.text = cost_str
	cost_lbl.add_theme_font_size_override("font_size", 15)
	cost_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	cost_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	cost_lbl.add_theme_constant_override("shadow_offset_x", 1)
	cost_lbl.add_theme_constant_override("shadow_offset_y", 1)
	cost_lbl.position = Vector2(0, 0)
	cost_lbl.size = Vector2(30, 30)
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
