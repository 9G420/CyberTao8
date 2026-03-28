class_name PixelArtGenerator
extends RefCounted

# === EVA Color Palette ===
const EVA_PURPLE := Color(0.4, 0.1, 0.6)
const EVA_ORANGE := Color(0.9, 0.5, 0.1)
const EVA_RED := Color(0.7, 0.1, 0.15)
const EVA_CYAN := Color(0.0, 0.8, 0.9)
const EVA_DARK_BLUE := Color(0.05, 0.05, 0.2)
const NEON_PINK := Color(1.0, 0.2, 0.5)
const NEON_GREEN := Color(0.2, 1.0, 0.4)

# === Helpers ===

static func _hash_float(seed_v: int) -> float:
	var s := ((seed_v * 1103515245 + 12345) & 0x7FFFFFFF)
	return float(s) / float(0x7FFFFFFF)

static func _create_image(width: int, height: int) -> Image:
	return Image.create(width, height, false, Image.FORMAT_RGBA8)

static func _set_pixel_safe(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, color)

static func _draw_circle(img: Image, cx: int, cy: int, radius: int, color: Color) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if dx * dx + dy * dy <= radius * radius:
				_set_pixel_safe(img, cx + dx, cy + dy, color)

static func _draw_rect_area(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for py in range(y, y + h):
		for px in range(x, x + w):
			_set_pixel_safe(img, px, py, color)

static func _draw_line_h(img: Image, x1: int, x2: int, y: int, color: Color) -> void:
	var start := mini(x1, x2)
	var end := maxi(x1, x2)
	for px in range(start, end + 1):
		_set_pixel_safe(img, px, y, color)

static func _draw_line_v(img: Image, x: int, y1: int, y2: int, color: Color) -> void:
	var start := mini(y1, y2)
	var end := maxi(y1, y2)
	for py in range(start, end + 1):
		_set_pixel_safe(img, x, py, color)

# === Card Art Generator (64x64) ===

static func generate_card_art(card_type: int, yinyang: int, rarity: int, seed_val: int) -> ImageTexture:
	var img := _create_image(64, 64)
	# Background fill based on yin/yang alignment
	var bg_color: Color
	match yinyang:
		0: bg_color = Color(0.15, 0.05, 0.25) # yin - deep purple
		1: bg_color = Color(0.2, 0.15, 0.05)  # yang - dark gold
		_: bg_color = Color(0.1, 0.1, 0.12)   # neutral gray
	_draw_rect_area(img, 0, 0, 64, 64, bg_color)

	# Card-type-specific motif
	match card_type:
		0: _draw_attack_motif(img, seed_val)
		1: _draw_defense_motif(img, seed_val)
		2: _draw_summon_motif(img, seed_val)
		3: _draw_spell_motif(img, seed_val)
		4: _draw_power_motif(img, seed_val)

	# Scanlines for retro feel (every other row dimmed)
	for y in range(0, 64, 2):
		for x in range(64):
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, c.darkened(0.15))

	# Rarity border glow
	var glow_color: Color
	match rarity:
		0: glow_color = Color(0.4, 0.4, 0.4, 0.6)
		1: glow_color = Color(0.2, 0.4, 1.0, 0.7)
		_: glow_color = Color(0.6, 0.15, 0.9, 0.8)
	_draw_border_glow(img, 64, 64, glow_color, rarity)

	return ImageTexture.create_from_image(img)

static func _draw_border_glow(img: Image, w: int, h_val: int, color: Color, rarity: int) -> void:
	var thickness := 1 + rarity
	for t in range(thickness):
		var alpha_mult := 1.0 - float(t) / float(thickness + 1)
		var c := Color(color.r, color.g, color.b, color.a * alpha_mult)
		_draw_line_h(img, t, w - 1 - t, t, c)
		_draw_line_h(img, t, w - 1 - t, h_val - 1 - t, c)
		_draw_line_v(img, t, t, h_val - 1 - t, c)
		_draw_line_v(img, w - 1 - t, t, h_val - 1 - t, c)

static func _draw_attack_motif(img: Image, seed_val: int) -> void:
	var variant := int(_hash_float(seed_val) * 3.0)
	if variant == 0:
		# === 道剑：赛博符文之刃 ===
		# 剑身（3px宽，渐变青→白）
		for i in range(28):
			var t := float(i) / 28.0
			var blade_col := EVA_CYAN.lerp(Color(0.8, 0.95, 1.0), t * 0.5)
			_set_pixel_safe(img, 31, 6 + i, blade_col.darkened(0.2))
			_set_pixel_safe(img, 32, 6 + i, blade_col)
			_set_pixel_safe(img, 33, 6 + i, blade_col.darkened(0.2))
		# 剑尖（三角形）
		_set_pixel_safe(img, 32, 4, Color(0.7, 1.0, 1.0))
		_set_pixel_safe(img, 32, 5, EVA_CYAN)
		_set_pixel_safe(img, 31, 5, EVA_CYAN.darkened(0.3))
		_set_pixel_safe(img, 33, 5, EVA_CYAN.darkened(0.3))
		# 剑尖发光晕
		_draw_circle(img, 32, 5, 3, Color(0.3, 0.8, 1.0, 0.25))
		# 护手（道教八卦横条 + 橙色）
		_draw_line_h(img, 25, 39, 34, EVA_ORANGE)
		_draw_line_h(img, 25, 39, 35, EVA_ORANGE)
		_draw_line_h(img, 27, 37, 36, EVA_ORANGE.darkened(0.3))
		# 护手两端符文点
		_set_pixel_safe(img, 25, 34, NEON_PINK)
		_set_pixel_safe(img, 39, 34, NEON_PINK)
		# 剑柄
		for i in range(10):
			_set_pixel_safe(img, 32, 37 + i, EVA_RED.darkened(0.1))
			# 缠绕纹
			if i % 3 == 0:
				_set_pixel_safe(img, 31, 37 + i, EVA_ORANGE.darkened(0.4))
				_set_pixel_safe(img, 33, 37 + i, EVA_ORANGE.darkened(0.4))
		# 柄底宝珠
		_draw_circle(img, 32, 48, 2, EVA_PURPLE)
		_set_pixel_safe(img, 32, 48, NEON_PINK)
		# 剑身电路纹（每隔4像素一个节点 + 水平短线）
		for i in range(5):
			var ny := 10 + i * 5
			_set_pixel_safe(img, 30, ny, EVA_CYAN.darkened(0.5))
			_set_pixel_safe(img, 34, ny, EVA_CYAN.darkened(0.5))
			_set_pixel_safe(img, 29, ny, Color(0.0, 0.5, 0.6, 0.4))
			_set_pixel_safe(img, 35, ny, Color(0.0, 0.5, 0.6, 0.4))
		# 两侧道气流（弧形散射粒子）
		for s in range(8):
			var side := -1 if s < 4 else 1
			var idx := s % 4
			var px := 32 + side * (5 + idx * 3)
			var py := 12 + idx * 5
			_set_pixel_safe(img, px, py, Color(0.0, 0.7, 0.9, 0.5))
	elif variant == 1:
		# === 雷符：道教雷法电击 ===
		# 主雷（粗锯齿 Z 形，2px宽）
		var thunder_pts := [Vector2i(22, 8), Vector2i(34, 20), Vector2i(26, 24),
							Vector2i(40, 40), Vector2i(32, 44), Vector2i(38, 54)]
		for idx in range(thunder_pts.size() - 1):
			_draw_pixel_line(img, thunder_pts[idx], thunder_pts[idx + 1], NEON_PINK)
			# 加粗：偏移1像素再画一遍
			var shifted_a := Vector2i(thunder_pts[idx].x + 1, thunder_pts[idx].y)
			var shifted_b := Vector2i(thunder_pts[idx + 1].x + 1, thunder_pts[idx + 1].y)
			_draw_pixel_line(img, shifted_a, shifted_b, NEON_PINK.darkened(0.2))
		# 雷电发光晕（沿路径关键点）
		_draw_circle(img, 34, 20, 3, Color(1.0, 0.4, 0.7, 0.2))
		_draw_circle(img, 40, 40, 4, Color(1.0, 0.4, 0.7, 0.25))
		# 分叉小雷
		_draw_pixel_line(img, Vector2i(34, 20), Vector2i(42, 16), EVA_CYAN)
		_draw_pixel_line(img, Vector2i(26, 24), Vector2i(18, 28), EVA_CYAN)
		_draw_pixel_line(img, Vector2i(40, 40), Vector2i(48, 36), EVA_CYAN)
		# 道教雷符框（顶部）
		_draw_rect_area(img, 16, 4, 32, 2, Color(0.5, 0.2, 0.0, 0.5))
		_draw_line_h(img, 16, 47, 6, EVA_ORANGE.darkened(0.4))
		# 符文点缀
		for s in range(10):
			var px := int(_hash_float(seed_val + s * 7) * 48.0) + 8
			var py := int(_hash_float(seed_val + s * 13) * 48.0) + 8
			_set_pixel_safe(img, px, py, Color(0.6, 0.9, 1.0, 0.7))
			_set_pixel_safe(img, px + 1, py, Color(0.6, 0.9, 1.0, 0.3))
	else:
		# === 双刃太极斩 ===
		# 太极底纹（中心）
		_draw_circle(img, 32, 30, 8, Color(0.15, 0.08, 0.25, 0.6))
		# 阴阳鱼眼
		_draw_circle(img, 32, 26, 2, EVA_CYAN)
		_draw_circle(img, 32, 34, 2, NEON_PINK)
		_set_pixel_safe(img, 32, 26, Color(0.05, 0.05, 0.15))
		_set_pixel_safe(img, 32, 34, Color(0.05, 0.05, 0.15))
		# X型双刃（每条3px宽）
		for i in range(30):
			var t := float(i) / 30.0
			# 左上→右下（青刃）
			var x1 := 8 + i
			var y1 := 8 + i
			var cyan_col := EVA_CYAN.lerp(Color(0.5, 1.0, 1.0), t * 0.3)
			_set_pixel_safe(img, x1, y1, cyan_col)
			_set_pixel_safe(img, x1 - 1, y1, cyan_col.darkened(0.3))
			_set_pixel_safe(img, x1 + 1, y1, cyan_col.darkened(0.3))
			# 右上→左下（粉刃）
			var x2 := 55 - i
			var y2 := 8 + i
			var pink_col := NEON_PINK.lerp(Color(1.0, 0.6, 0.8), t * 0.3)
			_set_pixel_safe(img, x2, y2, pink_col)
			_set_pixel_safe(img, x2 - 1, y2, pink_col.darkened(0.3))
			_set_pixel_safe(img, x2 + 1, y2, pink_col.darkened(0.3))
		# 交叉点爆发
		_draw_circle(img, 32, 30, 5, EVA_ORANGE)
		_draw_circle(img, 32, 30, 3, Color(1.0, 0.9, 0.5))
		_set_pixel_safe(img, 32, 30, Color(1.0, 1.0, 0.9))
		# 四角道气散射
		for corner in [Vector2i(10, 10), Vector2i(54, 10), Vector2i(10, 52), Vector2i(54, 52)]:
			_set_pixel_safe(img, corner.x, corner.y, EVA_PURPLE)
			_set_pixel_safe(img, corner.x + 1, corner.y, EVA_PURPLE.darkened(0.3))
			_set_pixel_safe(img, corner.x, corner.y + 1, EVA_PURPLE.darkened(0.3))

