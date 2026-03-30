extends RefCounted
class_name BattleCharRenderer

## 卡牌战斗角色渲染器
## 程序化绘制玩家英雄和敌方角色立绘（赛博朋克风格）
## 用于全屏 CardBattlePanel 的角色展示区域

# --- 角色绘制入口 ---

static func draw_player_hero(c: CanvasItem, center: Vector2, scale_f: float, pulse: float) -> void:
	# 刀盾犬英雄：赛博战士 + 盾牌 + 光刃
	var col: Color = CyberStyle.HP_PLAYER
	var cyan: Color = CyberStyle.ACCENT_CYAN
	var s: float = scale_f

	# 身体光晕
	_draw_glow_circle(c, center + Vector2(0, -10 * s), 55 * s, Color(col.r, col.g, col.b, 0.06 + pulse * 0.03))

	# 腿部
	c.draw_line(center + Vector2(-12 * s, 30 * s), center + Vector2(-16 * s, 65 * s), Color(col.r, col.g, col.b, 0.6), 4.0 * s)
	c.draw_line(center + Vector2(12 * s, 30 * s), center + Vector2(16 * s, 65 * s), Color(col.r, col.g, col.b, 0.6), 4.0 * s)
	# 脚部发光
	_draw_glow_circle(c, center + Vector2(-16 * s, 68 * s), 4 * s, Color(cyan.r, cyan.g, cyan.b, 0.4))
	_draw_glow_circle(c, center + Vector2(16 * s, 68 * s), 4 * s, Color(cyan.r, cyan.g, cyan.b, 0.4))

	# 躯干（梯形装甲）
	var body_pts: PackedVector2Array = PackedVector2Array([
		center + Vector2(-22 * s, -25 * s), center + Vector2(22 * s, -25 * s),
		center + Vector2(18 * s, 32 * s), center + Vector2(-18 * s, 32 * s)])
	c.draw_colored_polygon(body_pts, Color(col.r, col.g, col.b, 0.25 + pulse * 0.08))
	for i in range(4):
		c.draw_line(body_pts[i], body_pts[(i + 1) % 4], Color(col.r, col.g, col.b, 0.7), 2.0 * s)

	# 胸甲装饰线
	c.draw_line(center + Vector2(-12 * s, -15 * s), center + Vector2(12 * s, -15 * s), Color(cyan.r, cyan.g, cyan.b, 0.4 + pulse * 0.2), 1.5 * s)
	c.draw_line(center + Vector2(-8 * s, -5 * s), center + Vector2(8 * s, -5 * s), Color(cyan.r, cyan.g, cyan.b, 0.3), 1.0 * s)
	# 核心能量点
	_draw_glow_circle(c, center + Vector2(0, -10 * s), 5 * s, Color(cyan.r, cyan.g, cyan.b, 0.6 + pulse * 0.3))

	# 左臂 + 盾牌
	c.draw_line(center + Vector2(-22 * s, -18 * s), center + Vector2(-38 * s, 5 * s), Color(col.r, col.g, col.b, 0.6), 3.5 * s)
	# 盾牌（六边形）
	var shield_c: Vector2 = center + Vector2(-44 * s, 10 * s)
	var shield_pts: PackedVector2Array = PackedVector2Array()
	for i in range(6):
		var angle: float = PI / 6.0 + float(i) * PI / 3.0
		shield_pts.append(shield_c + Vector2(cos(angle) * 16 * s, sin(angle) * 22 * s))
	c.draw_colored_polygon(shield_pts, Color(cyan.r, cyan.g, cyan.b, 0.2 + pulse * 0.1))
	for i in range(6):
		c.draw_line(shield_pts[i], shield_pts[(i + 1) % 6], Color(cyan.r, cyan.g, cyan.b, 0.8), 2.0 * s)

	# 右臂 + 光刃
	c.draw_line(center + Vector2(22 * s, -18 * s), center + Vector2(38 * s, -5 * s), Color(col.r, col.g, col.b, 0.6), 3.5 * s)
	# 光刃
	var blade_base: Vector2 = center + Vector2(40 * s, -8 * s)
	var blade_tip: Vector2 = center + Vector2(58 * s, -42 * s)
	c.draw_line(blade_base, blade_tip, Color(1.0, 0.9, 0.3, 0.8 + pulse * 0.2), 3.0 * s)
	c.draw_line(blade_base + Vector2(2 * s, 0), blade_tip + Vector2(2 * s, 0), Color(1.0, 1.0, 0.6, 0.3), 1.5 * s)

	# 头部（圆形 + 面罩）
	var head_c: Vector2 = center + Vector2(0, -42 * s)
	_draw_glow_circle(c, head_c, 16 * s, Color(col.r, col.g, col.b, 0.3))
	c.draw_arc(head_c, 16 * s, 0, TAU, 24, Color(col.r, col.g, col.b, 0.7), 2.0 * s)
	# 面罩 V 型护目镜
	c.draw_line(head_c + Vector2(-10 * s, -2 * s), head_c + Vector2(0, 3 * s), Color(cyan.r, cyan.g, cyan.b, 0.9), 2.5 * s)
	c.draw_line(head_c + Vector2(0, 3 * s), head_c + Vector2(10 * s, -2 * s), Color(cyan.r, cyan.g, cyan.b, 0.9), 2.5 * s)

