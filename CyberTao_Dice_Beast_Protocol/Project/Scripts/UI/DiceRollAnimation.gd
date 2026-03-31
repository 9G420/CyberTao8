extends Control
class_name DiceRollAnimation

## 掷骰演出动画 v3（v0.1.64：更大骰子+更长动画+视觉增强）
## 全屏遮罩 → 棋盘中央 3 枚等距立方体翻滚 → 逐个定格 → 淡出

signal animation_finished(results: Array[String], crest_pool: Dictionary)

# --- 布局（v0.1.64：放大骰子+延长动画）---
const DICE_HW: float = 56.0
const DICE_H_RATIO: float = 1.15
const DICE_GAP: float = 48.0
const TUMBLE_DURATION: float = 1.4
const SETTLE_INTERVAL: float = 0.4
const POST_HOLD: float = 0.8
const FADE_DURATION: float = 0.4
const CREST_FACES: PackedStringArray = ["summon", "move", "attack", "defend", "skill", "trick"]

var board_center: Vector2 = Vector2(328, 382)

var _results: Array[String] = []
var _crest_pool: Dictionary = {}
var _display: Array[String] = ["", "", ""]
var _settled: Array[bool] = [false, false, false]
var _die_scale: Array[float] = [1.0, 1.0, 1.0]
var _die_glow: Array[float] = [0.0, 0.0, 0.0]
var _die_wobble_y: Array[float] = [0.0, 0.0, 0.0]
var _die_rotation: Array[float] = [0.0, 0.0, 0.0]
var _overlay_alpha: float = 0.0
var _swap_accum: float = 0.0
var _tumble_time: float = 0.0
var _phase: String = "idle"

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(PRESET_FULL_RECT)
	set_process(false)

func set_board_center(center: Vector2) -> void:
	board_center = center

func play(results: Array[String], crest_pool: Dictionary) -> void:
	_results = results
	_crest_pool = crest_pool
	_display = ["", "", ""]
	_settled = [false, false, false]
	_die_scale = [1.0, 1.0, 1.0]
	_die_glow = [0.0, 0.0, 0.0]
	_die_wobble_y = [0.0, 0.0, 0.0]
	_die_rotation = [0.0, 0.0, 0.0]
	_swap_accum = 0.0
	_tumble_time = 0.0
	_overlay_alpha = 0.0
	_phase = "tumble"
	visible = true
	set_process(true)
	for i in range(3):
		_display[i] = CREST_FACES[randi() % CREST_FACES.size()]
	var tw: Tween = create_tween()
	# 遮罩淡入（稍慢）
	tw.tween_method(_set_alpha, 0.0, 0.78, 0.25)
	tw.tween_interval(TUMBLE_DURATION)
	# 逐个定格（每颗骰子之间间隔更长）
	for i in range(3):
		tw.tween_callback(_settle_die.bind(i))
		tw.tween_interval(SETTLE_INTERVAL)
	tw.tween_callback(func() -> void: _phase = "hold")
	tw.tween_interval(POST_HOLD)
	tw.tween_callback(_start_fade)

func _process(delta: float) -> void:
	if _phase == "tumble" or _phase == "settling":
		_tumble_time += delta
		_swap_accum += delta
		# 翻滚阶段：面逐渐变慢（模拟骰子减速）
		var swap_threshold: float = 0.04 + _tumble_time * 0.02
		if _swap_accum >= swap_threshold:
			_swap_accum = 0.0
			for i in range(3):
				if not _settled[i]:
					_display[i] = CREST_FACES[randi() % CREST_FACES.size()]
					# 弹跳 wobble（振幅随时间衰减）
					var bounce_amp: float = maxf(1.0, 10.0 - _tumble_time * 4.0)
					_die_wobble_y[i] = (randf() - 0.5) * bounce_amp
					# 旋转效果
					_die_rotation[i] += (randf() - 0.5) * 0.15
	for i in range(3):
		if _die_glow[i] > 0.0:
			_die_glow[i] = maxf(0.0, _die_glow[i] - delta * 1.5)
		# 平滑回正旋转
		if _settled[i]:
			_die_rotation[i] = lerpf(_die_rotation[i], 0.0, delta * 6.0)
	queue_redraw()

func _set_alpha(v: float) -> void:
	_overlay_alpha = v

