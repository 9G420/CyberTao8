extends Control

const BattleFlowController = preload("res://Scripts/BattleV2/BattleFlowController.gd")
const CardBattleController = preload("res://Scripts/BattleV2/CardBattleController.gd")
const BoardView = preload("res://Scripts/UI/BoardView.gd")
const DiceDebugPanel = preload("res://Scripts/UI/DiceDebugPanel.gd")
const DisplaySettings = preload("res://Scripts/System/DisplaySettings.gd")
const SettingsPanel = preload("res://Scripts/UI/SettingsPanel.gd")
const CardBattlePanel = preload("res://Scripts/UI/CardBattlePanel.gd")
const CardRewardPanel = preload("res://Scripts/UI/CardRewardPanel.gd")
const DeckViewPanel = preload("res://Scripts/UI/DeckViewPanel.gd")
const CyberBackground = preload("res://Scripts/UI/CyberBackground.gd")
const TransitionOverlay = preload("res://Scripts/UI/TransitionOverlay.gd")

var _battle_flow: BattleFlowController
var _card_battle_ctrl: CardBattleController
var _board_view: BoardView
var _dice_panel: DiceDebugPanel
var _display_settings: DisplaySettings
var _settings_panel: SettingsPanel
var _card_battle_panel: CardBattlePanel
var _card_reward_panel: CardRewardPanel
var _deck_view_panel: DeckViewPanel
var _result_label: Label
var _restart_btn: Button
var _dice_anim: DiceRollAnimation
var _transition: TransitionOverlay
var _audio: AudioManager
var _last_attack_damage: int = 0
var _last_attack_killed: bool = false
var _floor_clear_pending: bool = false

func _ready() -> void:
	_display_settings = DisplaySettings.new()
	add_child(_display_settings)
	_audio = AudioManager.new()
	add_child(_audio)
	_battle_flow = BattleFlowController.new()
	add_child(_battle_flow)
	_card_battle_ctrl = CardBattleController.new()
	add_child(_card_battle_ctrl)
	_build_debug_view()
	_wire_debug_views()
	# 启动棋盘 BGM
	_audio.play_bgm("bgm_map")

