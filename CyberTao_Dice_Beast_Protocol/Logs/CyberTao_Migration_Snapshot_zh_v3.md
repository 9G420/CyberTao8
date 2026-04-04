# CyberTao Snapshot zh v3 (Refactor Clean)

**更新时间**: 2026-04-05 00:42 SGT  
**版本口径**: v0.1.117-dev

## 当前架构（精简）
- 主场景：`Project/Scenes/Main.tscn`
- 主入口：`Project/Scripts/Main.gd`
- 棋盘主控：`Project/Scripts/BattleV2/BattleFlowController.gd`
- 命令桥接层：`Project/Scripts/Core/Command.gd` / `CommandChain.gd` / `CommandExecutor.gd`
- 2D 棋盘：`Project/Scripts/UI/BoardView.gd`
- 3D 棋盘：`Project/Scripts/UI3D/BoardView3D.gd`

## 当前主线
- 方案A渐进式重构
- 当前唯一任务：`A2_path_loop_resonance`

## 接手提醒
- 先读 `Execution_Command_Center`，再读 `Mechanic_Refactor_Plan_A`。
