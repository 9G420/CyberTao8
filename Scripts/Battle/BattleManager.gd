# ============================================================
# BattleManager.gd - 战斗管理器（回合状态机核心）
# 挂载在Battle.tscn根节点上
# ============================================================
extends Control

# 效果系统类型引用（解决 EffectResult 类型不可见问题）
const EffectResult := EffectSystem.EffectResult

# --- AI资产辅助函数 ---
static func _ai_sprite(char_type: String, frame: int = 0) -> ImageTexture:
	if frame == 0:
		var ai_tex := AssetLoader.get_character_sprite(char_type, frame)
		if ai_tex:
			return ai_tex
	return _ai_sprite(char_type, frame)

# --- 战斗状态枚举 ---
enum BattleState {
	INIT,            # 初始化
	PLAYER_TURN,     # 玩家回合
	ENEMY_TURN,      # 敌人回合
	RESOLVE_EFFECTS, # 结算效果
	VICTORY,         # 胜利
	DEFEAT,          # 失败
}

# --- 当前状态 ---
var state: BattleState = BattleState.INIT

# --- 战斗数据 ---
var player_hp: int = 30
var player_max_hp: int = 30
var player_shield: int = 0
var energy: int = 1
var max_energy: int = 1
var energy_cap: int = 6  # 算力上限
var turn_number: int = 0
var resonance_turns: int = 0  # 连续共鸣回合数

# --- 阴阳 ---
var yin_count: int = 0
var yang_count: int = 0

# --- 敌人 ---
var enemy: EnemyUnit = null
var enemy_type_key: String = "grunt"

# --- 牌库与手牌 ---
var deck: Deck = Deck.new()
var hand_node: Hand = null

# --- 召唤物 ---
var player_summons: Array[Dictionary] = []
const MAX_SUMMONS := 4

# --- Status/Power tracking ---
var active_powers: Array[String] = []  # active power card effect_ids
var player_statuses: Array[Dictionary] = []  # {type, value, turns}
var turn_damaged: bool = false  # track if player took damage this turn
var attacks_played_this_turn: int = 0  # for finisher_protocol
var cards_played_this_turn: int = 0  # for strangle_protocol
var glass_blade_bonus: int = 0  # permanent bonus for glass_blade_grow
var next_turn_bonus_energy: int = 0  # energy bonus from seize_initiative etc
var no_draw_mode: bool = false  # from bullet_time
var extra_draw_per_turn: int = 0  # from power_essential_tools
var extra_discard_per_turn: int = 0  # from power_essential_tools

# --- Positioning ---
var summon_positions: Dictionary = {}  # card_id -> "front" or "back"

# --- UI节点引用 ---
var hp_bar: ProgressBar
var hp_label: Label
var energy_label: Label
var enemy_hp_bar: ProgressBar
var enemy_hp_label: Label
var enemy_name_label: Label
var enemy_intent_label: Label
var enemy_shield_label: Label
var yin_label: Label
var yang_label: Label
var balance_label: Label
var turn_label: Label
var end_turn_btn: Button
var log_label: RichTextLabel
var deck_count_label: Label
var discard_count_label: Label
var player_shield_label: Label
var summon_container: VBoxContainer
var player_status_container: HBoxContainer
var enemy_status_container: HBoxContainer

# --- Glitch效果 ---
var glitch_rect: ColorRect = null

# --- 战场释放区域 ---
var play_zone: Panel

# --- Visual enhancement variables ---
var player_sprite: TextureRect = null
var enemy_sprite: TextureRect = null
var taiji_sprite: TextureRect = null
var crt_overlay: ColorRect = null
var energy_panel: Panel = null
var _taiji_frame: int = 0
var _taiji_timer: float = 0.0
var _resonance_pulse_time: float = 0.0
var _player_bob_tween: Tween = null
var _taiji_rot_tween: Tween = null
var _floating_log_container: VBoxContainer = null
var _front_shield_texture: ImageTexture = null  # cached

func _ready() -> void:
	_setup_ui()
	_init_battle()

# ============================================================
# UI构建
# ============================================================
func _setup_ui() -> void:
	# --- 1. Battle background with TextureRect ---
	var stage: int = 0
	match enemy_type_key:
		"grunt": stage = 0
		"elite": stage = 1
		"elite2": stage = 2
		"boss": stage = 3
	var bg_tex := TextureRect.new()
	bg_tex.set_anchors_preset(PRESET_FULL_RECT)
	bg_tex.stretch_mode = TextureRect.STRETCH_SCALE
	var _ai_bg := AssetLoader.get_battle_background(enemy_type_key)
	bg_tex.texture = _ai_bg if _ai_bg else PixelArtGenerator.generate_battle_background(stage)
	bg_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(bg_tex)

	# Color overlay for tinting
	var bg_overlay := ColorRect.new()
	bg_overlay.set_anchors_preset(PRESET_FULL_RECT)
	bg_overlay.color = Color(0.05, 0.03, 0.1, 0.35)
	bg_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_overlay)

	# --- 战场区域（敌人+释放区） ---
	play_zone = Panel.new()
	play_zone.position = Vector2(0, 0)
	play_zone.size = Vector2(1280, 420)
	var pz_sb := StyleBoxFlat.new()
	pz_sb.bg_color = Color(0.08, 0.05, 0.15, 0.5)
	pz_sb.border_color = Color(0.3, 0.1, 0.5, 0.3)
	pz_sb.set_border_width_all(1)
	play_zone.add_theme_stylebox_override("panel", pz_sb)
	add_child(play_zone)

	# --- 敌人信息 ---
	enemy_name_label = _make_label(Vector2(500, 15), 280, 22, Color(1, 0.3, 0.3))
	play_zone.add_child(enemy_name_label)

	enemy_hp_bar = ProgressBar.new()
	enemy_hp_bar.position = Vector2(440, 45)
	enemy_hp_bar.size = Vector2(400, 24)
	enemy_hp_bar.show_percentage = false
	var ehp_sb := StyleBoxFlat.new()
	ehp_sb.bg_color = Color(0.8, 0.15, 0.15)
	enemy_hp_bar.add_theme_stylebox_override("fill", ehp_sb)
	play_zone.add_child(enemy_hp_bar)

	enemy_hp_label = _make_label(Vector2(440, 45), 400, 18, Color.WHITE)
	enemy_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_zone.add_child(enemy_hp_label)

	enemy_shield_label = _make_label(Vector2(850, 45), 100, 18, Color(0.3, 0.6, 1))
	play_zone.add_child(enemy_shield_label)

	enemy_intent_label = _make_label(Vector2(440, 75), 400, 16, Color(1, 0.8, 0.5))
	enemy_intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_zone.add_child(enemy_intent_label)

	# --- 3. Enemy character sprite (RIGHT side) ---
	enemy_sprite = TextureRect.new()
	enemy_sprite.position = Vector2(540, 110)
	enemy_sprite.size = Vector2(144, 192)
	enemy_sprite.stretch_mode = TextureRect.STRETCH_SCALE
	enemy_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	enemy_sprite.texture = _ai_sprite("grunt", 0)
	play_zone.add_child(enemy_sprite)

	# --- 2. Player character sprite (LEFT side) ---
	player_sprite = TextureRect.new()
	player_sprite.position = Vector2(40, 180)
	player_sprite.size = Vector2(144, 192)
	player_sprite.stretch_mode = TextureRect.STRETCH_SCALE
	player_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player_sprite.texture = _ai_sprite("player", 0)
	play_zone.add_child(player_sprite)
	# Start idle bobbing animation
	_start_player_idle_bob()

	# --- 玩家信息区（左下） ---
	var player_panel := Panel.new()
	player_panel.position = Vector2(15, 430)
	player_panel.size = Vector2(280, 140)
	var pp_sb := StyleBoxFlat.new()
	pp_sb.bg_color = Color(0.05, 0.08, 0.15, 0.8)
	pp_sb.border_color = Color(0, 0.5, 1, 0.4)
	pp_sb.set_border_width_all(1)
	player_panel.add_theme_stylebox_override("panel", pp_sb)
	add_child(player_panel)

	var player_title := _make_label(Vector2(10, 5), 260, 16, Color(0, 0.9, 1))
	player_title.text = "[ 阿零 · 像素觉醒者 ]"
	player_panel.add_child(player_title)

	hp_bar = ProgressBar.new()
	hp_bar.position = Vector2(10, 28)
	hp_bar.size = Vector2(260, 20)
	hp_bar.show_percentage = false
	var hp_sb := StyleBoxFlat.new()
	hp_sb.bg_color = Color(0.1, 0.7, 0.3)
	hp_bar.add_theme_stylebox_override("fill", hp_sb)
	player_panel.add_child(hp_bar)

	hp_label = _make_label(Vector2(10, 28), 260, 16, Color.WHITE)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_panel.add_child(hp_label)

	player_shield_label = _make_label(Vector2(10, 52), 260, 16, Color(0.3, 0.6, 1))
	player_panel.add_child(player_shield_label)

	# 玩家状态图标（放在player_panel内shield标签旁）
	player_status_container = HBoxContainer.new()
	player_status_container.position = Vector2(130, 52)
	player_status_container.size = Vector2(140, 18)
	player_status_container.add_theme_constant_override("separation", 3)
	player_status_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_panel.add_child(player_status_container)

	# --- 7. Enhanced energy display with neon panel ---
	energy_panel = Panel.new()
	energy_panel.position = Vector2(8, 68)
	energy_panel.size = Vector2(264, 30)
	var ep_sb := StyleBoxFlat.new()
	ep_sb.bg_color = Color(0.02, 0.04, 0.12, 0.9)
	ep_sb.border_color = Color(0, 0.9, 1, 0.6)
	ep_sb.set_border_width_all(1)
	ep_sb.corner_radius_top_left = 3
	ep_sb.corner_radius_top_right = 3
	ep_sb.corner_radius_bottom_left = 3
	ep_sb.corner_radius_bottom_right = 3
	energy_panel.add_theme_stylebox_override("panel", ep_sb)
	player_panel.add_child(energy_panel)

	energy_label = _make_label(Vector2(4, 3), 256, 22, Color(0, 0.9, 1))
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_panel.add_child(energy_label)

	# 阴阳显示
	yin_label = _make_label(Vector2(10, 100), 100, 16, Color(0.5, 0.3, 1))
	player_panel.add_child(yin_label)
	yang_label = _make_label(Vector2(120, 100), 100, 16, Color(1, 0.8, 0.2))
	player_panel.add_child(yang_label)

	# --- 4. Taiji indicator sprite ---
	taiji_sprite = TextureRect.new()
	taiji_sprite.position = Vector2(228, 96)
	taiji_sprite.size = Vector2(40, 40)
	taiji_sprite.stretch_mode = TextureRect.STRETCH_SCALE
	taiji_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var _ai_taiji := AssetLoader.get_ui_texture("taiji", 48, 48)
	taiji_sprite.texture = _ai_taiji if _ai_taiji else PixelArtGenerator.generate_taiji_symbol(48, 0)
	player_panel.add_child(taiji_sprite)
	_start_taiji_rotation()

	balance_label = _make_label(Vector2(10, 120), 260, 16, Color(0.8, 0.8, 0.8))
	player_panel.add_child(balance_label)

	# --- 右侧信息 ---
	var info_panel := Panel.new()
	info_panel.position = Vector2(985, 430)
	info_panel.size = Vector2(280, 140)
	var ip_sb := StyleBoxFlat.new()
	ip_sb.bg_color = Color(0.05, 0.08, 0.15, 0.8)
	ip_sb.border_color = Color(0.5, 0.1, 0.5, 0.4)
	ip_sb.set_border_width_all(1)
	info_panel.add_theme_stylebox_override("panel", ip_sb)
	add_child(info_panel)

	turn_label = _make_label(Vector2(10, 5), 260, 16, Color(0.7, 0.7, 0.8))
	info_panel.add_child(turn_label)

	deck_count_label = _make_label(Vector2(10, 28), 260, 16, Color(0.5, 0.8, 0.5))
	info_panel.add_child(deck_count_label)

	discard_count_label = _make_label(Vector2(10, 51), 260, 16, Color(0.8, 0.5, 0.5))
	info_panel.add_child(discard_count_label)

	# 结束回合按钮
	end_turn_btn = Button.new()
	end_turn_btn.text = "结束回合"
	end_turn_btn.position = Vector2(50, 85)
	end_turn_btn.size = Vector2(180, 44)
	end_turn_btn.add_theme_font_size_override("font_size", 18)
	end_turn_btn.pressed.connect(_on_end_turn_pressed)
	info_panel.add_child(end_turn_btn)

	# --- 战斗日志 (浮动文字容器，位于战场底部) ---
	_floating_log_container = VBoxContainer.new()
	_floating_log_container.position = Vector2(200, 370)
	_floating_log_container.size = Vector2(880, 50)
	_floating_log_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_floating_log_container.add_theme_constant_override("separation", 2)
	play_zone.add_child(_floating_log_container)

	# --- 手牌区域 ---
	hand_node = Hand.new()
	hand_node.position = Vector2(100, 585)
	hand_node.size = Vector2(1080, 240)
	hand_node.play_zone_rect = Rect2(0, 0, 1280, 420)
	hand_node.card_played_from_hand.connect(_on_card_played)
	add_child(hand_node)

	# --- 召唤物战场区域（独立sprite，不再用VBoxContainer文字列表） ---
	summon_container = VBoxContainer.new()  # 保留引用但不再用于主显示
	summon_container.position = Vector2(0, 0)
	summon_container.size = Vector2(0, 0)
	summon_container.visible = false
	play_zone.add_child(summon_container)

	# --- 敌人状态图标容器（敌人HP条下方） ---
	enemy_status_container = HBoxContainer.new()
	enemy_status_container.position = Vector2(440, 100)
	enemy_status_container.size = Vector2(400, 20)
	enemy_status_container.add_theme_constant_override("separation", 4)
	enemy_status_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_zone.add_child(enemy_status_container)

	# Cache front shield texture
	_front_shield_texture = PixelArtGenerator.generate_status_icon("front_shield")

	# --- 6. Glitch覆盖层 (with shader) ---
	glitch_rect = ColorRect.new()
	glitch_rect.set_anchors_preset(PRESET_FULL_RECT)
	glitch_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glitch_rect.color = Color(0, 0, 0, 0)  # 安全fallback: shader失败不白屏
	var glitch_shader := load("res://Shaders/glitch.gdshader") as Shader
	if glitch_shader:
		var glitch_mat := ShaderMaterial.new()
		glitch_mat.shader = glitch_shader
		glitch_mat.set_shader_parameter("glitch_intensity", 0.0)
		glitch_rect.material = glitch_mat
	glitch_rect.z_index = 5
	add_child(glitch_rect)

	# --- 5. CRT overlay ---
	crt_overlay = ColorRect.new()
	crt_overlay.set_anchors_preset(PRESET_FULL_RECT)
	crt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crt_overlay.color = Color(0, 0, 0, 0)  # 安全fallback
	var crt_shader := load("res://Shaders/crt.gdshader") as Shader
	if crt_shader:
		var crt_mat := ShaderMaterial.new()
		crt_mat.shader = crt_shader
		crt_mat.set_shader_parameter("master_intensity", 1.0)
		crt_overlay.material = crt_mat
	crt_overlay.z_index = 6
	add_child(crt_overlay)

