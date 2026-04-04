extends Control

const MainViewCoordinatorScript = preload("res://Scripts/App/MainViewCoordinator.gd")
const ChapterContent = preload("res://Scripts/App/ChapterContent.gd")
const BoardViewScript = preload("res://Scripts/UI/BoardView.gd")
const BoardView3DScript = preload("res://Scripts/UI3D/BoardView3D.gd")

# v0.1.71：3D/2D 视图切换标志（默认 false = 2D 模式）
var _use_3d: bool = false

var _battle_flow: BattleFlowController
var _card_battle_ctrl: CardBattleController
var _board_view: BoardView
var _board_view_3d: BoardView3D = null
var _sub_viewport: SubViewport = null
var _sub_viewport_container: SubViewportContainer = null
var _dice_panel: DiceDebugPanel
var _display_settings: DisplaySettings
var _settings_panel: SettingsPanel
var _card_battle_panel: CardBattlePanel
var _card_reward_panel: CardRewardPanel
var _deck_view_panel: DeckViewPanel
var _chapter_label: Label
var _objective_label: Label
var _result_label: Label
var _restart_btn: Button
var _dice_anim: DiceRollAnimation
var _transition: TransitionOverlay
var _mission_brief_overlay = null
var _audio: AudioManager
var _portrait_hud: UnitPortraitHUD
var _shop_panel: ShopPanel
var _view_switch_fx: ColorRect = null
var _last_attack_damage: int = 0
var _last_attack_killed: bool = false
var _floor_clear_pending: bool = false
var _last_operated_unit_id: String = ""
var _view_coordinator = null

func _ready() -> void:
	_display_settings = DisplaySettings.new()
	add_child(_display_settings)
	_audio = AudioManager.new()
	add_child(_audio)
	_battle_flow = BattleFlowController.new()
	add_child(_battle_flow)
	_card_battle_ctrl = CardBattleController.new()
	add_child(_card_battle_ctrl)
	_view_coordinator = MainViewCoordinatorScript.new()
	_build_debug_view()
	_wire_debug_views()
	# v0.1.71：3D 视图初始化（默认隐藏）
	_setup_3d_view()
	# 初始相机跟随玩家位置
	_update_camera_to_player()
	# 启动棋盘 BGM
	_audio.play_bgm("bgm_map")
	_refresh_chapter_banner()
	call_deferred("_show_opening_briefing")

func _build_debug_view() -> void:
	_view_coordinator.build_views(self, _display_settings, _audio)
	_sync_view_refs()

func _wire_debug_views() -> void:
	_view_coordinator.wire_views(self, _battle_flow, _card_battle_ctrl)

func _sync_view_refs() -> void:
	_board_view = _view_coordinator.board_view
	_board_view_3d = _view_coordinator.board_view_3d
	_sub_viewport = _view_coordinator.sub_viewport
	_sub_viewport_container = _view_coordinator.sub_viewport_container
	_dice_panel = _view_coordinator.dice_panel
	_settings_panel = _view_coordinator.settings_panel
	_card_battle_panel = _view_coordinator.card_battle_panel
	_card_reward_panel = _view_coordinator.card_reward_panel
	_deck_view_panel = _view_coordinator.deck_view_panel
	_chapter_label = _view_coordinator.chapter_label
	_objective_label = _view_coordinator.objective_label
	_result_label = _view_coordinator.result_label
	_restart_btn = _view_coordinator.restart_btn
	_dice_anim = _view_coordinator.dice_anim
	_transition = _view_coordinator.transition
	_mission_brief_overlay = _view_coordinator.mission_brief_overlay
	_portrait_hud = _view_coordinator.portrait_hud
	_shop_panel = _view_coordinator.shop_panel
	_view_switch_fx = _view_coordinator.view_switch_fx

func _on_move_requested(unit_id: String, target_cell: Vector2i) -> void:
	if not _battle_flow.validate_move(unit_id, target_cell):
		return
	_audio.play_sfx("click")
	_last_operated_unit_id = unit_id
	# 逐格动画+相机跟随由 move_step_visual 信号链驱动
	_battle_flow.try_move_unit(unit_id, target_cell)

