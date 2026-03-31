extends RefCounted
class_name BoardGenerator

## 棋盘随机生成器（Day 17：程序化布局）
## 从固定 debug 布局升级为每局随机生成
## 纯静态工具类，不持有状态，不修改 BFC 逻辑

# --- 生成参数 ---
const ENCOUNTER_COUNT_MIN: int = 3
const ENCOUNTER_COUNT_MAX: int = 4
const HIGH_GROUND_COUNT_MIN: int = 2
const HIGH_GROUND_COUNT_MAX: int = 3
const TRAP_COUNT_MIN: int = 2
const TRAP_COUNT_MAX: int = 3
const ITEM_COUNT: int = 2
const HEAL_COUNT: int = 2
const EVENT_COUNT_MIN: int = 2
const EVENT_COUNT_MAX: int = 3
const SHOP_COUNT: int = 1
const CHEST_COUNT_MIN: int = 1
const CHEST_COUNT_MAX: int = 2
const ENEMY_COUNT: int = 2

# 可用遭遇 ID 池
const ENCOUNTER_IDS: Array[String] = [
	"encounter_01", "encounter_02", "encounter_03",
	"encounter_04", "encounter_05",
]

# Boss 遭遇 ID 池（每局放置 1 个）
const BOSS_ENCOUNTER_IDS: Array[String] = [
	"encounter_boss_01",
]

# 可用道具 ID 池
const ITEM_IDS: Array[String] = [
	"patch_tea_cache", "overclock_bone",
]

# 玩家出生区域（左下角 3x3），不放置危险格子
const PLAYER_ZONE_COLS: int = 2  # col 0~1
const PLAYER_ZONE_ROWS_START: int = 5  # row 5~7

## 生成完整棋盘布局（地形+道具+遭遇+恢复+事件+敌方单位）
## 玩家单位由 BFC 单独生成（需要加载 .tres 资源）
## current_floor：当前层数（1起），影响敌方单位数值缩放
static func generate_board(board_mgr: Node, unit_mgr: Node, board_size: Vector2i, current_floor: int = 1) -> void:
	var used_cells: Dictionary = {}  # cell -> true，防止重叠
	# 标记玩家单位初始位置为已占用
	_mark_player_spawn_cells(used_cells)
	# 1. 地形：高台
	var high_count: int = _rand_range(HIGH_GROUND_COUNT_MIN, HIGH_GROUND_COUNT_MAX)
	var high_cells: Array[Vector2i] = _pick_random_cells(board_size, high_count, used_cells, false)
	for cell in high_cells:
		board_mgr.add_terrain_cell(cell, "high_ground")
		used_cells[cell] = true
	# 2. 地形：陷阱（不在玩家出生区）
	var trap_count: int = _rand_range(TRAP_COUNT_MIN, TRAP_COUNT_MAX)
	var trap_cells: Array[Vector2i] = _pick_random_cells(board_size, trap_count, used_cells, true)
	for cell in trap_cells:
		board_mgr.add_terrain_cell(cell, "trap")
		used_cells[cell] = true
	# 3. 道具
	var item_cells: Array[Vector2i] = _pick_random_cells(board_size, ITEM_COUNT, used_cells, false)
	for i in range(item_cells.size()):
		var item_id: String = ITEM_IDS[i % ITEM_IDS.size()]
		board_mgr.add_item_cell(item_cells[i], item_id)
		used_cells[item_cells[i]] = true
	# 4. 遭遇格（不在玩家出生区，分散放置）
	var enc_count: int = _rand_range(ENCOUNTER_COUNT_MIN, ENCOUNTER_COUNT_MAX)
	var enc_cells: Array[Vector2i] = _pick_random_cells(board_size, enc_count, used_cells, true)
	var shuffled_enc_ids: Array[String] = _shuffle_strings(ENCOUNTER_IDS.duplicate())
	for i in range(enc_cells.size()):
		var enc_id: String = shuffled_enc_ids[i % shuffled_enc_ids.size()]
		board_mgr.add_encounter_cell(enc_cells[i], enc_id)
		used_cells[enc_cells[i]] = true
	# 4b. Boss 遭遇格（1 个，放置在远离玩家出生区的上半区域）
	var boss_cells: Array[Vector2i] = _pick_boss_cell(board_size, used_cells)
	if boss_cells.size() > 0:
		var boss_id: String = BOSS_ENCOUNTER_IDS[randi() % BOSS_ENCOUNTER_IDS.size()]
		board_mgr.add_encounter_cell(boss_cells[0], boss_id)
		board_mgr.lock_encounter(boss_cells[0])
		used_cells[boss_cells[0]] = true
	# 5. 恢复格
	var heal_cells: Array[Vector2i] = _pick_random_cells(board_size, HEAL_COUNT, used_cells, false)
	for cell in heal_cells:
		var heal_amount: int = 2 + (randi() % 2)  # 2 或 3
		board_mgr.add_heal_cell(cell, heal_amount)
		used_cells[cell] = true
	# 6. 事件格（不在玩家出生区）
	var event_count: int = _rand_range(EVENT_COUNT_MIN, EVENT_COUNT_MAX)
	var event_cells: Array[Vector2i] = _pick_random_cells(board_size, event_count, used_cells, true)
	for cell in event_cells:
		board_mgr.add_event_cell(cell, "random_event")
		used_cells[cell] = true
	# 7. 商店格（不在玩家出生区，持久，回复 3 HP，消耗 1 move crest）
	var shop_cells: Array[Vector2i] = _pick_random_cells(board_size, SHOP_COUNT, used_cells, true)
	for cell in shop_cells:
		board_mgr.add_shop_cell(cell, 3)
		used_cells[cell] = true
	# 8. 宝箱格（不在玩家出生区，一次性随机奖励）
	var chest_count: int = _rand_range(CHEST_COUNT_MIN, CHEST_COUNT_MAX)
	var chest_cell_list: Array[Vector2i] = _pick_random_cells(board_size, chest_count, used_cells, true)
	for cell in chest_cell_list:
		board_mgr.add_chest_cell(cell, "chest")
		used_cells[cell] = true
	# 9. 敌方单位（上半区域，row 0~4）
	_spawn_enemies(unit_mgr, board_size, used_cells, current_floor)