## 创建标签辅助函数
func _make_label(pos: Vector2, width: float, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.position = pos
	lbl.size = Vector2(width, 20)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.clip_text = true
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl

# ============================================================
# _process - visual updates
# ============================================================
var _defeat_safety_timer: float = 0.0

func _process(delta: float) -> void:
	# Safety fallback: if player is dead but scene hasn't changed, force it
	if player_hp <= 0 and state != BattleState.DEFEAT and state != BattleState.INIT:
		state = BattleState.DEFEAT
		_on_player_defeated()
		return
	# If in DEFEAT state for too long (>5 seconds), force scene change
	if state == BattleState.DEFEAT:
		_defeat_safety_timer += delta
		if _defeat_safety_timer > 5.0:
			Global.is_transitioning = false
			get_tree().change_scene_to_file(Global.SCENE_DEFEAT)
			return

	# Update taiji symbol rotation frame periodically
	_taiji_timer += delta
	if _taiji_timer >= 0.1 and taiji_sprite:
		_taiji_timer = 0.0
		_taiji_frame = (_taiji_frame + 1) % 60
		if not AssetLoader.use_ai_assets:
			taiji_sprite.texture = PixelArtGenerator.generate_taiji_symbol(48, _taiji_frame)
		else:
			taiji_sprite.rotation_degrees = _taiji_frame * 6.0  # 360/60 = 6度每帧

	# Pulse balance_label glow when in resonance
	var diff: int = absi(yin_count - yang_count)
	if diff <= 2 and (yin_count + yang_count) > 0 and balance_label:
		_resonance_pulse_time += delta
		var pulse := (sin(_resonance_pulse_time * 4.0) + 1.0) / 2.0
		var glow_color := Color(1, 0.85, 0.3).lerp(Color(1, 1, 0.8), pulse)
		balance_label.add_theme_color_override("font_color", glow_color)

# ============================================================
# Visual helper methods
# ============================================================
## Update the enemy sprite based on enemy_type_key
func _update_enemy_sprite() -> void:
	if not enemy_sprite:
		return
	enemy_sprite.texture = _ai_sprite(enemy_type_key, 0)

## Start idle bobbing animation for player sprite
func _start_player_idle_bob() -> void:
	if not player_sprite:
		return
	_player_bob_tween = create_tween().set_loops()
	var base_y: float = player_sprite.position.y
	_player_bob_tween.tween_property(player_sprite, "position:y", base_y - 4.0, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_player_bob_tween.tween_property(player_sprite, "position:y", base_y + 4.0, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

## Start taiji rotation tween (visual rotation of the TextureRect node)
func _start_taiji_rotation() -> void:
	if not taiji_sprite:
		return
	taiji_sprite.pivot_offset = taiji_sprite.size / 2.0
	_taiji_rot_tween = create_tween().set_loops()
	_taiji_rot_tween.tween_property(taiji_sprite, "rotation", TAU, 8.0).from(0.0)

## Battle start intro transition
func _play_battle_intro() -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 1)
	overlay.z_index = 100
	add_child(overlay)

	var title_label := Label.new()
	title_label.text = "战 斗 开 始"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.set_anchors_preset(PRESET_FULL_RECT)
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	title_label.z_index = 101
	add_child(title_label)

	var sub_label := Label.new()
	sub_label.text = "战斗开始"
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub_label.set_anchors_preset(PRESET_FULL_RECT)
	sub_label.position.y = 60
	sub_label.add_theme_font_size_override("font_size", 28)
	sub_label.add_theme_color_override("font_color", Color(0, 0.9, 1))
	sub_label.z_index = 101
	add_child(sub_label)

	# Flash the text a few times
	for i in range(3):
		title_label.visible = true
		sub_label.visible = true
		await get_tree().create_timer(0.2).timeout
		title_label.visible = false
		sub_label.visible = false
		await get_tree().create_timer(0.1).timeout
	title_label.visible = true
	sub_label.visible = true
	await get_tree().create_timer(0.4).timeout

	# Fade out
	var fade_tw := create_tween()
	fade_tw.set_parallel(true)
	fade_tw.tween_property(overlay, "color:a", 0.0, 0.4)
	fade_tw.tween_property(title_label, "modulate:a", 0.0, 0.3)
	fade_tw.tween_property(sub_label, "modulate:a", 0.0, 0.3)
	await fade_tw.finished

	overlay.queue_free()
	title_label.queue_free()
	sub_label.queue_free()

## Victory transition with fullscreen effects
func _play_victory_transition() -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	overlay.color = Color(1, 0.9, 0.3, 0)
	overlay.z_index = 100
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var vic_label := Label.new()
	vic_label.text = "胜 利"
	vic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vic_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vic_label.set_anchors_preset(PRESET_FULL_RECT)
	vic_label.add_theme_font_size_override("font_size", 52)
	vic_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	vic_label.modulate.a = 0.0
	vic_label.z_index = 101
	add_child(vic_label)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(overlay, "color:a", 0.5, 0.6)
	tw.tween_property(vic_label, "modulate:a", 1.0, 0.4).set_delay(0.2)
	await tw.finished
	await get_tree().create_timer(0.6).timeout

	overlay.queue_free()
	vic_label.queue_free()

## Defeat transition with fullscreen effects
func _play_defeat_transition() -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	overlay.color = Color(0.5, 0, 0, 0)
	overlay.z_index = 100
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var def_label := Label.new()
	def_label.text = "战 败"
	def_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	def_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	def_label.set_anchors_preset(PRESET_FULL_RECT)
	def_label.add_theme_font_size_override("font_size", 48)
	def_label.add_theme_color_override("font_color", Color(0.8, 0.1, 0.1))
	def_label.modulate.a = 0.0
	def_label.z_index = 101
	add_child(def_label)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(overlay, "color:a", 0.7, 0.8)
	tw.tween_property(def_label, "modulate:a", 1.0, 0.5).set_delay(0.3)
	await tw.finished
	await get_tree().create_timer(0.8).timeout

	overlay.queue_free()
	def_label.queue_free()

## Player attack animation - briefly change sprite to attack frame, shake forward
func _play_player_attack_anim() -> void:
	if not player_sprite:
		return
	var orig_pos := player_sprite.position
	player_sprite.texture = _ai_sprite("player", 1)
	var tw := create_tween()
	tw.tween_property(player_sprite, "position:x", orig_pos.x + 20.0, 0.08)
	tw.tween_property(player_sprite, "position:x", orig_pos.x, 0.12)
	await tw.finished
	player_sprite.texture = _ai_sprite("player", 0)

## Player hurt animation - briefly change sprite to hurt frame, flash red
func _play_player_hurt_anim() -> void:
	if not player_sprite:
		return
	player_sprite.texture = _ai_sprite("player", 2)
	var tw := create_tween()
	tw.tween_property(player_sprite, "modulate", Color(1, 0.3, 0.3), 0.08)
	tw.tween_property(player_sprite, "modulate", Color.WHITE, 0.15)
	await tw.finished
	player_sprite.texture = _ai_sprite("player", 0)

# ============================================================
# 战斗初始化
# ============================================================
func _init_battle() -> void:
	state = BattleState.INIT

	# 从GameState获取数据
	player_hp = GameState.player_hp
	player_max_hp = GameState.player_max_hp
	player_shield = 0

	# Reset new tracking variables
	active_powers.clear()
	player_statuses.clear()
	turn_damaged = false
	attacks_played_this_turn = 0
	cards_played_this_turn = 0
	glass_blade_bonus = 0
	next_turn_bonus_energy = 0
	no_draw_mode = false
	extra_draw_per_turn = 0
	extra_discard_per_turn = 0
	player_summons.clear()
	summon_positions.clear()

	# 根据当前节点确定敌人类型
	var node_data: Dictionary = GameState.get_current_node()
	enemy_type_key = node_data.get("enemy", "grunt") as String
	match enemy_type_key:
		"grunt": enemy = EnemyUnit.create_enemy(EnemyUnit.EnemyType.GRUNT_GHOST)
		"grunt2": enemy = EnemyUnit.create_enemy(EnemyUnit.EnemyType.GRUNT_SWARM)
		"grunt3": enemy = EnemyUnit.create_enemy(EnemyUnit.EnemyType.GRUNT_THIEF)
		"elite": enemy = EnemyUnit.create_enemy(EnemyUnit.EnemyType.ELITE_PUPPET)
		"elite2": enemy = EnemyUnit.create_enemy(EnemyUnit.EnemyType.ELITE_OBSESSION)
		"boss": enemy = EnemyUnit.create_enemy(EnemyUnit.EnemyType.BOSS)
		_: enemy = EnemyUnit.create_enemy(EnemyUnit.EnemyType.GRUNT_GHOST)

	# 初始化牌库
	deck.init_from_paths(GameState.player_deck)

	# 初始化能量
	turn_number = 0
	energy = 1
	max_energy = 1

	# 重置阴阳
	yin_count = 0
	yang_count = 0
	GameState.reset_yinyang()

	# 播放战斗BGM
	AudioManager.play_bgm_generated("battle")

	_add_log("[color=cyan]===== 战斗开始 =====[/color]")
	_add_log("对手: [color=red]" + enemy.enemy_name + "[/color]")

	# Update enemy sprite now that enemy is known
	_update_enemy_sprite()

	# Battle intro transition then start first turn
	await _play_battle_intro()

	# 开始第一回合
	_start_player_turn()

# ============================================================
# 回合流程
# ============================================================
func _start_player_turn() -> void:
	state = BattleState.PLAYER_TURN
	turn_number += 1
	turn_damaged = false
	attacks_played_this_turn = 0
	cards_played_this_turn = 0

	# 增加算力
	max_energy = min(turn_number, energy_cap)
	energy = max_energy + next_turn_bonus_energy
	next_turn_bonus_energy = 0

	# 检查道境共鸣加成
	var bonus: Dictionary = EffectSystem.calc_resonance_bonus(yin_count, yang_count)
	if bonus["is_resonance"]:
		energy += bonus["energy_bonus"]
		resonance_turns += 1
		_add_log("[color=gold]☯ 道境共鸣！算力+1，伤害+1[/color]")
		AudioManager.play_sfx_generated("resonance")
		if resonance_turns >= 5:
			GameState.achievements["yinyang_master"] = true
	else:
		resonance_turns = 0

	if bonus["is_backlash"]:
		_add_log("[color=purple]⚠ 心魔反噬！伤害-2，随机弃牌[/color]")
		AudioManager.play_sfx_generated("backlash")
		_trigger_glitch(0.4)
		# 随机弃一张牌
		var discarded: Card = hand_node.discard_random()
		if discarded:
			deck.discard(discarded.card_data.resource_path if discarded.card_data else "")
			discarded.queue_free()

	# 护盾重置（每回合开始清除）
	player_shield = 0

	# Process player statuses at turn start
	_process_player_turn_start_statuses()

	# Death check after status damage (burn etc.)
	if player_hp <= 0:
		_on_player_defeated()
		return

	# Power: infinite_blade - generate token each turn
	if "power_infinite_blade" in active_powers:
		_add_token_to_hand()
		_add_log("[color=cyan]无尽之刃：获得1张数据碎片[/color]")

	# Power: essential_tools - extra draw/discard
	if "power_essential_tools" in active_powers and extra_draw_per_turn == 0:
		extra_draw_per_turn = 1
		extra_discard_per_turn = 1

	# 抽牌（每回合抽5张+额外，手牌上限8）
	if not no_draw_mode:
		var draw_count: int = mini(5 + extra_draw_per_turn, Hand.MAX_HAND_SIZE - hand_node.hand_size())
		var drawn: Array[String] = deck.draw_cards(draw_count)
		for card_path in drawn:
			_add_card_to_hand(card_path)

	# 更新手牌可用性
	hand_node.update_playability(energy)

	end_turn_btn.disabled = false
	_update_all_ui()
	_add_log("[color=cyan]--- 回合 " + str(turn_number) + " · 玩家回合 ---[/color]")

## 添加卡牌到手牌
func _add_card_to_hand(card_path: String) -> void:
	var card_data: CardData = (load(card_path) as CardData) if ResourceLoader.exists(card_path) else null
	if not card_data:
		# 创建占位卡牌数据
		card_data = CardData.new()
		card_data.card_name = "数据残片"
		card_data.cost = 1
		card_data.card_type = CardData.CardType.ATTACK
		card_data.attack_power = 3
		card_data.description = "损坏的数据碎片"

	var card_node := Card.new()
	card_node.setup(card_data)
	hand_node.add_card(card_node)
	AudioManager.play_sfx_generated("draw")

## 生成数据碎片token到手牌
func _add_token_to_hand() -> void:
	var token := CardData.new()
	token.card_id = "tok_data_shard"
	token.card_name = "数据碎片"
	token.cost = 0
	token.card_type = CardData.CardType.ATTACK
	token.attack_power = 4
	token.exhaust = true
	token.description = "造成4伤害。消耗"
	token.card_color = Color(0.5, 0.5, 0.5, 1)
	# Check power_precision bonus
	if "power_precision" in active_powers:
		token.attack_power += 3
	var card_node := Card.new()
	card_node.setup(token)
	hand_node.add_card(card_node)

## 玩家打出卡牌回调
func _on_card_played(card: Card) -> void:
	if state != BattleState.PLAYER_TURN:
		hand_node._return_card_to_hand(card)
		return
	var data := card.card_data
	if not data:
		hand_node._return_card_to_hand(card)
		return

	# Check unplayable
	if data.unplayable:
		hand_node._return_card_to_hand(card)
		return

	# X-cost handling
	var actual_cost: int = data.cost
	if data.cost == -1:
		actual_cost = energy  # spend all

	if actual_cost > energy:
		hand_node._return_card_to_hand(card)
		return

	energy -= actual_cost
	cards_played_this_turn += 1

	# Track attack cards played
	if data.card_type == CardData.CardType.ATTACK:
		attacks_played_this_turn += 1

	# 更新阴阳
	if data.yinyang == CardData.YinYang.YIN:
		yin_count += abs(data.yinyang_value) if data.yinyang_value != 0 else 1
	elif data.yinyang == CardData.YinYang.YANG:
		yang_count += abs(data.yinyang_value) if data.yinyang_value != 0 else 1
	GameState.yin_count = yin_count
	GameState.yang_count = yang_count

	# 执行效果
	var result: EffectResult = EffectSystem.execute_card(data, player_hp, player_shield)

	# 道境共鸣伤害加成
	var bonus: Dictionary = EffectSystem.calc_resonance_bonus(yin_count, yang_count)
	if bonus["is_resonance"] and result.damage_dealt > 0:
		result.damage_dealt += bonus["damage_bonus"]
	if bonus["is_backlash"] and result.damage_dealt > 0:
		result.damage_dealt = max(0, result.damage_dealt + bonus["damage_bonus"])

	# Glass blade permanent bonus
	if data.effect_id == "glass_blade_grow":
		result.damage_dealt += glass_blade_bonus
		glass_blade_bonus += 2

	# X-cost: data_flood_x
	if data.effect_id == "data_flood_x":
		result.damage_dealt = 8 * actual_cost

	# Power card: afterimage (+1 shield per card)
	if "power_afterimage" in active_powers:
		player_shield += 1

	# Power card: lingchi (2 dmg per card)
	if "power_lingchi" in active_powers:
		if enemy and not enemy.is_dead():
			enemy.take_damage(2)
			_add_log("[color=red]  凌迟：对敌人造成2伤害[/color]")

	# Power card: poison_protocol (+1 corruption per attack)
	if "power_poison_protocol" in active_powers and data.card_type == CardData.CardType.ATTACK:
		if enemy and not enemy.is_dead():
			enemy.apply_status("corruption", 1, -1)
			_add_log("[color=green]  毒素协议：施加1层侵蚀[/color]")

	# Nimble step bonus
	if "power_nimble_step" in active_powers and result.shield_gained > 0:
		result.shield_gained += 2

	_add_log("[color=white]使用: " + data.card_name + " (算力:" + str(actual_cost) + ")[/color]")

	# --- Conditional checks ---
	match result.conditional:
		"enemy_has_corruption":
			if enemy and enemy.has_status("corruption"):
				result.damage_dealt += 7
				_add_log("[color=yellow]  侵蚀触发！额外+7伤害[/color]")
		"not_damaged_this_turn":
			if not turn_damaged:
				result.damage_dealt *= 2
				_add_log("[color=yellow]  精准触发！伤害翻倍[/color]")
		"count_attacks_played":
			result.multi_hit = attacks_played_this_turn
			_add_log("[color=yellow]  终结协议：击" + str(result.multi_hit) + "次[/color]")
		"kill_refund_2energy":
			pass  # handled after damage
		"empty_discard_pile":
			if deck.discard_count() > 0:
				result.damage_dealt = 0
				_add_log("[color=yellow]  弃牌堆不为空，无法造成伤害[/color]")
		"add_corruption_equal_stacks":
			if enemy:
				var stacks: int = enemy.get_status_value("corruption")
				if stacks > 0:
					enemy.apply_status("corruption", stacks, -1)
					_add_log("[color=green]  额外施加" + str(stacks) + "层侵蚀[/color]")
		"resonance_bonus_8":
			if bonus["is_resonance"]:
				result.shield_gained += 8
				_add_log("[color=gold]  道境共鸣！额外+8护盾[/color]")
		"shield_to_damage":
			result.damage_dealt = player_shield
			player_shield = 0
			_add_log("[color=yellow]  护盾转化为" + str(result.damage_dealt) + "伤害[/color]")

	# --- Apply basic effects ---

	# Multi-hit damage
	if result.damage_dealt > 0:
		var hits: int = max(1, result.multi_hit)
		var total_damage: int = 0
		for _i in range(hits):
			if enemy and not enemy.is_dead():
				var actual_dmg: int
				if result.ignore_shield:
					var before_hp: int = enemy.hp
					enemy.hp = max(0, enemy.hp - result.damage_dealt)
					actual_dmg = before_hp - enemy.hp
				else:
					actual_dmg = enemy.take_damage(result.damage_dealt)
				total_damage += actual_dmg
		if total_damage > 0:
			if hits > 1:
				_add_log("[color=red]  → 造成 " + str(result.damage_dealt) + "x" + str(hits) + "=" + str(total_damage) + " 伤害[/color]")
			else:
				_add_log("[color=red]  → 造成 " + str(total_damage) + " 伤害[/color]")
			_flash_enemy_hit()
			_play_player_attack_anim()
			AudioManager.play_sfx_generated("attack")

	if result.shield_gained > 0:
		player_shield += result.shield_gained
		_add_log("[color=blue]  → 获得 " + str(result.shield_gained) + " 护盾[/color]")
		AudioManager.play_sfx_generated("defense")

	if result.healing_done > 0:
		player_hp = min(player_max_hp, player_hp + result.healing_done)
		_add_log("[color=green]  → 恢复 " + str(result.healing_done) + " 生命[/color]")

	if result.cards_drawn > 0 and not no_draw_mode:
		var extra_cards: Array[String] = deck.draw_cards(result.cards_drawn)
		for p in extra_cards:
			_add_card_to_hand(p)
		_add_log("[color=cyan]  → 抽 " + str(extra_cards.size()) + " 张牌[/color]")

	if result.energy_change != 0:
		energy = max(0, energy + result.energy_change)
		_add_log("[color=cyan]  → 算力变化 " + str(result.energy_change) + "[/color]")

	# --- New effect handling ---
	if result.next_turn_energy > 0:
		next_turn_bonus_energy += result.next_turn_energy
		_add_log("[color=cyan]  下回合额外+" + str(result.next_turn_energy) + "算力[/color]")

	if result.exhaust or data.exhaust:
		_add_log("[color=gray]  卡牌消耗[/color]")

	# Apply statuses to enemy
	for status_data in result.apply_statuses_to_enemy:
		if enemy and not enemy.is_dead():
			enemy.apply_status(status_data["type"], status_data["value"], status_data.get("turns", -1))
			_add_log("[color=yellow]  → 对敌方施加 " + status_data["type"] + " " + str(status_data["value"]) + "[/color]")

	# Apply statuses to player
	for status_data in result.apply_statuses_to_player:
		_apply_player_status(status_data["type"], status_data["value"], status_data.get("turns", -1))
		_add_log("[color=blue]  → 获得 " + status_data["type"] + " " + str(status_data["value"]) + "[/color]")

	# Generate tokens (数据碎片)
	if result.generate_tokens > 0:
		for _i in range(result.generate_tokens):
			_add_token_to_hand()
		_add_log("[color=cyan]  → 生成 " + str(result.generate_tokens) + " 张数据碎片[/color]")

	# Discard effects
	if result.discard_all:
		var discard_list: Array = hand_node.cards.duplicate()
		var count: int = discard_list.size()
		for c in discard_list:
			deck.discard(c.card_data.resource_path if c.card_data else "")
		hand_node.clear_hand()
		if result.damage_per_discard > 0 and enemy:
			var total_dmg: int = count * result.damage_per_discard
			enemy.take_damage(total_dmg)
			_add_log("[color=red]  弃" + str(count) + "张牌，造成" + str(total_dmg) + "伤害[/color]")
	elif result.discard_count > 0:
		for _i in range(result.discard_count):
			var discarded: Card = hand_node.discard_random()
			if discarded:
				deck.discard(discarded.card_data.resource_path if discarded.card_data else "")
				_add_log("[color=gray]  弃牌: " + (discarded.card_data.card_name if discarded.card_data else "?") + "[/color]")
				discarded.queue_free()

	# Corruption double
	if result.corruption_double and enemy:
		var current: int = enemy.get_status_value("corruption")
		if current > 0:
			enemy.apply_status("corruption", current, -1)
			_add_log("[color=green]  侵蚀翻倍！" + str(current) + " → " + str(current * 2) + "[/color]")

	# Summon shield
	if result.summon_shield > 0:
		for s in player_summons:
			if s["hp"] > 0:
				s["shield"] = s.get("shield", 0) + result.summon_shield
		_add_log("[color=blue]  所有召唤物+" + str(result.summon_shield) + "护盾[/color]")

	# Heal summons
	if result.heal_summons > 0:
		for s in player_summons:
			if s["hp"] > 0:
				s["hp"] = mini(s.get("max_hp", s["hp"]), s["hp"] + result.heal_summons)

	# Yin/Yang manipulation
	if result.yinyang_reduce_diff > 0:
		var yy_diff: int = absi(yin_count - yang_count)
		if yy_diff > 0:
			var reduce: int = mini(result.yinyang_reduce_diff, yy_diff)
			if yin_count > yang_count:
				yin_count -= reduce / 2
				yang_count += (reduce + 1) / 2
			else:
				yang_count -= reduce / 2
				yin_count += (reduce + 1) / 2

	# Zero cost hand (bullet_time)
	if result.zero_cost_hand:
		for c in hand_node.cards:
			if c.card_data:
				c.card_data.cost = 0
				c._update_display()
		_add_log("[color=yellow]  所有手牌费用变为0[/color]")

	if result.no_draw:
		no_draw_mode = true
		_add_log("[color=gray]  不再抽牌[/color]")

	# Random zero cost
	if result.random_zero_cost > 0:
		var available: Array = hand_node.cards.filter(func(c: Card) -> bool: return c.card_data != null and c.card_data.cost > 0)
		available.shuffle()
		for _i in range(mini(result.random_zero_cost, available.size())):
			available[_i].card_data.cost = 0
			available[_i]._update_display()
		_add_log("[color=yellow]  随机" + str(result.random_zero_cost) + "张手牌费用变为0[/color]")

	# Shuffle discard to deck
	if result.shuffle_discard_to_deck:
		deck.shuffle_discard_into_draw()
		_add_log("[color=cyan]  弃牌堆洗入牌库[/color]")

	# Power card registration
	if data.card_type == CardData.CardType.POWER and result.power_id != "":
		if result.power_id not in active_powers:
			active_powers.append(result.power_id)
			_add_log("[color=gold]  ★ 能力激活: " + data.card_name + "[/color]")

	# Enemy attack reduction
	if result.enemy_attack_reduction > 0 and enemy:
		enemy.apply_status("weak", result.enemy_attack_reduction, 1)

	# Talisman purify
	if data.effect_id == "talisman_purify":
		_clear_player_negative_statuses()
		_add_log("[color=yellow]  负面状态已清除[/color]")

	# Yin/Yang reverse
	if data.effect_id == "yinyang_reverse":
		var tmp := yin_count
		yin_count = yang_count
		yang_count = tmp
		GameState.yin_count = yin_count
		GameState.yang_count = yang_count
		_add_log("[color=yellow]  阴阳逆转！[/color]")

	# Universal balance yin/yang reset
	if data.effect_id == "universal_balance":
		var avg: int = roundi(float(yin_count + yang_count) / 2.0)
		yin_count = avg
		yang_count = avg
		GameState.yin_count = yin_count
		GameState.yang_count = yang_count

	# Bounce vial
	if data.effect_id == "bounce_vial" and enemy:
		for _i in range(3):
			enemy.apply_status("corruption", 3, -1)
		_add_log("[color=green]  弹射3次，共施加9层侵蚀[/color]")

	# Strangle protocol: damage per card played (handled via cards_played_this_turn at end)
	if data.effect_id == "strangle_protocol" and enemy and not enemy.is_dead():
		var strangle_dmg: int = cards_played_this_turn * 2
		if strangle_dmg > 0:
			enemy.take_damage(strangle_dmg)
			_add_log("[color=red]  绞杀协议：额外造成" + str(strangle_dmg) + "伤害[/color]")

	# Kill refund check
	if result.conditional == "kill_refund_2energy" and enemy and enemy.is_dead():
		energy += 2
		_add_log("[color=cyan]  击杀！返还2算力[/color]")

	if result.summon_data:
		_add_player_summon(result.summon_data)

	if result.special_text != "":
		_add_log("[color=yellow]  ★ " + result.special_text + "[/color]")

	# Card-type specific visual effects and SFX
	match data.card_type:
		CardData.CardType.ATTACK:
			_play_attack_card_vfx()
		CardData.CardType.DEFENSE:
			_play_defense_card_vfx()
		CardData.CardType.SUMMON:
			_play_summon_card_vfx()
			AudioManager.play_sfx_generated("summon")
		CardData.CardType.SPELL:
			_play_spell_card_vfx()
			AudioManager.play_sfx_generated("spell")
		CardData.CardType.POWER:
			_play_spell_card_vfx()
			AudioManager.play_sfx_generated("spell")

	# 卡牌动画 → 移除
	await card.play_cast_animation(Vector2(320, 100))
	hand_node.remove_card(card)

	# Exhaust vs discard
	if result.exhaust or data.exhaust:
		pass  # exhausted, don't add to discard
	else:
		deck.discard(data.resource_path if data.resource_path else "")
	card.queue_free()

	# 更新UI
	hand_node.update_playability(energy)
	_update_all_ui()

	# 检查敌人是否死亡
	if enemy and enemy.is_dead():
		_on_enemy_defeated()

## 结束回合按钮
func _on_end_turn_pressed() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	end_turn_btn.disabled = true
	_start_enemy_turn()

## 敌人回合
func _start_enemy_turn() -> void:
	state = BattleState.ENEMY_TURN
	_add_log("[color=red]--- 敌方回合 ---[/color]")

	# Process enemy turn-start statuses (corruption damage, burn, etc.)
	var status_result: Dictionary = enemy.process_turn_start_statuses()
	if status_result["damage"] > 0:
		_add_log("[color=green]状态效果对敌人造成" + str(status_result["damage"]) + "伤害[/color]")

	if enemy.is_dead():
		_on_enemy_defeated()
		return

	# 敌人护盾重置
	enemy.shield = 0

	# 等待短暂延迟
	await get_tree().create_timer(0.5).timeout

	# Check stun
	if status_result.get("skip_turn", false):
		_add_log("[color=yellow]敌人被眩晕，跳过回合[/color]")
		await get_tree().create_timer(0.5).timeout
	else:
		# 敌方召唤物先攻击
		for s in enemy.summons:
			if s["hp"] > 0:
				var sdmg: int = s["attack"]
				var actual: int = _apply_damage_to_player(sdmg)
				_add_log("[color=red]" + s["name"] + " 攻击！造成 " + str(actual) + " 伤害[/color]")
				await get_tree().create_timer(0.3).timeout
				# Death check after each summon attack
				if player_hp <= 0:
					_on_player_defeated()
					return

		# 敌人执行行动
		var action: Dictionary = enemy.execute_action()
		_add_log(action["text"])

		if action["damage_to_player"] > 0:
			var total_enemy_dmg: int = action["damage_to_player"]
			var enemy_hits: int = action.get("multi_hit", 0)
			if enemy_hits <= 1:
				var actual_dmg: int = _apply_damage_to_player(total_enemy_dmg)
				if actual_dmg > 0:
					_flash_player_hit()
					_play_player_hurt_anim()
			else:
				var per_hit: int = total_enemy_dmg
				for _i in range(enemy_hits):
					var actual_dmg: int = _apply_damage_to_player(per_hit)
					if actual_dmg > 0:
						_flash_player_hit()
						_play_player_hurt_anim()
			_play_enemy_attack_anim()
			if enemy_type_key == "boss":
				_play_boss_attack_vfx()
			else:
				AudioManager.play_sfx_generated("attack")

			# Death check immediately after enemy attack
			if player_hp <= 0:
				_on_player_defeated()
				return

			# Power: thorns
			if "power_thorns" in active_powers and enemy and not enemy.is_dead():
				enemy.take_damage(3)
				_add_log("[color=red]  荆棘反击3伤害[/color]")

			# Reflect status
			if _has_player_status("reflect"):
				var reflect_dmg: int = _get_player_status_value("reflect")
				if enemy and not enemy.is_dead():
					enemy.take_damage(reflect_dmg)
					_add_log("[color=red]  反伤" + str(reflect_dmg) + "伤害[/color]")

		# Enemy apply_status to player
		var enemy_status: Dictionary = action.get("apply_status", {})
		if enemy_status.size() > 0:
			_apply_player_status(enemy_status.get("type", ""), enemy_status.get("value", 0), enemy_status.get("turns", 1))

		# Steal energy
		var steal: int = action.get("steal_energy", 0)
		if steal > 0:
			energy = max(0, energy - steal)
			_add_log("[color=red]  被窃取" + str(steal) + "点算力[/color]")

		# Burn summons
		var burn_summons_val: int = action.get("burn_summons", 0)
		if burn_summons_val > 0:
			for s in player_summons:
				if s["hp"] > 0:
					s["hp"] = max(0, s["hp"] - burn_summons_val)
					_add_log("[color=orange]  " + s["name"] + "被灼烧" + str(burn_summons_val) + "伤害[/color]")
					if s["hp"] <= 0:
						_on_summon_died(s)

		if action["special_effect"] == "boss_phase2":
			_trigger_glitch(0.6)
			_add_log("[color=purple]屏幕开始扭曲...心魔正在觉醒...[/color]")

	await get_tree().create_timer(0.5).timeout

	# 玩家召唤物攻击敌人
	for s in player_summons:
		if s["hp"] > 0:
			var sdmg: int = s["attack"]
			var s_hits: int = s.get("multi_hit", 0)
			if s_hits <= 1:
				s_hits = 1
			for _h in range(s_hits):
				if enemy and not enemy.is_dead():
					enemy.take_damage(sdmg)
			var total_sdmg: int = sdmg * s_hits
			_add_log("[color=green]" + s["name"] + " 攻击敌人！造成 " + str(total_sdmg) + " 伤害[/color]")
			# Summon passive: poison on attack
			if s.get("passive", "") == "poison_1_on_attack":
				if enemy and not enemy.is_dead():
					enemy.apply_status("corruption", 1, -1)
					_add_log("[color=green]  " + s["name"] + "施加1层侵蚀[/color]")
			await get_tree().create_timer(0.3).timeout

	# Summon passive: heal per turn
	for s in player_summons:
		if s["hp"] > 0 and s.get("passive", "") == "heal_1_per_turn":
			player_hp = min(player_max_hp, player_hp + 1)
			_add_log("[color=green]" + s["name"] + "治疗1HP[/color]")

	# Power: poison_fog (all enemies get 2 corruption at end of turn)
	if "power_poison_fog" in active_powers and enemy and not enemy.is_dead():
		enemy.apply_status("corruption", 2, -1)
		_add_log("[color=green]毒雾：敌人获得2层侵蚀[/color]")

	_update_all_ui()

	# 检查结果
	if player_hp <= 0:
		_on_player_defeated()
		return
	if enemy and enemy.is_dead():
		_on_enemy_defeated()
		return

	# 弃置手牌（处理保留/弃牌触发）
	_end_turn_discard()

	# 开始新的玩家回合
	_start_player_turn()

## 回合结束弃牌（处理保留和弃牌触发型卡牌）
func _end_turn_discard() -> void:
	var cards_to_discard: Array = []
	var cards_to_keep: Array = []

	for c in hand_node.cards.duplicate():
		if not c.card_data:
			cards_to_discard.append(c)
			continue
		if c.card_data.retain:
			cards_to_keep.append(c)
			continue
		# Check unplayable discard triggers
		if c.card_data.unplayable:
			_trigger_discard_effect(c)
		cards_to_discard.append(c)

	for c in cards_to_discard:
		deck.discard(c.card_data.resource_path if c.card_data else "")
	hand_node.clear_hand()

	# Re-add retained cards
	for c in cards_to_keep:
		hand_node.add_card(c)

## 弃牌触发效果
func _trigger_discard_effect(card: Card) -> void:
	if not card.card_data:
		return
	var result: EffectResult = EffectSystem.execute_card(card.card_data)
	if result.unplayable_on_discard_damage > 0 and enemy and not enemy.is_dead():
		enemy.take_damage(result.unplayable_on_discard_damage)
		_add_log("[color=red]  " + card.card_data.card_name + "弃牌触发：造成" + str(result.unplayable_on_discard_damage) + "伤害[/color]")
	if result.unplayable_on_discard_energy > 0:
		energy += result.unplayable_on_discard_energy
		_add_log("[color=cyan]  " + card.card_data.card_name + "弃牌触发：获得" + str(result.unplayable_on_discard_energy) + "算力[/color]")
	if result.unplayable_on_discard_draw > 0:
		var drawn: Array[String] = deck.draw_cards(result.unplayable_on_discard_draw)
		for p in drawn:
			_add_card_to_hand(p)
		_add_log("[color=cyan]  " + card.card_data.card_name + "弃牌触发：抽" + str(result.unplayable_on_discard_draw) + "张牌[/color]")

# ============================================================
# Damage and Status Systems
# ============================================================
## 对玩家造成伤害（考虑无敌、前排召唤物拦截、护盾）
func _apply_damage_to_player(amount: int) -> int:
	var remaining := amount

	# Check intangible
	if _has_player_status("intangible"):
		remaining = 1

	# Front-row summons intercept first
	for s in player_summons:
		if s["hp"] > 0 and s.get("position", "front") == "front" and remaining > 0:
			var summon_shield: int = s.get("shield", 0)
			if summon_shield > 0:
				if summon_shield >= remaining:
					s["shield"] = summon_shield - remaining
					_add_log("[color=cyan]  " + s["name"] + "的护盾吸收了" + str(remaining) + "伤害[/color]")
					remaining = 0
				else:
					remaining -= summon_shield
					s["shield"] = 0
			if remaining > 0:
				var absorbed := mini(remaining, s["hp"])
				s["hp"] -= absorbed
				remaining -= absorbed
				_add_log("[color=cyan]  " + s["name"] + "替你挡了" + str(absorbed) + "伤害[/color]")
				if s["hp"] <= 0:
					_on_summon_died(s)
			if remaining <= 0:
				_update_summon_display()
				return amount - remaining

	# Then player shield
	if player_shield > 0:
		if player_shield >= remaining:
			player_shield -= remaining
			_update_all_ui()
			return 0
		else:
			remaining -= player_shield
			player_shield = 0

	player_hp = max(0, player_hp - remaining)
	if remaining > 0:
		turn_damaged = true
	_update_all_ui()
	return remaining

## 召唤物死亡处理
func _on_summon_died(summon: Dictionary) -> void:
	_add_log("[color=red]  " + summon["name"] + "被消灭了！[/color]")
	if summon.get("passive", "") == "draw_1_on_death":
		var drawn: Array[String] = deck.draw_cards(1)
		for p in drawn:
			_add_card_to_hand(p)
		_add_log("[color=cyan]  " + summon["name"] + "死亡触发：抽1张牌[/color]")

## 施加玩家状态效果
func _apply_player_status(status_type: String, value: int, turns: int) -> void:
	for s in player_statuses:
		if s["type"] == status_type:
			s["value"] += value
			if turns > 0:
				s["turns"] = max(s["turns"], turns)
			return
	player_statuses.append({"type": status_type, "value": value, "turns": turns})

## 检查玩家是否有某个状态
func _has_player_status(status_type: String) -> bool:
	for s in player_statuses:
		if s["type"] == status_type and s["value"] > 0:
			return true
	return false

## 获取玩家状态数值
func _get_player_status_value(status_type: String) -> int:
	for s in player_statuses:
		if s["type"] == status_type:
			return s["value"]
	return 0

## 处理玩家回合开始时的状态效果
func _process_player_turn_start_statuses() -> void:
	var to_remove: Array[int] = []
	for i in range(player_statuses.size()):
		var s: Dictionary = player_statuses[i]
		match s["type"]:
			"burn":
				var burn_dmg: int = 2  # flat 2 per turn
				player_hp = max(0, player_hp - burn_dmg)
				_add_log("[color=orange]灼烧造成" + str(burn_dmg) + "伤害[/color]")
			"delayed_shield":
				player_shield += s["value"]
				_add_log("[color=blue]延迟护盾生效: +" + str(s["value"]) + "护盾[/color]")
				to_remove.append(i)
			"reflect":
				pass  # processed on damage taken
			"intangible":
				pass  # processed in damage calc
		if s.get("turns", -1) > 0:
			s["turns"] -= 1
			if s["turns"] <= 0 and i not in to_remove:
				to_remove.append(i)
	to_remove.sort()
	to_remove.reverse()
	for idx in to_remove:
		if idx < player_statuses.size():
			player_statuses.remove_at(idx)

## 清除玩家负面状态
func _clear_player_negative_statuses() -> void:
	player_statuses = player_statuses.filter(func(s: Dictionary) -> bool: return s["type"] not in ["burn", "weak", "vulnerable", "corruption"])

# ============================================================
# Summon System
# ============================================================
## 添加玩家召唤物
func _add_player_summon(card_data: CardData) -> void:
	# 召唤物上限检查
	if player_summons.size() >= MAX_SUMMONS:
		_add_log("[color=yellow]召唤失败：场上已有 " + str(MAX_SUMMONS) + " 个召唤物！[/color]")
		return
	var summon := {
		"name": card_data.card_name,
		"hp": card_data.summon_hp,
		"max_hp": card_data.summon_hp,
		"attack": card_data.attack_power,
		"card_id": card_data.card_id,
		"position": "front",  # default to front row
		"shield": 0,
		"passive": card_data.summon_passive,
		"multi_hit": card_data.multi_hit,
	}
	player_summons.append(summon)
	_update_summon_display()
	_add_log("[color=green]召唤: " + summon["name"] + " [前排] (攻:" + str(summon["attack"]) + " 血:" + str(summon["hp"]) + ")[/color]")

## 更新召唤物显示 — 战场独立sprite（v5重写）
func _update_summon_display() -> void:
	# 清理旧的战场sprite节点（标记为 _summon_node 的子节点）
	var to_remove: Array[Node] = []
	for child in play_zone.get_children():
		if child.has_meta("_summon_node"):
			to_remove.append(child)
	for child in to_remove:
		child.queue_free()

	# 分离前排和后排
	var front_list: Array[Dictionary] = []
	var back_list: Array[Dictionary] = []
	var front_indices: Array[int] = []
	var back_indices: Array[int] = []
	for idx in range(player_summons.size()):
		var s: Dictionary = player_summons[idx]
		if s["hp"] <= 0:
			continue
		if s.get("position", "front") == "front":
			front_list.append(s)
			front_indices.append(idx)
		else:
			back_list.append(s)
			back_indices.append(idx)

	# 地面线 y 坐标（sprite底部对齐）
	var ground_y: int = 310
	var sprite_h: int = 96
	var sprite_w: int = 72

	# 后排：靠近玩家（x: 190起）
	for i in range(back_list.size()):
		var s: Dictionary = back_list[i]
		var sx: int = 190 + i * 78
		var sy: int = ground_y - sprite_h
		_create_summon_battlefield_node(s, sx, sy, sprite_w, sprite_h, back_indices[i], false)

	# 前排：玩家和敌人之间（x: 320起）
	for i in range(front_list.size()):
		var s: Dictionary = front_list[i]
		var sx: int = 320 + i * 78
		var sy: int = ground_y - sprite_h
		_create_summon_battlefield_node(s, sx, sy, sprite_w, sprite_h, front_indices[i], true)

## 创建单个召唤物战场节点
func _create_summon_battlefield_node(s: Dictionary, sx: int, sy: int, sw: int, sh: int, idx: int, is_front: bool) -> void:
	var container := Control.new()
	container.position = Vector2(sx, sy)
	container.size = Vector2(sw, sh + 30)
	container.mouse_filter = Control.MOUSE_FILTER_PASS
	container.set_meta("_summon_node", true)

	# Sprite
	var sprite := TextureRect.new()
	var summon_type := _get_summon_sprite_type(s.get("card_id", ""))
	sprite.texture = _ai_sprite(summon_type, 0)
	sprite.position = Vector2(0, 0)
	sprite.size = Vector2(sw, sh)
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(sprite)

	# 前排蓝色盾牌图标
	if is_front and _front_shield_texture:
		var shield_icon := TextureRect.new()
		shield_icon.texture = _front_shield_texture
		shield_icon.position = Vector2(sw / 2 - 10, -4)
		shield_icon.size = Vector2(20, 20)
		shield_icon.stretch_mode = TextureRect.STRETCH_SCALE
		shield_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		shield_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(shield_icon)

	# HP条背景
	var hp_bg := ColorRect.new()
	hp_bg.position = Vector2(4, sh + 2)
	hp_bg.size = Vector2(sw - 8, 6)
	hp_bg.color = Color(0.2, 0.1, 0.1, 0.8)
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(hp_bg)

	# HP条填充
	var hp_fill := ColorRect.new()
	var hp_ratio: float = float(s["hp"]) / float(maxi(s["max_hp"], 1))
	hp_fill.position = Vector2(4, sh + 2)
	hp_fill.size = Vector2(int((sw - 8) * hp_ratio), 6)
	hp_fill.color = Color(0.2, 0.85, 0.3) if hp_ratio > 0.5 else Color(0.9, 0.4, 0.1)
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(hp_fill)

	# 名字 + 位置标签
	var name_lbl := Label.new()
	var pos_tag := "[前]" if is_front else "[后]"
	name_lbl.text = pos_tag + s["name"]
	name_lbl.position = Vector2(0, sh + 8)
	name_lbl.size = Vector2(sw + 20, 16)
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(0.3, 1, 0.5) if is_front else Color(0.5, 0.8, 0.6))
	name_lbl.clip_text = true
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(name_lbl)

	# 盾值显示
	if s.get("shield", 0) > 0:
		var shield_lbl := Label.new()
		shield_lbl.text = "🛡" + str(s["shield"])
		shield_lbl.position = Vector2(sw - 30, sh - 16)
		shield_lbl.size = Vector2(30, 14)
		shield_lbl.add_theme_font_size_override("font_size", 10)
		shield_lbl.add_theme_color_override("font_color", Color(0.3, 0.6, 1))
		shield_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(shield_lbl)

	# 点击切换前后排
	var click_area := Button.new()
	click_area.position = Vector2(0, 0)
	click_area.size = Vector2(sw, sh)
	click_area.flat = true
	click_area.mouse_filter = Control.MOUSE_FILTER_STOP
	click_area.modulate = Color(1, 1, 1, 0)  # 透明按钮
	var captured_idx := idx
	click_area.pressed.connect(func() -> void: _toggle_summon_position(captured_idx))
	container.add_child(click_area)

	play_zone.add_child(container)

## 获取召唤物sprite类型
func _get_summon_sprite_type(card_id: String) -> String:
	match card_id:
		"sum_cyber_fox": return "summon_fox"
		"sum_dao_crane": return "summon_crane"
		"sum_spirit_dragon": return "summon_dragon"
		"sum_neon_golem": return "summon_golem"
		"sum_pixel_sprite": return "summon_sprite"
		"sum_shadow_clone": return "summon_clone"
		"sum_byte_familiar": return "summon_familiar"
		"sum_swarm": return "summon_swarm"
		"sum_beast": return "summon_beast"
		_: return "summon_sprite"

## 切换召唤物前后排
func _toggle_summon_position(idx: int) -> void:
	if idx < 0 or idx >= player_summons.size():
		return
	var s: Dictionary = player_summons[idx]
	if s.get("position", "front") == "front":
		s["position"] = "back"
		_add_log("[color=cyan]" + s["name"] + " 移至后排[/color]")
	else:
		s["position"] = "front"
		_add_log("[color=cyan]" + s["name"] + " 移至前排[/color]")
	_update_summon_display()

# ============================================================
# 战斗结束
# ============================================================
func _on_enemy_defeated() -> void:
	state = BattleState.VICTORY
	_add_log("[color=gold]===== 胜利！=====[/color]")
	AudioManager.play_sfx_generated("victory")
	AudioManager.stop_bgm(0.5)
	GameState.battles_won += 1
	GameState.player_hp = player_hp

	# 奖励金币
	var gold_reward: int = 15 + randi() % 10
	GameState.player_gold += gold_reward
	_add_log("[color=yellow]获得 " + str(gold_reward) + " 金币[/color]")

	# Victory transition
	await _play_victory_transition()

	# Boss特殊处理
	if enemy_type_key == "boss":
		if player_hp == player_max_hp:
			GameState.achievements["no_damage_boss"] = true
		GameState.achievements["first_awakening"] = true
		await get_tree().create_timer(1.5).timeout
		Global.is_transitioning = false
		get_tree().change_scene_to_file(Global.SCENE_VICTORY)
	else:
		await get_tree().create_timer(1.0).timeout
		GameState.advance_node()
		Global.is_transitioning = false
		get_tree().change_scene_to_file(Global.SCENE_EVENT)

func _on_player_defeated() -> void:
	state = BattleState.DEFEAT
	_add_log("[color=red]===== 战败 =====[/color]")
	AudioManager.play_sfx_generated("defeat")
	AudioManager.stop_bgm(0.5)

	# Defeat transition
	await _play_defeat_transition()

	await get_tree().create_timer(1.5).timeout
	# Direct scene change - bypass Global.change_scene to avoid transition lock
	Global.is_transitioning = false
	get_tree().change_scene_to_file(Global.SCENE_DEFEAT)

# ============================================================
# 卡牌类型视觉效果
# ============================================================
## Diagonal slash lines streaking from player toward enemy
func _play_attack_card_vfx() -> void:
	if not player_sprite or not enemy_sprite:
		return
	var start_pos: Vector2 = play_zone.position + player_sprite.position + player_sprite.size / 2.0
	var end_pos: Vector2 = play_zone.position + enemy_sprite.position + enemy_sprite.size / 2.0
	var colors: Array[Color] = [
		Color(1.0, 0.2, 0.1, 0.9),
		Color(1.0, 0.45, 0.1, 0.85),
		Color(0.9, 0.3, 0.05, 0.8),
	]
	for i in range(3):
		var slash := ColorRect.new()
		slash.size = Vector2(80, 3)
		slash.color = colors[i]
		slash.position = start_pos + Vector2(0, -10 + i * 10)
		slash.rotation = deg_to_rad(45.0)
		slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slash.z_index = 50
		add_child(slash)
		var target := end_pos + Vector2(0, -10 + i * 10)
		var delay: float = i * 0.05
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(slash, "position", target, 0.2).set_delay(delay)
		tw.tween_property(slash, "color:a", 0.0, 0.1).set_delay(delay + 0.15)
		tw.chain().tween_callback(slash.queue_free)

## Shield ring of 8 squares expanding outward around the player sprite
func _play_defense_card_vfx() -> void:
	if not player_sprite:
		return
	var center: Vector2 = play_zone.position + player_sprite.position + player_sprite.size / 2.0
	for i in range(8):
		var angle: float = float(i) * TAU / 8.0
		var dir := Vector2(cos(angle), sin(angle))
		var square := ColorRect.new()
		square.size = Vector2(10, 10)
		square.color = Color(0.2, 0.5, 1.0, 0.8)
		square.position = center + dir * 20.0 - Vector2(5, 5)
		square.mouse_filter = Control.MOUSE_FILTER_IGNORE
		square.z_index = 50
		add_child(square)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(square, "position", center + dir * 40.0 - Vector2(5, 5), 0.35)
		tw.tween_property(square, "color:a", 0.0, 0.35)
		tw.chain().tween_callback(square.queue_free)

## Pillar of light at the summon area with rising particles
func _play_summon_card_vfx() -> void:
	# 光柱出现在战场召唤物区域（前排位置附近）
	var pillar_x: float = play_zone.position.x + 340.0
	var pillar_y: float = play_zone.position.y + 110.0
	var pillar := ColorRect.new()
	pillar.size = Vector2(40, 300)
	pillar.position = Vector2(pillar_x, pillar_y)
	pillar.color = Color(0.1, 1.0, 0.3, 0.0)
	pillar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pillar.z_index = 50
	add_child(pillar)
	var tw := create_tween()
	tw.tween_property(pillar, "color:a", 0.7, 0.2)
	tw.tween_property(pillar, "color:a", 0.0, 0.2)
	tw.tween_callback(pillar.queue_free)
	# Rising particles
	for i in range(6):
		var particle := ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = Color(0.2, 1.0, 0.4, 0.8)
		particle.position = Vector2(pillar_x + randf_range(5, 35), pillar_y + 280.0 - float(i) * 30.0)
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particle.z_index = 50
		add_child(particle)
		var ptw := create_tween()
		ptw.set_parallel(true)
		ptw.tween_property(particle, "position:y", particle.position.y - 80.0, 0.4).set_delay(float(i) * 0.05)
		ptw.tween_property(particle, "color:a", 0.0, 0.3).set_delay(float(i) * 0.05 + 0.15)
		ptw.chain().tween_callback(particle.queue_free)

## Rotating rune circle of purple/gold dots at screen center
func _play_spell_card_vfx() -> void:
	var center := Vector2(640, 210)
	var ring_container := Control.new()
	ring_container.position = center
	ring_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring_container.z_index = 50
	add_child(ring_container)
	for i in range(12):
		var angle: float = float(i) * TAU / 12.0
		var dot := ColorRect.new()
		dot.size = Vector2(6, 6)
		dot.position = Vector2(cos(angle) * 60.0 - 3.0, sin(angle) * 60.0 - 3.0)
		if i % 2 == 0:
			dot.color = Color(0.6, 0.15, 0.9, 1.0)
		else:
			dot.color = Color(0.9, 0.75, 0.2, 1.0)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring_container.add_child(dot)
	ring_container.pivot_offset = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(ring_container, "rotation", TAU, 0.5)
	tw.tween_property(ring_container, "modulate:a", 0.0, 0.2)
	tw.tween_callback(ring_container.queue_free)

## Boss enhanced attack effect: strong screen shake + red flash overlay
func _play_boss_attack_vfx() -> void:
	# Red flash overlay
	var flash := ColorRect.new()
	flash.set_anchors_preset(PRESET_FULL_RECT)
	flash.color = Color(0.8, 0.05, 0.05, 0.35)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 60
	add_child(flash)
	var flash_tw := create_tween()
	flash_tw.tween_property(flash, "color:a", 0.0, 0.4)
	flash_tw.tween_callback(flash.queue_free)
	# Strong screen shake
	var orig_pos := position
	var shake_tw := create_tween()
	for i in range(8):
		shake_tw.tween_property(self, "position", orig_pos + Vector2(randf_range(-6, 6), randf_range(-6, 6)), 0.03)
	shake_tw.tween_property(self, "position", orig_pos, 0.04)
	AudioManager.play_sfx_generated("boss_attack")

## Enemy attack animation - enemy moves left toward player briefly
func _play_enemy_attack_anim() -> void:
	if not enemy_sprite:
		return
	var orig_pos := enemy_sprite.position
	enemy_sprite.texture = _ai_sprite(enemy_type_key, 1)
	var tw := create_tween()
	tw.tween_property(enemy_sprite, "position:x", orig_pos.x - 20.0, 0.08)
	tw.tween_property(enemy_sprite, "position:x", orig_pos.x, 0.12)
	tw.tween_callback(func():
		if is_instance_valid(enemy_sprite):
			enemy_sprite.texture = _ai_sprite(enemy_type_key, 0)
	)

# ============================================================
# 视觉效果
# ============================================================
func _flash_enemy_hit() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(enemy_hp_bar, "modulate", Color(1, 0, 0), 0.1)
	tween.tween_property(enemy_hp_bar, "modulate", Color.WHITE, 0.2)
	# Shake enemy sprite and briefly change frame
	if enemy_sprite:
		var orig_pos := enemy_sprite.position
		var shake_amp: float = 16.0 if enemy_type_key == "boss" else 8.0
		var shake_amp_half: float = shake_amp / 2.0
		enemy_sprite.texture = _ai_sprite(enemy_type_key, 2)
		var shake_tw := create_tween()
		shake_tw.tween_property(enemy_sprite, "position:x", orig_pos.x - shake_amp, 0.04)
		shake_tw.tween_property(enemy_sprite, "position:x", orig_pos.x + shake_amp, 0.04)
		shake_tw.tween_property(enemy_sprite, "position:x", orig_pos.x - shake_amp_half, 0.04)
		shake_tw.tween_property(enemy_sprite, "position:x", orig_pos.x, 0.04)
		shake_tw.tween_callback(func():
			if is_instance_valid(enemy_sprite):
				enemy_sprite.texture = _ai_sprite(enemy_type_key, 0)
		)
		if enemy_type_key == "boss":
			AudioManager.play_sfx_generated("boss_hurt")

func _flash_player_hit() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(hp_bar, "modulate", Color(1, 0, 0), 0.1)
	tween.tween_property(hp_bar, "modulate", Color.WHITE, 0.2)
	# Shake player sprite and briefly flash red
	if player_sprite:
		var orig_pos := player_sprite.position
		var shake_tw := create_tween()
		shake_tw.tween_property(player_sprite, "modulate", Color(1, 0.2, 0.2), 0.06)
		shake_tw.tween_property(player_sprite, "position:x", orig_pos.x - 6.0, 0.03)
		shake_tw.tween_property(player_sprite, "position:x", orig_pos.x + 6.0, 0.03)
		shake_tw.tween_property(player_sprite, "position:x", orig_pos.x, 0.04)
		shake_tw.tween_property(player_sprite, "modulate", Color.WHITE, 0.15)

func _trigger_glitch(intensity: float) -> void:
	# Set glitch shader intensity if available
	if glitch_rect and glitch_rect.material is ShaderMaterial:
		var mat := glitch_rect.material as ShaderMaterial
		mat.set_shader_parameter("glitch_intensity", intensity)
		# Fade out the glitch intensity over time
		var fade_tw := create_tween()
		fade_tw.tween_method(func(val: float):
			mat.set_shader_parameter("glitch_intensity", val)
		, intensity, 0.0, 1.5)
	else:
		# Fallback: original color-based glitch
		var colors: Array[Color] = [
			Color(0.8, 0.0, 0.2, intensity * 0.5),
			Color(0.5, 0.0, 0.8, intensity * 0.4),
			Color(0.0, 0.8, 0.8, intensity * 0.3),
			Color(1.0, 1.0, 1.0, intensity * 0.2),
		]
		for i in range(4):
			glitch_rect.color = colors[i]
			await get_tree().create_timer(0.07).timeout
		var tween: Tween = create_tween()
		tween.tween_property(glitch_rect, "color:a", 0.0, 1.5)

	var original_pos := position
	for j in range(6):
		position = original_pos + Vector2(randf_range(-3, 3) * intensity, randf_range(-2, 2) * intensity)
		await get_tree().create_timer(0.05).timeout
	position = original_pos

# ============================================================
# UI更新
# ============================================================
func _update_all_ui() -> void:
	hp_bar.max_value = player_max_hp
	hp_bar.value = player_hp
	hp_label.text = str(player_hp) + "/" + str(player_max_hp)
	player_shield_label.text = "护盾: " + str(player_shield) if player_shield > 0 else ""
	energy_label.text = "算力: " + str(energy) + "/" + str(max_energy)

	if enemy:
		enemy_hp_bar.max_value = enemy.max_hp
		enemy_hp_bar.value = enemy.hp
		enemy_hp_label.text = str(enemy.hp) + "/" + str(enemy.max_hp)
		enemy_name_label.text = enemy.enemy_name
		enemy_intent_label.text = enemy.get_intent_text()
		enemy_shield_label.text = "🛡" + str(enemy.shield) if enemy.shield > 0 else ""

		# Enemy status icons (replace text display)
		var enemy_status_text := ""
		_update_enemy_status_icons()

	yin_label.text = "阴: " + str(yin_count)
	yang_label.text = "阳: " + str(yang_count)

	# Player status icons
	_update_player_status_icons()

	var diff: int = absi(yin_count - yang_count)
	if diff <= 2 and (yin_count + yang_count) > 0:
		balance_label.text = "☯ 道境共鸣！"
		balance_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	elif diff >= 4:
		balance_label.text = "⚠ 心魔反噬！"
		balance_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.3))
	else:
		balance_label.text = "平衡: " + str(diff)
		balance_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))

	turn_label.text = "回合: " + str(turn_number)
	deck_count_label.text = "牌库: " + str(deck.draw_count())
	discard_count_label.text = "弃牌: " + str(deck.discard_count())

	_update_summon_display()

