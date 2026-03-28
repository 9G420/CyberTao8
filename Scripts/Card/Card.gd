# ============================================================
# Card.gd - 卡牌UI节点（可拖拽的卡牌实体）
# 继承Control，支持鼠标悬停、拖拽释放
# Designed for 1280x720 native resolution
# ============================================================
class_name Card
extends Control

## 信号
signal card_clicked(card: Card)
signal card_drag_started(card: Card)
signal card_drag_ended(card: Card)
signal card_hovered(card: Card)
signal card_unhovered(card: Card)

## 卡牌数据
var card_data: CardData = null

## 状态
var is_dragging: bool = false
var is_hovered: bool = false
var is_playable: bool = true
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
var original_z_index: int = 0
var hand_index: int = 0

## 内部UI节点引用
var _bg_rect: ColorRect
var _name_label: Label
var _cost_label: Label
var _desc_label: Label
var _type_label: Label
var _yinyang_label: Label
var _stats_label: Label
var _art_rect: ColorRect  # 占位卡面艺术
var _highlight: ColorRect

## Enhanced visual nodes
var _card_frame: ColorRect
var _inner_panel: ColorRect
var _art_texture_rect: TextureRect
var _preview_panel: PanelContainer = null
var _hover_tooltip: PanelContainer = null
var _glow_tween: Tween = null
var _frame_pulse_tween: Tween = null
var _drag_target_pos: Vector2 = Vector2.ZERO

## 卡牌尺寸常量
const CARD_WIDTH: int = 160
const CARD_HEIGHT: int = 220
const HOVER_SCALE: float = 1.35
const HOVER_Y_OFFSET: float = -60.0

## EVA color constants
const EVA_ORANGE := Color(1.0, 0.5, 0.0)
const EVA_PURPLE := Color(0.5, 0.1, 0.8)
const EVA_DARK_BG := Color(0.06, 0.04, 0.1, 0.95)

## Card type frame colors (STS-style)
const TYPE_COLOR_ATTACK: Color = Color(0.85, 0.15, 0.1)
const TYPE_COLOR_DEFENSE: Color = Color(0.15, 0.4, 0.85)
const TYPE_COLOR_SPELL: Color = Color(0.6, 0.2, 0.85)
const TYPE_COLOR_POWER: Color = Color(0.85, 0.7, 0.15)
const TYPE_COLOR_SUMMON: Color = Color(0.15, 0.75, 0.35)

## Shadow node for hover effect
var _hover_shadow: ColorRect = null
## Stored cost_bg reference for shader coloring
var _cost_bg: ColorRect = null

func _ready() -> void:
	custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	pivot_offset = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_card_ui()
	if card_data:
		_update_display()

## 平滑拖拽跟随
func _process(delta: float) -> void:
	if is_dragging and _drag_target_pos != Vector2.ZERO:
		global_position = global_position.lerp(_drag_target_pos, minf(delta * 22.0, 1.0))

## 构建卡牌UI布局（精致卡牌风格）
func _build_card_ui() -> void:
	# 高亮边框（悬停时显示）
	_highlight = ColorRect.new()
	_highlight.size = Vector2(CARD_WIDTH + 8, CARD_HEIGHT + 8)
	_highlight.position = Vector2(-4, -4)
	_highlight.color = Color(1, 0.8, 0, 0.0)
	_highlight.visible = false
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 悬停高亮shader（柔和外发光）
	var hl_shader := Shader.new()
	hl_shader.code = "
