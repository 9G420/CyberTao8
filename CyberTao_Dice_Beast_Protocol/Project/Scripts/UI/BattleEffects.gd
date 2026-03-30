extends RefCounted
class_name BattleEffects

## 战斗特效系统（Phase 2.2）
## 屏幕微震 + 命中粒子爆发 + 增强伤害飘字
## CPUParticles2D（gl_compatibility 兼容）
## 全部静态方法，与 CyberStyle/BoardCellRenderer 同模式

# --- 屏幕微震 ---

static func shake_screen(target: Control, intensity: float = 3.0, duration: float = 0.25) -> void:
	if not target.has_meta("_shake_rest_pos"):
		target.set_meta("_shake_rest_pos", target.position)
	var rest_pos: Vector2 = target.get_meta("_shake_rest_pos")
	var tw: Tween = target.create_tween()
	var steps: int = 6
	var step_time: float = duration / float(steps)
	for i in range(steps):
		var decay: float = 1.0 - float(i) / float(steps)
		var offset_x: float = randf_range(-intensity, intensity) * decay
		var offset_y: float = randf_range(-intensity, intensity) * decay
		tw.tween_property(target, "position", rest_pos + Vector2(offset_x, offset_y), step_time)
	tw.tween_property(target, "position", rest_pos, step_time * 0.5)

# --- 命中粒子爆发 ---

static func spawn_hit_particles(parent: Node, world_pos: Vector2, color: Color, is_kill: bool = false) -> void:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.position = world_pos
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 12 if is_kill else 6
	particles.lifetime = 0.6 if is_kill else 0.4
	# 方向：全方位扩散
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.initial_velocity_min = 60.0 if is_kill else 40.0
	particles.initial_velocity_max = 130.0 if is_kill else 80.0
	particles.gravity = Vector2(0, 180)
	# 粒子大小
	particles.scale_amount_min = 3.0 if is_kill else 2.0
	particles.scale_amount_max = 5.0 if is_kill else 3.5
	# 颜色渐变（开始不透明 → 结束透明）
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(color.r, color.g, color.b, 1.0))
	gradient.set_color(1, Color(color.r, color.g, color.b, 0.0))
	particles.color_ramp = gradient
	particles.color = color
	# 发射形状
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 8.0 if is_kill else 4.0
	parent.add_child(particles)
	particles.emitting = true
	# 粒子结束后自动释放
	var tw: Tween = particles.create_tween()
	tw.tween_interval(particles.lifetime + 0.15)
	tw.tween_callback(particles.queue_free)

# --- 增强伤害飘字（缩放弹跳 + 上浮 + 渐隐） ---

static func enhanced_damage_popup(parent: Control, pos: Vector2, damage: int, is_kill: bool = false) -> void:
	var lbl: Label = Label.new()
	lbl.text = "-" + str(damage)
	var font_size: int = 28 if is_kill else 22
	lbl.add_theme_font_size_override("font_size", font_size)
	var col: Color = CyberStyle.NEON_GOLD if is_kill else CyberStyle.NEON_RED
	lbl.add_theme_color_override("font_color", col)
	lbl.position = pos
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.pivot_offset = Vector2(20, 12)
	parent.add_child(lbl)
	# 缩放弹跳
	var tw_scale: Tween = lbl.create_tween()
	tw_scale.tween_property(lbl, "scale", Vector2(1.4, 1.4), 0.1).set_ease(Tween.EASE_OUT)
	tw_scale.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_IN)
	# 上浮 + 渐隐
	var rise_duration: float = 0.75 if is_kill else 0.6
	var tw_move: Tween = lbl.create_tween()
	tw_move.set_parallel(true)
	tw_move.tween_property(lbl, "position:y", pos.y - 50.0, rise_duration)
	tw_move.tween_property(lbl, "modulate:a", 0.0, rise_duration)
	tw_move.set_parallel(false)
	tw_move.tween_callback(lbl.queue_free)

# --- 击杀特效文字（KILL! 弹出） ---

static func kill_text_popup(parent: Control, pos: Vector2) -> void:
	var lbl: Label = Label.new()
	lbl.text = "KILL!"
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", CyberStyle.NEON_GOLD)
	lbl.position = Vector2(pos.x - 4, pos.y - 20)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.pivot_offset = Vector2(24, 10)
	parent.add_child(lbl)
	var tw: Tween = lbl.create_tween()
	tw.tween_property(lbl, "scale", Vector2(1.3, 1.3), 0.12).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.1)
	tw.tween_interval(0.3)
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", pos.y - 55.0, 0.5)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.set_parallel(false)
	tw.tween_callback(lbl.queue_free)
