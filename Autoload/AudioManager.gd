# ============================================================
# AudioManager.gd - 音频管理器（BGM + SFX）
# 使用SFXGenerator程序化生成8bit音效，无需外部文件
# Autoload名称: AudioManager
# ============================================================
extends Node

## BGM播放器
var bgm_player: AudioStreamPlayer
## SFX播放器池
var sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 12

## 当前BGM标识
var current_bgm_id: String = ""

## 预生成的音效缓存
var _sfx_cache: Dictionary = {}
## 预生成的BGM缓存
var _bgm_cache: Dictionary = {}

## 用于crossfade的辅助BGM播放器
var _bgm_fade_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 创建BGM播放器
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	bgm_player.volume_db = -8.0
	add_child(bgm_player)
	# 创建crossfade用辅助BGM播放器
	_bgm_fade_player = AudioStreamPlayer.new()
	_bgm_fade_player.bus = "Master"
	_bgm_fade_player.volume_db = -40.0
	add_child(_bgm_fade_player)
	# 创建SFX播放器池
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = -3.0
		add_child(p)
		sfx_players.append(p)
	# 预生成所有音效
	_generate_all_audio()

## 预生成所有音效和BGM
func _generate_all_audio() -> void:
	_sfx_cache["attack"] = SFXGenerator.generate_attack_sfx()
	_sfx_cache["defense"] = SFXGenerator.generate_defense_sfx()
	_sfx_cache["draw"] = SFXGenerator.generate_draw_sfx()
	_sfx_cache["resonance"] = SFXGenerator.generate_resonance_sfx()
	_sfx_cache["backlash"] = SFXGenerator.generate_backlash_sfx()
	_sfx_cache["bell"] = SFXGenerator.generate_bell_sfx()
	_sfx_cache["victory"] = SFXGenerator.generate_victory_sfx()
	_sfx_cache["defeat"] = SFXGenerator.generate_defeat_sfx()
	_sfx_cache["glitch"] = SFXGenerator.generate_cyber_glitch_sfx()
	_sfx_cache["click"] = SFXGenerator.generate_click_sfx()
	_sfx_cache["summon"] = SFXGenerator.generate_summon_sfx()
	_sfx_cache["heal"] = SFXGenerator.generate_heal_sfx()
	_sfx_cache["card_hover"] = SFXGenerator.generate_card_hover_sfx()
	_sfx_cache["transition"] = SFXGenerator.generate_transition_sfx()
	_bgm_cache["battle"] = SFXGenerator.generate_battle_bgm_loop()
	_bgm_cache["title"] = SFXGenerator.generate_title_bgm_loop()
	_bgm_cache["map"] = SFXGenerator.generate_map_bgm_loop()
	_bgm_cache["boss"] = SFXGenerator.generate_boss_bgm_loop()
	_sfx_cache["typing"] = SFXGenerator.generate_typing_sfx()
	_sfx_cache["spell"] = SFXGenerator.generate_spell_sfx()
	_sfx_cache["boss_attack"] = SFXGenerator.generate_boss_attack_sfx()
	_sfx_cache["boss_hurt"] = SFXGenerator.generate_boss_hurt_sfx()
	_bgm_cache["opening"] = SFXGenerator.generate_opening_bgm_loop()

## 播放预生成的BGM
func play_bgm_generated(bgm_id: String, volume_db: float = -8.0) -> void:
	if current_bgm_id == bgm_id and bgm_player.playing:
		return
	if bgm_id not in _bgm_cache:
		push_warning("AudioManager: BGM ID不存在 - " + bgm_id)
		return
	current_bgm_id = bgm_id
	bgm_player.stream = _bgm_cache[bgm_id]
	bgm_player.volume_db = volume_db
	bgm_player.play()

## 播放预生成的音效
func play_sfx_generated(sfx_id: String, volume_db: float = -3.0) -> void:
	if sfx_id not in _sfx_cache:
		return
	var stream: AudioStreamWAV = _sfx_cache[sfx_id]
	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.play()
			return
	sfx_players[0].stream = stream
	sfx_players[0].volume_db = volume_db
	sfx_players[0].play()

## 停止BGM（淡出）
func stop_bgm(fade_time: float = 1.0) -> void:
	if not bgm_player.playing:
		return
	var tween: Tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", -40.0, fade_time)
	await tween.finished
	bgm_player.stop()
	current_bgm_id = ""

## Crossfade到新BGM：淡出当前BGM，同时淡入新BGM
func crossfade_bgm(bgm_id: String, fade_time: float = 1.0) -> void:
	if current_bgm_id == bgm_id and bgm_player.playing:
		return
	if bgm_id not in _bgm_cache:
		push_warning("AudioManager: BGM ID不存在 - " + bgm_id)
		return
	# Swap players: move current into fade player, use main for new track
	var old_volume: float = bgm_player.volume_db
	# Transfer current playback to fade player for fade-out
	if bgm_player.playing:
		_bgm_fade_player.stream = bgm_player.stream
		_bgm_fade_player.volume_db = old_volume
		_bgm_fade_player.play()
		_bgm_fade_player.seek(bgm_player.get_playback_position())
		bgm_player.stop()
	# Start new BGM on main player at silent volume, then fade in
	current_bgm_id = bgm_id
	bgm_player.stream = _bgm_cache[bgm_id]
	bgm_player.volume_db = -40.0
	bgm_player.play()
	# Create crossfade tween
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(bgm_player, "volume_db", old_volume, fade_time)
	tween.tween_property(_bgm_fade_player, "volume_db", -40.0, fade_time)
	await tween.finished
	_bgm_fade_player.stop()

## 设置BGM音高（用于Boss阶段变化的动态BGM变形）
func set_bgm_pitch(pitch_scale: float) -> void:
	bgm_player.pitch_scale = pitch_scale

## 播放BGM（从文件，备用）
func play_bgm(path: String, volume_db: float = -8.0) -> void:
	if not ResourceLoader.exists(path):
		return
	bgm_player.stream = load(path) as AudioStream
	bgm_player.volume_db = volume_db
	bgm_player.play()

## 播放音效（从文件，备用）
func play_sfx(path: String, volume_db: float = -3.0) -> void:
	if not ResourceLoader.exists(path):
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = load(path) as AudioStream
			p.volume_db = volume_db
			p.play()
			return
	sfx_players[0].stream = load(path) as AudioStream
	sfx_players[0].volume_db = volume_db
	sfx_players[0].play()
