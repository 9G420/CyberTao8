extends Node3D
class_name BoardView3D

## 3D 棋盘视图（v0.1.81 — 精灵动画移除，全单位程序化像素）
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
const CAMERA_LERP_SPEED: float = 8.0
const CAMERA_ANGLE_MIN: float = 30.0
const CAMERA_ANGLE_MAX: float = 75.0
var _camera_angle_deg: float = 55.0
var _camera_yaw_deg: float = 0.0		# v0.1.72：提高至 8.0（原 4.5 在 60fps 下过慢）
const ZOOM_MIN: float = 10.0
const ZOOM_MAX: float = 30.0
const ZOOM_STEP: float = 1.5
var _camera_distance: float = 18.0

# --- 3D 场景容器 ---
var _tiles_root: Node3D = null
var _units_root: Node3D = null
var _highlights_root: Node3D = null
var _feedback_root: Node3D = null		# v0.1.74：反馈特效容器
var _env_light: DirectionalLight3D = null
var _ambient: WorldEnvironment = null

# --- 相机震动（v0.1.74）---
var _shake_offset: Vector3 = Vector3.ZERO

# --- 拖拽 ---
var _drag_active: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_start_offset: Vector3 = Vector3.ZERO		# v0.1.72：拖拽开始时的累积偏移快照
var _drag_offset: Vector3 = Vector3.ZERO
var _drag_offset_accumulated: Vector3 = Vector3.ZERO

# --- 中键视角旋转 ---
var _orbit_active: bool = false
var _orbit_start_pos: Vector2 = Vector2.ZERO
var _orbit_start_angle: float = 55.0
var _orbit_start_yaw: float = 0.0

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

	_feedback_root = Node3D.new()
	_feedback_root.name = "FeedbackRoot"
	add_child(_feedback_root)

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
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_bloom = 0.1
	_ambient = WorldEnvironment.new()
	_ambient.environment = env
	add_child(_ambient)

func _process(delta: float) -> void:
	_pulse_time += delta
	# v0.1.72：边界限制 — 将拖拽偏移夹紧到棋盘世界范围
	_clamp_drag_offset()
	# 平滑相机插值（v0.1.72：拖拽期间也更新相机，消除滞后感）
	if _camera:
		var target_pos: Vector3 = _camera_target + _drag_offset_accumulated
		var angle_rad: float = deg_to_rad(_camera_angle_deg)
		var yaw_rad: float = deg_to_rad(_camera_yaw_deg)
		var cam_offset := Vector3(0, sin(angle_rad) * _camera_distance, cos(angle_rad) * _camera_distance)
		cam_offset = cam_offset.rotated(Vector3.UP, yaw_rad)
		var desired_pos: Vector3 = target_pos + cam_offset
		if _drag_active:
			# 拖拽中：高速追踪，接近即时响应
			_camera.position = _camera.position.lerp(desired_pos, clampf(20.0 * delta, 0.0, 1.0)) + _shake_offset
		else:
			_camera.position = _camera.position.lerp(desired_pos, clampf(CAMERA_LERP_SPEED * delta, 0.0, 1.0)) + _shake_offset
		_camera.look_at(target_pos, Vector3.UP)
	# v0.1.93：按相机距离动态放大单位（远处更清楚，近处不过大）
	_update_unit_readability_scale()
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

func _update_unit_readability_scale() -> void:
	var t: float = inverse_lerp(ZOOM_MIN, ZOOM_MAX, _camera_distance)
	var scale_factor: float = lerpf(1.0, 2.8, clampf(t, 0.0, 1.0))
	for uid in _unit_nodes.keys():
		var node: Node3D = _unit_nodes[uid]
		if node == null:
			continue
		var body: Sprite3D = node.get_node_or_null("Body")
		if body:
			body.scale = Vector3(scale_factor, scale_factor, scale_factor)

# --- 反馈方法（v0.1.74 — 3D 反馈系统完整实现）---

