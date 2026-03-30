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
}

# ---- 卡牌类型图标（程序化符号） ----
const TYPE_ICONS: Dictionary = {
	"attack": "⚔",
	"pierce": "◇",
	"lifesteal": "♦",
	"shock": "⚡",
	"defend": "■",
	"heal": "✚",
}

# ---- 卡牌类型中文标签 ----
const TYPE_LABELS: Dictionary = {
	"attack": "攻击",
	"pierce": "穿透",
	"lifesteal": "吸血",
	"shock": "电击",
	"defend": "防御",
	"heal": "治疗",
}

# ---- 卡牌尺寸 ----
const CARD_W: float = 90.0
const CARD_H: float = 108.0

# ======== 卡牌控件创建 ========

static func create_card(card: Dictionary, can_play: bool, index: int, callback: Callable) -> Panel:
	var panel := Panel.new()
	panel.size = Vector2(CARD_W, CARD_H)
	panel.custom_minimum_size = Vector2(CARD_W, CARD_H)
	var card_type: String = String(card.get("type", "attack"))
	var accent: Color = TYPE_COLORS.get(card_type, Color(0.5, 0.5, 0.5))
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
	icon_lbl.text = TYPE_ICONS.get(card_type, "?")
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
	type_lbl.text = TYPE_LABELS.get(card_type, "")
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
	return str(v)

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
