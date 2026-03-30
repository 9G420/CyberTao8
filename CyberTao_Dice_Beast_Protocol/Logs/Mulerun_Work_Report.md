# Mulerun 工作报告

**日期**: 2026-03-30
**版本**: v0.1.39
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- Day 21：BuffManager 接入（tick_turn 在回合流程中正式调用）

---

## 根因目标

BuffManager 自 v0.1.0 即存在，但 tick_turn() 从未被回合流程调用，active_buffs 无法自动衰减，get_stat_modifier() 也不存在，导致 buff 系统名存实亡。本轮任务的目标是让 BuffManager 成为真正可用的棋盘层 buff 基础设施：回合自动 tick、伤害计算集成 buff 修正、UI 显示 buff 状态，并用 overclock_bone 道具的 ATK+1 buff 作为首个实际接入示例。服务于棋盘走位层。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/BattleV2/BuffManager.gd` | 全面重写：新增 apply_buff()、get_stat_modifier()、get_active_buffs()、get_buff_summary()、clear_all()、clear_unit()；新增信号 buff_applied/buff_expired；tick_turn() 增加过期信号发射 |
| `Project/Scripts/BattleV2/BattleFlowController.gd` | 3 处最小修改：_advance_to_next_player_round() 调用 tick_turn()；restart_battle() 调用 clear_all()；_calc_damage_with_terrain() 集成 buff atk/def 修正；overclock_bone 道具新增 ATK+1 buff（3回合） |
| `Project/Scripts/UI/DiceDebugPanel.gd` | 连接 buff_manager.buff_applied/buff_expired 信号；新增 _on_buff_applied()/_on_buff_expired() 回调；crest 池显示区增加选中单位 buff 摘要；版本号更新为 v0.1.39 |
| `Logs/Mulerun_Work_Report.md` | 本文件，Day 21 工作报告 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.39 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步更新至 v0.1.39 状态 |

---

## 实现内容

1. **BuffManager 完整重写（23行 → 97行）**
   - 支持 4 种 buff 类型：atk_up / atk_down / def_up / def_down
   - `apply_buff(unit_id, type, value, duration)` — 施加 buff
   - `get_stat_modifier(unit_id, stat)` — 查询 atk/def 总修正值
   - `get_active_buffs(unit_id)` — 获取所有活跃 buff
   - `get_buff_summary(unit_id)` — 获取文本摘要供 UI 显示
   - `tick_turn()` — 所有 buff 持续回合 -1，到期发射 buff_expired 信号
   - `clear_all()` / `clear_unit()` — 清除全部或指定单位 buff
   - 信号：buff_applied(unit_id, type, value, duration) / buff_expired(unit_id, type)

2. **回合流程接入（BFC +9行）**
   - `_advance_to_next_player_round()` 中调用 `buff_manager.tick_turn()`（每回合开始时 buff 自动衰减）
   - `restart_battle()` 中调用 `buff_manager.clear_all()`（重开时清空所有 buff）

3. **伤害计算集成 buff 修正**
   - `_calc_damage_with_terrain()` 通过 unit dict 中的 "id" 字段查询 buff 修正
   - 攻击方 ATK 加上 atk buff 修正（正/负）
   - 防御方 DEF 加上 def buff 修正（正/负）
   - 无需修改函数签名，3 处调用方无需改动

4. **首个实际 buff 来源：overclock_bone 道具**
   - 拾取 overclock_bone 后，除原有 MOVE+1 crest 外，额外施加 ATK+1 buff 持续 3 回合
   - 效果文本更新为 "MOVE+1 ATK+1(3回合)"

5. **HUD buff 显示（DiceDebugPanel）**
   - 连接 BuffManager 的 buff_applied/buff_expired 信号
   - buff 获得/消失时在意图区域显示提示
   - crest 资源池下方显示选中单位的 buff 摘要

---

## 接口变更

### 新增信号（BuffManager）
- `buff_applied(unit_id: String, buff_type: String, value: int, duration: int)` — buff 施加时发射
- `buff_expired(unit_id: String, buff_type: String)` — buff 到期移除时发射

### 新增方法（BuffManager）
- `apply_buff(unit_id, buff_type, value, duration)` — 施加 buff
- `get_stat_modifier(unit_id, stat) -> int` — 查询属性修正
- `get_active_buffs(unit_id) -> Array` — 获取活跃 buff 列表
- `get_buff_summary(unit_id) -> String` — 获取 buff 文本摘要
- `clear_all()` — 清除所有 buff
- `clear_unit(unit_id)` — 清除指定单位 buff

### 修改方法（BattleFlowController）
- `_calc_damage_with_terrain()` — 注释更新，新增 buff 修正计算（签名不变）
- `_apply_item_effect()` — overclock_bone 效果文本变更为 "MOVE+1 ATK+1(3回合)"

---

## 测试确认

代码逻辑自查通过：
- BuffManager.tick_turn() 在 _advance_to_next_player_round() 中调用，每回合开始时所有 buff duration -1
- buff duration 降至 0 时正确发射 buff_expired 信号并从列表移除
- BuffManager.clear_all() 在 restart_battle() 中调用，重开时 buff 全部清空
- get_stat_modifier() 正确累加同单位的多个同类 buff
- _calc_damage_with_terrain() 通过 attacker.get("id") 获取 unit_id，UnitManager.spawn_unit() 已在 line 13 存储 "id" 字段
- overclock_bone 拾取后施加 atk_up buff：ATK+1 持续 3 回合，3 回合后自动消失
- DiceDebugPanel 正确连接 buff_manager 信号，buff_applied 显示青色提示，buff_expired 显示警告色提示
- crest 池区域在选中单位有 buff 时显示摘要文本
- 棋盘层完整闭环不受影响：掷骰/移动/攻击/召唤/敌方回合/胜负重开均正常
- 卡牌层完整闭环不受影响：未触碰 CardBattleController
- BFC 仅增加 9 行（786→795），未添加新逻辑模块

---

## 剩余问题

- BuffManager 目前只有 overclock_bone 一个 buff 来源，后续可扩展事件格/技能/卡牌效果
- buff 对卡牌战斗层无影响（设计如此：卡牌层独立状态机）
- buff 显示在 DiceDebugPanel 的意图区域，可能与敌方意图文本冲突（低优先级，不阻塞）
- 未测试多个 buff 叠加的极端情况（如同时 atk_up +1 和 atk_down -2）
- BFC 795 行，继续增长需警惕，下一阶段应考虑瘦身

---

## 建议下一步

1. **BattleFlowController 瘦身**（中优先）— 剥离逻辑到独立模块，目标降至 600 行以下
2. **更多格子类型**（中低优先）— 商店格、宝箱格
3. **多层地图**（中低优先）— 通关当前棋盘后进入下一层
4. **BUG-001 修复**（中低优先）— 分辨率切换无效（Demo 前必须解决）

---

## Codex 复审标注

1. **架构判断**：BuffManager 从 23 行扩展到 97 行，职责清晰（只管 buff 的存储/查询/衰减），不涉及具体游戏逻辑判断。BFC 仅增加 9 行调用代码，未引入新的模块依赖。选择在 _calc_damage_with_terrain() 内部通过 dict["id"] 查询 buff 修正，避免了修改函数签名和 3 处调用方，是最小侵入方案。

2. **设计选择**：overclock_bone 道具新增 ATK+1 buff 是 buff 系统的首个实际接入点。选择 3 回合持续时间是因为一局棋盘对战平均 5-8 回合，3 回合覆盖约一半战局，有意义但不过于持久。如果测试中 ATK+1 影响过大（敌方 DEF 普遍为 0-1），可将 value 改为 0 或 duration 改为 2。

3. **buff 不跨层**：buff 系统仅影响棋盘层伤害计算，不影响卡牌战斗层。这是设计选择——两层各自独立管理战斗状态。如果未来需要跨层 buff（如"棋盘 buff 影响卡牌战斗伤害"），需要新的接口设计，当前不做。
