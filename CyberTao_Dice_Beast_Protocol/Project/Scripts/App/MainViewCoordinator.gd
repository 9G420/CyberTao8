extends RefCounted
class_name MainViewCoordinator

const BoardViewScript = preload("res://Scripts/UI/BoardView.gd")
const DiceDebugPanelScript = preload("res://Scripts/UI/DiceDebugPanel.gd")
const SettingsPanelScript = preload("res://Scripts/UI/SettingsPanel.gd")
const CardBattlePanelScript = preload("res://Scripts/UI/CardBattlePanel.gd")
const CardRewardPanelScript = preload("res://Scripts/UI/CardRewardPanel.gd")
const DeckViewPanelScript = preload("res://Scripts/UI/DeckViewPanel.gd")
const ImageGenerationPanelScript = preload("res://Scripts/UI/ImageGenerationPanel.gd")
const CyberBackgroundScript = preload("res://Scripts/UI/CyberBackground.gd")
const TransitionOverlayScript = preload("res://Scripts/UI/TransitionOverlay.gd")
const MissionBriefOverlayScript = preload("res://Scripts/UI/MissionBriefOverlay.gd")
const UnitPortraitHUDScript = preload("res://Scripts/UI/UnitPortraitHUD.gd")
const ShopPanelScript = preload("res://Scripts/UI/ShopPanel.gd")
const BoardView3DScript = preload("res://Scripts/UI3D/BoardView3D.gd")

var board_view: BoardView = null
var board_view_3d: BoardView3D = null
var sub_viewport: SubViewport = null
var sub_viewport_container: SubViewportContainer = null
var dice_panel: DiceDebugPanel = null
var settings_panel: SettingsPanel = null
var card_battle_panel: CardBattlePanel = null
var card_reward_panel: CardRewardPanel = null
var deck_view_panel: DeckViewPanel = null
var image_generation_panel = null
var chapter_label: Label = null
var objective_label: Label = null
var result_label: Label = null
var restart_btn: Button = null
var dice_anim: DiceRollAnimation = null
var transition: TransitionOverlay = null
var mission_brief_overlay = null
var portrait_hud: UnitPortraitHUD = null
var shop_panel: ShopPanel = null
var view_switch_fx: ColorRect = null

func build_views(owner: Control, display_settings: DisplaySettings, audio: AudioManager, image_service) -> void:
	_call_owner(owner, "_setup_custom_cursor")

	var cyber_bg := CyberBackgroundScript.new()
	cyber_bg.set_board_rect(Vector2.ZERO, Vector2(1280, 720))
	owner.add_child(cyber_bg)

	board_view = BoardViewScript.new()
	board_view.position = Vector2.ZERO
	owner.add_child(board_view)

	portrait_hud = UnitPortraitHUDScript.new()
	owner.add_child(portrait_hud)

	dice_panel = DiceDebugPanelScript.new()
	dice_panel.position = Vector2(1012, 512)
	owner.add_child(dice_panel)

	var settings_btn := Button.new()
	settings_btn.text = "设置"
	settings_btn.position = Vector2(8, 8)
	settings_btn.size = Vector2(72, 28)
	settings_btn.add_theme_font_size_override("font_size", 12)
	settings_btn.pressed.connect(_owner_callable(owner, "_on_settings_pressed"))
	CyberStyle.style_button(settings_btn, "cyan")
	owner.add_child(settings_btn)

	var image_btn := Button.new()
	image_btn.text = "生图"
	image_btn.position = Vector2(88, 8)
	image_btn.size = Vector2(72, 28)
	image_btn.add_theme_font_size_override("font_size", 12)
	image_btn.pressed.connect(_owner_callable(owner, "_on_image_generation_pressed"))
	CyberStyle.style_button(image_btn, "orange")
	owner.add_child(image_btn)

	chapter_label = Label.new()
	chapter_label.position = Vector2(188, 10)
	chapter_label.size = Vector2(560, 24)
	chapter_label.add_theme_font_size_override("font_size", 18)
	chapter_label.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY)
	chapter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owner.add_child(chapter_label)

	objective_label = Label.new()
	objective_label.position = Vector2(188, 34)
	objective_label.size = Vector2(620, 20)
	objective_label.add_theme_font_size_override("font_size", 12)
	objective_label.add_theme_color_override("font_color", CyberStyle.TEXT_SECONDARY)
	objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owner.add_child(objective_label)

	settings_panel = SettingsPanelScript.new()
	settings_panel.position = Vector2(420, 100)
	owner.add_child(settings_panel)
	settings_panel.bind_display_settings(display_settings)
	settings_panel.bind_audio_manager(audio)

	image_generation_panel = ImageGenerationPanelScript.new()
	image_generation_panel.position = Vector2(210, 78)
	owner.add_child(image_generation_panel)
	image_generation_panel.bind_service(image_service)

	card_battle_panel = CardBattlePanelScript.new()
	card_battle_panel.position = Vector2.ZERO
	owner.add_child(card_battle_panel)

	card_reward_panel = CardRewardPanelScript.new()
	card_reward_panel.position = Vector2(380, 200)
	owner.add_child(card_reward_panel)

	deck_view_panel = DeckViewPanelScript.new()
	deck_view_panel.position = Vector2(160, 120)
	owner.add_child(deck_view_panel)

	shop_panel = ShopPanelScript.new()
	shop_panel.position = Vector2(400, 170)
	owner.add_child(shop_panel)

	view_switch_fx = ColorRect.new()
	view_switch_fx.position = Vector2.ZERO
	view_switch_fx.size = Vector2(1280, 720)
	view_switch_fx.color = Color(0.7, 0.1, 1.0, 0.0)
	view_switch_fx.visible = false
	view_switch_fx.z_index = 999
	view_switch_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	owner.add_child(view_switch_fx)

	result_label = Label.new()
	result_label.position = Vector2(0, 320)
	result_label.size = Vector2(1280, 60)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 36)
	result_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_label.visible = false
	owner.add_child(result_label)

	restart_btn = Button.new()
	restart_btn.text = "重新开始"
	restart_btn.position = Vector2(540, 384)
	restart_btn.size = Vector2(200, 40)
	restart_btn.add_theme_font_size_override("font_size", 16)
	restart_btn.visible = false
	restart_btn.pressed.connect(_owner_callable(owner, "_on_restart_pressed"))
	CyberStyle.style_button(restart_btn, "orange")
	owner.add_child(restart_btn)

	dice_anim = DiceRollAnimation.new()
	dice_anim.set_board_center(Vector2(640, 360))
	owner.add_child(dice_anim)

	transition = TransitionOverlayScript.new()
	owner.add_child(transition)

	mission_brief_overlay = MissionBriefOverlayScript.new()
	owner.add_child(mission_brief_overlay)

