extends RefCounted
class_name UnitMeshFactory3D

## 3D 单位精灵工厂（v0.1.77 — billboard Sprite3D 替代几何体）
## 玩家单位：使用现有 4 方向 spritesheet（刀盾向X走.png），支持帧动画
## 敌方单位：程序化生成赛博朋克风格像素图标（红色菱形）
## 召唤伙伴：程序化生成青色系像素图标（圆形）

const HP_BAR_WIDTH: float = 1.0
const HP_BAR_HEIGHT: float = 0.12
const HP_BAR_OFFSET_Y: float = 1.6

const PLAYER_PIXEL_SIZE: float = 0.002		# 玩家精灵：世界单位/像素
const ICON_PIXEL_SIZE: float = 0.01			# 敌方/召唤图标：世界单位/像素
const SPRITE_Y_PLAYER: float = 0.65			# 玩家精灵中心 Y（底部贴地）
const SPRITE_Y_ICON: float = 0.64			# 图标中心 Y

# --- 精灵帧参数（与 PlayerSpriteAnimator 对齐）---
const COLUMNS: int = 4
const TOTAL_FRAMES: int = 15
const ICON_RESOLUTION: int = 128			# 程序化图标分辨率

# --- 纹理缓存（静态，跨实例共享）---
static var _player_textures: Dictionary = {}		# dir(String) -> Texture2D
static var _player_frame_sizes: Dictionary = {}		# dir(String) -> Vector2
static var _enemy_tex: Texture2D = null
static var _summoned_tex: Texture2D = null
static var _textures_ready: bool = false

# ============================
#  纹理加载 / 程序化生成
# ============================

static func _ensure_textures() -> void:
	if _textures_ready:
		return
	_textures_ready = true
	# 玩家 4 方向 spritesheet
	var paths: Dictionary = {
		"up": "res://Assets/Tiles/刀盾向上走.png",
		"down": "res://Assets/Tiles/刀盾向下走.png",
		"left": "res://Assets/Tiles/刀盾向左走.png",
		"right": "res://Assets/Tiles/刀盾向右走.png",
	}
	for dir_key in paths.keys():
		var tex = load(paths[dir_key])
		if tex != null:
			_player_textures[dir_key] = tex
			var fw: float = float(tex.get_width()) / float(COLUMNS)
			var fh: float = float(tex.get_height()) / float(COLUMNS)
			_player_frame_sizes[dir_key] = Vector2(fw, fh)
	# 敌方：红色菱形图标
	_enemy_tex = _generate_icon(
		Color(0.7, 0.1, 0.08), Color(1.0, 0.25, 0.12), "diamond")
	# 召唤伙伴：青色圆形图标
	_summoned_tex = _generate_icon(
		Color(0.1, 0.45, 0.6), Color(0.2, 0.75, 1.0), "circle")

## 程序化生成赛博朋克风格图标纹理
static func _generate_icon(body_color: Color, glow_color: Color, shape: String) -> ImageTexture:
	var s: int = ICON_RESOLUTION
	var img: Image = Image.create(s, s, true, Image.FORMAT_RGBA8)
	var center: float = float(s) * 0.5
	var outer_r: float = float(s) * 0.5 - 4.0
	var glow_w: float = 6.0
	var inner_r: float = outer_r - glow_w
	# 内部"核心"高亮
	var core_r: float = outer_r * 0.25
	var core_color: Color = Color(
		minf(glow_color.r + 0.3, 1.0),
		minf(glow_color.g + 0.3, 1.0),
		minf(glow_color.b + 0.3, 1.0), 1.0)
	for y in range(s):
		for x in range(s):
			var dx: float = float(x) - center
			var dy: float = float(y) - center
			var dist: float = 0.0
			if shape == "diamond":
				dist = absf(dx) + absf(dy)
			else:
				dist = sqrt(dx * dx + dy * dy)
			if dist <= core_r:
				# 核心高亮区域
				var t: float = dist / core_r
				var col: Color = core_color.lerp(body_color, t * t)
				col.a = 1.0
				img.set_pixel(x, y, col)
			elif dist <= inner_r:
				# 主体区域
				img.set_pixel(x, y, Color(body_color.r, body_color.g, body_color.b, 1.0))
			elif dist <= outer_r:
				# 发光边缘
				var t: float = (dist - inner_r) / glow_w
				var col: Color = body_color.lerp(glow_color, t)
				col.a = 1.0
				img.set_pixel(x, y, col)
			elif dist <= outer_r + glow_w:
				# 外发光渐隐
				var t: float = 1.0 - (dist - outer_r) / glow_w
				img.set_pixel(x, y, Color(glow_color.r, glow_color.g, glow_color.b, t * 0.5))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)

# ============================
#  公开接口
# ============================

## 创建单位的完整 3D 节点（精灵 + HP条），返回 Node3D 容器
static func create_unit_node(unit: Dictionary, cell: Vector2i, grid_size: int = 12) -> Node3D:
	_ensure_textures()
	var container: Node3D = Node3D.new()
	var uid: String = String(unit.get("id", "unknown"))
	container.name = "Unit_" + uid
	var world_pos: Vector3 = GridMapper3D.cell_to_world(cell, grid_size)
	container.position = Vector3(world_pos.x, 0.0, world_pos.z)
	# 精灵主体
	var body: Sprite3D = _create_body_sprite(unit)
	container.add_child(body)
	# HP 条
	var hp_bar: MeshInstance3D = _create_hp_bar(unit)
	container.add_child(hp_bar)
	return container

