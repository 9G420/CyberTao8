extends RefCounted
class_name BattleCharRenderer

const UnitMeshFactory3D = preload("res://Scripts/UI3D/UnitMeshFactory3D.gd")

static var _portrait_cache: Dictionary = {}

## 卡牌战斗角色渲染器 — Cult of the Lamb 风格重绘
## 可爱 chibi 比例：超大圆头、小身体、大眼睛、短粗四肢
## 用于全屏 CardBattlePanel 的角色展示区域（大尺寸立绘）

# --- 角色绘制入口 ---

static func _draw_pixel_portrait(c: CanvasItem, center: Vector2, tex: Texture2D, scale_f: float, pulse: float, tint: Color) -> void:
	if tex == null:
		return
	var size: float = 140.0 * scale_f
	var rect: Rect2 = Rect2(center.x - size * 0.5, center.y - size * 0.72, size, size)
	_draw_glow_circle(c, center + Vector2(0, -10 * scale_f), 42 * scale_f, Color(tint.r, tint.g, tint.b, 0.08 + pulse * 0.04))
	c.draw_texture_rect(tex, rect, false, Color(1, 1, 1, 1))

static func draw_player_hero(c: CanvasItem, center: Vector2, scale_f: float, pulse: float) -> void:
	# v0.1.90：优先使用 UnitMeshFactory3D 的像素纹理，保持棋盘/卡牌战斗角色风格一致
	if not _portrait_cache.has("player"):
		_portrait_cache["player"] = UnitMeshFactory3D._gen_player_hero()
	var p_tex: Texture2D = _portrait_cache.get("player", null)
	if p_tex != null:
		_draw_pixel_portrait(c, center, p_tex, scale_f, pulse, CyberStyle.HP_PLAYER)
		return
	var col: Color = CyberStyle.HP_PLAYER
	var cyan: Color = CyberStyle.ACCENT_CYAN
	var s: float = scale_f

	# --- 身体光晕（背后大圆） ---
	_draw_glow_circle(c, center + Vector2(0, -20 * s), 60 * s, Color(col.r, col.g, col.b, 0.06 + pulse * 0.03))

	# --- 小皇冠/光环（头顶三个金色小三角） ---
	var crown_c: Vector2 = center + Vector2(0, -62 * s)
	var gold_crown: Color = Color(1.0, 0.85, 0.2, 0.8)
	for i in range(3):
		var cx: float = (-8.0 + float(i) * 8.0) * s
		var tri: PackedVector2Array = PackedVector2Array([
			crown_c + Vector2(cx, 0),
			crown_c + Vector2(cx - 3.5 * s, 6 * s),
			crown_c + Vector2(cx + 3.5 * s, 6 * s)])
		c.draw_colored_polygon(tri, gold_crown)

	# --- 大圆头 ---
	var head_c: Vector2 = center + Vector2(0, -40 * s)
	var head_r: float = 18 * s
	# 头部填充
	c.draw_circle(head_c, head_r, Color(col.r, col.g, col.b, 0.28 + pulse * 0.06))
	c.draw_arc(head_c, head_r, 0, TAU, 32, Color(col.r, col.g, col.b, 0.75), 2.5 * s)
	# V 型护目镜（赛博朋克标志）
	var visor_col: Color = Color(cyan.r, cyan.g, cyan.b, 0.85 + pulse * 0.15)
	c.draw_line(head_c + Vector2(-12 * s, -1 * s), head_c + Vector2(0, 5 * s), visor_col, 3.0 * s)
	c.draw_line(head_c + Vector2(0, 5 * s), head_c + Vector2(12 * s, -1 * s), visor_col, 3.0 * s)
	# 两只大圆眼（白底 + 青色瞳孔）
	var eye_r: float = 5.5 * s
	var pupil_r: float = 2.0 * s
	for side in [-1.0, 1.0]:
		var eye_pos: Vector2 = head_c + Vector2(side * 7 * s, -3 * s)
		c.draw_circle(eye_pos, eye_r, Color(1.0, 1.0, 1.0, 0.9))
		c.draw_circle(eye_pos + Vector2(side * 1.0 * s, 1.0 * s), pupil_r, Color(cyan.r, cyan.g, cyan.b, 0.95))

	# --- 小圆润身体（梯形/椭圆感） ---
	var body_pts: PackedVector2Array = PackedVector2Array([
		center + Vector2(-14 * s, -22 * s), center + Vector2(14 * s, -22 * s),
		center + Vector2(16 * s, 12 * s), center + Vector2(-16 * s, 12 * s)])
	c.draw_colored_polygon(body_pts, Color(col.r, col.g, col.b, 0.25 + pulse * 0.07))
	for i in range(4):
		c.draw_line(body_pts[i], body_pts[(i + 1) % 4], Color(col.r, col.g, col.b, 0.65), 2.0 * s)
	# 胸部能量核心（小青色发光点）
	_draw_glow_circle(c, center + Vector2(0, -6 * s), 4.0 * s, Color(cyan.r, cyan.g, cyan.b, 0.7 + pulse * 0.25))

	# --- 左臂 + 六边形盾牌 ---
	c.draw_line(center + Vector2(-14 * s, -14 * s), center + Vector2(-30 * s, 2 * s), Color(col.r, col.g, col.b, 0.6), 4.0 * s)
	var shield_c: Vector2 = center + Vector2(-38 * s, 6 * s)
	var shield_pts: PackedVector2Array = PackedVector2Array()
	for i in range(6):
		var angle: float = PI / 6.0 + float(i) * PI / 3.0
		shield_pts.append(shield_c + Vector2(cos(angle) * 14 * s, sin(angle) * 19 * s))
	c.draw_colored_polygon(shield_pts, Color(cyan.r, cyan.g, cyan.b, 0.2 + pulse * 0.1))
	for i in range(6):
		c.draw_line(shield_pts[i], shield_pts[(i + 1) % 6], Color(cyan.r, cyan.g, cyan.b, 0.8), 2.0 * s)
	# 盾牌中心光点
	_draw_glow_circle(c, shield_c, 4 * s, Color(cyan.r, cyan.g, cyan.b, 0.5 + pulse * 0.2))

	# --- 右臂 + 光刃 ---
	c.draw_line(center + Vector2(14 * s, -14 * s), center + Vector2(30 * s, -4 * s), Color(col.r, col.g, col.b, 0.6), 4.0 * s)
	var blade_base: Vector2 = center + Vector2(32 * s, -6 * s)
	var blade_tip: Vector2 = center + Vector2(52 * s, -38 * s)
	c.draw_line(blade_base, blade_tip, Color(1.0, 0.9, 0.3, 0.85 + pulse * 0.15), 3.5 * s)
	c.draw_line(blade_base + Vector2(2 * s, 0), blade_tip + Vector2(2 * s, 0), Color(1.0, 1.0, 0.6, 0.3), 2.0 * s)
	# 刀柄小发光
	_draw_glow_circle(c, blade_base, 3 * s, Color(1.0, 0.9, 0.3, 0.4))

	# --- 短粗小腿 + 脚部发光 ---
	c.draw_line(center + Vector2(-8 * s, 12 * s), center + Vector2(-10 * s, 30 * s), Color(col.r, col.g, col.b, 0.6), 5.0 * s)
	c.draw_line(center + Vector2(8 * s, 12 * s), center + Vector2(10 * s, 30 * s), Color(col.r, col.g, col.b, 0.6), 5.0 * s)
	_draw_glow_circle(c, center + Vector2(-10 * s, 32 * s), 4.5 * s, Color(cyan.r, cyan.g, cyan.b, 0.4 + pulse * 0.15))
	_draw_glow_circle(c, center + Vector2(10 * s, 32 * s), 4.5 * s, Color(cyan.r, cyan.g, cyan.b, 0.4 + pulse * 0.15))