func _on_attack_requested(unit_id: String, target_cell: Vector2i) -> void:
	_last_operated_unit_id = unit_id
	var success: bool = _battle_flow.try_attack_unit(unit_id, target_cell)
	var view = _active_view()
	if success:
		view.play_attack_feedback(target_cell, _last_attack_damage, _last_attack_killed)
		_audio.play_sfx("attack_hit")
	view.highlight_cells = _battle_flow.get_reachable_cells_for(unit_id)
	view.attack_highlight_cells = _battle_flow.get_attackable_cells_for(unit_id)
	view.summon_highlight_cells = view._filter_summon_cells(_battle_flow.get_summon_cells_for(unit_id))
	view.queue_redraw()

func _on_summon_requested(unit_id: String, target_cell: Vector2i) -> void:
	_last_operated_unit_id = unit_id
	var success: bool = _battle_flow.try_summon(unit_id, target_cell)
	if success:
		_audio.play_sfx("summon")
	var view = _active_view()
	view.highlight_cells = _battle_flow.get_reachable_cells_for(unit_id)
	view.attack_highlight_cells = _battle_flow.get_attackable_cells_for(unit_id)
	view.summon_highlight_cells = view._filter_summon_cells(_battle_flow.get_summon_cells_for(unit_id))
	view.queue_redraw()

func _on_phase_changed(phase_name: String) -> void:
	if phase_name == "VICTORY":
		_result_label.text = ChapterContent.get_victory_text()
		_result_label.add_theme_color_override("font_color", CyberStyle.TEXT_SUCCESS)
		_result_label.visible = true
		_restart_btn.visible = true
		_audio.play_sfx("victory")
	elif phase_name == "DEFEAT":
		_result_label.text = "突破失败"
		_result_label.add_theme_color_override("font_color", CyberStyle.TEXT_WARN)
		_result_label.visible = true
		_restart_btn.visible = true
		_audio.play_sfx("defeat")
	elif phase_name == "FLOOR_CLEAR":
		var floor_num: int = _battle_flow.get_current_floor()
		_result_label.text = ChapterContent.get_floor_clear_text(floor_num)
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
	_active_view().play_attack_feedback(target_cell, damage, killed)
	_audio.play_sfx("player_hurt")

func _on_summon_completed(unit_id: String, path_cells_created: Array[Vector2i], spawn_cell: Vector2i) -> void:
	# 召唤展开演出：路径格逐格铺展 + 单位出场闪光
	_active_view().queue_redraw()
	# 路径格逐格铺展（每格 0.1 秒延迟重绘）
	for i in range(path_cells_created.size()):
		if i > 0:
			await get_tree().create_timer(0.1).timeout
			_active_view().queue_redraw()
	# 召唤单位出场：2D 模式下做 UITransitions 演出
	if not _use_3d:
		var pixel_pos: Vector2 = IsoTileRenderer.grid_to_screen_zoom(spawn_cell.x, spawn_cell.y, _board_view.iso_origin, _board_view._zoom)
		UITransitions.summon_unit_spawn(_board_view, pixel_pos, float(IsoTileRenderer.TILE_W) * 0.5)

func _on_terrain_damage_triggered(unit_id: String, cell: Vector2i, damage: int, terrain_type: String) -> void:
	_active_view().play_attack_feedback(cell, damage)
	_audio.play_sfx("player_hurt")
	_active_view().queue_redraw()

func _on_item_picked_up(unit_id: String, item_id: String, effect_text: String, cell: Vector2i) -> void:
	_active_view().play_pickup_feedback(cell, effect_text)
	_audio.play_sfx("pickup")
	_active_view().queue_redraw()

func _on_enemy_action_announced(unit_id: String, action_type: String, detail: String) -> void:
	# 敌方行动时相机跟随敌人（v0.1.63）
	var unit: Dictionary = _battle_flow.unit_manager.get_unit(unit_id)
	if not unit.is_empty():
		var cell: Vector2i = unit["cell"]
		_active_view().set_camera_target(cell)
		if action_type == "attack":
			var adjacent: Array[Vector2i] = _battle_flow.battle_ai.get_adjacent_player_cells(cell)
			if adjacent.size() > 0:
				_active_view().play_enemy_warning(adjacent[0])

