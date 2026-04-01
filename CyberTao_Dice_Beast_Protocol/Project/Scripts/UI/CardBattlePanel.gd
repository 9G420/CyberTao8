extends Panel
class_name CardBattlePanel

## 卡牌战斗 UI 面板（v0.1.54 全屏重设计）
## 1280x720 独立全屏界面：战斗背景 + 角色立绘 + 扇形手牌 + HP/能量
## 设计参考：宝可梦 / 杀戮尖塔 全屏战斗风格

const CardBattleController = preload("res://Scripts/BattleV2/CardBattleController.gd")

var _controller: CardBattleController = null

# --- UI 引用 ---
var _title_label: Label
var _turn_label: Label
var _enemy_name_label: Label
var _enemy_hp_container: Control
var _enemy_intent_label: Label
var _player_name_label: Label
var _player_hp_container: Control
var _energy_container: Control
var _deck_label: Label
var _log_label: Label
var _card_container: Control
var _card_widgets: Array = []
var _end_turn_button: Button
var _flee_button: Button
var _char_draw_layer: Control  # 角色绘制层（用 _draw 渲染角色）
var _pulse_time: float = 0.0
var _current_encounter_id: String = ""

# v0.1.68：拖拽出牌系统
var _drag_index: int = -1
var _drag_widget: Panel = null
var _drag_offset: Vector2 = Vector2.ZERO
var _drag_origin_pos: Vector2 = Vector2.ZERO
var _drag_origin_rot: float = 0.0
var _play_zone: ColorRect = null
const PLAY_ZONE_Y: float = 380.0
# v0.1.68：即时 HP 追踪（用于伤害飘字）
var _hp_before_enemy: int = 0
var _hp_before_player: int = 0

# --- 扇形手牌参数 ---
const FAN_RADIUS: float = 700.0
const FAN_CARD_ANGLE: float = 6.0
const FAN_MAX_ANGLE: float = 22.0
const FAN_CENTER_X: float = 640.0
const FAN_CENTER_Y: float = 820.0
const CARD_Y_BASE: float = 540.0
const BATTLE_CARD_W: float = 105.0
const BATTLE_CARD_H: float = 130.0

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(1280, 720)
	size = Vector2(1280, 720)
	_build_ui()

func _process(_delta: float) -> void:
	if visible:
		_pulse_time += _delta
		if _char_draw_layer:
			_char_draw_layer.queue_redraw()

func bind_controller(controller: CardBattleController) -> void:
	_controller = controller
	if _controller.battle_started and not _controller.battle_started.is_connected(_on_battle_started):
		_controller.battle_started.connect(_on_battle_started)
	if _controller.hand_changed and not _controller.hand_changed.is_connected(_on_hand_changed):
		_controller.hand_changed.connect(_on_hand_changed)
	if _controller.card_played and not _controller.card_played.is_connected(_on_card_played):
		_controller.card_played.connect(_on_card_played)
	if _controller.enemy_acted and not _controller.enemy_acted.is_connected(_on_enemy_acted):
		_controller.enemy_acted.connect(_on_enemy_acted)
	if _controller.enemy_intent_changed and not _controller.enemy_intent_changed.is_connected(_on_enemy_intent_changed):
		_controller.enemy_intent_changed.connect(_on_enemy_intent_changed)
	if _controller.turn_resolved and not _controller.turn_resolved.is_connected(_on_turn_resolved):
		_controller.turn_resolved.connect(_on_turn_resolved)
	if _controller.battle_ended and not _controller.battle_ended.is_connected(_on_battle_ended):
		_controller.battle_ended.connect(_on_battle_ended)
	if _controller.victory_reward and not _controller.victory_reward.is_connected(_on_victory_reward):
		_controller.victory_reward.connect(_on_victory_reward)
	if _controller.energy_grown and not _controller.energy_grown.is_connected(_on_energy_grown):
		_controller.energy_grown.connect(_on_energy_grown)

# --- 控制器信号回调 ---

