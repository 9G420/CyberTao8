# ============================================================
# GameState.gd - 游戏状态管理（存档、运行进度、传承卡）
# Autoload名称: GameState
# ============================================================
extends Node

## 玩家当前牌组（CardData资源路径数组）
var player_deck: Array[String] = []

## 当前可用卡池（商店/事件可获得的卡）
var available_pool: Array[String] = []

## 传承卡（死亡/通关后保留，最多1张）
var legacy_card: String = ""

## 当前地图节点索引（0-3表示4个节点）
var current_node_index: int = 0

## 最大节点数
const MAX_NODES := 4

## 玩家生命值
var player_hp: int = 30
var player_max_hp: int = 30

## 玩家金币（用于商店）
var player_gold: int = 50

## 阴阳累计值（场上）
var yin_count: int = 0
var yang_count: int = 0

## 已完成的战斗数
var battles_won: int = 0

## 剧情选择倾向：0=中立, 负数=贪欲, 正数=觉醒
var story_alignment: int = 0

## 当前Run编号
var run_number: int = 1

## 成就
var achievements: Dictionary = {
	"first_awakening": false,    # 首次觉醒
	"yinyang_master": false,     # 阴阳大师（战斗中维持道境共鸣5回合）
	"no_damage_boss": false,     # 无伤Boss
	"full_collection": false,    # 收集所有卡
}

## 地图节点数据
var map_nodes: Array[Dictionary] = []

## 保存路径
const SAVE_PATH := "user://cybertao_save.json"

