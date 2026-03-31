extends Node3D
class_name BoardView3D

## 3D 棋盘视图（v0.1.71 — 3D 渐进迁移 P0）
## 与 BoardView（2D）信号接口对齐，支持 Main.gd 通过 _active_view() 路由
## 内嵌于 SubViewport 中，由 Main.gd 的 SubViewportContainer 承载

# --- 信号（与 BoardView 对齐）---
signal unit_selected(unit_id: String)
signal unit_deselected
signal move_requested(unit_id: String, target_cell: Vector2i)
signal attack_requested(unit_id: String, target_cell: Vector2i)
signal summon_requested(unit_id: String, target_cell: Vector2i)
signal move_anim_done

# --- 外部引用 ---
var board_manager: Node = null
var unit_manager: Node = null
var battle_flow: Node = null

# --- 选中状态（与 BoardView 对齐）---
var selected_unit_id: String = ""
var highlight_cells: Array[Vector2i] = []
var attack_highlight_cells: Array[Vector2i] = []
var summon_highlight_cells: Array[Vector2i] = []

# --- 相机 ---
var camera_cell: Vector2i = Vector2i(0, 0)
var _camera: Camera3D = null
var _camera_target: Vector3 = Vector3.ZERO
const CAMERA_HEIGHT: float = 18.0
const CAMERA_ANGLE_DEG: float = 55.0
const CAMERA_LERP_SPEED: float = 4.5
const ZOOM_MIN: float = 10.0
const ZOOM_MAX: float = 30.0
var _camera_distance: float = 18.0

# --- 3D 场景容器 ---
var _tiles_root: Node3D = null
var _units_root: Node3D = null
var _highlights_root: Node3D = null
var _env_light: DirectionalLight3D = null
var _ambient: WorldEnvironment = null

# --- 拖拽 ---
var _drag_active: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_offset: Vector3 = Vector3.ZERO
var _drag_offset_accumulated: Vector3 = Vector3.ZERO

# --- 移动动画（与 BoardView 对齐）---
var _move_anim_unit: String = ""
var _move_anim_from: Vector3 = Vector3.ZERO
var _move_anim_to: Vector3 = Vector3.ZERO
var _move_anim_t: float = 1.0
var _move_tween: Tween = null

# --- 脉冲动画 ---
var _pulse_time: float = 0.0

# --- 网格尺寸缓存 ---
var _grid_size: int = 12

# --- 内部节点字典 ---
var _tile_nodes: Dictionary = {}		# cell(Vector2i) -> MeshInstance3D
var _unit_nodes: Dictionary = {}		# unit_id(String) -> Node3D
var _highlight_nodes: Array[MeshInstance3D] = []

func _ready() -> void:
	# 场景根节点组织
	_tiles_root = Node3D.new()
	_tiles_root.name = "TilesRoot"
	add_child(_tiles_root)

	_highlights_root = Node3D.new()
	_highlights_root.name = "HighlightsRoot"
	add_child(_highlights_root)

	_units_root = Node3D.new()
	_units_root.name = "UnitsRoot"
	add_child(_units_root)

	# 相机
	_camera = Camera3D.new()
	_camera.name = "BoardCamera3D"
	_camera.fov = 45.0
	_camera.near = 0.1
	_camera.far = 100.0
	add_child(_camera)
	_update_camera_transform()

	# 灯光
	_setup_lighting()

func _setup_lighting() -> void:
	# 主方向光（模拟赛博朋克冷调光源）
	_env_light = DirectionalLight3D.new()
	_env_light.name = "MainLight"
	_env_light.light_color = Color(0.75, 0.82, 1.0)
	_env_light.light_energy = 0.8
	_env_light.shadow_enabled = true
	_env_light.rotation_degrees = Vector3(-55, -30, 0)
	add_child(_env_light)

	# 环境光
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.05, 0.08, 0.15)
	env.ambient_light_energy = 0.4
	env.tonemap_mode = Environment.TONE_MAP_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_bloom = 0.1
	_ambient = WorldEnvironment.new()
	_ambient.environment = env
	add_child(_ambient)

