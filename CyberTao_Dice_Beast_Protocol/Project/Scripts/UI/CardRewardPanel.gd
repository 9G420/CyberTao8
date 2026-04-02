extends Panel
class_name CardRewardPanel

## 卡牌奖励/升级选择面板（Day 18：卡牌升级机制）
## 战斗胜利后显示两种选择：获取新牌 / 升级已有牌
## 纯 UI 层，所有逻辑委托给 CardBattleController

const CardBattleController = preload("res://Scripts/BattleV2/CardBattleController.gd")

var _controller: CardBattleController = null

# --- 模式控制 ---
var _upgrade_mode: bool = false

# --- UI 引用 ---
var _title_label: Label
var _subtitle_label: Label
var _deck_info_label: Label
var _options_scroll: ScrollContainer
var _options_grid: GridContainer
var _skip_button: Button
var _upgrade_toggle_button: Button
var _back_button: Button

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(560, 420)
	size = Vector2(560, 420)
	pivot_offset = Vector2(280, 210)
	_build_ui()

func bind_controller(controller: CardBattleController) -> void:
	_controller = controller
	if _controller.reward_cards_offered and not _controller.reward_cards_offered.is_connected(_on_reward_offered):
		_controller.reward_cards_offered.connect(_on_reward_offered)
	if _controller.reward_card_selected and not _controller.reward_card_selected.is_connected(_on_reward_selected):
		_controller.reward_card_selected.connect(_on_reward_selected)
	if _controller.card_upgrade_completed and not _controller.card_upgrade_completed.is_connected(_on_card_upgraded):
		_controller.card_upgrade_completed.connect(_on_card_upgraded)

# --- 控制器信号回调 ---

func _on_reward_offered(options: Array) -> void:
	_upgrade_mode = false
	_rebuild_card_options(options)
	_deck_info_label.text = "当前牌组：" + str(_controller.get_deck_size()) + " 张 | 能量上限：" + str(_controller.max_energy)
	_title_label.text = "战斗胜利 — 选择奖励卡牌"
	_subtitle_label.text = "选择 1 张加入牌组，或升级已有牌，或跳过"
	_upgrade_toggle_button.visible = true
	_back_button.visible = false
	_skip_button.visible = true
	# 检查是否有可升级的牌
	var upgradeable: Array[int] = _controller.get_upgradeable_indices()
	_upgrade_toggle_button.disabled = upgradeable.is_empty()
	UITransitions.popup(self)

func _on_reward_selected(_card: Dictionary) -> void:
	_deck_info_label.text = "已选择！牌组：" + str(_controller.get_deck_size()) + " 张"
	_clear_card_options()
	_upgrade_toggle_button.visible = false
	_back_button.visible = false
	await get_tree().create_timer(0.8).timeout
	await UITransitions.close_await(self)

func _on_card_upgraded(old_card: Dictionary, new_card: Dictionary) -> void:
	_deck_info_label.text = "升级完成！" + String(old_card["name"]) + " → " + String(new_card["name"])
	_clear_card_options()
	_upgrade_toggle_button.visible = false
	_back_button.visible = false
	_skip_button.visible = false
	await get_tree().create_timer(1.0).timeout
	await UITransitions.close_await(self)

# --- 按钮回调 ---

func _on_card_option_pressed(index: int) -> void:
	if _controller == null:
		return
	if _upgrade_mode:
		_controller.upgrade_deck_card(index)
	else:
		_controller.select_reward_card(index)

func _on_skip_pressed() -> void:
	if _controller:
		_controller.skip_reward()
	UITransitions.close(self)

func _on_upgrade_toggle_pressed() -> void:
	if _controller == null:
		return
	_upgrade_mode = true
	_title_label.text = "升级卡牌 — 选择一张强化"
	_subtitle_label.text = "选择要升级的卡牌（数值提升，费用不变）"
	_upgrade_toggle_button.visible = false
	_back_button.visible = true
	_rebuild_upgrade_options()

func _on_back_pressed() -> void:
	if _controller == null:
		return
	_upgrade_mode = false
	_title_label.text = "战斗胜利 — 选择奖励卡牌"
	_subtitle_label.text = "选择 1 张加入牌组，或升级已有牌，或跳过"
	_back_button.visible = false
	_upgrade_toggle_button.visible = true
	_rebuild_card_options(_controller.get_reward_options())

# --- 动态卡牌选项（奖励模式） ---

func _rebuild_card_options(options: Array) -> void:
	_clear_card_options()
	_options_grid.columns = 3
	for i in range(options.size()):
		var card: Dictionary = options[i]
		var tile: Panel = CardRenderer.create_collection_tile(card, {
			"interactive": true,
			"callback": Callable(self, "_on_card_option_pressed"),
			"index": i,
			"footer_text": "点击纳入牌组",
		})
		_options_grid.add_child(tile)

