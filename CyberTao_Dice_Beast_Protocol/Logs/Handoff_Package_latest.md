# CyberTao: Dice Beast Protocol - 交接包

**生成时间**: 2026-04-04 20:13 SGT
**当前版本**: v0.1.115
**分支**: `codex/dice-beast-protocol`

---

## 1. 此刻的精确状态（一句话）

v0.1.115 已完成“推进流程不断档 + 战斗可读性修复”：新增执行指挥中心日志，修复 2D 头像点敌后镜头回拉与棋盘外点击回正，并将单位血条升级为按生命值分格显示。

---

## 2. 最近完成的工作

| 版本 | 任务 | 状态 |
|------|------|------|
| v0.1.115 | 新增 `Execution_Command_Center` 推进中枢；接入 `AI Guide` 强制读取；修复 2D 头像镜头跟随与棋盘外点击回正；血条改为离散分格显示 | 完成 |
| v0.1.103 | 外场固定边框台座与四角结构件，取消自动回正 | 完成 |
| v0.1.104 | 核心日志保守编码修复；同步最新接手基线 | 完成 |
| v0.1.105 | 重写 `AI Guide`、`Art Strategy`、`Snapshot v3`，并清理最新交接路径 | 完成 |
| v0.1.106 | 接入 OpenAI 生图入口；抽离 `MainViewCoordinator`；抽离 `CardBattleData`；重构商店/奖励/牌组 UI；接通 `hacker_fox` 主流程出生 | 完成 |
| v0.1.107 | 同步 `Handoff / Work Report / Snapshot / changelog`，并修复 headless 下新类型解析风险 | 完成 |
| v0.1.108 | 同步 `AI_Employee_Guide_v3.md` 与 `Art_Beautification_Strategy_zh.md`，补齐文档更新规则 | 完成 |
| v0.1.109 | 主视图/棋盘重置路径改为 `.clear()`，防止高亮数组赋值 crash，并把这次修复写进 changelog | 完成 |
| v0.1.110 | 新增第一章 `ChapterContent`/`MissionBriefOverlay`，修复召唤物误触发主流程交互并统一第一章遭遇/Boss命名 | 完成 |
| v0.1.111 | 删除 OpenAI 生图入口与两份相关脚本，重做顶部单位头像 HUD 视觉，并补齐 6 个骰面基础功能 | 完成 |
| v0.1.112 | DM 机制深化：crest 双池分离+跨回合保留+同面连锁奖励；敌方目标选择改为优先主角/残血 | 完成 |
| v0.1.113 | 召唤体系深化：三职业召唤单位 + 护卫嘲讽与减伤光环 + 登场/回合战术收益 + 召唤上限调优 | 完成 |
| v0.1.114 | 棋盘据点系统：新增可占领控制点、归属可视化、据点收益结算、敌方据点优先寻路与反馈提示 | 完成 |

---

## 3. 当前真实结构

- 入口：`Project/Scenes/Main.tscn`
- 主控入口：`Project/Scripts/Main.gd`
- 主界面协调层：`Project/Scripts/App/MainViewCoordinator.gd`
- 章节文案中心：`Project/Scripts/App/ChapterContent.gd`
- 棋盘外层：`Project/Scripts/BattleV2/BattleFlowController.gd`
- 卡牌内层：`Project/Scripts/BattleV2/CardBattleController.gd`
- 卡牌数据：`Project/Scripts/BattleV2/CardBattleData.gd`
- 生图服务：已从主流程与仓库中移除
- 生图面板：已从主流程与仓库中移除
- 章节简报面板：`Project/Scripts/UI/MissionBriefOverlay.gd`
- 商店 UI：`Project/Scripts/UI/ShopPanel.gd`
- 结构快照：`Logs/CyberTao_Migration_Snapshot_zh_v3.md`

---

## 4. 本轮已核实的事实

- `FloorManager.gd` 现在会生成 `blade_shield_dog` 与 `hacker_fox` 两个玩家单位，旧日志中“次级玩家单位尚未接入主流程”的描述已过时。
- `CardBattleData.gd` 已集中管理起始牌组、奖励池、升级规则与遭遇敌人数据；`CardBattleController.gd` 不再内嵌整块卡牌数据表。
- `Main.gd` 已把大部分界面构建与信号接线抽到 `MainViewCoordinator.gd`，入口协调层规模从旧快照里的 700+ 行回落到 472 行。
- `ShopPanel.gd`、`CardRewardPanel.gd`、`DeckViewPanel.gd` 已统一到新的卡牌 tile / row 展示方案。
- 隔离用户目录下的最小 headless 启动已通过，不再出现 `ImageGenerationPanel` / `OpenAIImageService` 类型解析错误。
- `MainViewCoordinator.gd` 已接入 `MissionBriefOverlay`，`Main.gd` 开局能稳定显示章节简报，不再空降棋盘。
- `UnitManager.gd` 新增 `get_player_hero_units()` / `is_player_hero_unit()`；`BattleFlowController.gd`、`CellEffectHandler.gd`、`BoardView.gd`、`BoardView3D.gd`、`UnitPortraitHUD.gd`、`Main.gd` 全链路按此区分主角与召唤物。
- 召唤物不再触发事件/遭遇/商店/宝箱/传送门，也不再进入主角头像栏和核心选择流程。
- `CardBattleData.gd` / `ChapterContent.gd` 已将第一章遭遇与 Boss 命名统一到“灰链封锁区 / 天枢治域”语气，避免终局设定前置。

---

## 5. 当前仍需继续关注的风险

| 问题 | 严重程度 | 是否阻塞 | 说明 |
|------|----------|----------|------|
| `Main.gd` 仍承担较多协调职责 | 中 | 否 | 虽已拆出 `MainViewCoordinator` 并接入章节简报层，但入口层仍负责流程切换、音频、结果结算与多路信号转发 |
| 2D / 3D 表现一致性仍在追赶 | 中 | 否 | 3D 反馈已继续增强，但可读性和 2D 仍未完全拉齐 |
| 第三个玩家单位 `crow_caster` 仍未接入主流程 | 中 | 否 | 当前可玩双英雄已接通，第三单位仍停留在资源层 |
| 本机 headless 仍有系统警告 | 低 | 否 | 当前最小启动仍会出现 `Failed to read the root certificate store` 和退出时 1 处资源未释放警告 |

---

## 6. 下一步建议

1. 把据点系统从“占点得资源”继续升级为“占点胜利条件”与回合压制分数，强化对局目标感。
2. 按据点语义扩展敌方行为（守点/驱逐/反占），减少当前“看见人就冲”的单调体验。
3. 继续拆分 `Main.gd` 的纯中转与表现触发逻辑，减轻入口层职责。
4. 决定 `crow_caster` 是否进入主循环，还是继续保留为资源预备位。
