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

## 当前地图节点索引（兼容旧接口：已经过的节点总数）
var current_node_index: int = 0

## 最大节点数（兼容旧接口：总层数）
const MAX_NODES := 15

# ── 新地图系统 (STS式15层多分支) ──
## map_graph[floor_idx] = Array of node dicts
##   每个node: {type, col, connections: Array[int], enemy, name, completed}
var map_graph: Array = []
## 玩家当前所在层 (-1=尚未进入地图)
var map_current_floor: int = -1
## 玩家在当前层选择的节点索引 (-1=未选)
var map_current_node: int = -1
## 已走过的路径: [{floor, node}]
var map_visited_path: Array = []

## 层数
const MAP_FLOORS := 15
## 列数(列位置0-6)
const MAP_COLUMNS := 7

## 节点类型常量
const NT_BATTLE := "battle"
const NT_ELITE := "elite"
const NT_REST := "rest"
const NT_SHOP := "shop"
const NT_EVENT := "event"
const NT_TREASURE := "treasure"
const NT_BOSS := "boss"

## 敌人类型映射（节点类型→敌人key）
const ENEMY_FOR_TYPE: Dictionary = {
	"battle": "grunt",
	"elite": "elite",
	"boss": "boss",
}

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

## 地图节点数据 (兼容旧接口，不再直接使用)
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
	generate_map()

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
	map_current_floor = -1
	map_current_node = -1
	map_visited_path = []
	generate_map()

# ============================================================
# 地图生成系统 (STS式15层多分支)
# ============================================================

## 节点名称表
const FLOOR_NAMES: Array[String] = [
	"数据街·外围", "欲望街·小巷", "扭曲塔·底层",
	"回路废墟", "暗网节点", "守护者领域",
	"数据修道院", "虚空驿站", "道墟遗迹·入口",
	"扭曲镜廊", "深层算力场", "暗码商铺",
	"寂灭休憩所", "核心·外廊", "核心·旧我的领域",
]

## 生成完整地图
func generate_map() -> void:
	map_graph = []
	for _f in range(MAP_FLOORS):
		var floor_nodes: Array = []
		map_graph.append(floor_nodes)

	# ── 第0层: 起始 (2-3个战斗节点) ──
	var start_count: int = randi_range(2, 3)
	var start_cols: Array[int] = _pick_columns(start_count)
	for col in start_cols:
		map_graph[0].append(_make_node(NT_BATTLE, col, 0))

	# ── 第14层: Boss (1个节点，中央) ──
	map_graph[14].append(_make_node(NT_BOSS, 3, 14))

	# ── 第1-13层: 按规则生成节点类型 ──
	for floor_idx in range(1, 14):
		var node_count: int = randi_range(2, 4)
		var cols: Array[int] = _pick_columns(node_count)
		for col in cols:
			var ntype: String = _pick_node_type(floor_idx)
			map_graph[floor_idx].append(_make_node(ntype, col, floor_idx))

	# ── 生成层间连接 (不交叉) ──
	for floor_idx in range(MAP_FLOORS - 1):
		_generate_connections(floor_idx)

	# ── 确保所有节点都至少有一条来路 (除了第0层) ──
	for floor_idx in range(1, MAP_FLOORS):
		_ensure_reachability(floor_idx)

	# 兼容旧接口: 也更新 map_nodes
	_sync_legacy_map_nodes()

## 创建单个节点
func _make_node(ntype: String, col: int, floor_idx: int) -> Dictionary:
	var enemy_key: String = ""
	if ntype == NT_BATTLE:
		# 随机选普通怪类型
		var grunt_types: Array[String] = ["grunt", "grunt2", "grunt3"]
		enemy_key = grunt_types[randi() % grunt_types.size()]
	elif ntype == NT_ELITE:
		# 随机选精英类型
		var elite_types: Array[String] = ["elite", "elite2"]
		enemy_key = elite_types[randi() % elite_types.size()]
	elif ntype == NT_BOSS:
		enemy_key = "boss"

	var floor_name: String = FLOOR_NAMES[floor_idx] if floor_idx < FLOOR_NAMES.size() else "未知区域"
	var connections: Array[int] = []
	return {
		"type": ntype,
		"col": col,
		"connections": connections,
		"enemy": enemy_key,
		"name": floor_name,
		"completed": false,
	}