static func _draw_defense_motif(img: Image, seed_val: int) -> void:
	var variant := int(_hash_float(seed_val) * 3.0)
	if variant == 0:
		# === 八卦盾：道教八卦阵防御 ===
		# 外圈（双层环，粗实线）
		for a_step in range(48):
			var a := float(a_step) * TAU / 48.0
			for r in [16, 17, 18]:
				var px := 32 + int(cos(a) * float(r))
				var py := 30 + int(sin(a) * float(r))
				_set_pixel_safe(img, px, py, EVA_CYAN.darkened(0.2))
		# 八卦线段（8条辐射线）
		for i in range(8):
			var a := float(i) * TAU / 8.0
			for r in range(8, 16):
				var px := 32 + int(cos(a) * float(r))
				var py := 30 + int(sin(a) * float(r))
				_set_pixel_safe(img, px, py, EVA_CYAN.darkened(0.5))
		# 中心太极圆
		_draw_circle(img, 32, 30, 7, EVA_DARK_BLUE)
		# 太极 S 曲线
		for s_step in range(20):
			var t := float(s_step) / 20.0
			var sx := 32 + int(sin(t * PI) * 3.0)
			var sy := 23 + int(t * 14.0)
			_set_pixel_safe(img, sx, sy, Color(0.4, 0.4, 0.5))
		# 阴阳鱼眼
		_draw_circle(img, 32, 26, 1, Color(0.9, 0.9, 0.9))
		_draw_circle(img, 32, 34, 1, Color(0.1, 0.1, 0.15))
		# 四角电路端子
		for corner in [Vector2i(14, 12), Vector2i(50, 12), Vector2i(14, 48), Vector2i(50, 48)]:
			_set_pixel_safe(img, corner.x, corner.y, EVA_ORANGE)
			_set_pixel_safe(img, corner.x + 1, corner.y, EVA_ORANGE)
			_set_pixel_safe(img, corner.x, corner.y + 1, EVA_ORANGE)
			_set_pixel_safe(img, corner.x + 1, corner.y + 1, EVA_ORANGE)
		# 护盾脉冲光晕
		_draw_circle(img, 32, 30, 20, Color(0.0, 0.6, 0.8, 0.1))
	elif variant == 1:
		# === 符篆壁障：道教护身符 ===
		# 符纸底板
		_draw_rect_area(img, 16, 6, 32, 52, Color(0.12, 0.08, 0.2))
		# 符纸边框（双线）
		for t in range(2):
			_draw_line_h(img, 16 + t, 47 - t, 6 + t, EVA_ORANGE.darkened(float(t) * 0.3))
			_draw_line_h(img, 16 + t, 47 - t, 57 - t, EVA_ORANGE.darkened(float(t) * 0.3))
			_draw_line_v(img, 16 + t, 6 + t, 57 - t, EVA_ORANGE.darkened(float(t) * 0.3))
			_draw_line_v(img, 47 - t, 6 + t, 57 - t, EVA_ORANGE.darkened(float(t) * 0.3))
		# 符文竖笔画（中央的道教"敕"字简化）
		_draw_line_v(img, 32, 12, 50, EVA_RED)  # 中竖
		_draw_line_h(img, 24, 40, 16, EVA_RED)   # 上横
		_draw_line_h(img, 24, 40, 28, EVA_RED)   # 中横
		# 左右撇捺
		for i in range(8):
			_set_pixel_safe(img, 28 - i, 30 + i, EVA_RED.darkened(0.2))
			_set_pixel_safe(img, 36 + i, 30 + i, EVA_RED.darkened(0.2))
		# 符文四角印章
		_draw_circle(img, 22, 11, 2, NEON_PINK)
		_draw_circle(img, 42, 11, 2, NEON_PINK)
		_draw_circle(img, 22, 52, 2, NEON_PINK)
		_draw_circle(img, 42, 52, 2, NEON_PINK)
		# 电路连接线
		_draw_line_h(img, 20, 24, 20, EVA_CYAN.darkened(0.5))
		_draw_line_h(img, 40, 44, 20, EVA_CYAN.darkened(0.5))
		_draw_line_h(img, 20, 24, 42, EVA_CYAN.darkened(0.5))
		_draw_line_h(img, 40, 44, 42, EVA_CYAN.darkened(0.5))
	else:
		# === 六角结界：赛博蜂巢护盾 ===
		# 六边形外框（大六边形）
		for i in range(6):
			var a1 := float(i) * TAU / 6.0 - PI / 6.0
			var a2 := float(i + 1) * TAU / 6.0 - PI / 6.0
			var p1 := Vector2i(32 + int(cos(a1) * 22.0), 30 + int(sin(a1) * 22.0))
			var p2 := Vector2i(32 + int(cos(a2) * 22.0), 30 + int(sin(a2) * 22.0))
			_draw_pixel_line(img, p1, p2, EVA_CYAN)
			# 加粗内层
			var p3 := Vector2i(32 + int(cos(a1) * 20.0), 30 + int(sin(a1) * 20.0))
			var p4 := Vector2i(32 + int(cos(a2) * 20.0), 30 + int(sin(a2) * 20.0))
			_draw_pixel_line(img, p3, p4, EVA_CYAN.darkened(0.3))
		# 内部蜂巢格（3×3小六边形）
		for row in range(3):
			for col in range(3):
				var hx := 22 + col * 10 - (5 if row == 1 else 0)
				var hy := 18 + row * 10
				for hi in range(6):
					var ha1 := float(hi) * TAU / 6.0 - PI / 6.0
					var ha2 := float(hi + 1) * TAU / 6.0 - PI / 6.0
					var hp1 := Vector2i(hx + int(cos(ha1) * 4.0), hy + int(sin(ha1) * 4.0))
					var hp2 := Vector2i(hx + int(cos(ha2) * 4.0), hy + int(sin(ha2) * 4.0))
					_draw_pixel_line(img, hp1, hp2, Color(0.0, 0.5, 0.6, 0.5))
				# 蜂巢节点
				_set_pixel_safe(img, hx, hy, EVA_ORANGE)
		# 中心能量核心
		_draw_circle(img, 32, 30, 4, Color(0.0, 0.4, 0.5, 0.6))
		_draw_circle(img, 32, 30, 2, EVA_CYAN)
		# 顶底锚点
		_set_pixel_safe(img, 32, 8, NEON_PINK)
		_set_pixel_safe(img, 32, 52, NEON_PINK)

static func _draw_summon_motif(img: Image, seed_val: int) -> void:
	var creature := int(_hash_float(seed_val) * 4.0)
	# Summoning circle base
	_draw_circle(img, 32, 40, 18, Color(0.2, 0.05, 0.3, 0.4))
	_draw_circle(img, 32, 40, 17, Color(0.0, 0.0, 0.0, 0.0))
	# Outer ring
	for angle_step in range(36):
		var a := float(angle_step) * TAU / 36.0
		var rx := 32 + int(cos(a) * 18.0)
		var ry := 40 + int(sin(a) * 18.0)
		_set_pixel_safe(img, rx, ry, EVA_PURPLE)

	if creature == 0:
		# Fox silhouette
		# Body
		_draw_rect_area(img, 26, 28, 12, 8, EVA_ORANGE.darkened(0.2))
		# Head
		_draw_rect_area(img, 29, 22, 6, 7, EVA_ORANGE.darkened(0.1))
		# Ears
		_set_pixel_safe(img, 29, 20, EVA_ORANGE)
		_set_pixel_safe(img, 29, 21, EVA_ORANGE)
		_set_pixel_safe(img, 34, 20, EVA_ORANGE)
		_set_pixel_safe(img, 34, 21, EVA_ORANGE)
		# Tail
		for i in range(6):
			@warning_ignore("integer_division")
			_set_pixel_safe(img, 38 + i, 30 - i / 2, EVA_ORANGE)
			@warning_ignore("integer_division")
			_set_pixel_safe(img, 38 + i, 31 - i / 2, EVA_ORANGE)
		# Eye glow
		_set_pixel_safe(img, 31, 24, EVA_CYAN)
		_set_pixel_safe(img, 33, 24, EVA_CYAN)
	elif creature == 1:
		# Crane silhouette
		# Body
		_draw_rect_area(img, 28, 26, 8, 6, Color(0.85, 0.85, 0.9))
		# Neck
		_draw_line_v(img, 32, 18, 26, Color(0.85, 0.85, 0.9))
		# Head
		_draw_rect_area(img, 31, 16, 3, 3, Color(0.85, 0.85, 0.9))
		# Beak
		_set_pixel_safe(img, 34, 17, EVA_ORANGE)
		_set_pixel_safe(img, 35, 17, EVA_ORANGE)
		# Red crown
		_set_pixel_safe(img, 32, 15, EVA_RED)
		# Legs
		_draw_line_v(img, 30, 32, 40, Color(0.3, 0.3, 0.3))
		_draw_line_v(img, 34, 32, 40, Color(0.3, 0.3, 0.3))
		# Wing spread
		for i in range(8):
			@warning_ignore("integer_division")
			_set_pixel_safe(img, 24 + i, 27 - i / 3, Color(0.7, 0.7, 0.8))
			@warning_ignore("integer_division")
			_set_pixel_safe(img, 36 + i / 2, 27 - i / 3, Color(0.7, 0.7, 0.8))
	elif creature == 2:
		# Dragon silhouette
		# Body
		_draw_rect_area(img, 24, 26, 16, 10, EVA_RED.darkened(0.2))
		# Head
		_draw_rect_area(img, 38, 22, 8, 6, EVA_RED.darkened(0.1))
		# Jaw
		_draw_rect_area(img, 42, 28, 5, 2, EVA_RED.darkened(0.3))
		# Eye
		_set_pixel_safe(img, 43, 23, NEON_GREEN)
		_set_pixel_safe(img, 44, 23, NEON_GREEN)
		# Wings
		for i in range(10):
			@warning_ignore("integer_division")
			_set_pixel_safe(img, 28 + i, 22 - i / 2, EVA_PURPLE)
			@warning_ignore("integer_division")
			_set_pixel_safe(img, 28 + i, 23 - i / 2, EVA_PURPLE)
		# Tail
		for i in range(8):
			@warning_ignore("integer_division")
			_set_pixel_safe(img, 22 - i, 30 + i / 3, EVA_RED.darkened(0.3))
		# Fire breath
		for i in range(4):
			_set_pixel_safe(img, 47 + i, 27, EVA_ORANGE)
			_set_pixel_safe(img, 48 + i, 28, EVA_ORANGE)
	else:
		# Golem silhouette
		# Body
		_draw_rect_area(img, 24, 24, 16, 16, Color(0.25, 0.2, 0.3))
		# Head
		_draw_rect_area(img, 27, 18, 10, 7, Color(0.3, 0.25, 0.35))
		# Eyes
		_set_pixel_safe(img, 30, 21, NEON_PINK)
		_set_pixel_safe(img, 34, 21, NEON_PINK)
		# Arms
		_draw_rect_area(img, 18, 26, 6, 4, Color(0.25, 0.2, 0.3))
		_draw_rect_area(img, 40, 26, 6, 4, Color(0.25, 0.2, 0.3))
		# Rune on chest
		_draw_circle(img, 32, 30, 3, EVA_CYAN)
		_set_pixel_safe(img, 32, 30, Color(0.25, 0.2, 0.3))
		# Legs
		_draw_rect_area(img, 26, 40, 5, 6, Color(0.22, 0.18, 0.28))
		_draw_rect_area(img, 33, 40, 5, 6, Color(0.22, 0.18, 0.28))

static func _draw_spell_motif(img: Image, seed_val: int) -> void:
	var variant := int(_hash_float(seed_val) * 3.0)
	var cx := 32
	var cy := 30
	if variant == 0:
		# === 太极旋涡：阴阳双螺旋法阵 ===
		# 外圈法阵环
		for a_step in range(64):
			var a := float(a_step) * TAU / 64.0
			var px := cx + int(cos(a) * 22.0)
			var py := cy + int(sin(a) * 22.0)
			var ring_col := EVA_PURPLE.lerp(EVA_CYAN, float(a_step) / 64.0)
			_set_pixel_safe(img, px, py, ring_col)
		# 阳螺旋（顺时针，青色）
		for a_step in range(90):
			var a := float(a_step) * TAU / 90.0
			var r := 4.0 + float(a_step) * 0.18
			var px := cx + int(cos(a) * r)
			var py := cy + int(sin(a) * r)
			var col := EVA_CYAN.lerp(Color(0.6, 1.0, 1.0), float(a_step) / 90.0)
			_set_pixel_safe(img, px, py, col)
			_set_pixel_safe(img, px + 1, py, col.darkened(0.4))
		# 阴螺旋（逆时针，紫色）
		for a_step in range(90):
			var a := float(a_step) * TAU / 90.0 + PI
			var r := 4.0 + float(a_step) * 0.18
			var px := cx + int(cos(a) * r)
			var py := cy + int(sin(a) * r)
			var col := EVA_PURPLE.lerp(NEON_PINK, float(a_step) / 90.0)
			_set_pixel_safe(img, px, py, col)
		# 中心太极核
		_draw_circle(img, cx, cy, 4, EVA_PURPLE)
		_draw_circle(img, cx, cy, 2, EVA_CYAN)
		_set_pixel_safe(img, cx, cy, Color(0.9, 0.9, 1.0))
		# 八方位符点
		for i in range(8):
			var a := float(i) * TAU / 8.0
			var px := cx + int(cos(a) * 20.0)
			var py := cy + int(sin(a) * 20.0)
			_draw_circle(img, px, py, 1, EVA_ORANGE)
	elif variant == 1:
		# === 五行法阵：金木水火土循环 ===
		# 五角星连线
		var star_pts: Array[Vector2i] = []
		for i in range(5):
			var a := float(i) * TAU / 5.0 - PI / 2.0
			star_pts.append(Vector2i(cx + int(cos(a) * 20.0), cy + int(sin(a) * 20.0)))
		# 画五角星（跳一个连）
		var star_colors := [EVA_RED, NEON_GREEN, EVA_CYAN, EVA_ORANGE, EVA_PURPLE]
		for i in range(5):
			var next := (i + 2) % 5
			_draw_pixel_line(img, star_pts[i], star_pts[next], star_colors[i])
		# 五元素节点（大圆点）
		for i in range(5):
			_draw_circle(img, star_pts[i].x, star_pts[i].y, 2, star_colors[i])
			_set_pixel_safe(img, star_pts[i].x, star_pts[i].y, Color(1, 1, 1, 0.8))
		# 外圈
		for a_step in range(60):
			var a := float(a_step) * TAU / 60.0
			var px := cx + int(cos(a) * 24.0)
			var py := cy + int(sin(a) * 24.0)
			_set_pixel_safe(img, px, py, Color(0.3, 0.2, 0.5, 0.6))
		# 中心道印
		_draw_circle(img, cx, cy, 3, Color(0.3, 0.15, 0.5))
		_draw_circle(img, cx, cy, 1, Color(0.9, 0.7, 0.2))
		# 能量粒子
		for s in range(12):
			var px := int(_hash_float(seed_val + s * 3) * 50.0) + 7
			var py := int(_hash_float(seed_val + s * 5) * 50.0) + 7
			var ci := s % 5
			_set_pixel_safe(img, px, py, star_colors[ci].lightened(0.3))
	else:
		# === 符咒矩阵：赛博符文矩阵 ===
		# 3×3 符文网格
		for row in range(3):
			for col in range(3):
				var gx := 14 + col * 16
				var gy := 10 + row * 16
				# 符框
				_draw_line_h(img, gx, gx + 10, gy, EVA_CYAN.darkened(0.4))
				_draw_line_h(img, gx, gx + 10, gy + 10, EVA_CYAN.darkened(0.4))
				_draw_line_v(img, gx, gy, gy + 10, EVA_CYAN.darkened(0.4))
				_draw_line_v(img, gx + 10, gy, gy + 10, EVA_CYAN.darkened(0.4))
				# 符内随机道纹
				var rune_seed := seed_val + row * 3 + col
				var rune_type := int(_hash_float(rune_seed) * 4.0)
				var rune_col := EVA_PURPLE.lerp(NEON_PINK, _hash_float(rune_seed + 99))
				if rune_type == 0:  # 十字
					_draw_line_h(img, gx + 2, gx + 8, gy + 5, rune_col)
					_draw_line_v(img, gx + 5, gy + 2, gy + 8, rune_col)
				elif rune_type == 1:  # 圆
					_draw_circle(img, gx + 5, gy + 5, 3, rune_col)
				elif rune_type == 2:  # 三横
					for ln in range(3):
						_draw_line_h(img, gx + 2, gx + 8, gy + 3 + ln * 2, rune_col)
				else:  # 斜线
					_draw_pixel_line(img, Vector2i(gx + 2, gy + 2), Vector2i(gx + 8, gy + 8), rune_col)
					_draw_pixel_line(img, Vector2i(gx + 8, gy + 2), Vector2i(gx + 2, gy + 8), rune_col)
		# 网格连接电路线
		for row in range(3):
			_draw_line_h(img, 10, 54, 15 + row * 16, Color(0.0, 0.4, 0.5, 0.3))
		for col in range(3):
			_draw_line_v(img, 19 + col * 16, 8, 56, Color(0.0, 0.4, 0.5, 0.3))
		# 激活闪光（中心格高亮）
		_draw_rect_area(img, 28, 24, 8, 8, Color(0.5, 0.2, 0.8, 0.15))

