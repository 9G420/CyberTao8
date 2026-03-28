# ============================================================
# CardData.gd - 卡牌数据资源类
# 使用Godot Resource系统，每张卡保存为.tres文件
# ============================================================
class_name CardData
extends Resource

## 卡牌类型枚举
enum CardType {
	ATTACK,    # 攻击
	DEFENSE,   # 防御
	SUMMON,    # 召唤
	SPELL,     # 术法
	POWER,     # 能力（打出后永久生效）
}

## 阴阳属性枚举
enum YinYang {
	YIN,       # 阴
	YANG,      # 阳
	NEUTRAL,   # 中性
}

## 卡牌唯一ID
@export var card_id: String = ""

## 卡牌名称
@export var card_name: String = ""

## 卡牌描述
@export_multiline var description: String = ""

## 算力消耗（-1 表示 X 费，消耗所有算力）
@export_range(-1, 6) var cost: int = 1

## 卡牌类型
@export var card_type: CardType = CardType.ATTACK

## 阴阳属性
@export var yinyang: YinYang = YinYang.NEUTRAL

## 阴阳数值（正=阳，负=阴，0=中性）
@export_range(-3, 3) var yinyang_value: int = 0

## 攻击力（攻击卡/召唤物攻击力）
@export_range(0, 20) var attack_power: int = 0

## 防御力/护盾值
@export_range(0, 20) var defense_power: int = 0

## 召唤物生命值
@export_range(0, 20) var summon_hp: int = 0

## 特殊效果描述（用字符串标识，由EffectSystem解析）
@export var effect_id: String = ""

## 卡牌稀有度: 0=普通, 1=稀有, 2=史诗
@export_range(0, 2) var rarity: int = 0

## 升级后版本的资源路径（空字符串=无法升级）
@export var upgraded_version: String = ""

## 可融合标记
@export var fusable: bool = false

## 融合结果资源路径
@export var fusion_result: String = ""

## 商店价格
@export_range(0, 100) var shop_price: int = 10

## 卡面颜色（像素风代表色）
@export var card_color: Color = Color.WHITE

## --- 新增关键词字段 ---

## 消耗：使用后移出本场战斗
@export var exhaust: bool = false

## 固有：战斗开始时必定在初始手牌
@export var innate: bool = false

## 保留：回合结束时不弃掉
@export var retain: bool = false

## 多段伤害次数（0=单段，>0=多段）
@export_range(0, 10) var multi_hit: int = 0

## 召唤物被动技能ID（由BattleManager解析）
@export var summon_passive: String = ""

## 不可打出标记（弃牌触发型卡牌）
@export var unplayable: bool = false

## 获取阴阳属性文本
func get_yinyang_text() -> String:
	match yinyang:
		YinYang.YIN: return "阴"
		YinYang.YANG: return "阳"
		_: return "中"

## 获取类型文本
func get_type_text() -> String:
	match card_type:
		CardType.ATTACK: return "攻击"
		CardType.DEFENSE: return "防御"
		CardType.SUMMON: return "召唤"
		CardType.SPELL: return "术法"
		CardType.POWER: return "能力"
		_: return "未知"

## 获取关键词标签文本（消耗/固有/保留/不可打出）
func get_keywords_text() -> String:
	var keywords: PackedStringArray = []
	if exhaust:
		keywords.append("消耗")
	if innate:
		keywords.append("固有")
	if retain:
		keywords.append("保留")
	if unplayable:
		keywords.append("弃牌触发")
	if keywords.is_empty():
		return ""
	return " ".join(keywords)

## 获取稀有度颜色
func get_rarity_color() -> Color:
	match rarity:
		0: return Color(0.7, 0.7, 0.7)      # 普通-灰白
		1: return Color(0.3, 0.6, 1.0)       # 稀有-蓝
		2: return Color(0.8, 0.3, 1.0)       # 史诗-紫
		_: return Color.WHITE
