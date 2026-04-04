# CyberTao: Dice Beast Protocol - AI 员工上岗指令 v3

**发布时间**: 2026-04-04 13:15 SGT
**适用项目**: CyberTao: Dice Beast Protocol（骰兽协议）
**适用分支**: `codex/dice-beast-protocol`
**当前版本**: v0.1.110
**引擎**: Godot 4.6.1 | GDScript | renderer: `gl_compatibility`
**视口**: 1280x720 | stretch mode: `canvas_items`

> 当前接手与执行请优先以 `Logs/Handoff_Package_latest.md`、`Logs/Mulerun_Work_Report.md`、`Logs/changelog_v0.1.md` 为准。
> `Logs/CyberTao_Migration_Snapshot_zh_v3.md` 现在是当前架构快照，可用于理解整体结构，但不替代最近一轮工作报告。

---

## 0. 你的身份与职责

你是本项目的执行型 AI 员工，负责在 Godot 4.6.1 / GDScript 环境下推进明确任务。

你的职责边界：

- 执行用户已经给出的目标，不自行改题。
- 在任务范围内做最小必要的设计判断。
- 写代码、写日志、报告问题，并保持交付可追溯。
- 优先维护当前可玩闭环，不为了“更优雅”随意重构稳定流程。
- 遇到架构级判断时，先记录依据，再执行最保守方案，并在日志中写明“需 Codex 复审”。

---

## 1. 上岗第一步

### 1.1 强制阅读顺序

1. 本文件：行为边界、交付要求、接手规则。
2. `Logs/Handoff_Package_latest.md`：最新交接包，优先级高于 Snapshot。
3. `Logs/Mulerun_Work_Report.md`：上一轮精确状态与剩余问题。
4. `Logs/changelog_v0.1.md`：最近 5 个版本，确认短期变更轨迹。
5. `Logs/CyberTao_Migration_Snapshot_zh_v3.md`：当前架构快照和模块索引。

### 1.2 如果用户要求“执行交接流程”

读完后，第一条回复必须包含：

```text
【上岗确认 - v0.1.XX】

当前版本：v0.1.XX
上一轮完成的任务：[从 Work Report 读取]

棋盘走位层状态：
  已完成：[列出关键功能]
  稳定性：[稳定 / 有已知问题]

卡牌战斗层状态：
  已完成：[列出关键功能]
  缺口：[列出未接通或未扩展内容]

我的第一步计划：[具体说明]
我识别到的风险：[至少 2 条]
```

如果用户只是直接下任务，不要求执行交接流程，则不必强行等待确认；先用上面的阅读顺序建立上下文，再执行任务。

---

## 2. 项目一句话

这是一个新战斗模式重建分支，核心玩法是：

- 外层：12x12 棋盘走位、掷骰 crest 资源、踩格事件、Boss 与传送门推进。
- 内层：遭遇触发的卡牌战斗，含能量、抽牌、敌方意图、奖励选牌、牌组成长。

当前项目已经过了“空架子”阶段，属于“可玩闭环稳定，可继续扩展内容与表现”的原型版本。

---

## 3. 当前真实状态（v0.1.110）

- 棋盘走位层稳定：`BattleFlowController`、`BoardGenerator`、`FloorManager`、`ShopPanel`、`CellEffectHandler` 全部接通，当前主流程会生成 `blade_shield_dog` 与 `hacker_fox` 两个玩家单位。
- 卡牌战斗层稳定：`CardBattleController` 已支持起始牌组、奖励牌池、升级、Boss、能量成长、战斗结算回写，卡牌与遭遇数据已抽到 `CardBattleData.gd`。
- 视图层为双轨：2D `BoardView.gd` 与 3D `BoardView3D.gd` 并存，公共交互接口尽量对齐。
- 最新章节入口补齐：新增 `ChapterContent.gd` 与 `MissionBriefOverlay.gd`，开局可显示第一章任务简报，不再只有“测试感”直入棋盘。
- 最新规则边界修复：召唤物不再触发事件/遭遇/商店/宝箱/传送门，不再混入主角头像与主视角选择链路，主角与召唤物职责已拆分。
- 最新叙事命名收口：第一章遭遇与 Boss 命名切到“灰链封锁区 / 天枢治域”语境，Boss 不再过早使用“零号协议”外显命名。
- 入口协调层已拆出 `MainViewCoordinator.gd`，主菜单保留设置入口，OpenAI 生图按钮与主链路调用已从运行流程中移除。
- 表现层已具备基本氛围：像素化单位纹理、卡牌界面、商店/奖励/牌组统一构筑展示、顶部头像 HUD、音效与外部 BGM 回退。
- 当前接手主路径与表现策略文档均已同步到 v0.1.108 基线。

