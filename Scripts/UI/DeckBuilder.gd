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

# 悬停预览面板
var hover_preview: PanelContainer
var _preview_art: TextureRect
var _preview_name: Label
var _preview_info: Label
var _preview_desc: Label
var _preview_stats: Label
var _preview_keywords: Label
var _preview_effect: Label
var _preview_border_sb: StyleBoxFlat

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

	# 悬停预览面板 (Slay the Spire 风格大卡预览)
	_create_hover_preview()

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
	var h1: float = _hash_f(cid, 1)
	var h2: float = _hash_f(cid, 2)
	var h3: float = _hash_f(cid, 3)
	var h4: float = _hash_f(cid, 4)
	var h5: float = _hash_f(cid, 5)
	var h6: float = _hash_f(cid, 6)

	# ── 主色调: 直接用卡牌自身 card_color (每张卡唯一) ──
	var accent: Color = card_data.card_color
	if accent == Color.WHITE or accent == Color.BLACK:
		# fallback: 用 hash 生成色
		accent = Color(0.3 + h1 * 0.6, 0.2 + h2 * 0.5, 0.3 + h3 * 0.6)

	# 背景: 卡牌自身色的暗色版, 但足够可见
	var bg_r: float = clampf(accent.r * 0.2 + h4 * 0.04, 0.04, 0.25)
	var bg_g: float = clampf(accent.g * 0.2 + h5 * 0.04, 0.03, 0.22)
	var bg_b: float = clampf(accent.b * 0.2 + h6 * 0.04, 0.04, 0.28)

	# 边框: 卡牌自身色为主 (明亮), 阴阳微调冷暖
	var border_r: float = accent.r
	var border_g: float = accent.g
	var border_b: float = accent.b
	match card_data.yinyang:
		0:  # Yin - 整体偏冷一点
			border_r = clampf(border_r * 0.8, 0.1, 0.9)
			border_b = clampf(border_b + 0.15, 0.2, 1.0)
		1:  # Yang - 整体偏暖一点
			border_r = clampf(border_r + 0.1, 0.2, 1.0)
			border_b = clampf(border_b * 0.8, 0.05, 0.85)

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

	# ── Hover: 用该卡的独特色高亮 + 预览面板 ──
	var normal_border := sb.border_color
	var hover_col := Color(
		clampf(border_r + 0.3, 0.0, 1.0),
		clampf(border_g + 0.3, 0.0, 1.0),
		clampf(border_b + 0.3, 0.0, 1.0), 0.95)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var _cd_ref: CardData = card_data
	var _path_ref: String = card_path
	var _accent_ref: Color = accent
	panel.mouse_entered.connect(func():
		sb.border_color = hover_col
		sb.shadow_size = shadow_sz + 5
		sb.shadow_color = Color(hover_col.r, hover_col.g, hover_col.b, 0.35)
		_show_hover_preview(_cd_ref, _path_ref, _accent_ref, panel)
	)
	panel.mouse_exited.connect(func():
		sb.border_color = normal_border
		sb.shadow_size = shadow_sz
		sb.shadow_color = Color(border_r, border_g, border_b, 0.15 + float(card_data.rarity) * 0.1)
		_hide_hover_preview()
	)

	# ── 点击查看详情 ──
	panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_show_card_detail(card_data)
	)

	# ── 卡牌内容 VBox ──
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	# ── 顶部色条: 用卡牌自身色 ──
	var strip_h := HBoxContainer.new()
	strip_h.custom_minimum_size = Vector2(0, 6)
	strip_h.add_theme_constant_override("separation", 0)
	var strip_left := ColorRect.new()
	strip_left.custom_minimum_size = Vector2(0, 6)
	strip_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip_left.color = Color(accent.r, accent.g, accent.b, 0.9)
	strip_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var strip_right := ColorRect.new()
	strip_right.custom_minimum_size = Vector2(0, 6)
	strip_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip_right.color = Color(
		clampf(accent.r * 0.6 + h1 * 0.4, 0.0, 1.0),
		clampf(accent.g * 0.6 + h2 * 0.4, 0.0, 1.0),
		clampf(accent.b * 0.6 + h3 * 0.4, 0.0, 1.0), 0.75)
	strip_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip_h.add_child(strip_left)
	strip_h.add_child(strip_right)
	vbox.add_child(strip_h)

	# ── 卡面图片 ──
	var art_container := Control.new()
	art_container.custom_minimum_size = Vector2(240, 110)
	art_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 图片背景 (用卡牌自身色, 更明亮可见)
	var art_bg := ColorRect.new()
	art_bg.position = Vector2.ZERO
	art_bg.size = Vector2(240, 110)
	art_bg.color = Color(accent.r * 0.25 + 0.02, accent.g * 0.25 + 0.02, accent.b * 0.25 + 0.02, 0.55)
	art_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_container.add_child(art_bg)

	# 大型独特徽章 (每张卡完全不同的几何图案)
	_add_card_emblem(art_container, cid, accent)

	var card_art := TextureRect.new()
	var _ai_db_card := AssetLoader.get_card_art(card_data.card_type, card_data.yinyang, card_data.rarity, card_path.hash(), card_data.card_id)
	card_art.texture = _ai_db_card if _ai_db_card else PixelArtGenerator.generate_card_art(
		card_data.card_type, card_data.yinyang, card_data.rarity, cid.hash()
	)
	card_art.position = Vector2(20, 5)
	card_art.size = Vector2(200, 100)
	card_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_container.add_child(card_art)

	# 费用球 (独特形状)
	var cost_orb := _create_cost_orb(card_data, cid, accent)
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

	# ── 类型/阴阳/费用 行 ──
	var cost_text: String = "X" if card_data.cost == -1 else str(card_data.cost)
	var info_lbl := Label.new()
	info_lbl.text = card_data.get_type_text() + " | " + card_data.get_yinyang_text() + " | " + cost_text + "算力"
	info_lbl.add_theme_font_size_override("font_size", 12)
	info_lbl.add_theme_color_override("font_color", Color(
		clampf(accent.r * 0.5 + 0.35, 0.35, 0.85),
		clampf(accent.g * 0.5 + 0.35, 0.35, 0.85),
		clampf(accent.b * 0.5 + 0.35, 0.35, 0.85), 0.85))
	vbox.add_child(info_lbl)

	# ── 数值行: 用卡牌主色强调 ──
	var stats_color := Color(
		clampf(accent.r + 0.25, 0.45, 1.0),
		clampf(accent.g + 0.2, 0.35, 1.0),
		clampf(accent.b + 0.15, 0.3, 1.0))
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
		clampf(accent.r * 0.15 + 0.5, 0.45, 0.7),
		clampf(accent.g * 0.15 + 0.5, 0.45, 0.7),
		clampf(accent.b * 0.15 + 0.55, 0.5, 0.75), 0.9))
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

