# ============================================================
# Map.gd - STS式垂直分支路线图
# 15层多分支、虚线连接、节点类型图标、玩家位置标记
# 底部为第0层(起始)，顶部为第14层(Boss)
# ============================================================
extends Control

# ── 布局常量 ──
const FLOOR_HEIGHT := 110  # 每层间距
const MAP_TOP_MARGIN := 60
const MAP_BOTTOM_MARGIN := 120
const NODE_RADIUS := 28
const MAP_TOTAL_HEIGHT: int = MAP_TOP_MARGIN + 15 * FLOOR_HEIGHT + MAP_BOTTOM_MARGIN
const VIEWPORT_W := 1280
const VIEWPORT_H := 720

# ── 节点类型颜色 ──
const TYPE_COLORS: Dictionary = {
	"battle": Color(0.7, 0.25, 0.2),
	"elite": Color(0.9, 0.6, 0.1),
	"rest": Color(0.2, 0.7, 0.4),
	"shop": Color(0.3, 0.6, 0.9),
	"event": Color(0.6, 0.4, 0.8),
	"treasure": Color(1, 0.8, 0.2),
	"boss": Color(0.9, 0.15, 0.15),
}

# ── 节点类型图标 (文字) ──
const TYPE_ICONS: Dictionary = {
	"battle": "⚔",
	"elite": "☠",
	"rest": "🔥",
	"shop": "💰",
	"event": "？",
	"treasure": "✦",
	"boss": "💀",
}

# ── 节点类型中文名 ──
const TYPE_NAMES: Dictionary = {
	"battle": "战斗",
	"elite": "精英",
	"rest": "休息",
	"shop": "商店",
	"event": "事件",
	"treasure": "宝箱",
	"boss": "Boss",
}

# ── 内部状态 ──
var scroll_offset: float = 0.0
var target_scroll: float = 0.0
var map_canvas: Control
var node_buttons: Array = []  # [{btn, floor_idx, node_idx, pos}]
var player_marker: TextureRect
var info_label: Label
var is_scrolling: bool = false

func _ready() -> void:
	_build_ui()
	AudioManager.play_bgm_generated("map")
	# 自动滚动到玩家位置
	_scroll_to_player()

func _build_ui() -> void:
	# ── 暗色背景 ──
	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.02, 0.06)
	add_child(bg)

	# ── 背景装饰 (电路纹理) ──
	_create_circuit_bg()

	# ── 地图滚动区域 ──
	# 使用ClipControl来裁剪超出区域的内容
	var clip := Control.new()
	clip.position = Vector2(100, 50)
	clip.size = Vector2(1050, 560)
	clip.clip_contents = true
	add_child(clip)

	map_canvas = Control.new()
	map_canvas.size = Vector2(1050, MAP_TOTAL_HEIGHT)
	map_canvas.position = Vector2(0, 0)
	clip.add_child(map_canvas)

	# ── 绘制地图内容 ──
	_draw_connections()
	_draw_nodes()
	_draw_player_marker()

	# ── 右侧图例面板 ──
	_build_legend_panel()

	# ── 顶部标题 ──
	var title := Label.new()
	title.text = "═══ 道 境 路 线 图 ═══"
	title.position = Vector2(0, 8)
	title.size = Vector2(VIEWPORT_W, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0, 0.9, 1))
	title.add_theme_color_override("font_shadow_color", Color(0, 0.4, 0.8, 0.4))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	add_child(title)

	# ── 底部状态栏 ──
	_build_status_bar()

	# ── 提示文字 ──
	info_label = Label.new()
	info_label.text = "选择下一个节点继续探索..."
	info_label.position = Vector2(0, 690)
	info_label.size = Vector2(VIEWPORT_W, 30)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	add_child(info_label)

	# ── CRT overlay ──
	var crt_overlay := ColorRect.new()
	crt_overlay.set_anchors_preset(PRESET_FULL_RECT)
	crt_overlay.z_index = 90
	crt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crt_overlay.color = Color(0, 0, 0, 0)
	var crt_shader = load("res://Shaders/crt.gdshader")
	if crt_shader:
		var crt_mat := ShaderMaterial.new()
		crt_mat.shader = crt_shader
		crt_overlay.material = crt_mat
	add_child(crt_overlay)

	# ── 检查地图是否全部完成 ──
	if GameState.is_map_complete():
		info_label.text = "所有节点已完成！前往觉醒..."
		Global.is_transitioning = false
		get_tree().change_scene_to_file(Global.SCENE_VICTORY)

