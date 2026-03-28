# ============================================================
# EffectSystem.gd - 卡牌效果执行系统
# 解析CardData中的effect_id并执行对应效果
# 支持102张卡牌 + 状态效果系统
# ============================================================
class_name EffectSystem
extends RefCounted


## 效果执行结果（内部类，供其他脚本使用 EffectResult 类型）
class EffectResult:
	extends RefCounted

	var damage_dealt: int = 0
	var shield_gained: int = 0
	var healing_done: int = 0
	var energy_change: int = 0
	var cards_drawn: int = 0
	var yinyang_shift: int = 0
	var summon_data: CardData = null
	var special_text: String = ""
	var apply_statuses_to_enemy: Array[Dictionary] = []
	var apply_statuses_to_player: Array[Dictionary] = []
	var exhaust: bool = false
	var generate_tokens: int = 0
	var discard_count: int = 0
	var discard_all: bool = false
	var damage_per_discard: int = 0
	var unplayable_on_discard_damage: int = 0
	var unplayable_on_discard_energy: int = 0
	var unplayable_on_discard_draw: int = 0
	var enemy_attack_reduction: int = 0
	var multi_hit: int = 0
	var ignore_shield: bool = false
	var conditional: String = ""
	var power_id: String = ""
	var aoe: bool = false
	var extra_turn: bool = false
	var corpse_explode: bool = false
	var corruption_double: bool = false
	var heal_summons: int = 0
	var summon_shield: int = 0
	var yinyang_reduce_diff: int = 0
	var zero_cost_hand: bool = false
	var no_draw: bool = false
	var copy_hand_next_turn: bool = false
	var shuffle_discard_to_deck: bool = false
	var random_zero_cost: int = 0
	var next_turn_energy: int = 0


