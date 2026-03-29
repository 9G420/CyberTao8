extends Node
class_name BuffManager

var active_buffs_by_unit: Dictionary = {}

func apply_pickup(item_id: String, unit_id: String) -> void:
	var buffs: Array = active_buffs_by_unit.get(unit_id, [])
	buffs.append({
		"source": item_id,
		"duration": 3,
	})
	active_buffs_by_unit[unit_id] = buffs

func tick_turn() -> void:
	for unit_id in active_buffs_by_unit.keys():
		var next_buffs: Array = []
		for buff in active_buffs_by_unit[unit_id]:
			var duration: int = int(buff.get("duration", 0)) - 1
			if duration > 0:
				buff["duration"] = duration
				next_buffs.append(buff)
		active_buffs_by_unit[unit_id] = next_buffs
