extends Panel
class_name CardBattlePanel

## 卡牌战斗 UI 面板（纯显示层）
## 所有战斗逻辑委托给 CardBattleController，本文件只负责渲染和按钮回调
## 不持有任何战斗状态，仅通过 bind_controller() 绑定信号

const CardBattleController = preload("res://Scripts/BattleV2/CardBattleController.gd")

var _controller: CardBattleController = null

# --- UI 引用 ---
var _title_label: Label
var _enemy_hp_label: Label
var _player_hp_label: Label
var _log_label: Label
var _turn_label: Label
var _card_buttons: Array[Button] = []
var _flee_button: Button

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(420, 400)
	size = Vector2(420, 400)
	_build_ui()

func bind_controller(controller: CardBattleController) -> void:
	_controller = controller
	if _controller.battle_started and not _controller.battle_started.is_connected(_on_battle_started):
		_controller.battle_started.connect(_on_battle_started)
	if _controller.card_played and not _controller.card_played.is_connected(_on_card_played):
		_controller.card_played.connect(_on_card_played)
	if _controller.enemy_acted and not _controller.enemy_acted.is_connected(_on_enemy_acted):
		_controller.enemy_acted.connect(_on_enemy_acted)
	if _controller.turn_resolved and not _controller.turn_resolved.is_connected(_on_turn_resolved):
		_controller.turn_resolved.connect(_on_turn_resolved)
	if _controller.battle_ended and not _controller.battle_ended.is_connected(_on_battle_ended):
		_controller.battle_ended.connect(_on_battle_ended)

# --- 控制器信号回调 ---

func _on_battle_started(player_hp: int, enemy_hp: int, enemy_name: String) -> void:
	_log_label.text = "遭遇 " + enemy_name + "！选择手牌出击。"
	_set_cards_disabled(false)
	_refresh_hp(player_hp, _controller.player_max_hp, enemy_hp, _controller.enemy_max_hp, enemy_name, 1)
	visible = true

func _on_card_played(_card_index: int, _card_name: String, effect_text: String) -> void:
	_log_label.text = effect_text

func _on_enemy_acted(action_text: String) -> void:
	_log_label.text = _log_label.text + "\n" + action_text

func _on_turn_resolved(player_hp: int, enemy_hp: int, battle_turn: int) -> void:
	_refresh_hp(player_hp, _controller.player_max_hp, enemy_hp, _controller.enemy_max_hp, _controller.enemy_name, battle_turn)

func _on_battle_ended(victory: bool, _player_hp_remaining: int) -> void:
	_set_cards_disabled(true)
	if victory:
		_log_label.text = _log_label.text + "\n胜利！" + _controller.enemy_name + " 被消灭。"
	else:
		if _controller.player_hp <= 0:
			_log_label.text = _log_label.text + "\n败北..."
		else:
			_log_label.text = "逃跑！受到 1 点惩罚伤害。"
	# 延迟关闭面板（由 Main.gd 处理 resolve_encounter）
	await get_tree().create_timer(1.2).timeout
	visible = false

# --- 按钮回调（委托给 controller） ---

func _on_card_pressed(index: int) -> void:
	if _controller:
		_controller.play_card(index)

func _on_flee_pressed() -> void:
	if _controller:
		_controller.flee()

# --- UI 刷新 ---

func _refresh_hp(player_hp: int, player_max_hp: int, enemy_hp: int, enemy_max_hp: int, enemy_name: String, battle_turn: int) -> void:
	_title_label.text = "卡牌战斗 — " + enemy_name
	_enemy_hp_label.text = "敌方 HP：" + str(enemy_hp) + " / " + str(enemy_max_hp)
	_player_hp_label.text = "我方 HP：" + str(player_hp) + " / " + str(player_max_hp)
	_turn_label.text = "回合 " + str(battle_turn)
	if enemy_hp <= enemy_max_hp * 0.3:
		_enemy_hp_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	else:
		_enemy_hp_label.add_theme_color_override("font_color", Color(0.95, 0.5, 0.35))
	if player_hp <= player_max_hp * 0.3:
		_player_hp_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		_player_hp_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.7))

func _set_cards_disabled(disabled: bool) -> void:
	for btn in _card_buttons:
		btn.disabled = disabled
	_flee_button.disabled = disabled

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
	_title_label.position = Vector2(0, 10)
	_title_label.size = Vector2(420, 30)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.25))
	add_child(_title_label)

	_turn_label = Label.new()
	_turn_label.text = "回合 1"
	_turn_label.position = Vector2(340, 12)
	_turn_label.size = Vector2(70, 22)
	_turn_label.add_theme_font_size_override("font_size", 13)
	_turn_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
	add_child(_turn_label)

	_enemy_hp_label = Label.new()
	_enemy_hp_label.text = "敌方 HP：0 / 0"
	_enemy_hp_label.position = Vector2(20, 46)
	_enemy_hp_label.size = Vector2(380, 24)
	_enemy_hp_label.add_theme_font_size_override("font_size", 17)
	_enemy_hp_label.add_theme_color_override("font_color", Color(0.95, 0.5, 0.35))
	add_child(_enemy_hp_label)

	_player_hp_label = Label.new()
	_player_hp_label.text = "我方 HP：0 / 0"
	_player_hp_label.position = Vector2(20, 72)
	_player_hp_label.size = Vector2(380, 24)
	_player_hp_label.add_theme_font_size_override("font_size", 17)
	_player_hp_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.7))
	add_child(_player_hp_label)

	_log_label = Label.new()
	_log_label.text = ""
	_log_label.position = Vector2(20, 102)
	_log_label.size = Vector2(380, 68)
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.add_theme_font_size_override("font_size", 14)
	_log_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.75))
	add_child(_log_label)

	var card_names: Array[String] = ["斩击(3)", "重击(5)", "防御(2)", "修复(2)", "连斩(2)"]
	var card_y: float = 178.0
	for i in range(5):
		var btn := Button.new()
		btn.text = card_names[i]
		if i < 3:
			btn.position = Vector2(20 + i * 130, card_y)
		else:
			btn.position = Vector2(20 + (i - 3) * 130 + 65, card_y + 50)
		btn.size = Vector2(120, 42)
		btn.add_theme_font_size_override("font_size", 15)
		var idx: int = i
		btn.pressed.connect(func(): _on_card_pressed(idx))
		add_child(btn)
		_card_buttons.append(btn)

	var desc_labels: Array[String] = ["伤害3", "伤害5", "减伤2", "回复2", "伤害2"]
	for i in range(5):
		var dlbl := Label.new()
		dlbl.text = desc_labels[i]
		var bpos: Vector2 = _card_buttons[i].position
		dlbl.position = Vector2(bpos.x + 20, bpos.y + 42)
		dlbl.size = Vector2(80, 16)
		dlbl.add_theme_font_size_override("font_size", 10)
		dlbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.55))
		add_child(dlbl)

	_flee_button = Button.new()
	_flee_button.text = "逃跑（-1 HP）"
	_flee_button.position = Vector2(20, 346)
	_flee_button.size = Vector2(380, 38)
	_flee_button.add_theme_font_size_override("font_size", 14)
	_flee_button.pressed.connect(_on_flee_pressed)
	add_child(_flee_button)
