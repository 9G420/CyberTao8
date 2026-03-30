extends RefCounted
class_name UnitRenderer

## 单位渲染器（Phase 1 美化）
## 独特形状 + 发光轮廓 + HP 条 + idle 微动画 + 选中脉冲
## 颜色 100% 来自 CyberStyle

# --- 单位完整绘制（形状 + 名称 + HP条 + 选中环 + 适性星） ---

static func draw_full_unit(c: CanvasItem, cell: Vector2i, cs: int, unit: Dictionary, is_selected: bool, pulse: float, idle_y: float, font: Font) -> void:
	var owner: String = String(unit.get("owner", "player"))
	var is_player: bool = owner == "player"
	var display_name: String = String(unit.get("display_name", ""))
	var hp: int = int(unit.get("hp", 1))
	var max_hp: int = int(unit.get("max_hp", 1))
	var hp_ratio: float = float(hp) / float(max_hp) if max_hp > 0 else 1.0

	var base_x: float = cell.x * cs + 10
	var base_y: float = cell.y * cs + 8 + idle_y
	var uw: float = cs - 22
	var uh: float = cs - 28

	if is_player:
		_draw_player_unit(c, Vector2(base_x, base_y), Vector2(uw, uh), display_name, pulse, font)
	else:
		_draw_enemy_unit(c, Vector2(base_x, base_y), Vector2(uw, uh), display_name, pulse, font)

	# HP 条
	_draw_hp_bar(c, Vector2(cell.x * cs + 8, cell.y * cs + cs - 12), cs - 16, hp_ratio, is_player)

	# 选中脉冲环
	if is_selected:
		_draw_selection(c, Vector2(cell.x * cs + 5, cell.y * cs + 5 + idle_y), Vector2(cs - 12, cs - 16), pulse)

# --- 玩家单位：根据名称绘制独特形状 ---

static func _draw_player_unit(c: CanvasItem, pos: Vector2, sz: Vector2, name: String, pulse: float, font: Font) -> void:
	var col: Color = CyberStyle.HP_PLAYER
	var glow_a: float = 0.25 + pulse * 0.15
	var short: String = name.substr(0, 2) if name.length() >= 2 else name

	# 外发光
	c.draw_rect(Rect2(pos - Vector2(2, 2), sz + Vector2(4, 4)), Color(col.r, col.g, col.b, 0.08 + pulse * 0.06), false, 1.0)
	c.draw_rect(Rect2(pos - Vector2(1, 1), sz + Vector2(2, 2)), Color(col.r, col.g, col.b, 0.15 + pulse * 0.1), false, 1.0)

	# 根据单位名称选择形状
	var cx: float = pos.x + sz.x * 0.5
	var cy: float = pos.y + sz.y * 0.5

	if name.begins_with("刀盾") or name.begins_with("blade"):
		# 盾形：圆角矩形 + 底部V形
		c.draw_rect(Rect2(pos, sz), Color(col.r, col.g, col.b, glow_a), true)
		c.draw_rect(Rect2(pos, sz), Color(col.r, col.g, col.b, 0.7), false, 2.0)
		# V形底部装饰
		c.draw_line(Vector2(pos.x, pos.y + sz.y), Vector2(cx, pos.y + sz.y + 4), Color(col.r, col.g, col.b, 0.5), 1.5)
		c.draw_line(Vector2(pos.x + sz.x, pos.y + sz.y), Vector2(cx, pos.y + sz.y + 4), Color(col.r, col.g, col.b, 0.5), 1.5)
	elif name.begins_with("黑客") or name.begins_with("hacker"):
		# 菱形
		var pts: PackedVector2Array = PackedVector2Array([
			Vector2(cx, pos.y), Vector2(pos.x + sz.x, cy),
			Vector2(cx, pos.y + sz.y), Vector2(pos.x, cy)])
		c.draw_colored_polygon(pts, Color(col.r, col.g, col.b, glow_a))
		for i in range(4):
			c.draw_line(pts[i], pts[(i + 1) % 4], Color(col.r, col.g, col.b, 0.7), 2.0)
	elif name.begins_with("鸦") or name.begins_with("crow"):
		# 倒三角
		var pts: PackedVector2Array = PackedVector2Array([
			Vector2(pos.x, pos.y), Vector2(pos.x + sz.x, pos.y), Vector2(cx, pos.y + sz.y)])
		c.draw_colored_polygon(pts, Color(col.r, col.g, col.b, glow_a))
		for i in range(3):
			c.draw_line(pts[i], pts[(i + 1) % 3], Color(col.r, col.g, col.b, 0.7), 2.0)
	else:
		# 默认：圆角矩形
		c.draw_rect(Rect2(pos, sz), Color(col.r, col.g, col.b, glow_a), true)
		c.draw_rect(Rect2(pos, sz), Color(col.r, col.g, col.b, 0.7), false, 2.0)

	# 名称缩写
	if short != "":
		var tx: float = pos.x + sz.x * 0.2
		var ty: float = pos.y + sz.y * 0.55
		c.draw_string(font, Vector2(tx, ty), short, HORIZONTAL_ALIGNMENT_LEFT, int(sz.x * 0.6), 10, CyberStyle.TEXT_PRIMARY)

