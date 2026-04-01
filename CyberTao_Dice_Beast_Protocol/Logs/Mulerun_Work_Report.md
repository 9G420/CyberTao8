# Mulerun 工作报告

**日期**: 2026-04-02
**版本**: v0.1.93
**分支**: `codex/dice-beast-protocol`

## 本轮任务
- 修复 3D 模式单位近景溢出屏幕

## 根因
- 上一版通过 `Sprite3D.fixed_size=true` 提升远距可读性，但副作用是近景保持固定屏幕尺寸，导致角色巨大化。

## 修改
- `UnitMeshFactory3D.gd`
  - `fixed_size: true -> false`
  - `SPRITE_PIXEL_SIZE: 0.013 -> 0.0105`
- `BoardView3D.gd`
  - 新增 `_update_unit_readability_scale()`：根据 `_camera_distance` 动态调整 `Body` 缩放（远大近小）
  - 在 `_process()` 中每帧调用

## 结果
- 近景不再溢出屏幕
- 中远景单位仍保持可读性
