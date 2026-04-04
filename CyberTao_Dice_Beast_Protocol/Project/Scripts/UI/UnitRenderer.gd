extends RefCounted
class_name UnitRenderer

const UnitMeshFactory3D = preload("res://Scripts/UI3D/UnitMeshFactory3D.gd")
static var _iso_tex_cache: Dictionary = {}

## 单位渲染器（v0.2.0 咩咩启示录风格：可爱Q版角色 + 发光 + HP条 + 选中脉冲）
## Cult of the Lamb inspired chibi art: big round heads, dot pupils, stubby limbs
## 颜色 100% 来自 CyberStyle

# --- 单位完整绘制 ---

static func draw_full_unit(c: CanvasItem, cell: Vector2i, cs: int, unit: Dictionary, is_selected: bool, pulse: float, idle_y: float, font: Font) -> void:
	var owner: String = String(unit.get("owner", "player"))
	var is_player: bool = owner == "player"
	var display_name: String = String(unit.get("display_name", ""))
	var hp: int = int(unit.get("hp", 1))
	var max_hp: int = int(unit.get("max_hp", 1))

	var cx: float = float(cell.x * cs) + float(cs) * 0.5
	var cy: float = float(cell.y * cs) + float(cs) * 0.5 + idle_y
	var s: float = float(cs) / 72.0  # 基于 72px 格子大小的缩放因子

	if is_player:
		_draw_player_char(c, Vector2(cx, cy), s, display_name, pulse)
	else:
		_draw_enemy_char(c, Vector2(cx, cy), s, display_name, pulse)

	# HP 条
	_draw_hp_bar(c, Vector2(cell.x * cs + 8, cell.y * cs + cs - 12), cs - 16, hp, max_hp, is_player)

	# 选中脉冲环
	if is_selected:
		_draw_selection(c, Vector2(cell.x * cs + 5, cell.y * cs + 5 + idle_y), Vector2(cs - 12, cs - 16), pulse)

# --- 玩家角色（Q版刀盾犬英雄 - Cult of the Lamb chibi style） ---