static func draw_enemy(c: CanvasItem, center: Vector2, scale_f: float, pulse: float, encounter_id: String) -> void:
	if encounter_id == "encounter_01":
		_draw_sentinel(c, center, scale_f, pulse)
	elif encounter_id == "encounter_02":
		_draw_cyber_ghost(c, center, scale_f, pulse)
	elif encounter_id == "encounter_03":
		_draw_dark_crawler(c, center, scale_f, pulse)
	elif encounter_id == "encounter_04":
		_draw_pulse_hunter(c, center, scale_f, pulse)
	elif encounter_id == "encounter_05":
		_draw_data_phantom(c, center, scale_f, pulse)
	elif encounter_id == "encounter_boss_01":
		_draw_boss_zero(c, center, scale_f, pulse)
	else:
		_draw_sentinel(c, center, scale_f, pulse)

# --- 异常哨兵：机械巡逻兵，方形身躯 + 扫描眼 ---

static func _draw_sentinel(c: CanvasItem, center: Vector2, s: float, pulse: float) -> void:
	var col: Color = CyberStyle.HP_ENEMY
	var orange: Color = CyberStyle.ACCENT_ORANGE
	# 身体（宽矩形）
	var body_r: Rect2 = Rect2(center + Vector2(-20 * s, -20 * s), Vector2(40 * s, 50 * s))
	c.draw_rect(body_r, Color(col.r, col.g, col.b, 0.25 + pulse * 0.08), true)
	c.draw_rect(body_r, Color(col.r, col.g, col.b, 0.7), false, 2.0 * s)
	# 肩甲
	c.draw_rect(Rect2(center + Vector2(-30 * s, -22 * s), Vector2(10 * s, 18 * s)), Color(col.r, col.g, col.b, 0.4), true)
	c.draw_rect(Rect2(center + Vector2(20 * s, -22 * s), Vector2(10 * s, 18 * s)), Color(col.r, col.g, col.b, 0.4), true)
	# 头部（扫描眼）
	var head_c: Vector2 = center + Vector2(0, -35 * s)
	c.draw_rect(Rect2(head_c + Vector2(-12 * s, -10 * s), Vector2(24 * s, 20 * s)), Color(col.r, col.g, col.b, 0.35), true)
	c.draw_rect(Rect2(head_c + Vector2(-12 * s, -10 * s), Vector2(24 * s, 20 * s)), Color(col.r, col.g, col.b, 0.6), false, 1.5 * s)
	# 扫描眼（水平线 + 脉冲）
	var eye_w: float = 16 * s * (0.7 + pulse * 0.3)
	c.draw_line(head_c + Vector2(-eye_w * 0.5, 0), head_c + Vector2(eye_w * 0.5, 0), Color(orange.r, orange.g, orange.b, 0.9), 3.0 * s)
	_draw_glow_circle(c, head_c, 4 * s, Color(orange.r, orange.g, orange.b, 0.5 + pulse * 0.3))
	# 腿部
	c.draw_line(center + Vector2(-10 * s, 30 * s), center + Vector2(-14 * s, 60 * s), Color(col.r, col.g, col.b, 0.5), 3.5 * s)
	c.draw_line(center + Vector2(10 * s, 30 * s), center + Vector2(14 * s, 60 * s), Color(col.r, col.g, col.b, 0.5), 3.5 * s)