# --- 敌方单位：暗红 + 锯齿边框暗示威胁 ---

static func _draw_enemy_unit(c: CanvasItem, pos: Vector2, sz: Vector2, name: String, pulse: float, font: Font) -> void:
	var col: Color = CyberStyle.HP_ENEMY
	var glow_a: float = 0.25 + pulse * 0.12
	var short: String = name.substr(0, 2) if name.length() >= 2 else name

	# 外发光（红色）
	c.draw_rect(Rect2(pos - Vector2(2, 2), sz + Vector2(4, 4)), Color(col.r, col.g, col.b, 0.1 + pulse * 0.08), false, 1.0)
	c.draw_rect(Rect2(pos - Vector2(1, 1), sz + Vector2(2, 2)), Color(col.r, col.g, col.b, 0.2 + pulse * 0.1), false, 1.0)

	# 填充
	c.draw_rect(Rect2(pos, sz), Color(col.r, col.g, col.b, glow_a), true)
	# 锯齿边框效果：主边框 + 四角小三角装饰
	c.draw_rect(Rect2(pos, sz), Color(col.r, col.g, col.b, 0.65 + pulse * 0.2), false, 2.0)
	# 四角尖角装饰
	var ts: float = 5.0
	var lc: Color = Color(col.r, col.g, col.b, 0.6)
	c.draw_line(pos, Vector2(pos.x + ts, pos.y + ts), lc, 1.5)
	c.draw_line(Vector2(pos.x + sz.x, pos.y), Vector2(pos.x + sz.x - ts, pos.y + ts), lc, 1.5)
	c.draw_line(Vector2(pos.x, pos.y + sz.y), Vector2(pos.x + ts, pos.y + sz.y - ts), lc, 1.5)
	c.draw_line(Vector2(pos.x + sz.x, pos.y + sz.y), Vector2(pos.x + sz.x - ts, pos.y + sz.y - ts), lc, 1.5)

	# 名称
	if short != "":
		var tx: float = pos.x + sz.x * 0.2
		var ty: float = pos.y + sz.y * 0.55
		c.draw_string(font, Vector2(tx, ty), short, HORIZONTAL_ALIGNMENT_LEFT, int(sz.x * 0.6), 10, Color(1.0, 0.9, 0.85, 0.9))

# --- HP 条：薄条 + 绿→黄→红渐变 ---

static func _draw_hp_bar(c: CanvasItem, pos: Vector2, width: float, ratio: float, is_player: bool) -> void:
	var bar_h: float = 4.0
	# 底色
	c.draw_rect(Rect2(pos, Vector2(width, bar_h)), Color(0.15, 0.15, 0.2, 0.8), true)
	# HP 填充
	if ratio > 0.0:
		var fill_w: float = width * clampf(ratio, 0.0, 1.0)
		var fill_col: Color
		if ratio > 0.6:
			fill_col = CyberStyle.HP_PLAYER if is_player else CyberStyle.HP_ENEMY
		elif ratio > 0.3:
			fill_col = CyberStyle.TEXT_TITLE  # 金黄警告
		else:
			fill_col = CyberStyle.HP_PLAYER_LOW if is_player else CyberStyle.HP_ENEMY_LOW
		c.draw_rect(Rect2(pos, Vector2(fill_w, bar_h)), fill_col, true)
	# 边框
	c.draw_rect(Rect2(pos, Vector2(width, bar_h)), Color(0.5, 0.55, 0.6, 0.3), false, 1.0)

# --- 选中脉冲金色边框 ---

static func _draw_selection(c: CanvasItem, pos: Vector2, sz: Vector2, pulse: float) -> void:
	var col: Color = CyberStyle.NEON_GOLD
	var a: float = 0.5 + pulse * 0.4
	# 外层辉光
	c.draw_rect(Rect2(pos - Vector2(1, 1), sz + Vector2(2, 2)), Color(col.r, col.g, col.b, a * 0.3), false, 1.0)
	# 主选中框
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