func wire_views(owner: Node, battle_flow: BattleFlowController, card_battle_ctrl: CardBattleController) -> void:
	board_view.bind_managers(battle_flow.board_manager, battle_flow.unit_manager)
	board_view.bind_battle_flow(battle_flow)
	board_view.move_requested.connect(_owner_callable(owner, "_on_move_requested"))
	board_view.attack_requested.connect(_owner_callable(owner, "_on_attack_requested"))
	board_view.summon_requested.connect(_owner_callable(owner, "_on_summon_requested"))
	battle_flow.phase_changed.connect(_owner_callable(owner, "_on_phase_changed"))
	battle_flow.attack_completed.connect(_owner_callable(owner, "_on_attack_completed"))
	battle_flow.enemy_attack_completed.connect(_owner_callable(owner, "_on_enemy_attack_completed"))
	battle_flow.summon_completed.connect(_owner_callable(owner, "_on_summon_completed"))
	battle_flow.terrain_damage_triggered.connect(_owner_callable(owner, "_on_terrain_damage_triggered"))
	battle_flow.item_picked_up.connect(_owner_callable(owner, "_on_item_picked_up"))
	battle_flow.enemy_action_announced.connect(_owner_callable(owner, "_on_enemy_action_announced"))
	battle_flow.enemy_turn_ended.connect(_owner_callable(owner, "_on_enemy_turn_ended"))
	battle_flow.encounter_triggered.connect(_owner_callable(owner, "_on_encounter_triggered"))
	battle_flow.encounter_resolved.connect(_owner_callable(owner, "_on_encounter_resolved"))
	battle_flow.heal_cell_triggered.connect(_owner_callable(owner, "_on_heal_cell_triggered"))
	battle_flow.event_cell_triggered.connect(_owner_callable(owner, "_on_event_cell_triggered"))
	battle_flow.defend_crest_used.connect(_owner_callable(owner, "_on_defend_crest_used"))
	battle_flow.skill_crest_used.connect(_owner_callable(owner, "_on_skill_crest_used"))
	battle_flow.trick_crest_used.connect(_owner_callable(owner, "_on_trick_crest_used"))
	battle_flow.shop_panel_requested.connect(_owner_callable(owner, "_on_shop_panel_requested"))
	shop_panel.shop_closed.connect(_owner_callable(owner, "_on_shop_closed"))
	battle_flow.chest_cell_triggered.connect(_owner_callable(owner, "_on_chest_cell_triggered"))
	battle_flow.floor_cleared.connect(_owner_callable(owner, "_on_floor_cleared"))
	battle_flow.game_won.connect(_owner_callable(owner, "_on_game_won"))
	battle_flow.boss_unlocked.connect(_owner_callable(owner, "_on_boss_unlocked"))
	battle_flow.portal_spawned.connect(_owner_callable(owner, "_on_portal_spawned"))
	battle_flow.hero_warped.connect(_owner_callable(owner, "_on_hero_warped"))
	battle_flow.enemy_turn_starting.connect(_owner_callable(owner, "_on_enemy_turn_starting"))
	dice_anim.animation_finished.connect(_owner_callable(owner, "_on_dice_anim_finished_forward"))
	battle_flow.move_completed.connect(_owner_callable(owner, "_on_move_completed_camera"))
	battle_flow.move_step_visual.connect(_owner_callable(owner, "_on_move_step_visual"))
	board_view.move_anim_done.connect(_owner_callable(owner, "_on_board_move_anim_done"))
	card_battle_ctrl.battle_ended.connect(_owner_callable(owner, "_on_card_battle_ended"))
	card_battle_ctrl.victory_reward.connect(_owner_callable(owner, "_on_card_battle_reward"))
	card_battle_ctrl.card_played.connect(_owner_callable(owner, "_on_card_played_sfx"))
	card_battle_ctrl.enemy_acted.connect(_owner_callable(owner, "_on_enemy_acted_sfx"))
	card_battle_ctrl.hand_changed.connect(_owner_callable(owner, "_on_hand_changed_sfx"))
	card_battle_panel.bind_controller(card_battle_ctrl)
	card_reward_panel.bind_controller(card_battle_ctrl)
	deck_view_panel.bind_controller(card_battle_ctrl)
	dice_panel.bind_battle_flow(battle_flow)
	dice_panel.bind_board_view(board_view)
	dice_panel.set_dice_animation(dice_anim)
	dice_panel.test_card_battle_requested.connect(_owner_callable(owner, "_on_test_card_battle_requested"))
	dice_panel.deck_view_requested.connect(_owner_callable(owner, "_on_deck_view_requested"))
	portrait_hud.bind_unit_manager(battle_flow.unit_manager)
	portrait_hud.portrait_clicked.connect(_owner_callable(owner, "_on_portrait_clicked"))
	board_view.unit_selected.connect(func(uid: String): portrait_hud.set_selected(uid))
	board_view.unit_deselected.connect(func(): portrait_hud.set_selected(""))
	if battle_flow.dice_manager and battle_flow.dice_manager.has_signal("dice_rolled"):
		battle_flow.dice_manager.dice_rolled.connect(_owner_callable(owner, "_on_dice_rolled_sfx"))

