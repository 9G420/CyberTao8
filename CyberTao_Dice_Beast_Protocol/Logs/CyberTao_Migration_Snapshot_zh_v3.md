# CyberTao: Dice Beast Protocol 项目迁移快照（中文 v3）

**更新时间**: 2026-03-29
**当前版本**: v0.1.30
**GitHub 仓库**: `https://github.com/9G420/CyberTao8`
**主要开发分支**: `codex/dice-beast-protocol`
**主工作目录**: `CyberTao_Dice_Beast_Protocol/Project/`
**引擎**: Godot 4.6.1 | GDScript | renderer: gl_compatibility
**视口**: 1280x720 | stretch mode: canvas_items

---

## 0. 新接手 AI 必读（快速上手指南）

**你正在接手一个 Godot 赛博朋克战术 Roguelike 项目。** 请按以下顺序阅读文件：

1. **本文件**（`Logs/CyberTao_Migration_Snapshot_zh_v3.md`）— 项目全貌、架构、数据结构、当前状态、下一步
2. **`Logs/Weekly_Mulerun_Plan_zh_v2.md`** — 当前周计划（Day 1~12 已全部完成）
3. **`Logs/Board_Card_Battle_Concept_zh.md`** — 双层玩法机制方案（棋盘走位层 + 卡牌战斗层的设计文档）
4. **`Logs/Mulerun_Work_Report.md`** — 最近一轮工作报告（v0.1.30 阶段收口）
5. **`Logs/changelog_v0.1.md`** — 完整版本变更记录（v0.1.0 ~ v0.1.30）

**关键规则：**
- **只在 `CyberTao_Dice_Beast_Protocol/Project/` 目录下开发**，不要修改旧项目 `CyberTao8` 根目录
- **所有日志必须写中文**
- 每轮任务完成后必须更新 `Mulerun_Work_Report.md` 和 `changelog_v0.1.md`
- 每次任务前确认：服务于棋盘走位层 or 卡牌战斗层，两者都不是则不优先做
- 工作报告必须包含：本轮任务 / 根因目标 / 修改文件 / 实现内容 / 剩余问题 / 建议下一步

**当前阶段状态：双层玩法结构第一版已完成闭环。下一阶段应聚焦于深化战斗策略和视觉演出。**

---

## 1. 项目定位

`CyberTao: Dice Beast Protocol（骰兽协议）` 是旧项目 `CyberTao8` 的并行重构方向。

**正式主玩法方向（v0.1.22 起生效）：**

### "骰子走位棋盘推进 + 遭遇触发卡牌战斗"

双层玩法结构：

1. **外层：棋盘走位层** — 掷骰获得资源 → 在棋盘上移动/走位/踩格 → 路线选择/抢点/占高台/避陷阱/铺路推进 → 触发遭遇
2. **内层：卡牌战斗层** — 遭遇触发后切入 → 抽牌/出牌/能量费用/攻防博弈/构筑成长 → 战斗结算 → 回到棋盘继续

核心理念：
- 棋盘层负责"走到哪里、遇到什么、占什么优势"
- 卡牌层负责"真正打起来时怎么赢"
- 两层互相增益：棋盘走位影响战斗条件，战斗结果影响棋盘推进

风格标签：骰子驱动 / 怪兽对抗 / 召唤铺路 / CN meme / 赛博 furry

---

## 2. 当前已完成内容（v0.1.0 → v0.1.30）

### 棋盘走位层（外层 — 完备）

| 系统 | 版本 | 状态 |
|------|------|------|
| 8x8 棋盘可视化（暗色赛博风格） | v0.1.0 | 稳定 |
| 掷骰 → 6 种 crest 资源池 | v0.1.1 | 稳定 |
| 单位选中 + BFS 移动（含地形权重） | v0.1.1 | 稳定 |
| 基础近战攻击（含地形适性加成） | v0.1.4 | 稳定 |
| HP 显示 + 胜负判定 + 重新开始 | v0.1.6/v0.1.12 | 稳定 |
| 攻击反馈（闪光+飘字） | v0.1.12 | 稳定 |
| 敌方 AI 最小回合（优先攻击/追踪） | v0.1.13 | 稳定 |
| 召唤铺路（SUMMON → 路径格 + 召唤单位） | v0.1.14 | 稳定 |
| 地形系统（高台+陷阱） | v0.1.15 | 稳定 |
| 单位地形适性（3种） | v0.1.19 | 稳定 |
| 道具拾取（2种即时效果） | v0.1.20 | 稳定 |
| 敌方意图广播 + 攻击预警 | v0.1.21 | 稳定 |
| 遭遇格入口 + 暂停流程 | v0.1.22/v0.1.23 | 稳定 |
| 恢复格 + 事件格（7种格子） | v0.1.24 | 稳定 |
| 显示设置系统 | v0.1.7 | 有 BUG-001 |

