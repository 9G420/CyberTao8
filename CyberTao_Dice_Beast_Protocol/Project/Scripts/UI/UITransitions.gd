extends RefCounted
class_name UITransitions

## UI 过渡动画工具类（v0.1.55 Phase 4.2）
## 面板弹出/关闭 Tween 动画 + 召唤展开演出
## 使用 class_name 全局注册，无需 preload

## 面板弹出动画：scale 0.9→1.0 + modulate alpha 0→1（0.2秒）
## 调用前设 visible=true，pivot_offset 设为面板中心
static func popup(panel: Control, duration: float = 0.2) -> void:
	panel.scale = Vector2(0.9, 0.9)
	panel.modulate = Color(1, 1, 1, 0)
	panel.visible = true
	var tw: Tween = panel.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(panel, "scale", Vector2.ONE, duration)
	tw.parallel().tween_property(panel, "modulate", Color.WHITE, duration * 0.8)

## 面板关闭动画：scale 1.0→0.95 + modulate alpha 1→0（0.15秒）
## 动画完成后自动隐藏面板
static func close(panel: Control, duration: float = 0.15) -> void:
	var tw: Tween = panel.create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(panel, "scale", Vector2(0.95, 0.95), duration)
	tw.parallel().tween_property(panel, "modulate", Color(1, 1, 1, 0), duration)
	tw.tween_callback(func():
		panel.visible = false
		panel.scale = Vector2.ONE
		panel.modulate = Color.WHITE
	)

## 异步关闭（可 await）：返回时面板已隐藏
static func close_await(panel: Control, duration: float = 0.15) -> void:
	var tw: Tween = panel.create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(panel, "scale", Vector2(0.95, 0.95), duration)
	tw.parallel().tween_property(panel, "modulate", Color(1, 1, 1, 0), duration)
	await tw.finished
	panel.visible = false
	panel.scale = Vector2.ONE
	panel.modulate = Color.WHITE

## 召唤路径格逐格铺展动画
## cells: 路径格坐标数组，board_view: 棋盘视图（用于 queue_redraw）
## 每格延迟 delay_per_cell 秒出现
static func summon_path_spread(board_view: Control, cells: Array, delay_per_cell: float = 0.1) -> void:
	if cells.is_empty():
		return
	for i in range(cells.size()):
		if i > 0:
			await board_view.get_tree().create_timer(delay_per_cell).timeout
		board_view.queue_redraw()

## 召唤单位出场动画：在指定像素位置播放从小到大+发光闪烁效果
## 创建一个临时 ColorRect 闪光，scale 弹跳后消失
static func summon_unit_spawn(parent: Control, pixel_pos: Vector2, cell_size: float = 72.0) -> void:
	# 发光闪烁效果
	var flash := ColorRect.new()
	flash.size = Vector2(cell_size, cell_size)
	flash.position = pixel_pos - Vector2(cell_size / 2.0, cell_size / 2.0)
	flash.color = Color(0.0, 0.85, 1.0, 0.6)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.pivot_offset = Vector2(cell_size / 2.0, cell_size / 2.0)
	flash.scale = Vector2(0.3, 0.3)
	parent.add_child(flash)
	# scale 弹跳 0.3→1.3→1.0 + alpha 淡出
	var tw: Tween = flash.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(flash, "scale", Vector2(1.3, 1.3), 0.2)
	tw.tween_property(flash, "scale", Vector2(1.0, 1.0), 0.1)
	tw.tween_property(flash, "color:a", 0.0, 0.25)
	tw.tween_callback(flash.queue_free)
