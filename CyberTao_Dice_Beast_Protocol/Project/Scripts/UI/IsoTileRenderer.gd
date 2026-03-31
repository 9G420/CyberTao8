extends RefCounted
class_name IsoTileRenderer

## 等距棋盘程序化渲染器（v0.1.63 大世界+缩放）
## 负责：格坐标↔屏幕坐标转换、等距菱形格子程序化绘制
## class_name 全局注册，BoardView 直接调用静态方法

# --- 等距参数 ---
const TILE_W: int = 192			# 菱形宽度（像素）
const TILE_H_DIAMOND: int = 96	# 菱形高度 = TILE_W / 2
const TILE_H_HALF: int = 48		# 菱形半高 = 格子行步进
const DEFAULT_GRID_SIZE: int = 12	# 默认棋盘尺寸
const AMBIENT_PAD: int = 6		# 棋盘外延伸渲染的环境格子圈数

# --- 相机跟随：根据目标格子计算 iso_origin ---

## 计算使指定格子处于屏幕中心的 iso_origin
static func calc_origin_for_cell(cell: Vector2i, screen_center: Vector2) -> Vector2:
	var ox: float = screen_center.x - float(cell.x - cell.y) * float(TILE_W) * 0.5
	var oy: float = screen_center.y - float(cell.x + cell.y) * float(TILE_H_HALF)
	return Vector2(ox, oy)

## 格坐标 → 屏幕坐标（菱形中心点），支持缩放
static func grid_to_screen_zoom(gx: int, gy: int, origin: Vector2, zoom: float) -> Vector2:
	var sx: float = origin.x + float(gx - gy) * float(TILE_W) * 0.5 * zoom
	var sy: float = origin.y + float(gx + gy) * float(TILE_H_HALF) * zoom
	return Vector2(sx, sy)

## 屏幕坐标 → 格坐标（支持缩放）
static func screen_to_grid_zoom(screen_pos: Vector2, origin: Vector2, zoom: float) -> Vector2i:
	var dx: float = screen_pos.x - origin.x
	var dy: float = screen_pos.y - origin.y
	var tw: float = float(TILE_W) * zoom
	var th: float = float(TILE_H_HALF) * zoom
	var fgx: float = (dx / tw * 2.0 + dy / th) * 0.5
	var fgy: float = (dy / th - dx / tw * 2.0) * 0.5
	return Vector2i(int(round(fgx)), int(round(fgy)))

## 菱形顶面四顶点（支持缩放）
static func diamond_points_zoom(center: Vector2, shrink: float, zoom: float) -> PackedVector2Array:
	var hw: float = (float(TILE_W) * 0.5 - shrink) * zoom
	var hh: float = (float(TILE_H_HALF) - shrink * 0.5) * zoom
	return PackedVector2Array([
		Vector2(center.x, center.y - hh),
		Vector2(center.x + hw, center.y),
		Vector2(center.x, center.y + hh),
		Vector2(center.x - hw, center.y),
	])

## calc_origin_for_cell with zoom support
static func calc_origin_for_cell_zoom(cell: Vector2i, screen_center: Vector2, zoom: float) -> Vector2:
	var ox: float = screen_center.x - float(cell.x - cell.y) * float(TILE_W) * 0.5 * zoom
	var oy: float = screen_center.y - float(cell.x + cell.y) * float(TILE_H_HALF) * zoom
	return Vector2(ox, oy)

# --- 坐标转换 ---

## 格坐标 → 屏幕坐标（菱形中心点）
static func grid_to_screen(gx: int, gy: int, origin: Vector2) -> Vector2:
	var sx: float = origin.x + float(gx - gy) * float(TILE_W) * 0.5
	var sy: float = origin.y + float(gx + gy) * float(TILE_H_HALF)
	return Vector2(sx, sy)

## 屏幕坐标 → 格坐标（最近格子，四舍五入）
static func screen_to_grid(screen_pos: Vector2, origin: Vector2) -> Vector2i:
	var dx: float = screen_pos.x - origin.x
	var dy: float = screen_pos.y - origin.y
	var fgx: float = (dx / float(TILE_W) * 2.0 + dy / float(TILE_H_HALF)) * 0.5
	var fgy: float = (dy / float(TILE_H_HALF) - dx / float(TILE_W) * 2.0) * 0.5
	return Vector2i(int(round(fgx)), int(round(fgy)))