### 卡牌战斗层（内层 — 最小策略版完成）

| 系统 | 版本 | 状态 |
|------|------|------|
| CardBattleController 独立状态机 | v0.1.26 | 稳定 |
| CardBattlePanel 纯 UI 面板 | v0.1.25/v0.1.26 | 稳定 |
| 5 张固定手牌（斩击/重击/防御/修复/连斩） | v0.1.25 | 被 v0.1.27 升级 |
| 能量系统（每回合 3E，牌消耗 1~3E） | v0.1.27 | 稳定 |
| 双牌堆系统（10 张牌组，抽 3/回合，reshuffle） | v0.1.27 | 稳定 |
| 3 种敌方行为模式 + 循环 pattern | v0.1.27 | 稳定 |
| 敌方意图预告 | v0.1.27 | 稳定 |
| 防御减伤机制 | v0.1.27 | 稳定 |
| 胜利奖励（+1 随机 crest） | v0.1.27 | 稳定 |
| 逃跑机制（-1 HP） | v0.1.25 | 稳定 |
| HP 同步（卡牌层 → 棋盘层） | v0.1.25 | 稳定 |
| 调试快捷按钮（一键进入战斗） | v0.1.28 | 稳定 |

### 视觉系统

| 系统 | 版本 | 状态 |
|------|------|------|
| CyberStyle 统一风格系统 | v0.1.29 | 稳定 |
| 面板赛博朋克化（暗底+霓虹边框） | v0.1.29 | 稳定 |
| 按钮四态样式（normal/hover/pressed/disabled） | v0.1.29 | 稳定 |
| Crest 彩色显示（青/橙/品红） | v0.1.29 | 稳定 |

### 双层闭环完整流程

```
棋盘走位层                              卡牌战斗层
掷骰 → 获得 crest
选中单位 → 移动/攻击/召唤
踩遭遇格 → ENCOUNTER 暂停 ──────────→ CardBattleController.start_battle()
                                        ↓
                                      抽牌 3 张 → 显示意图
                                        ↓
                                      玩家出牌（消耗能量）→ 效果结算
                                        ↓
                                      结束回合 → 弃手牌 → 敌方行动
                                        ↓
                                      循环至一方 HP ≤ 0
                                        ↓
PLAYER_ACTION 恢复 ←─────────────────── battle_ended 信号
棋盘单位 HP 同步 ←──────────────────── resolve_encounter(victory, hp)
crest 奖励写入 ←────────────────────── victory_reward 信号
遭遇格消失 → 棋盘继续
```

### 3 个玩家原型单位

| 单位 | 定位 | HP | ATK | DEF | 移动 | 攻击范围 | 适性 |
|------|------|-----|-----|-----|------|----------|------|
| 刀盾狗 | 前排坦克 | 8 | 3 | 1 | 1 | 1 | 路径（DEF+1） |
| 灵狐骇客 | 控制型 | 6 | 2 | 0 | 2 | 2 | 陷阱（免疫） |
| 鸦机术士 | 远程控场 | 5 | 2 | 0 | 1 | 3 | 高台（范围+2） |

### 2 个棋盘敌方单位

| 单位 | HP | ATK | DEF | 位置 |
|------|-----|-----|-----|------|
| 哨兵甲 | 5 | 2 | 0 | (3,4) |
| 哨兵乙 | 4 | 3 | 0 | (5,3) |

### 2 个遭遇敌方

| 遭遇 ID | 名称 | HP | ATK | 行为模式 |
|----------|------|-----|-----|----------|
| encounter_01 | 异常哨兵 | 8 | 2 | attack→attack→defend_attack→heavy_attack |
| encounter_02 | 赛博游魂 | 6 | 3 | attack→heavy_attack→attack |

