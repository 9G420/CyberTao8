# CyberTao: Dice Beast Protocol 项目迁移快照
**生成时间**: 2026-03-29
**当前版本**: v0.1.13（敌方 AI 最小回合已接入）
**当前分支**: `codex/dice-beast-protocol`
**主工作目录**: `CyberTao_Dice_Beast_Protocol/Project/`

---

## 1. 项目概要

`CyberTao: Dice Beast Protocol（骰兽协议）` 是旧项目 `CyberTao8` 的并行重构方向。

它不再延续原本偏《杀戮尖塔》式的纯卡牌回合战斗，而是转向：

- 骰子驱动资源
- 棋盘走位与空间控制
- 怪兽单位对抗
- 卡牌式局外构筑
- buff / 道具拾取
- CN 网络 meme + 赛博 furry 风格

旧项目 `CyberTao8` 仍保留不动，作为参考基线，主要参考：

- 程序化视觉生成方式
- UI 搭建思路
- 项目语气 / 世界观调性
- GameState / 数据结构组织方式

**GitHub 仓库**: `https://github.com/9G420/CyberTao8`  
**主要开发分支**: `codex/dice-beast-protocol`

---

## 2. 已确认的设计方案

### 核心玩法方向

新项目目标是一个“骰子驱动的怪兽棋盘战斗 Roguelike”，融合以下元素：

- 骰子决斗资源系统
- 战棋 / 斗兽棋式单位推进
- 卡牌式 meta progression
- 棋盘 buff / 道具互动
- 赛博道教 + 兽人 + meme 风格角色

### 核心资源（crest）

当前原型使用 6 类 crest 资源：

- `显化 summon`
- `步进 move`
- `杀伐 attack`
- `护持 defend`
- `术式 skill`
- `机巧 trick`

### 核心战斗流程（当前已落地）

当前已经打通的最小战斗闭环：

1. 掷骰
2. 获得 crest 资源
3. 选择我方单位
4. 消耗 `MOVE` 进行移动
5. 消耗 `ATTACK` 进行基础近战攻击
6. 结束回合
7. 触发胜利 / 失败判定

### 当前阵营原型

已存在 3 个原型单位资源：

- 刀盾狗 `blade_shield_dog`
- 灵狐骇客 `hacker_fox`
- 鸦机术士 `crow_caster`

第四个常驻规划原型：

- 虎机斗士（尚未正式接入）

### 架构原则

新模式明确不继续堆在旧项目的 `BattleManager.gd` 上。  
新战斗逻辑统一在 `BattleV2` 架构下拆分：

- `BattleFlowController`
- `DiceManager`
- `BoardManager`
- `UnitManager`
- `ActionResolver`
- `BuffManager`
- `BattleAI`

---

## 3. 当前项目状态

### 已完成内容

当前新项目已经不是“只有脚手架”，而是一个可运行的战斗原型，已完成：

- 独立 Godot 子项目
- 独立 `project.godot`
- 主场景 `Main.tscn`
- 可视化 8x8 棋盘
- 调试面板
- 3 个原型单位资源
- 技能 / 道具 / 骰面 / 核心资源雏形
- 每回合只能掷一次
- End Turn 回合推进
- MOVE 驱动移动
- ATTACK 驱动基础近战攻击
- HP 文本显示
- Victory / Defeat 判定
- 显示设置系统（分辨率 / 窗口模式 / 保存设置）
- 中文主界面 / 中文调试面板 / 中文设置面板
- 敌方 AI 最小回合（ENEMY_ROLL → ENEMY_ACTION → 自动回到 PLAYER_ROLL）
- 敌方会移动、会攻击、有攻击反馈

### 当前可直接测试的内容

在 Godot 中当前可测试：

- 打开新项目
- 运行主场景
- 点击我方单位
- 青色格移动
- 红色格攻击
- 结束回合
- 观察敌方掷骰、移动、攻击
- 再次掷骰
- 杀死目标后进入胜利 / 失败阶段
- 打开设置面板调整分辨率 / 窗口模式

### 当前还不属于“完整 DEMO”

虽然已经能运行”战斗沙盒原型”，但还不等于旧项目那种完整可玩 demo。当前仍缺：

- summon / path-building
- 更明确的移动动画
- 更强的棋盘表现力和骰子演出
- 多敌人编队

---

## 4. 技术实现现状

### 新项目核心目录

#### 项目入口

- `CyberTao_Dice_Beast_Protocol/Project/project.godot`
- `CyberTao_Dice_Beast_Protocol/Project/Scenes/Main.tscn`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/Main.gd`

#### 战斗脚本

- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/BattleFlowController.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/DiceManager.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/BoardManager.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/UnitManager.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/ActionResolver.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/BuffManager.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/BattleAI.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/SkillEffectLibrary.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/ItemEffectLibrary.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/AttackRuleHelper.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/VictoryRuleHelper.gd`

