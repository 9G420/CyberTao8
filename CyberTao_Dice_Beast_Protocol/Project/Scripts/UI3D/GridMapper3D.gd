extends RefCounted
class_name GridMapper3D

## 3D 网格坐标映射器（v0.1.71）
## 负责棋盘格坐标(Vector2i) ↔ 3D世界坐标(Vector3) 的双向转换
## 纯数学工具类，无依赖

const CELL_SIZE: float = 2.0		# 每格世界单位边长
const HALF_CELL: float = 1.0		# CELL_SIZE / 2
const DEFAULT_GRID: int = 12		# 默认棋盘尺寸

## 格坐标 → 3D 世界坐标（格子中心点，Y=0 地面）
## 棋盘以原点为中心：grid(0,0) 在左上角偏移
static func cell_to_world(cell: Vector2i, grid_size: int = DEFAULT_GRID) -> Vector3:
	var offset: float = float(grid_size) * HALF_CELL
	var wx: float = float(cell.x) * CELL_SIZE + HALF_CELL - offset
	var wz: float = float(cell.y) * CELL_SIZE + HALF_CELL - offset
	return Vector3(wx, 0.0, wz)

## 3D 世界坐标 → 格坐标（四舍五入到最近格子）
static func world_to_cell(world_pos: Vector3, grid_size: int = DEFAULT_GRID) -> Vector2i:
	var offset: float = float(grid_size) * HALF_CELL
	var gx: int = int(round((world_pos.x + offset - HALF_CELL) / CELL_SIZE))
	var gy: int = int(round((world_pos.z + offset - HALF_CELL) / CELL_SIZE))
	return Vector2i(gx, gy)

## 判断格坐标是否在棋盘范围内
static func is_in_bounds(cell: Vector2i, grid_size: int = DEFAULT_GRID) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size and cell.y < grid_size

## 两格之间的世界距离
static func cell_distance_world(a: Vector2i, b: Vector2i, grid_size: int = DEFAULT_GRID) -> float:
	return cell_to_world(a, grid_size).distance_to(cell_to_world(b, grid_size))

## 棋盘总世界尺寸
static func board_world_size(grid_size: int = DEFAULT_GRID) -> float:
	return float(grid_size) * CELL_SIZE

## 棋盘中心点（世界坐标）
static func board_center(grid_size: int = DEFAULT_GRID) -> Vector3:
	return Vector3.ZERO  # 棋盘以原点为中心
