extends Panel
class_name DiceDebugPanel

var battle_flow: Node = null
var dice_manager: Node = null
var phase_label: Label
var selected_label: Label
var roll_label: Label
var crest_label: RichTextLabel

func _ready() -> void:
	custom_minimum_size = Vector2(280, 440)
	size = Vector2(280, 440)
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
	title.text = "Dice Debug"
	title.position = Vector2(0, 12)
	title.size = Vector2(280, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.6))
	add_child(title)

	phase_label = Label.new()
	phase_label.text = "Phase: PLAYER_ROLL"
	phase_label.position = Vector2(20, 50)
	phase_label.size = Vector2(240, 24)
	phase_label.add_theme_font_size_override("font_size", 16)
	phase_label.add_theme_color_override("font_color", Color(0.72, 0.9, 0.84))
	add_child(phase_label)

	selected_label = Label.new()
	selected_label.text = "Selected: none"
	selected_label.position = Vector2(20, 76)
	selected_label.size = Vector2(240, 24)
	selected_label.add_theme_font_size_override("font_size", 15)
	selected_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	add_child(selected_label)

	var roll_button := Button.new()
	roll_button.text = "Roll Dice"
	roll_button.position = Vector2(20, 108)
	roll_button.size = Vector2(240, 42)
	roll_button.pressed.connect(_on_roll_pressed)
	add_child(roll_button)

	var path_button := Button.new()
	path_button.text = "Spawn Demo Path"
	path_button.position = Vector2(20, 158)
	path_button.size = Vector2(240, 42)
	path_button.pressed.connect(_on_spawn_path_pressed)
	add_child(path_button)

	roll_label = Label.new()
	roll_label.text = "Last roll: -"
	roll_label.position = Vector2(20, 214)
	roll_label.size = Vector2(240, 50)
	roll_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	roll_label.add_theme_font_size_override("font_size", 15)
	roll_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.72))
	add_child(roll_label)

	crest_label = RichTextLabel.new()
	crest_label.position = Vector2(20, 270)
	crest_label.size = Vector2(240, 150)
	crest_label.scroll_active = false
	crest_label.add_theme_font_size_override("normal_font_size", 15)
	add_child(crest_label)

func _on_roll_pressed() -> void:
	if battle_flow:
		battle_flow.start_player_roll()

func _on_spawn_path_pressed() -> void:
	if battle_flow:
		battle_flow.spawn_demo_path()

func _on_phase_changed(phase_name: String) -> void:
	phase_label.text = "Phase: " + phase_name

func _on_dice_rolled(results: Array[String], next_crest_pool: Dictionary) -> void:
	roll_label.text = "Last roll: " + ", ".join(results)
	_refresh_crest_pool(next_crest_pool)

func _on_unit_selected(unit_id: String) -> void:
	selected_label.text = "Selected: " + unit_id

func _on_unit_deselected() -> void:
	selected_label.text = "Selected: none"

func _on_move_completed(_unit_id: String, _from_cell: Vector2i, _to_cell: Vector2i) -> void:
	_refresh_crest_pool()

func _refresh_crest_pool(next_crest_pool: Dictionary = {}) -> void:
	var pool: Dictionary = next_crest_pool
	if pool.is_empty() and dice_manager:
		pool = dice_manager.crest_pool
	crest_label.clear()
	crest_label.append_text("summon: " + str(pool.get("summon", 0)) + "\n")
	crest_label.append_text("move: " + str(pool.get("move", 0)) + "\n")
	crest_label.append_text("attack: " + str(pool.get("attack", 0)) + "\n")
	crest_label.append_text("defend: " + str(pool.get("defend", 0)) + "\n")
	crest_label.append_text("skill: " + str(pool.get("skill", 0)) + "\n")
	crest_label.append_text("trick: " + str(pool.get("trick", 0)) + "\n")