### 10 张卡牌牌组

| 牌名 | 费用 | 效果 | 数量 |
|------|------|------|------|
| 斩击 | 1E | 3 伤害 | x2 |
| 重击 | 2E | 5 伤害 | x1 |
| 防御 | 1E | 减伤 2 | x2 |
| 修复 | 1E | 回复 2 HP | x1 |
| 连斩 | 1E | 2 伤害 | x2 |
| 猛攻 | 3E | 8 伤害 | x1 |
| 急救 | 2E | 回复 4 HP | x1 |

### 调试棋盘布局

| 格子 | 位置 | 类型 |
|------|------|------|
| 高台格 | (2,4) (2,5) | terrain: high_ground |
| 陷阱格 | (1,5) (3,6) | terrain: trap |
| 道具格 | (4,5) 补丁凉茶, (2,6) 超频骨头 | item |
| 遭遇格 | (4,4) encounter_01, (6,5) encounter_02 | encounter |
| 恢复格 | (5,6) HP+2, (1,3) HP+3 | heal |
| 事件格 | (3,5) (6,3) (4,6) | event（随机正/负） |

---

## 3. 架构概述

### BattleV2 模块化架构

```
BattleFlowController（棋盘层核心控制器）
├── DiceManager        — 掷骰 + crest 资源池
├── BoardManager       — 棋盘状态（7 种格子字典）
├── UnitManager        — 单位状态（生成/移动/伤害/击杀）
├── ActionResolver     — 攻击范围计算（含地形加成）
├── BuffManager        — buff 管理（tick_turn 未接入）
├── BattleAI           — 敌方决策（简单优先攻击/追踪）
├── AttackRuleHelper   — 伤害公式
├── VictoryRuleHelper  — 胜负判定
└── ItemEffectLibrary  — 道具效果执行

CardBattleController（卡牌层独立控制器）
├── 能量系统           — 每回合 3E
├── 双牌堆             — draw pile + discard pile + reshuffle
├── 敌方行为循环       — 3 种行为 × 2 种 pattern
└── 意图预告           — 每回合显示下一步行动
```

### UI 层

```
Main.gd（场景组合+信号接线+反馈调度）
├── BoardView          — 棋盘渲染 + 点击交互 + 反馈动画
├── DiceDebugPanel     — 棋盘层 HUD（crest 池/阶段/意图/遭遇）
├── CardBattlePanel    — 卡牌战斗 UI（手牌/能量/HP/意图/日志）
├── SettingsPanel      — 显示设置
├── DisplaySettings    — 分辨率/窗口模式管理
└── CyberStyle         — 统一赛博朋克视觉风格（class_name 全局可用）
```

### 信号体系

```
棋盘层信号（BattleFlowController）：
  setup_completed / phase_changed / round_changed
  move_completed / attack_completed / enemy_attack_completed
  summon_completed / terrain_damage_triggered / item_picked_up
  enemy_action_announced / enemy_turn_ended
  encounter_triggered / encounter_resolved
  heal_cell_triggered / event_cell_triggered

卡牌层信号（CardBattleController）：
  battle_started / hand_changed / card_played
  enemy_acted / enemy_intent_changed / turn_resolved
  battle_ended / victory_reward

调试信号（DiceDebugPanel）：
  test_card_battle_requested
```

### 关键数据结构

```
BoardManager:
  occupied_cells: Dictionary  # cell -> unit_id
  path_cells: Dictionary      # cell -> owner_id
  item_cells: Dictionary      # cell -> item_id
  terrain_cells: Dictionary   # cell -> "high_ground" / "trap"
  encounter_cells: Dictionary # cell -> encounter_id
  heal_cells: Dictionary      # cell -> int (heal_amount)
  event_cells: Dictionary     # cell -> String (event_id)

UnitManager:
  units_by_id: Dictionary     # unit_id -> {hp, max_hp, atk, def, move_range, attack_range, owner, cell, terrain_affinity, display_name}
  units_by_cell: Dictionary   # cell -> unit_id

DiceManager:
  crest_pool: Dictionary      # "summon"/"move"/"attack"/"defend"/"skill"/"trick" -> int

CardBattleController:
  _draw_pile: Array           # 抽牌堆
  _discard_pile: Array        # 弃牌堆
  _hand: Array                # 当前手牌（每张 = {name, type, value, cost}）
  energy / max_energy: int    # 当前能量 / 每回合能量上限
  _enemy_pattern: Array       # 敌方行为循环序列
```

