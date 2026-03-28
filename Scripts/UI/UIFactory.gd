# ============================================================
# UIFactory.gd - STS风格按钮/面板工厂
# 提供统一的主题化UI组件创建方法
# ============================================================
class_name UIFactory
extends RefCounted

# ── 颜色常量 ──
const COLOR_DARK_BG := Color(0.06, 0.03, 0.12, 0.9)
const COLOR_DARK_BG_LIGHT := Color(0.08, 0.04, 0.16, 0.9)
const COLOR_GOLD := Color(1, 0.85, 0.3)
const COLOR_GOLD_DIM := Color(0.7, 0.55, 0.15, 0.6)
const COLOR_RED := Color(0.85, 0.2, 0.2)
const COLOR_RED_DIM := Color(0.6, 0.12, 0.12, 0.6)
const COLOR_CYAN := Color(0, 0.9, 1)
const COLOR_CYAN_DIM := Color(0, 0.5, 0.8, 0.5)
const COLOR_SILVER := Color(0.75, 0.78, 0.82)
const COLOR_SILVER_DIM := Color(0.45, 0.48, 0.52, 0.6)
const COLOR_GREEN := Color(0.3, 0.9, 0.4)
const COLOR_GREEN_DIM := Color(0.15, 0.55, 0.2, 0.5)
const COLOR_PURPLE := Color(0.7, 0.3, 0.9)

# ========================================
# 红色卷轴/绸带按钮 (返回、启程、主操作)
# ========================================
static func make_ribbon_button(text: String, width: float = 260.0, height: float = 54.0) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(width, height)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(1, 0.95, 0.85))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_shadow_color", Color(0.3, 0.05, 0.0, 0.5))
	btn.add_theme_constant_override("shadow_offset_x", 1)
	btn.add_theme_constant_override("shadow_offset_y", 2)
	# Normal
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.6, 0.1, 0.08, 0.92)
	sb.border_color = Color(0.85, 0.35, 0.15, 0.85)
	sb.set_border_width_all(3)
	sb.border_width_top = 2
	sb.border_width_bottom = 4
	sb.corner_radius_top_left = 2
	sb.corner_radius_top_right = 2
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.shadow_color = Color(0.9, 0.3, 0.1, 0.3)
	sb.shadow_size = 4
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 6
	sb.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", sb)
	# Hover
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = Color(0.72, 0.14, 0.1, 0.95)
	sb_h.border_color = Color(1, 0.5, 0.2, 0.95)
	sb_h.shadow_size = 8
	sb_h.shadow_color = Color(1, 0.4, 0.1, 0.45)
	btn.add_theme_stylebox_override("hover", sb_h)
	# Pressed
	var sb_p := sb.duplicate() as StyleBoxFlat
	sb_p.bg_color = Color(0.45, 0.08, 0.06, 0.95)
	sb_p.shadow_size = 2
	btn.add_theme_stylebox_override("pressed", sb_p)
	# Disabled
	var sb_d := sb.duplicate() as StyleBoxFlat
	sb_d.bg_color = Color(0.25, 0.1, 0.1, 0.6)
	sb_d.border_color = Color(0.4, 0.2, 0.15, 0.4)
	sb_d.shadow_size = 0
	btn.add_theme_stylebox_override("disabled", sb_d)
	btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.4, 0.35))
	return btn

# ========================================
# 银灰六边形金属按钮 (结束回合)
# ========================================
static func make_metal_button(text: String, width: float = 180.0, height: float = 50.0) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(width, height)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_shadow_color", Color(0.1, 0.1, 0.15, 0.4))
	btn.add_theme_constant_override("shadow_offset_x", 1)
	btn.add_theme_constant_override("shadow_offset_y", 1)
	# Normal - metallic silver
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.28, 0.3, 0.35, 0.92)
	sb.border_color = Color(0.55, 0.58, 0.65, 0.85)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(4)
	sb.shadow_color = Color(0.4, 0.45, 0.55, 0.35)
	sb.shadow_size = 4
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", sb)
	# Hover
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = Color(0.35, 0.38, 0.44, 0.95)
	sb_h.border_color = Color(0.7, 0.75, 0.85, 0.95)
	sb_h.shadow_size = 7
	sb_h.shadow_color = Color(0.5, 0.6, 0.8, 0.4)
	btn.add_theme_stylebox_override("hover", sb_h)
	# Pressed
	var sb_p := sb.duplicate() as StyleBoxFlat
	sb_p.bg_color = Color(0.2, 0.22, 0.28, 0.95)
	sb_p.shadow_size = 1
	btn.add_theme_stylebox_override("pressed", sb_p)
	# Disabled
	var sb_d := sb.duplicate() as StyleBoxFlat
	sb_d.bg_color = Color(0.18, 0.18, 0.2, 0.6)
	sb_d.border_color = Color(0.3, 0.3, 0.35, 0.4)
	sb_d.shadow_size = 0
	btn.add_theme_stylebox_override("disabled", sb_d)
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.45))
	return btn

