extends Control
class_name DiceRollAnimation

## 掷骰演出动画（Phase 2.1）
## 3枚骰子翻滚 → 逐个定格 → crest图标弹出发光
## 持续约 1.1s，完成后发信号

signal animation_finished(results: Array[String], crest_pool: Dictionary)

const DICE_SIZE: float = 56.0
const DICE_GAP: float = 10.0
const TUMBLE_DURATION: float = 0.55
const SETTLE_INTERVAL: float = 0.15
const POST_SETTLE_WAIT: float = 0.25
const CREST_FACES: PackedStringArray = ["summon", "move", "attack", "defend", "skill", "trick"]

var _results: Array[String] = []
var _crest_pool: Dictionary = {}
var _display: Array[String] = ["", "", ""]
var _settled: Array[bool] = [false, false, false]
var _die_scale: Array[float] = [1.0, 1.0, 1.0]
var _die_glow: Array[float] = [0.0, 0.0, 0.0]
var _swap_accum: float = 0.0

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	var total_w: float = DICE_SIZE * 3 + DICE_GAP * 2 + 20
	size = Vector2(total_w, DICE_SIZE + 28)

func play(results: Array[String], crest_pool: Dictionary) -> void:
	_results = results
	_crest_pool = crest_pool
	_display = ["", "", ""]
	_settled = [false, false, false]
	_die_scale = [1.0, 1.0, 1.0]
	_die_glow = [0.0, 0.0, 0.0]
	_swap_accum = 0.0
	visible = true
	set_process(true)
	for i in range(3):
		_display[i] = CREST_FACES[randi() % CREST_FACES.size()]
	var tw: Tween = create_tween()
	tw.tween_interval(TUMBLE_DURATION)
	for i in range(3):
		tw.tween_callback(_settle_die.bind(i))
		tw.tween_interval(SETTLE_INTERVAL)
	tw.tween_interval(POST_SETTLE_WAIT)
	tw.tween_callback(_finish)

func _process(delta: float) -> void:
	_swap_accum += delta
	if _swap_accum >= 0.055:
		_swap_accum = 0.0
		for i in range(3):
			if not _settled[i]:
				_display[i] = CREST_FACES[randi() % CREST_FACES.size()]
	for i in range(3):
		if _die_glow[i] > 0.0:
			_die_glow[i] = maxf(0.0, _die_glow[i] - delta * 2.5)
	queue_redraw()

func _settle_die(idx: int) -> void:
	if idx < _results.size():
		_display[idx] = _results[idx]
	_settled[idx] = true
	_die_scale[idx] = 1.25
	_die_glow[idx] = 1.0
	var tw: Tween = create_tween()
	tw.tween_method(func(v: float) -> void: _die_scale[idx] = v, 1.25, 1.0, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _finish() -> void:
	set_process(false)
	visible = false
	animation_finished.emit(_results, _crest_pool)

func _draw() -> void:
	# 半透明背景遮罩
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.03, 0.08, 0.92), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.7, 0.9, 0.12), false, 1.0)
	var font: Font = ThemeDB.fallback_font
	var base_x: float = 10.0
	var base_y: float = 14.0
	for i in range(3):
		var cx: float = base_x + i * (DICE_SIZE + DICE_GAP) + DICE_SIZE * 0.5
		var cy: float = base_y + DICE_SIZE * 0.5
		var sc: float = _die_scale[i]
		var hw: float = DICE_SIZE * 0.5 * sc
		var hh: float = DICE_SIZE * 0.5 * sc
		var rect: Rect2 = Rect2(cx - hw, cy - hh, hw * 2.0, hh * 2.0)
		var col: Color = _crest_color(_display[i])
		# 骰子底色
		draw_rect(rect, Color(0.05, 0.05, 0.11, 0.95), true)
		# 定格发光
		if _die_glow[i] > 0.0:
			var ga: float = _die_glow[i]
			draw_rect(Rect2(rect.position - Vector2(4, 4), rect.size + Vector2(8, 8)), Color(col.r, col.g, col.b, ga * 0.15), false, 1.5)
			draw_rect(Rect2(rect.position - Vector2(2, 2), rect.size + Vector2(4, 4)), Color(col.r, col.g, col.b, ga * 0.35), false, 1.5)
		# 边框
		var ba: float = 0.7 if _settled[i] else 0.25
		draw_rect(rect, Color(col.r, col.g, col.b, ba), false, 2.0)
		# Crest 符号
		_draw_crest(cx, cy - 4, DICE_SIZE * 0.28 * sc, _display[i], col, _settled[i])
		# Crest 名称
		var cname: String = _crest_name(_display[i])
		var ta: float = 0.85 if _settled[i] else 0.3
		draw_string(font, Vector2(cx - 18, cy + hh - 4), cname, HORIZONTAL_ALIGNMENT_CENTER, 36, 9, Color(col.r, col.g, col.b, ta))

# --- Crest 颜色/名称映射 ---

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

# --- Crest 符号程序化绘制 ---

func _draw_crest(cx: float, cy: float, r: float, crest: String, col: Color, settled: bool) -> void:
	var a: float = 0.9 if settled else 0.35
	var c: Color = Color(col.r, col.g, col.b, a)
	match crest:
		"summon":
			_draw_star(cx, cy, r, 5, c)
		"move":
			draw_line(Vector2(cx - r, cy), Vector2(cx + r, cy), c, 2.0)
			draw_line(Vector2(cx + r, cy), Vector2(cx + r * 0.4, cy - r * 0.6), c, 2.0)
			draw_line(Vector2(cx + r, cy), Vector2(cx + r * 0.4, cy + r * 0.6), c, 2.0)
		"attack":
			draw_line(Vector2(cx - r, cy - r), Vector2(cx + r, cy + r), c, 2.5)
			draw_line(Vector2(cx + r, cy - r), Vector2(cx - r, cy + r), c, 2.5)
		"defend":
			draw_line(Vector2(cx - r * 0.7, cy - r), Vector2(cx + r * 0.7, cy - r), c, 2.0)
			draw_line(Vector2(cx - r * 0.7, cy - r), Vector2(cx - r * 0.7, cy + r * 0.3), c, 2.0)
			draw_line(Vector2(cx + r * 0.7, cy - r), Vector2(cx + r * 0.7, cy + r * 0.3), c, 2.0)
			draw_line(Vector2(cx - r * 0.7, cy + r * 0.3), Vector2(cx, cy + r), c, 2.0)
			draw_line(Vector2(cx + r * 0.7, cy + r * 0.3), Vector2(cx, cy + r), c, 2.0)
		"skill":
			draw_arc(Vector2(cx, cy), r, 0, TAU, 24, c, 2.0)
			draw_arc(Vector2(cx, cy), r * 0.4, 0, TAU, 16, c, 1.5)
		"trick":
			var pts: PackedVector2Array = PackedVector2Array()
			for j in range(6):
				var angle: float = j * TAU / 6.0 - PI / 6.0
				pts.append(Vector2(cx + cos(angle) * r, cy + sin(angle) * r))
			for j in range(6):
				draw_line(pts[j], pts[(j + 1) % 6], c, 2.0)

func _draw_star(cx: float, cy: float, r: float, points: int, col: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(points * 2):
		var angle: float = i * TAU / (points * 2) - PI / 2.0
		var dist: float = r if i % 2 == 0 else r * 0.4
		pts.append(Vector2(cx + cos(angle) * dist, cy + sin(angle) * dist))
	for i in range(pts.size()):
		draw_line(pts[i], pts[(i + 1) % pts.size()], col, 1.5)
