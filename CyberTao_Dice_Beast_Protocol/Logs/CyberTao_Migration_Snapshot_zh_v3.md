# CyberTao: Dice Beast Protocol 项目迁移快照（中文 v3）

**更新时间**: 2026-03-29
**当前版本**: v0.1.22
**GitHub 仓库**: `https://github.com/9G420/CyberTao8`
**主要开发分支**: `codex/dice-beast-protocol`
**主工作目录**: `CyberTao_Dice_Beast_Protocol/Project/`
**引擎**: Godot 4.6.1 | GDScript | renderer: gl_compatibility
**视口**: 1280x720 | stretch mode: canvas_items

---

## 0. 新接手 AI 必读（快速上手指南）

**你正在接手一个 Godot 赛博朋克战术 Roguelike 项目。** 请按以下顺序阅读文件：

1. **本文件**（`Logs/CyberTao_Migration_Snapshot_zh_v3.md`）— 项目全貌、架构、数据结构、当前状态、下一步
2. **`Logs/Weekly_Mulerun_Plan_zh_v2.md`** — 当前周计划（Day 1~6 已完成，从 Day 7 开始执行）
3. **`Logs/Board_Card_Battle_Concept_zh.md`** — 双层玩法机制方案（棋盘走位层 + 卡牌战斗层的设计文档）
4. **`Logs/Demo_Roadmap_2p5D_zh.md`** — 中长期 Demo 路线（六阶段开发规划）
5. **`Logs/Mulerun_Work_Report.md`** — 最近一轮工作报告（v0.1.22 遭遇格入口）
6. **`Logs/changelog_v0.1.md`** — 完整版本变更记录（v0.1.0 ~ v0.1.22）

**关键规则：**
- **只在 `CyberTao_Dice_Beast_Protocol/Project/` 目录下开发**，不要修改旧项目 `CyberTao8` 根目录
- **所有日志必须写中文**
- 每轮任务完成后必须更新 `Mulerun_Work_Report.md` 和 `changelog_v0.1.md`
- 每次任务前确认：服务于棋盘走位层 or 卡牌战斗层入口，两者都不是则不优先做
- 工作报告必须包含：本轮任务 / 根因目标 / 修改文件 / 实现内容 / 剩余问题 / 建议下一步

**当前最优先任务：执行 Day 7 — 遭遇暂停与战斗占位流程**（详见第 5 节）

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

## 2. 当前已完成内容（v0.1.0 → v0.1.22）

### 棋盘走位层（外层基础已成型 + 遭遇入口已接入）

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
| **遭遇格原型入口** | **v0.1.22** | **稳定** |
| 显示设置系统 | v0.1.7 | 有 BUG-001 |

### v0.1.22 新增：遭遇格原型入口

- `BoardManager.encounter_cells` 字典（cell → encounter_id）
- `add_encounter_cell()` / `clear_encounter_cell()` 方法
- 调试布局 2 个遭遇格：(4,4) encounter_01、(6,5) encounter_02
- 玩家单位踩遭遇格时触发 `encounter_triggered(unit_id, encounter_id, cell)` 信号
- 橙红色警告渲染 + "遭遇" 文字标记
- 面板占位提示 "遭遇！准备进入战斗..."
- 橙红色飘字反馈
- **当前限制**：踩后只发信号+提示，不暂停棋盘、不清除遭遇格、不切场景

### 3 个玩家原型单位

| 单位 | 定位 | HP | ATK | DEF | 移动 | 攻击范围 | 适性 |
|------|------|-----|-----|-----|------|----------|------|
| 刀盾狗 | 前排坦克 | 8 | 3 | 1 | 1 | 1 | 路径（DEF+1） |
| 灵狐骇客 | 控制型 | 6 | 2 | 0 | 2 | 2 | 陷阱（免疫） |
| 鸦机术士 | 远程控场 | 5 | 2 | 0 | 1 | 3 | 高台（范围+2） |

### 2 个敌方单位

| 单位 | HP | ATK | DEF | 位置 |
|------|-----|-----|-----|------|
| 哨兵甲 | 5 | 2 | 0 | (3,4) |
| 哨兵乙 | 4 | 3 | 0 | (5,3) |

### 调试棋盘布局总览

| 格子 | 位置 | 类型 |
|------|------|------|
| 高台格 | (2,4) (2,5) | terrain: high_ground |
| 陷阱格 | (1,5) (3,6) | terrain: trap |
| 道具格 | (4,5) 补丁凉茶, (2,6) 超频骨头 | item |
| 遭遇格 | (4,4) encounter_01, (6,5) encounter_02 | encounter |
| 玩家单位 | (0,6) 刀盾狗, (1,7) 灵狐骇客, (0,5) 鸦机术士 | unit: player |
| 敌方单位 | (3,4) 哨兵甲, (5,3) 哨兵乙 | unit: enemy |