# ============================================================
# 节点坐标计算
# ============================================================

## 将(floor_idx, col)映射到画布像素坐标
func _get_node_pos(floor_idx: int, col: int) -> Vector2:
	# X: 在1050px宽画布上分7列
	var x: float = 90.0 + col * 138.0
	# Y: 底部=第0层, 顶部=第14层 (倒置)
	var y: float = MAP_TOTAL_HEIGHT - MAP_BOTTOM_MARGIN - floor_idx * FLOOR_HEIGHT
	return Vector2(x, y)

# ============================================================
# 绘制连接线 (虚线)
# ============================================================

func _draw_connections() -> void:
	for floor_idx in range(GameState.MAP_FLOORS - 1):
		var cur_floor: Array = GameState.map_graph[floor_idx]
		var next_floor: Array = GameState.map_graph[floor_idx + 1]

		for ni in range(cur_floor.size()):
			var node: Dictionary = cur_floor[ni]
			var from_pos: Vector2 = _get_node_pos(floor_idx, node["col"])

			for conn_idx in node["connections"]:
				if conn_idx < 0 or conn_idx >= next_floor.size():
					continue
				var target_node: Dictionary = next_floor[conn_idx]
				var to_pos: Vector2 = _get_node_pos(floor_idx + 1, target_node["col"])

				# 判断是否是玩家已走过的路径
				var is_walked := _is_path_walked(floor_idx, ni, floor_idx + 1, conn_idx)
				# 判断是否是当前可选的路径
				var is_available := _is_path_available(floor_idx, ni, floor_idx + 1, conn_idx)

				_draw_dashed_line(from_pos, to_pos, is_walked, is_available)

## 绘制虚线
func _draw_dashed_line(from: Vector2, to: Vector2, is_walked: bool, is_available: bool) -> void:
	var direction: Vector2 = (to - from)
	var length: float = direction.length()
	if length < 1.0:
		return
	direction = direction.normalized()
	var dash_len: float = 12.0
	var gap_len: float = 7.0
	var traveled: float = 0.0

	var color: Color
	var width: float
	if is_walked:
		color = Color(0.8, 0.7, 0.3, 0.7)
		width = 4.0
	elif is_available:
		color = Color(0, 0.7, 0.9, 0.6)
		width = 3.0
	else:
		color = Color(0.3, 0.2, 0.4, 0.3)
		width = 2.0

	while traveled < length:
		var seg_start: Vector2 = from + direction * traveled
		var seg_end_dist: float = minf(traveled + dash_len, length)
		var seg_end: Vector2 = from + direction * seg_end_dist

		var dash := ColorRect.new()
		var seg_vec: Vector2 = seg_end - seg_start
		dash.position = Vector2(minf(seg_start.x, seg_end.x), minf(seg_start.y, seg_end.y))
		# 简化: 只画水平/垂直段；对于斜线用细ColorRect近似
		var seg_len: float = seg_vec.length()
		if abs(seg_vec.x) > abs(seg_vec.y):
			dash.size = Vector2(seg_len, width)
			dash.position.y = seg_start.y - width * 0.5
			dash.position.x = minf(seg_start.x, seg_end.x)
		else:
			dash.size = Vector2(width, seg_len)
			dash.position.x = seg_start.x - width * 0.5
			dash.position.y = minf(seg_start.y, seg_end.y)

		# 对角线情况：旋转ColorRect
		if abs(seg_vec.x) > 2.0 and abs(seg_vec.y) > 2.0:
			dash.size = Vector2(seg_len, width)
			dash.position = seg_start - Vector2(0, width * 0.5)
			dash.rotation = seg_vec.angle()
			dash.pivot_offset = Vector2(0, width * 0.5)

		dash.color = color
		dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map_canvas.add_child(dash)

		traveled += dash_len + gap_len

