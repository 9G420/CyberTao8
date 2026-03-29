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
	# Block interaction if battle is over or encounter is active
	if battle_flow and (battle_flow.is_battle_over() or battle_flow.current_phase == battle_flow.BattlePhase.ENCOUNTER):
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
	_draw_encounters()
	_draw_heal_cells()
	_draw_event_cells()
	_draw_highlights()
	_draw_attack_highlights()
	_draw_summon_highlights()
	_draw_paths()
	_draw_items()
	_draw_units()
	_draw_unit_hp()
	_draw_unit_names()
	_draw_terrain_affinity_indicator()
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

## 绘制遭遇格：橙红警告色填充 + 边框 + "遭遇" 文字标记
func _draw_encounters() -> void:
	if board_manager == null:
		return
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 10
	for cell in board_manager.encounter_cells.keys():
		var pos: Vector2 = Vector2(cell.x * CELL_SIZE + 1, cell.y * CELL_SIZE + 1)
		var sz: Vector2 = Vector2(CELL_SIZE - 4, CELL_SIZE - 4)
		# 橙红警告色填充
		draw_rect(Rect2(pos, sz), Color(1.0, 0.35, 0.1, 0.35), true)
		# 橙红边框（脉冲感）
		draw_rect(Rect2(pos, sz), Color(1.0, 0.4, 0.15, 0.85), false, 2.5)
		# "遭遇" 文字标记
		var text_pos: Vector2 = Vector2(cell.x * CELL_SIZE + 14, cell.y * CELL_SIZE + CELL_SIZE / 2 + 4)
		draw_string(font, text_pos, "遭遇", HORIZONTAL_ALIGNMENT_LEFT, CELL_SIZE - 28, font_size, Color(1.0, 0.5, 0.2, 0.9))

## 绘制恢复格：蓝白色填充 + 边框 + "回复" 文字标记 + 回复量
func _draw_heal_cells() -> void:
	if board_manager == null:
		return
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 10
	for cell in board_manager.heal_cells.keys():
		var heal_amount: int = int(board_manager.heal_cells[cell])
		var pos: Vector2 = Vector2(cell.x * CELL_SIZE + 1, cell.y * CELL_SIZE + 1)
		var sz: Vector2 = Vector2(CELL_SIZE - 4, CELL_SIZE - 4)
		# 蓝白色填充
		draw_rect(Rect2(pos, sz), Color(0.3, 0.6, 1.0, 0.25), true)
		# 蓝白色边框
		draw_rect(Rect2(pos, sz), Color(0.4, 0.7, 1.0, 0.8), false, 2.0)
		# "回复" 文字标记
		var text_pos: Vector2 = Vector2(cell.x * CELL_SIZE + 8, cell.y * CELL_SIZE + 14)
		draw_string(font, text_pos, "回复", HORIZONTAL_ALIGNMENT_LEFT, CELL_SIZE - 16, font_size, Color(0.5, 0.8, 1.0, 0.9))
		# 回复量
		var amount_pos: Vector2 = Vector2(cell.x * CELL_SIZE + 14, cell.y * CELL_SIZE + CELL_SIZE / 2 + 4)
		draw_string(font, amount_pos, "+" + str(heal_amount), HORIZONTAL_ALIGNMENT_LEFT, CELL_SIZE - 28, font_size, Color(0.6, 0.9, 1.0, 0.85))

## 绘制事件格：黄紫色填充 + 边框 + "?" 标记
func _draw_event_cells() -> void:
	if board_manager == null:
		return
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 16
	for cell in board_manager.event_cells.keys():
		var pos: Vector2 = Vector2(cell.x * CELL_SIZE + 1, cell.y * CELL_SIZE + 1)
		var sz: Vector2 = Vector2(CELL_SIZE - 4, CELL_SIZE - 4)
		# 黄紫色填充
		draw_rect(Rect2(pos, sz), Color(0.8, 0.5, 1.0, 0.25), true)
		# 黄紫色边框
		draw_rect(Rect2(pos, sz), Color(0.85, 0.55, 1.0, 0.8), false, 2.0)
		# "?" 标记
		var text_pos: Vector2 = Vector2(cell.x * CELL_SIZE + CELL_SIZE / 2 - 6, cell.y * CELL_SIZE + CELL_SIZE / 2 + 6)
		draw_string(font, text_pos, "?", HORIZONTAL_ALIGNMENT_LEFT, 20, font_size, Color(0.95, 0.8, 0.3, 0.9))

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

## 绘制道具格：绿色菱形标记 + 道具名称缩写
func _draw_items() -> void:
	if board_manager == null:
		return
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 9
	var item_names: Dictionary = {
		"patch_tea_cache": "凉茶",
		"overclock_bone": "骨头",
		"glitch_snack_box": "零食",
	}
	for cell in board_manager.item_cells.keys():
		var item_id: String = String(board_manager.item_cells[cell])
		var pos: Vector2 = Vector2(cell.x * CELL_SIZE + 3, cell.y * CELL_SIZE + 3)
		var sz: Vector2 = Vector2(CELL_SIZE - 8, CELL_SIZE - 8)
		# 绿色填充 + 边框
		draw_rect(Rect2(pos, sz), Color(0.2, 0.85, 0.4, 0.25), true)
		draw_rect(Rect2(pos, sz), Color(0.25, 0.9, 0.45, 0.75), false, 2.0)
		# 道具名称
		var display: String = String(item_names.get(item_id, "?"))
		var text_pos: Vector2 = Vector2(cell.x * CELL_SIZE + 14, cell.y * CELL_SIZE + CELL_SIZE / 2 + 4)
		draw_string(font, text_pos, display, HORIZONTAL_ALIGNMENT_LEFT, CELL_SIZE - 28, font_size, Color(0.3, 1.0, 0.5, 0.9))

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

