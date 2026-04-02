extends RefCounted
class_name CardRenderer

## 卡牌渲染工具类（Phase 3 美化）
## 提供卡牌控件创建、HP 条、能量点等视觉组件
## 设计模式：与 CyberStyle / BoardCellRenderer 一致的无状态静态方法

# ---- 卡牌类型配色 ----
const TYPE_COLORS: Dictionary = {
	"attack": Color(1.0, 0.4, 0.2),
	"pierce": Color(1.0, 0.7, 0.15),
	"lifesteal": Color(0.9, 0.2, 0.55),
	"shock": Color(0.65, 0.4, 1.0),
	"defend": Color(0.3, 0.7, 1.0),
	"heal": Color(0.3, 0.95, 0.55),
	"poison": Color(0.45, 0.85, 0.15),
	"draw": Color(0.2, 0.75, 0.95),
	"counter": Color(0.85, 0.55, 0.15),
	"combo": Color(1.0, 0.25, 0.35),
}

# ---- 卡牌类型图标（程序化符号） ----
const TYPE_ICONS: Dictionary = {
	"attack": "⚔",
	"pierce": "◇",
	"lifesteal": "♦",
	"shock": "⚡",
	"defend": "■",
	"heal": "✚",
	"poison": "☠",
	"draw": "↻",
	"counter": "↺",
	"combo": "⚔⚔",
}

# ---- 卡牌类型中文标签 ----
const TYPE_LABELS: Dictionary = {
	"attack": "攻击",
	"pierce": "穿透",
	"lifesteal": "吸血",
	"shock": "电击",
	"defend": "防御",
	"heal": "治疗",
	"poison": "毒素",
	"draw": "抽牌",
	"counter": "反击",
	"combo": "连击",
}

# ---- 卡牌尺寸 ----
const CARD_W: float = 90.0
const CARD_H: float = 108.0
const COLLECTION_TILE_SIZE := Vector2(152.0, 156.0)
const COLLECTION_ROW_WIDTH: float = 320.0
const COLLECTION_ROW_HEIGHT: float = 82.0

const TYPE_SORT_ORDER: Dictionary = {
	"attack": 0,
	"pierce": 1,
	"lifesteal": 2,
	"shock": 3,
	"defend": 4,
	"counter": 5,
	"heal": 6,
	"draw": 7,
	"poison": 8,
	"combo": 9,
}

# ======== 卡牌控件创建 ========

static func create_card(card: Dictionary, can_play: bool, index: int, callback: Callable) -> Panel:
	var panel := Panel.new()
	panel.size = Vector2(CARD_W, CARD_H)
	panel.custom_minimum_size = Vector2(CARD_W, CARD_H)
	var card_type: String = String(card.get("type", "attack"))
	var accent: Color = get_type_color(card_type)
	var is_upgraded: bool = card.get("upgraded", false)
	# 面板样式
	var sb := StyleBoxFlat.new()
	sb.bg_color = CyberStyle.BG_CARD if can_play else Color(0.03, 0.03, 0.06, 0.85)
	var border_col: Color
	if not can_play:
		border_col = Color(0.2, 0.22, 0.25, 0.5)
	elif is_upgraded:
		border_col = CyberStyle.ACCENT_CYAN
	else:
		border_col = accent
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	if is_upgraded and can_play:
		sb.shadow_color = Color(0.0, 0.85, 1.0, 0.3)
		sb.shadow_size = 5
	elif can_play:
		sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.15)
		sb.shadow_size = 3
	panel.add_theme_stylebox_override("panel", sb)
	# 卡牌名称（顶部）
	var name_lbl := Label.new()
	name_lbl.text = String(card.get("name", "?"))
	name_lbl.position = Vector2(0, 5)
	name_lbl.size = Vector2(CARD_W, 16)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY if can_play else CyberStyle.TEXT_MUTED)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(name_lbl)
	# 类型图标（中央）
	var icon_lbl := Label.new()
	icon_lbl.text = get_type_icon(card_type)
	icon_lbl.position = Vector2(0, 22)
	icon_lbl.size = Vector2(CARD_W, 34)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 26)
	icon_lbl.add_theme_color_override("font_color", accent if can_play else Color(accent.r, accent.g, accent.b, 0.3))
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(icon_lbl)
	# 数值描述
	var val_lbl := Label.new()
	val_lbl.text = _format_value(card)
	val_lbl.position = Vector2(0, 56)
	val_lbl.size = Vector2(CARD_W, 14)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.add_theme_font_size_override("font_size", 11)
	val_lbl.add_theme_color_override("font_color", CyberStyle.TEXT_SECONDARY if can_play else CyberStyle.TEXT_MUTED)
	val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(val_lbl)
	# 分隔线
	var sep := ColorRect.new()
	sep.position = Vector2(8, 74)
	sep.size = Vector2(CARD_W - 16, 1)
	sep.color = Color(border_col.r, border_col.g, border_col.b, 0.25)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sep)
	# 费用（左下）
	var cost_lbl := Label.new()
	cost_lbl.text = str(card.get("cost", 1)) + "E"
	cost_lbl.position = Vector2(8, 80)
	cost_lbl.size = Vector2(30, 20)
	cost_lbl.add_theme_font_size_override("font_size", 13)
	cost_lbl.add_theme_color_override("font_color", CyberStyle.TEXT_ENERGY if can_play else CyberStyle.TEXT_WARN)
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(cost_lbl)
	# 类型标签（右下）
	var type_lbl := Label.new()
	type_lbl.text = get_type_label(card_type)
	type_lbl.position = Vector2(CARD_W - 42, 82)
	type_lbl.size = Vector2(36, 18)
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	type_lbl.add_theme_font_size_override("font_size", 9)
	type_lbl.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.5 if can_play else 0.25))
	type_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(type_lbl)
	# 交互处理
	if can_play:
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var idx: int = index
		panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				callback.call(idx)
		)
		panel.mouse_entered.connect(func(): panel.modulate = Color(1.15, 1.15, 1.15))
		panel.mouse_exited.connect(func(): panel.modulate = Color(1.0, 1.0, 1.0))
	return panel

