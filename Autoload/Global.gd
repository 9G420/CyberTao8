# ============================================================
# Global.gd - 全局单例，管理场景切换、通用工具函数
# Autoload名称: Global
# ============================================================
extends Node

## 场景路径常量
const SCENE_TITLE := "res://Scenes/Title.tscn"
const SCENE_OPENING := "res://Scenes/OpeningCG.tscn"
const SCENE_MAP := "res://Scenes/Map.tscn"
const SCENE_BATTLE := "res://Scenes/Battle.tscn"
const SCENE_DECK_BUILDER := "res://Scenes/DeckBuilder.tscn"
const SCENE_EVENT := "res://Scenes/Event.tscn"
const SCENE_VICTORY := "res://Scenes/Victory.tscn"
const SCENE_DEFEAT := "res://Scenes/Defeat.tscn"
const SCENE_CARD_REWARD := "res://Scenes/CardReward.tscn"

## 过渡效果信号
signal scene_transition_started
signal scene_transition_finished

## 当前是否正在过渡
var is_transitioning := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## 切换场景（带淡入淡出）
func change_scene(path: String, fade_duration: float = 0.5) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	scene_transition_started.emit()

	# 创建遮罩层用于淡出
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.z_index = 100
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(overlay)

	# 淡出
	var tween: Tween = create_tween()
	tween.tween_property(overlay, "color:a", 1.0, fade_duration)
	await tween.finished

	# 切换场景
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame

	# 淡入
	var tween_in: Tween = create_tween()
	tween_in.tween_property(overlay, "color:a", 0.0, fade_duration)
	await tween_in.finished

	overlay.queue_free()
	is_transitioning = false
	scene_transition_finished.emit()

## 快速切换（无过渡）
func change_scene_instant(path: String) -> void:
	get_tree().change_scene_to_file(path)

## 生成范围内随机整数
func randi_range_safe(from: int, to: int) -> int:
	if from >= to:
		return from
	return randi() % (to - from + 1) + from

## 打乱数组
func shuffle_array(arr: Array) -> Array:
	var shuffled: Array = arr.duplicate()
	shuffled.shuffle()
	return shuffled