## 为每张卡生成大型独特几何徽章 (8种基础图案 × hash参数 = 每张卡唯一)
func _add_card_emblem(container: Control, cid: String, accent: Color) -> void:
	var e1: float = _hash_f(cid, 40)
	var e2: float = _hash_f(cid, 41)
	var e3: float = _hash_f(cid, 42)
	var e4: float = _hash_f(cid, 43)
	var e5: float = _hash_f(cid, 44)
	var e6: float = _hash_f(cid, 45)
	var e7: float = _hash_f(cid, 46)
	var e8: float = _hash_f(cid, 47)

	# 徽章中心和尺寸 (每张卡位置微偏)
	var cx: float = 120.0 + (e7 - 0.5) * 30.0
	var cy: float = 55.0 + (e8 - 0.5) * 16.0
	var col := Color(accent.r, accent.g, accent.b, 0.4 + e1 * 0.2)
	var col_bright := Color(
		clampf(accent.r + 0.3, 0.0, 1.0),
		clampf(accent.g + 0.3, 0.0, 1.0),
		clampf(accent.b + 0.3, 0.0, 1.0), 0.35 + e2 * 0.15)

	var pattern: int = int(e1 * 8.0)

	if pattern == 0:
		# 大圆环 + 内圆
		var r_out: float = 30.0 + e2 * 15.0
		_add_circle(container, cx, cy, r_out, col, 2)
		_add_circle(container, cx, cy, r_out * 0.5, col_bright, 1)
		# 小装饰点
		_add_circle(container, cx - r_out * 0.8, cy, 4.0, col_bright, 0)
		_add_circle(container, cx + r_out * 0.8, cy, 4.0, col_bright, 0)

	elif pattern == 1:
		# 十字架
		var arm_len: float = 30.0 + e3 * 18.0
		var arm_w: float = 4.0 + e4 * 5.0
		_add_rect(container, cx - arm_len, cy - arm_w * 0.5, arm_len * 2, arm_w, col)
		_add_rect(container, cx - arm_w * 0.5, cy - arm_len * 0.7, arm_w, arm_len * 1.4, col)
		_add_circle(container, cx, cy, arm_w + 2.0, col_bright, 0)

	elif pattern == 2:
		# 三层同心方框
		var s1: float = 22.0 + e2 * 16.0
		var s2: float = s1 * 0.65
		var s3: float = s1 * 0.35
		_add_rect_border(container, cx - s1, cy - s1 * 0.7, s1 * 2, s1 * 1.4, col, 2)
		_add_rect_border(container, cx - s2, cy - s2 * 0.7, s2 * 2, s2 * 1.4, col_bright, 1)
		_add_rect(container, cx - s3, cy - s3 * 0.7, s3 * 2, s3 * 1.4, col)

	elif pattern == 3:
		# 星芒放射 (8条线从中心向外)
		var ray_len: float = 28.0 + e2 * 18.0
		# 上下左右4线
		_add_rect(container, cx - 1, cy - ray_len, 2, ray_len, col)
		_add_rect(container, cx - 1, cy, 2, ray_len, col)
		_add_rect(container, cx - ray_len, cy - 1, ray_len, 2, col)
		_add_rect(container, cx, cy - 1, ray_len, 2, col)
		# 对角4线 (用短粗矩形近似)
		var d: float = ray_len * 0.55
		_add_rect(container, cx - d, cy - d, d * 0.15 + 3, d * 0.15 + 3, col_bright)
		_add_rect(container, cx + d * 0.85, cy - d, d * 0.15 + 3, d * 0.15 + 3, col_bright)
		_add_rect(container, cx - d, cy + d * 0.85, d * 0.15 + 3, d * 0.15 + 3, col_bright)
		_add_rect(container, cx + d * 0.85, cy + d * 0.85, d * 0.15 + 3, d * 0.15 + 3, col_bright)
		_add_circle(container, cx, cy, 5.0 + e3 * 4.0, col_bright, 0)

	elif pattern == 4:
		# 点阵 (3x3 到 4x4 网格)
		var cols_n: int = 3 + int(e3 * 2.0)
		var rows_n: int = 3 + int(e4 * 1.5)
		var spacing: float = 16.0 + e5 * 8.0
		var dot_r: float = 3.0 + e6 * 3.0
		var ox: float = cx - float(cols_n - 1) * spacing * 0.5
		var oy: float = cy - float(rows_n - 1) * spacing * 0.5
		for gy in range(rows_n):
			for gx in range(cols_n):
				var dot_col: Color = col if ((gx + gy) % 2 == 0) else col_bright
				_add_circle(container, ox + float(gx) * spacing, oy + float(gy) * spacing, dot_r, dot_col, 0)

	elif pattern == 5:
		# 水平条纹 (4-6条)
		var n_stripes: int = 4 + int(e2 * 3.0)
		var stripe_h: float = 3.0 + e3 * 3.0
		var total_h: float = float(n_stripes) * (stripe_h + 6.0)
		var start_y: float = cy - total_h * 0.5
		var stripe_w: float = 100.0 + e4 * 80.0
		var start_x: float = cx - stripe_w * 0.5
		for si in range(n_stripes):
			var sy: float = start_y + float(si) * (stripe_h + 6.0)
			var sw: float = stripe_w * (0.6 + _hash_f(cid, 50 + si) * 0.4)
			var sx: float = start_x + (stripe_w - sw) * _hash_f(cid, 60 + si)
			var sc: Color = col if si % 2 == 0 else col_bright
			_add_rect(container, sx, sy, sw, stripe_h, sc)

	elif pattern == 6:
		# 角落括号装饰 (四角L形)
		var bk_len: float = 18.0 + e2 * 12.0
		var bk_w: float = 2.0 + e3 * 2.0
		var margin: float = 12.0 + e4 * 10.0
		# 左上
		_add_rect(container, margin, margin, bk_len, bk_w, col)
		_add_rect(container, margin, margin, bk_w, bk_len, col)
		# 右上
		_add_rect(container, 240 - margin - bk_len, margin, bk_len, bk_w, col)
		_add_rect(container, 240 - margin - bk_w, margin, bk_w, bk_len, col)
		# 左下
		_add_rect(container, margin, 110 - margin - bk_w, bk_len, bk_w, col)
		_add_rect(container, margin, 110 - margin - bk_len, bk_w, bk_len, col)
		# 右下
		_add_rect(container, 240 - margin - bk_len, 110 - margin - bk_w, bk_len, bk_w, col)
		_add_rect(container, 240 - margin - bk_w, 110 - margin - bk_len, bk_w, bk_len, col)
		# 中心点
		_add_circle(container, cx, cy, 6.0 + e5 * 4.0, col_bright, 1)

	else:
		# 菱形组合 (用4个方块拼)
		var diam_s: float = 16.0 + e2 * 12.0
		_add_rect(container, cx - diam_s * 0.5, cy - diam_s * 0.5, diam_s, diam_s, col)
		# 4个小方块在菱形位置
		var offset_d: float = diam_s + 4.0
		_add_rect(container, cx - 4, cy - offset_d - 4, 8, 8, col_bright)
		_add_rect(container, cx - 4, cy + offset_d - 4, 8, 8, col_bright)
		_add_rect(container, cx - offset_d - 4, cy - 4, 8, 8, col_bright)
		_add_rect(container, cx + offset_d - 4, cy - 4, 8, 8, col_bright)
		# 连接线
		_add_rect(container, cx - 1, cy - offset_d, 2, offset_d * 2, Color(col.r, col.g, col.b, 0.2))
		_add_rect(container, cx - offset_d, cy - 1, offset_d * 2, 2, Color(col.r, col.g, col.b, 0.2))

	# 额外: 基于另一组hash添加小装饰 (让同pattern的卡也不完全相同)
	if e5 > 0.3:
		var extra_x: float = e6 * 200.0 + 20.0
		var extra_y: float = e7 * 80.0 + 15.0
		_add_circle(container, extra_x, extra_y, 2.0 + e8 * 2.0, col, 0)
	if e6 > 0.5:
		var lx: float = e7 * 180.0 + 30.0
		_add_rect(container, lx, 5.0 + e8 * 20.0, 1, 20.0 + e5 * 30.0, Color(col.r, col.g, col.b, 0.15))