func _process(delta: float) -> void:
	_pulse_time += delta
	# 平滑相机插值
	if _camera and not _drag_active:
		var target_pos: Vector3 = _camera_target + _drag_offset_accumulated
		var angle_rad: float = deg_to_rad(CAMERA_ANGLE_DEG)
		var cam_offset := Vector3(0, sin(angle_rad) * _camera_distance, cos(angle_rad) * _camera_distance)
		var desired_pos: Vector3 = target_pos + cam_offset
		_camera.position = _camera.position.lerp(desired_pos, clampf(CAMERA_LERP_SPEED * delta, 0.0, 1.0))
		_camera.look_at(target_pos, Vector3.UP)
	# 移动动画更新
	_update_move_animation()

# ============================
#  公开接口（与 BoardView 对齐）
# ============================

func bind_managers(next_board_manager: Node, next_unit_manager: Node) -> void:
	board_manager = next_board_manager
	unit_manager = next_unit_manager
	if board_manager and board_manager.has_signal("board_changed"):
		if not board_manager.board_changed.is_connected(_on_state_changed):
			board_manager.board_changed.connect(_on_state_changed)
	if unit_manager and unit_manager.has_signal("units_changed"):
		if not unit_manager.units_changed.is_connected(_on_state_changed):
			unit_manager.units_changed.connect(_on_state_changed)
	rebuild_board()

func bind_battle_flow(next_battle_flow: Node) -> void:
	battle_flow = next_battle_flow
	if battle_flow and battle_flow.has_signal("phase_changed"):
		if not battle_flow.phase_changed.is_connected(_on_phase_changed):
			battle_flow.phase_changed.connect(_on_phase_changed)

func set_camera_target(cell: Vector2i) -> void:
	camera_cell = cell
	_camera_target = GridMapper3D.cell_to_world(cell, _grid_size)

## 与 BoardView.queue_redraw() 对应：在 3D 中重建变化的部分
func queue_redraw() -> void:
	_refresh_units()
	_refresh_highlights()

## 逐格移动动画（与 BoardView.play_move_step 对齐）
func play_move_step(unit_id: String, from_cell: Vector2i, to_cell: Vector2i, duration: float = 0.15) -> void:
	if _move_tween and _move_tween.is_running():
		_move_tween.kill()
	_move_anim_unit = unit_id
	_move_anim_from = GridMapper3D.cell_to_world(from_cell, _grid_size)
	_move_anim_to = GridMapper3D.cell_to_world(to_cell, _grid_size)
	_move_anim_t = 0.0
	_move_tween = create_tween()
	_move_tween.tween_method(_set_move_t, 0.0, 1.0, duration)
	_move_tween.tween_callback(_on_move_step_finished)

func _set_move_t(t: float) -> void:
	_move_anim_t = t

func _on_move_step_finished() -> void:
	_move_anim_unit = ""
	_move_anim_t = 1.0
	_refresh_units()
	emit_signal("move_anim_done")

func _update_move_animation() -> void:
	if _move_anim_unit == "" or _move_anim_t >= 1.0:
		return
	var node: Node3D = _unit_nodes.get(_move_anim_unit, null)
	if node == null:
		return
	var pos: Vector3 = _move_anim_from.lerp(_move_anim_to, _move_anim_t)
	node.position = pos

# --- 反馈方法桩（与 BoardView 对齐，3D 实现后续补充）---

func play_attack_feedback(cell: Vector2i, damage: int, is_kill: bool = false) -> void:
	# TODO: 3D 攻击闪光特效
	pass

func play_pickup_feedback(cell: Vector2i, effect_text: String) -> void:
	pass

func play_enemy_warning(cell: Vector2i) -> void:
	pass

func play_enemy_move_indicator(cell: Vector2i, unit_name: String) -> void:
	pass

func play_encounter_feedback(cell: Vector2i, text: String) -> void:
	pass

func play_heal_feedback(cell: Vector2i, text: String) -> void:
	pass

func play_event_feedback(cell: Vector2i, text: String, is_positive: bool) -> void:
	pass

func play_shop_feedback(cell: Vector2i, text: String) -> void:
	pass

func play_chest_feedback(cell: Vector2i, text: String) -> void:
	pass

# ============================
#  棋盘构建
# ============================

