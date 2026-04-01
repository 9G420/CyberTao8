# Mulerun 工作报告

**日期**: 2026-04-01
**版本**: v0.1.79
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.79：卡牌战斗层深化 — 4 种新卡牌 + 2 种新敌方行为 + 2 个新遭遇

---

## 根因目标

卡牌战斗层当前有 7 种奖励卡牌类型（attack/pierce/lifesteal/shock/defend/heal）和 3 种敌方行为模式（attack/heavy_attack/defend_attack + heal/mega_attack 仅Boss用）。随着商品池扩展（v0.1.78）让玩家能在棋盘层影响牌组构筑，卡牌战斗本身的策略深度需要同步提升。本轮新增毒素/抽牌/反击/连击 4 种机制性卡牌，以及 buff/multi_attack 两种敌方行为，配合 2 个使用新行为的遭遇敌方。

服务层：游戏玩法层（卡牌战斗机制深化）

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/BattleV2/CardBattleController.gd` | 新增 _poison_turns/_poison_dmg/_counter_dmg 状态变量；_resolve_card 4 种新卡牌类型；end_turn 毒素结算；_enemy_act buff/multi_attack + 反击触发；_update_enemy_intent 2 种新意图；奖励卡池 13→17；升级数据 +4；遭遇数据 +2（~546→~610行） |
| `Scripts/UI/CardRenderer.gd` | TYPE_COLORS/TYPE_ICONS/TYPE_LABELS 各 +4 项；_format_value +4 种格式 |
| `Scripts/BattleV2/BoardGenerator.gd` | ENCOUNTER_IDS 5→7 |
| `Scripts/Main.gd` | 遭遇显示名映射 +2 |
| `Scripts/UI/BattleCharRenderer.gd` | draw_enemy +2 分支；新增 _draw_quantum_splitter/_draw_cyber_shaman（~412→~480行） |
| `Scripts/UI/CardBattlePanel.gd` | _on_enemy_intent_changed +2 种意图图标（连续/强化） |
| `Scripts/UI/DiceDebugPanel.gd` | 版本标记 v0.1.78 → v0.1.79 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.79 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号 + §2.2/§2.3/§2.4/§3.1/§6 更新 |
| `Logs/Handoff_Package_latest.md` | 覆盖为 v0.1.79 交接包 |

---

## 实现内容

### 新卡牌：毒素注入（poison）

- cost 1，施加毒素效果（2伤/回合），持续 value 回合（基础3回合，升级后4回合）
- 多次使用可叠加回合数（_poison_turns += value）
- 毒素在 end_turn 中结算，敌方行动前生效（可在敌方出手前击杀）
- 如果毒素击杀敌方，直接触发 _win()

### 新卡牌：能量虹吸（draw）

- cost 0，额外抽 value 张牌（基础2张，升级后3张）
- 抽牌逻辑复用现有 draw_pile + _reshuffle 系统
- 抽牌后立即触发 hand_changed 信号更新 UI

### 新卡牌：反击（counter）

- cost 1，获得 def_value 点防御（基础2，升级后3）+ 蓄力 value 点反击伤害（基础3，升级后4）
- 反击通过 _counter_dmg 变量存储，在敌方执行攻击类行为时触发
- _resolve_counter() 统一处理：attack/heavy_attack/defend_attack/mega_attack/multi_attack 均触发
- 反击伤害直接穿透，不受敌方防御影响

### 新卡牌：裂空斩（combo）

- cost 2，hits 次攻击（基础3次），每次 value 伤害（基础2，升级后3）
- 每次攻击独立计算敌方防御减免：max(1, value - _enemy_def_bonus)
- 每次攻击消耗敌方防御：_enemy_def_bonus = max(0, _enemy_def_bonus - value)
- 对高防敌方效果大幅减弱（设计意图：多段攻击被防御克制）

### 新敌方行为：buff

- 敌方 ATK 永久+1
- 意图预告："强化（ATK+1）"
- 使长战斗中敌方威胁持续递增（量子分裂体 5 回合循环含 1 次 buff）

### 新敌方行为：multi_attack

- 敌方连续攻击 2 次，每次 60% ATK（向上取整至少1）
- 总伤害约 120% ATK，但分别受玩家防御减免
- 意图预告："连续攻击（Xx2）"
- 对有防御的玩家比 heavy_attack 弱，对无防御的玩家比普通攻击强

### 新遭遇：encounter_06 量子分裂体

- HP 7 / ATK 2，模式：攻→强化→连击→攻→重击（5回合循环）
- 定位：成长型 — ATK 持续增长，需要速战速决
- 立绘：紫色菱形晶体 + 浮动碎片 + 中心裂缝光

### 新遭遇：encounter_07 赛博巫医

- HP 11 / ATK 2，模式：强化→防击→治疗→重击→攻（5回合循环）
- 定位：持久型 — 高 HP + 治疗回复 + ATK 增长，需要高爆发或毒素持续压制
- 立绘：绿色兜帽三角形 + 法杖顶部光球

---

## 接口变更

- **CardBattleController 新增内部变量**：`_poison_turns`、`_poison_dmg`、`_counter_dmg`
- **CardBattleController 新增内部方法**：`_resolve_counter() -> String`
- **CardRenderer TYPE_COLORS/TYPE_ICONS/TYPE_LABELS** 新增 poison/draw/counter/combo
- **无外部信号变更**

---

## 测试确认

### 自查闭环（代码审查）

| 测试项 | 结果 |
|--------|------|
| 毒素施加 → 每回合结算 → 回合到期消散 | ✅ end_turn 中 _poison_turns 递减 |
| 毒素击杀敌方 → 触发胜利 | ✅ enemy_hp <= 0 检查后调用 _win() |
| 能量虹吸 cost 0 → 抽牌 → hand_changed | ✅ 抽牌后 emit hand_changed |
| 反击蓄力 → 敌方攻击 → 触发反击伤害 | ✅ _resolve_counter() 在所有攻击类行为后调用 |
| 反击对非攻击行为（heal/buff）不触发 | ✅ heal/buff 分支未调用 _resolve_counter() |
| 连击 vs 高防敌方 → 每击减免 | ✅ 每击独立计算 max(1, value - _enemy_def_bonus) |
| buff 行为 → ATK 永久增加 | ✅ enemy_atk += 1 |
| multi_attack → 2 次独立伤害 | ✅ for _i in range(2) 循环 |
| 新遭遇在棋盘生成 | ✅ BoardGenerator.ENCOUNTER_IDS 包含 06/07 |
| 新遭遇受层间缩放 | ✅ get_encounter_enemy_data floor_offset 逻辑不变 |
| 新遭遇显示名正确 | ✅ Main._get_encounter_display_name 映射已添加 |
| 新遭遇立绘绘制 | ✅ BattleCharRenderer.draw_enemy 分支已添加 |
| 新卡牌在商店 add_card 可获得 | ✅ _build_reward_pool 包含新卡牌 |
| 新卡牌渲染正确（颜色/图标/数值） | ✅ CardRenderer TYPE 字典均已添加 |
| start_battle 重置毒素/反击状态 | ✅ _poison_turns=0, _counter_dmg=0 |

---

## 剩余问题

- spritesheet 背景透明度（v0.1.70 遗留）
- DiceDebugPanel 仍绑定 2D BoardView（v0.1.71 遗留）
- ATK/DEF 商店提升未走 BuffManager（v0.1.73 设计取舍）
- remove_card 自动选择最弱牌（v0.1.78 设计取舍）
- 敌方/召唤单位使用程序化图标，无独立美术资源
- 新卡牌/新敌方数值未经平衡测试
- 电弧 ATK-1 效果永久（应为单场，但当前 enemy_atk 在战斗间不保留，实际无问题）

---

## 建议下一步

1. 敌方单位美术资源（替换程序化图标为独立 spritesheet）
2. 数值平衡调优（卡牌/敌方/商品/复活回复）
3. 商店 remove_card 手动选择UI

## Codex 复审标注（可选）

- 毒素伤害 _poison_dmg=2 是常量，不随毒素叠加增加（只叠加回合数）。如需叠加伤害，改为 _poison_dmg += card_value 即可
- 反击 _counter_dmg 在 _resolve_counter() 中一次性消耗为 0。如需持续反击（如"荆棘"效果），去掉 _counter_dmg = 0 即可
- combo 连击对 _enemy_def_bonus 的消耗是设计性的：第一击被减免，后续击穿透。这使得 combo 成为破防手段
- 量子分裂体的 buff 行为在 5 回合循环中出现 1 次。如果战斗持续 15 回合，ATK 会从 2 增长到 5（3层时从 4 到 7），这是有意的时间压力
- multi_attack 的 60% 取整使用 int(float(enemy_atk) * 0.6)，对 ATK=2 的敌方每击 1 伤害（总 2），ATK=3 则每击 1（总 2），ATK=5 每击 3（总 6）