static func draw_enemy(c: CanvasItem, center: Vector2, scale_f: float, pulse: float, encounter_id: String) -> void:
	# v0.1.90：优先使用 UnitMeshFactory3D 的敌方像素纹理（与3D棋盘美术同步）
	var key: String = "enemy_" + encounter_id
	if not _portrait_cache.has(key):
		_portrait_cache[key] = UnitMeshFactory3D._gen_enemy_by_id(encounter_id)
	var e_tex: Texture2D = _portrait_cache.get(key, null)
	if e_tex != null:
		_draw_pixel_portrait(c, center, e_tex, scale_f, pulse, CyberStyle.HP_ENEMY)
		return
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
	elif encounter_id == "encounter_06":
		_draw_quantum_splitter(c, center, scale_f, pulse)
	elif encounter_id == "encounter_07":
		_draw_cyber_shaman(c, center, scale_f, pulse)
	elif encounter_id == "encounter_boss_01":
		_draw_boss_zero(c, center, scale_f, pulse)
	else:
		_draw_sentinel(c, center, scale_f, pulse)

# --- 异常哨兵 Sentinel: 可爱方头机器人 ---

static func _draw_sentinel(c: CanvasItem, center: Vector2, s: float, pulse: float) -> void:
	var col: Color = CyberStyle.HP_ENEMY
	var orange: Color = CyberStyle.ACCENT_ORANGE

	# --- 短粗机械腿 ---
	c.draw_line(center + Vector2(-9 * s, 14 * s), center + Vector2(-11 * s, 32 * s), Color(col.r, col.g, col.b, 0.55), 5.0 * s)
	c.draw_line(center + Vector2(9 * s, 14 * s), center + Vector2(11 * s, 32 * s), Color(col.r, col.g, col.b, 0.55), 5.0 * s)
	# 脚部小方块
	c.draw_rect(Rect2(center + Vector2(-15 * s, 30 * s), Vector2(8 * s, 4 * s)), Color(col.r, col.g, col.b, 0.5), true)
	c.draw_rect(Rect2(center + Vector2(7 * s, 30 * s), Vector2(8 * s, 4 * s)), Color(col.r, col.g, col.b, 0.5), true)

	# --- 圆润方形身体 ---
	var body_r: Rect2 = Rect2(center + Vector2(-16 * s, -16 * s), Vector2(32 * s, 32 * s))
	c.draw_rect(body_r, Color(col.r, col.g, col.b, 0.25 + pulse * 0.07), true)
	c.draw_rect(body_r, Color(col.r, col.g, col.b, 0.65), false, 2.0 * s)
	# 橙色装饰线
	c.draw_line(center + Vector2(-12 * s, -4 * s), center + Vector2(12 * s, -4 * s), Color(orange.r, orange.g, orange.b, 0.35), 1.5 * s)
	c.draw_line(center + Vector2(-12 * s, 6 * s), center + Vector2(12 * s, 6 * s), Color(orange.r, orange.g, orange.b, 0.25), 1.0 * s)

	# --- 圆润肩甲 ---
	_draw_glow_circle(c, center + Vector2(-22 * s, -10 * s), 8 * s, Color(col.r, col.g, col.b, 0.3))
	c.draw_arc(center + Vector2(-22 * s, -10 * s), 8 * s, 0, TAU, 16, Color(col.r, col.g, col.b, 0.55), 1.5 * s)
	_draw_glow_circle(c, center + Vector2(22 * s, -10 * s), 8 * s, Color(col.r, col.g, col.b, 0.3))
	c.draw_arc(center + Vector2(22 * s, -10 * s), 8 * s, 0, TAU, 16, Color(col.r, col.g, col.b, 0.55), 1.5 * s)

	# --- 大圆润方形头（平顶） ---
	var head_c: Vector2 = center + Vector2(0, -32 * s)
	var head_w: float = 20 * s
	var head_h: float = 16 * s
	c.draw_rect(Rect2(head_c + Vector2(-head_w * 0.5, -head_h * 0.5), Vector2(head_w, head_h)),
		Color(col.r, col.g, col.b, 0.35), true)
	c.draw_rect(Rect2(head_c + Vector2(-head_w * 0.5, -head_h * 0.5), Vector2(head_w, head_h)),
		Color(col.r, col.g, col.b, 0.7), false, 2.0 * s)

	# 小天线
	c.draw_line(head_c + Vector2(0, -head_h * 0.5), head_c + Vector2(0, -head_h * 0.5 - 10 * s), Color(col.r, col.g, col.b, 0.6), 2.0 * s)
	_draw_glow_circle(c, head_c + Vector2(0, -head_h * 0.5 - 11 * s), 3 * s, Color(orange.r, orange.g, orange.b, 0.7 + pulse * 0.3))

	# 宽扫描眼（水平橙色线 + 发光）
	var eye_w: float = 14 * s * (0.75 + pulse * 0.25)
	c.draw_line(head_c + Vector2(-eye_w * 0.5, 0), head_c + Vector2(eye_w * 0.5, 0), Color(orange.r, orange.g, orange.b, 0.9), 3.5 * s)
	_draw_glow_circle(c, head_c, 5 * s, Color(orange.r, orange.g, orange.b, 0.4 + pulse * 0.3))

