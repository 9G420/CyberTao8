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
	var ox: float = screen_center.x - float(cell.x - cell.y) * float(TILE_W) * 0.5 * 0.88
	var oy: float = screen_center.y - float(cell.x + cell.y) * float(TILE_H_HALF) * 1.08
	return Vector2(ox, oy)

## 格坐标 → 屏幕坐标（菱形中心点），支持缩放
static func grid_to_screen_zoom(gx: int, gy: int, origin: Vector2, zoom: float) -> Vector2:
	var sx: float = origin.x + float(gx - gy) * float(TILE_W) * 0.5 * 0.88 * zoom
	var sy: float = origin.y + float(gx + gy) * float(TILE_H_HALF) * 1.08 * zoom
	return Vector2(sx, sy)

## 屏幕坐标 → 格坐标（支持缩放）
static func screen_to_grid_zoom(screen_pos: Vector2, origin: Vector2, zoom: float) -> Vector2i:
	var dx: float = screen_pos.x - origin.x
	var dy: float = screen_pos.y - origin.y
	var tw: float = float(TILE_W) * 0.88 * zoom
	var th: float = float(TILE_H_HALF) * 1.08 * zoom
	var fgx: float = (dx / tw * 2.0 + dy / th) * 0.5
	var fgy: float = (dy / th - dx / tw * 2.0) * 0.5
	return Vector2i(int(round(fgx)), int(round(fgy)))

## 菱形顶面四顶点（支持缩放）
static func diamond_points_zoom(center: Vector2, shrink: float, zoom: float) -> PackedVector2Array:
	var hw: float = (float(TILE_W) * 0.5 * 0.88 - shrink) * zoom
	var hh: float = (float(TILE_H_HALF) * 1.08 - shrink * 0.5) * zoom
	return PackedVector2Array([
		Vector2(center.x, center.y - hh),
		Vector2(center.x + hw, center.y),
		Vector2(center.x, center.y + hh),
		Vector2(center.x - hw, center.y),
	])

## calc_origin_for_cell with zoom support
static func calc_origin_for_cell_zoom(cell: Vector2i, screen_center: Vector2, zoom: float) -> Vector2:
	var ox: float = screen_center.x - float(cell.x - cell.y) * float(TILE_W) * 0.5 * 0.88 * zoom
	var oy: float = screen_center.y - float(cell.x + cell.y) * float(TILE_H_HALF) * 1.08 * zoom
	return Vector2(ox, oy)

# --- 坐标转换 ---

## 格坐标 → 屏幕坐标（菱形中心点）
static func grid_to_screen(gx: int, gy: int, origin: Vector2) -> Vector2:
	var sx: float = origin.x + float(gx - gy) * float(TILE_W) * 0.5 * 0.88
	var sy: float = origin.y + float(gx + gy) * float(TILE_H_HALF) * 1.08
	return Vector2(sx, sy)

## 屏幕坐标 → 格坐标（最近格子，四舍五入）
static func screen_to_grid(screen_pos: Vector2, origin: Vector2) -> Vector2i:
	var dx: float = screen_pos.x - origin.x
	var dy: float = screen_pos.y - origin.y
	var fgx: float = (dx / (float(TILE_W) * 0.88) * 2.0 + dy / (float(TILE_H_HALF) * 1.08)) * 0.5
	var fgy: float = (dy / (float(TILE_H_HALF) * 1.08) - dx / (float(TILE_W) * 0.88) * 2.0) * 0.5
	return Vector2i(int(round(fgx)), int(round(fgy)))

## 菱形顶面四顶点（用于高亮/叠层绘制）
static func diamond_points(center: Vector2, shrink: float = 0.0) -> PackedVector2Array:
	var hw: float = float(TILE_W) * 0.5 * 0.88 - shrink
	var hh: float = float(TILE_H_HALF) * 1.08 - shrink * 0.5
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
	# v0.1.97：外部改为“背景舞台”而非继续铺格子
	_draw_board_platform_bg(canvas, origin, gs, zoom, pulse)
	for depth in range(0, gw + gh - 1):
		var gx_min: int = max(0, depth - gh + 1)
		var gx_max: int = min(gw - 1, depth)
		for gx in range(gx_min, gx_max + 1):
			var gy: int = depth - gx
			var tile_key: String = _get_tile_key(gx, gy, board_mgr)
			_draw_tile_procedural(canvas, gx, gy, tile_key, origin, pulse, zoom)

