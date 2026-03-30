extends Panel
class_name CardBattlePanel

## 卡牌战斗 UI 面板（Phase 3 美化版）
## CardRenderer 卡牌控件 + HP 条 + 能量点 + 意图图标

const CardBattleController = preload("res://Scripts/BattleV2/CardBattleController.gd")

var _controller: CardBattleController = null

# --- UI 引用 ---
var _title_label: Label
var _turn_label: Label
var _enemy_hp_container: Control
var _enemy_intent_label: Label
var _player_hp_container: Control
var _energy_container: Control
var _deck_label: Label
var _log_label: Label
var _card_container: Control
var _card_widgets: Array = []
var _end_turn_button: Button
var _flee_button: Button

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(500, 470)
	size = Vector2(500, 470)
	_build_ui()

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
	_log_label.text = "遭遇 " + enemy_name + "！抽牌并选择出牌。"
	_end_turn_button.disabled = false
	_flee_button.disabled = false
	if _controller and _controller.is_boss_encounter():
		_flee_button.disabled = true
		_flee_button.text = "无法逃跑"
	else:
		_flee_button.text = "逃跑（-1 HP）"
	_refresh_status()
	# visible 由 Main.gd 通过 TransitionOverlay 统一管理

func _on_hand_changed(new_hand: Array, cur_energy: int, max_e: int) -> void:
	_rebuild_card_widgets(new_hand, cur_energy)
	_rebuild_container(_energy_container, CardRenderer.create_energy_dots(cur_energy, max_e))
	_deck_label.text = "牌堆 " + str(_controller.get_draw_count()) + " | 弃牌 " + str(_controller.get_discard_count())

func _on_card_played(_card_index: int, _card_name: String, effect_text: String) -> void:
	_log_label.text = effect_text

func _on_enemy_acted(action_text: String) -> void:
	_log_label.text = _log_label.text + "\n" + action_text

func _on_enemy_intent_changed(intent_text: String) -> void:
	var icon: String = ""
	var color: Color = CyberStyle.ACCENT_ORANGE
	if "超载" in intent_text:
		icon = "⚠ "
		color = Color(1.0, 0.15, 0.1)
	elif "重击" in intent_text:
		icon = "⚔⚔ "
		color = Color(1.0, 0.3, 0.15)
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
	# 不再自动隐藏——由 Main.gd 通过 TransitionOverlay 统一管理可见性

func _on_victory_reward(reward_text: String) -> void:
	_log_label.text = _log_label.text + "\n奖励：" + reward_text

func _on_energy_grown(old_max: int, new_max: int) -> void:
	_log_label.text = _log_label.text + "\n能量上限提升！" + str(old_max) + " → " + str(new_max)

# --- 按钮回调 ---

func _on_card_pressed(index: int) -> void:
	if _controller:
		_controller.play_card(index)

func _on_end_turn_pressed() -> void:
	if _controller:
		_controller.end_turn()

func _on_flee_pressed() -> void:
	if _controller:
		_controller.flee()

# --- 卡牌控件管理 ---

func _rebuild_card_widgets(new_hand: Array, cur_energy: int) -> void:
	_clear_card_widgets()
	var gap: float = 10.0
	var start_x: float = 10.0
	for i in range(new_hand.size()):
		var card: Dictionary = new_hand[i]
		var cost: int = int(card.get("cost", 1))
		var can_play: bool = cost <= cur_energy
		var col: int = i % 4
		var row: int = i / 4
		var widget: Panel = CardRenderer.create_card(card, can_play, i, _on_card_pressed)
		widget.position = Vector2(
			start_x + float(col) * (CardRenderer.CARD_W + gap),
			float(row) * (CardRenderer.CARD_H + 8)
		)
		_card_container.add_child(widget)
		_card_widgets.append(widget)

func _clear_card_widgets() -> void:
	for w in _card_widgets:
		if is_instance_valid(w):
			w.queue_free()
	_card_widgets = []

# --- 状态刷新 ---

