# ============================================================
# Event.gd - 事件/商店场景（v5 完整适配102张卡池）
# 稀有度加权奖励池 + 按稀有度/类型定价 + 关键词显示
# 偏向池覆盖全5种卡类型 + 战斗奖励3选1
# CRT overlay 安全处理（透明fallback）
# ============================================================
extends Control

enum EventPhase { DIALOGUE, SHOP, REWARD, DONE }
var phase: EventPhase = EventPhase.DIALOGUE

var dialogue_label: RichTextLabel
var choice_container: VBoxContainer
var shop_container: GridContainer
var gold_label: Label
var continue_btn: Button
var reward_container: HBoxContainer

# 事件数据
var event_dialogues: Array[Dictionary] = []
var shop_cards: Array[String] = []
var reward_cards: Array[String] = []  # 战斗后奖励3选1

func _ready() -> void:
	_init_event_data()
	_build_ui()
	# 如果是战后奖励模式
	var node_data: Dictionary = GameState.get_current_node()
	if node_data.get("_reward_mode", false):
		_show_reward()
	else:
		_show_dialogue()

func _init_event_data() -> void:
	var node_data: Dictionary = GameState.get_current_node()
	var node_name: String = node_data.get("name", "未知区域")

	# 根据节点生成对话
	event_dialogues = [
		{
			"text": "你踏入了「" + node_name + "」。\n\n一个模糊的数据残影出现在面前，似乎在等待你的回答...\n\n「旅者，你追寻的是什么？」",
			"choices": [
				{"text": "力量——我要碾碎一切阻碍", "effect": "greed", "alignment": -2},
				{"text": "平衡——我要看清真实的道", "effect": "awakening", "alignment": 2},
				{"text": "...(沉默)", "effect": "neutral", "alignment": 0},
			]
		}
	]

	# 准备商店卡牌 — 稀有度加权随机选取
	shop_cards = _generate_weighted_shop(4)

	# 准备战斗奖励卡（3张，偏向当前缺少的类型）
	reward_cards = _generate_reward_cards(3)

## 稀有度加权商店生成：普通70% / 罕见25% / 稀有5%
func _generate_weighted_shop(count: int) -> Array[String]:
	var pool: Array = GameState.available_pool.duplicate()
	if pool.is_empty():
		return [] as Array[String]

	# 按稀有度分桶
	var common: Array[String] = []
	var uncommon: Array[String] = []
	var rare: Array[String] = []
	for path in pool:
		var cd: CardData = load(path) if ResourceLoader.exists(path) else null
		if cd == null:
			continue
		match cd.rarity:
			0: common.append(path)
			1: uncommon.append(path)
			2: rare.append(path)

	common.shuffle()
	uncommon.shuffle()
	rare.shuffle()

	var result: Array[String] = []
	for i in range(count):
		var roll := randf()
		var picked: String = ""
		if roll < 0.05 and rare.size() > 0:
			picked = rare.pop_back()
		elif roll < 0.30 and uncommon.size() > 0:
			picked = uncommon.pop_back()
		elif common.size() > 0:
			picked = common.pop_back()
		elif uncommon.size() > 0:
			picked = uncommon.pop_back()
		elif rare.size() > 0:
			picked = rare.pop_back()

		if picked != "":
			result.append(picked)
	return result