static func get_type_color(card_type: String) -> Color:
	return TYPE_COLORS.get(card_type, Color(0.5, 0.5, 0.5))

static func get_type_icon(card_type: String) -> String:
	return TYPE_ICONS.get(card_type, "◇")

static func get_type_label(card_type: String) -> String:
	return TYPE_LABELS.get(card_type, card_type)

static func format_card_summary(card: Dictionary) -> String:
	return _format_value(card)

static func format_card_meta(card: Dictionary) -> String:
	var cost_text: String = str(int(card.get("cost", 1))) + "E"
	var type_text: String = get_type_label(String(card.get("type", "attack")))
	return cost_text + "  ·  " + type_text

static func format_card_compare(card: Dictionary, compared_card: Dictionary) -> String:
	return format_card_summary(card) + " → " + format_card_summary(compared_card)

static func is_card_before(card_a: Dictionary, card_b: Dictionary) -> bool:
	var cost_a: int = int(card_a.get("cost", 1))
	var cost_b: int = int(card_b.get("cost", 1))
	if cost_a != cost_b:
		return cost_a < cost_b
	var type_a: String = String(card_a.get("type", "attack"))
	var type_b: String = String(card_b.get("type", "attack"))
	var order_a: int = int(TYPE_SORT_ORDER.get(type_a, 99))
	var order_b: int = int(TYPE_SORT_ORDER.get(type_b, 99))
	if order_a != order_b:
		return order_a < order_b
	var name_a: String = String(card_a.get("name", ""))
	var name_b: String = String(card_b.get("name", ""))
	if name_a != name_b:
		return name_a < name_b
	return bool(card_a.get("upgraded", false)) and not bool(card_b.get("upgraded", false))

static func build_grouped_deck_entries(deck: Array[Dictionary]) -> Array[Dictionary]:
	var grouped: Dictionary = {}
	for i in range(deck.size()):
		var card: Dictionary = deck[i]
		var key: String = _build_card_key(card)
		if grouped.has(key):
			grouped[key]["count"] = int(grouped[key]["count"]) + 1
		else:
			grouped[key] = {
				"card": card.duplicate(),
				"count": 1,
				"first_index": i,
			}
	var entries: Array[Dictionary] = []
	for value in grouped.values():
		entries.append(value)
	entries.sort_custom(func(a, b):
		var card_a: Dictionary = a.get("card", {})
		var card_b: Dictionary = b.get("card", {})
		if _cards_equal_for_sort(card_a, card_b):
			return int(a.get("first_index", 0)) < int(b.get("first_index", 0))
		return is_card_before(card_a, card_b)
	)
	return entries

