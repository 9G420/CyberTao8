extends Control
class_name BoardView

signal unit_selected(unit_id: String)
signal unit_deselected
signal move_requested(unit_id: String, target_cell: Vector2i)
signal attack_requested(unit_id: String, target_cell: Vector2i)
signal summon_requested(unit_id: String, target_cell: Vector2i)

const CELL_SIZE: int = 72

# --- 相机跟随（v0.1.63：拖�?平滑+缩放�?--
var board_manager: Node = null
var unit_manager: Node = null
var battle_flow: Node = null
var _enemy_intents: Dictionary = {}

var camera_cell: Vector2i = Vector2i(0, 0)
var iso_origin: Vector2 = Vector2(640.0, 392.0)
var _iso_origin_target: Vector2 = Vector2(640.0, 392.0)
const SCREEN_CENTER: Vector2 = Vector2(640.0, 392.0)
const CAMERA_LERP_SPEED: float = 4.5	# 平滑跟随速度（v0.1.65：降低以获得更柔和的过渡�?

# 缩放（v0.1.63�?
var _zoom: float = 1.0
const ZOOM_MIN: float = 0.4
const ZOOM_MAX: float = 1.6
const ZOOM_STEP: float = 0.1

# 鼠标拖拽平移
var _drag_active: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_start_origin: Vector2 = Vector2.ZERO
var _drag_offset: Vector2 = Vector2.ZERO	# 用户拖拽累积偏移

# v0.1.95�?D 中键视角调节（伪镜头俯仰�?
var _orbit_active: bool = false
var _orbit_start_pos: Vector2 = Vector2.ZERO
var _orbit_start_zoom: float = 1.0
var _view_pitch_offset: float = 0.0
var _view_yaw_offset: float = 0.0
var _orbit_start_pitch: float = 0.0
var _orbit_start_yaw: float = 0.0

# Selection state
var selected_unit_id: String = ""
var highlight_cells: Array[Vector2i] = []
var attack_highlight_cells: Array[Vector2i] = []
var summon_highlight_cells: Array[Vector2i] = []

# Attack feedback state
var _flash_cell: Vector2i = Vector2i(-1, -1)
var _flash_alpha: float = 0.0

# Hover highlight（v0.1.62�?
var _hover_cell: Vector2i = Vector2i(-1, -1)

# v0.1.67：逐格移动动画
var _move_anim_unit: String = ""
var _move_anim_from_cell: Vector2i = Vector2i(-1, -1)
var _move_anim_to_cell: Vector2i = Vector2i(-1, -1)
var _move_anim_t: float = 1.0
var _move_tween: Tween = null
signal move_anim_done

# v0.1.82：精灵动画器已移除（全程序化渲染，无外部美术资源�?

# Animation pulse (20fps refresh via Timer)
var _anim_timer: Timer = null
var _last_redraw_ms: int = 0

# Item display name mapping
var _item_names: Dictionary = {
	"patch_tea_cache": "凉茶",
	"overclock_bone": "骨头",
	"glitch_snack_box": "零食",
}

func _ready() -> void:
	size = Vector2(1280, 720)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	# 初始相机位置
	_view_pitch_offset = 0.0
	_view_yaw_offset = 0.0
	_iso_origin_target = IsoTileRenderer.calc_origin_for_cell_zoom(camera_cell, SCREEN_CENTER, _zoom)
	iso_origin = _iso_origin_target
	# 动画刷新定时器（50ms=20fps，驱动呼�?脉冲效果�?
	_anim_timer = Timer.new()
	_anim_timer.wait_time = 0.05
	_anim_timer.autostart = true
	_anim_timer.timeout.connect(_on_anim_tick)
	add_child(_anim_timer)
	# v0.1.82：精灵动画器已移除（全程序化渲染�?

func _on_anim_tick() -> void:
	# v0.1.101：选中单位时持续跟随中心，避免棋盘偏到角落
	if not _drag_active and selected_unit_id != "" and unit_manager != null:
		var su: Dictionary = unit_manager.get_unit(selected_unit_id)
		if not su.is_empty():
			camera_cell = su["cell"]
			_iso_origin_target = IsoTileRenderer.calc_origin_for_cell_zoom(camera_cell, SCREEN_CENTER, _zoom)
	if not _drag_active:
		var target: Vector2 = _iso_origin_target + _drag_offset
		var diff: Vector2 = target - iso_origin
		if diff.length() > 0.5:
			iso_origin = iso_origin.lerp(target, clampf(CAMERA_LERP_SPEED * 0.05, 0.0, 1.0))
		else:
			iso_origin = target
	queue_redraw()

