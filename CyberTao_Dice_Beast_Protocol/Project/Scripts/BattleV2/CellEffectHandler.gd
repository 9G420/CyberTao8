extends Node
class_name CellEffectHandler

## 格子效果处理器（从 BattleFlowController 剥离）
## 处理陷阱/道具/恢复/事件格的效果计算，返回结果字典
## BFC 负责信号发射和战斗结算判定

const ItemEffectLibrary = preload("res://Scripts/BattleV2/ItemEffectLibrary.gd")

var board_manager: Node = null
var unit_manager: Node = null
var dice_manager: Node = null
var buff_manager: Node = null

## 检查陷阱地形：触发 1 点伤害（陷阱适性单位免疫）
## 返回 {"triggered": true, "damage": int, "killed": bool} 或 {"triggered": false}
func check_terrain_trap(unit_id: String, cell: Vector2i) -> Dictionary:
	if board_manager.get_terrain_type(cell) != "trap":
		return {"triggered": false}
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if String(unit.get("terrain_affinity", "")) == "trap":
		return {"triggered": false}
	var trap_damage: int = 1
	var killed: bool = unit_manager.apply_damage(unit_id, trap_damage)
	return {"triggered": true, "damage": trap_damage, "killed": killed}

## 检查道具拾取：拾取并应用道具效果
## 返回 {"picked": true, "item_id": str, "effect_text": str} 或 {"picked": false}
func check_item_pickup(unit_id: String, cell: Vector2i) -> Dictionary:
	if not board_manager.item_cells.has(cell):
		return {"picked": false}
	var item_id: String = String(board_manager.item_cells[cell])
	board_manager.item_cells.erase(cell)
	var effect_text: String = _apply_item_effect(item_id, unit_id)
	board_manager.emit_signal("board_changed")
	return {"picked": true, "item_id": item_id, "effect_text": effect_text}

## 检查恢复格：回复 HP（持久，不消失）
## 返回 {"healed": true, "heal_amount": int, "actual_heal": int} 或 {"healed": false}
func check_heal_cell(unit_id: String, cell: Vector2i) -> Dictionary:
	if not board_manager.heal_cells.has(cell):
		return {"healed": false}
	var heal_amount: int = int(board_manager.heal_cells[cell])
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if unit.is_empty():
		return {"healed": false}
	var current_hp: int = int(unit.get("hp", 0))
	var max_hp: int = int(unit.get("max_hp", 1))
	if current_hp >= max_hp:
		return {"healed": false}
	var actual_heal: int = min(heal_amount, max_hp - current_hp)
	unit["hp"] = current_hp + actual_heal
	unit_manager.units_by_id[unit_id] = unit
	unit_manager.emit_signal("units_changed")
	return {"healed": true, "heal_amount": heal_amount, "actual_heal": actual_heal}

## 检查事件格：触发随机效果（一次性，踩后消失）
## 返回 {"triggered": true, "event_id": str, "effect_text": str, "killed": bool} 或 {"triggered": false}
func check_event_cell(unit_id: String, cell: Vector2i) -> Dictionary:
	if not board_manager.event_cells.has(cell):
		return {"triggered": false}
	var event_id: String = String(board_manager.event_cells[cell])
	board_manager.clear_event_cell(cell)
	var roll: int = randi() % 3
	var effect_text: String = ""
	var killed: bool = false
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if unit.is_empty():
		return {"triggered": false}
	match roll:
		0:
			# 正面：回复 1 HP
			var current_hp: int = int(unit.get("hp", 0))
			var max_hp: int = int(unit.get("max_hp", 1))
			var actual_heal: int = min(1, max_hp - current_hp)
			if actual_heal > 0:
				unit["hp"] = current_hp + actual_heal
				unit_manager.units_by_id[unit_id] = unit
				unit_manager.emit_signal("units_changed")
			effect_text = "HP+1"
		1:
			# 正面：随机获得 1 crest
			var crest_types: Array[String] = ["move", "attack", "defend", "skill", "trick", "summon"]
			var picked: String = crest_types[randi() % crest_types.size()]
			var current: int = int(dice_manager.crest_pool.get(picked, 0))
			dice_manager.crest_pool[picked] = current + 1
			effect_text = picked.to_upper() + "+1"
		2:
			# 负面：受到 1 点伤害
			killed = unit_manager.apply_damage(unit_id, 1)
			effect_text = "HP-1"
	return {"triggered": true, "event_id": event_id, "effect_text": effect_text, "killed": killed}

