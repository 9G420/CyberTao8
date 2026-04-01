# Mulerun 工作报告

**日期**: 2026-04-01
**版本**: v0.1.75
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.75：阵亡单位跨层复活机制 + 存活单位跨层回复

---

## 根因目标

v0.1.42 引入多层地图后，存活单位 HP 跨层保留，但阵亡单位永久消失（`_spawn_player_units_with_hp` 跳过不在 HP 快照中的单位）。当前只有 1 个永久单位（刀盾狗/英雄），英雄阵亡即 DEFEAT，所以阵亡复活尚未实际触发。但存活单位可能以极低 HP 进入后续层（"死亡螺旋"），且机制未为未来多永久单位场景做准备。本轮实现：阵亡复活（50% HP）+ 存活回复（+30% HP），同时为未来扩展多永久单位预留。

服务层：棋盘走位层（多层地图数值调优）

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/BattleV2/BattleFlowController.gd` | 新增 `REVIVE_HP_RATIO`/`FLOOR_HEAL_RATIO` 常量；重写 `_spawn_player_units_with_hp()`（阵亡复活+存活回复）；`_snapshot_player_hp()` 追加 `alive` 字段 |
| `Scripts/UI/DiceDebugPanel.gd` | 版本标记 v0.1.74 → v0.1.75 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.75 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号 + §2.2/§5/§6 更新 |

---

## 实现内容

### 跨层复活与回复机制

**进入下一层时的 HP 计算规则**：

| 单位状态 | HP 计算 | 示例（max_hp=8） |
|----------|---------|-------------------|
| 存活（HP > 0） | 保留 HP + 回复 30% max_hp（不超过 max_hp） | HP=2 → 2+3=5；HP=7 → 7+3→上限8 |
| 阵亡（HP ≤ 0 / 不在快照中） | 复活，HP = 50% max_hp（向上取整，至少 1） | max_hp=8 → HP=4；max_hp=1 → HP=1 |

**常量**：
- `REVIVE_HP_RATIO = 0.5` — 复活 HP 比例
- `FLOOR_HEAL_RATIO = 0.3` — 存活跨层回复比例

**设计取舍**：
- 召唤伙伴（tagged "summoned"）仍为层内临时单位，不参与跨层复活（设计意图：召唤是战术资源，不是永久伙伴）
- 复活比例 50% 选择理由：太低（如 25%）复活后立刻阵亡，太高（如 100%）失去惩罚意义
- 跨层回复 30% 选择理由：3 层推进中，英雄以 50% HP 进入下层时可回到 80%，不至于满血但也不至于太脆弱
- 数值未经平衡测试，后续可直接修改常量调整

---

## 接口变更

- **无新增/删除公开接口**
- **新增常量**：`REVIVE_HP_RATIO: float = 0.5`、`FLOOR_HEAL_RATIO: float = 0.3`
- **修改内部方法**：`_spawn_player_units_with_hp()` 逻辑变更（不再跳过阵亡单位）
- **修改内部方法**：`_snapshot_player_hp()` 字典新增 `alive: true` 字段（向前兼容）

---

## 测试确认

### 自查闭环（代码审查）

| 测试项 | 结果 |
|--------|------|
| 掷骰 → 移动 → 攻击 → 召唤 | ✅ 不涉及本次修改 |
| 敌方回合 → 镜头跟随 | ✅ 不涉及 |
| 遭遇触发 → 卡牌战斗 → 选牌奖励 → HP同步回棋盘 | ✅ 不涉及 |
| 重新开始（restart_battle） | ✅ 不调用 _spawn_player_units_with_hp，走 _spawn_player_units 全新生成 |
| 胜负判定 | ✅ 不涉及 |
| 跨层 HP 保留 + 回复 | ✅ 存活单位 HP + ceil(max_hp * 0.3)，clamp 到 max_hp |
| 阵亡单位复活 | ✅ 不在快照中的单位以 ceil(max_hp * 0.5) HP 生成 |
| 召唤伙伴跨层消失 | ✅ 召唤单位不在 spawn_data 列表中，不会被重新生成 |
| 多永久单位场景 | ✅ spawn_data 为 Array，可扩展追加更多永久单位 |

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

1. BattleFlowController 瘦身（当前约 695 行）
2. 3D 单位精灵化（billboard sprite 或低多边形模型）
3. 商品池扩展（加新牌/移除诅咒/随机 crest 等）

## Codex 复审标注（可选）

- REVIVE_HP_RATIO 和 FLOOR_HEAL_RATIO 为 const，调整数值只需改这两个常量，无需修改逻辑代码。
- 当前只有 1 个永久单位（blade_shield_dog），英雄阵亡会触发 DEFEAT（不会走到 advance_to_next_floor），所以复活逻辑暂时不会在实际游戏中触发。但机制已为未来多永久单位场景（如增加第二个永久伙伴）预留。
- 跨层回复是"进入下一层"时的一次性回复，不是每回合回复，不会破坏层内战斗平衡。