## 设置相机跟随目标格子（v0.1.63：平滑过�?缩放�?
func set_camera_target(cell: Vector2i) -> void:
	camera_cell = cell
	_iso_origin_target = IsoTileRenderer.calc_origin_for_cell_zoom(camera_cell, SCREEN_CENTER, _zoom)
	queue_redraw()

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
	if battle_flow and battle_flow.has_signal("enemy_intents_updated") and not battle_flow.enemy_intents_updated.is_connected(_on_enemy_intents_updated):
		battle_flow.enemy_intents_updated.connect(_on_enemy_intents_updated)
	if battle_flow and battle_flow.has_method("get_enemy_intents"):
		_enemy_intents = battle_flow.get_enemy_intents()
	else:
		_enemy_intents.clear()
	queue_redraw()

func _on_enemy_intents_updated(intents: Dictionary) -> void:
	_enemy_intents = intents.duplicate(true)
	queue_redraw()

func _on_phase_changed(_phase_name: String) -> void:
	if selected_unit_id != "":
		_deselect()

func _on_state_changed() -> void:
	if selected_unit_id != "" and battle_flow:
		if unit_manager and unit_manager.get_unit(selected_unit_id).is_empty():
			_deselect()
			return
		highlight_cells = battle_flow.get_reachable_cells_for(selected_unit_id)
		attack_highlight_cells = battle_flow.get_attackable_cells_for(selected_unit_id)
		summon_highlight_cells = _filter_summon_cells(battle_flow.get_summon_cells_for(selected_unit_id))
	queue_redraw()

# --- 点击/拖拽/缩放交互逻辑（v0.1.63�?--

func _gui_input(event: InputEvent) -> void:
	# 鼠标滚轮缩放
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_apply_zoom(ZOOM_STEP, mb.position)
			accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_apply_zoom(-ZOOM_STEP, mb.position)
			accept_event()
			return
	# 右键拖拽平移（v0.1.100：禁用2D伪视角，回归稳定构图）
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_drag_active = true
				_drag_start_pos = mb.position
				_drag_start_origin = iso_origin
			else:
				_drag_active = false
				_drag_offset = iso_origin - _iso_origin_target
			accept_event()
			return
	if event is InputEventMouseMotion and _drag_active:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		iso_origin = _drag_start_origin + (mm.position - _drag_start_pos)
		queue_redraw()
		accept_event()
		return
	# 悬停高亮
	if event is InputEventMouseMotion and not _drag_active:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		var hcell: Vector2i = _pixel_to_cell(mm.position)
		if _is_valid_cell(hcell):
			if _hover_cell != hcell:
				_hover_cell = hcell
				queue_redraw()
		elif _hover_cell.x >= 0:
			_hover_cell = Vector2i(-1, -1)
			queue_redraw()
		return
	# 左键点击选择/移动
	if not event is InputEventMouseButton:
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	var cell: Vector2i = _pixel_to_cell(mb.position)
	if not _is_valid_cell(cell):
		_recenter_to_board_center()
		_deselect()
		return
	_handle_cell_click(cell)
	accept_event()

func _pixel_to_cell(pixel_pos: Vector2) -> Vector2i:
	return IsoTileRenderer.screen_to_grid_zoom(pixel_pos, iso_origin, _zoom)

func _is_valid_cell(cell: Vector2i) -> bool:
	if board_manager != null:
		return board_manager.is_in_bounds(cell)
	return cell.x >= 0 and cell.y >= 0 and cell.x < 12 and cell.y < 12

func _recenter_to_board_center() -> void:
	_drag_active = false
	_drag_offset = Vector2.ZERO
	var center_cell: Vector2i = Vector2i(6, 6)
	if board_manager != null and board_manager.board_size != Vector2i.ZERO:
		center_cell = Vector2i(board_manager.board_size.x / 2, board_manager.board_size.y / 2)
	set_camera_target(center_cell)

## 缩放（以鼠标位置为中心）
func _apply_zoom(delta: float, mouse_pos: Vector2) -> void:
	var old_zoom: float = _zoom
	_zoom = clampf(_zoom + delta, ZOOM_MIN, ZOOM_MAX)
	if _zoom == old_zoom:
		return
	# 保持鼠标指向的世界位置不�?
	var ratio: float = _zoom / old_zoom
	iso_origin = mouse_pos + (iso_origin - mouse_pos) * ratio
	_iso_origin_target = IsoTileRenderer.calc_origin_for_cell_zoom(camera_cell, SCREEN_CENTER, _zoom)
	_drag_offset = iso_origin - _iso_origin_target
	queue_redraw()

