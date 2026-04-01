# Mulerun 工作报告

**日期**: 2026-04-01
**版本**: v0.1.76
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.76：BattleFlowController 瘦身 — 将多层地图逻辑剥离为 FloorManager 独立类

---

## 根因目标

BattleFlowController 在 v0.1.75 后增长至 881 行，包含大量多层地图逻辑（HP 快照/复活/回复、Boss 解锁/传送、传送门生成/检测、层间推进）。这些逻辑与 BFC 核心的回合流程/战斗结算职责正交，适合剥离为独立管理器。本轮将这些逻辑提取为 `FloorManager` 类，BFC 保留信号发射和阶段管理的薄代理，减少 ~90 行至 791 行。

服务层：棋盘走位层（架构优化）

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/BattleV2/FloorManager.gd` | 新增文件（~162 行），从 BFC 提取多层地图逻辑：HP 快照/复活/回复、Boss 解锁/传送、传送门生成/检测、层间推进 |
| `Scripts/BattleV2/BattleFlowController.gd` | 移除 `MAX_FLOOR`/`REVIVE_HP_RATIO`/`FLOOR_HEAL_RATIO` 常量和 `current_floor` 变量；新增 `floor_manager` 实例；`_try_unlock_boss()`/`_warp_hero_to_boss()`/`_spawn_portal_near()`/`_check_portal()`/`advance_to_next_floor()`/`get_current_floor()`/`get_max_floor()` 改为委托 FloorManager；移除 `_snapshot_player_hp()`/`_spawn_player_units_with_hp()`；`restart_battle()` 改用 `floor_manager.reset_floor()` |
| `Scripts/UI/DiceDebugPanel.gd` | 版本标记 v0.1.75 → v0.1.76 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.76 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号 + §2.2/§3.1/§5/§6 更新 |
| `Logs/Handoff_Package_latest.md` | 覆盖为 v0.1.76 交接包 |

---

## 实现内容

### FloorManager 独立类

**提取的职责**：
- 层间推进（`advance_floor()`）：HP 快照 → 清理 → 递增层数 → 重生单位 → 生成新棋盘
- HP 快照/复活/回复（`snapshot_player_hp()` + `_spawn_player_units_with_hp()`）
- Boss 解锁（`try_unlock_boss()`）
- 英雄传送到 Boss 旁（`warp_hero_to_boss()`）
- 传送门生成（`spawn_portal_near()`）
- 传送门检测（`check_portal()`）
- 层数管理（`get_current_floor()`/`get_max_floor()`/`reset_floor()`）

**设计取舍**：
- FloorManager 返回数据（字典/数组），不直接发射信号 — BFC 保留信号发射权，避免暴露 FloorManager 给 Main
- FloorManager 的外部依赖（dice_manager/board_manager/unit_manager/buff_manager）由 BFC._bootstrap() 注入
- 召唤计数器重置通过 Callable 传入 FloorManager.advance_floor()，避免 FloorManager 持有对 BFC 内部变量的引用
- 常量 `MAX_FLOOR`/`REVIVE_HP_RATIO`/`FLOOR_HEAL_RATIO` 移至 FloorManager，BFC 不再持有这些值

**行数变化**：BFC 从 881 行减至 791 行（-90 行），FloorManager 162 行

---

## 接口变更

- **新增文件**：`Scripts/BattleV2/FloorManager.gd`（`class_name FloorManager`）
- **新增 BFC 成员变量**：`var floor_manager: _FloorManager`
- **移除 BFC 常量**：`MAX_FLOOR`、`REVIVE_HP_RATIO`、`FLOOR_HEAL_RATIO`（移至 FloorManager）
- **移除 BFC 变量**：`current_floor`（移至 FloorManager）
- **移除 BFC 方法**：`_snapshot_player_hp()`、`_spawn_player_units_with_hp()`（移至 FloorManager）
- **方法签名不变**：`advance_to_next_floor()`、`get_current_floor()`、`get_max_floor()` 保留签名，内部委托 FloorManager
- **无信号变更**：所有外部信号接口不变

---

## 测试确认

### 自查闭环（代码审查）

| 测试项 | 结果 |
|--------|------|
| 掷骰 → 移动 → 攻击 → 召唤 | ✅ 不涉及本次修改 |
| 敌方回合 → 镜头跟随 | ✅ 不涉及 |
| 遭遇触发 → 卡牌战斗 → 选牌奖励 → HP同步回棋盘 | ✅ 不涉及 |
| 重新开始（restart_battle） | ✅ 调用 floor_manager.reset_floor() 替代 current_floor = 1 |
| 胜负判定 | ✅ _check_battle_outcome() 通过 floor_manager.current_floor 和 floor_manager.get_max_floor() 判定 |
| 跨层 HP 保留 + 回复 | ✅ 逻辑已移至 FloorManager，行为不变 |
| 阵亡单位复活 | ✅ 逻辑已移至 FloorManager，行为不变 |
| Boss 解锁 + 传送 | ✅ _try_unlock_boss()/_warp_hero_to_boss() 委托 FloorManager + BFC 发信号 |
| 传送门生成 + 检测 | ✅ _spawn_portal_near()/_check_portal() 委托 FloorManager + BFC 发信号/切阶段 |
| resolve_encounter → Boss 击败 → 传送门 | ✅ resolve_encounter() 调用 _spawn_portal_near()（内部委托 FloorManager） |

---

## 剩余问题

- 3D 单位仍为简单几何体（v0.1.71 遗留）
- DiceDebugPanel 仍绑定 2D BoardView（v0.1.71 遗留）
- spritesheet 背景透明度（v0.1.70 遗留）
- ATK/DEF 商店提升未走 BuffManager（v0.1.73 设计取舍）
- BoardView3D.rebuild_board() 全量重建（大棋盘性能开销）
- 复活/回复数值未经平衡测试

---

## 建议下一步

1. 3D 单位精灵化（billboard sprite 或低多边形模型）
2. 商品池扩展（加新牌/移除诅咒/随机 crest 等）
3. 卡牌战斗层深化（新卡牌效果/新敌方行为模式）

## Codex 复审标注（可选）

- FloorManager 使用 `class_name FloorManager` 全局注册，BFC 中通过 `const _FloorManager = preload(...)` 引用并实例化。两种方式都可访问，但 BFC 内部统一用 preload 常量。
- `advance_floor()` 接受 `summon_counter_reset: Callable` 参数是为了避免 FloorManager 直接访问 BFC 的 `_summon_counter`/`_summon_this_floor` 内部变量。如果未来有更多 BFC 内部状态需要在层间重置，可考虑将其封装为更通用的 reset Callable 或信号。
- BFC 行数从 881 降至 791（-90 行），FloorManager 162 行。净增 72 行代码（FloorManager 包含必要的方法签名和文档注释）。这是典型的"拆分增加总代码量但降低单文件复杂度"的取舍。
