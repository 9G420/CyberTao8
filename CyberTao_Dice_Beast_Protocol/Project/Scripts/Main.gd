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
const UnitPortraitHUD = preload("res://Scripts/UI/UnitPortraitHUD.gd")
const ShopPanelScript = preload("res://Scripts/UI/ShopPanel.gd")
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
var _result_label: Label
var _restart_btn: Button
var _dice_anim: DiceRollAnimation
var _transition: TransitionOverlay
var _audio: AudioManager
var _portrait_hud: UnitPortraitHUD
var _shop_panel: ShopPanel
var _last_attack_damage: int = 0
var _last_attack_killed: bool = false
var _floor_clear_pending: bool = false
var _last_operated_unit_id: String = ""

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
	# v0.1.71：3D 视图初始化（默认隐藏）
	_setup_3d_view()
	# 初始相机跟随玩家位置
	_update_camera_to_player()
	# 启动棋盘 BGM
	_audio.play_bgm("bgm_map")

func _build_debug_view() -> void:
	# 自定义鼠标光标（v0.1.63：赛博风格十字光标）
	_setup_custom_cursor()

	var cyber_bg := CyberBackground.new()
	cyber_bg.set_board_rect(Vector2(0, 0), Vector2(1280, 720))
	add_child(cyber_bg)

	# 棋盘占满全屏
	_board_view = BoardView.new()
	_board_view.position = Vector2(0, 0)
	add_child(_board_view)

	# 顶部单位头像 HUD（v0.1.69）
	_portrait_hud = UnitPortraitHUD.new()
	add_child(_portrait_hud)

	# 底部右侧操作面板（v0.1.63 紧凑HUD）
	_dice_panel = DiceDebugPanel.new()
	_dice_panel.position = Vector2(1012, 512)
	add_child(_dice_panel)

	var settings_btn := Button.new()
	settings_btn.text = "设置"
	settings_btn.position = Vector2(8, 8)
	settings_btn.size = Vector2(72, 28)
	settings_btn.add_theme_font_size_override("font_size", 12)
	settings_btn.pressed.connect(_on_settings_pressed)
	CyberStyle.style_button(settings_btn, "cyan")
	add_child(settings_btn)

	_settings_panel = SettingsPanel.new()
	_settings_panel.position = Vector2(420, 100)
	add_child(_settings_panel)
	_settings_panel.bind_display_settings(_display_settings)
	_settings_panel.bind_audio_manager(_audio)

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

	# 商店面板（v0.1.73 多选商品）
	_shop_panel = ShopPanel.new()
	_shop_panel.position = Vector2(400, 170)
	add_child(_shop_panel)

	_result_label = Label.new()
	_result_label.position = Vector2(0, 320)
	_result_label.size = Vector2(1280, 60)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 36)
	_result_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_label.visible = false
	add_child(_result_label)

	_restart_btn = Button.new()
	_restart_btn.text = "重新开始"
	_restart_btn.position = Vector2(540, 384)
	_restart_btn.size = Vector2(200, 40)
	_restart_btn.add_theme_font_size_override("font_size", 16)
	_restart_btn.visible = false
	_restart_btn.pressed.connect(_on_restart_pressed)
	CyberStyle.style_button(_restart_btn, "orange")
	add_child(_restart_btn)

	# 掷骰演出（全屏居中等距 3D 骰子，覆盖在最上层）
	_dice_anim = DiceRollAnimation.new()
	_dice_anim.set_board_center(Vector2(640, 360))
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
	_battle_flow.shop_panel_requested.connect(_on_shop_panel_requested)
	_shop_panel.shop_closed.connect(_on_shop_closed)
	_battle_flow.chest_cell_triggered.connect(_on_chest_cell_triggered)
	_battle_flow.floor_cleared.connect(_on_floor_cleared)
	_battle_flow.game_won.connect(_on_game_won)
	_battle_flow.boss_unlocked.connect(_on_boss_unlocked)
	_battle_flow.portal_spawned.connect(_on_portal_spawned)
	_battle_flow.hero_warped.connect(_on_hero_warped)
	# v0.1.64：敌方回合开始前将相机给到敌方单位
	_battle_flow.enemy_turn_starting.connect(_on_enemy_turn_starting)
	# v0.1.65：掷骰动画结束后通知 BFC 可以继续
	_dice_anim.animation_finished.connect(_on_dice_anim_finished_forward)
	# 移动完成后更新相机（v0.1.60）
	_battle_flow.move_completed.connect(_on_move_completed_camera)
	# v0.1.67：逐格移动动画信号链
	_battle_flow.move_step_visual.connect(_on_move_step_visual)
	_board_view.move_anim_done.connect(_on_board_move_anim_done)
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
	# v0.1.69：顶部单位头像 HUD
	_portrait_hud.bind_unit_manager(_battle_flow.unit_manager)
	_portrait_hud.portrait_clicked.connect(_on_portrait_clicked)
	_board_view.unit_selected.connect(func(uid: String): _portrait_hud.set_selected(uid))
	_board_view.unit_deselected.connect(func(): _portrait_hud.set_selected(""))
	# 掷骰音效
	if _battle_flow.dice_manager and _battle_flow.dice_manager.has_signal("dice_rolled"):
		_battle_flow.dice_manager.dice_rolled.connect(_on_dice_rolled_sfx)

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
	# 宝可梦式过渡：百叶窗合拢 + 闪烁敌方名称
	await _transition.transition_to_battle(enemy_display, is_boss)
	# 百叶窗合拢后：显示全屏卡牌战斗面板 + 启动战斗
	_card_battle_panel.visible = true
	_portrait_hud.visible = false
	_card_battle_ctrl.start_battle(encounter_id, p_hp, p_max_hp, _battle_flow.get_current_floor())
	# 切换为战斗 BGM
	if is_boss:
		_audio.play_bgm("bgm_boss")
	else:
		_audio.play_bgm("bgm_battle")
	# 百叶窗展开，露出卡牌战斗界面
	await _transition.reveal()

