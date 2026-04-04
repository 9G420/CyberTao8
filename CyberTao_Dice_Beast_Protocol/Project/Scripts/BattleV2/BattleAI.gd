extends Node
class_name BattleAI

var board_manager: Node
var unit_manager: Node
var action_resolver: Node

## 获取所有敌方单位 ID
func get_enemy_units() -> Array[String]:
	var result: Array[String] = []
	for uid in unit_manager.units_by_id.keys():
		var state: Dictionary = unit_manager.units_by_id[uid]
		if String(state.get("owner", "")) == "enemy":
			result.append(String(uid))
	return result

## 查找距离指定格子最近的玩家单位所在格
func find_nearest_player_cell(from_cell: Vector2i) -> Vector2i:
	var best_cell: Vector2i = Vector2i(-1, -1)
	var best_dist: int = 9999
	for uid in unit_manager.units_by_id.keys():
		var state: Dictionary = unit_manager.units_by_id[uid]
		if String(state.get("owner", "")) != "player":
			continue
		var cell: Vector2i = state["cell"]
		var dist: int = absi(cell.x - from_cell.x) + absi(cell.y - from_cell.y)
		if dist < best_dist:
			best_dist = dist
			best_cell = cell
	return best_cell

func find_priority_player_cell(from_cell: Vector2i) -> Vector2i:
	var taunt_cell: Vector2i = _find_nearest_player_cell_with_tag(from_cell, "taunt")
	if taunt_cell.x >= 0:
		return taunt_cell
	var best_cell: Vector2i = Vector2i(-1, -1)
	var best_score: int = 999999
	for uid in unit_manager.units_by_id.keys():
		var state: Dictionary = unit_manager.units_by_id[uid]
		if String(state.get("owner", "")) != "player":
			continue
		var cell: Vector2i = state["cell"]
		var dist: int = absi(cell.x - from_cell.x) + absi(cell.y - from_cell.y)
		var hp: int = max(1, int(state.get("hp", 1)))
		var is_hero: bool = _is_hero_unit(String(uid), state)
		var score: int = dist * 10 + hp
		if not is_hero:
			score += 60
		if score < best_score:
			best_score = score
			best_cell = cell
	return best_cell

func find_priority_enemy_destination(from_cell: Vector2i) -> Vector2i:
	var node_target: Vector2i = find_priority_control_node_for_enemy(from_cell)
	if node_target.x >= 0:
		return node_target
	return find_priority_player_cell(from_cell)

func find_priority_control_node_for_enemy(from_cell: Vector2i) -> Vector2i:
	if board_manager == null:
		return Vector2i(-1, -1)
	if not board_manager.has_method("get_control_node_owner"):
		return Vector2i(-1, -1)
	var best_cell: Vector2i = Vector2i(-1, -1)
	var best_score: int = 999999
	for cell in board_manager.control_nodes.keys():
		var owner: String = String(board_manager.get_control_node_owner(cell))
		if owner == "enemy":
			continue
		var dist: int = absi(cell.x - from_cell.x) + absi(cell.y - from_cell.y)
		var score: int = dist * 10
		if owner == "player":
			score -= 25
		if score < best_score:
			best_score = score
			best_cell = cell
	return best_cell

## 获取相邻格中包含玩家单位的格子列表
func get_adjacent_player_cells(from_cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if board_manager == null or unit_manager == null:
		return result
	var neighbors: Array[Vector2i] = board_manager.get_neighbors(from_cell)
	for nb in neighbors:
		if not unit_manager.units_by_cell.has(nb):
			continue
		var uid: String = String(unit_manager.units_by_cell[nb])
		var state: Dictionary = unit_manager.get_unit(uid)
		if String(state.get("owner", "")) == "player":
			result.append(nb)
	return result

func pick_best_adjacent_target_cell(from_cell: Vector2i) -> Vector2i:
	var adjacent: Array[Vector2i] = get_adjacent_player_cells(from_cell)
	var taunt_targets: Array[Vector2i] = []
	for cell in adjacent:
		var uid_t: String = String(unit_manager.units_by_cell.get(cell, ""))
		if uid_t == "":
			continue
		var state_t: Dictionary = unit_manager.get_unit(uid_t)
		if _has_tag(state_t, "taunt"):
			taunt_targets.append(cell)
	if not taunt_targets.is_empty():
		return _pick_lowest_hp_cell(taunt_targets)
	return _pick_lowest_hp_cell(adjacent)

func _pick_lowest_hp_cell(cells: Array[Vector2i]) -> Vector2i:
	var best_cell: Vector2i = Vector2i(-1, -1)
	var best_score: int = 999999
	for cell in cells:
		var uid: String = String(unit_manager.units_by_cell.get(cell, ""))
		if uid == "":
			continue
		var state: Dictionary = unit_manager.get_unit(uid)
		if state.is_empty():
			continue
		var hp: int = max(1, int(state.get("hp", 1)))
		var is_hero: bool = _is_hero_unit(uid, state)
		var score: int = hp
		if not is_hero:
			score += 50
		if score < best_score:
			best_score = score
			best_cell = cell
	return best_cell

## 选择一个朝目标方向移动的最优相邻空格
func pick_move_toward(from_cell: Vector2i, target_cell: Vector2i) -> Vector2i:
	var best_cell: Vector2i = Vector2i(-1, -1)
	var best_dist: int = absi(target_cell.x - from_cell.x) + absi(target_cell.y - from_cell.y)
	if board_manager == null:
		return best_cell
	var neighbors: Array[Vector2i] = board_manager.get_neighbors(from_cell)
	for nb in neighbors:
		if board_manager.occupied_cells.has(nb):
			continue
		var dist: int = absi(target_cell.x - nb.x) + absi(target_cell.y - nb.y)
		if dist < best_dist:
			best_dist = dist
			best_cell = nb
	return best_cell

func _is_hero_unit(unit_id: String, state: Dictionary) -> bool:
	if unit_manager != null and unit_manager.has_method("is_player_hero_unit"):
		return bool(unit_manager.is_player_hero_unit(unit_id))
	var tags: Array = state.get("tags", [])
	return not tags.has("summoned")

func _has_tag(state: Dictionary, tag_name: String) -> bool:
	if state.is_empty():
		return false
	var tags: Array = state.get("tags", [])
	return tags.has(tag_name)

func _find_nearest_player_cell_with_tag(from_cell: Vector2i, tag_name: String) -> Vector2i:
	var best_cell: Vector2i = Vector2i(-1, -1)
	var best_dist: int = 9999
	for uid in unit_manager.units_by_id.keys():
		var state: Dictionary = unit_manager.units_by_id[uid]
		if String(state.get("owner", "")) != "player":
			continue
		if not _has_tag(state, tag_name):
			continue
		var cell: Vector2i = state["cell"]
		var dist: int = absi(cell.x - from_cell.x) + absi(cell.y - from_cell.y)
		if dist < best_dist:
			best_dist = dist
			best_cell = cell
	return best_cell
