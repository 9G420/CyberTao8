# Mulerun 工作报告

**日期**: 2026-04-04 14:47 SGT
**版本**: v0.1.114
**分支**: `codex/dice-beast-protocol`

## 本轮任务

追加更新（v0.1.114）：

- `BoardGenerator.gd` 新增中路据点生成逻辑，开局稳定生成可争夺目标（能量/指挥/驱逐）。
- `BoardManager.gd` 新增据点数据结构与归属读写接口：`control_nodes`、`control_node_owner`。
- `BattleFlowController.gd` 新增据点占领与收益结算流程，并对玩家/敌方回合都接入据点收益。
- `BattleAI.gd` 新增据点优先目标选择：敌方会优先争夺玩家已占领据点，其次争夺中立据点。
- `IsoTileRenderer.gd` + `BoardView.gd` 新增据点可视化与归属标记覆盖层。
- `MainViewCoordinator.gd` + `Main.gd` 新增据点事件反馈信号与提示文案，确保占领与收益可感知。
- headless 启动检查通过（仅保留历史资源释放警告，不阻塞本轮交付）。

追加更新（v0.1.113）：

- 召唤单位从单一模板升级为三职业：侦察型（机动补给）、突击型（压血斩杀）、护卫型（嘲讽护卫）。
- `BattleAI.gd` 接入 taunt 规则：若邻接嘲讽单位，敌方优先攻击嘲讽目标；追击路径也会优先朝 taunt 单位推进。
- `BattleFlowController.gd` 接入护卫光环：主角邻接护卫型召唤单位时，结算伤害获得额外防护（DEF+1 等效）。
- 召唤收益改为“登场收益 + 每轮收益”：召唤单位不会只在落地那一刻有用，能持续影响 crest 经济。
- 召唤上限调优：每层部署上限提升为 3，场上上限提升为 2，支持组合而非一次性测试。

追加更新（v0.1.112）：

- DM 机制深化：`DiceManager` 改为玩家/敌方双 crest 资源池，双方资源互不污染，并支持跨回合保留。
- 新增同面连锁奖励：单次掷骰中同类型面达到 2 个及以上时，额外获得该类型 +1 crest。
- 敌方行为优化：`BattleAI` 新增主角优先与残血优先策略；`BattleFlowController` 接入优先目标选择和追击逻辑。
- 骰面语义修正：`move/defend/skill/summon` 的奖励效果与面类型对齐，减少“掷到A却加B”的违和感。

追加更新（v0.1.111）：

- 彻底剔除 OpenAI 生图功能：移除设置旁生图按钮、移除 `Main.gd` 与 `MainViewCoordinator.gd` 中所有生图调用链、并从仓库删除 `OpenAIImageService.gd` 与 `ImageGenerationPanel.gd`。
- 优化顶部单位头像选择 UI：重做 `UnitPortraitHUD.gd` 的布局、选中/悬停反馈、血量可读性与整体视觉质感。
- 补齐当前基础骰面体验：同步 `DiceManager.gd` 与 6 个 `face_*.tres`，让每个骰面都具备明确用途，不再出现空功能面。

执行私有创意文档任务 1，收口第一章公开实现路径，并修复当前“主角/召唤物规则混乱”导致的棋盘游玩体验问题；同时补齐从开场简报到遭遇战斗的章节入口层。

## 根因目标

当前项目已具备可玩闭环，但仍有明显“测试功能感”：

- 开局缺少稳定的章节叙事入口，直接进入棋盘，章节感不足。
- 主角与召唤物边界不清，召唤物能触发事件/遭遇/商店/宝箱/传送门，破坏主流程认知。
- 头像栏和选择链路未区分主角与召唤物，玩家容易误判单位职责。
- 第一章遭遇与 Boss 命名语气未收口，且 Boss 外显命名过早触及终局设定语义。