## 菱形顶面四顶点（用于高亮/叠层绘制）
static func diamond_points(center: Vector2, shrink: float = 0.0) -> PackedVector2Array:
	var hw: float = float(TILE_W) * 0.5 - shrink
	var hh: float = float(TILE_H_HALF) - shrink * 0.5
	return PackedVector2Array([
		Vector2(center.x, center.y - hh),		# 上
		Vector2(center.x + hw, center.y),		# 右
		Vector2(center.x, center.y + hh),		# 下
		Vector2(center.x - hw, center.y),		# 左
	])

# --- 程序化绘制 ---

## 按 painter's algorithm 顺序绘制整张棋盘（含环境填充格）
static func draw_board(canvas: CanvasItem, origin: Vector2, board_mgr: Node, pulse: float = 0.5, zoom: float = 1.0) -> void:
	var gs: Vector2i = _get_grid_size(board_mgr)
	var gw: int = gs.x
	var gh: int = gs.y
	# 扩展范围：在棋盘四周绘制环境格子（消除黑色空白）
	var pad: int = int(ceil(float(AMBIENT_PAD) / zoom))
	var min_g: int = -pad
	var max_gw: int = gw + pad
	var max_gh: int = gh + pad
	for depth in range(min_g * 2, max_gw + max_gh - 1):
		var gx_min: int = max(min_g, depth - max_gh + 1)
		var gx_max: int = min(max_gw - 1, depth - min_g)
		for gx in range(gx_min, gx_max + 1):
			var gy: int = depth - gx
			if gy < min_g or gy >= max_gh:
				continue
			var in_board: bool = gx >= 0 and gy >= 0 and gx < gw and gy < gh
			if in_board:
				var tile_key: String = _get_tile_key(gx, gy, board_mgr)
				_draw_tile_procedural(canvas, gx, gy, tile_key, origin, pulse, zoom)
			else:
				_draw_ambient_tile(canvas, gx, gy, origin, zoom)

## 绘制棋盘外的环境装饰格（暗色菱形，消除黑色空白）
static func _draw_ambient_tile(canvas: CanvasItem, gx: int, gy: int, origin: Vector2, zoom: float = 1.0) -> void:
	var center: Vector2 = grid_to_screen_zoom(gx, gy, origin, zoom)
	var pts: PackedVector2Array = diamond_points_zoom(center, 1.0, zoom)
	var base_a: float = 0.6 if (gx + gy) % 2 == 0 else 0.45
	var fill: Color = Color(0.025, 0.025, 0.06, base_a)
	canvas.draw_colored_polygon(pts, fill)
	var line_col: Color = Color(0.0, 0.4, 0.6, 0.04)
	for i in range(4):
		canvas.draw_line(pts[i], pts[(i + 1) % 4], line_col, 1.0)

## 获取棋盘尺寸（优先从 board_mgr 取，否则用默认值）
static func _get_grid_size(board_mgr: Node) -> Vector2i:
	if board_mgr != null and board_mgr.board_size != Vector2i.ZERO:
		return board_mgr.board_size
	return Vector2i(DEFAULT_GRID_SIZE, DEFAULT_GRID_SIZE)

## 程序化绘制单个菱形格子
static func _draw_tile_procedural(canvas: CanvasItem, gx: int, gy: int, tile_key: String, origin: Vector2, pulse: float, zoom: float = 1.0) -> void:
	var center: Vector2 = grid_to_screen_zoom(gx, gy, origin, zoom)
	var pts: PackedVector2Array = diamond_points_zoom(center, 1.0, zoom)

	# 基础填充
	var fill_color: Color = _get_fill_color(tile_key, pulse)
	canvas.draw_colored_polygon(pts, fill_color)

	# 内部微亮区域（模拟径向渐变，缩小菱形）
	var inner_pts: PackedVector2Array = diamond_points_zoom(center, 20.0, zoom)
	var inner_color: Color = Color(fill_color.r + 0.04, fill_color.g + 0.06, fill_color.b + 0.1, 0.35)
	canvas.draw_colored_polygon(inner_pts, inner_color)

	# 网格边框线
	var border_color: Color = _get_border_color(tile_key, pulse)
	for i in range(4):
		canvas.draw_line(pts[i], pts[(i + 1) % 4], border_color, 1.0)

	# 类型特殊装饰
	_draw_tile_decoration(canvas, center, tile_key, pulse, zoom)

