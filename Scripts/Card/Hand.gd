# ============================================================
# Hand.gd - 手牌管理（扇形排列、添加/移除、拖拽释放）
# 挂载在Control节点上（不再使用HBoxContainer自动布局）
# ============================================================
class_name Hand
extends Control

## 信号
signal card_played_from_hand(card: Card)

## 最大手牌数
const MAX_HAND_SIZE := 8

## 当前手牌
var cards: Array[Card] = []

## 战场释放区域（用于判断拖拽目标）
var play_zone_rect: Rect2 = Rect2(0, 0, 1280, 420)

## 扇形布局参数
const FAN_RADIUS: float = 900.0       # 扇形弧度半径
const FAN_MAX_ANGLE: float = 25.0     # 最大展开角度（单张一侧）
const FAN_CARD_ANGLE: float = 7.0     # 每张卡牌间角度
const HAND_CENTER_X: float = 640.0    # 手牌中心X（屏幕中央）
const HAND_CENTER_Y: float = 780.0    # 扇形圆心Y（屏幕下方偏外）
const CARD_Y_BASE: float = 520.0      # 卡牌基线Y

## Hover spread distance (px) for adjacent cards
const HOVER_SPREAD_PX: float = 30.0

func _ready() -> void:
	# 设置为全屏覆盖的Control（不再是HBoxContainer）
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## 添加卡牌到手牌
func add_card(card: Card) -> void:
	if cards.size() >= MAX_HAND_SIZE:
		return  # 手牌满
	cards.append(card)
	add_child(card)
	card.hand_index = cards.size() - 1
	# 连接拖拽信号
	if not card.card_drag_ended.is_connected(_on_card_drag_ended):
		card.card_drag_ended.connect(_on_card_drag_ended)
	if not card.card_drag_started.is_connected(_on_card_drag_started):
		card.card_drag_started.connect(_on_card_drag_started)
	# Connect hover signals for card spread
	if not card.card_hovered.is_connected(_on_card_hover_spread):
		card.card_hovered.connect(_on_card_hover_spread)
	if not card.card_unhovered.is_connected(_on_card_unhover_spread):
		card.card_unhovered.connect(_on_card_unhover_spread)
	# 重新排列
	_arrange_hand(true)

## 移除卡牌
func remove_card(card: Card) -> void:
	if card in cards:
		cards.erase(card)
		remove_child(card)
		_reindex()
		_arrange_hand(true)

## 重建索引
func _reindex() -> void:
	for i in cards.size():
		cards[i].hand_index = i

## 扇形排列手牌（核心布局算法）
func _arrange_hand(animated: bool = true) -> void:
	var count: int = cards.size()
	if count == 0:
		return

	# 计算总展开角度
	var total_angle: float = minf(FAN_CARD_ANGLE * (count - 1), FAN_MAX_ANGLE * 2.0)
	var start_angle: float = -total_angle / 2.0

	for i in count:
		var card: Card = cards[i]
		if card.is_dragging:
			continue  # 正在拖拽的卡牌不参与排列

		# 计算该卡牌的角度（度）
		var angle_deg: float = start_angle + (total_angle * float(i) / maxf(float(count - 1), 1.0)) if count > 1 else 0.0
		var angle_rad: float = deg_to_rad(angle_deg)

		# 通过圆弧计算位置
		var target_x: float = HAND_CENTER_X + sin(angle_rad) * FAN_RADIUS - Card.CARD_WIDTH / 2.0
		var target_y: float = CARD_Y_BASE + (1.0 - cos(angle_rad)) * FAN_RADIUS * 0.06
		var target_pos := Vector2(target_x, target_y)
		var target_rot: float = angle_deg * 0.6  # 旋转比角度稍小，更自然

		card.hand_index = i
		card.z_index = i
		card.original_position = target_pos

		if animated and card.is_inside_tree():
			var tw: Tween = card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(card, "position", target_pos, 0.2)
			tw.parallel().tween_property(card, "rotation_degrees", target_rot, 0.2)
		else:
			card.position = target_pos
			card.rotation_degrees = target_rot

## 拖拽开始回调 - 拖拽时归零旋转
func _on_card_drag_started(card: Card) -> void:
	var tw: Tween = card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(card, "rotation_degrees", 0.0, 0.1)

## 拖拽结束回调 - 判断是否打出
func _on_card_drag_ended(card: Card) -> void:
	if _is_in_play_zone(card.global_position):
		# 在战场区域内，触发打出
		card_played_from_hand.emit(card)
	else:
		# 不在战场区域，回到手牌位置
		_return_card_to_hand(card)

## 判断是否在战场释放区域内
func _is_in_play_zone(pos: Vector2) -> bool:
	return play_zone_rect.has_point(pos)

## 卡牌回到手牌位置（含旋转恢复）
func _return_card_to_hand(card: Card) -> void:
	_arrange_hand(true)

## 更新所有卡牌的可打出状态
func update_playability(current_energy: int) -> void:
	for card in cards:
		if card.card_data:
			if card.card_data.unplayable:
				card.set_playable(false)
			elif card.card_data.cost == -1:
				# X-cost: playable if any energy
				card.set_playable(current_energy > 0)
			else:
				card.set_playable(card.card_data.cost <= current_energy)

## 清空手牌
func clear_hand() -> void:
	for card in cards:
		card.queue_free()
	cards.clear()

## 随机弃一张牌（心魔反噬效果）
func discard_random() -> Card:
	if cards.is_empty():
		return null
	var idx: int = randi() % cards.size()
	var card: Card = cards[idx]
	remove_card(card)
	return card

## 获取手牌数量
func hand_size() -> int:
	return cards.size()

## Spread adjacent cards apart when a card is hovered (STS-style)
func _on_card_hover_spread(hovered_card: Card) -> void:
	var idx: int = hovered_card.hand_index
	for i in cards.size():
		var card: Card = cards[i]
		if card == hovered_card or card.is_dragging:
			continue
		if not card.is_inside_tree():
			continue
		var offset_x: float = 0.0
		if i < idx:
			offset_x = -HOVER_SPREAD_PX
		elif i > idx:
			offset_x = HOVER_SPREAD_PX
		var target_pos: Vector2 = card.original_position + Vector2(offset_x, 0.0)
		var tw: Tween = card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(card, "position", target_pos, 0.15)

## Restore hand positions when hover ends
func _on_card_unhover_spread(_card: Card) -> void:
	_arrange_hand(true)