func _settle_die(idx: int) -> void:
	_phase = "settling"
	if idx < _results.size():
		_display[idx] = _results[idx]
	_settled[idx] = true
	_die_scale[idx] = 1.4
	_die_glow[idx] = 1.0
	_die_wobble_y[idx] = 0.0
	var tw: Tween = create_tween()
	tw.tween_method(func(v: float) -> void: _die_scale[idx] = v, 1.4, 1.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _start_fade() -> void:
	_phase = "fade_out"
	var tw: Tween = create_tween()
	tw.tween_method(_set_alpha, _overlay_alpha, 0.0, FADE_DURATION)
	tw.tween_callback(_finish)

func _finish() -> void:
	_phase = "idle"
	set_process(false)
	visible = false
	animation_finished.emit(_results, _crest_pool)

# ===========================================================
#  绘制
# ===========================================================

func _draw() -> void:
	if _phase == "idle":
		return
	var vp: Vector2 = get_rect().size
	if vp.x < 1.0:
		vp = Vector2(1280, 720)
	# 遮罩（稍深）
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.015, 0.015, 0.05, _overlay_alpha * 0.88), true)
	# 中心光晕（营造舞台感）
	if _overlay_alpha > 0.1:
		_draw_center_glow(vp)
	var font: Font = ThemeDB.fallback_font
	var total_w: float = DICE_HW * 2.0 * 3.0 + DICE_GAP * 2.0
	var start_x: float = board_center.x - total_w * 0.5 + DICE_HW
	for i in range(3):
		var cx: float = start_x + i * (DICE_HW * 2.0 + DICE_GAP)
		var cy: float = board_center.y + _die_wobble_y[i]
		# 落地阴影
		_draw_die_shadow(cx, board_center.y, DICE_HW * _die_scale[i])
		_draw_iso_cube(cx, cy, DICE_HW * _die_scale[i], _display[i], _settled[i], _die_glow[i], font)
	# 结果文字（更大字号）
	if _phase == "hold" or _phase == "fade_out":
		var txt: String = ""
		for i in range(_results.size()):
			if i > 0:
				txt += "   "
			txt += _crest_name(_results[i])
		var ty: float = board_center.y + DICE_HW * DICE_H_RATIO + 28
		var txt_w: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		draw_string(font, Vector2(board_center.x - txt_w * 0.5, ty), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.85, 0.92, 1.0, _overlay_alpha * 1.2))

## 中心径向光晕（衬托骰子）
func _draw_center_glow(vp: Vector2) -> void:
	var glow_r: float = 180.0
	var steps: int = 6
	for i in range(steps):
		var ratio: float = float(i) / float(steps)
		var r: float = glow_r * (1.0 - ratio)
		var a: float = _overlay_alpha * 0.06 * (1.0 - ratio)
		draw_circle(board_center, r, Color(0.1, 0.5, 0.8, a))

## 骰子落地阴影
func _draw_die_shadow(cx: float, base_y: float, hw: float) -> void:
	var shadow_hw: float = hw * 0.8
	var shadow_hh: float = shadow_hw * 0.3
	var sy: float = base_y + hw * DICE_H_RATIO + 6.0
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(cx, sy - shadow_hh),
		Vector2(cx + shadow_hw, sy),
		Vector2(cx, sy + shadow_hh),
		Vector2(cx - shadow_hw, sy),
	])
	draw_colored_polygon(pts, Color(0.0, 0.0, 0.0, _overlay_alpha * 0.25))

# --- 等距伪 3D 立方体（v0.1.64：增强视觉）---

func _draw_iso_cube(cx: float, cy: float, hw: float, crest: String, settled: bool, glow: float, font: Font) -> void:
	var hh: float = hw * DICE_H_RATIO
	var col: Color = _crest_color(crest)
	# 六边形 6 顶点
	var pt: Vector2 = Vector2(cx, cy - hh)
	var pul: Vector2 = Vector2(cx - hw, cy - hh * 0.5)
	var pur: Vector2 = Vector2(cx + hw, cy - hh * 0.5)
	var pc: Vector2 = Vector2(cx, cy)
	var pll: Vector2 = Vector2(cx - hw, cy + hh * 0.5)
	var plr: Vector2 = Vector2(cx + hw, cy + hh * 0.5)
	var pb: Vector2 = Vector2(cx, cy + hh)
	# 顶面（稍亮）
	var top_col: Color = Color(0.08, 0.09, 0.18, 0.97)
	if settled:
		top_col = Color(0.09, 0.1, 0.2, 0.97)
	draw_colored_polygon(PackedVector2Array([pt, pur, pc, pul]), top_col)
	# 左面
	draw_colored_polygon(PackedVector2Array([pul, pc, pb, pll]), Color(0.045, 0.05, 0.1, 0.97))
	# 右面
	draw_colored_polygon(PackedVector2Array([pc, pur, plr, pb]), Color(0.03, 0.035, 0.075, 0.97))
	# 边框（更粗更亮）
	var la: float = 0.65 if settled else 0.22
	var lc: Color = Color(col.r, col.g, col.b, la)
	var lw: float = 2.0 if settled else 1.5
	draw_line(pt, pur, lc, lw)
	draw_line(pur, plr, lc, lw)
	draw_line(plr, pb, lc, lw)
	draw_line(pb, pll, lc, lw)
	draw_line(pll, pul, lc, lw)
	draw_line(pul, pt, lc, lw)
	# 内部棱线
	var ila: float = la * 0.35
	var ilc: Color = Color(col.r, col.g, col.b, ila)
	draw_line(pc, pul, ilc, 1.0)
	draw_line(pc, pur, ilc, 1.0)
	draw_line(pc, pb, ilc, 1.0)
	# 辉光（多层光晕）
	if glow > 0.0:
		for layer in range(3):
			var ga: float = glow * (0.25 - float(layer) * 0.06)
			var gw: float = 3.0 + float(layer) * 3.0
			var gc: Color = Color(col.r, col.g, col.b, ga)
			draw_line(pt, pur, gc, gw)
			draw_line(pur, plr, gc, gw)
			draw_line(plr, pb, gc, gw)
			draw_line(pb, pll, gc, gw)
			draw_line(pll, pul, gc, gw)
			draw_line(pul, pt, gc, gw)
	# Crest 符号（顶面中心，更大）
	var fcx: float = (pt.x + pur.x + pc.x + pul.x) * 0.25
	var fcy: float = (pt.y + pur.y + pc.y + pul.y) * 0.25
	var sa: float = 0.95 if settled else 0.35
	_draw_crest_symbol(fcx, fcy, hw * 0.36, crest, Color(col.r, col.g, col.b, sa))
	# Crest 名称（右面中心，更大字号）
	var ncx: float = (pc.x + pur.x + plr.x + pb.x) * 0.25
	var ncy: float = (pc.y + pur.y + plr.y + pb.y) * 0.25
	var na: float = 0.85 if settled else 0.2
	var fsize: int = 14
	var name_text: String = _crest_name(crest)
	var name_w: float = font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
	draw_string(font, Vector2(ncx - name_w * 0.5, ncy + 5), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(col.r, col.g, col.b, na))

