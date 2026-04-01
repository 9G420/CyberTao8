# Mulerun 工作报告

**日期**: 2026-04-02
**版本**: v0.1.99
**分支**: `codex/dice-beast-protocol`

## 本轮修复
- 继续处理用户反馈：2D中键体感弱、棋盘会漂移、棋盘外仍偏黑

## 具体改动
- `BoardView.gd`
  - `_on_anim_tick`：非拖拽/非视角模式时，`_drag_offset` 缓慢回归 0，避免长时偏移累积
- `BoardView3D.gd`
  - `_process`：非拖拽/非orbit时，`_drag_offset_accumulated` 缓慢回正
- `IsoTileRenderer.gd`
  - `_draw_board_platform_bg`：外场平台底色和边缘高光整体提亮，确保与纯黑背景明显区分

## 结果
- 2D/3D 棋盘中心稳定性提升
- 棋盘外背景区更容易看出“平台外场”而非纯黑
- 2D 视角控制保留：中键拖拽 + Alt/Shift+右键拖拽（兼容路径）