# ========================================
# 青色圆角按钮 (跳过、次要操作)
# ========================================
static func make_cyan_button(text: String, width: float = 200.0, height: float = 44.0) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(width, height)
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", COLOR_CYAN)
	btn.add_theme_color_override("font_hover_color", Color(0.5, 1, 1))
	# Normal
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.08, 0.14, 0.88)
	sb.border_color = Color(0, 0.5, 0.7, 0.6)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.shadow_color = Color(0, 0.4, 0.6, 0.25)
	sb.shadow_size = 3
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	btn.add_theme_stylebox_override("normal", sb)
	# Hover
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = Color(0.05, 0.12, 0.2, 0.92)
	sb_h.border_color = Color(0, 0.8, 1, 0.85)
	sb_h.shadow_size = 6
	sb_h.shadow_color = Color(0, 0.6, 0.9, 0.4)
	btn.add_theme_stylebox_override("hover", sb_h)
	# Pressed
	var sb_p := sb.duplicate() as StyleBoxFlat
	sb_p.bg_color = Color(0.02, 0.05, 0.1, 0.95)
	btn.add_theme_stylebox_override("pressed", sb_p)
	return btn

# ========================================
# 红色箭头按钮 (跳过奖励)
# ========================================
static func make_arrow_button(text: String, width: float = 200.0, height: float = 44.0) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(width, height)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.9, 0.5, 0.4))
	btn.add_theme_color_override("font_hover_color", Color(1, 0.7, 0.6))
	# Normal - subtle red with arrow feel (pointed right side)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.2, 0.05, 0.05, 0.8)
	sb.border_color = Color(0.6, 0.15, 0.12, 0.6)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_right = 14
	sb.shadow_color = Color(0.5, 0.1, 0.05, 0.2)
	sb.shadow_size = 3
	sb.content_margin_left = 16
	sb.content_margin_right = 20
	btn.add_theme_stylebox_override("normal", sb)
	# Hover
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = Color(0.3, 0.08, 0.06, 0.9)
	sb_h.border_color = Color(0.8, 0.25, 0.15, 0.85)
	sb_h.shadow_size = 6
	btn.add_theme_stylebox_override("hover", sb_h)
	return btn

# ========================================
# 金色强调按钮 (重要操作: 选择卡牌等)
# ========================================
static func make_gold_button(text: String, width: float = 240.0, height: float = 50.0) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(width, height)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", COLOR_GOLD)
	btn.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.7))
	btn.add_theme_color_override("font_shadow_color", Color(0.4, 0.3, 0.0, 0.5))
	btn.add_theme_constant_override("shadow_offset_x", 1)
	btn.add_theme_constant_override("shadow_offset_y", 1)
	# Normal
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.08, 0.02, 0.9)
	sb.border_color = Color(0.7, 0.55, 0.15, 0.7)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(4)
	sb.shadow_color = Color(0.8, 0.6, 0.1, 0.3)
	sb.shadow_size = 4
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	btn.add_theme_stylebox_override("normal", sb)
	# Hover
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = Color(0.16, 0.11, 0.03, 0.95)
	sb_h.border_color = Color(1, 0.8, 0.25, 0.9)
	sb_h.shadow_size = 8
	sb_h.shadow_color = Color(1, 0.7, 0.15, 0.45)
	btn.add_theme_stylebox_override("hover", sb_h)
	# Pressed
	var sb_p := sb.duplicate() as StyleBoxFlat
	sb_p.bg_color = Color(0.08, 0.05, 0.01, 0.95)
	sb_p.shadow_size = 1
	btn.add_theme_stylebox_override("pressed", sb_p)
	# Disabled
	var sb_d := sb.duplicate() as StyleBoxFlat
	sb_d.bg_color = Color(0.08, 0.06, 0.03, 0.5)
	sb_d.border_color = Color(0.4, 0.3, 0.1, 0.3)
	sb_d.shadow_size = 0
	btn.add_theme_stylebox_override("disabled", sb_d)
	btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.4, 0.3))
	return btn