static func _draw_power_motif(img: Image, seed_val: int) -> void:
	# === 金丹曼荼罗：道教修炼核心 ===
	var cx := 32
	var cy := 30
	var variant := int(_hash_float(seed_val) * 2.0)
	if variant == 0:
		# === 金丹放射：层层金光曼荼罗 ===
		# 最外层光环（24 颗金点）
		for i in range(24):
			var a := float(i) * TAU / 24.0
			var px := cx + int(cos(a) * 24.0)
			var py := cy + int(sin(a) * 24.0)
			_set_pixel_safe(img, px, py, EVA_ORANGE)
		# 外圈辐射线（12条，粗）
		for i in range(12):
			var a := float(i) * TAU / 12.0
			for r in range(10, 22):
				var px := cx + int(cos(a) * float(r))
				var py := cy + int(sin(a) * float(r))
				var col := EVA_ORANGE.lerp(Color(1.0, 0.85, 0.3), float(r - 10) / 12.0)
				col.a = 0.6 + 0.3 * (1.0 - float(r - 10) / 12.0)
				_set_pixel_safe(img, px, py, col)
		# 中层六芒星
		for i in range(6):
			var a1 := float(i) * TAU / 6.0
			var a2 := float(i + 2) * TAU / 6.0
			var p1 := Vector2i(cx + int(cos(a1) * 14.0), cy + int(sin(a1) * 14.0))
			var p2 := Vector2i(cx + int(cos(a2) * 14.0), cy + int(sin(a2) * 14.0))
			_draw_pixel_line(img, p1, p2, Color(1.0, 0.75, 0.2, 0.7))
		# 内层圆环
		for a_step in range(36):
			var a := float(a_step) * TAU / 36.0
			var px := cx + int(cos(a) * 8.0)
			var py := cy + int(sin(a) * 8.0)
			_set_pixel_safe(img, px, py, Color(1.0, 0.85, 0.3))
		# 金丹核心（多层发光）
		_draw_circle(img, cx, cy, 5, Color(0.8, 0.6, 0.1))
		_draw_circle(img, cx, cy, 3, Color(1.0, 0.85, 0.3))
		_draw_circle(img, cx, cy, 1, Color(1.0, 0.95, 0.7))
		# 四方位三爻卦符
		var trigram_positions := [Vector2i(cx, cy - 20), Vector2i(cx, cy + 20),
								  Vector2i(cx - 20, cy), Vector2i(cx + 20, cy)]
		for ti in range(4):
			var tp := trigram_positions[ti]
			for line_idx in range(3):
				var ly := tp.y - 2 + line_idx * 2
				var broken := (int(_hash_float(seed_val + ti * 3 + line_idx) * 2.0) == 0)
				if broken:
					_draw_line_h(img, tp.x - 3, tp.x - 1, ly, EVA_ORANGE)
					_draw_line_h(img, tp.x + 1, tp.x + 3, ly, EVA_ORANGE)
				else:
					_draw_line_h(img, tp.x - 3, tp.x + 3, ly, EVA_ORANGE)
	else:
		# === 天眼觉醒：竖瞳 + 灵能爆发 ===
		# 外层散射能量线
		for i in range(16):
			var a := float(i) * TAU / 16.0
			for r in range(18, 26):
				var px := cx + int(cos(a) * float(r))
				var py := cy + int(sin(a) * float(r))
				var intensity := 1.0 - float(r - 18) / 8.0
				_set_pixel_safe(img, px, py, Color(1.0, 0.8, 0.2, intensity * 0.5))
		# 眼眶（椭圆形，水平长）
		for a_step in range(48):
			var a := float(a_step) * TAU / 48.0
			var px := cx + int(cos(a) * 18.0)
			var py := cy + int(sin(a) * 10.0)
			_set_pixel_safe(img, px, py, Color(1.0, 0.85, 0.3))
			# 内层
			var px2 := cx + int(cos(a) * 16.0)
			var py2 := cy + int(sin(a) * 8.0)
			_set_pixel_safe(img, px2, py2, EVA_ORANGE)
		# 虹膜
		_draw_circle(img, cx, cy, 6, EVA_PURPLE)
		_draw_circle(img, cx, cy, 4, Color(0.6, 0.2, 0.8))
		# 竖瞳
		for i in range(8):
			_set_pixel_safe(img, cx, cy - 4 + i, Color(0.1, 0.05, 0.15))
			_set_pixel_safe(img, cx + 1, cy - 3 + i, Color(0.1, 0.05, 0.15, 0.5))
		# 瞳孔高光
		_set_pixel_safe(img, cx - 1, cy - 2, Color(1.0, 1.0, 0.9))
		_set_pixel_safe(img, cx + 2, cy + 1, Color(1.0, 0.9, 0.7, 0.6))
		# 眼角道纹延伸
		for i in range(6):
			_set_pixel_safe(img, cx - 19 - i, cy, Color(1.0, 0.7, 0.2, 0.6 - float(i) * 0.1))
			_set_pixel_safe(img, cx + 19 + i, cy, Color(1.0, 0.7, 0.2, 0.6 - float(i) * 0.1))
		# 上下三角道印
		for i in range(4):
			_set_pixel_safe(img, cx - i, cy - 12 - i, EVA_ORANGE.darkened(0.2))
			_set_pixel_safe(img, cx + i, cy - 12 - i, EVA_ORANGE.darkened(0.2))
			_set_pixel_safe(img, cx - i, cy + 12 + i, EVA_ORANGE.darkened(0.2))
			_set_pixel_safe(img, cx + i, cy + 12 + i, EVA_ORANGE.darkened(0.2))
		# 能量粒子
		for s in range(8):
			var px := int(_hash_float(seed_val + s * 7) * 50.0) + 7
			var py := int(_hash_float(seed_val + s * 13) * 50.0) + 7
			_set_pixel_safe(img, px, py, Color(1.0, 0.9, 0.5, 0.8))

static func _draw_pixel_line(img: Image, from: Vector2i, to: Vector2i, color: Color) -> void:
	var dx := absi(to.x - from.x)
	var dy := absi(to.y - from.y)
	var sx := 1 if from.x < to.x else -1
	var sy := 1 if from.y < to.y else -1
	var err := dx - dy
	var cx := from.x
	var cy := from.y
	while true:
		_set_pixel_safe(img, cx, cy, color)
		if cx == to.x and cy == to.y:
			break
		var e2 := 2 * err
		if e2 > -dy:
			err -= dy
			cx += sx
		if e2 < dx:
			err += dx
			cy += sy
# === Character Sprite Generator (48x64) ===

static func generate_character_sprite(char_type: String, frame: int) -> ImageTexture:
	var img := _create_image(48, 64)

	match char_type:
		"player": _draw_player_sprite(img, frame)
		"grunt": _draw_grunt_sprite(img, frame)
		"grunt2": _draw_grunt_swarm_sprite(img, frame)
		"grunt3": _draw_grunt_thief_sprite(img, frame)
		"elite": _draw_elite_sprite(img, frame)
		"elite2": _draw_elite2_sprite(img, frame)
		"boss": _draw_boss_sprite(img, frame)
		"summon_fox": _draw_summon_fox(img, frame)
		"summon_crane": _draw_summon_crane(img, frame)
		"summon_dragon": _draw_summon_dragon(img, frame)
		"summon_golem": _draw_summon_golem(img, frame)
		"summon_sprite": _draw_summon_sprite(img, frame)
		"summon_clone": _draw_summon_clone(img, frame)
		"summon_familiar": _draw_summon_familiar(img, frame)
		"summon_swarm": _draw_summon_swarm(img, frame)
		"summon_beast": _draw_summon_beast(img, frame)

	# 16bit后处理: 自动描边 + 边缘高光 + 阴影
	_enhance_16bit(img)
	return ImageTexture.create_from_image(img)

## 16bit风格后处理: 描边 + 顶部高光 + 底部阴影
static func _enhance_16bit(img: Image) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var outline_color := Color(0.02, 0.01, 0.05, 0.85)
	# Pass 1: 收集描边位置（透明像素旁有不透明邻居）
	var outline_pixels: Array[Vector2i] = []
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a < 0.1:
				var has_neighbor := false
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						if dx == 0 and dy == 0:
							continue
						var nx: int = x + dx
						var ny: int = y + dy
						if nx >= 0 and nx < w and ny >= 0 and ny < h:
							if img.get_pixel(nx, ny).a > 0.5:
								has_neighbor = true
								break
					if has_neighbor:
						break
				if has_neighbor:
					outline_pixels.append(Vector2i(x, y))
	for p in outline_pixels:
		img.set_pixel(p.x, p.y, outline_color)
	# Pass 2: 顶部边缘高光 + 底部边缘阴影
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var c: Color = img.get_pixel(x, y)
			if c.a > 0.5 and c != outline_color:
				var above: Color = img.get_pixel(x, y - 1)
				var below: Color = img.get_pixel(x, y + 1)
				if above.a < 0.1:
					img.set_pixel(x, y, c.lightened(0.18))
				elif below.a < 0.1:
					img.set_pixel(x, y, c.darkened(0.12))

