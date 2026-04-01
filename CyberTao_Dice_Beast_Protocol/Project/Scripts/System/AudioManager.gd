extends Node
class_name AudioManager

## 音效管理器（v0.1.56）
## class_name 全局注册，由 Main.gd 创建并 add_child
## 使用 SFXGenerator 程序化生成音效，缓存 AudioStream，多通道播放
## 调用方式：audio_manager.play_sfx("attack_hit")

# --- 配置 ---
const SFX_CHANNELS: int = 6
const BGM_VOLUME_DB: float = -18.0
const SFX_VOLUME_DB: float = -12.0

# --- 内部状态 ---
var _cache: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _bgm_player: AudioStreamPlayer = null
var _current_bgm: String = ""
var _sfx_enabled: bool = true
var _bgm_enabled: bool = true

func _ready() -> void:
	# 创建多通道 SFX 播放器
	for i in SFX_CHANNELS:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = SFX_VOLUME_DB
		add_child(player)
		_sfx_players.append(player)
	# 创建 BGM 播放器
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	_bgm_player.volume_db = BGM_VOLUME_DB
	add_child(_bgm_player)
	# 预生成常用音效缓存
	_precache_sfx()

# --- 预缓存 ---
func _precache_sfx() -> void:
	_cache["attack_hit"] = SFXGenerator.generate_attack_sfx()
	_cache["defense"] = SFXGenerator.generate_defense_sfx()
	_cache["card_draw"] = SFXGenerator.generate_draw_sfx()
	_cache["card_play"] = SFXGenerator.generate_card_play_sfx()
	_cache["victory"] = SFXGenerator.generate_victory_sfx()
	_cache["defeat"] = SFXGenerator.generate_defeat_sfx()
	_cache["click"] = SFXGenerator.generate_click_sfx()
	_cache["heal"] = SFXGenerator.generate_heal_sfx()
	_cache["summon"] = SFXGenerator.generate_summon_sfx()
	_cache["encounter"] = SFXGenerator.generate_transition_sfx()
	# v0.1.86：柔化高刺耳音效（保留事件语义，降低“炸耳”感）
	_cache["dice_roll"] = SFXGenerator.generate_draw_sfx()
	_cache["player_hurt"] = SFXGenerator.generate_enemy_hurt_sfx()
	_cache["enemy_hurt"] = SFXGenerator.generate_enemy_hurt_sfx()
	_cache["turn_start"] = SFXGenerator.generate_turn_start_sfx()
	_cache["boss_attack"] = SFXGenerator.generate_attack_sfx()
	_cache["pickup"] = SFXGenerator.generate_click_sfx()
	_cache["chest"] = SFXGenerator.generate_resonance_sfx()
	_cache["shop"] = SFXGenerator.generate_bell_sfx()

# --- 公开 API ---

## 播放一次性音效
func play_sfx(sfx_name: String) -> void:
	if not _sfx_enabled:
		return
	var stream: AudioStream = _get_or_generate(sfx_name)
	if stream == null:
		return
	# 找一个空闲通道
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	# 全部占用则抢占第一个
	_sfx_players[0].stream = stream
	_sfx_players[0].play()

## 播放 BGM（循环）
func play_bgm(bgm_name: String) -> void:
	if not _bgm_enabled:
		return
	if bgm_name == _current_bgm and _bgm_player.playing:
		return
	var stream: AudioStream = _get_or_generate(bgm_name)
	if stream == null:
		return
	_current_bgm = bgm_name
	_bgm_player.stream = stream
	_bgm_player.play()

## 停止 BGM
func stop_bgm() -> void:
	_bgm_player.stop()
	_current_bgm = ""

## 开关 SFX
func set_sfx_enabled(enabled: bool) -> void:
	_sfx_enabled = enabled

## 开关 BGM
func set_bgm_enabled(enabled: bool) -> void:
	_bgm_enabled = enabled
	if not enabled:
		stop_bgm()

# --- 内部：获取或生成音效 ---
func _get_or_generate(name: String) -> AudioStream:
	if _cache.has(name):
		return _cache[name] as AudioStream
	# 尝试按名称动态生成 BGM
	var stream: AudioStream = null
	match name:
		"bgm_battle":
			stream = SFXGenerator.generate_battle_bgm_loop()
		"bgm_map":
			stream = SFXGenerator.generate_map_bgm_loop()
		"bgm_boss":
			stream = SFXGenerator.generate_boss_bgm_loop()
		"bgm_title":
			stream = SFXGenerator.generate_title_bgm_loop()
	if stream != null:
		_cache[name] = stream
	return stream

# --- 音量控制 API ---

## 设置 BGM 音量（0.0 ~ 1.0）
func set_bgm_volume(volume: float) -> void:
	var db: float = linear_to_db(clampf(volume, 0.0, 1.0)) if volume > 0.001 else -80.0
	_bgm_player.volume_db = db

## 设置 SFX 音量（0.0 ~ 1.0）
func set_sfx_volume(volume: float) -> void:
	var db: float = linear_to_db(clampf(volume, 0.0, 1.0)) if volume > 0.001 else -80.0
	for player in _sfx_players:
		player.volume_db = db

## 获取当前 BGM 音量（0.0 ~ 1.0）
func get_bgm_volume() -> float:
	return db_to_linear(_bgm_player.volume_db)

## 获取当前 SFX 音量（0.0 ~ 1.0）
func get_sfx_volume() -> float:
	if _sfx_players.size() > 0:
		return db_to_linear(_sfx_players[0].volume_db)
	return 1.0

func is_sfx_enabled() -> bool:
	return _sfx_enabled

func is_bgm_enabled() -> bool:
	return _bgm_enabled
