# CyberTao: Dice Beast Protocol — 交接包

**生成时间**: 2026-04-01
**当前版本**: v0.1.76
**分支**: codex/dice-beast-protocol

---

## 1. 此刻的精确状态（一句话）

v0.1.76 完成 BattleFlowController 瘦身：多层地图逻辑（HP 快照/复活/回复、Boss 解锁/传送、传送门生成/检测）剥离为 FloorManager 独立类，BFC 从 881 行减至 791 行。3D 反馈系统（v0.1.74）、跨层复活/回复（v0.1.75）和商店面板（v0.1.73）均稳定。下一步是 3D 单位精灵化或商品池扩展。

---

## 2. 本账号完成的工作

| 版本 | 任务 | 状态 |
|------|------|------|
| v0.1.74 | 3D 反馈系统实现（9个桩函数→完整3D特效） | 完成 |
| v0.1.75 | 阵亡单位跨层复活 + 存活单位跨层回复 | 完成 |
| v0.1.76 | BFC 瘦身：FloorManager 独立类 | 完成 |

---

## 3. 最后版本关键变更

**版本号**: v0.1.76

**修改文件**:
- `Scripts/BattleV2/FloorManager.gd` — 新增文件（~162 行），多层地图逻辑独立类
- `Scripts/BattleV2/BattleFlowController.gd` — 移除多层地图相关常量/变量/方法，改为委托 FloorManager；881→791 行
- `Scripts/UI/DiceDebugPanel.gd` — 版本标记 → v0.1.76

**新增文件**:
- `Scripts/BattleV2/FloorManager.gd`（`class_name FloorManager`）— 多层地图管理器

**无公开接口变更**：所有外部信号/方法签名不变，Main.gd 无需修改

**遗留问题**:
- 3D 单位使用简单几何体（v0.1.71 遗留）
- DiceDebugPanel 仍绑定 2D BoardView（v0.1.71 遗留）
- spritesheet 背景透明度（v0.1.70 遗留）
- 复活/回复数值未经平衡测试

---

## 4. 下一步任务（精确到可以直接开始）

**立刻要做的**:
根据用户指派的任务方向选择：
- 3D 单位精灵化：在 `Scripts/UI3D/UnitMeshFactory3D.gd` 中将 CapsuleMesh/CylinderMesh 替换为 billboard Sprite3D 或低多边形模型
- 商品池扩展：在 `Scripts/UI/ShopPanel.gd` 和 `Scripts/BattleV2/CellEffectHandler.gd` 中添加新商品类型

**任务队列**:
1. 3D 单位精灵化
2. 商品池扩展（加新牌/移除诅咒/随机 crest 等）
3. 卡牌战斗层深化

---

## 5. 当前未解决问题清单

| 问题 | 严重程度 | 是否阻塞 | 建议处理时机 |
|------|----------|----------|--------------|
| 3D 单位为简单几何体 | 低 | 否 | 3D 迭代 P2 |
| DiceDebugPanel 绑定 2D BoardView | 低 | 否 | 3D 完善轮次 |
| spritesheet 背景透明度待确认 | 中 | 否 | 用户测试后处理 |
| CardRewardPanel 未使用 CardRenderer 风格 | 低 | 否 | UI 统一轮次 |
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

- v0.1.76 的 FloorManager 使用 `class_name FloorManager` 全局注册，BFC 中通过 `const _FloorManager = preload(...)` 引用
- FloorManager 的外部依赖由 BFC._bootstrap() 注入，不需要手动初始化
- FloorManager 返回数据（字典/数组），BFC 负责发射信号和管理阶段转换
- `advance_floor()` 接受 `summon_counter_reset: Callable` 参数重置 BFC 的召唤计数器
- v0.1.75 的复活/回复常量（`REVIVE_HP_RATIO`/`FLOOR_HEAL_RATIO`）现在在 FloorManager 中，调整数值改那里即可
- 召唤伙伴（tag "summoned"）仍不参与跨层复活（设计意图不变）
- v0.1.74 的 3D 反馈系统详见上一版交接包备注
