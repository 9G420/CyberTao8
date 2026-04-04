<!-- CURRENT_VERSION_NOTICE -->
> 注意：本文件已同步到当前真实项目基线。
> 执行时仍请优先结合 `Logs/Handoff_Package_latest.md`、`Logs/Mulerun_Work_Report.md` 与 `Logs/changelog_v0.1.md`。

# CyberTao: Dice Beast Protocol 项目迁移快照（中文 v3）

**更新时间**: 2026-04-04 20:56 SGT
**当前版本**: v0.1.116
**GitHub 仓库**: `https://github.com/9G420/CyberTao8`
**主要分支**: `codex/dice-beast-protocol`
**主工作目录**: `CyberTao_Dice_Beast_Protocol/Project/`
**入口场景**: `Project/Scenes/Main.tscn`
**引擎**: Godot 4.6.1 | GDScript | renderer: `gl_compatibility`
**视口**: 1280x720 | stretch mode: `canvas_items`

---

## 0. 新接手时先读什么

建议阅读顺序：

1. `Logs/AI_Employee_Guide_v3.md`
2. `Logs/Handoff_Package_latest.md`
3. `Logs/Mulerun_Work_Report.md`
4. `Logs/changelog_v0.1.md` 最近 5 个版本
5. 本文件

其中：

- `AI Guide` 负责说明行为边界和交付规则。
- `Handoff` 负责说明当前版本和当前风险。
- `Work Report` 负责说明上一轮到底做了什么。
- `changelog` 负责说明最近几轮改动轨迹。
- 本文件负责说明当前代码结构、模块关系和内容基线。

---

## 1. 项目定位

`CyberTao: Dice Beast Protocol` 是基于旧项目并行重建的新战斗模式分支。

核心玩法是双层结构：

1. 外层：棋盘走位层
   - 掷骰获得 crest 资源
   - 进行移动、攻击、召唤、踩格事件、商店购买
   - 清理遭遇、解锁 Boss、通过传送门推进楼层
2. 内层：卡牌战斗层
   - 遭遇触发后切入独立战斗界面
   - 通过能量、抽牌、出牌、敌方意图与奖励选牌推动成长
   - 战斗结果回写到棋盘层，继续推进整局流程

设计原则仍然成立：

- 新模式继续在 `BattleV2` 内推进
- 不把新逻辑强塞回旧 `BattleManager.gd`
- 先保证原型闭环稳定，再继续扩内容和表现

---

## 2. 当前一句话状态

v0.1.116 已完成敌方意图连线首版：战斗流程可实时输出敌方下一步攻击/移动意图，2D 棋盘可视化 `ATK/MOV` 预告线，玩家可通过走位与击杀进行打断。

---

## 3. 当前可玩闭环

### 3.1 棋盘阶段

- 玩家在 12x12 棋盘上活动。
- 每回合通过掷骰获得 crest 资源。
- 可执行移动、攻击、召唤、防御 crest、技能 crest、技巧 crest 等操作。
- 棋盘会生成高地、陷阱、道具、遭遇、治疗、事件、商店、宝箱、Boss、传送门等要素。

### 3.2 遭遇阶段

- 玩家踩到遭遇格后进入 `ENCOUNTER`。
- `Main.gd` 调度过渡动画并打开独立的卡牌战斗界面。
- 卡牌战斗结束后，结果回写到棋盘层。

### 3.3 卡牌战斗阶段

- 起始牌组、抽牌、弃牌、洗牌、能量、敌方行动模式、敌方意图全部已接通。
- 战斗胜利会给 crest 奖励、能量成长和奖励选牌。
- 牌组在遭遇之间持久保留，并支持升级。

### 3.4 楼层推进

- 普通遭遇清空后解锁 Boss。
- Boss 胜利后在附近生成传送门。
- 传送门触发楼层推进，当前总楼层数为 3。
- 楼层切换时，存活单位回复 30%，阵亡单位以 50% HP 复活。

---

## 4. 已实装系统概览

### 4.1 棋盘走位层

- `BattleFlowController` 流程控制
- `BoardManager` 棋盘状态
- `BoardGenerator` 随机生成
- `UnitManager` 单位状态
- `ActionResolver` 攻击范围与移动辅助
- `BuffManager` buff 管理
- `BattleAI` 敌方行动
- `CellEffectHandler` 处理陷阱、道具、治疗、事件、商店、宝箱
- `CrestActionHandler` 处理 DEFEND / SKILL / TRICK crest 消耗
- `FloorManager` 处理多层地图、Boss 解锁、传送门和跨层状态