static func _draw_player_char(c: CanvasItem, center: Vector2, s: float, name: String, pulse: float) -> void:
	var col: Color = CyberStyle.HP_PLAYER
	var cyan: Color = CyberStyle.ACCENT_CYAN
	var ga: float = 0.30 + pulse * 0.10

	# --- 脚底光环 (soft glow circle beneath) ---
	c.draw_circle(center + Vector2(0, 22 * s), 10 * s, Color(cyan.r, cyan.g, cyan.b, 0.08 + pulse * 0.04))
	c.draw_arc(center + Vector2(0, 22 * s), 11 * s, 0, TAU, 14, Color(cyan.r, cyan.g, cyan.b, 0.12 + pulse * 0.06), 1.0 * s)

	# --- 短粗腿 (stubby chibi legs) ---
	var leg_col: Color = Color(col.r, col.g, col.b, ga + 0.15)
	# Left leg - short rounded rectangle
	var ll: PackedVector2Array = PackedVector2Array([
		center + Vector2(-7 * s, 10 * s), center + Vector2(-3 * s, 10 * s),
		center + Vector2(-3 * s, 20 * s), center + Vector2(-7 * s, 20 * s)])
	c.draw_colored_polygon(ll, leg_col)
	# Right leg
	var rl: PackedVector2Array = PackedVector2Array([
		center + Vector2(3 * s, 10 * s), center + Vector2(7 * s, 10 * s),
		center + Vector2(7 * s, 20 * s), center + Vector2(3 * s, 20 * s)])
	c.draw_colored_polygon(rl, leg_col)

	# --- 圆润小身体 (cute rounded body - oval) ---
	var body_center: Vector2 = center + Vector2(0, 2 * s)
	c.draw_circle(body_center, 10 * s, Color(col.r, col.g, col.b, ga))
	c.draw_arc(body_center, 10 * s, 0, TAU, 14, Color(col.r, col.g, col.b, 0.5), 1.2 * s)
	# Chest energy line (small accent)
	c.draw_line(body_center + Vector2(-5 * s, -2 * s), body_center + Vector2(5 * s, -2 * s), Color(cyan.r, cyan.g, cyan.b, 0.35 + pulse * 0.15), 1.0 * s)

	# --- 左手小盾牌 (stubby arm + small shield) ---
	c.draw_line(center + Vector2(-10 * s, 0), center + Vector2(-14 * s, 4 * s), Color(col.r, col.g, col.b, 0.5), 2.5 * s)
	c.draw_arc(center + Vector2(-15 * s, 4 * s), 4 * s, 0, TAU, 10, Color(cyan.r, cyan.g, cyan.b, 0.45 + pulse * 0.12), 1.8 * s)
	c.draw_circle(center + Vector2(-15 * s, 4 * s), 2.5 * s, Color(cyan.r, cyan.g, cyan.b, 0.25))

	# --- 右手发光小刀 (stubby arm + glowing blade) ---
	c.draw_line(center + Vector2(10 * s, 0), center + Vector2(14 * s, -2 * s), Color(col.r, col.g, col.b, 0.5), 2.5 * s)
	c.draw_line(center + Vector2(14 * s, -2 * s), center + Vector2(17 * s, -12 * s), Color(1.0, 0.9, 0.3, 0.55 + pulse * 0.25), 2.2 * s)
	c.draw_line(center + Vector2(14 * s, -2 * s), center + Vector2(17 * s, -12 * s), Color(1.0, 1.0, 0.8, 0.20), 4.0 * s)

	# --- 大圆头 (big round chibi head ~40% of total height) ---
	var head: Vector2 = center + Vector2(0, -14 * s)
	var head_r: float = 11 * s
	c.draw_circle(head, head_r, Color(col.r, col.g, col.b, ga + 0.08))
	c.draw_arc(head, head_r, 0, TAU, 16, Color(col.r, col.g, col.b, 0.55), 1.5 * s)

	# --- 大圆眼 + 小瞳孔 (Cult of the Lamb style eyes) ---
	var eye_l: Vector2 = head + Vector2(-4 * s, 0)
	var eye_r: Vector2 = head + Vector2(4 * s, 0)
	# White eye circles
	c.draw_circle(eye_l, 3.2 * s, Color(1.0, 1.0, 1.0, 0.85))
	c.draw_circle(eye_r, 3.2 * s, Color(1.0, 1.0, 1.0, 0.85))
	# Small dark pupils
	c.draw_circle(eye_l + Vector2(0.5 * s, 0.5 * s), 1.3 * s, Color(0.1, 0.1, 0.15, 0.9))
	c.draw_circle(eye_r + Vector2(0.5 * s, 0.5 * s), 1.3 * s, Color(0.1, 0.1, 0.15, 0.9))
	# Tiny eye highlights
	c.draw_circle(eye_l + Vector2(-0.5 * s, -0.8 * s), 0.6 * s, Color(1.0, 1.0, 1.0, 0.7))
	c.draw_circle(eye_r + Vector2(-0.5 * s, -0.8 * s), 0.6 * s, Color(1.0, 1.0, 1.0, 0.7))

	# --- 小嘴 (tiny cute mouth) ---
	c.draw_arc(head + Vector2(0, 3 * s), 2 * s, 0.2, PI - 0.2, 6, Color(0.2, 0.15, 0.2, 0.5), 1.0 * s)

	# --- 头顶小皇冠/光环 (crown/halo - 3 small triangles) ---
	var crown_base: float = head.y - head_r - 1 * s
	var crown_col: Color = Color(cyan.r, cyan.g, cyan.b, 0.5 + pulse * 0.15)
	# Center spike
	var spike_c: PackedVector2Array = PackedVector2Array([
		Vector2(head.x - 2 * s, crown_base), Vector2(head.x + 2 * s, crown_base),
		Vector2(head.x, crown_base - 5 * s)])
	c.draw_colored_polygon(spike_c, crown_col)
	# Left spike
	var spike_l: PackedVector2Array = PackedVector2Array([
		Vector2(head.x - 6 * s, crown_base), Vector2(head.x - 2 * s, crown_base),
		Vector2(head.x - 4 * s, crown_base - 3.5 * s)])
	c.draw_colored_polygon(spike_l, crown_col)
	# Right spike
	var spike_rr: PackedVector2Array = PackedVector2Array([
		Vector2(head.x + 2 * s, crown_base), Vector2(head.x + 6 * s, crown_base),
		Vector2(head.x + 4 * s, crown_base - 3.5 * s)])
	c.draw_colored_polygon(spike_rr, crown_col)

# --- 敌方角色（各敌方类型不同Q版剪影） ---

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