## 绘制单位名称缩写（区分不同单位）
func _draw_unit_names() -> void:
	if unit_manager == null:
		return
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 9
	for cell in unit_manager.units_by_cell.keys():
		var uid: String = String(unit_manager.units_by_cell[cell])
		var unit: Dictionary = unit_manager.get_unit(uid)
		var display_name: String = String(unit.get("display_name", ""))
		if display_name == "":
			continue
		# 取前两个字符作为缩写
		var short_name: String = display_name.substr(0, 2)
		var text_pos: Vector2 = Vector2(cell.x * CELL_SIZE + 14, cell.y * CELL_SIZE + 22)
		var name_color: Color = Color(0.9, 0.95, 1.0, 0.85) if String(unit.get("owner", "")) == "player" else Color(1.0, 0.85, 0.8, 0.85)
		draw_string(font, text_pos, short_name, HORIZONTAL_ALIGNMENT_LEFT, CELL_SIZE - 28, font_size, name_color)

## 绘制地形适性激活指示器（单位站在匹配地形上时显示 ★）
func _draw_terrain_affinity_indicator() -> void:
	if unit_manager == null or board_manager == null:
		return
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 12
	for cell in unit_manager.units_by_cell.keys():
		var uid: String = String(unit_manager.units_by_cell[cell])
		var unit: Dictionary = unit_manager.get_unit(uid)
		var affinity: String = String(unit.get("terrain_affinity", ""))
		if affinity == "":
			continue
		var active: bool = false
		if affinity == "high_ground" and board_manager.get_terrain_type(cell) == "high_ground":
			active = true
		elif affinity == "path" and board_manager.path_cells.has(cell):
			active = true
		elif affinity == "trap" and board_manager.get_terrain_type(cell) == "trap":
			active = true
		if active:
			var star_pos: Vector2 = Vector2(cell.x * CELL_SIZE + CELL_SIZE - 18, cell.y * CELL_SIZE + 14)
			draw_string(font, star_pos, "*", HORIZONTAL_ALIGNMENT_LEFT, 14, font_size, Color(1.0, 0.95, 0.3, 0.95))

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

## Play item pickup feedback: green floating text showing effect
func play_pickup_feedback(cell: Vector2i, effect_text: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = effect_text
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	var start_x: float = cell.x * CELL_SIZE + 10
	var start_y: float = cell.y * CELL_SIZE + 8
	lbl.position = Vector2(start_x, start_y)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw: Tween = lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", start_y - 36.0, 0.7)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw.set_parallel(false)
	tw.tween_callback(lbl.queue_free)

## 敌方攻击预警：在目标格显示橙色闪烁，提示即将受到攻击
func play_enemy_warning(cell: Vector2i) -> void:
	_flash_cell = cell
	_flash_alpha = 0.6
	var tw: Tween = create_tween()
	tw.tween_method(_set_flash_alpha, 0.6, 0.15, 0.4)
	tw.tween_method(_set_flash_alpha, 0.15, 0.5, 0.2)

## 敌方移动意图：在目标格短暂显示橙色边框提示
func play_enemy_move_indicator(cell: Vector2i, unit_name: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = unit_name
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	var start_x: float = cell.x * CELL_SIZE + 8
	var start_y: float = cell.y * CELL_SIZE - 4
	lbl.position = Vector2(start_x, start_y)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw: Tween = lbl.create_tween()
	tw.tween_property(lbl, "modulate:a", 0.0, 0.8)
	tw.tween_callback(lbl.queue_free)

func _set_flash_alpha(val: float) -> void:
	_flash_alpha = val
	queue_redraw()

func _clear_flash() -> void:
	_flash_cell = Vector2i(-1, -1)
	_flash_alpha = 0.0
	queue_redraw()

## 遭遇触发反馈：在遭遇格显示橙红色飘字
func play_encounter_feedback(cell: Vector2i, text: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.15))
	var start_x: float = cell.x * CELL_SIZE + 6
	var start_y: float = cell.y * CELL_SIZE + 6
	lbl.position = Vector2(start_x, start_y)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw: Tween = lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", start_y - 44.0, 0.9)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.9)
	tw.set_parallel(false)
	tw.tween_callback(lbl.queue_free)

## 恢复格反馈：蓝色飘字显示回复量
func play_heal_feedback(cell: Vector2i, text: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	var start_x: float = cell.x * CELL_SIZE + 10
	var start_y: float = cell.y * CELL_SIZE + 8
	lbl.position = Vector2(start_x, start_y)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw2: Tween = lbl.create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(lbl, "position:y", start_y - 36.0, 0.7)
	tw2.tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw2.set_parallel(false)
	tw2.tween_callback(lbl.queue_free)

## 事件格反馈：黄紫色飘字显示效果
func play_event_feedback(cell: Vector2i, text: String, is_positive: bool) -> void:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 18)
	var color: Color = Color(0.9, 0.8, 0.3) if is_positive else Color(1.0, 0.35, 0.25)
	lbl.add_theme_color_override("font_color", color)
	var start_x: float = cell.x * CELL_SIZE + 10
	var start_y: float = cell.y * CELL_SIZE + 8
	lbl.position = Vector2(start_x, start_y)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw3: Tween = lbl.create_tween()
	tw3.set_parallel(true)
	tw3.tween_property(lbl, "position:y", start_y - 36.0, 0.7)
	tw3.tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw3.set_parallel(false)
	tw3.tween_callback(lbl.queue_free)
