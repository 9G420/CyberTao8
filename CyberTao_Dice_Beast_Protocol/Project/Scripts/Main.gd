extends Control

const BattleFlowController = preload("res://Scripts/BattleV2/BattleFlowController.gd")
const BoardView = preload("res://Scripts/UI/BoardView.gd")
const DiceDebugPanel = preload("res://Scripts/UI/DiceDebugPanel.gd")

var _battle_flow: BattleFlowController
var _board_view: BoardView
var _dice_panel: DiceDebugPanel

func _ready() -> void:
	_battle_flow = BattleFlowController.new()
	add_child(_battle_flow)
	_build_debug_view()
	_wire_debug_views()

func _build_debug_view() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.06, 0.1)
	add_child(bg)

	var title := Label.new()
	title.text = "CyberTao: Dice Beast Protocol"
	title.position = Vector2(0, 56)
	title.size = Vector2(1280, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.56, 0.26))
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Parallel rebuild scaffold active"
	subtitle.position = Vector2(0, 104)
	subtitle.size = Vector2(1280, 28)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.9, 0.86))
	add_child(subtitle)

	_board_view = BoardView.new()
	_board_view.position = Vector2(80, 170)
	add_child(_board_view)

	_dice_panel = DiceDebugPanel.new()
	_dice_panel.position = Vector2(920, 170)
	add_child(_dice_panel)

func _wire_debug_views() -> void:
	_board_view.bind_managers(_battle_flow.board_manager, _battle_flow.unit_manager)
	_dice_panel.bind_battle_flow(_battle_flow)