## 根据层数选取节点类型 (STS风格分布)
func _pick_node_type(floor_idx: int) -> String:
	# 精英层: 5-6, 10-11
	# 休息层: 7, 12
	# 商店层: 3, 9
	# 宝箱: 8 (稀有)
	# 事件: 散布其余层
	var roll: float = randf()
	match floor_idx:
		1, 2:
			# 前期以战斗为主，少量事件
			if roll < 0.75: return NT_BATTLE
			return NT_EVENT
		3:
			# 商店层
			if roll < 0.4: return NT_SHOP
			if roll < 0.7: return NT_BATTLE
			return NT_EVENT
		4:
			if roll < 0.6: return NT_BATTLE
			if roll < 0.85: return NT_EVENT
			return NT_ELITE
		5, 6:
			# 精英层
			if roll < 0.35: return NT_ELITE
			if roll < 0.65: return NT_BATTLE
			return NT_EVENT
		7:
			# 休息层
			if roll < 0.45: return NT_REST
			if roll < 0.7: return NT_BATTLE
			return NT_EVENT
		8:
			# 宝箱/中场
			if roll < 0.3: return NT_TREASURE
			if roll < 0.55: return NT_BATTLE
			if roll < 0.75: return NT_REST
			return NT_ELITE
		9:
			# 商店层
			if roll < 0.35: return NT_SHOP
			if roll < 0.7: return NT_BATTLE
			return NT_EVENT
		10, 11:
			# 后期精英层
			if roll < 0.4: return NT_ELITE
			if roll < 0.7: return NT_BATTLE
			return NT_EVENT
		12:
			# 后期休息
			if roll < 0.5: return NT_REST
			if roll < 0.8: return NT_BATTLE
			return NT_SHOP
		13:
			# Boss前夕
			if roll < 0.5: return NT_ELITE
			if roll < 0.75: return NT_BATTLE
			return NT_REST
		_:
			return NT_BATTLE

## 从MAP_COLUMNS个列位置中随机选count个，排序返回
func _pick_columns(count: int) -> Array[int]:
	var all_cols: Array[int] = []
	for i in range(MAP_COLUMNS):
		all_cols.append(i)
	all_cols.shuffle()
	var picked: Array[int] = []
	for i in range(mini(count, MAP_COLUMNS)):
		picked.append(all_cols[i])
	picked.sort()
	return picked

## 生成从floor_idx到floor_idx+1的连接 (不交叉规则)
func _generate_connections(floor_idx: int) -> void:
	var cur_floor: Array = map_graph[floor_idx]
	var next_floor: Array = map_graph[floor_idx + 1]
	if cur_floor.is_empty() or next_floor.is_empty():
		return

	# 按列排序确保连线不交叉
	cur_floor.sort_custom(func(a, b): return a["col"] < b["col"])
	next_floor.sort_custom(func(a, b): return a["col"] < b["col"])

	# 每个当前层节点连接到最近的1-2个下层节点
	for i in range(cur_floor.size()):
		var node: Dictionary = cur_floor[i]
		var my_col: int = node["col"]
		# 找到最近的下层节点
		var best_idx: int = _find_nearest_node(my_col, next_floor)
		if best_idx >= 0:
			if best_idx not in node["connections"]:
				node["connections"].append(best_idx)

		# 概率连接第二个邻近节点
		if randf() < 0.5 and next_floor.size() > 1:
			var second: int = -1
			if best_idx > 0 and randf() < 0.5:
				second = best_idx - 1
			elif best_idx < next_floor.size() - 1:
				second = best_idx + 1
			elif best_idx > 0:
				second = best_idx - 1
			if second >= 0 and second not in node["connections"]:
				# 检查不交叉: 不能连到比右边邻居的连接更靠右的节点
				var ok := true
				if i > 0:
					var left_conns: Array = cur_floor[i - 1]["connections"]
					for lc in left_conns:
						if lc > second:
							ok = false
							break
				if i < cur_floor.size() - 1:
					var right_conns: Array = cur_floor[i + 1]["connections"]
					for rc in right_conns:
						if rc < second:
							ok = false
							break
				if ok:
					node["connections"].append(second)

		# 排序连接索引
		node["connections"].sort()

