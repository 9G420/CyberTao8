# Execution Command Center

**更新时间**: 2026-04-05 00:42 SGT  
**版本口径**: v0.1.117-dev  
**执行模式**: 方案A渐进式重构（允许重构，禁止推倒重来）

## 当前阶段
- Phase A：机制重构桥接阶段（Bridge）

## 当前唯一主任务
1. `A2_path_loop_resonance`

## A2 任务定义
- 在现有棋盘玩法上实现“最小闭环共鸣”。
- 先落地 1 条稳定规则（可触发、可反馈、可回归）。
- 至少在 2D 视图提供明确反馈。

## 验收标准
- 闭环可稳定触发。
- 不破坏移动/攻击/召唤/遭遇流程。
- `godot4 --headless --path Project --quit` 通过。

## 当前禁止事项
- 禁止一次性全系统重写。
- 禁止同轮“玩法大改 + 全UI重做”。
- 禁止改机制不更新日志。

## 新对话必读顺序
1. 本文件
2. `Logs/Mechanic_Refactor_Plan_A.md`
3. `Logs/Handoff_Package_latest.md`
4. `Logs/Mulerun_Work_Report.md`
5. `Logs/changelog_v0.1.md`（最近两条）

---

## 2026-04-05 00:57 SGT Hot Update
- Current phase: Phase A / Bridge stabilization
- Today main task: `A2_path_loop_resonance` (minimum playable version) completed
- Acceptance result:
  - Added player path loop detection in `BoardManager`
  - Added one-time-per-round path resonance trigger in `BattleFlowController`
  - Added 2D feedback hook in `Main` via `MainViewCoordinator`
  - `godot4 --headless --path Project --quit` passed (with historical resource-leak warnings)
- Next main task: `A3_enemy_counterplay`

---

## 2026-04-05 01:12 SGT Re-Alignment (Rebirth v1)
- Active anchor: `Logs/Rebirth_v1_Anchor.md`
- Active main task switched to: `RV1-P1_command_chain_playtest`
- New acceptance focus:
  - queue commands first, execute later
  - at least 2 commands can be chained in one player action phase
  - no regression on move/attack/summon and round flow
- New session required read order:
  1. `Logs/Execution_Command_Center.md`
  2. `Logs/Rebirth_v1_Anchor.md`
  3. `Logs/Handoff_Package_latest.md`
  4. `Logs/Mulerun_Work_Report.md`
  5. `Logs/changelog_v0.1.md` (latest 2 entries)

---

## 2026-04-05 01:32 SGT Next-Day Lock
- 明天开工默认执行任务: `RV1-P1.1_formal_command_chain_turnflow`
- 必做四步:
  1. 命令链编辑闭环（追加/删除最后一步/清空/执行）
  2. 执行前整链合法性预检（失败要给出第几步失败）
  3. GhostPath预演（显示执行后的走位与攻击落点）
  4. 执行后统一结算与UI刷新（防乱序、防卡死）
- 验收标准:
  - 玩家单回合可稳定编排并执行 >=2 条命令
  - 移动/攻击/召唤在命令链模式下不回归
  - `godot4 --headless --path Project --quit` 通过
- 若新对话未主动指定任务，必须先执行本节任务，不得跳过。

---

## 2026-04-05 01:18 SGT Workflow Protocol (User Locked)
- Trigger keyword: `推进任务`
- When user sends only `推进任务`, assistant must:
  1. Read this file + `Logs/Rebirth_v1_Anchor.md` + latest handoff
  2. Pick the highest-priority unfinished task
  3. Start implementation directly (no extra planning round-trip)
- Plan replacement rule:
  - If a newer scheme or priority appears, update active logs immediately and mark old task as superseded.
  - Never keep conflicting “current main task” definitions at the same time.
- Log sync rule (mandatory per round):
  - Update `Execution_Command_Center.md`
  - Update `Handoff_Package_latest.md`
  - Update `Mulerun_Work_Report.md`
  - Update `changelog_v0.1.md`
- Push rule:
  - For log/planning changes, create a dedicated docs commit and push immediately.
  - For gameplay code changes, commit and push after baseline validation (`headless` pass) unless user explicitly says local-only.
