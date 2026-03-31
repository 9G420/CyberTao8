extends RefCounted
class_name UnitRenderer

## 单位渲染器（v0.1.54 美化：赛博角色剪影 + 发光 + HP条 + 选中脉冲）
## 棋盘格内绘制迷你角色形象，替代旧版几何方框/三角形
## 颜色 100% 来自 CyberStyle

# --- 单位完整绘制 ---

static func draw_full_unit(c: CanvasItem, cell: Vector2i, cs: int, unit: Dictionary, is_selected: bool, pulse: float, idle_y: float, font: Font) -> void:
	var owner: String = String(unit.get("owner", "player"))
	var is_player: bool = owner == "player"
	var display_name: String = String(unit.get("display_name", ""))
	var hp: int = int(unit.get("hp", 1))
	var max_hp: int = int(unit.get("max_hp", 1))
	var hp_ratio: float = float(hp) / float(max_hp) if max_hp > 0 else 1.0

	var cx: float = float(cell.x * cs) + float(cs) * 0.5
	var cy: float = float(cell.y * cs) + float(cs) * 0.5 + idle_y
	var s: float = float(cs) / 72.0  # 基于 72px 格子大小的缩放因子

	if is_player:
		_draw_player_char(c, Vector2(cx, cy), s, display_name, pulse)
	else:
		_draw_enemy_char(c, Vector2(cx, cy), s, display_name, pulse)

	# HP 条
	_draw_hp_bar(c, Vector2(cell.x * cs + 8, cell.y * cs + cs - 12), cs - 16, hp_ratio, is_player)

	# 选中脉冲环
	if is_selected:
		_draw_selection(c, Vector2(cell.x * cs + 5, cell.y * cs + 5 + idle_y), Vector2(cs - 12, cs - 16), pulse)

# --- 玩家角色（迷你赛博战士剪影） ---

static func _draw_player_char(c: CanvasItem, center: Vector2, s: float, name: String, pulse: float) -> void:
	var col: Color = CyberStyle.HP_PLAYER
	var cyan: Color = CyberStyle.ACCENT_CYAN
	var ga: float = 0.25 + pulse * 0.12

	# 脚底光环
	c.draw_arc(center + Vector2(0, 22 * s), 12 * s, 0, TAU, 12, Color(cyan.r, cyan.g, cyan.b, 0.15 + pulse * 0.08), 1.5 * s)

	# 腿部
	c.draw_line(center + Vector2(-5 * s, 10 * s), center + Vector2(-7 * s, 22 * s), Color(col.r, col.g, col.b, 0.55), 2.0 * s)
	c.draw_line(center + Vector2(5 * s, 10 * s), center + Vector2(7 * s, 22 * s), Color(col.r, col.g, col.b, 0.55), 2.0 * s)

	# 躯干（小梯形）
	var body: PackedVector2Array = PackedVector2Array([
		center + Vector2(-8 * s, -8 * s), center + Vector2(8 * s, -8 * s),
		center + Vector2(6 * s, 12 * s), center + Vector2(-6 * s, 12 * s)])
	c.draw_colored_polygon(body, Color(col.r, col.g, col.b, ga))
	for i in range(4):
		c.draw_line(body[i], body[(i + 1) % 4], Color(col.r, col.g, col.b, 0.6), 1.5 * s)

	# 胸甲能量线
	c.draw_line(center + Vector2(-4 * s, -2 * s), center + Vector2(4 * s, -2 * s), Color(cyan.r, cyan.g, cyan.b, 0.4 + pulse * 0.2), 1.0 * s)

	# 左臂+盾
	c.draw_line(center + Vector2(-8 * s, -5 * s), center + Vector2(-14 * s, 3 * s), Color(col.r, col.g, col.b, 0.5), 1.8 * s)
	c.draw_arc(center + Vector2(-16 * s, 4 * s), 5 * s, 0, TAU, 8, Color(cyan.r, cyan.g, cyan.b, 0.5 + pulse * 0.15), 1.5 * s)

	# 右臂+刃
	c.draw_line(center + Vector2(8 * s, -5 * s), center + Vector2(14 * s, -2 * s), Color(col.r, col.g, col.b, 0.5), 1.8 * s)
	c.draw_line(center + Vector2(14 * s, -2 * s), center + Vector2(18 * s, -14 * s), Color(1.0, 0.9, 0.3, 0.6 + pulse * 0.2), 2.0 * s)

	# 头部（圆形+护目镜）
	var head: Vector2 = center + Vector2(0, -16 * s)
	c.draw_circle(head, 7 * s, Color(col.r, col.g, col.b, ga + 0.05))
	c.draw_arc(head, 7 * s, 0, TAU, 10, Color(col.r, col.g, col.b, 0.6), 1.5 * s)
	# V 型护目镜
	c.draw_line(head + Vector2(-4 * s, 0), head + Vector2(0, 2 * s), Color(cyan.r, cyan.g, cyan.b, 0.8), 1.5 * s)
	c.draw_line(head + Vector2(0, 2 * s), head + Vector2(4 * s, 0), Color(cyan.r, cyan.g, cyan.b, 0.8), 1.5 * s)