func play_attack_feedback(cell: Vector2i, damage: int, is_kill: bool = false) -> void:
	# 1) 格子闪光
	var flash_color: Color = CyberStyle.NEON_GOLD if is_kill else Color(1.0, 1.0, 1.0, 0.9)
	var particle_color: Color = CyberStyle.NEON_GOLD if is_kill else CyberStyle.NEON_RED
	_play_cell_burst_feedback_3d(
		cell,
		flash_color,
		0.45 if is_kill else 0.35,
		particle_color,
		is_kill,
		0.6 if is_kill else 0.35,
		0.3
	)
	# 2) 相机震动
	# 3) 命中粒子
	# 4) 伤害飘字
	var dmg_color: Color = CyberStyle.NEON_GOLD if is_kill else CyberStyle.NEON_RED
	var dmg_size: float = 0.9 if is_kill else 0.65
	_spawn_float_text_3d(cell, "-" + str(damage), dmg_color, dmg_size, 3.0, 0.75 if is_kill else 0.6)
	# 5) 击杀文字
	if is_kill:
		_spawn_float_text_3d(cell, "KILL!", CyberStyle.NEON_GOLD, 0.7, 4.5, 0.9, 0.25)

func play_pickup_feedback(cell: Vector2i, effect_text: String) -> void:
	_spawn_float_text_3d(cell, effect_text, CyberStyle.NEON_GREEN, 0.55, 3.0, 0.7)

func play_enemy_warning(cell: Vector2i) -> void:
	# 红色闪烁脉冲：快速闪两次
	_spawn_cell_flash_3d(cell, Color(1.0, 0.2, 0.15, 0.7), 0.25)
	# 延迟第二次闪烁
	var timer: SceneTreeTimer = get_tree().create_timer(0.3)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(self):
			_spawn_cell_flash_3d(cell, Color(1.0, 0.2, 0.15, 0.5), 0.2)
	)

func play_enemy_move_indicator(cell: Vector2i, unit_name: String) -> void:
	_spawn_float_text_3d(cell, unit_name, CyberStyle.ACCENT_ORANGE, 0.4, 2.0, 0.8)

func play_encounter_feedback(cell: Vector2i, text: String) -> void:
	_spawn_float_text_3d(cell, text, CyberStyle.ACCENT_ORANGE, 0.7, 3.5, 0.9)

func play_heal_feedback(cell: Vector2i, text: String) -> void:
	_play_cell_burst_feedback_3d(
		cell,
		Color(CyberStyle.NEON_BLUE.r, CyberStyle.NEON_BLUE.g, CyberStyle.NEON_BLUE.b, 0.55),
		0.5,
		CyberStyle.NEON_BLUE
	)
	_spawn_float_text_3d(cell, text, CyberStyle.NEON_BLUE, 0.6, 3.1, 0.7)

func play_event_feedback(cell: Vector2i, text: String, is_positive: bool) -> void:
	var col: Color = CyberStyle.NEON_GOLD if is_positive else CyberStyle.NEON_RED
	_play_cell_burst_feedback_3d(
		cell,
		Color(col.r, col.g, col.b, 0.58),
		0.55,
		col,
		not is_positive,
		0.22 if not is_positive else 0.0,
		0.2
	)
	_spawn_float_text_3d(cell, text, col, 0.6, 3.1, 0.72)

func play_shop_feedback(cell: Vector2i, text: String) -> void:
	_play_cell_burst_feedback_3d(
		cell,
		Color(CyberStyle.NEON_TEAL.r, CyberStyle.NEON_TEAL.g, CyberStyle.NEON_TEAL.b, 0.55),
		0.55,
		CyberStyle.NEON_TEAL
	)
	_spawn_float_text_3d(cell, text, CyberStyle.NEON_TEAL, 0.6, 3.1, 0.72)

func play_chest_feedback(cell: Vector2i, text: String) -> void:
	_play_cell_burst_feedback_3d(
		cell,
		Color(CyberStyle.NEON_GOLD.r, CyberStyle.NEON_GOLD.g, CyberStyle.NEON_GOLD.b, 0.7),
		0.65,
		CyberStyle.NEON_GOLD,
		true,
		0.28,
		0.24
	)
	_spawn_float_text_3d(cell, text, CyberStyle.NEON_GOLD, 0.72, 3.4, 0.8)

# ============================
#  3D 反馈辅助方法（v0.1.74）
# ============================

## 3D 漂浮文字（Label3D billboard，上升 + 渐隐 + 自动释放）
## rise_height: 世界单位上升高度；duration: 动画总时长；delay: 起始延迟
func _spawn_float_text_3d(cell: Vector2i, text: String, color: Color, font_size: float, rise_height: float, duration: float, delay: float = 0.0) -> void:
	var world_pos: Vector3 = GridMapper3D.cell_to_world(cell, _grid_size)
	var lbl: Label3D = Label3D.new()
	lbl.text = text
	lbl.font_size = int(font_size * 64.0)		# Label3D font_size 单位较小，乘以缩放系数
	lbl.pixel_size = 0.01						# 世界单位 / 像素
	lbl.modulate = color
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true					# 始终可见（不被格子遮挡）
	lbl.position = Vector3(world_pos.x, 1.5, world_pos.z)	# 起始高度略高于格子
	lbl.outline_modulate = Color(0, 0, 0, 0.8)
	lbl.outline_size = 8
	_feedback_root.add_child(lbl)
	# 延迟后播放动画
	var tw: Tween = lbl.create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", 1.5 + rise_height, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(lbl, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.set_parallel(false)
	tw.tween_callback(lbl.queue_free)