func _on_enemy_turn_ended() -> void:
	# 敌方回合结束（v0.1.67：切回上一轮操作的我方单位，而非固定切主角）
	_reset_drag_offset()
	await get_tree().create_timer(0.8).timeout
	if _last_operated_unit_id != "":
		var last_unit: Dictionary = _battle_flow.unit_manager.get_unit(_last_operated_unit_id)
		if not last_unit.is_empty() and String(last_unit.get("owner", "")) == "player":
			_active_view().set_camera_target(last_unit["cell"])
			_active_view().queue_redraw()
			return
	_update_camera_to_player()
	_active_view().queue_redraw()

func _on_encounter_triggered(unit_id: String, encounter_id: String, cell: Vector2i) -> void:
	_active_view().queue_redraw()
	_audio.play_sfx("encounter")
	# 查询遭遇敌方名称和 Boss 标识
	var is_boss: bool = encounter_id.begins_with("encounter_boss_")
	var enemy_display: String = _get_encounter_display_name(encounter_id)
	# 查询玩家单位 HP
	var unit: Dictionary = _battle_flow.unit_manager.get_unit(unit_id)
	var p_hp: int = int(unit.get("hp", 1))
	var p_max_hp: int = int(unit.get("max_hp", 1))
	var player_name: String = String(unit.get("display_name", "主角"))
	# 宝可梦式过渡：百叶窗合拢 + 闪烁敌方名称
	await _transition.transition_to_battle(enemy_display, is_boss)
	# 百叶窗合拢后：显示全屏卡牌战斗面板 + 启动战斗
	_card_battle_panel.visible = true
	_portrait_hud.visible = false
	_card_battle_ctrl.start_battle(encounter_id, p_hp, p_max_hp, _battle_flow.get_current_floor(), player_name)
	# 切换为战斗 BGM
	if is_boss:
		_audio.play_bgm("bgm_boss")
	else:
		_audio.play_bgm("bgm_battle")
	# 百叶窗展开，露出卡牌战斗界面
	await _transition.reveal()

func _on_encounter_resolved(encounter_id: String, cell: Vector2i) -> void:
	_active_view().play_pickup_feedback(cell, ChapterContent.get_encounter_resolved_text())
	_active_view().queue_redraw()

func _on_heal_cell_triggered(unit_id: String, cell: Vector2i, heal_amount: int, actual_heal: int) -> void:
	_active_view().play_heal_feedback(cell, "HP+" + str(actual_heal))
	_audio.play_sfx("heal")
	_active_view().queue_redraw()

func _on_event_cell_triggered(unit_id: String, cell: Vector2i, event_id: String, effect_text: String) -> void:
	var is_positive: bool = not effect_text.begins_with("HP-")
	_active_view().play_event_feedback(cell, effect_text, is_positive)
	_active_view().queue_redraw()

func _on_defend_crest_used(unit_id: String, new_temp_def: int) -> void:
	var unit: Dictionary = _battle_flow.unit_manager.get_unit(unit_id)
	if not unit.is_empty():
		var cell: Vector2i = unit["cell"]
		_active_view().play_heal_feedback(cell, "DEF+" + str(new_temp_def))
	_audio.play_sfx("defense")
	_active_view().queue_redraw()

func _on_skill_crest_used(unit_id: String, heal_amount: int) -> void:
	var unit: Dictionary = _battle_flow.unit_manager.get_unit(unit_id)
	if not unit.is_empty():
		var cell: Vector2i = unit["cell"]
		_active_view().play_heal_feedback(cell, "HP+" + str(heal_amount))
	_audio.play_sfx("heal")
	_active_view().queue_redraw()

func _on_trick_crest_used(gained_crest: String) -> void:
	_active_view().queue_redraw()

func _on_shop_panel_requested(unit_id: String, cell: Vector2i) -> void:
	_shop_panel.open_shop(unit_id, _battle_flow.dice_manager, _battle_flow.unit_manager, _card_battle_ctrl)
	_audio.play_sfx("shop")
	_active_view().play_shop_feedback(cell, ChapterContent.get_shop_feedback_label())
	_active_view().queue_redraw()