func _build_debug_view() -> void:
	var cyber_bg := CyberBackground.new()
	cyber_bg.set_board_rect(Vector2(40, 94), Vector2(576, 350))
	add_child(cyber_bg)

	var title := Label.new()
	title.text = "CyberTao：骰兽协议"
	title.position = Vector2(0, 4)
	title.size = Vector2(1280, 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", CyberStyle.TEXT_TITLE)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "原型战斗沙盒 — 掷骰 / 移动 / 攻击 / 遭遇 / 卡牌战斗"
	subtitle.position = Vector2(0, 44)
	subtitle.size = Vector2(1280, 22)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", CyberStyle.TEXT_CYAN)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)

	var hint := Label.new()
	hint.text = "青色=移动 红色=攻击 紫色=召唤 | 金色=高台 暗红=陷阱 绿色=道具 橙红=遭遇 深红=BOSS 蓝白=回复 黄紫=事件 青绿=商店 金琥珀=宝箱 | *=适性激活"
	hint.position = Vector2(0, 66)
	hint.size = Vector2(1280, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", CyberStyle.TEXT_SECONDARY)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

	_board_view = BoardView.new()
	_board_view.position = Vector2(40, 94)
	add_child(_board_view)

	_dice_panel = DiceDebugPanel.new()
	_dice_panel.position = Vector2(660, 94)
	add_child(_dice_panel)

	var settings_btn := Button.new()
	settings_btn.text = "设置"
	settings_btn.position = Vector2(1180, 4)
	settings_btn.size = Vector2(80, 32)
	settings_btn.add_theme_font_size_override("font_size", 13)
	settings_btn.pressed.connect(_on_settings_pressed)
	CyberStyle.style_button(settings_btn, "cyan")
	add_child(settings_btn)

	_settings_panel = SettingsPanel.new()
	_settings_panel.position = Vector2(440, 130)
	add_child(_settings_panel)
	_settings_panel.bind_display_settings(_display_settings)

	# 卡牌战斗面板（v0.1.54 全屏独立界面，自带战斗背景）
	_card_battle_panel = CardBattlePanel.new()
	_card_battle_panel.position = Vector2(0, 0)
	add_child(_card_battle_panel)

	_card_reward_panel = CardRewardPanel.new()
	_card_reward_panel.position = Vector2(380, 200)
	add_child(_card_reward_panel)

	_deck_view_panel = DeckViewPanel.new()
	_deck_view_panel.position = Vector2(160, 120)
	add_child(_deck_view_panel)

	_result_label = Label.new()
	_result_label.position = Vector2(0, 44)
	_result_label.size = Vector2(1280, 40)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 32)
	_result_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_label.visible = false
	add_child(_result_label)

	_restart_btn = Button.new()
	_restart_btn.text = "重新开始"
	_restart_btn.position = Vector2(560, 4)
	_restart_btn.size = Vector2(160, 36)
	_restart_btn.add_theme_font_size_override("font_size", 14)
	_restart_btn.visible = false
	_restart_btn.pressed.connect(_on_restart_pressed)
	CyberStyle.style_button(_restart_btn, "orange")
	add_child(_restart_btn)

	# 掷骰演出（全屏居中等距 3D 骰子，覆盖在最上层）
	_dice_anim = DiceRollAnimation.new()
	_dice_anim.set_board_center(Vector2(328, 382))
	add_child(_dice_anim)

	# 百叶窗过渡动画（CanvasLayer 10，覆盖一切）
	_transition = TransitionOverlay.new()
	add_child(_transition)

func _wire_debug_views() -> void:
	_board_view.bind_managers(_battle_flow.board_manager, _battle_flow.unit_manager)
	_board_view.bind_battle_flow(_battle_flow)
	_board_view.move_requested.connect(_on_move_requested)
	_board_view.attack_requested.connect(_on_attack_requested)
	_board_view.summon_requested.connect(_on_summon_requested)
	_battle_flow.phase_changed.connect(_on_phase_changed)
	_battle_flow.attack_completed.connect(_on_attack_completed)
	_battle_flow.enemy_attack_completed.connect(_on_enemy_attack_completed)
	_battle_flow.summon_completed.connect(_on_summon_completed)
	_battle_flow.terrain_damage_triggered.connect(_on_terrain_damage_triggered)
	_battle_flow.item_picked_up.connect(_on_item_picked_up)
	_battle_flow.enemy_action_announced.connect(_on_enemy_action_announced)
	_battle_flow.enemy_turn_ended.connect(_on_enemy_turn_ended)
	_battle_flow.encounter_triggered.connect(_on_encounter_triggered)
	_battle_flow.encounter_resolved.connect(_on_encounter_resolved)
	_battle_flow.heal_cell_triggered.connect(_on_heal_cell_triggered)
	_battle_flow.event_cell_triggered.connect(_on_event_cell_triggered)
	_battle_flow.defend_crest_used.connect(_on_defend_crest_used)
	_battle_flow.skill_crest_used.connect(_on_skill_crest_used)
	_battle_flow.trick_crest_used.connect(_on_trick_crest_used)
	_battle_flow.shop_cell_triggered.connect(_on_shop_cell_triggered)
	_battle_flow.chest_cell_triggered.connect(_on_chest_cell_triggered)
	_battle_flow.floor_cleared.connect(_on_floor_cleared)
	_battle_flow.game_won.connect(_on_game_won)
	_battle_flow.boss_unlocked.connect(_on_boss_unlocked)
	_battle_flow.portal_spawned.connect(_on_portal_spawned)
	_battle_flow.hero_warped.connect(_on_hero_warped)
	# 卡牌战斗控制器信号
	_card_battle_ctrl.battle_ended.connect(_on_card_battle_ended)
	_card_battle_ctrl.victory_reward.connect(_on_card_battle_reward)
	_card_battle_ctrl.card_played.connect(_on_card_played_sfx)
	_card_battle_ctrl.enemy_acted.connect(_on_enemy_acted_sfx)
	_card_battle_ctrl.hand_changed.connect(_on_hand_changed_sfx)
	# 卡牌战斗面板绑定控制器
	_card_battle_panel.bind_controller(_card_battle_ctrl)
	# 卡牌奖励面板绑定控制器
	_card_reward_panel.bind_controller(_card_battle_ctrl)
	# 牌组查看面板绑定控制器
	_deck_view_panel.bind_controller(_card_battle_ctrl)
	_dice_panel.bind_battle_flow(_battle_flow)
	_dice_panel.bind_board_view(_board_view)
	_dice_panel.set_dice_animation(_dice_anim)
	_dice_panel.test_card_battle_requested.connect(_on_test_card_battle_requested)
	_dice_panel.deck_view_requested.connect(_on_deck_view_requested)
	# 掷骰音效
	if _battle_flow.dice_manager and _battle_flow.dice_manager.has_signal("dice_rolled"):
		_battle_flow.dice_manager.dice_rolled.connect(_on_dice_rolled_sfx)

func _on_move_requested(unit_id: String, target_cell: Vector2i) -> void:
	var success: bool = _battle_flow.try_move_unit(unit_id, target_cell)
	if success:
		_audio.play_sfx("click")
	_board_view.highlight_cells = _battle_flow.get_reachable_cells_for(unit_id)
	_board_view.attack_highlight_cells = _battle_flow.get_attackable_cells_for(unit_id)
	_board_view.summon_highlight_cells = _board_view._filter_summon_cells(_battle_flow.get_summon_cells_for(unit_id))
	_board_view.queue_redraw()

func _on_attack_requested(unit_id: String, target_cell: Vector2i) -> void:
	var success: bool = _battle_flow.try_attack_unit(unit_id, target_cell)
	if success:
		_board_view.play_attack_feedback(target_cell, _last_attack_damage, _last_attack_killed)
		_audio.play_sfx("attack_hit")
	_board_view.highlight_cells = _battle_flow.get_reachable_cells_for(unit_id)
	_board_view.attack_highlight_cells = _battle_flow.get_attackable_cells_for(unit_id)
	_board_view.summon_highlight_cells = _board_view._filter_summon_cells(_battle_flow.get_summon_cells_for(unit_id))
	_board_view.queue_redraw()

func _on_summon_requested(unit_id: String, target_cell: Vector2i) -> void:
	var success: bool = _battle_flow.try_summon(unit_id, target_cell)
	if success:
		_audio.play_sfx("summon")
	_board_view.highlight_cells = _battle_flow.get_reachable_cells_for(unit_id)
	_board_view.attack_highlight_cells = _battle_flow.get_attackable_cells_for(unit_id)
	_board_view.summon_highlight_cells = _board_view._filter_summon_cells(_battle_flow.get_summon_cells_for(unit_id))
	_board_view.queue_redraw()

func _on_phase_changed(phase_name: String) -> void:
	if phase_name == "VICTORY":
		_result_label.text = "通关胜利！"
		_result_label.add_theme_color_override("font_color", CyberStyle.TEXT_SUCCESS)
		_result_label.visible = true
		_restart_btn.visible = true
		_audio.play_sfx("victory")
	elif phase_name == "DEFEAT":
		_result_label.text = "失败"
		_result_label.add_theme_color_override("font_color", CyberStyle.TEXT_WARN)
		_result_label.visible = true
		_restart_btn.visible = true
		_audio.play_sfx("defeat")
	elif phase_name == "FLOOR_CLEAR":
		var floor_num: int = _battle_flow.get_current_floor()
		_result_label.text = "第 " + str(floor_num) + " 层通关！"
		_result_label.add_theme_color_override("font_color", CyberStyle.TEXT_SUCCESS)
		_result_label.visible = true
		_restart_btn.visible = false
	else:
		_result_label.visible = false
		_restart_btn.visible = false

func _on_attack_completed(attacker_id: String, defender_id: String, damage: int, killed: bool) -> void:
	_last_attack_damage = damage
	_last_attack_killed = killed

func _on_enemy_attack_completed(attacker_id: String, defender_id: String, damage: int, killed: bool, target_cell: Vector2i) -> void:
	_board_view.play_attack_feedback(target_cell, damage, killed)
	_audio.play_sfx("player_hurt")

func _on_summon_completed(unit_id: String, path_cells_created: Array[Vector2i], spawn_cell: Vector2i) -> void:
	# 召唤展开演出：路径格逐格铺展 + 单位出场闪光
	_board_view.queue_redraw()
	# 路径格逐格铺展（每格 0.1 秒延迟重绘）
	for i in range(path_cells_created.size()):
		if i > 0:
			await get_tree().create_timer(0.1).timeout
			_board_view.queue_redraw()
	# 召唤单位出场：从小到大 + 发光闪烁
	var pixel_pos: Vector2 = IsoTileRenderer.grid_to_screen(spawn_cell.x, spawn_cell.y, _board_view.iso_origin)
	UITransitions.summon_unit_spawn(_board_view, pixel_pos, float(IsoTileRenderer.TILE_W) * 0.5)

func _on_terrain_damage_triggered(unit_id: String, cell: Vector2i, damage: int, terrain_type: String) -> void:
	_board_view.play_attack_feedback(cell, damage)
	_audio.play_sfx("player_hurt")
	_board_view.queue_redraw()

func _on_item_picked_up(unit_id: String, item_id: String, effect_text: String, cell: Vector2i) -> void:
	_board_view.play_pickup_feedback(cell, effect_text)
	_audio.play_sfx("pickup")
	_board_view.queue_redraw()

func _on_enemy_action_announced(unit_id: String, action_type: String, detail: String) -> void:
	if action_type == "attack":
		var unit: Dictionary = _battle_flow.unit_manager.get_unit(unit_id)
		if not unit.is_empty():
			var cell: Vector2i = unit["cell"]
			var adjacent: Array[Vector2i] = _battle_flow.battle_ai.get_adjacent_player_cells(cell)
			if adjacent.size() > 0:
				_board_view.play_enemy_warning(adjacent[0])

func _on_enemy_turn_ended() -> void:
	_board_view.queue_redraw()

func _on_encounter_triggered(unit_id: String, encounter_id: String, cell: Vector2i) -> void:
	_board_view.queue_redraw()
	_audio.play_sfx("encounter")
	# 查询遭遇敌方名称和 Boss 标识
	var is_boss: bool = encounter_id.begins_with("encounter_boss_")
	var enemy_display: String = _get_encounter_display_name(encounter_id)
	# 查询玩家单位 HP
	var unit: Dictionary = _battle_flow.unit_manager.get_unit(unit_id)
	var p_hp: int = int(unit.get("hp", 1))
	var p_max_hp: int = int(unit.get("max_hp", 1))
	# 宝可梦式过渡：百叶窗合拢 + 闪烁敌方名称
	await _transition.transition_to_battle(enemy_display, is_boss)
	# 百叶窗合拢后：显示全屏卡牌战斗面板 + 启动战斗
	_card_battle_panel.visible = true
	_card_battle_ctrl.start_battle(encounter_id, p_hp, p_max_hp, _battle_flow.current_floor)
	# 切换为战斗 BGM
	if is_boss:
		_audio.play_bgm("bgm_boss")
	else:
		_audio.play_bgm("bgm_battle")
	# 百叶窗展开，露出卡牌战斗界面
	await _transition.reveal()

func _on_encounter_resolved(encounter_id: String, cell: Vector2i) -> void:
	_board_view.play_pickup_feedback(cell, "遭遇清除")
	_board_view.queue_redraw()

func _on_heal_cell_triggered(unit_id: String, cell: Vector2i, heal_amount: int, actual_heal: int) -> void:
	_board_view.play_heal_feedback(cell, "HP+" + str(actual_heal))
	_audio.play_sfx("heal")
	_board_view.queue_redraw()

func _on_event_cell_triggered(unit_id: String, cell: Vector2i, event_id: String, effect_text: String) -> void:
	var is_positive: bool = not effect_text.begins_with("HP-")
	_board_view.play_event_feedback(cell, effect_text, is_positive)
	_board_view.queue_redraw()

func _on_defend_crest_used(unit_id: String, new_temp_def: int) -> void:
	var unit: Dictionary = _battle_flow.unit_manager.get_unit(unit_id)
	if not unit.is_empty():
		var cell: Vector2i = unit["cell"]
		_board_view.play_heal_feedback(cell, "DEF+" + str(new_temp_def))
	_audio.play_sfx("defense")
	_board_view.queue_redraw()

func _on_skill_crest_used(unit_id: String, heal_amount: int) -> void:
	var unit: Dictionary = _battle_flow.unit_manager.get_unit(unit_id)
	if not unit.is_empty():
		var cell: Vector2i = unit["cell"]
		_board_view.play_heal_feedback(cell, "HP+" + str(heal_amount))
	_audio.play_sfx("heal")
	_board_view.queue_redraw()

func _on_trick_crest_used(gained_crest: String) -> void:
	_board_view.queue_redraw()

func _on_shop_cell_triggered(unit_id: String, cell: Vector2i, cost_crest: String, actual_heal: int) -> void:
	_board_view.play_shop_feedback(cell, "-1步 HP+" + str(actual_heal))
	_audio.play_sfx("shop")
	_board_view.queue_redraw()

func _on_chest_cell_triggered(unit_id: String, cell: Vector2i, effect_text: String) -> void:
	_board_view.play_chest_feedback(cell, effect_text)
	_audio.play_sfx("chest")
	_board_view.queue_redraw()

func _on_card_battle_ended(victory: bool, player_hp_remaining: int) -> void:
	# 层间奖励完成 → 进入下一层（无过渡动画）
	if _floor_clear_pending:
		_floor_clear_pending = false
		_result_label.visible = false
		_board_view.selected_unit_id = ""
		_board_view.highlight_cells = []
		_board_view.attack_highlight_cells = []
		_board_view.summon_highlight_cells = []
		_battle_flow.advance_to_next_floor()
		_board_view.queue_redraw()
		return
	# 卡牌战斗结束：先等待结果展示
	var encounter_cell: Vector2i = _battle_flow._encounter_cell
	await get_tree().create_timer(0.8).timeout
	# 百叶窗合拢
	await _transition.transition_to_board()
	# 百叶窗合拢后：隐藏卡牌战斗面板
	_card_battle_panel.visible = false
	# 结算遭遇
	_battle_flow.resolve_encounter(victory, player_hp_remaining)
	# 反馈飘字
	if victory and encounter_cell.x >= 0:
		_board_view.play_pickup_feedback(encounter_cell, "战斗胜利！")
		_audio.play_sfx("victory")
	elif not victory and encounter_cell.x >= 0:
		_board_view.play_encounter_feedback(encounter_cell, "战斗失败...")
	_board_view.queue_redraw()
	# 百叶窗展开，回到棋盘
	await _transition.reveal()
	# 恢复棋盘 BGM
	_audio.play_bgm("bgm_map")

func _on_card_battle_reward(reward_text: String) -> void:
	# 卡牌战斗胜利奖励：将 crest 加入棋盘层资源池
	var crest_type: String = reward_text.replace("+1", "").to_lower()
	var dm: Node = _battle_flow.dice_manager
	if dm:
		var current: int = int(dm.crest_pool.get(crest_type, 0))
		dm.crest_pool[crest_type] = current + 1

func _on_floor_cleared(floor_number: int) -> void:
	# 层通关 → 触发层间奖励（选牌/升级），完成后进入下一层
	_floor_clear_pending = true
	_card_battle_ctrl.offer_floor_reward()

func _on_game_won() -> void:
	# 全部层通关（最终胜利在 _on_phase_changed VICTORY 中处理显示）
	pass

func _on_boss_unlocked(cell: Vector2i) -> void:
	_board_view.play_encounter_feedback(cell, "BOSS 解锁！")
	_audio.play_sfx("encounter")
	_board_view.queue_redraw()

func _on_hero_warped(unit_id: String, target_cell: Vector2i) -> void:
	_board_view.play_pickup_feedback(target_cell, "传送至 Boss！")
	_board_view.queue_redraw()

func _on_portal_spawned(cell: Vector2i) -> void:
	_board_view.play_pickup_feedback(cell, "传送门！")
	_board_view.queue_redraw()

func _on_restart_pressed() -> void:
	_board_view.selected_unit_id = ""
	_board_view.highlight_cells = []
	_board_view.attack_highlight_cells = []
	_board_view.summon_highlight_cells = []
	_floor_clear_pending = false
	_card_battle_ctrl.reset_persistent_deck()
	_battle_flow.restart_battle()
	_board_view.queue_redraw()

func _on_settings_pressed() -> void:
	_audio.play_sfx("click")
	_settings_panel.open()

func _on_test_card_battle_requested() -> void:
	# 调试快捷键：直接用第一个玩家单位的 HP 启动卡牌战斗（encounter_01）
	var player_ids: Array[String] = _battle_flow.unit_manager.get_player_units()
	if player_ids.is_empty():
		return
	var unit: Dictionary = _battle_flow.unit_manager.get_unit(player_ids[0])
	if unit.is_empty():
		return
	var p_hp: int = int(unit.get("hp", 1))
	var p_max_hp: int = int(unit.get("max_hp", 1))
	# 调试也走宝可梦式过渡
	await _transition.transition_to_battle("异常哨兵", false)
	_card_battle_panel.visible = true
	_card_battle_ctrl.start_battle("encounter_01", p_hp, p_max_hp, _battle_flow.current_floor)
	await _transition.reveal()

func _on_deck_view_requested() -> void:
	if _deck_view_panel.is_open():
		_deck_view_panel.close()
	else:
		_deck_view_panel.open()

## 掷骰音效回调
func _on_dice_rolled_sfx(_results: Array[String], _crest_pool: Dictionary) -> void:
	_audio.play_sfx("dice_roll")

## 卡牌层音效回调
func _on_card_played_sfx(_card_index: int, _card_name: String, _effect_text: String) -> void:
	_audio.play_sfx("card_play")

func _on_enemy_acted_sfx(_action_text: String) -> void:
	_audio.play_sfx("enemy_hurt")

func _on_hand_changed_sfx(_hand: Array, _energy: int, _max_energy: int) -> void:
	_audio.play_sfx("card_draw")

## 遭遇 ID → 显示名称映射（用于过渡动画闪字）
func _get_encounter_display_name(encounter_id: String) -> String:
	var names: Dictionary = {
		"encounter_01": "异常哨兵",
		"encounter_02": "赛博游魂",
		"encounter_03": "暗网爬虫",
		"encounter_04": "脉冲猎手",
		"encounter_05": "数据幽灵",
		"encounter_boss_01": "零号协议",
	}
	if names.has(encounter_id):
		return String(names[encounter_id])
	if encounter_id.begins_with("encounter_boss_"):
		return "BOSS"
	return "未知遭遇"
