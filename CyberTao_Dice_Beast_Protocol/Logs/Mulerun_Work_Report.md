# Mulerun 工作报告

**日期**: 2026-03-30
**版本**: v0.1.36
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- Day 18：卡牌升级机制

---

## 根因目标

牌组在多次遭遇后虽然可以通过奖励选牌扩充，但已有卡牌始终保持基础数值，导致后期战斗中基础牌（如斩击 3 伤害、防御 2 减伤）逐渐乏力。卡牌升级机制让玩家可以强化已有卡牌的数值而不增加牌组体积，引入"加新牌 vs 升级旧牌"的策略抉择，提升构筑深度。参考 STS（Slay the Spire）的升级模型。服务于卡牌战斗层。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/BattleV2/CardBattleController.gd` | 新增 card_upgrade_completed 信号；所有卡牌字典增加 upgraded 字段；新增 get_card_upgrade() 升级数据映射（14种牌）；新增 get_upgradeable_indices()、upgrade_deck_card() 方法；吸血斩增加 heal_value 字段支持升级后回复量变化 |
| `Project/Scripts/UI/CardRewardPanel.gd` | 重写为双模式面板：奖励模式（选新牌）+ 升级模式（升级旧牌）；新增"升级卡牌"/"返回选牌"切换按钮；升级模式合并同名牌并显示升级前后数值对比 |
| `Project/Scripts/UI/CardBattlePanel.gd` | 升级牌在手牌中使用青色按钮样式（区分于普通牌的橙色） |
| `Project/Scripts/UI/DeckViewPanel.gd` | 牌组查看面板支持显示升级状态，升级牌名称用青色高亮 |
| `Project/Scripts/UI/DiceDebugPanel.gd` | 版本号更新为 v0.1.36 |
| `Logs/Mulerun_Work_Report.md` | 本文件，Day 18 工作报告 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.36 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步更新至 v0.1.36 状态 |

---

## 实现内容

1. **卡牌升级数据定义**
   - 所有卡牌字典新增 `upgraded: bool` 字段（默认 false）
   - `get_card_upgrade(card)` 静态方法：输入基础牌字典，返回升级版本
   - 升级规则：名称加"+"后缀，费用不变，数值提升约 30%~50%
   - 14 种牌的升级映射全部定义完成

2. **升级数据表**

   | 卡牌 | 基础 | 升级后 |
   |------|------|--------|
   | 斩击 | 1E/3伤 | 斩击+ → 1E/4伤 |
   | 重击 | 2E/5伤 | 重击+ → 2E/7伤 |
   | 防御 | 1E/2防 | 防御+ → 1E/3防 |
   | 修复 | 1E/2回 | 修复+ → 1E/3回 |
   | 连斩 | 1E/2伤 | 连斩+ → 1E/3伤 |
   | 猛攻 | 3E/8伤 | 猛攻+ → 3E/11伤 |
   | 急救 | 2E/4回 | 急救+ → 2E/6回 |
   | 穿刺 | 2E/4穿 | 穿刺+ → 2E/6穿 |
   | 铁壁 | 2E/4防 | 铁壁+ → 2E/6防 |
   | 吸血斩 | 2E/3伤+1回 | 吸血斩+ → 2E/4伤+2回 |
   | 超频修复 | 3E/6回 | 超频修复+ → 3E/9回 |
   | 电弧 | 1E/2伤+ATK-1 | 电弧+ → 1E/3伤+ATK-1 |
   | 强化斩击 | 1E/4伤 | 强化斩击+ → 1E/6伤 |
   | 双重防御 | 1E/3防 | 双重防御+ → 1E/4防 |

3. **奖励面板双模式切换**
   - 胜利后面板默认显示 3 张奖励牌（原有功能）
   - 底部新增"升级卡牌"按钮，点击切换到升级模式
   - 升级模式：显示牌组中所有未升级的牌，同名牌合并，每张显示"当前值 → 升级值"
   - "返回选牌"按钮可切回奖励模式
   - 选择升级后调用 `upgrade_deck_card()` 原地替换持久牌组中的卡牌
   - 如果没有可升级的牌，"升级卡牌"按钮禁用

4. **视觉区分**
   - 手牌中升级牌使用青色按钮样式（普通牌为橙色）
   - 牌组查看面板中升级牌名称用青色高亮显示

---

## 接口变更

### 新增信号（CardBattleController）
- `card_upgrade_completed(old_card: Dictionary, new_card: Dictionary)` — 卡牌升级完成

### 新增方法（CardBattleController）
- `get_card_upgrade(card: Dictionary) -> Dictionary` — 静态，返回卡牌升级版本
- `get_upgradeable_indices() -> Array[int]` — 返回持久牌组中可升级卡牌索引
- `upgrade_deck_card(deck_index: int) -> void` — 升级指定索引卡牌

### 新增字段（卡牌字典）
- `upgraded: bool` — 是否已升级（所有卡牌字典均包含此字段）
- `heal_value: int` — 吸血斩回复量（基础 1，升级后 2）

---

## 测试确认

代码逻辑自查通过：
- `_build_deck()` 和 `_build_reward_pool()` 中所有卡牌字典均包含 `upgraded: false`
- `get_card_upgrade()` 对 14 种牌名逐一映射，未知牌名默认 value+1
- `get_upgradeable_indices()` 正确过滤已升级牌（检查 `upgraded` 字段）
- `upgrade_deck_card()` 仅在 REWARD_SELECT 状态执行，防止非法调用
- 升级后原地替换 `persistent_deck[index]`，下次战斗时 `start_battle()` 从持久牌组复制
- `_resolve_card()` 中 lifesteal 类型改为读取 `heal_value` 字段，兼容升级后回复量
- 奖励面板双模式切换不影响原有"选新牌"和"跳过"流程
- 升级模式合并同名牌，点击后升级该名称的第一张（持久牌组中的实际索引）
- 手牌按钮颜色区分正确：升级牌 cyan、普通牌 orange
- 牌组查看面板正确显示升级牌的青色高亮
- 棋盘层完整闭环不受影响：未触碰 BattleFlowController
- 卡牌层闭环正常：遭遇触发/卡牌战斗/出牌/敌方行动/选牌奖励/升级/HP同步均正常
- 重新开始后 `reset_persistent_deck()` 重建初始牌组，所有升级状态重置

---

## 剩余问题

- 升级只能在战斗胜利后的奖励阶段进行，没有其他升级入口（如商店格/休息格）
- 每次胜利只能选择"加新牌"或"升级一张旧牌"之一（设计选择，非 bug）
- 同名牌合并显示时只升级第一张，如有多张同名基础牌需多次战斗分别升级
- 升级数值为手工调优，未做数值平衡测试
- 已升级的牌不能再次升级（单次升级上限，与 STS 一致）

---

## 建议下一步

1. **Boss 遭遇**（中优先）— 特殊遭遇格触发 Boss 战（HP 高 + 独特模式）
2. **能量成长机制**（中优先）— 随游戏进度每回合能量上限+1
3. **BuffManager 接入**（中优先）— tick_turn 在回合流程中正式调用
4. **BattleFlowController 瘦身**（中优先）— 剥离逻辑到独立模块

---

## Codex 复审标注

1. **架构判断**：升级逻辑全部写在 CardBattleController 内部（新增约 60 行），未创建独立文件。理由：(a) 升级与牌组管理紧密相关，persistent_deck 就在 Controller 里；(b) 数据映射是纯静态方法，不增加状态复杂度；(c) Controller 从 424 行增长到约 490 行，仍在合理范围。如果后续升级规则变得更复杂（如多级升级、升级消耗资源），可提取到独立的 CardUpgradeManager。
2. **数值平衡**：升级幅度约 30%~50%，参考 STS 标准。斩击 3→4（+33%）、猛攻 8→11（+37%）、穿刺 4→6（+50%）。吸血斩的回复从 1→2 是较大提升，但考虑到 2E 费用和吸血类型的稀有性，应属合理。如果测试中发现某些升级过强或过弱，可在 `get_card_upgrade()` 中微调。
3. **UI 设计选择**：在奖励面板内集成升级功能而非新建面板，避免 UI 层级膨胀。双模式切换通过"升级卡牌"/"返回选牌"按钮实现，用户操作路径清晰。升级模式中同名牌合并显示是为了防止列表过长。
