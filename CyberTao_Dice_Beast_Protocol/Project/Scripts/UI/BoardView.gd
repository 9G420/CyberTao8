extends Control
class_name BoardView

signal unit_selected(unit_id: String)
signal unit_deselected
signal move_requested(unit_id: String, target_cell: Vector2i)
signal attack_requested(unit_id: String, target_cell: Vector2i)
signal summon_requested(unit_id: String, target_cell: Vector2i)

const CELL_SIZE: int = 72
const GRID_W: int = 8
const GRID_H: int = 8

var board_manager: Node = null
var unit_manager: Node = null
var battle_flow: Node = null

# Selection state
var selected_unit_id: String = ""
var highlight_cells: Array[Vector2i] = []
var attack_highlight_cells: Array[Vector2i] = []
var summon_highlight_cells: Array[Vector2i] = []

# Attack feedback state
var _flash_cell: Vector2i = Vector2i(-1, -1)
var _flash_alpha: float = 0.0
var _damage_label: Label = null

func _ready() -> void:
	size = Vector2(GRID_W * CELL_SIZE, GRID_H * CELL_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP

func bind_managers(next_board_manager: Node, next_unit_manager: Node) -> void:
	board_manager = next_board_manager
	unit_manager = next_unit_manager
	if board_manager and not board_manager.board_changed.is_connected(_on_state_changed):
		board_manager.board_changed.connect(_on_state_changed)
	if unit_manager and not unit_manager.units_changed.is_connected(_on_state_changed):
		unit_manager.units_changed.connect(_on_state_changed)
	queue_redraw()

func bind_battle_flow(next_battle_flow: Node) -> void:
	battle_flow = next_battle_flow
	if battle_flow and battle_flow.phase_changed and not battle_flow.phase_changed.is_connected(_on_phase_changed):
		battle_flow.phase_changed.connect(_on_phase_changed)

func _on_phase_changed(_phase_name: String) -> void:
	# Deselect and clear highlights on any phase transition
	if selected_unit_id != "":
		_deselect()

func _on_state_changed() -> void:
	# Refresh highlights if a unit is selected (board changed)
	if selected_unit_id != "" and battle_flow:
		# 如果选中的单位已不存在（被击杀），自动取消选中
		if unit_manager and unit_manager.get_unit(selected_unit_id).is_empty():
			_deselect()
			return
		highlight_cells = battle_flow.get_reachable_cells_for(selected_unit_id)
		attack_highlight_cells = battle_flow.get_attackable_cells_for(selected_unit_id)
		summon_highlight_cells = _filter_summon_cells(battle_flow.get_summon_cells_for(selected_unit_id))
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	var cell: Vector2i = _pixel_to_cell(mb.position)
	if not _is_valid_cell(cell):
		return
	_handle_cell_click(cell)
	accept_event()

func _pixel_to_cell(pixel_pos: Vector2) -> Vector2i:
	var cx: int = int(pixel_pos.x) / CELL_SIZE
	var cy: int = int(pixel_pos.y) / CELL_SIZE
	return Vector2i(cx, cy)

func _is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_W and cell.y < GRID_H

func _handle_cell_click(cell: Vector2i) -> void:
	# Block interaction if battle is over
	if battle_flow and battle_flow.is_battle_over():
		return
	# If a unit is selected
	if selected_unit_id != "":
		# Check if clicked cell is an attack target
		var is_attack_target: bool = false
		for ac in attack_highlight_cells:
			if ac == cell:
				is_attack_target = true
				break
		if is_attack_target:
			emit_signal("attack_requested", selected_unit_id, cell)
			return
		# Check if clicked cell is a move target (优先于召唤)
		var is_move_target: bool = false
		for hc in highlight_cells:
			if hc == cell:
				is_move_target = true
				break
		if is_move_target:
			emit_signal("move_requested", selected_unit_id, cell)
			return
		# Check if clicked cell is a summon target (仅在不可移动时触发)
		var is_summon_target: bool = false
		for sc in summon_highlight_cells:
			if sc == cell:
				is_summon_target = true
				break
		if is_summon_target:
			emit_signal("summon_requested", selected_unit_id, cell)
			return
		# Clicking the same unit again deselects
		if unit_manager and unit_manager.units_by_cell.has(cell):
			var clicked_id: String = String(unit_manager.units_by_cell[cell])
			if clicked_id == selected_unit_id:
				_deselect()
				return
			# Clicked a different player unit — select it instead
			var clicked_unit: Dictionary = unit_manager.get_unit(clicked_id)
			if String(clicked_unit.get("owner", "")) == "player":
				_select_unit(clicked_id)
				return
		# Clicked empty cell or enemy — deselect
		_deselect()
		return
	# No unit selected — check if clicking a player unit
	if unit_manager and unit_manager.units_by_cell.has(cell):
		var clicked_id: String = String(unit_manager.units_by_cell[cell])
		var clicked_unit: Dictionary = unit_manager.get_unit(clicked_id)
		if String(clicked_unit.get("owner", "")) == "player":
			_select_unit(clicked_id)

func _select_unit(unit_id: String) -> void:
	selected_unit_id = unit_id
	if battle_flow:
		highlight_cells = battle_flow.get_reachable_cells_for(unit_id)
		attack_highlight_cells = battle_flow.get_attackable_cells_for(unit_id)
		summon_highlight_cells = _filter_summon_cells(battle_flow.get_summon_cells_for(unit_id))
	else:
		highlight_cells = []
		attack_highlight_cells = []
		summon_highlight_cells = []
	emit_signal("unit_selected", unit_id)
	queue_redraw()

func _deselect() -> void:
	selected_unit_id = ""
	highlight_cells = []
	attack_highlight_cells = []
	summon_highlight_cells = []
	emit_signal("unit_deselected")
	queue_redraw()

## 过滤召唤高亮格：移除已在移动高亮中的格子，避免点击移动时误触召唤
func _filter_summon_cells(raw_summon_cells: Array[Vector2i]) -> Array[Vector2i]:
	var filtered: Array[Vector2i] = []
	for sc in raw_summon_cells:
		var in_move: bool = false
		for hc in highlight_cells:
			if hc == sc:
				in_move = true
				break
		if not in_move:
			filtered.append(sc)
	return filtered

func _draw() -> void:
	_draw_board()
	_draw_terrain()
	_draw_highlights()
	_draw_attack_highlights()
	_draw_summon_highlights()
	_draw_paths()
	_draw_units()
	_draw_unit_hp()
	_draw_selection_ring()
	_draw_attack_flash()

func _draw_board() -> void:
	for y in range(GRID_H):
		for x in range(GRID_W):
			var pos: Vector2 = Vector2(x * CELL_SIZE, y * CELL_SIZE)
			var base_color: Color = Color(0.11, 0.14, 0.19) if (x + y) % 2 == 0 else Color(0.08, 0.1, 0.15)
			draw_rect(Rect2(pos, Vector2(CELL_SIZE - 2, CELL_SIZE - 2)), base_color, true)
			draw_rect(Rect2(pos, Vector2(CELL_SIZE - 2, CELL_SIZE - 2)), Color(0.21, 0.28, 0.35, 0.6), false, 2.0)

func _draw_highlights() -> void:
	for cell in highlight_cells:
		var pos: Vector2 = Vector2(cell.x * CELL_SIZE + 4, cell.y * CELL_SIZE + 4)
		var sz: Vector2 = Vector2(CELL_SIZE - 10, CELL_SIZE - 10)
		# Filled highlight
		draw_rect(Rect2(pos, sz), Color(0.2, 0.8, 1.0, 0.22), true)
		# Border highlight
		draw_rect(Rect2(pos, sz), Color(0.2, 0.85, 1.0, 0.65), false, 2.0)

## 绘制地形格：高台（金色）、陷阱（暗红尖刺风格）
func _draw_terrain() -> void:
	if board_manager == null:
		return
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 10
	for cell in board_manager.terrain_cells.keys():
		var terrain_type: String = String(board_manager.terrain_cells[cell])
		var pos: Vector2 = Vector2(cell.x * CELL_SIZE + 1, cell.y * CELL_SIZE + 1)
		var sz: Vector2 = Vector2(CELL_SIZE - 4, CELL_SIZE - 4)
		if terrain_type == "high_ground":
			# 高台：金色填充 + 金色边框
			draw_rect(Rect2(pos, sz), Color(0.85, 0.7, 0.2, 0.25), true)
			draw_rect(Rect2(pos, sz), Color(0.9, 0.75, 0.25, 0.7), false, 2.0)
			# 标记文字
			var text_pos: Vector2 = Vector2(cell.x * CELL_SIZE + 8, cell.y * CELL_SIZE + 14)
			draw_string(font, text_pos, "HIGH", HORIZONTAL_ALIGNMENT_LEFT, CELL_SIZE - 16, font_size, Color(0.95, 0.85, 0.3, 0.8))
		elif terrain_type == "trap":
			# 陷阱：暗红填充 + 红色边框
			draw_rect(Rect2(pos, sz), Color(0.7, 0.15, 0.1, 0.3), true)
			draw_rect(Rect2(pos, sz), Color(0.85, 0.2, 0.15, 0.75), false, 2.0)
			# 标记文字
			var text_pos: Vector2 = Vector2(cell.x * CELL_SIZE + 8, cell.y * CELL_SIZE + 14)
			draw_string(font, text_pos, "TRAP", HORIZONTAL_ALIGNMENT_LEFT, CELL_SIZE - 16, font_size, Color(1.0, 0.35, 0.25, 0.8))

func _draw_attack_highlights() -> void:
	for cell in attack_highlight_cells:
		var pos: Vector2 = Vector2(cell.x * CELL_SIZE + 4, cell.y * CELL_SIZE + 4)
		var sz: Vector2 = Vector2(CELL_SIZE - 10, CELL_SIZE - 10)
		# Filled red highlight
		draw_rect(Rect2(pos, sz), Color(1.0, 0.2, 0.2, 0.25), true)
		# Border red highlight
		draw_rect(Rect2(pos, sz), Color(1.0, 0.25, 0.25, 0.75), false, 2.0)

func _draw_summon_highlights() -> void:
	for cell in summon_highlight_cells:
		var pos: Vector2 = Vector2(cell.x * CELL_SIZE + 4, cell.y * CELL_SIZE + 4)
		var sz: Vector2 = Vector2(CELL_SIZE - 10, CELL_SIZE - 10)
		# 紫色填充高亮
		draw_rect(Rect2(pos, sz), Color(0.7, 0.2, 1.0, 0.2), true)
		# 紫色边框高亮
		draw_rect(Rect2(pos, sz), Color(0.75, 0.3, 1.0, 0.7), false, 2.0)

func _draw_paths() -> void:
	if board_manager == null:
		return
	for cell in board_manager.path_cells.keys():
		var owner_id: String = String(board_manager.path_cells[cell])
		var fill_color: Color
		var border_color: Color
		if owner_id == "player":
			# 玩家路径：青色发光
			fill_color = Color(0.15, 0.85, 0.75, 0.18)
			border_color = Color(0.2, 0.95, 0.8, 0.6)
		else:
			# 其他路径：橙色
			fill_color = Color(1.0, 0.55, 0.2, 0.2)
			border_color = Color(1.0, 0.6, 0.25, 0.55)
		var path_pos: Vector2 = Vector2(cell.x * CELL_SIZE + 2, cell.y * CELL_SIZE + 2)
		var path_sz: Vector2 = Vector2(CELL_SIZE - 6, CELL_SIZE - 6)
		draw_rect(Rect2(path_pos, path_sz), fill_color, true)
		draw_rect(Rect2(path_pos, path_sz), border_color, false, 2.0)

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

func _draw_unit_hp() -> void:
	if unit_manager == null:
		return
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 11
	for cell in unit_manager.units_by_cell.keys():
		var uid: String = String(unit_manager.units_by_cell[cell])
		var unit: Dictionary = unit_manager.get_unit(uid)
		var hp: int = int(unit.get("hp", 0))
		var max_hp: int = int(unit.get("max_hp", 0))
		var hp_text: String = str(hp) + "/" + str(max_hp)
		var text_pos: Vector2 = Vector2(cell.x * CELL_SIZE + 14, cell.y * CELL_SIZE + CELL_SIZE - 8)
		draw_string(font, text_pos, hp_text, HORIZONTAL_ALIGNMENT_LEFT, CELL_SIZE - 28, font_size, Color(1.0, 1.0, 1.0, 0.95))

func _draw_selection_ring() -> void:
	if selected_unit_id == "" or unit_manager == null:
		return
	var unit: Dictionary = unit_manager.get_unit(selected_unit_id)
	if unit.is_empty():
		return
	var cell: Vector2i = unit["cell"]
	var ring_pos: Vector2 = Vector2(cell.x * CELL_SIZE + 6, cell.y * CELL_SIZE + 6)
	var ring_sz: Vector2 = Vector2(CELL_SIZE - 14, CELL_SIZE - 14)
	draw_rect(Rect2(ring_pos, ring_sz), Color(1.0, 0.85, 0.2, 0.85), false, 3.0)

func _draw_attack_flash() -> void:
	if _flash_alpha <= 0.0 or _flash_cell.x < 0:
		return
	var pos: Vector2 = Vector2(_flash_cell.x * CELL_SIZE, _flash_cell.y * CELL_SIZE)
	var sz: Vector2 = Vector2(CELL_SIZE - 2, CELL_SIZE - 2)
	draw_rect(Rect2(pos, sz), Color(1.0, 1.0, 1.0, _flash_alpha), true)

## Play attack feedback: white flash on cell + floating damage number
func play_attack_feedback(cell: Vector2i, damage: int) -> void:
	# White flash
	_flash_cell = cell
	_flash_alpha = 0.85
	var tw: Tween = create_tween()
	tw.tween_method(_set_flash_alpha, 0.85, 0.0, 0.35)
	tw.tween_callback(_clear_flash)
	# Floating damage number
	if _damage_label != null and is_instance_valid(_damage_label):
		_damage_label.queue_free()
	_damage_label = Label.new()
	_damage_label.text = "-" + str(damage)
	_damage_label.add_theme_font_size_override("font_size", 22)
	_damage_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.2))
	var start_x: float = cell.x * CELL_SIZE + 16
	var start_y: float = cell.y * CELL_SIZE + 10
	_damage_label.position = Vector2(start_x, start_y)
	_damage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_damage_label)
	var tw2: Tween = _damage_label.create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(_damage_label, "position:y", start_y - 40.0, 0.6)
	tw2.tween_property(_damage_label, "modulate:a", 0.0, 0.6)
	tw2.set_parallel(false)
	tw2.tween_callback(_damage_label.queue_free)

func _set_flash_alpha(val: float) -> void:
	_flash_alpha = val
	queue_redraw()

func _clear_flash() -> void:
	_flash_cell = Vector2i(-1, -1)
	_flash_alpha = 0.0
	queue_redraw()
