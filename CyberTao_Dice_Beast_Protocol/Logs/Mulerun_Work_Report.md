# Mulerun 工作报告

**日期**: 2026-03-29
**版本**: v0.1.24
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- Day 8：棋盘格子事件化（棋盘走位层）

---

## 根因目标

让棋盘格子种类更丰富，走位路线选择更有策略意义。新增恢复格（持久回血）和事件格（一次性随机效果），使棋盘从 5 种可交互格子扩展到 7 种，形成"多条路线"的走位决策感。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `BoardManager.gd` | 新增 `heal_cells`、`event_cells` 字典；新增 `add_heal_cell()`、`add_event_cell()`、`clear_event_cell()` 方法；`build_test_board()`/`clear_board()` 清空新字典 |
| `BattleFlowController.gd` | 新增 `heal_cell_triggered`、`event_cell_triggered` 信号；新增 `_check_heal_cell()`（持久回血）、`_check_event_cell()`（随机三选一效果）；新增 `_spawn_debug_heal_cells()`（2 个回复格）、`_spawn_debug_event_cells()`（3 个事件格）；`try_move_unit()` 移动后增加恢复格和事件格检查；`_bootstrap()`/`restart_battle()` 调用新 spawn 方法 |
| `BoardView.gd` | 新增 `_draw_heal_cells()`（蓝白色填充+边框+"回复"+回复量）、`_draw_event_cells()`（黄紫色填充+边框+"?"标记）；新增 `play_heal_feedback()`（蓝色飘字）、`play_event_feedback()`（正面黄色/负面红色飘字）；`_draw()` 调用新绘制方法 |
| `DiceDebugPanel.gd` | 连接 `heal_cell_triggered`、`event_cell_triggered` 信号，触发后刷新 crest 池显示 |
| `Main.gd` | 连接 `heal_cell_triggered`、`event_cell_triggered` 信号；新增 `_on_heal_cell_triggered()`、`_on_event_cell_triggered()` 反馈处理；提示栏新增 "蓝白=回复 黄紫=事件" |

---

## 实现内容

1. **恢复格**（蓝白色）：持久地形，每次踩上回复 HP（不超过 max_hp），满血不触发
   - 调试布局：(5,6) 回复 2 HP、(1,3) 回复 3 HP
2. **事件格**（黄紫色 + "?" 标记）：一次性触发，踩后消失，随机三选一效果：
   - 正面：回复 1 HP
   - 正面：随机 +1 crest（6 种之一）
   - 负面：受到 1 点伤害（可致死触发胜负判定）
   - 调试布局：(3,5)、(6,3)、(4,6) 三个事件格
3. 棋盘现有 **7 种可交互格子**：路径/高台/陷阱/道具/遭遇/恢复/事件
4. 新增 2 个信号：`heal_cell_triggered`、`event_cell_triggered`
5. 完整反馈链：触发 → 信号 → 飘字（蓝色回复/黄色正面/红色负面）→ 面板刷新

---

## 调试棋盘布局总览（v0.1.24）

| 格子 | 位置 | 类型 |
|------|------|------|
| 高台格 | (2,4) (2,5) | terrain: high_ground |
| 陷阱格 | (1,5) (3,6) | terrain: trap |
| 道具格 | (4,5) 补丁凉茶, (2,6) 超频骨头 | item |
| 遭遇格 | (4,4) encounter_01, (6,5) encounter_02 | encounter |
| 恢复格 | (5,6) HP+2, (1,3) HP+3 | heal |
| 事件格 | (3,5) (6,3) (4,6) 随机效果 | event |
| 玩家单位 | (0,6) 刀盾狗, (1,7) 灵狐骇客, (0,5) 鸦机术士 | unit: player |
| 敌方单位 | (3,4) 哨兵甲, (5,3) 哨兵乙 | unit: enemy |

---

## 剩余问题

- **遭遇面板为纯占位** — 无实际卡牌战斗（Day 9 实现）
- **BuffManager.tick_turn() 仍未接入**
- **BUG-001 分辨率切换无效**（低优先级）

---

## 建议下一步

1. **Day 9：最小卡牌战斗原型** — 替换占位面板，接入简化版抽牌/出牌/结算
2. **Day 10~12 按周计划继续**
