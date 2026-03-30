# Mulerun 工作报告

**日期**: 2026-03-30
**版本**: v0.1.52
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.51（P0）：修复 Boss/遭遇格击败消失 Bug
- v0.1.52（P1）：单位精简 — 1 主角 + 伙伴槽系统

---

## v0.1.52（P1）单位精简

### 目标

玩家出场单位从 3 个减为 1 个主角（blade_shield_dog），伙伴通过召唤系统部署，每层上限 2 次部署、场上上限 1 只伙伴。胜负判定改为英雄存活制。

### 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/BattleV2/BattleFlowController.gd` | 新增 `_summon_this_floor`/`SUMMON_FLOOR_LIMIT`/`SUMMON_FIELD_LIMIT`；`_spawn_player_units()` 精简为仅 blade_shield_dog；`get_summon_cells_for()`/`try_summon()` 增加层/场限制；`restart_battle()`/`advance_to_next_floor()` 重置 `_summon_this_floor`；`_spawn_player_units_with_hp()` 精简 |
| `Scripts/BattleV2/VictoryRuleHelper.gd` | 新增 `has_hero_unit()`（检查非 summoned 的存活玩家单位）；`get_battle_outcome()` 改为英雄存活制 |
| `Scripts/UI/DiceDebugPanel.gd` | `_refresh_crest_pool()` 末尾追加本层部署剩余次数显示 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.52 条目 |

### 实现细节

1. **出场单位精简**：`_spawn_player_units()` 和 `_spawn_player_units_with_hp()` 的 spawn_data 仅保留 blade_shield_dog 一条
2. **伙伴槽限制**：`get_summon_cells_for()` 在返回邻居格之前检查 `_summon_this_floor >= SUMMON_FLOOR_LIMIT` 和 `summoned_count >= SUMMON_FIELD_LIMIT`；`try_summon()` 同理，并在成功召唤后 `_summon_this_floor += 1`
3. **层间重置**：`restart_battle()` 和 `advance_to_next_floor()` 均 `_summon_this_floor = 0`
4. **胜负判定**：`VictoryRuleHelper.get_battle_outcome()` 使用 `has_hero_unit()` 替代 `has_units_for_owner("player")`，仅非 summoned 的玩家单位视为英雄
5. **HUD 显示**：DiceDebugPanel 在 Crest 池信息下方显示 `本层部署剩余：N 次`

### 接口变更

- `VictoryRuleHelper.has_hero_unit()` — 新增静态方法
- `VictoryRuleHelper.get_battle_outcome()` — 逻辑变更（hero_alive 替代 player_alive）
- `BattleFlowController.SUMMON_FLOOR_LIMIT` / `SUMMON_FIELD_LIMIT` — 新增常量
- `BattleFlowController._summon_this_floor` — 新增变量

### 自查确认

- `_spawn_player_units()` 仅生成 blade_shield_dog，无其他单位
- `_spawn_player_units_with_hp()` spawn_data 仅 blade_shield_dog 一条
- `get_summon_cells_for()` 和 `try_summon()` 均检查 SUMMON_FLOOR_LIMIT 和 SUMMON_FIELD_LIMIT
- `restart_battle()` 和 `advance_to_next_floor()` 均重置 `_summon_this_floor = 0`
- `has_hero_unit()` 正确过滤 summoned 标签
- `get_battle_outcome()` 使用 hero_alive 判定
- DiceDebugPanel 显示部署剩余，引用 `battle_flow.SUMMON_FLOOR_LIMIT - battle_flow._summon_this_floor`
- v0.1.50 传送门/Boss 锁定逻辑不受影响（仅在 resolve_encounter 胜利分支中）
- v0.1.51 三分支 resolve_encounter 不受影响（P1 不修改该函数）

---

## v0.1.51（P0）遭遇格击败消失 Bug 修复

### 根因

`resolve_encounter()` 无论胜败都调用 `board_manager.clear_encounter_cell()`，导致卡牌战斗失败后遭遇格被清除。

### 修复

- **胜利**：清除遭遇格 → Boss 时生成传送门 → 清空上下文 → 回到 PLAYER_ACTION → 发射 encounter_resolved 信号
- **失败但存活**：HP 保底 1 → 遭遇格保留 → 回到 PLAYER_ACTION，可再次挑战
- **失败且全灭**：触发 mark_defeat()

### 自查确认

- 胜利分支保留 is_boss + _spawn_portal_near（v0.1.50 传送门不受影响）
- 失败分支 HP 保底 max(1, remaining)，不出现 0 HP 存活
- 失败分支不调用 clear_encounter_cell
- 失败且全灭时正确触发 mark_defeat()

---

## 剩余问题

- 层间难度暂不递增（已排后）
- 阵亡单位跨层不复活
- CardRewardPanel 暂未使用 CardRenderer 风格

---

## 建议下一步

1. 美化 Phase 4.2：UI 过渡动画（宝可梦式全屏场景切换）
2. 层间难度递增
3. Crest 蓄力池 + 骰子操控机制