# 哨兵: Cute boxy robot, rounded head, single scanning eye, antenna
static func _draw_mini_sentinel(c: CanvasItem, center: Vector2, s: float, col: Color, ga: float, pulse: float) -> void:
	var orange: Color = CyberStyle.ACCENT_ORANGE

	# --- 短粗腿 (stubby mechanical legs) ---
	var leg_col: Color = Color(col.r, col.g, col.b, ga + 0.1)
	c.draw_colored_polygon(PackedVector2Array([
		center + Vector2(-7 * s, 12 * s), center + Vector2(-3 * s, 12 * s),
		center + Vector2(-3 * s, 21 * s), center + Vector2(-7 * s, 21 * s)]), leg_col)
	c.draw_colored_polygon(PackedVector2Array([
		center + Vector2(3 * s, 12 * s), center + Vector2(7 * s, 12 * s),
		center + Vector2(7 * s, 21 * s), center + Vector2(3 * s, 21 * s)]), leg_col)

	# --- 方形圆角身体 (compact square body) ---
	var body_r: Rect2 = Rect2(center + Vector2(-9 * s, -4 * s), Vector2(18 * s, 18 * s))
	c.draw_rect(body_r, Color(col.r, col.g, col.b, ga), true)
	c.draw_rect(body_r, Color(col.r, col.g, col.b, 0.5), false, 1.5 * s)
	# Body accent line
	c.draw_line(center + Vector2(-6 * s, 6 * s), center + Vector2(6 * s, 6 * s), Color(orange.r, orange.g, orange.b, 0.2), 1.0 * s)

	# --- 大圆角方头 (boxy but rounded robot head) ---
	var head_c: Vector2 = center + Vector2(0, -13 * s)
	var head_rect: Rect2 = Rect2(head_c + Vector2(-8 * s, -7 * s), Vector2(16 * s, 14 * s))
	c.draw_rect(head_rect, Color(col.r, col.g, col.b, ga + 0.06), true)
	c.draw_rect(head_rect, Color(col.r, col.g, col.b, 0.55), false, 1.5 * s)

	# --- 单只大扫描眼 (single big scanning eye - horizontal oval) ---
	var eye_w: float = 7 * s * (0.8 + pulse * 0.2)
	var eye_c: Vector2 = head_c + Vector2(0, 1 * s)
	c.draw_arc(eye_c, eye_w, 0, TAU, 12, Color(orange.r, orange.g, orange.b, 0.7 + pulse * 0.2), 2.0 * s)
	c.draw_circle(eye_c, 3.5 * s, Color(orange.r, orange.g, orange.b, 0.25 + pulse * 0.1))
	# Pupil dot
	c.draw_circle(eye_c, 1.5 * s, Color(orange.r, orange.g, orange.b, 0.8))

	# --- 天线 (small antenna on top) ---
	var ant_base: Vector2 = head_c + Vector2(0, -7 * s)
	c.draw_line(ant_base, ant_base + Vector2(0, -6 * s), Color(col.r, col.g, col.b, 0.5), 1.2 * s)
	c.draw_circle(ant_base + Vector2(0, -6 * s), 1.8 * s, Color(orange.r, orange.g, orange.b, 0.5 + pulse * 0.3))

# 游魂: Round blob ghost, wavy bottom, angry cute eyes, trailing wisps
static func _draw_mini_ghost(c: CanvasItem, center: Vector2, s: float, col: Color, ga: float, pulse: float) -> void:
	# --- 幽灵尾焰 (faint trailing wisps below) ---
	for i in range(3):
		var wx: float = (-4.0 + float(i) * 4.0) * s
		var wy: float = 10 * s + float(i) * 3 * s
		var fade: float = 0.18 - float(i) * 0.04
		c.draw_circle(center + Vector2(wx, wy), 2.5 * s, Color(col.r, col.g, col.b, fade))

	# --- 波浪底边 (wavy/wiggly bottom - 3 small arcs) ---
	var bot_y: float = center.y + 8 * s
	for i in range(3):
		var ax: float = center.x + (-6.0 + float(i) * 6.0) * s
		c.draw_arc(Vector2(ax, bot_y), 3 * s, 0, PI, 6, Color(col.r, col.g, col.b, ga + 0.1), 1.5 * s)

	# --- 大圆身体 (round blob body, no legs) ---
	var body_c: Vector2 = center + Vector2(0, -3 * s)
	c.draw_circle(body_c, 12 * s, Color(col.r, col.g, col.b, ga))
	c.draw_arc(body_c, 12 * s, 0, TAU, 16, Color(col.r, col.g, col.b, 0.45), 1.5 * s)

	# --- 大圆眼 + 微怒表情 (big round eyes, slightly angry) ---
	var eye_l: Vector2 = body_c + Vector2(-4 * s, -1 * s)
	var eye_r: Vector2 = body_c + Vector2(4 * s, -1 * s)
	# White sclera
	c.draw_circle(eye_l, 3.0 * s, Color(1.0, 1.0, 1.0, 0.8))
	c.draw_circle(eye_r, 3.0 * s, Color(1.0, 1.0, 1.0, 0.8))
	# Red-tinted pupils for anger
	c.draw_circle(eye_l + Vector2(0, 0.5 * s), 1.4 * s, Color(1.0, 0.2, 0.2, 0.8 + pulse * 0.15))
	c.draw_circle(eye_r + Vector2(0, 0.5 * s), 1.4 * s, Color(1.0, 0.2, 0.2, 0.8 + pulse * 0.15))
	# Angry eyebrow lines (angled down toward center)
	c.draw_line(eye_l + Vector2(-2.5 * s, -3 * s), eye_l + Vector2(1.5 * s, -2 * s), Color(col.r, col.g, col.b, 0.6), 1.2 * s)
	c.draw_line(eye_r + Vector2(2.5 * s, -3 * s), eye_r + Vector2(-1.5 * s, -2 * s), Color(col.r, col.g, col.b, 0.6), 1.2 * s)

	# --- 小嘴 (tiny frowning mouth) ---
	c.draw_arc(body_c + Vector2(0, 4 * s), 2 * s, PI + 0.3, TAU - 0.3, 6, Color(0.2, 0.1, 0.2, 0.5), 1.0 * s)