func _on_battle_started(player_hp: int, enemy_hp: int, enemy_name: String) -> void:
	_current_encounter_id = _controller.encounter_id if _controller else ""
	_hp_before_player = player_hp
	_hp_before_enemy = enemy_hp
	_log_label.text = "遭遇 " + enemy_name + "！抽牌并选择出牌。"
	_end_turn_button.disabled = false
	_flee_button.disabled = false
	if _controller and _controller.is_boss_encounter():
		_flee_button.disabled = true
		_flee_button.text = "无法逃跑"
	else:
		_flee_button.text = "逃跑（-1 HP）"
	_refresh_status()

func _on_hand_changed(new_hand: Array, cur_energy: int, max_e: int) -> void:
	_cancel_drag()
	_rebuild_fan_cards(new_hand, cur_energy)
	_rebuild_container(_energy_container, CardRenderer.create_energy_dots(cur_energy, max_e))
	_deck_label.text = "牌堆 " + str(_controller.get_draw_count()) + " | 弃牌 " + str(_controller.get_discard_count())

func _on_card_played(_card_index: int, _card_name: String, effect_text: String) -> void:
	_log_label.text = effect_text
	# v0.1.68：即时刷新 HP + 伤害飘字
	_refresh_status()
	if _controller:
		var enemy_dmg: int = _hp_before_enemy - _controller.enemy_hp
		var player_dmg: int = _hp_before_player - _controller.player_hp
		if enemy_dmg > 0:
			_spawn_effect_popup("-" + str(enemy_dmg), Color(1.0, 0.3, 0.2), Vector2(1040, 60))
		elif enemy_dmg < 0:
			_spawn_effect_popup("+" + str(-enemy_dmg), Color(0.3, 1.0, 0.5), Vector2(1040, 60))
		if player_dmg > 0:
			_spawn_effect_popup("-" + str(player_dmg), Color(1.0, 0.3, 0.2), Vector2(160, 430))
		elif player_dmg < 0:
			_spawn_effect_popup("+" + str(-player_dmg), Color(0.3, 1.0, 0.5), Vector2(160, 430))

func _on_enemy_acted(action_text: String) -> void:
	_log_label.text = _log_label.text + "\n" + action_text
	# v0.1.68：即时刷新 + 敌方行动伤害飘字
	_refresh_status()
	if _controller:
		var player_dmg: int = _hp_before_player - _controller.player_hp
		if player_dmg > 0:
			_spawn_effect_popup("-" + str(player_dmg), Color(1.0, 0.3, 0.2), Vector2(160, 430))
		elif player_dmg < 0:
			_spawn_effect_popup("+" + str(-player_dmg), Color(0.3, 1.0, 0.5), Vector2(160, 430))
		# 更新追踪值
		_hp_before_player = _controller.player_hp
		_hp_before_enemy = _controller.enemy_hp

func _on_enemy_intent_changed(intent_text: String) -> void:
	var icon: String = ""
	var color: Color = CyberStyle.ACCENT_ORANGE
	if "超载" in intent_text:
		icon = "⚠ "
		color = Color(1.0, 0.15, 0.1)
	elif "重击" in intent_text:
		icon = "⚔⚔ "
		color = Color(1.0, 0.3, 0.15)
	elif "连续" in intent_text:
		icon = "⚔⚔ "
		color = Color(1.0, 0.35, 0.25)
	elif "强化" in intent_text:
		icon = "▲ "
		color = Color(0.85, 0.4, 1.0)
	elif "防御" in intent_text:
		icon = "■⚔ "
		color = Color(0.85, 0.65, 0.2)
	elif "修复" in intent_text:
		icon = "✚ "
		color = Color(0.3, 1.0, 0.55)
	elif "攻击" in intent_text:
		icon = "⚔ "
		color = Color(1.0, 0.45, 0.2)
	_enemy_intent_label.text = icon + intent_text
	_enemy_intent_label.add_theme_color_override("font_color", color)

func _on_turn_resolved(player_hp: int, enemy_hp: int, battle_turn: int) -> void:
	_refresh_status()