shader_type canvas_item;
uniform vec4 glow_color : source_color = vec4(1.0, 0.85, 0.2, 1.0);
void fragment() {
	vec2 uv = UV;
	float dx = min(uv.x, 1.0 - uv.x);
	float dy = min(uv.y, 1.0 - uv.y);
	float edge = min(dx, dy);
	float glow = 1.0 - smoothstep(0.0, 0.22, edge);
	float pulse = 0.75 + 0.25 * sin(TIME * 2.5);
	COLOR = vec4(glow_color.rgb, glow * pulse * 0.65);
}
"
	var hl_mat := ShaderMaterial.new()
	hl_mat.shader = hl_shader
	_highlight.material = hl_mat
	add_child(_highlight)

	# Outer metallic frame (rounded border effect)
	_card_frame = ColorRect.new()
	_card_frame.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	_card_frame.color = EVA_ORANGE
	_card_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card_frame)

	# Inner panel (inset by 2px)
	_inner_panel = ColorRect.new()
	_inner_panel.size = Vector2(CARD_WIDTH - 4, CARD_HEIGHT - 4)
	_inner_panel.position = Vector2(2, 2)
	_inner_panel.color = Color(0.06, 0.04, 0.12, 0.97)
	_inner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_inner_panel)

	# 背景
	_bg_rect = ColorRect.new()
	_bg_rect.size = Vector2(CARD_WIDTH - 8, CARD_HEIGHT - 8)
	_bg_rect.position = Vector2(4, 4)
	_bg_rect.color = Color(0.09, 0.06, 0.14, 0.95)
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_rect)

	# 卡面艺术区域
	_art_rect = ColorRect.new()
	_art_rect.size = Vector2(CARD_WIDTH - 14, 88)
	_art_rect.position = Vector2(7, 28)
	_art_rect.color = Color(0.18, 0.12, 0.28)
	_art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art_rect)

	_art_texture_rect = TextureRect.new()
	_art_texture_rect.size = Vector2(CARD_WIDTH - 14, 88)
	_art_texture_rect.position = Vector2(7, 28)
	_art_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art_texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_art_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art_texture_rect)

	# 费用标签（左上角，能量球效果）
	_cost_bg = ColorRect.new()
	_cost_bg.size = Vector2(26, 26)
	_cost_bg.position = Vector2(5, 3)
	_cost_bg.color = Color.WHITE
	_cost_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var orb_shader := Shader.new()
	orb_shader.code = "
shader_type canvas_item;
uniform vec4 orb_color : source_color = vec4(0.0, 0.6, 1.0, 1.0);
void fragment() {
	float dist = distance(UV, vec2(0.5));
	float circle = 1.0 - smoothstep(0.3, 0.5, dist);
	float glow = 1.0 - smoothstep(0.0, 0.5, dist);
	vec3 col = orb_color.rgb * (0.6 + 0.4 * glow);
	COLOR = vec4(col, circle * 0.95);
}
"
	var orb_mat := ShaderMaterial.new()
	orb_mat.shader = orb_shader
	_cost_bg.material = orb_mat
	add_child(_cost_bg)

	_cost_label = Label.new()
	_cost_label.position = Vector2(5, 1)
	_cost_label.size = Vector2(26, 26)
	_cost_label.add_theme_font_size_override("font_size", 20)
	_cost_label.add_theme_color_override("font_color", Color(0, 0.9, 1))
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cost_label)

	# 阴阳标签（右上角）
	_yinyang_label = Label.new()
	_yinyang_label.position = Vector2(CARD_WIDTH - 32, 3)
	_yinyang_label.add_theme_font_size_override("font_size", 16)
	_yinyang_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_yinyang_label)

	# 分割线
	var sep_line := ColorRect.new()
	sep_line.size = Vector2(CARD_WIDTH - 16, 1)
	sep_line.position = Vector2(8, 117)
	sep_line.color = Color(1.0, 0.5, 0.0, 0.35)
	sep_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep_line)

	# 卡名
	_name_label = Label.new()
	_name_label.position = Vector2(6, 118)
	_name_label.size = Vector2(CARD_WIDTH - 12, 22)
	_name_label.add_theme_font_size_override("font_size", 16)
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.clip_text = true
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)

	# 类型标签
	_type_label = Label.new()
	_type_label.position = Vector2(6, 139)
	_type_label.size = Vector2(CARD_WIDTH - 12, 16)
	_type_label.add_theme_font_size_override("font_size", 11)
	_type_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_type_label)

	# 描述
	_desc_label = Label.new()
	_desc_label.position = Vector2(8, 156)
	_desc_label.size = Vector2(CARD_WIDTH - 16, 36)
	_desc_label.add_theme_font_size_override("font_size", 11)
	_desc_label.add_theme_color_override("font_color", Color(0.78, 0.78, 0.85))
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.clip_text = true
	_desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_desc_label)

	# 攻/防数值
	_stats_label = Label.new()
	_stats_label.position = Vector2(6, CARD_HEIGHT - 26)
	_stats_label.size = Vector2(CARD_WIDTH - 12, 22)
	_stats_label.add_theme_font_size_override("font_size", 18)
	_stats_label.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stats_label)

	# 底部分割线
	var bottom_sep := ColorRect.new()
	bottom_sep.size = Vector2(CARD_WIDTH - 16, 1)
	bottom_sep.position = Vector2(8, CARD_HEIGHT - 29)
	bottom_sep.color = Color(1.0, 0.5, 0.0, 0.25)
	bottom_sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom_sep)

	# Start the EVA frame color pulse
	_start_frame_pulse()