# --- 赛博游魂 Cyber Ghost: 可爱圆胖幽灵 ---

static func _draw_cyber_ghost(c: CanvasItem, center: Vector2, s: float, pulse: float) -> void:
	var col: Color = Color(0.7, 0.3, 1.0)

	# --- 多层紫色以太光晕 ---
	for i in range(3):
		var r: float = (40 - i * 10) * s
		var a: float = (0.08 - float(i) * 0.02) + pulse * 0.03
		_draw_glow_circle(c, center + Vector2(0, -8 * s), r, Color(col.r, col.g, col.b, a))

	# --- 大圆胖身体（无腿） ---
	var body_c: Vector2 = center + Vector2(0, -8 * s)
	var body_r: float = 22 * s
	c.draw_circle(body_c, body_r, Color(col.r, col.g, col.b, 0.25 + pulse * 0.1))
	c.draw_arc(body_c, body_r, 0, TAU, 32, Color(col.r, col.g, col.b, 0.55), 2.0 * s)

	# --- 波浪形底部（多段弧线） ---
	var wave_y: float = center.y + 14 * s
	for i in range(5):
		var wx: float = center.x + (-16 + i * 8) * s
		var arc_r: float = 5 * s
		c.draw_arc(Vector2(wx, wave_y), arc_r, 0, PI, 8, Color(col.r, col.g, col.b, 0.45), 2.0 * s)

	# --- 两只大愤怒红眼 + 发光 ---
	for side in [-1.0, 1.0]:
		var eye_pos: Vector2 = body_c + Vector2(side * 8 * s, -3 * s)
		_draw_glow_circle(c, eye_pos, 5.5 * s, Color(1.0, 0.2, 0.2, 0.75 + pulse * 0.2))
		c.draw_circle(eye_pos, 3.5 * s, Color(1.0, 0.4, 0.3, 0.95))
		# 愤怒眉毛（斜线）
		c.draw_line(eye_pos + Vector2(-side * 4 * s, -5 * s), eye_pos + Vector2(side * 2 * s, -7 * s),
			Color(col.r, col.g, col.b, 0.7), 2.0 * s)

	# --- 飘散尾焰（5条渐隐波浪线） ---
	for i in range(5):
		var base_x: float = center.x + (-12 + i * 6) * s
		var tail_a: float = 0.45 - float(i) * 0.07
		var tail_len: float = (20 + float(i) * 8) * s
		for seg in range(4):
			var y0: float = center.y + 18 * s + float(seg) * tail_len * 0.25
			var y1: float = y0 + tail_len * 0.25
			var wobble: float = sin(float(i) * 1.5 + float(seg) * 1.2 + pulse * 3.0) * 5 * s
			c.draw_line(Vector2(base_x + wobble, y0), Vector2(base_x - wobble, y1),
				Color(col.r, col.g, col.b, tail_a - float(seg) * 0.08), 1.5 * s)