# 爬虫: Cute round bug, stubby legs, cluster eyes, small mandibles
static func _draw_mini_crawler(c: CanvasItem, center: Vector2, s: float, col: Color, ga: float, pulse: float) -> void:
	# --- 6只小短腿 (tiny stubby legs sticking out from sides) ---
	for i in range(3):
		var by: float = (-4.0 + float(i) * 5.0) * s
		var leg_a: float = 0.35
		# Left legs
		var ll_start: Vector2 = center + Vector2(-9 * s, by)
		var ll_end: Vector2 = center + Vector2(-14 * s, by + 3 * s)
		c.draw_line(ll_start, ll_end, Color(col.r, col.g, col.b, leg_a), 2.0 * s)
		c.draw_circle(ll_end, 1.2 * s, Color(col.r, col.g, col.b, leg_a))
		# Right legs
		var rl_start: Vector2 = center + Vector2(9 * s, by)
		var rl_end: Vector2 = center + Vector2(14 * s, by + 3 * s)
		c.draw_line(rl_start, rl_end, Color(col.r, col.g, col.b, leg_a), 2.0 * s)
		c.draw_circle(rl_end, 1.2 * s, Color(col.r, col.g, col.b, leg_a))

	# --- 圆形主体 (round/oval main body like a cute bug) ---
	c.draw_circle(center, 10 * s, Color(col.r, col.g, col.b, ga))
	c.draw_arc(center, 10 * s, 0, TAU, 14, Color(col.r, col.g, col.b, 0.45), 1.5 * s)
	# Shell line accent
	c.draw_arc(center, 6 * s, 0.3, PI - 0.3, 8, Color(col.r, col.g, col.b, 0.25), 1.0 * s)

	# --- 眼簇 (multiple small dot eyes in a cluster) ---
	var eye_positions: Array = [
		Vector2(-3.0, -4.0), Vector2(0.0, -5.0), Vector2(3.0, -4.0),
		Vector2(-1.5, -2.5), Vector2(1.5, -2.5)]
	for ep in eye_positions:
		c.draw_circle(center + Vector2(ep.x * s, ep.y * s), 1.2 * s, Color(1.0, 0.15, 0.15, 0.6 + pulse * 0.2))

	# --- 小钳子 (small mandibles/pincers at front) ---
	c.draw_line(center + Vector2(-3 * s, 8 * s), center + Vector2(-6 * s, 13 * s), Color(col.r, col.g, col.b, 0.5), 1.5 * s)
	c.draw_line(center + Vector2(3 * s, 8 * s), center + Vector2(6 * s, 13 * s), Color(col.r, col.g, col.b, 0.5), 1.5 * s)
	# Pincer tips
	c.draw_line(center + Vector2(-6 * s, 13 * s), center + Vector2(-4 * s, 15 * s), Color(col.r, col.g, col.b, 0.4), 1.2 * s)
	c.draw_line(center + Vector2(6 * s, 13 * s), center + Vector2(4 * s, 15 * s), Color(col.r, col.g, col.b, 0.4), 1.2 * s)

