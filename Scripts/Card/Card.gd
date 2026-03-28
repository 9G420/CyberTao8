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
var _glow_tween: Tween = null
var _frame_pulse_tween: Tween = null

## 卡牌尺寸常量
const CARD_WIDTH: int = 160
const CARD_HEIGHT: int = 220
const HOVER_SCALE: float = 1.25
const HOVER_Y_OFFSET: float = -40.0

## EVA color constants
const EVA_ORANGE := Color(1.0, 0.5, 0.0)
const EVA_PURPLE := Color(0.5, 0.1, 0.8)
const EVA_DARK_BG := Color(0.06, 0.04, 0.1, 0.95)

func _ready() -> void:
	custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	pivot_offset = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_card_ui()
	if card_data:
		_update_display()

## 构建卡牌UI布局
func _build_card_ui() -> void:
	# 高亮边框（悬停时显示）
	_highlight = ColorRect.new()
	_highlight.size = Vector2(CARD_WIDTH + 12, CARD_HEIGHT + 12)
	_highlight.position = Vector2(-6, -6)
	_highlight.color = Color(1, 0.8, 0, 0.6)
	_highlight.visible = false
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_highlight)

	# Outer metallic EVA frame (2px border effect)
	_card_frame = ColorRect.new()
	_card_frame.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	_card_frame.color = EVA_ORANGE
	_card_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card_frame)

	# Inner gradient panel (inset by 2px for border effect)
	_inner_panel = ColorRect.new()
	_inner_panel.size = Vector2(CARD_WIDTH - 4, CARD_HEIGHT - 4)
	_inner_panel.position = Vector2(2, 2)
	_inner_panel.color = Color(0.08, 0.05, 0.14, 0.97)
	_inner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_inner_panel)

	# 背景 (sits inside the inner panel for layered look)
	_bg_rect = ColorRect.new()
	_bg_rect.size = Vector2(CARD_WIDTH - 8, CARD_HEIGHT - 8)
	_bg_rect.position = Vector2(4, 4)
	_bg_rect.color = Color(0.1, 0.08, 0.15, 0.95)
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_rect)

	# 卡面艺术区域 - TextureRect for procedural art, with ColorRect fallback behind it
	_art_rect = ColorRect.new()
	_art_rect.size = Vector2(CARD_WIDTH - 12, 90)
	_art_rect.position = Vector2(6, 30)
	_art_rect.color = Color(0.2, 0.15, 0.3)
	_art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art_rect)

	_art_texture_rect = TextureRect.new()
	_art_texture_rect.size = Vector2(CARD_WIDTH - 12, 90)
	_art_texture_rect.position = Vector2(6, 30)
	_art_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art_texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_art_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art_texture_rect)

	# 费用标签（左上角）
	_cost_label = Label.new()
	_cost_label.position = Vector2(6, 2)
	_cost_label.add_theme_font_size_override("font_size", 22)
	_cost_label.add_theme_color_override("font_color", Color(0, 0.9, 1))
	_cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cost_label)

	# 阴阳标签（右上角）
	_yinyang_label = Label.new()
	_yinyang_label.position = Vector2(CARD_WIDTH - 36, 2)
	_yinyang_label.add_theme_font_size_override("font_size", 18)
	_yinyang_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_yinyang_label)

	# 卡名
	_name_label = Label.new()
	_name_label.position = Vector2(6, 115)
	_name_label.size = Vector2(CARD_WIDTH - 12, 24)
	_name_label.add_theme_font_size_override("font_size", 18)
	_name_label.add_theme_color_override("font_color", Color.WHITE)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.clip_text = true
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)

	# 类型标签
	_type_label = Label.new()
	_type_label.position = Vector2(6, 140)
	_type_label.size = Vector2(CARD_WIDTH - 12, 18)
	_type_label.add_theme_font_size_override("font_size", 14)
	_type_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_type_label)

	# 描述
	_desc_label = Label.new()
	_desc_label.position = Vector2(6, 158)
	_desc_label.size = Vector2(CARD_WIDTH - 12, 35)
	_desc_label.add_theme_font_size_override("font_size", 13)
	_desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.clip_text = true
	_desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_desc_label)

	# 攻/防数值
	_stats_label = Label.new()
	_stats_label.position = Vector2(6, CARD_HEIGHT - 28)
	_stats_label.size = Vector2(CARD_WIDTH - 12, 24)
	_stats_label.add_theme_font_size_override("font_size", 20)
	_stats_label.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stats_label)

	# Start the EVA frame color pulse
	_start_frame_pulse()