# --- 暗网爬虫 Dark Crawler: 可爱甲虫 ---

static func _draw_dark_crawler(c: CanvasItem, center: Vector2, s: float, pulse: float) -> void:
	var col: Color = Color(0.4, 0.9, 0.3)

	# --- 绿色光晕 ---
	_draw_glow_circle(c, center, 35 * s, Color(col.r, col.g, col.b, 0.06 + pulse * 0.03))

	# --- 大圆身体（甲虫壳） ---
	var body_c: Vector2 = center + Vector2(0, 2 * s)
	var body_r: float = 20 * s
	c.draw_circle(body_c, body_r, Color(col.r, col.g, col.b, 0.22 + pulse * 0.07))
	c.draw_arc(body_c, body_r, 0, TAU, 32, Color(col.r, col.g, col.b, 0.6), 2.5 * s)
	# 壳纹（中线）
	c.draw_line(body_c + Vector2(0, -body_r * 0.7), body_c + Vector2(0, body_r * 0.7),
		Color(col.r, col.g, col.b, 0.3), 1.5 * s)

	# --- 小钳子（前方） ---
	for side in [-1.0, 1.0]:
		var pincer_base: Vector2 = body_c + Vector2(side * 8 * s, -body_r + 2 * s)
		var pincer_tip: Vector2 = pincer_base + Vector2(side * 6 * s, -8 * s)
		var pincer_inner: Vector2 = pincer_base + Vector2(side * 2 * s, -10 * s)
		c.draw_line(pincer_base, pincer_tip, Color(col.r, col.g, col.b, 0.7), 2.5 * s)
		c.draw_line(pincer_tip, pincer_inner, Color(col.r, col.g, col.b, 0.5), 2.0 * s)

	# --- 6条关节腿 ---
	for i in range(6):
		var side: float = -1.0 if i < 3 else 1.0
		var leg_i: int = i % 3
		var base_y: float = (-6 + leg_i * 10) * s
		var base: Vector2 = body_c + Vector2(side * body_r * 0.9, base_y)
		var knee: Vector2 = base + Vector2(side * 18 * s, -10 * s + sin(pulse * 2.0 + float(i) * 0.8) * 3 * s)
		var foot: Vector2 = knee + Vector2(side * 10 * s, 16 * s)
		c.draw_line(base, knee, Color(col.r, col.g, col.b, 0.55), 2.5 * s)
		c.draw_line(knee, foot, Color(col.r, col.g, col.b, 0.55), 2.5 * s)
		# 关节点
		c.draw_circle(knee, 2.0 * s, Color(col.r, col.g, col.b, 0.6))

	# --- 4只小红眼簇 ---
	var eye_positions: Array = [
		Vector2(-5 * s, -6 * s), Vector2(5 * s, -6 * s),
		Vector2(-3 * s, -12 * s), Vector2(3 * s, -12 * s)]
	for ep in eye_positions:
		_draw_glow_circle(c, body_c + ep, 3.0 * s, Color(1.0, 0.2, 0.2, 0.7 + pulse * 0.2))

