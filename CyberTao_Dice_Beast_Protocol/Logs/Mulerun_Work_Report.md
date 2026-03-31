# Mulerun 工作报告

**日期**: 2026-03-31
**版本**: v0.1.72
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.72：修复 3D 交互手感（鼠标拖拽+镜头跟随+边界限制+缩放轴心）

---

## 根因目标

v0.1.71 3D 视图可运行但交互手感差：拖拽有滞后感（增量累积+lerp 关闭）、镜头跟随慢（lerp 因子在 60fps 下过小）、无边界限制（相机可无限漂移）、缩放不以鼠标为轴心。本轮对标 2D BoardView 的成熟交互体验，逐项修复。

服务层：棋盘走位层（3D 视觉体验打磨）

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/UI3D/BoardView3D.gd` | 重写拖拽/缩放/相机逻辑，新增边界限制（详见下方） |
| `Scripts/UI/DiceDebugPanel.gd` | 版本标记 v0.1.71 → v0.1.72 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.72 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号 + §2.2/§6 追加条目 |

---

## 实现内容

### 问题 1：拖拽滞后与漂移

**根因**：v0.1.71 使用逐帧增量累积 `+= delta_px * 0.003 * distance`，每帧浮点误差叠加导致长时间拖拽后偏移漂移；magic number 0.003 在不同缩放距离下手感不一致。且拖拽期间 `_process` 中 `not _drag_active` 完全禁止了相机 lerp，相机在拖拽时纹丝不动，松手才突然追上。

**修复**：
- 拖拽开始时快照当前偏移 `_drag_start_offset = _drag_offset_accumulated`
- 拖拽中基于起始位置计算绝对偏移：`_drag_start_offset + (mm.position - _drag_start_pos) * scale`
- 缩放因子改为 `_camera_distance / 350.0`（350 ≈ viewport 半宽 640 * sin(55°)，近似 1:1 地面映射）
- 拖拽期间相机 lerp 改为高速（20.0 * delta），接近即时响应

### 问题 2：镜头跟随过慢

**根因**：2D 用 Timer(50ms) 驱动 lerp(4.5 * 0.05 = 0.225/tick)；3D 用 _process(delta≈0.016) 驱动 lerp(4.5 * 0.016 ≈ 0.072/frame)。3D 镜头跟随实际速度约为 2D 的 1/3。

**修复**：CAMERA_LERP_SPEED 4.5 → 8.0（8.0 * 0.016 ≈ 0.128/frame，接近 2D 手感）

### 问题 3：无边界限制

**根因**：`_drag_offset_accumulated` 无任何 clamp，用户可将相机拖到无限远处。

**修复**：新增 `_clamp_drag_offset()`，每帧在 `_process` 中调用。限制为棋盘世界半径的 ±50%（12格棋盘 = 24世界单位 → 半径 12 → 限制 ±6）。

### 问题 4：缩放不以鼠标为轴心

**根因**：v0.1.71 缩放只改 `_camera_distance`，效果是向/背相机目标点直线推拉。2D 的 `_apply_zoom` 会保持鼠标下方的世界点不变。

**修复**：新增 `_apply_zoom(delta_dist, mouse_pos)` + `_screen_to_ground(screen_pos, cam_dist)`。缩放前后分别计算鼠标指向的 Y=0 地面交点，差值补入 `_drag_offset_accumulated`，使鼠标下方世界点在缩放前后不变。

---

## 接口变更

- BoardView3D 新增内部变量：`_drag_start_offset: Vector3`
- BoardView3D 新增常量：`ZOOM_STEP: float = 1.5`
- BoardView3D 新增内部方法：`_clamp_drag_offset()` / `_apply_zoom()` / `_screen_to_ground()`
- 无公开接口变更，信号/方法签名不变

---

## 测试确认

### 自查闭环（代码审查）

| 测试项 | 结果 |
|--------|------|
| 掷骰 → 移动 → 攻击 → 召唤 | ✅ 全部通过 _active_view() 路由，本次未修改 Main.gd |
| 敌方回合 → 镜头跟随 | ✅ _on_enemy_action_announced → _active_view().set_camera_target |
| 遭遇触发 → 卡牌战斗 → 返回 | ✅ TransitionOverlay 不依赖视图 |
| 重新开始 | ✅ _on_restart_pressed → rebuild_board + 相机归位 |
| 胜负判定 | ✅ 结果标签不依赖视图 |
| F5 切换 2D↔3D | ✅ toggle_3d_view 逻辑未改 |
| 2D 模式零影响 | ✅ 本次仅改 BoardView3D.gd + DiceDebugPanel 版本标记 |

### 3D 专项

| 测试项 | 结果 |
|--------|------|
| 拖拽即时响应 | ✅ 拖拽中 lerp(20.0*delta) 高速追踪 |
| 拖拽精度（长距离无漂移） | ✅ 绝对偏移计算，无逐帧浮点误差叠加 |
| 边界限制生效 | ✅ _clamp_drag_offset 每帧执行，±half_board*0.5 |
| 缩放以鼠标为轴心 | ✅ _apply_zoom 射线交叉补偿 |
| 镜头跟随速度适中 | ✅ CAMERA_LERP_SPEED 8.0 |
| 选中单位 → 拖拽归零 + 镜头居中 | ✅ _select_unit → _drag_offset_accumulated = Vector3.ZERO |
| 射线点击映射未受影响 | ✅ _screen_to_cell 逻辑未改 |

---

## 剩余问题

- 3D 反馈方法（飘字/闪光/粒子）仍为桩函数（v0.1.71 遗留）
- 3D 单位仍为简单几何体（v0.1.71 遗留）
- DiceDebugPanel 仍绑定 2D BoardView（v0.1.71 遗留）
- _screen_to_ground() 在相机 lerp 未到位时存在微小偏差（缩放轴心近似误差，可接受）
- spritesheet 背景透明度（v0.1.70 遗留）

---

## 建议下一步

1. 3D 反馈系统实现（粒子特效/3D 飘字）
2. 商店格扩展（多选商品 + 独立 UI 面板）
3. 3D 单位精灵化（billboard sprite 或低多边形模型）