## 所有卡牌资源路径（用于初始化卡池）
const ALL_CARD_PATHS: Array[String] = [
	# === 攻击卡 (32张) ===
	"res://Resources/Cards/atk_basic_strike.tres",
	"res://Resources/Cards/atk_yang_strike.tres",
	"res://Resources/Cards/atk_yin_strike.tres",
	"res://Resources/Cards/atk_double_tap.tres",
	"res://Resources/Cards/atk_circuit_break.tres",
	"res://Resources/Cards/atk_cyber_slash.tres",
	"res://Resources/Cards/atk_data_pierce.tres",
	"res://Resources/Cards/atk_flame_sigil.tres",
	"res://Resources/Cards/atk_neon_flash.tres",
	"res://Resources/Cards/atk_quick_compile.tres",
	"res://Resources/Cards/atk_poison_inject.tres",
	"res://Resources/Cards/atk_dagger_rain.tres",
	"res://Resources/Cards/atk_dao_thorn.tres",
	"res://Resources/Cards/atk_data_shatter.tres",
	"res://Resources/Cards/atk_dark_pulse.tres",
	"res://Resources/Cards/atk_disaster_algo.tres",
	"res://Resources/Cards/atk_thunder_chain.tres",
	"res://Resources/Cards/atk_core_breach.tres",
	"res://Resources/Cards/atk_finisher.tres",
	"res://Resources/Cards/atk_void_slash.tres",
	"res://Resources/Cards/atk_precise_strike.tres",
	"res://Resources/Cards/atk_all_in.tres",
	"res://Resources/Cards/atk_bone_erode.tres",
	"res://Resources/Cards/atk_pixel_storm.tres",
	"res://Resources/Cards/atk_strangle.tres",
	"res://Resources/Cards/atk_elegant_finish.tres",
	"res://Resources/Cards/atk_void_wrath.tres",
	"res://Resources/Cards/atk_dao_judgement.tres",
	"res://Resources/Cards/atk_apocalypse.tres",
	"res://Resources/Cards/atk_data_flood.tres",
	"res://Resources/Cards/atk_glass_blade.tres",
	# === 防御卡 (24张) ===
	"res://Resources/Cards/def_basic_guard.tres",
	"res://Resources/Cards/def_yang_guard.tres",
	"res://Resources/Cards/def_yin_guard.tres",
	"res://Resources/Cards/def_dao_ward.tres",
	"res://Resources/Cards/def_digital_cloak.tres",
	"res://Resources/Cards/def_firewall.tres",
	"res://Resources/Cards/def_yin_shield.tres",
	"res://Resources/Cards/def_deflect.tres",
	"res://Resources/Cards/def_spirit_guard.tres",
	"res://Resources/Cards/def_backflip.tres",
	"res://Resources/Cards/def_delayed.tres",
	"res://Resources/Cards/def_talisman.tres",
	"res://Resources/Cards/def_cloak_weave.tres",
	"res://Resources/Cards/def_code_armor.tres",
	"res://Resources/Cards/def_thorn_armor.tres",
	"res://Resources/Cards/def_afterimage.tres",
	"res://Resources/Cards/def_leg_sweep.tres",
	"res://Resources/Cards/def_pixel_barrier.tres",
	"res://Resources/Cards/def_harmony_light.tres",
	"res://Resources/Cards/def_data_fortress.tres",
	"res://Resources/Cards/def_crippling_cloud.tres",
	"res://Resources/Cards/def_spirit_scatter.tres",
	"res://Resources/Cards/def_planned_well.tres",
	"res://Resources/Cards/def_ghost_form.tres",
	"res://Resources/Cards/def_settle_accounts.tres",
	"res://Resources/Cards/def_dao_bulwark.tres",
	"res://Resources/Cards/def_time_fold.tres",
	# === 术法卡 (23张) ===
	"res://Resources/Cards/spl_dao_guidance.tres",
	"res://Resources/Cards/spl_preparation.tres",
	"res://Resources/Cards/spl_system_scan.tres",
	"res://Resources/Cards/spl_glitch_wave.tres",
	"res://Resources/Cards/spl_yinyang_reverse.tres",
	"res://Resources/Cards/spl_blade_dance.tres",
	"res://Resources/Cards/spl_lethal_corrode.tres",
	"res://Resources/Cards/spl_seize_initiative.tres",
	"res://Resources/Cards/spl_catalyze.tres",
	"res://Resources/Cards/spl_concentrate.tres",
	"res://Resources/Cards/spl_universal_balance.tres",
	"res://Resources/Cards/spl_bounce_vial.tres",
	"res://Resources/Cards/spl_dao_heart_cycle.tres",
	"res://Resources/Cards/spl_instinct_reaction.tres",
	"res://Resources/Cards/spl_terror_data.tres",
	"res://Resources/Cards/spl_crazy_compile.tres",
	"res://Resources/Cards/spl_corpse_explode.tres",
	"res://Resources/Cards/spl_bullet_time.tres",
	"res://Resources/Cards/spl_nightmare_copy.tres",
	"res://Resources/Cards/spl_system_reboot.tres",
	"res://Resources/Cards/spl_dual_existence.tres",
	"res://Resources/Cards/spl_adrenaline.tres",
	"res://Resources/Cards/spl_quick_patch.tres",
	"res://Resources/Cards/spl_overclock.tres",
	# === 召唤卡 (9张) ===
	"res://Resources/Cards/sum_pixel_sprite.tres",
	"res://Resources/Cards/sum_cyber_fox.tres",
	"res://Resources/Cards/sum_dao_crane.tres",
	"res://Resources/Cards/sum_neon_golem.tres",
	"res://Resources/Cards/sum_shadow_clone.tres",
	"res://Resources/Cards/sum_spirit_dragon.tres",
	"res://Resources/Cards/sum_byte_familiar.tres",
	"res://Resources/Cards/sum_swarm.tres",
	"res://Resources/Cards/sum_beast.tres",
	# === 能力卡 (10张) ===
	"res://Resources/Cards/pow_nimble_step.tres",
	"res://Resources/Cards/pow_poison_protocol.tres",
	"res://Resources/Cards/pow_infinite_blade.tres",
	"res://Resources/Cards/pow_precision.tres",
	"res://Resources/Cards/pow_thorns.tres",
	"res://Resources/Cards/pow_afterimage.tres",
	"res://Resources/Cards/pow_lingchi.tres",
	"res://Resources/Cards/pow_poison_fog.tres",
	"res://Resources/Cards/pow_essential_tools.tres",
	"res://Resources/Cards/pow_dao_awakening.tres",
]