# --- 脉冲猎手 Pulse Hunter: 狐狸猎手 ---

static func _draw_pulse_hunter(c: CanvasItem, center: Vector2, s: float, pulse: float) -> void:
	var col: Color = Color(1.0, 0.5, 0.15)

	# --- 细长腿 ---
	c.draw_line(center + Vector2(-6 * s, 15 * s), center + Vector2(-10 * s, 38 * s), Color(col.r, col.g, col.b, 0.5), 3.0 * s)
	c.draw_line(center + Vector2(6 * s, 15 * s), center + Vector2(10 * s, 38 * s), Color(col.r, col.g, col.b, 0.5), 3.0 * s)

	# --- 修长锥形身体 ---
	var body_pts: PackedVector2Array = PackedVector2Array([
		center + Vector2(-10 * s, -18 * s), center + Vector2(10 * s, -18 * s),
		center + Vector2(7 * s, 16 * s), center + Vector2(-7 * s, 16 * s)])
	c.draw_colored_polygon(body_pts, Color(col.r, col.g, col.b, 0.2 + pulse * 0.06))
	for i in range(4):
		c.draw_line(body_pts[i], body_pts[(i + 1) % 4], Color(col.r, col.g, col.b, 0.6), 1.5 * s)

	# --- 尖三角头（狐狸/猎食者风格） ---
	var head_c: Vector2 = center + Vector2(0, -32 * s)
	var head_pts: PackedVector2Array = PackedVector2Array([
		head_c + Vector2(0, -18 * s),  # 尖顶
		head_c + Vector2(-14 * s, 8 * s),
		head_c + Vector2(14 * s, 8 * s)])
	c.draw_colored_polygon(head_pts, Color(col.r, col.g, col.b, 0.3 + pulse * 0.05))
	for i in range(3):
		c.draw_line(head_pts[i], head_pts[(i + 1) % 3], Color(col.r, col.g, col.b, 0.7), 2.0 * s)
	# 耳朵尖角（两侧小三角）
	for side in [-1.0, 1.0]:
		var ear_base: Vector2 = head_c + Vector2(side * 10 * s, -6 * s)
		var ear_tip: Vector2 = head_c + Vector2(side * 16 * s, -18 * s)
		c.draw_line(ear_base, ear_tip, Color(col.r, col.g, col.b, 0.6), 2.0 * s)

	# --- 单只大发光黄眼 ---
	_draw_glow_circle(c, head_c + Vector2(0, -2 * s), 6 * s, Color(1.0, 0.85, 0.1, 0.8 + pulse * 0.2))
	c.draw_circle(head_c + Vector2(0, -2 * s), 3 * s, Color(1.0, 0.95, 0.6, 0.95))

	# --- 右臂伸出持枪 ---
	c.draw_line(center + Vector2(10 * s, -10 * s), center + Vector2(28 * s, -16 * s), Color(col.r, col.g, col.b, 0.55), 3.0 * s)
	# 枪身
	var gun_start: Vector2 = center + Vector2(28 * s, -16 * s)
	var gun_end: Vector2 = center + Vector2(52 * s, -20 * s)
	c.draw_line(gun_start, gun_end, Color(col.r, col.g, col.b, 0.7), 3.5 * s)
	# 枪口发光
	_draw_glow_circle(c, gun_end, 4 * s, Color(1.0, 0.7, 0.15, 0.5 + pulse * 0.3))
	# 枪身橙色高光
	c.draw_line(gun_start + Vector2(4 * s, -2 * s), gun_end + Vector2(-4 * s, -2 * s),
		Color(col.r, col.g, col.b, 0.4), 1.5 * s)