func rebuild_board() -> void:
	_clear_tiles()
	if board_manager == null:
		return
	_grid_size = _get_grid_size()
	for gx in range(_grid_size):
		for gy in range(_grid_size):
			var cell := Vector2i(gx, gy)
			var tile_key: String = _get_tile_key(cell)
			var tile_node: MeshInstance3D = TileMeshFactory3D.create_tile(tile_key, cell, _grid_size)
			_tiles_root.add_child(tile_node)
			_tile_nodes[cell] = tile_node
	_refresh_units()
	_refresh_highlights()

func _clear_tiles() -> void:
	for child in _tiles_root.get_children():
		child.queue_free()
	_tile_nodes.clear()

func _get_grid_size() -> int:
	if board_manager != null and board_manager.board_size != Vector2i.ZERO:
		return board_manager.board_size.x
	return GridMapper3D.DEFAULT_GRID

# ============================
#  单位刷新
# ============================

func _refresh_units() -> void:
	if unit_manager == null:
		return
	# 移除已不存在的单位
	var existing_ids: Array = _unit_nodes.keys()
	for uid in existing_ids:
		if not unit_manager.units_by_id.has(uid):
			var node: Node3D = _unit_nodes[uid]
			node.queue_free()
			_unit_nodes.erase(uid)
	# 添加/更新单位
	for uid in unit_manager.units_by_id.keys():
		var unit: Dictionary = unit_manager.get_unit(uid)
		if unit.is_empty():
			continue
		var cell: Vector2i = unit["cell"]
		var world_pos: Vector3 = GridMapper3D.cell_to_world(cell, _grid_size)
		if _unit_nodes.has(uid):
			var node: Node3D = _unit_nodes[uid]
			# 移动动画中的单位不更新位置
			if uid != _move_anim_unit:
				node.position = world_pos
			# 更新 HP
			var is_player: bool = String(unit.get("owner", "")) == "player"
			UnitMeshFactory3D.update_hp_bar(node, int(unit.get("hp", 1)), int(unit.get("max_hp", 1)), is_player)
		else:
			var node: Node3D = UnitMeshFactory3D.create_unit_node(unit, cell, _grid_size)
			_units_root.add_child(node)
			_unit_nodes[uid] = node

# ============================
#  高亮刷新
# ============================

func _refresh_highlights() -> void:
	# 清除旧高亮
	for hl in _highlight_nodes:
		if is_instance_valid(hl):
			hl.queue_free()
	_highlight_nodes.clear()
	# 移动高亮（青色）
	for cell in highlight_cells:
		var hl := TileMeshFactory3D.create_highlight(cell, CyberStyle.ACCENT_CYAN, _grid_size)
		_highlights_root.add_child(hl)
		_highlight_nodes.append(hl)
	# 攻击高亮（红色）
	for cell in attack_highlight_cells:
		var hl := TileMeshFactory3D.create_highlight(cell, CyberStyle.NEON_RED, _grid_size)
		_highlights_root.add_child(hl)
		_highlight_nodes.append(hl)
	# 召唤高亮（品红）
	for cell in summon_highlight_cells:
		var hl := TileMeshFactory3D.create_highlight(cell, CyberStyle.ACCENT_MAGENTA, _grid_size)
		_highlights_root.add_child(hl)
		_highlight_nodes.append(hl)
	# 选中单位脚下光圈
	if selected_unit_id != "" and unit_manager:
		var unit: Dictionary = unit_manager.get_unit(selected_unit_id)
		if not unit.is_empty():
			var cell: Vector2i = unit["cell"]
			var hl := TileMeshFactory3D.create_highlight(cell, CyberStyle.NEON_GOLD, _grid_size)
			_highlights_root.add_child(hl)
			_highlight_nodes.append(hl)

# ============================
#  输入处理（射线检测）
# ============================

func handle_input(event: InputEvent) -> void:
	if _camera == null:
		return
	# 缩放
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_camera_distance = clampf(_camera_distance - 1.5, ZOOM_MIN, ZOOM_MAX)
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_camera_distance = clampf(_camera_distance + 1.5, ZOOM_MIN, ZOOM_MAX)
			return
	# 拖拽
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				_drag_active = true
				_drag_start_pos = mb.position
			else:
				_drag_active = false
			return
	if event is InputEventMouseMotion and _drag_active:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		var delta_px: Vector2 = mm.position - _drag_start_pos
		_drag_start_pos = mm.position
		# 将屏幕像素偏移转换为世界 XZ 偏移（近似）
		var world_scale: float = _camera_distance * 0.003
		_drag_offset_accumulated += Vector3(-delta_px.x * world_scale, 0, -delta_px.y * world_scale)
		return
	# 点击
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var cell: Vector2i = _screen_to_cell(mb.position)
			if _is_valid_cell(cell):
				_handle_cell_click(cell)

