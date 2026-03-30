extends Control
class_name DiceRollAnimation

## 掷骰演出动画 v2（伪 3D 等距骰子 + 全屏居中演出）
## 全屏遮罩 → 棋盘中央 3 枚等距立方体翻滚 → 逐个定格 → 淡出
## 替代旧版 Phase 2 内嵌小骰子

signal animation_finished(results: Array[String], crest_pool: Dictionary)

# --- 布局 ---
const DICE_HW: float = 34.0
const DICE_H_RATIO: float = 1.15
const DICE_GAP: float = 32.0
const TUMBLE_DURATION: float = 0.6
const SETTLE_INTERVAL: float = 0.18
const POST_HOLD: float = 0.45
const FADE_DURATION: float = 0.28
const CREST_FACES: PackedStringArray = ["summon", "move", "attack", "defend", "skill", "trick"]

var board_center: Vector2 = Vector2(328, 382)

var _results: Array[String] = []
var _crest_pool: Dictionary = {}
var _display: Array[String] = ["", "", ""]
var _settled: Array[bool] = [false, false, false]
var _die_scale: Array[float] = [1.0, 1.0, 1.0]
var _die_glow: Array[float] = [0.0, 0.0, 0.0]
var _die_wobble_y: Array[float] = [0.0, 0.0, 0.0]
var _overlay_alpha: float = 0.0
var _swap_accum: float = 0.0
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
	_swap_accum = 0.0
	_overlay_alpha = 0.0
	_phase = "tumble"
	visible = true
	set_process(true)
	for i in range(3):
		_display[i] = CREST_FACES[randi() % CREST_FACES.size()]
	var tw: Tween = create_tween()
	tw.tween_method(_set_alpha, 0.0, 0.75, 0.12)
	tw.tween_interval(TUMBLE_DURATION)
	for i in range(3):
		tw.tween_callback(_settle_die.bind(i))
		tw.tween_interval(SETTLE_INTERVAL)
	tw.tween_callback(func() -> void: _phase = "hold")
	tw.tween_interval(POST_HOLD)
	tw.tween_callback(_start_fade)

func _process(delta: float) -> void:
	if _phase == "tumble" or _phase == "settling":
		_swap_accum += delta
		if _swap_accum >= 0.05:
			_swap_accum = 0.0
			for i in range(3):
				if not _settled[i]:
					_display[i] = CREST_FACES[randi() % CREST_FACES.size()]
					_die_wobble_y[i] = (randf() - 0.5) * 5.0
	for i in range(3):
		if _die_glow[i] > 0.0:
			_die_glow[i] = maxf(0.0, _die_glow[i] - delta * 2.0)
	queue_redraw()

func _set_alpha(v: float) -> void:
	_overlay_alpha = v

func _settle_die(idx: int) -> void:
	_phase = "settling"
	if idx < _results.size():
		_display[idx] = _results[idx]
	_settled[idx] = true
	_die_scale[idx] = 1.3
	_die_glow[idx] = 1.0
	_die_wobble_y[idx] = 0.0
	var tw: Tween = create_tween()
	tw.tween_method(func(v: float) -> void: _die_scale[idx] = v, 1.3, 1.0, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

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
	# 遮罩
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.02, 0.02, 0.06, _overlay_alpha * 0.82), true)
	var font: Font = ThemeDB.fallback_font
	var total_w: float = DICE_HW * 2.0 * 3.0 + DICE_GAP * 2.0
	var start_x: float = board_center.x - total_w * 0.5 + DICE_HW
	for i in range(3):
		var cx: float = start_x + i * (DICE_HW * 2.0 + DICE_GAP)
		var cy: float = board_center.y + _die_wobble_y[i]
		_draw_iso_cube(cx, cy, DICE_HW * _die_scale[i], _display[i], _settled[i], _die_glow[i], font)
	# 结果文字
	if _phase == "hold" or _phase == "fade_out":
		var txt: String = ""
		for i in range(_results.size()):
			if i > 0:
				txt += "  "
			txt += _crest_name(_results[i])
		var ty: float = board_center.y + DICE_HW * DICE_H_RATIO + 18
		draw_string(font, Vector2(board_center.x - 90, ty), txt, HORIZONTAL_ALIGNMENT_CENTER, 180, 15, Color(0.85, 0.92, 1.0, _overlay_alpha * 1.2))

