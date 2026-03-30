# Mulerun 工作报告

**日期**: 2026-03-30
**版本**: v0.1.37
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- Day 19：Boss 遭遇

---

## 根因目标

当前 5 种遭遇敌方（HP 4~12，ATK 1~4）均为普通战斗，缺乏终局挑战感。Boss 遭遇作为特殊高难度战斗，具有高 HP（20）、独特多阶段行为模式（含回复和超载重击）、独立的棋盘视觉标识和增强奖励，为玩家的卡牌构筑提供终极考验。服务于卡牌战斗层 + 棋盘走位层（Boss 格放置）。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/BattleV2/CardBattleController.gd` | 新增 encounter_boss_01 数据（HP20/ATK3/6阶段模式/is_boss标记）；_enemy_act() 新增 heal 和 mega_attack 两种敌方行为；_update_enemy_intent() 新增对应意图文案；Boss 胜利提供 4 张奖励牌（普通 3 张）；新增 is_boss_encounter() 辅助方法 |
| `Project/Scripts/BattleV2/BoardGenerator.gd` | 新增 BOSS_ENCOUNTER_IDS 常量；generate_board() 每局放置 1 个 Boss 遭遇格（优先右上象限）；新增 _pick_boss_cell() 选位方法 |
| `Project/Scripts/UI/BoardView.gd` | _draw_encounters() 区分 Boss 与普通遭遇：Boss 格深红填充 + 粗边框 + "BOSS" 文字 |
| `Project/Scripts/UI/CardBattlePanel.gd` | Boss 战斗标题显示 [BOSS] 标记；Boss 战斗禁止逃跑 |
| `Project/Scripts/UI/DiceDebugPanel.gd` | 版本号更新为 v0.1.37 |
| `Project/Scripts/Main.gd` | 棋盘图例提示新增"深红=BOSS" |
| `Logs/Mulerun_Work_Report.md` | 本文件，Day 19 工作报告 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.37 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步更新至 v0.1.37 状态 |

---

## 实现内容

1. **Boss 遭遇敌方数据**
   - encounter_boss_01："零号协议"
   - HP: 20，ATK: 3，is_boss: true
   - 6 阶段行为循环：attack → defend_attack → heavy_attack → heal → attack → mega_attack
   - heal 行为：Boss 回复 3 HP（上限为满血）
   - mega_attack 行为：造成 3×ATK = 9 伤害（含减免计算）

2. **Boss 行为模式设计思路**
   - 6 回合一循环，覆盖攻防和回复，玩家需在 heal 前尽量削血
   - mega_attack 作为循环终点给予高威胁，玩家需在第 5~6 回合储备防御
   - heal 只回复 3 HP（max 20 的 15%），不过强但增加持久战压力
   - 不可逃跑，玩家必须正面应战

3. **Boss 棋盘放置**
   - 每局棋盘放置 1 个 Boss 遭遇格
   - 优先放置在右上象限（col ≥ 4, row ≤ 3），远离玩家出生区
   - 如右上象限满则回退到整个上半区域

4. **Boss 视觉区分**
   - 棋盘：Boss 格使用深红色填充 + 更粗边框（3px vs 普通 2.5px）+ "BOSS" 文字（12号字，纯红色）
   - 战斗面板标题显示"卡牌战斗 — 零号协议 [BOSS]"
   - 图例提示新增"深红=BOSS"

5. **Boss 奖励增强**
   - Boss 战胜利后奖励选牌提供 4 张（普通遭遇 3 张），增加获得稀有牌的机会

6. **Boss 战不可逃跑**
   - Boss 战斗中逃跑按钮禁用，显示"无法逃跑"

---

## 接口变更

### 新增数据（CardBattleController）
- `encounter_boss_01` 遭遇数据：含 `is_boss: true` 标记
- `"heal"` 敌方行为：Boss 回复 3 HP
- `"mega_attack"` 敌方行为：造成 ATK×3 伤害

### 新增方法（CardBattleController）
- `is_boss_encounter() -> bool` — 判断当前战斗是否为 Boss 遭遇

### 新增常量（BoardGenerator）
- `BOSS_ENCOUNTER_IDS: Array[String]` — Boss 遭遇 ID 池

### 新增方法（BoardGenerator）
- `_pick_boss_cell(board_size, used_cells) -> Array[Vector2i]` — 为 Boss 选择放置位置

---

## 测试确认

代码逻辑自查通过：
- `get_encounter_enemy_data("encounter_boss_01")` 返回正确的 Boss 数据（HP20/ATK3/6阶段模式/is_boss=true）
- `_enemy_act()` 正确处理 heal 行为：回复 3 HP，不超过 enemy_max_hp
- `_enemy_act()` 正确处理 mega_attack 行为：3×ATK=9 伤害，含 def_bonus 减免
- `_update_enemy_intent()` 正确显示 heal 和 mega_attack 的意图文案
- `is_boss_encounter()` 根据 encounter_id 查询 is_boss 字段，默认返回 false
- `_generate_reward_options()` Boss 胜利时 choice_count=4，普通时 choice_count=3
- BoardGenerator 每局放置 1 个 Boss 遭遇格，不与其他格子重叠
- Boss 格优先选择右上象限，远离玩家出生区
- BoardView 正确区分 Boss 格（enc_id.begins_with("encounter_boss_")）和普通遭遇格
- CardBattlePanel Boss 战标题显示 [BOSS] 标记，逃跑按钮禁用
- 棋盘层完整闭环不受影响：未触碰 BattleFlowController 核心逻辑
- 卡牌层闭环正常：Boss 遭遇触发 → 卡牌战斗 → 出牌/敌方行动（含 heal 和 mega_attack）→ 奖励选牌（4选1）→ HP 同步回棋盘
- 普通遭遇不受影响：原有 5 种遭遇数据和行为模式无变化
- 重新开始后 Boss 格随机重新生成

---

## 剩余问题

- Boss 只有 1 种（零号协议），后续可扩展更多 Boss（加入 BOSS_ENCOUNTER_IDS 即可）
- Boss 的 heal 行为固定回复 3 HP，未参数化（后续可加入数据驱动）
- mega_attack 固定 3 倍 ATK，未参数化
- Boss 战无特殊胜利画面或音效（依赖视觉演出阶段）
- Boss 数值（HP20/ATK3）未经平衡测试
- Boss 不可逃跑但可以通过被击败退出（扣 HP 惩罚），设计上是否合理待验证

---

## 建议下一步

1. **能量成长机制**（中优先）— 随游戏进度每回合能量上限+1
2. **BuffManager 接入**（中优先）— tick_turn 在回合流程中正式调用
3. **BattleFlowController 瘦身**（中优先）— 剥离逻辑到独立模块，目标降至 600 行以下
4. **更多 Boss 类型**（低优先）— 扩展 Boss 池，不同 Boss 有不同行为模式

---

## Codex 复审标注

1. **架构判断**：Boss 遭遇数据和行为逻辑全部在 CardBattleController 内实现（新增约 35 行），未创建独立文件。理由：(a) Boss 和普通敌方共用同一套状态机和行为框架，仅在数据层面区分；(b) heal 和 mega_attack 是通用敌方行为类型，未来普通敌方也可使用；(c) Controller 从约 490 行增长到约 505 行，仍在合理范围。如果后续 Boss 需要多阶段转换（如 HP 低于 50% 切换模式）或专属技能系统，可提取到独立的 BossEncounterManager。

2. **数值设计**：Boss HP20 约为当前最强普通敌（暗网爬虫 HP12）的 1.67 倍。ATK3 低于脉冲猎手的 ATK4，但 mega_attack（ATK×3=9）是全游戏最高单回合伤害。6 回合循环中，前 3 回合累计伤害约 3+5+6=14（不含减免），heal 回复 3，回合 5~6 累计 3+9=12。玩家初始牌组 10 张平均每回合约 3~5 伤害输出，需 4~7 回合击杀 Boss（考虑 heal），节奏合理。但未实际测试，可能需要微调。

3. **不可逃跑决策**：Boss 战禁止逃跑是为了保证 Boss 遭遇的仪式感和挑战性。玩家只有两种结局：击败 Boss 获得增强奖励，或被 Boss 击败受到 HP 惩罚。这参考了 STS 的 Boss 战不可跳过设计。如果测试中发现 Boss 战过于惩罚性（玩家因牌组弱而必败），可考虑恢复逃跑或加入"投降"选项（HP 惩罚较轻）。
