extends RefCounted
class_name BoardCellRenderer

## 棋盘格渲染器（Phase 1 美化）
## 所有格子视觉升级：发光边缘 + 渐变 + 赛博符号
## 颜色 100% 来自 CyberStyle，不硬编码

# --- 辉光辅助：3 层外发光叠加 ---

static func _glow(c: CanvasItem, rect: Rect2, col: Color, intensity: float) -> void:
	var r: Color = Color(col.r, col.g, col.b, 0.06 * intensity)
	c.draw_rect(Rect2(rect.position - Vector2(3, 3), rect.size + Vector2(6, 6)), r, false, 1.0)
	r.a = 0.15 * intensity
	c.draw_rect(Rect2(rect.position - Vector2(1.5, 1.5), rect.size + Vector2(3, 3)), r, false, 1.0)
	r.a = 0.35 * intensity
	c.draw_rect(rect, r, false, 1.5)

# --- 基础格子：暗色交替 + 微渐变 + 青色网格线 ---

static func draw_base_cell(c: CanvasItem, x: int, y: int, cs: int) -> void:
	var pos: Vector2 = Vector2(x * cs, y * cs)
	var sz: Vector2 = Vector2(cs - 2, cs - 2)
	var base: Color = CyberStyle.BOARD_CELL_DARK if (x + y) % 2 == 0 else CyberStyle.BOARD_CELL_LIGHT
	c.draw_rect(Rect2(pos, sz), base, true)
	# 内部微亮区域（模拟径向渐变）
	var inner_pos: Vector2 = pos + Vector2(10, 10)
	var inner_sz: Vector2 = sz - Vector2(20, 20)
	c.draw_rect(Rect2(inner_pos, inner_sz), CyberStyle.BOARD_INNER_GLOW, true)
	# 网格线
	c.draw_rect(Rect2(pos, sz), CyberStyle.BOARD_GRID_LINE, false, 1.0)

# --- 类型格子分发 ---

static func draw_overlay(c: CanvasItem, rect: Rect2, cell_type: String, pulse: float, font: Font, extra: String) -> void:
	match cell_type:
		"high_ground":
			_draw_high_ground(c, rect, pulse, font)
		"trap":
			_draw_trap(c, rect, pulse, font)
		"encounter":
			_draw_encounter(c, rect, pulse, font)
		"boss":
			_draw_boss(c, rect, pulse, font)
		"heal":
			_draw_heal(c, rect, pulse, font, extra)
		"event":
			_draw_event(c, rect, pulse, font)
		"shop":
			_draw_shop(c, rect, pulse, font, extra)
		"chest":
			_draw_chest(c, rect, pulse, font)
		"item":
			_draw_item(c, rect, pulse, font, extra)
		"path_player":
			_draw_path(c, rect, pulse, CyberStyle.ACCENT_CYAN)
		"path_other":
			_draw_path(c, rect, pulse, CyberStyle.ACCENT_ORANGE)

# --- 高台：金色辉光 + ▲ 符号 + 高度阴影（Phase 6 预留）---

static func _draw_high_ground(c: CanvasItem, rect: Rect2, pulse: float, font: Font) -> void:
	var col: Color = CyberStyle.NEON_GOLD
	var a: float = 0.18 + pulse * 0.1
	# 高度阴影（2px 偏移）
	c.draw_rect(Rect2(rect.position + Vector2(2, 2), rect.size), Color(0.0, 0.0, 0.0, 0.2), true)
	c.draw_rect(rect, Color(col.r, col.g, col.b, a), true)
	_glow(c, rect, col, 0.7 + pulse * 0.4)
	# ▲ 三角符号
	var cx: float = rect.position.x + rect.size.x * 0.5
	var cy: float = rect.position.y + rect.size.y * 0.38
	var ts: float = 11.0
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(cx, cy - ts), Vector2(cx - ts * 0.85, cy + ts * 0.5), Vector2(cx + ts * 0.85, cy + ts * 0.5)])
	c.draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.65 + pulse * 0.25))

# --- 陷阱：红色脉冲 + ✖ 符号 ---

