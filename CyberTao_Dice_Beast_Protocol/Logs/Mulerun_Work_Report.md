# Mulerun 工作报告

**日期**: 2026-03-30
**版本**: v0.1.50
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.49：掷骰演出升级（伪 3D 等距骰子 + 全屏居中演出）
- v0.1.50：Boss 锁定 + 哨兵前置条件 + 传送门机制

---

## 根因目标

v0.1.49：旧版掷骰动画嵌在 DiceDebugPanel 内部，位置与 HUD 面板重叠，视觉效果不佳。升级为全屏居中的等距伪 3D 立方体翻滚演出，提升掷骰仪式感。

v0.1.50：当前关卡流程过于简单（击杀所有敌方单位即可通关）。新增 Boss 锁定机制：必须先击败两个哨兵单位才能解锁并挑战 Boss 遭遇，Boss 击败后生成传送门，踩上传送门进入下一层。增加了战略层次和通关流程感。

---

## 修改文件

### v0.1.49

| 文件 | 修改内容 |
|------|----------|
| `Scripts/UI/DiceRollAnimation.gd` | **完全重写**，~252行，全屏等距 3D 骰子演出 |
| `Scripts/UI/DiceDebugPanel.gd` | 移除旧内嵌骰子创建，新增 set_dice_animation() 方法 |
| `Scripts/Main.gd` | 创建 DiceRollAnimation 实例，set_board_center，传入 DiceDebugPanel |

### v0.1.50

| 文件 | 修改内容 |
|------|----------|
| `Scripts/BattleV2/BoardManager.gd` | 新增 locked_encounters/portal_cells 字典 + 锁定/解锁/传送门方法 |
| `Scripts/BattleV2/BoardGenerator.gd` | Boss 遭遇格生成后调用 lock_encounter() |
| `Scripts/BattleV2/BattleFlowController.gd` | 新信号 boss_unlocked/portal_spawned；重写 _check_battle_outcome()；新增 _try_unlock_boss()/_spawn_portal_near()/_check_portal() |
| `Scripts/BattleV2/VictoryRuleHelper.gd` | 新增 has_grunt_units() 静态方法 |
| `Scripts/UI/BoardCellRenderer.gd` | 新增 _draw_boss_locked() 和 _draw_portal() 渲染方法 |
| `Scripts/UI/BoardView.gd` | encounter 渲染区分三态（boss/boss_locked/encounter）；新增 portal_cells 渲染 |
| `Scripts/Main.gd` | 连接 boss_unlocked/portal_spawned 信号 + 反馈飘字 |

### 日志

| 文件 | 修改内容 |
|------|----------|
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.49 + v0.1.50 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 版本更新至 v0.1.50，§2.2/§3.1/§3.3/§6 同步 |

---

## 实现内容

### 1. 掷骰演出升级（v0.1.49）

- DiceRollAnimation.gd 完全重写：
  - 全屏遮罩（PRESET_FULL_RECT + MOUSE_FILTER_STOP）
  - 3 枚等距立方体：六边形轮廓 + 三面着色（顶/左/右）+ Crest 符号（顶面）+ 名称（右面）
  - 四阶段动画：tumble（随机翻面）→ settle（逐颗定格+弹跳缩放+辉光）→ hold → fade_out
  - set_board_center() 接口，默认居中于棋盘区域 (328, 382)
- DiceDebugPanel 不再内部创建动画，由 Main 传入外部引用
- Main.gd 在 _build_debug_view() 末尾创建 DiceRollAnimation，z-order 最高

### 2. Boss 锁定 + 传送门（v0.1.50）

- **BoardManager**：新增 locked_encounters 和 portal_cells 字典，6 个新方法
- **BoardGenerator**：Boss 遭遇格生成后自动锁定
- **VictoryRuleHelper**：新增 has_grunt_units() 检测哨兵存活
- **BattleFlowController**：
  - _check_battle_outcome() 重写：DEFEAT 优先判定 → 哨兵全灭时解锁 Boss → 仍有遭遇格/传送门时不判胜
  - _try_unlock_boss()：遍历 locked_encounters 并解锁 + 发信号
  - _spawn_portal_near()：Boss 击败后在附近（优先下方）生成传送门
  - _check_portal()：玩家踩传送门 → FLOOR_CLEAR 或 VICTORY
  - try_move_unit() 新增 _check_portal() 调用
  - _check_encounter() 跳过锁定遭遇格
  - resolve_encounter() Boss 胜利时生成传送门
