extends Panel
class_name ShopPanel

## 商店面板（v0.1.78：商品池扩展）
## 玩家踩到商店格后弹出，展示 3 件随机商品，用 crest 购买
## 纯 UI 层，购买效果在面板内直接结算（引用 dice_manager/unit_manager/card_battle_ctrl）

signal shop_closed

# --- 商品池定义 ---
const SHOP_ITEM_POOL: Array = [
	{"id": "heal_small", "name": "修复药剂", "desc": "回复 3 HP", "cost_type": "move", "cost_amount": 1, "effect": "heal", "value": 3},
	{"id": "heal_large", "name": "高级修复", "desc": "回复 6 HP", "cost_type": "move", "cost_amount": 2, "effect": "heal", "value": 6},
	{"id": "atk_boost", "name": "攻击芯片", "desc": "本层 ATK+1", "cost_type": "attack", "cost_amount": 1, "effect": "atk_boost", "value": 1},
	{"id": "def_boost", "name": "防御芯片", "desc": "本层 DEF+1", "cost_type": "defend", "cost_amount": 1, "effect": "def_boost", "value": 1},
	{"id": "energy_up", "name": "能量核心", "desc": "最大能量+1（上限5）", "cost_type": "skill", "cost_amount": 2, "effect": "energy_up", "value": 1},
	{"id": "add_card", "name": "数据芯片", "desc": "随机获得1张卡牌加入牌组", "cost_type": "trick", "cost_amount": 1, "effect": "add_card", "value": 1},
	{"id": "remove_card", "name": "数据清洗", "desc": "手动选择移除牌组中的1张牌", "cost_type": "skill", "cost_amount": 1, "effect": "remove_card", "value": 1},
	{"id": "random_crest", "name": "赛博彩票", "desc": "随机获得2个crest资源", "cost_type": "move", "cost_amount": 2, "effect": "random_crest", "value": 2},
	{"id": "max_hp_up", "name": "生体强化", "desc": "最大HP+2（同时回复2HP）", "cost_type": "defend", "cost_amount": 2, "effect": "max_hp_up", "value": 2},
]

const ITEMS_PER_SHOP: int = 3

# --- 外部引用 ---
var _dice_manager = null
var _unit_manager = null
var _card_battle_ctrl = null
var _unit_id: String = ""

# --- 当前商品 ---
var _current_items: Array = []

# --- UI 引用 ---
var _title_label: Label
var _crest_info_label: Label
var _item_containers: Array[Control] = []
var _buy_buttons: Array[Button] = []
var _item_name_labels: Array[Label] = []
var _item_desc_labels: Array[Label] = []
var _item_cost_labels: Array[Label] = []
var _status_label: Label
var _close_button: Button

# --- remove_card 手动选择 UI ---
var _remove_picker_overlay: ColorRect
var _remove_picker_panel: Panel
var _remove_picker_title: Label
var _remove_picker_list: VBoxContainer
var _remove_picker_cancel_btn: Button
var _pending_remove_item: Dictionary = {}

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(480, 380)
	size = Vector2(480, 380)
	pivot_offset = Vector2(240, 190)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_build_remove_picker_ui()

# --- 公开方法 ---

func open_shop(unit_id: String, dice_mgr, unit_mgr, card_battle_ctrl) -> void:
	_unit_id = unit_id
	_dice_manager = dice_mgr
	_unit_manager = unit_mgr
	_card_battle_ctrl = card_battle_ctrl
	_current_items = _pick_random_items()
	_status_label.text = ""
	_refresh_display()
	UITransitions.popup(self)

# --- 商品生成 ---

func _pick_random_items() -> Array:
	var pool: Array = SHOP_ITEM_POOL.duplicate()
	# 过滤不适用的商品
	if _card_battle_ctrl != null and int(_card_battle_ctrl.max_energy) >= 5:
		pool = pool.filter(func(item): return item["id"] != "energy_up")
	# 牌组过小（<=3张）时不提供移除
	if _card_battle_ctrl != null and _card_battle_ctrl.get_deck_size() <= 3:
		pool = pool.filter(func(item): return item["id"] != "remove_card")
	pool.shuffle()
	var count: int = min(ITEMS_PER_SHOP, pool.size())
	var result: Array = []
	for i in range(count):
		result.append(pool[i].duplicate())
	return result