#### 数据脚本

- `CyberTao_Dice_Beast_Protocol/Project/Scripts/Data/UnitData.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/Data/SkillData.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/Data/ItemData.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/Data/CoreData.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/Data/DiceFaceData.gd`

#### UI / 系统脚本

- `CyberTao_Dice_Beast_Protocol/Project/Scripts/UI/BoardView.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/UI/DiceDebugPanel.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/UI/SettingsPanel.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/System/DisplaySettings.gd`

#### 文档

- `CyberTao_Dice_Beast_Protocol/Docs/TECH_REBUILD_BLUEPRINT.md`
- `CyberTao_Dice_Beast_Protocol/Docs/COMBAT_RULES_v0.1.md`
- `CyberTao_Dice_Beast_Protocol/Docs/ATTACK_RULES_v0.1.md`
- `CyberTao_Dice_Beast_Protocol/Docs/HP_VICTORY_RULES_v0.1.md`
- `CyberTao_Dice_Beast_Protocol/Docs/UNIT_KEYWORDS_v0.1.md`
- `CyberTao_Dice_Beast_Protocol/Docs/CONTENT_ROADMAP_v0.1.md`

#### 日志 / 接力文件

- `CyberTao_Dice_Beast_Protocol/Logs/CyberTao_Migration_Snapshot.md`
- `CyberTao_Dice_Beast_Protocol/Logs/CyberTao_Migration_Snapshot_zh.md`
- `CyberTao_Dice_Beast_Protocol/Logs/changelog_v0.1.md`
- `CyberTao_Dice_Beast_Protocol/Logs/Mulerun_Work_Report.md`
- `CyberTao_Dice_Beast_Protocol/Logs/Mulerun_Start_Prompt.md`
- `CyberTao_Dice_Beast_Protocol/Logs/Mulerun_Handoff_Template.md`

---

## 5. 当前阶段的关键结论

1. **旧项目只保留参考，不再继续扩大战斗核心**
   - 所有新模式开发统一在 `CyberTao_Dice_Beast_Protocol/Project/` 下进行。

2. **战斗原型已经成立**
   - 当前不是纯概念或纯脚手架，而是可以运行的交互原型。

3. **Mulerun 负责执行层，Codex 负责架构与审查层**
   - 这是当前最高效也最省额度的协作方式。

4. **中文 UI 已在本地直接修正**
   - `Main.gd`
   - `DiceDebugPanel.gd`
   - `SettingsPanel.gd`
   当前本地应以这 3 个修正后的版本为准。

5. **显示设置系统已经接入**
   - 已支持分辨率
   - 已支持窗口化 / 全屏 / 无边框窗口
   - 已支持设置保存

6. **当前棋盘表现仍是原型级平面战场**
   - 这不是最终视觉方向
   - 后续推荐转向“2.5D / 伪3D 棋盘 + 骰子演出”

---

## 6. 后续工作计划（按优先级）

### 🔴 第一优先级：补齐最小可玩战斗 DEMO

1. ~~**敌方 AI 最小回合**~~ ✅ 已完成 v0.1.13
   - 实现 `ENEMY_ROLL -> ENEMY_ACTION`
   - 敌人会移动 / 攻击
   - 不再只是静态靶子

2. ~~**战斗结束后的重开 / 再来一局**~~ ✅ 已完成 v0.1.12
   - Victory / Defeat 后有"重新开始"按钮
   - 快速回到同一测试战斗

3. ~~**攻击反馈增强**~~ ✅ 已完成 v0.1.12
   - 受击闪烁
   - 飘字
   - tween 动画

### 🟡 第二优先级：真正体现“骰兽协议”的独特玩法

4. **召唤 / 铺路（summon + path-building）**
   - 当前还没真正落地
   - 这是和普通战棋原型拉开差异的关键玩法

5. **道具格 / buff 拾取更明确**
   - 让 `ItemData` 不只存在于资源层
   - 真正进入棋盘流程

6. **更丰富的单位差异**
   - 区分近战 / 远程 / 突进 / 控制
   - 为后续阵营构筑打基础

### 🟢 第三优先级：视觉与沉浸感升级

7. **棋盘从纯平升级为 2.5D / 伪3D**
   - 倾斜视角
   - 格子厚度
   - 发光边缘
   - 悬浮感

8. **骰子投掷演出**
   - 最值得优先强化的沉浸点
   - 可以明显向“游戏王动画骰子决斗”靠拢

9. **单位召唤与路径展开演出**
   - 单位和路径不再是瞬间出现
   - 强化仪式感

---

## 7. 预计开发路线

### 最近阶段目标

