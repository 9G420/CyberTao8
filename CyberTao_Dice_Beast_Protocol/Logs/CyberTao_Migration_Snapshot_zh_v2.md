# CyberTao: Dice Beast Protocol 项目迁移快照（中文 v2）

**生成时间**: 2026-03-29  
**当前版本**: v0.1.14  
**当前分支**: `codex/dice-beast-protocol`  
**主工作目录**: `CyberTao_Dice_Beast_Protocol/Project/`

---

## 1. 项目定位

`CyberTao: Dice Beast Protocol（骰兽协议）` 是旧项目 `CyberTao8` 的并行重构方向。

新项目不再继续沿用原来偏《杀戮尖塔》式的纯卡牌战斗，而是转向：

- 骰子驱动资源
- 棋盘走位与空间控制
- 怪兽单位对抗
- 卡牌式局外构筑
- buff / 道具拾取
- CN 网络 meme + 赛博 furry 风格

旧项目 `CyberTao8` 继续保留，只作参考基线，不再作为新模式主开发位置。

---

## 2. 当前已完成内容

当前新项目已经从“脚手架阶段”推进到“最小可玩战斗 demo 原型”阶段，已完成：

- 独立 Godot 子项目
- 8x8 可视化棋盘
- 调试面板
- 3 个原型单位资源：
  - 刀盾狗 `blade_shield_dog`
  - 灵狐骇客 `hacker_fox`
  - 鸦机术士 `crow_caster`
- 掷骰与 crest 资源池
- 每回合只能掷一次
- MOVE 移动
- ATTACK 基础近战攻击
- HP 显示
- 胜利 / 失败判定
- 显示设置系统：
  - 分辨率
  - 窗口化
  - 全屏
  - 无边框窗口
  - 保存设置
- 中文主界面 / 中文调试面板 / 中文设置面板
- 敌方 AI 最小回合：
  - `ENEMY_ROLL`
  - `ENEMY_ACTION`
  - 敌人会移动、会攻击
- 攻击反馈：
  - 白色受击闪光
  - 红色伤害飘字
- 胜负后 `重新开始` 按钮
- 召唤 + 铺路原型（summon + path-building v1）：
  - 消耗 SUMMON crest 在相邻格召唤单位
  - 自动生成 2 格路径（青色发光）
  - 紫色高亮标示可召唤位置

---

## 3. 当前可直接测试的内容

在 Godot 中当前可以直接测试：

1. 打开新项目：
   - `CyberTao_Dice_Beast_Protocol/Project/project.godot`
2. 运行主场景
3. 测试以下流程：
   - 掷骰
   - 选中我方单位
   - 青色格移动
   - 红色格攻击
   - 紫色格召唤铺路
   - 敌方回合移动 / 攻击
   - 胜利 / 失败
   - 点击 `重新开始`
   - 打开设置面板切换分辨率和窗口模式

---

## 4. 当前核心脚本结构

### 入口

- `CyberTao_Dice_Beast_Protocol/Project/project.godot`
- `CyberTao_Dice_Beast_Protocol/Project/Scenes/Main.tscn`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/Main.gd`

### 战斗层

- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/BattleFlowController.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/DiceManager.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/BoardManager.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/UnitManager.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/ActionResolver.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/BattleAI.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/AttackRuleHelper.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/VictoryRuleHelper.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/SkillEffectLibrary.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/ItemEffectLibrary.gd`

### 数据层

- `CyberTao_Dice_Beast_Protocol/Project/Scripts/Data/UnitData.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/Data/SkillData.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/Data/ItemData.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/Data/CoreData.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/Data/DiceFaceData.gd`

### UI / 系统层

- `CyberTao_Dice_Beast_Protocol/Project/Scripts/UI/BoardView.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/UI/DiceDebugPanel.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/UI/SettingsPanel.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/System/DisplaySettings.gd`

---

## 5. 当前结论

1. 新项目已经不是概念图或空壳，而是能运行、能测试、能打起来的原型。
2. 当前最小战斗闭环已经成立：
   - 掷骰
   - 移动
   - 攻击
   - 敌方行动
   - 胜负判定
   - 重开
3. 现在最需要的是继续把原型做顺，而不是急着做大重构。
4. 旧项目 `CyberTao8` 只作参考，不要继续往旧战斗系统上堆新模式逻辑。

---

## 6. 近期优先级

### 第一优先级：把当前 demo 做顺

- 优化敌方 AI 行为与可读性
- 继续增强攻击/受击反馈
- 修复测试中发现的交互问题
- 保持设置系统稳定

### 第二优先级：继续扩展”骰兽协议”独特玩法

- 路径格影响移动规则（限制 / 加成）
- 多种路径形状模板
- 召唤来源接入 UnitData 资源
- 棋盘 buff / 道具格接入

### 第三优先级：战斗表现升级

- 棋盘 2.5D / 伪 3D 表现
- 骰子投掷演出
- 单位召唤演出

---

## 7. 日志与协作规则

以后默认规则如下：

1. 新项目日志优先写中文。
2. 每次开发推进后必须更新：
   - `Logs/Mulerun_Work_Report.md`
   - `Logs/changelog_v0.1.md`
3. 如果阶段目标或项目状态明显变化，再更新：
   - `Logs/CyberTao_Migration_Snapshot.md`
   - 或直接维护本文件 `Logs/CyberTao_Migration_Snapshot_zh_v2.md`
4. 不要只在聊天里说完成，必须写进日志。

---

## 8. Git 噪音文件说明

为避免 Godot 测试时反复产生大量无意义改动，仓库根 `.gitignore` 已加入以下忽略规则：

- `*.uid`
- `*.import`
- `CyberTao_Dice_Beast_Protocol/Signals/*.json`
- `CyberTao_Dice_Beast_Protocol/Signals/*.log`

含义：

- `.uid`、`.import` 是 Godot 本地导入/标识噪音，通常不需要提交。
- `Signals/*.json`、`Signals/*.log` 是本地 Mulerun 监听器生成的临时信号文件，不属于正式项目内容。

正式提交时优先关注：

- `.gd`
- `.tscn`
- `.tres`
- `.md`

---

## 9. 给新 Mulerun 账号的接力说明

新账号接手时请先：

1. 拉取仓库并切到 `codex/dice-beast-protocol`
2. 阅读：
   - `CyberTao_Dice_Beast_Protocol/Logs/CyberTao_Migration_Snapshot_zh_v2.md`
   - `CyberTao_Dice_Beast_Protocol/Logs/changelog_v0.1.md`
   - `CyberTao_Dice_Beast_Protocol/Logs/Mulerun_Work_Report.md`
3. 只在 `CyberTao_Dice_Beast_Protocol/Project/` 内开发
4. 不修改旧项目核心战斗逻辑
5. 所有新增日志默认写中文

---

## 10. 当前一句话状态

**当前已进入”最小可玩战斗 demo + 召唤铺路原型”阶段，下一步重点是让路径系统真正影响战斗规则，并继续提升战斗表现。**
