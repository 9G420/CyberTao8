extends Node
class_name BattleFlowController

signal setup_completed
signal phase_changed(phase_name: String)
signal move_completed(unit_id: String, from_cell: Vector2i, to_cell: Vector2i)
signal attack_completed(attacker_id: String, defender_id: String, damage: int, killed: bool)
signal enemy_attack_completed(attacker_id: String, defender_id: String, damage: int, killed: bool, target_cell: Vector2i)
signal summon_completed(unit_id: String, path_cells_created: Array[Vector2i], spawn_cell: Vector2i)
signal round_changed(round_number: int)
signal terrain_damage_triggered(unit_id: String, cell: Vector2i, damage: int, terrain_type: String)
signal item_picked_up(unit_id: String, item_id: String, effect_text: String, cell: Vector2i)
signal enemy_action_announced(unit_id: String, action_type: String, detail: String)
signal enemy_turn_ended
signal encounter_triggered(unit_id: String, encounter_id: String, cell: Vector2i)
signal encounter_resolved(encounter_id: String, cell: Vector2i)
signal heal_cell_triggered(unit_id: String, cell: Vector2i, heal_amount: int, actual_heal: int)
signal event_cell_triggered(unit_id: String, cell: Vector2i, event_id: String, effect_text: String)
signal defend_crest_used(unit_id: String, new_temp_def: int)
signal skill_crest_used(unit_id: String, heal_amount: int)
signal trick_crest_used(gained_crest: String)
signal shop_panel_requested(unit_id: String, cell: Vector2i)
signal chest_cell_triggered(unit_id: String, cell: Vector2i, effect_text: String)
signal floor_cleared(floor_number: int)
signal game_won
signal boss_unlocked(cell: Vector2i)
signal portal_spawned(cell: Vector2i)
signal hero_warped(unit_id: String, target_cell: Vector2i)
signal enemy_turn_starting(first_enemy_id: String)
signal dice_animation_done
signal move_step_visual(unit_id: String, from_cell: Vector2i, to_cell: Vector2i)
signal move_step_done

const DiceManager = preload("res://Scripts/BattleV2/DiceManager.gd")
const BoardManager = preload("res://Scripts/BattleV2/BoardManager.gd")
const UnitManager = preload("res://Scripts/BattleV2/UnitManager.gd")
const ActionResolver = preload("res://Scripts/BattleV2/ActionResolver.gd")
const BuffManager = preload("res://Scripts/BattleV2/BuffManager.gd")
const BattleAI = preload("res://Scripts/BattleV2/BattleAI.gd")
const AttackRuleHelper = preload("res://Scripts/BattleV2/AttackRuleHelper.gd")
const VictoryRuleHelper = preload("res://Scripts/BattleV2/VictoryRuleHelper.gd")
const UnitData = preload("res://Scripts/Data/UnitData.gd")
const BoardGenerator = preload("res://Scripts/BattleV2/BoardGenerator.gd")
const CrestActionHandler = preload("res://Scripts/BattleV2/CrestActionHandler.gd")
const CellEffectHandler = preload("res://Scripts/BattleV2/CellEffectHandler.gd")
const _FloorManager = preload("res://Scripts/BattleV2/FloorManager.gd")

enum BattlePhase {
	BOOT,
	PLAYER_ROLL,
	PLAYER_ACTION,
	ENCOUNTER,
	ENEMY_ROLL,
	ENEMY_ACTION,
	RESOLUTION,
	FLOOR_CLEAR,
	VICTORY,
	DEFEAT,
}

const BOARD_SIZE: Vector2i = Vector2i(12, 12)	# v0.1.62 扩展棋盘

var current_phase: BattlePhase = BattlePhase.BOOT
var round_index: int = 0
var _summon_counter: int = 0
var _summon_this_floor: int = 0      # 本层已部署次数
const SUMMON_FLOOR_LIMIT: int = 2   # 每层部署上限
const SUMMON_FIELD_LIMIT: int = 1   # 场上伙伴上限
var _encounter_unit_id: String = ""
var _encounter_id: String = ""
var _encounter_cell: Vector2i = Vector2i(-1, -1)

var dice_manager: DiceManager
var board_manager: BoardManager
var unit_manager: UnitManager
var action_resolver: ActionResolver
var buff_manager: BuffManager
var battle_ai: BattleAI
var crest_handler: CrestActionHandler
var cell_effect_handler: CellEffectHandler
var floor_manager: _FloorManager

func _ready() -> void:
	_bootstrap()

