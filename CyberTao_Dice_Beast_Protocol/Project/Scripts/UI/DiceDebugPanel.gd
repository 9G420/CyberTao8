extends Panel
class_name DiceDebugPanel

signal test_card_battle_requested
signal deck_view_requested

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
var floor_label: Label
var encounter_panel: Panel
var encounter_title_label: Label
var encounter_resolve_button: Button

func _ready() -> void:
	custom_minimum_size = Vector2(280, 574)
	size = Vector2(280, 574)
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
	if battle_flow.shop_cell_triggered and not battle_flow.shop_cell_triggered.is_connected(_on_shop_cell_triggered):
		battle_flow.shop_cell_triggered.connect(_on_shop_cell_triggered)
	if battle_flow.chest_cell_triggered and not battle_flow.chest_cell_triggered.is_connected(_on_chest_cell_triggered):
		battle_flow.chest_cell_triggered.connect(_on_chest_cell_triggered)
	if battle_flow.floor_cleared and not battle_flow.floor_cleared.is_connected(_on_floor_cleared):
		battle_flow.floor_cleared.connect(_on_floor_cleared)
	# BuffManager 信号
	if battle_flow.buff_manager:
		if battle_flow.buff_manager.buff_applied and not battle_flow.buff_manager.buff_applied.is_connected(_on_buff_applied):
			battle_flow.buff_manager.buff_applied.connect(_on_buff_applied)
		if battle_flow.buff_manager.buff_expired and not battle_flow.buff_manager.buff_expired.is_connected(_on_buff_expired):
			battle_flow.buff_manager.buff_expired.connect(_on_buff_expired)
	round_label.text = "回合：" + str(battle_flow.round_index)
	floor_label.text = "层数：" + str(battle_flow.current_floor) + "/" + str(battle_flow.get_max_floor())
	_refresh_crest_pool()

func bind_board_view(board_view: Node) -> void:
	if board_view == null:
		return
	if board_view.unit_selected and not board_view.unit_selected.is_connected(_on_unit_selected):
		board_view.unit_selected.connect(_on_unit_selected)
	if board_view.unit_deselected and not board_view.unit_deselected.is_connected(_on_unit_deselected):
		board_view.unit_deselected.connect(_on_unit_deselected)