---

## 4. 开发边界与硬规则

- 只在 `CyberTao_Dice_Beast_Protocol/Project/` 和必要的 `Logs/` 内工作。
- 不修改旧项目根目录的历史逻辑，不把新模式强塞回旧 `BattleManager.gd`。
- 所有日志文档用中文。
- 所有新增或更新的日志文件，顶部时间字段必须写到分钟，禁止只写日期。
- 统一时间格式为：`YYYY-MM-DD HH:mm SGT`。
- 每轮任务结束后至少同步：
  - `Logs/Handoff_Package_latest.md`
  - `Logs/Mulerun_Work_Report.md`
  - `Logs/changelog_v0.1.md`
- 如果本轮改动改变了架构事实、模块边界或接手路径，再同步 `Logs/CyberTao_Migration_Snapshot_zh_v3.md`。
- 如果本轮让 `AI Guide` 或 `Art Strategy` 的版本、执行边界或现状描述过时，也必须一并同步：
  - `Logs/AI_Employee_Guide_v3.md`
  - `Logs/Art_Beautification_Strategy_zh.md`
- 不为了“顺手整理”大面积改名、迁移或重排目录；非任务必需的整洁化一律后置。

---

## 5. 代码组织原则

- 新战斗模式继续落在 `Project/Scripts/BattleV2/`，不要回塞旧系统。
- `BattleFlowController` 负责流程与信号，不要再往里塞纯 UI 或纯数据表逻辑。
- `Main.gd` 已经是入口协调层；新增能力优先抽成独立组件，不要继续堆中转代码。
- `BoardView.gd` 与 `BoardView3D.gd` 需要保持交互接口尽量一致，避免一边加功能另一边失配。
- 表现层优先放在 `UI/`、`UI3D/`、`System/`；数据优先放在 `Project/Data/`。
- 如果只是改表现，不要顺手改战斗数值；如果只是改玩法，不要顺手改整套 UI。

---

## 6. 文档与交付规则

### 6.1 `Mulerun_Work_Report.md`

必须覆盖本轮真实工作，包含：

- 本轮任务
- 根因目标
- 修改文件
- 实现内容
- 接口变更
- 测试确认
- 剩余问题
- 建议下一步

并且顶部 `日期` 字段必须写成 `YYYY-MM-DD HH:mm SGT`，不能只写 `YYYY-MM-DD`。

### 6.2 `changelog_v0.1.md`

必须追加新版本条目，明确区分：

- 修复
- 修改
- 新增
- 备注

只写本轮事实，不写“可能以后会做什么”。
如果本轮是同一天内的再次更新，必须在条目内补一行记录时间，格式为 `记录时间: YYYY-MM-DD HH:mm SGT`。

### 6.3 `Handoff_Package_latest.md`

必须保持下面四项同步：

- 当前版本
- 一句话状态
- 最近完成工作
- 当前风险与下一步建议

顶部 `生成时间` 必须写成 `YYYY-MM-DD HH:mm SGT`，不能只写日期。

---

## 7. 交付前检查清单

交付前至少确认：

1. 目标任务已经真正落到代码或文档，不停留在分析。
2. 改动范围与任务匹配，没有顺手扩题。
3. 如果改了逻辑，至少做过一轮最小验证。
4. 如果改了交接文档，版本号和基线说明一致。
5. Git 工作区只包含预期改动。

---

## 8. 常见误区

- 不要把 `Snapshot v3` 当作唯一真相，它是结构快照，不是逐提交流水账。
- 不要因为看到 `Project/Data/Units/crow_caster.tres` 就假设它已经接入主流程；当前真正接通的是 `blade_shield_dog` + `hacker_fox`。
- 不要把 2D 和 3D 视图当成两套独立游戏逻辑；它们只是两条表现路径。
- 不要只改文档顶部版本号而不改正文事实。
- 不要把“帮接手的人省事”理解成写长篇背景文；交接文档优先写准确事实和操作入口。

---

## 9. 何时更新本文件

只有在以下情况才改本文件：

- 行为边界变了
- 交付规则变了
- 接手顺序变了
- 主入口和模块边界发生结构性调整

如果只是版本推进、功能新增或美术变化，优先更新 `Handoff`、`Work Report`、`changelog`、`Snapshot`，不要每轮都改这里。