# --- 数据幽灵 Data Phantom: 飘浮菱形体 ---

static func _draw_data_phantom(c: CanvasItem, center: Vector2, s: float, pulse: float) -> void:
	var col: Color = Color(0.3, 0.6, 1.0)

	# --- 蓝色以太光晕 ---
	_draw_glow_circle(c, center, 40 * s, Color(col.r, col.g, col.b, 0.06 + pulse * 0.03))

	# --- 8条辐射数据线 ---
	for i in range(8):
		var angle: float = float(i) * TAU / 8.0 + pulse * 0.5
		var r_inner: float = 22 * s
		var r_outer: float = 38 * s
		var pt_inner: Vector2 = center + Vector2(cos(angle) * r_inner, sin(angle) * r_inner * 0.75)
		var pt_outer: Vector2 = center + Vector2(cos(angle) * r_outer, sin(angle) * r_outer * 0.75)
		c.draw_line(pt_inner, pt_outer, Color(col.r, col.g, col.b, 0.12 + pulse * 0.06), 1.0 * s)
		# 数据点
		c.draw_circle(pt_outer, 1.5 * s, Color(col.r, col.g, col.b, 0.25 + pulse * 0.1))

	# --- 菱形核心身体 ---
	var diamond: PackedVector2Array = PackedVector2Array([
		center + Vector2(0, -28 * s), center + Vector2(18 * s, 0),
		center + Vector2(0, 28 * s), center + Vector2(-18 * s, 0)])
	c.draw_colored_polygon(diamond, Color(col.r, col.g, col.b, 0.15 + pulse * 0.08))
	for i in range(4):
		c.draw_line(diamond[i], diamond[(i + 1) % 4], Color(col.r, col.g, col.b, 0.65 + pulse * 0.2), 2.5 * s)
	# 内部小菱形
	var inner_diamond: PackedVector2Array = PackedVector2Array([
		center + Vector2(0, -14 * s), center + Vector2(9 * s, 0),
		center + Vector2(0, 14 * s), center + Vector2(-9 * s, 0)])
	for i in range(4):
		c.draw_line(inner_diamond[i], inner_diamond[(i + 1) % 4], Color(col.r, col.g, col.b, 0.25), 1.0 * s)

	# --- 两只柔和白色发光眼 ---
	for side in [-1.0, 1.0]:
		var eye_pos: Vector2 = center + Vector2(side * 6 * s, -6 * s)
		_draw_glow_circle(c, eye_pos, 3.5 * s, Color(1.0, 1.0, 1.0, 0.65 + pulse * 0.15))

	# --- 小水平线嘴巴 ---
	c.draw_line(center + Vector2(-5 * s, 4 * s), center + Vector2(5 * s, 4 * s), Color(col.r, col.g, col.b, 0.45), 1.5 * s)

# --- Boss 零号协议 Boss Zero Protocol: 巨型可爱暴君 ---

