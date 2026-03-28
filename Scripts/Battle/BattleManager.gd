# ============================================================
# BattleManager.gd - 战斗管理器（回合状态机核心）
# 挂载在Battle.tscn根节点上
# ============================================================
extends Control

# 效果系统类型引用（解决 EffectResult 类型不可见问题）
const EffectResult := EffectSystem.EffectResult

# --- AI资产辅助函数 ---
static func _ai_sprite(char_type: String, frame: int = 0) -> ImageTexture:
	var ai_tex := AssetLoader.get_character_sprite(char_type, frame)
	if ai_tex:
		return ai_tex
	# Fallback to programmatic pixel art
	return PixelArtGenerator.generate_character_sprite(char_type, frame)

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
var _energy_field_rect: ColorRect = null   # 战场能量场 shader 层
var _ink_flow_rect: ColorRect = null       # 墨迹流动 shader 层
var _enemy_aura_rect: ColorRect = null     # 敌人气场光圈
var _taiji_rot_tween: Tween = null
var _floating_log_container: VBoxContainer = null
var _front_shield_texture: ImageTexture = null  # cached

# --- 卡牌指向系统（杀戮尖塔式拖拽指向）---
var _drag_arrow: Line2D = null          # 拖拽时的指向箭头
var _drag_arrow_head: Polygon2D = null  # 箭头头部三角
var _highlight_rect: ColorRect = null   # 目标高亮框
var _last_hover_target: String = ""     # 上次悬停的目标

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

	# --- 能量场 shader 层（电路符文 + 太极暗纹 + 雾气）---
	_energy_field_rect = ColorRect.new()
	_energy_field_rect.set_anchors_preset(PRESET_FULL_RECT)
	_energy_field_rect.color = Color(1, 1, 1, 1)
	_energy_field_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_energy_field_rect.z_index = 1
	var ef_shader := load("res://Shaders/energy_field.gdshader") as Shader
	if ef_shader:
		var ef_mat := ShaderMaterial.new()
		ef_mat.shader = ef_shader
		ef_mat.set_shader_parameter("field_intensity", 0.25)
		ef_mat.set_shader_parameter("circuit_speed", 0.4)
		ef_mat.set_shader_parameter("fog_density", 0.2)
		ef_mat.set_shader_parameter("battle_state", 0)
		_energy_field_rect.material = ef_mat
	add_child(_energy_field_rect)

	# --- 墨迹流动层（持续微弱底纹）---
	_ink_flow_rect = ColorRect.new()
	_ink_flow_rect.set_anchors_preset(PRESET_FULL_RECT)
	_ink_flow_rect.color = Color(1, 1, 1, 1)
	_ink_flow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink_flow_rect.z_index = 2
	var ink_shader := load("res://Shaders/ink_flow.gdshader") as Shader
	if ink_shader:
		var ink_mat := ShaderMaterial.new()
		ink_mat.shader = ink_shader
		ink_mat.set_shader_parameter("ink_intensity", 0.12)
		ink_mat.set_shader_parameter("flow_speed", 0.3)
		ink_mat.set_shader_parameter("ink_color_mode", 0)
		ink_mat.set_shader_parameter("spread_radius", 0.0)
		_ink_flow_rect.material = ink_mat
	add_child(_ink_flow_rect)

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
	# 敌人气场光圈（精灵下方）
	_enemy_aura_rect = ColorRect.new()
	_enemy_aura_rect.size = Vector2(180, 230)
	_enemy_aura_rect.position = Vector2(522, 92)
	_enemy_aura_rect.color = Color(1, 1, 1, 0.6)
	_enemy_aura_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var enemy_aura_shader := load("res://Shaders/summon_aura.gdshader") as Shader
	if enemy_aura_shader:
		var ea_mat := ShaderMaterial.new()
		ea_mat.shader = enemy_aura_shader
		# Boss 用紫色，精英用橙色，普通用青色
		var enemy_color_mode: int = 3
		match enemy_type_key:
			"boss": enemy_color_mode = 2
			"elite", "elite2": enemy_color_mode = 1
		ea_mat.set_shader_parameter("color_mode", enemy_color_mode)
		ea_mat.set_shader_parameter("pulse_speed", 1.5)
		ea_mat.set_shader_parameter("glow_intensity", 0.6)
		ea_mat.set_shader_parameter("rune_visibility", 0.2)
		_enemy_aura_rect.material = ea_mat
	play_zone.add_child(_enemy_aura_rect)

	enemy_sprite = TextureRect.new()
	enemy_sprite.position = Vector2(500, 60)
	enemy_sprite.size = Vector2(192, 256)
	enemy_sprite.stretch_mode = TextureRect.STRETCH_SCALE
	enemy_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	enemy_sprite.texture = _ai_sprite("grunt", 0)
	play_zone.add_child(enemy_sprite)

	# --- 2. Player character sprite (LEFT side) ---
	player_sprite = TextureRect.new()
	player_sprite.position = Vector2(30, 130)
	player_sprite.size = Vector2(192, 256)
	player_sprite.stretch_mode = TextureRect.STRETCH_SCALE
	player_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player_sprite.texture = _ai_sprite("player", 0)
	play_zone.add_child(player_sprite)
	# Start idle bobbing animation
	_start_player_idle_bob()

	# --- 角色脚下阴影（消除漂浮感）---
	var player_shadow := ColorRect.new()
	player_shadow.size = Vector2(150, 18)
	player_shadow.position = Vector2(50, 384)
	player_shadow.color = Color(0, 0, 0, 0)
	player_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shadow_shader := Shader.new()
	shadow_shader.code = "
