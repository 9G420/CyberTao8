# CyberTao 执行指挥中心（Execution Command Center）

**更新时间**: 2026-04-04 20:56 SGT  
**当前版本**: v0.1.116  
**目标**: 让任意新对话窗口都能在 1 分钟内接手，不再“每次重讲一遍”。

---

## 0. 使用规则（强制）

每次新对话开始，Codex 必须先读取本文件，并在第一条执行回复里输出：

1. 当前阶段（来自第 1 节）
2. 本轮要执行的唯一主任务（来自第 2 节第 1 项）
3. 本轮验收标准（来自第 3 节）
4. 本轮禁止事项（来自第 4 节）

如果本文件与其他日志冲突，以本文件为“本轮执行口径”，并在 `Mulerun_Work_Report` 记录冲突处理。

---

## 1. 当前推进阶段（只保留一个）

**阶段名**: 战棋战斗“可玩性强化”阶段（Phase A）  
**阶段目标**: 让棋盘层从“功能测试感”升级为“可规划、可反制、可连招”的策略层。  
**阶段完成判定**:

- 敌方意图可视化（玩家能看懂敌方下一步）
- 玩家有至少 2 种“打断敌方意图”的手段
- 路径/据点/召唤三者形成稳定收益循环
- 单局测试时，玩家能描述出“这回合为何这样走位”

---

## 2. 当前最优先任务（严格按序）

1. **敌方意图连线系统（首要）**
   - 显示敌方下一步攻击或争夺目标
   - 玩家可通过走位/占位/击杀打断
2. **路径闭环共鸣**
   - 当玩家路径形成闭环时触发团队增益
   - 先做一条简单规则，避免一次做复杂
3. **召唤单位可控性补齐**
   - 允许召唤单位执行基础移动（不触发剧情类格子）
   - 明确它们是“控点工具”而不是主角替代

---

## 3. 本轮验收标准模板（每轮都要填）

> 执行任务前复制本模板到 `Mulerun_Work_Report` 的“本轮任务”章节并填写

- 任务名称:
- 用户可感知变化:
- 功能验收:
  - [ ] 战斗内能稳定触发
  - [ ] 不破坏既有流程（掷骰/行动/敌回合/遭遇）
  - [ ] 2D 与 3D 视图至少保证 2D 完整可用
- 回归点:
  - [ ] 单位选择/移动/攻击正常
  - [ ] 召唤与 crest 消耗正常
  - [ ] 遭遇进出正常

---

## 4. 当前禁止做的事（防跑偏）

- 不做整套“完全推翻式”重构（例如一次性改成全新算符系统）
- 不在同一轮同时改玩法核心 + 全套 UI 重画
- 不引入新系统但不补日志
- 不为了“更优雅”破坏当前可玩闭环

---

## 5. 每轮结束必须更新的文件

- `Logs/Handoff_Package_latest.md`
- `Logs/Mulerun_Work_Report.md`
- `Logs/changelog_v0.1.md`
- 本文件 `Logs/Execution_Command_Center.md`（至少更新时间 + 当前最优先任务状态）

---

## 6. 下一轮建议直接执行的任务卡

**任务卡 ID**: `A2_path_loop_resonance`  
**一句话**: 实装“路径闭环共鸣”最小规则，让玩家通过闭环走位获得可感知增益。 
**建议改动文件**:

- `Project/Scripts/BattleV2/BattleFlowController.gd`
- `Project/Scripts/BattleV2/BoardManager.gd`
- `Project/Scripts/UI/BoardView.gd`

**完成定义**:

- 玩家回合与敌方回合都能看到敌方下一意图
- 当玩家打断条件成立时，意图线消失或切换目标
- 无头启动通过（`godot --headless --quit`）

---

## 7. 维护说明

本文件是“执行导航仪”，不是历史档案。  
历史细节去 `changelog` / `work report` 查；本文件只保留“现在该做什么”。
## 8. v0.1.117 接管口径（覆盖旧条目）

- 更新时间: `2026-04-05 00:31 SGT`
- 当前阶段: `Phase A - 渐进式机制重构（方案A）`
- 当前版本口径: `v0.1.117-dev`（本地重构进行中）
- 必读新增文件: `Logs/Mechanic_Refactor_Plan_A.md`

### 本轮主任务（唯一）
1. 执行 `A2_path_loop_resonance`，完成“路径闭环共鸣”最小可玩规则。

### 本轮验收标准
- 闭环触发时出现可感知增益与可视反馈。
- 不破坏现有移动/攻击/召唤与遭遇流程。
- `godot4 --headless --path Project --quit` 通过。

### 本轮禁止事项
- 禁止推倒式重构。
- 禁止同轮重做玩法核心 + 全UI重绘。
- 禁止改了机制不补日志。

### 本轮后续必须同步
- `Logs/Mechanic_Refactor_Plan_A.md`
- `Logs/Handoff_Package_latest.md`
- `Logs/Mulerun_Work_Report.md`
- `Logs/changelog_v0.1.md`
- `Logs/CyberTao_Migration_Snapshot_zh_v3.md`
## 9. 重构会话必读顺序（v0.1.117-dev）
1. `Logs/Execution_Command_Center.md`（先看第8节覆盖口径）
2. `Logs/Mechanic_Refactor_Plan_A.md`
3. `Logs/Handoff_Package_latest.md`
4. `Logs/Mulerun_Work_Report.md`（优先看覆盖报告）
5. `Logs/changelog_v0.1.md`（最近两条）
# Execution Command Center (Refactor Override)

**更新时间**: 2026-04-05 00:42 SGT  
**当前版本口径**: v0.1.117-dev  
**执行模式**: 方案A（渐进式重构，禁止推倒重来）

> 重要：本文件中若出现旧条目与本段冲突，以本段为唯一执行口径。旧条目仅作历史归档，不再执行。

## 当前阶段
- Phase A：机制重构桥接阶段（Bridge）

## 当前最优先任务（唯一）
1. `A2_path_loop_resonance`

## A2 任务定义
- 在现有棋盘规则上实现“最小闭环共鸣”。
- 触发条件先做一条：玩家路径形成闭环后给予一次团队增益（先做简单稳定版）。
- 必须有可视反馈（2D 至少可见）。

## A2 验收标准
- 闭环能稳定触发。
- 不破坏现有移动/攻击/召唤/遭遇流程。
- `godot4 --headless --path Project --quit` 通过。

## 当前禁止事项
- 禁止一次性大重构替换全部战斗系统。
- 禁止同轮重做玩法核心 + 全UI重绘。
- 禁止改机制不写日志。

## 新对话必读顺序
1. `Logs/Execution_Command_Center.md`（本覆盖段）
2. `Logs/Mechanic_Refactor_Plan_A.md`
3. `Logs/Handoff_Package_latest.md`
4. `Logs/Mulerun_Work_Report.md`（看“覆盖报告”）
5. `Logs/changelog_v0.1.md`（最近两条）