func _on_shop_closed() -> void:
	_dice_panel._refresh_crest_pool()
	_active_view().queue_redraw()

func _on_chest_cell_triggered(unit_id: String, cell: Vector2i, effect_text: String) -> void:
	_active_view().play_chest_feedback(cell, effect_text)
	_audio.play_sfx("chest")
	_active_view().queue_redraw()

func _on_card_battle_ended(victory: bool, player_hp_remaining: int) -> void:
	var view = _active_view()
	# 层间奖励完成 → 进入下一层（无过渡动画）
	if _floor_clear_pending:
		_floor_clear_pending = false
		_result_label.visible = false
		view.selected_unit_id = ""
		_clear_highlight_arrays(view)
		_battle_flow.advance_to_next_floor()
		_update_camera_to_player()
		_refresh_chapter_banner()
		view.queue_redraw()
		if _use_3d and _board_view_3d:
			_board_view_3d.rebuild_board()
		return
	# 卡牌战斗结束：先等待结果展示
	var encounter_cell: Vector2i = _battle_flow._encounter_cell
	await get_tree().create_timer(0.8).timeout
	# 百叶窗合拢
	await _transition.transition_to_board()
	# 百叶窗合拢后：隐藏卡牌战斗面板
	_card_battle_panel.visible = false
	_portrait_hud.visible = true
	# 结算遭遇
	_battle_flow.resolve_encounter(victory, player_hp_remaining)
	# 反馈飘字
	if victory and encounter_cell.x >= 0:
		view.play_pickup_feedback(encounter_cell, ChapterContent.get_encounter_victory_text())
		_audio.play_sfx("victory")
	elif not victory and encounter_cell.x >= 0:
		view.play_encounter_feedback(encounter_cell, ChapterContent.get_encounter_defeat_text())
	view.queue_redraw()
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
	_active_view().play_encounter_feedback(cell, ChapterContent.get_boss_unlock_text())
	_audio.play_sfx("encounter")
	_active_view().queue_redraw()

func _on_hero_warped(unit_id: String, target_cell: Vector2i) -> void:
	_active_view().set_camera_target(target_cell)
	_active_view().play_pickup_feedback(target_cell, ChapterContent.get_warp_text())
	_active_view().queue_redraw()

func _on_portal_spawned(cell: Vector2i) -> void:
	_active_view().play_pickup_feedback(cell, ChapterContent.get_portal_text())
	_active_view().queue_redraw()

func _on_restart_pressed() -> void:
	var view = _active_view()
	view.selected_unit_id = ""
	view.highlight_cells.clear()
	view.attack_highlight_cells.clear()
	view.summon_highlight_cells.clear()
	_floor_clear_pending = false
	_last_operated_unit_id = ""
	_card_battle_ctrl.reset_persistent_deck()
	_battle_flow.restart_battle()
	_update_camera_to_player()
	_refresh_chapter_banner()
	view.queue_redraw()
	if _use_3d and _board_view_3d:
		_board_view_3d.rebuild_board()

## 相机跟随：找到第一个玩家单位位置并更新相机目标（v0.1.60）
func _update_camera_to_player() -> void:
	if _battle_flow == null or _battle_flow.unit_manager == null:
		return
	var player_ids: Array[String] = _battle_flow.unit_manager.get_player_hero_units()
	if player_ids.is_empty():
		return
	var unit: Dictionary = _battle_flow.unit_manager.get_unit(player_ids[0])
	if unit.is_empty():
		return
	var cell: Vector2i = unit["cell"]
	_active_view().set_camera_target(cell)

## move_completed 相机跟随回调（v0.1.64：仅跟随当前阶段活动单位）
func _on_move_completed_camera(unit_id: String, _from_cell: Vector2i, to_cell: Vector2i) -> void:
	_reset_drag_offset()
	_active_view().set_camera_target(to_cell)

## v0.1.67：逐格移动动画 — 收到 BFC 的 move_step_visual 后驱动活动视图动画
func _on_move_step_visual(unit_id: String, from_cell: Vector2i, to_cell: Vector2i) -> void:
	_reset_drag_offset()
	_active_view().set_camera_target(to_cell)
	_active_view().play_move_step(unit_id, from_cell, to_cell, 0.15)