# --- 显示刷新 ---

func _refresh_display() -> void:
	# 更新 crest 信息
	if _dice_manager != null:
		var pool: Dictionary = _dice_manager.crest_pool
		var parts: Array[String] = []
		for crest_type in ["move", "attack", "defend", "skill", "trick", "summon"]:
			var count: int = int(pool.get(crest_type, 0))
			if count > 0:
				parts.append(_crest_display_name(crest_type) + ":" + str(count))
		_crest_info_label.text = "持有资源：" + (" | ".join(parts) if parts.size() > 0 else "无")
	# 更新每件商品
	for i in range(ITEMS_PER_SHOP):
		if i < _current_items.size():
			var item: Dictionary = _current_items[i]
			_item_containers[i].visible = true
			_item_name_labels[i].text = String(item["name"])
			_item_desc_labels[i].text = String(item["desc"])
			var cost_type: String = String(item["cost_type"])
			var cost_amount: int = int(item["cost_amount"])
			_item_cost_labels[i].text = _crest_display_name(cost_type) + " x" + str(cost_amount)
			# 检查是否可购买
			var can_buy: bool = _can_purchase(item)
			_buy_buttons[i].disabled = not can_buy
			if can_buy:
				_item_cost_labels[i].add_theme_color_override("font_color", CyberStyle.TEXT_CYAN)
			else:
				_item_cost_labels[i].add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.7))
		else:
			_item_containers[i].visible = false

# --- 购买判定 ---

func _can_purchase(item: Dictionary) -> bool:
	if _dice_manager == null or _unit_manager == null:
		return false
	var cost: Dictionary = {String(item["cost_type"]): int(item["cost_amount"])}
	if not _dice_manager.can_pay(cost):
		return false
	# 治疗类：检查 HP 是否已满
	var effect: String = String(item["effect"])
	if effect == "heal":
		var unit: Dictionary = _unit_manager.get_unit(_unit_id)
		if unit.is_empty():
			return false
		if int(unit.get("hp", 0)) >= int(unit.get("max_hp", 1)):
			return false
	# 能量核心：检查上限
	if effect == "energy_up":
		if _card_battle_ctrl == null or int(_card_battle_ctrl.max_energy) >= 5:
			return false
	# 加牌/移除牌：需要 card_battle_ctrl
	if effect == "add_card" or effect == "remove_card":
		if _card_battle_ctrl == null:
			return false
	# 移除牌：牌组过小不允许
	if effect == "remove_card":
		if _card_battle_ctrl.get_deck_size() <= 3:
			return false
	return true

# --- 购买执行 ---

