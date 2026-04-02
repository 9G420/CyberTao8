extends Panel
class_name DeckViewPanel

## 牌组查看面板（Day 16：构筑系统配套 UI）
## 棋盘阶段可查看当前持久牌组内容和大小
## 纯 UI 层，读取 CardBattleController.persistent_deck 显示

const CardBattleController = preload("res://Scripts/BattleV2/CardBattleController.gd")

var _controller: CardBattleController = null

# --- UI 引用 ---
var _title_label: Label
var _deck_size_label: Label
var _summary_label: Label
var _card_scroll: ScrollContainer
var _card_list_container: VBoxContainer
var _close_button: Button

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(360, 460)
	size = Vector2(360, 460)
	pivot_offset = Vector2(180, 230)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()

func bind_controller(controller: CardBattleController) -> void:
	_controller = controller

func open() -> void:
	if _controller == null:
		return
	_refresh_deck_list()
	mouse_filter = Control.MOUSE_FILTER_STOP
	UITransitions.popup(self)

func close() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITransitions.close(self)

func is_open() -> bool:
	return visible

# --- 刷新牌组列表 ---

func _refresh_deck_list() -> void:
	if _controller == null:
		return
	var deck: Array[Dictionary] = _controller.persistent_deck
	_deck_size_label.text = "牌组总数：" + str(deck.size()) + " 张 | 能量上限：" + str(_controller.max_energy)
	_summary_label.text = "按费用与类型整理，相同卡牌自动合并"
	_clear_deck_entries()
	var grouped_entries: Array[Dictionary] = CardRenderer.build_grouped_deck_entries(deck)
	for entry in grouped_entries:
		var card: Dictionary = entry.get("card", {})
		var count: int = int(entry.get("count", 1))
		var row: Panel = CardRenderer.create_card_row(card, {
			"width": 312.0,
			"count": count,
		})
		_card_list_container.add_child(row)

func _clear_deck_entries() -> void:
	for child in _card_list_container.get_children():
		child.queue_free()

# --- UI 构建 ---

func _build_ui() -> void:
	add_theme_stylebox_override("panel", CyberStyle.make_panel_bg(CyberStyle.ACCENT_CYAN, 8))

	_title_label = Label.new()
	_title_label.text = "当前牌组"
	_title_label.position = Vector2(0, 10)
	_title_label.size = Vector2(360, 28)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", CyberStyle.TEXT_TITLE)
	add_child(_title_label)

	_deck_size_label = Label.new()
	_deck_size_label.text = "牌组总数：10 张"
	_deck_size_label.position = Vector2(0, 38)
	_deck_size_label.size = Vector2(360, 20)
	_deck_size_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_deck_size_label.add_theme_font_size_override("font_size", 13)
	_deck_size_label.add_theme_color_override("font_color", CyberStyle.TEXT_CYAN)
	add_child(_deck_size_label)

	_summary_label = Label.new()
	_summary_label.text = "按费用与类型整理，相同卡牌自动合并"
	_summary_label.position = Vector2(18, 60)
	_summary_label.size = Vector2(324, 18)
	_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_label.add_theme_font_size_override("font_size", 11)
	_summary_label.add_theme_color_override("font_color", CyberStyle.TEXT_SECONDARY)
	add_child(_summary_label)

	var sep := ColorRect.new()
	sep.position = Vector2(18, 84)
	sep.size = Vector2(324, 1)
	sep.color = Color(0.0, 0.75, 0.9, 0.3)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep)

	_card_scroll = ScrollContainer.new()
	_card_scroll.position = Vector2(18, 94)
	_card_scroll.size = Vector2(324, 308)
	_card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_card_scroll)

	_card_list_container = VBoxContainer.new()
	_card_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card_list_container.add_theme_constant_override("separation", 8)
	_card_scroll.add_child(_card_list_container)

	_close_button = Button.new()
	_close_button.text = "关闭"
	_close_button.position = Vector2(130, 414)
	_close_button.size = Vector2(100, 32)
	_close_button.add_theme_font_size_override("font_size", 13)
	_close_button.pressed.connect(_on_close_pressed)
	CyberStyle.style_button(_close_button, "cyan")
	add_child(_close_button)

func _on_close_pressed() -> void:
	close()