### 3 个道具数据

| 道具 | 效果 | .tres 文件 | 棋盘放置 |
|------|------|-----------|----------|
| 补丁凉茶 | HP+2 | patch_tea_cache.tres | (4,5) |
| 超频骨头 | MOVE+1 | overclock_bone.tres | (2,6) |
| 故障零食盒 | 随机 crest+1 | glitch_snack_box.tres | 未放置 |

### 卡牌战斗层（内层未开始）

- 完全未实现
- 无卡牌数据、无抽牌/出牌、无能量系统
- 旧项目 `CyberTao8` 中有部分卡牌积累可参考

---

## 3. 当前可直接测试的内容

1. 掷骰
2. 选择单位（金色选中框）
3. 青色格移动（BFS + 地形权重）
4. 红色格攻击（含地形适性）
5. 紫色格召唤铺路
6. 绿色格道具自动拾取
7. 金色高台格 / 暗红陷阱格
8. **橙红遭遇格（踩上触发信号+占位提示）** ← v0.1.22 新增
9. 敌方回合（意图广播 + 预警闪烁）
10. 胜利 / 失败
11. 重新开始
12. 设置面板

---

## 4. 架构概述

### BattleV2 模块化架构

```
BattleFlowController（核心控制器）
├── DiceManager        — 掷骰 + crest 资源池
├── BoardManager       — 棋盘状态（格子/路径/地形/道具/遭遇/占位）
├── UnitManager        — 单位状态（生成/移动/伤害/击杀）
├── ActionResolver     — 攻击范围计算（含地形加成）
├── BuffManager        — buff 管理（tick_turn 未接入）
├── BattleAI           — 敌方决策（简单优先攻击/追踪）
├── AttackRuleHelper   — 伤害公式
├── VictoryRuleHelper  — 胜负判定
└── ItemEffectLibrary  — 道具效果执行
```

### UI 层

```
Main.gd（场景组合+信号接线）
├── BoardView          — 棋盘渲染 + 点击交互
├── DiceDebugPanel     — 调试面板（crest 池/阶段/意图/遭遇）
├── SettingsPanel      — 显示设置
└── DisplaySettings    — 分辨率/窗口模式管理
```

### 信号体系

```
setup_completed / phase_changed / round_changed
move_completed / attack_completed / enemy_attack_completed
summon_completed / terrain_damage_triggered / item_picked_up
enemy_action_announced / enemy_turn_ended
encounter_triggered                           ← v0.1.22 新增
```

### 关键数据结构

```
BoardManager:
  occupied_cells: Dictionary  # cell -> unit_id
  path_cells: Dictionary      # cell -> owner_id
  item_cells: Dictionary      # cell -> item_id
  terrain_cells: Dictionary   # cell -> "high_ground" / "trap"
  encounter_cells: Dictionary # cell -> encounter_id  ← v0.1.22 新增

UnitManager:
  units_by_id: Dictionary     # unit_id -> {hp, max_hp, atk, def, move_range, attack_range, owner, cell, terrain_affinity, display_name, ...}
  units_by_cell: Dictionary   # cell -> unit_id

DiceManager:
  crest_pool: Dictionary      # "summon"/"move"/"attack"/"defend"/"skill"/"trick" -> int
```

### 战斗阶段流程

```
BattlePhase: BOOT → PLAYER_ROLL → PLAYER_ACTION → ENEMY_ROLL → ENEMY_ACTION → (loop)
终态: VICTORY / DEFEAT
```

### 关键代码路径

- **移动后检查顺序**：`try_move_unit()` → `_check_terrain_trap()` → `_check_item_pickup()` → `_check_encounter()`
- **点击优先级**：attack > move > summon
- **伤害公式**：`max(1, attacker.atk - defender.def - terrain_bonus)`
- **保底机制**：每次掷骰保底 1 MOVE crest

---

## 5. 推进优先级（当前状态下）

### 最高优先级：遭遇暂停流程（Day 7）

遭遇格入口已就绪（v0.1.22），下一步核心是让"踩格 → 暂停 → 占位面板 → 返回"的完整流程闭环。

需要实现：
1. 新增 `BattlePhase.ENCOUNTER` 暂停状态
2. 触发遭遇后棋盘进入暂停（禁止操作）
3. 显示战斗占位面板（"战斗开始 — [encounter_id]"）
4. 面板上"战斗胜利（占位）"按钮，点击后清除遭遇格、回到 PLAYER_ACTION
5. 为后续接入真实卡牌战斗预留流程口

### 第二优先级：棋盘格子事件化（Day 8）

- 恢复格（踩上回复 HP）
- 事件格（随机 buff/debuff）
- 走位路线更有策略意义

### 第三优先级：最小卡牌战斗原型（Day 9）

- 替换 Day 7 的占位面板，接入简化版抽牌/出牌/结算
- 战斗结果影响棋盘

