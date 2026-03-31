# Mulerun 工作报告

**日期**: 2026-03-31
**版本**: v0.1.57
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.57：层间难度递增（根据 current_floor 缩放敌方 HP/ATK）

---

## 根因目标

AI_Employee_Guide_v3 §6 当前最高优先级任务。3层地图各层敌方数值完全相同（哨兵甲 HP5/ATK2、哨兵乙 HP4/ATK3、遭遇敌方固定数值），无难度递增感。本轮目标：根据当前层数对棋盘敌方单位和卡牌层遭遇敌方同时进行 HP/ATK 缩放，使后续层逐步变难。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/BattleV2/BoardGenerator.gd` | generate_board 新增 current_floor 参数；新增 _floor_scaling 缩放函数；_spawn_enemies 按层缩放 HP/ATK |
| `Scripts/BattleV2/CardBattleController.gd` | get_encounter_enemy_data 新增 current_floor 参数，返回前按层缩放 HP/ATK；start_battle 新增 current_floor 参数透传 |
| `Scripts/BattleV2/BattleFlowController.gd` | 3处 generate_board 调用传入 current_floor（_ready/advance_to_next_floor/restart_battle） |
| `Scripts/Main.gd` | 2处 start_battle 调用传入 _battle_flow.current_floor（遭遇触发+调试快捷键） |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.57 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号+完成列表+任务优先级 |

---

## 实现内容

### 缩放公式

| 层数 | HP 倍率 | ATK 加值 | 说明 |
|------|---------|----------|------|
| 第1层 | x1.0 | +0 | 基准数值，无变化 |
| 第2层 | x1.3 | +1 | HP 向上取整 |
| 第3层 | x1.6 | +2 | HP 向上取整 |

公式：`floor_offset = max(0, current_floor - 1)`
- HP = ceil(base_hp * (1.0 + 0.3 * floor_offset))
- ATK = base_atk + floor_offset

### 棋盘层敌方单位（BoardGenerator）

| 单位 | 第1层 | 第2层 | 第3层 |
|------|-------|-------|-------|
| 哨兵甲 | HP5/ATK2 | HP7/ATK3 | HP8/ATK4 |
| 哨兵乙 | HP4/ATK3 | HP6/ATK4 | HP7/ATK5 |

### 卡牌层遭遇敌方（CardBattleController）

| 遭遇 | 第1层 | 第2层 | 第3层 |
|------|-------|-------|-------|
| 异常哨兵 | HP8/ATK2 | HP11/ATK3 | HP13/ATK4 |
| 赛博游魂 | HP6/ATK3 | HP8/ATK4 | HP10/ATK5 |
| 暗网爬虫 | HP12/ATK1 | HP16/ATK2 | HP20/ATK3 |
| 脉冲猎手 | HP5/ATK4 | HP7/ATK5 | HP8/ATK6 |
| 数据幽灵 | HP9/ATK2 | HP12/ATK3 | HP15/ATK4 |
| 零号协议(Boss) | HP20/ATK3 | HP26/ATK4 | HP32/ATK5 |

### 调用链

- BattleFlowController._ready → BoardGenerator.generate_board(..., current_floor)
- BattleFlowController.advance_to_next_floor → BoardGenerator.generate_board(..., current_floor)
- BattleFlowController.restart_battle → BoardGenerator.generate_board(..., 1)
- Main._on_encounter_triggered → CardBattleController.start_battle(..., current_floor)
- Main._on_test_card_battle_requested → CardBattleController.start_battle(..., current_floor)

---

## 接口变更

- `BoardGenerator.generate_board(board_mgr, unit_mgr, board_size, current_floor)` — 新增第4参数 current_floor: int = 1
- `BoardGenerator._floor_scaling(current_floor)` — 新增静态方法，返回 {hp_mult, atk_add}
- `BoardGenerator._spawn_enemies(unit_mgr, board_size, used_cells, current_floor)` — 新增第4参数
- `CardBattleController.get_encounter_enemy_data(enc_id, current_floor)` — 新增第2参数 current_floor: int = 1
- `CardBattleController.start_battle(enc_id, p_hp, p_max_hp, current_floor)` — 新增第4参数 current_floor: int = 1
- 所有新增参数均有默认值 = 1，不影响现有无参调用的兼容性

---

## 测试确认

- 第1层棋盘敌方数值不变（哨兵甲 HP5/ATK2，哨兵乙 HP4/ATK3）
- 第2层棋盘敌方数值递增（哨兵甲 HP7/ATK3，哨兵乙 HP6/ATK4）
- 第1层遭遇敌方数值不变（异常哨兵 HP8/ATK2）
- 第2层遭遇敌方数值递增（异常哨兵 HP11/ATK3）
- restart_battle 重置为第1层，数值回归基准
- 调试快捷键卡牌战斗也按当前层缩放
- 所有参数默认值 = 1，不破坏现有代码路径

---

## 剩余问题

- 阵亡单位跨层不复活
- CardRewardPanel 暂未使用 CardRenderer 风格
- 扇形手牌暂无拖拽机制（仅点击出牌）
- 角色立绘为程序化绘制
- SettingsPanel 暂未添加音量/音效开关控件

---

## 建议下一步

1. 商店格扩展（多选商品 + 独立 UI 面板）
2. 阵亡单位跨层复活机制
3. SettingsPanel 添加音量滑块 + SFX/BGM 开关
