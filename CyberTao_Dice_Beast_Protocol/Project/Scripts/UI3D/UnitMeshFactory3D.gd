extends RefCounted
class_name UnitMeshFactory3D

## 3D 单位精灵工厂（v0.1.81 — 全单位程序化 BGA 宝可梦像素风格）
## 所有单位（玩家英雄/敌方/召唤）均使用程序化像素风格生成，无外部美术资源依赖
## 参考 BGA 宝可梦像素怪物设计：大头比例、粗体轮廓、鲜明配色、赛博朋克发光

const HP_BAR_WIDTH: float = 1.0
const HP_BAR_HEIGHT: float = 0.12
const HP_BAR_OFFSET_Y: float = 1.6

const SPRITE_PIXEL_SIZE: float = 0.009		# 统一世界单位/像素（128px × 0.009 ≈ 1.15 世界单位）
const SPRITE_Y: float = 0.65				# 精灵中心 Y

const RES: int = 128						# 纹理分辨率
const PX: int = 4							# 每逻辑像素占实际像素（128/4 = 32×32 逻辑网格）

# --- 纹理缓存（静态，跨实例共享）---
static var _tex_cache: Dictionary = {}		# key(String) -> ImageTexture
static var _cache_ready: bool = false

# ============================
#  绘图原语（逻辑像素级）
# ============================

## 绘制一个逻辑像素（PX×PX 实际像素块）
static func _px(img: Image, lx: int, ly: int, c: Color) -> void:
	for dy in range(PX):
		for dx in range(PX):
			var ax: int = lx * PX + dx
			var ay: int = ly * PX + dy
			if ax >= 0 and ax < RES and ay >= 0 and ay < RES:
				img.set_pixel(ax, ay, c)

## 填充逻辑矩形（含边界）
static func _fill_rect_l(img: Image, x1: int, y1: int, x2: int, y2: int, c: Color) -> void:
	for ly in range(y1, y2 + 1):
		for lx in range(x1, x2 + 1):
			_px(img, lx, ly, c)

## 填充逻辑椭圆
static func _fill_ellipse_l(img: Image, cx: int, cy: int, rx: int, ry: int, c: Color) -> void:
	for ly in range(cy - ry, cy + ry + 1):
		for lx in range(cx - rx, cx + rx + 1):
			var dx2: float = float(lx - cx) / float(max(rx, 1))
			var dy2: float = float(ly - cy) / float(max(ry, 1))
			if dx2 * dx2 + dy2 * dy2 <= 1.0:
				_px(img, lx, ly, c)

## 对已绘制的不透明区域添加 1 逻辑像素发光轮廓
static func _apply_glow(img: Image, glow_color: Color) -> void:
	# 扫描逻辑网格，找不透明→透明边界
	var grid_size: int = RES / PX
	var opaque: Array = []
	for _i in range(grid_size):
		var row: Array = []
		for _j in range(grid_size):
			row.append(false)
		opaque.append(row)
	# 标记不透明逻辑像素
	for ly in range(grid_size):
		for lx in range(grid_size):
			var sample_x: int = lx * PX + PX / 2
			var sample_y: int = ly * PX + PX / 2
			if sample_x < RES and sample_y < RES:
				if img.get_pixel(sample_x, sample_y).a > 0.5:
					opaque[ly][lx] = true
	# 在透明位置如果邻接不透明则绘制发光
	var dirs: Array = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for ly in range(grid_size):
		for lx in range(grid_size):
			if opaque[ly][lx]:
				continue
			var adjacent: bool = false
			for d in dirs:
				var nx: int = lx + d.x
				var ny: int = ly + d.y
				if nx >= 0 and nx < grid_size and ny >= 0 and ny < grid_size:
					if opaque[ny][nx]:
						adjacent = true
						break
			if adjacent:
				_px(img, lx, ly, Color(glow_color.r, glow_color.g, glow_color.b, 0.65))

## 创建空白画布
static func _new_canvas() -> Image:
	return Image.create(RES, RES, true, Image.FORMAT_RGBA8)

