# ============================================================
# Deck.gd - 牌库管理（抽牌堆、弃牌堆）
# ============================================================
class_name Deck
extends RefCounted

## 抽牌堆（CardData资源路径）
var draw_pile: Array[String] = []

## 弃牌堆
var discard_pile: Array[String] = []

## 从路径数组初始化牌库
func init_from_paths(paths: Array[String]) -> void:
	draw_pile = paths.duplicate() as Array[String]
	discard_pile.clear()
	shuffle_draw_pile()

## 洗牌
func shuffle_draw_pile() -> void:
	draw_pile.shuffle()

## 抽一张卡（返回CardData资源路径，空则洗入弃牌堆重抽）
func draw_card() -> String:
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			return ""  # 无牌可抽
		# 弃牌堆洗入抽牌堆
		draw_pile = discard_pile.duplicate() as Array[String]
		discard_pile.clear()
		shuffle_draw_pile()
	if draw_pile.is_empty():
		return ""
	return draw_pile.pop_back()

## 抽多张卡
func draw_cards(count: int) -> Array[String]:
	var result: Array[String] = []
	for i in count:
		var card := draw_card()
		if card == "":
			break
		result.append(card)
	return result

## 弃牌
func discard(card_path: String) -> void:
	discard_pile.append(card_path)

## 剩余牌数
func draw_count() -> int:
	return draw_pile.size()

## 弃牌堆数量
func discard_count() -> int:
	return discard_pile.size()

## 将弃牌堆洗入抽牌堆（系统重启等效果）
func shuffle_discard_into_draw() -> void:
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	shuffle_draw_pile()
