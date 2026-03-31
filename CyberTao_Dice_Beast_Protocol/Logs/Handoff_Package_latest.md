# CyberTao: Dice Beast Protocol — 交接包

**生成时间**: 2026-03-31
**当前版本**: v0.1.71
**分支**: codex/dice-beast-protocol

---

## 1. 此刻的精确状态（一句话）

v0.1.71 完成 3D 渐进迁移 P0：新增完整 3D 表现层（GridMapper3D + TileMeshFactory3D + UnitMeshFactory3D + BoardView3D），通过 SubViewport 嵌入 2D UI 树，F5 切换 2D/3D 视图，Main.gd 全部回调通过 _active_view() duck typing 路由，核心逻辑文件零改动，下一步是 3D 反馈系统或商店格扩展。

---

## 2. 本账号完成的工作

| 版本 | 任务 | 状态 |
|------|------|------|
| v0.1.67 | 移动逐格行走动画+敌方移动动画+我方回合镜头切回优化 | 完成 |
| v0.1.68 | 卡牌拖拽出牌+即时伤害反馈 | 完成 |
| v0.1.69 | 顶部单位头像 HUD | 完成 |
| v0.1.70 | 玩家角色精灵动画（4方向 spritesheet 集成） | 完成 |
| v0.1.71 | 3D 渐进迁移 P0（BoardView3D + SubViewport + F5 切换） | 完成 |

---

## 3. 最后版本关键变更

**版本号**: v0.1.71

**新增文件（4个）**:
- `Scripts/UI3D/GridMapper3D.gd` — 格坐标↔3D世界坐标双向转换（CELL_SIZE=2.0）
- `Scripts/UI3D/TileMeshFactory3D.gd` — 9种格子 BoxMesh + StandardMaterial3D 工厂
- `Scripts/UI3D/UnitMeshFactory3D.gd` — 玩家 CapsuleMesh + 敌方 CylinderMesh + billboard HP 条
- `Scripts/UI3D/BoardView3D.gd` — 完整 3D 棋盘视图（extends Node3D，信号接口对齐 BoardView）

**修改文件**:
- `Scripts/Main.gd` — 新增 _use_3d + _active_view() + _setup_3d_view() + toggle_3d_view() + _input() F5
- `Scripts/UI/DiceDebugPanel.gd` — 版本标记 v0.1.71

**新增接口**:
- `GridMapper3D.cell_to_world(cell, grid_size) -> Vector3` — 格坐标→世界坐标
- `GridMapper3D.world_to_cell(world_pos, grid_size) -> Vector2i` — 世界坐标→格坐标
- `TileMeshFactory3D.create_tile(tile_key, cell, grid_size) -> MeshInstance3D` — 创建格子网格
- `TileMeshFactory3D.create_highlight(cell, color, grid_size) -> MeshInstance3D` — 创建高亮
- `UnitMeshFactory3D.create_unit_node(unit, cell, grid_size) -> Node3D` — 创建单位节点
- `UnitMeshFactory3D.update_hp_bar(node, hp, max_hp, is_player)` — 更新 HP 条
- `BoardView3D` — 全部信号和方法与 BoardView 对齐（见 BoardView3D.gd 头部声明）
- `Main.toggle_3d_view()` — 切换 2D/3D
- `Main._active_view()` — 返回当前活动视图（duck typing）
- `Main._input()` — F5 快捷键 + 3D 鼠标事件转发

**遗留问题**:
- 3D 反馈方法（攻击闪光/飘字/粒子）暂为桩函数
- 3D 单位使用简单几何体，未接入精灵/模型
- DiceDebugPanel 仍绑定 2D BoardView（3D 模式下骰子面板无交互适配）
- spritesheet 背景透明度（v0.1.70 遗留）仍需用户确认

---

## 4. 下一步任务（精确到可以直接开始）

**立刻要做的**:
用户测试 3D 视图效果，根据反馈调整：
- 按 F5 切换到 3D → 确认棋盘格/单位/相机/点击是否正常
- 如果 3D 效果不满意，可回退到 2D（再按 F5）

**任务队列**:
1. 3D 反馈系统实现（粒子特效/3D 飘字替代 2D BattleEffects）
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
| BattleFlowController ~710行 | 中 | 否 | 下次大功能前 |

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