## 获取格子填充色
static func _get_fill_color(tile_key: String, _pulse: float) -> Color:
	match tile_key:
		"normal_dark":
			return CyberStyle.BOARD_CELL_DARK
		"normal_light":
			return CyberStyle.BOARD_CELL_LIGHT
		"high_ground":
			return Color(CyberStyle.NEON_GOLD.r, CyberStyle.NEON_GOLD.g, CyberStyle.NEON_GOLD.b, 0.18 + _pulse * 0.08)
		"trap":
			return Color(CyberStyle.NEON_RED.r, CyberStyle.NEON_RED.g, CyberStyle.NEON_RED.b, 0.18 + _pulse * 0.1)
		"encounter":
			return Color(CyberStyle.ACCENT_ORANGE.r, CyberStyle.ACCENT_ORANGE.g, CyberStyle.ACCENT_ORANGE.b, 0.2 + _pulse * 0.1)
		"heal":
			return Color(CyberStyle.NEON_BLUE.r, CyberStyle.NEON_BLUE.g, CyberStyle.NEON_BLUE.b, 0.18 + _pulse * 0.08)
		"shop":
			return Color(CyberStyle.NEON_TEAL.r, CyberStyle.NEON_TEAL.g, CyberStyle.NEON_TEAL.b, 0.18 + _pulse * 0.06)
		"chest":
			return Color(CyberStyle.NEON_GOLD.r, CyberStyle.NEON_GOLD.g, CyberStyle.NEON_GOLD.b, 0.2 + _pulse * 0.08)
		"item":
			return Color(CyberStyle.NEON_GREEN.r, CyberStyle.NEON_GREEN.g, CyberStyle.NEON_GREEN.b, 0.16 + _pulse * 0.06)
		"event":
			return Color(CyberStyle.NEON_PURPLE.r, CyberStyle.NEON_PURPLE.g, CyberStyle.NEON_PURPLE.b, 0.18 + _pulse * 0.08)
		"portal":
			return Color(CyberStyle.ACCENT_CYAN.r, CyberStyle.ACCENT_CYAN.g, CyberStyle.ACCENT_CYAN.b, 0.2 + _pulse * 0.1)
	return CyberStyle.BOARD_CELL_DARK

## 获取格子边框色
static func _get_border_color(tile_key: String, pulse: float) -> Color:
	match tile_key:
		"normal_dark", "normal_light":
			return CyberStyle.BOARD_GRID_LINE
		"high_ground":
			return Color(CyberStyle.NEON_GOLD.r, CyberStyle.NEON_GOLD.g, CyberStyle.NEON_GOLD.b, 0.3 + pulse * 0.15)
		"trap":
			return Color(CyberStyle.NEON_RED.r, CyberStyle.NEON_RED.g, CyberStyle.NEON_RED.b, 0.35 + pulse * 0.2)
		"encounter":
			return Color(CyberStyle.ACCENT_ORANGE.r, CyberStyle.ACCENT_ORANGE.g, CyberStyle.ACCENT_ORANGE.b, 0.4 + pulse * 0.2)
		"heal":
			return Color(CyberStyle.NEON_BLUE.r, CyberStyle.NEON_BLUE.g, CyberStyle.NEON_BLUE.b, 0.3 + pulse * 0.15)
		"shop":
			return Color(CyberStyle.NEON_TEAL.r, CyberStyle.NEON_TEAL.g, CyberStyle.NEON_TEAL.b, 0.3 + pulse * 0.15)
		"chest":
			return Color(CyberStyle.NEON_GOLD.r, CyberStyle.NEON_GOLD.g, CyberStyle.NEON_GOLD.b, 0.35 + pulse * 0.15)
		"item":
			return Color(CyberStyle.NEON_GREEN.r, CyberStyle.NEON_GREEN.g, CyberStyle.NEON_GREEN.b, 0.3 + pulse * 0.12)
		"event":
			return Color(CyberStyle.NEON_PURPLE.r, CyberStyle.NEON_PURPLE.g, CyberStyle.NEON_PURPLE.b, 0.3 + pulse * 0.15)
		"portal":
			return Color(CyberStyle.ACCENT_CYAN.r, CyberStyle.ACCENT_CYAN.g, CyberStyle.ACCENT_CYAN.b, 0.4 + pulse * 0.2)
	return CyberStyle.BOARD_GRID_LINE