## 战斗奖励卡生成：根据牌组组成偏向缺少的类型
func _generate_reward_cards(count: int) -> Array[String]:
	var pool: Array = GameState.available_pool.duplicate()
	if pool.is_empty():
		return [] as Array[String]

	# 统计当前牌组类型分布
	var type_counts := {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}
	for path in GameState.player_deck:
		var cd: CardData = load(path) if ResourceLoader.exists(path) else null
		if cd:
			type_counts[cd.card_type] = type_counts.get(cd.card_type, 0) + 1

	# 对池中卡牌按"缺少程度"加权
	var weighted: Array[Dictionary] = []
	for path in pool:
		var cd: CardData = load(path) if ResourceLoader.exists(path) else null
		if cd == null:
			continue
		# 类型越少，权重越高
		var type_w: float = 1.0 / (1.0 + type_counts.get(cd.card_type, 0))
		# 罕见/稀有略加权
		var rarity_w: float = 1.0 + cd.rarity * 0.3
		weighted.append({"path": path, "weight": type_w * rarity_w})

	# 按权重排序取前N（简化的加权选取）
	weighted.sort_custom(func(a, b): return a["weight"] > b["weight"])
	# 从前 count*3 中随机选 count 张
	var candidates := weighted.slice(0, mini(count * 3, weighted.size()))
	candidates.shuffle()

	var result: Array[String] = []
	for i in range(mini(count, candidates.size())):
		result.append(candidates[i]["path"])
	return result

## 获取卡牌价格（基于稀有度 + 类型加成）
func _get_card_price(cd: CardData) -> int:
	if cd == null:
		return 10
	var base: int = cd.shop_price
	# 如果shop_price有值就用，否则用稀有度默认值
	if base <= 0:
		match cd.rarity:
			0: base = 8
			1: base = 15
			2: base = 30
			_: base = 10
	return base