## 绘制棋盘外“舞台背景区”（与主棋盘区分开）
static func _draw_board_platform_bg(canvas: CanvasItem, origin: Vector2, gs: Vector2i, zoom: float, pulse: float) -> void:
	var pad: int = int(5 + ceil(float(AMBIENT_PAD) / zoom))
	var min_x: int = -pad
	var min_y: int = -pad
	var max_x: int = gs.x - 1 + pad
	var max_y: int = gs.y - 1 + pad
	var p0: Vector2 = grid_to_screen_zoom(min_x, min_y, origin, zoom)
	var p1: Vector2 = grid_to_screen_zoom(max_x + 1, min_y, origin, zoom)
	var p2: Vector2 = grid_to_screen_zoom(max_x + 1, max_y + 1, origin, zoom)
	var p3: Vector2 = grid_to_screen_zoom(min_x, max_y + 1, origin, zoom)
	var ring: PackedVector2Array = PackedVector2Array([p0, p1, p2, p3])
	var base_col: Color = Color(0.16, 0.18, 0.22, 0.95)
	canvas.draw_colored_polygon(ring, base_col)
	var board_a: Vector2 = grid_to_screen_zoom(0, 0, origin, zoom)
	var board_b: Vector2 = grid_to_screen_zoom(gs.x, 0, origin, zoom)
	var board_c: Vector2 = grid_to_screen_zoom(gs.x, gs.y, origin, zoom)
	var board_d: Vector2 = grid_to_screen_zoom(0, gs.y, origin, zoom)
	var depth_vec: Vector2 = Vector2(0.0, 56.0 * zoom)
	var east_side: PackedVector2Array = PackedVector2Array([board_b, board_c, board_c + depth_vec, board_b + depth_vec])
	var south_side: PackedVector2Array = PackedVector2Array([board_d, board_c, board_c + depth_vec, board_d + depth_vec])
	canvas.draw_colored_polygon(east_side, Color(0.20, 0.24, 0.30, 0.86))
	canvas.draw_colored_polygon(south_side, Color(0.16, 0.19, 0.24, 0.88))
	canvas.draw_polyline(PackedVector2Array([board_b + depth_vec, board_c + depth_vec, board_d + depth_vec]), Color(0.55, 0.66, 0.78, 0.42), 2.0)
	# 固定边框台座（双层）
	var frame_outer: Color = Color(0.22, 0.42, 0.56, 0.46)
	var frame_inner: Color = Color(0.45, 0.85, 1.0, 0.34 + pulse * 0.12)
	for i in range(4):
		canvas.draw_line(ring[i], ring[(i + 1) % 4], frame_outer, 7.0)
	for i in range(4):
		canvas.draw_line(ring[i], ring[(i + 1) % 4], frame_inner, 2.5)

	# 四角结构件（机械支架感）
	for cpos in [p0, p1, p2, p3]:
		var a: float = 0.72
		var sz: float = 22.0 * zoom
		var r: Rect2 = Rect2(cpos - Vector2(sz, sz), Vector2(sz * 2.0, sz * 2.0))
		canvas.draw_rect(r, Color(0.16, 0.22, 0.28, 0.45), true)
		canvas.draw_rect(r, Color(0.5, 0.9, 1.0, a * 0.35), false, 2.0)
		canvas.draw_line(r.position, r.position + Vector2(r.size.x, r.size.y), Color(0.45, 0.78, 1.0, 0.20), 1.2)
		canvas.draw_line(Vector2(r.position.x + r.size.x, r.position.y), Vector2(r.position.x, r.position.y + r.size.y), Color(0.45, 0.78, 1.0, 0.20), 1.2)

	# 外场警示斜线（轻量）
	for i in range(11):
		var t_warn: float = float(i) / 10.0
		var wa: Vector2 = p0.lerp(p3, t_warn)
		var wb: Vector2 = p1.lerp(p2, t_warn)
		canvas.draw_line(wa + Vector2(-18, 0), wb + Vector2(18, 0), Color(0.75, 0.42, 0.25, 0.10), 1.2)
	# 轻微分层扫描线
	for i in range(9):
		var t: float = float(i) / 8.0
		var a: Vector2 = p0.lerp(p3, t)
		var b: Vector2 = p1.lerp(p2, t)
		canvas.draw_line(a, b, Color(0.12, 0.2, 0.3, 0.08), 1.0)

	# v0.1.102：外场有画面（角落面板+能量节点+远景条带）
	var corners: Array[Vector2] = [p0, p1, p2, p3]
	for cpos in corners:
		var panel_size: Vector2 = Vector2(110, 56) * zoom
		var panel_rect: Rect2 = Rect2(cpos - panel_size * 0.5, panel_size)
		canvas.draw_rect(panel_rect, Color(0.18, 0.24, 0.3, 0.35), true)
		canvas.draw_rect(panel_rect, Color(0.35, 0.75, 0.95, 0.28), false, 1.8)
		for li in range(3):
			var yy: float = panel_rect.position.y + 10.0 * zoom + li * 12.0 * zoom
			canvas.draw_line(Vector2(panel_rect.position.x + 10.0 * zoom, yy), Vector2(panel_rect.position.x + panel_rect.size.x - 10.0 * zoom, yy), Color(0.45, 0.85, 1.0, 0.16), 1.0)

	var mid_l: Vector2 = p0.lerp(p3, 0.5)
	var mid_r: Vector2 = p1.lerp(p2, 0.5)
	for npos in [mid_l, mid_r]:
		canvas.draw_circle(npos, 12.0 * zoom, Color(0.25, 0.65, 0.9, 0.22 + pulse * 0.08))
		canvas.draw_arc(npos, 16.0 * zoom, 0, TAU, 20, Color(0.35, 0.85, 1.0, 0.35 + pulse * 0.12), 2.0)

	for bi in range(5):
		var tb: float = float(bi) / 4.0
		var la: Vector2 = p0.lerp(p1, tb)
		var lb: Vector2 = p3.lerp(p2, tb)
		canvas.draw_line(la + Vector2(0, -22 * zoom), lb + Vector2(0, -22 * zoom), Color(0.2, 0.35, 0.5, 0.09), 1.2)

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
		"node_energy":
			return Color(0.35, 0.86, 0.95, 0.18 + _pulse * 0.1)
		"node_command":
			return Color(1.0, 0.7, 0.25, 0.2 + _pulse * 0.1)
		"node_repulse":
			return Color(0.95, 0.38, 0.38, 0.2 + _pulse * 0.1)
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
		"node_energy":
			return Color(0.5, 0.95, 1.0, 0.4 + pulse * 0.2)
		"node_command":
			return Color(1.0, 0.82, 0.4, 0.4 + pulse * 0.2)
		"node_repulse":
			return Color(1.0, 0.55, 0.55, 0.4 + pulse * 0.2)
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
		"node_energy":
			_deco_control_node(canvas, center, pulse, zoom, "E", Color(0.5, 0.95, 1.0))
		"node_command":
			_deco_control_node(canvas, center, pulse, zoom, "C", Color(1.0, 0.84, 0.4))
		"node_repulse":
			_deco_control_node(canvas, center, pulse, zoom, "R", Color(1.0, 0.55, 0.55))

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

static func _deco_control_node(c: CanvasItem, center: Vector2, pulse: float, zoom: float, label: String, base_col: Color) -> void:
	var glow: Color = Color(base_col.r, base_col.g, base_col.b, 0.45 + pulse * 0.25)
	c.draw_arc(center, 14.0 * zoom, 0.0, TAU, 24, glow, 2.0)
	c.draw_arc(center, 8.0 * zoom, 0.0, TAU, 20, Color(base_col.r, base_col.g, base_col.b, 0.7 + pulse * 0.2), 2.0)
	var font: Font = ThemeDB.fallback_font
	var fs: int = int(16.0 * zoom)
	var text_w: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	canvas_draw_string_static(c, font, Vector2(center.x - text_w * 0.5, center.y + 5.0 * zoom), label, fs, Color(1.0, 1.0, 1.0, 0.9))

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
	if board_mgr.control_nodes.has(cell):
		var ntype: String = String(board_mgr.control_nodes[cell])
		return "node_" + ntype
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