static func _draw_player_sprite(img: Image, frame: int) -> void:
	# 16bit赛博道士 - 深色道袍+发光电路纹+赛博单眼
	var robe_dark := Color(0.08, 0.06, 0.15)
	var robe_mid := Color(0.15, 0.12, 0.25)
	var robe_light := Color(0.22, 0.18, 0.35)
	var skin := Color(0.72, 0.58, 0.48)
	var skin_shade := Color(0.55, 0.42, 0.35)
	var hair_col := Color(0.12, 0.10, 0.18)
	var cyber_glow := EVA_CYAN
	var eye_glow := EVA_RED
	var circuit := Color(0.0, 0.6, 0.8, 0.8)

	var bob := 0
	var arm_off := 0
	match frame:
		0: bob = 0
		1: arm_off = -5  # 攻击
		2: bob = 2       # 受击
		3: bob = -1      # 特殊

	var cy: int = bob  # center Y offset

	# === 脚 / 鞋 ===
	_draw_rect_area(img, 18, 56 + cy, 5, 5, robe_dark)
	_draw_rect_area(img, 25, 56 + cy, 5, 5, robe_dark)
	_draw_line_h(img, 18, 22, 60 + cy, robe_mid)
	_draw_line_h(img, 25, 29, 60 + cy, robe_mid)

	# === 腿 ===
	_draw_rect_area(img, 19, 49 + cy, 4, 7, robe_mid)
	_draw_rect_area(img, 25, 49 + cy, 4, 7, robe_mid)
	# 腿部明暗
	_draw_line_v(img, 19, 49 + cy, 55 + cy, robe_dark)
	_draw_line_v(img, 28, 49 + cy, 55 + cy, robe_dark)

	# === 身体/道袍 ===
	_draw_rect_area(img, 15, 30 + cy, 18, 20, robe_mid)
	# 道袍左右深色边
	_draw_rect_area(img, 15, 30 + cy, 2, 20, robe_dark)
	_draw_rect_area(img, 31, 30 + cy, 2, 20, robe_dark)
	# 道袍中间亮色对襟
	_draw_line_v(img, 23, 32 + cy, 48 + cy, robe_light)
	_draw_line_v(img, 24, 32 + cy, 48 + cy, robe_light)
	# 腰带
	_draw_rect_area(img, 16, 42 + cy, 16, 2, Color(0.4, 0.25, 0.1))
	_set_pixel_safe(img, 23, 42 + cy, EVA_ORANGE)
	_set_pixel_safe(img, 24, 42 + cy, EVA_ORANGE)

	# === 电路纹（道袍上的赛博纹路）===
	_set_pixel_safe(img, 20, 34 + cy, circuit)
	_set_pixel_safe(img, 20, 36 + cy, circuit)
	_set_pixel_safe(img, 20, 38 + cy, circuit)
	_draw_line_h(img, 20, 22, 38 + cy, circuit)
	_set_pixel_safe(img, 27, 35 + cy, circuit)
	_set_pixel_safe(img, 27, 37 + cy, circuit)
	_draw_line_h(img, 26, 28, 37 + cy, circuit)
	# 下摆电路
	_set_pixel_safe(img, 18, 46 + cy, circuit)
	_set_pixel_safe(img, 29, 46 + cy, circuit)

	# === 手臂 ===
	# 左臂
	_draw_rect_area(img, 10, 32 + cy + arm_off, 5, 14, robe_mid)
	_draw_line_v(img, 10, 32 + cy + arm_off, 45 + cy + arm_off, robe_dark)
	_draw_rect_area(img, 11, 45 + cy + arm_off, 4, 3, skin_shade)
	# 右臂
	_draw_rect_area(img, 33, 32 + cy, 5, 14, robe_mid)
	_draw_line_v(img, 37, 32 + cy, 45 + cy, robe_dark)
	_draw_rect_area(img, 33, 45 + cy, 4, 3, skin_shade)

	# === 头部 ===
	# 头发/帽
	_draw_rect_area(img, 17, 17 + cy, 14, 14, hair_col)
	# 脸（肤色）
	_draw_rect_area(img, 19, 22 + cy, 10, 8, skin)
	# 脸部阴影（下半）
	_draw_rect_area(img, 19, 27 + cy, 10, 3, skin_shade)
	# 赛博单眼（左眼红色发光, 右眼正常）
	_set_pixel_safe(img, 21, 24 + cy, eye_glow)
	_set_pixel_safe(img, 22, 24 + cy, eye_glow)
	_set_pixel_safe(img, 21, 25 + cy, Color(eye_glow.r, 0.1, 0.1, 0.5))
	# 正常右眼
	_set_pixel_safe(img, 26, 24 + cy, Color(0.1, 0.1, 0.1))
	_set_pixel_safe(img, 27, 24 + cy, Color(0.1, 0.1, 0.1))
	# 嘴
	_draw_line_h(img, 22, 25, 28 + cy, skin_shade.darkened(0.2))
	# 道冠
	_draw_rect_area(img, 20, 16 + cy, 8, 3, Color(0.35, 0.25, 0.1))
	_set_pixel_safe(img, 23, 15 + cy, EVA_ORANGE)
	_set_pixel_safe(img, 24, 15 + cy, EVA_ORANGE)
	# 头发侧面
	_draw_rect_area(img, 17, 22 + cy, 2, 6, hair_col)
	_draw_rect_area(img, 29, 22 + cy, 2, 6, hair_col)

	# === 攻击帧: 能量斩 ===
	if frame == 1:
		for i in range(10):
			_set_pixel_safe(img, 6 + i, 26 + i, NEON_PINK)
			_set_pixel_safe(img, 7 + i, 26 + i, Color(1, 0.4, 0.7, 0.7))
			_set_pixel_safe(img, 5 + i, 26 + i, Color(1, 0.2, 0.5, 0.4))
	# === 受击帧: 闪白 ===
	if frame == 2:
		for y in range(17, 61):
			for x in range(10, 38):
				var c: Color = img.get_pixel(x, y + cy)
				if c.a > 0.3:
					img.set_pixel(x, y + cy, c.lightened(0.35))
	# === 特殊帧: 太极气场 ===
	if frame == 3:
		for angle_step in range(20):
			var a: float = float(angle_step) * TAU / 20.0
			var rx: int = 24 + int(cos(a) * 16.0)
			var ry: int = 38 + cy + int(sin(a) * 16.0)
			_set_pixel_safe(img, rx, ry, Color(cyber_glow.r, cyber_glow.g, cyber_glow.b, 0.5))

static func _draw_grunt_sprite(img: Image, frame: int) -> void:
	# 16bit数据游魂 - 大型幽灵实体，道教符文+赛博电路混合
	var body_outer := Color(0.35, 0.2, 0.65)
	var body_mid := Color(0.22, 0.12, 0.5)
	var body_inner := Color(0.12, 0.06, 0.35)
	var eye_col := EVA_CYAN
	var data_col := Color(0.0, 0.8, 0.6, 0.5)
	var rune_col := Color(0.7, 0.55, 0.15, 0.45)
	var circuit_col := Color(0.0, 0.6, 0.8, 0.4)
	var bob := 0
	match frame:
		0: bob = 0
		1: bob = -3
		2: bob = 3
		3: bob = -1

	# === 主体（更大的椭圆幽灵身体，4层渐变）===
	_draw_circle(img, 24, 26 + bob, 15, body_outer)
	_draw_circle(img, 24, 26 + bob, 13, body_mid)
	_draw_circle(img, 24, 26 + bob, 10, body_inner)
	_draw_circle(img, 24, 25 + bob, 7, body_inner.lightened(0.05))

	# === 头顶尖角（幽灵冠）===
	_set_pixel_safe(img, 24, 10 + bob, body_outer)
	_set_pixel_safe(img, 23, 11 + bob, body_outer)
	_set_pixel_safe(img, 25, 11 + bob, body_outer)
	_set_pixel_safe(img, 22, 12 + bob, body_mid)
	_set_pixel_safe(img, 26, 12 + bob, body_mid)

	# === 飘动的下摆（更宽、更多层波浪）===
	for x_off in range(-14, 15):
		var wave: int = int(sin(float(x_off) * 0.6) * 4.0)
		var wave2: int = int(sin(float(x_off) * 1.2 + 2.0) * 2.0)
		var fade: float = 1.0 - absf(float(x_off)) / 15.0
		_set_pixel_safe(img, 24 + x_off, 41 + bob + wave, Color(body_outer.r, body_outer.g, body_outer.b, fade * 0.85))
		_set_pixel_safe(img, 24 + x_off, 42 + bob + wave, Color(body_mid.r, body_mid.g, body_mid.b, fade * 0.65))
		_set_pixel_safe(img, 24 + x_off, 43 + bob + wave, Color(body_mid.r, body_mid.g, body_mid.b, fade * 0.4))
		_set_pixel_safe(img, 24 + x_off, 44 + bob + wave + wave2, Color(body_inner.r, body_inner.g, body_inner.b, fade * 0.25))
		_set_pixel_safe(img, 24 + x_off, 45 + bob + wave + wave2, Color(body_inner.r, body_inner.g, body_inner.b, fade * 0.12))

	# === 眼睛（更大、更有威胁感）===
	# 左眼
	_draw_rect_area(img, 16, 23 + bob, 5, 5, eye_col)
	_set_pixel_safe(img, 17, 24 + bob, body_inner)
	_set_pixel_safe(img, 18, 25 + bob, body_inner)
	_set_pixel_safe(img, 19, 24 + bob, body_inner)
	# 右眼
	_draw_rect_area(img, 27, 23 + bob, 5, 5, eye_col)
	_set_pixel_safe(img, 28, 24 + bob, body_inner)
	_set_pixel_safe(img, 29, 25 + bob, body_inner)
	_set_pixel_safe(img, 30, 24 + bob, body_inner)
	# 眼睛外圈光晕
	for ex in [15, 21, 26, 32]:
		_set_pixel_safe(img, ex, 24 + bob, Color(eye_col.r, eye_col.g, eye_col.b, 0.25))
		_set_pixel_safe(img, ex, 25 + bob, Color(eye_col.r, eye_col.g, eye_col.b, 0.2))
	# 眼下光痕（哭泣般的数据流）
	for tear_y in range(3):
		_set_pixel_safe(img, 18, 28 + bob + tear_y, Color(eye_col.r, eye_col.g, eye_col.b, 0.3 - float(tear_y) * 0.08))
		_set_pixel_safe(img, 29, 28 + bob + tear_y, Color(eye_col.r, eye_col.g, eye_col.b, 0.3 - float(tear_y) * 0.08))

	# === 嘴（锯齿状裂口）===
	_set_pixel_safe(img, 20, 30 + bob, body_inner.darkened(0.3))
	_set_pixel_safe(img, 22, 31 + bob, body_inner.darkened(0.3))
	_set_pixel_safe(img, 24, 30 + bob, body_inner.darkened(0.3))
	_set_pixel_safe(img, 26, 31 + bob, body_inner.darkened(0.3))
	_set_pixel_safe(img, 28, 30 + bob, body_inner.darkened(0.3))

	# === 赛博电路纹（身体表面）===
	_draw_line_h(img, 16, 20, 33 + bob, circuit_col)
	_draw_line_v(img, 20, 33 + bob, 37 + bob, circuit_col)
	_draw_line_h(img, 28, 32, 34 + bob, circuit_col)
	_draw_line_v(img, 28, 34 + bob, 38 + bob, circuit_col)
	# 电路节点亮点
	_set_pixel_safe(img, 16, 33 + bob, Color(0.0, 0.9, 1.0, 0.6))
	_set_pixel_safe(img, 32, 34 + bob, Color(0.0, 0.9, 1.0, 0.6))

	# === 道教符文（身体上浮现的符号点阵）===
	_set_pixel_safe(img, 22, 35 + bob, rune_col)
	_set_pixel_safe(img, 24, 34 + bob, rune_col)
	_set_pixel_safe(img, 26, 35 + bob, rune_col)
	_set_pixel_safe(img, 23, 37 + bob, rune_col)
	_set_pixel_safe(img, 25, 37 + bob, rune_col)
	_set_pixel_safe(img, 24, 39 + bob, rune_col)

	# === 数据碎片装饰（周围浮动）===
	_set_pixel_safe(img, 8, 20 + bob, data_col)
	_set_pixel_safe(img, 10, 35 + bob, data_col)
	_set_pixel_safe(img, 38, 22 + bob, data_col)
	_set_pixel_safe(img, 40, 32 + bob, data_col)
	_set_pixel_safe(img, 6, 28 + bob, Color(data_col.r, data_col.g, data_col.b, 0.3))
	_set_pixel_safe(img, 42, 26 + bob, Color(data_col.r, data_col.g, data_col.b, 0.3))

	# === 受击帧: 静电干扰线 + 闪白 ===
	if frame == 2:
		for row in range(6):
			var y_pos: int = 18 + bob + row * 5
			_draw_line_h(img, 10, 38, y_pos, Color(1.0, 1.0, 1.0, 0.3))
	# === 攻击帧: 前冲数据冲击波 ===
	if frame == 1:
		for i in range(10):
			var wave_a: float = 0.7 - float(i) * 0.06
			_set_pixel_safe(img, 8 - i, 26 + bob, Color(eye_col.r, eye_col.g, eye_col.b, wave_a))
			_set_pixel_safe(img, 8 - i, 28 + bob, Color(eye_col.r, eye_col.g, eye_col.b, wave_a * 0.7))
			_set_pixel_safe(img, 40 + i, 26 + bob, Color(eye_col.r, eye_col.g, eye_col.b, wave_a))
			_set_pixel_safe(img, 40 + i, 28 + bob, Color(eye_col.r, eye_col.g, eye_col.b, wave_a * 0.7))