## Start pulsing the card frame border between EVA orange and purple
func _start_frame_pulse() -> void:
	_frame_pulse_tween = create_tween().set_loops()
	_frame_pulse_tween.tween_property(_card_frame, "color", EVA_PURPLE, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_frame_pulse_tween.tween_property(_card_frame, "color", EVA_ORANGE, 1.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

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

	# 阴阳颜色
	match card_data.yinyang:
		CardData.YinYang.YIN:
			_yinyang_label.add_theme_color_override("font_color", Color(0.5, 0.3, 1.0))
			_art_rect.color = Color(0.15, 0.1, 0.35)
		CardData.YinYang.YANG:
			_yinyang_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
			_art_rect.color = Color(0.35, 0.25, 0.1)
		_:
			_yinyang_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

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
		modulate = Color(0.5, 0.5, 0.5, 0.8)
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
				card_drag_started.emit(self)
			elif not mb.pressed and is_dragging:
				# 结束拖拽
				is_dragging = false
				z_index = original_z_index
				card_drag_ended.emit(self)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			card_clicked.emit(self)

	elif event is InputEventMouseMotion:
		if is_dragging:
			# 跟随鼠标
			global_position = (event as InputEventMouseMotion).global_position - drag_offset

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
	# 悬停放大效果
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(HOVER_SCALE, HOVER_SCALE), 0.15)
	tween.parallel().tween_property(self, "position:y", position.y + HOVER_Y_OFFSET, 0.15)
	card_hovered.emit(self)
	# Play hover sound
	AudioManager.play_sfx_generated("card_hover", -12.0)
	# Show preview panel
	_create_preview_panel()

func _on_mouse_exited() -> void:
	if is_dragging:
		return
	is_hovered = false
	_highlight.visible = false
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)
	tween.parallel().tween_property(self, "position:y", original_position.y, 0.15)
	card_unhovered.emit(self)
	# Remove preview panel and its CanvasLayer parent
	if _preview_panel and is_instance_valid(_preview_panel):
		var layer := _preview_panel.get_parent()
		if layer and layer is CanvasLayer:
			layer.queue_free()
		else:
			_preview_panel.queue_free()
		_preview_panel = null

## Create and show a large hover preview popup above the card
func _create_preview_panel() -> void:
	if not card_data:
		return
	if _preview_panel and is_instance_valid(_preview_panel):
		_preview_panel.queue_free()
		_preview_panel = null

	_preview_panel = PanelContainer.new()
	_preview_panel.custom_minimum_size = Vector2(400, 300)
	_preview_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Style: semi-transparent dark purple EVA background
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.05, 0.2, 0.92)
	style.border_color = EVA_ORANGE
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	_preview_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview_panel.add_child(vbox)

	# Card name (large)
	var name_lbl := Label.new()
	name_lbl.text = card_data.card_name
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	# Large card art (128x128)
	var art_container := CenterContainer.new()
	art_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(art_container)
	var art_preview := TextureRect.new()
	art_preview.custom_minimum_size = Vector2(128, 128)
	art_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	art_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _art_texture_rect and _art_texture_rect.texture:
		art_preview.texture = _art_texture_rect.texture
	art_container.add_child(art_preview)

	# Full description (no clipping)
	var desc_lbl := Label.new()
	desc_lbl.text = card_data.description
	desc_lbl.add_theme_font_size_override("font_size", 15)
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.custom_minimum_size.x = 370
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc_lbl)

	# Stats display
	var stats_lbl := Label.new()
	stats_lbl.add_theme_font_size_override("font_size", 18)
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match card_data.card_type:
		CardData.CardType.ATTACK:
			stats_lbl.text = "攻击力: " + str(card_data.attack_power)
			stats_lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		CardData.CardType.DEFENSE:
			stats_lbl.text = "防御力: " + str(card_data.defense_power)
			stats_lbl.add_theme_color_override("font_color", Color(0.3, 0.7, 1))
		CardData.CardType.SUMMON:
			stats_lbl.text = "攻:" + str(card_data.attack_power) + "  血:" + str(card_data.summon_hp)
			stats_lbl.add_theme_color_override("font_color", Color(0.3, 1, 0.5))
		CardData.CardType.SPELL:
			stats_lbl.text = "术法效果"
			stats_lbl.add_theme_color_override("font_color", Color(0.8, 0.5, 1))
	vbox.add_child(stats_lbl)

	# Yin/Yang indicator with color
	var yy_lbl := Label.new()
	yy_lbl.text = card_data.get_yinyang_text()
	yy_lbl.add_theme_font_size_override("font_size", 16)
	yy_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	yy_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match card_data.yinyang:
		CardData.YinYang.YIN:
			yy_lbl.add_theme_color_override("font_color", Color(0.5, 0.3, 1.0))
		CardData.YinYang.YANG:
			yy_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		_:
			yy_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(yy_lbl)

	# Rarity indicator
	var rarity_lbl := Label.new()
	rarity_lbl.text = "算力: " + str(card_data.cost) + "  |  " + card_data.get_type_text()
	rarity_lbl.add_theme_font_size_override("font_size", 14)
	rarity_lbl.add_theme_color_override("font_color", card_data.get_rarity_color())
	rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(rarity_lbl)

	# Add to tree as top-level so it isn't affected by card transforms
	var canvas_layer: CanvasLayer = CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.name = "CardPreviewLayer"
	add_child(canvas_layer)
	canvas_layer.add_child(_preview_panel)

	# Position above the card, centered, clamped to screen bounds
	var card_global_center: Vector2 = global_position + (size * scale) / 2.0
	var preview_x: float = card_global_center.x - 200.0  # half of 400
	var preview_y: float = global_position.y - 310.0  # above card
	# Clamp to screen
	var screen_size: Vector2 = get_viewport_rect().size
	preview_x = clampf(preview_x, 4.0, screen_size.x - 404.0)
	preview_y = clampf(preview_y, 4.0, screen_size.y - 304.0)
	_preview_panel.position = Vector2(preview_x, preview_y)

## 播放打出动画
func play_cast_animation(target_pos: Vector2) -> void:
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "global_position", target_pos, 0.3)
	tween.parallel().tween_property(self, "scale", Vector2(0.5, 0.5), 0.3)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
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