func _handle_cell_click(cell: Vector2i) -> void:
	if battle_flow and (battle_flow.is_battle_over() or battle_flow.current_phase == battle_flow.BattlePhase.ENCOUNTER):
		return
	if selected_unit_id != "":
		var is_attack_target: bool = false
		for ac in attack_highlight_cells:
			if ac == cell:
				is_attack_target = true
				break
		if is_attack_target:
			emit_signal("attack_requested", selected_unit_id, cell)
			return
		var is_move_target: bool = false
		for hc in highlight_cells:
			if hc == cell:
				is_move_target = true
				break
		if is_move_target:
			emit_signal("move_requested", selected_unit_id, cell)
			return
		var is_summon_target: bool = false
		for sc in summon_highlight_cells:
			if sc == cell:
				is_summon_target = true
				break
		if is_summon_target:
			emit_signal("summon_requested", selected_unit_id, cell)
			return
		if unit_manager and unit_manager.units_by_cell.has(cell):
			var clicked_id: String = String(unit_manager.units_by_cell[cell])
			if clicked_id == selected_unit_id:
				_deselect()
				return
			var clicked_unit: Dictionary = unit_manager.get_unit(clicked_id)
			if _is_selectable_player_unit(clicked_id, clicked_unit):
				_select_unit(clicked_id)
				return
		_deselect()
		return
	if unit_manager and unit_manager.units_by_cell.has(cell):
		var clicked_id: String = String(unit_manager.units_by_cell[cell])
		var clicked_unit: Dictionary = unit_manager.get_unit(clicked_id)
		if _is_selectable_player_unit(clicked_id, clicked_unit):
			_select_unit(clicked_id)

func _select_unit(unit_id: String) -> void:
	selected_unit_id = unit_id
	if battle_flow:
		highlight_cells = battle_flow.get_reachable_cells_for(unit_id)
		attack_highlight_cells = battle_flow.get_attackable_cells_for(unit_id)
		summon_highlight_cells = _filter_summon_cells(battle_flow.get_summon_cells_for(unit_id))
	else:
		highlight_cells.clear()
		attack_highlight_cells.clear()
		summon_highlight_cells.clear()
	# v0.1.64：选中单位时立即将相机居中到该单位
	if unit_manager:
		var unit: Dictionary = unit_manager.get_unit(unit_id)
		if not unit.is_empty():
			var cell: Vector2i = unit["cell"]
			_drag_offset = Vector2.ZERO
			set_camera_target(cell)
	emit_signal("unit_selected", unit_id)
	queue_redraw()

func _deselect() -> void:
	selected_unit_id = ""
	highlight_cells.clear()
	attack_highlight_cells.clear()
	summon_highlight_cells.clear()
	emit_signal("unit_deselected")
	queue_redraw()

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

func _is_selectable_player_unit(unit_id: String, unit: Dictionary) -> bool:
	if unit_manager and unit_manager.has_method("is_player_hero_unit"):
		return bool(unit_manager.is_player_hero_unit(unit_id))
	if unit.is_empty():
		return false
	if String(unit.get("owner", "")) != "player":
		return false
	var tags: Array = unit.get("tags", [])
	return not tags.has("summoned")

# --- v0.1.67：逐格移动动画 ---

func play_move_step(unit_id: String, from_cell: Vector2i, to_cell: Vector2i, duration: float = 0.15) -> void:
	if _move_tween and _move_tween.is_running():
		_move_tween.kill()
	_move_anim_unit = unit_id
	_move_anim_from_cell = from_cell
	_move_anim_to_cell = to_cell
	_move_anim_t = 0.0
	_move_tween = create_tween()
	_move_tween.tween_method(_set_move_anim_t, 0.0, 1.0, duration)
	_move_tween.tween_callback(_on_move_step_finished)

func _set_move_anim_t(t: float) -> void:
	_move_anim_t = t
	queue_redraw()

func _on_move_step_finished() -> void:
	_move_anim_unit = ""
	_move_anim_t = 1.0
	queue_redraw()
	emit_signal("move_anim_done")

# --- 辅助 ---

func _cell_rect(cell: Vector2i, margin: int) -> Rect2:
	return Rect2(Vector2(cell.x * CELL_SIZE + margin, cell.y * CELL_SIZE + margin), Vector2(CELL_SIZE - margin * 2, CELL_SIZE - margin * 2))

func _iso_cell_center(cell: Vector2i) -> Vector2:
	return IsoTileRenderer.grid_to_screen_zoom(cell.x, cell.y, iso_origin, _zoom)

# ===========================================================
#  绘制层（v0.1.62：悬停高�?拖拽相机�?
# ===========================================================

func _draw() -> void:
	var pulse: float = sin(Time.get_ticks_msec() * 0.003) * 0.5 + 0.5
	var font: Font = ThemeDB.fallback_font
	_draw_layer_grid(pulse)
	_draw_layer_overlays(pulse, font)
	_draw_layer_hover(pulse)
	_draw_layer_highlights(pulse)
	_draw_layer_enemy_intents(pulse, font)
	_draw_layer_units(pulse, font)
	_draw_attack_flash()
	_draw_edge_vignette()

# Layer 1: 等距程序化菱形网格（含环境填充）
func _draw_layer_grid(pulse: float) -> void:
	# v0.1.98：先铺底色，避免棋盘外出现纯�?
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.04, 0.06, 0.09, 0.96), true)
	IsoTileRenderer.draw_board(self, iso_origin, board_manager, pulse, _zoom)

