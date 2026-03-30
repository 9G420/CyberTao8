extends Node
class_name BoardManager

signal board_changed

var board_size: Vector2i = Vector2i.ZERO
var occupied_cells: Dictionary = {}
var path_cells: Dictionary = {}
var item_cells: Dictionary = {}
var terrain_cells: Dictionary = {}  # cell -> String ("high_ground" / "trap")
var encounter_cells: Dictionary = {}  # cell -> String (encounter_id)
var heal_cells: Dictionary = {}  # cell -> int (heal_amount)
var event_cells: Dictionary = {}  # cell -> String (event_id)
var shop_cells: Dictionary = {}  # cell -> int (heal_amount per visit)
var chest_cells: Dictionary = {}  # cell -> String ("chest")

func build_test_board(size: Vector2i) -> void:
	board_size = size
	occupied_cells.clear()
	path_cells.clear()
	item_cells.clear()
	terrain_cells.clear()
	encounter_cells.clear()
	heal_cells.clear()
	event_cells.clear()
	shop_cells.clear()
	chest_cells.clear()
	emit_signal("board_changed")

func clear_board() -> void:
	occupied_cells.clear()
	path_cells.clear()
	item_cells.clear()
	terrain_cells.clear()
	encounter_cells.clear()
	heal_cells.clear()
	event_cells.clear()
	shop_cells.clear()
	chest_cells.clear()
	emit_signal("board_changed")

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < board_size.x and cell.y < board_size.y

func is_cell_free(cell: Vector2i) -> bool:
	return is_in_bounds(cell) and not occupied_cells.has(cell)

func set_unit_cell(unit_id: String, cell: Vector2i) -> void:
	occupied_cells[cell] = unit_id

func clear_unit_cell(cell: Vector2i) -> void:
	occupied_cells.erase(cell)

func add_path_cell(cell: Vector2i, owner_id: String) -> void:
	if is_in_bounds(cell):
		path_cells[cell] = owner_id
		emit_signal("board_changed")

func add_item_cell(cell: Vector2i, item_id: String) -> void:
	if is_in_bounds(cell):
		item_cells[cell] = item_id
		emit_signal("board_changed")

## 添加地形格（high_ground / trap），地形与路径格可共存
func add_terrain_cell(cell: Vector2i, terrain_type: String) -> void:
	if is_in_bounds(cell):
		terrain_cells[cell] = terrain_type
		emit_signal("board_changed")

## 获取指定格子的地形类型，无地形返回空字符串
func get_terrain_type(cell: Vector2i) -> String:
	return String(terrain_cells.get(cell, ""))

## 获取进入指定格的移动消耗（默认 1，高台 +1）
func get_move_cost(cell: Vector2i) -> int:
	if get_terrain_type(cell) == "high_ground":
		return 2
	return 1

func get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var offsets: Array[Vector2i] = [
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.DOWN,
	]
	for offset in offsets:
		var next_cell: Vector2i = cell + offset
		if is_in_bounds(next_cell):
			result.append(next_cell)
	return result

## BFS reachable cells within move_range, excluding occupied cells.
## 高台格消耗 2 移动点，普通格消耗 1 移动点。
func get_reachable_cells(origin: Vector2i, move_range: int) -> Array[Vector2i]:
	var reachable: Array[Vector2i] = []
	if move_range <= 0:
		return reachable
	var visited: Dictionary = {}
	visited[origin] = 0
	var frontier: Array[Vector2i] = [origin]
	while frontier.size() > 0:
		var current: Vector2i = frontier[0]
		frontier.remove_at(0)
		var current_dist: int = int(visited[current])
		var neighbors: Array[Vector2i] = get_neighbors(current)
		for nb in neighbors:
			if visited.has(nb):
				continue
			if occupied_cells.has(nb):
				continue
			var cost: int = get_move_cost(nb)
			var total: int = current_dist + cost
			if total > move_range:
				continue
			visited[nb] = total
			frontier.append(nb)
			reachable.append(nb)
	return reachable

## 获取指定格子的所有空闲相邻格（在棋盘内、未被占据、不是路径格）
func get_free_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var neighbors: Array[Vector2i] = get_neighbors(cell)
	for nb in neighbors:
		if not occupied_cells.has(nb) and not path_cells.has(nb):
			result.append(nb)
	return result

## 添加遭遇格（encounter_id 用于区分不同遭遇）
func add_encounter_cell(cell: Vector2i, encounter_id: String) -> void:
	if is_in_bounds(cell):
		encounter_cells[cell] = encounter_id
		emit_signal("board_changed")

## 清除指定遭遇格
func clear_encounter_cell(cell: Vector2i) -> void:
	encounter_cells.erase(cell)
	emit_signal("board_changed")

## 添加恢复格（持久地形，每次踩上回复 heal_amount HP）
func add_heal_cell(cell: Vector2i, heal_amount: int) -> void:
	if is_in_bounds(cell):
		heal_cells[cell] = heal_amount
		emit_signal("board_changed")

## 添加事件格（一次性触发，踩后消失）
func add_event_cell(cell: Vector2i, event_id: String) -> void:
	if is_in_bounds(cell):
		event_cells[cell] = event_id
		emit_signal("board_changed")

## 清除指定事件格
func clear_event_cell(cell: Vector2i) -> void:
	event_cells.erase(cell)
	emit_signal("board_changed")

## 添加商店格（持久地形，每次踩上消耗 crest 回复 HP）
func add_shop_cell(cell: Vector2i, heal_amount: int) -> void:
	if is_in_bounds(cell):
		shop_cells[cell] = heal_amount
		emit_signal("board_changed")

## 添加宝箱格（一次性触发，踩后消失）
func add_chest_cell(cell: Vector2i, chest_id: String) -> void:
	if is_in_bounds(cell):
		chest_cells[cell] = chest_id
		emit_signal("board_changed")

## 清除指定宝箱格
func clear_chest_cell(cell: Vector2i) -> void:
	chest_cells.erase(cell)
	emit_signal("board_changed")
