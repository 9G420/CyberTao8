# Mulerun 工作报告

**日期**: 2026-03-29
**版本**: v0.1.27
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- Day 10：卡牌战斗丰富化（卡牌战斗层）

---

## 根因目标

Day 9 的卡牌战斗原型只有固定 5 张手牌、无费用消耗、敌方单一攻击。Day 10 的目标是让卡牌战斗具备最小策略感：能量约束迫使玩家每回合做取舍（出哪几张？留能量还是全打出？）、抽牌随机性带来适应力考验、敌方行为模式让战斗节奏有变化。这三个维度共同构成"出牌有意义"的基础体验。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/BattleV2/CardBattleController.gd` | 重写。新增能量系统（每回合 3 点）；新增双牌堆（10 张牌组，draw/discard/reshuffle）；每回合抽 3 张（上限 6）、回合结束弃手牌；3 种敌方行为（attack/heavy_attack/defend_attack）+ 行为循环模式；敌方意图预告信号；敌方防御减伤机制；胜利奖励信号（+1 随机 crest）；遭遇敌方数据增加 HP 和行为模式 |
| `Scripts/UI/CardBattlePanel.gd` | 重写。动态手牌按钮（根据当前手牌重建）；能量显示；敌方意图显示；牌堆/弃牌计数；结束回合按钮；卡牌费用标签（能量不足时变红）；面板扩大至 480x460；绑定新增信号（hand_changed/enemy_intent_changed/victory_reward） |
| `Scripts/Main.gd` | 连接 `victory_reward` 信号；新增 `_on_card_battle_reward()` 将 crest 奖励写入棋盘层 dice_manager；调整面板位置 |

---

## 实现内容

1. **能量系统**
   - 每回合 3 点能量，出牌消耗对应费用
   - 能量不足的牌按钮灰显禁用
   - 回合结束剩余能量不保留（原型简化）

2. **牌组系统**（参考旧项目 Deck.gd 双牌堆结构）
   - 10 张固定牌组：斩击x2(1E/3伤) / 重击x1(2E/5伤) / 防御x2(1E/减伤2) / 修复x1(1E/回复2) / 连斩x2(1E/2伤) / 猛攻x1(3E/8伤) / 急救x1(2E/回复4)
   - 每回合抽 3 张（手牌上限 6），回合结束弃全部手牌
   - 抽牌堆空时自动从弃牌堆 reshuffle
   - 出牌后立即从手牌移除并进入弃牌堆

3. **敌方行为模式**（3 种行为 + 循环模式）
   - `attack`：普通攻击（ATK 点伤害）
   - `heavy_attack`：重击（ATK×2 伤害）
   - `defend_attack`：防御+攻击（ATK 伤害 + 获得 2 点减伤）
   - 异常哨兵模式：attack → attack → defend_attack → heavy_attack（HP 提升至 8，适应多回合战斗）
   - 赛博游魂模式：attack → heavy_attack → attack（高攻激进型）

4. **敌方意图预告**
   - 每回合开始显示敌方下一步行动类型和预期伤害
   - 玩家可据此决定出防御牌还是攻击牌

5. **防御机制完善**
   - 玩家防御可叠加（同回合出多张防御牌）
   - 敌方 defend_attack 给敌方 +2 减伤，影响玩家下次攻击
   - 所有伤害最低穿透 1 点

6. **胜利奖励**
   - 卡牌战斗胜利后随机获得 +1 crest（6 种之一）
   - crest 直接写入棋盘层 dice_manager.crest_pool

7. **结束回合按钮**
   - 玩家可随时结束回合（不必打完所有牌）
   - 剩余手牌全部进入弃牌堆

---

## 接口变更

| 变更类型 | 内容 |
|----------|------|
| 新增信号 | `CardBattleController.hand_changed(hand, energy, max_energy)` |
| 新增信号 | `CardBattleController.enemy_intent_changed(intent_text)` |
| 新增信号 | `CardBattleController.victory_reward(reward_text)` |
| 新增方法 | `CardBattleController.end_turn()` — 结束玩家回合 |
| 新增方法 | `CardBattleController.get_draw_count()` / `get_discard_count()` |
| 修改方法 | `CardBattleController.play_card()` — 增加能量检查和手牌移除 |
| 修改数据 | `get_encounter_enemy_data()` — 增加 pattern 字段和 HP 调整 |
| 删除信号 | （无） |

---

## 测试确认

- 代码结构检查：所有信号连接链完整
- 逻辑走查：
  - 战斗开始 → 洗牌 → 抽 3 张 → 显示意图 → 出牌消耗能量 → 能量归零后按钮禁用 → 结束回合 → 弃手牌 → 抽新牌 → 敌方行动 → 循环
  - 牌堆耗尽 → reshuffle → 继续抽牌
  - 胜利 → reward crest → battle_ended → resolve_encounter → 棋盘继续
  - 败北 → battle_ended(false) → resolve_encounter → HP 保底 1
- 未在 Godot 引擎中实际运行测试（沙盒环境无 Godot）

---

## 剩余问题

- **未做引擎运行测试** — 需人工确认
- **卡牌无升级/稀有度** — 后续可参考旧 CardData.gd 的 rarity/fusion 系统
- **无能量增长机制** — 旧项目每回合 +1 能量（max 6），可在后续版本引入
- **BuffManager.tick_turn() 仍未接入**
- **BattleFlowController 仍有 740+ 行** — debug spawn 应剥离
- **BUG-001 分辨率切换无效**（低优先级）

---

## 建议下一步

1. **Day 11：UI 去调试化** — DiceDebugPanel 视觉升级、按钮样式统一、配色统一
2. **Day 12：阶段收口 + 日志整理**

---

## Codex 复审标注

1. **敌方防御减伤只影响玩家下一次攻击牌**（`_enemy_def_bonus` 在 `_resolve_card` 的 attack 分支中消费后归零）。这是简化设计，STS 风格通常是 block 持续一回合。如果需要改为持续一回合，需在 `_enemy_act` 开始时重置而非在 `_resolve_card` 中。
2. **能量不保留跨回合** — 原型简化选择。旧项目的能量模型更复杂（next_turn_energy 等）。当前设计足以让出牌有取舍意义。
3. **胜利奖励直接写入 dice_manager.crest_pool** — 通过 Main.gd 中转，未引入新的跨层信号。如果后续奖励种类增多，建议新建 RewardSystem。