# Layer 2: 叠层符号（高起贴图已区分格类型，此层仅补充文�?特殊标记�?
func _draw_layer_overlays(pulse: float, font: Font) -> void:
	if board_manager == null:
		return
	# Boss / Boss锁定 标记（encounter 贴图无法区分 boss 与普通）
	for cell in board_manager.encounter_cells.keys():
		var enc_id: String = String(board_manager.encounter_cells[cell])
		var is_boss: bool = enc_id.begins_with("encounter_boss_")
		if not is_boss:
			continue
		var center: Vector2 = _iso_cell_center(cell)
		if board_manager.is_encounter_locked(cell):
			_draw_iso_label(center - Vector2(0, 16), "LOCKED", Color(0.6, 0.3, 0.3, 0.7 + pulse * 0.2), font, 14)
		else:
			_draw_iso_label(center - Vector2(0, 16), "BOSS", Color(CyberStyle.NEON_RED.r, CyberStyle.NEON_RED.g, CyberStyle.NEON_RED.b, 0.9 + pulse * 0.1), font, 16)
	# 回复量文�?
	for cell in board_manager.heal_cells.keys():
		var center: Vector2 = _iso_cell_center(cell)
		var amt: String = "+" + str(int(board_manager.heal_cells[cell]))
		_draw_iso_label(center + Vector2(0, 8), amt, Color(CyberStyle.NEON_BLUE.r, CyberStyle.NEON_BLUE.g, CyberStyle.NEON_BLUE.b, 0.85), font, 14)
	# 商店费用文字
	for cell in board_manager.shop_cells.keys():
		var center: Vector2 = _iso_cell_center(cell)
		var heal_amount: int = int(board_manager.shop_cells[cell])
		_draw_iso_label(center + Vector2(0, 8), "HP+" + str(heal_amount), Color(CyberStyle.NEON_TEAL.r, CyberStyle.NEON_TEAL.g, CyberStyle.NEON_TEAL.b, 0.75), font, 13)
	# 道具名称文字
	for cell in board_manager.item_cells.keys():
		var item_id: String = String(board_manager.item_cells[cell])
		var display: String = String(_item_names.get(item_id, "?"))
		var center: Vector2 = _iso_cell_center(cell)
		_draw_iso_label(center + Vector2(0, 8), display, Color(CyberStyle.NEON_GREEN.r, CyberStyle.NEON_GREEN.g, CyberStyle.NEON_GREEN.b, 0.8), font, 14)
	# 路径格叠�?
	for cell in board_manager.path_cells.keys():
		var owner_id: String = String(board_manager.path_cells[cell])
		var col: Color = CyberStyle.ACCENT_CYAN if owner_id == "player" else CyberStyle.ACCENT_ORANGE
		var center: Vector2 = _iso_cell_center(cell)
		IsoTileRenderer.draw_diamond_highlight(self, center, Color(col.r, col.g, col.b, 0.12 + pulse * 0.06), Color(col.r, col.g, col.b, 0.3 + pulse * 0.15), 8.0, _zoom)
	for cell in board_manager.control_nodes.keys():
		var center2: Vector2 = _iso_cell_center(cell)
		var owner2: String = board_manager.get_control_node_owner(cell)
		var node_type: String = board_manager.get_control_node_type(cell)
		var tag_text: String = "NEU"
		var col2: Color = Color(0.85, 0.85, 0.9, 0.8)
		if owner2 == "player":
			tag_text = "P"
			col2 = Color(CyberStyle.ACCENT_CYAN.r, CyberStyle.ACCENT_CYAN.g, CyberStyle.ACCENT_CYAN.b, 0.95)
		elif owner2 == "enemy":
			tag_text = "E"
			col2 = Color(CyberStyle.ACCENT_ORANGE.r, CyberStyle.ACCENT_ORANGE.g, CyberStyle.ACCENT_ORANGE.b, 0.95)
		var node_mark: String = "N"
		if node_type == "energy":
			node_mark = "EN"
		elif node_type == "command":
			node_mark = "CM"
		elif node_type == "repulse":
			node_mark = "RP"
		_draw_iso_label(center2 - Vector2(0, 14), node_mark + ":" + tag_text, col2, font, 12)