# --- 赛博游魂：飘渺幽灵，波浪形轮廓 ---

static func _draw_cyber_ghost(c: CanvasItem, center: Vector2, s: float, pulse: float) -> void:
	var col: Color = Color(0.7, 0.3, 1.0)
	# 幽灵身体（椭圆形渐隐）
	for i in range(3):
		var r: float = (30 - i * 6) * s
		var a: float = (0.15 - float(i) * 0.04) + pulse * 0.05
		c.draw_arc(center + Vector2(0, -5 * s), r, 0, TAU, 24, Color(col.r, col.g, col.b, a), 2.0 * s)
	# 核心
	_draw_glow_circle(c, center + Vector2(0, -5 * s), 14 * s, Color(col.r, col.g, col.b, 0.3 + pulse * 0.15))
	# 双眼
	_draw_glow_circle(c, center + Vector2(-8 * s, -12 * s), 4 * s, Color(1.0, 0.3, 0.3, 0.8 + pulse * 0.2))
	_draw_glow_circle(c, center + Vector2(8 * s, -12 * s), 4 * s, Color(1.0, 0.3, 0.3, 0.8 + pulse * 0.2))
	# 尾焰（向下飘散）
	for i in range(5):
		var offset_x: float = sin(float(i) * 1.3 + pulse * 3.0) * 8 * s
		var y_off: float = float(i) * 12 * s
		var tail_a: float = 0.4 - float(i) * 0.07
		c.draw_line(center + Vector2(offset_x, 20 * s + y_off), center + Vector2(offset_x + sin(float(i)) * 4 * s, 32 * s + y_off), Color(col.r, col.g, col.b, tail_a), 2.0 * s)

# --- 暗网爬虫：多足蜘蛛形态 ---

static func _draw_dark_crawler(c: CanvasItem, center: Vector2, s: float, pulse: float) -> void:
	var col: Color = Color(0.4, 0.9, 0.3)
	# 身体（椭圆）
	_draw_glow_circle(c, center, 22 * s, Color(col.r, col.g, col.b, 0.2 + pulse * 0.08))
	c.draw_arc(center, 22 * s, 0, TAU, 20, Color(col.r, col.g, col.b, 0.6), 2.0 * s)
	# 6 条腿
	for i in range(6):
		var side: float = -1.0 if i < 3 else 1.0
		var leg_i: int = i % 3
		var angle: float = (-0.4 + float(leg_i) * 0.4) * side
		var base: Vector2 = center + Vector2(side * 20 * s, (-8 + leg_i * 12) * s)
		var knee: Vector2 = base + Vector2(side * 25 * s, -15 * s + sin(pulse * 2.0 + float(i)) * 3 * s)
		var foot: Vector2 = knee + Vector2(side * 15 * s, 20 * s)
		c.draw_line(base, knee, Color(col.r, col.g, col.b, 0.5), 2.0 * s)
		c.draw_line(knee, foot, Color(col.r, col.g, col.b, 0.5), 2.0 * s)
	# 眼簇
	for i in range(4):
		var ex: float = (-6 + float(i) * 4) * s
		var ey: float = (-8 + abs(float(i) - 1.5) * 3) * s
		_draw_glow_circle(c, center + Vector2(ex, ey), 3 * s, Color(1.0, 0.2, 0.2, 0.7 + pulse * 0.2))

# --- 脉冲猎手：纤细高速射手 ---