# --- 敌方角色（各敌方类型不同剪影） ---

static func _draw_enemy_char(c: CanvasItem, center: Vector2, s: float, name: String, pulse: float) -> void:
	var col: Color = CyberStyle.HP_ENEMY
	var ga: float = 0.25 + pulse * 0.1

	if "哨兵" in name:
		_draw_mini_sentinel(c, center, s, col, ga, pulse)
	elif "游魂" in name:
		_draw_mini_ghost(c, center, s, Color(0.7, 0.3, 1.0), ga, pulse)
	elif "爬虫" in name:
		_draw_mini_crawler(c, center, s, Color(0.4, 0.9, 0.3), ga, pulse)
	elif "猎手" in name:
		_draw_mini_hunter(c, center, s, Color(1.0, 0.5, 0.15), ga, pulse)
	elif "幽灵" in name:
		_draw_mini_phantom(c, center, s, Color(0.3, 0.6, 1.0), ga, pulse)
	elif "零号" in name or "BOSS" in name:
		_draw_mini_boss(c, center, s, col, ga, pulse)
	else:
		# 通用敌方
		_draw_mini_sentinel(c, center, s, col, ga, pulse)

# 迷你哨兵：方形身躯+扫描眼
static func _draw_mini_sentinel(c: CanvasItem, center: Vector2, s: float, col: Color, ga: float, pulse: float) -> void:
	var r: Rect2 = Rect2(center + Vector2(-9 * s, -8 * s), Vector2(18 * s, 22 * s))
	c.draw_rect(r, Color(col.r, col.g, col.b, ga), true)
	c.draw_rect(r, Color(col.r, col.g, col.b, 0.6), false, 1.5 * s)
	# 头
	c.draw_rect(Rect2(center + Vector2(-6 * s, -16 * s), Vector2(12 * s, 8 * s)), Color(col.r, col.g, col.b, ga + 0.05), true)
	# 扫描眼
	var ew: float = 8 * s * (0.7 + pulse * 0.3)
	c.draw_line(center + Vector2(-ew * 0.5, -12 * s), center + Vector2(ew * 0.5, -12 * s), Color(CyberStyle.ACCENT_ORANGE.r, CyberStyle.ACCENT_ORANGE.g, CyberStyle.ACCENT_ORANGE.b, 0.8), 2.0 * s)
	# 腿
	c.draw_line(center + Vector2(-5 * s, 14 * s), center + Vector2(-7 * s, 23 * s), Color(col.r, col.g, col.b, 0.45), 1.5 * s)
	c.draw_line(center + Vector2(5 * s, 14 * s), center + Vector2(7 * s, 23 * s), Color(col.r, col.g, col.b, 0.45), 1.5 * s)