## 检查是否为商店格且玩家可进入（v0.1.73：仅做存在性+玩家身份检查，不自动购买）
## 返回 true 时由 Main 打开 ShopPanel 面板
func has_valid_shop_cell(unit_id: String, cell: Vector2i) -> bool:
	if not board_manager.shop_cells.has(cell):
		return false
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if unit.is_empty():
		return false
	if String(unit.get("owner", "")) != "player":
		return false
	return true

## 检查宝箱格：随机奖励（一次性，踩后消失）
## 返回 {"opened": true, "effect_text": str} 或 {"opened": false}
func check_chest_cell(unit_id: String, cell: Vector2i) -> Dictionary:
	if not board_manager.chest_cells.has(cell):
		return {"opened": false}
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if unit.is_empty():
		return {"opened": false}
	board_manager.clear_chest_cell(cell)
	var roll: int = randi() % 3
	var effect_text: String = ""
	match roll:
		0:
			# 回复 3 HP
			var current_hp: int = int(unit.get("hp", 0))
			var max_hp: int = int(unit.get("max_hp", 1))
			var actual_heal: int = min(3, max_hp - current_hp)
			if actual_heal > 0:
				unit["hp"] = current_hp + actual_heal
				unit_manager.units_by_id[unit_id] = unit
				unit_manager.emit_signal("units_changed")
			effect_text = "HP+" + str(actual_heal)
		1:
			# 随机 crest +2
			var crest_types: Array[String] = ["move", "attack", "defend", "skill", "trick", "summon"]
			var picked: String = crest_types[randi() % crest_types.size()]
			var current: int = int(dice_manager.crest_pool.get(picked, 0))
			dice_manager.crest_pool[picked] = current + 2
			effect_text = picked.to_upper() + "+2"
		2:
			# 全 crest +1
			for crest_type in ["move", "attack", "defend", "skill", "trick", "summon"]:
				var current: int = int(dice_manager.crest_pool.get(crest_type, 0))
				dice_manager.crest_pool[crest_type] = current + 1
			effect_text = "ALL CREST+1"
	return {"opened": true, "effect_text": effect_text}

## 执行道具效果并返回效果描述（内部方法）
func _apply_item_effect(item_id: String, unit_id: String) -> String:
	var context: Dictionary = {"unit_id": unit_id}
	var effect_id: String = ""
	match item_id:
		"patch_tea_cache":
			effect_id = "heal_and_cleanse"
		"overclock_bone":
			effect_id = "gain_move_and_attack_boost"
		"glitch_snack_box":
			effect_id = "random_crest_gain"
		_:
			return ""
	var result: Dictionary = ItemEffectLibrary.execute(effect_id, context)
	if not result.get("ok", false):
		return ""
	var effect: String = String(result.get("effect", ""))
	match effect:
		"heal_and_cleanse":
			var heal: int = int(result.get("heal", 0))
			var unit: Dictionary = unit_manager.get_unit(unit_id)
			if not unit.is_empty():
				var new_hp: int = min(int(unit.get("hp", 0)) + heal, int(unit.get("max_hp", 1)))
				unit["hp"] = new_hp
				unit_manager.units_by_id[unit_id] = unit
				unit_manager.emit_signal("units_changed")
			return "HP+" + str(heal)
		"gain_move_and_attack_boost":
			var crest_bonus: Dictionary = result.get("crest_bonus", {})
			for crest_type in crest_bonus.keys():
				var amount: int = int(crest_bonus[crest_type])
				var current: int = int(dice_manager.crest_pool.get(crest_type, 0))
				dice_manager.crest_pool[crest_type] = current + amount
			# 施加 ATK+1 buff 持续 3 回合
			buff_manager.apply_buff(unit_id, "atk_up", 1, 3)
			return "MOVE+1 ATK+1(3回合)"
		"random_crest_gain":
			var crest_bonus: Dictionary = result.get("crest_bonus", {})
			var gained_type: String = ""
			for crest_type in crest_bonus.keys():
				var amount: int = int(crest_bonus[crest_type])
				var current: int = int(dice_manager.crest_pool.get(crest_type, 0))
				dice_manager.crest_pool[crest_type] = current + amount
				gained_type = String(crest_type)
			return gained_type.to_upper() + "+1"
	return ""
