extends CanvasLayer
class_name TransitionOverlay

## 宝可梦式百叶窗过渡动画
## 用于棋盘 ↔ 卡牌战斗的全屏场景切换

signal mid_reached      # 百叶窗完全合拢（可切换场景内容）
signal open_completed   # 百叶窗完全展开

const BAR_COUNT: int = 8
const CLOSE_DURATION: float = 0.35
const OPEN_DURATION: float = 0.3
const NAME_DISPLAY_SEC: float = 0.45
const VIEWPORT_W: float = 1280.0
const VIEWPORT_H: float = 720.0

var _canvas: Control
var _bars: Array = []
var _name_label: Label
var _is_animating: bool = false

func _init() -> void:
	layer = 10

func _ready() -> void:
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.visible = false
	add_child(_canvas)

	var bar_h: float = VIEWPORT_H / BAR_COUNT
	for i in BAR_COUNT:
		var bar := ColorRect.new()
		bar.position = Vector2(0.0, float(i) * bar_h + bar_h * 0.5)
		bar.size = Vector2(VIEWPORT_W, 0.0)
		bar.color = Color(0.0, 0.0, 0.0, 1.0)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_canvas.add_child(bar)
		_bars.append(bar)

	_name_label = Label.new()
	_name_label.position = Vector2(0.0, 280.0)
	_name_label.size = Vector2(VIEWPORT_W, 160.0)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 36)
	_name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.visible = false
	_canvas.add_child(_name_label)

## 进入卡牌战斗过渡：百叶窗合拢 → 闪烁敌方名称 → 发射 mid_reached
func transition_to_battle(enemy_name: String, is_boss: bool = false) -> void:
	if _is_animating:
		return
	_is_animating = true
	var bar_color: Color = Color(0.2, 0.02, 0.02) if is_boss else Color(0.0, 0.0, 0.0)
	for bar in _bars:
		bar.color = bar_color
	_name_label.text = enemy_name
	_name_label.visible = false
	_canvas.visible = true
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	# 百叶窗合拢
	await _animate_close()
	# 闪烁敌方名称
	_name_label.visible = true
	await get_tree().create_timer(NAME_DISPLAY_SEC).timeout
	_name_label.visible = false
	emit_signal("mid_reached")

## 展开百叶窗，露出下方内容
func reveal() -> void:
	await _animate_open()
	_canvas.visible = false
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_animating = false
	emit_signal("open_completed")

## 退出卡牌战斗过渡：百叶窗合拢 → 发射 mid_reached
func transition_to_board() -> void:
	if _is_animating:
		return
	_is_animating = true
	for bar in _bars:
		bar.color = Color(0.0, 0.0, 0.0)
	_name_label.visible = false
	_canvas.visible = true
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	await _animate_close()
	emit_signal("mid_reached")

## 内部：百叶窗合拢动画
func _animate_close() -> void:
	var bar_h: float = VIEWPORT_H / BAR_COUNT
	var tw: Tween = _canvas.create_tween()
	tw.set_parallel(true)
	for i in BAR_COUNT:
		var bar: ColorRect = _bars[i]
		var target_y: float = float(i) * bar_h
		var center_y: float = target_y + bar_h * 0.5
		bar.position.y = center_y
		bar.size.y = 0.0
		tw.tween_property(bar, "size:y", bar_h, CLOSE_DURATION)
		tw.tween_property(bar, "position:y", target_y, CLOSE_DURATION)
	await tw.finished

## 内部：百叶窗展开动画
func _animate_open() -> void:
	var bar_h: float = VIEWPORT_H / BAR_COUNT
	var tw: Tween = _canvas.create_tween()
	tw.set_parallel(true)
	for i in BAR_COUNT:
		var bar: ColorRect = _bars[i]
		var start_y: float = float(i) * bar_h
		var center_y: float = start_y + bar_h * 0.5
		bar.position.y = start_y
		bar.size.y = bar_h
		tw.tween_property(bar, "size:y", 0.0, OPEN_DURATION)
		tw.tween_property(bar, "position:y", center_y, OPEN_DURATION)
	await tw.finished