func _build_ui() -> void:
	# --- 面板背景 ---
	add_theme_stylebox_override("panel", CyberStyle.make_panel_bg(CyberStyle.BORDER_CYAN, 8))

	# --- 分隔线辅助 ---
	var sep1 := ColorRect.new()
	sep1.position = Vector2(16, 38)
	sep1.size = Vector2(248, 1)
	sep1.color = Color(0.0, 0.7, 0.9, 0.25)
	sep1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep1)

	# --- 标题 ---
	var title := Label.new()
	title.text = "骰兽协议"
	title.position = Vector2(0, 8)
	title.size = Vector2(280, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", CyberStyle.TEXT_TITLE)
	add_child(title)

	# --- 回合 + 阶段 + 选中 ---
	round_label = Label.new()
	round_label.text = "回合：1"
	round_label.position = Vector2(20, 44)
	round_label.size = Vector2(80, 20)
	round_label.add_theme_font_size_override("font_size", 14)
	round_label.add_theme_color_override("font_color", CyberStyle.ACCENT_ORANGE)
	add_child(round_label)

	floor_label = Label.new()
	floor_label.text = "层数：1/3"
	floor_label.position = Vector2(100, 44)
	floor_label.size = Vector2(40, 20)
	floor_label.add_theme_font_size_override("font_size", 14)
	floor_label.add_theme_color_override("font_color", CyberStyle.ACCENT_MAGENTA)
	add_child(floor_label)

	phase_label = Label.new()
	phase_label.text = "阶段：玩家掷骰"
	phase_label.position = Vector2(140, 44)
	phase_label.size = Vector2(130, 20)
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	phase_label.add_theme_font_size_override("font_size", 13)
	phase_label.add_theme_color_override("font_color", CyberStyle.TEXT_CYAN)
	add_child(phase_label)

	selected_label = Label.new()
	selected_label.text = "选中：无"
	selected_label.position = Vector2(20, 66)
	selected_label.size = Vector2(240, 20)
	selected_label.add_theme_font_size_override("font_size", 13)
	selected_label.add_theme_color_override("font_color", CyberStyle.TEXT_SECONDARY)
	add_child(selected_label)

	# --- 分隔线 ---
	var sep2 := ColorRect.new()
	sep2.position = Vector2(16, 88)
	sep2.size = Vector2(248, 1)
	sep2.color = Color(0.0, 0.7, 0.9, 0.15)
	sep2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep2)

	# --- 操作按钮区 ---
	roll_button = Button.new()
	roll_button.text = "掷 骰"
	roll_button.position = Vector2(16, 96)
	roll_button.size = Vector2(248, 38)
	roll_button.add_theme_font_size_override("font_size", 15)
	roll_button.pressed.connect(_on_roll_pressed)
	CyberStyle.style_button(roll_button, "orange")
	add_child(roll_button)

	end_turn_button = Button.new()
	end_turn_button.text = "结束回合"
	end_turn_button.position = Vector2(16, 140)
	end_turn_button.size = Vector2(248, 36)
	end_turn_button.add_theme_font_size_override("font_size", 14)
	end_turn_button.disabled = true
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	CyberStyle.style_button(end_turn_button, "cyan")
	add_child(end_turn_button)

	var path_button := Button.new()
	path_button.text = "召唤（需选中+显化）"
	path_button.position = Vector2(16, 182)
	path_button.size = Vector2(248, 32)
	path_button.add_theme_font_size_override("font_size", 12)
	path_button.pressed.connect(_on_spawn_path_pressed)
	CyberStyle.style_button(path_button, "cyan")
	add_child(path_button)

	var card_test_button := Button.new()
	card_test_button.text = "测试战斗"
	card_test_button.position = Vector2(16, 218)
	card_test_button.size = Vector2(120, 32)
	card_test_button.add_theme_font_size_override("font_size", 12)
	card_test_button.pressed.connect(_on_test_card_battle_pressed)
	CyberStyle.style_button(card_test_button, "orange")
	add_child(card_test_button)

	var deck_view_button := Button.new()
	deck_view_button.text = "查看牌组"
	deck_view_button.position = Vector2(142, 218)
	deck_view_button.size = Vector2(122, 32)
	deck_view_button.add_theme_font_size_override("font_size", 12)
	deck_view_button.pressed.connect(_on_deck_view_pressed)
	CyberStyle.style_button(deck_view_button, "cyan")
	add_child(deck_view_button)

	# --- Crest 使用按钮（护持/术式/机巧） ---
	var defend_btn := Button.new()
	defend_btn.text = "护持(DEF+1)"
	defend_btn.position = Vector2(16, 256)
	defend_btn.size = Vector2(78, 28)
	defend_btn.add_theme_font_size_override("font_size", 10)
	defend_btn.pressed.connect(_on_defend_crest_pressed)
	CyberStyle.style_button(defend_btn, "orange")
	add_child(defend_btn)

	var skill_btn := Button.new()
	skill_btn.text = "术式(HP+2)"
	skill_btn.position = Vector2(100, 256)
	skill_btn.size = Vector2(78, 28)
	skill_btn.add_theme_font_size_override("font_size", 10)
	skill_btn.pressed.connect(_on_skill_crest_pressed)
	CyberStyle.style_button(skill_btn, "cyan")
	add_child(skill_btn)

	var trick_btn := Button.new()
	trick_btn.text = "机巧(转化)"
	trick_btn.position = Vector2(184, 256)
	trick_btn.size = Vector2(80, 28)
	trick_btn.add_theme_font_size_override("font_size", 10)
	trick_btn.pressed.connect(_on_trick_crest_pressed)
	CyberStyle.style_button(trick_btn, "cyan")
	add_child(trick_btn)

	# --- 分隔线 ---
	var sep3 := ColorRect.new()
	sep3.position = Vector2(16, 290)
	sep3.size = Vector2(248, 1)
	sep3.color = Color(0.0, 0.7, 0.9, 0.15)
	sep3.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep3)

	# --- 掷骰结果 ---
	roll_label = Label.new()
	roll_label.text = "上次掷骰：-"
	roll_label.position = Vector2(16, 296)
	roll_label.size = Vector2(248, 40)
	roll_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	roll_label.add_theme_font_size_override("font_size", 13)
	roll_label.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY)
	add_child(roll_label)

	# --- Crest 资源池 ---
	crest_label = RichTextLabel.new()
	crest_label.position = Vector2(16, 340)
	crest_label.size = Vector2(248, 140)
	crest_label.scroll_active = false
	crest_label.add_theme_font_size_override("normal_font_size", 13)
	add_child(crest_label)

	# --- 敌方意图 ---
	enemy_intent_label = Label.new()
	enemy_intent_label.text = ""
	enemy_intent_label.position = Vector2(16, 486)
	enemy_intent_label.size = Vector2(248, 40)
	enemy_intent_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_intent_label.add_theme_font_size_override("font_size", 13)
	enemy_intent_label.add_theme_color_override("font_color", CyberStyle.ACCENT_ORANGE)
	add_child(enemy_intent_label)

	# --- 版本标记 ---
	var ver_label := Label.new()
	ver_label.text = "v0.1.44"
	ver_label.position = Vector2(210, 554)
	ver_label.size = Vector2(60, 16)
	ver_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ver_label.add_theme_font_size_override("font_size", 10)
	ver_label.add_theme_color_override("font_color", CyberStyle.TEXT_MUTED)
	add_child(ver_label)

	# --- 遭遇战斗占位面板（默认隐藏） ---
	encounter_panel = Panel.new()
	encounter_panel.position = Vector2(8, 96)
	encounter_panel.size = Vector2(264, 140)
	encounter_panel.visible = false
	encounter_panel.add_theme_stylebox_override("panel", CyberStyle.make_encounter_panel_bg())
	add_child(encounter_panel)

	encounter_title_label = Label.new()
	encounter_title_label.text = ""
	encounter_title_label.position = Vector2(10, 12)
	encounter_title_label.size = Vector2(244, 50)
	encounter_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	encounter_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	encounter_title_label.add_theme_font_size_override("font_size", 17)
	encounter_title_label.add_theme_color_override("font_color", CyberStyle.ACCENT_ORANGE)
	encounter_panel.add_child(encounter_title_label)

	encounter_resolve_button = Button.new()
	encounter_resolve_button.text = "卡牌战斗进行中..."
	encounter_resolve_button.position = Vector2(22, 80)
	encounter_resolve_button.size = Vector2(220, 42)
	encounter_resolve_button.add_theme_font_size_override("font_size", 15)
	encounter_resolve_button.disabled = true
	CyberStyle.style_button(encounter_resolve_button, "orange")
	encounter_panel.add_child(encounter_resolve_button)