## v0.1.67：视图单步动画完成后通知 BFC 继续下一步
func _on_board_move_anim_done() -> void:
	_battle_flow.move_step_done.emit()

## 敌方回合开始前：将相机移到第一个敌方单位（v0.1.64）
func _on_enemy_turn_starting(first_enemy_id: String) -> void:
	var unit: Dictionary = _battle_flow.unit_manager.get_unit(first_enemy_id)
	if not unit.is_empty():
		var cell: Vector2i = unit["cell"]
		_reset_drag_offset()
		_active_view().set_camera_target(cell)

func _on_settings_pressed() -> void:
	_audio.play_sfx("click")
	_settings_panel.open()

func _on_test_card_battle_requested() -> void:
	# 调试快捷键：直接用第一个玩家单位的 HP 启动卡牌战斗（encounter_01）
	var player_ids: Array[String] = _battle_flow.unit_manager.get_player_hero_units()
	if player_ids.is_empty():
		return
	var unit: Dictionary = _battle_flow.unit_manager.get_unit(player_ids[0])
	if unit.is_empty():
		return
	var p_hp: int = int(unit.get("hp", 1))
	var p_max_hp: int = int(unit.get("max_hp", 1))
	var player_name: String = String(unit.get("display_name", "主角"))
	# 调试也走宝可梦式过渡
	await _transition.transition_to_battle(ChapterContent.get_encounter_display_name("encounter_01"), false)
	_card_battle_panel.visible = true
	_portrait_hud.visible = false
	_card_battle_ctrl.start_battle("encounter_01", p_hp, p_max_hp, _battle_flow.get_current_floor(), player_name)
	await _transition.reveal()

func _on_deck_view_requested() -> void:
	if _deck_view_panel.is_open():
		_deck_view_panel.close()
	else:
		_deck_view_panel.open()

## v0.1.69：顶部头像 HUD 点击切换镜头
func _on_portrait_clicked(unit_id: String) -> void:
	var unit: Dictionary = _battle_flow.unit_manager.get_unit(unit_id)
	if unit.is_empty():
		return
	_audio.play_sfx("click")
	var cell: Vector2i = unit["cell"]
	var view = _active_view()
	_reset_drag_offset()
	view.set_camera_target(cell)
	# 如果是玩家单位，选中它
	if _battle_flow.unit_manager.is_player_hero_unit(unit_id):
		view.selected_unit_id = unit_id
		view.highlight_cells = _battle_flow.get_reachable_cells_for(unit_id)
		view.attack_highlight_cells = _battle_flow.get_attackable_cells_for(unit_id)
		view.summon_highlight_cells = view._filter_summon_cells(_battle_flow.get_summon_cells_for(unit_id))
	_portrait_hud.set_selected(unit_id)
	view.queue_redraw()

## 掷骰音效回调
func _on_dice_rolled_sfx(_results: Array[String], _crest_pool: Dictionary) -> void:
	_audio.play_sfx("dice_roll")

## v0.1.65：掷骰动画结束后转发信号给 BFC，以便敌方回合等待动画完成
func _on_dice_anim_finished_forward(_results: Array[String], _crest_pool: Dictionary) -> void:
	_battle_flow.dice_animation_done.emit()

## 卡牌层音效回调
func _on_card_played_sfx(_card_index: int, _card_name: String, _effect_text: String) -> void:
	_audio.play_sfx("card_play")

func _on_enemy_acted_sfx(_action_text: String) -> void:
	_audio.play_sfx("enemy_hurt")

func _on_hand_changed_sfx(_hand: Array, _energy: int, _max_energy: int) -> void:
	_audio.play_sfx("card_draw")

## 遭遇 ID → 显示名称映射（用于过渡动画闪字）
func _get_encounter_display_name(encounter_id: String) -> String:
	return ChapterContent.get_encounter_display_name(encounter_id)

func _refresh_chapter_banner() -> void:
	if _battle_flow == null:
		return
	var floor_num: int = _battle_flow.get_current_floor()
	if _chapter_label:
		_chapter_label.text = ChapterContent.get_run_header(floor_num)
	if _objective_label:
		_objective_label.text = ChapterContent.get_run_objective(floor_num)

