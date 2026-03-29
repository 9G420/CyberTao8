extends Panel
class_name DiceDebugPanel

signal test_card_battle_requested

var battle_flow: Node = null
var dice_manager: Node = null
var _selected_unit_id_cache: String = ""
var phase_label: Label
var round_label: Label
var selected_label: Label
var roll_label: Label
var crest_label: RichTextLabel
var enemy_intent_label: Label
var roll_button: Button
var end_turn_button: Button
var encounter_panel: Panel
var encounter_title_label: Label
var encounter_resolve_button: Button

func _ready() -> void:
	custom_minimum_size = Vector2(280, 540)
	size = Vector2(280, 540)
	_build_ui()

func bind_battle_flow(next_battle_flow: Node) -> void:
	battle_flow = next_battle_flow
	if battle_flow == null:
		return
	dice_manager = battle_flow.dice_manager
	if battle_flow.phase_changed and not battle_flow.phase_changed.is_connected(_on_phase_changed):
		battle_flow.phase_changed.connect(_on_phase_changed)
	if dice_manager and dice_manager.dice_rolled and not dice_manager.dice_rolled.is_connected(_on_dice_rolled):
		dice_manager.dice_rolled.connect(_on_dice_rolled)
	if battle_flow.move_completed and not battle_flow.move_completed.is_connected(_on_move_completed):
		battle_flow.move_completed.connect(_on_move_completed)
	if battle_flow.round_changed and not battle_flow.round_changed.is_connected(_on_round_changed):
		battle_flow.round_changed.connect(_on_round_changed)
	if battle_flow.attack_completed and not battle_flow.attack_completed.is_connected(_on_attack_completed):
		battle_flow.attack_completed.connect(_on_attack_completed)
	if battle_flow.enemy_attack_completed and not battle_flow.enemy_attack_completed.is_connected(_on_enemy_attack_completed):
		battle_flow.enemy_attack_completed.connect(_on_enemy_attack_completed)
	if battle_flow.summon_completed and not battle_flow.summon_completed.is_connected(_on_summon_completed):
		battle_flow.summon_completed.connect(_on_summon_completed)
	if battle_flow.terrain_damage_triggered and not battle_flow.terrain_damage_triggered.is_connected(_on_terrain_damage_triggered):
		battle_flow.terrain_damage_triggered.connect(_on_terrain_damage_triggered)
	if battle_flow.item_picked_up and not battle_flow.item_picked_up.is_connected(_on_item_picked_up):
		battle_flow.item_picked_up.connect(_on_item_picked_up)
	if battle_flow.enemy_action_announced and not battle_flow.enemy_action_announced.is_connected(_on_enemy_action_announced):
		battle_flow.enemy_action_announced.connect(_on_enemy_action_announced)
	if battle_flow.enemy_turn_ended and not battle_flow.enemy_turn_ended.is_connected(_on_enemy_turn_ended):
		battle_flow.enemy_turn_ended.connect(_on_enemy_turn_ended)
	if battle_flow.encounter_triggered and not battle_flow.encounter_triggered.is_connected(_on_encounter_triggered):
		battle_flow.encounter_triggered.connect(_on_encounter_triggered)
	if battle_flow.encounter_resolved and not battle_flow.encounter_resolved.is_connected(_on_encounter_resolved):
		battle_flow.encounter_resolved.connect(_on_encounter_resolved)
	if battle_flow.heal_cell_triggered and not battle_flow.heal_cell_triggered.is_connected(_on_heal_cell_triggered):
		battle_flow.heal_cell_triggered.connect(_on_heal_cell_triggered)
	if battle_flow.event_cell_triggered and not battle_flow.event_cell_triggered.is_connected(_on_event_cell_triggered):
		battle_flow.event_cell_triggered.connect(_on_event_cell_triggered)
	round_label.text = "回合：" + str(battle_flow.round_index)
	_refresh_crest_pool()

func bind_board_view(board_view: Node) -> void:
	if board_view == null:
		return
	if board_view.unit_selected and not board_view.unit_selected.is_connected(_on_unit_selected):
		board_view.unit_selected.connect(_on_unit_selected)
	if board_view.unit_deselected and not board_view.unit_deselected.is_connected(_on_unit_deselected):
		board_view.unit_deselected.connect(_on_unit_deselected)