func _on_battle_ended(victory: bool, _player_hp_remaining: int) -> void:
	_clear_card_widgets()
	_end_turn_button.disabled = true
	_flee_button.disabled = true
	if victory:
		_log_label.text = _log_label.text + "\n胜利！" + _controller.enemy_name + " 被消灭。"
	else:
		if _controller.player_hp <= 0:
			_log_label.text = _log_label.text + "\n败北..."
		else:
			_log_label.text = "逃跑！受到 1 点惩罚伤害。"
	_refresh_status()

func _on_victory_reward(reward_text: String) -> void:
	_log_label.text = _log_label.text + "\n奖励：" + reward_text

func _on_energy_grown(old_max: int, new_max: int) -> void:
	_log_label.text = _log_label.text + "\n能量上限提升！" + str(old_max) + " → " + str(new_max)

# --- 拖拽出牌系统 (v0.1.68) ---

func _input(event: InputEvent) -> void:
	if not visible or _drag_index < 0:
		return
	if event is InputEventMouseMotion:
		if is_instance_valid(_drag_widget):
			var local_mouse: Vector2 = _card_container.get_local_mouse_position()
			_drag_widget.position = local_mouse - _drag_offset
			# 进入出牌区高亮
			if _play_zone:
				_play_zone.visible = true
				if local_mouse.y < PLAY_ZONE_Y:
					_play_zone.color = Color(0.0, 0.85, 1.0, 0.12)
				else:
					_play_zone.color = Color(0.0, 0.85, 1.0, 0.04)
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_mouse: Vector2 = _card_container.get_local_mouse_position()
		if local_mouse.y < PLAY_ZONE_Y:
			_end_drag()
		else:
			_cancel_drag()

func _start_card_drag(index: int, widget: Panel) -> void:
	_drag_index = index
	_drag_widget = widget
	var local_mouse: Vector2 = _card_container.get_local_mouse_position()
	_drag_offset = local_mouse - widget.position
	_drag_origin_pos = widget.position
	_drag_origin_rot = widget.rotation_degrees
	widget.rotation_degrees = 0.0
	widget.scale = Vector2(1.15, 1.15)
	widget.z_index = 20
	if _play_zone:
		_play_zone.visible = true

func _end_drag() -> void:
	if _drag_index < 0 or _controller == null:
		_cancel_drag()
		return
	var idx: int = _drag_index
	# 记录出牌前 HP，用于伤害飘字
	_hp_before_enemy = _controller.enemy_hp
	_hp_before_player = _controller.player_hp
	_drag_index = -1
	_drag_widget = null
	if _play_zone:
		_play_zone.visible = false
	_controller.play_card(idx)

func _cancel_drag() -> void:
	if _drag_index >= 0 and is_instance_valid(_drag_widget):
		var widget: Panel = _drag_widget
		var tw: Tween = widget.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(widget, "position", _drag_origin_pos, 0.12)
		tw.parallel().tween_property(widget, "rotation_degrees", _drag_origin_rot, 0.12)
		tw.parallel().tween_property(widget, "scale", Vector2.ONE, 0.12)
		widget.z_index = 0
	_drag_index = -1
	_drag_widget = null
	if _play_zone:
		_play_zone.visible = false

func _spawn_effect_popup(text: String, color: Color, base_pos: Vector2) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = base_pos
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", color)
	lbl.z_index = 50
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw: Tween = lbl.create_tween()
	tw.tween_property(lbl, "position:y", base_pos.y - 60, 0.7).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.7).set_ease(Tween.EASE_IN).set_delay(0.3)
	tw.tween_callback(lbl.queue_free)

func _on_end_turn_pressed() -> void:
	if _controller:
		_controller.end_turn()

func _on_flee_pressed() -> void:
	if _controller:
		_controller.flee()

# --- 扇形手牌布局 ---

