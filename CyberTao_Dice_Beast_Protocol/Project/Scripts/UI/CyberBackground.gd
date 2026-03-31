extends Control
class_name CyberBackground

## 美化 Phase 4.1：赛博朋克背景氛围系统
## 深色渐变背景 + 透视网格线 + 浮动粒子 + 棋盘发光边框

# --- 配置常量 ---

# 渐变背景
const GRAD_TOP := Color(0.015, 0.015, 0.04)
const GRAD_MID := Color(0.03, 0.03, 0.07)
const GRAD_BOTTOM := Color(0.05, 0.04, 0.09)

# 透视网格
const GRID_COLOR_MAIN := Color(0.0, 0.6, 0.85, 0.06)
const GRID_COLOR_ACCENT := Color(0.0, 0.75, 1.0, 0.12)
const GRID_SPACING := 48
const GRID_LINE_WIDTH := 1.0

# 棋盘发光边框
const GLOW_COLOR_INNER := Color(0.0, 0.7, 0.95, 0.35)
const GLOW_COLOR_OUTER := Color(0.0, 0.5, 0.8, 0.08)
const GLOW_WIDTH := 3.0
const GLOW_OUTER_LAYERS := 4
const GLOW_OUTER_STEP := 3

# 扫描线
const SCAN_COLOR := Color(0.0, 0.85, 1.0, 0.03)
const SCAN_SPEED := 0.02
const SCAN_HEIGHT := 6.0

# 角标装饰
const CORNER_COLOR := Color(0.0, 0.75, 1.0, 0.4)
const CORNER_LEN := 14.0
const CORNER_WIDTH := 2.0

# 棋盘区域参数（从 Main.gd 传入）
var board_origin := Vector2(40, 94)
var board_size := Vector2(576, 576)  # 8*72=576

# 粒子节点
var _particles: CPUParticles2D = null

# 动画定时器
var _anim_timer: Timer = null

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 浮动粒子
	_particles = CPUParticles2D.new()
	_particles.emitting = true
	_particles.amount = 35
	_particles.lifetime = 6.0
	_particles.one_shot = false
	_particles.explosiveness = 0.0
	_particles.randomness = 1.0
	_particles.direction = Vector2(0, -1)
	_particles.spread = 180.0
	_particles.gravity = Vector2(0, 0)
	_particles.initial_velocity_min = 4.0
	_particles.initial_velocity_max = 12.0
	_particles.scale_amount_min = 1.0
	_particles.scale_amount_max = 2.5
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = Vector2(640, 360)
	_particles.position = Vector2(640, 360)
	_particles.color = Color(0.3, 0.75, 1.0, 0.18)
	var grad := Gradient.new()
	grad.set_offset(0, 0.0)
	grad.set_color(0, Color(0.2, 0.6, 1.0, 0.0))
	grad.add_point(0.15, Color(0.3, 0.8, 1.0, 0.22))
	grad.add_point(0.5, Color(0.2, 0.7, 0.95, 0.18))
	grad.add_point(0.85, Color(0.15, 0.5, 0.8, 0.1))
	grad.set_offset(1, 1.0)
	grad.set_color(1, Color(0.1, 0.3, 0.6, 0.0))
	_particles.color_ramp = grad
	add_child(_particles)
	# 动画刷新（20fps 够用）
	_anim_timer = Timer.new()
	_anim_timer.wait_time = 0.05
	_anim_timer.autostart = true
	_anim_timer.timeout.connect(queue_redraw)
	add_child(_anim_timer)

func set_board_rect(origin: Vector2, sz: Vector2) -> void:
	board_origin = origin
	board_size = sz
	queue_redraw()

func _draw() -> void:
	var vp_size := get_rect().size
	if vp_size.x < 1.0:
		vp_size = Vector2(1280, 720)
	var t_sec: float = Time.get_ticks_msec() * 0.001
	_draw_gradient(vp_size)
	_draw_grid(vp_size, t_sec)
	_draw_scan_line(vp_size, t_sec)
	# v0.1.60：相机跟随模式下不再绘制棋盘边框和角标（棋盘超出视口）

# --- 绘制子模块 ---

