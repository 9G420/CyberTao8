# AI Employee Guide v3 (Refactor Clean)

**更新时间**: 2026-04-05 00:42 SGT

## 会话启动规则
- 先读：`Execution_Command_Center.md`
- 再读：`Mechanic_Refactor_Plan_A.md`
- 再读：`Handoff_Package_latest.md`

## 执行规则
- 当前执行模式：方案A渐进式重构。
- 当前唯一任务：`A2_path_loop_resonance`。
- 禁止推倒式重构；必须保持可运行闭环。

## 交付规则
- 每轮结束必须同步：
  - `Execution_Command_Center.md`
  - `Handoff_Package_latest.md`
  - `Mulerun_Work_Report.md`
  - `changelog_v0.1.md`

## 用户口令规则（新增）
- 用户输入 `推进任务` 时：
  - 视为“按当前最高优先级任务直接开工”
  - 不等待额外确认，不重复提问
  - 先读取执行中枢与Rebirth锚点，再直接编码推进

## 方案替换规则（新增）
- 发现新的方案建议或任务规划后，必须在同一轮内完成：
  1. 更新活跃日志中的主任务与阶段定义
  2. 显式标记旧方案/旧任务为“已替换/已失效”
  3. 更新handoff，确保新对话不会读取旧方向

## 自动存档推送规则（新增）
- 日志与规划发生变更时，默认立即执行：
  - docs commit
  - push 到当前工作分支
- 除非用户明确要求“先不要推送”。
