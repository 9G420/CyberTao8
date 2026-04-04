# Mechanic Refactor Plan A

**更新时间**: 2026-04-05 00:42 SGT  
**版本口径**: v0.1.117-dev

## 重构原则
- 采用渐进式重构：先桥接，再替换。
- 当前可玩闭环优先，禁止推倒式重做。
- 每轮都要可运行、可测试、可交接。

## 当前状态
- Bridge-1 已完成：
  - 已新增 `Command / CommandChain / CommandExecutor`
  - 玩家关键输入已接入 `execute_single_player_command(...)`

## 当前唯一主任务
1. `A2_path_loop_resonance`

## 后续任务队列
1. `A3_enemy_counterplay`
2. `A4_patch_card_bridge`

## 每轮必过检查
- `godot4 --headless --path Project --quit` 通过
- 基础战斗链路可用（移动/攻击/召唤/遭遇）
- 更新 `Execution_Command_Center` / `Handoff` / `Work_Report` / `changelog`