func _execute_purchase(item: Dictionary, remove_deck_index: int = -1) -> String:
	var cost: Dictionary = {String(item["cost_type"]): int(item["cost_amount"])}
	if not _dice_manager.pay(cost):
		return "资源不足"
	var effect: String = String(item["effect"])
	var value: int = int(item["value"])
	match effect:
		"heal":
			var unit: Dictionary = _unit_manager.get_unit(_unit_id)
			if unit.is_empty():
				return "单位不存在"
			var current_hp: int = int(unit.get("hp", 0))
			var max_hp: int = int(unit.get("max_hp", 1))
			var actual_heal: int = min(value, max_hp - current_hp)
			unit["hp"] = current_hp + actual_heal
			_unit_manager.units_by_id[_unit_id] = unit
			_unit_manager.emit_signal("units_changed")
			return "HP+" + str(actual_heal)
		"atk_boost":
			var unit: Dictionary = _unit_manager.get_unit(_unit_id)
			if unit.is_empty():
				return "单位不存在"
			var current_atk: int = int(unit.get("atk", 0))
			unit["atk"] = current_atk + value
			_unit_manager.units_by_id[_unit_id] = unit
			_unit_manager.emit_signal("units_changed")
			return "ATK+" + str(value)
		"def_boost":
			var unit: Dictionary = _unit_manager.get_unit(_unit_id)
			if unit.is_empty():
				return "单位不存在"
			var current_def: int = int(unit.get("def", 0))
			unit["def"] = current_def + value
			_unit_manager.units_by_id[_unit_id] = unit
			_unit_manager.emit_signal("units_changed")
			return "DEF+" + str(value)
		"energy_up":
			if _card_battle_ctrl != null:
				_card_battle_ctrl.max_energy = int(_card_battle_ctrl.max_energy) + value
				return "最大能量+" + str(value)
			return "无效"
		"add_card":
			if _card_battle_ctrl == null:
				return "无效"
			var pool: Array = CardBattleController._build_reward_pool()
			if pool.is_empty():
				return "无效"
			var card: Dictionary = pool[randi() % pool.size()].duplicate()
			_card_battle_ctrl.persistent_deck.append(card)
			return "获得「" + String(card["name"]) + "」"
		"remove_card":
			if _card_battle_ctrl == null:
				return "无效"
			var deck: Array = _card_battle_ctrl.persistent_deck
			if deck.size() <= 3:
				return "牌组过小"
			if remove_deck_index < 0 or remove_deck_index >= deck.size():
				return "未选择卡牌"
			var removed: Dictionary = deck[remove_deck_index]
			deck.remove_at(remove_deck_index)
			return "移除「" + String(removed["name"]) + "」"
		"random_crest":
			var crest_types: Array = ["move", "attack", "defend", "skill", "trick", "summon"]
			var gained: Array = []
			for _i in range(value):
				var picked: String = crest_types[randi() % crest_types.size()]
				_dice_manager.crest_pool[picked] = int(_dice_manager.crest_pool.get(picked, 0)) + 1
				gained.append(_crest_display_name(picked))
			return "+" + "+".join(gained)
		"max_hp_up":
			var unit: Dictionary = _unit_manager.get_unit(_unit_id)
			if unit.is_empty():
				return "单位不存在"
			var old_max: int = int(unit.get("max_hp", 1))
			unit["max_hp"] = old_max + value
			unit["hp"] = int(unit.get("hp", 0)) + value
			_unit_manager.units_by_id[_unit_id] = unit
			_unit_manager.emit_signal("units_changed")
			return "最大HP+" + str(value)
	return ""

# --- 按钮回调 ---

func _on_buy_pressed(index: int) -> void:
	if index < 0 or index >= _current_items.size():
		return
	var item: Dictionary = _current_items[index]
	if String(item.get("effect", "")) == "remove_card":
		_open_remove_picker(item)
		return
	var result: String = _execute_purchase(item)
	_apply_purchase_result(item, result)
	_refresh_display()

func _apply_purchase_result(item: Dictionary, result: String) -> void:
	if result != "" and result != "资源不足" and result != "单位不存在" and result != "无效" and result != "未选择卡牌":
		_status_label.text = "购买成功：" + String(item["name"]) + "（" + result + "）"
		_status_label.add_theme_color_override("font_color", CyberStyle.NEON_TEAL)
	else:
		_status_label.text = "购买失败：" + result
		_status_label.add_theme_color_override("font_color", CyberStyle.ACCENT_ORANGE)

func _open_remove_picker(item: Dictionary) -> void:
	if _card_battle_ctrl == null:
		_status_label.text = "购买失败：无效"
		_status_label.add_theme_color_override("font_color", CyberStyle.ACCENT_ORANGE)
		return
	if not _can_purchase(item):
		_status_label.text = "购买失败：条件不足"
		_status_label.add_theme_color_override("font_color", CyberStyle.ACCENT_ORANGE)
		return
	_pending_remove_item = item.duplicate()
	_refresh_remove_picker_list()
	_remove_picker_overlay.visible = true

func _refresh_remove_picker_list() -> void:
	for child in _remove_picker_list.get_children():
		child.queue_free()
	if _card_battle_ctrl == null:
		return
	var deck: Array = _card_battle_ctrl.persistent_deck
	for i in range(deck.size()):
		var card: Dictionary = deck[i]
		var row: HBoxContainer = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 30)
		_remove_picker_list.add_child(row)

		var info: Label = Label.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.text = _format_card_entry(card)
		info.add_theme_font_size_override("font_size", 12)
		info.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY)
		row.add_child(info)

		var remove_btn: Button = Button.new()
		remove_btn.text = "移除"
		remove_btn.custom_minimum_size = Vector2(64, 26)
		CyberStyle.style_button(remove_btn, "orange")
		if deck.size() <= 3:
			remove_btn.disabled = true
		var idx: int = i
		remove_btn.pressed.connect(func(): _on_remove_card_selected(idx))
		row.add_child(remove_btn)