# 猎手: Fox/cat pointed head, cyclops eye, slim cute body, small blaster
static func _draw_mini_hunter(c: CanvasItem, center: Vector2, s: float, col: Color, ga: float, pulse: float) -> void:
	# --- 细腿 (thin but cute legs) ---
	c.draw_line(center + Vector2(-4 * s, 10 * s), center + Vector2(-5 * s, 21 * s), Color(col.r, col.g, col.b, 0.4), 1.8 * s)
	c.draw_line(center + Vector2(4 * s, 10 * s), center + Vector2(5 * s, 21 * s), Color(col.r, col.g, col.b, 0.4), 1.8 * s)
	# Tiny feet
	c.draw_circle(center + Vector2(-5 * s, 21 * s), 1.5 * s, Color(col.r, col.g, col.b, 0.35))
	c.draw_circle(center + Vector2(5 * s, 21 * s), 1.5 * s, Color(col.r, col.g, col.b, 0.35))

	# --- 可爱纤细身体 (slim but still cute body) ---
	var body_c: Vector2 = center + Vector2(0, 3 * s)
	var body_poly: PackedVector2Array = PackedVector2Array([
		body_c + Vector2(-7 * s, -7 * s), body_c + Vector2(7 * s, -7 * s),
		body_c + Vector2(5 * s, 8 * s), body_c + Vector2(-5 * s, 8 * s)])
	c.draw_colored_polygon(body_poly, Color(col.r, col.g, col.b, ga))
	for i in range(4):
		c.draw_line(body_poly[i], body_poly[(i + 1) % 4], Color(col.r, col.g, col.b, 0.45), 1.0 * s)

	# --- 小枪/爆能枪 (small gun/blaster to the side) ---
	c.draw_line(center + Vector2(7 * s, -2 * s), center + Vector2(14 * s, -5 * s), Color(col.r, col.g, col.b, 0.45), 2.0 * s)
	c.draw_line(center + Vector2(14 * s, -5 * s), center + Vector2(18 * s, -8 * s), Color(col.r, col.g, col.b, 0.5 + pulse * 0.2), 2.5 * s)
	# Muzzle glow
	c.draw_circle(center + Vector2(18 * s, -8 * s), 1.5 * s, Color(1.0, 0.6, 0.1, 0.4 + pulse * 0.3))

	# --- 三角尖头 (triangular/pointed fox-cat head) ---
	var head_c: Vector2 = center + Vector2(0, -12 * s)
	# Main round head
	c.draw_circle(head_c, 9 * s, Color(col.r, col.g, col.b, ga + 0.05))
	c.draw_arc(head_c, 9 * s, 0, TAU, 14, Color(col.r, col.g, col.b, 0.5), 1.2 * s)
	# Pointed ears (fox/cat)
	var ear_l: PackedVector2Array = PackedVector2Array([
		head_c + Vector2(-7 * s, -5 * s), head_c + Vector2(-3 * s, -7 * s),
		head_c + Vector2(-9 * s, -14 * s)])
	c.draw_colored_polygon(ear_l, Color(col.r, col.g, col.b, ga + 0.05))
	var ear_r: PackedVector2Array = PackedVector2Array([
		head_c + Vector2(3 * s, -7 * s), head_c + Vector2(7 * s, -5 * s),
		head_c + Vector2(9 * s, -14 * s)])
	c.draw_colored_polygon(ear_r, Color(col.r, col.g, col.b, ga + 0.05))

	# --- 独眼 (one big cyclops eye, glowing) ---
	c.draw_circle(head_c + Vector2(0, 0), 4 * s, Color(1.0, 1.0, 1.0, 0.8))
	c.draw_circle(head_c + Vector2(0, 0), 2 * s, Color(1.0, 0.75, 0.1, 0.75 + pulse * 0.2))
	c.draw_circle(head_c + Vector2(0, 0), 0.8 * s, Color(0.1, 0.05, 0.0, 0.9))
	# Eye glow
	c.draw_arc(head_c, 4.5 * s, 0, TAU, 10, Color(1.0, 0.8, 0.2, 0.15 + pulse * 0.1), 1.5 * s)