## 更新单位位置
static func update_unit_position(node: Node3D, world_pos: Vector3) -> void:
	node.position = world_pos

## 更新 HP 条显示
static func update_hp_bar(node: Node3D, hp: int, max_hp: int, is_player: bool) -> void:
	var hp_bar: MeshInstance3D = node.get_node_or_null("HPBar")
	if hp_bar == null:
		return
	var ratio: float = float(hp) / float(max_hp) if max_hp > 0 else 1.0
	hp_bar.scale.x = ratio
	hp_bar.position.x = -HP_BAR_WIDTH * 0.5 * (1.0 - ratio)
	var mat: StandardMaterial3D = hp_bar.material_override as StandardMaterial3D
	if mat:
		if is_player:
			mat.albedo_color = CyberStyle.HP_PLAYER if ratio > 0.3 else CyberStyle.HP_PLAYER_LOW
		else:
			mat.albedo_color = CyberStyle.HP_ENEMY if ratio > 0.3 else CyberStyle.HP_ENEMY_LOW
		mat.emission = mat.albedo_color

# ============================
#  精灵动画接口（BoardView3D 调用）
# ============================

## 判断节点是否为 spritesheet 精灵（玩家英雄）
static func is_spritesheet_unit(node: Node3D) -> bool:
	var body: Sprite3D = node.get_node_or_null("Body") as Sprite3D
	if body == null:
		return false
	return body.region_enabled

## 设置精灵朝向（切换 spritesheet 纹理）
static func set_sprite_direction(node: Node3D, dir: String) -> void:
	var body: Sprite3D = node.get_node_or_null("Body") as Sprite3D
	if body == null or not body.region_enabled:
		return
	var tex: Texture2D = _player_textures.get(dir, null)
	if tex == null:
		return
	body.texture = tex

## 设置精灵帧索引（更新 region_rect）
static func set_sprite_frame(node: Node3D, dir: String, frame_index: int) -> void:
	var body: Sprite3D = node.get_node_or_null("Body") as Sprite3D
	if body == null or not body.region_enabled:
		return
	var fs: Vector2 = _player_frame_sizes.get(dir, Vector2(758, 649))
	var col: int = frame_index % COLUMNS
	var row: int = frame_index / COLUMNS
	body.region_rect = Rect2(float(col) * fs.x, float(row) * fs.y, fs.x, fs.y)

## 重置精灵到默认待机姿态（朝下，帧0）
static func reset_sprite_idle(node: Node3D) -> void:
	set_sprite_direction(node, "down")
	set_sprite_frame(node, "down", 0)

# ============================
#  内部创建方法
# ============================

## 创建精灵主体（Sprite3D billboard）
static func _create_body_sprite(unit: Dictionary) -> Sprite3D:
	var sprite: Sprite3D = Sprite3D.new()
	sprite.name = "Body"
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.double_sided = true
	sprite.no_depth_test = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.4
	var owner_str: String = String(unit.get("owner", ""))
	var is_player: bool = owner_str == "player"
	var tags: Array = unit.get("tags", [])
	var is_summoned: bool = tags.has("summoned")
	if is_player and not is_summoned:
		# 玩家英雄：使用 spritesheet
		sprite.pixel_size = PLAYER_PIXEL_SIZE
		sprite.position.y = SPRITE_Y_PLAYER
		var tex: Texture2D = _player_textures.get("down", null)
		if tex != null:
			sprite.texture = tex
			sprite.region_enabled = true
			var fs: Vector2 = _player_frame_sizes.get("down", Vector2(758, 649))
			sprite.region_rect = Rect2(0, 0, fs.x, fs.y)
		else:
			# 纹理加载失败 → 回退到程序化图标
			sprite.texture = _generate_icon(
				Color(0.15, 0.5, 0.9), Color(0.3, 0.6, 1.0), "circle")
			sprite.pixel_size = ICON_PIXEL_SIZE
	elif is_summoned:
		# 召唤伙伴：青色图标
		sprite.texture = _summoned_tex
		sprite.pixel_size = ICON_PIXEL_SIZE
		sprite.position.y = SPRITE_Y_ICON
	else:
		# 敌方单位：红色菱形图标
		sprite.texture = _enemy_tex
		sprite.pixel_size = ICON_PIXEL_SIZE
		sprite.position.y = SPRITE_Y_ICON
	return sprite

## 创建 HP 条（BoxMesh + billboard 材质）
static func _create_hp_bar(unit: Dictionary) -> MeshInstance3D:
	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	mesh_inst.name = "HPBar"
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(HP_BAR_WIDTH, HP_BAR_HEIGHT, 0.02)
	mesh_inst.mesh = box
	var owner_str: String = String(unit.get("owner", ""))
	var is_player: bool = owner_str == "player"
	var hp: int = int(unit.get("hp", 1))
	var max_hp: int = int(unit.get("max_hp", 1))
	var ratio: float = float(hp) / float(max_hp) if max_hp > 0 else 1.0
	var mat: StandardMaterial3D = StandardMaterial3D.new()
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
