extends Node
class_name FloorManager

## 多层地图管理器（v0.1.76 — 从 BattleFlowController 剥离）
## 负责：层间推进、HP 快照/复活/回复、Boss 解锁/传送、传送门生成/检测
## 信号通过 BattleFlowController 转发（FloorManager 不直接暴露信号给 Main）

const UnitData = preload("res://Scripts/Data/UnitData.gd")
const BoardGenerator = preload("res://Scripts/BattleV2/BoardGenerator.gd")
const VictoryRuleHelper = preload("res://Scripts/BattleV2/VictoryRuleHelper.gd")

# --- 常量 ---
const MAX_FLOOR: int = 3
const REVIVE_HP_RATIO: float = 0.5		# 阵亡复活 HP 比例
const FLOOR_HEAL_RATIO: float = 0.3	# 存活跨层回复比例

# --- 外部引用（由 BFC._bootstrap 注入）---
var dice_manager: Node = null
var board_manager: Node = null
var unit_manager: Node = null
var buff_manager: Node = null

# --- 状态 ---
var current_floor: int = 1

# ============================
#  层间推进
# ============================

## 获取存活玩家单位的 HP 快照（用于跨层保留）
func snapshot_player_hp() -> Dictionary:
	var snapshot: Dictionary = {}
	var player_ids: Array[String] = unit_manager.get_player_units()
	for uid in player_ids:
		var unit: Dictionary = unit_manager.get_unit(uid)
		if not unit.is_empty() and int(unit.get("hp", 0)) > 0:
			snapshot[uid] = {"hp": int(unit["hp"]), "max_hp": int(unit["max_hp"]), "alive": true}
	return snapshot

## 执行层间推进（BFC 调用，返回新层数）
func advance_floor(board_size: Vector2i, summon_counter_reset: Callable) -> int:
	var hp_snapshot: Dictionary = snapshot_player_hp()
	# 清理当前层
	dice_manager.reset_for_battle()
	buff_manager.clear_all()
	unit_manager.clear_all_units()
	board_manager.clear_board()
	board_manager.build_test_board(board_size)
	summon_counter_reset.call()
	# 递增层数
	current_floor += 1
	# 重新生成玩家单位（含阵亡复活 + 存活回复）
	_spawn_player_units_with_hp(hp_snapshot)
	# 生成新棋盘布局
	BoardGenerator.generate_board(board_manager, unit_manager, board_size, current_floor)
	return current_floor

## 带 HP 快照生成玩家单位（阵亡复活 + 存活回复）
func _spawn_player_units_with_hp(hp_snapshot: Dictionary) -> void:
	var spawn_data: Array[Dictionary] = [
		{"path": "res://Data/Units/blade_shield_dog.tres", "cell": Vector2i(0, 10)},
	]
	for entry in spawn_data:
		var data := load(String(entry["path"])) as UnitData
		if data == null:
			continue
		var spawn_hp: int = 0
		var spawn_max_hp: int = data.max_hp
		if hp_snapshot.has(data.unit_id):
			var saved: Dictionary = hp_snapshot[data.unit_id]
			spawn_max_hp = int(saved["max_hp"])
			var heal_amount: int = int(ceil(float(spawn_max_hp) * FLOOR_HEAL_RATIO))
			spawn_hp = mini(int(saved["hp"]) + heal_amount, spawn_max_hp)
		else:
			spawn_hp = maxi(int(ceil(float(spawn_max_hp) * REVIVE_HP_RATIO)), 1)
		unit_manager.spawn_unit(data.unit_id, {
			"max_hp": spawn_max_hp, "atk": data.atk, "def": data.def,
			"move_range": data.move_range, "attack_range": data.attack_range,
			"owner": "player", "tags": data.meme_tags,
			"terrain_affinity": data.terrain_affinity, "display_name": data.unit_name,
		}, entry["cell"])
		var unit: Dictionary = unit_manager.get_unit(data.unit_id)
		if not unit.is_empty():
			unit["hp"] = spawn_hp
			unit_manager.units_by_id[data.unit_id] = unit

func get_current_floor() -> int:
	return current_floor

func get_max_floor() -> int:
	return MAX_FLOOR

func reset_floor() -> void:
	current_floor = 1

# ============================
#  Boss 解锁 & 传送
# ============================

## 尝试解锁所有 Boss 遭遇格，返回解锁的格子列表
func try_unlock_boss() -> Array[Vector2i]:
	var cells_to_unlock: Array[Vector2i] = []
	for cell in board_manager.locked_encounters.keys():
		cells_to_unlock.append(cell)
	for cell in cells_to_unlock:
		board_manager.unlock_encounter(cell)
	return cells_to_unlock

## Boss 解锁后，将英雄单位传送到 Boss 格旁边的空格，返回目标格（空串=失败）
func warp_hero_to_boss(boss_cell: Vector2i) -> Dictionary:
	var hero_id: String = ""
	for uid in unit_manager.units_by_id.keys():
		var u: Dictionary = unit_manager.get_unit(String(uid))
		if String(u.get("owner", "")) != "player":
			continue
		var tags: Array = u.get("tags", [])
		if not tags.has("summoned"):
			hero_id = String(uid)
			break
	if hero_id == "":
		return {}
	var dirs: Array[Vector2i] = [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]
	for dir in dirs:
		var adj: Vector2i = boss_cell + dir
		if adj.x < 0 or adj.x >= board_manager.board_size.x or adj.y < 0 or adj.y >= board_manager.board_size.y:
			continue
		if board_manager.occupied_cells.has(adj):
			continue
		unit_manager.move_unit(hero_id, adj)
		return {"hero_id": hero_id, "target_cell": adj}
	return {}

# ============================
#  传送门
# ============================

## 在指定格子附近生成传送门，返回传送门格子
func spawn_portal_near(cell: Vector2i) -> Vector2i:
	var candidates: Array[Vector2i] = [
		cell + Vector2i(0, 1), cell + Vector2i(1, 0),
		cell + Vector2i(-1, 0), cell + Vector2i(0, -1),
	]
	for c in candidates:
		if board_manager.is_in_bounds(c) and not board_manager.occupied_cells.has(c):
			board_manager.add_portal_cell(c)
			return c
	board_manager.add_portal_cell(cell)
	return cell

## 检查玩家是否踩上传送门，返回结果字典（空=未踩）
func check_portal(unit_id: String, cell: Vector2i) -> Dictionary:
	if not board_manager.portal_cells.has(cell):
		return {}
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if unit.is_empty() or String(unit.get("owner", "")) != "player":
		return {}
	board_manager.clear_portal_cell(cell)
	if current_floor < MAX_FLOOR:
		return {"action": "floor_clear"}
	else:
		return {"action": "game_won"}