func _build_ui() -> void:
	# 背景
	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.02, 0.08)
	add_child(bg)

	_create_atmospheric_bg()

	# 标题
	var title := Label.new()
	title.text = "═══ 事 件 ═══"
	title.position = Vector2(0, 16)
	title.size = Vector2(1280, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.8, 0.5, 1))
	title.add_theme_color_override("font_shadow_color", Color(0.4, 0.15, 0.6, 0.4))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	add_child(title)

	var title_sep := ColorRect.new()
	title_sep.position = Vector2(300, 60)
	title_sep.size = Vector2(680, 2)
	title_sep.color = Color(0.5, 0.2, 0.7, 0.4)
	add_child(title_sep)

	# 对话文本
	dialogue_label = RichTextLabel.new()
	dialogue_label.bbcode_enabled = true
	dialogue_label.position = Vector2(80, 80)
	dialogue_label.size = Vector2(1120, 220)
	dialogue_label.add_theme_font_size_override("normal_font_size", 18)
	dialogue_label.add_theme_color_override("default_color", Color(0.8, 0.8, 0.85))
	var dl_sb := StyleBoxFlat.new()
	dl_sb.bg_color = Color(0.04, 0.02, 0.1, 0.85)
	dl_sb.border_color = Color(0.4, 0.1, 0.6, 0.6)
	dl_sb.set_border_width_all(2)
	dl_sb.border_width_left = 4
	dl_sb.set_corner_radius_all(2)
	dl_sb.content_margin_left = 24
	dl_sb.content_margin_top = 16
	dl_sb.content_margin_right = 20
	dl_sb.content_margin_bottom = 16
	dl_sb.shadow_color = Color(0.3, 0.05, 0.5, 0.2)
	dl_sb.shadow_size = 4
	dialogue_label.add_theme_stylebox_override("normal", dl_sb)
	add_child(dialogue_label)

	var dl_accent := ColorRect.new()
	dl_accent.position = Vector2(80, 80)
	dl_accent.size = Vector2(4, 220)
	dl_accent.color = Color(0.9, 0.5, 0.1, 0.6)
	add_child(dl_accent)

	# 选项容器
	choice_container = VBoxContainer.new()
	choice_container.position = Vector2(160, 320)
	choice_container.size = Vector2(960, 140)
	choice_container.add_theme_constant_override("separation", 10)
	add_child(choice_container)

	# 商店容器（4列）
	shop_container = GridContainer.new()
	shop_container.columns = 4
	shop_container.position = Vector2(40, 310)
	shop_container.size = Vector2(1200, 280)
	shop_container.add_theme_constant_override("h_separation", 16)
	shop_container.add_theme_constant_override("v_separation", 10)
	shop_container.visible = false
	add_child(shop_container)

	# 战斗奖励容器（3选1 水平排列）
	reward_container = HBoxContainer.new()
	reward_container.position = Vector2(80, 310)
	reward_container.size = Vector2(1120, 280)
	reward_container.add_theme_constant_override("separation", 24)
	reward_container.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_container.visible = false
	add_child(reward_container)

	# 底部分隔线
	var bottom_sep := ColorRect.new()
	bottom_sep.position = Vector2(80, 616)
	bottom_sep.size = Vector2(1120, 2)
	bottom_sep.color = Color(0.3, 0.15, 0.5, 0.3)
	add_child(bottom_sep)

	# 金币显示
	gold_label = Label.new()
	gold_label.text = "◆ 金币: " + str(GameState.player_gold)
	gold_label.position = Vector2(80, 626)
	gold_label.add_theme_font_size_override("font_size", 20)
	gold_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	gold_label.add_theme_color_override("font_shadow_color", Color(0.5, 0.4, 0.1, 0.3))
	gold_label.add_theme_constant_override("shadow_offset_x", 1)
	gold_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(gold_label)

	# 继续按钮
	continue_btn = UIFactory.make_ribbon_button("继续前进", 280, 50)
	continue_btn.position = Vector2(500, 656)
	continue_btn.visible = false
	continue_btn.pressed.connect(_on_continue)
	add_child(continue_btn)

	# 删卡按钮
	var remove_btn: Button = UIFactory.make_arrow_button("删除一张卡 (免费)", 300, 50)
	remove_btn.position = Vector2(900, 656)
	remove_btn.pressed.connect(_on_remove_card)
	add_child(remove_btn)

	# 跳过奖励按钮（仅在奖励模式显示）
	var skip_btn: Button = UIFactory.make_cyan_button("跳过奖励", 200, 50)
	skip_btn.name = "SkipRewardBtn"
	skip_btn.position = Vector2(80, 656)
	skip_btn.visible = false
	skip_btn.pressed.connect(_on_skip_reward)
	add_child(skip_btn)

	# CRT shader overlay — 安全处理
	var crt_overlay := ColorRect.new()
	crt_overlay.set_anchors_preset(PRESET_FULL_RECT)
	crt_overlay.color = Color(0, 0, 0, 0)  # 安全fallback
	crt_overlay.z_index = 6
	crt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var crt_shader = load("res://Shaders/crt.gdshader")
	if crt_shader:
		var crt_mat := ShaderMaterial.new()
		crt_mat.shader = crt_shader
		crt_overlay.material = crt_mat
	add_child(crt_overlay)

func _create_atmospheric_bg() -> void:
	var ambient_chars := "道☯◎△▽"
	for i in range(8):
		var lbl := Label.new()
		lbl.text = ambient_chars[randi() % ambient_chars.length()]
		lbl.position = Vector2(randf() * 1280, randf() * 720)
		lbl.add_theme_font_size_override("font_size", randi_range(20, 40))
		lbl.add_theme_color_override("font_color", Color(0.1, 0.05, 0.2, randf_range(0.03, 0.08)))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lbl)
	for corner_data in [
		{"pos": Vector2(12, 12), "sz": Vector2(24, 2)},
		{"pos": Vector2(12, 12), "sz": Vector2(2, 24)},
		{"pos": Vector2(1244, 12), "sz": Vector2(24, 2)},
		{"pos": Vector2(1266, 12), "sz": Vector2(2, 24)},
	]:
		var mark := ColorRect.new()
		mark.position = corner_data["pos"]
		mark.size = corner_data["sz"]
		mark.color = Color(0.4, 0.1, 0.6, 0.25)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(mark)