func _bootstrap() -> void:
	dice_manager = DiceManager.new()
	board_manager = BoardManager.new()
	unit_manager = UnitManager.new()
	action_resolver = ActionResolver.new()
	buff_manager = BuffManager.new()
	battle_ai = BattleAI.new()
	crest_handler = CrestActionHandler.new()
	cell_effect_handler = CellEffectHandler.new()
	floor_manager = _FloorManager.new()

	add_child(dice_manager)
	add_child(board_manager)
	add_child(unit_manager)
	add_child(action_resolver)
	add_child(buff_manager)
	add_child(battle_ai)
	add_child(crest_handler)
	add_child(cell_effect_handler)
	add_child(floor_manager)

	action_resolver.board_manager = board_manager
	action_resolver.unit_manager = unit_manager
	action_resolver.buff_manager = buff_manager
	unit_manager.board_manager = board_manager
	battle_ai.board_manager = board_manager
	battle_ai.unit_manager = unit_manager
	battle_ai.action_resolver = action_resolver
	crest_handler.unit_manager = unit_manager
	crest_handler.dice_manager = dice_manager
	cell_effect_handler.board_manager = board_manager
	cell_effect_handler.unit_manager = unit_manager
	cell_effect_handler.dice_manager = dice_manager
	cell_effect_handler.buff_manager = buff_manager

	floor_manager.dice_manager = dice_manager
	floor_manager.board_manager = board_manager
	floor_manager.unit_manager = unit_manager
	floor_manager.buff_manager = buff_manager

	board_manager.build_test_board(BOARD_SIZE)
	_spawn_player_units()
	BoardGenerator.generate_board(board_manager, unit_manager, BOARD_SIZE, floor_manager.current_floor)
	dice_manager.set_active_side("player")
	current_phase = BattlePhase.PLAYER_ROLL
	round_index = 1
	emit_signal("setup_completed")
	emit_signal("phase_changed", _phase_name(current_phase))

func is_battle_over() -> bool:
	return current_phase == BattlePhase.VICTORY or current_phase == BattlePhase.DEFEAT or current_phase == BattlePhase.FLOOR_CLEAR

func start_player_roll() -> void:
	if current_phase != BattlePhase.PLAYER_ROLL:
		return
	if is_battle_over():
		return
	dice_manager.set_active_side("player")
	dice_manager.roll_turn_dice()
	current_phase = BattlePhase.PLAYER_ACTION
	emit_signal("phase_changed", _phase_name(current_phase))

func enter_player_action() -> void:
	current_phase = BattlePhase.PLAYER_ACTION
	emit_signal("phase_changed", _phase_name(current_phase))

func start_enemy_roll() -> void:
	current_phase = BattlePhase.ENEMY_ROLL
	dice_manager.set_active_side("enemy")
	dice_manager.roll_turn_dice()
	emit_signal("phase_changed", _phase_name(current_phase))

func enter_enemy_action() -> void:
	current_phase = BattlePhase.ENEMY_ACTION
	emit_signal("phase_changed", _phase_name(current_phase))

func mark_victory() -> void:
	current_phase = BattlePhase.VICTORY
	emit_signal("phase_changed", _phase_name(current_phase))

func mark_defeat() -> void:
	current_phase = BattlePhase.DEFEAT
	emit_signal("phase_changed", _phase_name(current_phase))

func spawn_demo_path() -> void:
	var owner_id: String = "player"
	for x in range(1, 4):
		board_manager.add_path_cell(Vector2i(x, 10), owner_id)

## 从 UnitData 资源生成一个玩家单位（内部辅助）
func _spawn_unit_from_data(res_path: String, cell: Vector2i) -> void:
	var data := load(res_path) as UnitData
	if data:
		unit_manager.spawn_unit(data.unit_id, {
			"max_hp": data.max_hp, "atk": data.atk, "def": data.def,
			"move_range": data.move_range, "attack_range": data.attack_range,
			"owner": "player", "tags": data.meme_tags,
			"terrain_affinity": data.terrain_affinity, "display_name": data.unit_name,
		}, cell)

func _spawn_player_units() -> void:
	if floor_manager != null:
		floor_manager.spawn_initial_player_units()
		return
	_spawn_unit_from_data("res://Data/Units/blade_shield_dog.tres", Vector2i(0, 10))
	_spawn_unit_from_data("res://Data/Units/hacker_fox.tres", Vector2i(1, 11))

# ─── 格子效果薄代理（委托 CellEffectHandler，BFC 负责信号和结算） ───

func _check_terrain_trap(unit_id: String, cell: Vector2i) -> void:
	var r: Dictionary = cell_effect_handler.check_terrain_trap(unit_id, cell)
	if r.get("triggered", false):
		emit_signal("terrain_damage_triggered", unit_id, cell, int(r["damage"]), "trap")
		if bool(r["killed"]):
			_check_battle_outcome()