func _is_path_walked(from_floor: int, from_node: int, to_floor: int, to_node: int) -> bool:
	for i in range(GameState.map_visited_path.size() - 1):
		var step: Dictionary = GameState.map_visited_path[i]
		var next_step: Dictionary = GameState.map_visited_path[i + 1]
		if step.get("floor", -1) == from_floor and step.get("node", -1) == from_node:
			if next_step.get("floor", -1) == to_floor and next_step.get("node", -1) == to_node:
				return true
	return false

func _is_path_available(from_floor: int, from_node: int, _to_floor: int, _to_node: int) -> bool:
	if GameState.map_current_floor < 0:
		# 初始状态: 第0层所有节点可选 — 连线从虚拟起点到第0层
		return false
	return from_floor == GameState.map_current_floor and from_node == GameState.map_current_node

# ============================================================
# 绘制节点
# ============================================================

func _draw_nodes() -> void:
	node_buttons = []
	var next_floor: int = GameState.get_next_floor()
	var reachable: Array[int] = []
	if GameState.map_current_floor >= 0:
		reachable = GameState.get_reachable_next_nodes()

	for floor_idx in range(GameState.MAP_FLOORS):
		var floor_nodes: Array = GameState.map_graph[floor_idx]
		for ni in range(floor_nodes.size()):
			var node: Dictionary = floor_nodes[ni]
			var pos: Vector2 = _get_node_pos(floor_idx, node["col"])

			# 判断节点状态
			var is_completed: bool = node.get("completed", false)
			var is_current := (floor_idx == GameState.map_current_floor and ni == GameState.map_current_node)
			var is_reachable := false

			if GameState.map_current_floor < 0:
				# 初始状态: 第0层所有节点可选
				is_reachable = (floor_idx == 0)
			elif floor_idx == next_floor and ni in reachable:
				is_reachable = true

			# 节点视觉
			_create_node_visual(pos, node, floor_idx, ni, is_completed, is_current, is_reachable)