func _play_cell_burst_feedback_3d(
	cell: Vector2i,
	flash_color: Color,
	flash_duration: float,
	particle_color: Color,
	strong_particles: bool = false,
	shake_intensity: float = 0.0,
	shake_duration: float = 0.0
) -> void:
	_spawn_cell_flash_3d(cell, flash_color, flash_duration)
	_spawn_hit_particles_3d(GridMapper3D.cell_to_world(cell, _grid_size), particle_color, strong_particles)
	if shake_intensity > 0.0 and shake_duration > 0.0:
		_shake_camera_3d(shake_intensity, shake_duration)

## 3D 格子闪光覆盖层（半透明 PlaneMesh 叠放在格子上方，渐隐后释放）
func _spawn_cell_flash_3d(cell: Vector2i, color: Color, duration: float) -> void:
	var world_pos: Vector3 = GridMapper3D.cell_to_world(cell, _grid_size)
	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(GridMapper3D.CELL_SIZE * 0.95, GridMapper3D.CELL_SIZE * 0.95)
	mesh_inst.mesh = plane
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b)
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat
	mesh_inst.position = Vector3(world_pos.x, 0.15, world_pos.z)	# 格子表面略上方
	_feedback_root.add_child(mesh_inst)
	# 渐隐动画
	var tw: Tween = mesh_inst.create_tween()
	tw.tween_method(func(alpha: float) -> void:
		mat.albedo_color.a = alpha
		mat.emission_energy_multiplier = alpha * 2.0
	, color.a, 0.0, duration)
	tw.tween_callback(mesh_inst.queue_free)

## 3D 相机震动（通过 _shake_offset 驱动，_process 中叠加到相机位置）
func _shake_camera_3d(intensity: float, duration: float) -> void:
	var steps: int = 6
	var step_time: float = duration / float(steps)
	var tw: Tween = create_tween()
	for i in range(steps):
		var decay: float = 1.0 - float(i) / float(steps)
		var offset_x: float = randf_range(-intensity, intensity) * decay
		var offset_z: float = randf_range(-intensity, intensity) * decay
		tw.tween_property(self, "_shake_offset", Vector3(offset_x, 0, offset_z), step_time)
	tw.tween_property(self, "_shake_offset", Vector3.ZERO, step_time * 0.5)

## 3D 命中粒子爆发（CPUParticles3D，gl_compatibility 兼容）
func _spawn_hit_particles_3d(world_pos: Vector3, color: Color, is_kill: bool) -> void:
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.position = Vector3(world_pos.x, 0.8, world_pos.z)
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 16 if is_kill else 8
	particles.lifetime = 0.7 if is_kill else 0.45
	# 方向：全方位向上扩散
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 60.0
	particles.initial_velocity_min = 3.0 if is_kill else 2.0
	particles.initial_velocity_max = 7.0 if is_kill else 4.5
	particles.gravity = Vector3(0, -8.0, 0)
	# 粒子大小
	particles.scale_amount_min = 0.08 if is_kill else 0.05
	particles.scale_amount_max = 0.15 if is_kill else 0.1
	# 颜色渐变（不透明 → 透明）
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(color.r, color.g, color.b, 1.0))
	gradient.set_color(1, Color(color.r, color.g, color.b, 0.0))
	particles.color_ramp = gradient
	particles.color = color
	# 发射形状
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.4 if is_kill else 0.2
	# 使用简单网格作为粒子可见形状
	var sphere_mesh: SphereMesh = SphereMesh.new()
	sphere_mesh.radius = 0.05
	sphere_mesh.height = 0.1
	particles.mesh = sphere_mesh
	_feedback_root.add_child(particles)
	particles.emitting = true
	# 粒子结束后自动释放
	var tw: Tween = particles.create_tween()
	tw.tween_interval(particles.lifetime + 0.2)
	tw.tween_callback(particles.queue_free)

# ============================
#  棋盘构建
# ============================