func _check_item_pickup(unit_id: String, cell: Vector2i) -> void:
	var r: Dictionary = cell_effect_handler.check_item_pickup(unit_id, cell)
	if r.get("picked", false):
		emit_signal("item_picked_up", unit_id, String(r["item_id"]), String(r["effect_text"]), cell)

func _check_heal_cell(unit_id: String, cell: Vector2i) -> void:
	var r: Dictionary = cell_effect_handler.check_heal_cell(unit_id, cell)
	if r.get("healed", false):
		emit_signal("heal_cell_triggered", unit_id, cell, int(r["heal_amount"]), int(r["actual_heal"]))

func _check_event_cell(unit_id: String, cell: Vector2i) -> void:
	var r: Dictionary = cell_effect_handler.check_event_cell(unit_id, cell)
	if r.get("triggered", false):
		emit_signal("event_cell_triggered", unit_id, cell, String(r["event_id"]), String(r["effect_text"]))
		if bool(r.get("killed", false)):
			_check_battle_outcome()

func _check_shop_cell(unit_id: String, cell: Vector2i) -> void:
	if cell_effect_handler.has_valid_shop_cell(unit_id, cell):
		emit_signal("shop_panel_requested", unit_id, cell)

func _check_chest_cell(unit_id: String, cell: Vector2i) -> void:
	var r: Dictionary = cell_effect_handler.check_chest_cell(unit_id, cell)
	if r.get("opened", false):
		emit_signal("chest_cell_triggered", unit_id, cell, String(r["effect_text"]))

# ─── 回合流程 ───

## 结束玩家回合：清空资源池，清除临时防御，进入敌方回合
func end_player_turn() -> void:
	if current_phase != BattlePhase.PLAYER_ACTION:
		return
	if is_battle_over():
		return
	crest_handler.clear_temp_def()
	dice_manager.reset_for_turn()
	_start_enemy_turn()

## 使用护持(DEFEND) crest：选中单位本回合 DEF+1（累加），回合结束清零
func try_use_defend_crest(unit_id: String) -> bool:
	if is_battle_over() or current_phase != BattlePhase.PLAYER_ACTION:
		return false
	var r: Dictionary = crest_handler.try_use_defend(unit_id)
	if r["ok"]:
		emit_signal("defend_crest_used", unit_id, int(r["new_temp_def"]))
	return bool(r["ok"])

## 使用术式(SKILL) crest：选中单位回复 2 HP
func try_use_skill_crest(unit_id: String) -> bool:
	if is_battle_over() or current_phase != BattlePhase.PLAYER_ACTION:
		return false
	var r: Dictionary = crest_handler.try_use_skill(unit_id)
	if r["ok"]:
		emit_signal("skill_crest_used", unit_id, int(r["heal"]))
	return bool(r["ok"])

## 使用机巧(TRICK) crest：转化为 +1 随机实用 crest（步进/杀伐/显化）
func try_use_trick_crest() -> bool:
	if is_battle_over() or current_phase != BattlePhase.PLAYER_ACTION:
		return false
	var r: Dictionary = crest_handler.try_use_trick()
	if r["ok"]:
		emit_signal("trick_crest_used", String(r["gained_crest"]))
	return bool(r["ok"])

## 启动敌方回合：通知相机 → 掷骰 -> 延迟 -> 执行敌方行动
func _start_enemy_turn() -> void:
	var enemy_units: Array[String] = battle_ai.get_enemy_units()
	if enemy_units.is_empty():
		_advance_to_next_player_round()
		return
	# v0.1.64：在掷骰前先通知 UI 将相机移到第一个敌方单位
	emit_signal("enemy_turn_starting", enemy_units[0])
	await get_tree().create_timer(0.5).timeout
	current_phase = BattlePhase.ENEMY_ROLL
	emit_signal("phase_changed", _phase_name(current_phase))
	dice_manager.set_active_side("enemy")
	dice_manager.roll_turn_dice()
	# v0.1.65：等待掷骰动画真正结束（由 Main 转发 dice_animation_done 信号）
	await dice_animation_done
	await get_tree().create_timer(0.3).timeout
	if is_battle_over():
		return
	_execute_enemy_actions()

## 获取单位显示名称（用于意图广播）
func _get_unit_display_name(unit_id: String) -> String:
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	var uname: String = String(unit.get("display_name", ""))
	if uname == "":
		uname = unit_id
	return uname

