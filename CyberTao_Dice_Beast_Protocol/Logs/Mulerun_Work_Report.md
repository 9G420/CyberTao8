# Mulerun 工作报告

**日期**: 2026-03-30
**版本**: v0.1.53
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.53：Boss 解锁自动传送 + 宝可梦式卡牌战斗过渡

---

## v0.1.53 实现内容

### 问题背景

1. 哨兵全灭后 Boss 在棋盘远处，玩家需要多回合掷骰走路才能到达，期间零游戏性
2. 卡牌战斗仍以浮窗形式叠在棋盘上，缺乏场景切换感

### 功能一：Boss 解锁后英雄自动传送

- `_try_unlock_boss()` 末尾新增 `_warp_hero_to_boss(boss_cell)` 调用
- `_warp_hero_to_boss()` 查找英雄单位（非 summoned 的玩家单位），传送到 Boss 格旁边的空格（优先下方）
- 新增信号 `hero_warped(unit_id, target_cell)`
- Main.gd 连接 `hero_warped` 信号，飘字提示"传送至 Boss！"

### 功能二：宝可梦式卡牌战斗过渡

- **新增 `TransitionOverlay.gd`**（~110行）：CanvasLayer（layer 10）百叶窗过渡动画
  - 8 条水平百叶窗，合拢 0.35s / 展开 0.3s
  - `transition_to_battle(enemy_name, is_boss)` — 百叶窗合拢 + 闪烁敌方名称
  - `reveal()` — 百叶窗展开
  - `transition_to_board()` — 百叶窗合拢（退出战斗）
  - Boss 遭遇使用暗红色百叶窗区分
- **Main.gd 遭遇触发流程重写**：
  - `_on_encounter_triggered()` → 百叶窗合拢 + 闪字 → 显示暗幕+战斗面板 → 百叶窗展开
  - `_on_card_battle_ended()` → 等待 0.8s 结果展示 → 百叶窗合拢 → 隐藏面板 → 结算 → 百叶窗展开
- **全屏暗幕**：`_battle_dark_bg`（ColorRect 1280x720，85% 不透明黑色）遮挡棋盘
- **CardBattlePanel 可见性管理**：移除 `_on_battle_started` 和 `_on_battle_ended` 的自动 visible 控制，改由 Main.gd 通过过渡统一管理
- **遭遇名称映射**：`_get_encounter_display_name()` 返回中文敌方名称用于闪字

### 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/UI/TransitionOverlay.gd` | 新增文件，百叶窗过渡动画 |
| `Scripts/BattleV2/BattleFlowController.gd` | 新增 `hero_warped` 信号、`_warp_hero_to_boss()` 函数；`_try_unlock_boss()` 末尾调用自动传送 |
| `Scripts/Main.gd` | 新增 TransitionOverlay + 暗幕；重写 `_on_encounter_triggered` / `_on_card_battle_ended` / `_on_test_card_battle_requested`；新增 `_on_hero_warped` / `_get_encounter_display_name` |
| `Scripts/UI/CardBattlePanel.gd` | `_on_battle_started` / `_on_battle_ended` 移除自动 visible 控制 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.53 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号+完成列表+任务优先级 |

### 接口变更

- `BattleFlowController.hero_warped(unit_id, target_cell)` — 新增信号
- `BattleFlowController._warp_hero_to_boss(boss_cell)` — 新增内部方法
- `CardBattlePanel._on_battle_started()` — 不再设 `visible = true`
- `CardBattlePanel._on_battle_ended()` — 不再自动隐藏面板
- `TransitionOverlay` — 新增 class_name

### 自查确认

- `_warp_hero_to_boss()` 正确查找非 summoned 玩家单位，传送到 Boss 旁空格
- `_warp_hero_to_boss()` 使用 `unit_manager.move_unit()` 正确更新 occupied_cells
- TransitionOverlay 使用 CanvasLayer layer 10，不影响任何现有 UI 层级
- 暗幕 `_battle_dark_bg` 置于 CardBattlePanel 之下，CardBattlePanel 通过 remove/add_child 确保在暗幕上层
- `_on_encounter_triggered` 正确 await 过渡完成后才启动战斗
- `_on_card_battle_ended` 先等 0.8s 展示结果，再过渡回棋盘
- 层间奖励 `_floor_clear_pending` 分支不走过渡动画（保持原流程）
- 调试按钮"测试战斗"也走过渡流程
- v0.1.51 三分支 resolve_encounter 不受影响
- v0.1.52 单位精简+伙伴槽不受影响

---

## 剩余问题

- 层间难度暂不递增
- 阵亡单位跨层不复活
- CardRewardPanel 暂未使用 CardRenderer 风格
- CardBattlePanel 内部布局未扩展为真正全屏（保持 500x470 居中+暗幕）

---

## 建议下一步

1. CardBattlePanel 全屏布局重设计（利用 1280x720 全屏空间）
2. 层间难度递增
3. Crest 蓄力池 + 骰子操控机制