### 后续（Day 10~12）

- 卡牌丰富化（能量/抽牌/多种敌人）
- UI 去调试化
- 阶段收口

---

## 6. 未处理 BUG

### BUG-001：分辨率/窗口模式切换无效
- **发现版本**: v0.1.20
- **现象**: 窗口仍为 1280x720；内容偏左不居中；全屏无效
- **优先级**: 低（不阻塞双层玩法推进）
- **相关文件**: `Project/Scripts/System/DisplaySettings.gd`

---

## 7. 日志与协作规则

1. 所有日志默认写中文
2. 每轮开发后必须更新：
   - `Logs/Mulerun_Work_Report.md`
   - `Logs/changelog_v0.1.md`
3. 阶段方向有明显变化时更新：
   - `Logs/CyberTao_Migration_Snapshot_zh_v3.md`
4. 不要只在聊天里说完成，必须写入日志
5. 工作报告必须包含：本轮任务 / 根因目标 / 修改文件 / 实现内容 / 剩余问题 / 建议下一步
6. 每次任务前确认：服务于棋盘走位层 or 卡牌战斗层入口，两者都不是则不优先做

---

## 8. 核心文件索引

### 源代码文件（`Project/Scripts/` 下）

| 文件路径 | 职责 | 行数参考 |
|----------|------|----------|
| `BattleV2/BattleFlowController.gd` | 核心战斗控制器：阶段管理/信号中枢/移动攻击召唤/遭遇检测/敌方回合 | ~630 行 |
| `BattleV2/BoardManager.gd` | 棋盘状态：5 个字典（occupied/path/item/terrain/encounter）+ BFS 移动 | ~130 行 |
| `BattleV2/UnitManager.gd` | 单位状态：生成/移动/伤害/击杀 | ~100 行 |
| `BattleV2/ActionResolver.gd` | 攻击范围计算（含地形适性加成） | ~50 行 |
| `BattleV2/DiceManager.gd` | 掷骰 + crest 资源池管理 | ~60 行 |
| `BattleV2/BattleAI.gd` | 敌方 AI（优先攻击/追踪最近玩家） | ~80 行 |
| `BattleV2/BuffManager.gd` | buff 管理（tick_turn 未接入） | ~30 行 |
| `BattleV2/AttackRuleHelper.gd` | 伤害公式 | ~15 行 |
| `BattleV2/VictoryRuleHelper.gd` | 胜负判定 | ~20 行 |
| `BattleV2/ItemEffectLibrary.gd` | 道具效果执行 | ~40 行 |
| `UI/BoardView.gd` | 棋盘渲染 + 点击交互 + 反馈动画 | ~470 行 |
| `UI/DiceDebugPanel.gd` | 调试面板（crest 池/阶段/意图/遭遇提示） | ~260 行 |
| `UI/SettingsPanel.gd` | 显示设置面板 | ~100 行 |
| `System/DisplaySettings.gd` | 分辨率/窗口模式（有 BUG-001） | ~60 行 |
| `Main.gd` | 场景组合 + 信号接线 + 反馈调度 | ~205 行 |
| `Data/UnitData.gd` | 单位数据资源脚本 | ~20 行 |

### 数据文件（`Project/Data/` 下）

| 文件 | 内容 |
|------|------|
| `Data/Units/blade_shield_dog.tres` | 刀盾狗（路径适性） |
| `Data/Units/hacker_fox.tres` | 灵狐骇客（陷阱适性） |
| `Data/Units/crow_caster.tres` | 鸦机术士（高台适性） |
| `Data/Items/patch_tea_cache.tres` | 补丁凉茶（HP+2） |
| `Data/Items/overclock_bone.tres` | 超频骨头（MOVE+1） |
| `Data/Items/glitch_snack_box.tres` | 故障零食盒（随机 crest+1，未放置） |

### 日志文件（`Logs/` 下）

| 文件 | 用途 |
|------|------|
| `CyberTao_Migration_Snapshot_zh_v3.md` | 本文件 — 项目全貌+架构（阶段性更新） |
| `Weekly_Mulerun_Plan_zh_v2.md` | 周推进计划（任务列表+优先级） |
| `Board_Card_Battle_Concept_zh.md` | 双层玩法机制方案 |
| `Demo_Roadmap_2p5D_zh.md` | 中长期 Demo 路线 |
| `Mulerun_Work_Report.md` | 最近一轮工作报告（每轮更新） |
| `changelog_v0.1.md` | 完整版本变更记录（每轮追加） |

---

## 9. 一句话状态

**v0.1.22 遭遇格原型入口已完成（棋盘上可见遭遇格、踩上触发信号+占位提示），双层结构的入口信号层已就绪。下一步核心是 Day 7 实现遭遇暂停流程（踩格→暂停→占位面板→返回），让"进入-退出"闭环成立，为 Day 9 接入最小卡牌战斗做准备。**