static func _draw_pulse_hunter(c: CanvasItem, center: Vector2, s: float, pulse: float) -> void:
	var col: Color = Color(1.0, 0.5, 0.15)
	# 纤细身躯
	var body_pts: PackedVector2Array = PackedVector2Array([
		center + Vector2(-10 * s, -25 * s), center + Vector2(10 * s, -25 * s),
		center + Vector2(8 * s, 35 * s), center + Vector2(-8 * s, 35 * s)])
	c.draw_colored_polygon(body_pts, Color(col.r, col.g, col.b, 0.2 + pulse * 0.06))
	for i in range(4):
		c.draw_line(body_pts[i], body_pts[(i + 1) % 4], Color(col.r, col.g, col.b, 0.65), 1.5 * s)
	# 头部（尖锐三角）
	var head_pts: PackedVector2Array = PackedVector2Array([
		center + Vector2(0, -50 * s), center + Vector2(-12 * s, -25 * s), center + Vector2(12 * s, -25 * s)])
	c.draw_colored_polygon(head_pts, Color(col.r, col.g, col.b, 0.3))
	for i in range(3):
		c.draw_line(head_pts[i], head_pts[(i + 1) % 3], Color(col.r, col.g, col.b, 0.7), 2.0 * s)
	# 单眼
	_draw_glow_circle(c, center + Vector2(0, -35 * s), 5 * s, Color(1.0, 0.8, 0.1, 0.8 + pulse * 0.2))
	# 双臂持枪
	c.draw_line(center + Vector2(10 * s, -15 * s), center + Vector2(35 * s, -20 * s), Color(col.r, col.g, col.b, 0.55), 2.5 * s)
	c.draw_line(center + Vector2(35 * s, -20 * s), center + Vector2(55 * s, -25 * s), Color(1.0, 0.8, 0.2, 0.6 + pulse * 0.3), 3.0 * s)
	# 腿部
	c.draw_line(center + Vector2(-6 * s, 35 * s), center + Vector2(-12 * s, 62 * s), Color(col.r, col.g, col.b, 0.45), 2.5 * s)
	c.draw_line(center + Vector2(6 * s, 35 * s), center + Vector2(12 * s, 62 * s), Color(col.r, col.g, col.b, 0.45), 2.5 * s)

# --- 数据幽灵：半透明电子体 ---

static func _draw_data_phantom(c: CanvasItem, center: Vector2, s: float, pulse: float) -> void:
	var col: Color = Color(0.3, 0.6, 1.0)
	# 数据流外圈
	for i in range(8):
		var angle: float = float(i) * TAU / 8.0 + pulse * 0.5
		var r: float = 35 * s
		var pt: Vector2 = center + Vector2(cos(angle) * r, sin(angle) * r * 0.7)
		c.draw_line(center, pt, Color(col.r, col.g, col.b, 0.1 + pulse * 0.05), 1.0 * s)
	# 核心菱形
	var diamond: PackedVector2Array = PackedVector2Array([
		center + Vector2(0, -30 * s), center + Vector2(20 * s, 0),
		center + Vector2(0, 30 * s), center + Vector2(-20 * s, 0)])
	c.draw_colored_polygon(diamond, Color(col.r, col.g, col.b, 0.15 + pulse * 0.08))
	for i in range(4):
		c.draw_line(diamond[i], diamond[(i + 1) % 4], Color(col.r, col.g, col.b, 0.6 + pulse * 0.2), 2.0 * s)
	# 面部（两点 + 横线）
	_draw_glow_circle(c, center + Vector2(-7 * s, -8 * s), 3 * s, Color(1.0, 1.0, 1.0, 0.7))
	_draw_glow_circle(c, center + Vector2(7 * s, -8 * s), 3 * s, Color(1.0, 1.0, 1.0, 0.7))
	c.draw_line(center + Vector2(-6 * s, 3 * s), center + Vector2(6 * s, 3 * s), Color(col.r, col.g, col.b, 0.5), 1.5 * s)

# --- Boss 零号协议：巨型赛博体 ---