## 执行卡牌效果
static func execute_card(card_data: CardData, _caster_hp: int = 0, _caster_shield: int = 0) -> EffectResult:
	var result := EffectResult.new()

	# 基础效果（根据卡牌类型）
	match card_data.card_type:
		CardData.CardType.ATTACK:
			result.damage_dealt = card_data.attack_power
		CardData.CardType.DEFENSE:
			result.shield_gained = card_data.defense_power
		CardData.CardType.SUMMON:
			result.summon_data = card_data
		CardData.CardType.SPELL:
			pass
		CardData.CardType.POWER:
			result.power_id = card_data.effect_id

	# 阴阳值影响
	result.yinyang_shift = card_data.yinyang_value

	# 特殊效果（根据 effect_id）
	match card_data.effect_id:
		# ── Attack cards ──────────────────────────────────────────
		"":
			pass  # base damage only

		"cyber_slash_corrode":
			result.damage_dealt = 4
			result.apply_statuses_to_enemy.append({"type": "corruption", "value": 2, "turns": -1})

		"data_pierce_ignore_shield":
			result.damage_dealt = 3
			result.ignore_shield = true

		"flame_sigil_burn":
			result.damage_dealt = 5
			result.apply_statuses_to_enemy.append({"type": "burn", "value": 1, "turns": 2})

		"neon_flash_multi":
			result.damage_dealt = 3
			result.multi_hit = 2

		"quick_compile_draw":
			result.damage_dealt = 6
			result.cards_drawn = 1

		"poison_inject":
			result.damage_dealt = 4
			result.apply_statuses_to_enemy.append({"type": "corruption", "value": 3, "turns": -1})

		"dagger_rain_aoe":
			result.damage_dealt = 3
			result.multi_hit = 2
			result.aoe = true

		"dao_thorn_vulnerable":
			result.damage_dealt = 3
			result.apply_statuses_to_enemy.append({"type": "vulnerable", "value": 1, "turns": 1})

		"data_shatter_refund":
			result.damage_dealt = 8
			result.next_turn_energy = 1

		"dark_pulse_discard_trigger":
			result.unplayable_on_discard_damage = 7
			result.special_text = "不可打出；弃牌时对随机敌人造成7伤害"

		"disaster_algorithm":
			result.damage_dealt = 7
			result.conditional = "enemy_has_corruption"
			result.special_text = "若敌方有侵蚀，额外+7伤害"

		"thunder_chain_multi":
			result.damage_dealt = 4
			result.multi_hit = 3

		"core_breach":
			result.damage_dealt = 12
			result.enemy_attack_reduction = 2

		"finisher_protocol":
			result.damage_dealt = 2
			result.conditional = "count_attacks_played"
			result.special_text = "本回合每打出1张攻击牌，多击1次"

		"void_slash_kill_refund":
			result.damage_dealt = 10
			result.conditional = "kill_refund_2energy"
			result.special_text = "击杀时返还2算力"

		"precise_strike_conditional":
			result.damage_dealt = 8
			result.conditional = "not_damaged_this_turn"
			result.special_text = "本回合未受伤则伤害翻倍"

		"all_in_discard":
			result.discard_all = true
			result.damage_per_discard = 4
			result.special_text = "弃光手牌，每弃1张造成4伤害"

		"bone_erode":
			result.damage_dealt = 6
			result.conditional = "add_corruption_equal_stacks"
			result.special_text = "额外施加等同于敌方当前侵蚀层数的侵蚀"

		"pixel_storm_aoe":
			result.damage_dealt = 8
			result.aoe = true

		"strangle_protocol":
			result.damage_dealt = 10
			result.special_text = "本回合每打出1张牌，敌人额外失去3HP（BattleManager处理）"

		"elegant_finish":
			result.damage_dealt = 30
			result.conditional = "empty_discard_pile"
			result.special_text = "弃牌堆为空时才能造成伤害"

		"void_wrath":
			result.damage_dealt = 40
			result.exhaust = true

		"dao_judgement_multi":
			result.damage_dealt = 5
			result.multi_hit = 5

		"apocalypse_aoe":
			result.damage_dealt = 20
			result.aoe = true
			result.exhaust = true

		"data_flood_x":
			result.special_text = "X费：消耗所有算力，造成8*X伤害（BattleManager处理）"

		"glass_blade_grow":
			result.damage_dealt = 10
			result.special_text = "每场战斗永久+2伤害（BattleManager追踪）"

		# ── Defense cards ─────────────────────────────────────────
		"firewall_reflect":
			result.shield_gained = 5
			result.damage_dealt = 2
			result.special_text = "防火墙反射！"

		"yin_shield":
			result.shield_gained = 6

		"deflect_free":
			result.shield_gained = 3

		"spirit_guard_summon_shield":
			result.shield_gained = 4
			result.summon_shield = 3

		"backflip_draw":
			result.shield_gained = 5
			result.cards_drawn = 2

		"delayed_defense":
			result.shield_gained = 4
			result.apply_statuses_to_player.append({"type": "delayed_shield", "value": 4, "turns": 1})

		"talisman_purify":
			result.shield_gained = 5
			result.special_text = "清除玩家负面状态"

		"cloak_weave_token":
			result.shield_gained = 4
			result.generate_tokens = 1

		"code_armor":
			result.shield_gained = 10

		"thorn_armor":
			result.shield_gained = 4
			result.apply_statuses_to_player.append({"type": "reflect", "value": 3, "turns": 1})

		"afterimage_retain_shield":
			result.shield_gained = 6
			result.special_text = "护盾不衰减（BattleManager处理）"

		"leg_sweep":
			result.shield_gained = 12
			result.apply_statuses_to_enemy.append({"type": "weak", "value": 2, "turns": 2})

		"pixel_barrier_reflect":
			result.shield_gained = 8
			result.apply_statuses_to_player.append({"type": "reflect", "value": 4, "turns": 1})

		"harmony_light":
			result.shield_gained = 7
			result.yinyang_reduce_diff = 2

		"data_fortress_exhaust":
			result.shield_gained = 18
			result.exhaust = true

		"crippling_cloud":
			result.shield_gained = 4
			result.aoe = true
			result.apply_statuses_to_enemy.append({"type": "corruption", "value": 4, "turns": -1})
			result.apply_statuses_to_enemy.append({"type": "weak", "value": 2, "turns": 2})

		"spirit_scatter_discard":
			result.shield_gained = 5
			result.discard_count = 1

		"planned_well_retain":
			result.shield_gained = 5
			result.special_text = "保留（回合结束不弃）"

		"ghost_form":
			result.apply_statuses_to_player.append({"type": "intangible", "value": 2, "turns": 2})
			result.exhaust = true

		"settle_accounts":
			result.conditional = "shield_to_damage"
			result.aoe = true
			result.exhaust = true
			result.special_text = "将当前护盾转化为对所有敌人的伤害"

		"dao_bulwark":
			result.shield_gained = 12
			result.conditional = "resonance_bonus_8"
			result.special_text = "道境共鸣时额外+8护盾"

		"time_fold":
			result.shield_gained = 8
			result.extra_turn = true

		# ── Spell cards ───────────────────────────────────────────
		"dao_guidance":
			result.energy_change = 1
			result.cards_drawn = 1

		"preparation":
			result.cards_drawn = 1
			result.discard_count = 1

		"system_scan":
			result.cards_drawn = 3

		"glitch_wave":
			result.damage_dealt = randi_range(3, 9)
			result.apply_statuses_to_enemy.append({"type": "burn", "value": 1, "turns": 1})
			result.special_text = "Glitch波动！随机伤害 " + str(result.damage_dealt)

		"yinyang_reverse":
			result.cards_drawn = 1
			result.special_text = "阴阳逆转！场上阴阳值互换"

		"blade_dance":
			result.generate_tokens = 3

		"lethal_corrode":
			result.apply_statuses_to_enemy.append({"type": "corruption", "value": 5, "turns": -1})

		"seize_initiative":
			result.next_turn_energy = 2

		"catalyze":
			result.corruption_double = true
			result.exhaust = true

		"concentrate":
			result.discard_count = 3
			result.energy_change = 2

		"universal_balance":
			result.healing_done = 5
			result.heal_summons = 3
			result.special_text = "阴阳重置 + 治疗5 + 召唤物治疗3"

		"bounce_vial":
			result.special_text = "随机对敌方施加3次侵蚀（每次3层，BattleManager处理）"

		"dao_heart_cycle":
			result.unplayable_on_discard_energy = 1
			result.special_text = "不可打出；弃牌时获得1算力"

		"instinct_reaction":
			result.unplayable_on_discard_draw = 2
			result.special_text = "不可打出；弃牌时抽2张牌"

		"terror_data":
			result.apply_statuses_to_enemy.append({"type": "vulnerable", "value": 99, "turns": 99})

		"crazy_compile":
			result.random_zero_cost = 2

		"corpse_explode_spell":
			result.apply_statuses_to_enemy.append({"type": "corruption", "value": 6, "turns": -1})
			result.corpse_explode = true

		"bullet_time":
			result.zero_cost_hand = true
			result.no_draw = true

		"nightmare_copy":
			result.special_text = "复制手牌1张x2到下回合（BattleManager处理）"

		"system_reboot_shuffle":
			result.shuffle_discard_to_deck = true

		"dual_existence":
			result.discard_all = true
			result.copy_hand_next_turn = true

		"adrenaline":
			result.energy_change = 1
			result.cards_drawn = 2
			result.exhaust = true

		# ── Power cards ───────────────────────────────────────────
		"power_nimble_step":
			result.special_text = "永久：每次获得护盾时额外+2"

		"power_poison_protocol":
			result.special_text = "永久：每次攻击附加1层侵蚀"

		"power_infinite_blade":
			result.special_text = "永久：每回合开始获得1张数据碎片"

		"power_precision":
			result.special_text = "永久：数据碎片伤害+3"

		"power_thorns":
			result.special_text = "永久：受到攻击时反击3伤害"

		"power_afterimage":
			result.special_text = "永久：每打出1张牌获得1护盾"

		"power_lingchi":
			result.special_text = "永久：每打出1张牌对随机敌人造成2伤害"

		"power_poison_fog":
			result.special_text = "永久：每回合结束所有敌人获得2侵蚀"

		"power_essential_tools":
			result.special_text = "永久：每回合多抽1张，多弃1张"

		"power_dao_awakening":
			result.exhaust = true
			result.special_text = "永久：所有卡牌效果+30%"

	return result


## 计算道境共鸣加成
static func calc_resonance_bonus(yin: int, yang: int) -> Dictionary:
	var diff: int = absi(yin - yang)
	var bonus := {
		"energy_bonus": 0,
		"damage_bonus": 0,
		"is_resonance": false,
		"is_backlash": false,
	}

	if diff <= 2 and (yin + yang) > 0:
		bonus["energy_bonus"] = 1
		bonus["damage_bonus"] = 1
		bonus["is_resonance"] = true
	elif diff >= 4:
		bonus["damage_bonus"] = -2
		bonus["is_backlash"] = true

	return bonus


## 随机整数范围
static func randi_range(from: int, to: int) -> int:
	if from >= to:
		return from
	return randi() % (to - from + 1) + from