static func _draw_elite_sprite(img: Image, frame: int) -> void:
	# Puppet / marionette with neon strings
	var body_col := Color(0.5, 0.15, 0.1)
	var joint_col := EVA_ORANGE
	var string_col := NEON_PINK
	var bob := 0
	if frame == 1: bob = -2
	if frame == 2: bob = 2

	# Strings going up
	_draw_line_v(img, 20, 2, 24 + bob, string_col)
	_draw_line_v(img, 28, 2, 24 + bob, string_col)
	_draw_line_v(img, 24, 2, 20 + bob, string_col)
	# Head
	_draw_circle(img, 24, 22 + bob, 5, body_col)
	# Eyes
	_set_pixel_safe(img, 22, 21 + bob, EVA_RED)
	_set_pixel_safe(img, 26, 21 + bob, EVA_RED)
	# Torso
	_draw_rect_area(img, 20, 28 + bob, 8, 12, body_col.darkened(0.2))
	# Arms with joints
	_draw_rect_area(img, 13, 30 + bob, 7, 3, body_col)
	_draw_rect_area(img, 28, 30 + bob, 7, 3, body_col)
	_draw_circle(img, 16, 31 + bob, 1, joint_col)
	_draw_circle(img, 31, 31 + bob, 1, joint_col)
	# Legs
	_draw_rect_area(img, 20, 40 + bob, 3, 10, body_col)
	_draw_rect_area(img, 25, 40 + bob, 3, 10, body_col)
	_draw_circle(img, 21, 45 + bob, 1, joint_col)
	_draw_circle(img, 26, 45 + bob, 1, joint_col)
	# Attack: swing arm out
	if frame == 1:
		_draw_rect_area(img, 6, 28, 7, 3, body_col)
		_set_pixel_safe(img, 5, 29, EVA_ORANGE)
	# Special: strings glow bright
	if frame == 3:
		_draw_line_v(img, 20, 2, 24, Color(1.0, 0.5, 0.8))
		_draw_line_v(img, 28, 2, 24, Color(1.0, 0.5, 0.8))
		_draw_line_v(img, 24, 2, 20, Color(1.0, 0.5, 0.8))

static func _draw_elite2_sprite(img: Image, frame: int) -> void:
	# Twisted obsession figure - dark purple with glitch
	var body_col := Color(0.2, 0.05, 0.3)
	var bob := 1 if frame == 2 else 0

	# Distorted body shape
	_draw_rect_area(img, 18, 24 + bob, 12, 20, body_col)
	# Asymmetric shoulders
	_draw_rect_area(img, 12, 26 + bob, 6, 6, body_col.lightened(0.1))
	_draw_rect_area(img, 30, 24 + bob, 8, 8, body_col.lightened(0.05))
	# Head - slightly off-center
	_draw_circle(img, 25, 20 + bob, 6, body_col.lightened(0.15))
	# Single glowing eye
	_set_pixel_safe(img, 27, 19 + bob, NEON_PINK)
	_set_pixel_safe(img, 28, 19 + bob, NEON_PINK)
	# Mouth slit
	_draw_line_h(img, 23, 28, 23 + bob, EVA_RED.darkened(0.3))
	# Legs
	_draw_rect_area(img, 19, 44 + bob, 4, 10, body_col.darkened(0.2))
	_draw_rect_area(img, 25, 44 + bob, 4, 10, body_col.darkened(0.2))
	# Glitch stripes (horizontal displacement)
	for g in range(4):
		var gy := 22 + bob + g * 6
		var shift := 2 if g % 2 == 0 else -2
		for gx in range(14, 34):
			if gy >= 0 and gy < 64:
				var c := img.get_pixel(clampi(gx, 0, 47), clampi(gy, 0, 63))
				if c.a > 0.0:
					_set_pixel_safe(img, gx + shift, gy, c.lightened(0.2))
	# Special: full glitch burst
	if frame == 3:
		for row in range(5):
			var gy := 18 + row * 6
			_draw_line_h(img, 10, 38, gy, Color(1.0, 0.0, 0.5, 0.4))

static func _draw_boss_sprite(img: Image, frame: int) -> void:
	# 16bit「旧我」- 半机械半道士，威严巨大身躯
	var mecha_dark := Color(0.15, 0.15, 0.2)
	var mecha_mid := Color(0.25, 0.25, 0.3)
	var mecha_light := Color(0.35, 0.35, 0.4)
	var robe_dark := Color(0.1, 0.03, 0.18)
	var robe_mid := Color(0.18, 0.06, 0.28)
	var robe_light := Color(0.25, 0.1, 0.38)
	var rune_col := EVA_CYAN
	var bob := 0
	if frame == 1: bob = -2
	if frame == 2: bob = 1

	# === 腿 ===
	_draw_rect_area(img, 12, 52 + bob, 7, 10, mecha_mid)
	_draw_rect_area(img, 29, 52 + bob, 7, 10, robe_dark)
	_draw_line_v(img, 12, 52 + bob, 61 + bob, mecha_dark)
	_draw_line_v(img, 35, 52 + bob, 61 + bob, robe_dark.darkened(0.2))

	# === 身体 - 左半机械，右半道袍 ===
	# 机械侧
	_draw_rect_area(img, 6, 18 + bob, 18, 34, mecha_mid)
	_draw_rect_area(img, 6, 18 + bob, 2, 34, mecha_dark)
	# 机械板甲细节
	_draw_line_h(img, 8, 23, 24 + bob, mecha_light)
	_draw_line_h(img, 8, 23, 34 + bob, mecha_light)
	_draw_rect_area(img, 10, 27 + bob, 5, 5, mecha_light)
	_draw_rect_area(img, 11, 28 + bob, 3, 3, EVA_RED.darkened(0.3))
	# 关节铆钉
	_set_pixel_safe(img, 9, 22 + bob, mecha_light)
	_set_pixel_safe(img, 9, 38 + bob, mecha_light)

	# 道袍侧
	_draw_rect_area(img, 24, 18 + bob, 18, 36, robe_mid)
	_draw_rect_area(img, 40, 18 + bob, 2, 36, robe_dark)
	# 道袍纹饰
	_draw_line_v(img, 30, 20 + bob, 50 + bob, robe_light)
	_draw_line_v(img, 31, 20 + bob, 50 + bob, robe_light)
	# 道袍下摆飘动
	for i in range(10):
		@warning_ignore("integer_division")
		var wave: int = i / 4
		_set_pixel_safe(img, 32 + i, 54 + bob + wave, robe_mid)
		_set_pixel_safe(img, 32 + i, 55 + bob + wave, robe_dark)

	# === 巨大头部 ===
	_draw_rect_area(img, 12, 4 + bob, 24, 16, mecha_mid)
	_draw_rect_area(img, 24, 4 + bob, 12, 16, robe_mid.lightened(0.08))
	# 机械眼（左，红色大眼）
	_draw_rect_area(img, 15, 10 + bob, 5, 3, EVA_RED)
	_set_pixel_safe(img, 14, 11 + bob, Color(EVA_RED.r, 0, 0, 0.4))
	_set_pixel_safe(img, 20, 11 + bob, Color(EVA_RED.r, 0, 0, 0.4))
	# 道士眼（右，金色）
	_set_pixel_safe(img, 30, 11 + bob, Color(0.9, 0.8, 0.4))
	_set_pixel_safe(img, 31, 11 + bob, Color(0.9, 0.8, 0.4))
	_set_pixel_safe(img, 30, 12 + bob, Color(0.7, 0.6, 0.3))
	# 道冠
	_draw_rect_area(img, 16, 2 + bob, 16, 3, EVA_PURPLE)
	_draw_rect_area(img, 22, 0 + bob, 4, 3, EVA_ORANGE)
	# 面部分界线
	_draw_line_v(img, 24, 5 + bob, 19 + bob, Color(0.4, 0.3, 0.2))

	# === 手臂 ===
	# 机械臂（粗壮）
	_draw_rect_area(img, 0, 22 + bob, 6, 18, mecha_mid)
	_draw_rect_area(img, 0, 22 + bob, 1, 18, mecha_dark)
	_draw_rect_area(img, 0, 38 + bob, 7, 5, mecha_light)
	# 道袍袖
	_draw_rect_area(img, 42, 22 + bob, 5, 16, robe_mid)
	_draw_rect_area(img, 46, 22 + bob, 1, 16, robe_dark)

	# === 符文发光 ===
	for r in range(6):
		var rx: int = 10 + r * 3
		var ry: int = 30 + bob + int(sin(float(r) * 1.2) * 2.0)
		_set_pixel_safe(img, rx, ry, rune_col)
		_set_pixel_safe(img, rx, ry + 1, Color(rune_col.r, rune_col.g, rune_col.b, 0.4))
	for r in range(5):
		var rx: int = 26 + r * 3
		var ry: int = 32 + bob + r
		_set_pixel_safe(img, rx, ry, EVA_ORANGE)
		_set_pixel_safe(img, rx + 1, ry, Color(EVA_ORANGE.r, EVA_ORANGE.g, EVA_ORANGE.b, 0.3))

	# === 攻击帧: 机械臂能量炮 ===
	if frame == 1:
		for i in range(8):
			var alpha: float = 0.9 - float(i) * 0.1
			_set_pixel_safe(img, -1 - i, 30 + bob, Color(EVA_RED.r, 0.2, 0.1, alpha))
			_set_pixel_safe(img, -1 - i, 31 + bob, Color(1, 0.5, 0.1, alpha))
	# === 特殊帧: 全身符文阵 ===
	if frame == 3:
		for angle_step in range(28):
			var a: float = float(angle_step) * TAU / 28.0
			var rx: int = 24 + int(cos(a) * 22.0)
			var ry: int = 32 + bob + int(sin(a) * 22.0)
			_set_pixel_safe(img, rx, ry, rune_col)
			_set_pixel_safe(img, rx + 1, ry, Color(rune_col.r, rune_col.g, rune_col.b, 0.3))

static func _draw_summon_fox(img: Image, frame: int) -> void:
	var shift := 3 if frame == 1 else 0
	# Body
	_draw_rect_area(img, 16 + shift, 35, 16, 10, EVA_ORANGE)
	# Head
	_draw_rect_area(img, 18 + shift, 29, 8, 7, EVA_ORANGE.lightened(0.1))
	# Pointed ears (triangles)
	_set_pixel_safe(img, 18 + shift, 27, EVA_ORANGE)
	_set_pixel_safe(img, 19 + shift, 27, EVA_ORANGE)
	_set_pixel_safe(img, 19 + shift, 28, EVA_ORANGE)
	_set_pixel_safe(img, 24 + shift, 27, EVA_ORANGE)
	_set_pixel_safe(img, 25 + shift, 27, EVA_ORANGE)
	_set_pixel_safe(img, 24 + shift, 28, EVA_ORANGE)
	# Glowing cyan eyes
	_set_pixel_safe(img, 20 + shift, 31, EVA_CYAN)
	_set_pixel_safe(img, 24 + shift, 31, EVA_CYAN)
	# Bushy tail (right side)
	for i in range(6):
		@warning_ignore("integer_division")
		_set_pixel_safe(img, 32 + shift + i, 34 - i / 2, EVA_ORANGE.lightened(0.15))
		@warning_ignore("integer_division")
		_set_pixel_safe(img, 32 + shift + i, 35 - i / 2, EVA_ORANGE.lightened(0.1))
	# Legs (4 thin rects)
	_draw_rect_area(img, 17 + shift, 45, 2, 5, EVA_ORANGE.darkened(0.3))
	_draw_rect_area(img, 22 + shift, 45, 2, 5, EVA_ORANGE.darkened(0.3))
	_draw_rect_area(img, 27 + shift, 45, 2, 5, EVA_ORANGE.darkened(0.3))
	_draw_rect_area(img, 30 + shift, 45, 2, 5, EVA_ORANGE.darkened(0.3))

static func _draw_summon_crane(img: Image, frame: int) -> void:
	var wing_extra := 4 if frame == 1 else 0
	# Body (white)
	_draw_rect_area(img, 20, 25, 8, 15, Color(0.9, 0.9, 0.95))
	# Neck
	_draw_rect_area(img, 22, 15, 4, 10, Color(0.9, 0.9, 0.95))
	# Head
	_draw_circle(img, 24, 13, 3, Color(0.9, 0.9, 0.95))
	# Eye
	_set_pixel_safe(img, 25, 12, EVA_RED)
	# Beak
	_set_pixel_safe(img, 27, 13, EVA_ORANGE)
	_set_pixel_safe(img, 28, 13, EVA_ORANGE)
	# Long legs
	_draw_line_v(img, 22, 40, 55, Color(0.3, 0.3, 0.35))
	_draw_line_v(img, 26, 40, 55, Color(0.3, 0.3, 0.35))
	# Wing accents (purple)
	for i in range(6 + wing_extra):
		@warning_ignore("integer_division")
		_set_pixel_safe(img, 16 - i, 27 + i / 3, EVA_PURPLE.lightened(0.1))
		@warning_ignore("integer_division")
		_set_pixel_safe(img, 28 + i, 27 + i / 3, EVA_PURPLE.lightened(0.1))

static func _draw_summon_dragon(img: Image, frame: int) -> void:
	var undulate := 2 if frame == 1 else 0
	# Body segments (serpentine circles)
	_draw_circle(img, 20, 34, 4, EVA_PURPLE)
	_draw_circle(img, 26, 32 - undulate, 4, EVA_PURPLE.lightened(0.05))
	_draw_circle(img, 32, 34 + undulate, 4, EVA_PURPLE)
	_draw_circle(img, 38, 32, 4, EVA_PURPLE.lightened(0.05))
	# Gold accents on segments
	_set_pixel_safe(img, 20, 32, EVA_ORANGE)
	_set_pixel_safe(img, 26, 30 - undulate, EVA_ORANGE)
	_set_pixel_safe(img, 32, 32 + undulate, EVA_ORANGE)
	_set_pixel_safe(img, 38, 30, EVA_ORANGE)
	# Small wings (triangles)
	_set_pixel_safe(img, 24, 26 - undulate, EVA_PURPLE.lightened(0.2))
	_set_pixel_safe(img, 25, 25 - undulate, EVA_PURPLE.lightened(0.2))
	_set_pixel_safe(img, 26, 24 - undulate, EVA_PURPLE.lightened(0.2))
	_set_pixel_safe(img, 28, 26 - undulate, EVA_PURPLE.lightened(0.2))
	_set_pixel_safe(img, 29, 25 - undulate, EVA_PURPLE.lightened(0.2))
	# Whisker lines from head
	_draw_line_h(img, 14, 18, 33, EVA_CYAN)
	_draw_line_h(img, 14, 18, 35, EVA_CYAN)
	# Eyes
	_set_pixel_safe(img, 18, 33, NEON_GREEN)

