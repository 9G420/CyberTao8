# Mulerun 工作报告

**日期**: 2026-03-30
**版本**: v0.1.51
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.51（P0）：修复 Boss/遭遇格击败消失 Bug

---

## 根因目标

`resolve_encounter()` 无论胜败都调用 `board_manager.clear_encounter_cell()`，导致卡牌战斗失败后遭遇格被清除。玩家回到棋盘后单位存活（HP 保底 1）但遭遇格消失，无法重新挑战，也不触发 DEFEAT，棋盘进入无意义状态。这是一个阻塞性 Bug，必须优先修复。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/BattleV2/BattleFlowController.gd` | `resolve_encounter()` 重写为三分支判断（胜利/失败存活/失败全灭） |
| `Scripts/Main.gd` | `_on_card_battle_ended()` 新增失败反馈飘字 |
| `Logs/AI_Employee_Guide_v3.md` | §7 新增版本顺延规则，§10 新增任务单不一致处理规则 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.51 条目 |

---

## 实现内容

### resolve_encounter() 三分支重写

- **胜利（victory=true）**：清除遭遇格 → Boss 时生成传送门 → 清空上下文 → 回到 PLAYER_ACTION → 发射 encounter_resolved 信号
- **失败但单位存活（victory=false, any_player_alive=true）**：HP 同步（保底1）→ 遭遇格保留（不调用 clear_encounter_cell）→ 清空 _encounter_unit_id/_encounter_id → 回到 PLAYER_ACTION，玩家可再次挑战
- **失败且全灭（victory=false, any_player_alive=false）**：清空上下文 → 触发 mark_defeat()

### Main.gd 失败反馈

- `_on_card_battle_ended()` 新增 `elif not victory` 分支，调用 `play_encounter_feedback(cell, "战斗失败...")` 提示玩家遭遇格仍在

---

## 接口变更

### 修改

- `BattleFlowController.resolve_encounter()` 逻辑重写（函数签名不变）
  - 失败时不再调用 `clear_encounter_cell()`
  - 失败时不再调用 `_check_battle_outcome()`（改为直接检查存活状态）
  - 失败时不发射 `encounter_resolved` 信号（遭遇未真正结束）

### 无变化

- CardBattleController 零修改
- CardBattlePanel 零修改
- BoardManager 零修改
- VictoryRuleHelper 零修改

---

## 测试确认

代码审查确认：
- 胜利分支保留了 is_boss + _spawn_portal_near 逻辑（v0.1.50 传送门机制不受影响）
- 失败分支 HP 保底 max(1, player_hp_remaining)，不会出现 0 HP 存活
- 失败分支不调用 clear_encounter_cell，遭遇格确实保留
- 失败且全灭时正确触发 mark_defeat()
- _floor_clear_pending 层间奖励逻辑在 _on_card_battle_ended 前置 return，不受影响
- 基础闭环（掷骰/移动/攻击/敌方回合/重开）不涉及 resolve_encounter，不受影响

---

## 剩余问题

- 层间难度暂不递增（已排后）
- 阵亡单位跨层不复活
- CardRewardPanel 暂未使用 CardRenderer 风格

---

## 建议下一步

1. **P1（v0.1.52）**：单位精简 — 1 主角 + 伙伴槽系统
2. 美化 Phase 4.2：UI 过渡动画
3. 层间难度递增

---

## Codex 复审标注

1. **失败时不发射 encounter_resolved 信号**：这是有意设计——遭遇格仍存在，不应通知下游"遭遇已清除"。DiceDebugPanel 的 _on_encounter_resolved 回调会隐藏 encounter_panel 并显示"遭遇已清除"文字，失败时不应触发这些。但这意味着失败后 encounter_panel 仍然可见，需要在 _on_phase_changed PLAYER_ACTION 中隐藏（现有代码已在非 ENCOUNTER 阶段隐藏 encounter_panel，所以实际上是正确的）。