## 完成纹理：添加发光轮廓 + 创建 ImageTexture
static func _finalize(img: Image, glow_color: Color) -> ImageTexture:
	_apply_glow(img, glow_color)
	return ImageTexture.create_from_image(img)

# ============================
#  公开接口
# ============================

## 创建单位完整 3D 节点（精灵 + HP条）
static func create_unit_node(unit: Dictionary, cell: Vector2i, grid_size: int = 12) -> Node3D:
	_ensure_textures()
	var container: Node3D = Node3D.new()
	var uid: String = String(unit.get("id", "unknown"))
	container.name = "Unit_" + uid
	var world_pos: Vector3 = GridMapper3D.cell_to_world(cell, grid_size)
	container.position = Vector3(world_pos.x, 0.0, world_pos.z)
	var body: Sprite3D = _create_body_sprite(unit)
	container.add_child(body)
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
#  内部创建方法
# ============================

## 创建精灵主体
static func _create_body_sprite(unit: Dictionary) -> Sprite3D:
	var sprite: Sprite3D = Sprite3D.new()
	sprite.name = "Body"
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.double_sided = true
	sprite.no_depth_test = false
	sprite.modulate = Color(1, 1, 1, 1)
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.25
	sprite.pixel_size = SPRITE_PIXEL_SIZE
	sprite.position.y = SPRITE_Y
	var owner_str: String = String(unit.get("owner", ""))
	var is_player: bool = owner_str == "player"
	var tags: Array = unit.get("tags", [])
	var is_summoned: bool = tags.has("summoned")
	if is_player and not is_summoned:
		sprite.texture = _tex_cache.get("player", null)
	elif is_summoned:
		sprite.texture = _tex_cache.get("summoned", null)
	else:
		# 根据 encounter_id 获取对应敌方纹理
		var enc_id: String = String(unit.get("encounter_id", ""))
		if enc_id != "":
			sprite.texture = _get_enemy_tex(enc_id)
		else:
			sprite.texture = _tex_cache.get("enemy_default", null)
	# 兜底：防止纹理为空导致黑色不可见
	if sprite.texture == null:
		sprite.texture = _gen_enemy_default()
	return sprite

## 创建 HP 条
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

# ============================
#  纹理缓存管理
# ============================

static func _ensure_textures() -> void:
	if _cache_ready:
		return
	_cache_ready = true
	_tex_cache["player"] = _gen_player_hero()
	_tex_cache["summoned"] = _gen_summoned_ally()
	_tex_cache["enemy_default"] = _gen_enemy_default()

static func _get_enemy_tex(encounter_id: String) -> ImageTexture:
	var key: String = "enemy_" + encounter_id
	if _tex_cache.has(key):
		return _tex_cache[key] as ImageTexture
	var tex: ImageTexture = _gen_enemy_by_id(encounter_id)
	_tex_cache[key] = tex
	return tex

static func _gen_enemy_by_id(encounter_id: String) -> ImageTexture:
	match encounter_id:
		"encounter_01":
			return _gen_enc01_sentinel()
		"encounter_02":
			return _gen_enc02_ghost()
		"encounter_03":
			return _gen_enc03_crawler()
		"encounter_04":
			return _gen_enc04_hunter()
		"encounter_05":
			return _gen_enc05_phantom()
		"encounter_06":
			return _gen_enc06_splitter()
		"encounter_07":
			return _gen_enc07_shaman()
		"encounter_boss_01":
			return _gen_boss_zero()
	return _gen_enemy_default()

# ============================
#  程序化像素生物生成器
# ============================