shader_type canvas_item;
void fragment() {
	vec2 c = UV - vec2(0.5);
	float d = length(c * vec2(1.0, 2.5));
	float a = (1.0 - smoothstep(0.0, 0.5, d)) * 0.35;
	COLOR = vec4(0.0, 0.0, 0.02, a);
}
"
	var shadow_mat := ShaderMaterial.new()
	shadow_mat.shader = shadow_shader
	player_shadow.material = shadow_mat
	play_zone.add_child(player_shadow)

	var enemy_shadow := ColorRect.new()
	enemy_shadow.size = Vector2(160, 20)
	enemy_shadow.position = Vector2(510, 314)
	enemy_shadow.color = Color(0, 0, 0, 0)
	enemy_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var eshadow_mat := ShaderMaterial.new()
	eshadow_mat.shader = shadow_shader
	enemy_shadow.material = eshadow_mat
	play_zone.add_child(enemy_shadow)

	# --- 地面分割线（战场底部平台边缘）---
	var ground_line := ColorRect.new()
	ground_line.size = Vector2(1280, 2)
	ground_line.position = Vector2(0, 385)
	ground_line.color = Color(0.12, 0.08, 0.22, 0.5)
	ground_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_zone.add_child(ground_line)
	var ground_glow := ColorRect.new()
	ground_glow.size = Vector2(1280, 8)
	ground_glow.position = Vector2(0, 385)
	ground_glow.color = Color(0.08, 0.05, 0.18, 0.2)
	ground_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_zone.add_child(ground_glow)

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

	# --- 手牌区域（扇形布局，覆盖下半屏幕） ---
	hand_node = Hand.new()
	hand_node.position = Vector2(0, 0)
	hand_node.size = Vector2(1280, 720)
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

	# 拖拽指向箭头 + 目标高亮（杀戮尖塔式）
	_update_drag_targeting()

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
	# 玩家呼吸缩放
	var breath_tw := create_tween().set_loops()
	breath_tw.tween_property(player_sprite, "scale", Vector2(1.02, 0.98), 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	breath_tw.tween_property(player_sprite, "scale", Vector2(0.98, 1.02), 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# 玩家idle帧循环（frame 0 ↔ frame 3 special pose）
	var player_frame_tw := create_tween().set_loops()
	player_frame_tw.tween_callback(func():
		if is_instance_valid(player_sprite):
			player_sprite.texture = _ai_sprite("player", 3)
	).set_delay(1.5)
	player_frame_tw.tween_callback(func():
		if is_instance_valid(player_sprite):
			player_sprite.texture = _ai_sprite("player", 0)
	).set_delay(1.5)

## 敌人待机浮动动画
func _start_enemy_idle_bob() -> void:
	if not enemy_sprite:
		return
	var bob_tw := create_tween().set_loops()
	var base_y: float = enemy_sprite.position.y
	bob_tw.tween_property(enemy_sprite, "position:y", base_y - 3.0, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	bob_tw.tween_property(enemy_sprite, "position:y", base_y + 3.0, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# 敌人呼吸缩放
	var breath_tw := create_tween().set_loops()
	breath_tw.tween_property(enemy_sprite, "scale", Vector2(1.01, 0.99), 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	breath_tw.tween_property(enemy_sprite, "scale", Vector2(0.99, 1.01), 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# 敌人idle帧循环（frame 0 ↔ frame 1 attack pose，营造威胁感）
	var enemy_frame_tw := create_tween().set_loops()
	enemy_frame_tw.tween_callback(func():
		if is_instance_valid(enemy_sprite):
			enemy_sprite.texture = _ai_sprite(enemy_type_key, 1)
	).set_delay(2.0)
	enemy_frame_tw.tween_callback(func():
		if is_instance_valid(enemy_sprite):
			enemy_sprite.texture = _ai_sprite(enemy_type_key, 0)
	).set_delay(0.4)

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
	_start_enemy_idle_bob()

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
		_update_energy_field_state(1)  # 共鸣态
		if resonance_turns >= 5:
			GameState.achievements["yinyang_master"] = true
	else:
		resonance_turns = 0
		_update_energy_field_state(0)  # 常态

	if bonus["is_backlash"]:
		_add_log("[color=purple]⚠ 心魔反噬！伤害-2，随机弃牌[/color]")
		AudioManager.play_sfx_generated("backlash")
		_trigger_glitch(0.4)
		_update_energy_field_state(2)  # 反噬态
		# 随机弃一张牌
		var discarded: Card = hand_node.discard_random()
		if discarded:
			deck.discard(discarded.card_data.resource_path if discarded.card_data else "")
			discarded.queue_free()

	# 回合开始墨迹扩散特效
	_play_turn_start_ink_burst()

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
	AudioManager.play_sfx_generated("turn_start")
	_show_turn_banner("玩 家 回 合", Color(0, 0.9, 1.0))
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

	# 检测鼠标下的目标（杀戮尖塔式拖拽指向）
	var target: String = _get_target_at_position(get_global_mouse_position())
	# DEFENSE/SPELL卡有召唤物时，如果没拖到具体目标，默认自身/敌人
	if target == "" or target == "none":
		if data.card_type == CardData.CardType.ATTACK:
			target = "enemy"
		else:
			target = "self"

	# 执行效果
	_execute_card_effect(card, data, actual_cost, target)

# ============================================================
# 杀戮尖塔式拖拽指向系统
# ============================================================

## 每帧更新: 检测是否有卡牌正在拖拽，显示箭头和高亮
func _update_drag_targeting() -> void:
	var dragging_card: Card = null
	if hand_node:
		for c in hand_node.cards:
			if c.is_dragging:
				dragging_card = c
				break

	if dragging_card and dragging_card.card_data:
		var mouse_pos: Vector2 = get_global_mouse_position()
		var card_center: Vector2 = dragging_card.global_position + dragging_card.size * 0.5
		# 显示箭头
		_show_drag_arrow(card_center, mouse_pos)
		# 检测并高亮目标
		var hover_target: String = _get_target_at_position(mouse_pos)
		if hover_target != _last_hover_target:
			_last_hover_target = hover_target
			_update_target_highlight(hover_target)
	else:
		_hide_drag_arrow()
		if _last_hover_target != "":
			_last_hover_target = ""
			_update_target_highlight("")

## 获取指定位置下的目标单位
func _get_target_at_position(pos: Vector2) -> String:
	# 检查敌人精灵
	if enemy_sprite and _is_pos_over_node(pos, enemy_sprite):
		return "enemy"
	# 检查玩家精灵
	if player_sprite and _is_pos_over_node(pos, player_sprite):
		return "self"
	# 检查召唤物精灵
	if play_zone:
		for i in range(player_summons.size()):
			var summon_node: Node = play_zone.get_node_or_null("summon_" + str(i))
			if summon_node and summon_node is Control:
				if _is_pos_over_node(pos, summon_node as Control):
					return "summon_" + str(i)
	return ""

## 判断位置是否在节点范围内（含扩展边距）
func _is_pos_over_node(pos: Vector2, node: Control) -> bool:
	var rect := Rect2(node.global_position, node.size * node.scale)
	# 扩大检测范围使更容易选中
	rect = rect.grow(12.0)
	return rect.has_point(pos)

## 显示拖拽箭头（贝塞尔曲线，流畅渐变）
func _show_drag_arrow(from: Vector2, to: Vector2) -> void:
	if not _drag_arrow:
		_drag_arrow = Line2D.new()
		_drag_arrow.width = 5.0
		_drag_arrow.default_color = Color(1, 0.85, 0.2, 0.9)
		_drag_arrow.z_index = 90
		_drag_arrow.begin_cap_mode = Line2D.LINE_CAP_ROUND
		_drag_arrow.end_cap_mode = Line2D.LINE_CAP_ROUND
		_drag_arrow.joint_mode = Line2D.LINE_JOINT_ROUND
		_drag_arrow.antialiased = true
		# 渐变宽度曲线：从细到粗
		var width_curve := Curve.new()
		width_curve.add_point(Vector2(0.0, 0.4))
		width_curve.add_point(Vector2(0.5, 0.7))
		width_curve.add_point(Vector2(1.0, 1.0))
		_drag_arrow.width_curve = width_curve
		# 渐变颜色
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 0.85, 0.2, 0.3))
		gradient.set_color(1, Color(1, 0.7, 0.1, 0.95))
		_drag_arrow.gradient = gradient
		add_child(_drag_arrow)
	if not _drag_arrow_head:
		_drag_arrow_head = Polygon2D.new()
		_drag_arrow_head.color = Color(1, 0.7, 0.1, 0.95)
		_drag_arrow_head.z_index = 91
		_drag_arrow_head.antialiased = true
		add_child(_drag_arrow_head)

	_drag_arrow.visible = true
	_drag_arrow_head.visible = true

	# 贝塞尔曲线：从卡牌到鼠标，中间控制点在上方
	var mid_y: float = minf(from.y, to.y) - 60.0
	var ctrl: Vector2 = Vector2((from.x + to.x) * 0.5, mid_y)
	_drag_arrow.clear_points()
	var segments: int = 24
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var p: Vector2 = from.lerp(ctrl, t).lerp(ctrl.lerp(to, t), t)
		_drag_arrow.add_point(p)

	# 箭头三角形（稍大一些更美观）
	var dir: Vector2 = (to - ctrl).normalized()
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	var tip: Vector2 = to
	var arrow_size: float = 14.0
	_drag_arrow_head.polygon = PackedVector2Array([
		tip,
		tip - dir * arrow_size + perp * arrow_size * 0.55,
		tip - dir * arrow_size - perp * arrow_size * 0.55
	])

## 隐藏拖拽箭头
func _hide_drag_arrow() -> void:
	if _drag_arrow:
		_drag_arrow.visible = false
	if _drag_arrow_head:
		_drag_arrow_head.visible = false

## 更新目标高亮（脉冲圆环 + 角色发光）
func _update_target_highlight(target: String) -> void:
	# 清除旧高亮
	if _highlight_rect:
		_highlight_rect.queue_free()
		_highlight_rect = null
	# 重置所有精灵调制
	if enemy_sprite:
		enemy_sprite.modulate = Color.WHITE
	if player_sprite:
		player_sprite.modulate = Color.WHITE
	if play_zone:
		for child in play_zone.get_children():
			if child is Control:
				child.modulate = Color.WHITE

	if target == "":
		return

	var target_node: Control = null
	var glow_color := Color(1, 1, 0.3)

	if target == "enemy" and enemy_sprite:
		target_node = enemy_sprite
		glow_color = Color(1.0, 0.3, 0.15)
	elif target == "self" and player_sprite:
		target_node = player_sprite
		glow_color = Color(0.2, 0.8, 1.0)
	elif target.begins_with("summon_") and play_zone:
		var idx_str: String = target.replace("summon_", "")
		var summon_node: Node = play_zone.get_node_or_null("summon_" + idx_str)
		if summon_node and summon_node is Control:
			target_node = summon_node as Control
			glow_color = Color(0.2, 1, 0.5)

	if target_node:
		_apply_target_ring(target_node, glow_color)

## 给目标节点应用圆环脉冲高亮（替代丑陋矩形）
func _apply_target_ring(node: Control, glow_color: Color) -> void:
	# 目标精灵脉冲发光（直接调制颜色，无矩形覆盖）
	var bright := Color(
		minf(glow_color.r * 0.3 + 1.0, 1.4),
		minf(glow_color.g * 0.3 + 1.0, 1.4),
		minf(glow_color.b * 0.3 + 1.0, 1.4)
	)
	node.modulate = bright

	# 脚底圆环指示器（椭圆脉冲环，不是矩形）
	_highlight_rect = ColorRect.new()
	_highlight_rect.color = Color(0, 0, 0, 0)
	_highlight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_highlight_rect.z_index = 45

	# 圆环位于角色脚底，宽椭圆形
	var ring_w: float = maxf(node.size.x * node.scale.x, 80.0) + 30.0
	var ring_h: float = 36.0
	var node_center_x: float = node.global_position.x + node.size.x * node.scale.x * 0.5
	var node_bottom_y: float = node.global_position.y + node.size.y * node.scale.y
	_highlight_rect.global_position = Vector2(node_center_x - ring_w * 0.5, node_bottom_y - ring_h * 0.5 + 4.0)
	_highlight_rect.size = Vector2(ring_w, ring_h)

	var shader := Shader.new()
	shader.code = "
shader_type canvas_item;
uniform vec4 ring_color : source_color = vec4(1.0, 0.3, 0.2, 1.0);
void fragment() {
	vec2 c = UV - vec2(0.5);
	// 椭圆距离（水平宽，垂直窄）
	float d = length(c * vec2(1.0, 2.2));
	// 双层环
	float ring1 = smoothstep(0.42, 0.38, d) * smoothstep(0.30, 0.34, d);
	float ring2 = smoothstep(0.48, 0.44, d) * smoothstep(0.36, 0.40, d);
	// 脉冲
	float pulse = 0.6 + 0.4 * sin(TIME * 4.0);
	float pulse2 = 0.7 + 0.3 * sin(TIME * 4.0 + 1.5);
	// 内部淡光填充
	float fill = (1.0 - smoothstep(0.0, 0.4, d)) * 0.08 * pulse;
	float a = ring1 * 0.9 * pulse + ring2 * 0.4 * pulse2 + fill;
	COLOR = vec4(ring_color.rgb, a * ring_color.a);
}
"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("ring_color", Color(glow_color.r, glow_color.g, glow_color.b, 1.0))
	_highlight_rect.material = mat

	add_child(_highlight_rect)

	# 目标节点脉冲缩放动画
	if node.is_inside_tree():
		var tween: Tween = node.create_tween().set_loops()
		tween.tween_property(node, "modulate", bright, 0.3)
		tween.tween_property(node, "modulate", Color(1.05, 1.05, 1.05), 0.3)

## 执行卡牌效果（target: "enemy", "self", "summon_0", "summon_1" 等）
func _execute_card_effect(card: Card, data: CardData, actual_cost: int, target: String) -> void:
	AudioManager.play_sfx_generated("card_play")
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
			_flash_enemy_hit(total_damage)
			_play_player_attack_anim()
			AudioManager.play_sfx_generated("attack", randf_range(-5.0, -1.0))
			AudioManager.play_sfx_generated("enemy_hurt", randf_range(-6.0, -2.0))

	if result.shield_gained > 0:
		if target.begins_with("summon_"):
			var sidx: int = target.replace("summon_", "").to_int()
			if sidx >= 0 and sidx < player_summons.size():
				player_summons[sidx]["shield"] = player_summons[sidx].get("shield", 0) + result.shield_gained
				_add_log("[color=blue]  → " + player_summons[sidx]["name"] + " 获得 " + str(result.shield_gained) + " 护盾[/color]")
			else:
				player_shield += result.shield_gained
				if player_sprite:
					_spawn_damage_popup(result.shield_gained, player_sprite, "shield")
				_add_log("[color=blue]  → 获得 " + str(result.shield_gained) + " 护盾[/color]")
		else:
			player_shield += result.shield_gained
			if player_sprite:
				_spawn_damage_popup(result.shield_gained, player_sprite, "shield")
			_add_log("[color=blue]  → 获得 " + str(result.shield_gained) + " 护盾[/color]")
		AudioManager.play_sfx_generated("defense", randf_range(-5.0, -1.0))

	if result.healing_done > 0:
		if target.begins_with("summon_"):
			var sidx: int = target.replace("summon_", "").to_int()
			if sidx >= 0 and sidx < player_summons.size():
				var s: Dictionary = player_summons[sidx]
				s["hp"] = mini(s.get("max_hp", s["hp"]), s["hp"] + result.healing_done)
				_add_log("[color=green]  → " + s["name"] + " 恢复 " + str(result.healing_done) + " 生命[/color]")
			else:
				player_hp = min(player_max_hp, player_hp + result.healing_done)
				if player_sprite:
					_spawn_damage_popup(result.healing_done, player_sprite, "heal")
				_add_log("[color=green]  → 恢复 " + str(result.healing_done) + " 生命[/color]")
		else:
			player_hp = min(player_max_hp, player_hp + result.healing_done)
			if player_sprite:
				_spawn_damage_popup(result.healing_done, player_sprite, "heal")
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
	AudioManager.play_sfx_generated("end_turn")
	end_turn_btn.disabled = true
	_start_enemy_turn()

## 敌人回合
func _start_enemy_turn() -> void:
	state = BattleState.ENEMY_TURN
	_show_turn_banner("敌 方 回 合", Color(1.0, 0.3, 0.2))
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
					_flash_player_hit(actual_dmg)
					_play_player_hurt_anim()
					AudioManager.play_sfx_generated("player_hurt")
					_screen_shake(maxf(float(actual_dmg) * 1.5, 5.0), 0.25)
			else:
				var per_hit: int = total_enemy_dmg
				for _i in range(enemy_hits):
					var actual_dmg: int = _apply_damage_to_player(per_hit)
					if actual_dmg > 0:
						_flash_player_hit(actual_dmg)
						_play_player_hurt_anim()
						AudioManager.play_sfx_generated("player_hurt", -5.0)
				_screen_shake(maxf(float(total_enemy_dmg) * 1.0, 4.0), 0.3)
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
	# 死亡消散特效（在召唤物位置播放碎片散射）
	_play_summon_death_vfx(summon)
	if summon.get("passive", "") == "draw_1_on_death":
		var drawn: Array[String] = deck.draw_cards(1)
		for p in drawn:
			_add_card_to_hand(p)
		_add_log("[color=cyan]  " + summon["name"] + "死亡触发：抽1张牌[/color]")

## 召唤物死亡消散特效
func _play_summon_death_vfx(summon: Dictionary) -> void:
	# 找到对应的战场节点位置
	var summon_idx: int = player_summons.find(summon)
	if summon_idx < 0:
		return
	var summon_node: Node = play_zone.get_node_or_null("summon_" + str(summon_idx))
	if not summon_node or not summon_node is Control:
		return
	var center: Vector2 = (summon_node as Control).position + Vector2(36, 48)
	# 像素碎片散射 + 淡出
	for i in range(14):
		var frag := ColorRect.new()
		var fsize: float = randf_range(3.0, 8.0)
		frag.size = Vector2(fsize, fsize)
		frag.position = play_zone.position + center + Vector2(randf_range(-15, 15), randf_range(-20, 20))
		# 根据召唤物类型选色
		var color_mode: int = _get_summon_aura_color_mode(summon.get("card_id", ""))
		match color_mode:
			0: frag.color = Color(0.2, 1.0, 0.1, 0.9)
			1: frag.color = Color(1.0, 0.5, 0.0, 0.9)
			2: frag.color = Color(0.5, 0.1, 0.8, 0.9)
			3: frag.color = Color(0.0, 0.9, 1.0, 0.9)
			4: frag.color = Color(0.9, 0.88, 0.8, 0.9)
			_: frag.color = Color(1.0, 0.84, 0.2, 0.9)
		frag.rotation = randf_range(0, TAU)
		frag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frag.z_index = 55
		add_child(frag)
		var scatter_dir: float = randf_range(0, TAU)
		var scatter_dist: float = randf_range(40.0, 100.0)
		var target_pos: Vector2 = frag.position + Vector2(cos(scatter_dir), sin(scatter_dir)) * scatter_dist
		var ftw := frag.create_tween().set_parallel(true)
		ftw.tween_property(frag, "position", target_pos, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		ftw.tween_property(frag, "color:a", 0.0, 0.3).set_delay(0.25)
		ftw.tween_property(frag, "rotation", frag.rotation + randf_range(-4.0, 4.0), 0.5)
		ftw.chain().tween_callback(frag.queue_free)
	AudioManager.play_sfx_generated("glitch", -8.0)

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

	# 地面线 y 坐标（sprite底部对齐）— 增大召唤物尺寸
	var ground_y: int = 320
	var sprite_h: int = 160
	var sprite_w: int = 120

	# 后排：靠近玩家（x: 170起，间距加大）
	for i in range(back_list.size()):
		var s: Dictionary = back_list[i]
		var sx: int = 170 + i * 130
		var sy: int = ground_y - sprite_h
		_create_summon_battlefield_node(s, sx, sy, sprite_w, sprite_h, back_indices[i], false)

	# 前排：玩家和敌人之间（x: 300起，间距加大）
	for i in range(front_list.size()):
		var s: Dictionary = front_list[i]
		var sx: int = 300 + i * 130
		var sy: int = ground_y - sprite_h
		_create_summon_battlefield_node(s, sx, sy, sprite_w, sprite_h, front_indices[i], true)

## 创建单个召唤物战场节点（v6：光环shader + idle呼吸 + 符文装饰）
func _create_summon_battlefield_node(s: Dictionary, sx: int, sy: int, sw: int, sh: int, idx: int, is_front: bool) -> void:
	var container := Control.new()
	container.name = "summon_" + str(idx)
	container.position = Vector2(sx, sy)
	container.size = Vector2(sw, sh + 30)
	container.mouse_filter = Control.MOUSE_FILTER_PASS
	container.set_meta("_summon_node", true)
	container.pivot_offset = Vector2(sw / 2.0, sh / 2.0)

	# --- 光环 Shader 层（底层，精灵下方）---
	var aura_rect := ColorRect.new()
	var aura_pad: int = 16
	aura_rect.size = Vector2(sw + aura_pad * 2, sh + aura_pad * 2)
	aura_rect.position = Vector2(-aura_pad, -aura_pad)
	aura_rect.color = Color(1, 1, 1, 0.7)
	aura_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var aura_shader := load("res://Shaders/summon_aura.gdshader") as Shader
	if aura_shader:
		var aura_mat := ShaderMaterial.new()
		aura_mat.shader = aura_shader
		aura_mat.set_shader_parameter("color_mode", _get_summon_aura_color_mode(s.get("card_id", "")))
		aura_mat.set_shader_parameter("pulse_speed", 2.0)
		aura_mat.set_shader_parameter("glow_intensity", 0.8)
		aura_mat.set_shader_parameter("rune_visibility", 0.35)
		aura_rect.material = aura_mat
	container.add_child(aura_rect)

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

	# --- Idle 呼吸动画（轻微上下浮动 + 缩放脉冲）---
	var bob_tw := container.create_tween().set_loops()
	bob_tw.tween_property(container, "position:y", float(sy) - 3.0, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	bob_tw.tween_property(container, "position:y", float(sy) + 1.0, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# 轻微缩放呼吸
	var scale_tw := container.create_tween().set_loops()
	scale_tw.tween_property(container, "scale", Vector2(1.02, 0.98), 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	scale_tw.tween_property(container, "scale", Vector2(0.98, 1.02), 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# 精灵帧动画（交替 frame 0 和 frame 1）
	var frame_tw := sprite.create_tween().set_loops()
	var summon_type_captured := summon_type
	frame_tw.tween_callback(func():
		if is_instance_valid(sprite):
			sprite.texture = _ai_sprite(summon_type_captured, 1)
	).set_delay(0.6)
	frame_tw.tween_callback(func():
		if is_instance_valid(sprite):
			sprite.texture = _ai_sprite(summon_type_captured, 0)
	).set_delay(0.6)

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

	# HP条背景（道教风格：暗色+微弱边框）
	var hp_bg := ColorRect.new()
	hp_bg.position = Vector2(2, sh + 2)
	hp_bg.size = Vector2(sw - 4, 7)
	hp_bg.color = Color(0.12, 0.06, 0.08, 0.9)
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(hp_bg)
	# HP条边框
	var hp_border := ColorRect.new()
	hp_border.position = Vector2(1, sh + 1)
	hp_border.size = Vector2(sw - 2, 9)
	hp_border.color = Color(0.4, 0.2, 0.1, 0.5)
	hp_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_border.z_index = -1
	container.add_child(hp_border)

	# HP条填充
	var hp_fill := ColorRect.new()
	var hp_ratio: float = float(s["hp"]) / float(maxi(s["max_hp"], 1))
	hp_fill.position = Vector2(2, sh + 2)
	hp_fill.size = Vector2(int((sw - 4) * hp_ratio), 7)
	hp_fill.color = Color(0.2, 0.85, 0.3) if hp_ratio > 0.5 else Color(0.9, 0.4, 0.1)
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(hp_fill)

	# 名字 + 位置标签
	var name_lbl := Label.new()
	var pos_tag := "☰" if is_front else "☷"
	name_lbl.text = pos_tag + s["name"]
	name_lbl.position = Vector2(-2, sh + 10)
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

	# --- 入场动画（从下方弹入 + 淡入）---
	container.modulate.a = 0.0
	container.position.y += 30.0
	var enter_tw := container.create_tween().set_parallel(true)
	enter_tw.tween_property(container, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	enter_tw.tween_property(container, "position:y", float(sy), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

## 获取召唤物光环颜色模式（对应 summon_aura.gdshader 的 color_mode）
func _get_summon_aura_color_mode(card_id: String) -> int:
	match card_id:
		"sum_pixel_sprite": return 0  # 霓虹绿
		"sum_cyber_fox", "sum_beast": return 1  # EVA橙
		"sum_spirit_dragon", "sum_shadow_clone": return 2  # 电紫
		"sum_neon_golem", "sum_byte_familiar": return 3  # 赛博青
		"sum_dao_crane": return 4  # 符纸白
		"sum_swarm": return 5  # 金
		_: return 0

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

	# Defeat transition (红色覆盖 + 文字)
	await _play_defeat_transition()

	await get_tree().create_timer(1.0).timeout
	# Direct scene change - bypass Global.change_scene to avoid transition lock
	Global.is_transitioning = false
	get_tree().change_scene_to_file(Global.SCENE_DEFEAT)

## 战败过渡动画（红色覆盖 + "战败" 文字淡入）
func _play_defeat_transition() -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	overlay.color = Color(0.4, 0.02, 0.02, 0)
	overlay.z_index = 100
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var def_label := Label.new()
	def_label.text = "意 识 崩 溃"
	def_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	def_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	def_label.set_anchors_preset(PRESET_FULL_RECT)
	def_label.add_theme_font_size_override("font_size", 52)
	def_label.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))
	def_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	def_label.add_theme_constant_override("shadow_offset_x", 3)
	def_label.add_theme_constant_override("shadow_offset_y", 3)
	def_label.modulate.a = 0.0
	def_label.z_index = 101
	add_child(def_label)

	_screen_shake(12.0, 0.5)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(overlay, "color:a", 0.65, 0.8)
	tw.tween_property(def_label, "modulate:a", 1.0, 0.5).set_delay(0.3)
	await tw.finished
	await get_tree().create_timer(0.5).timeout

# ============================================================
# 卡牌类型视觉效果
# ============================================================
## Diagonal slash lines streaking from player toward enemy
func _play_attack_card_vfx() -> void:
	if not player_sprite or not enemy_sprite:
		return
	var start_pos: Vector2 = play_zone.position + player_sprite.position + player_sprite.size / 2.0
	var end_pos: Vector2 = play_zone.position + enemy_sprite.position + enemy_sprite.size / 2.0
	var dir: Vector2 = (end_pos - start_pos).normalized()
	var perp: Vector2 = Vector2(-dir.y, dir.x)

	# --- Phase 1: 5 staggered arc-slash projectiles ---
	var slash_colors: Array[Color] = [
		Color(1.0, 0.15, 0.05, 0.95),
		Color(1.0, 0.4, 0.08, 0.9),
		Color(1.0, 0.6, 0.15, 0.85),
		Color(1.0, 0.3, 0.05, 0.88),
		Color(0.95, 0.15, 0.0, 0.8),
	]
	for i in range(5):
		var slash := ColorRect.new()
		slash.size = Vector2(60 + i * 8, 3)
		slash.pivot_offset = slash.size / 2.0
		var arc_offset: float = (-2.0 + float(i)) * 12.0
		slash.position = start_pos + perp * arc_offset
		slash.rotation = dir.angle() + deg_to_rad(-15.0 + float(i) * 7.5)
		slash.color = slash_colors[i]
		slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slash.z_index = 52
		add_child(slash)
		var target_pos: Vector2 = end_pos + perp * arc_offset * 0.3
		var delay: float = float(i) * 0.04
		var tw := slash.create_tween()
		tw.set_parallel(true)
		tw.tween_property(slash, "position", target_pos, 0.18).set_delay(delay).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(slash, "scale:x", 1.6, 0.18).set_delay(delay)
		tw.tween_property(slash, "color:a", 0.0, 0.08).set_delay(delay + 0.14)
		tw.chain().tween_callback(slash.queue_free)

	# --- Phase 2: Impact flash at enemy (white → transparent, 0.12s) ---
	var flash := ColorRect.new()
	flash.size = Vector2(100, 100)
	flash.pivot_offset = Vector2(50, 50)
	flash.position = end_pos - Vector2(50, 50)
	flash.color = Color(1.0, 0.95, 0.85, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 55
	add_child(flash)
	var flash_tw := flash.create_tween()
	flash_tw.tween_property(flash, "color:a", 0.85, 0.05).set_delay(0.2)
	flash_tw.tween_property(flash, "scale", Vector2(1.8, 1.8), 0.1)
	flash_tw.parallel().tween_property(flash, "color:a", 0.0, 0.1)
	flash_tw.tween_callback(flash.queue_free)

	# --- Phase 3: Impact debris particles scatter from enemy ---
	for j in range(10):
		var debris := ColorRect.new()
		var dsize: float = randf_range(3.0, 7.0)
		debris.size = Vector2(dsize, dsize)
		debris.pivot_offset = debris.size / 2.0
		debris.position = end_pos + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		debris.color = Color(1.0, randf_range(0.3, 0.7), 0.1, 0.9)
		debris.rotation = randf_range(0.0, TAU)
		debris.mouse_filter = Control.MOUSE_FILTER_IGNORE
		debris.z_index = 53
		add_child(debris)
		var scatter_angle: float = randf_range(0.0, TAU)
		var scatter_dist: float = randf_range(30.0, 80.0)
		var scatter_target: Vector2 = debris.position + Vector2(cos(scatter_angle), sin(scatter_angle)) * scatter_dist
		var dtw := debris.create_tween().set_parallel(true)
		dtw.tween_property(debris, "position", scatter_target, 0.35).set_delay(0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		dtw.tween_property(debris, "color:a", 0.0, 0.2).set_delay(0.35)
		dtw.tween_property(debris, "rotation", debris.rotation + randf_range(-3.0, 3.0), 0.4).set_delay(0.22)
		dtw.chain().tween_callback(debris.queue_free)

## Shield hex-ring + energy converge + pulse overlay around the player sprite
func _play_defense_card_vfx() -> void:
	if not player_sprite:
		return
	var center: Vector2 = play_zone.position + player_sprite.position + player_sprite.size / 2.0

	# --- Phase 1: Hex-ring (6 elongated segments forming hexagonal shield) ---
	var hex_count: int = 6
	var ring_radius: float = 45.0
	for i in range(hex_count):
		var angle: float = float(i) * TAU / float(hex_count) - PI / 6.0
		var next_angle: float = float(i + 1) * TAU / float(hex_count) - PI / 6.0
		var mid_angle: float = (angle + next_angle) / 2.0
		var seg := ColorRect.new()
		seg.size = Vector2(28, 4)
		seg.pivot_offset = seg.size / 2.0
		seg.position = center + Vector2(cos(mid_angle), sin(mid_angle)) * ring_radius - seg.size / 2.0
		seg.rotation = mid_angle + PI / 2.0
		seg.color = Color(0.2, 0.55, 1.0, 0.0)
		seg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seg.z_index = 52
		add_child(seg)
		var delay: float = float(i) * 0.04
		var stw := seg.create_tween()
		# Fade in with slight scale-up
		stw.tween_property(seg, "color:a", 0.9, 0.1).set_delay(delay)
		stw.tween_property(seg, "color", Color(0.4, 0.75, 1.0, 0.7), 0.15)
		stw.tween_property(seg, "color:a", 0.0, 0.25)
		stw.tween_callback(seg.queue_free)

	# --- Phase 2: Energy lines converging from 8 directions ---
	for j in range(8):
		var line_angle: float = float(j) * TAU / 8.0
		var line := ColorRect.new()
		line.size = Vector2(40, 2)
		line.pivot_offset = Vector2(0, 1)
		var spawn_dist: float = 90.0
		line.position = center + Vector2(cos(line_angle), sin(line_angle)) * spawn_dist
		line.rotation = line_angle + PI
		line.color = Color(0.3, 0.65, 1.0, 0.7)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.z_index = 51
		add_child(line)
		var converge_target: Vector2 = center + Vector2(cos(line_angle), sin(line_angle)) * 15.0
		var ltw := line.create_tween().set_parallel(true)
		ltw.tween_property(line, "position", converge_target, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		ltw.tween_property(line, "size:x", 12.0, 0.25)
		ltw.tween_property(line, "color:a", 0.0, 0.12).set_delay(0.2)
		ltw.chain().tween_callback(line.queue_free)

	# --- Phase 3: Shield pulse overlay (expanding circle that fades) ---
	var pulse := ColorRect.new()
	pulse.size = Vector2(20, 20)
	pulse.pivot_offset = Vector2(10, 10)
	pulse.position = center - Vector2(10, 10)
	pulse.color = Color(0.3, 0.6, 1.0, 0.0)
	pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pulse.z_index = 50
	# Shield pulse shader (soft circular glow)
	var shield_shader := Shader.new()
	shield_shader.code = "
shader_type canvas_item;
void fragment() {
	vec2 c = UV - vec2(0.5);
	float d = length(c);
	float ring = smoothstep(0.35, 0.4, d) * (1.0 - smoothstep(0.45, 0.5, d));
	float fill = (1.0 - smoothstep(0.0, 0.5, d)) * 0.25;
	float a = (ring * 0.8 + fill) * COLOR.a;
	COLOR = vec4(COLOR.rgb, a);
}
"
	var shield_mat := ShaderMaterial.new()
	shield_mat.shader = shield_shader
	pulse.material = shield_mat
	add_child(pulse)
	var ptw := pulse.create_tween()
	ptw.tween_property(pulse, "color:a", 0.7, 0.15).set_delay(0.15)
	ptw.tween_property(pulse, "scale", Vector2(8.0, 8.0), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	ptw.parallel().tween_property(pulse, "position", center - Vector2(10, 10) * 8.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	ptw.parallel().tween_property(pulse, "color:a", 0.0, 0.2).set_delay(0.15)
	ptw.tween_callback(pulse.queue_free)

## Rift-tear summon effect: rune ring + vertical crack splits open with green energy pouring out
func _play_summon_card_vfx() -> void:
	var pillar_x: float = play_zone.position.x + 340.0
	var pillar_y: float = play_zone.position.y + 110.0
	var rift_center: Vector2 = Vector2(pillar_x + 20.0, pillar_y + 140.0)

	# --- Phase 0: Dao rune ring (8 rune dots spinning then fading) ---
	var rune_container := Control.new()
	rune_container.position = rift_center
	rune_container.pivot_offset = Vector2.ZERO
	rune_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rune_container.z_index = 52
	add_child(rune_container)
	var rune_chars: Array[String] = ["☰", "☱", "☲", "☳", "☴", "☵", "☶", "☷"]
	for i in range(8):
		var angle: float = float(i) * TAU / 8.0
		var rune_lbl := Label.new()
		rune_lbl.text = rune_chars[i]
		rune_lbl.add_theme_font_size_override("font_size", 14)
		rune_lbl.add_theme_color_override("font_color", Color(0.1, 1.0, 0.4, 0.0))
		rune_lbl.position = Vector2(cos(angle) * 55.0 - 7.0, sin(angle) * 55.0 - 9.0)
		rune_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rune_container.add_child(rune_lbl)
		# Staggered fade in
		var rtw := rune_lbl.create_tween()
		rtw.tween_property(rune_lbl, "theme_override_colors/font_color:a", 0.9, 0.08).set_delay(float(i) * 0.03)
	# Spin the rune ring
	var rune_tw := rune_container.create_tween()
	rune_tw.tween_property(rune_container, "rotation", TAU * 0.5, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	rune_tw.tween_property(rune_container, "modulate:a", 0.0, 0.2)
	rune_tw.tween_callback(rune_container.queue_free)

	# --- Phase 1: Dark rift line splits open vertically ---
	var rift_left := ColorRect.new()
	rift_left.size = Vector2(3, 120)
	rift_left.pivot_offset = Vector2(3, 60)
	rift_left.position = rift_center - Vector2(1.5, 60)
	rift_left.color = Color(0.0, 0.0, 0.0, 0.95)
	rift_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rift_left.z_index = 54
	add_child(rift_left)
	var rift_right := ColorRect.new()
	rift_right.size = Vector2(3, 120)
	rift_right.pivot_offset = Vector2(0, 60)
	rift_right.position = rift_center - Vector2(1.5, 60)
	rift_right.color = Color(0.0, 0.0, 0.0, 0.95)
	rift_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rift_right.z_index = 54
	add_child(rift_right)

	# Split apart
	var split_tw_l := rift_left.create_tween()
	split_tw_l.tween_property(rift_left, "position:x", rift_center.x - 22.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	split_tw_l.tween_property(rift_left, "color:a", 0.0, 0.4)
	split_tw_l.tween_callback(rift_left.queue_free)
	var split_tw_r := rift_right.create_tween()
	split_tw_r.tween_property(rift_right, "position:x", rift_center.x + 19.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	split_tw_r.tween_property(rift_right, "color:a", 0.0, 0.4)
	split_tw_r.tween_callback(rift_right.queue_free)

	# --- Phase 2: Green energy glow between rift halves ---
	var glow := ColorRect.new()
	glow.size = Vector2(6, 120)
	glow.position = rift_center - Vector2(3, 60)
	glow.color = Color(0.1, 1.0, 0.4, 0.0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.z_index = 53
	add_child(glow)
	var glow_tw := glow.create_tween()
	glow_tw.tween_property(glow, "color:a", 0.9, 0.12).set_delay(0.08)
	glow_tw.parallel().tween_property(glow, "size:x", 36.0, 0.25)
	glow_tw.parallel().tween_property(glow, "position:x", rift_center.x - 18.0, 0.25)
	glow_tw.tween_property(glow, "color:a", 0.0, 0.3)
	glow_tw.tween_callback(glow.queue_free)

	# --- Phase 3: Particles erupting from rift ---
	for i in range(12):
		var particle := ColorRect.new()
		var psize: float = randf_range(3.0, 6.0)
		particle.size = Vector2(psize, psize)
		particle.position = rift_center + Vector2(randf_range(-4, 4), randf_range(-50, 50))
		var green_var: float = randf_range(0.6, 1.0)
		particle.color = Color(0.1, green_var, randf_range(0.2, 0.5), 0.9)
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particle.z_index = 55
		add_child(particle)
		var scatter_x: float = randf_range(-60.0, 60.0)
		var scatter_y: float = randf_range(-70.0, -20.0)
		var pdelay: float = randf_range(0.1, 0.25)
		var ptw := particle.create_tween().set_parallel(true)
		ptw.tween_property(particle, "position", particle.position + Vector2(scatter_x, scatter_y), 0.4).set_delay(pdelay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		ptw.tween_property(particle, "color:a", 0.0, 0.25).set_delay(pdelay + 0.2)
		ptw.chain().tween_callback(particle.queue_free)

	# --- Phase 4: Brief white flash at rift center ---
	var flash := ColorRect.new()
	flash.size = Vector2(60, 60)
	flash.pivot_offset = Vector2(30, 30)
	flash.position = rift_center - Vector2(30, 30)
	flash.color = Color(0.8, 1.0, 0.9, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 56
	add_child(flash)
	var ftw := flash.create_tween()
	ftw.tween_property(flash, "color:a", 0.75, 0.06).set_delay(0.18)
	ftw.tween_property(flash, "scale", Vector2(2.0, 2.0), 0.12)
	ftw.parallel().tween_property(flash, "position", rift_center - Vector2(60, 60), 0.12)
	ftw.parallel().tween_property(flash, "color:a", 0.0, 0.12)
	ftw.tween_callback(flash.queue_free)

## Dual magic circle + rune dots + energy burst at screen center
func _play_spell_card_vfx() -> void:
	var center := Vector2(640, 210)

	# --- Phase 1: Outer ring (16 dots, clockwise) ---
	var outer_container := Control.new()
	outer_container.position = center
	outer_container.pivot_offset = Vector2.ZERO
	outer_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer_container.z_index = 50
	add_child(outer_container)
	for i in range(16):
		var angle: float = float(i) * TAU / 16.0
		var dot := ColorRect.new()
		var dot_size: float = 5.0 if i % 2 == 0 else 3.0
		dot.size = Vector2(dot_size, dot_size)
		dot.position = Vector2(cos(angle) * 70.0 - dot_size / 2.0, sin(angle) * 70.0 - dot_size / 2.0)
		dot.color = Color(0.6, 0.15, 0.9, 0.0) if i % 2 == 0 else Color(0.9, 0.75, 0.2, 0.0)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		outer_container.add_child(dot)
		# Staggered fade in
		var dtw := dot.create_tween()
		dtw.tween_property(dot, "color:a", 1.0, 0.08).set_delay(float(i) * 0.02)

	# --- Phase 2: Inner ring (8 dots, counter-clockwise) ---
	var inner_container := Control.new()
	inner_container.position = center
	inner_container.pivot_offset = Vector2.ZERO
	inner_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_container.z_index = 51
	add_child(inner_container)
	for i in range(8):
		var angle: float = float(i) * TAU / 8.0
		var dot := ColorRect.new()
		dot.size = Vector2(7, 7)
		dot.position = Vector2(cos(angle) * 35.0 - 3.5, sin(angle) * 35.0 - 3.5)
		dot.color = Color(0.85, 0.6, 1.0, 0.0)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner_container.add_child(dot)
		var dtw := dot.create_tween()
		dtw.tween_property(dot, "color:a", 0.9, 0.1).set_delay(0.1 + float(i) * 0.015)

	# --- Phase 3: Rotate both rings (opposite directions) ---
	var outer_tw := outer_container.create_tween()
	outer_tw.tween_property(outer_container, "rotation", TAU * 0.6, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	outer_tw.tween_property(outer_container, "modulate:a", 0.0, 0.15)
	outer_tw.tween_callback(outer_container.queue_free)

	var inner_tw := inner_container.create_tween()
	inner_tw.tween_property(inner_container, "rotation", -TAU * 0.4, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	inner_tw.tween_property(inner_container, "modulate:a", 0.0, 0.15)
	inner_tw.tween_callback(inner_container.queue_free)

	# --- Phase 4: Center energy gather + burst ---
	var core := ColorRect.new()
	core.size = Vector2(12, 12)
	core.pivot_offset = Vector2(6, 6)
	core.position = center - Vector2(6, 6)
	core.color = Color(0.9, 0.7, 1.0, 0.0)
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	core.z_index = 53
	add_child(core)
	var core_tw := core.create_tween()
	core_tw.tween_property(core, "color:a", 0.9, 0.2).set_delay(0.15)
	core_tw.tween_property(core, "scale", Vector2(5.0, 5.0), 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	core_tw.parallel().tween_property(core, "position", center - Vector2(30, 30), 0.12)
	core_tw.tween_property(core, "color:a", 0.0, 0.15)
	core_tw.tween_callback(core.queue_free)

	# --- Phase 5: Burst particles outward from center ---
	for k in range(8):
		var spark := ColorRect.new()
		spark.size = Vector2(4, 4)
		spark.position = center - Vector2(2, 2)
		spark.color = Color(0.8, 0.5, 1.0, 0.85)
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spark.z_index = 52
		add_child(spark)
		var burst_angle: float = float(k) * TAU / 8.0 + randf_range(-0.2, 0.2)
		var burst_dist: float = randf_range(50.0, 90.0)
		var burst_target: Vector2 = center + Vector2(cos(burst_angle), sin(burst_angle)) * burst_dist
		var stw := spark.create_tween().set_parallel(true)
		stw.tween_property(spark, "position", burst_target, 0.25).set_delay(0.38).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		stw.tween_property(spark, "color:a", 0.0, 0.15).set_delay(0.5)
		stw.chain().tween_callback(spark.queue_free)

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
func _flash_enemy_hit(damage_amount: int = 0) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(enemy_hp_bar, "modulate", Color(1, 0, 0), 0.1)
	tween.tween_property(enemy_hp_bar, "modulate", Color.WHITE, 0.2)
	# 飘字伤害数字
	if damage_amount > 0 and enemy_sprite:
		var popup_type: String = "crit" if damage_amount >= 15 else "damage"
		_spawn_damage_popup(damage_amount, enemy_sprite, popup_type)
	# 屏幕震动（伤害越高震动越强）
	var shake_intensity: float = clampf(float(damage_amount) * 0.5, 3.0, 12.0)
	screen_shake(0.15, shake_intensity)
	# Shake enemy sprite and briefly change frame
	if enemy_sprite:
		var orig_pos := enemy_sprite.position
		var shake_amp: float = 16.0 if enemy_type_key == "boss" else 8.0
		var shake_amp_half: float = shake_amp / 2.0
		enemy_sprite.texture = _ai_sprite(enemy_type_key, 2)
		# 红色闪烁
		var shake_tw := enemy_sprite.create_tween()
		shake_tw.tween_property(enemy_sprite, "modulate", Color(1.5, 0.3, 0.3), 0.05)
		shake_tw.tween_property(enemy_sprite, "position:x", orig_pos.x - shake_amp, 0.04)
		shake_tw.tween_property(enemy_sprite, "position:x", orig_pos.x + shake_amp, 0.04)
		shake_tw.tween_property(enemy_sprite, "position:x", orig_pos.x - shake_amp_half, 0.04)
		shake_tw.tween_property(enemy_sprite, "position:x", orig_pos.x, 0.04)
		shake_tw.tween_property(enemy_sprite, "modulate", Color.WHITE, 0.12)
		shake_tw.tween_callback(func():
			if is_instance_valid(enemy_sprite):
				enemy_sprite.texture = _ai_sprite(enemy_type_key, 0)
		)
		if enemy_type_key == "boss":
			AudioManager.play_sfx_generated("boss_hurt")

func _flash_player_hit(damage_amount: int = 0) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(hp_bar, "modulate", Color(1, 0, 0), 0.1)
	tween.tween_property(hp_bar, "modulate", Color.WHITE, 0.2)
	# 飘字伤害数字
	if damage_amount > 0 and player_sprite:
		_spawn_damage_popup(damage_amount, player_sprite, "damage")
	# Shake player sprite and briefly flash red
	if player_sprite:
		var orig_pos := player_sprite.position
		var shake_tw := player_sprite.create_tween()
		shake_tw.tween_property(player_sprite, "modulate", Color(1.5, 0.2, 0.2), 0.06)
		shake_tw.tween_property(player_sprite, "position:x", orig_pos.x - 8.0, 0.03)
		shake_tw.tween_property(player_sprite, "position:x", orig_pos.x + 8.0, 0.03)
		shake_tw.tween_property(player_sprite, "position:x", orig_pos.x, 0.04)
		shake_tw.tween_property(player_sprite, "modulate", Color.WHITE, 0.15)

func _trigger_glitch(intensity: float) -> void:
	# Set glitch shader intensity if available
	if glitch_rect and glitch_rect.material is ShaderMaterial:
		var mat := glitch_rect.material as ShaderMaterial
		mat.set_shader_parameter("glitch_intensity", intensity)
		# Fade out the glitch intensity over time
		var fade_tw := create_tween()
		var rect_ref: ColorRect = glitch_rect
		fade_tw.tween_method(func(val: float):
			if is_instance_valid(rect_ref) and rect_ref.material is ShaderMaterial:
				(rect_ref.material as ShaderMaterial).set_shader_parameter("glitch_intensity", val)
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

## 屏幕震动效果
func screen_shake(duration: float = 0.3, intensity: float = 6.0) -> void:
	var orig_pos := position
	var elapsed: float = 0.0
	while elapsed < duration:
		var decay: float = 1.0 - (elapsed / duration)
		position = orig_pos + Vector2(
			randf_range(-intensity, intensity) * decay,
			randf_range(-intensity, intensity) * decay
		)
		await get_tree().create_timer(0.03).timeout
		elapsed += 0.03
	position = orig_pos

## 生成飘字伤害/治疗/护盾数字（在目标精灵位置上方弹出）
func _spawn_damage_popup(value: int, target_node: Control, popup_type: String = "damage") -> void:
	if not target_node or not is_instance_valid(target_node):
		return
	var lbl := Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 100

	match popup_type:
		"damage":
			lbl.text = "-" + str(value)
			lbl.add_theme_font_size_override("font_size", 28)
			lbl.add_theme_color_override("font_color", Color(1, 0.25, 0.15))
			lbl.add_theme_color_override("font_outline_color", Color(0.2, 0, 0))
			lbl.add_theme_constant_override("outline_size", 3)
		"heal":
			lbl.text = "+" + str(value)
			lbl.add_theme_font_size_override("font_size", 24)
			lbl.add_theme_color_override("font_color", Color(0.2, 1, 0.4))
			lbl.add_theme_color_override("font_outline_color", Color(0, 0.15, 0))
			lbl.add_theme_constant_override("outline_size", 2)
		"shield":
			lbl.text = "+" + str(value) + " 🛡"
			lbl.add_theme_font_size_override("font_size", 22)
			lbl.add_theme_color_override("font_color", Color(0.3, 0.7, 1))
			lbl.add_theme_color_override("font_outline_color", Color(0, 0.05, 0.15))
			lbl.add_theme_constant_override("outline_size", 2)
		"crit":
			lbl.text = "-" + str(value) + " !"
			lbl.add_theme_font_size_override("font_size", 34)
			lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.1))
			lbl.add_theme_color_override("font_outline_color", Color(0.3, 0.15, 0))
			lbl.add_theme_constant_override("outline_size", 4)

	# 定位在目标精灵上方，加随机偏移避免重叠
	var spawn_pos := target_node.global_position + Vector2(
		target_node.size.x * target_node.scale.x * 0.5 + randf_range(-20, 20) - 30.0,
		-10.0 + randf_range(-10, 5)
	)
	lbl.global_position = spawn_pos
	add_child(lbl)

	# 弹出动画：先快速上升后减速，同时缩放弹跳
	var tw := lbl.create_tween().set_parallel(true)
	tw.tween_property(lbl, "global_position:y", spawn_pos.y - 60.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.3).set_delay(0.4)
	# 缩放弹跳
	lbl.pivot_offset = lbl.size / 2.0
	lbl.scale = Vector2(0.5, 0.5)
	tw.tween_property(lbl, "scale", Vector2(1.1, 1.1), 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	var tw2 := lbl.create_tween()
	tw2.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.12)
	tw2.tween_callback(lbl.queue_free).set_delay(0.6)

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
	_update_shield_visuals()

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

	# 3秒后自动淡出 (bind to lbl so tween dies when lbl is freed)
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(2.5)
	tw.tween_callback(lbl.queue_free)

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

# ============================================================
# 赛博道教氛围系统
# ============================================================

## 更新能量场 shader 状态（0=常态, 1=共鸣, 2=反噬）
func _update_energy_field_state(battle_state_val: int) -> void:
	if _energy_field_rect and _energy_field_rect.material is ShaderMaterial:
		var mat := _energy_field_rect.material as ShaderMaterial
		mat.set_shader_parameter("battle_state", battle_state_val)
		# 共鸣时加强能量场强度
		if battle_state_val == 1:
			var tw := create_tween()
			tw.tween_method(func(v: float):
				if is_instance_valid(_energy_field_rect) and _energy_field_rect.material is ShaderMaterial:
					(_energy_field_rect.material as ShaderMaterial).set_shader_parameter("field_intensity", v)
			, 0.25, 0.5, 0.5)
			tw.tween_method(func(v: float):
				if is_instance_valid(_energy_field_rect) and _energy_field_rect.material is ShaderMaterial:
					(_energy_field_rect.material as ShaderMaterial).set_shader_parameter("field_intensity", v)
			, 0.5, 0.25, 1.5)
		elif battle_state_val == 2:
			var tw := create_tween()
			tw.tween_method(func(v: float):
				if is_instance_valid(_energy_field_rect) and _energy_field_rect.material is ShaderMaterial:
					(_energy_field_rect.material as ShaderMaterial).set_shader_parameter("field_intensity", v)
			, 0.25, 0.6, 0.3)
			tw.tween_method(func(v: float):
				if is_instance_valid(_energy_field_rect) and _energy_field_rect.material is ShaderMaterial:
					(_energy_field_rect.material as ShaderMaterial).set_shader_parameter("field_intensity", v)
			, 0.6, 0.25, 2.0)

## 回合开始墨迹扩散特效
func _play_turn_start_ink_burst() -> void:
	if not _ink_flow_rect or not _ink_flow_rect.material is ShaderMaterial:
		return
	var mat := _ink_flow_rect.material as ShaderMaterial
	# 触发墨迹从屏幕中心向外扩散
	mat.set_shader_parameter("ink_intensity", 0.4)
	mat.set_shader_parameter("spread_radius", 0.0)
	var ink_ref: ColorRect = _ink_flow_rect
	var tw := create_tween()
	tw.tween_method(func(v: float):
		if is_instance_valid(ink_ref) and ink_ref.material is ShaderMaterial:
			(ink_ref.material as ShaderMaterial).set_shader_parameter("spread_radius", v)
	, 0.0, 1.2, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(func(v: float):
		if is_instance_valid(ink_ref) and ink_ref.material is ShaderMaterial:
			(ink_ref.material as ShaderMaterial).set_shader_parameter("ink_intensity", v)
	, 0.4, 0.12, 0.8)
	tw.tween_method(func(v: float):
		if is_instance_valid(ink_ref) and ink_ref.material is ShaderMaterial:
			(ink_ref.material as ShaderMaterial).set_shader_parameter("spread_radius", v)
	, 1.2, 0.0, 0.3)

# ============================================================
# === 回合横幅 + 屏幕震动 + 护盾视觉 (STS风格升级) ===
# ============================================================

## 回合切换横幅（杀戮尖塔风格：大字居中淡入淡出）
func _show_turn_banner(text: String, color: Color) -> void:
	# 背景暗条
	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.0)
	backdrop.size = Vector2(1280, 80)
	backdrop.position = Vector2(0, 190)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.z_index = 95
	add_child(backdrop)

	# 主文字
	var banner := Label.new()
	banner.text = text
	banner.add_theme_font_size_override("font_size", 42)
	banner.add_theme_color_override("font_color", color)
	banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	banner.add_theme_constant_override("shadow_offset_x", 2)
	banner.add_theme_constant_override("shadow_offset_y", 2)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.size = Vector2(1280, 80)
	banner.position = Vector2(0, 190)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.z_index = 96
	banner.modulate.a = 0.0
	banner.scale = Vector2(0.6, 0.6)
	banner.pivot_offset = Vector2(640, 40)
	add_child(banner)

	# 动画：淡入+缩放→保持→淡出
	var tw: Tween = create_tween()
	# 背景暗条淡入
	tw.tween_property(backdrop, "color:a", 0.5, 0.2)
	tw.parallel().tween_property(banner, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(banner, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# 保持
	tw.tween_interval(0.6)
	# 淡出
	tw.tween_property(banner, "modulate:a", 0.0, 0.25)
	tw.parallel().tween_property(backdrop, "color:a", 0.0, 0.3)
	tw.parallel().tween_property(banner, "scale", Vector2(1.15, 1.15), 0.25)
	# 清理
	tw.tween_callback(backdrop.queue_free)
	tw.tween_callback(banner.queue_free)

## 屏幕震动（受击反馈）
func _screen_shake(intensity: float = 8.0, duration: float = 0.3) -> void:
	var original_pos: Vector2 = position
	var tw: Tween = create_tween()
	var steps: int = int(duration / 0.03)
	for i in steps:
		var offset := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity * 0.6, intensity * 0.6)
		)
		# 强度递减
		var decay: float = 1.0 - float(i) / float(steps)
		tw.tween_property(self, "position", original_pos + offset * decay, 0.03)
	tw.tween_property(self, "position", original_pos, 0.03)

## 护盾视觉覆盖（角色身上显示蓝色护盾图标+数值）
var _player_shield_visual: Control = null
var _enemy_shield_visual: Control = null

func _update_shield_visuals() -> void:
	# --- 玩家护盾 ---
	if player_shield > 0:
		if not _player_shield_visual or not is_instance_valid(_player_shield_visual):
			_player_shield_visual = _create_shield_badge()
			add_child(_player_shield_visual)
		if player_sprite and is_instance_valid(player_sprite):
			_player_shield_visual.global_position = Vector2(
				player_sprite.global_position.x + player_sprite.size.x * player_sprite.scale.x * 0.5 - 18,
				player_sprite.global_position.y - 10
			)
		_player_shield_visual.visible = true
		var shield_lbl: Label = _player_shield_visual.get_node_or_null("val")
		if shield_lbl:
			shield_lbl.text = str(player_shield)
	else:
		if _player_shield_visual and is_instance_valid(_player_shield_visual):
			_player_shield_visual.visible = false

	# --- 敌人护盾 ---
	if enemy and enemy.shield > 0:
		if not _enemy_shield_visual or not is_instance_valid(_enemy_shield_visual):
			_enemy_shield_visual = _create_shield_badge()
			add_child(_enemy_shield_visual)
		if enemy_sprite and is_instance_valid(enemy_sprite):
			_enemy_shield_visual.global_position = Vector2(
				enemy_sprite.global_position.x + enemy_sprite.size.x * enemy_sprite.scale.x * 0.5 - 18,
				enemy_sprite.global_position.y - 10
			)
		_enemy_shield_visual.visible = true
		var shield_lbl: Label = _enemy_shield_visual.get_node_or_null("val")
		if shield_lbl:
			shield_lbl.text = str(enemy.shield)
	else:
		if _enemy_shield_visual and is_instance_valid(_enemy_shield_visual):
			_enemy_shield_visual.visible = false

func _create_shield_badge() -> Control:
	var badge := Control.new()
	badge.z_index = 60
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 盾牌底色（圆角蓝色底）
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0)
	bg.size = Vector2(36, 36)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var shield_shader := Shader.new()
	shield_shader.code = "
shader_type canvas_item;
void fragment() {
	vec2 c = UV - vec2(0.5);
	float d = length(c);
	// 盾牌形状（上半圆+下尖角）
	float shape = smoothstep(0.5, 0.44, d);
	if (UV.y > 0.55) {
		float taper = (UV.y - 0.55) / 0.45;
		float w = 0.5 - taper * 0.4;
		shape *= smoothstep(w + 0.05, w, abs(UV.x - 0.5));
	}
	float pulse = 0.85 + 0.15 * sin(TIME * 3.0);
	vec3 col = mix(vec3(0.1, 0.3, 0.7), vec3(0.3, 0.6, 1.0), UV.y);
	float border = smoothstep(0.38, 0.42, d) * shape;
	col = mix(col, vec3(0.5, 0.8, 1.0), border * 0.5);
	COLOR = vec4(col * pulse, shape * 0.85);
}
"
	var mat := ShaderMaterial.new()
	mat.shader = shield_shader
	bg.material = mat
	badge.add_child(bg)

	# 数值文字
	var lbl := Label.new()
	lbl.name = "val"
	lbl.size = Vector2(36, 36)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(lbl)

	return badge