func _rebuild_fan_cards(new_hand: Array, cur_energy: int) -> void:
	_clear_card_widgets()
	var count: int = new_hand.size()
	if count == 0:
		return
	var total_angle: float = minf(FAN_CARD_ANGLE * float(count - 1), FAN_MAX_ANGLE * 2.0)
	var start_angle: float = -total_angle / 2.0
	for i in range(count):
		var card: Dictionary = new_hand[i]
		var cost: int = int(card.get("cost", 1))
		var can_play: bool = cost <= cur_energy
		# 计算扇形位置
		var angle_deg: float = 0.0
		if count > 1:
			angle_deg = start_angle + (total_angle * float(i) / float(count - 1))
		var angle_rad: float = deg_to_rad(angle_deg)
		var target_x: float = FAN_CENTER_X + sin(angle_rad) * FAN_RADIUS - BATTLE_CARD_W / 2.0
		var target_y: float = CARD_Y_BASE + (1.0 - cos(angle_rad)) * FAN_RADIUS * 0.06
		var target_rot: float = angle_deg * 0.5
		var widget: Panel = _create_battle_card(card, can_play, i)
		widget.position = Vector2(target_x, target_y)
		widget.set_meta("base_pos", widget.position)
		widget.rotation_degrees = target_rot
		widget.pivot_offset = Vector2(BATTLE_CARD_W / 2.0, BATTLE_CARD_H)
		_card_container.add_child(widget)
		_card_widgets.append(widget)

func _clear_card_widgets() -> void:
	for w in _card_widgets:
		if is_instance_valid(w):
			w.queue_free()
	_card_widgets = []

# --- 战斗用卡牌创建（比标准卡牌稍大） ---

func _create_battle_card(card: Dictionary, can_play: bool, index: int) -> Panel:
	var panel := Panel.new()
	panel.size = Vector2(BATTLE_CARD_W, BATTLE_CARD_H)
	panel.custom_minimum_size = Vector2(BATTLE_CARD_W, BATTLE_CARD_H)
	var card_type: String = String(card.get("type", "attack"))
	var accent: Color = CardRenderer.TYPE_COLORS.get(card_type, Color(0.5, 0.5, 0.5))
	var is_upgraded: bool = card.get("upgraded", false)
	# 面板样式
	var sb := StyleBoxFlat.new()
	sb.bg_color = CyberStyle.BG_CARD if can_play else Color(0.03, 0.03, 0.06, 0.85)
	var border_col: Color
	if not can_play:
		border_col = Color(0.2, 0.22, 0.25, 0.5)
	elif is_upgraded:
		border_col = CyberStyle.ACCENT_CYAN
	else:
		border_col = accent
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	if is_upgraded and can_play:
		sb.shadow_color = Color(0.0, 0.85, 1.0, 0.35)
		sb.shadow_size = 6
	elif can_play:
		sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.2)
		sb.shadow_size = 4
	panel.add_theme_stylebox_override("panel", sb)
	# 卡牌名称
	var name_lbl := Label.new()
	name_lbl.text = String(card.get("name", "?"))
	name_lbl.position = Vector2(0, 6)
	name_lbl.size = Vector2(BATTLE_CARD_W, 18)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY if can_play else CyberStyle.TEXT_MUTED)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(name_lbl)
	# 类型图标
	var icon_lbl := Label.new()
	icon_lbl.text = CardRenderer.TYPE_ICONS.get(card_type, "?")
	icon_lbl.position = Vector2(0, 26)
	icon_lbl.size = Vector2(BATTLE_CARD_W, 38)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 30)
	icon_lbl.add_theme_color_override("font_color", accent if can_play else Color(accent.r, accent.g, accent.b, 0.3))
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(icon_lbl)
	# 数值描述
	var val_lbl := Label.new()
	val_lbl.text = CardRenderer._format_value(card)
	val_lbl.position = Vector2(0, 66)
	val_lbl.size = Vector2(BATTLE_CARD_W, 16)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.add_theme_font_size_override("font_size", 12)
	val_lbl.add_theme_color_override("font_color", CyberStyle.TEXT_SECONDARY if can_play else CyberStyle.TEXT_MUTED)
	val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(val_lbl)
	# 分隔线
	var sep := ColorRect.new()
	sep.position = Vector2(10, 86)
	sep.size = Vector2(BATTLE_CARD_W - 20, 1)
	sep.color = Color(border_col.r, border_col.g, border_col.b, 0.3)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sep)
	# 费用
	var cost_lbl := Label.new()
	cost_lbl.text = str(card.get("cost", 1)) + "E"
	cost_lbl.position = Vector2(10, 92)
	cost_lbl.size = Vector2(30, 22)
	cost_lbl.add_theme_font_size_override("font_size", 14)
	cost_lbl.add_theme_color_override("font_color", CyberStyle.TEXT_ENERGY if can_play else CyberStyle.TEXT_WARN)
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(cost_lbl)
	# 类型标签
	var type_lbl := Label.new()
	type_lbl.text = CardRenderer.TYPE_LABELS.get(card_type, "")
	type_lbl.position = Vector2(BATTLE_CARD_W - 48, 94)
	type_lbl.size = Vector2(42, 20)
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	type_lbl.add_theme_font_size_override("font_size", 10)
	type_lbl.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.5 if can_play else 0.25))
	type_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(type_lbl)
	# 交互
	if can_play:
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var idx: int = index
		panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_start_card_drag(idx, panel)
		)
		panel.mouse_entered.connect(func():
			if _drag_index >= 0:
				return
			var base_pos: Vector2 = panel.get_meta("base_pos", panel.position)
			var tw: Tween = panel.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tw.tween_property(panel, "scale", Vector2(1.12, 1.12), 0.1)
			tw.parallel().tween_property(panel, "position:y", base_pos.y - 20, 0.1)
			panel.z_index = 10
		)
		panel.mouse_exited.connect(func():
			if _drag_index >= 0:
				return
			var base_pos: Vector2 = panel.get_meta("base_pos", panel.position)
			var tw: Tween = panel.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tw.tween_property(panel, "scale", Vector2.ONE, 0.1)
			tw.parallel().tween_property(panel, "position:y", base_pos.y, 0.1)
			panel.z_index = 0
		)
	return panel