func _draw_gradient(vp: Vector2) -> void:
	var steps := 12
	var step_h: float = vp.y / float(steps)
	for i in range(steps):
		var ratio: float = float(i) / float(steps)
		var c: Color
		if ratio < 0.5:
			c = GRAD_TOP.lerp(GRAD_MID, ratio * 2.0)
		else:
			c = GRAD_MID.lerp(GRAD_BOTTOM, (ratio - 0.5) * 2.0)
		draw_rect(Rect2(0, i * step_h, vp.x, step_h + 1), c, true)

func _draw_grid(vp: Vector2, t: float) -> void:
	var drift: float = fmod(t * 3.0, float(GRID_SPACING))
	# 水平线
	var y_start: float = board_origin.y + board_size.y + 10
	var y: float = y_start + drift
	while y < vp.y:
		var fade: float = clampf(1.0 - (y - y_start) / (vp.y - y_start), 0.0, 1.0)
		var c: Color = GRID_COLOR_MAIN
		c.a *= fade * fade
		draw_line(Vector2(0, y), Vector2(vp.x, y), c, GRID_LINE_WIDTH)
		y += GRID_SPACING
	# 垂直线
	var x: float = 0.0
	while x < vp.x:
		var dist_center: float = absf(x - vp.x * 0.5) / (vp.x * 0.5)
		var fade_x: float = clampf(1.0 - dist_center * 0.6, 0.0, 1.0)
		var c: Color = GRID_COLOR_MAIN
		c.a *= fade_x
		var y0: float = board_origin.y + board_size.y + 10
		draw_line(Vector2(x, y0), Vector2(x, vp.y), c, GRID_LINE_WIDTH)
		x += GRID_SPACING
	# 中心强调线
	var cx: float = board_origin.x + board_size.x * 0.5
	var cy_start: float = board_origin.y + board_size.y + 10
	draw_line(Vector2(cx, cy_start), Vector2(cx, vp.y), GRID_COLOR_ACCENT, GRID_LINE_WIDTH + 0.5)

func _draw_scan_line(vp: Vector2, t: float) -> void:
	var cycle: float = fmod(t * SCAN_SPEED, 1.0)
	var sy: float = cycle * vp.y
	draw_rect(Rect2(0, sy, vp.x, SCAN_HEIGHT), SCAN_COLOR, true)

func _draw_board_glow(t: float) -> void:
	var pulse: float = sin(t * 2.0) * 0.15 + 0.85
	var r := Rect2(board_origin - Vector2(2, 2), board_size + Vector2(4, 4))
	# 外层辉光（多层半透明）
	for i in range(GLOW_OUTER_LAYERS):
		var expand: float = float(i + 1) * GLOW_OUTER_STEP
		var outer := Rect2(r.position - Vector2(expand, expand), r.size + Vector2(expand * 2, expand * 2))
		var c := GLOW_COLOR_OUTER
		c.a *= pulse * (1.0 - float(i) / float(GLOW_OUTER_LAYERS))
		draw_rect(outer, c, false, 1.0)
	# 内层亮线
	var inner_c := GLOW_COLOR_INNER
	inner_c.a *= pulse
	draw_rect(r, inner_c, false, GLOW_WIDTH)

func _draw_corner_marks() -> void:
	var r := Rect2(board_origin - Vector2(4, 4), board_size + Vector2(8, 8))
	var tl := r.position
	var tr := Vector2(r.position.x + r.size.x, r.position.y)
	var bl := Vector2(r.position.x, r.position.y + r.size.y)
	var br := r.position + r.size
	# 四个角各画两条短线
	_draw_corner(tl, 1, 1)
	_draw_corner(tr, -1, 1)
	_draw_corner(bl, 1, -1)
	_draw_corner(br, -1, -1)

func _draw_corner(pos: Vector2, dx: int, dy: int) -> void:
	draw_line(pos, pos + Vector2(CORNER_LEN * dx, 0), CORNER_COLOR, CORNER_WIDTH)
	draw_line(pos, pos + Vector2(0, CORNER_LEN * dy), CORNER_COLOR, CORNER_WIDTH)