## Get the frame color for the current card type
func _get_type_frame_color() -> Color:
	if not card_data:
		return EVA_ORANGE
	match card_data.card_type:
		CardData.CardType.ATTACK:
			return TYPE_COLOR_ATTACK
		CardData.CardType.DEFENSE:
			return TYPE_COLOR_DEFENSE
		CardData.CardType.SPELL:
			return TYPE_COLOR_SPELL
		CardData.CardType.POWER:
			return TYPE_COLOR_POWER
		CardData.CardType.SUMMON:
			return TYPE_COLOR_SUMMON
	return EVA_ORANGE

## Start pulsing the card frame border between type color and a lighter variant
func _start_frame_pulse() -> void:
	if _frame_pulse_tween and _frame_pulse_tween.is_valid():
		_frame_pulse_tween.kill()
	var base_color: Color = _get_type_frame_color()
	var light_color: Color = base_color.lightened(0.35)
	_card_frame.color = base_color
	_frame_pulse_tween = create_tween().set_loops()
	_frame_pulse_tween.tween_property(_card_frame, "color", light_color, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_frame_pulse_tween.tween_property(_card_frame, "color", base_color, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

## 设置卡牌数据并刷新显示
func setup(data: CardData) -> void:
	card_data = data
	if is_inside_tree():
		_update_display()

## 刷新卡牌显示
func _update_display() -> void:
	if not card_data:
		return

	_cost_label.text = str(card_data.cost)
	_name_label.text = card_data.card_name
	_type_label.text = card_data.get_type_text()
	_desc_label.text = card_data.description
	_yinyang_label.text = card_data.get_yinyang_text()

	# Set frame color based on card type (STS-style)
	_card_frame.color = _get_type_frame_color()
	_start_frame_pulse()

	# 阴阳颜色
	match card_data.yinyang:
		CardData.YinYang.YIN:
			_yinyang_label.add_theme_color_override("font_color", Color(0.5, 0.3, 1.0))
			_art_rect.color = Color(
				card_data.card_color.r * 0.15 + 0.05,
				card_data.card_color.g * 0.1 + 0.05,
				card_data.card_color.b * 0.15 + 0.15)
		CardData.YinYang.YANG:
			_yinyang_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
			_art_rect.color = Color(
				card_data.card_color.r * 0.2 + 0.15,
				card_data.card_color.g * 0.15 + 0.1,
				card_data.card_color.b * 0.08 + 0.05)
		_:
			_yinyang_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			_art_rect.color = Color(
				card_data.card_color.r * 0.12 + 0.08,
				card_data.card_color.g * 0.12 + 0.08,
				card_data.card_color.b * 0.12 + 0.08)

	# 数值显示
	match card_data.card_type:
		CardData.CardType.ATTACK:
			if card_data.multi_hit > 0:
				_stats_label.text = "⚔ " + str(card_data.attack_power) + " x" + str(card_data.multi_hit)
			else:
				_stats_label.text = "⚔ " + str(card_data.attack_power)
			_stats_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		CardData.CardType.DEFENSE:
			_stats_label.text = "🛡 " + str(card_data.defense_power)
			_stats_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1))
		CardData.CardType.SUMMON:
			_stats_label.text = "⚔" + str(card_data.attack_power) + " ♥" + str(card_data.summon_hp)
			_stats_label.add_theme_color_override("font_color", Color(0.3, 1, 0.5))
		CardData.CardType.SPELL:
			_stats_label.text = "✦ 术法"
			_stats_label.add_theme_color_override("font_color", Color(0.8, 0.5, 1))
		CardData.CardType.POWER:
			_stats_label.text = "✦ 能力"
			_stats_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))

	# 关键词标签显示（消耗/固有/保留/弃牌触发）
	var kw_text := card_data.get_keywords_text()
	if kw_text != "":
		_type_label.text = card_data.get_type_text() + " | " + kw_text
		_type_label.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
	else:
		_type_label.text = card_data.get_type_text()

	# 卡牌边框颜色（稀有度）
	_highlight.color = card_data.get_rarity_color()
	_highlight.color.a = 0.6

	# Generate card art: AI asset first (by card_id), fallback to procedural
	var art_seed: int = card_data.card_name.hash()
	var _ai_card_art := AssetLoader.get_card_art(card_data.card_type as int, card_data.yinyang as int, card_data.rarity, art_seed, card_data.card_id)
	var art_tex: ImageTexture = _ai_card_art if _ai_card_art else PixelArtGenerator.generate_card_art(
		card_data.card_type as int,
		card_data.yinyang as int,
		card_data.rarity,
		art_seed
	)
	if art_tex:
		_art_texture_rect.texture = art_tex

	# 可用性视觉 + glow
	if not is_playable:
		modulate = Color(0.4, 0.4, 0.5, 0.7)
		_stop_playable_glow()
	else:
		modulate = Color.WHITE
		_start_playable_glow()