func _create_node_visual(pos: Vector2, node: Dictionary, floor_idx: int, node_idx: int,
		is_completed: bool, is_current: bool, is_reachable: bool) -> void:
	var ntype: String = node.get("type", "battle")
	var base_color: Color = TYPE_COLORS.get(ntype, Color(0.5, 0.5, 0.5))
	var icon_text: String = TYPE_ICONS.get(ntype, "?")

	# ── 外圈光晕 (reachable/current 才显示) ──
	var outer_glow: ColorRect = null
	if is_reachable or is_current:
		outer_glow = ColorRect.new()
		var glow_r: int = NODE_RADIUS + 8
		outer_glow.position = Vector2(pos.x - glow_r, pos.y - glow_r)
		outer_glow.size = Vector2(glow_r * 2, glow_r * 2)
		var glow_col: Color = base_color if is_reachable else Color(1, 0.85, 0.3)
		outer_glow.color = Color(glow_col.r, glow_col.g, glow_col.b, 0.15)
		outer_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map_canvas.add_child(outer_glow)

	# ── 节点按钮 (flat=false, 让 StyleBoxFlat 实际渲染) ──
	var btn := Button.new()
	btn.position = Vector2(pos.x - NODE_RADIUS, pos.y - NODE_RADIUS)
	btn.size = Vector2(NODE_RADIUS * 2, NODE_RADIUS * 2)
	btn.text = ""
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	# ── 节点背景 (圆形样式) ──
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(NODE_RADIUS)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0

	if is_completed:
		sb.bg_color = Color(base_color.r * 0.25, base_color.g * 0.25, base_color.b * 0.25, 0.6)
		sb.border_color = Color(0.3, 0.3, 0.35, 0.5)
		sb.set_border_width_all(2)
		btn.disabled = true
	elif is_current:
		sb.bg_color = Color(base_color.r * 0.55, base_color.g * 0.55, base_color.b * 0.55, 0.95)
		sb.border_color = Color(1, 0.9, 0.3, 1.0)
		sb.set_border_width_all(4)
		sb.shadow_color = Color(1, 0.8, 0.2, 0.5)
		sb.shadow_size = 10
		btn.disabled = true
	elif is_reachable:
		sb.bg_color = Color(base_color.r * 0.45, base_color.g * 0.45, base_color.b * 0.45, 0.9)
		sb.border_color = Color(base_color.r, base_color.g, base_color.b, 0.95)
		sb.set_border_width_all(3)
		sb.shadow_color = Color(base_color.r, base_color.g, base_color.b, 0.4)
		sb.shadow_size = 6
	else:
		sb.bg_color = Color(0.07, 0.05, 0.11, 0.55)
		sb.border_color = Color(0.2, 0.15, 0.25, 0.35)
		sb.set_border_width_all(1)
		btn.disabled = true

	# ── 所有状态的 stylebox ──
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("disabled", sb)

	# ── pressed 样式 (reachable 才有意义) ──
	var pressed_sb := sb.duplicate() as StyleBoxFlat
	if is_reachable:
		pressed_sb.bg_color = Color(base_color.r * 0.7, base_color.g * 0.7, base_color.b * 0.7, 1.0)
		pressed_sb.border_color = Color(1, 1, 1, 1.0)
		pressed_sb.shadow_size = 12
		pressed_sb.shadow_color = Color(base_color.r, base_color.g, base_color.b, 0.6)
	btn.add_theme_stylebox_override("pressed", pressed_sb)

	# ── hover 样式 — 强烈高亮反馈 ──
	if is_reachable:
		var hover_sb := sb.duplicate() as StyleBoxFlat
		hover_sb.bg_color = Color(base_color.r * 0.65, base_color.g * 0.65, base_color.b * 0.65, 1.0)
		hover_sb.border_color = Color(1, 1, 1, 0.95)
		hover_sb.set_border_width_all(4)
		hover_sb.shadow_size = 14
		hover_sb.shadow_color = Color(base_color.r, base_color.g, base_color.b, 0.6)
		btn.add_theme_stylebox_override("hover", hover_sb)
	else:
		btn.add_theme_stylebox_override("hover", sb)

	# ── Focus 样式 (去掉默认虚线框) ──
	var focus_sb := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("focus", focus_sb)

	var f_idx := floor_idx
	var n_idx := node_idx
	btn.pressed.connect(_on_map_node_pressed.bind(f_idx, n_idx))
	map_canvas.add_child(btn)

	# ── 图标文字 (在按钮上方叠加) ──
	var icon_lbl := Label.new()
	icon_lbl.text = icon_text
	icon_lbl.position = Vector2(pos.x - NODE_RADIUS, pos.y - NODE_RADIUS)
	icon_lbl.size = Vector2(NODE_RADIUS * 2, NODE_RADIUS * 2)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 24)
	var icon_alpha: float = 0.3 if (not is_reachable and not is_current and not is_completed) else 1.0
	if is_completed:
		icon_alpha = 0.45
	icon_lbl.add_theme_color_override("font_color", Color(1, 1, 1, icon_alpha))
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_canvas.add_child(icon_lbl)

	# ── 节点类型标签 (在节点下方) ──
	var type_lbl := Label.new()
	type_lbl.text = TYPE_NAMES.get(ntype, "")
	type_lbl.position = Vector2(pos.x - 40, pos.y + NODE_RADIUS + 4)
	type_lbl.size = Vector2(80, 20)
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_font_size_override("font_size", 13)
	type_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_reachable or is_current:
		type_lbl.add_theme_color_override("font_color", Color(base_color.r, base_color.g, base_color.b, 0.9))
	else:
		type_lbl.add_theme_color_override("font_color", Color(base_color.r * 0.5, base_color.g * 0.5, base_color.b * 0.5, 0.4))
	map_canvas.add_child(type_lbl)

	# ── Hover 交互反馈: 放大 + 图标亮度 + 外圈光晕增强 + 信息提示 ──
	if is_reachable:
		var orig_btn_pos := btn.position
		var orig_btn_size := btn.size
		var orig_icon_pos := icon_lbl.position
		var orig_icon_size := icon_lbl.size
		var orig_type_color := Color(base_color.r, base_color.g, base_color.b, 0.9)
		btn.mouse_entered.connect(func():
			if not is_instance_valid(btn):
				return
			# 放大按钮 (scale effect via position/size)
			btn.position = orig_btn_pos - Vector2(4, 4)
			btn.size = orig_btn_size + Vector2(8, 8)
			# 放大图标
			icon_lbl.position = orig_icon_pos - Vector2(4, 4)
			icon_lbl.size = orig_icon_size + Vector2(8, 8)
			icon_lbl.add_theme_font_size_override("font_size", 28)
			# 类型标签高亮
			type_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1.0))
			type_lbl.add_theme_font_size_override("font_size", 14)
			# 外圈光晕增强
			if outer_glow and is_instance_valid(outer_glow):
				outer_glow.color.a = 0.35
			# 更新信息文字
			if info_label and is_instance_valid(info_label):
				info_label.text = TYPE_NAMES.get(ntype, "") + " — 点击进入"
		)
		btn.mouse_exited.connect(func():
			if not is_instance_valid(btn):
				return
			# 恢复原始大小
			btn.position = orig_btn_pos
			btn.size = orig_btn_size
			icon_lbl.position = orig_icon_pos
			icon_lbl.size = orig_icon_size
			icon_lbl.add_theme_font_size_override("font_size", 24)
			# 恢复类型标签
			type_lbl.add_theme_color_override("font_color", orig_type_color)
			type_lbl.add_theme_font_size_override("font_size", 13)
			# 外圈光晕恢复
			if outer_glow and is_instance_valid(outer_glow):
				outer_glow.color.a = 0.15
			# 恢复信息文字
			if info_label and is_instance_valid(info_label):
				info_label.text = "选择下一个节点继续探索..."
		)

	# ── 呼吸动画 (可达节点) ──
	if is_reachable:
		var glow_tween: Tween = btn.create_tween().set_loops()
		glow_tween.tween_method(func(v: float):
			if is_instance_valid(btn):
				sb.shadow_size = int(6 + v * 8)
				sb.shadow_color.a = 0.4 + v * 0.4
		, 0.0, 1.0, 0.8)
		glow_tween.tween_method(func(v: float):
			if is_instance_valid(btn):
				sb.shadow_size = int(6 + v * 8)
				sb.shadow_color.a = 0.4 + v * 0.4
		, 1.0, 0.0, 0.8)

	node_buttons.append({"btn": btn, "floor": floor_idx, "node": node_idx, "pos": pos})