# --- Crest 符号 ---

func _draw_crest_symbol(cx: float, cy: float, r: float, crest: String, col: Color) -> void:
	var lw: float = 2.5
	match crest:
		"summon":
			_draw_star(cx, cy, r, 5, col)
		"move":
			draw_line(Vector2(cx - r, cy), Vector2(cx + r, cy), col, lw)
			draw_line(Vector2(cx + r, cy), Vector2(cx + r * 0.4, cy - r * 0.55), col, lw)
			draw_line(Vector2(cx + r, cy), Vector2(cx + r * 0.4, cy + r * 0.55), col, lw)
		"attack":
			draw_line(Vector2(cx - r, cy - r), Vector2(cx + r, cy + r), col, 3.0)
			draw_line(Vector2(cx + r, cy - r), Vector2(cx - r, cy + r), col, 3.0)
		"defend":
			draw_line(Vector2(cx - r * 0.65, cy - r), Vector2(cx + r * 0.65, cy - r), col, lw)
			draw_line(Vector2(cx - r * 0.65, cy - r), Vector2(cx - r * 0.65, cy + r * 0.3), col, lw)
			draw_line(Vector2(cx + r * 0.65, cy - r), Vector2(cx + r * 0.65, cy + r * 0.3), col, lw)
			draw_line(Vector2(cx - r * 0.65, cy + r * 0.3), Vector2(cx, cy + r), col, lw)
			draw_line(Vector2(cx + r * 0.65, cy + r * 0.3), Vector2(cx, cy + r), col, lw)
		"skill":
			draw_arc(Vector2(cx, cy), r, 0, TAU, 24, col, lw)
			draw_arc(Vector2(cx, cy), r * 0.38, 0, TAU, 16, col, 2.0)
		"trick":
			var pts: PackedVector2Array = PackedVector2Array()
			for j in range(6):
				var angle: float = j * TAU / 6.0 - PI / 6.0
				pts.append(Vector2(cx + cos(angle) * r, cy + sin(angle) * r))
			for j in range(6):
				draw_line(pts[j], pts[(j + 1) % 6], col, lw)

func _draw_star(cx: float, cy: float, r: float, points: int, col: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(points * 2):
		var angle: float = i * TAU / (points * 2) - PI / 2.0
		var dist: float = r if i % 2 == 0 else r * 0.4
		pts.append(Vector2(cx + cos(angle) * dist, cy + sin(angle) * dist))
	for i in range(pts.size()):
		draw_line(pts[i], pts[(i + 1) % pts.size()], col, 2.0)

# --- 颜色/名称 ---

static func _crest_color(crest: String) -> Color:
	match crest:
		"summon": return CyberStyle.ACCENT_CYAN
		"move": return CyberStyle.NEON_TEAL
		"attack": return CyberStyle.ACCENT_ORANGE
		"defend": return CyberStyle.NEON_GOLD
		"skill": return CyberStyle.ACCENT_MAGENTA
		"trick": return CyberStyle.NEON_PURPLE
	return CyberStyle.TEXT_PRIMARY

static func _crest_name(crest: String) -> String:
	match crest:
		"summon": return "显化"
		"move": return "步进"
		"attack": return "杀伐"
		"defend": return "护持"
		"skill": return "术式"
		"trick": return "机巧"
	return crest