## Start subtle glow pulse on highlight when card is playable
func _start_playable_glow() -> void:
	if _glow_tween and _glow_tween.is_valid():
		return  # already running
	_highlight.visible = false  # glow uses modulate on frame instead
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property(_card_frame, "modulate:a", 0.6, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_glow_tween.tween_property(_card_frame, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

## Stop the playable glow effect
func _stop_playable_glow() -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
		_glow_tween = null
	_card_frame.modulate.a = 0.5

## 设置是否可打出
func set_playable(playable: bool) -> void:
	is_playable = playable
	if is_inside_tree():
		_update_display()

## 输入处理
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and is_playable:
				# 开始拖拽
				is_dragging = true
				drag_offset = mb.position
				original_position = position
				original_z_index = z_index
				z_index = 50
				_drag_target_pos = global_position
				_hide_hover_tooltip()
				# 拖拽开始动效：轻微缩放
				var drag_tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
				drag_tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.1)
				card_drag_started.emit(self)
			elif not mb.pressed and is_dragging:
				# 结束拖拽
				is_dragging = false
				z_index = original_z_index
				_drag_target_pos = Vector2.ZERO
				# 恢复缩放
				var end_tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
				end_tween.tween_property(self, "scale", Vector2.ONE, 0.12)
				card_drag_ended.emit(self)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if is_dragging:
				# 右键取消拖拽
				is_dragging = false
				z_index = original_z_index
				_drag_target_pos = Vector2.ZERO
				var cancel_tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
				cancel_tween.tween_property(self, "scale", Vector2.ONE, 0.12)
				card_drag_ended.emit(self)
			else:
				card_clicked.emit(self)

	elif event is InputEventMouseMotion:
		if is_dragging:
			# 跟随鼠标（平滑跟随）
			_drag_target_pos = (event as InputEventMouseMotion).global_position - drag_offset

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		_on_mouse_entered()
	elif what == NOTIFICATION_MOUSE_EXIT:
		_on_mouse_exited()

func _on_mouse_entered() -> void:
	if is_dragging:
		return
	is_hovered = true
	_highlight.visible = true
	# Add drop shadow behind card
	_show_hover_shadow()
	# 悬停放大效果（snappier 0.12s）
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), 0.12)
	tween.parallel().tween_property(self, "position:y", position.y + HOVER_Y_OFFSET, 0.12)
	card_hovered.emit(self)
	# Play hover sound
	AudioManager.play_sfx_generated("card_hover", -12.0)
	# 显示简洁的悬浮提示（卡牌描述）
	_show_hover_tooltip()