## 辅助: 在容器内添加圆形 (Panel + StyleBoxFlat)
## mode: 0=实心, 1=有边框实心, 2=只有边框
func _add_circle(container: Control, cx_pos: float, cy_pos: float, radius: float, col: Color, mode: int) -> void:
	var p := Panel.new()
	var d: float = radius * 2.0
	p.position = Vector2(cx_pos - radius, cy_pos - radius)
	p.size = Vector2(d, d)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(int(radius) + 1)
	if mode == 2:
		sb.bg_color = Color(0, 0, 0, 0)
		sb.border_color = col
		sb.set_border_width_all(2)
	elif mode == 1:
		sb.bg_color = Color(col.r, col.g, col.b, col.a * 0.4)
		sb.border_color = col
		sb.set_border_width_all(1)
	else:
		sb.bg_color = col
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	p.add_theme_stylebox_override("panel", sb)
	container.add_child(p)

## 辅助: 添加实心矩形
func _add_rect(container: Control, x: float, y: float, w: float, h: float, col: Color) -> void:
	var r := ColorRect.new()
	r.position = Vector2(x, y)
	r.size = Vector2(w, h)
	r.color = col
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(r)

## 辅助: 添加边框矩形
func _add_rect_border(container: Control, x: float, y: float, w: float, h: float, col: Color, bw: int) -> void:
	var p := Panel.new()
	p.position = Vector2(x, y)
	p.size = Vector2(w, h)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = col
	sb.set_border_width_all(bw)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	p.add_theme_stylebox_override("panel", sb)
	container.add_child(p)