# 迷你游魂：飘渺圆+尾焰
static func _draw_mini_ghost(c: CanvasItem, center: Vector2, s: float, col: Color, ga: float, pulse: float) -> void:
	c.draw_circle(center + Vector2(0, -3 * s), 10 * s, Color(col.r, col.g, col.b, ga))
	c.draw_arc(center + Vector2(0, -3 * s), 10 * s, 0, TAU, 10, Color(col.r, col.g, col.b, 0.5), 1.5 * s)
	# 双眼
	c.draw_circle(center + Vector2(-4 * s, -5 * s), 2 * s, Color(1.0, 0.3, 0.3, 0.7 + pulse * 0.2))
	c.draw_circle(center + Vector2(4 * s, -5 * s), 2 * s, Color(1.0, 0.3, 0.3, 0.7 + pulse * 0.2))
	# 尾焰
	for i in range(3):
		var ox: float = sin(float(i) * 1.5 + pulse * 3.0) * 4 * s
		c.draw_line(center + Vector2(ox, 7 * s + float(i) * 5 * s), center + Vector2(ox, 12 * s + float(i) * 5 * s), Color(col.r, col.g, col.b, 0.3 - float(i) * 0.08), 1.5 * s)

# 迷你爬虫：椭圆体+多足
static func _draw_mini_crawler(c: CanvasItem, center: Vector2, s: float, col: Color, ga: float, pulse: float) -> void:
	c.draw_circle(center, 9 * s, Color(col.r, col.g, col.b, ga))
	c.draw_arc(center, 9 * s, 0, TAU, 10, Color(col.r, col.g, col.b, 0.5), 1.5 * s)
	# 6足
	for i in range(3):
		var side: float = -1.0
		for j in range(2):
			var bx: float = side * 9 * s
			var by: float = (-5 + i * 5) * s
			c.draw_line(center + Vector2(bx, by), center + Vector2(bx + side * 8 * s, by + 4 * s), Color(col.r, col.g, col.b, 0.4), 1.0 * s)
			side = 1.0
	# 眼簇
	for i in range(3):
		c.draw_circle(center + Vector2((-3 + float(i) * 3) * s, -4 * s), 1.5 * s, Color(1.0, 0.2, 0.2, 0.6 + pulse * 0.2))

# 迷你猎手：纤细三角+枪
static func _draw_mini_hunter(c: CanvasItem, center: Vector2, s: float, col: Color, ga: float, pulse: float) -> void:
	var body: PackedVector2Array = PackedVector2Array([
		center + Vector2(0, -18 * s), center + Vector2(-7 * s, 12 * s), center + Vector2(7 * s, 12 * s)])
	c.draw_colored_polygon(body, Color(col.r, col.g, col.b, ga))
	for i in range(3):
		c.draw_line(body[i], body[(i + 1) % 3], Color(col.r, col.g, col.b, 0.6), 1.5 * s)
	# 单眼
	c.draw_circle(center + Vector2(0, -10 * s), 3 * s, Color(1.0, 0.8, 0.1, 0.7 + pulse * 0.2))
	# 枪
	c.draw_line(center + Vector2(7 * s, -4 * s), center + Vector2(16 * s, -10 * s), Color(col.r, col.g, col.b, 0.5 + pulse * 0.2), 2.0 * s)
	# 腿
	c.draw_line(center + Vector2(-4 * s, 12 * s), center + Vector2(-6 * s, 22 * s), Color(col.r, col.g, col.b, 0.4), 1.5 * s)
	c.draw_line(center + Vector2(4 * s, 12 * s), center + Vector2(6 * s, 22 * s), Color(col.r, col.g, col.b, 0.4), 1.5 * s)