func setup_3d_view(owner: Control, battle_flow: BattleFlowController) -> void:
	sub_viewport_container = SubViewportContainer.new()
	sub_viewport_container.position = Vector2.ZERO
	sub_viewport_container.size = Vector2(1280, 720)
	sub_viewport_container.stretch = true
	sub_viewport_container.visible = false
	var board_view_index: int = board_view.get_index()
	owner.add_child(sub_viewport_container)
	owner.move_child(sub_viewport_container, board_view_index + 1)

	sub_viewport = SubViewport.new()
	sub_viewport.size = Vector2i(1280, 720)
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_viewport.transparent_bg = false
	sub_viewport_container.add_child(sub_viewport)

	board_view_3d = BoardView3DScript.new()
	sub_viewport.add_child(board_view_3d)

	board_view_3d.bind_managers(battle_flow.board_manager, battle_flow.unit_manager)
	board_view_3d.bind_battle_flow(battle_flow)
	board_view_3d.move_requested.connect(_owner_callable(owner, "_on_move_requested"))
	board_view_3d.attack_requested.connect(_owner_callable(owner, "_on_attack_requested"))
	board_view_3d.summon_requested.connect(_owner_callable(owner, "_on_summon_requested"))
	board_view_3d.move_anim_done.connect(_owner_callable(owner, "_on_board_move_anim_done"))
	board_view_3d.unit_selected.connect(func(uid: String): portrait_hud.set_selected(uid))
	board_view_3d.unit_deselected.connect(func(): portrait_hud.set_selected(""))

func _owner_callable(owner: Object, method_name: String) -> Callable:
	return Callable(owner, method_name)

func _call_owner(owner: Object, method_name: String) -> Variant:
	return _owner_callable(owner, method_name).call()