func _make_event_button(text: String, font_color: Color, border_color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_hover_color", font_color.lightened(0.3))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.03, 0.12, 0.8)
	sb.border_color = border_color
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.2)
	sb.shadow_size = 3
	btn.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.border_color = Color(font_color.r, font_color.g, font_color.b, 0.8)
	sb_h.shadow_size = 6
	sb_h.shadow_color = Color(font_color.r, font_color.g, font_color.b, 0.3)
	btn.add_theme_stylebox_override("hover", sb_h)
	return btn

# ========================
# 对话阶段
# ========================

func _show_dialogue() -> void:
	phase = EventPhase.DIALOGUE
	if event_dialogues.is_empty():
		_show_shop()
		return

	var evt: Dictionary = event_dialogues[0]
	dialogue_label.clear()
	dialogue_label.append_text(evt["text"])

	for child in choice_container.get_children():
		child.queue_free()

	var choices: Array = evt["choices"]
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = choice["text"]
		btn.add_theme_font_size_override("font_size", 16)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.03, 0.12, 0.8)
		sb.border_color = Color(0.4, 0.2, 0.6, 0.6)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(4)
		sb.content_margin_left = 16
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		sb.shadow_color = Color(0.3, 0.1, 0.5, 0.15)
		sb.shadow_size = 2
		btn.add_theme_stylebox_override("normal", sb)
		var sb_h: StyleBoxFlat = sb.duplicate() as StyleBoxFlat
		sb_h.border_color = Color(0, 0.8, 1, 0.8)
		sb_h.bg_color = Color(0.08, 0.04, 0.16, 0.9)
		sb_h.shadow_color = Color(0, 0.5, 0.8, 0.3)
		sb_h.shadow_size = 6
		btn.add_theme_stylebox_override("hover", sb_h)
		btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
		btn.add_theme_color_override("font_hover_color", Color(0, 0.95, 1))
		var idx := i
		btn.pressed.connect(_on_choice_made.bind(idx))
		choice_container.add_child(btn)

func _on_choice_made(idx: int) -> void:
	var evt: Dictionary = event_dialogues[0]
	var choice: Dictionary = evt["choices"][idx]
	GameState.story_alignment += choice["alignment"]

	dialogue_label.clear()
	match choice["effect"]:
		"greed":
			dialogue_label.append_text("[color=red]你选择了力量的道路。\n贪欲的气息在数据中蔓延...\n\n商店偏向: 高攻击 + 侵蚀卡。[/color]")
			_bias_pool_towards("attack")
		"awakening":
			dialogue_label.append_text("[color=cyan]你选择了觉醒之道。\n太极之力在意识中共鸣...\n\n商店偏向: 防御 + 术法 + 能力卡。[/color]")
			_bias_pool_towards("balance")
		"neutral":
			dialogue_label.append_text("[color=gray]沉默是最深的回答。\n残影微笑着消散...\n\n你获得了少量金币。[/color]")
			GameState.player_gold += 15
			gold_label.text = "◆ 金币: " + str(GameState.player_gold)

	for child in choice_container.get_children():
		child.queue_free()

	await get_tree().create_timer(1.5).timeout
	_show_shop()

func _bias_pool_towards(bias: String) -> void:
	var pool: Array = GameState.available_pool.duplicate()
	shop_cards.clear()

	match bias:
		"attack":
			# 优先攻击卡、召唤卡
			var priority: Array[String] = []
			var rest: Array[String] = []
			for path in pool:
				if "atk_" in path or "sum_" in path:
					priority.append(path)
				else:
					rest.append(path)
			priority.shuffle()
			rest.shuffle()
			var combined := priority + rest
			for i in range(mini(4, combined.size())):
				shop_cards.append(combined[i])
		"balance":
			# 优先防御、术法、能力卡
			var priority: Array[String] = []
			var rest: Array[String] = []
			for path in pool:
				if "def_" in path or "spl_" in path or "pow_" in path:
					priority.append(path)
				else:
					rest.append(path)
			priority.shuffle()
			rest.shuffle()
			var combined := priority + rest
			for i in range(mini(4, combined.size())):
				shop_cards.append(combined[i])