static func _draw_summon_golem(img: Image, frame: int) -> void:
	var arm_raise := -6 if frame == 1 else 0
	var body_col := Color(0.25, 0.25, 0.3)
	# Body
	_draw_rect_area(img, 16, 20, 16, 24, body_col)
	# Head
	_draw_rect_area(img, 18, 12, 12, 10, body_col.lightened(0.1))
	# Glowing cyan eyes
	_set_pixel_safe(img, 21, 16, EVA_CYAN)
	_set_pixel_safe(img, 22, 16, EVA_CYAN)
	_set_pixel_safe(img, 26, 16, EVA_CYAN)
	_set_pixel_safe(img, 27, 16, EVA_CYAN)
	# Circuit lines on body
	_draw_line_h(img, 18, 30, 25, EVA_CYAN.darkened(0.3))
	_draw_line_h(img, 18, 30, 30, EVA_CYAN.darkened(0.3))
	_draw_line_h(img, 18, 30, 35, EVA_CYAN.darkened(0.3))
	_draw_line_v(img, 24, 22, 40, EVA_CYAN.darkened(0.4))
	# Arms
	_draw_rect_area(img, 10, 22 + arm_raise, 6, 14, body_col.darkened(0.1))
	_draw_rect_area(img, 32, 22 + arm_raise, 6, 14, body_col.darkened(0.1))
	# Legs
	_draw_rect_area(img, 18, 44, 5, 8, body_col.darkened(0.2))
	_draw_rect_area(img, 25, 44, 5, 8, body_col.darkened(0.2))

static func _draw_summon_sprite(img: Image, frame: int) -> void:
	var float_y := -2 if frame == 1 else 0
	var cx := 24
	var cy := 32 + float_y
	# Glowing core
	_draw_circle(img, cx, cy, 5, NEON_GREEN)
	_draw_circle(img, cx, cy, 3, NEON_GREEN.lightened(0.3))
	# Wings (small triangles)
	_set_pixel_safe(img, cx - 7, cy - 2, NEON_GREEN.lightened(0.2))
	_set_pixel_safe(img, cx - 8, cy - 3, NEON_GREEN.lightened(0.2))
	_set_pixel_safe(img, cx - 7, cy, NEON_GREEN.lightened(0.1))
	_set_pixel_safe(img, cx + 7, cy - 2, NEON_GREEN.lightened(0.2))
	_set_pixel_safe(img, cx + 8, cy - 3, NEON_GREEN.lightened(0.2))
	_set_pixel_safe(img, cx + 7, cy, NEON_GREEN.lightened(0.1))
	# Sparkle pixels around
	_set_pixel_safe(img, cx - 10, cy - 6, Color(1, 1, 0.8, 0.8))
	_set_pixel_safe(img, cx + 9, cy - 8, Color(1, 1, 0.8, 0.7))
	_set_pixel_safe(img, cx - 5, cy + 10, Color(1, 1, 0.8, 0.6))
	_set_pixel_safe(img, cx + 7, cy + 8, Color(1, 1, 0.8, 0.8))
	_set_pixel_safe(img, cx + 2, cy - 11, Color(1, 1, 0.8, 0.7))
	_set_pixel_safe(img, cx - 8, cy + 5, Color(1, 1, 0.8, 0.6))

static func _draw_summon_clone(img: Image, frame: int) -> void:
	var fill := Color(0.15, 0.05, 0.25)
	var outline := EVA_PURPLE
	var alpha := 0.6 if frame == 1 else 1.0
	fill.a = alpha
	outline.a = alpha
	# Body silhouette (humanoid shape)
	_draw_rect_area(img, 18, 30, 12, 16, fill)
	# Head
	_draw_rect_area(img, 20, 22, 8, 9, fill)
	# Arms
	_draw_rect_area(img, 14, 32, 4, 10, fill)
	_draw_rect_area(img, 30, 32, 4, 10, fill)
	# Legs
	_draw_rect_area(img, 19, 46, 4, 8, fill)
	_draw_rect_area(img, 25, 46, 4, 8, fill)
	# Outline border (body)
	_draw_line_h(img, 18, 29, 29, outline)
	_draw_line_h(img, 18, 29, 46, outline)
	_draw_line_v(img, 17, 30, 46, outline)
	_draw_line_v(img, 30, 30, 46, outline)
	# Head outline
	_draw_line_h(img, 20, 27, 21, outline)
	_draw_line_h(img, 20, 27, 31, outline)
	_draw_line_v(img, 19, 22, 30, outline)
	_draw_line_v(img, 28, 22, 30, outline)

static func _draw_summon_familiar(img: Image, frame: int) -> void:
	var body_col := Color(0.12, 0.1, 0.18)
	var tail_shift := 2 if frame == 1 else 0
	# Body
	_draw_rect_area(img, 18, 38, 12, 8, body_col)
	# Head
	_draw_rect_area(img, 20, 33, 8, 6, body_col.lightened(0.05))
	# Ears (small triangles)
	_set_pixel_safe(img, 20, 31, body_col.lightened(0.1))
	_set_pixel_safe(img, 21, 31, body_col.lightened(0.1))
	_set_pixel_safe(img, 21, 32, body_col.lightened(0.1))
	_set_pixel_safe(img, 26, 31, body_col.lightened(0.1))
	_set_pixel_safe(img, 27, 31, body_col.lightened(0.1))
	_set_pixel_safe(img, 26, 32, body_col.lightened(0.1))
	# Eyes
	_set_pixel_safe(img, 22, 35, EVA_CYAN)
	_set_pixel_safe(img, 26, 35, EVA_CYAN)
	# Tail curving up
	_set_pixel_safe(img, 30, 42 - tail_shift, body_col)
	_set_pixel_safe(img, 31, 41 - tail_shift, body_col)
	_set_pixel_safe(img, 32, 40 - tail_shift, body_col)
	_set_pixel_safe(img, 33, 38 - tail_shift, body_col)
	_set_pixel_safe(img, 33, 37 - tail_shift, body_col)
	# Legs
	_draw_rect_area(img, 19, 46, 2, 4, body_col.darkened(0.2))
	_draw_rect_area(img, 23, 46, 2, 4, body_col.darkened(0.2))
	_draw_rect_area(img, 27, 46, 2, 4, body_col.darkened(0.2))
	# Data-pattern dots (cyan)
	_set_pixel_safe(img, 21, 40, EVA_CYAN)
	_set_pixel_safe(img, 25, 39, EVA_CYAN)
	_set_pixel_safe(img, 23, 42, EVA_CYAN)
	_set_pixel_safe(img, 27, 41, EVA_CYAN)

static func _draw_grunt_swarm_sprite(img: Image, frame: int) -> void:
	# Swarm of small buzzing data insects - multiple small bodies
	var buzz := 1 if frame == 1 else 0
	var body_col := Color(0.3, 0.5, 0.1)
	var wing_col := Color(0.5, 0.8, 0.2, 0.6)
	# Central large bug
	_draw_rect_area(img, 20, 28 + buzz, 8, 12, body_col)
	_draw_rect_area(img, 22, 24 + buzz, 4, 5, body_col.lightened(0.1))
	_set_pixel_safe(img, 23, 25 + buzz, NEON_GREEN)
	_set_pixel_safe(img, 25, 25 + buzz, NEON_GREEN)
	# Wings
	_draw_rect_area(img, 15, 27 + buzz, 5, 3, wing_col)
	_draw_rect_area(img, 28, 27 + buzz, 5, 3, wing_col)
	# Legs
	for i in range(3):
		_set_pixel_safe(img, 19, 32 + i * 3, body_col.darkened(0.3))
		_set_pixel_safe(img, 18, 33 + i * 3, body_col.darkened(0.3))
		_set_pixel_safe(img, 29, 32 + i * 3, body_col.darkened(0.3))
		_set_pixel_safe(img, 30, 33 + i * 3, body_col.darkened(0.3))
	# Smaller bugs orbiting
	_draw_circle(img, 10, 22 - buzz, 3, body_col.darkened(0.1))
	_set_pixel_safe(img, 9, 21 - buzz, NEON_GREEN)
	_draw_circle(img, 38, 26 + buzz, 3, body_col.darkened(0.1))
	_set_pixel_safe(img, 37, 25 + buzz, NEON_GREEN)
	_draw_circle(img, 14, 42 + buzz, 2, body_col.darkened(0.2))
	_draw_circle(img, 36, 38 - buzz, 2, body_col.darkened(0.2))
	# Hit frame: scatter
	if frame == 2:
		for i in range(6):
			var px := 12 + i * 5
			_set_pixel_safe(img, px, 20 + i * 2, Color(1.0, 1.0, 0.3, 0.5))

static func _draw_grunt_thief_sprite(img: Image, frame: int) -> void:
	# Sleek data thief - hooded figure with digital mask
	var cloak_col := Color(0.1, 0.1, 0.15)
	var mask_col := Color(0.15, 0.8, 0.6)
	var bob := 0
	if frame == 1: bob = -3
	if frame == 2: bob = 2
	# Cloak body (triangular shape)
	for row in range(24):
		var half_w := 4 + row / 2
		_draw_line_h(img, 24 - half_w, 24 + half_w, 24 + bob + row, cloak_col)
	# Hood
	_draw_circle(img, 24, 20 + bob, 7, cloak_col.lightened(0.05))
	# Digital mask (glowing visor)
	_draw_rect_area(img, 19, 18 + bob, 10, 3, mask_col)
	_set_pixel_safe(img, 21, 19 + bob, Color(0, 0, 0))
	_set_pixel_safe(img, 27, 19 + bob, Color(0, 0, 0))
	# Dagger in hand
	if frame == 1:
		for i in range(8):
			_set_pixel_safe(img, 12 + i, 22 - i, Color(0.7, 0.7, 0.8))
	else:
		_draw_line_v(img, 16, 30 + bob, 38 + bob, Color(0.5, 0.5, 0.6))
		_set_pixel_safe(img, 16, 29 + bob, Color(0.7, 0.7, 0.8))
	# Feet
	_draw_rect_area(img, 19, 48 + bob, 4, 3, cloak_col.darkened(0.2))
	_draw_rect_area(img, 25, 48 + bob, 4, 3, cloak_col.darkened(0.2))
	# Data trail particles
	_set_pixel_safe(img, 34, 30 + bob, mask_col.darkened(0.3))
	_set_pixel_safe(img, 37, 28 + bob, mask_col.darkened(0.5))
	_set_pixel_safe(img, 40, 32 + bob, mask_col.darkened(0.6))

static func _draw_summon_swarm(img: Image, frame: int) -> void:
	# Bee/wasp swarm - cluster of tiny flying creatures
	var body_col := Color(0.7, 0.55, 0.1)
	var wing_col := Color(0.8, 0.8, 0.6, 0.5)
	var bob := 1 if frame == 1 else 0
	# 3 bees in formation
	var positions: Array[Vector2i] = [Vector2i(16, 30), Vector2i(24, 26 - bob), Vector2i(32, 32 + bob)]
	for pos in positions:
		# Body (striped)
		_draw_rect_area(img, pos.x - 2, pos.y, 5, 4, body_col)
		_set_pixel_safe(img, pos.x, pos.y + 1, Color(0.15, 0.1, 0.05))
		_set_pixel_safe(img, pos.x, pos.y + 3, Color(0.15, 0.1, 0.05))
		# Wings
		_set_pixel_safe(img, pos.x - 3, pos.y - 1, wing_col)
		_set_pixel_safe(img, pos.x - 3, pos.y - 2, wing_col)
		_set_pixel_safe(img, pos.x + 3, pos.y - 1, wing_col)
		_set_pixel_safe(img, pos.x + 3, pos.y - 2, wing_col)
		# Eye
		_set_pixel_safe(img, pos.x + 1, pos.y, EVA_RED)
		# Stinger
		_set_pixel_safe(img, pos.x - 3, pos.y + 2, Color(0.6, 0.6, 0.7))
	# Buzz lines (motion)
	if frame == 1:
		_set_pixel_safe(img, 10, 28, Color(1, 1, 0.8, 0.3))
		_set_pixel_safe(img, 38, 34, Color(1, 1, 0.8, 0.3))