static func _draw_trap(c: CanvasItem, rect: Rect2, pulse: float, font: Font) -> void:
	var col: Color = CyberStyle.NEON_RED
	var a: float = 0.2 + pulse * 0.15
	c.draw_rect(rect, Color(col.r, col.g, col.b, a), true)
	_glow(c, rect, col, 0.6 + pulse * 0.5)
	# ✖ 交叉
	var cx: float = rect.position.x + rect.size.x * 0.5
	var cy: float = rect.position.y + rect.size.y * 0.4
	var s: float = 9.0
	var lc: Color = Color(col.r, col.g, col.b, 0.7 + pulse * 0.25)
	c.draw_line(Vector2(cx - s, cy - s), Vector2(cx + s, cy + s), lc, 2.5)
	c.draw_line(Vector2(cx + s, cy - s), Vector2(cx - s, cy + s), lc, 2.5)

# --- 普通遭遇：橙色呼吸 + ⚡ 闪电 ---

static func _draw_encounter(c: CanvasItem, rect: Rect2, pulse: float, font: Font) -> void:
	var col: Color = CyberStyle.ACCENT_ORANGE
	c.draw_rect(rect, Color(col.r, col.g, col.b, 0.22 + pulse * 0.12), true)
	_glow(c, rect, col, 0.7 + pulse * 0.35)
	# ⚡ 闪电符号（程序化折线）
	var cx: float = rect.position.x + rect.size.x * 0.5
	var cy: float = rect.position.y + rect.size.y * 0.35
	var lc: Color = Color(col.r, col.g, col.b, 0.75 + pulse * 0.2)
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(cx + 2, cy - 10), Vector2(cx - 4, cy), Vector2(cx + 1, cy + 1),
		Vector2(cx - 5, cy + 12)])
	for i in range(pts.size() - 1):
		c.draw_line(pts[i], pts[i + 1], lc, 2.5)

# --- Boss 遭遇：深红粗光 + 骷髅符号 ---

static func _draw_boss(c: CanvasItem, rect: Rect2, pulse: float, font: Font) -> void:
	var col: Color = CyberStyle.NEON_RED
	c.draw_rect(rect, Color(col.r, col.g, col.b, 0.3 + pulse * 0.15), true)
	_glow(c, rect, col, 1.0 + pulse * 0.5)
	# 额外粗发光框
	c.draw_rect(rect, Color(col.r, col.g, col.b, 0.6 + pulse * 0.3), false, 3.0)
	# BOSS 文字
	var tx: float = rect.position.x + rect.size.x * 0.15
	var ty: float = rect.position.y + rect.size.y * 0.6
	c.draw_string(font, Vector2(tx, ty), "BOSS", HORIZONTAL_ALIGNMENT_LEFT, int(rect.size.x * 0.7), 13, Color(col.r, col.g, col.b, 0.9 + pulse * 0.1))

# --- 回复格：蓝色辉光 + ✚ 十字 + 回复量 ---

static func _draw_heal(c: CanvasItem, rect: Rect2, pulse: float, font: Font, amount: String) -> void:
	var col: Color = CyberStyle.NEON_BLUE
	c.draw_rect(rect, Color(col.r, col.g, col.b, 0.18 + pulse * 0.08), true)
	_glow(c, rect, col, 0.6 + pulse * 0.3)
	# ✚ 十字
	var cx: float = rect.position.x + rect.size.x * 0.5
	var cy: float = rect.position.y + rect.size.y * 0.35
	var s: float = 8.0
	var lc: Color = Color(col.r, col.g, col.b, 0.7 + pulse * 0.2)
	c.draw_line(Vector2(cx - s, cy), Vector2(cx + s, cy), lc, 2.5)
	c.draw_line(Vector2(cx, cy - s), Vector2(cx, cy + s), lc, 2.5)
	# 回复量
	if amount != "":
		var tx: float = rect.position.x + rect.size.x * 0.25
		var ty: float = rect.position.y + rect.size.y * 0.75
		c.draw_string(font, Vector2(tx, ty), "+" + amount, HORIZONTAL_ALIGNMENT_LEFT, int(rect.size.x * 0.5), 10, Color(col.r, col.g, col.b, 0.85))

