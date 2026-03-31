extends RefCounted
class_name IsoTileRenderer

## 等距棋盘贴图渲染器（v0.1.60 相机跟随 + 全新素材）
## 负责：贴图加载/缓存、格坐标↔屏幕坐标转换、等距贴图绘制
## class_name 全局注册，BoardView 直接调用静态方法

# --- 等距参数（v0.1.60：放大至超出视口，配合相机跟随）---
const TILE_W: int = 192			# 菱形宽度（像素）
const TILE_H_DIAMOND: int = 96	# 菱形高度 = TILE_W / 2
const TILE_H_HALF: int = 48	# 菱形半高 = 格子行步进
const TILE_FULL_H: int = 192	# 普通贴图显示完整高度（含方块体）
const TILE_ELEVATED_H: int = 256	# 高起贴图显示高度（含突起方块）
const ELEVATION_OFFSET: int = 64	# 高起贴图额外向上偏移
const GRID_SIZE: int = 8

# --- 需要高起渲染的 tile key 集合 ---
const ELEVATED_KEYS: Array[String] = [
	"high_ground", "encounter", "heal", "shop", "chest", "item", "event", "portal"
]

# --- 贴图缓存 ---
static var _textures: Dictionary = {}
static var _loaded: bool = false

# --- 贴图路径映射（v0.1.60：全新 AI 生成素材）---
const TILE_PATHS: Dictionary = {
	"normal_light": "res://Assets/Tiles/normal_light.png",
	"normal_dark": "res://Assets/Tiles/normal_dark.png",
	"high_ground": "res://Assets/Tiles/high_ground.png",
	"trap": "res://Assets/Tiles/trap.png",
	"encounter": "res://Assets/Tiles/encounter.png",
	"heal": "res://Assets/Tiles/heal.png",
	"item": "res://Assets/Tiles/item.png",
	"shop": "res://Assets/Tiles/shop.png",
	"chest": "res://Assets/Tiles/chest.png",
	"event": "res://Assets/Tiles/event.png",
	"portal": "res://Assets/Tiles/portal.png",
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

# --- 相机跟随：根据目标格子计算 iso_origin ---

## 计算使指定格子处于屏幕中心的 iso_origin
static func calc_origin_for_cell(cell: Vector2i, screen_center: Vector2) -> Vector2:
	# 反推 origin 使 grid_to_screen(cell.x, cell.y, origin) == screen_center
	var ox: float = screen_center.x - float(cell.x - cell.y) * float(TILE_W) * 0.5
	var oy: float = screen_center.y - float(cell.x + cell.y) * float(TILE_H_HALF)
	return Vector2(ox, oy)

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
static func draw_board(canvas: CanvasItem, origin: Vector2, board_mgr: Node) -> void:
	_ensure_loaded()
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
		var draw_pos: Vector2 = Vector2(
			center.x - float(TILE_W) * 0.5,
			center.y - float(TILE_H_HALF) - float(ELEVATION_OFFSET)
		)
		canvas.draw_texture_rect(tex, Rect2(draw_pos, Vector2(TILE_W, TILE_ELEVATED_H)), false)
	else:
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

# --- 叠层绘制辅助 ---

static func draw_diamond_highlight(canvas: CanvasItem, center: Vector2, fill_color: Color, border_color: Color, shrink: float = 8.0) -> void:
	var pts: PackedVector2Array = diamond_points(center, shrink)
	canvas.draw_colored_polygon(pts, fill_color)
	if border_color.a > 0.01:
		for i in range(4):
			canvas.draw_line(pts[i], pts[(i + 1) % 4], border_color, 2.0)

static func draw_diamond_corners(canvas: CanvasItem, center: Vector2, col: Color, shrink: float = 8.0) -> void:
	var pts: PackedVector2Array = diamond_points(center, shrink)
	var frac: float = 0.25
	for i in range(4):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % 4]
		var d: Vector2 = pts[(i + 3) % 4]
		canvas.draw_line(a, a.lerp(b, frac), col, 2.5)
		canvas.draw_line(a, a.lerp(d, frac), col, 2.5)