func _build_ui() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.09, 0.11, 0.16, 0.95)
	bg.border_color = Color(1.0, 0.55, 0.25, 0.7)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", bg)

	var title := Label.new()
	title.text = "战斗调试"
	title.position = Vector2(0, 10)
	title.size = Vector2(280, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.6))
	add_child(title)

	round_label = Label.new()
	round_label.text = "回合：1"
	round_label.position = Vector2(20, 42)
	round_label.size = Vector2(240, 22)
	round_label.add_theme_font_size_override("font_size", 16)
	round_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	add_child(round_label)

	phase_label = Label.new()
	phase_label.text = "阶段：玩家掷骰"
	phase_label.position = Vector2(20, 64)
	phase_label.size = Vector2(240, 22)
	phase_label.add_theme_font_size_override("font_size", 15)
	phase_label.add_theme_color_override("font_color", Color(0.72, 0.9, 0.84))
	add_child(phase_label)

	selected_label = Label.new()
	selected_label.text = "选中：无"
	selected_label.position = Vector2(20, 86)
	selected_label.size = Vector2(240, 22)
	selected_label.add_theme_font_size_override("font_size", 14)
	selected_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	add_child(selected_label)

	roll_button = Button.new()
	roll_button.text = "掷骰"
	roll_button.position = Vector2(20, 116)
	roll_button.size = Vector2(240, 40)
	roll_button.pressed.connect(_on_roll_pressed)
	add_child(roll_button)

	end_turn_button = Button.new()
	end_turn_button.text = "结束回合"
	end_turn_button.position = Vector2(20, 162)
	end_turn_button.size = Vector2(240, 40)
	end_turn_button.disabled = true
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	add_child(end_turn_button)

	var path_button := Button.new()
	path_button.text = "测试召唤（需选中单位+显化）"
	path_button.position = Vector2(20, 210)
	path_button.size = Vector2(240, 36)
	path_button.add_theme_font_size_override("font_size", 12)
	path_button.pressed.connect(_on_spawn_path_pressed)
	add_child(path_button)

	var card_test_button := Button.new()
	card_test_button.text = "测试卡牌战斗"
	card_test_button.position = Vector2(20, 250)
	card_test_button.size = Vector2(240, 36)
	card_test_button.add_theme_font_size_override("font_size", 13)
	card_test_button.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	card_test_button.pressed.connect(_on_test_card_battle_pressed)
	add_child(card_test_button)

	roll_label = Label.new()
	roll_label.text = "上次掷骰：-"
	roll_label.position = Vector2(20, 294)
	roll_label.size = Vector2(240, 44)
	roll_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	roll_label.add_theme_font_size_override("font_size", 14)
	roll_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.72))
	add_child(roll_label)

	crest_label = RichTextLabel.new()
	crest_label.position = Vector2(20, 342)
	crest_label.size = Vector2(240, 140)
	crest_label.scroll_active = false
	crest_label.add_theme_font_size_override("normal_font_size", 14)
	add_child(crest_label)

	enemy_intent_label = Label.new()
	enemy_intent_label.text = ""
	enemy_intent_label.position = Vector2(20, 488)
	enemy_intent_label.size = Vector2(240, 40)
	enemy_intent_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_intent_label.add_theme_font_size_override("font_size", 14)
	enemy_intent_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.25))
	add_child(enemy_intent_label)

	# 遭遇战斗占位面板（默认隐藏）
	encounter_panel = Panel.new()
	encounter_panel.position = Vector2(10, 116)
	encounter_panel.size = Vector2(260, 140)
	encounter_panel.visible = false
	var enc_bg := StyleBoxFlat.new()
	enc_bg.bg_color = Color(0.15, 0.08, 0.05, 0.95)
	enc_bg.border_color = Color(1.0, 0.4, 0.15, 0.9)
	enc_bg.set_border_width_all(2)
	enc_bg.set_corner_radius_all(6)
	encounter_panel.add_theme_stylebox_override("panel", enc_bg)
	add_child(encounter_panel)

	encounter_title_label = Label.new()
	encounter_title_label.text = ""
	encounter_title_label.position = Vector2(10, 12)
	encounter_title_label.size = Vector2(240, 50)
	encounter_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	encounter_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	encounter_title_label.add_theme_font_size_override("font_size", 18)
	encounter_title_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))
	encounter_panel.add_child(encounter_title_label)

	encounter_resolve_button = Button.new()
	encounter_resolve_button.text = "卡牌战斗进行中..."
	encounter_resolve_button.position = Vector2(30, 80)
	encounter_resolve_button.size = Vector2(200, 44)
	encounter_resolve_button.add_theme_font_size_override("font_size", 16)
	encounter_resolve_button.disabled = true
	encounter_panel.add_child(encounter_resolve_button)

func _on_roll_pressed() -> void:
	if battle_flow:
		battle_flow.start_player_roll()

func _on_end_turn_pressed() -> void:
	if battle_flow:
		battle_flow.end_player_turn()

func _on_spawn_path_pressed() -> void:
	if battle_flow == null:
		return
	# 需要选中一个玩家单位才能召唤
	if _selected_unit_id_cache == "":
		return
	var summon_cells: Array[Vector2i] = battle_flow.get_summon_cells_for(_selected_unit_id_cache)
	if summon_cells.is_empty():
		return
	# 选第一个可用格进行召唤
	battle_flow.try_summon(_selected_unit_id_cache, summon_cells[0])

func _on_test_card_battle_pressed() -> void:
	test_card_battle_requested.emit()

