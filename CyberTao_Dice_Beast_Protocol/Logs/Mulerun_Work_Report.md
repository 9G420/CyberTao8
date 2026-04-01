# Mulerun 工作报告

**日期**: 2026-04-02
**版本**: v0.1.100
**分支**: `codex/dice-beast-protocol`

## 用户反馈
- 2D 棋盘角度歪，不方正
- 拖拽后会自动回正到奇怪位置

## 处理策略
- 2D 暂停伪视角功能，优先恢复稳定、方正、可控构图

## 修改
- `BoardView.gd`
  - 禁用 2D orbit 输入路径（中键/Alt+右键）
  - 保留右键平移
  - 启动时重置 `_view_pitch_offset/_view_yaw_offset`
  - `_on_anim_tick` 改为仅依据 `_drag_active` 控制插值

## 结果
- 2D 构图恢复方正
- 拖拽后不会再回到“奇怪倾斜位置”