# --- 事件格：紫色辉光 + ? 符号 ---

static func _draw_event(c: CanvasItem, rect: Rect2, pulse: float, font: Font) -> void:
	var col: Color = CyberStyle.NEON_PURPLE
	c.draw_rect(rect, Color(col.r, col.g, col.b, 0.18 + pulse * 0.1), true)
	_glow(c, rect, col, 0.6 + pulse * 0.35)
	var tx: float = rect.position.x + rect.size.x * 0.35
	var ty: float = rect.position.y + rect.size.y * 0.62
	c.draw_string(font, Vector2(tx, ty), "?", HORIZONTAL_ALIGNMENT_LEFT, 20, 18, Color(col.r, col.g, col.b, 0.8 + pulse * 0.2))

# --- 商店格：青绿辉光 + ◆ 菱形 + 费用 ---

static func _draw_shop(c: CanvasItem, rect: Rect2, pulse: float, font: Font, info: String) -> void:
	var col: Color = CyberStyle.NEON_TEAL
	c.draw_rect(rect, Color(col.r, col.g, col.b, 0.2 + pulse * 0.08), true)
	_glow(c, rect, col, 0.6 + pulse * 0.3)
	# ◆ 菱形
	var cx: float = rect.position.x + rect.size.x * 0.5
	var cy: float = rect.position.y + rect.size.y * 0.35
	var s: float = 8.0
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(cx, cy - s), Vector2(cx + s, cy), Vector2(cx, cy + s), Vector2(cx - s, cy)])
	c.draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.65 + pulse * 0.2))
	if info != "":
		var tx: float = rect.position.x + 4
		var ty: float = rect.position.y + rect.size.y * 0.78
		c.draw_string(font, Vector2(tx, ty), info, HORIZONTAL_ALIGNMENT_LEFT, int(rect.size.x - 8), 9, Color(col.r, col.g, col.b, 0.75))

# --- 宝箱格：金琥珀辉光 + ⬡ 六角 ---

static func _draw_chest(c: CanvasItem, rect: Rect2, pulse: float, font: Font) -> void:
	var col: Color = CyberStyle.NEON_GOLD
	c.draw_rect(rect, Color(col.r, col.g, col.b, 0.2 + pulse * 0.1), true)
	_glow(c, rect, col, 0.7 + pulse * 0.35)
	# 六角形
	var cx: float = rect.position.x + rect.size.x * 0.5
	var cy: float = rect.position.y + rect.size.y * 0.4
	var r: float = 9.0
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(6):
		var angle: float = PI / 6.0 + i * PI / 3.0
		pts.append(Vector2(cx + cos(angle) * r, cy + sin(angle) * r))
	c.draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.6 + pulse * 0.25))

# --- 道具格：绿色辉光 + 名称 ---

static func _draw_item(c: CanvasItem, rect: Rect2, pulse: float, font: Font, name: String) -> void:
	var col: Color = CyberStyle.NEON_GREEN
	c.draw_rect(rect, Color(col.r, col.g, col.b, 0.18 + pulse * 0.08), true)
	_glow(c, rect, col, 0.5 + pulse * 0.3)
	# 菱形小图标
	var cx: float = rect.position.x + rect.size.x * 0.5
	var cy: float = rect.position.y + rect.size.y * 0.35
	var s: float = 6.0
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(cx, cy - s), Vector2(cx + s, cy), Vector2(cx, cy + s), Vector2(cx - s, cy)])
	c.draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.6 + pulse * 0.2))
	if name != "":
		var tx: float = rect.position.x + rect.size.x * 0.15
		var ty: float = rect.position.y + rect.size.y * 0.72
		c.draw_string(font, Vector2(tx, ty), name, HORIZONTAL_ALIGNMENT_LEFT, int(rect.size.x * 0.7), 9, Color(col.r, col.g, col.b, 0.8))

# --- 路径格：半透明辉光 ---