static func create_collection_tile(card: Dictionary, config: Dictionary = {}) -> Panel:
	var size_v: Vector2 = config.get("size", COLLECTION_TILE_SIZE)
	var footer_text: String = String(config.get("footer_text", ""))
	var count: int = int(config.get("count", 0))
	var compared_card: Dictionary = config.get("compare_card", {})
	var panel: Panel = _create_card_surface(card, size_v, bool(config.get("enabled", true)))
	_attach_interaction(panel, config)

	var accent: Color = _get_card_border_color(card, bool(config.get("enabled", true)))
	var content_color: Color = CyberStyle.TEXT_PRIMARY if bool(config.get("enabled", true)) else CyberStyle.TEXT_MUTED
	var secondary_color: Color = CyberStyle.TEXT_SECONDARY if bool(config.get("enabled", true)) else CyberStyle.TEXT_MUTED

	var top_strip := ColorRect.new()
	top_strip.position = Vector2(0, 0)
	top_strip.size = Vector2(size_v.x, 4)
	top_strip.color = Color(accent.r, accent.g, accent.b, 0.85 if bool(config.get("enabled", true)) else 0.35)
	top_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(top_strip)

	var badge_lbl := Label.new()
	badge_lbl.text = get_type_icon(String(card.get("type", "attack"))) + " " + get_type_label(String(card.get("type", "attack")))
	badge_lbl.position = Vector2(10, 10)
	badge_lbl.size = Vector2(size_v.x - 20, 16)
	badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_lbl.add_theme_font_size_override("font_size", 10)
	badge_lbl.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.9 if bool(config.get("enabled", true)) else 0.45))
	badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(badge_lbl)

	var name_lbl := Label.new()
	name_lbl.text = String(card.get("name", "未知卡牌"))
	name_lbl.position = Vector2(10, 28)
	name_lbl.size = Vector2(size_v.x - 20, 22)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", content_color)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(name_lbl)

	var summary_lbl := Label.new()
	summary_lbl.text = format_card_compare(card, compared_card) if not compared_card.is_empty() else format_card_summary(card)
	summary_lbl.position = Vector2(12, 56)
	summary_lbl.size = Vector2(size_v.x - 24, 44)
	summary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	summary_lbl.add_theme_font_size_override("font_size", 12)
	summary_lbl.add_theme_color_override("font_color", secondary_color)
	summary_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	summary_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(summary_lbl)

	var meta_lbl := Label.new()
	meta_lbl.text = format_card_meta(card)
	meta_lbl.position = Vector2(12, size_v.y - 40)
	meta_lbl.size = Vector2(size_v.x - 24, 16)
	meta_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta_lbl.add_theme_font_size_override("font_size", 10)
	meta_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.65 if bool(config.get("enabled", true)) else 0.35))
	meta_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(meta_lbl)

	var footer_lbl := Label.new()
	footer_lbl.text = footer_text
	footer_lbl.position = Vector2(12, size_v.y - 22)
	footer_lbl.size = Vector2(size_v.x - 24, 14)
	footer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_lbl.add_theme_font_size_override("font_size", 10)
	footer_lbl.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.85 if bool(config.get("enabled", true)) else 0.45))
	footer_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(footer_lbl)

	if count > 1:
		var count_lbl := Label.new()
		count_lbl.text = "x" + str(count)
		count_lbl.position = Vector2(size_v.x - 46, 10)
		count_lbl.size = Vector2(34, 16)
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_lbl.add_theme_font_size_override("font_size", 11)
		count_lbl.add_theme_color_override("font_color", CyberStyle.ACCENT_ORANGE if bool(config.get("enabled", true)) else CyberStyle.TEXT_MUTED)
		count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(count_lbl)

	return panel