# --- 玩家英雄：刀盾狗（赛博朋克犬战士）---
static func _gen_player_hero() -> ImageTexture:
	var img: Image = _new_canvas()
	var body: Color = Color(0.18, 0.45, 0.85)
	var body_hi: Color = Color(0.3, 0.6, 1.0)
	var dark: Color = Color(0.1, 0.25, 0.55)
	var eye: Color = Color(0.0, 1.0, 1.0)
	var blade: Color = Color(0.8, 0.88, 0.95)
	var shield: Color = Color(0.15, 0.3, 0.6)
	var shield_edge: Color = Color(0.0, 0.8, 1.0)
	# 耳朵（三角）
	_px(img, 11, 2, dark); _px(img, 12, 2, body); _px(img, 12, 3, body)
	_px(img, 20, 2, dark); _px(img, 19, 2, body); _px(img, 19, 3, body)
	# 头部（大圆脑袋 — BGA风格大头比例）
	_fill_ellipse_l(img, 16, 7, 5, 4, body)
	_fill_ellipse_l(img, 16, 7, 4, 3, body_hi)
	# 眼睛（亮色大眼）
	_fill_rect_l(img, 13, 6, 14, 7, eye)
	_fill_rect_l(img, 18, 6, 19, 7, eye)
	_px(img, 14, 6, Color.WHITE); _px(img, 19, 6, Color.WHITE)
	# 鼻子/口
	_px(img, 16, 9, dark)
	_fill_rect_l(img, 15, 10, 17, 10, dark)
	# 身体（躯干）
	_fill_rect_l(img, 12, 12, 19, 20, body)
	_fill_rect_l(img, 13, 12, 18, 19, body_hi)
	# 护甲纹路
	_fill_rect_l(img, 12, 14, 12, 18, dark)
	_fill_rect_l(img, 19, 14, 19, 18, dark)
	# 盾牌（左手）
	_fill_rect_l(img, 8, 11, 11, 18, shield)
	_fill_rect_l(img, 8, 11, 8, 18, shield_edge)
	_fill_rect_l(img, 8, 11, 11, 11, shield_edge)
	_px(img, 10, 14, shield_edge); _px(img, 10, 15, shield_edge)
	# 刀刃（右手）
	_fill_rect_l(img, 21, 6, 22, 17, blade)
	_fill_rect_l(img, 21, 4, 22, 5, Color.WHITE)
	_px(img, 20, 12, dark); _px(img, 20, 13, dark)
	# 腿部
	_fill_rect_l(img, 13, 21, 14, 24, body)
	_fill_rect_l(img, 17, 21, 18, 24, body)
	# 脚部
	_fill_rect_l(img, 12, 25, 15, 25, dark)
	_fill_rect_l(img, 16, 25, 19, 25, dark)
	return _finalize(img, Color(0.2, 0.6, 1.0))

# --- 召唤伙伴：赛博小精灵（小型青色飞行伙伴）---
static func _gen_summoned_ally() -> ImageTexture:
	var img: Image = _new_canvas()
	var body: Color = Color(0.15, 0.65, 0.85)
	var hi: Color = Color(0.3, 0.85, 1.0)
	var eye: Color = Color(1.0, 1.0, 1.0)
	# 头/身一体（圆润小身体）
	_fill_ellipse_l(img, 16, 14, 5, 6, body)
	_fill_ellipse_l(img, 16, 13, 4, 4, hi)
	# 眼睛
	_fill_rect_l(img, 14, 12, 15, 13, eye)
	_fill_rect_l(img, 17, 12, 18, 13, eye)
	_px(img, 15, 12, Color(0, 0.8, 1.0)); _px(img, 18, 12, Color(0, 0.8, 1.0))
	# 天线/角
	_px(img, 16, 7, hi); _px(img, 16, 8, hi); _px(img, 15, 6, Color(0, 1, 1))
	_px(img, 17, 6, Color(0, 1, 1))
	# 小翅膀
	_fill_rect_l(img, 9, 12, 11, 14, Color(body.r, body.g, body.b, 0.7))
	_fill_rect_l(img, 21, 12, 23, 14, Color(body.r, body.g, body.b, 0.7))
	# 小脚
	_px(img, 14, 20, body); _px(img, 18, 20, body)
	return _finalize(img, Color(0.2, 0.8, 1.0))