### 战斗阶段流程

```
棋盘层:
  BattlePhase: BOOT → PLAYER_ROLL → PLAYER_ACTION → [ENCOUNTER] → ENEMY_ROLL → ENEMY_ACTION → (loop)
  终态: VICTORY / DEFEAT
  遭遇分支: PLAYER_ACTION → ENCOUNTER → [卡牌战斗] → resolve_encounter → PLAYER_ACTION

卡牌层:
  BattleState: IDLE → PLAYER_TURN → ENEMY_TURN → (loop) → VICTORY / DEFEAT
```

### 关键代码路径

- **移动后检查顺序**：`try_move_unit()` → `_check_terrain_trap()` → `_check_item_pickup()` → `_check_heal_cell()` → `_check_event_cell()` → `_check_encounter()`
- **点击优先级**：attack > move > summon
- **伤害公式**：`max(1, attacker.atk - defender.def - terrain_bonus)`
- **保底机制**：每次掷骰保底 1 MOVE crest
- **遭遇触发链**：`encounter_triggered` → Main.gd → `CardBattleController.start_battle()` → `battle_ended` → Main.gd → `resolve_encounter()`

---

## 4. 已知问题与技术债

### BUG-001：分辨率/窗口模式切换无效
- **发现版本**: v0.1.20
- **现象**: 窗口仍为 1280x720；内容偏左不居中；全屏无效
- **优先级**: 低（不阻塞玩法推进）
- **相关文件**: `Project/Scripts/System/DisplaySettings.gd`

### 技术债

| 问题 | 优先级 | 说明 |
|------|--------|------|
| BattleFlowController 740+ 行 | 中 | debug spawn 函数应剥离到 DebugScenario.gd |
| BuffManager.tick_turn() 未接入 | 中 | buff 系统骨架存在但未在回合流程中调用 |
| 调试按钮进入卡牌战斗不暂停棋盘 | 低 | 仅影响调试场景，正式遭遇不受影响 |
| OptionButton 未风格化 | 低 | SettingsPanel 下拉框仍为 Godot 默认样式 |
| 卡牌无升级/稀有度 | 后续 | 可参考旧项目 CardData.gd 的 rarity/fusion 系统 |
| 无能量增长机制 | 后续 | 旧项目每回合 +1 能量（max 6），可在后续引入 |

---

## 5. 下一阶段推进建议

### 第二阶段核心方向：深化策略 + 视觉演出

Day 1~12 完成了双层玩法的最小闭环。下一阶段应从以下方向推进：

### A. 卡牌战斗深化（最高优先）

1. **牌组构筑** — 战斗胜利后选牌加入牌组（参考 STS 模式）
2. **卡牌升级** — 基础牌可升级为强化版本
3. **能量成长** — 随关卡进度每回合能量上限 +1
4. **更多敌方种类** — 3~5 种敌方，各有独特行为模式
5. **Boss 遭遇** — 特殊遭遇格触发 Boss 战

### B. 棋盘走位深化

1. **多层地图** — 通关当前棋盘后进入下一层
2. **随机棋盘生成** — 从固定布局升级为程序化生成
3. **更多格子类型** — 商店格、传送格、宝箱格
4. **棋盘事件系统** — 更丰富的随机事件池

### C. 视觉与体验

1. **2.5D 棋盘** — 从纯 2D 方块升级为 2.5D 等距视角
2. **单位动画** — 移动/攻击/受伤动画
3. **卡牌动画** — 抽牌/出牌/弃牌动效
4. **音效系统** — 基础音效接入

### D. 系统完善

1. **BuffManager 接入** — tick_turn 在回合流程中调用
2. **BFC 瘦身** — 剥离 debug spawn 到 DebugScenario.gd
3. **存档系统** — 最小存档/读档

---

## 6. 核心文件索引

### 源代码文件（`Project/Scripts/` 下）