func rebuild_board() -> void:
	_clear_tiles()
	if board_manager == null:
		return
	_grid_size = _get_grid_size()
	_build_stage_environment()
	var ambient_pad: int = 8
	for gx in range(-ambient_pad, _grid_size + ambient_pad):
		for gy in range(-ambient_pad, _grid_size + ambient_pad):
			var cell := Vector2i(gx, gy)
			var in_board: bool = gx >= 0 and gy >= 0 and gx < _grid_size and gy < _grid_size
			var tile_key: String = _get_tile_key(cell) if in_board else ("normal_dark" if (gx + gy) % 2 == 0 else "normal_light")
			var tile_node: MeshInstance3D = TileMeshFactory3D.create_tile(tile_key, cell, _grid_size)
			if not in_board:
				var ambient_mat: StandardMaterial3D = tile_node.material_override as StandardMaterial3D
				if ambient_mat:
					var dim_mat: StandardMaterial3D = ambient_mat.duplicate()
					dim_mat.albedo_color = dim_mat.albedo_color.darkened(0.35)
					dim_mat.emission_energy_multiplier *= 0.35
					tile_node.material_override = dim_mat
			_tiles_root.add_child(tile_node)
			_tile_nodes[cell] = tile_node
	_refresh_units()
	_refresh_highlights()

func _clear_tiles() -> void:
	for child in _tiles_root.get_children():
		child.queue_free()
	_tile_nodes.clear()

func _build_stage_environment() -> void:
	var board_world: float = float(_grid_size) * GridMapper3D.CELL_SIZE
	# 舞台底板（比棋盘大）
	var stage := MeshInstance3D.new()
	var stage_mesh := BoxMesh.new()
	stage_mesh.size = Vector3(board_world * 1.9, 0.5, board_world * 1.9)
	stage.mesh = stage_mesh
	var stage_mat := StandardMaterial3D.new()
	stage_mat.albedo_color = Color(0.08, 0.1, 0.14, 0.95)
	stage_mat.emission_enabled = true
	stage_mat.emission = Color(0.1, 0.25, 0.35)
	stage_mat.emission_energy_multiplier = 0.25
	stage_mat.roughness = 0.85
	stage_mat.metallic = 0.12
	stage.material_override = stage_mat
	stage.position = Vector3(0, -0.45, 0)
	_tiles_root.add_child(stage)

	# 四面背景景片（低饱和，区分棋盘外区域）
	for i in range(4):
		var wall := MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = Vector2(board_world * 2.2, board_world * 0.9)
		wall.mesh = plane
		var wall_mat := StandardMaterial3D.new()
		wall_mat.albedo_color = Color(0.07, 0.09, 0.12, 0.9)
		wall_mat.emission_enabled = true
		wall_mat.emission = Color(0.08, 0.18, 0.28)
		wall_mat.emission_energy_multiplier = 0.18
		wall_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		wall_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wall.material_override = wall_mat
		match i:
			0:
				wall.position = Vector3(0, board_world * 0.18, -board_world * 1.05)
				wall.rotation_degrees = Vector3(80, 0, 0)
			1:
				wall.position = Vector3(0, board_world * 0.18, board_world * 1.05)
				wall.rotation_degrees = Vector3(80, 180, 0)
			2:
				wall.position = Vector3(-board_world * 1.05, board_world * 0.18, 0)
				wall.rotation_degrees = Vector3(80, 90, 0)
			3:
				wall.position = Vector3(board_world * 1.05, board_world * 0.18, 0)
				wall.rotation_degrees = Vector3(80, -90, 0)
		_tiles_root.add_child(wall)

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
	# 缩放（v0.1.72：以鼠标位置为轴心，与 2D 行为对齐）
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_apply_zoom(-ZOOM_STEP, mb.position)
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_apply_zoom(ZOOM_STEP, mb.position)
			return
	# 右键平移 / 中键旋转视角
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_drag_active = true
				_drag_start_pos = mb.position
				_drag_start_offset = _drag_offset_accumulated
			else:
				_drag_active = false
			return
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				_orbit_active = true
				_orbit_start_pos = mb.position
				_orbit_start_angle = _camera_angle_deg
				_orbit_start_yaw = _camera_yaw_deg
			else:
				_orbit_active = false
			return
	if event is InputEventMouseMotion and _drag_active:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		var delta_px: Vector2 = mm.position - _drag_start_pos
		var world_scale: float = _camera_distance / 350.0
		_drag_offset_accumulated = _drag_start_offset + Vector3(-delta_px.x * world_scale, 0, -delta_px.y * world_scale)
		return
	if event is InputEventMouseMotion and _orbit_active:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		var d: Vector2 = mm.position - _orbit_start_pos
		_camera_angle_deg = clampf(_orbit_start_angle + d.y * 0.12, CAMERA_ANGLE_MIN, CAMERA_ANGLE_MAX)
		_camera_yaw_deg = _orbit_start_yaw - d.x * 0.16
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
		highlight_cells.clear()
		attack_highlight_cells.clear()
		summon_highlight_cells.clear()
	if unit_manager:
		var unit: Dictionary = unit_manager.get_unit(unit_id)
		if not unit.is_empty():
			_drag_offset_accumulated = Vector3.ZERO
			set_camera_target(unit["cell"])
	emit_signal("unit_selected", unit_id)
	_refresh_highlights()

