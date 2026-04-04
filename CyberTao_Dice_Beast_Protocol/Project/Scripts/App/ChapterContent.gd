extends RefCounted
class_name ChapterContent

const OPENING_BRIEFING := {
	"tag": "第一章 / 天枢治域",
	"title": "灰链封锁区",
	"subtitle": "路权冻结，配额异常，封锁线正在收紧",
	"body": "你们已被投入天枢治域外围的灰链封锁区。这里的路权、通路和补给都由区务系统实时审定，任何偏移都会被巡检单位视为异常。\n\n当前目标不是揭开整个世界的真相，而是先在封锁区里重新建立前进路线，击穿巡检链路，找到被压制的出口节点。",
	"footer": "教学重点：移动夺路、路径扩展、遭遇切换、资源分配",
	"button": "进入封锁区",
}

const RUN_HEADERS := {
	1: "第一章 灰链封锁区 / 天枢治域外围",
	2: "封锁区深层 / 配额回收带",
	3: "监督核心前庭 / 路权主闸",
}

const RUN_OBJECTIVES := {
	1: "重建前进路径，穿过首段灰链封锁线。",
	2: "夺回路权节点，削弱配额回收与巡检协同。",
	3: "突破监督主闸，击败区务监督官。",
}

const ENCOUNTER_DISPLAY_NAMES := {
	"encounter_01": "灰链巡检哨",
	"encounter_02": "路权清扫者",
	"encounter_03": "配额爬虫",
	"encounter_04": "截流追猎手",
	"encounter_05": "失序记录员",
	"encounter_06": "配额分裂体",
	"encounter_07": "封锁维护师",
	"encounter_boss_01": "区务监督官",
}

static func get_opening_briefing() -> Dictionary:
	return OPENING_BRIEFING.duplicate(true)

static func get_run_header(floor_num: int) -> String:
	return String(RUN_HEADERS.get(floor_num, "灰链封锁区 / 天枢治域"))

static func get_run_objective(floor_num: int) -> String:
	return String(RUN_OBJECTIVES.get(floor_num, "继续推进封锁区。"))

static func get_encounter_display_name(encounter_id: String) -> String:
	return String(ENCOUNTER_DISPLAY_NAMES.get(encounter_id, "未知拦截体"))

static func get_encounter_resolved_text() -> String:
	return "封锁节点已压制"

static func get_shop_feedback_label() -> String:
	return "黑市补给已接入"

static func get_victory_text() -> String:
	return "封锁区已突破"

static func get_floor_clear_text(floor_num: int) -> String:
	if floor_num >= 3:
		return "监督主闸已瓦解"
	return "封锁层已压制"

static func get_encounter_victory_text() -> String:
	return "巡检链路已断开"

static func get_encounter_defeat_text() -> String:
	return "拦截失败，封锁压力上升"

static func get_boss_unlock_text() -> String:
	return "监督主闸已暴露"

static func get_warp_text() -> String:
	return "已接入强制转运链路"

static func get_portal_text() -> String:
	return "出口节点已开放"
