extends Control
class_name BoardView

const CELL_SIZE: int = 72
const GRID_W: int = 8
const GRID_H: int = 8

var board_manager: Node = null
var unit_manager: Node = null

func _ready() -> void:
	size = Vector2(GRID_W * CELL_SIZE, GRID_H * CELL_SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func bind_managers(next_board_manager: Node, next_unit_manager: Node) -> void:
	board_manager = next_board_manager
	unit_manager = next_unit_manager
	if board_manager and not board_manager.board_changed.is_connected(_on_state_changed):
		board_manager.board_changed.connect(_on_state_changed)
	if unit_manager and not unit_manager.units_changed.is_connected(_on_state_changed):
		unit_manager.units_changed.connect(_on_state_changed)
	queue_redraw()

func _on_state_changed() -> void:
	queue_redraw()

func _draw() -> void:
	_draw_board()
	_draw_paths()
	_draw_units()

func _draw_board() -> void:
	for y in range(GRID_H):
		for x in range(GRID_W):
			var pos: Vector2 = Vector2(x * CELL_SIZE, y * CELL_SIZE)
			var base_color: Color = Color(0.11, 0.14, 0.19) if (x + y) % 2 == 0 else Color(0.08, 0.1, 0.15)
			draw_rect(Rect2(pos, Vector2(CELL_SIZE - 2, CELL_SIZE - 2)), base_color, true)
			draw_rect(Rect2(pos, Vector2(CELL_SIZE - 2, CELL_SIZE - 2)), Color(0.21, 0.28, 0.35, 0.6), false, 2.0)

func _draw_paths() -> void:
	if board_manager == null:
		return
	for cell in board_manager.path_cells.keys():
		var path_pos: Vector2 = Vector2(cell.x * CELL_SIZE + 8, cell.y * CELL_SIZE + 8)
		draw_rect(Rect2(path_pos, Vector2(CELL_SIZE - 18, CELL_SIZE - 18)), Color(1.0, 0.55, 0.2, 0.55), true)

func _draw_units() -> void:
	if unit_manager == null:
		return
	for cell in unit_manager.units_by_cell.keys():
		var unit_id: String = String(unit_manager.units_by_cell[cell])
		var unit: Dictionary = unit_manager.get_unit(unit_id)
		var owner: String = String(unit.get("owner", "player"))
		var fill: Color = Color(0.32, 0.95, 0.78) if owner == "player" else Color(0.95, 0.32, 0.4)
		var unit_pos: Vector2 = Vector2(cell.x * CELL_SIZE + 12, cell.y * CELL_SIZE + 12)
		draw_rect(Rect2(unit_pos, Vector2(CELL_SIZE - 26, CELL_SIZE - 26)), fill, true)
		draw_rect(Rect2(unit_pos, Vector2(CELL_SIZE - 26, CELL_SIZE - 26)), Color(0.04, 0.04, 0.04, 0.9), false, 2.0)