static func _draw_boss_zero(c: CanvasItem, center: Vector2, s: float, pulse: float) -> void:
	var col: Color = Color(1.0, 0.2, 0.15)
	var gold: Color = CyberStyle.NEON_GOLD

	# --- 红色恐怖光晕（全身） ---
	_draw_glow_circle(c, center + Vector2(0, -10 * s), 70 * s, Color(col.r, col.g, col.b, 0.06 + pulse * 0.04))
	_draw_glow_circle(c, center + Vector2(0, -10 * s), 50 * s, Color(col.r, col.g, col.b, 0.04 + pulse * 0.03))

	# --- 粗壮短腿 ---
	c.draw_line(center + Vector2(-14 * s, 30 * s), center + Vector2(-16 * s, 55 * s), Color(col.r, col.g, col.b, 0.55), 6.0 * s)
	c.draw_line(center + Vector2(14 * s, 30 * s), center + Vector2(16 * s, 55 * s), Color(col.r, col.g, col.b, 0.55), 6.0 * s)
	# 脚部
	c.draw_rect(Rect2(center + Vector2(-22 * s, 53 * s), Vector2(12 * s, 5 * s)), Color(col.r, col.g, col.b, 0.5), true)
	c.draw_rect(Rect2(center + Vector2(10 * s, 53 * s), Vector2(12 * s, 5 * s)), Color(col.r, col.g, col.b, 0.5), true)

	# --- 宽大梯形躯干 ---
	var body: PackedVector2Array = PackedVector2Array([
		center + Vector2(-28 * s, -25 * s), center + Vector2(28 * s, -25 * s),
		center + Vector2(22 * s, 32 * s), center + Vector2(-22 * s, 32 * s)])
	c.draw_colored_polygon(body, Color(col.r, col.g, col.b, 0.3 + pulse * 0.08))
	for i in range(4):
		c.draw_line(body[i], body[(i + 1) % 4], Color(col.r, col.g, col.b, 0.8), 2.5 * s)
	# 金色十字装甲纹
	c.draw_line(center + Vector2(0, -25 * s), center + Vector2(0, 32 * s), Color(gold.r, gold.g, gold.b, 0.35), 2.0 * s)
	c.draw_line(center + Vector2(-22 * s, 2 * s), center + Vector2(22 * s, 2 * s), Color(gold.r, gold.g, gold.b, 0.3), 1.5 * s)
	# 额外金色装饰线
	c.draw_line(center + Vector2(-18 * s, -12 * s), center + Vector2(18 * s, -12 * s), Color(gold.r, gold.g, gold.b, 0.2), 1.0 * s)

	# --- 巨大肩甲 ---
	for side in [-1.0, 1.0]:
		var sp_c: Vector2 = center + Vector2(side * 38 * s, -20 * s)
		var sp_pts: PackedVector2Array = PackedVector2Array([
			sp_c + Vector2(0, -16 * s),
			sp_c + Vector2(side * 14 * s, -4 * s),
			sp_c + Vector2(side * 10 * s, 14 * s),
			sp_c + Vector2(-side * 4 * s, 14 * s),
			sp_c + Vector2(-side * 8 * s, -4 * s)])
		c.draw_colored_polygon(sp_pts, Color(col.r, col.g, col.b, 0.35))
		for i in range(5):
			c.draw_line(sp_pts[i], sp_pts[(i + 1) % 5], Color(col.r, col.g, col.b, 0.65), 2.0 * s)
		# 肩甲金色高光
		c.draw_line(sp_c + Vector2(0, -10 * s), sp_c + Vector2(0, 8 * s), Color(gold.r, gold.g, gold.b, 0.3), 1.5 * s)

	# --- 大圆头 ---
	var head_c: Vector2 = center + Vector2(0, -48 * s)
	var head_r: float = 20 * s
	c.draw_circle(head_c, head_r, Color(col.r, col.g, col.b, 0.3 + pulse * 0.06))
	c.draw_arc(head_c, head_r, 0, TAU, 32, Color(col.r, col.g, col.b, 0.75), 2.5 * s)

	# --- 金色皇冠尖刺（3个尖角） ---
	var crown_base_y: float = head_c.y - head_r + 2 * s
	for i in range(3):
		var cx: float = head_c.x + (-10.0 + float(i) * 10.0) * s
		var spike_h: float = (14 + 6 * (1 if i == 1 else 0)) * s  # 中间更高
		var tri: PackedVector2Array = PackedVector2Array([
			Vector2(cx, crown_base_y - spike_h),
			Vector2(cx - 5 * s, crown_base_y),
			Vector2(cx + 5 * s, crown_base_y)])
		c.draw_colored_polygon(tri, Color(gold.r, gold.g, gold.b, 0.7))
		for j in range(3):
			c.draw_line(tri[j], tri[(j + 1) % 3], Color(gold.r, gold.g, gold.b, 0.9), 1.5 * s)
	# 皇冠底部连线
	c.draw_line(Vector2(head_c.x - 15 * s, crown_base_y), Vector2(head_c.x + 15 * s, crown_base_y),
		Color(gold.r, gold.g, gold.b, 0.6), 2.0 * s)

	# --- 三眼：两只金色侧眼 + 一只红色顶眼 ---
	# 侧眼（大）
	for side in [-1.0, 1.0]:
		var eye_pos: Vector2 = head_c + Vector2(side * 8 * s, 2 * s)
		c.draw_circle(eye_pos, 5 * s, Color(gold.r, gold.g, gold.b, 0.85 + pulse * 0.1))
		c.draw_circle(eye_pos, 2.5 * s, Color(0.2, 0.1, 0.0, 0.9))
	# 中央/顶部红眼
	var third_eye: Vector2 = head_c + Vector2(0, -8 * s)
	_draw_glow_circle(c, third_eye, 4.5 * s, Color(1.0, 0.1, 0.1, 0.8 + pulse * 0.2))
	c.draw_circle(third_eye, 2.5 * s, Color(1.0, 0.3, 0.2, 0.95))