## 在菱形中心绘制居中文字（缩放感知�?
func _draw_iso_label(center: Vector2, text: String, col: Color, font: Font, font_size: int) -> void:
	var fs: int = int(float(font_size) * _zoom)
	var text_w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, Vector2(center.x - text_w * 0.5, center.y + float(fs) * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

# Layer 2.5: 悬停高亮
func _draw_layer_hover(pulse: float) -> void:
	if _hover_cell.x < 0:
		return
	var center: Vector2 = _iso_cell_center(_hover_cell)
	var col: Color = Color(1.0, 1.0, 1.0, 0.08 + pulse * 0.04)
	var border_col: Color = Color(1.0, 1.0, 1.0, 0.2 + pulse * 0.1)
	IsoTileRenderer.draw_diamond_highlight(self, center, col, border_col, 4.0, _zoom)

# Layer 3: 高亮系统（菱形）
func _draw_layer_highlights(pulse: float) -> void:
	for cell in highlight_cells:
		var center: Vector2 = _iso_cell_center(cell)
		var col: Color = CyberStyle.ACCENT_CYAN
		IsoTileRenderer.draw_diamond_corners(self, center, Color(col.r, col.g, col.b, 0.55 + pulse * 0.3), 8.0, _zoom)
		IsoTileRenderer.draw_diamond_highlight(self, center, Color(col.r, col.g, col.b, 0.06 + pulse * 0.04), Color(0, 0, 0, 0), 0.0, _zoom)
	for cell in attack_highlight_cells:
		var center: Vector2 = _iso_cell_center(cell)
		var col: Color = CyberStyle.NEON_RED
		IsoTileRenderer.draw_diamond_highlight(self, center, Color(col.r, col.g, col.b, 0.15 + pulse * 0.15), Color(col.r, col.g, col.b, 0.35 + pulse * 0.3), 0.0, _zoom)
	for cell in summon_highlight_cells:
		var center: Vector2 = _iso_cell_center(cell)
		var col: Color = CyberStyle.ACCENT_MAGENTA
		IsoTileRenderer.draw_diamond_highlight(self, center, Color(col.r, col.g, col.b, 0.1 + pulse * 0.08), Color(col.r, col.g, col.b, 0.5 + pulse * 0.3), 0.0, _zoom)

func _draw_layer_enemy_intents(pulse: float, font: Font) -> void:
	if _enemy_intents.is_empty():
		return
	for uid in _enemy_intents.keys():
		var intent: Dictionary = _enemy_intents.get(uid, {})
		if intent.is_empty():
			continue
		var action: String = String(intent.get("action", "wait"))
		if action == "wait":
			continue
		var from_var: Variant = intent.get("from_cell", Vector2i(-1, -1))
		var to_var: Variant = intent.get("to_cell", Vector2i(-1, -1))
		if not (from_var is Vector2i) or not (to_var is Vector2i):
			continue
		var from_cell: Vector2i = from_var as Vector2i
		var to_cell: Vector2i = to_var as Vector2i
		if from_cell.x < 0 or to_cell.x < 0:
			continue
		var line_col: Color = Color(CyberStyle.ACCENT_ORANGE.r, CyberStyle.ACCENT_ORANGE.g, CyberStyle.ACCENT_ORANGE.b, 0.85)
		var ring_col: Color = Color(CyberStyle.ACCENT_ORANGE.r, CyberStyle.ACCENT_ORANGE.g, CyberStyle.ACCENT_ORANGE.b, 0.95)
		var tag: String = "MOV"
		if action == "attack":
			line_col = Color(CyberStyle.NEON_RED.r, CyberStyle.NEON_RED.g, CyberStyle.NEON_RED.b, 0.88)
			ring_col = Color(CyberStyle.NEON_RED.r, CyberStyle.NEON_RED.g, CyberStyle.NEON_RED.b, 0.95)
			tag = "ATK"
		var from_center: Vector2 = _iso_cell_center(from_cell) + Vector2(0.0, -22.0 * _zoom)
		var to_center: Vector2 = _iso_cell_center(to_cell) + Vector2(0.0, -22.0 * _zoom)
		var line_w: float = max(2.0, 2.0 * _zoom)
		draw_line(from_center, to_center, line_col, line_w)
		var radius: float = max(7.0, 7.0 * _zoom + pulse * 1.4)
		draw_circle(to_center, radius, Color(ring_col.r, ring_col.g, ring_col.b, 0.24))
		draw_arc(to_center, radius, 0.0, TAU, 24, ring_col, max(1.0, 1.4 * _zoom), true)
		var fs: int = int(12.0 * _zoom)
		var text_w: float = font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, to_center + Vector2(-text_w * 0.5, -10.0 * _zoom), tag, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, Color(1.0, 0.98, 0.92, 0.95))