# --- 默认敌方（无特定ID时的回退：红色菱形生物）---
static func _gen_enemy_default() -> ImageTexture:
	var img: Image = _new_canvas()
	var body: Color = Color(0.7, 0.15, 0.1)
	var hi: Color = Color(1.0, 0.3, 0.15)
	var eye: Color = Color(1.0, 0.9, 0.2)
	_fill_ellipse_l(img, 16, 14, 6, 7, body)
	_fill_ellipse_l(img, 16, 13, 4, 5, hi)
	_fill_rect_l(img, 14, 11, 15, 12, eye)
	_fill_rect_l(img, 17, 11, 18, 12, eye)
	_fill_rect_l(img, 13, 21, 14, 23, body)
	_fill_rect_l(img, 18, 21, 19, 23, body)
	return _finalize(img, Color(1.0, 0.3, 0.2))

# --- encounter_01 异常哨兵：红色方形机器人，天线+方形头 ---
static func _gen_enc01_sentinel() -> ImageTexture:
	var img: Image = _new_canvas()
	var body: Color = Color(0.65, 0.12, 0.1)
	var hi: Color = Color(0.9, 0.25, 0.15)
	var metal: Color = Color(0.45, 0.45, 0.5)
	var eye: Color = Color(1.0, 0.9, 0.1)
	# 天线
	_px(img, 16, 2, metal); _px(img, 16, 3, metal); _px(img, 16, 4, Color(1, 0.2, 0.1))
	# 方头
	_fill_rect_l(img, 12, 5, 20, 11, body)
	_fill_rect_l(img, 13, 6, 19, 10, hi)
	# 眼部视窗
	_fill_rect_l(img, 13, 7, 15, 9, Color(0.1, 0.1, 0.15))
	_fill_rect_l(img, 17, 7, 19, 9, Color(0.1, 0.1, 0.15))
	_px(img, 14, 8, eye); _px(img, 18, 8, eye)
	# 躯干
	_fill_rect_l(img, 13, 12, 19, 20, metal)
	_fill_rect_l(img, 14, 13, 18, 19, body)
	# 胸甲标记
	_fill_rect_l(img, 15, 14, 17, 16, eye)
	# 手臂
	_fill_rect_l(img, 10, 13, 12, 18, metal)
	_fill_rect_l(img, 20, 13, 22, 18, metal)
	# 腿
	_fill_rect_l(img, 13, 21, 15, 25, metal)
	_fill_rect_l(img, 17, 21, 19, 25, metal)
	return _finalize(img, Color(1.0, 0.2, 0.15))

# --- encounter_02 赛博游魂：紫色飘浮幽灵，无腿 ---
static func _gen_enc02_ghost() -> ImageTexture:
	var img: Image = _new_canvas()
	var body: Color = Color(0.4, 0.15, 0.65)
	var hi: Color = Color(0.6, 0.3, 0.9)
	var glow: Color = Color(0.7, 0.4, 1.0)
	var eye: Color = Color(1.0, 0.3, 0.9)
	# 头（大圆）
	_fill_ellipse_l(img, 16, 9, 6, 5, body)
	_fill_ellipse_l(img, 16, 8, 5, 4, hi)
	# 眼睛（诡异斜眼）
	_fill_rect_l(img, 13, 8, 14, 9, eye)
	_fill_rect_l(img, 18, 8, 19, 9, eye)
	_px(img, 13, 8, Color.WHITE); _px(img, 18, 8, Color.WHITE)
	# 嘴
	_fill_rect_l(img, 14, 11, 18, 11, Color(0.2, 0.05, 0.35))
	# 飘浮身体（逐渐变窄变透明）
	_fill_rect_l(img, 12, 14, 20, 17, Color(body.r, body.g, body.b, 0.85))
	_fill_rect_l(img, 13, 18, 19, 20, Color(body.r, body.g, body.b, 0.6))
	_fill_rect_l(img, 14, 21, 18, 23, Color(body.r, body.g, body.b, 0.35))
	_fill_rect_l(img, 15, 24, 17, 25, Color(body.r, body.g, body.b, 0.15))
	# 飘浮手臂
	_fill_rect_l(img, 9, 13, 11, 15, Color(glow.r, glow.g, glow.b, 0.6))
	_fill_rect_l(img, 21, 13, 23, 15, Color(glow.r, glow.g, glow.b, 0.6))
	return _finalize(img, Color(0.6, 0.2, 1.0))