# ========================
# 商店阶段
# ========================

func _show_shop() -> void:
	phase = EventPhase.SHOP
	choice_container.visible = false
	shop_container.visible = true
	continue_btn.visible = true

	dialogue_label.clear()
	dialogue_label.append_text("[color=cyan]══ 数据商店 ══[/color]\n选择要购买的卡牌。稀有度越高价格越贵。")

	for child in shop_container.get_children():
		child.queue_free()

	for card_path in shop_cards:
		var card_data: CardData = load(card_path) if ResourceLoader.exists(card_path) else null
		var item_panel := _create_shop_card(card_data, card_path, true)
		shop_container.add_child(item_panel)

func _create_shop_card(card_data: CardData, card_path: String, with_buy_btn: bool) -> Panel:
	var item_panel := Panel.new()
	item_panel.custom_minimum_size = Vector2(280, 270)
	var ip_sb := StyleBoxFlat.new()
	ip_sb.bg_color = Color(0.06, 0.03, 0.12, 0.85)
	ip_sb.set_border_width_all(2)
	ip_sb.set_corner_radius_all(4)
	ip_sb.shadow_size = 3

	if card_data:
		match card_data.yinyang:
			0:
				ip_sb.border_color = Color(0.4, 0.1, 0.6, 0.6)
				ip_sb.shadow_color = Color(0.3, 0.05, 0.5, 0.2)
			1:
				ip_sb.border_color = Color(0.7, 0.4, 0.1, 0.6)
				ip_sb.shadow_color = Color(0.5, 0.3, 0.05, 0.2)
			_:
				ip_sb.border_color = Color(0.3, 0.15, 0.5, 0.5)
				ip_sb.shadow_color = Color(0.2, 0.1, 0.3, 0.15)
	else:
		ip_sb.border_color = Color(0.3, 0.15, 0.5, 0.5)
		ip_sb.shadow_color = Color(0.2, 0.1, 0.3, 0.15)

	item_panel.add_theme_stylebox_override("panel", ip_sb)

	if card_data:
		# 卡面缩略图
		var card_art := TextureRect.new()
		var _ai_ev_card := AssetLoader.get_card_art(card_data.card_type, card_data.yinyang, card_data.rarity, card_path.hash(), card_data.card_id)
		card_art.texture = _ai_ev_card if _ai_ev_card else PixelArtGenerator.generate_card_art(
			card_data.card_type, card_data.yinyang, card_data.rarity, card_path.hash()
		)
		card_art.position = Vector2(108, 6)
		card_art.size = Vector2(64, 64)
		card_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_panel.add_child(card_art)

		# 卡名（稀有度颜色）
		var name_lbl := Label.new()
		name_lbl.text = card_data.card_name
		name_lbl.position = Vector2(8, 72)
		name_lbl.size = Vector2(264, 30)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", card_data.get_rarity_color())
		item_panel.add_child(name_lbl)

		# 类型 | 阴阳 | 费用
		var cost_str: String = "X" if card_data.cost == -1 else str(card_data.cost)
		var type_lbl := Label.new()
		type_lbl.text = card_data.get_type_text() + " | " + card_data.get_yinyang_text() + " | " + cost_str + "算力"
		type_lbl.position = Vector2(8, 100)
		type_lbl.size = Vector2(264, 24)
		type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		type_lbl.add_theme_font_size_override("font_size", 11)
		type_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		item_panel.add_child(type_lbl)

		# 描述
		var desc_lbl := Label.new()
		desc_lbl.text = card_data.description
		desc_lbl.position = Vector2(8, 124)
		desc_lbl.size = Vector2(264, 44)
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.clip_text = true
		item_panel.add_child(desc_lbl)

		# 数值行（含多段）
		var stats := ""
		match card_data.card_type:
			CardData.CardType.ATTACK:
				if card_data.multi_hit > 0:
					stats = "攻击: " + str(card_data.attack_power) + " x" + str(card_data.multi_hit)
				else:
					stats = "攻击: " + str(card_data.attack_power)
			CardData.CardType.DEFENSE: stats = "护盾: " + str(card_data.defense_power)
			CardData.CardType.SUMMON: stats = "攻:" + str(card_data.attack_power) + " 血:" + str(card_data.summon_hp)
			CardData.CardType.SPELL: stats = "术法效果"
			CardData.CardType.POWER: stats = "永久效果"
		var stats_lbl := Label.new()
		stats_lbl.text = stats
		stats_lbl.position = Vector2(8, 170)
		stats_lbl.size = Vector2(264, 24)
		stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_lbl.add_theme_font_size_override("font_size", 13)
		stats_lbl.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
		item_panel.add_child(stats_lbl)

		# 关键词标签
		var kw_text := card_data.get_keywords_text()
		if kw_text != "":
			var kw_lbl := Label.new()
			kw_lbl.text = kw_text
			kw_lbl.position = Vector2(8, 192)
			kw_lbl.size = Vector2(264, 20)
			kw_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			kw_lbl.add_theme_font_size_override("font_size", 10)
			kw_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 0.8))
			item_panel.add_child(kw_lbl)

		# 购买按钮或选择按钮
		if with_buy_btn:
			var price := _get_card_price(card_data)
			var buy_btn := _make_event_button("购买 (" + str(price) + "金)", Color(0, 0.9, 1), Color(0, 0.5, 0.8, 0.5))
			buy_btn.position = Vector2(30, 218)
			buy_btn.size = Vector2(220, 42)
			buy_btn.add_theme_font_size_override("font_size", 15)
			buy_btn.disabled = GameState.player_gold < price
			var path_copy := card_path
			buy_btn.pressed.connect(_on_buy_card.bind(path_copy, price, buy_btn))
			item_panel.add_child(buy_btn)
		else:
			# 奖励模式：选择按钮（免费）
			var pick_btn := _make_event_button("选择此卡", Color(0.2, 1, 0.5), Color(0.1, 0.6, 0.3, 0.5))
			pick_btn.position = Vector2(30, 218)
			pick_btn.size = Vector2(220, 42)
			pick_btn.add_theme_font_size_override("font_size", 15)
			var path_copy := card_path
			pick_btn.pressed.connect(_on_pick_reward.bind(path_copy))
			item_panel.add_child(pick_btn)
	else:
		var err_lbl := Label.new()
		err_lbl.text = "数据损坏"
		err_lbl.position = Vector2(8, 100)
		err_lbl.size = Vector2(264, 40)
		err_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		err_lbl.add_theme_font_size_override("font_size", 16)
		err_lbl.add_theme_color_override("font_color", Color(0.5, 0.3, 0.3))
		item_panel.add_child(err_lbl)

	return item_panel