## 层间难度缩放：返回 {hp_mult, atk_add} 基于当前层数
## 第1层=基准，第2层 HP+30%/ATK+1，第3层 HP+60%/ATK+2
static func _floor_scaling(current_floor: int) -> Dictionary:
	var floor_offset: int = max(0, current_floor - 1)
	return {
		"hp_mult": 1.0 + 0.3 * float(floor_offset),
		"atk_add": floor_offset,
	}

## 生成敌方单位（随机位置，上半区域）
## current_floor 用于数值缩放
static func _spawn_enemies(unit_mgr: Node, board_size: Vector2i, used_cells: Dictionary, current_floor: int = 1) -> void:
	var scaling: Dictionary = _floor_scaling(current_floor)
	var enemy_templates: Array[Dictionary] = [
		{"id": "enemy_grunt_1", "max_hp": 5, "atk": 2, "def": 0, "display_name": "哨兵甲"},
		{"id": "enemy_grunt_2", "max_hp": 4, "atk": 3, "def": 0, "display_name": "哨兵乙"},
	]
	for tmpl in enemy_templates:
		var cell: Vector2i = _pick_enemy_cell(board_size, used_cells)
		if cell.x < 0:
			continue
		var scaled_hp: int = int(ceil(float(int(tmpl["max_hp"])) * float(scaling["hp_mult"])))
		var scaled_atk: int = int(tmpl["atk"]) + int(scaling["atk_add"])
		var data: Dictionary = {
			"max_hp": scaled_hp,
			"atk": scaled_atk,
			"def": int(tmpl["def"]),
			"move_range": 1,
			"attack_range": 1,
			"owner": "enemy",
			"tags": ["grunt"],
			"display_name": String(tmpl["display_name"]),
		}
		unit_mgr.spawn_unit(String(tmpl["id"]), data, cell)
		used_cells[cell] = true

## 为 Boss 遭遇选择一个格子（远离玩家出生区，优先上半右侧）
static func _pick_boss_cell(board_size: Vector2i, used_cells: Dictionary) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	# 优先选择右上象限（col >= 4, row <= 3）
	for y in range(0, board_size.y / 2):
		for x in range(board_size.x / 2, board_size.x):
			var c: Vector2i = Vector2i(x, y)
			if not used_cells.has(c):
				candidates.append(c)
	# 如果右上象限无空位，扩大到整个上半区
	if candidates.is_empty():
		for y in range(0, board_size.y / 2):
			for x in range(0, board_size.x):
				var c: Vector2i = Vector2i(x, y)
				if not used_cells.has(c):
					candidates.append(c)
	if candidates.is_empty():
		return []
	var picked: Vector2i = candidates[randi() % candidates.size()]
	return [picked]

## 在上半区域（row 0 ~ board_size.y/2）随机选一个空闲格
static func _pick_enemy_cell(board_size: Vector2i, used_cells: Dictionary) -> Vector2i:
	var candidates: Array[Vector2i] = []
	var max_row: int = board_size.y / 2
	for y in range(0, max_row):
		for x in range(0, board_size.x):
			var c: Vector2i = Vector2i(x, y)
			if not used_cells.has(c):
				candidates.append(c)
	if candidates.is_empty():
		return Vector2i(-1, -1)
	return candidates[randi() % candidates.size()]

## 标记玩家单位初始位置为已占用
static func _mark_player_spawn_cells(used_cells: Dictionary) -> void:
	used_cells[Vector2i(0, 6)] = true  # 刀盾狗
	used_cells[Vector2i(1, 7)] = true  # 灵狐骇客
	used_cells[Vector2i(0, 5)] = true  # 鸦机术士

## 随机选取 count 个不重叠的格子
## avoid_player_zone=true 时排除玩家出生区域
static func _pick_random_cells(board_size: Vector2i, count: int, used_cells: Dictionary, avoid_player_zone: bool) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for y in range(board_size.y):
		for x in range(board_size.x):
			var c: Vector2i = Vector2i(x, y)
			if used_cells.has(c):
				continue
			if avoid_player_zone and _is_player_zone(c):
				continue
			candidates.append(c)
	# Fisher-Yates 洗牌后取前 count 个
	for i in range(candidates.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var tmp: Vector2i = candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp
	var result: Array[Vector2i] = []
	var pick: int = min(count, candidates.size())
	for i in range(pick):
		result.append(candidates[i])
	return result

## 判断是否在玩家出生区域
static func _is_player_zone(cell: Vector2i) -> bool:
	return cell.x < PLAYER_ZONE_COLS and cell.y >= PLAYER_ZONE_ROWS_START

## 随机整数 [min_val, max_val]
static func _rand_range(min_val: int, max_val: int) -> int:
	if min_val >= max_val:
		return min_val
	return min_val + (randi() % (max_val - min_val + 1))

## 洗牌字符串数组
static func _shuffle_strings(arr: Array[String]) -> Array[String]:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var tmp: String = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
	return arr
