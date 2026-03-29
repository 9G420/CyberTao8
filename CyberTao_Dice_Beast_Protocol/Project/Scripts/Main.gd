extends Control

const BattleFlowController = preload("res://Scripts/BattleV2/BattleFlowController.gd")
const BoardView = preload("res://Scripts/UI/BoardView.gd")
const DiceDebugPanel = preload("res://Scripts/UI/DiceDebugPanel.gd")
const DisplaySettings = preload("res://Scripts/System/DisplaySettings.gd")
const SettingsPanel = preload("res://Scripts/UI/SettingsPanel.gd")

var _battle_flow: BattleFlowController
var _board_view: BoardView
var _dice_panel: DiceDebugPanel
var _display_settings: DisplaySettings
var _settings_panel: SettingsPanel
var _result_label: Label
var _restart_btn: Button
var _last_attack_damage: int = 0

func _ready() -> void:
	_display_settings = DisplaySettings.new()
	add_child(_display_settings)
	_battle_flow = BattleFlowController.new()
	add_child(_battle_flow)
	_build_debug_view()
	_wire_debug_views()

func _build_debug_view() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.06, 0.1)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title := Label.new()
	title.text = "CyberTao：骰兽协议"
	title.position = Vector2(0, 4)
	title.size = Vector2(1280, 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.56, 0.26))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "原型战斗沙盒已启动：掷骰、移动、攻击、结束回合"
	subtitle.position = Vector2(0, 44)
	subtitle.size = Vector2(1280, 26)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.9, 0.86))
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)

	var hint := Label.new()
	hint.text = "左侧棋盘：点击单位后 青色=移动 红色=攻击 紫色=召唤 | 金色=高台 暗红=陷阱"
	hint.position = Vector2(0, 68)
	hint.size = Vector2(1280, 22)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.98, 0.86, 0.58))
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
	settings_btn.pressed.connect(_on_settings_pressed)
	add_child(settings_btn)

	_settings_panel = SettingsPanel.new()
	_settings_panel.position = Vector2(440, 130)
	add_child(_settings_panel)
	_settings_panel.bind_display_settings(_display_settings)

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
	_restart_btn.visible = false
	_restart_btn.pressed.connect(_on_restart_pressed)
	add_child(_restart_btn)

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
	_dice_panel.bind_battle_flow(_battle_flow)
	_dice_panel.bind_board_view(_board_view)

func _on_move_requested(unit_id: String, target_cell: Vector2i) -> void:
	var success: bool = _battle_flow.try_move_unit(unit_id, target_cell)
	_board_view.highlight_cells = _battle_flow.get_reachable_cells_for(unit_id)
	_board_view.attack_highlight_cells = _battle_flow.get_attackable_cells_for(unit_id)
	_board_view.summon_highlight_cells = _board_view._filter_summon_cells(_battle_flow.get_summon_cells_for(unit_id))
	_board_view.queue_redraw()

func _on_attack_requested(unit_id: String, target_cell: Vector2i) -> void:
	var success: bool = _battle_flow.try_attack_unit(unit_id, target_cell)
	if success:
		_board_view.play_attack_feedback(target_cell, _last_attack_damage)
	_board_view.highlight_cells = _battle_flow.get_reachable_cells_for(unit_id)
	_board_view.attack_highlight_cells = _battle_flow.get_attackable_cells_for(unit_id)
	_board_view.summon_highlight_cells = _board_view._filter_summon_cells(_battle_flow.get_summon_cells_for(unit_id))
	_board_view.queue_redraw()

func _on_summon_requested(unit_id: String, target_cell: Vector2i) -> void:
	var success: bool = _battle_flow.try_summon(unit_id, target_cell)
	_board_view.highlight_cells = _battle_flow.get_reachable_cells_for(unit_id)
	_board_view.attack_highlight_cells = _battle_flow.get_attackable_cells_for(unit_id)
	_board_view.summon_highlight_cells = _board_view._filter_summon_cells(_battle_flow.get_summon_cells_for(unit_id))
	_board_view.queue_redraw()

func _on_phase_changed(phase_name: String) -> void:
	if phase_name == "VICTORY":
		_result_label.text = "胜利"
		_result_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
		_result_label.visible = true
		_restart_btn.visible = true
	elif phase_name == "DEFEAT":
		_result_label.text = "失败"
		_result_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		_result_label.visible = true
		_restart_btn.visible = true
	else:
		_result_label.visible = false
		_restart_btn.visible = false

func _on_attack_completed(attacker_id: String, defender_id: String, damage: int, killed: bool) -> void:
	_last_attack_damage = damage

func _on_enemy_attack_completed(attacker_id: String, defender_id: String, damage: int, killed: bool, target_cell: Vector2i) -> void:
	# 敌方攻击时在目标格显示受击反馈
	_board_view.play_attack_feedback(target_cell, damage)

func _on_summon_completed(unit_id: String, path_cells_created: Array[Vector2i], spawn_cell: Vector2i) -> void:
	# 召唤完成后刷新棋盘
	_board_view.queue_redraw()

func _on_terrain_damage_triggered(unit_id: String, cell: Vector2i, damage: int, terrain_type: String) -> void:
	# 地形伤害反馈：在受伤格显示伤害飘字
	_board_view.play_attack_feedback(cell, damage)
	_board_view.queue_redraw()

func _on_restart_pressed() -> void:
	_board_view.selected_unit_id = ""
	_board_view.highlight_cells = []
	_board_view.attack_highlight_cells = []
	_board_view.summon_highlight_cells = []
	_battle_flow.restart_battle()
	_board_view.queue_redraw()

func _on_settings_pressed() -> void:
	_settings_panel.open()