func _on_buy_card(card_path: String, price: int, btn: Button) -> void:
	if GameState.player_gold < price:
		return
	GameState.player_gold -= price
	GameState.player_deck.append(card_path)
	GameState.available_pool.erase(card_path)
	gold_label.text = "◆ 金币: " + str(GameState.player_gold)
	btn.text = "已购买"
	btn.disabled = true
	dialogue_label.append_text("\n[color=green]卡牌已加入牌组！[/color]")
	# 刷新其他购买按钮的可购买状态
	_refresh_buy_buttons()

func _refresh_buy_buttons() -> void:
	# 遍历商店子项，禁用买不起的按钮
	for child in shop_container.get_children():
		if child is Panel:
			for sub in child.get_children():
				if sub is Button and sub.text.begins_with("购买"):
					# 从按钮文本中提取价格
					var price_str: String = sub.text.replace("购买 (", "").replace("金)", "")
					if price_str.is_valid_int():
						var price: int = price_str.to_int()
						if GameState.player_gold < price:
							sub.disabled = true

# ========================
# 战斗奖励阶段（3选1）
# ========================

func _show_reward() -> void:
	phase = EventPhase.REWARD
	choice_container.visible = false
	shop_container.visible = false
	reward_container.visible = true
	continue_btn.visible = false

	# 显示跳过奖励按钮
	var skip_btn := get_node_or_null("SkipRewardBtn")
	if skip_btn:
		skip_btn.visible = true

	dialogue_label.clear()
	dialogue_label.append_text("[color=green]══ 战斗奖励 ══[/color]\n选择一张卡牌加入你的牌组（或跳过）。")

	for child in reward_container.get_children():
		child.queue_free()

	for card_path in reward_cards:
		var card_data: CardData = load(card_path) if ResourceLoader.exists(card_path) else null
		var item_panel := _create_shop_card(card_data, card_path, false)
		reward_container.add_child(item_panel)