## 战斗日志 — 浮动文字（v5重写）
func _add_log(text: String) -> void:
	if not _floating_log_container:
		return
	# 纯文本（去除BBCode标签用于Label显示）
	var clean_text := text
	# 简单去标签
	var regex_result := clean_text
	while "[color=" in regex_result:
		var start := regex_result.find("[color=")
		var end := regex_result.find("]", start)
		if end >= 0:
			regex_result = regex_result.substr(0, start) + regex_result.substr(end + 1)
		else:
			break
	regex_result = regex_result.replace("[/color]", "")

	# 提取颜色（简单方法）
	var label_color := Color(0.7, 0.7, 0.8)
	if "[color=red]" in text: label_color = Color(1, 0.4, 0.3)
	elif "[color=green]" in text: label_color = Color(0.3, 1, 0.5)
	elif "[color=cyan]" in text: label_color = Color(0, 0.9, 1)
	elif "[color=yellow]" in text: label_color = Color(1, 0.85, 0.3)
	elif "[color=gold]" in text: label_color = Color(1, 0.8, 0.2)
	elif "[color=gray]" in text: label_color = Color(0.5, 0.5, 0.6)

	var lbl := Label.new()
	lbl.text = regex_result
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", label_color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_floating_log_container.add_child(lbl)

	# 限制最多显示2行，超过删掉最早的
	while _floating_log_container.get_child_count() > 2:
		var oldest := _floating_log_container.get_child(0)
		_floating_log_container.remove_child(oldest)
		oldest.queue_free()

	# 3秒后自动淡出
	var tw := create_tween()
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(2.5)
	tw.tween_callback(func():
		if is_instance_valid(lbl) and lbl.get_parent():
			lbl.get_parent().remove_child(lbl)
			lbl.queue_free()
	)

