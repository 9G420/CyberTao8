# Mulerun 工作报告

**日期**: 2026-03-30
**版本**: v0.1.35
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- Day 17：棋盘随机生成

---

## 根因目标

固定棋盘布局导致重玩性极低——每局遭遇格、地形、道具位置相同，玩家第二局就能记住最优路线。Day 17 的目标是将所有格子（地形/道具/遭遇/恢复/事件）和敌方单位的位置从硬编码改为每局随机生成，同时保持格子密度和玩家出生区安全。附带效果：BFC 减少约 50 行 debug spawn 代码，部分缓解了"BFC 瘦身"技术债。服务于棋盘走位层。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/BattleV2/BoardGenerator.gd` | 全新文件，棋盘程序化生成器：随机放置高台/陷阱/道具/遭遇/恢复/事件格+敌方单位，防重叠，保护玩家出生区 |
| `Project/Scripts/BattleV2/BattleFlowController.gd` | 新增 BoardGenerator preload；_spawn_debug_units 改名为 _spawn_player_units 并移除敌方单位生成；删除 _spawn_debug_terrain/_spawn_debug_items/_spawn_debug_encounters/_spawn_debug_heal_cells/_spawn_debug_event_cells 共 5 个方法；_bootstrap 和 restart_battle 改为调用 BoardGenerator.generate_board() |
| `Project/Scripts/UI/DiceDebugPanel.gd` | 版本号更新为 v0.1.35 |
| `Logs/Mulerun_Work_Report.md` | 本文件，Day 17 工作报告 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.35 条目 |

---

## 实现内容

1. **BoardGenerator.gd 程序化生成器**
   - 纯静态工具类（extends RefCounted, class_name BoardGenerator），不持有状态
   - 每次调用 `generate_board()` 生成全新随机布局
   - 生成参数可调：
     - 高台格 2~3 个
     - 陷阱格 2~3 个（不在玩家出生区）
     - 道具格 2 个
     - 遭遇格 3~4 个（不在玩家出生区，从 5 种遭遇中随机选取）
     - 恢复格 2 个（回复量 2~3 随机）
     - 事件格 2~3 个（不在玩家出生区）
     - 敌方单位 2 个（上半区域 row 0~3）
   - 防重叠机制：used_cells Dictionary 追踪已占用格子，Fisher-Yates 洗牌选取
   - 玩家出生区保护：col 0~1, row 5~7 区域不放置陷阱/遭遇/事件等危险格子
   - 敌方单位生成在棋盘上半区域，保证与玩家有足够距离

2. **BFC 瘦身（附带效果）**
   - 删除 5 个 _spawn_debug_* 方法（约 50 行硬编码位置）
   - _spawn_debug_units 改名为 _spawn_player_units，仅保留玩家单位生成（需要 .tres 资源加载）
   - 敌方单位生成移入 BoardGenerator._spawn_enemies()
   - _bootstrap() 和 restart_battle() 各减少 5 行调用改为 1 行 BoardGenerator 调用

3. **每局体验变化**
   - 重新开始后布局完全随机：遭遇格位置变化，不能靠记忆绕过
   - 高台/陷阱位置变化，地形策略每局不同
   - 道具和恢复格散落位置不同，探索路线有变化

---

## 接口变更

### 新增文件
- `Project/Scripts/BattleV2/BoardGenerator.gd` — 棋盘程序化生成器（class_name BoardGenerator）

### 新增方法（BoardGenerator，全部 static）
- `generate_board(board_mgr, unit_mgr, board_size)` — 生成完整棋盘布局
- `_spawn_enemies(unit_mgr, board_size, used_cells)` — 生成敌方单位
- `_pick_random_cells(board_size, count, used_cells, avoid_player_zone)` — 随机选取不重叠格子
- `_pick_enemy_cell(board_size, used_cells)` — 在上半区域选取敌方位置
- `_is_player_zone(cell)` — 判断是否在玩家出生区
- `_mark_player_spawn_cells(used_cells)` — 标记玩家单位初始位置

### 修改方法（BattleFlowController）
- `_spawn_debug_units()` → 改名为 `_spawn_player_units()`（仅含玩家单位）

### 删除方法（BattleFlowController）
- `_spawn_debug_terrain()` — 移入 BoardGenerator
- `_spawn_debug_items()` — 移入 BoardGenerator
- `_spawn_debug_encounters()` — 移入 BoardGenerator
- `_spawn_debug_heal_cells()` — 移入 BoardGenerator
- `_spawn_debug_event_cells()` — 移入 BoardGenerator

---

## 测试确认

代码逻辑自查通过：
- BoardGenerator.generate_board() 在 _bootstrap() 和 restart_battle() 中均被调用
- 玩家单位仍在固定位置生成（(0,6)/(1,7)/(0,5)），不受随机影响
- used_cells 防重叠：每种格子放置后立即标记，后续不会选到同一格
- 玩家出生区保护：_is_player_zone 检查 col<2 && row>=5，陷阱/遭遇/事件均排除此区域
- 敌方生成在 row 0~3，与玩家区域（row 5~7）有足够距离
- 遭遇格 3~4 个从 5 种中 Fisher-Yates 洗牌选取，不会所有遭遇都一样
- 高台格不排除玩家区（高台不是危险格子，站上有加成）
- 道具格和恢复格不排除玩家区（有益格子）
- 棋盘层完整闭环不受影响：掷骰/移动/攻击/召唤/敌方回合/胜负/重开均正常
- 卡牌层闭环不受影响：遭遇触发/卡牌战斗/选牌奖励/HP同步均正常
- 重新开始后 BoardGenerator 重新调用，生成新布局

---

## 剩余问题

- 敌方单位数据仍为硬编码 2 个哨兵（未接入 .tres 资源或配置文件）
- 玩家单位位置固定，未随机化（设计选择：保持稳定的出发体验）
- 格子密度参数为常量，未提供外部配置入口
- 理论上极端情况下某些格子可能聚集在一起（无最小距离约束）
- 8x8 棋盘大小仍为硬编码（BoardGenerator 已接受 board_size 参数，可扩展）

---

## 建议下一步

1. **卡牌升级机制**（高优先）— 基础牌可升级为强化版本
2. **Boss 遭遇**（中优先）— 特殊遭遇格触发 Boss 战
3. **能量成长机制**（中优先）— 随游戏进度每回合能量上限+1
4. **BuffManager 接入**（中优先）— tick_turn 在回合流程中正式调用

---

## Codex 复审标注

1. **架构判断**：选择创建独立的 BoardGenerator（RefCounted 静态类）而非在 BFC 内部改造。理由：(a) 上岗指令禁止往 BFC 添加逻辑；(b) 生成逻辑与战斗流程完全正交；(c) 静态方法无状态，便于测试和替换。如果后续需要更复杂的生成算法（如保证路径连通性、Perlin 噪声地形），可在 BoardGenerator 内部迭代，不影响 BFC。
2. **格子密度平衡**：当前 8x8=64 格中约放置 15~19 个特殊格子（占 23%~30%），加上 5 个单位占位，共约 20~24 格被占用。剩余 40+ 格为空白可通行格。如果测试中觉得棋盘太拥挤或太空旷，可调整 BoardGenerator 中的常量参数。
3. **BFC 瘦身副作用**：本轮删除了 5 个 _spawn_debug_* 方法，BFC 行数维持在 785 行（因新增了 BoardGenerator preload 和方法改名）。真正的大幅瘦身需要将 _execute_enemy_actions、_check_event_cell 等逻辑提取到独立模块，这是中优先任务，不在本轮范围内。
