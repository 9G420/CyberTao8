# CyberTao 机制重构主计划（方案A）

**更新时间**: 2026-04-05 00:31 SGT  
**状态**: 执行中（Bridge 阶段已落地）  
**适用分支**: `codex/dice-beast-protocol`

---

## 1. 重构目标（不推倒）

采用“渐进式重构（方案A）”：

1. 先保留当前可玩循环（棋盘+遭遇+卡牌）。  
2. 再用桥接层把玩家动作统一到命令链入口。  
3. 最后逐步替换为路径闭环共鸣、补丁卡与骰面改写。

禁止一次性大推翻，必须每一轮都可运行、可测试、可回归。

---

## 2. 当前完成状态

### A1（已完成）
- 敌方意图连线已上线（`ATK/MOV` 可视化）。

### Bridge-1（已完成，待持续扩展）
- 已新增：
  - `Project/Scripts/Core/Command.gd`
  - `Project/Scripts/Core/CommandChain.gd`
  - `Project/Scripts/Core/CommandExecutor.gd`
- 已接入：
  - `BattleFlowController` 新增命令链接口：
    - `enqueue_player_command`
    - `execute_player_command_chain`
    - `execute_single_player_command`
    - `reset_player_command_chain`
- 主输入链路已改走命令执行器：
  - `Main.gd`（移动/攻击/召唤）
  - `DiceDebugPanel.gd`（召唤/护持/术式/机巧）

---

## 3. 当前最优先三任务

1. `A2_path_loop_resonance`  
先做“最小闭环共鸣”：满足闭环条件时给团队一个清晰增益（先做 1 条规则）。

2. `A3_enemy_counterplay`  
敌方加入“断环/守点”优先级，防止玩家闭环无脑滚雪球。

3. `A4_patch_card_bridge`  
把现有卡牌逐步映射为 `LogicPatch`（先支持对 `move/attack/defend` 三类命令的补丁挂载）。

---

## 4. 当前禁止做的事

- 不做“一次性全系统重写”。
- 不在同一轮同时重做玩法核心 + 全 UI 重画。
- 不引入新机制但不写日志（会导致接手失败）。
- 不为了重构洁癖打断当前可玩闭环。

---

## 5. 每轮验收标准（重构专用）

- `godot4 --headless --path Project --quit` 必须通过。
- 棋盘移动/攻击/召唤必须可用。
- 遭遇进出与回合推进不能退化。
- 本文件 + 执行中枢 + changelog 必须同步时间与版本。
# 机制重构主计划（方案A）- 清晰口径

**更新时间**: 2026-04-05 00:42 SGT  
**当前状态**: Bridge-1 已完成，正在执行 A2  
**唯一方向**: 渐进式重构（先桥接、再闭环、再补丁）

> 说明：如果本文件后续历史段落出现旧内容或乱码，本段为最高优先口径。

## 当前唯一主任务
1. `A2_path_loop_resonance`

## A2 目标
- 实现“路径闭环共鸣”最小规则（先 1 条稳定规则）。
- 闭环触发后给玩家可感知增益。
- 2D 至少提供明确可视反馈。

## 后续排队任务
1. `A3_enemy_counterplay`
2. `A4_patch_card_bridge`

## 禁止事项
- 禁止推倒式重写。
- 禁止同轮玩法重构 + 全UI重绘。
- 禁止不写日志直接改机制。