static func create_card_row(card: Dictionary, config: Dictionary = {}) -> Panel:
	var width: float = float(config.get("width", COLLECTION_ROW_WIDTH))
	var height: float = float(config.get("height", COLLECTION_ROW_HEIGHT))
	var footer_text: String = String(config.get("footer_text", ""))
	var count: int = int(config.get("count", 0))
	var compared_card: Dictionary = config.get("compare_card", {})
	var panel: Panel = _create_card_surface(card, Vector2(width, height), bool(config.get("enabled", true)))
	_attach_interaction(panel, config)

	var accent: Color = _get_card_border_color(card, bool(config.get("enabled", true)))
	var content_color: Color = CyberStyle.TEXT_PRIMARY if bool(config.get("enabled", true)) else CyberStyle.TEXT_MUTED
	var secondary_color: Color = CyberStyle.TEXT_SECONDARY if bool(config.get("enabled", true)) else CyberStyle.TEXT_MUTED

	var strip := ColorRect.new()
	strip.position = Vector2(0, 0)
	strip.size = Vector2(4, height)
	strip.color = Color(accent.r, accent.g, accent.b, 0.9 if bool(config.get("enabled", true)) else 0.4)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(strip)

	var name_lbl := Label.new()
	name_lbl.text = String(card.get("name", "未知卡牌"))
	name_lbl.position = Vector2(14, 10)
	name_lbl.size = Vector2(width - 120, 20)
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", content_color)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(name_lbl)

	var badge_lbl := Label.new()
	badge_lbl.text = get_type_icon(String(card.get("type", "attack"))) + " " + get_type_label(String(card.get("type", "attack")))
	badge_lbl.position = Vector2(width - 106, 10)
	badge_lbl.size = Vector2(90, 16)
	badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	badge_lbl.add_theme_font_size_override("font_size", 10)
	badge_lbl.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.9 if bool(config.get("enabled", true)) else 0.45))
	badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(badge_lbl)

	var summary_lbl := Label.new()
	summary_lbl.text = format_card_compare(card, compared_card) if not compared_card.is_empty() else format_card_summary(card)
	summary_lbl.position = Vector2(14, 32)
	summary_lbl.size = Vector2(width - 28, 22)
	summary_lbl.add_theme_font_size_override("font_size", 12)
	summary_lbl.add_theme_color_override("font_color", secondary_color)
	summary_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(summary_lbl)

	var meta_lbl := Label.new()
	meta_lbl.text = format_card_meta(card)
	meta_lbl.position = Vector2(14, height - 22)
	meta_lbl.size = Vector2(width - 150, 14)
	meta_lbl.add_theme_font_size_override("font_size", 10)
	meta_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.6 if bool(config.get("enabled", true)) else 0.35))
	meta_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(meta_lbl)

	if count > 1:
		var count_lbl := Label.new()
		count_lbl.text = "x" + str(count)
		count_lbl.position = Vector2(width - 56, 34 if footer_text != "" else height - 24)
		count_lbl.size = Vector2(40, 14)
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_lbl.add_theme_font_size_override("font_size", 10)
		count_lbl.add_theme_color_override("font_color", CyberStyle.ACCENT_ORANGE if bool(config.get("enabled", true)) else CyberStyle.TEXT_MUTED)
		count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(count_lbl)

	if footer_text != "":
		var footer_lbl := Label.new()
		footer_lbl.text = footer_text
		footer_lbl.position = Vector2(width - 150, height - 22)
		footer_lbl.size = Vector2(134, 14)
		footer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		footer_lbl.add_theme_font_size_override("font_size", 10)
		footer_lbl.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.85 if bool(config.get("enabled", true)) else 0.45))
		footer_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(footer_lbl)

	return panel

static func _format_value(card: Dictionary) -> String:
	var t: String = String(card.get("type", "attack"))
	var v: int = int(card.get("value", 0))
	match t:
		"attack", "pierce", "shock":
			return str(v) + " 伤害"
		"defend":
			return "减伤 " + str(v)
		"heal":
			return "回复 " + str(v)
		"lifesteal":
			return str(v) + "伤/" + str(card.get("heal_value", 1)) + "回"
		"poison":
			return "毒素 " + str(v) + "回合"
		"draw":
			return "抽 " + str(v) + " 张"
		"counter":
			return "防" + str(card.get("def_value", 2)) + "/反击" + str(v)
		"combo":
			return str(card.get("hits", 3)) + "x" + str(v) + " 伤害"
	return str(v)

static func _build_card_key(card: Dictionary) -> String:
	return "|".join([
		String(card.get("name", "")),
		String(card.get("type", "")),
		str(int(card.get("cost", 1))),
		str(int(card.get("value", 0))),
		str(int(card.get("heal_value", 0))),
		str(int(card.get("def_value", 0))),
		str(int(card.get("hits", 0))),
		"1" if bool(card.get("upgraded", false)) else "0",
	])

static func _cards_equal_for_sort(card_a: Dictionary, card_b: Dictionary) -> bool:
	return _build_card_key(card_a) == _build_card_key(card_b)

static func _get_card_border_color(card: Dictionary, enabled: bool) -> Color:
	if not enabled:
		return Color(0.22, 0.24, 0.28, 0.55)
	if bool(card.get("upgraded", false)):
		return CyberStyle.ACCENT_CYAN
	return get_type_color(String(card.get("type", "attack")))