func _refresh_status() -> void:
	if _controller == null:
		return
	var boss_tag: String = ""
	if _controller.is_boss_encounter():
		boss_tag = " [BOSS]"
	_title_label.text = "卡牌战斗 — " + _controller.enemy_name + boss_tag
	_turn_label.text = "回合 " + str(_controller.battle_turn)
	_deck_label.text = "牌堆 " + str(_controller.get_draw_count()) + " | 弃牌 " + str(_controller.get_discard_count())
	# 敌方 HP 条
	_rebuild_container(_enemy_hp_container, CardRenderer.create_hp_bar(
		_controller.enemy_hp, _controller.enemy_max_hp,
		CyberStyle.HP_ENEMY, CyberStyle.HP_ENEMY_LOW, 185.0, 14.0
	))
	# 玩家 HP 条
	_rebuild_container(_player_hp_container, CardRenderer.create_hp_bar(
		_controller.player_hp, _controller.player_max_hp,
		CyberStyle.HP_PLAYER, CyberStyle.HP_PLAYER_LOW, 185.0, 14.0
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

# --- UI 构建 ---

func _build_ui() -> void:
	add_theme_stylebox_override("panel", CyberStyle.make_panel_bg(CyberStyle.BORDER_ORANGE, 8))

	# 标题
	_title_label = Label.new()
	_title_label.text = "卡牌战斗"
	_title_label.position = Vector2(0, 8)
	_title_label.size = Vector2(500, 26)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", CyberStyle.TEXT_TITLE)
	add_child(_title_label)

	_turn_label = Label.new()
	_turn_label.text = "回合 1"
	_turn_label.position = Vector2(420, 10)
	_turn_label.size = Vector2(70, 20)
	_turn_label.add_theme_font_size_override("font_size", 11)
	_turn_label.add_theme_color_override("font_color", CyberStyle.TEXT_SECONDARY)
	add_child(_turn_label)

	_add_separator(34)

	# 敌方区域
	var enemy_lbl := Label.new()
	enemy_lbl.text = "敌方"
	enemy_lbl.position = Vector2(16, 40)
	enemy_lbl.size = Vector2(36, 16)
	enemy_lbl.add_theme_font_size_override("font_size", 11)
	enemy_lbl.add_theme_color_override("font_color", CyberStyle.HP_ENEMY)
	enemy_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(enemy_lbl)

	_enemy_hp_container = Control.new()
	_enemy_hp_container.position = Vector2(56, 38)
	_enemy_hp_container.size = Vector2(190, 18)
	_enemy_hp_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_enemy_hp_container)

	_enemy_intent_label = Label.new()
	_enemy_intent_label.text = ""
	_enemy_intent_label.position = Vector2(256, 39)
	_enemy_intent_label.size = Vector2(230, 18)
	_enemy_intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_enemy_intent_label.add_theme_font_size_override("font_size", 11)
	_enemy_intent_label.add_theme_color_override("font_color", CyberStyle.ACCENT_ORANGE)
	add_child(_enemy_intent_label)

	# 玩家区域
	var player_lbl := Label.new()
	player_lbl.text = "我方"
	player_lbl.position = Vector2(16, 62)
	player_lbl.size = Vector2(36, 16)
	player_lbl.add_theme_font_size_override("font_size", 11)
	player_lbl.add_theme_color_override("font_color", CyberStyle.HP_PLAYER)
	player_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(player_lbl)

	_player_hp_container = Control.new()
	_player_hp_container.position = Vector2(56, 60)
	_player_hp_container.size = Vector2(190, 18)
	_player_hp_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_player_hp_container)

	_energy_container = Control.new()
	_energy_container.position = Vector2(256, 62)
	_energy_container.size = Vector2(100, 18)
	_energy_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_energy_container)

	_deck_label = Label.new()
	_deck_label.text = "牌堆 0 | 弃牌 0"
	_deck_label.position = Vector2(370, 62)
	_deck_label.size = Vector2(120, 18)
	_deck_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_deck_label.add_theme_font_size_override("font_size", 10)
	_deck_label.add_theme_color_override("font_color", CyberStyle.TEXT_MUTED)
	add_child(_deck_label)

	_add_separator(82)

	# 战斗日志
	_log_label = Label.new()
	_log_label.text = ""
	_log_label.position = Vector2(16, 87)
	_log_label.size = Vector2(468, 52)
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.add_theme_font_size_override("font_size", 11)
	_log_label.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY)
	add_child(_log_label)

	_add_separator(142)

	# 手牌容器
	_card_container = Control.new()
	_card_container.position = Vector2(16, 148)
	_card_container.size = Vector2(468, 226)
	add_child(_card_container)

	_add_separator(380)

	# 结束回合按钮
	_end_turn_button = Button.new()
	_end_turn_button.text = "结束回合"
	_end_turn_button.position = Vector2(16, 388)
	_end_turn_button.size = Vector2(228, 36)
	_end_turn_button.add_theme_font_size_override("font_size", 14)
	_end_turn_button.pressed.connect(_on_end_turn_pressed)
	_end_turn_button.disabled = true
	CyberStyle.style_button(_end_turn_button, "cyan")
	add_child(_end_turn_button)

	# 逃跑按钮
	_flee_button = Button.new()
	_flee_button.text = "逃跑（-1 HP）"
	_flee_button.position = Vector2(256, 388)
	_flee_button.size = Vector2(228, 36)
	_flee_button.add_theme_font_size_override("font_size", 14)
	_flee_button.pressed.connect(_on_flee_pressed)
	_flee_button.disabled = true
	CyberStyle.style_button(_flee_button, "orange")
	add_child(_flee_button)

func _add_separator(y: float) -> void:
	var sep := ColorRect.new()
	sep.position = Vector2(16, y)
	sep.size = Vector2(468, 1)
	sep.color = Color(1.0, 0.5, 0.15, 0.2)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep)