# Layer 4: 单位层（�?depth 排序保证遮挡正确�?
func _draw_layer_units(pulse: float, font: Font) -> void:
	if unit_manager == null:
		return
	var cells: Array = unit_manager.units_by_cell.keys()
	cells.sort_custom(func(a, b): return (a.x + a.y) < (b.x + b.y))
	for cell in cells:
		var uid: String = String(unit_manager.units_by_cell[cell])
		var unit: Dictionary = unit_manager.get_unit(uid)
		var is_sel: bool = uid == selected_unit_id
		var idle_y: float = sin(Time.get_ticks_msec() * 0.004) * 2.0 if is_sel else 0.0
		var center: Vector2
		if uid == _move_anim_unit and _move_anim_t < 1.0:
			var from_pos: Vector2 = _iso_cell_center(_move_anim_from_cell)
			var to_pos: Vector2 = _iso_cell_center(_move_anim_to_cell)
			center = from_pos.lerp(to_pos, _move_anim_t)
		else:
			center = _iso_cell_center(cell)
		# v0.1.82：全程序化渲染（移除 spritesheet 分支�?
		UnitRenderer.draw_full_unit_iso(self, center, unit, is_sel, pulse, idle_y, font)
		if board_manager:
			UnitRenderer.draw_affinity_star_iso(self, center, unit, board_manager, cell, font)

# Layer 5: 攻击闪光（菱形）
func _draw_attack_flash() -> void:
	if _flash_alpha <= 0.0 or _flash_cell.x < 0:
		return
	var center: Vector2 = _iso_cell_center(_flash_cell)
	IsoTileRenderer.draw_diamond_highlight(self, center, Color(1.0, 1.0, 1.0, _flash_alpha), Color(0, 0, 0, 0), 4.0, _zoom)

func _draw_tactical_hud(font: Font, pulse: float) -> void:
	var top_strip: Rect2 = Rect2(0, 0, 1280, 88)
	var bottom_strip: Rect2 = Rect2(0, 628, 1280, 92)
	draw_rect(top_strip, Color(0.01, 0.03, 0.06, 0.66), true)
	draw_rect(bottom_strip, Color(0.01, 0.03, 0.06, 0.72), true)
	draw_line(Vector2(0, 88), Vector2(1280, 88), Color(CyberStyle.ACCENT_CYAN.r, CyberStyle.ACCENT_CYAN.g, CyberStyle.ACCENT_CYAN.b, 0.42), 1.0)
	draw_line(Vector2(0, 628), Vector2(1280, 628), Color(CyberStyle.ACCENT_CYAN.r, CyberStyle.ACCENT_CYAN.g, CyberStyle.ACCENT_CYAN.b, 0.42), 1.0)

	var panel_alpha: float = 0.14 + pulse * 0.06
	var panel_border_alpha: float = 0.55 + pulse * 0.2
	var panel_fill: Color = Color(CyberStyle.BG_PANEL.r, CyberStyle.BG_PANEL.g, CyberStyle.BG_PANEL.b, panel_alpha)
	var panel_border: Color = Color(CyberStyle.ACCENT_CYAN.r, CyberStyle.ACCENT_CYAN.g, CyberStyle.ACCENT_CYAN.b, panel_border_alpha)
	var text_main: Color = Color(0.9, 0.96, 1.0, 0.95)
	var text_sub: Color = Color(0.62, 0.82, 0.95, 0.92)

	var cmd_rect: Rect2 = Rect2(24, 16, 360, 58)
	_draw_hud_panel(cmd_rect, panel_fill, panel_border)
	_draw_string_line(font, cmd_rect.position + Vector2(14, 23), "部署战斗单位", 24, text_main)
	_draw_string_line(font, cmd_rect.position + Vector2(14, 46), "目标：占领据点并压制敌方核心", 14, text_sub)

	var phase_rect: Rect2 = Rect2(910, 14, 344, 64)
	_draw_hud_panel(phase_rect, panel_fill, panel_border)
	var phase_text: String = _get_phase_text()
	var floor_text: String = "层数 " + str(int(battle_flow.get_current_floor()) if battle_flow and battle_flow.has_method("get_current_floor") else 1)
	var round_text: String = "回合 " + str(int(battle_flow.round_index) if battle_flow else 1)
	_draw_string_line(font, phase_rect.position + Vector2(14, 22), phase_text + "  |  " + floor_text + " / " + round_text, 17, text_main)
	_draw_string_line(font, phase_rect.position + Vector2(14, 46), "当前目标：控制更多据点并清空敌方单位", 14, text_sub)

	var node_rect: Rect2 = Rect2(910, 82, 344, 38)
	_draw_hud_panel(node_rect, Color(panel_fill.r, panel_fill.g, panel_fill.b, panel_fill.a * 0.88), panel_border)
	_draw_string_line(font, node_rect.position + Vector2(14, 25), _get_control_node_state(), 14, Color(0.88, 0.94, 1.0, 0.9))

	var unit_rect: Rect2 = Rect2(26, 642, 510, 62)
	_draw_hud_panel(unit_rect, panel_fill, panel_border)
	_draw_string_line(font, unit_rect.position + Vector2(14, 24), _get_selected_unit_stat_line(), 15, text_main)
	_draw_string_line(font, unit_rect.position + Vector2(14, 48), _get_crest_line(), 14, text_sub)

	var tips_rect: Rect2 = Rect2(910, 642, 344, 62)
	_draw_hud_panel(tips_rect, panel_fill, panel_border)
	_draw_string_line(font, tips_rect.position + Vector2(14, 24), "战场提示：先占资源点，再压前线。", 14, text_main)
	_draw_string_line(font, tips_rect.position + Vector2(14, 48), "召唤物用于控点/护卫，不要单走送掉。", 14, text_sub)