# ============================================================
# 层数标签 (左侧)
# ============================================================

func _build_legend_panel() -> void:
	# 层数标记在map_canvas左侧
	for floor_idx in range(GameState.MAP_FLOORS):
		if GameState.map_graph[floor_idx].is_empty():
			continue
		var first_node: Dictionary = GameState.map_graph[floor_idx][0]
		var y: float = _get_node_pos(floor_idx, first_node["col"]).y
		var floor_lbl := Label.new()
		floor_lbl.text = str(floor_idx + 1) + "F"
		floor_lbl.position = Vector2(4, y - 8)
		floor_lbl.size = Vector2(40, 18)
		floor_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		floor_lbl.add_theme_font_size_override("font_size", 12)
		floor_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5, 0.6))
		floor_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map_canvas.add_child(floor_lbl)

	# 右侧图例
	var legend := Panel.new()
	legend.position = Vector2(1155, 55)
	legend.size = Vector2(120, 310)
	var leg_sb := StyleBoxFlat.new()
	leg_sb.bg_color = Color(0.04, 0.03, 0.08, 0.85)
	leg_sb.border_color = Color(0.3, 0.15, 0.45, 0.5)
	leg_sb.set_border_width_all(1)
	leg_sb.set_corner_radius_all(3)
	legend.add_theme_stylebox_override("panel", leg_sb)
	add_child(legend)

	var leg_title := Label.new()
	leg_title.text = "图例"
	leg_title.position = Vector2(0, 6)
	leg_title.size = Vector2(120, 22)
	leg_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leg_title.add_theme_font_size_override("font_size", 14)
	leg_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	legend.add_child(leg_title)

	var legend_items: Array[Array] = [
		["⚔ 战斗", "battle"],
		["☠ 精英", "elite"],
		["🔥 休息", "rest"],
		["💰 商店", "shop"],
		["？ 事件", "event"],
		["✦ 宝箱", "treasure"],
		["💀 Boss", "boss"],
	]
	for i in range(legend_items.size()):
		var item: Array = legend_items[i]
		var item_lbl := Label.new()
		item_lbl.text = item[0]
		item_lbl.position = Vector2(10, 32 + i * 38)
		item_lbl.size = Vector2(100, 32)
		item_lbl.add_theme_font_size_override("font_size", 14)
		var col: Color = TYPE_COLORS.get(item[1], Color.WHITE)
		item_lbl.add_theme_color_override("font_color", col)
		legend.add_child(item_lbl)

