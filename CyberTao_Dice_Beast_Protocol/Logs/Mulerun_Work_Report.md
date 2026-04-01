# Mulerun 工作报告

**日期**: 2026-04-02
**版本**: v0.1.94
**分支**: `codex/dice-beast-protocol`

## 本轮任务
- 修复 3D 最远距离单位不可见
- 新增中键按住拖拽调整 3D 视角
- 增强棋盘功能格 3D 立体识别

## 修改摘要
- `BoardView3D.gd`
  - 新增中键 Orbit 视角控制（Pitch/Yaw）
  - 右键继续平移，操作分离
  - 相机计算改为 `_camera_angle_deg + _camera_yaw_deg`
  - 远距单位缩放倍率上限提高（最远更容易看清）
- `UnitMeshFactory3D.gd`
  - 精灵像素尺寸微调，配合动态缩放防止近景过大
- `TileMeshFactory3D.gd`
  - 功能格增加 3D marker（箱体/棱柱/圆柱）
  - shop/chest 等可直接肉眼识别，不再等于平面2D

## 结果
- 3D 最远视角下单位可见性提升
- 可以按住鼠标滚轮键自由调视角
- 功能格有立体结构，棋盘层次明显增强
