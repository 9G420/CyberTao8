# Mulerun 工作报告

**日期**: 2026-03-29
**版本**: v0.1.31
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- Day 13：卡牌构筑成长（第二阶段首个任务）

---

## 根因目标

第一阶段（Day 1~12）完成了双层玩法最小闭环，但卡牌战斗缺少"成长感"——每次遭遇使用相同的固定 10 张牌组，玩家无法通过战斗获得新卡牌。Day 13 的目标是引入"战斗胜利后选牌构筑"机制，让每次遭遇都有"收获感"，是从"可玩"到"想玩"的关键一步。服务于卡牌战斗层。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/BattleV2/CardBattleController.gd` | 新增持久牌组系统（persistent_deck，跨战斗保留）；新增 REWARD_SELECT 状态；新增奖励卡池（13 张候选，含 5 种新卡牌类型）；新增 reward_cards_offered / reward_card_selected 信号；新增 select_reward_card() / skip_reward() / reset_persistent_deck() 方法；新增 pierce/lifesteal/shock 三种新卡牌效果结算 |
| `Project/Scripts/UI/CardRewardPanel.gd` | **新建文件**。战斗胜利后显示 3 张随机候选卡牌的选择面板，品红色边框赛博朋克风格，纯 UI 层 |
| `Project/Scripts/UI/CardBattlePanel.gd` | 修改 _on_battle_ended：胜利时缩短延迟（0.5s），不再阻塞奖励面板显示 |
| `Project/Scripts/Main.gd` | 新增 CardRewardPanel 引用和创建；绑定奖励面板到控制器；重新开始时重置持久牌组 |
| `Logs/Mulerun_Work_Report.md` | 本文件，Day 13 工作报告 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.31 条目 |

---

## 实现内容

1. **持久牌组系统**
   - 牌组在首次战斗时初始化为 10 张基础牌，后续战斗复用同一牌组
   - 每次战斗从持久牌组复制到抽牌堆（不影响原始牌组）
   - 重新开始游戏时重置牌组为初始状态

2. **战斗胜利选牌机制**
   - 击败敌人后进入 REWARD_SELECT 状态（不立即结束战斗）
   - 从 13 张奖励卡池中随机选取 3 张展示
   - 玩家可选择 1 张加入持久牌组，或跳过
   - 选择后卡牌永久加入牌组，后续战斗中可抽到

3. **5 种新卡牌类型**
   - 穿刺（pierce）：2E，4 伤害，无视敌方防御
   - 吸血斩（lifesteal）：2E，3 伤害 + 回复 1 HP
   - 电弧（shock）：1E，2 伤害 + 永久降低敌方 ATK 1 点
   - 强化斩击：1E，4 伤害（基础斩击的强化版）
   - 双重防御：1E，防御 3（基础防御的强化版）

4. **CardRewardPanel 奖励选牌面板**
   - 品红色边框赛博朋克风格（与战斗面板的橙色区分）
   - 显示卡牌名称、类型、费用、数值
   - 跳过按钮允许不选择
   - 选择后自动关闭

---

## 接口变更

### 新增信号（CardBattleController）
- `reward_cards_offered(options: Array)` — 奖励候选卡牌生成后发出
- `reward_card_selected(card: Dictionary)` — 玩家选择奖励卡牌后发出

### 新增方法（CardBattleController）
- `select_reward_card(index: int)` — 选择指定索引的奖励卡牌加入牌组
- `skip_reward()` — 跳过奖励选择
- `get_reward_options() -> Array[Dictionary]` — 获取当前奖励候选列表
- `get_deck_size() -> int` — 获取持久牌组大小
- `reset_persistent_deck()` — 重置牌组为初始 10 张

### 新增状态（CardBattleController）
- `BattleState.REWARD_SELECT` — 奖励选牌阶段

### 新增文件
- `Scripts/UI/CardRewardPanel.gd` — 奖励选牌面板（class_name: CardRewardPanel）

---

## 测试确认

代码逻辑自查通过：
- 持久牌组初始化和复制逻辑正确
- 新卡牌效果结算（pierce/lifesteal/shock）逻辑完整
- REWARD_SELECT 状态正确拦截非法操作（play_card/end_turn/flee 在此状态下无效）
- 选牌后正确调用 _finish_battle → battle_ended 信号 → 棋盘层 resolve_encounter
- 重新开始时重置牌组

---

## 剩余问题

- 电弧（shock）效果是永久降低 enemy_atk，可能需要改为仅本场战斗生效（当前因为 start_battle 会重新读取敌方数据，实际已经是单场生效）
- 奖励卡池目前是固定的 13 张，后续可引入稀有度权重
- 牌组没有上限限制，理论上可以无限膨胀（可在后续加入上限或移除机制）
- CardRewardPanel 位置 (380, 200) 可能与 CardBattlePanel 有轻微重叠，但因为 CardBattlePanel 在胜利后 0.5s 隐藏，视觉上不冲突

---

## 建议下一步

1. **更多敌方种类**（高优先）— 当前只有 2 种遭遇敌方，需要 3~5 种以增加战斗变化
2. **牌组查看面板** — 让玩家在棋盘阶段查看当前持久牌组内容
3. **卡牌升级机制** — 基础牌可通过多次获得升级为强化版
4. **棋盘随机生成** — 从固定布局升级为程序化棋盘

---

## Codex 复审标注

1. **架构判断：持久牌组放在 CardBattleController 内部** — 选择将 persistent_deck 作为 CardBattleController 的成员变量而非独立的 DeckManager，因为当前复杂度不需要额外抽象。如果后续引入牌组编辑/存档，可能需要剥离为独立管理器。
2. **电弧卡效果设计** — 永久降低 enemy_atk 的效果看似强力，但因为每场战斗 start_battle() 会重新读取敌方数据，实际只在当场生效。这个隐式行为是否需要显式重置，待复审。