# ============================================================
# 底部状态栏
# ============================================================

func _build_status_bar() -> void:
	var bar := Panel.new()
	bar.position = Vector2(40, 620)
	bar.size = Vector2(1200, 65)
	var bar_sb := StyleBoxFlat.new()
	bar_sb.bg_color = Color(0.04, 0.02, 0.1, 0.85)
	bar_sb.border_color = Color(0.4, 0.1, 0.6, 0.5)
	bar_sb.set_border_width_all(2)
	bar_sb.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("panel", bar_sb)
	add_child(bar)

	# 顶部橙色线
	var accent := ColorRect.new()
	accent.position = Vector2(2, 0)
	accent.size = Vector2(1196, 2)
	accent.color = Color(0.9, 0.5, 0.1, 0.5)
	bar.add_child(accent)

	# HP
	var hp_lbl := Label.new()
	hp_lbl.text = "❤ " + str(GameState.player_hp) + "/" + str(GameState.player_max_hp)
	hp_lbl.position = Vector2(24, 14)
	hp_lbl.add_theme_font_size_override("font_size", 20)
	hp_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	bar.add_child(hp_lbl)

	# Gold
	var gold_lbl := Label.new()
	gold_lbl.text = "◆ " + str(GameState.player_gold)
	gold_lbl.position = Vector2(220, 14)
	gold_lbl.add_theme_font_size_override("font_size", 20)
	gold_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	bar.add_child(gold_lbl)

	# Deck
	var deck_lbl := Label.new()
	deck_lbl.text = "◈ " + str(GameState.player_deck.size()) + "张"
	deck_lbl.position = Vector2(400, 14)
	deck_lbl.add_theme_font_size_override("font_size", 20)
	deck_lbl.add_theme_color_override("font_color", Color(0.5, 0.7, 1))
	bar.add_child(deck_lbl)

	# Floor
	var floor_lbl := Label.new()
	var f_num: int = GameState.map_current_floor + 1 if GameState.map_current_floor >= 0 else 0
	floor_lbl.text = "层: " + str(f_num) + "/" + str(GameState.MAP_FLOORS)
	floor_lbl.position = Vector2(560, 14)
	floor_lbl.add_theme_font_size_override("font_size", 20)
	floor_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	bar.add_child(floor_lbl)

	# Run
	var run_lbl := Label.new()
	run_lbl.text = "第" + str(GameState.run_number) + "轮"
	run_lbl.position = Vector2(720, 14)
	run_lbl.add_theme_font_size_override("font_size", 20)
	run_lbl.add_theme_color_override("font_color", Color(0.6, 0.5, 0.7))
	bar.add_child(run_lbl)

	# 查看牌组按钮
	var deck_btn: Button = UIFactory.make_cyan_button("查看牌组", 180, 40)
	deck_btn.position = Vector2(980, 10)
	deck_btn.pressed.connect(_on_deck_pressed)
	bar.add_child(deck_btn)

