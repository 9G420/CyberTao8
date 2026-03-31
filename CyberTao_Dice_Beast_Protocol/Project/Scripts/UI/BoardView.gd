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

# --- 等距棋盘原点（菱形棋盘顶端中心）---
var iso_origin: Vector2 = Vector2(288.0, 30.0)

# Selection state
var selected_unit_id: String = ""
var highlight_cells: Array[Vector2i] = []
var attack_highlight_cells: Array[Vector2i] = []
var summon_highlight_cells: Array[Vector2i] = []

# Attack feedback state
var _flash_cell: Vector2i = Vector2i(-1, -1)
var _flash_alpha: float = 0.0

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
	size = Vector2(576, 350)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# 动画刷新定时器（50ms=20fps，驱动呼吸/脉冲效果）
	_anim_timer = Timer.new()
	_anim_timer.wait_time = 0.05
	_anim_timer.autostart = true
	_anim_timer.timeout.connect(_on_anim_tick)
	add_child(_anim_timer)

func _on_anim_tick() -> void:
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

# --- 点击交互逻辑（完全保留，零修改）---

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
	return IsoTileRenderer.screen_to_grid(pixel_pos, iso_origin)

func _is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_W and cell.y < GRID_H

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
	return IsoTileRenderer.grid_to_screen(cell.x, cell.y, iso_origin)

# ===========================================================
#  绘制层（v0.1.58 Phase 6：等距贴图渲染）
# ===========================================================

func _draw() -> void:
	var pulse: float = sin(Time.get_ticks_msec() * 0.003) * 0.5 + 0.5
	var font: Font = ThemeDB.fallback_font
	_draw_layer_grid(pulse)
	_draw_layer_overlays(pulse, font)
	_draw_layer_highlights(pulse)
	_draw_layer_units(pulse, font)
	_draw_attack_flash()

# Layer 1: 等距贴图基础网格
func _draw_layer_grid(_pulse: float) -> void:
	IsoTileRenderer.draw_board(self, iso_origin, board_manager)

# Layer 2: 叠层符号（贴图已区分格类型，此层仅补充文字/特殊标记）
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
			_draw_iso_label(center, "LOCKED", Color(0.6, 0.3, 0.3, 0.7 + pulse * 0.2), font, 9)
		else:
			_draw_iso_label(center, "BOSS", Color(CyberStyle.NEON_RED.r, CyberStyle.NEON_RED.g, CyberStyle.NEON_RED.b, 0.9 + pulse * 0.1), font, 11)
	# 回复量文字
	for cell in board_manager.heal_cells.keys():
		var center: Vector2 = _iso_cell_center(cell)
		var amt: String = "+" + str(int(board_manager.heal_cells[cell]))
		_draw_iso_label(center + Vector2(0, 6), amt, Color(CyberStyle.NEON_BLUE.r, CyberStyle.NEON_BLUE.g, CyberStyle.NEON_BLUE.b, 0.85), font, 10)
	# 事件格（无专属贴图，显示 ? 符号）
	for cell in board_manager.event_cells.keys():
		var center: Vector2 = _iso_cell_center(cell)
		var col: Color = CyberStyle.NEON_PURPLE
		IsoTileRenderer.draw_diamond_highlight(self, center, Color(col.r, col.g, col.b, 0.18 + pulse * 0.1), Color(col.r, col.g, col.b, 0.4 + pulse * 0.2))
		_draw_iso_label(center, "?", Color(col.r, col.g, col.b, 0.8 + pulse * 0.2), font, 16)
	# 商店费用文字
	for cell in board_manager.shop_cells.keys():
		var center: Vector2 = _iso_cell_center(cell)
		var heal_amount: int = int(board_manager.shop_cells[cell])
		_draw_iso_label(center + Vector2(0, 6), "HP+" + str(heal_amount), Color(CyberStyle.NEON_TEAL.r, CyberStyle.NEON_TEAL.g, CyberStyle.NEON_TEAL.b, 0.75), font, 9)
	# 道具名称文字
	for cell in board_manager.item_cells.keys():
		var item_id: String = String(board_manager.item_cells[cell])
		var display: String = String(_item_names.get(item_id, "?"))
		var center: Vector2 = _iso_cell_center(cell)
		_draw_iso_label(center + Vector2(0, 6), display, Color(CyberStyle.NEON_GREEN.r, CyberStyle.NEON_GREEN.g, CyberStyle.NEON_GREEN.b, 0.8), font, 10)
	# 路径格叠层（无专属贴图）
	for cell in board_manager.path_cells.keys():
		var owner_id: String = String(board_manager.path_cells[cell])
		var col: Color = CyberStyle.ACCENT_CYAN if owner_id == "player" else CyberStyle.ACCENT_ORANGE
		var center: Vector2 = _iso_cell_center(cell)
		IsoTileRenderer.draw_diamond_highlight(self, center, Color(col.r, col.g, col.b, 0.12 + pulse * 0.06), Color(col.r, col.g, col.b, 0.3 + pulse * 0.15), 6.0)
	# 传送门叠层（无专属贴图）
	for cell in board_manager.portal_cells.keys():
		var center: Vector2 = _iso_cell_center(cell)
		var col: Color = CyberStyle.ACCENT_CYAN
		IsoTileRenderer.draw_diamond_highlight(self, center, Color(col.r, col.g, col.b, 0.2 + pulse * 0.12), Color(col.r, col.g, col.b, 0.5 + pulse * 0.3), 4.0)
		_draw_iso_label(center, "◎", Color(col.r, col.g, col.b, 0.7 + pulse * 0.25), font, 14)