func _format_card_entry(card: Dictionary) -> String:
	var card_name: String = String(card.get("name", "未知卡牌"))
	var cost: int = int(card.get("cost", 1))
	var value: int = int(card.get("value", 0))
	var type_label: String = String(card.get("type", ""))
	if bool(card.get("upgraded", false)):
		card_name += "★"
	return card_name + "   " + str(cost) + "E | " + type_label + " " + str(value)

func _on_remove_card_selected(deck_index: int) -> void:
	if _pending_remove_item.is_empty():
		return
	var result: String = _execute_purchase(_pending_remove_item, deck_index)
	_apply_purchase_result(_pending_remove_item, result)
	_pending_remove_item = {}
	_remove_picker_overlay.visible = false
	_refresh_display()

func _on_remove_picker_cancel_pressed() -> void:
	_pending_remove_item = {}
	_remove_picker_overlay.visible = false

func _on_close_pressed() -> void:
	_pending_remove_item = {}
	_remove_picker_overlay.visible = false
	UITransitions.close(self)
	emit_signal("shop_closed")

# --- crest 显示名 ---

func _crest_display_name(crest_type: String) -> String:
	match crest_type:
		"move":
			return "步"
		"attack":
			return "攻"
		"defend":
			return "盾"
		"skill":
			return "术"
		"trick":
			return "策"
		"summon":
			return "召"
	return crest_type

# --- UI 构建 ---

func _build_remove_picker_ui() -> void:
	_remove_picker_overlay = ColorRect.new()
	_remove_picker_overlay.visible = false
	_remove_picker_overlay.position = Vector2(0, 0)
	_remove_picker_overlay.size = Vector2(480, 380)
	_remove_picker_overlay.color = Color(0.0, 0.0, 0.0, 0.7)
	_remove_picker_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_remove_picker_overlay)

	_remove_picker_panel = Panel.new()
	_remove_picker_panel.position = Vector2(30, 36)
	_remove_picker_panel.size = Vector2(420, 308)
	_remove_picker_panel.add_theme_stylebox_override("panel", CyberStyle.make_panel_bg(CyberStyle.ACCENT_MAGENTA, 8))
	_remove_picker_overlay.add_child(_remove_picker_panel)

	_remove_picker_title = Label.new()
	_remove_picker_title.text = "选择要移除的卡牌"
	_remove_picker_title.position = Vector2(0, 10)
	_remove_picker_title.size = Vector2(420, 24)
	_remove_picker_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_remove_picker_title.add_theme_font_size_override("font_size", 16)
	_remove_picker_title.add_theme_color_override("font_color", CyberStyle.TEXT_TITLE)
	_remove_picker_panel.add_child(_remove_picker_title)

	var picker_hint: Label = Label.new()
	picker_hint.text = "数据清洗：选择 1 张卡牌永久移除"
	picker_hint.position = Vector2(0, 34)
	picker_hint.size = Vector2(420, 18)
	picker_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	picker_hint.add_theme_font_size_override("font_size", 11)
	picker_hint.add_theme_color_override("font_color", CyberStyle.TEXT_SECONDARY)
	_remove_picker_panel.add_child(picker_hint)

	var list_bg: Panel = Panel.new()
	list_bg.position = Vector2(14, 58)
	list_bg.size = Vector2(392, 206)
	list_bg.add_theme_stylebox_override("panel", CyberStyle.make_panel_bg(CyberStyle.NEON_TEAL, 4))
	_remove_picker_panel.add_child(list_bg)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.position = Vector2(6, 6)
	scroll.size = Vector2(380, 194)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_bg.add_child(scroll)

	_remove_picker_list = VBoxContainer.new()
	_remove_picker_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_remove_picker_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_remove_picker_list)

	_remove_picker_cancel_btn = Button.new()
	_remove_picker_cancel_btn.text = "取消"
	_remove_picker_cancel_btn.position = Vector2(160, 272)
	_remove_picker_cancel_btn.size = Vector2(100, 28)
	_remove_picker_cancel_btn.add_theme_font_size_override("font_size", 13)
	_remove_picker_cancel_btn.pressed.connect(_on_remove_picker_cancel_pressed)
	CyberStyle.style_button(_remove_picker_cancel_btn, "cyan")
	_remove_picker_panel.add_child(_remove_picker_cancel_btn)