# 幽灵: Diamond ethereal body, soft glowing eyes, data lines, floating
static func _draw_mini_phantom(c: CanvasItem, center: Vector2, s: float, col: Color, ga: float, pulse: float) -> void:
	# --- 数据辐射线 (thin data lines radiating outward) ---
	for i in range(6):
		var angle: float = float(i) * TAU / 6.0 + pulse * 0.25
		var r_inner: float = 12 * s
		var r_outer: float = 18 * s
		c.draw_line(
			center + Vector2(cos(angle) * r_inner, sin(angle) * r_inner * 0.7),
			center + Vector2(cos(angle) * r_outer, sin(angle) * r_outer * 0.7),
			Color(col.r, col.g, col.b, 0.12 + pulse * 0.06), 1.0 * s)

	# --- 菱形空灵身体 (diamond/rhombus shaped ethereal body) ---
	var diamond: PackedVector2Array = PackedVector2Array([
		center + Vector2(0, -14 * s), center + Vector2(10 * s, 0),
		center + Vector2(0, 14 * s), center + Vector2(-10 * s, 0)])
	# Slight transparency effect - inner glow
	c.draw_colored_polygon(diamond, Color(col.r, col.g, col.b, ga * 0.7))
	# Brighter inner diamond for ethereal glow
	var inner_d: PackedVector2Array = PackedVector2Array([
		center + Vector2(0, -8 * s), center + Vector2(6 * s, 0),
		center + Vector2(0, 8 * s), center + Vector2(-6 * s, 0)])
	c.draw_colored_polygon(inner_d, Color(col.r, col.g, col.b, ga * 0.35))
	# Outer edge
	for i in range(4):
		c.draw_line(diamond[i], diamond[(i + 1) % 4], Color(col.r, col.g, col.b, 0.4 + pulse * 0.15), 1.5 * s)

	# --- 柔和发光双眼 (two soft glowing eyes) ---
	var eye_l: Vector2 = center + Vector2(-3.5 * s, -2 * s)
	var eye_r: Vector2 = center + Vector2(3.5 * s, -2 * s)
	# Soft outer glow
	c.draw_circle(eye_l, 3 * s, Color(1.0, 1.0, 1.0, 0.2 + pulse * 0.08))
	c.draw_circle(eye_r, 3 * s, Color(1.0, 1.0, 1.0, 0.2 + pulse * 0.08))
	# White eye
	c.draw_circle(eye_l, 2.2 * s, Color(1.0, 1.0, 1.0, 0.65))
	c.draw_circle(eye_r, 2.2 * s, Color(1.0, 1.0, 1.0, 0.65))
	# Small pupils
	c.draw_circle(eye_l, 0.9 * s, Color(0.15, 0.25, 0.5, 0.8))
	c.draw_circle(eye_r, 0.9 * s, Color(0.15, 0.25, 0.5, 0.8))

