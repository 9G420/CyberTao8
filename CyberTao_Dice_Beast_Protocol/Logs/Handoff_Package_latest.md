# CyberTao: Dice Beast Protocol — 交接包

**生成时间**: 2026-04-01
**当前版本**: v0.1.75
**分支**: codex/dice-beast-protocol

---

## 1. 此刻的精确状态（一句话）

v0.1.75 完成阵亡单位跨层复活 + 存活单位跨层回复：进入下一层时，阵亡永久单位以 50% max_hp 复活，存活单位额外回复 30% max_hp。3D 反馈系统（v0.1.74）和商店面板（v0.1.73）均已稳定。下一步是 BFC 瘦身或 3D 单位精灵化。

---

## 2. 本账号完成的工作

| 版本 | 任务 | 状态 |
|------|------|------|
| v0.1.74 | 3D 反馈系统实现（9个桩函数→完整3D特效） | 完成 |
| v0.1.75 | 阵亡单位跨层复活 + 存活单位跨层回复 | 完成 |

---

## 3. 最后版本关键变更

**版本号**: v0.1.75

**修改文件**:
- `Scripts/BattleV2/BattleFlowController.gd` — 新增 `REVIVE_HP_RATIO`/`FLOOR_HEAL_RATIO` 常量；重写 `_spawn_player_units_with_hp()`（阵亡复活+存活回复）
- `Scripts/UI/DiceDebugPanel.gd` — 版本标记 → v0.1.75

**新增常量**:
- `REVIVE_HP_RATIO: float = 0.5` — 阵亡复活 HP 比例
- `FLOOR_HEAL_RATIO: float = 0.3` — 存活跨层回复比例

**无公开接口变更**：内部方法逻辑变更，外部信号/方法签名不变

**遗留问题**:
- 3D 单位使用简单几何体（v0.1.71 遗留）
- DiceDebugPanel 仍绑定 2D BoardView（v0.1.71 遗留）
- spritesheet 背景透明度（v0.1.70 遗留）
- BattleFlowController ~695 行
- 复活/回复数值未经平衡测试

---

## 4. 下一步任务（精确到可以直接开始）

**立刻要做的**:
根据用户指派的任务方向选择：
- BattleFlowController 瘦身：将多层地图逻辑（advance_to_next_floor + HP 快照 + Boss 解锁）剥离为 FloorManager 独立类
- 3D 单位精灵化：billboard sprite 或低多边形模型替代 CapsuleMesh/CylinderMesh

**任务队列**:
1. BattleFlowController 瘦身（当前约 695 行）
2. 3D 单位精灵化
3. 商品池扩展（加新牌/移除诅咒/随机 crest 等）

---

## 5. 当前未解决问题清单

| 问题 | 严重程度 | 是否阻塞 | 建议处理时机 |
|------|----------|----------|--------------|
| 3D 单位为简单几何体 | 低 | 否 | 3D 迭代 P2 |
| DiceDebugPanel 绑定 2D BoardView | 低 | 否 | 3D 完善轮次 |
| spritesheet 背景透明度待确认 | 中 | 否 | 用户测试后处理 |
| CardRewardPanel 未使用 CardRenderer 风格 | 低 | 否 | UI 统一轮次 |
| BattleFlowController ~695行 | 中 | 否 | 下次大功能前 |
| 商店 ATK/DEF 提升未走 BuffManager | 低 | 否 | 如需回合限制时改 |
| BoardView3D.rebuild_board() 全量重建 | 低 | 否 | 3D 优化轮次 |
| 复活/回复数值未经平衡测试 | 低 | 否 | 数值调优轮次 |

---

## 6. 新账号启动指令

```bash
git clone https://github.com/9G420/CyberTao8.git
cd CyberTao8
git checkout codex/dice-beast-protocol
git pull origin codex/dice-beast-protocol
```

然后按顺序阅读：
1. `Logs/AI_Employee_Guide_v3.md`（本上岗指令）
2. 本文件（已在读）
3. `Logs/CyberTao_Migration_Snapshot_zh_v3.md`
4. `Logs/Mulerun_Work_Report.md`

读完输出【上岗确认】，等用户确认后再开始工作。

---

## 7. 给下一个账号的备注

- v0.1.75 跨层复活/回复由 `REVIVE_HP_RATIO` 和 `FLOOR_HEAL_RATIO` 两个 const 控制，调整数值只需改常量
- 复活逻辑在 `_spawn_player_units_with_hp()` 中：不在 HP 快照中的单位 = 阵亡 → 以 REVIVE_HP_RATIO * max_hp 复活
- 存活单位额外回复在同一方法中：HP + ceil(max_hp * FLOOR_HEAL_RATIO)，上限 max_hp
- 召唤伙伴（tag "summoned"）不在 spawn_data 列表中，跨层时自然消失，不参与复活
- 当前只有 blade_shield_dog 一个永久单位，英雄阵亡 = DEFEAT，所以复活逻辑暂不实际触发；但多永久单位场景已预留
- `_snapshot_player_hp()` 新增 `alive: true` 字段是向前兼容预留，当前未使用
- v0.1.74 的 3D 反馈系统详见上一版交接包备注