## 执行敌方行动：遍历每个敌方单位，尝试攻击或移动（含意图广播和加长停顿）
func _execute_enemy_actions() -> void:
	current_phase = BattlePhase.ENEMY_ACTION
	emit_signal("phase_changed", _phase_name(current_phase))
	var enemy_units: Array[String] = battle_ai.get_enemy_units()
	for uid in enemy_units:
		if is_battle_over():
			break
		var unit: Dictionary = unit_manager.get_unit(uid)
		if unit.is_empty():
			continue
		var cell: Vector2i = unit["cell"]
		var unit_name: String = _get_unit_display_name(uid)
		# 优先检查相邻是否有玩家单位可攻击
		var adjacent_players: Array[Vector2i] = battle_ai.get_adjacent_player_cells(cell)
		if adjacent_players.size() > 0 and dice_manager.can_pay({"attack": 1}):
			dice_manager.pay({"attack": 1})
			var target_cell: Vector2i = battle_ai.pick_best_adjacent_target_cell(cell)
			if target_cell.x < 0:
				target_cell = adjacent_players[0]
			var defender_id: String = String(unit_manager.units_by_cell[target_cell])
			var defender_name: String = _get_unit_display_name(defender_id)
			emit_signal("enemy_action_announced", uid, "attack", unit_name + " → 攻击 " + defender_name)
			await get_tree().create_timer(0.6).timeout
			if is_battle_over():
				break
			var defender: Dictionary = unit_manager.get_unit(defender_id)
			var damage: int = _calc_damage_with_terrain(unit, defender)
			var killed: bool = unit_manager.apply_damage(defender_id, damage)
			emit_signal("enemy_attack_completed", uid, defender_id, damage, killed, target_cell)
			_check_battle_outcome()
			await get_tree().create_timer(0.7).timeout
			continue
		# 没有相邻目标则朝最近玩家移动
		if dice_manager.can_pay({"move": 1}):
			var target_player_cell: Vector2i = battle_ai.find_priority_player_cell(cell)
			if target_player_cell.x >= 0:
				var move_cell: Vector2i = battle_ai.pick_move_toward(cell, target_player_cell)
				if move_cell.x >= 0:
					emit_signal("enemy_action_announced", uid, "move", unit_name + " → 移动")
					await get_tree().create_timer(0.5).timeout
					if is_battle_over():
						break
					dice_manager.pay({"move": 1})
					var enemy_old_cell: Vector2i = unit_manager.get_unit(uid)["cell"]
					unit_manager.move_unit(uid, move_cell)
					emit_signal("move_step_visual", uid, enemy_old_cell, move_cell)
					await move_step_done
					# v0.1.65：敌方移动后也发射 move_completed，以便相机跟随
					emit_signal("move_completed", uid, cell, move_cell)
					_check_terrain_trap(uid, move_cell)
					await get_tree().create_timer(0.5).timeout
					if is_battle_over():
						break
					if unit_manager.get_unit(uid).is_empty():
						continue
					# 移动后再检查是否进入攻击范围
					var new_adjacent: Array[Vector2i] = battle_ai.get_adjacent_player_cells(move_cell)
					if new_adjacent.size() > 0 and dice_manager.can_pay({"attack": 1}):
						dice_manager.pay({"attack": 1})
						var atk_target_cell: Vector2i = battle_ai.pick_best_adjacent_target_cell(move_cell)
						if atk_target_cell.x < 0:
							atk_target_cell = new_adjacent[0]
						var def_id: String = String(unit_manager.units_by_cell[atk_target_cell])
						var def_name: String = _get_unit_display_name(def_id)
						var refreshed_unit: Dictionary = unit_manager.get_unit(uid)
						emit_signal("enemy_action_announced", uid, "attack", unit_name + " → 攻击 " + def_name)
						await get_tree().create_timer(0.6).timeout
						if is_battle_over():
							break
						var defender2: Dictionary = unit_manager.get_unit(def_id)
						var dmg: int = _calc_damage_with_terrain(refreshed_unit, defender2)
						var killed2: bool = unit_manager.apply_damage(def_id, dmg)
						emit_signal("enemy_attack_completed", uid, def_id, dmg, killed2, atk_target_cell)
						_check_battle_outcome()
						await get_tree().create_timer(0.7).timeout
	# 敌方回合结束（v0.1.65：延长等待，让玩家看清最终状态）
	if not is_battle_over():
		await get_tree().create_timer(0.6).timeout
		emit_signal("enemy_turn_ended")
		await get_tree().create_timer(1.2).timeout
		_advance_to_next_player_round()

## 推进到下一个玩家回合
func _advance_to_next_player_round() -> void:
	dice_manager.reset_for_turn()
	buff_manager.tick_turn()
	round_index += 1
	dice_manager.set_active_side("player")
	current_phase = BattlePhase.PLAYER_ROLL
	emit_signal("round_changed", round_index)
	emit_signal("phase_changed", _phase_name(current_phase))