static func _draw_summon_beast(img: Image, frame: int) -> void:
	# Large imposing beast - bulky armored creature
	var body_col := Color(0.35, 0.2, 0.1)
	var armor_col := Color(0.5, 0.35, 0.15)
	var horn_col := Color(0.7, 0.6, 0.4)
	var bob := 0
	if frame == 1: bob = -2
	if frame == 2: bob = 1
	# Large body
	_draw_rect_area(img, 10, 26 + bob, 28, 20, body_col)
	# Armor plating
	_draw_rect_area(img, 12, 28 + bob, 24, 4, armor_col)
	_draw_rect_area(img, 14, 34 + bob, 20, 3, armor_col.darkened(0.1))
	# Head (wide)
	_draw_rect_area(img, 14, 16 + bob, 20, 12, body_col.lightened(0.05))
	# Horns
	_draw_line_v(img, 14, 10 + bob, 16 + bob, horn_col)
	_draw_line_v(img, 13, 8 + bob, 12 + bob, horn_col)
	_draw_line_v(img, 34, 10 + bob, 16 + bob, horn_col)
	_draw_line_v(img, 35, 8 + bob, 12 + bob, horn_col)
	# Eyes (angry, glowing)
	_draw_rect_area(img, 18, 20 + bob, 3, 2, EVA_RED)
	_draw_rect_area(img, 27, 20 + bob, 3, 2, EVA_RED)
	# Mouth
	_draw_line_h(img, 20, 28, 26 + bob, Color(0.2, 0.05, 0.05))
	# Thick legs (4)
	_draw_rect_area(img, 12, 46 + bob, 5, 8, body_col.darkened(0.2))
	_draw_rect_area(img, 20, 46 + bob, 5, 8, body_col.darkened(0.2))
	_draw_rect_area(img, 28, 46 + bob, 5, 8, body_col.darkened(0.2))
	_draw_rect_area(img, 33, 46 + bob, 5, 8, body_col.darkened(0.2))
	# Tail
	_set_pixel_safe(img, 38, 36 + bob, body_col)
	_set_pixel_safe(img, 39, 35 + bob, body_col)
	_set_pixel_safe(img, 40, 34 + bob, body_col)
	# Attack frame: charging forward
	if frame == 1:
		_draw_rect_area(img, 8, 22, 4, 3, Color(1, 0.5, 0.2, 0.5))
		_draw_rect_area(img, 4, 23, 4, 2, Color(1, 0.5, 0.2, 0.3))

# === Battle Background Generator (320x180) ===

static func generate_battle_background(stage: int) -> ImageTexture:
	var img := _create_image(320, 180)

	match stage:
		0: _draw_bg_neon_city(img)
		1: _draw_bg_tower_interior(img)
		2: _draw_bg_deep_ruins(img)
		3: _draw_bg_boss_arena(img)
		_: _draw_bg_neon_city(img)

	return ImageTexture.create_from_image(img)

static func _draw_bg_neon_city(img: Image) -> void:
	# === Sky gradient (deep purple-blue, richer tones) ===
	for y in range(180):
		var t := float(y) / 180.0
		var sky_top := Color(0.04, 0.02, 0.14)
		var sky_mid := Color(0.06, 0.03, 0.18)
		var sky_bot := Color(0.03, 0.02, 0.10)
		var sky: Color
		if t < 0.4:
			sky = sky_top.lerp(sky_mid, t / 0.4)
		else:
			sky = sky_mid.lerp(sky_bot, (t - 0.4) / 0.6)
		for x in range(320):
			img.set_pixel(x, y, sky)

	# === Stars (more, with size variation) ===
	for s in range(70):
		var sx := int(_hash_float(s * 7) * 320.0)
		var sy := int(_hash_float(s * 13) * 60.0)
		var bright := 0.4 + _hash_float(s * 3) * 0.6
		var star_col := Color(bright, bright, bright * 0.85)
		_set_pixel_safe(img, sx, sy, star_col)
		if _hash_float(s * 41) > 0.7:
			_set_pixel_safe(img, sx + 1, sy, star_col.darkened(0.3))
			_set_pixel_safe(img, sx, sy + 1, star_col.darkened(0.3))

	# === Distant city haze (horizon glow) ===
	for x in range(320):
		for dy in range(8):
			var haze_y: int = 55 + dy
			var haze_a: float = (1.0 - float(dy) / 8.0) * 0.12
			var haze_col := Color(0.15, 0.08, 0.3, haze_a)
			var existing := img.get_pixel(x, haze_y)
			img.set_pixel(x, haze_y, existing.blend(haze_col))

	# === Far background buildings (small, dark, many) ===
	for b in range(20):
		var bx := int(_hash_float(b * 17 + 100) * 310.0)
		var bw := int(_hash_float(b * 23 + 200) * 12.0) + 5
		var bh := int(_hash_float(b * 31 + 300) * 25.0) + 15
		var by := 65 - bh
		var dark := Color(0.04, 0.03, 0.08 + _hash_float(b * 41) * 0.03)
		_draw_rect_area(img, bx, by, bw, bh, dark)
		# Tiny windows
		for wy in range(by + 2, 64, 4):
			for wx in range(bx + 1, bx + bw - 1, 3):
				if _hash_float(wx * 53 + wy * 97 + 500) > 0.5:
					var wc := EVA_CYAN.darkened(0.7) if _hash_float(wx + wy) > 0.5 else EVA_ORANGE.darkened(0.75)
					_set_pixel_safe(img, wx, wy, wc)

	# === Mid-ground buildings (taller, more detail, starts at y~50 so visible in battle) ===
	for b in range(14):
		var bx := int(_hash_float(b * 19 + 1) * 300.0)
		var bw := int(_hash_float(b * 29 + 2) * 22.0) + 12
		var bh := int(_hash_float(b * 37 + 3) * 60.0) + 50
		var by := 120 - bh  # tops reach into visible battle area
		var base_bright := 0.03 + _hash_float(b * 43) * 0.03
		var bld_col := Color(base_bright, base_bright * 0.9, base_bright * 1.2 + 0.02)
		_draw_rect_area(img, bx, by, bw, bh, bld_col)
		# Rooftop highlight
		_draw_line_h(img, bx, bx + bw - 1, by, bld_col.lightened(0.15))
		# Windows (2x1 pixel, colored)
		for wy in range(by + 3, 118, 5):
			for wx in range(bx + 2, bx + bw - 2, 4):
				if _hash_float(wx * 53 + wy * 97) > 0.35:
					var wc: Color
					var r := _hash_float(wx + wy * 7)
					if r > 0.65:
						wc = EVA_CYAN.darkened(0.4)
					elif r > 0.35:
						wc = EVA_ORANGE.darkened(0.5)
					else:
						wc = NEON_PINK.darkened(0.55)
					_set_pixel_safe(img, wx, wy, wc)
					_set_pixel_safe(img, wx + 1, wy, wc.darkened(0.15))

	# === Neon signs (more, brighter, with glow halos) ===
	var signs: Array[Dictionary] = [
		{"x": 40, "y": 45, "w": 18, "h": 3, "color": NEON_PINK},
		{"x": 180, "y": 35, "w": 14, "h": 3, "color": NEON_GREEN},
		{"x": 110, "y": 55, "w": 22, "h": 3, "color": EVA_CYAN},
		{"x": 250, "y": 42, "w": 16, "h": 3, "color": EVA_ORANGE},
		{"x": 70, "y": 70, "w": 12, "h": 2, "color": EVA_PURPLE.lightened(0.3)},
		{"x": 210, "y": 62, "w": 20, "h": 3, "color": NEON_PINK.lightened(0.1)},
	]
	for sign in signs:
		var sx: int = sign["x"]
		var sy: int = sign["y"]
		var sw: int = sign["w"]
		var sh: int = sign["h"]
		var sc: Color = sign["color"]
		_draw_rect_area(img, sx, sy, sw, sh, sc.darkened(0.15))
		# Glow halo (1px around, low alpha)
		for gx in range(sx - 1, sx + sw + 1):
			_set_pixel_safe(img, gx, sy - 1, Color(sc.r, sc.g, sc.b, 0.15))
			_set_pixel_safe(img, gx, sy + sh, Color(sc.r, sc.g, sc.b, 0.12))

	# === Ground platform (raised to y=120 so it's visible in battle area) ===
	# Dark metallic platform
	_draw_rect_area(img, 0, 120, 320, 60, Color(0.035, 0.03, 0.055))
	# Platform surface highlight line
	_draw_line_h(img, 0, 319, 120, Color(0.12, 0.08, 0.2))
	_draw_line_h(img, 0, 319, 121, Color(0.08, 0.05, 0.14))
	# Grid lines on platform (perspective-ish)
	for gx in range(0, 320, 20):
		for gy in range(122, 180, 1):
			var fade: float = 1.0 - float(gy - 122) / 58.0
			_set_pixel_safe(img, gx, gy, Color(0.08, 0.05, 0.15, fade * 0.25))
	for gy in range(125, 180, 10):
		var fade: float = 1.0 - float(gy - 122) / 58.0
		_draw_line_h(img, 0, 319, gy, Color(0.08, 0.05, 0.15, fade * 0.2))

	# === Dao symbols faintly on the ground ===
	# Bagua circle hint at center
	for angle_step in range(32):
		var a: float = float(angle_step) * TAU / 32.0
		var cx: int = 160 + int(cos(a) * 35.0)
		var cy: int = 145 + int(sin(a) * 12.0)
		_set_pixel_safe(img, cx, cy, Color(0.1, 0.06, 0.2, 0.3))

	# === Rain streaks (more, varied alpha) ===
	for r in range(90):
		var rx := int(_hash_float(r * 11 + 777) * 320.0)
		var ry := int(_hash_float(r * 19 + 888) * 115.0)
		var rlen := int(_hash_float(r * 7 + 999) * 5.0) + 2
		var rain_alpha: float = 0.08 + _hash_float(r * 3) * 0.15
		for rl in range(rlen):
			_set_pixel_safe(img, rx, ry + rl, Color(0.35, 0.45, 0.65, rain_alpha))

	# === Atmospheric fog at bottom ===
	for fy in range(115, 130):
		var fog_a: float = (1.0 - float(fy - 115) / 15.0) * 0.08
		for fx in range(320):
			var noise: float = _hash_float(fx * 7 + fy * 13) * 0.04
			var existing := img.get_pixel(fx, fy)
			var fog := Color(0.1, 0.06, 0.18, fog_a + noise)
			img.set_pixel(fx, fy, existing.blend(fog))

static func _draw_bg_tower_interior(img: Image) -> void:
	# Dark stone walls
	for y in range(180):
		for x in range(320):
			var noise := _hash_float(x * 31 + y * 53)
			var base := 0.06 + noise * 0.04
			img.set_pixel(x, y, Color(base, base * 0.9, base * 1.1))

	# Floor
	_draw_rect_area(img, 0, 140, 320, 40, Color(0.08, 0.06, 0.1))

	# Stone brick pattern
	for row in range(0, 140, 12):
		_draw_line_h(img, 0, 319, row, Color(0.04, 0.03, 0.06))
		@warning_ignore("integer_division")
		var offset := 0 if (row / 12) % 2 == 0 else 16
		for col in range(offset, 320, 32):
			_draw_line_v(img, col, row, row + 11, Color(0.04, 0.03, 0.06))

	# Glowing runes on walls
	var rune_positions := [Vector2i(40, 50), Vector2i(100, 30), Vector2i(180, 60),
							Vector2i(250, 40), Vector2i(290, 55)]
	for pos in rune_positions:
		_draw_circle(img, pos.x, pos.y, 3, EVA_PURPLE)
		_set_pixel_safe(img, pos.x, pos.y, EVA_CYAN)
		# Rune glow halo
		_draw_circle(img, pos.x, pos.y, 6, Color(EVA_PURPLE.r, EVA_PURPLE.g, EVA_PURPLE.b, 0.15))

	# Pillars
	for px in [60, 160, 260]:
		_draw_rect_area(img, px, 10, 10, 130, Color(0.07, 0.05, 0.09))
		_draw_rect_area(img, px - 2, 10, 14, 4, Color(0.09, 0.07, 0.12))
		_draw_rect_area(img, px - 2, 136, 14, 4, Color(0.09, 0.07, 0.12))

	# Torch-like light sources
	for tx in [30, 130, 220, 300]:
		_draw_circle(img, tx, 90, 2, EVA_ORANGE)
		_draw_circle(img, tx, 90, 5, Color(EVA_ORANGE.r, EVA_ORANGE.g, EVA_ORANGE.b, 0.1))

static func _draw_bg_deep_ruins(img: Image) -> void:
	# Very dark background
	for y in range(180):
		var t := float(y) / 180.0
		for x in range(320):
			var col := Color(0.02, 0.03, 0.08).lerp(Color(0.04, 0.02, 0.1), t)
			img.set_pixel(x, y, col)

	# Ruined structures
	for b in range(8):
		var bx := int(_hash_float(b * 29 + 5) * 280.0) + 10
		var bw := int(_hash_float(b * 37) * 20.0) + 8
		var bh := int(_hash_float(b * 43) * 50.0) + 20
		var by := 160 - bh
		_draw_rect_area(img, bx, by, bw, bh, Color(0.05, 0.04, 0.08))
		# Broken top edge
		for j in range(bw):
			var jag := int(_hash_float(bx + j) * 6.0)
			for jy in range(jag):
				_set_pixel_safe(img, bx + j, by + jy, Color(0.0, 0.0, 0.0, 0.0))

	# Floor
	_draw_rect_area(img, 0, 160, 320, 20, Color(0.03, 0.02, 0.06))

	# Floating data fragments
	for d in range(25):
		var dx := int(_hash_float(d * 11 + 7) * 300.0) + 10
		var dy := int(_hash_float(d * 17 + 3) * 140.0) + 10
		var dsize := int(_hash_float(d * 23) * 3.0) + 1
		var dcol: Color
		if d % 3 == 0:
			dcol = EVA_CYAN.darkened(0.4)
		elif d % 3 == 1:
			dcol = EVA_PURPLE.darkened(0.3)
		else:
			dcol = NEON_GREEN.darkened(0.5)
		_draw_rect_area(img, dx, dy, dsize, dsize, dcol)

	# Connecting data streams (vertical dotted lines)
	for s in range(6):
		var sx := int(_hash_float(s * 67) * 300.0) + 10
		for sy_dot in range(0, 160, 4):
			_set_pixel_safe(img, sx, sy_dot, EVA_CYAN.darkened(0.6))