func _on_mouse_exited() -> void:
	if is_dragging:
		return
	is_hovered = false
	_highlight.visible = false
	# Remove drop shadow
	_hide_hover_shadow()
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)
	tween.parallel().tween_property(self, "position:y", original_position.y, 0.12)
	card_unhovered.emit(self)
	# 移除悬浮提示
	_hide_hover_tooltip()

## Show a dark shadow ColorRect behind the card when hovered
func _show_hover_shadow() -> void:
	_hide_hover_shadow()
	_hover_shadow = ColorRect.new()
	_hover_shadow.size = Vector2(CARD_WIDTH + 12, CARD_HEIGHT + 12)
	_hover_shadow.position = Vector2(-6, 4)
	_hover_shadow.color = Color(0.0, 0.0, 0.0, 0.45)
	_hover_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover_shadow.z_index = -1
	add_child(_hover_shadow)
	move_child(_hover_shadow, 0)

## Hide the hover shadow
func _hide_hover_shadow() -> void:
	if _hover_shadow and is_instance_valid(_hover_shadow):
		_hover_shadow.queue_free()
		_hover_shadow = null

## 显示简洁悬浮提示（仅显示卡牌描述，紧凑小气泡）
func _show_hover_tooltip() -> void:
	if not card_data:
		return
	_hide_hover_tooltip()

	_hover_tooltip = PanelContainer.new()
	_hover_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.14, 0.92)
	style.border_color = Color(1.0, 0.6, 0.15, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	_hover_tooltip.add_theme_stylebox_override("panel", style)

	var desc_lbl := Label.new()
	desc_lbl.text = card_data.description
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.9, 0.88, 0.95))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.custom_minimum_size = Vector2(180, 0)
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover_tooltip.add_child(desc_lbl)

	# 使用CanvasLayer使tooltip不受卡牌缩放影响
	var canvas_layer: CanvasLayer = CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.name = "CardTooltipLayer"
	add_child(canvas_layer)
	canvas_layer.add_child(_hover_tooltip)

	# 定位：卡牌正上方偏小
	var card_global_center: Vector2 = global_position + (size * scale) / 2.0
	var tip_x: float = card_global_center.x - 90.0
	var tip_y: float = global_position.y - 55.0
	var screen_size: Vector2 = get_viewport_rect().size
	tip_x = clampf(tip_x, 4.0, screen_size.x - 194.0)
	tip_y = clampf(tip_y, 4.0, screen_size.y - 60.0)
	_hover_tooltip.position = Vector2(tip_x, tip_y)

## 隐藏悬浮提示
func _hide_hover_tooltip() -> void:
	if _hover_tooltip and is_instance_valid(_hover_tooltip):
		var layer := _hover_tooltip.get_parent()
		if layer and layer is CanvasLayer:
			layer.queue_free()
		else:
			_hover_tooltip.queue_free()
		_hover_tooltip = null

## 播放打出动画（STS风格：飞向目标+旋转+缩放+闪光）
func play_cast_animation(target_pos: Vector2) -> void:
	# 先短暂放大（蓄力感）
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.06).set_ease(Tween.EASE_OUT)
	# 然后飞向目标+旋转+缩小+淡出
	tween.tween_property(self, "global_position", target_pos, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(self, "scale", Vector2(0.3, 0.3), 0.25).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "rotation_degrees", randf_range(-15.0, 15.0), 0.25)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2).set_delay(0.05)
	await tween.finished

## 播放抽牌动画（从牌库飞入手牌位置）
func play_draw_animation(from_pos: Vector2, to_pos: Vector2) -> void:
	global_position = from_pos
	scale = Vector2(0.3, 0.3)
	modulate.a = 0.0
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "global_position", to_pos, 0.4)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.4)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.3)
	await tween.finished
