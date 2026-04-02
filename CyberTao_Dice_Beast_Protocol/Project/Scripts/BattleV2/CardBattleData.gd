extends RefCounted
class_name CardBattleData

const FLOOR_HP_SCALE: float = 0.3
const FLOOR_ATK_STEP: int = 1

const STARTER_DECK_CARD_IDS: Array[String] = [
	"slash",
	"slash",
	"heavy_strike",
	"guard",
	"guard",
	"repair",
	"dual_slash",
	"dual_slash",
	"assault",
	"first_aid",
]

const REWARD_POOL_CARD_IDS: Array[String] = [
	"pierce",
	"iron_wall",
	"vampiric_slash",
	"overclock_repair",
	"arc",
	"empowered_slash",
	"double_guard",
	"poison_injection",
	"energy_drain",
	"counter",
	"void_cleave",
	"slash",
	"heavy_strike",
	"guard",
	"repair",
	"assault",
	"first_aid",
]

const CARD_LIBRARY := {
	"slash": {
		"id": "slash",
		"name": "\u65a9\u51fb",
		"type": "attack",
		"cost": 1,
		"value": 3,
		"upgrade": {"value": 4},
	},
	"heavy_strike": {
		"id": "heavy_strike",
		"name": "\u91cd\u51fb",
		"type": "attack",
		"cost": 2,
		"value": 5,
		"upgrade": {"value": 7},
	},
	"guard": {
		"id": "guard",
		"name": "\u9632\u5fa1",
		"type": "defend",
		"cost": 1,
		"value": 2,
		"upgrade": {"value": 3},
	},
	"repair": {
		"id": "repair",
		"name": "\u4fee\u590d",
		"type": "heal",
		"cost": 1,
		"value": 2,
		"upgrade": {"value": 3},
	},
	"dual_slash": {
		"id": "dual_slash",
		"name": "\u8fde\u65a9",
		"type": "attack",
		"cost": 1,
		"value": 2,
		"upgrade": {"value": 3},
	},
	"assault": {
		"id": "assault",
		"name": "\u731b\u653b",
		"type": "attack",
		"cost": 3,
		"value": 8,
		"upgrade": {"value": 11},
	},
	"first_aid": {
		"id": "first_aid",
		"name": "\u6025\u6551",
		"type": "heal",
		"cost": 2,
		"value": 4,
		"upgrade": {"value": 6},
	},
	"pierce": {
		"id": "pierce",
		"name": "\u7a7f\u523a",
		"type": "pierce",
		"cost": 2,
		"value": 5,
		"upgrade": {"value": 6},
	},
	"iron_wall": {
		"id": "iron_wall",
		"name": "\u94c1\u58c1",
		"type": "defend",
		"cost": 2,
		"value": 5,
		"upgrade": {"value": 7},
	},
	"vampiric_slash": {
		"id": "vampiric_slash",
		"name": "\u5438\u8840\u65a9",
		"type": "lifesteal",
		"cost": 2,
		"value": 3,
		"heal_value": 2,
		"upgrade": {
			"value": 4,
			"heal_value": 3,
		},
	},
	"overclock_repair": {
		"id": "overclock_repair",
		"name": "\u8d85\u9891\u4fee\u590d",
		"type": "heal",
		"cost": 3,
		"value": 6,
		"upgrade": {"value": 9},
	},
	"arc": {
		"id": "arc",
		"name": "\u7535\u5f27",
		"type": "shock",
		"cost": 1,
		"value": 2,
		"upgrade": {"value": 3},
	},
	"empowered_slash": {
		"id": "empowered_slash",
		"name": "\u5f3a\u5316\u65a9\u51fb",
		"type": "attack",
		"cost": 1,
		"value": 4,
		"upgrade": {"value": 6},
	},
	"double_guard": {
		"id": "double_guard",
		"name": "\u53cc\u91cd\u9632\u5fa1",
		"type": "defend",
		"cost": 1,
		"value": 3,
		"upgrade": {"value": 4},
	},
	"poison_injection": {
		"id": "poison_injection",
		"name": "\u6bd2\u7d20\u6ce8\u5165",
		"type": "poison",
		"cost": 1,
		"value": 2,
		"upgrade": {"value": 3},
	},
	"energy_drain": {
		"id": "energy_drain",
		"name": "\u80fd\u91cf\u8679\u5438",
		"type": "draw",
		"cost": 1,
		"value": 2,
		"upgrade": {"value": 3},
	},
	"counter": {
		"id": "counter",
		"name": "\u53cd\u51fb",
		"type": "counter",
		"cost": 1,
		"value": 2,
		"def_value": 2,
		"upgrade": {
			"value": 3,
			"def_value": 3,
		},
	},
	"void_cleave": {
		"id": "void_cleave",
		"name": "\u88c2\u7a7a\u65a9",
		"type": "combo",
		"cost": 2,
		"value": 2,
		"hits": 3,
		"upgrade": {
			"value": 3,
			"hits": 3,
		},
	},
}