# Boss 零号协议: Large head + golden crown, three eyes, imposing body, shoulder pads
static func _draw_mini_boss(c: CanvasItem, center: Vector2, s: float, col: Color, ga: float, pulse: float) -> void:
	var gold: Color = CyberStyle.NEON_GOLD

	# --- 粗壮腿 (thick sturdy legs) ---
	var leg_col: Color = Color(col.r, col.g, col.b, ga + 0.12)
	c.draw_colored_polygon(PackedVector2Array([
		center + Vector2(-8 * s, 14 * s), center + Vector2(-3 * s, 14 * s),
		center + Vector2(-4 * s, 25 * s), center + Vector2(-9 * s, 25 * s)]), leg_col)
	c.draw_colored_polygon(PackedVector2Array([
		center + Vector2(3 * s, 14 * s), center + Vector2(8 * s, 14 * s),
		center + Vector2(9 * s, 25 * s), center + Vector2(4 * s, 25 * s)]), leg_col)

	# --- 宽大身体 (big imposing body, wider than regular enemies) ---
	var body_r: Rect2 = Rect2(center + Vector2(-13 * s, -6 * s), Vector2(26 * s, 22 * s))
	c.draw_rect(body_r, Color(col.r, col.g, col.b, ga + 0.05), true)
	c.draw_rect(body_r, Color(col.r, col.g, col.b, 0.6), false, 2.0 * s)
	# Golden accent lines on body
	c.draw_line(center + Vector2(-10 * s, 0), center + Vector2(10 * s, 0), Color(gold.r, gold.g, gold.b, 0.25), 1.0 * s)
	c.draw_line(center + Vector2(-10 * s, 6 * s), center + Vector2(10 * s, 6 * s), Color(gold.r, gold.g, gold.b, 0.2), 1.0 * s)
	# Center gem
	c.draw_circle(center + Vector2(0, 3 * s), 2.5 * s, Color(gold.r, gold.g, gold.b, 0.4 + pulse * 0.15))

	# --- 肩甲 (shoulder pads) ---
	var sp_col: Color = Color(col.r, col.g, col.b, ga + 0.08)
	# Left shoulder pad (rounded)
	c.draw_circle(center + Vector2(-16 * s, -4 * s), 5 * s, sp_col)
	c.draw_arc(center + Vector2(-16 * s, -4 * s), 5 * s, 0, TAU, 10, Color(gold.r, gold.g, gold.b, 0.3), 1.0 * s)
	# Right shoulder pad
	c.draw_circle(center + Vector2(16 * s, -4 * s), 5 * s, sp_col)
	c.draw_arc(center + Vector2(16 * s, -4 * s), 5 * s, 0, TAU, 10, Color(gold.r, gold.g, gold.b, 0.3), 1.0 * s)

	# --- 大圆头 (large round head) ---
	var head: Vector2 = center + Vector2(0, -17 * s)
	var head_r: float = 10 * s
	c.draw_circle(head, head_r, Color(col.r, col.g, col.b, ga + 0.08))
	c.draw_arc(head, head_r, 0, TAU, 16, Color(col.r, col.g, col.b, 0.55), 1.5 * s)

	# --- 金色皇冠 (golden crown with 3 pointed spikes) ---
	var crown_y: float = head.y - head_r
	# Crown base band
	c.draw_line(Vector2(head.x - 8 * s, crown_y), Vector2(head.x + 8 * s, crown_y), Color(gold.r, gold.g, gold.b, 0.5), 2.0 * s)
	# Center spike (tallest)
	var cs_poly: PackedVector2Array = PackedVector2Array([
		Vector2(head.x - 2.5 * s, crown_y), Vector2(head.x + 2.5 * s, crown_y),
		Vector2(head.x, crown_y - 8 * s)])
	c.draw_colored_polygon(cs_poly, Color(gold.r, gold.g, gold.b, 0.5 + pulse * 0.15))
	# Left spike
	var ls_poly: PackedVector2Array = PackedVector2Array([
		Vector2(head.x - 7 * s, crown_y), Vector2(head.x - 2.5 * s, crown_y),
		Vector2(head.x - 5 * s, crown_y - 5.5 * s)])
	c.draw_colored_polygon(ls_poly, Color(gold.r, gold.g, gold.b, 0.45 + pulse * 0.12))
	# Right spike
	var rs_poly: PackedVector2Array = PackedVector2Array([
		Vector2(head.x + 2.5 * s, crown_y), Vector2(head.x + 7 * s, crown_y),
		Vector2(head.x + 5 * s, crown_y - 5.5 * s)])
	c.draw_colored_polygon(rs_poly, Color(gold.r, gold.g, gold.b, 0.45 + pulse * 0.12))

	# --- 三眼 (two normal eyes + one red third eye above) ---
	# Normal eyes (big, round, Cult of the Lamb style)
	var el: Vector2 = head + Vector2(-4 * s, 0)
	var er: Vector2 = head + Vector2(4 * s, 0)
	c.draw_circle(el, 3 * s, Color(1.0, 1.0, 1.0, 0.8))
	c.draw_circle(er, 3 * s, Color(1.0, 1.0, 1.0, 0.8))
	c.draw_circle(el, 1.3 * s, Color(gold.r, gold.g, gold.b, 0.85))
	c.draw_circle(er, 1.3 * s, Color(gold.r, gold.g, gold.b, 0.85))
	# Third eye (red, smaller, above center)
	var te: Vector2 = head + Vector2(0, -5 * s)
	c.draw_circle(te, 2.2 * s, Color(1.0, 0.15, 0.15, 0.5 + pulse * 0.25))
	c.draw_circle(te, 1.0 * s, Color(1.0, 0.05, 0.05, 0.8 + pulse * 0.15))
	# Third eye glow
	c.draw_arc(te, 3 * s, 0, TAU, 10, Color(1.0, 0.1, 0.1, 0.15 + pulse * 0.1), 1.0 * s)

	# --- 小嘴 (stern small mouth) ---
	c.draw_line(head + Vector2(-3 * s, 4 * s), head + Vector2(3 * s, 4 * s), Color(0.2, 0.1, 0.15, 0.45), 1.2 * s)

# --- HP 条：薄条 + 绿→黄→红渐变 ---

