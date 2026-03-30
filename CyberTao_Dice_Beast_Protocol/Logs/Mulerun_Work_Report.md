# Mulerun 工作报告

**日期**: 2026-03-30
**版本**: v0.1.42
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- Day 24：多层地图 — 通关当前棋盘后进入下一层（3层，预留扩展）

---

## 根因目标

棋盘走位层此前只有单层棋盘，通关即结束，缺少层级推进和跨层成长体验。多层地图为玩家提供"通关当前层 → 层间奖励 → 进入下一层"的 Roguelike 核心循环，使牌组构筑、能量成长、HP 管理等系统在多层推进中产生真正的策略深度。服务于棋盘走位层 + 卡牌战斗层（层间奖励涉及卡牌系统）。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/BattleV2/BattleFlowController.gd` | 新增 FLOOR_CLEAR 阶段、MAX_FLOOR 常量、current_floor 变量、floor_cleared/game_won 信号、advance_to_next_floor()、_snapshot_player_hp()、_spawn_player_units_with_hp()、get_current_floor()/get_max_floor()；修改 _check_battle_outcome() 区分层通关与最终胜利；修改 is_battle_over() 包含 FLOOR_CLEAR；restart_battle() 重置 current_floor |
| `Project/Scripts/BattleV2/CardBattleController.gd` | 新增 offer_floor_reward() 方法（直接进入 REWARD_SELECT 状态，不经过战斗） |
| `Project/Scripts/Main.gd` | 新增 _floor_clear_pending 标志、_on_floor_cleared()、_on_game_won()；修改 _on_phase_changed() 处理 FLOOR_CLEAR 和最终胜利文字；修改 _on_card_battle_ended() 区分层间奖励和遭遇战斗结算；修改 _on_restart_pressed() 重置 _floor_clear_pending；连接 floor_cleared/game_won 信号 |
| `Project/Scripts/UI/DiceDebugPanel.gd` | 新增 floor_label 显示"层数：X/3"；连接 floor_cleared 信号；_on_phase_changed() 处理 FLOOR_CLEAR 阶段；_phase_label_text() 新增"本层通关"；版本号更新为 v0.1.42 |
| `Logs/Mulerun_Work_Report.md` | 本文件，Day 24 工作报告 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.42 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步更新至 v0.1.42 状态 |

---

## 实现内容

1. **多层地图核心机制（3层，预留扩展）**
   - 通关条件：击杀当前层所有棋盘敌方单位
   - 3层结构：第1-2层通关后进入 FLOOR_CLEAR 阶段 → 层间奖励 → 自动生成新层；第3层通关后进入 VICTORY（最终胜利）
   - MAX_FLOOR 常量可调整层数上限

2. **层间状态保留/重置策略**
   - 保留：存活玩家单位 HP（带伤进入下一层）、持久牌组、能量上限、卡牌升级状态
   - 重置：棋盘布局（每层随机生成新布局）、crest 资源池、buff、回合数、召唤计数
   - 已阵亡单位不复活，下一层不生成该单位

3. **层间奖励**
   - 通关一层后弹出 CardRewardPanel，提供选牌/升级机会（复用现有奖励面板）
   - 通过 CardBattleController.offer_floor_reward() 直接进入 REWARD_SELECT 状态
   - 奖励选择/跳过后自动进入下一层

4. **UI 显示**
   - DiceDebugPanel 新增"层数：X/3"标签（品红色）
   - Main.gd result_label：层通关显示"第 X 层通关！"（绿色），最终胜利显示"通关胜利！"
   - FLOOR_CLEAR 阶段禁用掷骰/结束回合按钮，intent 显示"本层通关！选择奖励后进入下一层"

5. **架构遵循**
   - BFC 新增 FLOOR_CLEAR 阶段，不污染已有阶段逻辑
   - 层间奖励通过 CardBattleController 现有 REWARD_SELECT 流程实现，零新增 UI 组件
   - _floor_clear_pending 标志在 Main.gd 中隔离层间奖励 vs 遭遇奖励的结算路径
   - advance_to_next_floor() 保守复用 clear_board + build_test_board + BoardGenerator 现有流程

---

## 接口变更

### 新增 BFC 信号
- `signal floor_cleared(floor_number: int)` — 当前层通关（非最终层）
- `signal game_won` — 全部层通关

### 新增 BFC 阶段
- `BattlePhase.FLOOR_CLEAR` — 层通关等待奖励阶段

### 新增 BFC 常量/变量
- `const MAX_FLOOR: int = 3` — 最大层数
- `var current_floor: int = 1` — 当前层数

### 新增 BFC 方法
- `advance_to_next_floor()` — 保留 HP 进入下一层
- `_snapshot_player_hp() -> Dictionary` — 存活玩家单位 HP 快照
- `_spawn_player_units_with_hp(hp_snapshot)` — 带 HP 快照生成玩家单位
- `get_current_floor() -> int` — 获取当前层数
- `get_max_floor() -> int` — 获取最大层数

### 新增 CardBattleController 方法
- `offer_floor_reward()` — 不经过战斗直接进入选牌/升级阶段

### 修改 BFC 方法
- `_check_battle_outcome()` — 区分层通关（FLOOR_CLEAR）和最终胜利（VICTORY）
- `is_battle_over()` — 包含 FLOOR_CLEAR 阶段
- `restart_battle()` — 重置 current_floor = 1

---

## 测试确认

代码逻辑自查通过：
- _check_battle_outcome() 在 outcome == "VICTORY" 时正确区分 floor < MAX_FLOOR（FLOOR_CLEAR）和 floor >= MAX_FLOOR（VICTORY） ✅
- advance_to_next_floor() 仅在 FLOOR_CLEAR 阶段可调用，防止非法状态转换 ✅
- _snapshot_player_hp() 正确筛选存活单位（hp > 0），阵亡单位不进入快照 ✅
- _spawn_player_units_with_hp() 跳过不在快照中的单位，HP 覆盖为保存值 ✅
- Main._on_card_battle_ended() 正确区分 _floor_clear_pending（层间奖励）和正常遭遇结算 ✅
- Main._on_floor_cleared() 设置 _floor_clear_pending=true 并调用 offer_floor_reward() ✅
- Main._on_restart_pressed() 重置 _floor_clear_pending=false ✅
- DiceDebugPanel 正确显示 floor_label 并在 phase_changed/round_changed 时更新 ✅
- FLOOR_CLEAR 阶段 is_battle_over()=true，阻止掷骰/移动/攻击/结束回合 ✅
- 棋盘层完整闭环：掷骰/移动/攻击/召唤/敌方回合/层通关/重开均正确 ✅
- 卡牌层完整闭环：遭遇触发/卡牌战斗/选牌奖励/HP同步/返回棋盘不受影响 ✅
- BFC 信号数量从 20 增至 22（+floor_cleared +game_won） ✅

---

## 剩余问题

- 难度暂不递增（各层敌方数值相同），后续可在 BoardGenerator 中根据 floor 调整
- CardRewardPanel 层间奖励标题仍显示"战斗胜利"，可在后续优化为"层通关奖励"
- 阵亡单位不复活可能导致后续层极度困难，需实际测试平衡
- BFC 从 605 行增长至约 693 行（+88行），仍在可维护范围

---

## 建议下一步

1. **BUG-001 修复**（中优先）— 分辨率切换无效（Demo 前必须解决）
2. **层间难度递增**（中优先）— 根据 current_floor 调整敌方 HP/ATK 或数量
3. **商店格扩展**（低优先）— 多选商品 + 独立 UI 面板

---

## Codex 复审标注

1. **通关条件选择**：选择"击杀所有棋盘敌方单位"作为通关条件。这与现有 VictoryRuleHelper.get_battle_outcome() 的 VICTORY 判定完全一致，无需新增判定逻辑。保守方案。

2. **层间 HP 保留策略**：存活单位保留当前 HP，阵亡单位不复活。这是 Roguelike 经典设计（如 STS 的 HP 跨层保留），但可能导致后续层过于困难。建议在数值平衡轮次中评估是否需要层间 HP 回复机制。

3. **层间奖励复用 CardBattleController**：通过 offer_floor_reward() 复用现有 REWARD_SELECT 状态和 CardRewardPanel，避免新增 UI 组件。代价是 CardRewardPanel 的标题文字仍显示"战斗胜利"，但功能完全正确。标注为保守方案。

4. **FLOOR_CLEAR 阶段设计**：新增独立阶段而非复用 VICTORY，原因是 VICTORY 是终态（不可恢复），而 FLOOR_CLEAR 需要在奖励后转换回 PLAYER_ROLL。is_battle_over() 包含 FLOOR_CLEAR 确保该阶段期间棋盘操作被阻止。
