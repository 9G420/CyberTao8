# CyberTao: Dice Beast Protocol — 交接包

**生成时间**: 2026-04-01
**当前版本**: v0.1.72
**分支**: codex/dice-beast-protocol

---

## 1. 此刻的精确状态（一句话）

v0.1.72 完成 3D 交互手感修复：拖拽即时响应（绝对偏移计算替代逐帧增量累积）、镜头跟随速度对齐2D体验（CAMERA_LERP_SPEED 4.5→8.0）、边界限制（棋盘世界半径±50%）、缩放以鼠标为轴心（射线交叉补偿）。3D 渐进迁移 P0+交互修复均已完成，核心逻辑文件零改动，下一步是 3D 反馈系统或商店格扩展。

---

## 2. 本账号完成的工作

| 版本 | 任务 | 状态 |
|------|------|------|
| v0.1.67 | 移动逐格行走动画+敌方移动动画+我方回合镜头切回优化 | 完成 |
| v0.1.68 | 卡牌拖拽出牌+即时伤害反馈 | 完成 |
| v0.1.69 | 顶部单位头像 HUD | 完成 |
| v0.1.70 | 玩家角色精灵动画（4方向 spritesheet 集成） | 完成 |
| v0.1.71 | 3D 渐进迁移 P0（BoardView3D + SubViewport + F5 切换） | 完成 |
| v0.1.72 | 3D 交互手感修复（拖拽+镜头跟随+边界限制+缩放轴心） | 完成 |

---

## 3. 最后版本关键变更

**版本号**: v0.1.72

**修改文件**:
- `Scripts/UI3D/BoardView3D.gd` — 重写拖拽/缩放/相机逻辑，新增边界限制+缩放轴心+绝对偏移计算
- `Scripts/UI/DiceDebugPanel.gd` — 版本标记 v0.1.71 → v0.1.72

**新增接口**:
- `BoardView3D._clamp_drag_offset()` — 拖拽偏移边界限制（内部方法）
- `BoardView3D._apply_zoom(delta_dist, mouse_pos)` — 鼠标轴心缩放（内部方法）
- `BoardView3D._screen_to_ground(screen_pos, cam_dist)` — 屏幕坐标→地面交点（内部方法）
- `BoardView3D._drag_start_offset: Vector3` — 拖拽起始快照变量
- `BoardView3D.ZOOM_STEP: float = 1.5` — 缩放步长常量
- 无公开接口变更，信号/方法签名不变

**遗留问题**:
- 3D 反馈方法（攻击闪光/飘字/粒子）暂为桩函数（v0.1.71 遗留）
- 3D 单位使用简单几何体，未接入精灵/模型（v0.1.71 遗留）
- DiceDebugPanel 仍绑定 2D BoardView（v0.1.71 遗留）
- _screen_to_ground() 在相机 lerp 未到位时存在微小偏差（可接受）
- spritesheet 背景透明度（v0.1.70 遗留）仍需用户确认

---

## 4. 下一步任务（精确到可以直接开始）

**立刻要做的**:
根据用户指派的任务方向选择：
- 3D 反馈系统实现（粒子特效/3D 飘字替代 2D BattleEffects）
- 商店格扩展（多选商品 + 独立 UI 面板）

**任务队列**:
1. 3D 反馈系统实现（粒子特效/3D 飘字）
2. 商店格扩展（多选商品 + 独立 UI 面板）
3. 阵亡单位跨层复活机制
4. BattleFlowController 瘦身

---

## 5. 当前未解决问题清单

| 问题 | 严重程度 | 是否阻塞 | 建议处理时机 |
|------|----------|----------|--------------|
| 3D 反馈方法为桩函数 | 中 | 否 | 3D 迭代 P1 |
| 3D 单位为简单几何体 | 低 | 否 | 3D 迭代 P2 |
| DiceDebugPanel 绑定 2D BoardView | 低 | 否 | 3D 完善轮次 |
| spritesheet 背景透明度待确认 | 中 | 否 | 用户测试后处理 |
| 阵亡单位跨层不复活 | 低 | 否 | 数值调优轮次 |
| CardRewardPanel 未使用 CardRenderer 风格 | 低 | 否 | UI 统一轮次 |
| BattleFlowController ~693行 | 中 | 否 | 下次大功能前 |
| _screen_to_ground() 相机 lerp 未到位时微小偏差 | 低 | 否 | 可接受，暂不处理 |

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

- _active_view() 返回 Variant（GDScript duck typing），无编译时类型检查，依赖方法名匹配
- BoardView3D 在 SubViewport 中运行，SubViewport 不自动接收父级输入事件，需要 Main._input() 手动转发
- 3D 模式下 DiceDebugPanel.bind_board_view() 仍传入 2D BoardView，如需 3D 适配需额外处理
- BoardView3D.rebuild_board() 是全量重建（清除+重建所有 MeshInstance3D），大棋盘可考虑增量更新
- 3D 相机使用 _process(delta) 插值，2D 相机使用 Timer（50ms）插值，两者独立运行
- TileMeshFactory3D 和 UnitMeshFactory3D 是静态方法工厂，不持有状态
- 高台格在 3D 中抬高 0.4 世界单位（HIGH_GROUND_LIFT），陷阱格不下沉
- 环境格子（棋盘外暗色填充）在 3D 中未实现，棋盘外为纯黑背景
- F5 切换不保留选中状态（切换时不自动同步 selected_unit_id）
- v0.1.72 拖拽改用绝对偏移（_drag_start_offset 快照），不再逐帧增量累积，长距离拖拽无漂移
- v0.1.72 缩放轴心依赖 _screen_to_ground() 射线交叉，相机 lerp 未完全到位时有微小偏差（可接受）