func _on_phase_changed(phase_name: String) -> void:
	phase_label.text = "阶段：" + _phase_label_text(phase_name)
	var is_terminal: bool = phase_name == "VICTORY" or phase_name == "DEFEAT"
	if is_terminal:
		roll_button.disabled = true
		end_turn_button.disabled = true
		enemy_intent_label.text = ""
		encounter_panel.visible = false
		if phase_name == "VICTORY":
			phase_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
		else:
			phase_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	elif phase_name == "ENCOUNTER":
		# 遭遇暂停状态：禁用所有常规按钮，显示遭遇面板
		roll_button.disabled = true
		end_turn_button.disabled = true
		phase_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.15))
	else:
		phase_label.add_theme_color_override("font_color", Color(0.72, 0.9, 0.84))
		roll_button.disabled = phase_name != "PLAYER_ROLL"
		end_turn_button.disabled = phase_name != "PLAYER_ACTION"
		encounter_panel.visible = false
		# 进入玩家阶段时清空敌方意图
		if phase_name == "PLAYER_ROLL" or phase_name == "PLAYER_ACTION":
			enemy_intent_label.text = ""
	_refresh_crest_pool()

func _on_round_changed(round_number: int) -> void:
	round_label.text = "回合：" + str(round_number)

func _on_dice_rolled(results: Array[String], next_crest_pool: Dictionary) -> void:
	roll_label.text = "上次掷骰：" + ", ".join(results)
	_refresh_crest_pool(next_crest_pool)

func _on_unit_selected(unit_id: String) -> void:
	selected_label.text = "选中：" + unit_id
	_selected_unit_id_cache = unit_id

func _on_unit_deselected() -> void:
	selected_label.text = "选中：无"
	_selected_unit_id_cache = ""

func _on_move_completed(_unit_id: String, _from_cell: Vector2i, _to_cell: Vector2i) -> void:
	_refresh_crest_pool()

func _on_attack_completed(_attacker_id: String, _defender_id: String, _damage: int, _killed: bool) -> void:
	_refresh_crest_pool()

func _on_enemy_attack_completed(_attacker_id: String, _defender_id: String, _damage: int, _killed: bool, _target_cell: Vector2i) -> void:
	_refresh_crest_pool()

func _on_summon_completed(_unit_id: String, _path_cells: Array[Vector2i], _spawn_cell: Vector2i) -> void:
	_refresh_crest_pool()

func _on_terrain_damage_triggered(_unit_id: String, _cell: Vector2i, _damage: int, _terrain_type: String) -> void:
	_refresh_crest_pool()

func _on_item_picked_up(_unit_id: String, _item_id: String, _effect_text: String, _cell: Vector2i) -> void:
	_refresh_crest_pool()

func _on_enemy_action_announced(_unit_id: String, _action_type: String, detail: String) -> void:
	enemy_intent_label.text = detail

func _on_enemy_turn_ended() -> void:
	enemy_intent_label.text = "敌方回合结束"

func _on_encounter_triggered(_unit_id: String, encounter_id: String, _cell: Vector2i) -> void:
	enemy_intent_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.15))
	enemy_intent_label.text = "遭遇！准备进入战斗... [" + encounter_id + "]"
	# 显示遭遇战斗占位面板
	encounter_title_label.text = "战斗开始\n[" + encounter_id + "]"
	encounter_panel.visible = true

func _on_encounter_resolved(_encounter_id: String, _cell: Vector2i) -> void:
	encounter_panel.visible = false
	enemy_intent_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	enemy_intent_label.text = "遭遇已清除，继续行动"

func _on_heal_cell_triggered(_unit_id: String, _cell: Vector2i, _heal_amount: int, _actual_heal: int) -> void:
	_refresh_crest_pool()

func _on_event_cell_triggered(_unit_id: String, _cell: Vector2i, _event_id: String, _effect_text: String) -> void:
	_refresh_crest_pool()

func _refresh_crest_pool(next_crest_pool: Dictionary = {}) -> void:
	var pool: Dictionary = next_crest_pool
	if pool.is_empty() and dice_manager:
		pool = dice_manager.crest_pool
	crest_label.clear()
	crest_label.append_text("显化：" + str(pool.get("summon", 0)) + "\n")
	crest_label.append_text("步进：" + str(pool.get("move", 0)) + "\n")
	crest_label.append_text("杀伐：" + str(pool.get("attack", 0)) + "\n")
	crest_label.append_text("护持：" + str(pool.get("defend", 0)) + "\n")
	crest_label.append_text("术式：" + str(pool.get("skill", 0)) + "\n")
	crest_label.append_text("机巧：" + str(pool.get("trick", 0)) + "\n")

func _phase_label_text(phase_name: String) -> String:
	match phase_name:
		"PLAYER_ROLL":
			return "玩家掷骰"
		"PLAYER_ACTION":
			return "玩家行动"
		"ENCOUNTER":
			return "遭遇战斗"
		"ENEMY_ROLL":
			return "敌方掷骰"
		"ENEMY_ACTION":
			return "敌方行动"
		"VICTORY":
			return "胜利"
		"DEFEAT":
			return "失败"
	return phase_name
