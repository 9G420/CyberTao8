# Mulerun 工作报告

**日期**: 2026-04-01
**版本**: v0.1.74
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.74：3D 反馈系统实现（9 个桩函数全部替换为 Label3D 漂浮文字 + CPUParticles3D 命中粒子 + PlaneMesh 格子闪光 + 相机震动）

---

## 根因目标

v0.1.71 引入 3D 棋盘视图后，所有 9 个反馈方法（攻击/拾取/预警/遭遇/治疗/事件/商店/宝箱/敌方移动指示）均为 `pass` 桩函数。3D 模式下任何战斗交互都没有视觉反馈，体验空白。本轮实现完整 3D 反馈系统，与 2D 版功能对齐。

服务层：棋盘走位层（3D 表现层完善）

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/UI3D/BoardView3D.gd` | 9 个桩函数替换为完整 3D 实现 + 4 个辅助方法（~130 行新增）+ `_feedback_root` 容器 + `_shake_offset` 相机震动变量 |
| `Scripts/UI/DiceDebugPanel.gd` | 版本标记 v0.1.73 → v0.1.74 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.74 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号 + §2.2/§3.1/§5/§6 更新 |

---

## 实现内容

### 3D 反馈系统（4 个辅助方法 + 9 个公开方法）

**辅助方法**：

| 方法 | 技术 | 说明 |
|------|------|------|
| `_spawn_float_text_3d()` | Label3D + billboard + Tween | 带黑色描边的 3D 漂浮文字，上升 + 渐隐 + 自动释放，支持延迟参数 |
| `_spawn_cell_flash_3d()` | PlaneMesh + StandardMaterial3D + emission | 半透明发光平面叠在目标格子上方，自发光渐隐后释放 |
| `_shake_camera_3d()` | Tween + _shake_offset | 6 步衰减抖动，通过变量驱动在 _process 中叠加到相机位置 |
| `_spawn_hit_particles_3d()` | CPUParticles3D + SphereMesh | 球形粒子向上爆散，颜色渐变透明，击杀时增强 |

**反馈方法对齐表**：

| 方法 | 3D 效果 |
|------|---------|
| `play_attack_feedback` | 闪光 + 震动 + 粒子 + 伤害飘字 + 击杀文字（5 层效果） |
| `play_pickup_feedback` | 绿色漂浮文字 |
| `play_enemy_warning` | 红色双次脉冲闪光 |
| `play_enemy_move_indicator` | 橙色漂浮文字 |
| `play_encounter_feedback` | 橙色大号漂浮文字 |
| `play_heal_feedback` | 蓝色漂浮文字 |
| `play_event_feedback` | 金色/红色漂浮文字（根据 is_positive） |
| `play_shop_feedback` | 青色漂浮文字 |
| `play_chest_feedback` | 金色大号漂浮文字 |

**设计取舍**：
- 使用 CPUParticles3D 而非 GPUParticles3D，因为项目使用 gl_compatibility 渲染器
- Label3D 设置 `no_depth_test = true` 确保文字不被格子遮挡
- 相机震动通过 `_shake_offset` 变量间接驱动（不直接修改 camera.position 动画目标，避免与 lerp 跟随冲突）
- 所有临时节点统一挂载到 `_feedback_root`，与格子/单位/高亮层分离
- `play_enemy_warning` 用 `get_tree().create_timer()` 实现第二次延迟闪烁，并通过 `is_instance_valid(self)` 安全检查

---

## 接口变更

- **无新增/删除公开接口**：9 个方法签名与 v0.1.71 桩函数完全一致，仅内部实现变化
- **新增内部方法**：`_spawn_float_text_3d()`、`_spawn_cell_flash_3d()`、`_shake_camera_3d()`、`_spawn_hit_particles_3d()`
- **新增变量**：`_feedback_root: Node3D`、`_shake_offset: Vector3`

---

## 测试确认

### 自查闭环（代码审查）

| 测试项 | 结果 |
|--------|------|
| 掷骰 → 移动 → 攻击 → 召唤 | ✅ 不涉及本次修改 |
| 敌方回合 → 镜头跟随 | ✅ 不涉及（_shake_offset 在震动结束后归零） |
| 遭遇触发 → 卡牌战斗 → 选牌奖励 → HP同步回棋盘 | ✅ 不涉及 |
| 重新开始 | ✅ _feedback_root 子节点 Tween 结束自动 queue_free |
| 胜负判定 | ✅ 不涉及 |
| 3D 攻击反馈：闪光+震动+粒子+飘字 | ✅ play_attack_feedback 调用 4 个辅助方法 |
| 3D 击杀反馈：增强闪光+大震动+更多粒子+金色飘字+KILL文字 | ✅ is_kill 分支全部增强 |
| 3D 治疗/拾取/事件/商店/宝箱/遭遇飘字 | ✅ 各方法调用 _spawn_float_text_3d 配不同颜色/大小 |
| 3D 敌方预警：双次红色脉冲 | ✅ timer 延迟 + is_instance_valid 安全检查 |
| 2D 模式零影响 | ✅ 仅修改 BoardView3D.gd |
| duck typing 路由兼容 | ✅ 方法签名不变，Main._active_view() 路由无需修改 |
| gl_compatibility 渲染器兼容 | ✅ CPUParticles3D + Label3D + StandardMaterial3D 均兼容 |

---

## 剩余问题

- 3D 单位仍为简单几何体（CapsuleMesh/CylinderMesh）（v0.1.71 遗留）
- DiceDebugPanel 仍绑定 2D BoardView（v0.1.71 遗留）
- spritesheet 背景透明度（v0.1.70 遗留）
- ATK/DEF 商店提升未走 BuffManager（v0.1.73 设计取舍，跨层重建自动重置）
- BoardView3D.rebuild_board() 全量重建（大棋盘性能开销）

---

## 建议下一步

1. 阵亡单位跨层复活机制
2. BattleFlowController 瘦身（当前约 693 行）
3. 3D 单位精灵化（billboard sprite 或低多边形模型）
4. 商品池扩展（加新牌/移除诅咒/随机 crest 等）

## Codex 复审标注（可选）

- 相机震动使用 `_shake_offset` 变量而非直接 tween `_camera.position`，这是因为 `_process()` 每帧都通过 lerp 更新相机位置，直接 tween position 会被 lerp 覆盖。_shake_offset 在 _process 中叠加到最终位置，两套系统互不冲突。
- Label3D 的 `font_size` 使用 `int(font_size * 64.0)` 缩放系数，是因为 Label3D.font_size 以像素为单位，配合 `pixel_size = 0.01` 使文字在 3D 空间中有合理的视觉大小。
- CPUParticles3D 的速度/大小参数（3~7 世界单位/秒）是基于 GridMapper3D.CELL_SIZE = 2.0 调校的，确保粒子扩散范围在 1~2 个格子内。