## 更新敌人状态图标
func _update_enemy_status_icons() -> void:
	if not enemy_status_container:
		return
	for child in enemy_status_container.get_children():
		child.queue_free()
	if not enemy:
		return
	for s in enemy.statuses:
		if s["value"] > 0 and s["type"] in ["corruption", "burn", "weak", "vulnerable"]:
			var icon_box := HBoxContainer.new()
			icon_box.add_theme_constant_override("separation", 1)
			icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			# Icon
			var icon := TextureRect.new()
			icon.texture = PixelArtGenerator.generate_status_icon(s["type"])
			icon.size = Vector2(16, 16)
			icon.custom_minimum_size = Vector2(16, 16)
			icon.stretch_mode = TextureRect.STRETCH_SCALE
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon_box.add_child(icon)
			# Value
			var val_lbl := Label.new()
			val_lbl.text = str(s["value"])
			val_lbl.add_theme_font_size_override("font_size", 11)
			var icon_color := Color.WHITE
			match s["type"]:
				"corruption": icon_color = Color(0.2, 0.85, 0.3)
				"burn": icon_color = Color(1, 0.5, 0.1)
				"weak": icon_color = Color(0.3, 0.5, 1)
				"vulnerable": icon_color = Color(1, 0.3, 0.2)
			val_lbl.add_theme_color_override("font_color", icon_color)
			val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon_box.add_child(val_lbl)
			enemy_status_container.add_child(icon_box)