| 文件路径 | 职责 | 行数参考 |
|----------|------|----------|
| `BattleV2/BattleFlowController.gd` | 棋盘层核心控制器：阶段管理/信号中枢/移动攻击召唤/遭遇检测/敌方回合 | ~740 行 |
| `BattleV2/CardBattleController.gd` | 卡牌层独立控制器：能量/双牌堆/敌方行为/意图/奖励 | ~210 行 |
| `BattleV2/BoardManager.gd` | 棋盘状态：7 个格子字典 + BFS 移动 | ~150 行 |
| `BattleV2/UnitManager.gd` | 单位状态：生成/移动/伤害/击杀 | ~90 行 |
| `BattleV2/ActionResolver.gd` | 攻击范围计算（含地形适性加成） | ~50 行 |
| `BattleV2/DiceManager.gd` | 掷骰 + crest 资源池管理 | ~60 行 |
| `BattleV2/BattleAI.gd` | 敌方 AI（优先攻击/追踪最近玩家） | ~80 行 |
| `BattleV2/BuffManager.gd` | buff 管理（tick_turn 未接入） | ~30 行 |
| `BattleV2/AttackRuleHelper.gd` | 伤害公式 | ~15 行 |
| `BattleV2/VictoryRuleHelper.gd` | 胜负判定 | ~20 行 |
| `BattleV2/ItemEffectLibrary.gd` | 道具效果执行 | ~40 行 |
| `UI/BoardView.gd` | 棋盘渲染 + 点击交互 + 反馈动画 | ~470 行 |
| `UI/DiceDebugPanel.gd` | 棋盘层 HUD（crest 池/阶段/意图/遭遇） | ~260 行 |
| `UI/CardBattlePanel.gd` | 卡牌战斗 UI（手牌/能量/HP/意图） | ~230 行 |
| `UI/CyberStyle.gd` | 统一赛博朋克视觉风格（全局 class_name） | ~120 行 |
| `UI/SettingsPanel.gd` | 显示设置面板 | ~100 行 |
| `System/DisplaySettings.gd` | 分辨率/窗口模式（有 BUG-001） | ~60 行 |
| `Main.gd` | 场景组合 + 信号接线 + 反馈调度 | ~270 行 |
| `Data/UnitData.gd` | 单位数据资源脚本 | ~20 行 |

### 日志文件（`Logs/` 下）

| 文件 | 用途 |
|------|------|
| `CyberTao_Migration_Snapshot_zh_v3.md` | 本文件 — 项目全貌+架构（阶段性更新） |
| `Weekly_Mulerun_Plan_zh_v2.md` | 周推进计划（Day 1~12 全部完成） |
| `Board_Card_Battle_Concept_zh.md` | 双层玩法机制方案 |
| `Demo_Roadmap_2p5D_zh.md` | 中长期 Demo 路线 |
| `Mulerun_Work_Report.md` | 最近一轮工作报告（每轮更新） |
| `changelog_v0.1.md` | 完整版本变更记录（v0.1.0 ~ v0.1.30） |

---

## 7. 版本里程碑总览

| 版本 | 里程碑 |
|------|--------|
| v0.1.0~v0.1.3 | 基础骨架（棋盘+掷骰+移动+回合） |
| v0.1.4~v0.1.6 | 战斗基础（攻击+HP+胜负） |
| v0.1.7~v0.1.12 | 体验增强（设置+反馈+重开） |
| v0.1.13~v0.1.14 | AI+召唤（敌方回合+铺路） |
| v0.1.15~v0.1.21 | 棋盘深化（地形+适性+道具+意图） |
| v0.1.22~v0.1.24 | 双层入口（遭遇格+暂停+格子事件化） |
| v0.1.25~v0.1.27 | 卡牌战斗（原型→丰富化） |
| v0.1.28~v0.1.29 | 调试+UI（快捷按钮+赛博朋克风格化） |
| v0.1.30 | 阶段收口（日志整理+下阶段建议） |

---

## 8. 一句话状态

**v0.1.30 双层玩法第一版完整闭环。棋盘走位层（7 种格子 + 3 单位适性 + 敌方 AI + 遭遇触发）和卡牌战斗层（能量 + 双牌堆 + 3 种敌方行为 + 意图预告 + 奖励回馈）已全部完成并通过赛博朋克统一风格化。下一阶段核心方向：卡牌构筑成长 + 更多敌方种类 + 棋盘随机生成。**