# ─── 玩家行动：移动 / 攻击 / 召唤 ───

func get_reachable_cells_for(unit_id: String) -> Array[Vector2i]:
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if unit.is_empty():
		var empty: Array[Vector2i] = []
		return empty
	var move_available: int = int(dice_manager.crest_pool.get("move", 0))
	if move_available <= 0:
		var empty: Array[Vector2i] = []
		return empty
	var cell: Vector2i = unit["cell"]
	var move_range: int = int(unit.get("move_range", 1))
	return board_manager.get_reachable_cells(cell, move_range)

## 纯验证：检查玩家单位移动是否合法（不消耗资源）
func validate_move(unit_id: String, target_cell: Vector2i) -> bool:
	if is_battle_over():
		return false
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if unit.is_empty():
		return false
	if String(unit.get("owner", "")) != "player":
		return false
	var reachable: Array[Vector2i] = get_reachable_cells_for(unit_id)
	var found: bool = false
	for rc in reachable:
		if rc == target_cell:
			found = true
			break
	if not found:
		return false
	var cost: Dictionary = {"move": 1}
	if not dice_manager.can_pay(cost):
		return false
	return true

func try_move_unit(unit_id: String, target_cell: Vector2i) -> void:
	if not validate_move(unit_id, target_cell):
		return
	var cost: Dictionary = {"move": 1}
	dice_manager.pay(cost)
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	var old_cell: Vector2i = unit["cell"]
	var move_range: int = int(unit.get("move_range", 1))
	var path: Array[Vector2i] = board_manager.get_path_to_cell(old_cell, target_cell, move_range)
	# 逐格移动 + 动画
	for i in range(1, path.size()):
		unit_manager.move_unit(unit_id, path[i])
		emit_signal("move_step_visual", unit_id, path[i - 1], path[i])
		await move_step_done
	emit_signal("move_completed", unit_id, old_cell, target_cell)
	_check_terrain_trap(unit_id, target_cell)
	if _can_trigger_board_interactions(unit_id):
		_check_item_pickup(unit_id, target_cell)
	if _can_trigger_board_interactions(unit_id):
		_check_heal_cell(unit_id, target_cell)
	if _can_trigger_board_interactions(unit_id):
		_check_event_cell(unit_id, target_cell)
	if _can_trigger_board_interactions(unit_id):
		_check_shop_cell(unit_id, target_cell)
	if _can_trigger_board_interactions(unit_id):
		_check_chest_cell(unit_id, target_cell)
	if _can_trigger_board_interactions(unit_id):
		_check_encounter(unit_id, target_cell)
	if _can_trigger_board_interactions(unit_id):
		_check_portal(unit_id, target_cell)

func get_attackable_cells_for(unit_id: String) -> Array[Vector2i]:
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if unit.is_empty():
		var empty: Array[Vector2i] = []
		return empty
	var attack_available: int = int(dice_manager.crest_pool.get("attack", 0))
	if attack_available <= 0:
		var empty: Array[Vector2i] = []
		return empty
	return action_resolver.get_attackable_cells(unit_id)

func try_attack_unit(attacker_id: String, target_cell: Vector2i) -> bool:
	if is_battle_over():
		return false
	var attacker: Dictionary = unit_manager.get_unit(attacker_id)
	if attacker.is_empty():
		return false
	if String(attacker.get("owner", "")) != "player":
		return false
	var attackable: Array[Vector2i] = get_attackable_cells_for(attacker_id)
	var found: bool = false
	for ac in attackable:
		if ac == target_cell:
			found = true
			break
	if not found:
		return false
	if not unit_manager.units_by_cell.has(target_cell):
		return false
	var defender_id: String = String(unit_manager.units_by_cell[target_cell])
	var cost: Dictionary = {"attack": 1}
	if not dice_manager.can_pay(cost):
		return false
	dice_manager.pay(cost)
	var defender: Dictionary = unit_manager.get_unit(defender_id)
	var damage: int = _calc_damage_with_terrain(attacker, defender)
	var killed: bool = unit_manager.apply_damage(defender_id, damage)
	emit_signal("attack_completed", attacker_id, defender_id, damage, killed)
	_check_battle_outcome()
	return true