static func _draw_bg_boss_arena(img: Image) -> void:
	# EVA-style void
	for y in range(180):
		for x in range(320):
			var t := float(y) / 180.0
			img.set_pixel(x, y, Color(0.02, 0.0, 0.04).lerp(Color(0.06, 0.0, 0.1), t))

	# Cross of light (large)
	var cx := 160
	var cy := 80
	# Vertical beam
	for y in range(180):
		var dist := absf(float(y - cy))
		var alpha := maxf(0.0, 0.6 - dist * 0.005)
		var w := int(3.0 + (1.0 - dist / 90.0) * 4.0)
		w = maxi(w, 1)
		for dx in range(-w, w + 1):
			var col := Color(0.9, 0.85, 1.0, alpha * (1.0 - float(absi(dx)) / float(w + 1)))
			_set_pixel_safe(img, cx + dx, y, col)
	# Horizontal beam
	for x in range(320):
		var dist := absf(float(x - cx))
		var alpha := maxf(0.0, 0.5 - dist * 0.003)
		var h := int(2.0 + (1.0 - dist / 160.0) * 3.0)
		h = maxi(h, 1)
		for dy in range(-h, h + 1):
			var col := Color(0.9, 0.85, 1.0, alpha * (1.0 - float(absi(dy)) / float(h + 1)))
			_set_pixel_safe(img, x, cy + dy, col)

	# Blood moon (upper right)
	var mx := 250
	var my := 35
	_draw_circle(img, mx, my, 18, EVA_RED.darkened(0.3))
	_draw_circle(img, mx, my, 16, EVA_RED.darkened(0.1))
	_draw_circle(img, mx, my, 12, EVA_RED)
	# Moon glow halo
	for angle_step in range(48):
		var a := float(angle_step) * TAU / 48.0
		for r in range(19, 25):
			var px := mx + int(cos(a) * float(r))
			var py := my + int(sin(a) * float(r))
			_set_pixel_safe(img, px, py, Color(EVA_RED.r, 0.05, 0.1, 0.15))

	# Floating debris / shards
	for s in range(15):
		var sx := int(_hash_float(s * 41) * 300.0) + 10
		var sy := int(_hash_float(s * 53) * 160.0) + 10
		_set_pixel_safe(img, sx, sy, EVA_PURPLE.lightened(0.3))
		_set_pixel_safe(img, sx + 1, sy, EVA_PURPLE.darkened(0.2))
		_set_pixel_safe(img, sx, sy + 1, EVA_PURPLE.darkened(0.4))

	# Ground plane
	for y in range(150, 180):
		var alpha := float(y - 150) / 30.0
		for x in range(320):
			var grid_x := (x % 16 == 0)
			var grid_y := ((y - 150) % 8 == 0)
			if grid_x or grid_y:
				_set_pixel_safe(img, x, y, Color(EVA_PURPLE.r, EVA_PURPLE.g, EVA_PURPLE.b, alpha * 0.3))
# === Taiji Symbol Generator ===

static func generate_taiji_symbol(size: int, rotation_frame: int) -> ImageTexture:
	var img := _create_image(size, size)
	@warning_ignore("integer_division")
	var cx := size / 2
	@warning_ignore("integer_division")
	var cy := size / 2
	@warning_ignore("integer_division")
	var radius := size / 2 - 2
	var angle_offset := float(rotation_frame) * TAU / 60.0  # 60 frames full rotation

	# Draw the main circle
	for y in range(size):
		for x in range(size):
			var dx := float(x - cx)
			var dy := float(y - cy)
			var dist := sqrt(dx * dx + dy * dy)
			if dist > float(radius):
				continue

			var angle := atan2(dy, dx) - angle_offset
			# Normalize angle
			while angle < 0.0:
				angle += TAU
			while angle >= TAU:
				angle -= TAU

			# S-curve divider: offset by small circle displacement
			var half_r := float(radius) / 2.0

			# Simple yin-yang division using angle + vertical offset
			var s_offset := sin(angle) * half_r
			var side := (dy - s_offset) > 0.0

			var col: Color
			if side:
				col = EVA_PURPLE  # Yin side
			else:
				col = EVA_ORANGE  # Yang side

			img.set_pixel(x, y, col)

	# Small circles (dots) - yin dot in yang, yang dot in yin
	@warning_ignore("integer_division")
	var dot_r := maxi(radius / 6, 2)
	var dot_dist := float(radius) / 2.0

	var yin_dot_x := cx + int(cos(angle_offset + PI * 0.5) * dot_dist)
	var yin_dot_y := cy + int(sin(angle_offset + PI * 0.5) * dot_dist)
	var yang_dot_x := cx + int(cos(angle_offset - PI * 0.5) * dot_dist)
	var yang_dot_y := cy + int(sin(angle_offset - PI * 0.5) * dot_dist)

	_draw_circle(img, yin_dot_x, yin_dot_y, dot_r, EVA_PURPLE)
	_draw_circle(img, yang_dot_x, yang_dot_y, dot_r, EVA_ORANGE)

	# Glowing edge
	for angle_step in range(128):
		var a := float(angle_step) * TAU / 128.0
		for edge_r in [radius, radius - 1]:
			var ex := cx + int(cos(a) * float(edge_r))
			var ey := cy + int(sin(a) * float(edge_r))
			var glow_t := (sin(a * 3.0 + angle_offset * 2.0) + 1.0) / 2.0
			var glow_col := EVA_CYAN.lerp(NEON_PINK, glow_t)
			glow_col.a = 0.7
			_set_pixel_safe(img, ex, ey, glow_col)

	# Outer glow halo
	for angle_step in range(96):
		var a := float(angle_step) * TAU / 96.0
		var outer_r := radius + 1
		var ox := cx + int(cos(a) * float(outer_r))
		var oy := cy + int(sin(a) * float(outer_r))
		_set_pixel_safe(img, ox, oy, Color(EVA_CYAN.r, EVA_CYAN.g, EVA_CYAN.b, 0.25))

	return ImageTexture.create_from_image(img)

# === Status Icons (16x16) ===

static func generate_status_icon(status_type: String) -> ImageTexture:
	var img := _create_image(16, 16)
	match status_type:
		"corruption": _draw_status_corruption(img)
		"burn": _draw_status_burn(img)
		"weak": _draw_status_weak(img)
		"vulnerable": _draw_status_vulnerable(img)
		"intangible": _draw_status_intangible(img)
		"front_shield": _draw_status_front_shield(img)
	return ImageTexture.create_from_image(img)

## 侵蚀图标 — 绿色毒液滴
static func _draw_status_corruption(img: Image) -> void:
	var c := Color(0.2, 0.85, 0.3)
	var cd := Color(0.1, 0.5, 0.15)
	_set_pixel_safe(img, 7, 2, c); _set_pixel_safe(img, 8, 2, c)
	_set_pixel_safe(img, 6, 3, c); _set_pixel_safe(img, 7, 3, cd); _set_pixel_safe(img, 8, 3, cd); _set_pixel_safe(img, 9, 3, c)
	for y in range(4, 8):
		for x in range(5, 11):
			_set_pixel_safe(img, x, y, cd if (x + y) % 3 == 0 else c)
	for y in range(8, 11):
		for x in range(6, 10):
			_set_pixel_safe(img, x, y, c)
	_set_pixel_safe(img, 7, 11, c); _set_pixel_safe(img, 8, 11, c)
	_set_pixel_safe(img, 6, 12, cd); _set_pixel_safe(img, 9, 12, cd)

## 灼烧图标 — 橙色火焰
static func _draw_status_burn(img: Image) -> void:
	var f := Color(1, 0.5, 0.1)
	var fy := Color(1, 0.85, 0.2)
	var fr := Color(0.9, 0.2, 0.05)
	_set_pixel_safe(img, 7, 3, fy); _set_pixel_safe(img, 8, 3, fy)
	for y in range(4, 8):
		for x in range(6, 10):
			_set_pixel_safe(img, x, y, fy if y < 6 else f)
	_set_pixel_safe(img, 5, 5, fr); _set_pixel_safe(img, 10, 5, fr)
	_set_pixel_safe(img, 5, 6, f); _set_pixel_safe(img, 10, 6, f)
	for y in range(8, 12):
		for x in range(5, 11):
			_set_pixel_safe(img, x, y, f if (x + y) % 2 == 0 else fr)
	_set_pixel_safe(img, 6, 12, fr); _set_pixel_safe(img, 9, 12, fr)

## 虚弱图标 — 蓝色下箭头
static func _draw_status_weak(img: Image) -> void:
	var c := Color(0.3, 0.5, 1)
	for y in range(3, 9):
		_set_pixel_safe(img, 7, y, c); _set_pixel_safe(img, 8, y, c)
	for i in range(4):
		_set_pixel_safe(img, 5 + i, 9 + i, c); _set_pixel_safe(img, 10 - i, 9 + i, c)
		if i < 3:
			_set_pixel_safe(img, 6 + i, 9 + i, c); _set_pixel_safe(img, 9 - i, 9 + i, c)

## 易伤图标 — 红色裂盾
static func _draw_status_vulnerable(img: Image) -> void:
	var c := Color(1, 0.3, 0.2)
	var cd := Color(0.6, 0.15, 0.1)
	for x in range(4, 12):
		_set_pixel_safe(img, x, 3, c)
	for y in range(3, 10):
		_set_pixel_safe(img, 4, y, c); _set_pixel_safe(img, 11, y, c)
	for y in range(3, 9):
		for x in range(5, 11):
			_set_pixel_safe(img, x, y, c)
	for x in range(5, 11):
		_set_pixel_safe(img, x, 10, c)
	_set_pixel_safe(img, 6, 11, c); _set_pixel_safe(img, 9, 11, c)
	_set_pixel_safe(img, 7, 12, c); _set_pixel_safe(img, 8, 12, c)
	_set_pixel_safe(img, 7, 4, cd); _set_pixel_safe(img, 8, 5, cd)
	_set_pixel_safe(img, 7, 6, cd); _set_pixel_safe(img, 6, 7, cd)
	_set_pixel_safe(img, 8, 8, cd); _set_pixel_safe(img, 7, 9, cd)

## 无形图标 — 半透明幽灵
static func _draw_status_intangible(img: Image) -> void:
	var c := Color(0.6, 0.8, 1, 0.7)
	var cd := Color(0.4, 0.6, 0.9, 0.5)
	for y in range(3, 10):
		for x in range(5, 11):
			_set_pixel_safe(img, x, y, cd if (x + y) % 2 == 0 else c)
	for x in range(6, 10):
		_set_pixel_safe(img, x, 2, c)
	_set_pixel_safe(img, 6, 5, Color.WHITE); _set_pixel_safe(img, 9, 5, Color.WHITE)
	_set_pixel_safe(img, 5, 10, c); _set_pixel_safe(img, 7, 10, c); _set_pixel_safe(img, 9, 10, c)
	_set_pixel_safe(img, 6, 11, cd); _set_pixel_safe(img, 8, 11, cd); _set_pixel_safe(img, 10, 11, cd)

## 前排盾牌图标 — 蓝色小盾
static func _draw_status_front_shield(img: Image) -> void:
	var c := Color(0.2, 0.6, 1)
	var cl := Color(0.5, 0.8, 1)
	for x in range(4, 12):
		_set_pixel_safe(img, x, 2, c)
	for y in range(2, 10):
		_set_pixel_safe(img, 4, y, c); _set_pixel_safe(img, 11, y, c)
	for y in range(3, 9):
		for x in range(5, 11):
			_set_pixel_safe(img, x, y, cl if y < 5 else c)
	for x in range(5, 11):
		_set_pixel_safe(img, x, 10, c)
	_set_pixel_safe(img, 6, 11, c); _set_pixel_safe(img, 9, 11, c)
	_set_pixel_safe(img, 7, 12, c); _set_pixel_safe(img, 8, 12, c)
	_set_pixel_safe(img, 7, 5, Color.WHITE); _set_pixel_safe(img, 8, 5, Color.WHITE)
	_set_pixel_safe(img, 7, 6, Color.WHITE); _set_pixel_safe(img, 8, 6, Color.WHITE)
	_set_pixel_safe(img, 6, 6, Color.WHITE); _set_pixel_safe(img, 9, 6, Color.WHITE)