## 绘制格子类型装饰符号
static func _draw_tile_decoration(canvas: CanvasItem, center: Vector2, tile_key: String, pulse: float, zoom: float = 1.0) -> void:
	match tile_key:
		"high_ground":
			_deco_high_ground(canvas, center, pulse, zoom)
		"trap":
			_deco_trap(canvas, center, pulse, zoom)
		"encounter":
			_deco_encounter(canvas, center, pulse, zoom)
		"heal":
			_deco_heal(canvas, center, pulse, zoom)
		"shop":
			_deco_shop(canvas, center, pulse, zoom)
		"chest":
			_deco_chest(canvas, center, pulse, zoom)
		"item":
			_deco_item(canvas, center, pulse, zoom)
		"event":
			_deco_event(canvas, center, pulse, zoom)
		"portal":
			_deco_portal(canvas, center, pulse, zoom)

# --- 装饰符号 ---

static func _deco_high_ground(c: CanvasItem, center: Vector2, pulse: float, zoom: float = 1.0) -> void:
	var col: Color = Color(CyberStyle.NEON_GOLD.r, CyberStyle.NEON_GOLD.g, CyberStyle.NEON_GOLD.b, 0.6 + pulse * 0.25)
	var s: float = 14.0 * zoom
	var cy_off: float = -4.0 * zoom
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(center.x, center.y + cy_off - s),
		Vector2(center.x - s * 0.85, center.y + cy_off + s * 0.5),
		Vector2(center.x + s * 0.85, center.y + cy_off + s * 0.5)])
	c.draw_colored_polygon(pts, col)

static func _deco_trap(c: CanvasItem, center: Vector2, pulse: float, zoom: float = 1.0) -> void:
	var col: Color = Color(CyberStyle.NEON_RED.r, CyberStyle.NEON_RED.g, CyberStyle.NEON_RED.b, 0.65 + pulse * 0.25)
	var s: float = 12.0 * zoom
	c.draw_line(Vector2(center.x - s, center.y - s), Vector2(center.x + s, center.y + s), col, 2.5)
	c.draw_line(Vector2(center.x + s, center.y - s), Vector2(center.x - s, center.y + s), col, 2.5)

static func _deco_encounter(c: CanvasItem, center: Vector2, pulse: float, zoom: float = 1.0) -> void:
	var col: Color = Color(CyberStyle.ACCENT_ORANGE.r, CyberStyle.ACCENT_ORANGE.g, CyberStyle.ACCENT_ORANGE.b, 0.7 + pulse * 0.2)
	var cy_off: float = -2.0 * zoom
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(center.x + 3 * zoom, center.y + cy_off - 14 * zoom),
		Vector2(center.x - 6 * zoom, center.y + cy_off),
		Vector2(center.x + 2 * zoom, center.y + cy_off + 1 * zoom),
		Vector2(center.x - 7 * zoom, center.y + cy_off + 16 * zoom)])
	for i in range(pts.size() - 1):
		c.draw_line(pts[i], pts[i + 1], col, 3.0)

static func _deco_heal(c: CanvasItem, center: Vector2, pulse: float, zoom: float = 1.0) -> void:
	var col: Color = Color(CyberStyle.NEON_BLUE.r, CyberStyle.NEON_BLUE.g, CyberStyle.NEON_BLUE.b, 0.65 + pulse * 0.2)
	var s: float = 11.0 * zoom
	c.draw_line(Vector2(center.x - s, center.y), Vector2(center.x + s, center.y), col, 3.0)
	c.draw_line(Vector2(center.x, center.y - s), Vector2(center.x, center.y + s), col, 3.0)

static func _deco_shop(c: CanvasItem, center: Vector2, pulse: float, zoom: float = 1.0) -> void:
	var col: Color = Color(CyberStyle.NEON_TEAL.r, CyberStyle.NEON_TEAL.g, CyberStyle.NEON_TEAL.b, 0.6 + pulse * 0.2)
	var s: float = 10.0 * zoom
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(center.x, center.y - s),
		Vector2(center.x + s, center.y),
		Vector2(center.x, center.y + s),
		Vector2(center.x - s, center.y)])
	c.draw_colored_polygon(pts, col)

static func _deco_chest(c: CanvasItem, center: Vector2, pulse: float, zoom: float = 1.0) -> void:
	var col: Color = Color(CyberStyle.NEON_GOLD.r, CyberStyle.NEON_GOLD.g, CyberStyle.NEON_GOLD.b, 0.55 + pulse * 0.25)
	var r: float = 12.0 * zoom
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(6):
		var angle: float = PI / 6.0 + float(i) * PI / 3.0
		pts.append(Vector2(center.x + cos(angle) * r, center.y + sin(angle) * r))
	c.draw_colored_polygon(pts, col)

