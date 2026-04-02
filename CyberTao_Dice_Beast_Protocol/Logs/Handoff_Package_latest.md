# CyberTao: Dice Beast Protocol - 交接包

**生成时间**: 2026-04-02
**当前版本**: v0.1.105
**分支**: `codex/dice-beast-protocol`

---

## 1. 此刻的精确状态（一句话）

v0.1.105 已完成核心交接文档的重写与同步，当前接手入口清晰可靠；项目主体仍是稳定可玩的双层原型，下一步重点是结构整理与内容扩展。

---

## 2. 最近完成的工作

| 版本 | 任务 | 状态 |
|------|------|------|
| v0.1.101 | 2D 选中单位持续居中跟随，强化外场区分 | 完成 |
| v0.1.102 | 增加棋盘外背景装饰画面 | 完成 |
| v0.1.103 | 外场固定边框台座与四角结构件，取消自动回正 | 完成 |
| v0.1.104 | 核心日志保守编码修复；同步最新接手基线 | 完成 |
| v0.1.105 | 重写 `AI Guide`、`Art Strategy`、`Snapshot v3`，并清理最新交接路径 | 完成 |

---

## 3. 当前真实结构

- 入口：`Project/Scenes/Main.tscn`
- 主控入口：`Project/Scripts/Main.gd`
- 棋盘外层：`Project/Scripts/BattleV2/BattleFlowController.gd`
- 卡牌内层：`Project/Scripts/BattleV2/CardBattleController.gd`
- 2D 视图：`Project/Scripts/UI/BoardView.gd`
- 3D 视图：`Project/Scripts/UI3D/BoardView3D.gd`
- 商店 UI：`Project/Scripts/UI/ShopPanel.gd`
- 结构快照：`Logs/CyberTao_Migration_Snapshot_zh_v3.md`

---

## 4. 本轮已处理的接手风险

- `AI_Employee_Guide_v3.md` 已重写为干净中文版本，不再依赖残缺正文。
- `Art_Beautification_Strategy_zh.md` 已改为当前基线策略文档，不再停留在 v0.1.44 阶段。
- `CyberTao_Migration_Snapshot_zh_v3.md` 已同步到当前版本，不再只靠顶部警告提示“正文过时”。
- 最新接手路径已经统一为 `Guide / Handoff / Work Report / changelog / Snapshot`。

---

## 5. 当前仍需继续关注的风险

| 问题 | 严重程度 | 是否阻塞 | 说明 |
|------|----------|----------|------|
| `Main.gd` 入口层持续膨胀 | 中 | 否 | 已是 700+ 行协调层，继续堆功能会提高联调成本 |
| 2D / 3D 表现一致性仍在追赶 | 中 | 否 | 3D 已可玩，但反馈和可读性尚未完全追平 2D |
| 次级玩家单位尚未接入主流程 | 中 | 否 | `hacker_fox`、`crow_caster` 资源已在，当前主循环仍只生成 `blade_shield_dog` |
| 更早历史日志仍有归档级编码遗留 | 低 | 否 | 不影响当前接手主路径，但后续若要做历史整理仍需单独处理 |

---

## 6. 下一步建议

1. 把 `Main.gd` 中纯连接、纯转发、纯表现触发逻辑继续往独立协调层收拢。
2. 把第二个可玩单位真正接进主流程，补足阵营差异而不是只保留资源文件。
3. 若继续做表现层，优先补 2D / 3D 反馈统一，而不是继续堆外场装饰。
