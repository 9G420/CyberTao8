extends Node
class_name BoardManager

signal board_changed

var board_size: Vector2i = Vector2i.ZERO
var occupied_cells: Dictionary = {}
var path_cells: Dictionary = {}
var item_cells: Dictionary = {}

func build_test_board(size: Vector2i) -> void:
	board_size = size
	occupied_cells.clear()
	path_cells.clear()
	item_cells.clear()
	emit_signal("board_changed")

func clear_board() -> void:
	occupied_cells.clear()
	path_cells.clear()
	item_cells.clear()
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
		if current_dist >= move_range:
			continue
		var neighbors: Array[Vector2i] = get_neighbors(current)
		for nb in neighbors:
			if visited.has(nb):
				continue
			if occupied_cells.has(nb):
				continue
			visited[nb] = current_dist + 1
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
