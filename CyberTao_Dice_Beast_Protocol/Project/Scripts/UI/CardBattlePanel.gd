extends Panel
class_name CardBattlePanel

## 最小卡牌战斗面板：遭遇触发后进入，玩家选牌 → 敌方行动 → 结算 → 回到棋盘
## Day 9 原型：固定 5 张手牌，敌方每回合固定攻击

signal battle_ended(victory: bool, player_hp_remaining: int)

# --- 战斗状态 ---
var _player_hp: int = 0
var _player_max_hp: int = 0
var _enemy_hp: int = 0
var _enemy_max_hp: int = 0
var _enemy_atk: int = 2
var _enemy_name: String = ""
var _def_bonus: int = 0  # 防御牌本回合减伤
var _battle_turn: int = 0
var _is_active: bool = false
var _encounter_id: String = ""

# --- UI 引用 ---
var _title_label: Label
var _enemy_hp_label: Label
var _player_hp_label: Label
var _log_label: Label
var _turn_label: Label
var _card_buttons: Array[Button] = []
var _flee_button: Button

# --- 手牌定义 ---
# type: "attack" | "defend" | "heal"
var _hand: Array[Dictionary] = []

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(420, 400)
	size = Vector2(420, 400)
	_build_ui()

func start_battle(encounter_id: String, enemy_name: String, enemy_hp: int, enemy_atk: int, player_hp: int, player_max_hp: int) -> void:
	_encounter_id = encounter_id
	_enemy_name = enemy_name
	_enemy_hp = enemy_hp
	_enemy_max_hp = enemy_hp
	_enemy_atk = enemy_atk
	_player_hp = player_hp
	_player_max_hp = player_max_hp
	_def_bonus = 0
	_battle_turn = 1
	_is_active = true
	_build_hand()
	_refresh_ui()
	_log_label.text = "遭遇 " + _enemy_name + "！选择手牌出击。"
	visible = true

func _build_hand() -> void:
	_hand = [
		{"name": "斩击", "type": "attack", "value": 3, "desc": "造成 3 点伤害"},
		{"name": "重击", "type": "attack", "value": 5, "desc": "造成 5 点伤害"},
		{"name": "防御", "type": "defend", "value": 2, "desc": "本回合减伤 2"},
		{"name": "修复", "type": "heal", "value": 2, "desc": "回复 2 HP"},
		{"name": "连斩", "type": "attack", "value": 2, "desc": "造成 2 点伤害"},
	]

func _play_card(index: int) -> void:
	if not _is_active or index < 0 or index >= _hand.size():
		return
	var card: Dictionary = _hand[index]
	var effect_text: String = ""
	# 重置上回合防御加成
	_def_bonus = 0
	match card["type"]:
		"attack":
			var dmg: int = card["value"]
			_enemy_hp = max(0, _enemy_hp - dmg)
			effect_text = card["name"] + " → 对 " + _enemy_name + " 造成 " + str(dmg) + " 伤害"
		"defend":
			_def_bonus = card["value"]
			effect_text = card["name"] + " → 防御 +" + str(card["value"])
		"heal":
			var actual: int = min(card["value"], _player_max_hp - _player_hp)
			_player_hp = min(_player_max_hp, _player_hp + card["value"])
			effect_text = card["name"] + " → 回复 " + str(actual) + " HP"
	# 检查敌方是否被击杀
	if _enemy_hp <= 0:
		_is_active = false
		_log_label.text = effect_text + "\n胜利！" + _enemy_name + " 被消灭。"
		_set_cards_disabled(true)
		_refresh_ui()
		# 延迟返回棋盘
		await get_tree().create_timer(1.2).timeout
		visible = false
		emit_signal("battle_ended", true, _player_hp)
		return
	# 敌方行动
	var enemy_text: String = _enemy_act()
	_battle_turn += 1
	_log_label.text = effect_text + "\n" + enemy_text
	_refresh_ui()
	# 检查玩家是否被击杀
	if _player_hp <= 0:
		_is_active = false
		_log_label.text = _log_label.text + "\n败北..."
		_set_cards_disabled(true)
		await get_tree().create_timer(1.2).timeout
		visible = false
		emit_signal("battle_ended", false, 0)

func _enemy_act() -> String:
	var actual_dmg: int = max(1, _enemy_atk - _def_bonus)
	_player_hp = max(0, _player_hp - actual_dmg)
	var text: String = _enemy_name + " 攻击 → " + str(actual_dmg) + " 伤害"
	if _def_bonus > 0:
		text += "（已减免）"
	return text

func _on_flee_pressed() -> void:
	if not _is_active:
		return
	_is_active = false
	_log_label.text = "逃跑！受到 1 点惩罚伤害。"
	_player_hp = max(0, _player_hp - 1)
	_set_cards_disabled(true)
	_refresh_ui()
	await get_tree().create_timer(0.8).timeout
	visible = false
	emit_signal("battle_ended", false, _player_hp)

func _refresh_ui() -> void:
	_title_label.text = "卡牌战斗 — " + _enemy_name
	_enemy_hp_label.text = "敌方 HP：" + str(_enemy_hp) + " / " + str(_enemy_max_hp)
	_player_hp_label.text = "我方 HP：" + str(_player_hp) + " / " + str(_player_max_hp)
	_turn_label.text = "回合 " + str(_battle_turn)
	# 更新 HP 颜色
	if _enemy_hp <= _enemy_max_hp * 0.3:
		_enemy_hp_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	else:
		_enemy_hp_label.add_theme_color_override("font_color", Color(0.95, 0.5, 0.35))
	if _player_hp <= _player_max_hp * 0.3:
		_player_hp_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		_player_hp_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.7))

func _set_cards_disabled(disabled: bool) -> void:
	for btn in _card_buttons:
		btn.disabled = disabled
	_flee_button.disabled = disabled

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

	# 战斗日志
	_log_label = Label.new()
	_log_label.text = ""
	_log_label.position = Vector2(20, 102)
	_log_label.size = Vector2(380, 68)
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.add_theme_font_size_override("font_size", 14)
	_log_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.75))
	add_child(_log_label)

	# 手牌按钮区域（5 张）
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
		btn.pressed.connect(func(): _play_card(idx))
		add_child(btn)
		_card_buttons.append(btn)

	# 手牌说明
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

	# 逃跑按钮
	_flee_button = Button.new()
	_flee_button.text = "逃跑（-1 HP）"
	_flee_button.position = Vector2(20, 346)
	_flee_button.size = Vector2(380, 38)
	_flee_button.add_theme_font_size_override("font_size", 14)
	_flee_button.pressed.connect(_on_flee_pressed)
	add_child(_flee_button)