### 4.2 卡牌战斗层

- `CardBattleController` 独立状态机
- `CardBattleData` 统一维护起始牌组、奖励池、升级规则与遭遇敌人数据
- 起始牌组 10 张
- 奖励池含扩展牌，并允许基础牌回流
- 奖励选牌、跳过奖励、升级卡牌全部可用
- 普通遭遇 7 种，Boss 遭遇 1 种
- 能量成长上限为 5

### 4.3 表现层

- 2D 视图：`BoardView.gd`
- 3D 视图：`BoardView3D.gd`
- 等距棋盘绘制：`IsoTileRenderer.gd`
- 卡牌表现：`CardRenderer.gd`
- 卡牌战斗界面：`CardBattlePanel.gd`
- 奖励与升级面板：`CardRewardPanel.gd`
- 牌组面板：`DeckViewPanel.gd`
- 商店面板：`ShopPanel.gd`
- 生图服务：已从主流程与仓库移除
- 生图面板：已从主流程与仓库移除
- 顶部单位头像：`UnitPortraitHUD.gd`
- 音频：`AudioManager.gd` + `SFXGenerator.gd`

---

## 5. 当前代码结构

### 5.1 入口与关键脚本

| 路径 | 角色 | 当前规模 |
|------|------|----------|
| `Project/Scenes/Main.tscn` | 场景入口 | 1 个主场景 |
| `Project/Scripts/Main.gd` | 入口协调层，负责流程切换、结算、音频与主信号转发 | 472 行 |
| `Project/Scripts/App/MainViewCoordinator.gd` | 主界面视图构建与信号接线协调层 | 192 行 |
| `Project/Scripts/App/ChapterContent.gd` | 第一章章节文案与流程提示中心 | 新增 |
| `Project/Scripts/BattleV2/BattleFlowController.gd` | 棋盘层主控（含敌方意图缓存/广播） | 1053 行 |
| `Project/Scripts/BattleV2/CardBattleController.gd` | 卡牌战斗主控 | 459 行 |
| `Project/Scripts/BattleV2/CardBattleData.gd` | 卡牌与遭遇数据中心 | 309 行 |
| `Project/Scripts/BattleV2/BoardGenerator.gd` | 棋盘随机生成 | 228 行 |
| `Project/Scripts/BattleV2/BoardManager.gd` | 棋盘状态存储 | 249 行 |
| `Project/Scripts/BattleV2/FloorManager.gd` | 楼层推进、双英雄出生与跨层状态 | 145 行 |
| `Project/Scripts/UI/BoardView.gd` | 2D 棋盘交互与表现（含敌方意图线可视化） | 720 行 |
| `Project/Scripts/UI/MissionBriefOverlay.gd` | 开局任务简报覆盖层 | 新增 |
| `Project/Scripts/UI3D/BoardView3D.gd` | 3D 棋盘交互与表现 | 773 行 |
| `Project/Scripts/UI/ShopPanel.gd` | 商店 UI 与购买结算 | 520 行 |
| `Project/Scripts/System/AudioManager.gd` | BGM / SFX 管理 | 144 行 |

### 5.2 模块目录现状

- `Project/Scripts/BattleV2/`：核心玩法层
- `Project/Scripts/App/`：入口 UI 协调层
- `Project/Scripts/UI/`：2D 与通用 UI
- `Project/Scripts/UI3D/`：3D 表现层
- `Project/Scripts/System/`：音频、显示设置等系统层（生图链路已移除）
- `Project/Scripts/Data/`：资源脚本定义
- `Project/Data/`：单位、技能、道具、骰面、核心等 `.tres` 资源

---

## 6. 当前数据与内容基线

### 6.1 `Project/Data/` 资源目录

| 分类 | 数量 | 说明 |
|------|------|------|
| `Units` | 3 | `blade_shield_dog`、`hacker_fox`、`crow_caster` |
| `Items` | 3 | `patch_tea_cache`、`overclock_bone`、`glitch_snack_box` |
| `Skills` | 8 | 基础技能与阵营技能资源 |
| `Dice` | 6 | 六种基础 crest 骰面 |
| `Cores` | 1 | 一个核心资源 |

### 6.2 当前启用的内容

