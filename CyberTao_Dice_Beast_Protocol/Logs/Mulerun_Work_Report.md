# Mulerun 工作报告

**日期**: 2026-03-30
**版本**: v0.1.41
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- Day 23：更多格子类型 — 商店格 + 宝箱格

---

## 根因目标

棋盘走位层已有 7 种可交互格子（高台/陷阱/道具/遭遇/恢复/事件/Boss遭遇），但缺少经济循环和探索奖励机制。商店格为玩家提供"消耗步进 crest 换取 HP 回复"的策略选择，宝箱格提供一次性随机奖励增加探索激励。这两种格子丰富了棋盘层的策略深度，为后续多层地图的经济系统铺路。服务于棋盘走位层。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/BattleV2/BoardManager.gd` | 新增 shop_cells/chest_cells 字典，add_shop_cell/add_chest_cell/clear_chest_cell 方法，build_test_board/clear_board 中清理新字典 |
| `Project/Scripts/BattleV2/CellEffectHandler.gd` | 新增 check_shop_cell()（商店格效果：消耗1步进crest回复HP）、check_chest_cell()（宝箱格效果：3种随机奖励） |
| `Project/Scripts/BattleV2/BattleFlowController.gd` | 新增 shop_cell_triggered/chest_cell_triggered 信号，_check_shop_cell/_check_chest_cell 薄代理，try_move_unit 格子检查链中接入新格子 |
| `Project/Scripts/BattleV2/BoardGenerator.gd` | 新增 SHOP_COUNT/CHEST_COUNT 常量，generate_board 中放置商店格（1个）和宝箱格（1-2个） |
| `Project/Scripts/UI/BoardView.gd` | 新增 _draw_shop_cells()（青绿色）、_draw_chest_cells()（金琥珀色）绘制方法，play_shop_feedback/play_chest_feedback 飘字反馈 |
| `Project/Scripts/UI/DiceDebugPanel.gd` | 连接 shop_cell_triggered/chest_cell_triggered 信号，版本号更新为 v0.1.41 |
| `Project/Scripts/Main.gd` | 连接 shop_cell_triggered/chest_cell_triggered 信号，新增 _on_shop_cell_triggered/_on_chest_cell_triggered 反馈处理，更新提示文字 |
| `Logs/Mulerun_Work_Report.md` | 本文件，Day 23 工作报告 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.41 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步更新至 v0.1.41 状态 |

---

## 实现内容

1. **商店格（Shop Cell）**
   - 持久格子（不消失，可重复使用）
   - 效果：消耗 1 步进(move) crest，回复 3 HP
   - 条件：单位 HP 未满 + 有 move crest 可用 + 仅玩家单位可触发
   - 视觉：青绿色填充 + 边框 + "商店" 文字 + "1步→HP+3" 费用标注
   - 飘字反馈：青绿色 "-1步 HP+X"
   - 每局生成 1 个，不在玩家出生区

2. **宝箱格（Chest Cell）**
   - 一次性格子（踩后消失）
   - 随机奖励（等概率 3 选 1）：
     - HP+3（受 max_hp 限制）
     - 随机 crest +2
     - 全 crest +1
   - 视觉：金琥珀色填充 + 边框 + "宝箱" 文字
   - 飘字反馈：金色飘字显示具体奖励
   - 每局生成 1-2 个，不在玩家出生区

3. **架构遵循**
   - 沿用 CellEffectHandler 薄代理模式：handler 返回结果字典，BFC 负责信号发射
   - BoardManager 新增字典 + 增删方法
   - BoardGenerator 静态生成逻辑
   - BoardView 纯渲染层绘制
   - 所有消费方（DiceDebugPanel/Main）通过信号订阅

---

## 接口变更

### 新增 BFC 信号
- `signal shop_cell_triggered(unit_id: String, cell: Vector2i, cost_crest: String, actual_heal: int)`
- `signal chest_cell_triggered(unit_id: String, cell: Vector2i, effect_text: String)`

### 新增 BFC 内部方法
- `_check_shop_cell(unit_id, cell)` — 商店格薄代理
- `_check_chest_cell(unit_id, cell)` — 宝箱格薄代理

### 新增 BoardManager 变量
- `var shop_cells: Dictionary = {}` — cell -> int (heal_amount)
- `var chest_cells: Dictionary = {}` — cell -> String ("chest")

### 新增 BoardManager 方法
- `add_shop_cell(cell, heal_amount)` — 添加商店格
- `add_chest_cell(cell, chest_id)` — 添加宝箱格
- `clear_chest_cell(cell)` — 清除宝箱格

### 新增 CellEffectHandler 方法
- `check_shop_cell(unit_id, cell) -> Dictionary` — 商店格效果
- `check_chest_cell(unit_id, cell) -> Dictionary` — 宝箱格效果

### 新增 BoardView 方法
- `_draw_shop_cells()` — 商店格渲染
- `_draw_chest_cells()` — 宝箱格渲染
- `play_shop_feedback(cell, text)` — 商店格飘字
- `play_chest_feedback(cell, text)` — 宝箱格飘字

### 新增 BoardGenerator 常量
- `SHOP_COUNT = 1`
- `CHEST_COUNT_MIN = 1`
- `CHEST_COUNT_MAX = 2`

---

## 测试确认

代码逻辑自查通过：
- BoardManager.build_test_board 和 clear_board 中正确清理 shop_cells 和 chest_cells ✅
- CellEffectHandler.check_shop_cell 条件完整：has(cell) + 非空单位 + player + HP未满 + can_pay ✅
- CellEffectHandler.check_chest_cell 条件完整：has(cell) + 非空单位 + clear_chest_cell 一次性消失 ✅
- BFC 薄代理 _check_shop_cell/_check_chest_cell 正确委托 + 信号发射 ✅
- try_move_unit 格子检查链完整：trap → item → heal → event → shop → chest → encounter ✅
- BoardGenerator 在事件格之后、敌方单位之前放置商店格和宝箱格，avoid_player_zone=true ✅
- BoardView._draw 中新增 _draw_shop_cells 和 _draw_chest_cells 调用 ✅
- DiceDebugPanel 正确连接 shop_cell_triggered 和 chest_cell_triggered 信号 ✅
- Main.gd 正确连接信号并调用 play_shop_feedback/play_chest_feedback ✅
- 棋盘层完整闭环：掷骰/移动/攻击/召唤/敌方回合/胜负重开均不受影响 ✅
- 卡牌层完整闭环：未触碰 CardBattleController 及其 UI 面板 ✅
- 20 个 BFC 信号（原18+新2），外部消费方通过新信号订阅 ✅

---

## 剩余问题

- 商店格当前仅提供"消耗 move crest 回复 HP"单一功能，未来可扩展为多选商品（需要 UI 面板支持）
- 宝箱格奖励池较小（3 种），未来可增加更多奖励类型（如 buff、卡牌相关）
- BoardView 行数从 572 增长至约 640 行，职责继续膨胀（但未超出可维护范围）

---

## 建议下一步

1. **多层地图**（中优先）— 通关当前棋盘后进入下一层
2. **BUG-001 修复**（中低优先）— 分辨率切换无效（Demo 前必须解决）
3. **商店格扩展**（低优先）— 多选商品 + 独立 UI 面板

---

## Codex 复审标注

1. **商店格设计选择**：选择"自动触发"模式而非"弹出选择面板"模式。原因：当前没有商店 UI 面板，且实现一个完整的商店选择界面会扩大任务范围。自动触发模式（消耗 1 move crest 回复 3 HP）足以验证商店格的核心机制，未来可在此基础上扩展为多选商品。标注为保守方案。

2. **宝箱格奖励平衡**：HP+3/crest+2/全crest+1 三种奖励等概率。HP+3 对于 max_hp 5-8 的玩家单位是较高回复量；crest+2 相当于减少一次掷骰依赖；全 crest+1 总计 6 点资源。三者价值大致均衡但未经实战测试。

3. **格子检查顺序**：商店格和宝箱格插入在 event → encounter 之间（event → shop → chest → encounter），确保遭遇格优先级最低（因为遭遇会暂停棋盘）。商店格在宝箱前是因为商店有消耗条件，宝箱无条件触发。