func _check_battle_outcome() -> void:
	var outcome: String = VictoryRuleHelper.get_battle_outcome(unit_manager)
	if outcome == "DEFEAT" or outcome == "DRAW":
		mark_defeat()
		return
	# 哨兵全灭 → 解锁 Boss 遭遇格
	if not VictoryRuleHelper.has_grunt_units(unit_manager):
		_try_unlock_boss()
	# 所有敌方单位清空但棋盘上仍有遭遇格（Boss 遭遇）→ 不判胜
	if outcome == "VICTORY":
		if board_manager.encounter_cells.size() > 0:
			return  # Boss 遭遇尚存，等玩家踩上触发卡牌战斗
		if board_manager.portal_cells.size() > 0:
			return  # 传送门已出现，等玩家踩上
		# 无遭遇无传送门：正常判胜/通关
		if floor_manager.current_floor < floor_manager.get_max_floor():
			current_phase = BattlePhase.FLOOR_CLEAR
			emit_signal("phase_changed", _phase_name(current_phase))
			emit_signal("floor_cleared", floor_manager.current_floor)
		else:
			emit_signal("game_won")
			mark_victory()

## 尝试解锁所有 Boss 遭遇格（v0.1.76：委托 FloorManager）
func _try_unlock_boss() -> void:
	var unlocked: Array[Vector2i] = floor_manager.try_unlock_boss()
	for cell in unlocked:
		emit_signal("boss_unlocked", cell)
	if unlocked.size() > 0:
		_warp_hero_to_boss(unlocked[0])

## Boss 解锁后，将英雄单位传送到 Boss 格旁边的空格（v0.1.76：委托 FloorManager）
func _warp_hero_to_boss(boss_cell: Vector2i) -> void:
	var result: Dictionary = floor_manager.warp_hero_to_boss(boss_cell)
	if not result.is_empty():
		emit_signal("hero_warped", String(result["hero_id"]), result["target_cell"] as Vector2i)

## 计算含地形适性加成、临时防御和 Buff 修正的伤害值
func _calc_damage_with_terrain(attacker: Dictionary, defender: Dictionary) -> int:
	var def_bonus: int = 0
	var defender_cell: Vector2i = defender.get("cell", Vector2i(-1, -1))
	if String(defender.get("terrain_affinity", "")) == "path":
		if board_manager.path_cells.has(defender_cell):
			def_bonus = 1
	var temp_def: int = int(defender.get("temp_def", 0))
	var attacker_id: String = String(attacker.get("id", ""))
	var defender_id: String = String(defender.get("id", ""))
	var atk_mod: int = buff_manager.get_stat_modifier(attacker_id, "atk") if attacker_id != "" else 0
	var def_mod: int = buff_manager.get_stat_modifier(defender_id, "def") if defender_id != "" else 0
	var raw_attack: int = int(attacker.get("atk", 0)) + atk_mod
	var raw_defense: int = int(defender.get("def", 0)) + def_bonus + temp_def + def_mod
	return max(1, raw_attack - raw_defense)

# ─── 遭遇系统 ───

func _check_encounter(unit_id: String, cell: Vector2i) -> void:
	if not _can_trigger_board_interactions(unit_id):
		return
	if not board_manager.encounter_cells.has(cell):
		return
	# 锁定的遭遇格（Boss 未解锁）不可触发
	if board_manager.is_encounter_locked(cell):
		return
	var encounter_id: String = String(board_manager.encounter_cells[cell])
	_encounter_unit_id = unit_id
	_encounter_id = encounter_id
	_encounter_cell = cell
	current_phase = BattlePhase.ENCOUNTER
	emit_signal("phase_changed", _phase_name(current_phase))
	emit_signal("encounter_triggered", unit_id, encounter_id, cell)

func get_encounter_unit_id() -> String:
	return _encounter_unit_id