本轮目标是先完成“可玩章节切片”的最低成本修复，而非扩大全世界设定。

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/App/ChapterContent.gd` | 新增第一章内容中心，统一开场简报、章节标题、楼层目标、遭遇显示名与战斗反馈文本 |
| `Project/Scripts/UI/MissionBriefOverlay.gd` | 新增章节简报覆盖层 UI，支持开局展示任务简报并阻断误输入 |
| `Project/Scripts/App/MainViewCoordinator.gd` | 接入 `MissionBriefOverlay`，补齐 `chapter_label` / `objective_label` 引用与创建 |
| `Project/Scripts/Main.gd` | 相机主角选择改为 hero-only；卡牌战斗启动传入真实主角名；保持章节入口链路稳定 |
| `Project/Scripts/BattleV2/UnitManager.gd` | 新增 `get_player_hero_units()`、`is_player_hero_unit()`、`is_summoned_unit()` |
| `Project/Scripts/BattleV2/CellEffectHandler.gd` | 事件/商店/宝箱/治疗/道具触发改为仅主角可触发 |
| `Project/Scripts/BattleV2/BattleFlowController.gd` | 棋盘交互触发链路加 hero-only 守卫；召唤单位补 `display_name` |
| `Project/Scripts/UI/BoardView.gd` | 2D 选择逻辑改为仅允许主角进入核心选择流 |
| `Project/Scripts/UI3D/BoardView3D.gd` | 3D 选择逻辑与 2D 对齐，召唤物不再占用主角选择入口 |
| `Project/Scripts/UI/UnitPortraitHUD.gd` | 顶部头像栏过滤召唤物，仅展示主角 |
| `Project/Scripts/BattleV2/CardBattleController.gd` | `battle_started` 信号新增 `player_name` 参数；战斗启动支持传入主角名 |
| `Project/Scripts/UI/CardBattlePanel.gd` | 玩家名不再写死，改为按触发遭遇的主角动态显示 |
| `Project/Scripts/BattleV2/CardBattleData.gd` | 第一章普通遭遇与 Boss 命名收口到“灰链封锁区 / 天枢治域”语境 |
| `Project/Scripts/BattleV2/BoardGenerator.gd` | 敌方杂兵显示名改为“巡检哨甲/乙/丙”语气 |
| `Project/project.godot` | 编辑器运行后项目配置同步变更 |
| `Logs/Private_Chapter1_Flow_local.md` | 新增本地私有推进文档（已本地排除，不进仓库） |

## 实现内容

- 补齐第一章入口层：`Main.gd -> ChapterContent -> MissionBriefOverlay` 形成稳定开场任务简报路径。
- 修复召唤物规则越权：召唤物仍可战斗与铺路，但不再触发章节主流程交互。
- 修复单位认知混乱：主角/召唤物在相机、选择、头像栏、卡牌战斗名牌中完成明确分层。
- 收口第一章公开命名：遭遇和 Boss 命名统一到天枢治域封锁语气，避免“终局词”前置。

## 接口变更

- `CardBattleController.battle_started` 从 3 参数变为 4 参数：
  - 旧：`battle_started(player_hp, enemy_hp, enemy_name)`
  - 新：`battle_started(player_hp, enemy_hp, enemy_name, player_name)`
- `CardBattleController.start_battle` 新增可选参数 `p_name`。
- `UnitManager` 新增：
  - `get_player_hero_units()`
  - `is_player_hero_unit(unit_id)`
  - `is_summoned_unit(unit)`

## 测试确认

- 已执行 `godot4 --headless --path Project --quit`，项目可正常启动，未再出现章节内容缺失或 UI 属性缺失报错。
- 已验证核心链路：
  - 开局章节简报可显示
  - 主角与召唤物选择链路分离
  - 召唤物不再触发事件/遭遇等主流程交互
- 仍有 Godot 退出时资源未释放警告（历史问题，非本轮新增阻塞）。

## 剩余问题

- 敌方虽然已具备据点优先目标，但行为仍偏“直线逼近”，尚未形成“守点/驱逐/围压”多意图行为。
- `crow_caster` 仍未接入主循环。
- 据点目前只提供 crest 收益，尚未接入“回合压制分/胜利条件”。

## 建议下一步

1. 先做第一章敌方 AI 收口（卡路、堵路、围压），把“封锁区”体验从文本落到行为层。
2. 继续拆分 `Main.gd` 的中转职责，减轻入口层复杂度。
3. 再决定 `crow_caster` 是进入主流程还是保留为后续章节单位。
4. 把据点推进到“守点/驱逐/反占”的可验证战斗目标系统。