func _show_opening_briefing() -> void:
	if _mission_brief_overlay == null:
		return
	var briefing: Dictionary = ChapterContent.get_opening_briefing()
	_mission_brief_overlay.show_briefing(
		String(briefing.get("tag", "")),
		String(briefing.get("title", "")),
		String(briefing.get("subtitle", "")),
		String(briefing.get("body", "")),
		String(briefing.get("footer", "")),
		String(briefing.get("button", "继续"))
	)

## v0.1.71：初始化 3D 视图（SubViewport + SubViewportContainer）
func _setup_3d_view() -> void:
	_view_coordinator.setup_3d_view(self, _battle_flow)
	_sync_view_refs()

## v0.1.71：获取当前活动视图（duck typing — 2D 和 3D 视图共享信号/方法接口）
func _active_view():
	if _use_3d and _board_view_3d:
		return _board_view_3d
	return _board_view

## v0.1.71：重置拖拽偏移（兼容 2D/3D）
func _reset_drag_offset() -> void:
	if _use_3d:
		if _board_view_3d:
			_board_view_3d._drag_offset_accumulated = Vector3.ZERO
	else:
		_board_view._drag_offset = Vector2.ZERO

## v0.1.71：切换 2D/3D 视图
func toggle_3d_view() -> void:
	_play_view_switch_fx()
	_use_3d = not _use_3d
	_board_view.visible = not _use_3d
	_sub_viewport_container.visible = _use_3d
	if _use_3d and _board_view_3d:
		_board_view_3d.rebuild_board()
		_update_camera_to_player()
	elif not _use_3d:
		_update_camera_to_player()
		_board_view.queue_redraw()

func _play_view_switch_fx() -> void:
	if _view_switch_fx == null:
		return
	_view_switch_fx.visible = true
	var color_a: Color = Color(0.9, 0.1, 1.0, 0.0)
	var color_b: Color = Color(0.1, 0.9, 1.0, 0.35)
	var tw: Tween = _view_switch_fx.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_view_switch_fx, "color", color_b, 0.12)
	tw.tween_property(_view_switch_fx, "color", color_a, 0.22)
	tw.tween_callback(func() -> void:
		if _view_switch_fx:
			_view_switch_fx.visible = false
	)

## v0.1.71：处理 3D 视图输入转发
func _input(event: InputEvent) -> void:
	if _mission_brief_overlay != null and _mission_brief_overlay.is_open():
		return
	# F5 切换 2D/3D
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_F5:
			toggle_3d_view()
			get_viewport().set_input_as_handled()
			return
	# 3D 模式下转发鼠标事件给 BoardView3D
	if _use_3d and _board_view_3d and _sub_viewport_container.visible:
		if event is InputEventMouse:
			_board_view_3d.handle_input(event)

func _clear_highlight_arrays(view: Node) -> void:
	if view is BoardViewScript:
		view.highlight_cells.clear()
		view.attack_highlight_cells.clear()
		view.summon_highlight_cells.clear()
		return
	if view is BoardView3DScript:
		view.highlight_cells.clear()
		view.attack_highlight_cells.clear()
		view.summon_highlight_cells.clear()

## 生成赛博风格十字光标纹理（v0.1.63）
func _setup_custom_cursor() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center: int = 15
	var arm: int = 10
	var gap: int = 3
	var col := Color(0.0, 0.85, 1.0, 0.9)
	var col_dim := Color(0.0, 0.6, 0.8, 0.5)
	# 十字准星（中心留空）
	for i in range(gap, arm + 1):
		img.set_pixel(center + i, center, col)
		img.set_pixel(center - i, center, col)
		img.set_pixel(center, center + i, col)
		img.set_pixel(center, center - i, col)
	# 中心点
	img.set_pixel(center, center, Color(1.0, 1.0, 1.0, 0.8))
	# 角标记
	for dx in [-1, 1]:
		for dy in [-1, 1]:
			img.set_pixel(center + dx * (arm - 1), center + dy, col_dim)
			img.set_pixel(center + dx, center + dy * (arm - 1), col_dim)
	var tex := ImageTexture.create_from_image(img)
	Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, Vector2(15, 15))
