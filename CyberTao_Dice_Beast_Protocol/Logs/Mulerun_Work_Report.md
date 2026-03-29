# Mulerun 工作报告

**日期**: 2026-03-29
**版本**: v0.1.20
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- buff / item 格第一版（Weekly Plan Day 4）

---

## 根因/目标

### 根因
- `BoardManager.item_cells`、`ActionResolver.try_pickup()`、`BuffManager`、`ItemEffectLibrary` 四个系统全部存在但处于死链状态
- 棋盘上没有可交互的资源点，战斗缺少"抢点 vs 推线"的策略选择
- 3 个 ItemData .tres 文件已定义但从未被使用

### 目标
- 接通现有道具管道：放置 → 拾取 → 效果生效
- 在棋盘上放置 2 种可拾取道具
- 拾取后即时生效并有视觉反馈
- 不做复杂持续 buff，只做即时效果

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/BattleV2/BattleFlowController.gd` | 添加 item_picked_up 信号、_spawn_debug_items()、_check_item_pickup()、_apply_item_effect()；try_move_unit 增加拾取检查；restart 增加道具重置 |
| `Project/Scripts/UI/BoardView.gd` | 添加 _draw_items() 绿色道具格渲染；添加 play_pickup_feedback() 绿色飘字 |
| `Project/Scripts/UI/DiceDebugPanel.gd` | 连接 item_picked_up 信号，拾取后刷新 crest 池 |
| `Project/Scripts/Main.gd` | 连接 item_picked_up 信号，触发拾取反馈；提示栏新增"绿色=道具" |
| `Logs/Mulerun_Work_Report.md` | 本报告 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.20 条目 |

---

## 实现内容

### 1. 道具放置
- `_spawn_debug_items()` 在棋盘上固定放置 2 个道具：
  - 补丁凉茶 (4,5)：回复 2 HP
  - 超频骨头 (2,6)：+1 MOVE crest
- 使用已有的 `BoardManager.add_item_cell()` 方法

### 2. 拾取触发
- `try_move_unit()` 在移动完成、陷阱检查之后，检查目标格是否有道具
- 条件：单位存活（陷阱未击杀）才触发拾取
- 拾取后道具格从 `item_cells` 中移除

### 3. 效果执行
- `_apply_item_effect()` 调用 `ItemEffectLibrary.execute()` 获取效果描述
- 根据返回的 effect 类型实际应用：
  - `heal_and_cleanse`：回复 HP（不超过 max_hp）
  - `gain_move_and_attack_boost`：向 crest_pool 添加 MOVE
  - `random_crest_gain`：随机添加 ATTACK/DEFEND/SKILL

### 4. 视觉呈现
- `_draw_items()`：绿色填充+边框+道具中文名缩写（"凉茶"/"骨头"）
- `play_pickup_feedback()`：绿色飘字上浮淡出（0.7 秒），显示效果文本（如"HP+2"）

### 5. 信号接通
- `item_picked_up` 信号 → Main.gd 触发飘字 → DiceDebugPanel 刷新 crest 池

---

## 当前剩余问题

- **道具为固定放置** — 无随机生成，无每回合补充
- **仅玩家触发拾取** — 敌方移动到道具格不触发
- **BuffManager.tick_turn() 仍未接入** — 持续 buff 暂不生效
- **无道具数量限制** — 理论上可无限放置
- **故障零食盒未放置** — 数据已就绪但调试布局只放了 2 个

---

## 建议下一步

1. 在编辑器中验证道具拾取流程
2. 按 Weekly Plan 继续推进 Day 5：敌方 AI 可读性增强