# ============================================================
# 玩家标记
# ============================================================

func _draw_player_marker() -> void:
	if GameState.map_current_floor < 0:
		# 未进入地图: 在底部中央显示
		var _ai_p := AssetLoader.get_character_sprite("player", 0)
		var player_tex: ImageTexture = _ai_p if _ai_p else PixelArtGenerator.generate_character_sprite("player", 0)
		player_marker = TextureRect.new()
		player_marker.texture = player_tex
		player_marker.position = Vector2(480, MAP_TOTAL_HEIGHT - 50)
		player_marker.size = Vector2(40, 52)
		player_marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		player_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map_canvas.add_child(player_marker)
	else:
		# 在当前节点位置显示
		var cur_floor: Array = GameState.map_graph[GameState.map_current_floor]
		if GameState.map_current_node >= 0 and GameState.map_current_node < cur_floor.size():
			var node: Dictionary = cur_floor[GameState.map_current_node]
			var pos: Vector2 = _get_node_pos(GameState.map_current_floor, node["col"])
			var _ai_p := AssetLoader.get_character_sprite("player", 0)
			var player_tex: ImageTexture = _ai_p if _ai_p else PixelArtGenerator.generate_character_sprite("player", 0)
			player_marker = TextureRect.new()
			player_marker.texture = player_tex
			player_marker.position = Vector2(pos.x - 20, pos.y - 62)
			player_marker.size = Vector2(40, 52)
			player_marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			player_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
			map_canvas.add_child(player_marker)

	# Bob animation
	if player_marker:
		var bob: Tween = player_marker.create_tween().set_loops()
		bob.tween_property(player_marker, "position:y", player_marker.position.y - 4, 0.8).set_trans(Tween.TRANS_SINE)
		bob.tween_property(player_marker, "position:y", player_marker.position.y + 4, 0.8).set_trans(Tween.TRANS_SINE)

# ============================================================
# 滚动
# ============================================================

func _scroll_to_player() -> void:
	var target_y: float
	if GameState.map_current_floor < 0:
		target_y = MAP_TOTAL_HEIGHT - MAP_BOTTOM_MARGIN
	else:
		var cur_floor: Array = GameState.map_graph[GameState.map_current_floor]
		if GameState.map_current_node >= 0 and GameState.map_current_node < cur_floor.size():
			var node: Dictionary = cur_floor[GameState.map_current_node]
			target_y = _get_node_pos(GameState.map_current_floor, node["col"]).y
		else:
			target_y = MAP_TOTAL_HEIGHT - MAP_BOTTOM_MARGIN

	# 让目标y大约在视口中央 (clip区域高560)
	target_scroll = target_y - 280.0
	# 限制范围
	var max_scroll: float = MAP_TOTAL_HEIGHT - 560.0
	target_scroll = clampf(target_scroll, 0, max_scroll)
	scroll_offset = target_scroll
	_apply_scroll()

