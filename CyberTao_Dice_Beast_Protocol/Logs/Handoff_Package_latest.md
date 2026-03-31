# CyberTao: Dice Beast Protocol — 交接包

**生成时间**: 2026-03-31
**当前版本**: v0.1.67
**分支**: codex/dice-beast-protocol

---

## 1. 此刻的精确状态（一句话）

v0.1.67 完成移动逐格行走动画（BFS路径重建+Tween逐格插值+信号链架构）+敌方移动动画+我方回合镜头切回优化（切回上一轮操作单位），棋盘层和卡牌层全部稳定，下一步是卡牌拖拽出牌+即时伤害反馈（v0.1.68）和顶部单位头像HUD（v0.1.69）。

---

## 2. 本账号完成的工作

| 版本 | 任务 | 状态 |
|------|------|------|
| v0.1.67 | 移动逐格行走动画+敌方移动动画+我方回合镜头切回优化 | 完成 |

---

## 3. 最后版本关键变更

**版本号**: v0.1.67

**修改文件**:
- `Scripts/BattleV2/BoardManager.gd` — 新增 `get_path_to_cell()` BFS路径重建
- `Scripts/BattleV2/BattleFlowController.gd` — 新增 `move_step_visual`/`move_step_done` 信号+`validate_move()`;`try_move_unit()` 改为 async 逐格移动
- `Scripts/UI/BoardView.gd` — 新增移动动画系统（play_move_step/move_anim_done）
- `Scripts/Main.gd` — `_last_operated_unit_id` 追踪+镜头切回优化+信号链中转

**新增接口**:
- `BoardManager.get_path_to_cell(origin, target, move_range) -> Array[Vector2i]`
- `BFC.move_step_visual(unit_id, from_cell, to_cell)` 信号
- `BFC.move_step_done` 信号
- `BFC.validate_move(unit_id, target_cell) -> bool`
- `BoardView.play_move_step(unit_id, from_cell, to_cell, duration)`
- `BoardView.move_anim_done` 信号

**遗留问题**:
- 卡牌出牌仍为点击模式（拖拽为 v0.1.68）
- 顶部单位头像 HUD 未实现（v0.1.69）
- CardRewardPanel 暂未使用 CardRenderer 风格
- 阵亡单位跨层不复活

---

## 4. 下一步任务（精确到可以直接开始）

**立刻要做的**:
v0.1.68 卡牌拖拽出牌+即时伤害反馈：
- 在 `CardBattlePanel.gd` 的 `_create_battle_card()` 中将 `gui_input` 的点击逻辑改为拖拽（mousedown 开始拖拽，mousemove 跟随，mouseup 在上半区释放=打出）
- 在 `CardBattlePanel._on_card_played` 回调中新增 HP 条即时刷新（读取 controller 的 player_hp/enemy_hp）和伤害飘字
- 目前 `card_played` 信号只携带 card_index/name/effect_text，需扩展或新增信号携带 HP 变化量

**任务队列**:
1. v0.1.68：卡牌拖拽出牌+即时伤害反馈
2. v0.1.69：顶部单位头像 HUD
3. 商店格扩展
4. 阵亡单位跨层复活机制

---

## 5. 当前未解决问题清单

| 问题 | 严重程度 | 是否阻塞 | 建议处理时机 |
|------|----------|----------|--------------|
| 卡牌出牌为点击模式（无拖拽） | 中 | 否 | v0.1.68 |
| 顶部单位头像 HUD 不存在 | 中 | 否 | v0.1.69 |
| 阵亡单位跨层不复活 | 低 | 否 | 数值调优轮次 |
| CardRewardPanel 未使用 CardRenderer 风格 | 低 | 否 | UI 统一轮次 |
| 电弧牌 ATK-1 效果仅单场生效 | 低 | 否 | 卡牌数据重构时 |
| BattleFlowController ~710行 | 中 | 否 | 下次大功能前 |
| 扇形手牌无拖拽（仅点击） | 中 | 否 | v0.1.68 同步解决 |

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

- `try_move_unit()` 从 v0.1.67 起是 async 协程（内部有 await），返回 void 不再返回 bool——如需同步检查用 `validate_move()`
- 移动动画信号链：BFC.move_step_visual → Main → BoardView.play_move_step → move_anim_done → Main → BFC.move_step_done，是双向信号中转架构
- `_last_operated_unit_id` 仅在 Main 层追踪，BFC 不知道这个概念
- BoardView 的 `_move_anim_from_cell` / `_move_anim_to_cell` 是 cell 坐标（非像素），绘制时用 `_iso_cell_center()` 实时转换，确保相机移动时位置正确
- `get_path_to_cell()` 使用 BFS（非 Dijkstra），在加权图中不保证最短步数路径，但保证在移动预算内
- AI_Employee_Guide_v3.md 是**每轮强制更新**的（三件套缺一不可）