# --- 状态刷新 ---

func _refresh_status() -> void:
	if _controller == null:
		return
	var boss_tag: String = ""
	if _controller.is_boss_encounter():
		boss_tag = " [BOSS]"
	_title_label.text = "卡牌战斗" + boss_tag
	_enemy_name_label.text = _controller.enemy_name
	_turn_label.text = "回合 " + str(_controller.battle_turn)
	_deck_label.text = "牌堆 " + str(_controller.get_draw_count()) + " | 弃牌 " + str(_controller.get_discard_count())
	# 敌方 HP 条
	_rebuild_container(_enemy_hp_container, CardRenderer.create_hp_bar(
		_controller.enemy_hp, _controller.enemy_max_hp,
		CyberStyle.HP_ENEMY, CyberStyle.HP_ENEMY_LOW, 220.0, 16.0
	))
	# 玩家 HP 条
	_rebuild_container(_player_hp_container, CardRenderer.create_hp_bar(
		_controller.player_hp, _controller.player_max_hp,
		CyberStyle.HP_PLAYER, CyberStyle.HP_PLAYER_LOW, 220.0, 16.0
	))
	# 能量点
	_rebuild_container(_energy_container, CardRenderer.create_energy_dots(
		_controller.energy, _controller.max_energy
	))

func _rebuild_container(container: Control, new_child: Control) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	container.add_child(new_child)

# --- 角色绘制层 ---

func _on_char_draw(ci: Control) -> void:
	# 绘制战斗背景
	_draw_battle_background(ci)
	# 绘制角色
	var pulse: float = sin(_pulse_time * 2.0) * 0.5 + 0.5
	BattleCharRenderer.draw_player_hero(ci, Vector2(200, 320), 2.2, pulse)
	if _current_encounter_id != "":
		var enemy_scale: float = 2.8 if _current_encounter_id.begins_with("encounter_boss_") else 2.2
		BattleCharRenderer.draw_enemy(ci, Vector2(1080, 300), enemy_scale, pulse, _current_encounter_id)