static func _draw_path(c: CanvasItem, rect: Rect2, pulse: float, col: Color) -> void:
	c.draw_rect(rect, Color(col.r, col.g, col.b, 0.12 + pulse * 0.06), true)
	_glow(c, rect, col, 0.4 + pulse * 0.2)

# --- 移动高亮：青色 L 角标 ---

static func draw_move_highlight(c: CanvasItem, rect: Rect2, pulse: float) -> void:
	var col: Color = CyberStyle.ACCENT_CYAN
	var a: float = 0.55 + pulse * 0.3
	var lc: Color = Color(col.r, col.g, col.b, a)
	var p: Vector2 = rect.position
	var s: Vector2 = rect.size
	var ln: float = 12.0
	var w: float = 2.0
	# 四角 L 形
	c.draw_line(p, Vector2(p.x + ln, p.y), lc, w)
	c.draw_line(p, Vector2(p.x, p.y + ln), lc, w)
	c.draw_line(Vector2(p.x + s.x, p.y), Vector2(p.x + s.x - ln, p.y), lc, w)
	c.draw_line(Vector2(p.x + s.x, p.y), Vector2(p.x + s.x, p.y + ln), lc, w)
	c.draw_line(Vector2(p.x, p.y + s.y), Vector2(p.x + ln, p.y + s.y), lc, w)
	c.draw_line(Vector2(p.x, p.y + s.y), Vector2(p.x, p.y + s.y - ln), lc, w)
	c.draw_line(Vector2(p.x + s.x, p.y + s.y), Vector2(p.x + s.x - ln, p.y + s.y), lc, w)
	c.draw_line(Vector2(p.x + s.x, p.y + s.y), Vector2(p.x + s.x, p.y + s.y - ln), lc, w)
	# 微弱填充
	c.draw_rect(rect, Color(col.r, col.g, col.b, 0.06 + pulse * 0.04), true)

# --- 攻击高亮：红色准星 + 脉冲边框 ---

static func draw_attack_highlight(c: CanvasItem, rect: Rect2, pulse: float) -> void:
	var col: Color = CyberStyle.NEON_RED
	var a: float = 0.5 + pulse * 0.35
	var lc: Color = Color(col.r, col.g, col.b, a)
	var cx: float = rect.position.x + rect.size.x * 0.5
	var cy: float = rect.position.y + rect.size.y * 0.5
	var arm: float = 14.0
	var gap: float = 4.0
	# 准星十字（中间留空）
	c.draw_line(Vector2(cx - arm, cy), Vector2(cx - gap, cy), lc, 2.0)
	c.draw_line(Vector2(cx + gap, cy), Vector2(cx + arm, cy), lc, 2.0)
	c.draw_line(Vector2(cx, cy - arm), Vector2(cx, cy - gap), lc, 2.0)
	c.draw_line(Vector2(cx, cy + gap), Vector2(cx, cy + arm), lc, 2.0)
	# 脉冲边框
	c.draw_rect(rect, Color(col.r, col.g, col.b, 0.15 + pulse * 0.15), true)
	c.draw_rect(rect, Color(col.r, col.g, col.b, 0.35 + pulse * 0.3), false, 1.5)

# --- 召唤高亮：紫色圆环 ---

static func draw_summon_highlight(c: CanvasItem, rect: Rect2, pulse: float) -> void:
	var col: Color = CyberStyle.ACCENT_MAGENTA
	var a: float = 0.5 + pulse * 0.3
	var cx: float = rect.position.x + rect.size.x * 0.5
	var cy: float = rect.position.y + rect.size.y * 0.5
	var r: float = rect.size.x * 0.35
	# 外圈
	c.draw_arc(Vector2(cx, cy), r + 2, 0.0, TAU, 24, Color(col.r, col.g, col.b, a * 0.4), 1.5)
	# 主圈
	c.draw_arc(Vector2(cx, cy), r, 0.0, TAU, 24, Color(col.r, col.g, col.b, a), 2.0)
	# 微弱填充
	c.draw_rect(rect, Color(col.r, col.g, col.b, 0.06 + pulse * 0.04), true)
