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
	{"id": "remove_card", "name": "数据清洗", "desc": "移除牌组中最弱的1张牌", "cost_type": "skill", "cost_amount": 1, "effect": "remove_card", "value": 1},
	{"id": "random_crest", "name": "赛博彩票", "desc": "随机获得2个crest资源", "cost_type": "move", "cost_amount": 1, "effect": "random_crest", "value": 2},
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

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(480, 380)
	size = Vector2(480, 380)
	pivot_offset = Vector2(240, 190)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()

# --- 公开方法 ---

func open_shop(unit_id: String, dice_mgr, unit_mgr, card_battle_ctrl) -> void:
	_unit_id = unit_id
	_dice_manager = dice_mgr
	_unit_manager = unit_mgr
	_card_battle_ctrl = card_battle_ctrl
	_current_items = _pick_random_items()
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
	_status_label.text = ""

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

func _execute_purchase(item: Dictionary) -> String:
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
			# 移除"最弱"卡牌：按 value/cost 比值最低的
			var worst_idx: int = 0
			var worst_score: float = 999.0
			for i in range(deck.size()):
				var c: Dictionary = deck[i]
				var c_cost: int = max(1, int(c.get("cost", 1)))
				var score: float = float(int(c.get("value", 0))) / float(c_cost)
				if score < worst_score:
					worst_score = score
					worst_idx = i
			var removed: Dictionary = deck[worst_idx]
			deck.remove_at(worst_idx)
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
	var result: String = _execute_purchase(item)
	if result != "" and result != "资源不足" and result != "单位不存在" and result != "无效":
		_status_label.text = "购买成功：" + String(item["name"]) + "（" + result + "）"
		_status_label.add_theme_color_override("font_color", CyberStyle.NEON_TEAL)
	else:
		_status_label.text = "购买失败：" + result
		_status_label.add_theme_color_override("font_color", CyberStyle.ACCENT_ORANGE)
	_refresh_display()

func _on_close_pressed() -> void:
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