# 迷你幽灵：菱形+数据线
static func _draw_mini_phantom(c: CanvasItem, center: Vector2, s: float, col: Color, ga: float, pulse: float) -> void:
	var diamond: PackedVector2Array = PackedVector2Array([
		center + Vector2(0, -14 * s), center + Vector2(10 * s, 0),
		center + Vector2(0, 14 * s), center + Vector2(-10 * s, 0)])
	c.draw_colored_polygon(diamond, Color(col.r, col.g, col.b, ga))
	for i in range(4):
		c.draw_line(diamond[i], diamond[(i + 1) % 4], Color(col.r, col.g, col.b, 0.5 + pulse * 0.15), 1.5 * s)
	# 数据辐射线
	for i in range(4):
		var angle: float = float(i) * TAU / 4.0 + pulse * 0.3
		var r: float = 16 * s
		c.draw_line(center, center + Vector2(cos(angle) * r, sin(angle) * r * 0.7), Color(col.r, col.g, col.b, 0.1), 1.0 * s)
	# 双眼
	c.draw_circle(center + Vector2(-3 * s, -3 * s), 2 * s, Color(1.0, 1.0, 1.0, 0.6))
	c.draw_circle(center + Vector2(3 * s, -3 * s), 2 * s, Color(1.0, 1.0, 1.0, 0.6))

# 迷你Boss：大型方体+冠+三眼
static func _draw_mini_boss(c: CanvasItem, center: Vector2, s: float, col: Color, ga: float, pulse: float) -> void:
	var gold: Color = CyberStyle.NEON_GOLD
	# 大身躯
	var r: Rect2 = Rect2(center + Vector2(-12 * s, -10 * s), Vector2(24 * s, 28 * s))
	c.draw_rect(r, Color(col.r, col.g, col.b, ga + 0.05), true)
	c.draw_rect(r, Color(col.r, col.g, col.b, 0.7), false, 2.0 * s)
	# 肩甲
	c.draw_rect(Rect2(center + Vector2(-18 * s, -12 * s), Vector2(6 * s, 10 * s)), Color(col.r, col.g, col.b, 0.4), true)
	c.draw_rect(Rect2(center + Vector2(12 * s, -12 * s), Vector2(6 * s, 10 * s)), Color(col.r, col.g, col.b, 0.4), true)
	# 头+冠
	c.draw_circle(center + Vector2(0, -18 * s), 7 * s, Color(col.r, col.g, col.b, ga + 0.08))
	c.draw_arc(center + Vector2(0, -18 * s), 7 * s, 0, TAU, 10, Color(col.r, col.g, col.b, 0.6), 1.5 * s)
	c.draw_line(center + Vector2(-5 * s, -23 * s), center + Vector2(0, -30 * s), Color(gold.r, gold.g, gold.b, 0.5), 1.5 * s)
	c.draw_line(center + Vector2(5 * s, -23 * s), center + Vector2(0, -30 * s), Color(gold.r, gold.g, gold.b, 0.5), 1.5 * s)
	# 三眼
	c.draw_circle(center + Vector2(-3 * s, -19 * s), 1.5 * s, Color(gold.r, gold.g, gold.b, 0.8))
	c.draw_circle(center + Vector2(3 * s, -19 * s), 1.5 * s, Color(gold.r, gold.g, gold.b, 0.8))
	c.draw_circle(center + Vector2(0, -24 * s), 1.0 * s, Color(1.0, 0.1, 0.1, 0.7 + pulse * 0.2))
	# 腿
	c.draw_line(center + Vector2(-6 * s, 18 * s), center + Vector2(-8 * s, 26 * s), Color(col.r, col.g, col.b, 0.45), 2.0 * s)
	c.draw_line(center + Vector2(6 * s, 18 * s), center + Vector2(8 * s, 26 * s), Color(col.r, col.g, col.b, 0.45), 2.0 * s)

# --- HP 条：薄条 + 绿→黄→红渐变 ---

static func _draw_hp_bar(c: CanvasItem, pos: Vector2, width: float, ratio: float, is_player: bool) -> void:
	var bar_h: float = 4.0
	c.draw_rect(Rect2(pos, Vector2(width, bar_h)), Color(0.15, 0.15, 0.2, 0.8), true)
	if ratio > 0.0:
		var fill_w: float = width * clampf(ratio, 0.0, 1.0)
		var fill_col: Color
		if ratio > 0.6:
			fill_col = CyberStyle.HP_PLAYER if is_player else CyberStyle.HP_ENEMY
		elif ratio > 0.3:
			fill_col = CyberStyle.TEXT_TITLE
		else:
			fill_col = CyberStyle.HP_PLAYER_LOW if is_player else CyberStyle.HP_ENEMY_LOW
		c.draw_rect(Rect2(pos, Vector2(fill_w, bar_h)), fill_col, true)
	c.draw_rect(Rect2(pos, Vector2(width, bar_h)), Color(0.5, 0.55, 0.6, 0.3), false, 1.0)

