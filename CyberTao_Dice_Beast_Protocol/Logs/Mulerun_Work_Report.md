# Mulerun 工作报告

**日期**: 2026-04-02
**版本**: v0.1.97
**分支**: `codex/dice-beast-protocol`

## 本轮任务
- 2D 中键视角调节改为可感知（更接近 3D 操作反馈）
- 棋盘外视觉改为独立背景区，不再延展棋盘格

## 修改
- `BoardView.gd`
  - 中键拖拽：左右调整 yaw offset、上下调整 pitch offset
  - 相机 target 计算统一使用 `(SCREEN_CENTER + yaw/pitch offset)`
- `IsoTileRenderer.gd`
  - `draw_board()` 改为只绘制真实棋盘格
  - 新增 `_draw_board_platform_bg()` 作为棋盘外“舞台背景区”

## 结果
- 2D 中键拖拽视角变化更明显
- 棋盘外与棋盘内形成清晰区分，沉浸感更接近你示意图方向
