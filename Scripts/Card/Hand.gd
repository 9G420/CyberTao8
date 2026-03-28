# ============================================================
# Hand.gd - 手牌管理（自动排列、添加/移除）
# 挂载在HBoxContainer或自定义Control上
# ============================================================
class_name Hand
extends HBoxContainer

## 信号
signal card_played_from_hand(card: Card)

## 最大手牌数
const MAX_HAND_SIZE := 8

## 当前手牌
var cards: Array[Card] = []

## 战场释放区域（用于判断拖拽目标）
var play_zone_rect: Rect2 = Rect2(0, 0, 1280, 420)

func _ready() -> void:
	# 设置手牌区域属性
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", -25)  # 卡牌稍微重叠

## 添加卡牌到手牌
func add_card(card: Card) -> void:
	if cards.size() >= MAX_HAND_SIZE:
		return  # 手牌满
	cards.append(card)
	add_child(card)
	card.original_position = card.position
	card.hand_index = cards.size() - 1
	# 连接拖拽信号
	if not card.card_drag_ended.is_connected(_on_card_drag_ended):
		card.card_drag_ended.connect(_on_card_drag_ended)

## 移除卡牌
func remove_card(card: Card) -> void:
	if card in cards:
		cards.erase(card)
		remove_child(card)
		_reindex()

## 重建索引
func _reindex() -> void:
	for i in cards.size():
		cards[i].hand_index = i
		cards[i].original_position = cards[i].position

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

## 卡牌回到手牌位置
func _return_card_to_hand(card: Card) -> void:
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(card, "position", card.original_position, 0.25)
	tween.parallel().tween_property(card, "scale", Vector2.ONE, 0.15)

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