# --- 选中脉冲金色边框 ---

static func _draw_selection(c: CanvasItem, pos: Vector2, sz: Vector2, pulse: float) -> void:
	var col: Color = CyberStyle.NEON_GOLD
	var a: float = 0.5 + pulse * 0.4
	c.draw_rect(Rect2(pos - Vector2(1, 1), sz + Vector2(2, 2)), Color(col.r, col.g, col.b, a * 0.3), false, 1.0)
	c.draw_rect(Rect2(pos, sz), Color(col.r, col.g, col.b, a), false, 2.5)

# --- 地形适性星标 ---

static func draw_affinity_star(c: CanvasItem, cell: Vector2i, cs: int, unit: Dictionary, board_mgr: Node, font: Font) -> void:
	var affinity: String = String(unit.get("terrain_affinity", ""))
	if affinity == "":
		return
	var active: bool = false
	if affinity == "high_ground" and board_mgr.get_terrain_type(cell) == "high_ground":
		active = true
	elif affinity == "path" and board_mgr.path_cells.has(cell):
		active = true
	elif affinity == "trap" and board_mgr.get_terrain_type(cell) == "trap":
		active = true
	if active:
		var sx: float = cell.x * cs + cs - 16
		var sy: float = cell.y * cs + 13
		c.draw_string(font, Vector2(sx, sy), "*", HORIZONTAL_ALIGNMENT_LEFT, 14, 13, CyberStyle.NEON_GOLD)

# --- 等距棋盘专用绘制（v0.1.58 Phase 6）---
# 与 draw_full_unit 相同的角色剪影，但以屏幕中心点定位、缩小以适配菱形格

static func draw_full_unit_iso(c: CanvasItem, center: Vector2, unit: Dictionary, is_selected: bool, pulse: float, idle_y: float, font: Font) -> void:
	var owner: String = String(unit.get("owner", "player"))
	var is_player: bool = owner == "player"
	var display_name: String = String(unit.get("display_name", ""))
	var hp: int = int(unit.get("hp", 1))
	var max_hp: int = int(unit.get("max_hp", 1))
	var hp_ratio: float = float(hp) / float(max_hp) if max_hp > 0 else 1.0
	var s: float = 0.55
	var cx: float = center.x
	var cy: float = center.y - 10.0 + idle_y
	if is_player:
		_draw_player_char(c, Vector2(cx, cy), s, display_name, pulse)
	else:
		_draw_enemy_char(c, Vector2(cx, cy), s, display_name, pulse)
	_draw_hp_bar(c, Vector2(center.x - 20.0, center.y + 10.0), 40.0, hp_ratio, is_player)
	if is_selected:
		var col: Color = CyberStyle.NEON_GOLD
		var a: float = 0.5 + pulse * 0.4
		c.draw_arc(Vector2(cx, cy), 16.0, 0, TAU, 16, Color(col.r, col.g, col.b, a), 2.0)

static func draw_affinity_star_iso(c: CanvasItem, center: Vector2, unit: Dictionary, board_mgr: Node, cell: Vector2i, font: Font) -> void:
	var affinity: String = String(unit.get("terrain_affinity", ""))
	if affinity == "":
		return
	var active: bool = false
	if affinity == "high_ground" and board_mgr.get_terrain_type(cell) == "high_ground":
		active = true
	elif affinity == "path" and board_mgr.path_cells.has(cell):
		active = true
	elif affinity == "trap" and board_mgr.get_terrain_type(cell) == "trap":
		active = true
	if active:
		c.draw_string(font, Vector2(center.x + 14.0, center.y - 16.0), "*", HORIZONTAL_ALIGNMENT_LEFT, 14, 13, CyberStyle.NEON_GOLD)
