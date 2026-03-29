extends Node
class_name BattleFlowController

const DiceManager = preload("res://Scripts/BattleV2/DiceManager.gd")
const BoardManager = preload("res://Scripts/BattleV2/BoardManager.gd")
const UnitManager = preload("res://Scripts/BattleV2/UnitManager.gd")
const ActionResolver = preload("res://Scripts/BattleV2/ActionResolver.gd")
const BuffManager = preload("res://Scripts/BattleV2/BuffManager.gd")
const BattleAI = preload("res://Scripts/BattleV2/BattleAI.gd")

enum BattlePhase {
	BOOT,
	PLAYER_ROLL,
	PLAYER_ACTION,
	ENEMY_ROLL,
	ENEMY_ACTION,
	RESOLUTION,
	VICTORY,
	DEFEAT,
}

var current_phase: BattlePhase = BattlePhase.BOOT
var round_index: int = 0

var dice_manager: DiceManager
var board_manager: BoardManager
var unit_manager: UnitManager
var action_resolver: ActionResolver
var buff_manager: BuffManager
var battle_ai: BattleAI

func _ready() -> void:
	_bootstrap()

func _bootstrap() -> void:
	dice_manager = DiceManager.new()
	board_manager = BoardManager.new()
	unit_manager = UnitManager.new()
	action_resolver = ActionResolver.new()
	buff_manager = BuffManager.new()
	battle_ai = BattleAI.new()

	add_child(dice_manager)
	add_child(board_manager)
	add_child(unit_manager)
	add_child(action_resolver)
	add_child(buff_manager)
	add_child(battle_ai)

	action_resolver.board_manager = board_manager
	action_resolver.unit_manager = unit_manager
	action_resolver.buff_manager = buff_manager
	battle_ai.board_manager = board_manager
	battle_ai.unit_manager = unit_manager
	battle_ai.action_resolver = action_resolver

	board_manager.build_test_board(Vector2i(8, 8))
	current_phase = BattlePhase.PLAYER_ROLL
	round_index = 1

func start_player_roll() -> void:
	current_phase = BattlePhase.PLAYER_ROLL
	dice_manager.roll_turn_dice()

func enter_player_action() -> void:
	current_phase = BattlePhase.PLAYER_ACTION

func start_enemy_roll() -> void:
	current_phase = BattlePhase.ENEMY_ROLL
	dice_manager.roll_turn_dice()

func enter_enemy_action() -> void:
	current_phase = BattlePhase.ENEMY_ACTION

func mark_victory() -> void:
	current_phase = BattlePhase.VICTORY

func mark_defeat() -> void:
	current_phase = BattlePhase.DEFEAT
