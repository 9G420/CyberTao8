# CyberTao: Battle Rebirth - Session Handoff & Memory Capsule

> **TO THE NEXT AI ASSISTANT**: Read this file to immediately synchronize with the project's current architectural overhaul.

---

## 1. 当前上下文 (Context Snapshot)
*   **项目阶段**: 战斗机制彻底重构期 (Re-design Phase).
*   **当前痛点**: 棋盘移动与卡牌战斗割裂，缺乏爽感，策略层级浅。
*   **已定稿方案**: 《逻辑位元·符咒指令合成系统 (v1.2)》.
*   **核心理念**: 取消传统移动消耗，改为“指令链”模式。将卡牌作为“逻辑补丁”挂载到指令块上，通过棋盘走位触发“八卦共鸣”。

---

## 2. 关键参考文件 (Must Read)
1.  `Logs/CyberTao_Battle_Rebirth_Scheme_v1.md`: 核心设计理念。
2.  `Logs/CyberTao_Full_Implementation_Blueprint_v1.2.md`: **最详细的 Codex 执行蓝图**（包含数据模型、任务拆解、技术提示）。

---

## 3. 核心架构逻辑 (Architectural DNA)
*   **指令链**: `[Move] -> [Turn] -> [Attack]` (由骰子面生成).
*   **卡牌作用**: 挂载到上述指令块上的装饰器 (Decorator), 如 `Attack + [Fire Card]`.
*   **共鸣引擎**: 检测 `(Unit Position.Bagua_Attribute) + (Command.Card_Attribute)`。

---

## 4. 下一步执行计划 (Next Steps for Codex)
1.  **Phase 1**: 实现 `CommandQueue` 与 `SequenceExecutor`（物理指令的顺序执行与 Tween 动画同步）。
2.  **Phase 2**: 实现 UI 指令槽位与卡牌的“拖拽挂载”逻辑。
3.  **Phase 3**: 编写“鬼影路径”预览算法。

---

## 5. 唤醒指令 (Wake-up Prompt for Next Session)
**直接复制以下内容发送给新的 AI：**

> "你好，我是 CyberTao 的开发者。我们正在进行战斗系统的深度重构（Battle Rebirth v1.2）。请立即阅读 `Logs/SESSION_CONTINUE_BATTLE_REBIRTH.md` 和 `Logs/CyberTao_Full_Implementation_Blueprint_v1.2.md` 以同步当前进度。同步完成后，请告诉我你对 `SequenceExecutor.gd`（指令执行器）的初步实现思路，我们将开始 Phase 1 的代码编写。"

---

**存档时间**: 2026-04-04
**存档状态**: 策略定稿，待进入 Phase 1 开发。