# --- 辅助方法 ---

static func _draw_glow_circle(c: CanvasItem, pos: Vector2, radius: float, col: Color) -> void:
	# 外层柔和光晕
	c.draw_circle(pos, radius * 1.4, Color(col.r, col.g, col.b, col.a * 0.3))
	c.draw_circle(pos, radius, col)

# --- 量子分裂体 Quantum Splitter: 分裂菱形晶体 ---

static func _draw_quantum_splitter(c: CanvasItem, center: Vector2, s: float, pulse: float) -> void:
	var col: Color = Color(0.6, 0.2, 0.9)
	var glow: Color = Color(0.8, 0.4, 1.0)
	# 主菱形体
	var body_pts: PackedVector2Array = PackedVector2Array([
		center + Vector2(0, -20 * s),
		center + Vector2(14 * s, 0),
		center + Vector2(0, 20 * s),
		center + Vector2(-14 * s, 0),
	])
	c.draw_colored_polygon(body_pts, Color(col.r, col.g, col.b, 0.7))
	for i in range(4):
		c.draw_line(body_pts[i], body_pts[(i + 1) % 4], Color(glow.r, glow.g, glow.b, 0.8 + pulse * 0.15), 2.0 * s)
	# 中心裂缝光
	c.draw_line(center + Vector2(0, -12 * s), center + Vector2(0, 12 * s), Color(glow.r, glow.g, glow.b, 0.9), 2.5 * s)
	# 分裂碎片（左右浮动）
	var offset_x: float = 18 * s + sin(pulse * 3.0) * 3 * s
	for side in [-1.0, 1.0]:
		var shard_c: Vector2 = center + Vector2(side * offset_x, 0)
		var shard_pts: PackedVector2Array = PackedVector2Array([
			shard_c + Vector2(0, -8 * s),
			shard_c + Vector2(5 * s, 0),
			shard_c + Vector2(0, 8 * s),
			shard_c + Vector2(-5 * s, 0),
		])
		c.draw_colored_polygon(shard_pts, Color(col.r, col.g, col.b, 0.5))
	# 两只眼
	for side in [-1.0, 1.0]:
		var eye_pos: Vector2 = center + Vector2(side * 5 * s, -4 * s)
		_draw_glow_circle(c, eye_pos, 3.5 * s, Color(glow.r, glow.g, glow.b, 0.8 + pulse * 0.15))

# --- 赛博巫医 Cyber Shaman: 兜帽治疗者 ---

static func _draw_cyber_shaman(c: CanvasItem, center: Vector2, s: float, pulse: float) -> void:
	var col: Color = Color(0.15, 0.7, 0.45)
	var glow: Color = Color(0.3, 1.0, 0.6)
	# 兜帽 / 身体 — 三角形
	var hood_pts: PackedVector2Array = PackedVector2Array([
		center + Vector2(0, -24 * s),
		center + Vector2(16 * s, 10 * s),
		center + Vector2(-16 * s, 10 * s),
	])
	c.draw_colored_polygon(hood_pts, Color(col.r, col.g, col.b, 0.6))
	for i in range(3):
		c.draw_line(hood_pts[i], hood_pts[(i + 1) % 3], Color(glow.r, glow.g, glow.b, 0.65), 2.0 * s)
	# 下摆 / 长袍
	var robe_pts: PackedVector2Array = PackedVector2Array([
		center + Vector2(-16 * s, 10 * s),
		center + Vector2(16 * s, 10 * s),
		center + Vector2(12 * s, 32 * s),
		center + Vector2(-12 * s, 32 * s),
	])
	c.draw_colored_polygon(robe_pts, Color(col.r * 0.7, col.g * 0.7, col.b * 0.7, 0.55))
	# 两只发光绿眼
	for side in [-1.0, 1.0]:
		var eye_pos: Vector2 = center + Vector2(side * 5 * s, -6 * s)
		_draw_glow_circle(c, eye_pos, 3 * s, Color(glow.r, glow.g, glow.b, 0.75 + pulse * 0.2))
	# 手持法杖 — 右侧竖线 + 顶部光球
	var staff_base: Vector2 = center + Vector2(18 * s, 8 * s)
	var staff_top: Vector2 = center + Vector2(18 * s, -18 * s)
	c.draw_line(staff_base, staff_top, Color(glow.r, glow.g, glow.b, 0.5), 2.5 * s)
	_draw_glow_circle(c, staff_top, 5 * s, Color(glow.r, glow.g, glow.b, 0.6 + pulse * 0.25))