func _deselect() -> void:
	selected_unit_id = ""
	highlight_cells.clear()
	attack_highlight_cells.clear()
	summon_highlight_cells.clear()
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

## v0.1.85：拖拽偏移边界限制放宽（对齐 2D 自由拖拽手感）
func _clamp_drag_offset() -> void:
	var half_board: float = float(_grid_size) * GridMapper3D.HALF_CELL
	# 旧版 half_board * 0.5（12x12 下仅 ±6）过紧，容易出现“拖到某位置就卡住”
	# 新版按棋盘尺寸 + 相机距离动态放宽，保留安全边界但接近 2D 的自由拖拽
	var zoom_extra: float = maxf(0.0, _camera_distance - ZOOM_MIN)
	var max_offset: float = half_board * 2.0 + zoom_extra * 0.8
	_drag_offset_accumulated.x = clampf(_drag_offset_accumulated.x, -max_offset, max_offset)
	_drag_offset_accumulated.z = clampf(_drag_offset_accumulated.z, -max_offset, max_offset)

## v0.1.72：以鼠标位置为轴心的缩放（与 2D _apply_zoom 行为对齐）
func _apply_zoom(delta_dist: float, mouse_pos: Vector2) -> void:
	var old_dist: float = _camera_distance
	_camera_distance = clampf(_camera_distance + delta_dist, ZOOM_MIN, ZOOM_MAX)
	if _camera_distance == old_dist:
		return
	# 计算缩放前后鼠标指向的地面点，调整偏移使该点不变
	var ground_before: Vector3 = _screen_to_ground(mouse_pos, old_dist)
	var ground_after: Vector3 = _screen_to_ground(mouse_pos, _camera_distance)
	if ground_before != Vector3.ZERO and ground_after != Vector3.ZERO:
		var shift: Vector3 = ground_before - ground_after
		_drag_offset_accumulated += Vector3(shift.x, 0, shift.z)

## 辅助：在给定相机距离下，屏幕坐标对应的地面点（Y=0 射线交叉）
func _screen_to_ground(screen_pos: Vector2, cam_dist: float) -> Vector3:
	if _camera == null:
		return Vector3.ZERO
	# 临时计算该距离下的相机位置
	var target_pos: Vector3 = _camera_target + _drag_offset_accumulated
	var angle_rad: float = deg_to_rad(_camera_angle_deg)
	var yaw_rad: float = deg_to_rad(_camera_yaw_deg)
	var cam_offset := Vector3(0, sin(angle_rad) * cam_dist, cos(angle_rad) * cam_dist)
	cam_offset = cam_offset.rotated(Vector3.UP, yaw_rad)
	var cam_pos: Vector3 = target_pos + cam_offset
	# 使用相机的投影方向（近似：从 cam_pos 看向 target_pos 的方向偏移）
	var from: Vector3 = _camera.project_ray_origin(screen_pos)
	var dir: Vector3 = _camera.project_ray_normal(screen_pos)
	if abs(dir.y) < 0.001:
		return Vector3.ZERO
	var t: float = -from.y / dir.y
	if t < 0:
		return Vector3.ZERO
	return from + dir * t

func _update_camera_transform() -> void:
	if _camera == null:
		return
	var angle_rad: float = deg_to_rad(_camera_angle_deg)
	var yaw_rad: float = deg_to_rad(_camera_yaw_deg)
	var cam_offset := Vector3(0, sin(angle_rad) * _camera_distance, cos(angle_rad) * _camera_distance)
	cam_offset = cam_offset.rotated(Vector3.UP, yaw_rad)
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