func _apply_scroll() -> void:
	if map_canvas:
		map_canvas.position.y = -scroll_offset

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_scroll = maxf(target_scroll - 60, 0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var max_scroll: float = maxf(MAP_TOTAL_HEIGHT - 560.0, 0)
			target_scroll = minf(target_scroll + 60, max_scroll)

func _process(delta: float) -> void:
	# 平滑滚动
	if abs(scroll_offset - target_scroll) > 1.0:
		scroll_offset = lerpf(scroll_offset, target_scroll, delta * 8.0)
		_apply_scroll()

# ============================================================
# 交互
# ============================================================

func _on_map_node_pressed(floor_idx: int, node_idx: int) -> void:
	var next_floor: int = GameState.get_next_floor()
	if floor_idx != next_floor:
		return

	# 检查是否可达
	if GameState.map_current_floor < 0:
		# 初始状态: 第0层所有节点可达
		if floor_idx != 0:
			return
	else:
		var reachable: Array[int] = GameState.get_reachable_next_nodes()
		if node_idx not in reachable:
			return

	# 选择节点
	GameState.select_map_node(floor_idx, node_idx)
	GameState.save_game()

	# 根据节点类型跳转
	var node: Dictionary = GameState.map_graph[floor_idx][node_idx]
	var ntype: String = node.get("type", "battle")

	match ntype:
		"battle", "elite":
			Global.change_scene(Global.SCENE_BATTLE)
		"boss":
			Global.change_scene(Global.SCENE_BATTLE)
		"rest":
			_handle_rest_node()
		"shop":
			Global.change_scene(Global.SCENE_EVENT)
		"event":
			Global.change_scene(Global.SCENE_EVENT)
		"treasure":
			_handle_treasure_node()
		_:
			Global.change_scene(Global.SCENE_BATTLE)

func _handle_rest_node() -> void:
	# 休息: 回复25%最大生命
	var heal_amount: int = maxi(1, GameState.player_max_hp / 4)
	GameState.player_hp = mini(GameState.player_hp + heal_amount, GameState.player_max_hp)
	GameState.advance_node()
	GameState.save_game()
	# 简单提示后返回地图
	if info_label:
		info_label.text = "休息回复了 " + str(heal_amount) + " 点生命！"
	await get_tree().create_timer(1.2).timeout
	# 刷新地图
	Global.is_transitioning = false
	get_tree().change_scene_to_file(Global.SCENE_MAP)

func _handle_treasure_node() -> void:
	# 宝箱: 获得随机金币
	var gold_amount: int = randi_range(20, 50)
	GameState.player_gold += gold_amount
	GameState.advance_node()
	GameState.save_game()
	if info_label:
		info_label.text = "开启宝箱获得 " + str(gold_amount) + " 金币！"
	await get_tree().create_timer(1.2).timeout
	Global.is_transitioning = false
	get_tree().change_scene_to_file(Global.SCENE_MAP)

func _on_deck_pressed() -> void:
	Global.change_scene(Global.SCENE_DECK_BUILDER)

# ============================================================
# 背景装饰
# ============================================================

func _create_circuit_bg() -> void:
	for i in range(10):
		var h_line := ColorRect.new()
		h_line.position = Vector2(0, 60 + i * 72)
		h_line.size = Vector2(VIEWPORT_W, 1)
		h_line.color = Color(0.06, 0.03, 0.12, 0.12)
		h_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(h_line)
	for i in range(14):
		var v_line := ColorRect.new()
		v_line.position = Vector2(50 + i * 95, 0)
		v_line.size = Vector2(1, VIEWPORT_H)
		v_line.color = Color(0.05, 0.025, 0.1, 0.1)
		v_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(v_line)