func resolve_encounter(victory: bool = true, player_hp_remaining: int = -1) -> void:
	if current_phase != BattlePhase.ENCOUNTER:
		return
	var resolved_id: String = _encounter_id
	var resolved_cell: Vector2i = _encounter_cell
	var unit_id: String = _encounter_unit_id
	var is_boss: bool = resolved_id.begins_with("encounter_boss_")

	# 同步卡牌战斗后的 HP 到棋盘单位
	if player_hp_remaining >= 0:
		var unit: Dictionary = unit_manager.get_unit(unit_id)
		if not unit.is_empty():
			if victory:
				unit["hp"] = player_hp_remaining
			else:
				unit["hp"] = max(1, player_hp_remaining)
			unit_manager.units_by_id[unit_id] = unit
			unit_manager.emit_signal("units_changed")
	elif not victory:
		# 无 HP 数据的失败回退：扣 2 点惩罚
		unit_manager.apply_damage(unit_id, 2)

	if victory:
		# 胜利：清除遭遇格（此遭遇已完成，不再触发）
		board_manager.clear_encounter_cell(resolved_cell)
		# Boss 击败 → 在 Boss 格下方生成传送门
		if is_boss:
			_spawn_portal_near(resolved_cell)
		# 清空遭遇上下文
		_encounter_unit_id = ""
		_encounter_id = ""
		_encounter_cell = Vector2i(-1, -1)
		# 回到玩家行动阶段
		current_phase = BattlePhase.PLAYER_ACTION
		emit_signal("encounter_resolved", resolved_id, resolved_cell)
		emit_signal("phase_changed", _phase_name(current_phase))
	else:
		# 失败：检查玩家单位是否全部阵亡
		var any_player_alive: bool = false
		for uid in unit_manager.units_by_id.keys():
			var u: Dictionary = unit_manager.get_unit(String(uid))
			if String(u.get("owner", "")) == "player" and int(u.get("hp", 0)) > 0:
				any_player_alive = true
				break

		if not any_player_alive:
			# 所有单位死亡 → 触发 DEFEAT
			_encounter_unit_id = ""
			_encounter_id = ""
			_encounter_cell = Vector2i(-1, -1)
			mark_defeat()
		else:
			# 单位存活但战斗失败 → 遭遇格保留，玩家可重新挑战
			_encounter_unit_id = ""
			_encounter_id = ""
			_encounter_cell = Vector2i(-1, -1)
			current_phase = BattlePhase.PLAYER_ACTION
			emit_signal("phase_changed", _phase_name(current_phase))

## 在指定格子附近生成传送门（v0.1.76：委托 FloorManager）
func _spawn_portal_near(cell: Vector2i) -> void:
	var portal_cell: Vector2i = floor_manager.spawn_portal_near(cell)
	emit_signal("portal_spawned", portal_cell)

## 检查玩家踩上传送门（v0.1.76：委托 FloorManager）
func _check_portal(unit_id: String, cell: Vector2i) -> void:
	if not _can_trigger_board_interactions(unit_id):
		return
	var result: Dictionary = floor_manager.check_portal(unit_id, cell)
	if result.is_empty():
		return
	var action: String = String(result["action"])
	if action == "floor_clear":
		current_phase = BattlePhase.FLOOR_CLEAR
		emit_signal("phase_changed", _phase_name(current_phase))
		emit_signal("floor_cleared", floor_manager.current_floor)
	elif action == "game_won":
		emit_signal("game_won")
		mark_victory()

# ─── 召唤系统 ───

func get_summon_cells_for(unit_id: String) -> Array[Vector2i]:
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if unit.is_empty():
		var empty: Array[Vector2i] = []
		return empty
	var summon_available: int = int(dice_manager.crest_pool.get("summon", 0))
	if summon_available <= 0:
		var empty: Array[Vector2i] = []
		return empty
	# 已达本层次数上限时返回空（禁止高亮）
	if _summon_this_floor >= SUMMON_FLOOR_LIMIT:
		return []
	# 已达场上伙伴上限时返回空
	var summoned_count: int = 0
	for uid in unit_manager.units_by_id.keys():
		var u: Dictionary = unit_manager.get_unit(String(uid))
		if String(u.get("owner", "")) == "player" and int(u.get("hp", 0)) > 0:
			var tags: Array = u.get("tags", [])
			if tags.has("summoned"):
				summoned_count += 1
	if summoned_count >= SUMMON_FIELD_LIMIT:
		return []
	var cell: Vector2i = unit["cell"]
	return board_manager.get_free_neighbors(cell)