func _draw_hud_panel(rect: Rect2, fill_col: Color, border_col: Color) -> void:
	draw_rect(rect, fill_col, true)
	draw_rect(rect, border_col, false, 1.0)

func _draw_string_line(font: Font, pos: Vector2, text: String, size: int, col: Color) -> void:
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, col)

func _get_phase_text() -> String:
	if battle_flow == null:
		return "阶段：准备"
	var phase_name: String = "UNKNOWN"
	if battle_flow.has_method("_phase_name"):
		phase_name = String(battle_flow._phase_name(battle_flow.current_phase))
	match phase_name:
		"PLAYER_ROLL":
			return "阶段：玩家掷骰"
		"PLAYER_ACTION":
			return "阶段：玩家行动"
		"ENCOUNTER":
			return "阶段：遭遇战"
		"ENEMY_ROLL":
			return "阶段：敌方掷骰"
		"ENEMY_ACTION":
			return "阶段：敌方行动"
		"FLOOR_CLEAR":
			return "阶段：本层完成"
		"VICTORY":
			return "阶段：战斗胜利"
		"DEFEAT":
			return "阶段：战斗失败"
	return "阶段：战场处理中"

func _get_control_node_state() -> String:
	if board_manager == null or not board_manager.has_method("get_control_node_owner"):
		return "据点占领：暂无数据"
	var player_count: int = 0
	var enemy_count: int = 0
	var neutral_count: int = 0
	for cell in board_manager.control_nodes.keys():
		var owner: String = String(board_manager.get_control_node_owner(cell))
		if owner == "player":
			player_count += 1
		elif owner == "enemy":
			enemy_count += 1
		else:
			neutral_count += 1
	return "据点占领  我方 " + str(player_count) + "  敌方 " + str(enemy_count) + "  中立 " + str(neutral_count)

func _get_selected_unit_stat_line() -> String:
	if selected_unit_id == "" or unit_manager == null:
		return "未选中单位：点击我方主角单位查看行动详情"
	var unit: Dictionary = unit_manager.get_unit(selected_unit_id)
	if unit.is_empty():
		return "未选中单位：点击我方主角单位查看行动详情"
	var name: String = String(unit.get("display_name", selected_unit_id))
	var hp: int = int(unit.get("hp", 0))
	var max_hp: int = int(unit.get("max_hp", 1))
	var atk: int = int(unit.get("atk", 0))
	var defv: int = int(unit.get("def", 0))
	var move_range: int = int(unit.get("move_range", 1))
	var attack_range: int = int(unit.get("attack_range", 1))
	var tags: Array = unit.get("tags", [])
	var role: String = "主角"
	if tags.has("summoned"):
		role = "召唤物"
	return "%s[%s]  HP %d/%d  ATK %d  DEF %d  移动 %d  攻击距 %d" % [name, role, hp, max_hp, atk, defv, move_range, attack_range]

func _get_crest_line() -> String:
	if battle_flow == null:
		return "资源：读取中"
	var dm: Object = battle_flow.dice_manager
	if dm == null:
		return "资源：读取中"
	var pool: Dictionary = dm.crest_pool
	return "资源  显:%d  步:%d  杀:%d  护:%d  术:%d  巧:%d" % [
		int(pool.get("summon", 0)),
		int(pool.get("move", 0)),
		int(pool.get("attack", 0)),
		int(pool.get("defend", 0)),
		int(pool.get("skill", 0)),
		int(pool.get("trick", 0))
	]

# ===========================================================
#  反馈动画（Phase 2.2 增强：屏幕微�?粒子+弹跳飘字�?
# ===========================================================

func play_attack_feedback(cell: Vector2i, damage: int, is_kill: bool = false) -> void:
	# 白色闪光
	_flash_cell = cell
	_flash_alpha = 1.0 if is_kill else 0.85
	var tw: Tween = create_tween()
	tw.tween_method(_set_flash_alpha, _flash_alpha, 0.0, 0.45 if is_kill else 0.35)
	tw.tween_callback(_clear_flash)
	# 屏幕微震
	BattleEffects.shake_screen(self, 4.0 if is_kill else 2.5, 0.3 if is_kill else 0.2)
	# 命中粒子
	var center: Vector2 = _iso_cell_center(cell)
	BattleEffects.spawn_hit_particles(self, center, CyberStyle.NEON_GOLD if is_kill else CyberStyle.NEON_RED, is_kill)
	# 增强伤害飘字
	var popup_pos: Vector2 = Vector2(center.x - 16, center.y - 28)
	BattleEffects.enhanced_damage_popup(self, popup_pos, damage, is_kill)
	# 击杀额外文字
	if is_kill:
		BattleEffects.kill_text_popup(self, Vector2(center.x - 16, center.y + 4))