- **BoardCellRenderer**：新增 boss_locked（灰暗+X锁链+LOCKED文字）和 portal（青蓝旋涡）渲染
- **BoardView**：encounter 渲染三态区分 + portal_cells 渲染循环
- **Main.gd**：连接新信号 + 反馈飘字

---

## 接口变更

### 新增

- `BoardManager.lock_encounter(cell)` / `unlock_encounter(cell)` / `is_encounter_locked(cell)`
- `BoardManager.add_portal_cell(cell)` / `clear_portal_cell(cell)`
- `BoardManager.locked_encounters: Dictionary` / `portal_cells: Dictionary`
- `VictoryRuleHelper.has_grunt_units(unit_manager)` 静态方法
- `BattleFlowController.boss_unlocked` / `portal_spawned` 信号
- `BoardCellRenderer._draw_boss_locked()` / `_draw_portal()` 静态方法
- `DiceRollAnimation.set_board_center(center)` 方法
- `DiceDebugPanel.set_dice_animation(anim)` 方法

### 修改

- `BattleFlowController._check_battle_outcome()` 逻辑重写
- `BattleFlowController._check_encounter()` 新增锁定检查
- `BattleFlowController.resolve_encounter()` Boss 胜利生成传送门
- `DiceRollAnimation` 全部重写（保留 animation_finished 信号签名不变）

### 无变化

- CardBattleController 零修改
- CardBattlePanel 零修改
- CyberStyle 零修改

---

## 测试确认

代码审查确认：
- BoardManager locked_encounters/portal_cells 在 build_test_board() 和 clear_board() 中都正确清理
- advance_to_next_floor() 调用 clear_board() 会自动清理新字典，无需额外修改
- restart_battle() 调用 clear_board() 会自动清理新字典，无需额外修改
- _check_battle_outcome() DEFEAT 在最前判断，不会遗漏失败判定
- _try_unlock_boss() 先收集待解锁格再遍历解锁，避免遍历中修改字典
- _spawn_portal_near() 有 fallback（所有邻格被占时放在原格）
- _check_portal() 只对 player 单位生效，敌方单位踩传送门不触发
- BoardCellRenderer.draw_overlay() dispatch 新增 boss_locked 和 portal 分支
- BoardView 正确区分 boss/boss_locked/encounter 三态渲染
- DiceRollAnimation 保持 animation_finished 信号签名不变，DiceDebugPanel 兼容

---

## 剩余问题

- 层间难度暂不递增（已排后）
- 阵亡单位跨层不复活
- CardRewardPanel 暂未使用 CardRenderer 风格（可在后续统一）
- Boss 卡牌战斗失败时玩家不死（HP 设为 max(1, remaining)），需要考虑是否改为真正死亡

---

## 建议下一步

1. **美化 Phase 4.2**：UI 过渡动画（面板弹出/关闭动画+召唤展开演出）
2. **美化 Phase 5**：音效系统（AudioManager + 基础音效接入）
3. **层间难度递增**：根据 current_floor 调整敌方数值

---

## Codex 复审标注

1. **胜利条件链变更**：原来是"全敌方死=胜利"，现在是"哨兵死→Boss解锁→踩Boss格→卡牌战斗→胜利→传送门→踩传送门→通关"。这大幅增加了通关步骤，需要测试实际游戏节奏是否合理。

2. **传送门位置选择**：优先 Boss 格下方，然后右、左、上。如果所有邻格被占则放在 Boss 原格（fallback）。这个逻辑在大多数情况下能正常工作，但如果 Boss 格在最下排（row 7），下方格子不在棋盘内，会 fallback 到右侧。

3. **_check_battle_outcome 复杂度增加**：原来 3 行逻辑变成约 20 行。核心改变是增加了"遭遇格仍存在"和"传送门存在"两个中间状态检查。这使得胜利条件不再是纯粹基于单位存活状态，而是结合了棋盘格子状态。
