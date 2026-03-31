extends RefCounted
class_name IsoTileRenderer

## 等距棋盘贴图渲染器（v0.1.59 全屏等距棋盘 + 高度堆叠）
## 负责：贴图加载/缓存、格坐标↔屏幕坐标转换、等距贴图绘制
## class_name 全局注册，BoardView 直接调用静态方法

# --- 等距参数（v0.1.59：放大至全屏 1280x720）---
const TILE_W: int = 144			# 菱形宽度（像素）
const TILE_H_DIAMOND: int = 72	# 菱形高度 = TILE_W / 2
const TILE_H_HALF: int = 36	# 菱形半高 = 格子行步进
const TILE_FULL_H: int = 144	# 普通贴图显示完整高度（含方块体）
const TILE_ELEVATED_H: int = 192	# 高起贴图显示高度（含突起方块）
const ELEVATION_OFFSET: int = 48	# 高起贴图额外向上偏移
const GRID_SIZE: int = 8

# --- 需要高起渲染的 tile key 集合 ---
const ELEVATED_KEYS: Array[String] = [
	"high_ground", "encounter", "heal", "shop", "chest", "item", "event", "portal"
]

# --- 贴图缓存 ---
static var _textures: Dictionary = {}
static var _loaded: bool = false

# --- 贴图路径映射（v0.1.59：特殊格使用 AI 生成的高起贴图）---
const TILE_PATHS: Dictionary = {
	"normal_light": "res://Assets/Tiles/普通格（浅色）.png",
	"normal_dark": "res://Assets/Tiles/普通格（深色）.png",
	"high_ground": "res://Assets/Tiles/high_ground_elevated.png",
	"trap": "res://Assets/Tiles/陷阱格.png",
	"encounter": "res://Assets/Tiles/encounter_elevated.png",
	"heal": "res://Assets/Tiles/heal_elevated.png",
	"item": "res://Assets/Tiles/item_elevated.png",
	"shop": "res://Assets/Tiles/shop_elevated.png",
	"chest": "res://Assets/Tiles/chest_elevated.png",
	"event": "res://Assets/Tiles/event_tile.png",
	"portal": "res://Assets/Tiles/portal_tile.png",
}

static func _ensure_loaded() -> void:
	if _loaded:
		return
	for key in TILE_PATHS.keys():
		var path: String = String(TILE_PATHS[key])
		var tex: Texture2D = load(path) as Texture2D
		if tex != null:
			_textures[String(key)] = tex
	_loaded = true

## 判断 tile_key 是否为高起贴图
static func is_elevated(tile_key: String) -> bool:
	for k in ELEVATED_KEYS:
		if k == tile_key:
			return true
	return false

# --- 坐标转换 ---

## 格坐标 → 屏幕坐标（菱形顶面中心点）
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

# --- 贴图绘制 ---

## 按 painter's algorithm 顺序绘制整张棋盘基础贴图
## board_mgr 用于查询格子类型，决定使用哪张贴图
static func draw_board(canvas: CanvasItem, origin: Vector2, board_mgr: Node) -> void:
	_ensure_loaded()
	# 按 depth = gx+gy 从后向前绘制（painter's algorithm）
	for depth in range(GRID_SIZE * 2 - 1):
		var gx_min: int = max(0, depth - GRID_SIZE + 1)
		var gx_max: int = min(GRID_SIZE - 1, depth)
		for gx in range(gx_min, gx_max + 1):
			var gy: int = depth - gx
			var tile_key: String = _get_tile_key(gx, gy, board_mgr)
			_draw_single_tile(canvas, gx, gy, tile_key, origin)

## 绘制单个贴图（含高起堆叠）
static func _draw_single_tile(canvas: CanvasItem, gx: int, gy: int, tile_key: String, origin: Vector2) -> void:
	var tex: Texture2D = _textures.get(tile_key, null) as Texture2D
	if tex == null:
		tex = _textures.get("normal_dark", null) as Texture2D
	if tex == null:
		return
	var center: Vector2 = grid_to_screen(gx, gy, origin)
	var elevated: bool = is_elevated(tile_key)
	if elevated:
		# 高起贴图：更大绘制区域 + 向上偏移
		var draw_pos: Vector2 = Vector2(
			center.x - float(TILE_W) * 0.5,
			center.y - float(TILE_H_HALF) - float(ELEVATION_OFFSET)
		)
		canvas.draw_texture_rect(tex, Rect2(draw_pos, Vector2(TILE_W, TILE_ELEVATED_H)), false)
	else:
		# 普通贴图
		var draw_pos: Vector2 = Vector2(
			center.x - float(TILE_W) * 0.5,
			center.y - float(TILE_H_HALF)
		)
		canvas.draw_texture_rect(tex, Rect2(draw_pos, Vector2(TILE_W, TILE_FULL_H)), false)

## 根据格子状态决定贴图 key
static func _get_tile_key(gx: int, gy: int, board_mgr: Node) -> String:
	var cell: Vector2i = Vector2i(gx, gy)
	if board_mgr == null:
		return "normal_dark" if (gx + gy) % 2 == 0 else "normal_light"
	# 优先级：传送门 > 遭遇 > 回复 > 商店 > 宝箱 > 道具 > 事件 > 地形 > 普通
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
	# 普通格：棋盘交替色
	return "normal_dark" if (gx + gy) % 2 == 0 else "normal_light"

# --- 叠层绘制辅助 ---

## 绘制菱形高亮（半透明填充 + 边框）
static func draw_diamond_highlight(canvas: CanvasItem, center: Vector2, fill_color: Color, border_color: Color, shrink: float = 6.0) -> void:
	var pts: PackedVector2Array = diamond_points(center, shrink)
	canvas.draw_colored_polygon(pts, fill_color)
	# 边框
	if border_color.a > 0.01:
		for i in range(4):
			canvas.draw_line(pts[i], pts[(i + 1) % 4], border_color, 2.0)

## 绘制菱形边框 L 角标（移动高亮用）
static func draw_diamond_corners(canvas: CanvasItem, center: Vector2, col: Color, shrink: float = 6.0) -> void:
	var pts: PackedVector2Array = diamond_points(center, shrink)
	var frac: float = 0.25  # 角标长度占边长比例
	for i in range(4):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % 4]
		var d: Vector2 = pts[(i + 3) % 4]
		canvas.draw_line(a, a.lerp(b, frac), col, 2.5)
		canvas.draw_line(a, a.lerp(d, frac), col, 2.5)