# --- encounter_03 暗网爬虫：绿色多腿蜘蛛型 ---
static func _gen_enc03_crawler() -> ImageTexture:
	var img: Image = _new_canvas()
	var body: Color = Color(0.08, 0.55, 0.2)
	var hi: Color = Color(0.15, 0.75, 0.35)
	var dark: Color = Color(0.04, 0.3, 0.1)
	var eye: Color = Color(1.0, 0.2, 0.2)
	# 身体（扁椭圆）
	_fill_ellipse_l(img, 16, 14, 7, 4, body)
	_fill_ellipse_l(img, 16, 13, 5, 3, hi)
	# 头部（小圆突出）
	_fill_ellipse_l(img, 16, 9, 3, 2, body)
	_fill_ellipse_l(img, 16, 9, 2, 1, hi)
	# 眼睛（多眼）
	_px(img, 14, 8, eye); _px(img, 18, 8, eye)
	_px(img, 15, 9, eye); _px(img, 17, 9, eye)
	# 腿（4对）
	for pair in [[8, 11], [7, 14], [8, 17], [10, 19]]:
		_px(img, pair[0], pair[1], dark); _px(img, pair[0] - 1, pair[1] + 1, dark)
		var mirror_x: int = 31 - pair[0]
		_px(img, mirror_x, pair[1], dark); _px(img, mirror_x + 1, pair[1] + 1, dark)
	# 腹部纹路
	_px(img, 16, 14, dark); _px(img, 15, 15, dark); _px(img, 17, 15, dark)
	return _finalize(img, Color(0.1, 0.9, 0.3))

# --- encounter_04 脉冲猎手：橙色尖头猎食者，流线型 ---
static func _gen_enc04_hunter() -> ImageTexture:
	var img: Image = _new_canvas()
	var body: Color = Color(0.85, 0.45, 0.05)
	var hi: Color = Color(1.0, 0.65, 0.15)
	var dark: Color = Color(0.55, 0.25, 0.02)
	var eye: Color = Color(1.0, 1.0, 0.0)
	# 尖头（三角形顶部）
	_px(img, 16, 3, hi)
	_fill_rect_l(img, 15, 4, 17, 4, hi)
	_fill_rect_l(img, 14, 5, 18, 5, body)
	# 头部
	_fill_rect_l(img, 13, 6, 19, 10, body)
	_fill_rect_l(img, 14, 7, 18, 9, hi)
	# 锐利眼睛
	_fill_rect_l(img, 14, 7, 15, 8, eye)
	_fill_rect_l(img, 17, 7, 18, 8, eye)
	_px(img, 15, 7, Color(1, 0.5, 0)); _px(img, 17, 7, Color(1, 0.5, 0))
	# 流线型身体
	_fill_rect_l(img, 12, 11, 20, 18, body)
	_fill_rect_l(img, 13, 12, 19, 17, hi)
	# 速度纹路
	_fill_rect_l(img, 13, 13, 13, 16, dark)
	_fill_rect_l(img, 19, 13, 19, 16, dark)
	# 利爪手臂
	_fill_rect_l(img, 9, 12, 11, 14, dark)
	_px(img, 9, 15, eye)
	_fill_rect_l(img, 21, 12, 23, 14, dark)
	_px(img, 23, 15, eye)
	# 腿
	_fill_rect_l(img, 13, 19, 14, 23, body)
	_fill_rect_l(img, 18, 19, 19, 23, body)
	_px(img, 12, 24, dark); _px(img, 15, 24, dark)
	_px(img, 17, 24, dark); _px(img, 20, 24, dark)
	return _finalize(img, Color(1.0, 0.6, 0.1))