func _draw_battle_background(ci: Control) -> void:
	# 深色赛博朋克战斗场景
	# 地面网格
	var grid_col: Color = Color(0.0, 0.6, 0.9, 0.06)
	var grid_y_start: float = 420.0
	# 水平线（透视效果）
	for i in range(8):
		var y: float = grid_y_start + float(i) * 18.0 + float(i * i) * 2.0
		if y > 720:
			break
		var alpha: float = 0.04 + float(i) * 0.008
		ci.draw_line(Vector2(0, y), Vector2(1280, y), Color(grid_col.r, grid_col.g, grid_col.b, alpha), 1.0)
	# 垂直线（透视收束）
	for i in range(12):
		var x: float = 640.0 + (float(i) - 5.5) * 120.0
		var top_x: float = 640.0 + (float(i) - 5.5) * 40.0
		ci.draw_line(Vector2(top_x, grid_y_start), Vector2(x, 720), Color(grid_col.r, grid_col.g, grid_col.b, 0.04), 1.0)
	# 中间分隔光带
	ci.draw_line(Vector2(640, 50), Vector2(640, 500), Color(0.0, 0.7, 0.9, 0.04), 1.5)
	# 顶部光弧
	ci.draw_arc(Vector2(640, -200), 350, 0.2, PI - 0.2, 32, Color(0.0, 0.7, 0.9, 0.03), 2.0)
	# VS 标记
	var vs_pulse: float = sin(_pulse_time * 1.5) * 0.15 + 0.85
	ci.draw_string(ci.get_theme_default_font(), Vector2(605, 275), "VS", HORIZONTAL_ALIGNMENT_CENTER, 70, 36, Color(1.0, 0.6, 0.15, 0.15 * vs_pulse))

# --- UI 构建 ---