## 更新玩家状态图标
func _update_player_status_icons() -> void:
	if not player_status_container:
		return
	for child in player_status_container.get_children():
		child.queue_free()
	for s in player_statuses:
		if s["value"] > 0 and s["type"] in ["corruption", "burn", "weak", "vulnerable", "intangible"]:
			var icon_box := HBoxContainer.new()
			icon_box.add_theme_constant_override("separation", 1)
			icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var icon := TextureRect.new()
			icon.texture = PixelArtGenerator.generate_status_icon(s["type"])
			icon.size = Vector2(14, 14)
			icon.custom_minimum_size = Vector2(14, 14)
			icon.stretch_mode = TextureRect.STRETCH_SCALE
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon_box.add_child(icon)
			var val_lbl := Label.new()
			val_lbl.text = str(s["value"])
			val_lbl.add_theme_font_size_override("font_size", 10)
			var icon_color := Color.WHITE
			match s["type"]:
				"corruption": icon_color = Color(0.2, 0.85, 0.3)
				"burn": icon_color = Color(1, 0.5, 0.1)
				"weak": icon_color = Color(0.3, 0.5, 1)
				"vulnerable": icon_color = Color(1, 0.3, 0.2)
				"intangible": icon_color = Color(0.6, 0.8, 1)
			val_lbl.add_theme_color_override("font_color", icon_color)
			val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon_box.add_child(val_lbl)
			player_status_container.add_child(icon_box)