# --- 按钮回调 ---

func _on_roll_pressed() -> void:
	if battle_flow:
		battle_flow.start_player_roll()

func _on_end_turn_pressed() -> void:
	if battle_flow:
		battle_flow.end_player_turn()

func _on_spawn_path_pressed() -> void:
	if battle_flow == null:
		return
	if _selected_unit_id_cache == "":
		return
	var summon_cells: Array[Vector2i] = battle_flow.get_summon_cells_for(_selected_unit_id_cache)
	if summon_cells.is_empty():
		return
	battle_flow.try_summon(_selected_unit_id_cache, summon_cells[0])

func _on_test_card_battle_pressed() -> void:
	test_card_battle_requested.emit()

func _on_deck_view_pressed() -> void:
	deck_view_requested.emit()

func _on_defend_crest_pressed() -> void:
	if battle_flow and _selected_unit_id_cache != "":
		battle_flow.try_use_defend_crest(_selected_unit_id_cache)

func _on_skill_crest_pressed() -> void:
	if battle_flow and _selected_unit_id_cache != "":
		battle_flow.try_use_skill_crest(_selected_unit_id_cache)

func _on_trick_crest_pressed() -> void:
	if battle_flow:
		battle_flow.try_use_trick_crest()

# --- 信号回调 ---

func _on_phase_changed(phase_name: String) -> void:
	phase_label.text = _phase_label_text(phase_name)
	var is_terminal: bool = phase_name == "VICTORY" or phase_name == "DEFEAT"
	if is_terminal:
		roll_button.disabled = true
		end_turn_button.disabled = true
		enemy_intent_label.text = ""
		encounter_panel.visible = false
		if phase_name == "VICTORY":
			phase_label.add_theme_color_override("font_color", CyberStyle.TEXT_SUCCESS)
		else:
			phase_label.add_theme_color_override("font_color", CyberStyle.TEXT_WARN)
	elif phase_name == "FLOOR_CLEAR":
		roll_button.disabled = true
		end_turn_button.disabled = true
		enemy_intent_label.add_theme_color_override("font_color", CyberStyle.TEXT_SUCCESS)
		enemy_intent_label.text = "本层通关！选择奖励后进入下一层"
		encounter_panel.visible = false
		phase_label.add_theme_color_override("font_color", CyberStyle.TEXT_SUCCESS)
	elif phase_name == "ENCOUNTER":
		roll_button.disabled = true
		end_turn_button.disabled = true
		phase_label.add_theme_color_override("font_color", CyberStyle.ACCENT_ORANGE)
	else:
		phase_label.add_theme_color_override("font_color", CyberStyle.TEXT_CYAN)
		roll_button.disabled = phase_name != "PLAYER_ROLL"
		end_turn_button.disabled = phase_name != "PLAYER_ACTION"
		encounter_panel.visible = false
		if phase_name == "PLAYER_ROLL" or phase_name == "PLAYER_ACTION":
			enemy_intent_label.text = ""
		# 刷新层数显示（进入新层后更新）
		if battle_flow:
			floor_label.text = "层数：" + str(battle_flow.current_floor) + "/" + str(battle_flow.get_max_floor())
	_refresh_crest_pool()

