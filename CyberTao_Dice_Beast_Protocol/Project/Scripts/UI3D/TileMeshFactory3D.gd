extends RefCounted
class_name TileMeshFactory3D

## 3D 格子网格工厂（v0.1.71）
## 负责为不同类型的棋盘格创建程序化 3D 网格（MeshInstance3D）
## 使用 BoxMesh + StandardMaterial3D，配色沿用 CyberStyle

const TILE_THICKNESS: float = 0.15		# 格子厚度（Y轴）
const TILE_GAP: float = 0.06			# 格子间缝隙
const HIGH_GROUND_LIFT: float = 0.4		# 高台额外抬高

## 创建单个格子的 MeshInstance3D（放置在 Y=0 平面上）
static func create_tile(tile_key: String, cell: Vector2i, grid_size: int = 12) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	var tile_size: float = GridMapper3D.CELL_SIZE - TILE_GAP
	box.size = Vector3(tile_size, TILE_THICKNESS, tile_size)
	mesh_inst.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = _get_tile_color(tile_key)
	mat.emission_enabled = true
	mat.emission = _get_emission_color(tile_key)
	mat.emission_energy_multiplier = _get_emission_energy(tile_key)
	mat.metallic = 0.1
	mat.roughness = 0.7
	mesh_inst.material_override = mat

	var world_pos: Vector3 = GridMapper3D.cell_to_world(cell, grid_size)
	var y_offset: float = -TILE_THICKNESS * 0.5
	if tile_key == "high_ground":
		y_offset += HIGH_GROUND_LIFT
	mesh_inst.position = Vector3(world_pos.x, y_offset, world_pos.z)
	mesh_inst.name = "Tile_%d_%d" % [cell.x, cell.y]
	return mesh_inst

## 创建高亮覆盖层（半透明薄片，叠在格子上方）
static func create_highlight(cell: Vector2i, color: Color, grid_size: int = 12) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	var tile_size: float = GridMapper3D.CELL_SIZE - TILE_GAP - 0.1
	box.size = Vector3(tile_size, 0.02, tile_size)
	mesh_inst.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	mat.no_depth_test = true
	mesh_inst.material_override = mat

	var world_pos: Vector3 = GridMapper3D.cell_to_world(cell, grid_size)
	mesh_inst.position = Vector3(world_pos.x, 0.05, world_pos.z)
	mesh_inst.name = "Highlight_%d_%d" % [cell.x, cell.y]
	return mesh_inst

## 根据 tile_key 获取主体颜色（与 IsoTileRenderer/_get_fill_color 对齐）
static func _get_tile_color(tile_key: String) -> Color:
	match tile_key:
		"normal_dark":
			return Color(0.06, 0.06, 0.12)
		"normal_light":
			return Color(0.09, 0.1, 0.18)
		"high_ground":
			return Color(0.25, 0.2, 0.08)
		"trap":
			return Color(0.25, 0.06, 0.05)
		"encounter":
			return Color(0.3, 0.15, 0.05)
		"heal":
			return Color(0.08, 0.15, 0.28)
		"shop":
			return Color(0.05, 0.22, 0.18)
		"chest":
			return Color(0.28, 0.22, 0.08)
		"item":
			return Color(0.06, 0.22, 0.1)
		"event":
			return Color(0.18, 0.1, 0.25)
		"portal":
			return Color(0.0, 0.2, 0.25)
	return Color(0.06, 0.06, 0.12)

## 发光颜色（与 CyberStyle 对齐）
static func _get_emission_color(tile_key: String) -> Color:
	match tile_key:
		"high_ground":
			return Color(CyberStyle.NEON_GOLD.r, CyberStyle.NEON_GOLD.g, CyberStyle.NEON_GOLD.b)
		"trap":
			return Color(CyberStyle.NEON_RED.r, CyberStyle.NEON_RED.g, CyberStyle.NEON_RED.b)
		"encounter":
			return Color(CyberStyle.ACCENT_ORANGE.r, CyberStyle.ACCENT_ORANGE.g, CyberStyle.ACCENT_ORANGE.b)
		"heal":
			return Color(CyberStyle.NEON_BLUE.r, CyberStyle.NEON_BLUE.g, CyberStyle.NEON_BLUE.b)
		"shop":
			return Color(CyberStyle.NEON_TEAL.r, CyberStyle.NEON_TEAL.g, CyberStyle.NEON_TEAL.b)
		"chest":
			return Color(CyberStyle.NEON_GOLD.r, CyberStyle.NEON_GOLD.g, CyberStyle.NEON_GOLD.b)
		"item":
			return Color(CyberStyle.NEON_GREEN.r, CyberStyle.NEON_GREEN.g, CyberStyle.NEON_GREEN.b)
		"event":
			return Color(CyberStyle.NEON_PURPLE.r, CyberStyle.NEON_PURPLE.g, CyberStyle.NEON_PURPLE.b)
		"portal":
			return Color(CyberStyle.ACCENT_CYAN.r, CyberStyle.ACCENT_CYAN.g, CyberStyle.ACCENT_CYAN.b)
	return Color(0.0, 0.02, 0.04)

## 发光强度
static func _get_emission_energy(tile_key: String) -> float:
	match tile_key:
		"normal_dark", "normal_light":
			return 0.05
		"high_ground", "chest":
			return 0.3
		"trap", "encounter":
			return 0.4
		"portal":
			return 0.5
	return 0.2