const ENCOUNTER_LIBRARY := {
	"encounter_01": {
		"name": "\u5f02\u5e38\u54e8\u5175",
		"hp": 8,
		"atk": 2,
		"pattern": ["attack", "attack", "defend_attack", "heavy_attack"],
	},
	"encounter_02": {
		"name": "\u8d5b\u535a\u6e38\u9b42",
		"hp": 6,
		"atk": 3,
		"pattern": ["attack", "heavy_attack", "attack"],
	},
	"encounter_03": {
		"name": "\u6697\u7f51\u722c\u866b",
		"hp": 12,
		"atk": 1,
		"pattern": ["defend_attack", "defend_attack", "heavy_attack", "attack"],
	},
	"encounter_04": {
		"name": "\u8109\u51b2\u730e\u624b",
		"hp": 6,
		"atk": 3,
		"pattern": ["attack", "heavy_attack", "attack"],
	},
	"encounter_05": {
		"name": "\u6570\u636e\u5e7d\u7075",
		"hp": 9,
		"atk": 2,
		"pattern": ["attack", "defend_attack", "heavy_attack", "heavy_attack", "attack"],
	},
	"encounter_06": {
		"name": "\u91cf\u5b50\u5206\u88c2\u4f53",
		"hp": 7,
		"atk": 2,
		"pattern": ["attack", "buff", "multi_attack", "attack", "heavy_attack"],
	},
	"encounter_07": {
		"name": "\u8d5b\u535a\u5deb\u533b",
		"hp": 9,
		"atk": 2,
		"pattern": ["buff", "defend_attack", "heal", "heavy_attack", "attack"],
	},
	"encounter_boss_01": {
		"name": "\u96f6\u53f7\u534f\u8bae",
		"hp": 20,
		"atk": 3,
		"is_boss": true,
		"pattern": ["attack", "defend_attack", "heavy_attack", "heal", "attack", "mega_attack"],
	},
}

const DEFAULT_ENCOUNTER := {
	"name": "\u672a\u77e5\u654c\u4eba",
	"hp": 5,
	"atk": 2,
	"pattern": ["attack", "attack"],
}

static func build_starter_deck() -> Array[Dictionary]:
	var deck: Array[Dictionary] = []
	for card_id in STARTER_DECK_CARD_IDS:
		deck.append(_build_card(String(card_id)))
	return deck

static func build_reward_pool() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for card_id in REWARD_POOL_CARD_IDS:
		pool.append(_build_card(String(card_id)))
	return pool

static func get_card_upgrade(card: Dictionary) -> Dictionary:
	var upgraded_card: Dictionary = card.duplicate(true)
	var card_id: String = _resolve_card_id(card)
	var template: Dictionary = {}
	if card_id != "":
		template = CARD_LIBRARY.get(card_id, {})
		upgraded_card["id"] = card_id

	var base_name: String = _normalize_card_name(String(card.get("name", "")))
	if not template.is_empty():
		base_name = String(template.get("name", base_name))

	upgraded_card["upgraded"] = true
	upgraded_card["name"] = base_name + "+"
	upgraded_card.erase("upgrade")

	if not template.is_empty():
		var upgrade_data: Dictionary = template.get("upgrade", {})
		for key in upgrade_data.keys():
			upgraded_card[key] = upgrade_data[key]
	else:
		upgraded_card["value"] = int(card.get("value", 0)) + 1
	return upgraded_card

static func get_encounter_enemy_data(enc_id: String, current_floor: int = 1) -> Dictionary:
	var base: Dictionary = ENCOUNTER_LIBRARY.get(enc_id, DEFAULT_ENCOUNTER).duplicate(true)
	var floor_offset: int = max(0, current_floor - 1)
	if floor_offset > 0:
		base["hp"] = int(ceil(float(int(base["hp"])) * (1.0 + FLOOR_HP_SCALE * float(floor_offset))))
		base["atk"] = int(base["atk"]) + FLOOR_ATK_STEP * floor_offset
	return base

static func _build_card(card_id: String) -> Dictionary:
	var template: Dictionary = CARD_LIBRARY.get(card_id, {})
	if template.is_empty():
		return {}
	var card: Dictionary = template.duplicate(true)
	card.erase("upgrade")
	card["upgraded"] = false
	return card

static func _resolve_card_id(card: Dictionary) -> String:
	var explicit_id: String = String(card.get("id", ""))
	if explicit_id != "" and CARD_LIBRARY.has(explicit_id):
		return explicit_id

	var base_name: String = _normalize_card_name(String(card.get("name", "")))
	for card_id in CARD_LIBRARY.keys():
		var template: Dictionary = CARD_LIBRARY[card_id]
		if String(template.get("name", "")) == base_name:
			return String(card_id)
	return ""

static func _normalize_card_name(card_name: String) -> String:
	if card_name.ends_with("+") and card_name.length() > 1:
		return card_name.substr(0, card_name.length() - 1)
	return card_name