## 屏幕坐标 → 格子坐标（地面射线交叉）
func _screen_to_cell(screen_pos: Vector2) -> Vector2i:
	if _camera == null:
		return Vector2i(-1, -1)
	var from: Vector3 = _camera.project_ray_origin(screen_pos)
	var dir: Vector3 = _camera.project_ray_normal(screen_pos)
	# 射线与 Y=0 平面交叉
	if abs(dir.y) < 0.001:
		return Vector2i(-1, -1)
	var t: float = -from.y / dir.y
	if t < 0:
		return Vector2i(-1, -1)
	var hit: Vector3 = from + dir * t
	return GridMapper3D.world_to_cell(hit, _grid_size)

func _is_valid_cell(cell: Vector2i) -> bool:
	if board_manager != null:
		return board_manager.is_in_bounds(cell)
	return GridMapper3D.is_in_bounds(cell, _grid_size)

## 点击处理（与 BoardView._handle_cell_click 逻辑完全对齐）
func _handle_cell_click(cell: Vector2i) -> void:
	if battle_flow and (battle_flow.is_battle_over() or battle_flow.current_phase == battle_flow.BattlePhase.ENCOUNTER):
		return
	if selected_unit_id != "":
		# 攻击优先
		for ac in attack_highlight_cells:
			if ac == cell:
				emit_signal("attack_requested", selected_unit_id, cell)
				return
		# 移动
		for hc in highlight_cells:
			if hc == cell:
				emit_signal("move_requested", selected_unit_id, cell)
				return
		# 召唤
		for sc in summon_highlight_cells:
			if sc == cell:
				emit_signal("summon_requested", selected_unit_id, cell)
				return
		# 点击同一个或其他玩家单位
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
	# 无选中 → 选中玩家单位
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
	if unit_manager:
		var unit: Dictionary = unit_manager.get_unit(unit_id)
		if not unit.is_empty():
			_drag_offset_accumulated = Vector3.ZERO
			set_camera_target(unit["cell"])
	emit_signal("unit_selected", unit_id)
	_refresh_highlights()

func _deselect() -> void:
	selected_unit_id = ""
	highlight_cells = []
	attack_highlight_cells = []
	summon_highlight_cells = []
	emit_signal("unit_deselected")
	_refresh_highlights()

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

# ============================
#  内部回调
# ============================

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
	_refresh_units()
	_refresh_highlights()

# ============================
#  工具方法
# ============================

func _update_camera_transform() -> void:
	if _camera == null:
		return
	var angle_rad: float = deg_to_rad(CAMERA_ANGLE_DEG)
	var cam_offset := Vector3(0, sin(angle_rad) * _camera_distance, cos(angle_rad) * _camera_distance)
	_camera.position = _camera_target + cam_offset
	_camera.look_at(_camera_target, Vector3.UP)

## 获取 tile_key（与 IsoTileRenderer._get_tile_key 逻辑一致）
func _get_tile_key(cell: Vector2i) -> String:
	if board_manager == null:
		return "normal_dark" if (cell.x + cell.y) % 2 == 0 else "normal_light"
	if board_manager.portal_cells.has(cell):
		return "portal"
	if board_manager.encounter_cells.has(cell):
		return "encounter"
	if board_manager.heal_cells.has(cell):
		return "heal"
	if board_manager.shop_cells.has(cell):
		return "shop"
	if board_manager.chest_cells.has(cell):
		return "chest"
	if board_manager.item_cells.has(cell):
		return "item"
	if board_manager.event_cells.has(cell):
		return "event"
	if board_manager.terrain_cells.has(cell):
		var ttype: String = String(board_manager.terrain_cells[cell])
		if ttype == "high_ground":
			return "high_ground"
		if ttype == "trap":
			return "trap"
	return "normal_dark" if (cell.x + cell.y) % 2 == 0 else "normal_light"
