# Mulerun 工作报告

**日期**: 2026-03-30
**版本**: v0.1.38
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- Day 20：能量成长机制

---

## 根因目标

当前卡牌战斗每回合固定 3 点能量，无论玩家经历多少次遭遇。随着牌组通过奖励选牌和升级逐渐强化，高费卡牌（猛攻 3E、超频修复 3E）的使用受限于固定能量上限，导致后期构筑深度不足。能量成长机制让每次遭遇胜利后能量上限+1（Boss 胜利+2），上限 5，使玩家随游戏进度获得更多操作空间，与牌组成长形成正反馈循环。服务于卡牌战斗层。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/BattleV2/CardBattleController.gd` | 新增 INITIAL_MAX_ENERGY(3) 和 MAX_ENERGY_CAP(5) 常量；新增 energy_grown 信号；_win() 中遭遇胜利 max_energy+1、Boss 胜利+2（上限 5）；reset_persistent_deck() 重置 max_energy |
| `Project/Scripts/UI/CardBattlePanel.gd` | 连接 energy_grown 信号；新增 _on_energy_grown() 回调在战斗日志中显示能量提升 |
| `Project/Scripts/UI/CardRewardPanel.gd` | 奖励面板 deck_info_label 新增显示当前能量上限 |
| `Project/Scripts/UI/DeckViewPanel.gd` | 牌组查看面板 deck_size_label 新增显示当前能量上限 |
| `Project/Scripts/UI/DiceDebugPanel.gd` | 版本号更新为 v0.1.38 |
| `Logs/Mulerun_Work_Report.md` | 本文件，Day 20 工作报告 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.38 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步更新至 v0.1.38 状态 |

---

## 实现内容

1. **能量成长规则**
   - 初始 max_energy = 3（每回合 3 点能量）
   - 每次遭遇胜利后 max_energy += 1
   - Boss 遭遇胜利后 max_energy += 2
   - 能量上限 MAX_ENERGY_CAP = 5（不可超过）
   - 重新开始游戏时重置为 INITIAL_MAX_ENERGY = 3

2. **能量成长通知**
   - 新信号 `energy_grown(old_max, new_max)` 在能量实际提升时发射
   - CardBattlePanel 战斗日志显示"能量上限提升！3 → 4"
   - 已满上限（5）时不发射信号、不显示提示

3. **UI 信息同步**
   - 奖励选牌面板：deck_info_label 显示"当前牌组：X 张 | 能量上限：Y"
   - 牌组查看面板：deck_size_label 显示"牌组总数：X 张 | 能量上限：Y"
   - 战斗面板能量显示已有"能量：X / Y"，自动反映新上限

4. **持久化设计**
   - max_energy 跨战斗保留（与 persistent_deck 同级别持久状态）
   - start_battle() 中 `energy = max_energy` 使用当前上限
   - reset_persistent_deck() 同时重置 max_energy = 3

---

## 接口变更

### 新增信号（CardBattleController）
- `energy_grown(old_max: int, new_max: int)` — 能量上限提升时发射

### 新增常量（CardBattleController）
- `INITIAL_MAX_ENERGY: int = 3` — 初始能量上限
- `MAX_ENERGY_CAP: int = 5` — 能量上限天花板

---

## 测试确认

代码逻辑自查通过：
- `_win()` 中 growth 计算正确：普通遭遇 +1，Boss +2
- `min(MAX_ENERGY_CAP, max_energy + growth)` 确保不超过 5
- `max_energy > old_max` 条件判断：仅在实际提升时发射 energy_grown 信号
- `start_battle()` 中 `energy = max_energy` 正确使用持久化的上限值
- `reset_persistent_deck()` 重置 max_energy = INITIAL_MAX_ENERGY = 3
- CardBattlePanel 正确连接 energy_grown 信号，显示提升文案
- CardRewardPanel deck_info_label 正确显示能量上限
- DeckViewPanel deck_size_label 正确显示能量上限
- 棋盘层完整闭环不受影响：未触碰 BattleFlowController
- 卡牌层闭环正常：遭遇胜利 → 能量+1 → 下次战斗使用新上限
- 普通遭遇连续 2 次胜利：3→4→5，第 3 次胜利不再增长
- Boss 胜利：如从 3 开始直接到 5（3+2=5）
- 重新开始后 max_energy 回到 3

---

## 剩余问题

- 能量成长只在遭遇胜利时触发，没有其他获取途径（如商店格/事件格）
- 上限 5 点是否合理需要实际测试（5 点可以一回合出猛攻+连斩，可能过强）
- 逃跑或战败不增长能量（设计选择，非 bug）
- Boss 胜利 +2 是否过多待验证（如果玩家第一次就打 Boss，3→5 跳跃较大）

---

## 建议下一步

1. **BuffManager 接入**（中优先）— tick_turn 在回合流程中正式调用
2. **BattleFlowController 瘦身**（中优先）— 剥离逻辑到独立模块，目标降至 600 行以下
3. **更多格子类型**（中低优先）— 商店格、宝箱格
4. **多层地图**（中低优先）— 通关当前棋盘后进入下一层

---

## Codex 复审标注

1. **架构判断**：能量成长逻辑完全在 CardBattleController 内实现（新增约 10 行），未创建独立文件。理由：max_energy 本身就是 Controller 的核心状态变量，成长逻辑只是在 _win() 中加了 3 行。Controller 从约 505 行增长到约 515 行，仍在合理范围。

2. **数值设计**：初始 3 → 上限 5 的设计参考了 STS（STS 初始 3，通过遗物可达 4~5）。5 点能量允许一回合出 1 张 3E 牌 + 1 张 2E 牌，或 5 张 1E 牌，操作空间显著提升但不失控。Boss 胜利 +2 是因为 Boss 战难度显著高于普通遭遇，额外奖励合理。如果测试中发现 5E 过强，可将 MAX_ENERGY_CAP 改为 4。

3. **持久化一致性**：max_energy 的持久化模式与 persistent_deck 完全一致——跨战斗保留，reset 时重置。没有引入新的持久化机制或存储方式。
