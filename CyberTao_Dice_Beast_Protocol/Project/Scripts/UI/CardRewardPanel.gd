extends Panel
class_name CardRewardPanel

## 卡牌奖励选择面板（Day 13：构筑成长）
## 战斗胜利后显示 3 张候选卡牌，玩家选 1 张加入持久牌组
## 纯 UI 层，所有逻辑委托给 CardBattleController

const CardBattleController = preload("res://Scripts/BattleV2/CardBattleController.gd")

var _controller: CardBattleController = null

# --- UI 引用 ---
var _title_label: Label
var _subtitle_label: Label
var _deck_info_label: Label
var _card_buttons: Array[Button] = []
var _card_detail_labels: Array[Label] = []
var _skip_button: Button

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(520, 320)
	size = Vector2(520, 320)
	_build_ui()

func bind_controller(controller: CardBattleController) -> void:
	_controller = controller
	if _controller.reward_cards_offered and not _controller.reward_cards_offered.is_connected(_on_reward_offered):
		_controller.reward_cards_offered.connect(_on_reward_offered)
	if _controller.reward_card_selected and not _controller.reward_card_selected.is_connected(_on_reward_selected):
		_controller.reward_card_selected.connect(_on_reward_selected)

# --- 控制器信号回调 ---

func _on_reward_offered(options: Array) -> void:
	_rebuild_card_options(options)
	_deck_info_label.text = "当前牌组：" + str(_controller.get_deck_size()) + " 张"
	visible = true

func _on_reward_selected(_card: Dictionary) -> void:
	_deck_info_label.text = "已选择！牌组：" + str(_controller.get_deck_size()) + " 张"
	_clear_card_options()
	await get_tree().create_timer(0.8).timeout
	visible = false

# --- 按钮回调 ---

func _on_card_option_pressed(index: int) -> void:
	if _controller:
		_controller.select_reward_card(index)

func _on_skip_pressed() -> void:
	if _controller:
		_controller.skip_reward()
	visible = false

# --- 动态卡牌选项 ---

func _rebuild_card_options(options: Array) -> void:
	_clear_card_options()
	var btn_w: float = 150.0
	var btn_h: float = 100.0
	var gap: float = 12.0
	var total_w: float = options.size() * btn_w + (options.size() - 1) * gap
	var start_x: float = (520.0 - total_w) / 2.0
	var start_y: float = 80.0
	for i in range(options.size()):
		var card: Dictionary = options[i]
		var btn := Button.new()
		btn.position = Vector2(start_x + i * (btn_w + gap), start_y)
		btn.size = Vector2(btn_w, btn_h)
		btn.text = String(card["name"])
		btn.add_theme_font_size_override("font_size", 16)
		CyberStyle.style_button(btn, "orange")
		var idx: int = i
		btn.pressed.connect(func(): _on_card_option_pressed(idx))
		add_child(btn)
		_card_buttons.append(btn)
		# 卡牌详情标签
		var detail := Label.new()
		var type_text: String = _get_type_display(String(card["type"]))
		var cost_text: String = str(int(card.get("cost", 1))) + "E"
		var value_text: String = str(int(card.get("value", 0)))
		detail.text = type_text + "\n" + cost_text + " | " + value_text
		detail.position = Vector2(start_x + i * (btn_w + gap), start_y + btn_h + 4)
		detail.size = Vector2(btn_w, 36)
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail.add_theme_font_size_override("font_size", 11)
		detail.add_theme_color_override("font_color", CyberStyle.TEXT_SECONDARY)
		add_child(detail)
		_card_detail_labels.append(detail)

func _clear_card_options() -> void:
	for btn in _card_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	_card_buttons = []
	for lbl in _card_detail_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	_card_detail_labels = []

func _get_type_display(card_type: String) -> String:
	match card_type:
		"attack":
			return "攻击"
		"defend":
			return "防御"
		"heal":
			return "回复"
		"pierce":
			return "穿透攻击"
		"lifesteal":
			return "吸血攻击"
		"shock":
			return "电击削弱"
	return card_type

# --- UI 构建 ---

func _build_ui() -> void:
	add_theme_stylebox_override("panel", CyberStyle.make_panel_bg(CyberStyle.ACCENT_MAGENTA, 8))

	_title_label = Label.new()
	_title_label.text = "战斗胜利 — 选择奖励卡牌"
	_title_label.position = Vector2(0, 10)
	_title_label.size = Vector2(520, 28)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", CyberStyle.TEXT_TITLE)
	add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.text = "选择 1 张卡牌加入你的牌组，或跳过"
	_subtitle_label.position = Vector2(0, 38)
	_subtitle_label.size = Vector2(520, 20)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_size_override("font_size", 12)
	_subtitle_label.add_theme_color_override("font_color", CyberStyle.TEXT_SECONDARY)
	add_child(_subtitle_label)

	_deck_info_label = Label.new()
	_deck_info_label.text = "当前牌组：10 张"
	_deck_info_label.position = Vector2(0, 56)
	_deck_info_label.size = Vector2(520, 18)
	_deck_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_deck_info_label.add_theme_font_size_override("font_size", 11)
	_deck_info_label.add_theme_color_override("font_color", CyberStyle.TEXT_CYAN)
	add_child(_deck_info_label)

	# 分隔线
	var sep := ColorRect.new()
	sep.position = Vector2(20, 74)
	sep.size = Vector2(480, 1)
	sep.color = Color(1.0, 0.2, 0.55, 0.3)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep)

	# 跳过按钮
	_skip_button = Button.new()
	_skip_button.text = "跳过"
	_skip_button.position = Vector2(200, 270)
	_skip_button.size = Vector2(120, 36)
	_skip_button.add_theme_font_size_override("font_size", 14)
	_skip_button.pressed.connect(_on_skip_pressed)
	CyberStyle.style_button(_skip_button, "cyan")
	add_child(_skip_button)
