# CyberTao: Dice Beast Protocol — 交接包

**生成时间**: 2026-04-01
**当前版本**: v0.1.73
**分支**: codex/dice-beast-protocol

---

## 1. 此刻的精确状态（一句话）

v0.1.73 完成商店格扩展：新增独立 ShopPanel UI 面板（5种商品池随机3选，使用 crest 资源购买，支持多次购买），替代旧版自动回复机制。信号链从 `shop_cell_triggered`（自动购买）重构为 `shop_panel_requested`（打开面板）。3D 渐进迁移 P0+交互修复均已完成。下一步是 3D 反馈系统或阵亡单位跨层复活。

---

## 2. 本账号完成的工作

| 版本 | 任务 | 状态 |
|------|------|------|
| v0.1.73 | 商店格扩展（ShopPanel独立面板+5种商品池+crest货币+多次购买） | 完成 |

---

## 3. 最后版本关键变更

**版本号**: v0.1.73

**新增文件**:
- `Scripts/UI/ShopPanel.gd` — 独立商店 UI 面板（~240行，class_name ShopPanel），5种商品池随机3选，crest 支付，CyberStyle 风格化

**修改文件**:
- `Scripts/BattleV2/CellEffectHandler.gd` — 删除 `check_shop_cell()`，新增 `has_valid_shop_cell()`（纯校验，不自动购买）
- `Scripts/BattleV2/BattleFlowController.gd` — 信号 `shop_cell_triggered` → `shop_panel_requested`，`_check_shop_cell` 改为仅发信号
- `Scripts/Main.gd` — 新增 ShopPanel 导入/实例化/信号连接 + `_on_shop_panel_requested`/`_on_shop_closed` 回调
- `Scripts/UI/DiceDebugPanel.gd` — 版本标记 → v0.1.73 + 信号绑定更新

**新增接口**:
- `ShopPanel.open_shop(unit_id, dice_mgr, unit_mgr, card_battle_ctrl)` — 打开商店面板
- `ShopPanel.shop_closed` 信号 — 面板关闭时发射
- `CellEffectHandler.has_valid_shop_cell(unit_id, cell) -> bool` — 检查商店格存在+玩家身份
- `BFC.shop_panel_requested(unit_id, cell)` 信号 — 替代旧 `shop_cell_triggered`

**删除接口**:
- `CellEffectHandler.check_shop_cell()` — 旧的自动购买方法
- `BFC.shop_cell_triggered` 信号 — 旧信号（grep 确认零引用）

**遗留问题**:
- 3D 反馈方法（攻击闪光/飘字/粒子）暂为桩函数（v0.1.71 遗留）
- 3D 单位使用简单几何体（v0.1.71 遗留）
- DiceDebugPanel 仍绑定 2D BoardView（v0.1.71 遗留）
- spritesheet 背景透明度（v0.1.70 遗留）
- ATK/DEF 商品提升直接改 unit dict（本层永久，跨层重建自动重置），未走 BuffManager

---

## 4. 下一步任务（精确到可以直接开始）

**立刻要做的**:
根据用户指派的任务方向选择：
- 3D 反馈系统实现：在 `Scripts/UI3D/BoardView3D.gd` 中实现 `play_attack_feedback`/`play_heal_feedback` 等桩函数，用 GPUParticles3D 或 Label3D 替代 2D BattleEffects
- 阵亡单位跨层复活机制：在 `BattleFlowController.advance_to_next_floor()` 中添加伙伴复活逻辑

**任务队列**:
1. 3D 反馈系统实现（粒子特效/3D 飘字）
2. 阵亡单位跨层复活机制
3. BattleFlowController 瘦身（当前约 693 行）
4. 商品池扩展（加新牌/移除诅咒/随机 crest 等）

---

## 5. 当前未解决问题清单

| 问题 | 严重程度 | 是否阻塞 | 建议处理时机 |
|------|----------|----------|--------------|
| 3D 反馈方法为桩函数 | 中 | 否 | 3D 迭代 P1 |
| 3D 单位为简单几何体 | 低 | 否 | 3D 迭代 P2 |
| DiceDebugPanel 绑定 2D BoardView | 低 | 否 | 3D 完善轮次 |
| spritesheet 背景透明度待确认 | 中 | 否 | 用户测试后处理 |
| 阵亡单位跨层不复活 | 低 | 否 | 数值调优轮次 |
| CardRewardPanel 未使用 CardRenderer 风格 | 低 | 否 | UI 统一轮次 |
| BattleFlowController ~693行 | 中 | 否 | 下次大功能前 |
| _screen_to_ground() 相机 lerp 未到位时微小偏差 | 低 | 否 | 可接受，暂不处理 |
| 商店 ATK/DEF 提升未走 BuffManager | 低 | 否 | 如需回合限制时改 |

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

- v0.1.73 商店信号链已重构：旧 `shop_cell_triggered`（自动扣资源+回血）已删除，新 `shop_panel_requested`（仅通知打开面板）。如果 grep 到旧信号名说明有遗漏
- ShopPanel 通过 open_shop() 接收 dice_manager/unit_manager/card_battle_ctrl 引用，购买逻辑在面板内部完成，不经过 BFC
- 商品池是 ShopPanel.SHOP_ITEM_POOL（const Array），扩展商品只需在这里追加 + 在 _execute_purchase 中加 match 分支
- ATK/DEF 提升直接改 unit dict 而非走 BuffManager——因为是"本层永久"效果，跨层时 unit 重建自动重置。如果需要回合限制就改走 BuffManager
- 能量核心直接改 CardBattleController.max_energy（该值设计上跨战斗持久），上限卡 5
- _active_view() 返回 Variant（GDScript duck typing），无编译时类型检查，依赖方法名匹配
- BoardView3D 在 SubViewport 中运行，SubViewport 不自动接收父级输入事件，需要 Main._input() 手动转发
- 3D 模式下 DiceDebugPanel.bind_board_view() 仍传入 2D BoardView，如需 3D 适配需额外处理
- BoardView3D.rebuild_board() 是全量重建（清除+重建所有 MeshInstance3D），大棋盘可考虑增量更新
- F5 切换不保留选中状态（切换时不自动同步 selected_unit_id）