func _create_cost_orb(card_data: CardData, cid: String, accent: Color) -> Panel:
	var orb := Panel.new()
	orb.position = Vector2(3, 3)
	orb.size = Vector2(30, 30)
	orb.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 独特圆角 (每张卡不同)
	var orb_round: int = 8 + int(_hash_f(cid, 30) * 8.0)  # 8~15
	var orb_sb := StyleBoxFlat.new()
	orb_sb.set_corner_radius_all(orb_round)

	# 费用球颜色: 用卡牌自身色
	var orb_shift: float = _hash_f(cid, 31) * 0.1 - 0.05
	orb_sb.bg_color = Color(
		clampf(accent.r * 0.8 + 0.15 + orb_shift, 0.15, 0.95),
		clampf(accent.g * 0.8 + 0.1 + orb_shift, 0.1, 0.9),
		clampf(accent.b * 0.8 + 0.1 + orb_shift, 0.1, 0.95), 0.92)

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

func _create_hover_preview() -> void:
	hover_preview = PanelContainer.new()
	hover_preview.custom_minimum_size = Vector2(400, 520)
	hover_preview.size = Vector2(400, 520)
	hover_preview.z_index = 50
	hover_preview.visible = false
	hover_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_preview_border_sb = StyleBoxFlat.new()
	_preview_border_sb.bg_color = Color(0.04, 0.03, 0.09, 0.96)
	_preview_border_sb.border_color = Color(0, 0.9, 1, 0.8)
	_preview_border_sb.set_border_width_all(3)
	_preview_border_sb.border_width_top = 4
	_preview_border_sb.set_corner_radius_all(8)
	_preview_border_sb.shadow_color = Color(0, 0.4, 0.6, 0.4)
	_preview_border_sb.shadow_size = 10
	_preview_border_sb.content_margin_left = 14
	_preview_border_sb.content_margin_top = 12
	_preview_border_sb.content_margin_right = 14
	_preview_border_sb.content_margin_bottom = 12
	hover_preview.add_theme_stylebox_override("panel", _preview_border_sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 卡面图片
	_preview_art = TextureRect.new()
	_preview_art.custom_minimum_size = Vector2(280, 180)
	_preview_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_preview_art)

	# 卡名
	_preview_name = Label.new()
	_preview_name.add_theme_font_size_override("font_size", 22)
	_preview_name.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	_preview_name.add_theme_constant_override("shadow_offset_x", 1)
	_preview_name.add_theme_constant_override("shadow_offset_y", 1)
	_preview_name.clip_text = true
	_preview_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_preview_name)

	# 类型 | 阴阳 | 费用
	_preview_info = Label.new()
	_preview_info.add_theme_font_size_override("font_size", 14)
	_preview_info.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	_preview_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_preview_info)

	# 描述
	_preview_desc = Label.new()
	_preview_desc.add_theme_font_size_override("font_size", 15)
	_preview_desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	_preview_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_desc.custom_minimum_size = Vector2(370, 0)
	_preview_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_preview_desc)

	# 数值行
	_preview_stats = Label.new()
	_preview_stats.add_theme_font_size_override("font_size", 16)
	_preview_stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_preview_stats)

	# 关键词
	_preview_keywords = Label.new()
	_preview_keywords.add_theme_font_size_override("font_size", 13)
	_preview_keywords.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 0.9))
	_preview_keywords.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_preview_keywords)

	# 效果ID
	_preview_effect = Label.new()
	_preview_effect.add_theme_font_size_override("font_size", 12)
	_preview_effect.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5, 0.7))
	_preview_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_preview_effect)

	hover_preview.add_child(vbox)
	add_child(hover_preview)