# --- encounter_05 数据幽灵：灰蓝色兜帽幽影 ---
static func _gen_enc05_phantom() -> ImageTexture:
	var img: Image = _new_canvas()
	var body: Color = Color(0.3, 0.35, 0.55)
	var hi: Color = Color(0.45, 0.5, 0.7)
	var hood: Color = Color(0.2, 0.22, 0.38)
	var eye: Color = Color(0.4, 0.7, 1.0)
	# 兜帽
	_fill_ellipse_l(img, 16, 8, 6, 5, hood)
	_fill_rect_l(img, 10, 8, 22, 13, hood)
	# 面部阴影区
	_fill_ellipse_l(img, 16, 9, 4, 3, Color(0.08, 0.08, 0.15))
	# 幽灵眼
	_px(img, 14, 9, eye); _px(img, 18, 9, eye)
	_px(img, 14, 10, eye); _px(img, 18, 10, eye)
	# 身体（斗篷）
	_fill_rect_l(img, 11, 14, 21, 21, body)
	_fill_rect_l(img, 12, 15, 20, 20, hi)
	# 斗篷底部渐隐
	_fill_rect_l(img, 12, 22, 20, 23, Color(body.r, body.g, body.b, 0.6))
	_fill_rect_l(img, 13, 24, 19, 25, Color(body.r, body.g, body.b, 0.3))
	# 手臂（斗篷袖）
	_fill_rect_l(img, 8, 15, 10, 19, hood)
	_fill_rect_l(img, 22, 15, 24, 19, hood)
	return _finalize(img, Color(0.4, 0.5, 0.8))

# --- encounter_06 量子分裂体：紫色多面晶体生物 ---
static func _gen_enc06_splitter() -> ImageTexture:
	var img: Image = _new_canvas()
	var body: Color = Color(0.5, 0.15, 0.75)
	var hi: Color = Color(0.7, 0.35, 1.0)
	var core: Color = Color(0.9, 0.5, 1.0)
	var eye: Color = Color(1.0, 0.8, 1.0)
	# 顶部晶体尖
	_px(img, 16, 3, hi)
	_fill_rect_l(img, 15, 4, 17, 5, hi)
	# 上半晶体（菱形扩展）
	_fill_rect_l(img, 13, 6, 19, 7, body)
	_fill_rect_l(img, 11, 8, 21, 11, body)
	_fill_rect_l(img, 12, 9, 20, 10, hi)
	# 核心发光
	_fill_rect_l(img, 14, 12, 18, 15, core)
	_fill_rect_l(img, 15, 13, 17, 14, eye)
	# 下半晶体
	_fill_rect_l(img, 11, 12, 21, 18, body)
	_fill_rect_l(img, 12, 13, 20, 17, hi)
	# 已绘核心覆盖回来
	_fill_rect_l(img, 14, 12, 18, 15, core)
	_fill_rect_l(img, 15, 13, 17, 14, eye)
	# 底部收窄
	_fill_rect_l(img, 13, 19, 19, 21, body)
	_fill_rect_l(img, 14, 22, 18, 23, body)
	_fill_rect_l(img, 15, 24, 17, 25, hi)
	# 侧面小晶体碎片
	_px(img, 8, 12, hi); _px(img, 9, 11, hi); _px(img, 9, 13, body)
	_px(img, 24, 12, hi); _px(img, 23, 11, hi); _px(img, 23, 13, body)
	return _finalize(img, Color(0.7, 0.2, 1.0))