static func _deco_item(c: CanvasItem, center: Vector2, pulse: float, zoom: float = 1.0) -> void:
	var col: Color = Color(CyberStyle.NEON_GREEN.r, CyberStyle.NEON_GREEN.g, CyberStyle.NEON_GREEN.b, 0.55 + pulse * 0.2)
	var s: float = 8.0 * zoom
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(center.x, center.y - s),
		Vector2(center.x + s, center.y),
		Vector2(center.x, center.y + s),
		Vector2(center.x - s, center.y)])
	c.draw_colored_polygon(pts, col)

static func _deco_event(c: CanvasItem, center: Vector2, pulse: float, zoom: float = 1.0) -> void:
	var col: Color = Color(CyberStyle.NEON_PURPLE.r, CyberStyle.NEON_PURPLE.g, CyberStyle.NEON_PURPLE.b, 0.75 + pulse * 0.2)
	var font: Font = ThemeDB.fallback_font
	var fs: int = int(22.0 * zoom)
	var text_w: float = font.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	canvas_draw_string_static(c, font, Vector2(center.x - text_w * 0.5, center.y + 8.0 * zoom), "?", fs, col)

static func _deco_portal(c: CanvasItem, center: Vector2, pulse: float, zoom: float = 1.0) -> void:
	var col: Color = Color(CyberStyle.ACCENT_CYAN.r, CyberStyle.ACCENT_CYAN.g, CyberStyle.ACCENT_CYAN.b, 0.5 + pulse * 0.3)
	c.draw_arc(Vector2(center.x, center.y), 16.0 * zoom, 0.0, TAU, 20, Color(col.r, col.g, col.b, col.a * 0.5), 1.5)
	c.draw_arc(Vector2(center.x, center.y), 10.0 * zoom, 0.0, TAU, 16, Color(col.r, col.g, col.b, col.a * 0.7), 2.0)
	c.draw_arc(Vector2(center.x, center.y), 4.0 * zoom, 0.0, TAU, 12, col, 2.5)

## draw_string 辅助（静态方法中无法用 canvas.draw_string 的 Font 默认参数）
static func canvas_draw_string_static(c: CanvasItem, font: Font, pos: Vector2, text: String, font_size: int, col: Color) -> void:
	c.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)

## 根据格子状态决定 tile key
static func _get_tile_key(gx: int, gy: int, board_mgr: Node) -> String:
	var cell: Vector2i = Vector2i(gx, gy)
	if board_mgr == null:
		return "normal_dark" if (gx + gy) % 2 == 0 else "normal_light"
	if board_mgr.portal_cells.has(cell):
		return "portal"
	if board_mgr.encounter_cells.has(cell):
		return "encounter"
	if board_mgr.heal_cells.has(cell):
		return "heal"
	if board_mgr.shop_cells.has(cell):
		return "shop"
	if board_mgr.chest_cells.has(cell):
		return "chest"
	if board_mgr.item_cells.has(cell):
		return "item"
	if board_mgr.event_cells.has(cell):
		return "event"
	if board_mgr.terrain_cells.has(cell):
		var ttype: String = String(board_mgr.terrain_cells[cell])
		if ttype == "high_ground":
			return "high_ground"
		if ttype == "trap":
			return "trap"
	return "normal_dark" if (gx + gy) % 2 == 0 else "normal_light"

# --- 叠层绘制辅助（支持 zoom）---

static func draw_diamond_highlight(canvas: CanvasItem, center: Vector2, fill_color: Color, border_color: Color, shrink: float = 8.0, zoom: float = 1.0) -> void:
	var pts: PackedVector2Array = diamond_points_zoom(center, shrink, zoom)
	canvas.draw_colored_polygon(pts, fill_color)
	if border_color.a > 0.01:
		for i in range(4):
			canvas.draw_line(pts[i], pts[(i + 1) % 4], border_color, 2.0)

static func draw_diamond_corners(canvas: CanvasItem, center: Vector2, col: Color, shrink: float = 8.0, zoom: float = 1.0) -> void:
	var pts: PackedVector2Array = diamond_points_zoom(center, shrink, zoom)
	var frac: float = 0.25
	for i in range(4):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % 4]
		var d: Vector2 = pts[(i + 3) % 4]
		canvas.draw_line(a, a.lerp(b, frac), col, 2.5)
		canvas.draw_line(a, a.lerp(d, frac), col, 2.5)