func _show_hover_preview(cd: CardData, card_path: String, accent: Color, panel: PanelContainer) -> void:
	if cd == null:
		return

	# 更新边框色为卡牌主色
	_preview_border_sb.border_color = Color(accent.r, accent.g, accent.b, 0.85)
	_preview_border_sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.35)

	# 卡面图片
	var art_seed: int = cd.card_id.hash() if cd.card_id != "" else card_path.hash()
	var ai_art = AssetLoader.get_card_art(cd.card_type, cd.yinyang, cd.rarity, art_seed, cd.card_id)
	_preview_art.texture = ai_art if ai_art else PixelArtGenerator.generate_card_art(
		cd.card_type, cd.yinyang, cd.rarity, art_seed
	)

	# 卡名 (稀有度颜色)
	_preview_name.text = cd.card_name
	_preview_name.add_theme_color_override("font_color", cd.get_rarity_color())

	# 类型 | 阴阳 | 费用
	var cost_text: String = "X(全算力)" if cd.cost == -1 else str(cd.cost) + "算力"
	_preview_info.text = cd.get_type_text() + " | " + cd.get_yinyang_text() + " | " + cost_text

	# 描述
	_preview_desc.text = cd.description

	# 数值
	var stats_text: String = ""
	match cd.card_type:
		CardData.CardType.ATTACK:
			if cd.multi_hit > 0:
				stats_text = "伤害: " + str(cd.attack_power) + " x" + str(cd.multi_hit) + "段"
			else:
				stats_text = "伤害: " + str(cd.attack_power)
		CardData.CardType.DEFENSE:
			stats_text = "护盾: " + str(cd.defense_power)
		CardData.CardType.SUMMON:
			stats_text = "攻击: " + str(cd.attack_power) + "  生命: " + str(cd.summon_hp)
			if cd.summon_passive != "":
				stats_text = stats_text + "  被动: " + cd.summon_passive
		CardData.CardType.SPELL:
			stats_text = "术法效果"
		CardData.CardType.POWER:
			stats_text = "永久增益"
	_preview_stats.text = stats_text
	_preview_stats.add_theme_color_override("font_color", Color(
		clampf(accent.r + 0.3, 0.5, 1.0),
		clampf(accent.g + 0.25, 0.4, 1.0),
		clampf(accent.b + 0.2, 0.35, 1.0)))

	# 关键词
	var kw: String = cd.get_keywords_text()
	_preview_keywords.text = kw
	_preview_keywords.visible = kw != ""

	# 效果ID
	if cd.effect_id != "":
		_preview_effect.text = "效果: " + cd.effect_id
		_preview_effect.visible = true
	else:
		_preview_effect.visible = false

	# 定位: 在卡牌右侧, 如果太靠右则放左侧
	var panel_rect: Rect2 = panel.get_global_rect()
	var preview_x: float = panel_rect.position.x + panel_rect.size.x + 12
	var preview_y: float = panel_rect.position.y

	# 如果右侧放不下 (超出1280), 放左侧
	if preview_x + 400 > 1280:
		preview_x = panel_rect.position.x - 400 - 12

	# 垂直方向限制在屏幕内
	preview_y = clampf(preview_y, 4, 720 - 520 - 4)

	# 转换为本控件的本地坐标
	var local_pos: Vector2 = Vector2(preview_x, preview_y)
	var parent_global: Vector2 = get_global_position()
	hover_preview.position = local_pos - parent_global

	hover_preview.visible = true

func _hide_hover_preview() -> void:
	hover_preview.visible = false

func _on_back() -> void:
	Global.change_scene(Global.SCENE_MAP)