# --- 等距伪 3D 立方体 ---

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
	# 顶面
	draw_colored_polygon(PackedVector2Array([pt, pur, pc, pul]), Color(0.07, 0.08, 0.15, 0.96))
	# 左面
	draw_colored_polygon(PackedVector2Array([pul, pc, pb, pll]), Color(0.04, 0.045, 0.09, 0.96))
	# 右面
	draw_colored_polygon(PackedVector2Array([pc, pur, plr, pb]), Color(0.025, 0.03, 0.065, 0.96))
	# 边框
	var la: float = 0.55 if settled else 0.18
	var lc: Color = Color(col.r, col.g, col.b, la)
	var lw: float = 1.5
	draw_line(pt, pur, lc, lw)
	draw_line(pur, plr, lc, lw)
	draw_line(plr, pb, lc, lw)
	draw_line(pb, pll, lc, lw)
	draw_line(pll, pul, lc, lw)
	draw_line(pul, pt, lc, lw)
	# 内部棱线
	var ila: float = la * 0.4
	var ilc: Color = Color(col.r, col.g, col.b, ila)
	draw_line(pc, pul, ilc, 1.0)
	draw_line(pc, pur, ilc, 1.0)
	draw_line(pc, pb, ilc, 1.0)
	# 辉光
	if glow > 0.0:
		var ga: float = glow * 0.3
		var gc: Color = Color(col.r, col.g, col.b, ga)
		draw_line(pt, pur, gc, 4.0)
		draw_line(pur, plr, gc, 4.0)
		draw_line(plr, pb, gc, 4.0)
		draw_line(pb, pll, gc, 4.0)
		draw_line(pll, pul, gc, 4.0)
		draw_line(pul, pt, gc, 4.0)
	# Crest 符号（顶面中心）
	var fcx: float = (pt.x + pur.x + pc.x + pul.x) * 0.25
	var fcy: float = (pt.y + pur.y + pc.y + pul.y) * 0.25
	var sa: float = 0.9 if settled else 0.3
	_draw_crest_symbol(fcx, fcy, hw * 0.32, crest, Color(col.r, col.g, col.b, sa))
	# Crest 名称（右面中心）
	var ncx: float = (pc.x + pur.x + plr.x + pb.x) * 0.25
	var ncy: float = (pc.y + pur.y + plr.y + pb.y) * 0.25
	var na: float = 0.8 if settled else 0.2
	draw_string(font, Vector2(ncx - 12, ncy + 4), _crest_name(crest), HORIZONTAL_ALIGNMENT_CENTER, 24, 10, Color(col.r, col.g, col.b, na))

# --- Crest 符号 ---

func _draw_crest_symbol(cx: float, cy: float, r: float, crest: String, col: Color) -> void:
	match crest:
		"summon":
			_draw_star(cx, cy, r, 5, col)
		"move":
			draw_line(Vector2(cx - r, cy), Vector2(cx + r, cy), col, 2.0)
			draw_line(Vector2(cx + r, cy), Vector2(cx + r * 0.4, cy - r * 0.55), col, 2.0)
			draw_line(Vector2(cx + r, cy), Vector2(cx + r * 0.4, cy + r * 0.55), col, 2.0)
		"attack":
			draw_line(Vector2(cx - r, cy - r), Vector2(cx + r, cy + r), col, 2.5)
			draw_line(Vector2(cx + r, cy - r), Vector2(cx - r, cy + r), col, 2.5)
		"defend":
			draw_line(Vector2(cx - r * 0.65, cy - r), Vector2(cx + r * 0.65, cy - r), col, 2.0)
			draw_line(Vector2(cx - r * 0.65, cy - r), Vector2(cx - r * 0.65, cy + r * 0.3), col, 2.0)
			draw_line(Vector2(cx + r * 0.65, cy - r), Vector2(cx + r * 0.65, cy + r * 0.3), col, 2.0)
			draw_line(Vector2(cx - r * 0.65, cy + r * 0.3), Vector2(cx, cy + r), col, 2.0)
			draw_line(Vector2(cx + r * 0.65, cy + r * 0.3), Vector2(cx, cy + r), col, 2.0)
		"skill":
			draw_arc(Vector2(cx, cy), r, 0, TAU, 20, col, 2.0)
			draw_arc(Vector2(cx, cy), r * 0.38, 0, TAU, 14, col, 1.5)
		"trick":
			var pts: PackedVector2Array = PackedVector2Array()
			for j in range(6):
				var angle: float = j * TAU / 6.0 - PI / 6.0
				pts.append(Vector2(cx + cos(angle) * r, cy + sin(angle) * r))
			for j in range(6):
				draw_line(pts[j], pts[(j + 1) % 6], col, 2.0)

func _draw_star(cx: float, cy: float, r: float, points: int, col: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(points * 2):
		var angle: float = i * TAU / (points * 2) - PI / 2.0
		var dist: float = r if i % 2 == 0 else r * 0.4
		pts.append(Vector2(cx + cos(angle) * dist, cy + sin(angle) * dist))
	for i in range(pts.size()):
		draw_line(pts[i], pts[(i + 1) % pts.size()], col, 1.5)

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