- 主流程当前会生成 2 个可玩英雄：`blade_shield_dog` 与 `hacker_fox`
- `crow_caster` 资源存在，但尚未接入主循环
- 棋盘生成会随机放置：
  - 普通遭遇 4 到 6 个
  - 高地 3 到 5 个
  - 陷阱 3 到 5 个
  - 道具 3 个
  - 治疗格 3 个
  - 事件格 3 到 5 个
  - 商店格 2 个
  - 宝箱格 2 到 3 个
  - 锁定 Boss 1 个
  - 敌方杂兵 3 个
- 当前卡牌遭遇数据为：
  - 普通遭遇 `encounter_01` 到 `encounter_07`
  - Boss 遭遇 `encounter_boss_01`
- 商店当前支持 9 类商品，包括回复、临时属性强化、能量上限、加牌、删牌、随机 crest、最大 HP 提升等
- OpenAI 生图按钮与运行链路已从当前版本主流程中移除，不再参与战斗主循环

---

## 7. 当前关键规则事实

### 7.1 棋盘与楼层

- 棋盘大小：`12 x 12`
- 总楼层数：`3`
- Boss 格默认锁定，清理杂兵后解锁
- Boss 胜利后生成传送门

### 7.2 召唤限制

- 每层召唤上限：3 次
- 场上召唤单位上限：2 个

### 7.3 卡牌战斗

- 起手抽牌：3
- 手牌上限：6
- 初始最大能量：3
- 最大能量上限：5
- 遭遇胜利后最大能量成长：
  - 普通遭遇：+1
  - Boss：+2

### 7.4 跨层保留

- 存活玩家单位：跨层回复 30%
- 阵亡玩家单位：跨层以 50% HP 复活
- 持久牌组跨遭遇保留

---

## 8. 当前接手时必须知道的事实

1. 当前最可靠的执行入口是 `AI Guide + Handoff + Work Report + changelog`，不是只看 Snapshot。
2. `Main.gd` 已经承担大量协调逻辑，后续新增能力应优先抽层。
3. 2D 和 3D 是两条表现路径，不是两套逻辑。
4. 当前项目的主循环已经稳定，接下来最有价值的是内容扩展、结构整理和表现统一，而不是重新发明底层循环。

---

## 9. 当前风险

| 问题 | 严重度 | 是否阻塞 | 说明 |
|------|--------|----------|------|
| `Main.gd` 仍承担较多协调职责 | 中 | 否 | 虽已拆出 `MainViewCoordinator`，但主入口仍负责流程切换、结算和多路信号转发 |
| 2D / 3D 表现一致性仍在追赶 | 中 | 否 | 3D 可玩，但反馈和可读性仍不完全追平 2D |
| 第三个玩家单位 `crow_caster` 尚未接入主流程 | 中 | 否 | 当前双英雄已接通，但第三单位仍停留在资源层 |
| 2D / 3D 意图线表现一致性仍需追齐 | 中 | 否 | 当前 A1 先落在 2D `BoardView`，3D 视图还需跟进同等可读性提示 |
| 更早历史日志仍可能残留编码遗留 | 低 | 否 | 当前接手主路径已清洗，旧历史段落不影响本轮执行 |

---

## 10. 推荐下一步

按优先级建议：

1. 继续拆分 `Main.gd` 的纯中转和协调逻辑。
2. 在 3D 视图补齐敌方意图可视化，保证两条表现路径规则一致。
3. 决定 `crow_caster` 是否进入主流程。
4. 统一 2D / 3D 的关键反馈与可读性，并继续保持 `Handoff / Work Report / changelog / Snapshot` 同步。

---

## 11. 常用入口索引

| 路径 | 用途 |
|------|------|
| `Project/Scenes/Main.tscn` | 主场景入口 |
| `Project/Scripts/Main.gd` | 入口协调层 |
| `Project/Scripts/BattleV2/BattleFlowController.gd` | 棋盘主循环 |
| `Project/Scripts/BattleV2/CardBattleController.gd` | 卡牌战斗主循环 |
| `Project/Scripts/UI/BoardView.gd` | 2D 棋盘 |
| `Project/Scripts/UI3D/BoardView3D.gd` | 3D 棋盘 |
| `Project/Scripts/UI/ShopPanel.gd` | 商店 |
| `Project/Scripts/System/AudioManager.gd` | 音频系统 |
| `Logs/Handoff_Package_latest.md` | 最新交接摘要 |
| `Logs/Mulerun_Work_Report.md` | 上一轮工作报告 |
| `Logs/changelog_v0.1.md` | 版本变更记录 |
