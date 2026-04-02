# CyberTao: Dice Beast Protocol - 交接包

**生成时间**: 2026-04-03
**当前版本**: v0.1.107
**分支**: `codex/dice-beast-protocol`

---

## 1. 此刻的精确状态（一句话）

v0.1.107 已完成 v0.1.106 的状态回补、项目日志同步和一处新生图入口的类型解析稳定性修补；当前项目处于“可玩闭环稳定 + 双英雄开局 + OpenAI 生图入口已接入”的阶段。

---

## 2. 最近完成的工作

| 版本 | 任务 | 状态 |
|------|------|------|
| v0.1.103 | 外场固定边框台座与四角结构件，取消自动回正 | 完成 |
| v0.1.104 | 核心日志保守编码修复；同步最新接手基线 | 完成 |
| v0.1.105 | 重写 `AI Guide`、`Art Strategy`、`Snapshot v3`，并清理最新交接路径 | 完成 |
| v0.1.106 | 接入 OpenAI 生图入口；抽离 `MainViewCoordinator`；抽离 `CardBattleData`；重构商店/奖励/牌组 UI；接通 `hacker_fox` 主流程出生 | 完成 |
| v0.1.107 | 同步 `Handoff / Work Report / Snapshot / changelog`，并修复 headless 下新类型解析风险 | 完成 |

---

## 3. 当前真实结构

- 入口：`Project/Scenes/Main.tscn`
- 主控入口：`Project/Scripts/Main.gd`
- 主界面协调层：`Project/Scripts/App/MainViewCoordinator.gd`
- 棋盘外层：`Project/Scripts/BattleV2/BattleFlowController.gd`
- 卡牌内层：`Project/Scripts/BattleV2/CardBattleController.gd`
- 卡牌数据：`Project/Scripts/BattleV2/CardBattleData.gd`
- 生图服务：`Project/Scripts/System/OpenAIImageService.gd`
- 生图面板：`Project/Scripts/UI/ImageGenerationPanel.gd`
- 商店 UI：`Project/Scripts/UI/ShopPanel.gd`
- 结构快照：`Logs/CyberTao_Migration_Snapshot_zh_v3.md`

---

## 4. 本轮已核实的事实

- `FloorManager.gd` 现在会生成 `blade_shield_dog` 与 `hacker_fox` 两个玩家单位，旧日志中“次级玩家单位尚未接入主流程”的描述已过时。
- `CardBattleData.gd` 已集中管理起始牌组、奖励池、升级规则与遭遇敌人数据；`CardBattleController.gd` 不再内嵌整块卡牌数据表。
- `Main.gd` 已把大部分界面构建与信号接线抽到 `MainViewCoordinator.gd`，入口协调层规模从旧快照里的 700+ 行回落到 472 行。
- `ShopPanel.gd`、`CardRewardPanel.gd`、`DeckViewPanel.gd` 已统一到新的卡牌 tile / row 展示方案。
- 隔离用户目录下的最小 headless 启动已通过，不再出现 `ImageGenerationPanel` / `OpenAIImageService` 类型解析错误。

---

## 5. 当前仍需继续关注的风险

| 问题 | 严重程度 | 是否阻塞 | 说明 |
|------|----------|----------|------|
| `Main.gd` 仍承担较多协调职责 | 中 | 否 | 虽已拆出 `MainViewCoordinator`，但入口层仍负责流程切换、音频、结果结算与多路信号转发 |
| 2D / 3D 表现一致性仍在追赶 | 中 | 否 | 3D 反馈已继续增强，但可读性和 2D 仍未完全拉齐 |
| 第三个玩家单位 `crow_caster` 仍未接入主流程 | 中 | 否 | 当前可玩双英雄已接通，但第三单位仍停留在资源层 |
| 生图功能仍缺少真实 API 链路回归 | 中 | 否 | 启动和界面已接通，但实际依赖 API Key、网络与系统证书环境 |
| 本机 headless 仍有系统警告 | 低 | 否 | 当前最小启动仍会出现 `Failed to read the root certificate store` 和退出时 1 处资源未释放警告 |

---

## 6. 下一步建议

1. 继续拆分 `Main.gd` 中的纯中转、纯表现触发和结算逻辑。
2. 用真实 API Key 对 OpenAI 生图链路做一次端到端回归，而不只停留在启动成功。
3. 决定 `crow_caster` 是否进入主循环，还是继续保留为资源预备位。
4. 单独排查 headless 下的根证书读取与退出资源释放警告。