# --- 动态卡牌选项（升级模式） ---

func _rebuild_upgrade_options() -> void:
	_clear_card_options()
	if _controller == null:
		return
	var grouped: Dictionary = {}
	for deck_index in _controller.get_upgradeable_indices():
		var card: Dictionary = _controller.persistent_deck[deck_index]
		var key: String = String(card.get("name", "")) + "|" + CardRenderer.format_card_meta(card) + "|" + CardRenderer.format_card_summary(card)
		if grouped.has(key):
			grouped[key]["count"] = int(grouped[key]["count"]) + 1
		else:
			grouped[key] = {
				"card": card,
				"count": 1,
				"deck_index": deck_index,
			}
	var entries: Array[Dictionary] = []
	for entry in grouped.values():
		entries.append(entry)
	entries.sort_custom(func(a, b): return CardRenderer.is_card_before(a.get("card", {}), b.get("card", {})))
	_options_grid.columns = 3
	for entry in entries:
		var card: Dictionary = entry.get("card", {})
		var upgraded: Dictionary = CardBattleController.get_card_upgrade(card)
		var tile: Panel = CardRenderer.create_collection_tile(card, {
			"interactive": true,
			"callback": Callable(self, "_on_card_option_pressed"),
			"index": int(entry.get("deck_index", -1)),
			"count": int(entry.get("count", 1)),
			"compare_card": upgraded,
			"footer_text": "点击升级该牌",
		})
		_options_grid.add_child(tile)

func _clear_card_options() -> void:
	for child in _options_grid.get_children():
		child.queue_free()

# --- UI 构建 ---

func _build_ui() -> void:
	add_theme_stylebox_override("panel", CyberStyle.make_panel_bg(CyberStyle.ACCENT_MAGENTA, 8))

	_title_label = Label.new()
	_title_label.text = "战斗胜利 — 选择奖励卡牌"
	_title_label.position = Vector2(0, 12)
	_title_label.size = Vector2(560, 28)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", CyberStyle.TEXT_TITLE)
	add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.text = "选择 1 张加入牌组，或升级已有牌，或跳过"
	_subtitle_label.position = Vector2(0, 42)
	_subtitle_label.size = Vector2(560, 20)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_size_override("font_size", 12)
	_subtitle_label.add_theme_color_override("font_color", CyberStyle.TEXT_SECONDARY)
	add_child(_subtitle_label)

	_deck_info_label = Label.new()
	_deck_info_label.text = "当前牌组：10 张"
	_deck_info_label.position = Vector2(0, 62)
	_deck_info_label.size = Vector2(560, 18)
	_deck_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_deck_info_label.add_theme_font_size_override("font_size", 11)
	_deck_info_label.add_theme_color_override("font_color", CyberStyle.TEXT_CYAN)
	add_child(_deck_info_label)

	var sep := ColorRect.new()
	sep.position = Vector2(20, 86)
	sep.size = Vector2(520, 1)
	sep.color = Color(1.0, 0.2, 0.55, 0.3)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep)

	_options_scroll = ScrollContainer.new()
	_options_scroll.position = Vector2(18, 98)
	_options_scroll.size = Vector2(524, 244)
	_options_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_options_scroll)

	_options_grid = GridContainer.new()
	_options_grid.columns = 3
	_options_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_options_grid.add_theme_constant_override("h_separation", 10)
	_options_grid.add_theme_constant_override("v_separation", 10)
	_options_scroll.add_child(_options_grid)

	_upgrade_toggle_button = Button.new()
	_upgrade_toggle_button.text = "升级卡牌"
	_upgrade_toggle_button.position = Vector2(40, 362)
	_upgrade_toggle_button.size = Vector2(130, 36)
	_upgrade_toggle_button.add_theme_font_size_override("font_size", 14)
	_upgrade_toggle_button.pressed.connect(_on_upgrade_toggle_pressed)
	CyberStyle.style_button(_upgrade_toggle_button, "orange")
	add_child(_upgrade_toggle_button)

	_back_button = Button.new()
	_back_button.text = "返回选牌"
	_back_button.position = Vector2(40, 362)
	_back_button.size = Vector2(130, 36)
	_back_button.add_theme_font_size_override("font_size", 14)
	_back_button.visible = false
	_back_button.pressed.connect(_on_back_pressed)
	CyberStyle.style_button(_back_button, "cyan")
	add_child(_back_button)

	_skip_button = Button.new()
	_skip_button.text = "跳过"
	_skip_button.position = Vector2(390, 362)
	_skip_button.size = Vector2(130, 36)
	_skip_button.add_theme_font_size_override("font_size", 14)
	_skip_button.pressed.connect(_on_skip_pressed)
	CyberStyle.style_button(_skip_button, "cyan")
	add_child(_skip_button)
