# CyberTao: Dice Beast Protocol — 交接包

**生成时间**: 2026-04-01
**当前版本**: v0.1.74
**分支**: codex/dice-beast-protocol

---

## 1. 此刻的精确状态（一句话）

v0.1.74 完成 3D 反馈系统：9 个桩函数全部替换为真实 3D 特效（Label3D 漂浮文字、CPUParticles3D 命中粒子、PlaneMesh 格子闪光、相机震动），3D 模式下攻击/治疗/拾取/事件/商店/宝箱/遭遇/敌方预警等交互反馈与 2D 版功能对齐。下一步是阵亡单位跨层复活或 BFC 瘦身。

---

## 2. 本账号完成的工作

| 版本 | 任务 | 状态 |
|------|------|------|
| v0.1.74 | 3D 反馈系统实现（9个桩函数→完整3D特效） | 完成 |

---

## 3. 最后版本关键变更

**版本号**: v0.1.74

**修改文件**:
- `Scripts/UI3D/BoardView3D.gd` — 9 个桩函数替换为完整实现 + 4 个辅助方法（~130 行新增）+ `_feedback_root` 容器 + `_shake_offset` 相机震动
- `Scripts/UI/DiceDebugPanel.gd` — 版本标记 → v0.1.74

**新增内部方法**:
- `_spawn_float_text_3d(cell, text, color, font_size, rise_height, duration, delay)` — Label3D billboard 漂浮文字
- `_spawn_cell_flash_3d(cell, color, duration)` — PlaneMesh 格子闪光
- `_shake_camera_3d(intensity, duration)` — 相机震动
- `_spawn_hit_particles_3d(world_pos, color, is_kill)` — CPUParticles3D 命中粒子

**无公开接口变更**：9 个反馈方法签名与 v0.1.71 桩函数完全一致

**遗留问题**:
- 3D 单位使用简单几何体（v0.1.71 遗留）
- DiceDebugPanel 仍绑定 2D BoardView（v0.1.71 遗留）
- spritesheet 背景透明度（v0.1.70 遗留）
- ATK/DEF 商品提升直接改 unit dict（v0.1.73 设计取舍）
- BattleFlowController ~693 行

---

## 4. 下一步任务（精确到可以直接开始）

**立刻要做的**:
根据用户指派的任务方向选择：
- 阵亡单位跨层复活机制：在 `BattleFlowController.advance_to_next_floor()` 中添加伙伴复活逻辑，HP 恢复至 max_hp 或百分比
- BattleFlowController 瘦身：将多层地图逻辑剥离为 FloorManager 独立类

**任务队列**:
1. 阵亡单位跨层复活机制
2. BattleFlowController 瘦身（当前约 693 行）
3. 3D 单位精灵化（billboard sprite 或低多边形模型）
4. 商品池扩展（加新牌/移除诅咒/随机 crest 等）

---

## 5. 当前未解决问题清单

| 问题 | 严重程度 | 是否阻塞 | 建议处理时机 |
|------|----------|----------|--------------|
| 3D 单位为简单几何体 | 低 | 否 | 3D 迭代 P2 |
| DiceDebugPanel 绑定 2D BoardView | 低 | 否 | 3D 完善轮次 |
| spritesheet 背景透明度待确认 | 中 | 否 | 用户测试后处理 |
| 阵亡单位跨层不复活 | 低 | 否 | 数值调优轮次 |
| CardRewardPanel 未使用 CardRenderer 风格 | 低 | 否 | UI 统一轮次 |
| BattleFlowController ~693行 | 中 | 否 | 下次大功能前 |
| _screen_to_ground() 相机 lerp 未到位时微小偏差 | 低 | 否 | 可接受，暂不处理 |
| 商店 ATK/DEF 提升未走 BuffManager | 低 | 否 | 如需回合限制时改 |
| BoardView3D.rebuild_board() 全量重建 | 低 | 否 | 3D 优化轮次 |

---

## 6. 新账号启动指令

```bash
git clone https://github.com/9G420/CyberTao8.git
cd CyberTao8
git checkout codex/dice-beast-protocol
git pull origin codex/dice-beast-protocol
```

然后按顺序阅读：
1. `Logs/AI_Employee_Guide_v3.md`（本上岗指令）
2. 本文件（已在读）
3. `Logs/CyberTao_Migration_Snapshot_zh_v3.md`
4. `Logs/Mulerun_Work_Report.md`

读完输出【上岗确认】，等用户确认后再开始工作。

---

## 7. 给下一个账号的备注

- v0.1.74 的 3D 反馈系统使用 4 个辅助方法统一实现：_spawn_float_text_3d / _spawn_cell_flash_3d / _shake_camera_3d / _spawn_hit_particles_3d，扩展新反馈只需调用这些方法
- 相机震动通过 _shake_offset 变量驱动（不是直接 tween camera.position），与 _process 中的 lerp 跟随系统互不冲突
- Label3D 的 font_size 使用 `int(font_size * 64.0)` 缩放系数配合 `pixel_size = 0.01`，调整文字大小时改 font_size 参数即可
- CPUParticles3D 使用 SphereMesh 作为粒子可见体，速度参数基于 CELL_SIZE=2.0 调校
- 所有临时反馈节点挂在 _feedback_root 下，Tween 结束后自动 queue_free，不需要手动清理
- _active_view() duck typing 路由：BoardView3D 的 9 个反馈方法签名与 BoardView 完全一致，Main.gd 无需任何修改