func try_summon(origin_unit_id: String, target_cell: Vector2i) -> bool:
	if is_battle_over():
		return false
	if current_phase != BattlePhase.PLAYER_ACTION:
		return false
	var origin_unit: Dictionary = unit_manager.get_unit(origin_unit_id)
	if origin_unit.is_empty():
		return false
	if String(origin_unit.get("owner", "")) != "player":
		return false
	var summon_cells: Array[Vector2i] = get_summon_cells_for(origin_unit_id)
	var found: bool = false
	for sc in summon_cells:
		if sc == target_cell:
			found = true
			break
	if not found:
		return false
	var cost: Dictionary = {"summon": 1}
	if not dice_manager.can_pay(cost):
		return false
	# 检查本层部署次数上限
	if _summon_this_floor >= SUMMON_FLOOR_LIMIT:
		return false
	# 检查场上伙伴上限（统计带 "summoned" tag 的存活玩家单位数）
	var summoned_count: int = 0
	for uid in unit_manager.units_by_id.keys():
		var u: Dictionary = unit_manager.get_unit(String(uid))
		if String(u.get("owner", "")) == "player" and int(u.get("hp", 0)) > 0:
			var tags: Array = u.get("tags", [])
			if tags.has("summoned"):
				summoned_count += 1
	if summoned_count >= SUMMON_FIELD_LIMIT:
		return false
	dice_manager.pay(cost)
	board_manager.add_path_cell(target_cell, "player")
	var extended_paths: Array[Vector2i] = [target_cell]
	var ext_neighbors: Array[Vector2i] = board_manager.get_free_neighbors(target_cell)
	if ext_neighbors.size() > 0:
		var origin_cell: Vector2i = origin_unit["cell"]
		var best_ext: Vector2i = ext_neighbors[0]
		var best_dist: int = absi(ext_neighbors[0].x - origin_cell.x) + absi(ext_neighbors[0].y - origin_cell.y)
		for ext in ext_neighbors:
			var d: int = absi(ext.x - origin_cell.x) + absi(ext.y - origin_cell.y)
			if d > best_dist:
				best_dist = d
				best_ext = ext
		board_manager.add_path_cell(best_ext, "player")
		extended_paths.append(best_ext)
	_summon_counter += 1
	_summon_this_floor += 1
	var summon_id: String = "summoned_fox_" + str(_summon_counter)
	var summon_data: Dictionary = {
		"max_hp": 4, "atk": 2, "def": 0,
		"move_range": 2, "attack_range": 1,
		"owner": "player", "tags": ["summoned", "fox"],
		"display_name": "协议灵狐",
	}
	unit_manager.spawn_unit(summon_id, summon_data, target_cell)
	emit_signal("summon_completed", summon_id, extended_paths, target_cell)
	return true

# ─── 多层地图（v0.1.76：委托 FloorManager） ───

## 进入下一层
func advance_to_next_floor() -> void:
	if current_phase != BattlePhase.FLOOR_CLEAR:
		return
	var _reset_summon: Callable = func() -> void:
		_summon_counter = 0
		_summon_this_floor = 0
	floor_manager.advance_floor(BOARD_SIZE, _reset_summon)
	_encounter_unit_id = ""
	_encounter_id = ""
	_encounter_cell = Vector2i(-1, -1)
	current_phase = BattlePhase.PLAYER_ROLL
	round_index = 1
	emit_signal("round_changed", round_index)
	emit_signal("phase_changed", _phase_name(current_phase))

func get_current_floor() -> int:
	return floor_manager.get_current_floor()

func get_max_floor() -> int:
	return floor_manager.get_max_floor()

# ─── 工具方法 ───

func _phase_name(phase: BattlePhase) -> String:
	match phase:
		BattlePhase.BOOT:
			return "BOOT"
		BattlePhase.PLAYER_ROLL:
			return "PLAYER_ROLL"
		BattlePhase.PLAYER_ACTION:
			return "PLAYER_ACTION"
		BattlePhase.ENCOUNTER:
			return "ENCOUNTER"
		BattlePhase.ENEMY_ROLL:
			return "ENEMY_ROLL"
		BattlePhase.ENEMY_ACTION:
			return "ENEMY_ACTION"
		BattlePhase.RESOLUTION:
			return "RESOLUTION"
		BattlePhase.FLOOR_CLEAR:
			return "FLOOR_CLEAR"
		BattlePhase.VICTORY:
			return "VICTORY"
		BattlePhase.DEFEAT:
			return "DEFEAT"
	return "UNKNOWN"

func _can_trigger_board_interactions(unit_id: String) -> bool:
	if unit_manager == null:
		return false
	if unit_manager.has_method("is_player_hero_unit"):
		return bool(unit_manager.is_player_hero_unit(unit_id))
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if unit.is_empty():
		return false
	if String(unit.get("owner", "")) != "player":
		return false
	var tags: Array = unit.get("tags", [])
	return not tags.has("summoned")

## Restart the battle: clear all state and re-spawn units at initial positions.
func restart_battle() -> void:
	dice_manager.reset_for_battle()
	buff_manager.clear_all()
	unit_manager.clear_all_units()
	board_manager.clear_board()
	board_manager.build_test_board(BOARD_SIZE)
	_summon_counter = 0
	_summon_this_floor = 0
	_encounter_unit_id = ""
	_encounter_id = ""
	_encounter_cell = Vector2i(-1, -1)
	floor_manager.reset_floor()
	_spawn_player_units()
	BoardGenerator.generate_board(board_manager, unit_manager, BOARD_SIZE, floor_manager.current_floor)
	current_phase = BattlePhase.PLAYER_ROLL
	round_index = 1
	emit_signal("round_changed", round_index)
	emit_signal("phase_changed", _phase_name(current_phase))
