extends RefCounted
class_name CyberStyle

## 赛博朋克统一视觉风格（Day 11：UI 去调试化）
## 所有面板共用配色和样式，保持一致的赛博朋克美感

# --- 配色常量 ---

# 背景
const BG_DARK := Color(0.04, 0.04, 0.08, 0.97)
const BG_PANEL := Color(0.06, 0.06, 0.12, 0.96)
const BG_CARD := Color(0.05, 0.04, 0.10, 0.97)

# 主色调
const ACCENT_ORANGE := Color(1.0, 0.55, 0.15)
const ACCENT_CYAN := Color(0.0, 0.85, 1.0)
const ACCENT_MAGENTA := Color(1.0, 0.2, 0.55)

# 边框
const BORDER_ORANGE := Color(1.0, 0.5, 0.12, 0.85)
const BORDER_CYAN := Color(0.0, 0.75, 0.9, 0.7)
const BORDER_ENCOUNTER := Color(1.0, 0.35, 0.1, 0.9)

# 文字
const TEXT_TITLE := Color(1.0, 0.72, 0.28)
const TEXT_PRIMARY := Color(0.92, 0.9, 0.82)
const TEXT_SECONDARY := Color(0.65, 0.72, 0.7)
const TEXT_MUTED := Color(0.45, 0.48, 0.5)
const TEXT_WARN := Color(1.0, 0.35, 0.25)
const TEXT_SUCCESS := Color(0.2, 1.0, 0.45)
const TEXT_CYAN := Color(0.4, 0.9, 1.0)
const TEXT_ENERGY := Color(0.45, 0.7, 1.0)

# HP
const HP_PLAYER := Color(0.3, 0.95, 0.65)
const HP_PLAYER_LOW := Color(1.0, 0.3, 0.25)
const HP_ENEMY := Color(0.95, 0.45, 0.3)
const HP_ENEMY_LOW := Color(1.0, 0.25, 0.2)

# 按钮
const BTN_BG := Color(0.08, 0.08, 0.16)
const BTN_BG_HOVER := Color(0.12, 0.12, 0.22)
const BTN_BG_PRESSED := Color(0.05, 0.05, 0.1)
const BTN_BG_DISABLED := Color(0.06, 0.06, 0.1)
const BTN_BORDER := Color(0.0, 0.65, 0.85, 0.6)
const BTN_BORDER_HOVER := Color(0.0, 0.85, 1.0, 0.85)
const BTN_BORDER_ORANGE := Color(1.0, 0.5, 0.15, 0.6)
const BTN_BORDER_ORANGE_HOVER := Color(1.0, 0.6, 0.2, 0.85)
const BTN_TEXT := Color(0.8, 0.9, 0.95)
const BTN_TEXT_DISABLED := Color(0.35, 0.38, 0.42)

# 棋盘 Phase 1 美化专用
const BOARD_CELL_DARK := Color(0.04, 0.04, 0.09)
const BOARD_CELL_LIGHT := Color(0.07, 0.08, 0.14)
const BOARD_GRID_LINE := Color(0.0, 0.7, 0.9, 0.10)
const BOARD_INNER_GLOW := Color(0.08, 0.12, 0.22, 0.5)
const NEON_GOLD := Color(1.0, 0.82, 0.3)
const NEON_RED := Color(1.0, 0.25, 0.2)
const NEON_TEAL := Color(0.15, 0.92, 0.75)
const NEON_PURPLE := Color(0.8, 0.45, 1.0)
const NEON_BLUE := Color(0.4, 0.75, 1.0)
const NEON_GREEN := Color(0.25, 1.0, 0.5)

# --- 样式工厂方法 ---

static func make_panel_bg(border_color: Color = BORDER_CYAN, radius: int = 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG_PANEL
	sb.border_color = border_color
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.15)
	sb.shadow_size = 4
	return sb

static func make_btn_normal(border_color: Color = BTN_BORDER) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = BTN_BG
	sb.border_color = border_color
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb

static func make_btn_hover(border_color: Color = BTN_BORDER_HOVER) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = BTN_BG_HOVER
	sb.border_color = border_color
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.2)
	sb.shadow_size = 3
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb

static func make_btn_pressed() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = BTN_BG_PRESSED
	sb.border_color = ACCENT_CYAN
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb

static func make_btn_disabled() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = BTN_BG_DISABLED
	sb.border_color = Color(0.2, 0.22, 0.25, 0.4)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb

static func style_button(btn: Button, accent: String = "cyan") -> void:
	var border_n: Color = BTN_BORDER
	var border_h: Color = BTN_BORDER_HOVER
	if accent == "orange":
		border_n = BTN_BORDER_ORANGE
		border_h = BTN_BORDER_ORANGE_HOVER
	btn.add_theme_stylebox_override("normal", make_btn_normal(border_n))
	btn.add_theme_stylebox_override("hover", make_btn_hover(border_h))
	btn.add_theme_stylebox_override("pressed", make_btn_pressed())
	btn.add_theme_stylebox_override("disabled", make_btn_disabled())
	btn.add_theme_color_override("font_color", BTN_TEXT)
	btn.add_theme_color_override("font_hover_color", ACCENT_CYAN if accent == "cyan" else ACCENT_ORANGE)
	btn.add_theme_color_override("font_pressed_color", ACCENT_CYAN)
	btn.add_theme_color_override("font_disabled_color", BTN_TEXT_DISABLED)

static func make_encounter_panel_bg() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.04, 0.02, 0.97)
	sb.border_color = BORDER_ENCOUNTER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.shadow_color = Color(1.0, 0.3, 0.1, 0.2)
	sb.shadow_size = 5
	return sb
