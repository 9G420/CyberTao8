extends RefCounted
class_name PlayerSpriteAnimator

## 玩家角色精灵动画器（v0.1.70）
## 管理4方向行走 spritesheet 帧切换
## 每张 spritesheet 为 4x4 网格，共 15 帧（最后一格为空）

const COLUMNS: int = 4
const TOTAL_FRAMES: int = 15

var _textures: Dictionary = {}
var _frame_sizes: Dictionary = {}
var _current_frame: int = 0
var _current_dir: String = "down"
var _is_animating: bool = false
var _tick_count: int = 0
var _loaded: bool = false

func _init() -> void:
	var paths: Dictionary = {
		"up": "res://Assets/Tiles/刀盾向上走.png",
		"down": "res://Assets/Tiles/刀盾向下走.png",
		"left": "res://Assets/Tiles/刀盾向左走.png",
		"right": "res://Assets/Tiles/刀盾向右走.png",
	}
	for dir in paths.keys():
		var tex = load(paths[dir])
		if tex != null:
			_textures[dir] = tex
			var fw: float = float(tex.get_width()) / float(COLUMNS)
			var fh: float = float(tex.get_height()) / float(COLUMNS)
			_frame_sizes[dir] = Vector2(fw, fh)
	_loaded = _textures.size() == 4

func is_loaded() -> bool:
	return _loaded

func set_direction(dir: String) -> void:
	if dir != _current_dir:
		_current_dir = dir
		_current_frame = 0
		_tick_count = 0

func set_animating(val: bool) -> void:
	if _is_animating != val:
		_is_animating = val
		if not val:
			_current_frame = 0
			_tick_count = 0

## 每次 BoardView._on_anim_tick() 调用一次（50ms 间隔）
func tick() -> void:
	if not _is_animating:
		return
	_tick_count += 1
	if _tick_count >= 2:  # 每 2 tick 切帧 → 100ms/帧 → 10fps
		_tick_count = 0
		_current_frame = (_current_frame + 1) % TOTAL_FRAMES

func get_texture() -> Texture2D:
	return _textures.get(_current_dir, null)

func get_source_rect() -> Rect2:
	var fs: Vector2 = _frame_sizes.get(_current_dir, Vector2(758, 649))
	var col: int = _current_frame % COLUMNS
	var row: int = _current_frame / COLUMNS
	return Rect2(float(col) * fs.x, float(row) * fs.y, fs.x, fs.y)

## 根据移动起终格计算朝向
static func direction_from_cells(from_cell: Vector2i, to_cell: Vector2i) -> String:
	var dx: int = to_cell.x - from_cell.x
	var dy: int = to_cell.y - from_cell.y
	if abs(dx) >= abs(dy):
		return "right" if dx > 0 else "left"
	else:
		return "down" if dy > 0 else "up"
