# Mulerun 工作报告

**日期**: 2026-03-31
**版本**: v0.1.71
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.71：3D 渐进迁移 P0（新增 3D 表现层模块 + 双视图切换）

---

## 根因目标

用户要求添加 3D 渲染层用于棋盘和单位可视化，同时保留 2D 回退，不修改核心游戏逻辑文件。

服务层：棋盘走位层（视觉升级 — 3D 渲染原型）

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/UI3D/GridMapper3D.gd` | **新文件**：格坐标↔3D世界坐标转换（CELL_SIZE=2.0，棋盘居中） |
| `Scripts/UI3D/TileMeshFactory3D.gd` | **新文件**：9种格子类型 BoxMesh 创建 + StandardMaterial3D（CyberStyle 配色+发光） |
| `Scripts/UI3D/UnitMeshFactory3D.gd` | **新文件**：单位 CapsuleMesh/CylinderMesh 创建 + billboard HP 条 |
| `Scripts/UI3D/BoardView3D.gd` | **新文件**：完整 3D 棋盘视图，信号接口与 BoardView 对齐 |
| `Scripts/Main.gd` | 新增 `_use_3d`/`_active_view()`/`_setup_3d_view()`/`toggle_3d_view()`/`_input()` + 全部回调路由替换 |
| `Scripts/UI/DiceDebugPanel.gd` | 版本标记更新至 v0.1.71 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.71 条目 |

---

## 实现内容

### 新增文件（4个，均在 Scripts/UI3D/）

**GridMapper3D.gd**（~40行）：
- 纯数学工具类，cell_to_world / world_to_cell 双向转换
- 棋盘以原点为中心，每格 2.0 世界单位

**TileMeshFactory3D.gd**（~110行）：
- create_tile() 为每种格子类型创建 BoxMesh + 匹配 CyberStyle 的 StandardMaterial3D
- create_highlight() 创建半透明高亮薄片
- 高台格额外抬高 0.4 世界单位

**UnitMeshFactory3D.gd**（~100行）：
- create_unit_node() 返回 Node3D 容器（Body + HPBar）
- 玩家用 CapsuleMesh（蓝色），敌方用 CylinderMesh（红色）
- HP 条使用 billboard BoxMesh，update_hp_bar() 更新缩放和颜色

**BoardView3D.gd**（~340行）：
- extends Node3D，class_name BoardView3D
- 信号：unit_selected / unit_deselected / move_requested / attack_requested / summon_requested / move_anim_done
- 方法：bind_managers / bind_battle_flow / set_camera_target / queue_redraw / play_move_step + 全部反馈方法桩
- 内部：rebuild_board() 重建格子 / _refresh_units() 增量更新单位 / _refresh_highlights() 重建高亮
- 输入：handle_input() 处理缩放/拖拽/点击（射线检测 Y=0 平面）
- 相机：55° 透视相机，平滑跟随 + _process() 插值

### Main.gd 修改（~90行净增）

- `_use_3d: bool = false` — 默认 2D
- `_active_view()` — duck typing 路由，返回 BoardView 或 BoardView3D
- `_reset_drag_offset()` — 兼容 2D Vector2 / 3D Vector3
- `_setup_3d_view()` — SubViewportContainer + SubViewport + BoardView3D 初始化 + 信号绑定
- `toggle_3d_view()` — 切换可见性 + rebuild_board
- `_input()` — F5 快捷键 + 3D 模式鼠标事件转发
- 所有 ~40 处 `_board_view.xxx` 替换为 `_active_view().xxx`

---

## 接口变更

- 新增 4 个 class_name 全局注册：GridMapper3D, TileMeshFactory3D, UnitMeshFactory3D, BoardView3D
- Main.gd 新增公开方法：toggle_3d_view()
- Main.gd 新增快捷键：F5 = 切换 2D/3D

---

## 测试确认

- 需用户在 Godot 中运行确认：
  - 默认启动仍为 2D 模式（与 v0.1.70 行为一致）
  - 按 F5 切换到 3D 视图：应看到 12x12 棋盘格（BoxMesh）+ 单位模型
  - 3D 模式下点击格子能选中/移动/攻击
  - 3D 模式下鼠标拖拽/缩放正常
  - 3D 模式下遭遇触发能正常切入卡牌战斗（百叶窗过渡）
  - 按 F5 切回 2D，2D 模式完全正常
  - 重新开始按钮在两种模式下都能正确重置

---

## 剩余问题

- 3D 反馈方法（攻击闪光/飘字/粒子）暂为桩函数
- 3D 模式下召唤演出无 UITransitions 效果（需 3D 粒子替代）
- 3D 单位使用简单几何体（CapsuleMesh/CylinderMesh），未接入精灵/模型
- BoardView3D.rebuild_board() 每次全量重建，大棋盘可能有性能开销
- spritesheet 背景透明度（v0.1.70 遗留）仍需用户确认

---

## 建议下一步

1. 3D 反馈系统实现（粒子特效/3D 飘字）
2. 3D 单位精灵化（billboard sprite 或低多边形模型）
3. 商店格扩展（多选商品 + 独立 UI 面板）

---

## Codex 复审标注

- BoardView3D 内嵌 SubViewport 会增加一次完整 3D 渲染 pass，性能影响需实测
- _active_view() 返回 Variant（duck typing），GDScript 不做编译时类型检查，依赖运行时方法匹配
- 3D 模式下 DiceDebugPanel 仍绑定 2D 的 _board_view（通过 bind_board_view），如需 3D 模式下骰子面板交互需额外适配
- handle_input() 从 Main._input() 手动转发，SubViewport 本身不自动接收父级输入
- 环境格子（棋盘外的暗色填充）在 3D 模式中未实现（仅棋盘范围内的格子）