## 在菱形中心绘制居中文字
func _draw_iso_label(center: Vector2, text: String, col: Color, font: Font, font_size: int) -> void:
	var text_w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2(center.x - text_w * 0.5, center.y + float(font_size) * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)

# Layer 3: 高亮系统（菱形）
func _draw_layer_highlights(pulse: float) -> void:
	for cell in highlight_cells:
		var center: Vector2 = _iso_cell_center(cell)
		var col: Color = CyberStyle.ACCENT_CYAN
		IsoTileRenderer.draw_diamond_corners(self, center, Color(col.r, col.g, col.b, 0.55 + pulse * 0.3))
		IsoTileRenderer.draw_diamond_highlight(self, center, Color(col.r, col.g, col.b, 0.06 + pulse * 0.04), Color(0, 0, 0, 0))
	for cell in attack_highlight_cells:
		var center: Vector2 = _iso_cell_center(cell)
		var col: Color = CyberStyle.NEON_RED
		IsoTileRenderer.draw_diamond_highlight(self, center, Color(col.r, col.g, col.b, 0.15 + pulse * 0.15), Color(col.r, col.g, col.b, 0.35 + pulse * 0.3))
	for cell in summon_highlight_cells:
		var center: Vector2 = _iso_cell_center(cell)
		var col: Color = CyberStyle.ACCENT_MAGENTA
		IsoTileRenderer.draw_diamond_highlight(self, center, Color(col.r, col.g, col.b, 0.1 + pulse * 0.08), Color(col.r, col.g, col.b, 0.5 + pulse * 0.3))

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
	IsoTileRenderer.draw_diamond_highlight(self, center, Color(1.0, 1.0, 1.0, _flash_alpha), Color(0, 0, 0, 0), 2.0)

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
	var popup_pos: Vector2 = Vector2(center.x - 12, center.y - 20)
	BattleEffects.enhanced_damage_popup(self, popup_pos, damage, is_kill)
	# 击杀额外文字
	if is_kill:
		BattleEffects.kill_text_popup(self, Vector2(center.x - 12, center.y))

func play_pickup_feedback(cell: Vector2i, effect_text: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = effect_text
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", CyberStyle.NEON_GREEN)
	var center: Vector2 = _iso_cell_center(cell)
	var start_x: float = center.x - 16
	var start_y: float = center.y - 20
	lbl.position = Vector2(start_x, start_y)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw: Tween = lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", start_y - 36.0, 0.7)
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
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", CyberStyle.ACCENT_ORANGE)
	var center: Vector2 = _iso_cell_center(cell)
	lbl.position = Vector2(center.x - 16, center.y - 24)
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
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", CyberStyle.ACCENT_ORANGE)
	var center: Vector2 = _iso_cell_center(cell)
	var start_y: float = center.y - 20
	lbl.position = Vector2(center.x - 24, start_y)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw: Tween = lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", start_y - 44.0, 0.9)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.9)
	tw.set_parallel(false)
	tw.tween_callback(lbl.queue_free)

func play_heal_feedback(cell: Vector2i, text: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", CyberStyle.NEON_BLUE)
	var center: Vector2 = _iso_cell_center(cell)
	var start_y: float = center.y - 20
	lbl.position = Vector2(center.x - 16, start_y)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw2: Tween = lbl.create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(lbl, "position:y", start_y - 36.0, 0.7)
	tw2.tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw2.set_parallel(false)
	tw2.tween_callback(lbl.queue_free)

func play_event_feedback(cell: Vector2i, text: String, is_positive: bool) -> void:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 18)
	var color: Color = CyberStyle.NEON_GOLD if is_positive else CyberStyle.NEON_RED
	lbl.add_theme_color_override("font_color", color)
	var center: Vector2 = _iso_cell_center(cell)
	var start_y: float = center.y - 20
	lbl.position = Vector2(center.x - 16, start_y)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw3: Tween = lbl.create_tween()
	tw3.set_parallel(true)
	tw3.tween_property(lbl, "position:y", start_y - 36.0, 0.7)
	tw3.tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw3.set_parallel(false)
	tw3.tween_callback(lbl.queue_free)

func play_shop_feedback(cell: Vector2i, text: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", CyberStyle.NEON_TEAL)
	var center: Vector2 = _iso_cell_center(cell)
	var start_y: float = center.y - 20
	lbl.position = Vector2(center.x - 16, start_y)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw4: Tween = lbl.create_tween()
	tw4.set_parallel(true)
	tw4.tween_property(lbl, "position:y", start_y - 36.0, 0.7)
	tw4.tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw4.set_parallel(false)
	tw4.tween_callback(lbl.queue_free)

func play_chest_feedback(cell: Vector2i, text: String) -> void:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", CyberStyle.NEON_GOLD)
	var center: Vector2 = _iso_cell_center(cell)
	var start_y: float = center.y - 20
	lbl.position = Vector2(center.x - 16, start_y)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw5: Tween = lbl.create_tween()
	tw5.set_parallel(true)
	tw5.tween_property(lbl, "position:y", start_y - 40.0, 0.8)
	tw5.tween_property(lbl, "modulate:a", 0.0, 0.8)
	tw5.set_parallel(false)
	tw5.tween_callback(lbl.queue_free)