func _on_encounter_resolved(encounter_id: String, cell: Vector2i) -> void:
	_active_view().play_pickup_feedback(cell, "遭遇清除")
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
	_active_view().play_shop_feedback(cell, "商店")
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
		view.highlight_cells = []
		view.attack_highlight_cells = []
		view.summon_highlight_cells = []
		_battle_flow.advance_to_next_floor()
		_update_camera_to_player()
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
		view.play_pickup_feedback(encounter_cell, "战斗胜利！")
		_audio.play_sfx("victory")
	elif not victory and encounter_cell.x >= 0:
		view.play_encounter_feedback(encounter_cell, "战斗失败...")
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
	_active_view().play_encounter_feedback(cell, "BOSS 解锁！")
	_audio.play_sfx("encounter")
	_active_view().queue_redraw()

func _on_hero_warped(unit_id: String, target_cell: Vector2i) -> void:
	_active_view().set_camera_target(target_cell)
	_active_view().play_pickup_feedback(target_cell, "传送至 Boss！")
	_active_view().queue_redraw()

func _on_portal_spawned(cell: Vector2i) -> void:
	_active_view().play_pickup_feedback(cell, "传送门！")
	_active_view().queue_redraw()

func _on_restart_pressed() -> void:
	var view = _active_view()
	view.selected_unit_id = ""
	view.highlight_cells = []
	view.attack_highlight_cells = []
	view.summon_highlight_cells = []
	_floor_clear_pending = false
	_last_operated_unit_id = ""
	_card_battle_ctrl.reset_persistent_deck()
	_battle_flow.restart_battle()
	_update_camera_to_player()
	view.queue_redraw()
	if _use_3d and _board_view_3d:
		_board_view_3d.rebuild_board()

## 相机跟随：找到第一个玩家单位位置并更新相机目标（v0.1.60）
func _update_camera_to_player() -> void:
	if _battle_flow == null or _battle_flow.unit_manager == null:
		return
	var player_ids: Array[String] = _battle_flow.unit_manager.get_player_units()
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
	_portrait_hud.visible = false
	_card_battle_ctrl.start_battle("encounter_01", p_hp, p_max_hp, _battle_flow.get_current_floor())
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
	if String(unit.get("owner", "")) == "player":
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
	var names: Dictionary = {
		"encounter_01": "异常哨兵",
		"encounter_02": "赛博游魂",
		"encounter_03": "暗网爬虫",
		"encounter_04": "脉冲猎手",
		"encounter_05": "数据幽灵",
		"encounter_06": "量子分裂体",
		"encounter_07": "赛博巫医",
		"encounter_boss_01": "零号协议",
	}
	if names.has(encounter_id):
		return String(names[encounter_id])
	if encounter_id.begins_with("encounter_boss_"):
		return "BOSS"
	return "未知遭遇"

## v0.1.71：初始化 3D 视图（SubViewport + SubViewportContainer）
func _setup_3d_view() -> void:
	# 创建 SubViewportContainer（全屏覆盖，初始隐藏）
	_sub_viewport_container = SubViewportContainer.new()
	_sub_viewport_container.position = Vector2(0, 0)
	_sub_viewport_container.size = Vector2(1280, 720)
	_sub_viewport_container.stretch = true
	_sub_viewport_container.visible = false
	# 插入到 BoardView 后面（背景之后、HUD 之前）
	var bv_idx: int = _board_view.get_index()
	add_child(_sub_viewport_container)
	move_child(_sub_viewport_container, bv_idx + 1)
	# 创建 SubViewport
	_sub_viewport = SubViewport.new()
	_sub_viewport.size = Vector2i(1280, 720)
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sub_viewport.transparent_bg = false
	_sub_viewport_container.add_child(_sub_viewport)
	# 创建 BoardView3D 并添加到 SubViewport
	_board_view_3d = BoardView3DScript.new()
	_sub_viewport.add_child(_board_view_3d)
	# 绑定管理器和信号
	_board_view_3d.bind_managers(_battle_flow.board_manager, _battle_flow.unit_manager)
	_board_view_3d.bind_battle_flow(_battle_flow)
	_board_view_3d.move_requested.connect(_on_move_requested)
	_board_view_3d.attack_requested.connect(_on_attack_requested)
	_board_view_3d.summon_requested.connect(_on_summon_requested)
	_board_view_3d.move_anim_done.connect(_on_board_move_anim_done)
	_board_view_3d.unit_selected.connect(func(uid: String): _portrait_hud.set_selected(uid))
	_board_view_3d.unit_deselected.connect(func(): _portrait_hud.set_selected(""))

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
	_use_3d = not _use_3d
	_board_view.visible = not _use_3d
	_sub_viewport_container.visible = _use_3d
	if _use_3d and _board_view_3d:
		_board_view_3d.rebuild_board()
		_update_camera_to_player()
	elif not _use_3d:
		_update_camera_to_player()
		_board_view.queue_redraw()

## v0.1.71：处理 3D 视图输入转发
func _input(event: InputEvent) -> void:
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

