# ============================================================
# AssetLoader.gd - 美术资产加载器（文件名约定驱动）
# Autoload名称: AssetLoader
#
# ★ 替换规则：往对应文件夹放PNG即可，游戏自动加载 ★
# 找不到自定义图片时，回退到PixelArtGenerator程序化生成
#
# 文件夹结构 & 命名约定：
# ──────────────────────────────────────────────
# Assets/
# ├── Characters/
# │   ├── player_idle.png      ← 玩家站立 (透明底, 建议144x192)
# │   ├── player_attack.png    ← 玩家攻击姿势
# │   └── player_hurt.png      ← 玩家受击姿势
# │
# ├── Enemies/
# │   ├── grunt_idle.png       ← 杂兵1(数据游魂)站立
# │   ├── grunt_attack.png     ← 杂兵1攻击
# │   ├── grunt_hurt.png       ← 杂兵1受击
# │   ├── grunt2_idle.png      ← 杂兵2(代码虫群)
# │   ├── grunt2_attack.png
# │   ├── grunt2_hurt.png
# │   ├── grunt3_idle.png      ← 杂兵3(数据窃贼)
# │   ├── elite_idle.png       ← 精英1(欲望傀儡)
# │   ├── elite_attack.png
# │   ├── elite_hurt.png
# │   ├── elite2_idle.png      ← 精英2(扭曲执念)
# │   ├── boss_idle.png        ← BOSS(旧我)
# │   ├── boss_attack.png
# │   └── boss_hurt.png
# │
# ├── Summons/
# │   ├── summon_fox_idle.png   ← 赛博狐站立
# │   ├── summon_crane_idle.png ← 道鹤
# │   ├── summon_dragon_idle.png
# │   ├── summon_golem_idle.png
# │   ├── summon_sprite_idle.png
# │   ├── summon_clone_idle.png
# │   ├── summon_familiar_idle.png
# │   ├── summon_swarm_idle.png
# │   └── summon_beast_idle.png
# │
# ├── Cards/
# │   ├── atk_basic_strike.png  ← 按card_id命名，每张卡独立美术
# │   ├── atk_cyber_slash.png
# │   ├── def_basic_guard.png
# │   ├── sum_cyber_fox.png
# │   ├── spl_adrenaline.png
# │   ├── pow_thorns.png
# │   └── ... (102张，没有的自动用类型模板)
# │   ├── _type_attack.png      ← 类型模板(以下划线开头)，没有独立卡图时用
# │   ├── _type_defense.png
# │   ├── _type_summon.png
# │   ├── _type_spell.png
# │   └── _type_power.png
# │
# ├── Backgrounds/
# │   ├── bg_grunt.png          ← 杂兵战斗背景 (1280x720)
# │   ├── bg_elite.png          ← 精英背景
# │   ├── bg_elite2.png
# │   └── bg_boss.png           ← BOSS背景
# │
# └── UI/
#     ├── title_bg.png          ← 标题画面背景
#     ├── taiji.png             ← 太极符号
#     └── map_bg.png            ← 地图背景
# ──────────────────────────────────────────────
# ============================================================
extends Node

## 是否启用自定义资产（false = 全部用程序化生成）
var use_ai_assets := true

## 资产缓存（避免重复从磁盘加载）
var _cache := {}

## 基础路径
const BASE := "res://Assets/"

## 帧名映射：frame编号 → 文件后缀
const FRAME_SUFFIX := {
	0: "_idle",
	1: "_attack",
	2: "_hurt",
}

# ============================================================
# 角色/敌人/召唤物 精灵
# ============================================================

## 获取角色精灵（支持动画帧）
## char_type: "player", "grunt", "boss", "summon_fox" 等
## frame: 0=站立, 1=攻击, 2=受击
func get_character_sprite(char_type: String, frame: int = 0) -> ImageTexture:
	if not use_ai_assets:
		return null
	var suffix: String = FRAME_SUFFIX.get(frame, "_idle")
	var key := char_type + suffix

	if _cache.has(key):
		return _cache[key]

	# 按优先级搜索文件夹
	var folders := []
	if char_type == "player":
		folders = ["Characters"]
	elif char_type.begins_with("summon_"):
		folders = ["Summons", "Characters"]
	else:
		folders = ["Enemies", "Characters"]

	var tex: ImageTexture = null
	for folder in folders:
		# 先找带帧后缀的: grunt_attack.png
		var path_with_frame := BASE + folder + "/" + char_type + suffix + ".png"
		tex = _try_load(path_with_frame, 144, 192)
		if tex:
			break
		# 再找不带帧后缀的(单图): grunt.png（仅idle帧回退）
		if frame == 0:
			var path_no_frame := BASE + folder + "/" + char_type + ".png"
			tex = _try_load(path_no_frame, 144, 192)
			if tex:
				break

	if tex:
		_cache[key] = tex
	return tex