## 找到next_floor中col最接近my_col的节点索引
func _find_nearest_node(my_col: int, next_floor: Array) -> int:
	var best: int = 0
	var best_dist: int = 999
	for i in range(next_floor.size()):
		var dist: int = abs(next_floor[i]["col"] - my_col)
		if dist < best_dist:
			best_dist = dist
			best = i
	return best

## 确保floor_idx层的每个节点至少被上层某个节点连接
func _ensure_reachability(floor_idx: int) -> void:
	var prev_floor: Array = map_graph[floor_idx - 1]
	var cur_floor: Array = map_graph[floor_idx]

	for ni in range(cur_floor.size()):
		var has_incoming := false
		for pn in prev_floor:
			if ni in pn["connections"]:
				has_incoming = true
				break
		if not has_incoming and not prev_floor.is_empty():
			# 找最近的上层节点连过来
			var best_parent: int = _find_nearest_node(cur_floor[ni]["col"], prev_floor)
			if best_parent >= 0:
				if ni not in prev_floor[best_parent]["connections"]:
					prev_floor[best_parent]["connections"].append(ni)
					prev_floor[best_parent]["connections"].sort()

## 同步到旧的map_nodes字段 (兼容)
func _sync_legacy_map_nodes() -> void:
	map_nodes = []
	# 将当前层节点转为旧格式
	if map_current_floor >= 0 and map_current_floor < map_graph.size():
		if map_current_node >= 0 and map_current_node < map_graph[map_current_floor].size():
			var node: Dictionary = map_graph[map_current_floor][map_current_node]
			var legacy_type: String = node["type"]
			# event_then_battle 兼容
			if legacy_type == NT_EVENT:
				legacy_type = "event_then_battle"
			map_nodes = [node]

## 获取当前节点数据 (兼容旧接口)
func get_current_node() -> Dictionary:
	if map_current_floor >= 0 and map_current_floor < map_graph.size():
		if map_current_node >= 0 and map_current_node < map_graph[map_current_floor].size():
			return map_graph[map_current_floor][map_current_node]
	return {}

## 推进到下一个节点 (兼容旧接口 — 标记当前完成，前进一层)
func advance_node() -> void:
	if map_current_floor >= 0 and map_current_floor < map_graph.size():
		if map_current_node >= 0 and map_current_node < map_graph[map_current_floor].size():
			map_graph[map_current_floor][map_current_node]["completed"] = true
	current_node_index += 1

## 选择地图节点 (Map.gd调用)
func select_map_node(floor_idx: int, node_idx: int) -> void:
	map_current_floor = floor_idx
	map_current_node = node_idx
	map_visited_path.append({"floor": floor_idx, "node": node_idx})
	_sync_legacy_map_nodes()

## 获取当前层可到达的下一层节点索引列表
func get_reachable_next_nodes() -> Array[int]:
	var result: Array[int] = []
	if map_current_floor < 0 or map_current_floor >= map_graph.size():
		return result
	if map_current_node < 0 or map_current_node >= map_graph[map_current_floor].size():
		return result
	var node: Dictionary = map_graph[map_current_floor][map_current_node]
	for c in node["connections"]:
		result.append(c as int)
	return result

## 地图是否完成(到达Boss层并完成)
func is_map_complete() -> bool:
	if map_current_floor == MAP_FLOORS - 1:
		var node: Dictionary = get_current_node()
		return node.get("completed", false)
	return false

## 获取下一个可进入的层 (-1 = 初始状态，可进入第0层)
func get_next_floor() -> int:
	if map_current_floor < 0:
		return 0
	return map_current_floor + 1

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
		"map_graph": map_graph,
		"map_current_floor": map_current_floor,
		"map_current_node": map_current_node,
		"map_visited_path": map_visited_path,
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
	# 加载新地图数据
	var saved_graph: Array = data.get("map_graph", [])
	if saved_graph.size() == MAP_FLOORS:
		map_graph = saved_graph
		map_current_floor = data.get("map_current_floor", -1) as int
		map_current_node = data.get("map_current_node", -1) as int
		map_visited_path = data.get("map_visited_path", [])
		_sync_legacy_map_nodes()
	else:
		# 旧存档或损坏，重新生成
		generate_map()
	return true

## 设置传承卡并开启新轮
func start_new_run_with_legacy(card_path: String) -> void:
	legacy_card = card_path
	run_number += 1
	start_new_game()
	save_game()  # 保存重置后的状态（而非重置前的旧状态）