func _on_pick_reward(card_path: String) -> void:
	GameState.player_deck.append(card_path)
	GameState.available_pool.erase(card_path)
	dialogue_label.clear()
	var cd: CardData = load(card_path) if ResourceLoader.exists(card_path) else null
	var cname: String = cd.card_name if cd else "未知"
	dialogue_label.append_text("[color=green]已获得: " + cname + "！[/color]")

	# 禁用所有选择按钮
	for child in reward_container.get_children():
		if child is Panel:
			for sub in child.get_children():
				if sub is Button:
					sub.disabled = true

	reward_container.visible = false
	var skip_btn := get_node_or_null("SkipRewardBtn")
	if skip_btn:
		skip_btn.visible = false
	continue_btn.visible = true

func _on_skip_reward() -> void:
	dialogue_label.clear()
	dialogue_label.append_text("[color=gray]你选择了跳过奖励。[/color]")
	reward_container.visible = false
	var skip_btn := get_node_or_null("SkipRewardBtn")
	if skip_btn:
		skip_btn.visible = false
	continue_btn.visible = true

# ========================
# 删卡 & 继续
# ========================

func _on_remove_card() -> void:
	if GameState.player_deck.size() <= 5:
		dialogue_label.append_text("\n[color=red]牌组太少，无法继续删除！[/color]")
		return
	# 删除最后一张非初始卡
	var removed: String = ""
	for i in range(GameState.player_deck.size() - 1, -1, -1):
		var path: String = GameState.player_deck[i]
		if path not in GameState.STARTER_DECK:
			removed = path
			GameState.player_deck.remove_at(i)
			break
	if removed == "":
		# 全是初始卡，删最后一张
		removed = GameState.player_deck.pop_back()
	GameState.available_pool.append(removed)
	var card_data: CardData = load(removed) if ResourceLoader.exists(removed) else null
	var card_name: String = card_data.card_name if card_data else "未知"
	dialogue_label.append_text("\n[color=red]已删除: " + card_name + "[/color]")

func _on_continue() -> void:
	GameState.save_game()
	var node_data: Dictionary = GameState.get_current_node()
	var ntype: String = node_data.get("type", "")
	if ntype == "event_then_battle" or ntype == "event":
		# 事件节点: 事件对话/商店后进入战斗（如果是event_then_battle）
		# 对于纯event类型，直接回地图
		if ntype == "event_then_battle":
			Global.change_scene(Global.SCENE_BATTLE)
		else:
			GameState.advance_node()
			Global.change_scene(Global.SCENE_MAP)
	elif ntype == "shop":
		# 商店节点完成，回地图
		GameState.advance_node()
		Global.change_scene(Global.SCENE_MAP)
	elif node_data.get("_reward_mode", false):
		# 从Victory奖励模式进入，不再推进节点
		Global.change_scene(Global.SCENE_MAP)
	else:
		GameState.advance_node()
		Global.change_scene(Global.SCENE_MAP)