## 获取召唤物精灵（72x96尺寸）
func get_summon_sprite(summon_type: String) -> ImageTexture:
	if not use_ai_assets:
		return null
	var key := "sm72_" + summon_type
	if _cache.has(key):
		return _cache[key]

	# 搜索: summon_fox_idle.png → summon_fox.png
	var tex := _try_load(BASE + "Summons/" + summon_type + "_idle.png", 72, 96)
	if not tex:
		tex = _try_load(BASE + "Summons/" + summon_type + ".png", 72, 96)
	if tex:
		_cache[key] = tex
	return tex


# ============================================================
# 卡牌美术
# ============================================================

## 获取卡牌美术（优先按card_id查找独立图，没有则用类型模板）
## card_id: "atk_basic_strike", "def_firewall" 等
## card_type: 0=ATTACK, 1=DEFENSE, 2=SUMMON, 3=SPELL, 4=POWER
func get_card_art(card_type: int, _yinyang: int = 0, _rarity: int = 0, _seed: int = 0, card_id: String = "") -> ImageTexture:
	if not use_ai_assets:
		return null

	# 1) 按card_id查找独立卡图
	if card_id != "":
		var key_id := "card_" + card_id
		if _cache.has(key_id):
			return _cache[key_id]
		var tex := _try_load(BASE + "Cards/" + card_id + ".png", 64, 64)
		if tex:
			_cache[key_id] = tex
			return tex

	# 2) 回退到类型模板
	var type_names := {0: "attack", 1: "defense", 2: "summon", 3: "spell", 4: "power"}
	var type_name: String = type_names.get(card_type, "attack")
	var key_type := "card_type_" + type_name
	if _cache.has(key_type):
		return _cache[key_type]
	var tex := _try_load(BASE + "Cards/_type_" + type_name + ".png", 64, 64)
	if tex:
		_cache[key_type] = tex
	return tex


# ============================================================
# 战斗背景
# ============================================================

func get_battle_background(stage: String) -> ImageTexture:
	if not use_ai_assets:
		return null
	var key := "bg_" + stage
	if _cache.has(key):
		return _cache[key]

	# grunt2/grunt3 共享 grunt 背景
	var bg_key := stage
	if stage in ["grunt2", "grunt3"]:
		bg_key = "grunt"

	var tex := _try_load(BASE + "Backgrounds/bg_" + bg_key + ".png", 1280, 720)
	if not tex and bg_key != "grunt":
		tex = _try_load(BASE + "Backgrounds/bg_grunt.png", 1280, 720)
	if tex:
		_cache[key] = tex
	return tex


# ============================================================
# UI 元素
# ============================================================

func get_ui_texture(ui_name: String, width: int = 0, height: int = 0) -> ImageTexture:
	if not use_ai_assets:
		return null
	var key := "ui_" + ui_name
	if _cache.has(key):
		return _cache[key]

	var path := BASE + "UI/" + ui_name + ".png"
	var tex: ImageTexture
	if width > 0 and height > 0:
		tex = _try_load(path, width, height)
	else:
		tex = _try_load_raw(path)
	if tex:
		_cache[key] = tex
	return tex


# ============================================================
# 缓存管理
# ============================================================

func clear_cache() -> void:
	_cache.clear()

## 运行时替换单个资产（高级用法：热更新）
func invalidate(cache_key: String) -> void:
	_cache.erase(cache_key)


# ============================================================
# 内部：文件加载（使用Godot资源系统，兼容导出）
# ============================================================

func _try_load(path: String, tw: int, th: int) -> ImageTexture:
	if not ResourceLoader.exists(path):
		return null
	var res = load(path)
	if res == null:
		return null
	# load() 返回 CompressedTexture2D，需要转换为 ImageTexture 以便 resize
	var img: Image = null
	if res is Texture2D:
		img = res.get_image()
	elif res is Image:
		img = res
	else:
		return null
	if img == null:
		return null
	# resize 到目标尺寸
	if img.get_width() != tw or img.get_height() != th:
		img.resize(tw, th, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)

func _try_load_raw(path: String) -> ImageTexture:
	if not ResourceLoader.exists(path):
		return null
	var res = load(path)
	if res == null:
		return null
	if res is Texture2D:
		var img := res.get_image()
		if img == null:
			return null
		return ImageTexture.create_from_image(img)
	elif res is Image:
		return ImageTexture.create_from_image(res)
	return null