static func _draw_hp_bar(c: CanvasItem, pos: Vector2, width: float, hp: int, max_hp: int, is_player: bool) -> void:
	var bar_h: float = 4.0
	var total_segments: int = max(1, max_hp)
	var filled_segments: int = clampi(hp, 0, total_segments)
	var gap: float = 1.0 if total_segments <= 12 else 0.0
	var seg_w: float = (width - gap * float(total_segments - 1)) / float(total_segments)
	var hp_ratio: float = float(filled_segments) / float(total_segments)
	var fill_col: Color
	if hp_ratio > 0.6:
		fill_col = CyberStyle.HP_PLAYER if is_player else CyberStyle.HP_ENEMY
	elif hp_ratio > 0.3:
		fill_col = CyberStyle.TEXT_TITLE
	else:
		fill_col = CyberStyle.HP_PLAYER_LOW if is_player else CyberStyle.HP_ENEMY_LOW
	for i in range(total_segments):
		var x: float = pos.x + float(i) * (seg_w + gap)
		c.draw_rect(Rect2(Vector2(x, pos.y), Vector2(seg_w, bar_h)), Color(0.12, 0.12, 0.18, 0.82), true)
		if i < filled_segments:
			c.draw_rect(Rect2(Vector2(x, pos.y), Vector2(seg_w, bar_h)), fill_col, true)
		c.draw_rect(Rect2(Vector2(x, pos.y), Vector2(seg_w, bar_h)), Color(0.5, 0.55, 0.6, 0.35), false, 1.0)

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

# --- 等距棋盘专用绘制（v0.1.60 相机跟随 + TILE_W=192 放大）---
# v0.1.91：2D 也改用 UnitMeshFactory3D 像素纹理，统一 2D/3D 美术风格

static func _get_iso_unit_tex(unit: Dictionary) -> Texture2D:
	var owner: String = String(unit.get("owner", ""))
	var tags: Array = unit.get("tags", [])
	var is_summoned: bool = tags.has("summoned")
	if owner == "player" and not is_summoned:
		if not _iso_tex_cache.has("player"):
			_iso_tex_cache["player"] = UnitMeshFactory3D._gen_player_hero()
		return _iso_tex_cache.get("player", null)
	if is_summoned:
		if not _iso_tex_cache.has("summoned"):
			_iso_tex_cache["summoned"] = UnitMeshFactory3D._gen_summoned_ally()
		return _iso_tex_cache.get("summoned", null)
	var enc_id: String = String(unit.get("encounter_id", ""))
	var key: String = "enemy_" + enc_id
	if not _iso_tex_cache.has(key):
		_iso_tex_cache[key] = UnitMeshFactory3D._gen_enemy_by_id(enc_id)
	return _iso_tex_cache.get(key, null)

static func draw_full_unit_iso(c: CanvasItem, center: Vector2, unit: Dictionary, is_selected: bool, pulse: float, idle_y: float, font: Font) -> void:
	var owner: String = String(unit.get("owner", "player"))
	var is_player: bool = owner == "player"
	var display_name: String = String(unit.get("display_name", ""))
	var hp: int = int(unit.get("hp", 1))
	var max_hp: int = int(unit.get("max_hp", 1))
	var cx: float = center.x
	var cy: float = center.y - 20.0 + idle_y
	var tex: Texture2D = _get_iso_unit_tex(unit)
	if tex != null:
		var w: float = 70.0
		var h: float = 70.0
		var rect := Rect2(cx - w * 0.5, cy - h * 0.75, w, h)
		c.draw_texture_rect(tex, rect, false, Color(1, 1, 1, 1))
		# 轻微脚底辉光
		var glow_col: Color = CyberStyle.ACCENT_CYAN if is_player else CyberStyle.ACCENT_ORANGE
		c.draw_circle(Vector2(cx, center.y + 10.0), 12.0, Color(glow_col.r, glow_col.g, glow_col.b, 0.10 + pulse * 0.05))
	else:
		var s: float = 1.1
		if is_player:
			_draw_player_char(c, Vector2(cx, cy), s, display_name, pulse)
		else:
			_draw_enemy_char(c, Vector2(cx, cy), s, display_name, pulse)
	_draw_hp_bar(c, Vector2(center.x - 36.0, center.y + 16.0), 72.0, hp, max_hp, is_player)
	if is_selected:
		var col: Color = CyberStyle.NEON_GOLD
		var a: float = 0.5 + pulse * 0.4
		c.draw_arc(Vector2(cx, cy), 30.0, 0, TAU, 16, Color(col.r, col.g, col.b, a), 2.5)

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
		c.draw_string(font, Vector2(center.x + 22.0, center.y - 24.0), "*", HORIZONTAL_ALIGNMENT_LEFT, 18, 16, CyberStyle.NEON_GOLD)