# --- encounter_07 赛博巫医：绿色兜帽治疗者+法杖 ---
static func _gen_enc07_shaman() -> ImageTexture:
	var img: Image = _new_canvas()
	var robe: Color = Color(0.1, 0.55, 0.25)
	var robe_hi: Color = Color(0.2, 0.75, 0.4)
	var hood: Color = Color(0.06, 0.35, 0.15)
	var eye: Color = Color(0.2, 1.0, 0.5)
	var staff: Color = Color(0.5, 0.35, 0.2)
	var gem: Color = Color(0.2, 1.0, 0.4)
	# 兜帽
	_fill_ellipse_l(img, 16, 8, 5, 5, hood)
	# 面部
	_fill_ellipse_l(img, 16, 9, 3, 3, Color(0.06, 0.15, 0.08))
	_px(img, 14, 9, eye); _px(img, 18, 9, eye)
	# 长袍身体
	_fill_rect_l(img, 12, 13, 20, 22, robe)
	_fill_rect_l(img, 13, 14, 19, 21, robe_hi)
	# 袍底
	_fill_rect_l(img, 11, 23, 21, 25, robe)
	# 符文标记
	_px(img, 16, 16, gem); _px(img, 15, 17, gem); _px(img, 17, 17, gem); _px(img, 16, 18, gem)
	# 法杖（右手）
	_fill_rect_l(img, 23, 6, 23, 23, staff)
	_fill_rect_l(img, 22, 5, 24, 5, gem)
	_px(img, 23, 4, Color(0.5, 1.0, 0.6))
	# 袖子
	_fill_rect_l(img, 9, 14, 11, 17, hood)
	_fill_rect_l(img, 21, 14, 22, 17, hood)
	return _finalize(img, Color(0.2, 1.0, 0.4))

# --- Boss 零号协议：大型暗红赛博实体，角+铠甲+发光核心 ---
static func _gen_boss_zero() -> ImageTexture:
	var img: Image = _new_canvas()
	var body: Color = Color(0.5, 0.08, 0.06)
	var hi: Color = Color(0.75, 0.15, 0.1)
	var armor: Color = Color(0.3, 0.3, 0.35)
	var eye: Color = Color(1.0, 0.85, 0.1)
	var core: Color = Color(1.0, 0.2, 0.1)
	# 角（左右）
	_px(img, 10, 1, hi); _px(img, 11, 2, hi); _px(img, 11, 3, body)
	_px(img, 22, 1, hi); _px(img, 21, 2, hi); _px(img, 21, 3, body)
	# 大头
	_fill_ellipse_l(img, 16, 7, 6, 5, body)
	_fill_ellipse_l(img, 16, 7, 5, 4, hi)
	# 头顶装甲
	_fill_rect_l(img, 12, 4, 20, 5, armor)
	# 眼睛（大且凶）
	_fill_rect_l(img, 12, 6, 14, 8, eye)
	_fill_rect_l(img, 18, 6, 20, 8, eye)
	_px(img, 14, 6, Color.RED); _px(img, 18, 6, Color.RED)
	# 嘴
	_fill_rect_l(img, 14, 10, 18, 10, Color(0.2, 0.02, 0.02))
	_px(img, 13, 10, eye); _px(img, 19, 10, eye)
	# 宽厚躯干
	_fill_rect_l(img, 10, 12, 22, 21, body)
	_fill_rect_l(img, 11, 13, 21, 20, hi)
	# 胸甲
	_fill_rect_l(img, 13, 13, 19, 17, armor)
	# 核心发光
	_fill_rect_l(img, 15, 14, 17, 16, core)
	_px(img, 16, 15, Color(1, 0.9, 0.4))
	# 肩甲
	_fill_rect_l(img, 7, 12, 9, 16, armor)
	_fill_rect_l(img, 23, 12, 25, 16, armor)
	# 手臂
	_fill_rect_l(img, 7, 17, 9, 20, body)
	_fill_rect_l(img, 23, 17, 25, 20, body)
	# 腿
	_fill_rect_l(img, 11, 22, 14, 26, body)
	_fill_rect_l(img, 18, 22, 21, 26, body)
	_fill_rect_l(img, 10, 27, 15, 27, armor)
	_fill_rect_l(img, 17, 27, 22, 27, armor)
	return _finalize(img, Color(1.0, 0.15, 0.1))
