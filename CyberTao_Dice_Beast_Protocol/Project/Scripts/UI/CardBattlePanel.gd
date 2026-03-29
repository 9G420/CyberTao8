extends Panel
class_name CardBattlePanel

## 卡牌战斗 UI 面板（纯显示层 — Day 10 丰富化版）
## 动态手牌按钮 + 能量显示 + 敌方意图 + 牌堆计数

const CardBattleController = preload("res://Scripts/BattleV2/CardBattleController.gd")

var _controller: CardBattleController = null

# --- UI 引用 ---
var _title_label: Label
var _enemy_hp_label: Label
var _enemy_intent_label: Label
var _player_hp_label: Label
var _energy_label: Label
var _log_label: Label
var _turn_label: Label
var _deck_label: Label
var _card_container: Control
var _card_buttons: Array[Button] = []
var _card_cost_labels: Array[Label] = []
var _end_turn_button: Button
var _flee_button: Button

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(480, 460)
	size = Vector2(480, 460)
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

# --- 控制器信号回调 ---

func _on_battle_started(player_hp: int, enemy_hp: int, enemy_name: String) -> void:
	_log_label.text = "遭遇 " + enemy_name + "！抽牌并选择出牌。"
	_end_turn_button.disabled = false
	_flee_button.disabled = false
	_refresh_status()
	visible = true

func _on_hand_changed(new_hand: Array, cur_energy: int, max_e: int) -> void:
	_rebuild_card_buttons(new_hand, cur_energy)
	_energy_label.text = "能量：" + str(cur_energy) + " / " + str(max_e)
	_deck_label.text = "牌堆 " + str(_controller.get_draw_count()) + " | 弃牌 " + str(_controller.get_discard_count())

func _on_card_played(_card_index: int, _card_name: String, effect_text: String) -> void:
	_log_label.text = effect_text

func _on_enemy_acted(action_text: String) -> void:
	_log_label.text = _log_label.text + "\n" + action_text

func _on_enemy_intent_changed(intent_text: String) -> void:
	_enemy_intent_label.text = intent_text

func _on_turn_resolved(player_hp: int, enemy_hp: int, battle_turn: int) -> void:
	_refresh_status()

func _on_battle_ended(victory: bool, _player_hp_remaining: int) -> void:
	_clear_card_buttons()
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
	await get_tree().create_timer(1.2).timeout
	visible = false

func _on_victory_reward(reward_text: String) -> void:
	_log_label.text = _log_label.text + "\n奖励：" + reward_text

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

# --- 动态手牌按钮 ---

func _rebuild_card_buttons(new_hand: Array, cur_energy: int) -> void:
	_clear_card_buttons()
	var btn_w: float = 105.0
	var btn_h: float = 50.0
	var gap: float = 6.0
	var start_x: float = 10.0
	var start_y: float = 0.0
	for i in range(new_hand.size()):
		var card: Dictionary = new_hand[i]
		var cost: int = int(card.get("cost", 1))
		var can_play: bool = cost <= cur_energy
		var btn := Button.new()
		var col: int = i % 4
		var row: int = i / 4
		btn.position = Vector2(start_x + col * (btn_w + gap), start_y + row * (btn_h + 18))
		btn.size = Vector2(btn_w, btn_h)
		btn.text = String(card["name"]) + " (" + str(card["value"]) + ")"
		btn.add_theme_font_size_override("font_size", 13)
		btn.disabled = not can_play
		var idx: int = i
		btn.pressed.connect(func(): _on_card_pressed(idx))
		_card_container.add_child(btn)
		_card_buttons.append(btn)
		# 费用标签
		var clbl := Label.new()
		clbl.text = str(cost) + "E"
		clbl.position = Vector2(btn.position.x + btn_w - 28, btn.position.y + btn_h)
		clbl.size = Vector2(30, 14)
		clbl.add_theme_font_size_override("font_size", 10)
		var cost_color: Color = Color(0.5, 0.85, 1.0) if can_play else Color(0.6, 0.3, 0.3)
		clbl.add_theme_color_override("font_color", cost_color)
		_card_container.add_child(clbl)
		_card_cost_labels.append(clbl)

func _clear_card_buttons() -> void:
	for btn in _card_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	_card_buttons = []
	for lbl in _card_cost_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	_card_cost_labels = []

# --- 状态刷新 ---

