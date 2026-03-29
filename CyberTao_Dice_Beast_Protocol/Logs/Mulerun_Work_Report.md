# Mulerun 工作报告

**日期**: 2026-03-29
**版本**: v0.1.18
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- 修复移动时误触召唤导致出现"分身"单位的 bug

---

## 根因/目标

### 根因
- `BoardView._handle_cell_click()` 的点击优先级为 attack > summon > move
- 当选中玩家单位且有 SUMMON crest 时，相邻空格同时出现在 `summon_highlight_cells` 和 `highlight_cells`（移动）中
- 由于 summon 优先于 move，用户点击相邻格意图移动时，实际触发了召唤
- 召唤在目标格生成 summoned_fox（4/4），用户看到"分身"

### 目标
- 确保移动优先于召唤
- 确保紫色召唤高亮不与青色移动高亮重叠，避免视觉误导

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/UI/BoardView.gd` | 点击优先级改为 attack > move > summon；添加 _filter_summon_cells() 过滤方法；_select_unit 和 _on_state_changed 使用过滤后的召唤高亮 |
| `Project/Scripts/Main.gd` | 所有高亮刷新点（_on_move/attack/summon_requested）使用 _filter_summon_cells 过滤 |
| `Logs/Mulerun_Work_Report.md` | 本报告 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.18 条目 |

---

## 实现内容

### 1. 点击优先级修正
- 原：attack → summon → move
- 新：attack → move → summon
- 确保有 MOVE crest 时，点击相邻空格执行移动而非召唤

### 2. 召唤高亮过滤
- 新增 `_filter_summon_cells(raw_summon_cells)` 方法
- 从召唤候选格中移除所有已在 `highlight_cells`（移动高亮）中的格子
- 效果：紫色高亮只出现在"不可移动但可召唤"的位置（通常是 MOVE crest 用完后的相邻格）

### 3. 全局刷新同步
- `_select_unit`、`_on_state_changed`、`_on_move_requested`、`_on_attack_requested`、`_on_summon_requested` 均使用过滤后的召唤高亮

---

## 当前剩余问题

- **调试面板"测试召唤"按钮不检查阶段** — 非 PLAYER_ACTION 时点击无效但按钮未禁用
- **召唤单位为 hardcoded** — 未接入 UnitData
- **路径格不影响移动规则** — 仅视觉标记

---

## 建议下一步

1. 在编辑器中验证本修复
2. 继续推进核心玩法：路径限制移动、召唤接入 UnitData
