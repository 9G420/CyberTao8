extends Node
class_name BuffManager

## Buff 管理器（棋盘层）
## 管理单位的时限性增益/减益效果
## tick_turn() 在每个新回合开始时由 BattleFlowController 调用

signal buff_applied(unit_id: String, buff_type: String, value: int, duration: int)
signal buff_expired(unit_id: String, buff_type: String)

## 每个 unit_id 对应一个 Array，内含 buff 字典：
## { "type": "atk_up"/"atk_down"/"def_up"/"def_down", "value": int, "duration": int }
var active_buffs_by_unit: Dictionary = {}

## 施加一个 buff：类型 + 数值 + 持续回合数
## buff_type 约定：atk_up / atk_down / def_up / def_down
func apply_buff(unit_id: String, buff_type: String, value: int, duration: int) -> void:
	var buffs: Array = active_buffs_by_unit.get(unit_id, [])
	buffs.append({
		"type": buff_type,
		"value": value,
		"duration": duration,
	})
	active_buffs_by_unit[unit_id] = buffs
	emit_signal("buff_applied", unit_id, buff_type, value, duration)

## 获取单位某个属性的总 buff 修正值（正数=增益，负数=减益）
## stat: "atk" / "def"
func get_stat_modifier(unit_id: String, stat: String) -> int:
	var buffs: Array = active_buffs_by_unit.get(unit_id, [])
	var total: int = 0
	for buff in buffs:
		var buff_type: String = String(buff.get("type", ""))
		match buff_type:
			"atk_up":
				if stat == "atk":
					total += int(buff.get("value", 0))
			"atk_down":
				if stat == "atk":
					total -= int(buff.get("value", 0))
			"def_up":
				if stat == "def":
					total += int(buff.get("value", 0))
			"def_down":
				if stat == "def":
					total -= int(buff.get("value", 0))
	return total

## 获取单位当前所有活跃 buff（供 UI 显示）
func get_active_buffs(unit_id: String) -> Array:
	return active_buffs_by_unit.get(unit_id, [])

## 回合结算：所有 buff 持续回合 -1，到期的 buff 移除并发信号
func tick_turn() -> void:
	for unit_id in active_buffs_by_unit.keys():
		var next_buffs: Array = []
		for buff in active_buffs_by_unit[unit_id]:
			var duration: int = int(buff.get("duration", 0)) - 1
			if duration > 0:
				buff["duration"] = duration
				next_buffs.append(buff)
			else:
				emit_signal("buff_expired", unit_id, String(buff.get("type", "")))
		active_buffs_by_unit[unit_id] = next_buffs

## 清除所有 buff（重开战斗时调用）
func clear_all() -> void:
	active_buffs_by_unit = {}

## 清除指定单位的所有 buff（单位死亡时可用）
func clear_unit(unit_id: String) -> void:
	active_buffs_by_unit.erase(unit_id)

## 获取单位 buff 摘要文本（供 HUD 显示）
func get_buff_summary(unit_id: String) -> String:
	var buffs: Array = active_buffs_by_unit.get(unit_id, [])
	if buffs.is_empty():
		return ""
	var parts: Array[String] = []
	for buff in buffs:
		var t: String = String(buff.get("type", ""))
		var v: int = int(buff.get("value", 0))
		var d: int = int(buff.get("duration", 0))
		var label: String = ""
		match t:
			"atk_up":
				label = "ATK+" + str(v)
			"atk_down":
				label = "ATK-" + str(v)
			"def_up":
				label = "DEF+" + str(v)
			"def_down":
				label = "DEF-" + str(v)
			_:
				label = t
		parts.append(label + "(" + str(d) + "回合)")
	return " ".join(parts)
