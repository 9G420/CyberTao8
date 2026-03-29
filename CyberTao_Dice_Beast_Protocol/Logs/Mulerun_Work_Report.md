# Mulerun 工作报告

**日期**: 2026-03-29
**版本**: v0.1.26
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- Day 9 架构重构：按上岗指令拆分卡牌战斗为 CardBattleController（逻辑）+ CardBattlePanel（UI），剥离 BattleFlowController 中不该存在的卡牌逻辑

---

## 根因目标

v0.1.25 的卡牌战斗实现违反了上岗指令的架构规则：战斗逻辑和 UI 混写在 CardBattlePanel 中，遭遇敌方数据映射和卡牌战斗信号堆在 BattleFlowController 里。本轮重构将卡牌战斗层拆分为独立的 Controller + Panel 架构，使两层（棋盘走位层 / 卡牌战斗层）的代码边界清晰，为 Day 10 丰富化打好基础。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/BattleV2/CardBattleController.gd` | **新增**。独立卡牌战斗状态机，包含：BattleState 枚举（IDLE/PLAYER_TURN/ENEMY_TURN/VICTORY/DEFEAT）、手牌构建、出牌结算、敌方行动、逃跑、遭遇敌方数据映射（static 方法）、完整信号链（battle_started/card_played/enemy_acted/turn_resolved/battle_ended） |
| `Scripts/UI/CardBattlePanel.gd` | **重写为纯 UI**。移除所有战斗状态和逻辑，改为通过 `bind_controller()` 绑定 CardBattleController 信号，按钮点击委托给 controller 方法 |
| `Scripts/BattleV2/BattleFlowController.gd` | 移除 `card_battle_started`/`card_battle_ended` 信号；移除 `get_encounter_enemy_data()` 方法；简化 `_check_encounter()` 只发射 `encounter_triggered`；`resolve_encounter()` 保留但去掉 card_battle_ended 发射；新增 `get_encounter_unit_id()` 查询方法 |
| `Scripts/UI/DiceDebugPanel.gd` | 移除 `card_battle_ended` 信号连接和 `_on_card_battle_ended()` 回调；遭遇面板按钮保持"卡牌战斗进行中..." |
| `Scripts/Main.gd` | 新增 `CardBattleController` 实例化（add_child）；`_on_encounter_triggered()` 中直接启动 controller；`_on_card_battle_ended()` 中先记录 encounter_cell 再调用 resolve_encounter；CardBattlePanel 通过 `bind_controller()` 连接 |

---

## 实现内容

1. **架构拆分**：CardBattlePanel（纯 UI，~170 行） + CardBattleController（纯逻辑，~115 行）
2. **信号归属修正**：卡牌战斗相关信号全部在 CardBattleController 上，BattleFlowController 只保留棋盘层信号
3. **数据归属修正**：遭遇敌方数据（异常哨兵/赛博游魂）从 BFC 移至 CardBattleController 的 static 方法
4. **接口简化**：BFC 只暴露 `encounter_triggered` 和 `resolve_encounter()`，不再关心卡牌战斗内部
5. **旧项目盘点**：已读旧 BattleManager.gd（2500+ 行）/ GameState.gd / Hand.gd / Deck.gd / CardData.gd，结论记录在 CardBattleController 文件头注释

---

## 接口变更

| 变更类型 | 内容 |
|----------|------|
| 新增信号 | `CardBattleController.battle_started(player_hp, enemy_hp, enemy_name)` |
| 新增信号 | `CardBattleController.card_played(card_index, card_name, effect_text)` |
| 新增信号 | `CardBattleController.enemy_acted(action_text)` |
| 新增信号 | `CardBattleController.turn_resolved(player_hp, enemy_hp, battle_turn)` |
| 新增信号 | `CardBattleController.battle_ended(victory, player_hp_remaining)` |
| 新增方法 | `CardBattleController.start_battle(enc_id, p_hp, p_max_hp)` |
| 新增方法 | `CardBattleController.play_card(index)` |
| 新增方法 | `CardBattleController.flee()` |
| 新增静态 | `CardBattleController.get_encounter_enemy_data(enc_id) -> Dictionary` |
| 新增方法 | `CardBattlePanel.bind_controller(controller)` |
| 新增方法 | `BattleFlowController.get_encounter_unit_id() -> String` |
| 删除信号 | `BattleFlowController.card_battle_started`（已移至 CardBattleController） |
| 删除信号 | `BattleFlowController.card_battle_ended`（已移至 CardBattleController） |
| 删除方法 | `BattleFlowController.get_encounter_enemy_data()`（已移至 CardBattleController） |

---

## 测试确认

- 代码结构检查：所有信号连接链完整，无悬挂引用
- 闭环流程验证（逻辑走查）：
  - 掷骰 → 移动 → 踩遭遇格 → ENCOUNTER 暂停 → CardBattleController.start_battle() → CardBattlePanel 显示 → 出牌 → 敌方行动 → 循环 → battle_ended → resolve_encounter() → PLAYER_ACTION 恢复
  - 逃跑流程：flee() → battle_ended(false, hp-1) → resolve_encounter(false, hp) → HP 保底 1
  - 重新开始：restart_battle() 不受影响（CardBattleController 为 IDLE 状态）
- 未在 Godot 引擎中实际运行测试（沙盒环境无 Godot）

---

## 剩余问题

- **未做引擎运行测试** — 沙盒无 Godot 4.6.1 环境，需人工确认
- **手牌固定不消耗** — Day 10 加入费用系统和抽牌机制
- **敌方行为单一** — Day 10 加入 2~3 种敌方行为模式
- **BuffManager.tick_turn() 仍未接入** — 已记录，不在当前任务范围
- **BUG-001 分辨率切换无效**（低优先级）
- **BattleFlowController 仍有 750+ 行** — debug spawn 函数应剥离到 DebugScenario.gd（Day 10 可并行）

---

## 建议下一步

1. **Day 10：卡牌战斗丰富化** — 能量/费用系统（参考旧 BattleManager 的 energy 模型）、手牌抽取（参考旧 Deck.gd 双牌堆结构）、2~3 种敌人行为模式
2. **Day 10 并行：BFC debug spawn 剥离** — 新建 DebugScenario.gd，降低 BFC 行数
3. **Day 11~12 按周计划继续**

---

## 旧项目卡牌结构盘点结论

| 旧文件 | 判断 | 理由 |
|--------|------|------|
| BattleManager.gd (2500 行) | **不复用，部分参考** | 阴阳系统/召唤/98卡池等远超原型需求，但 energy 增长模型（每回合+1, max 6）和 X-cost 概念可参考 |
| Deck.gd | **Day 10 可参考** | 双牌堆（draw + discard）+ 自动 reshuffle 结构干净，适合移植 |
| Hand.gd | **不复用** | 扇形布局是 STS 风格 UI，当前原型用按钮即可 |
| CardData.gd | **Day 10 可参考** | cost/power/defense/type 字段结构合理，可简化后用于卡牌资源 |
| GameState.gd | **不复用** | 地图/商店/成就等属于 meta 层，原型不需要 |

---

## Codex 复审标注

1. **CardBattleController 作为独立 Node 挂在 Main 下**（而非 BFC 子节点）——判断依据：上岗指令明确要求"不要把卡牌逻辑写进 BFC"，独立节点确保两层解耦。风险：如果后续需要 controller 访问 BFC 的 dice_manager（例如 Day 10 的费用系统可能与 crest 联动），需要通过 Main.gd 中转或新增绑定接口。
2. **resolve_encounter() 的 player_hp_remaining 参数**——判断依据：卡牌战斗结束时需要同步 HP 回棋盘单位，最直接的方式是传递剩余 HP。替代方案是让 controller 直接持有 unit_manager 引用，但这会打破层间隔离。选择了保守方案（通过参数传递）。