# ========================================
# 暗灰次要按钮 (返回标题等低优先级)
# ========================================
static func make_dim_button(text: String, width: float = 200.0, height: float = 44.0) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(width, height)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
	btn.add_theme_color_override("font_hover_color", Color(0.8, 0.8, 0.85))
	# Normal
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.08, 0.75)
	sb.border_color = Color(0.3, 0.3, 0.35, 0.45)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.shadow_color = Color(0.2, 0.2, 0.25, 0.15)
	sb.shadow_size = 2
	btn.add_theme_stylebox_override("normal", sb)
	# Hover
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.border_color = Color(0.5, 0.5, 0.6, 0.7)
	sb_h.shadow_size = 4
	btn.add_theme_stylebox_override("hover", sb_h)
	return btn

# ========================================
# 绿色确认按钮 (选择卡牌、购买)
# ========================================
static func make_green_button(text: String, width: float = 220.0, height: float = 44.0) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(width, height)
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", COLOR_GREEN)
	btn.add_theme_color_override("font_hover_color", Color(0.5, 1, 0.6))
	# Normal
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.1, 0.05, 0.88)
	sb.border_color = Color(0.15, 0.55, 0.2, 0.6)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(5)
	sb.shadow_color = Color(0.1, 0.5, 0.15, 0.25)
	sb.shadow_size = 3
	btn.add_theme_stylebox_override("normal", sb)
	# Hover
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = Color(0.06, 0.14, 0.07, 0.92)
	sb_h.border_color = Color(0.2, 0.8, 0.3, 0.85)
	sb_h.shadow_size = 6
	btn.add_theme_stylebox_override("hover", sb_h)
	# Disabled
	var sb_d := sb.duplicate() as StyleBoxFlat
	sb_d.bg_color = Color(0.04, 0.06, 0.04, 0.5)
	sb_d.border_color = Color(0.15, 0.25, 0.15, 0.3)
	sb_d.shadow_size = 0
	btn.add_theme_stylebox_override("disabled", sb_d)
	btn.add_theme_color_override("font_disabled_color", Color(0.35, 0.45, 0.35))
	return btn

# ========================================
# STS风格面板 (暗色底+发光边框)
# ========================================
static func make_panel_style(border_color: Color = Color(0.4, 0.15, 0.6, 0.6)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.025, 0.08, 0.9)
	sb.border_color = border_color
	sb.set_border_width_all(2)
	sb.border_width_top = 3
	sb.set_corner_radius_all(3)
	sb.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.25)
	sb.shadow_size = 5
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb

# ========================================
# STS风格横幅标题栏 (如"选择一张牌")
# ========================================
static func make_banner(text: String, width: float = 600.0) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(width, 56)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.04, 0.02, 0.92)
	sb.border_color = Color(0.7, 0.5, 0.15, 0.7)
	sb.set_border_width_all(2)
	sb.border_width_bottom = 4
	sb.set_corner_radius_all(2)
	sb.shadow_color = Color(0.6, 0.4, 0.1, 0.3)
	sb.shadow_size = 6
	panel.add_theme_stylebox_override("panel", sb)
	# 顶部金线装饰
	var top_line := ColorRect.new()
	top_line.position = Vector2(2, 0)
	top_line.size = Vector2(width - 4, 2)
	top_line.color = Color(1, 0.8, 0.3, 0.6)
	top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(top_line)
	# 标题文字
	var label := Label.new()
	label.text = text
	label.position = Vector2(0, 0)
	label.size = Vector2(width, 56)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", COLOR_GOLD)
	label.add_theme_color_override("font_shadow_color", Color(0.4, 0.25, 0.0, 0.5))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	return panel