func play_pickup_feedback(cell: Vector2i, effect_text: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = effect_text
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", CyberStyle.NEON_GREEN)
	var center: Vector2 = _iso_cell_center(cell)
	var start_x: float = center.x - 20
	var start_y: float = center.y - 28
	lbl.position = Vector2(start_x, start_y)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw: Tween = lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", start_y - 48.0, 0.7)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw.set_parallel(false)
	tw.tween_callback(lbl.queue_free)

func play_enemy_warning(cell: Vector2i) -> void:
	_flash_cell = cell
	_flash_alpha = 0.6
	var tw: Tween = create_tween()
	tw.tween_method(_set_flash_alpha, 0.6, 0.15, 0.4)
	tw.tween_method(_set_flash_alpha, 0.15, 0.5, 0.2)

func play_enemy_move_indicator(cell: Vector2i, unit_name: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = unit_name
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", CyberStyle.ACCENT_ORANGE)
	var center: Vector2 = _iso_cell_center(cell)
	lbl.position = Vector2(center.x - 20, center.y - 32)
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

func play_encounter_feedback(cell: Vector2i, text: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", CyberStyle.ACCENT_ORANGE)
	var center: Vector2 = _iso_cell_center(cell)
	var start_y: float = center.y - 28
	lbl.position = Vector2(center.x - 28, start_y)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw: Tween = lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", start_y - 56.0, 0.9)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.9)
	tw.set_parallel(false)
	tw.tween_callback(lbl.queue_free)

func play_heal_feedback(cell: Vector2i, text: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", CyberStyle.NEON_BLUE)
	var center: Vector2 = _iso_cell_center(cell)
	var start_y: float = center.y - 28
	lbl.position = Vector2(center.x - 20, start_y)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw2: Tween = lbl.create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(lbl, "position:y", start_y - 48.0, 0.7)
	tw2.tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw2.set_parallel(false)
	tw2.tween_callback(lbl.queue_free)

func play_event_feedback(cell: Vector2i, text: String, is_positive: bool) -> void:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 22)
	var color: Color = CyberStyle.NEON_GOLD if is_positive else CyberStyle.NEON_RED
	lbl.add_theme_color_override("font_color", color)
	var center: Vector2 = _iso_cell_center(cell)
	var start_y: float = center.y - 28
	lbl.position = Vector2(center.x - 20, start_y)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw3: Tween = lbl.create_tween()
	tw3.set_parallel(true)
	tw3.tween_property(lbl, "position:y", start_y - 48.0, 0.7)
	tw3.tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw3.set_parallel(false)
	tw3.tween_callback(lbl.queue_free)

func play_shop_feedback(cell: Vector2i, text: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", CyberStyle.NEON_TEAL)
	var center: Vector2 = _iso_cell_center(cell)
	var start_y: float = center.y - 28
	lbl.position = Vector2(center.x - 20, start_y)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw4: Tween = lbl.create_tween()
	tw4.set_parallel(true)
	tw4.tween_property(lbl, "position:y", start_y - 48.0, 0.7)
	tw4.tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw4.set_parallel(false)
	tw4.tween_callback(lbl.queue_free)

func play_chest_feedback(cell: Vector2i, text: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", CyberStyle.NEON_GOLD)
	var center: Vector2 = _iso_cell_center(cell)
	var start_y: float = center.y - 28
	lbl.position = Vector2(center.x - 20, start_y)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw5: Tween = lbl.create_tween()
	tw5.set_parallel(true)
	tw5.tween_property(lbl, "position:y", start_y - 52.0, 0.8)
	tw5.tween_property(lbl, "modulate:a", 0.0, 0.8)
	tw5.set_parallel(false)
	tw5.tween_callback(lbl.queue_free)

# --- 边缘渐暗（v0.1.60：柔化棋盘边界）---
func _draw_edge_vignette() -> void:
	var w: float = 1280.0
	var h: float = 720.0
	var band: float = 80.0
	var steps: int = 8
	for i in range(steps):
		var ratio: float = float(i) / float(steps)
		var a: float = 0.18 * (1.0 - ratio)
		var col: Color = Color(0.01, 0.01, 0.03, a)
		var t: float = band * ratio
		# �?
		draw_rect(Rect2(0, t, w, band / float(steps)), col, true)
		# �?
		draw_rect(Rect2(0, h - t - band / float(steps), w, band / float(steps)), col, true)
		# �?
		draw_rect(Rect2(t, 0, band / float(steps), h), col, true)
		# �?
		draw_rect(Rect2(w - t - band / float(steps), 0, band / float(steps), h), col, true)


