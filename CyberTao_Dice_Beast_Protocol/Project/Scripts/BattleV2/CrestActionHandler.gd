extends Node
class_name CrestActionHandler

## Crest 消耗操作处理器（从 BattleFlowController 剥离）
## 处理 DEFEND/SKILL/TRICK crest 的使用逻辑，返回结果字典

var unit_manager: Node = null
var dice_manager: Node = null

## 使用护持(DEFEND) crest：选中单位本回合 DEF+1（累加）
## 返回 {"ok": true, "new_temp_def": int} 或 {"ok": false}
func try_use_defend(unit_id: String) -> Dictionary:
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if unit.is_empty():
		return {"ok": false}
	if String(unit.get("owner", "")) != "player":
		return {"ok": false}
	var cost: Dictionary = {"defend": 1}
	if not dice_manager.can_pay(cost):
		return {"ok": false}
	dice_manager.pay(cost)
	var cur_temp: int = int(unit.get("temp_def", 0)) + 1
	unit["temp_def"] = cur_temp
	unit_manager.units_by_id[unit_id] = unit
	return {"ok": true, "new_temp_def": cur_temp}

## 使用术式(SKILL) crest：选中单位回复 2 HP
## 返回 {"ok": true, "heal": int} 或 {"ok": false}
func try_use_skill(unit_id: String) -> Dictionary:
	var unit: Dictionary = unit_manager.get_unit(unit_id)
	if unit.is_empty():
		return {"ok": false}
	if String(unit.get("owner", "")) != "player":
		return {"ok": false}
	var cost: Dictionary = {"skill": 1}
	if not dice_manager.can_pay(cost):
		return {"ok": false}
	var cur_hp: int = int(unit.get("hp", 0))
	var max_hp: int = int(unit.get("max_hp", 1))
	if cur_hp >= max_hp:
		return {"ok": false}
	dice_manager.pay(cost)
	var heal: int = min(2, max_hp - cur_hp)
	unit["hp"] = cur_hp + heal
	unit_manager.units_by_id[unit_id] = unit
	unit_manager.emit_signal("units_changed")
	return {"ok": true, "heal": heal}

## 使用机巧(TRICK) crest：转化为 +1 随机实用 crest（步进/杀伐/显化）
## 返回 {"ok": true, "gained_crest": str} 或 {"ok": false}
func try_use_trick() -> Dictionary:
	var cost: Dictionary = {"trick": 1}
	if not dice_manager.can_pay(cost):
		return {"ok": false}
	dice_manager.pay(cost)
	var options: Array[String] = ["move", "attack", "summon"]
	var picked: String = options[randi() % options.size()]
	dice_manager.crest_pool[picked] = int(dice_manager.crest_pool.get(picked, 0)) + 1
	return {"ok": true, "gained_crest": picked}

## 清除所有玩家单位的临时防御（回合结束时调用）
func clear_temp_def() -> void:
	for uid in unit_manager.units_by_id.keys():
		var u: Dictionary = unit_manager.units_by_id[uid]
		if String(u.get("owner", "")) == "player":
			u["temp_def"] = 0