做出一个真正的“最小可玩战斗 demo”，标准为：

- 可掷骰
- 可移动
- 可攻击
- 敌方会行动
- 可判定胜负
- 可快速重开

### 中阶段目标

在最小战斗 demo 稳定后，继续加入：

- summon / path-building
- 更丰富单位
- buff / 道具拾取
- 更强视觉反馈

### 长阶段目标

形成区别于旧项目的全新玩法辨识度：

- 赛博道教
- 骰子驱动
- 兽人棋盘战斗
- meme 风格阵营

---

## 8. 当前已知问题与风险

1. **项目仍处于原型阶段**
   - 可运行，但不是正式成品美术

2. **单位目前仍是矩形调试显示**
   - 这只是临时表现层

3. ~~**敌方 AI 尚未接入**~~ ✅ 已在 v0.1.13 接入最小 AI
   - 当前为极简决策（移动 + 攻击），无高级策略

4. **summon / path-building 还未真正实现**
   - 后续必须尽快补上

5. **新旧日志语言不统一**
   - 英文日志保留
   - 中文迁移快照从本文件开始补齐

6. **Godot 自动生成的 `.uid` / `.import` 不应乱提交**
   - 默认视作本地杂项

7. **`Signals/` 目录下的 signal 文件不应提交**
   - 仅用于本地提醒流程

---

## 9. 当前协作规则（非常重要）

### Mulerun 负责

- 明确边界的小功能实现
- UI 拼装
- 调试面板
- 有清晰改动范围的脚本补丁
- 日志更新

### Codex 负责

- 架构方向
- 技术审查
- 高风险修复
- 功能拆解
- 模块收口
- 合并与同步策略

### 固定协作流程

1. 给 Mulerun 下发任务
2. Mulerun 完成并推送
3. 本地 `done_signal` 出现
4. 先 `Pull origin`
5. 再让 Codex 读取本地 signal 与日志做审查

### 本地不应提交的内容

- `CyberTao_Dice_Beast_Protocol/Signals/done_signal.json`
- `CyberTao_Dice_Beast_Protocol/Signals/done_signal.log`
- 非必要 `.uid`
- 非必要 `.import`

---

## 10. 新账号接力启动指令（中文版）

下面这段可以直接作为新 Mulerun 账号的启动提示词基础：

```text
我正在开发一个新的 Godot 4.6.1 项目，工作命名为：

CyberTao: Dice Beast Protocol（骰兽协议）

仓库：
https://github.com/9G420/CyberTao8

当前工作分支：
codex/dice-beast-protocol

主工作目录：
CyberTao_Dice_Beast_Protocol/Project/

重要说明：
这个仓库里现在同时存在两个项目：

1. 旧项目 `CyberTao8`
- 原 STS-like 卡牌 Roguelike
- 仅作参考
- 不要随意修改旧战斗系统

2. 新项目 `CyberTao_Dice_Beast_Protocol/`
- 这是新的并行重构项目
- 当前主要开发工作都在这里进行

请先阅读以下文件：
- `CyberTao_Dice_Beast_Protocol/Logs/CyberTao_Migration_Snapshot_zh.md`
- `CyberTao_Dice_Beast_Protocol/Logs/changelog_v0.1.md`
- `CyberTao_Dice_Beast_Protocol/Logs/Mulerun_Work_Report.md`
- `CyberTao_Dice_Beast_Protocol/Docs/TECH_REBUILD_BLUEPRINT.md`

当前项目定位：
- 骰子驱动资源
- 棋盘怪兽战斗
- 局外构筑
- buff / 道具拾取
- CN meme + 赛博 furry 风格

当前已完成：
- 独立 Godot 子项目
- 棋盘可视化
- MOVE 移动
- ATTACK 基础攻击
- End Turn
- HP 显示
- Victory / Defeat 判定
- 显示设置系统

当前最高优先级：
1. 敌方 AI 最小回合
2. 胜负后的重开按钮
3. 攻击反馈增强

技术注意事项：
- Godot 4.6.1 不要错误使用 `:=`
- Tween 用 `node.create_tween()`
- 不要修改旧项目
- `Signals/` 下文件不要提交
- `.uid` / `.import` 默认不要乱提交
- 每次完成后更新：
  - `Logs/Mulerun_Work_Report.md`
  - `Logs/changelog_v0.1.md`

请先总结你对当前状态的理解，再开始工作。
```

---

## 11. 当前推荐的下一步

**最优先下一步：**

1. 移动动画（Tween 位移替代瞬移）
2. 多敌人编队测试
3. 召唤 / 铺路系统（summon + path-building）

第一优先级三项（敌方 AI、重开按钮、攻击反馈）已全部完成，新项目已进入”最小可玩战斗 demo”阶段。
