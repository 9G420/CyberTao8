# CyberTao: Dice Beast Protocol 项目迁移快照（中文 v3）

**更新时间**: 2026-03-29
**当前版本**: v0.1.21
**当前分支**: `codex/dice-beast-protocol`
**主工作目录**: `CyberTao_Dice_Beast_Protocol/Project/`

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

## 2. 当前已完成内容（v0.1.0 → v0.1.21）

### 棋盘走位层（外层基础已成型）

- 8x8 棋盘可视化（暗色赛博风格棋盘底色）
- 掷骰 → 6 种 crest 资源池（summon/move/attack/defend/skill/trick）
- BFS 移动（含地形消耗权重）
- 基础近战攻击（含地形适性加成）
- 召唤铺路系统（消耗 SUMMON → 铺路径格 + 生成召唤单位）
- 地形系统：高台格（移动消耗+2，攻击范围+1）、陷阱格（进入扣 1 HP）
- 3 种单位地形适性：高台（鸦机术士 攻击+2）、路径（刀盾狗 DEF+1）、陷阱（灵狐骇客 免疫）
- 道具拾取系统：补丁凉茶（HP+2）、超频骨头（MOVE+1）、故障零食盒（随机 crest+1）
- 敌方 AI 最小回合：优先攻击 → 朝最近玩家移动 → 移动后追击
- 敌方意图广播：行动前中文描述 + 攻击预警闪烁 + 加长停顿
- 攻击反馈（白色闪光 + 红色飘字）
- 道具拾取反馈（绿色飘字）
- 胜负判定 + 重新开始
- 显示设置系统（有 BUG-001）

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
8. 敌方回合（意图广播 + 预警闪烁）
9. 胜利 / 失败
10. 重新开始
11. 设置面板

---

## 4. 架构概述

### BattleV2 模块化架构

```
BattleFlowController（核心控制器）
├── DiceManager        — 掷骰 + crest 资源池
├── BoardManager       — 棋盘状态（格子/路径/地形/道具/占位）
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
├── DiceDebugPanel     — 调试面板（crest 池/阶段/意图）
├── SettingsPanel      — 显示设置
└── DisplaySettings    — 分辨率/窗口模式管理
```

### 信号体系

```
setup_completed / phase_changed / round_changed
move_completed / attack_completed / enemy_attack_completed
summon_completed / terrain_damage_triggered / item_picked_up
enemy_action_announced / enemy_turn_ended
```

---

## 5. 推进优先级（新方向下）

### 第一优先级：棋盘走位层扩展

1. 遭遇格原型入口（踩格触发遭遇信号）
2. 格子类型扩展（敌人格/事件格/恢复格）
3. 走位决策丰富化（路线选择更有意义）

### 第二优先级：双层玩法入口

1. 遭遇触发 → 切入战斗流程设计
2. 最小卡牌战斗原型（简化版抽牌/出牌/结算）
3. 战斗结算 → 回到棋盘层

### 第三优先级：打磨与演出

1. UI 去调试化（面板 → 游戏 HUD）
2. 2.5D 棋盘视觉升级
3. 骰子投掷演出
4. 召唤展开演出

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

---

## 8. 给新 Mulerun 账号的接力说明

新账号接手时请先阅读：

1. `Logs/CyberTao_Migration_Snapshot_zh_v3.md`（本文件 — 项目全貌）
2. `Logs/Weekly_Mulerun_Plan_zh_v2.md`（当前周计划）
3. `Logs/Board_Card_Battle_Concept_zh.md`（双层玩法机制方案）
4. `Logs/Demo_Roadmap_2p5D_zh.md`（中长期 Demo 路线）
5. `Logs/Mulerun_Work_Report.md`（最近一轮工作报告）
6. `Logs/changelog_v0.1.md`（完整版本变更记录）

只在以下目录开发：`CyberTao_Dice_Beast_Protocol/Project/`
不要修改旧项目：`CyberTao8` 根目录仅作参考。

---

## 9. 一句话状态

**v0.1.21 棋盘走位层基础底座已完成（移动/地形/适性/道具/AI 可读），项目正式转向"骰子走位棋盘推进 + 遭遇触发卡牌战斗"双层结构，下一步核心是在棋盘上实现遭遇格入口，为切入卡牌战斗层做准备。**