static func _create_card_surface(card: Dictionary, size_v: Vector2, enabled: bool) -> Panel:
	var panel := Panel.new()
	panel.size = size_v
	panel.custom_minimum_size = size_v
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var border_col: Color = _get_card_border_color(card, enabled)
	var sb := StyleBoxFlat.new()
	sb.bg_color = CyberStyle.BG_CARD if enabled else Color(0.03, 0.03, 0.06, 0.88)
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(border_col.r, border_col.g, border_col.b, 0.18 if enabled else 0.06)
	sb.shadow_size = 4
	panel.add_theme_stylebox_override("panel", sb)
	return panel

static func _attach_interaction(panel: Panel, config: Dictionary) -> void:
	if not bool(config.get("interactive", false)):
		return
	if not config.has("callback"):
		return
	var callback = config["callback"]
	if not (callback is Callable):
		return
	var cb: Callable = callback
	if not cb.is_valid():
		return
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var card_index: int = int(config.get("index", -1))
	panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if card_index >= 0:
				cb.call(card_index)
			else:
				cb.call()
	)
	panel.mouse_entered.connect(func(): panel.modulate = Color(1.06, 1.06, 1.06))
	panel.mouse_exited.connect(func(): panel.modulate = Color(1.0, 1.0, 1.0))

# ======== HP 条 ========

static func create_hp_bar(current: int, max_val: int, fill_color: Color, low_color: Color, w: float = 190.0, h: float = 14.0) -> Control:
	var ctr := Control.new()
	ctr.size = Vector2(w, h)
	ctr.custom_minimum_size = Vector2(w, h)
	ctr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 背景
	var bg := Panel.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(w, h)
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = Color(0.06, 0.06, 0.1)
	bg_sb.border_color = Color(0.2, 0.22, 0.28, 0.5)
	bg_sb.set_border_width_all(1)
	bg_sb.set_corner_radius_all(3)
	bg.add_theme_stylebox_override("panel", bg_sb)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctr.add_child(bg)
	# 填充条
	var ratio: float = float(current) / float(max(1, max_val))
	var bar_col: Color = fill_color if ratio > 0.3 else low_color
	var fw: float = max(0.0, (w - 4) * ratio)
	if fw > 0:
		var fill := Panel.new()
		fill.position = Vector2(2, 2)
		fill.size = Vector2(fw, h - 4)
		var fsb := StyleBoxFlat.new()
		fsb.bg_color = bar_col
		fsb.set_corner_radius_all(2)
		fill.add_theme_stylebox_override("panel", fsb)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ctr.add_child(fill)
		# 高光层
		var shine := ColorRect.new()
		shine.position = Vector2(2, 2)
		shine.size = Vector2(fw, (h - 4) * 0.35)
		shine.color = Color(1.0, 1.0, 1.0, 0.08)
		shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ctr.add_child(shine)
	# 数值文字
	var lbl := Label.new()
	lbl.text = str(current) + "/" + str(max_val)
	lbl.position = Vector2(0, 0)
	lbl.size = Vector2(w, h)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.85))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctr.add_child(lbl)
	return ctr

# ======== 能量点 ========

static func create_energy_dots(current: int, max_val: int) -> Control:
	var ds: float = 12.0
	var gap: float = 5.0
	var total_w: float = float(max_val) * ds + float(max(0, max_val - 1)) * gap
	var ctr := Control.new()
	ctr.size = Vector2(total_w, ds + 4)
	ctr.custom_minimum_size = Vector2(total_w, ds + 4)
	ctr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(max_val):
		var dot := Panel.new()
		dot.position = Vector2(float(i) * (ds + gap), 2)
		dot.size = Vector2(ds, ds)
		var dsb := StyleBoxFlat.new()
		dsb.set_corner_radius_all(6)
		if i < current:
			dsb.bg_color = CyberStyle.TEXT_ENERGY
			dsb.shadow_color = Color(0.4, 0.7, 1.0, 0.35)
			dsb.shadow_size = 3
		else:
			dsb.bg_color = Color(0.1, 0.12, 0.18)
			dsb.border_color = Color(0.2, 0.22, 0.28, 0.4)
			dsb.set_border_width_all(1)
		dot.add_theme_stylebox_override("panel", dsb)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ctr.add_child(dot)
	return ctr
