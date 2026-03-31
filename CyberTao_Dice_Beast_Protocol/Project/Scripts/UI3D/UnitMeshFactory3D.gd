extends RefCounted
class_name UnitMeshFactory3D

## 3D 单位网格工厂（v0.1.71）
## 负责为棋盘上的单位（玩家/敌方/召唤物）创建程序化 3D 表示
## 使用 CapsuleMesh（玩家）/ CylinderMesh（敌方）+ billboard HP 条

const UNIT_HEIGHT: float = 1.2		# 单位模型高度
const UNIT_RADIUS: float = 0.35	# 单位模型半径
const HP_BAR_WIDTH: float = 1.0	# HP 条宽度
const HP_BAR_HEIGHT: float = 0.12	# HP 条高度
const HP_BAR_OFFSET_Y: float = 1.6	# HP 条在单位上方的偏移

## 创建单位的完整 3D 节点（模型 + HP条），返回 Node3D 容器
static func create_unit_node(unit: Dictionary, cell: Vector2i, grid_size: int = 12) -> Node3D:
	var container := Node3D.new()
	var uid: String = String(unit.get("id", "unknown"))
	container.name = "Unit_" + uid

	var world_pos: Vector3 = GridMapper3D.cell_to_world(cell, grid_size)
	container.position = Vector3(world_pos.x, 0.0, world_pos.z)

	# 主体模型
	var body := _create_body_mesh(unit)
	container.add_child(body)

	# HP 条（billboard sprite）
	var hp_bar := _create_hp_bar(unit)
	container.add_child(hp_bar)

	return container

## 更新单位位置（用于移动动画）
static func update_unit_position(node: Node3D, world_pos: Vector3) -> void:
	node.position = world_pos

## 更新 HP 条显示
static func update_hp_bar(node: Node3D, hp: int, max_hp: int, is_player: bool) -> void:
	var hp_bar: MeshInstance3D = node.get_node_or_null("HPBar")
	if hp_bar == null:
		return
	var ratio: float = float(hp) / float(max_hp) if max_hp > 0 else 1.0
	# 更新 HP 条缩放（X 轴代表宽度）
	hp_bar.scale.x = ratio
	hp_bar.position.x = -HP_BAR_WIDTH * 0.5 * (1.0 - ratio)
	# 更新颜色
	var mat: StandardMaterial3D = hp_bar.material_override as StandardMaterial3D
	if mat:
		if is_player:
			mat.albedo_color = CyberStyle.HP_PLAYER if ratio > 0.3 else CyberStyle.HP_PLAYER_LOW
		else:
			mat.albedo_color = CyberStyle.HP_ENEMY if ratio > 0.3 else CyberStyle.HP_ENEMY_LOW
		mat.emission = mat.albedo_color

## 创建主体模型
static func _create_body_mesh(unit: Dictionary) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Body"
	var owner: String = String(unit.get("owner", ""))
	var is_player: bool = owner == "player"
	var is_summoned: bool = bool(unit.get("is_summoned", false))

	if is_player:
		var capsule := CapsuleMesh.new()
		capsule.radius = UNIT_RADIUS
		capsule.height = UNIT_HEIGHT
		mesh_inst.mesh = capsule
	else:
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = UNIT_RADIUS * 0.7
		cylinder.bottom_radius = UNIT_RADIUS
		cylinder.height = UNIT_HEIGHT * 0.9
		mesh_inst.mesh = cylinder

	var mat := StandardMaterial3D.new()
	mat.albedo_color = _get_unit_color(owner, is_summoned)
	mat.emission_enabled = true
	mat.emission = _get_unit_emission(owner, is_summoned)
	mat.emission_energy_multiplier = 0.4
	mat.metallic = 0.3
	mat.roughness = 0.5
	mesh_inst.material_override = mat

	# 模型底部贴地
	mesh_inst.position.y = UNIT_HEIGHT * 0.5
	return mesh_inst

## 创建 HP 条（使用 BoxMesh + billboard 行为通过代码实现）
static func _create_hp_bar(unit: Dictionary) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "HPBar"

	var box := BoxMesh.new()
	box.size = Vector3(HP_BAR_WIDTH, HP_BAR_HEIGHT, 0.02)
	mesh_inst.mesh = box

	var owner: String = String(unit.get("owner", ""))
	var is_player: bool = owner == "player"
	var hp: int = int(unit.get("hp", 1))
	var max_hp: int = int(unit.get("max_hp", 1))
	var ratio: float = float(hp) / float(max_hp) if max_hp > 0 else 1.0

	var mat := StandardMaterial3D.new()
	if is_player:
		mat.albedo_color = CyberStyle.HP_PLAYER if ratio > 0.3 else CyberStyle.HP_PLAYER_LOW
	else:
		mat.albedo_color = CyberStyle.HP_ENEMY if ratio > 0.3 else CyberStyle.HP_ENEMY_LOW
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.6
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mesh_inst.material_override = mat

	mesh_inst.position.y = HP_BAR_OFFSET_Y
	mesh_inst.scale.x = ratio
	return mesh_inst

## 单位主体颜色
static func _get_unit_color(owner: String, is_summoned: bool) -> Color:
	if owner == "player":
		if is_summoned:
			return Color(0.2, 0.6, 0.8)  # 召唤物偏青
		return Color(0.15, 0.5, 0.9)  # 玩家偏蓝
	return Color(0.85, 0.25, 0.15)  # 敌方红色

## 单位发光颜色
static func _get_unit_emission(owner: String, is_summoned: bool) -> Color:
	if owner == "player":
		if is_summoned:
			return Color(CyberStyle.ACCENT_CYAN.r, CyberStyle.ACCENT_CYAN.g, CyberStyle.ACCENT_CYAN.b)
		return Color(CyberStyle.NEON_BLUE.r, CyberStyle.NEON_BLUE.g, CyberStyle.NEON_BLUE.b)
	return Color(CyberStyle.NEON_RED.r, CyberStyle.NEON_RED.g, CyberStyle.NEON_RED.b)