func _refresh_status() -> void:
	if _controller == null:
		return
	_title_label.text = "卡牌战斗 — " + _controller.enemy_name
	_enemy_hp_label.text = "敌方 HP：" + str(_controller.enemy_hp) + " / " + str(_controller.enemy_max_hp)
	_player_hp_label.text = "我方 HP：" + str(_controller.player_hp) + " / " + str(_controller.player_max_hp)
	_energy_label.text = "能量：" + str(_controller.energy) + " / " + str(_controller.max_energy)
	_turn_label.text = "回合 " + str(_controller.battle_turn)
	_deck_label.text = "牌堆 " + str(_controller.get_draw_count()) + " | 弃牌 " + str(_controller.get_discard_count())
	# HP 颜色
	if _controller.enemy_hp <= _controller.enemy_max_hp * 0.3:
		_enemy_hp_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	else:
		_enemy_hp_label.add_theme_color_override("font_color", Color(0.95, 0.5, 0.35))
	if _controller.player_hp <= _controller.player_max_hp * 0.3:
		_player_hp_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		_player_hp_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.7))

# --- UI 构建 ---

func _build_ui() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.07, 0.05, 0.12, 0.97)
	bg.border_color = Color(0.9, 0.45, 0.15, 0.9)
	bg.set_border_width_all(3)
	bg.set_corner_radius_all(10)
	add_theme_stylebox_override("panel", bg)

	_title_label = Label.new()
	_title_label.text = "卡牌战斗"
	_title_label.position = Vector2(0, 8)
	_title_label.size = Vector2(480, 28)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.25))
	add_child(_title_label)

	_turn_label = Label.new()
	_turn_label.text = "回合 1"
	_turn_label.position = Vector2(400, 10)
	_turn_label.size = Vector2(70, 20)
	_turn_label.add_theme_font_size_override("font_size", 12)
	_turn_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
	add_child(_turn_label)

	# 敌方区域
	_enemy_hp_label = Label.new()
	_enemy_hp_label.text = "敌方 HP：0 / 0"
	_enemy_hp_label.position = Vector2(16, 38)
	_enemy_hp_label.size = Vector2(230, 22)
	_enemy_hp_label.add_theme_font_size_override("font_size", 15)
	_enemy_hp_label.add_theme_color_override("font_color", Color(0.95, 0.5, 0.35))
	add_child(_enemy_hp_label)

	_enemy_intent_label = Label.new()
	_enemy_intent_label.text = ""
	_enemy_intent_label.position = Vector2(250, 38)
	_enemy_intent_label.size = Vector2(220, 22)
	_enemy_intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_enemy_intent_label.add_theme_font_size_override("font_size", 13)
	_enemy_intent_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.25))
	add_child(_enemy_intent_label)

	# 玩家区域
	_player_hp_label = Label.new()
	_player_hp_label.text = "我方 HP：0 / 0"
	_player_hp_label.position = Vector2(16, 62)
	_player_hp_label.size = Vector2(200, 22)
	_player_hp_label.add_theme_font_size_override("font_size", 15)
	_player_hp_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.7))
	add_child(_player_hp_label)

	_energy_label = Label.new()
	_energy_label.text = "能量：3 / 3"
	_energy_label.position = Vector2(220, 62)
	_energy_label.size = Vector2(110, 22)
	_energy_label.add_theme_font_size_override("font_size", 15)
	_energy_label.add_theme_color_override("font_color", Color(0.55, 0.75, 1.0))
	add_child(_energy_label)

	_deck_label = Label.new()
	_deck_label.text = "牌堆 0 | 弃牌 0"
	_deck_label.position = Vector2(340, 62)
	_deck_label.size = Vector2(130, 22)
	_deck_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_deck_label.add_theme_font_size_override("font_size", 12)
	_deck_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.6))
	add_child(_deck_label)

	# 战斗日志
	_log_label = Label.new()
	_log_label.text = ""
	_log_label.position = Vector2(16, 88)
	_log_label.size = Vector2(448, 66)
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.add_theme_font_size_override("font_size", 13)
	_log_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.75))
	add_child(_log_label)

	# 手牌容器（动态生成按钮区域）
	_card_container = Control.new()
	_card_container.position = Vector2(16, 160)
	_card_container.size = Vector2(448, 140)
	add_child(_card_container)

	# 结束回合按钮
	_end_turn_button = Button.new()
	_end_turn_button.text = "结束回合"
	_end_turn_button.position = Vector2(16, 310)
	_end_turn_button.size = Vector2(220, 36)
	_end_turn_button.add_theme_font_size_override("font_size", 14)
	_end_turn_button.pressed.connect(_on_end_turn_pressed)
	_end_turn_button.disabled = true
	add_child(_end_turn_button)

	# 逃跑按钮
	_flee_button = Button.new()
	_flee_button.text = "逃跑（-1 HP）"
	_flee_button.position = Vector2(244, 310)
	_flee_button.size = Vector2(220, 36)
	_flee_button.add_theme_font_size_override("font_size", 14)
	_flee_button.pressed.connect(_on_flee_pressed)
	_flee_button.disabled = true
	add_child(_flee_button)