static func _draw_boss_zero(c: CanvasItem, center: Vector2, s: float, pulse: float) -> void:
	var col: Color = Color(1.0, 0.2, 0.15)
	var gold: Color = CyberStyle.NEON_GOLD
	# 身体光晕（大范围）
	_draw_glow_circle(c, center, 65 * s, Color(col.r, col.g, col.b, 0.05 + pulse * 0.03))
	# 巨型躯干
	var body: PackedVector2Array = PackedVector2Array([
		center + Vector2(-30 * s, -35 * s), center + Vector2(30 * s, -35 * s),
		center + Vector2(25 * s, 40 * s), center + Vector2(-25 * s, 40 * s)])
	c.draw_colored_polygon(body, Color(col.r, col.g, col.b, 0.3 + pulse * 0.08))
	for i in range(4):
		c.draw_line(body[i], body[(i + 1) % 4], Color(col.r, col.g, col.b, 0.8), 2.5 * s)
	# 装甲纹路
	c.draw_line(center + Vector2(0, -35 * s), center + Vector2(0, 40 * s), Color(gold.r, gold.g, gold.b, 0.3), 1.5 * s)
	c.draw_line(center + Vector2(-20 * s, 0), center + Vector2(20 * s, 0), Color(gold.r, gold.g, gold.b, 0.25), 1.0 * s)
	# 肩甲（巨大）
	c.draw_rect(Rect2(center + Vector2(-48 * s, -38 * s), Vector2(18 * s, 28 * s)), Color(col.r, col.g, col.b, 0.4), true)
	c.draw_rect(Rect2(center + Vector2(-48 * s, -38 * s), Vector2(18 * s, 28 * s)), Color(col.r, col.g, col.b, 0.6), false, 2.0 * s)
	c.draw_rect(Rect2(center + Vector2(30 * s, -38 * s), Vector2(18 * s, 28 * s)), Color(col.r, col.g, col.b, 0.4), true)
	c.draw_rect(Rect2(center + Vector2(30 * s, -38 * s), Vector2(18 * s, 28 * s)), Color(col.r, col.g, col.b, 0.6), false, 2.0 * s)
	# 头部（带冠）
	var head_c: Vector2 = center + Vector2(0, -52 * s)
	c.draw_arc(head_c, 18 * s, 0, TAU, 24, Color(col.r, col.g, col.b, 0.7), 2.5 * s)
	_draw_glow_circle(c, head_c, 15 * s, Color(col.r, col.g, col.b, 0.3))
	# 三眼
	_draw_glow_circle(c, head_c + Vector2(-8 * s, -2 * s), 4 * s, Color(gold.r, gold.g, gold.b, 0.9))
	_draw_glow_circle(c, head_c + Vector2(8 * s, -2 * s), 4 * s, Color(gold.r, gold.g, gold.b, 0.9))
	_draw_glow_circle(c, head_c + Vector2(0, -10 * s), 3 * s, Color(1.0, 0.1, 0.1, 0.8 + pulse * 0.2))
	# 冠部
	c.draw_line(head_c + Vector2(-15 * s, -15 * s), head_c + Vector2(0, -28 * s), Color(gold.r, gold.g, gold.b, 0.6), 2.0 * s)
	c.draw_line(head_c + Vector2(15 * s, -15 * s), head_c + Vector2(0, -28 * s), Color(gold.r, gold.g, gold.b, 0.6), 2.0 * s)
	# 腿部
	c.draw_line(center + Vector2(-14 * s, 40 * s), center + Vector2(-18 * s, 70 * s), Color(col.r, col.g, col.b, 0.55), 4.0 * s)
	c.draw_line(center + Vector2(14 * s, 40 * s), center + Vector2(18 * s, 70 * s), Color(col.r, col.g, col.b, 0.55), 4.0 * s)

# --- 辅助方法 ---

static func _draw_glow_circle(c: CanvasItem, pos: Vector2, radius: float, col: Color) -> void:
	# 外层柔和光晕
	c.draw_circle(pos, radius * 1.4, Color(col.r, col.g, col.b, col.a * 0.3))
	c.draw_circle(pos, radius, col)