func _build_ui() -> void:
	# 面板背景（全屏深色）
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.02, 0.06, 0.98)
	sb.border_color = Color(0.0, 0.0, 0.0, 0.0)
	sb.set_border_width_all(0)
	add_theme_stylebox_override("panel", sb)

	# 角色绘制层（全屏 Control，用于 _draw 回调）
	_char_draw_layer = Control.new()
	_char_draw_layer.position = Vector2.ZERO
	_char_draw_layer.size = Vector2(1280, 720)
	_char_draw_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_char_draw_layer.draw.connect(_on_char_draw.bind(_char_draw_layer))
	add_child(_char_draw_layer)

	# === 顶部信息栏 ===
	_title_label = Label.new()
	_title_label.text = "卡牌战斗"
	_title_label.position = Vector2(0, 8)
	_title_label.size = Vector2(1280, 30)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_color", CyberStyle.TEXT_TITLE)
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title_label)

	_turn_label = Label.new()
	_turn_label.text = "回合 1"
	_turn_label.position = Vector2(1180, 12)
	_turn_label.size = Vector2(90, 22)
	_turn_label.add_theme_font_size_override("font_size", 12)
	_turn_label.add_theme_color_override("font_color", CyberStyle.TEXT_SECONDARY)
	_turn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_turn_label)

	# === 敌方区域（右上） ===
	_enemy_name_label = Label.new()
	_enemy_name_label.text = ""
	_enemy_name_label.position = Vector2(900, 50)
	_enemy_name_label.size = Vector2(300, 24)
	_enemy_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_enemy_name_label.add_theme_font_size_override("font_size", 16)
	_enemy_name_label.add_theme_color_override("font_color", CyberStyle.HP_ENEMY)
	_enemy_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_enemy_name_label)

	_enemy_hp_container = Control.new()
	_enemy_hp_container.position = Vector2(940, 78)
	_enemy_hp_container.size = Vector2(224, 20)
	_enemy_hp_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_enemy_hp_container)

	_enemy_intent_label = Label.new()
	_enemy_intent_label.text = ""
	_enemy_intent_label.position = Vector2(900, 102)
	_enemy_intent_label.size = Vector2(300, 22)
	_enemy_intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_enemy_intent_label.add_theme_font_size_override("font_size", 13)
	_enemy_intent_label.add_theme_color_override("font_color", CyberStyle.ACCENT_ORANGE)
	_enemy_intent_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_enemy_intent_label)

	# === 玩家区域（左下） ===
	_player_name_label = Label.new()
	_player_name_label.text = "刀盾犬"
	_player_name_label.position = Vector2(60, 440)
	_player_name_label.size = Vector2(200, 24)
	_player_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_name_label.add_theme_font_size_override("font_size", 14)
	_player_name_label.add_theme_color_override("font_color", CyberStyle.HP_PLAYER)
	_player_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_player_name_label)

	_player_hp_container = Control.new()
	_player_hp_container.position = Vector2(70, 468)
	_player_hp_container.size = Vector2(224, 20)
	_player_hp_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_player_hp_container)

	_energy_container = Control.new()
	_energy_container.position = Vector2(105, 496)
	_energy_container.size = Vector2(120, 20)
	_energy_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_energy_container)

	_deck_label = Label.new()
	_deck_label.text = "牌堆 0 | 弃牌 0"
	_deck_label.position = Vector2(60, 520)
	_deck_label.size = Vector2(200, 20)
	_deck_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_deck_label.add_theme_font_size_override("font_size", 11)
	_deck_label.add_theme_color_override("font_color", CyberStyle.TEXT_MUTED)
	_deck_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_deck_label)

	# === 战斗日志（中央偏下） ===
	var log_bg := Panel.new()
	log_bg.position = Vector2(380, 430)
	log_bg.size = Vector2(520, 70)
	var log_sb := StyleBoxFlat.new()
	log_sb.bg_color = Color(0.02, 0.02, 0.06, 0.75)
	log_sb.border_color = Color(0.0, 0.5, 0.7, 0.2)
	log_sb.set_border_width_all(1)
	log_sb.set_corner_radius_all(6)
	log_bg.add_theme_stylebox_override("panel", log_sb)
	log_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(log_bg)

	_log_label = Label.new()
	_log_label.text = ""
	_log_label.position = Vector2(390, 436)
	_log_label.size = Vector2(500, 58)
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.add_theme_font_size_override("font_size", 12)
	_log_label.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY)
	_log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_log_label)

	# === 出牌区域提示（拖拽时显示） ===
	_play_zone = ColorRect.new()
	_play_zone.position = Vector2(0, 0)
	_play_zone.size = Vector2(1280, PLAY_ZONE_Y)
	_play_zone.color = Color(0.0, 0.85, 1.0, 0.04)
	_play_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play_zone.visible = false
	add_child(_play_zone)

	var play_zone_lbl := Label.new()
	play_zone_lbl.text = "拖到此处出牌"
	play_zone_lbl.position = Vector2(0, PLAY_ZONE_Y - 30)
	play_zone_lbl.size = Vector2(1280, 24)
	play_zone_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_zone_lbl.add_theme_font_size_override("font_size", 14)
	play_zone_lbl.add_theme_color_override("font_color", Color(0.0, 0.85, 1.0, 0.5))
	play_zone_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play_zone.add_child(play_zone_lbl)

	# === 手牌容器（底部扇形区域） ===
	_card_container = Control.new()
	_card_container.position = Vector2.ZERO
	_card_container.size = Vector2(1280, 720)
	_card_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card_container)

	# === 操作按钮（右下） ===
	_end_turn_button = Button.new()
	_end_turn_button.text = "结束回合"
	_end_turn_button.position = Vector2(1060, 520)
	_end_turn_button.size = Vector2(180, 40)
	_end_turn_button.add_theme_font_size_override("font_size", 15)
	_end_turn_button.pressed.connect(_on_end_turn_pressed)
	_end_turn_button.disabled = true
	CyberStyle.style_button(_end_turn_button, "cyan")
	add_child(_end_turn_button)

	_flee_button = Button.new()
	_flee_button.text = "逃跑（-1 HP）"
	_flee_button.position = Vector2(1060, 568)
	_flee_button.size = Vector2(180, 40)
	_flee_button.add_theme_font_size_override("font_size", 15)
	_flee_button.pressed.connect(_on_flee_pressed)
	_flee_button.disabled = true
	CyberStyle.style_button(_flee_button, "orange")
	add_child(_flee_button)