## 初始牌组路径（10张基础卡）
const STARTER_DECK: Array[String] = [
	"res://Resources/Cards/atk_basic_strike.tres",
	"res://Resources/Cards/atk_basic_strike.tres",
	"res://Resources/Cards/atk_yang_strike.tres",
	"res://Resources/Cards/atk_yin_strike.tres",
	"res://Resources/Cards/def_basic_guard.tres",
	"res://Resources/Cards/def_basic_guard.tres",
	"res://Resources/Cards/def_yang_guard.tres",
	"res://Resources/Cards/def_yin_guard.tres",
	"res://Resources/Cards/spl_dao_guidance.tres",
	"res://Resources/Cards/sum_pixel_sprite.tres",
]

func _ready() -> void:
	_init_map_nodes()

## 开始新游戏
func start_new_game() -> void:
	player_deck = STARTER_DECK.duplicate() as Array[String]
	# 如果有传承卡，加入牌组
	if legacy_card != "":
		player_deck.append(legacy_card)
	available_pool = []
	for card_path in ALL_CARD_PATHS:
		if card_path not in player_deck:
			available_pool.append(card_path)
	current_node_index = 0
	player_hp = 30
	player_max_hp = 30
	player_gold = 50
	yin_count = 0
	yang_count = 0
	battles_won = 0
	story_alignment = 0
	_init_map_nodes()

## 初始化地图节点
func _init_map_nodes() -> void:
	map_nodes = [
		{"name": "欲望街·外围", "type": "battle", "enemy": "grunt", "completed": false},
		{"name": "扭曲塔·入口", "type": "event_then_battle", "enemy": "elite", "completed": false},
		{"name": "道墟遗迹·深层", "type": "battle", "enemy": "elite2", "completed": false},
		{"name": "核心·旧我的领域", "type": "boss", "enemy": "boss", "completed": false},
	]

## 获取当前节点数据
func get_current_node() -> Dictionary:
	if current_node_index < map_nodes.size():
		return map_nodes[current_node_index]
	return {}

## 推进到下一个节点
func advance_node() -> void:
	if current_node_index < map_nodes.size():
		map_nodes[current_node_index]["completed"] = true
	current_node_index += 1

## 阴阳差值
func get_yinyang_diff() -> int:
	return abs(yin_count - yang_count)

## 是否触发道境共鸣
func is_dao_resonance() -> bool:
	return get_yinyang_diff() <= 2 and (yin_count + yang_count) > 0

## 是否触发心魔反噬
func is_demon_backlash() -> bool:
	return get_yinyang_diff() >= 4

## 重置阴阳计数（每场战斗开始时）
func reset_yinyang() -> void:
	yin_count = 0
	yang_count = 0

## 保存游戏
func save_game() -> void:
	var data := {
		"player_deck": player_deck,
		"legacy_card": legacy_card,
		"current_node_index": current_node_index,
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"player_gold": player_gold,
		"battles_won": battles_won,
		"story_alignment": story_alignment,
		"run_number": run_number,
		"achievements": achievements,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))

## 加载游戏
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		return false
	var data: Dictionary = json.data
	player_deck.assign(data.get("player_deck", STARTER_DECK))
	legacy_card = data.get("legacy_card", "")
	current_node_index = data.get("current_node_index", 0)
	player_hp = data.get("player_hp", 30)
	player_max_hp = data.get("player_max_hp", 30)
	player_gold = data.get("player_gold", 50)
	battles_won = data.get("battles_won", 0)
	story_alignment = data.get("story_alignment", 0)
	run_number = data.get("run_number", 1)
	var ach: Dictionary = data.get("achievements", {}) as Dictionary
	for key in ach:
		if key in achievements:
			achievements[key] = ach[key]
	_init_map_nodes()
	for i in range(current_node_index):
		if i < map_nodes.size():
			map_nodes[i]["completed"] = true
	return true

## 设置传承卡并开启新轮
func start_new_run_with_legacy(card_path: String) -> void:
	legacy_card = card_path
	run_number += 1
	save_game()
	start_new_game()
