# Mulerun 工作报告

**日期**: 2026-04-02
**版本**: v0.1.95
**分支**: `codex/dice-beast-protocol`

## 本轮任务
- 2D 增加中键按住拖拽视角调节
- 3D 去除棋盘外黑边，增强沉浸环境
- 3D 最远距离单位可见性继续增强

## 实现
- `BoardView.gd`
  - 新增 `_orbit_active` 2D 中键视角模式
  - 中键拖拽：上下调整 `_view_pitch_offset`，左右微调缩放
  - `set_camera_target/_apply_zoom` 统一接入 pitch 偏移
- `BoardView3D.gd`
  - `rebuild_board()` 改为主棋盘外扩 `ambient_pad=8` 圈环境地台
  - 外环 tile 采用暗化调制，形成“棋盘内外”层次
  - `_update_unit_readability_scale` 上限提高到 `2.8`

## 结果
- 2D 支持中键调视角（操作与 3D 更一致）
- 3D 棋盘外不再是纯黑边，沉浸感明显提升
- 3D 最远视角单位更可见