func _on_round_changed(round_number: int) -> void:
	round_label.text = "回合：" + str(round_number)
	if battle_flow:
		floor_label.text = "层数：" + str(battle_flow.current_floor) + "/" + str(battle_flow.get_max_floor())

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
	enemy_intent_label.add_theme_color_override("font_color", CyberStyle.ACCENT_ORANGE)
	enemy_intent_label.text = "遭遇！准备进入战斗... [" + encounter_id + "]"
	encounter_title_label.text = "战斗开始\n[" + encounter_id + "]"
	encounter_panel.visible = true

func _on_encounter_resolved(_encounter_id: String, _cell: Vector2i) -> void:
	encounter_panel.visible = false
	enemy_intent_label.add_theme_color_override("font_color", CyberStyle.TEXT_SUCCESS)
	enemy_intent_label.text = "遭遇已清除，继续行动"

func _on_heal_cell_triggered(_unit_id: String, _cell: Vector2i, _heal_amount: int, _actual_heal: int) -> void:
	_refresh_crest_pool()

func _on_event_cell_triggered(_unit_id: String, _cell: Vector2i, _event_id: String, _effect_text: String) -> void:
	_refresh_crest_pool()

func _on_shop_cell_triggered(_unit_id: String, _cell: Vector2i, _cost_crest: String, _actual_heal: int) -> void:
	_refresh_crest_pool()

func _on_chest_cell_triggered(_unit_id: String, _cell: Vector2i, _effect_text: String) -> void:
	_refresh_crest_pool()

func _on_floor_cleared(floor_number: int) -> void:
	floor_label.text = "层数：" + str(floor_number) + "/" + str(battle_flow.get_max_floor()) if battle_flow else ""

func _on_buff_applied(_unit_id: String, buff_type: String, _value: int, duration: int) -> void:
	var label: String = ""
	match buff_type:
		"atk_up":
			label = "ATK增强"
		"def_up":
			label = "DEF增强"
		"atk_down":
			label = "ATK削弱"
		"def_down":
			label = "DEF削弱"
		_:
			label = buff_type
	enemy_intent_label.add_theme_color_override("font_color", CyberStyle.ACCENT_CYAN)
	enemy_intent_label.text = "Buff获得：" + label + "（" + str(duration) + "回合）"

func _on_buff_expired(_unit_id: String, buff_type: String) -> void:
	var label: String = ""
	match buff_type:
		"atk_up":
			label = "ATK增强"
		"def_up":
			label = "DEF增强"
		"atk_down":
			label = "ATK削弱"
		"def_down":
			label = "DEF削弱"
		_:
			label = buff_type
	enemy_intent_label.add_theme_color_override("font_color", CyberStyle.TEXT_WARN)
	enemy_intent_label.text = "Buff消失：" + label

func _refresh_crest_pool(next_crest_pool: Dictionary = {}) -> void:
	var pool: Dictionary = next_crest_pool
	if pool.is_empty() and dice_manager:
		pool = dice_manager.crest_pool
	crest_label.clear()
	# 使用 BBCode 上色
	crest_label.push_color(CyberStyle.ACCENT_CYAN)
	crest_label.append_text("显化")
	crest_label.pop()
	crest_label.append_text("：" + str(pool.get("summon", 0)) + "  ")
	crest_label.push_color(CyberStyle.ACCENT_CYAN)
	crest_label.append_text("步进")
	crest_label.pop()
	crest_label.append_text("：" + str(pool.get("move", 0)) + "\n")
	crest_label.push_color(CyberStyle.ACCENT_ORANGE)
	crest_label.append_text("杀伐")
	crest_label.pop()
	crest_label.append_text("：" + str(pool.get("attack", 0)) + "  ")
	crest_label.push_color(CyberStyle.ACCENT_ORANGE)
	crest_label.append_text("护持")
	crest_label.pop()
	crest_label.append_text("：" + str(pool.get("defend", 0)) + "\n")
	crest_label.push_color(CyberStyle.ACCENT_MAGENTA)
	crest_label.append_text("术式")
	crest_label.pop()
	crest_label.append_text("：" + str(pool.get("skill", 0)) + "  ")
	crest_label.push_color(CyberStyle.ACCENT_MAGENTA)
	crest_label.append_text("机巧")
	crest_label.pop()
	crest_label.append_text("：" + str(pool.get("trick", 0)) + "\n")
	# Buff 摘要（选中单位）
	if _selected_unit_id_cache != "" and battle_flow and battle_flow.buff_manager:
		var buff_text: String = battle_flow.buff_manager.get_buff_summary(_selected_unit_id_cache)
		if buff_text != "":
			crest_label.push_color(CyberStyle.ACCENT_CYAN)
			crest_label.append_text("Buff：")
			crest_label.pop()
			crest_label.append_text(buff_text + "\n")

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
		"FLOOR_CLEAR":
			return "本层通关"
		"VICTORY":
			return "胜利"
		"DEFEAT":
			return "失败"
	return phase_name
