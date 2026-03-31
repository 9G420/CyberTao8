extends Control
class_name BoardView

signal unit_selected(unit_id: String)
signal unit_deselected
signal move_requested(unit_id: String, target_cell: Vector2i)
signal attack_requested(unit_id: String, target_cell: Vector2i)
signal summon_requested(unit_id: String, target_cell: Vector2i)

const CELL_SIZE: int = 72

# --- 相机跟随（v0.1.63：拖拽+平滑+缩放）---
var board_manager: Node = null
var unit_manager: Node = null
var battle_flow: Node = null

var camera_cell: Vector2i = Vector2i(0, 0)
var iso_origin: Vector2 = Vector2(640.0, 360.0)
var _iso_origin_target: Vector2 = Vector2(640.0, 360.0)
const SCREEN_CENTER: Vector2 = Vector2(640.0, 360.0)
const CAMERA_LERP_SPEED: float = 8.0	# 平滑跟随速度

# 缩放（v0.1.63）
var _zoom: float = 1.0
const ZOOM_MIN: float = 0.4
const ZOOM_MAX: float = 1.6
const ZOOM_STEP: float = 0.1

# 鼠标拖拽平移
var _drag_active: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_start_origin: Vector2 = Vector2.ZERO
var _drag_offset: Vector2 = Vector2.ZERO	# 用户拖拽累积偏移

# Selection state
var selected_unit_id: String = ""
var highlight_cells: Array[Vector2i] = []
var attack_highlight_cells: Array[Vector2i] = []
var summon_highlight_cells: Array[Vector2i] = []

# Attack feedback state
var _flash_cell: Vector2i = Vector2i(-1, -1)
var _flash_alpha: float = 0.0

# Hover highlight（v0.1.62）
var _hover_cell: Vector2i = Vector2i(-1, -1)

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
	_iso_origin_target = IsoTileRenderer.calc_origin_for_cell_zoom(camera_cell, SCREEN_CENTER, _zoom)
	iso_origin = _iso_origin_target
	# 动画刷新定时器（50ms=20fps，驱动呼吸/脉冲效果）
	_anim_timer = Timer.new()
	_anim_timer.wait_time = 0.05
	_anim_timer.autostart = true
	_anim_timer.timeout.connect(_on_anim_tick)
	add_child(_anim_timer)

func _on_anim_tick() -> void:
	# 平滑插值相机位置（v0.1.62）
	if not _drag_active:
		var target: Vector2 = _iso_origin_target + _drag_offset
		var diff: Vector2 = target - iso_origin
		if diff.length() > 0.5:
			iso_origin = iso_origin.lerp(target, clampf(CAMERA_LERP_SPEED * 0.05, 0.0, 1.0))
		else:
			iso_origin = target
	queue_redraw()

## 设置相机跟随目标格子（v0.1.63：平滑过渡+缩放）
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

# --- 点击/拖拽/缩放交互逻辑（v0.1.63）---

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
	# 鼠标拖拽平移（右键或中键或左键拖拽）
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
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
		return
	_handle_cell_click(cell)
	accept_event()

func _pixel_to_cell(pixel_pos: Vector2) -> Vector2i:
	return IsoTileRenderer.screen_to_grid_zoom(pixel_pos, iso_origin, _zoom)

func _is_valid_cell(cell: Vector2i) -> bool:
	if board_manager != null:
		return board_manager.is_in_bounds(cell)
	return cell.x >= 0 and cell.y >= 0 and cell.x < 12 and cell.y < 12

## 缩放（以鼠标位置为中心）
func _apply_zoom(delta: float, mouse_pos: Vector2) -> void:
	var old_zoom: float = _zoom
	_zoom = clampf(_zoom + delta, ZOOM_MIN, ZOOM_MAX)
	if _zoom == old_zoom:
		return
	# 保持鼠标指向的世界位置不变
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
			if String(clicked_unit.get("owner", "")) == "player":
				_select_unit(clicked_id)
				return
		_deselect()
		return
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
	highlight_cells = []
	attack_highlight_cells = []
	summon_highlight_cells = []
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

# --- 辅助 ---

func _cell_rect(cell: Vector2i, margin: int) -> Rect2:
	return Rect2(Vector2(cell.x * CELL_SIZE + margin, cell.y * CELL_SIZE + margin), Vector2(CELL_SIZE - margin * 2, CELL_SIZE - margin * 2))

func _iso_cell_center(cell: Vector2i) -> Vector2:
	return IsoTileRenderer.grid_to_screen_zoom(cell.x, cell.y, iso_origin, _zoom)

# ===========================================================
#  绘制层（v0.1.62：悬停高亮+拖拽相机）
# ===========================================================

func _draw() -> void:
	var pulse: float = sin(Time.get_ticks_msec() * 0.003) * 0.5 + 0.5
	var font: Font = ThemeDB.fallback_font
	_draw_layer_grid(pulse)
	_draw_layer_overlays(pulse, font)
	_draw_layer_hover(pulse)
	_draw_layer_highlights(pulse)
	_draw_layer_units(pulse, font)
	_draw_attack_flash()
	_draw_edge_vignette()

# Layer 1: 等距程序化菱形网格（含环境填充）
func _draw_layer_grid(pulse: float) -> void:
	IsoTileRenderer.draw_board(self, iso_origin, board_manager, pulse, _zoom)

# Layer 2: 叠层符号（高起贴图已区分格类型，此层仅补充文字/特殊标记）
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
	# 回复量文字
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
	# 路径格叠层
	for cell in board_manager.path_cells.keys():
		var owner_id: String = String(board_manager.path_cells[cell])
		var col: Color = CyberStyle.ACCENT_CYAN if owner_id == "player" else CyberStyle.ACCENT_ORANGE
		var center: Vector2 = _iso_cell_center(cell)
		IsoTileRenderer.draw_diamond_highlight(self, center, Color(col.r, col.g, col.b, 0.12 + pulse * 0.06), Color(col.r, col.g, col.b, 0.3 + pulse * 0.15), 8.0, _zoom)

## 在菱形中心绘制居中文字（缩放感知）
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

# Layer 4: 单位层（按 depth 排序保证遮挡正确）
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
		var center: Vector2 = _iso_cell_center(cell)
		UnitRenderer.draw_full_unit_iso(self, center, unit, is_sel, pulse, idle_y, font)
		if board_manager:
			UnitRenderer.draw_affinity_star_iso(self, center, unit, board_manager, cell, font)

# Layer 5: 攻击闪光（菱形）
func _draw_attack_flash() -> void:
	if _flash_alpha <= 0.0 or _flash_cell.x < 0:
		return
	var center: Vector2 = _iso_cell_center(_flash_cell)
	IsoTileRenderer.draw_diamond_highlight(self, center, Color(1.0, 1.0, 1.0, _flash_alpha), Color(0, 0, 0, 0), 4.0, _zoom)

# ===========================================================
#  反馈动画（Phase 2.2 增强：屏幕微震+粒子+弹跳飘字）
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
		var a: float = 0.55 * (1.0 - ratio)
		var col: Color = Color(0.01, 0.01, 0.03, a)
		var t: float = band * ratio
		# 上
		draw_rect(Rect2(0, t, w, band / float(steps)), col, true)
		# 下
		draw_rect(Rect2(0, h - t - band / float(steps), w, band / float(steps)), col, true)
		# 左
		draw_rect(Rect2(t, 0, band / float(steps), h), col, true)
		# 右
		draw_rect(Rect2(w - t - band / float(steps), 0, band / float(steps), h), col, true)
