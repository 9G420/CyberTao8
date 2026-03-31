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
var _card_list: RichTextLabel
var _close_button: Button

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(340, 440)
	size = Vector2(340, 440)
	pivot_offset = Vector2(170, 220)
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
	# 统计每种牌的数量
	var card_counts: Dictionary = {}
	for card in deck:
		var key: String = String(card["name"])
		if card_counts.has(key):
			card_counts[key]["count"] = int(card_counts[key]["count"]) + 1
		else:
			card_counts[key] = {
				"count": 1,
				"type": String(card["type"]),
				"cost": int(card.get("cost", 1)),
				"value": int(card.get("value", 0)),
				"upgraded": bool(card.get("upgraded", false)),
			}
	# 按费用排序后按名称排序
	var sorted_keys: Array[String] = []
	for k in card_counts.keys():
		sorted_keys.append(String(k))
	sorted_keys.sort()
	# 构建 BBCode 文本
	_card_list.clear()
	for card_name in sorted_keys:
		var info: Dictionary = card_counts[card_name]
		var count: int = int(info["count"])
		var card_type: String = String(info["type"])
		var cost: int = int(info["cost"])
		var value: int = int(info["value"])
		var type_display: String = _get_type_display(card_type)
		var type_color: Color = _get_type_color(card_type)
		var is_upgraded: bool = bool(info.get("upgraded", false))
		# 卡牌名称（带颜色，升级牌用青色高亮）
		if is_upgraded:
			_card_list.push_color(CyberStyle.TEXT_CYAN)
		else:
			_card_list.push_color(type_color)
		_card_list.append_text(card_name)
		_card_list.pop()
		# 数量
		if count > 1:
			_card_list.push_color(CyberStyle.ACCENT_ORANGE)
			_card_list.append_text(" x" + str(count))
			_card_list.pop()
		# 详情
		_card_list.push_color(CyberStyle.TEXT_SECONDARY)
		_card_list.append_text("  " + str(cost) + "E | " + type_display + " " + str(value))
		_card_list.pop()
		_card_list.append_text("\n")

func _get_type_display(card_type: String) -> String:
	match card_type:
		"attack":
			return "伤害"
		"defend":
			return "防御"
		"heal":
			return "回复"
		"pierce":
			return "穿透"
		"lifesteal":
			return "吸血"
		"shock":
			return "电击"
	return card_type

func _get_type_color(card_type: String) -> Color:
	match card_type:
		"attack":
			return CyberStyle.ACCENT_ORANGE
		"defend":
			return CyberStyle.ACCENT_CYAN
		"heal":
			return Color(0.3, 0.95, 0.65)
		"pierce":
			return CyberStyle.ACCENT_MAGENTA
		"lifesteal":
			return CyberStyle.ACCENT_MAGENTA
		"shock":
			return Color(0.6, 0.4, 1.0)
	return CyberStyle.TEXT_PRIMARY

# --- UI 构建 ---

func _build_ui() -> void:
	add_theme_stylebox_override("panel", CyberStyle.make_panel_bg(CyberStyle.ACCENT_CYAN, 8))

	_title_label = Label.new()
	_title_label.text = "当前牌组"
	_title_label.position = Vector2(0, 10)
	_title_label.size = Vector2(340, 28)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", CyberStyle.TEXT_TITLE)
	add_child(_title_label)

	_deck_size_label = Label.new()
	_deck_size_label.text = "牌组总数：10 张"
	_deck_size_label.position = Vector2(0, 38)
	_deck_size_label.size = Vector2(340, 20)
	_deck_size_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_deck_size_label.add_theme_font_size_override("font_size", 13)
	_deck_size_label.add_theme_color_override("font_color", CyberStyle.TEXT_CYAN)
	add_child(_deck_size_label)

	# 分隔线
	var sep := ColorRect.new()
	sep.position = Vector2(16, 62)
	sep.size = Vector2(308, 1)
	sep.color = Color(0.0, 0.75, 0.9, 0.3)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep)

	# 列标题
	var col_header := Label.new()
	col_header.text = "名称          费用 | 类型 数值"
	col_header.position = Vector2(16, 66)
	col_header.size = Vector2(308, 18)
	col_header.add_theme_font_size_override("font_size", 11)
	col_header.add_theme_color_override("font_color", CyberStyle.TEXT_MUTED)
	add_child(col_header)

	# 卡牌列表（RichTextLabel 支持滚动和 BBCode）
	_card_list = RichTextLabel.new()
	_card_list.position = Vector2(16, 86)
	_card_list.size = Vector2(308, 300)
	_card_list.scroll_active = true
	_card_list.add_theme_font_size_override("normal_font_size", 14)
	add_child(_card_list)

	# 关闭按钮
	_close_button = Button.new()
	_close_button.text = "关闭"
	_close_button.position = Vector2(120, 396)
	_close_button.size = Vector2(100, 32)
	_close_button.add_theme_font_size_override("font_size", 13)
	_close_button.pressed.connect(_on_close_pressed)
	CyberStyle.style_button(_close_button, "cyan")
	add_child(_close_button)

func _on_close_pressed() -> void:
	close()