func _build_ui() -> void:
	add_theme_stylebox_override("panel", CyberStyle.make_panel_bg(CyberStyle.NEON_TEAL, 8))

	# 标题
	_title_label = Label.new()
	_title_label.text = "赛博商店"
	_title_label.position = Vector2(0, 10)
	_title_label.size = Vector2(480, 28)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", CyberStyle.TEXT_TITLE)
	add_child(_title_label)

	# Crest 信息
	_crest_info_label = Label.new()
	_crest_info_label.text = "持有资源：—"
	_crest_info_label.position = Vector2(0, 38)
	_crest_info_label.size = Vector2(480, 18)
	_crest_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_crest_info_label.add_theme_font_size_override("font_size", 11)
	_crest_info_label.add_theme_color_override("font_color", CyberStyle.TEXT_SECONDARY)
	add_child(_crest_info_label)

	# 分隔线
	var sep := ColorRect.new()
	sep.position = Vector2(20, 58)
	sep.size = Vector2(440, 1)
	sep.color = Color(CyberStyle.NEON_TEAL.r, CyberStyle.NEON_TEAL.g, CyberStyle.NEON_TEAL.b, 0.3)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep)

	# 商品槽位（3 个横排）
	var slot_w: float = 140.0
	var slot_h: float = 200.0
	var gap: float = 10.0
	var total_w: float = ITEMS_PER_SHOP * slot_w + (ITEMS_PER_SHOP - 1) * gap
	var start_x: float = (480.0 - total_w) / 2.0
	var start_y: float = 68.0

	for i in range(ITEMS_PER_SHOP):
		var container := Control.new()
		container.position = Vector2(start_x + i * (slot_w + gap), start_y)
		container.size = Vector2(slot_w, slot_h)
		container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(container)
		_item_containers.append(container)

		# 商品名
		var name_lbl := Label.new()
		name_lbl.position = Vector2(0, 0)
		name_lbl.size = Vector2(slot_w, 24)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.add_theme_color_override("font_color", CyberStyle.TEXT_TITLE)
		container.add_child(name_lbl)
		_item_name_labels.append(name_lbl)

		# 描述
		var desc_lbl := Label.new()
		desc_lbl.position = Vector2(0, 26)
		desc_lbl.size = Vector2(slot_w, 40)
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", CyberStyle.TEXT_PRIMARY)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		container.add_child(desc_lbl)
		_item_desc_labels.append(desc_lbl)

		# 费用
		var cost_lbl := Label.new()
		cost_lbl.position = Vector2(0, 68)
		cost_lbl.size = Vector2(slot_w, 18)
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_lbl.add_theme_font_size_override("font_size", 12)
		cost_lbl.add_theme_color_override("font_color", CyberStyle.TEXT_CYAN)
		container.add_child(cost_lbl)
		_item_cost_labels.append(cost_lbl)

		# 购买按钮
		var buy_btn := Button.new()
		buy_btn.text = "购买"
		buy_btn.position = Vector2(20, 92)
		buy_btn.size = Vector2(100, 32)
		buy_btn.add_theme_font_size_override("font_size", 13)
		CyberStyle.style_button(buy_btn, "orange")
		var idx: int = i
		buy_btn.pressed.connect(func(): _on_buy_pressed(idx))
		container.add_child(buy_btn)
		_buy_buttons.append(buy_btn)

	# 状态标签
	_status_label = Label.new()
	_status_label.position = Vector2(0, 310)
	_status_label.size = Vector2(480, 20)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 12)
	_status_label.add_theme_color_override("font_color", CyberStyle.NEON_TEAL)
	add_child(_status_label)

	# 关闭按钮
	_close_button = Button.new()
	_close_button.text = "离开商店"
	_close_button.position = Vector2(175, 335)
	_close_button.size = Vector2(130, 36)
	_close_button.add_theme_font_size_override("font_size", 14)
	_close_button.pressed.connect(_on_close_pressed)
	CyberStyle.style_button(_close_button, "cyan")
	add_child(_close_button)
