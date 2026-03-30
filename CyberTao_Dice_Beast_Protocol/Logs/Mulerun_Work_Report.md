# Mulerun 工作报告

**日期**: 2026-03-30
**版本**: v0.1.33
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- Day 15：DEFEND/SKILL/TRICK crest 消耗入口

---

## 根因目标

骰子 6 面中有 3 面（护持/术式/机巧）占 50% 概率却完全无法使用，玩家每回合有一半骰面是"废骰"。Day 15 的目标是为这 3 种 crest 设计实际消耗入口，让每颗骰子都有价值，提升掷骰决策深度。服务于棋盘走位层。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/BattleV2/BattleFlowController.gd` | 新增 3 个 crest 使用方法（try_use_defend_crest / try_use_skill_crest / try_use_trick_crest）；新增 3 个信号；修改 _calc_damage_with_terrain 加入 temp_def；end_player_turn 中清除临时防御 |
| `Project/Scripts/UI/DiceDebugPanel.gd` | 新增护持/术式/机巧 3 个操作按钮（紧凑一行排列）；按钮回调接入 BFC 方法；UI 元素下移适配；版本号更新为 v0.1.33；面板高度从 540 调整为 574 |
| `Project/Scripts/Main.gd` | 接入 defend_crest_used / skill_crest_used / trick_crest_used 信号；新增 3 个回调函数提供视觉反馈 |
| `Logs/Mulerun_Work_Report.md` | 本文件，Day 15 工作报告 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.33 条目 |

---

## 实现内容

1. **护持(DEFEND) crest — 临时防御**
   - 消耗 1 护持 crest，选中玩家单位本回合 DEF +1
   - 可多次使用累加（每次 +1）
   - 回合结束时自动清零（不持续到下回合）
   - 集成到伤害公式：`max(1, ATK - DEF - 地形加成 - 临时防御)`
   - 需要先选中单位再点击按钮

2. **术式(SKILL) crest — 即时回复**
   - 消耗 1 术式 crest，选中玩家单位回复 2 HP
   - 满血时无法使用（防止浪费）
   - 不超过最大 HP
   - 需要先选中单位再点击按钮

3. **机巧(TRICK) crest — 资源转化**
   - 消耗 1 机巧 crest，随机获得 +1 实用 crest（步进/杀伐/显化三选一）
   - 不需要选中单位
   - 等概率 33.3% 每种

4. **UI 集成**
   - 3 个按钮紧凑排列在召唤和测试卡牌按钮下方
   - 护持按钮橙色主题，术式和机巧按钮青色主题
   - 使用后棋盘飘字反馈（DEF+N / HP+N）
   - 资源池面板实时刷新

---

## 接口变更

### 新增信号（BattleFlowController）
- `defend_crest_used(unit_id: String, new_temp_def: int)` — 护持 crest 使用后
- `skill_crest_used(unit_id: String, heal_amount: int)` — 术式 crest 使用后
- `trick_crest_used(gained_crest: String)` — 机巧 crest 使用后

### 新增方法（BattleFlowController）
- `try_use_defend_crest(unit_id: String) -> bool` — 使用护持 crest
- `try_use_skill_crest(unit_id: String) -> bool` — 使用术式 crest
- `try_use_trick_crest() -> bool` — 使用机巧 crest

### 修改方法
- `_calc_damage_with_terrain()` — 新增 temp_def 参与防御计算
- `end_player_turn()` — 新增 _clear_temp_def() 调用

### 新增数据字段
- 单位字典新增 `temp_def: int`（临时防御，回合结束清零）

---

## 测试确认

代码逻辑自查通过：
- 3 种 crest 均在 PLAYER_ACTION 阶段才可使用
- 护持/术式需要选中玩家单位，机巧不需要
- temp_def 在 end_player_turn 中正确清零
- 伤害公式正确集成 temp_def
- DiceDebugPanel 布局无重叠（已下移所有下方元素 34px）
- 面板底部 ver_label 在 y=554，面板高度 574，不超出视口（94+574=668 < 720）

---

## 剩余问题

- 护持/术式按钮未选中单位时点击无效果但无提示（可后续加提示文字）
- 机巧转化结果在 UI 上没有直接文字提示（只有资源池数值变化）
- 敌方目前不使用 defend/skill/trick crest（敌方 AI 仍只用 move/attack）
- DiceDebugPanel 面板高度增加到 574，如果后续再添加按钮需要考虑布局空间

---

## 建议下一步

1. **牌组查看面板**（中优先）— 构筑系统配套 UI
2. **棋盘随机生成**（高优先）— 固定布局重玩性低
3. **BFC 瘦身**（中优先）— 将 debug spawn 剥离
4. **DiceDebugPanel 重构**（低优先）— 面板已接近空间上限，可考虑折叠/分页

---

## Codex 复审标注

1. **Crest 效果平衡** — 护持 DEF+1 对比敌方 ATK 2~3 来说偏弱但安全；术式 HP+2 是即时收益，比较实用；机巧 1/3 概率转化为所需 crest，风险收益适中。如果测试中护持感觉过弱，可考虑改为 DEF+2。
2. **temp_def 存储位置** — 选择直接存在 unit 字典中而非 BuffManager，因为效果简单（单回合清零），不需要 buff 系统的持续时间管理。如果后续 buff 类型增多，应统一迁移到 BuffManager。
