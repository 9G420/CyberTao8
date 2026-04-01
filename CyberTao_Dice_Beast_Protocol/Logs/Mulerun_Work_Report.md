# Mulerun 工作报告

**日期**: 2026-04-01
**版本**: v0.1.73
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.73：商店格扩展（多选商品 + 独立 ShopPanel UI 面板）

---

## 根因目标

v0.1.41 的商店格是自动触发机制：玩家踩上即消耗 1 move crest 回复 3 HP，无选择余地，无 UI 面板，体验单薄。本轮将其扩展为独立商店面板，提供 5 种商品随机 3 选，使用不同 crest 作为货币，增加棋盘层策略深度。

服务层：棋盘走位层（商店格功能扩展）

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/UI/ShopPanel.gd` | **新增文件** ~240行，独立商店 UI 面板（5种商品池/随机3选/crest支付/多次购买/CyberStyle风格化） |
| `Scripts/BattleV2/CellEffectHandler.gd` | `check_shop_cell()` 替换为 `has_valid_shop_cell()`，仅做存在性+玩家身份校验，不再自动购买 |
| `Scripts/BattleV2/BattleFlowController.gd` | 信号 `shop_cell_triggered` → `shop_panel_requested`，`_check_shop_cell` 改为仅发信号 |
| `Scripts/Main.gd` | 新增 ShopPanel 导入/实例化/信号连接 + `_on_shop_panel_requested`/`_on_shop_closed` 回调 |
| `Scripts/UI/DiceDebugPanel.gd` | 版本标记 v0.1.72 → v0.1.73 + 信号绑定 `shop_panel_requested` 替换 `shop_cell_triggered` |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.73 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号 + §2.2/§6 追加条目 |

---

## 实现内容

### 商店面板（ShopPanel.gd）

**商品池（5 种，每次随机展示 3 种）**：

| 商品 | 费用 | 效果 |
|------|------|------|
| 修复药剂 | 步x1 | HP+3 |
| 高级修复 | 步x2 | HP+6 |
| 攻击芯片 | 攻x1 | 本层 ATK+1 |
| 防御芯片 | 盾x1 | 本层 DEF+1 |
| 能量核心 | 术x2 | 最大能量+1（上限5） |

**用户体验**：
- 玩家踩到商店格 → 弹出 ShopPanel（CyberStyle 赛博青色边框）
- 顶部显示当前持有 crest 资源
- 3 个商品横排展示（名称+描述+费用+购买按钮）
- 资源不足或条件不满足时购买按钮灰掉
- 可多次购买不同商品（每次购买后实时刷新按钮状态和 crest 显示）
- 购买反馈文字（成功/失败）
- "离开商店" 按钮关闭面板

**设计取舍**：
- ATK/DEF 提升直接修改 unit dict，不走 BuffManager（因为是"本层永久"效果，不需要倒计时）
- 能量核心直接修改 CardBattleController.max_energy（该值已跨战斗持久）
- 商品池中能量核心在 max_energy>=5 时自动从池中排除
- HP 回复类商品在满血时购买按钮灰掉

### 信号链重构

```
旧流程（v0.1.41~v0.1.72）：
  踩商店格 → CellEffectHandler.check_shop_cell()（自动扣 1 move、自动回复 HP）
  → BFC emit shop_cell_triggered → Main 显示飘字

新流程（v0.1.73）：
  踩商店格 → CellEffectHandler.has_valid_shop_cell()（仅检查格子存在+玩家身份）
  → BFC emit shop_panel_requested → Main 打开 ShopPanel
  → 玩家在面板中自由购买 → ShopPanel 内部直接结算
  → 关闭面板 → Main 刷新 DiceDebugPanel crest 显示 + BoardView 重绘
```

---

## 接口变更

- **删除**：`BFC.shop_cell_triggered` 信号、`CellEffectHandler.check_shop_cell()` 方法
- **新增**：`BFC.shop_panel_requested(unit_id, cell)` 信号
- **新增**：`CellEffectHandler.has_valid_shop_cell(unit_id, cell) -> bool` 方法
- **新增**：`ShopPanel` class（class_name 全局注册），含 `open_shop()` 方法和 `shop_closed` 信号
- **新增**：`Main._on_shop_panel_requested()` / `Main._on_shop_closed()` 回调
- DiceDebugPanel 信号绑定从 `shop_cell_triggered` 改为 `shop_panel_requested`

---

## 测试确认

### 自查闭环（代码审查）

| 测试项 | 结果 |
|--------|------|
| 掷骰 → 移动 → 攻击 → 召唤 | ✅ 不涉及本次修改 |
| 敌方回合 → 镜头跟随 | ✅ 不涉及 |
| 遭遇触发 → 卡牌战斗 → 选牌奖励 → HP同步回棋盘 | ✅ 不涉及 |
| 重新开始 | ✅ ShopPanel 默认 visible=false，重启不受影响 |
| 胜负判定 | ✅ 不涉及 |
| 商店格 → 面板弹出 | ✅ BFC._check_shop_cell → shop_panel_requested → Main → ShopPanel.open_shop |
| 购买商品 → crest 扣除 + 效果生效 | ✅ ShopPanel._execute_purchase 直接操作 dice_manager/unit_manager |
| 关闭商店 → crest 面板刷新 | ✅ _on_shop_closed → _dice_panel._refresh_crest_pool() |
| 商品不可购买时按钮灰掉 | ✅ _can_purchase 检查 crest 余额 + HP 满血 + 能量上限 |
| 敌方单位踩商店格不触发 | ✅ has_valid_shop_cell 检查 owner=="player" |
| 旧信号 shop_cell_triggered 全部清除 | ✅ grep 确认零引用 |

---

## 剩余问题

- 3D 反馈方法（飘字/闪光/粒子）仍为桩函数（v0.1.71 遗留）
- 3D 单位仍为简单几何体（v0.1.71 遗留）
- DiceDebugPanel 仍绑定 2D BoardView（v0.1.71 遗留）
- spritesheet 背景透明度（v0.1.70 遗留）
- ATK/DEF 提升未走 BuffManager，直接改 unit dict——跨层时 unit 重建所以自动"重置"，但同层内是永久的（设计意图）

---

## 建议下一步

1. 3D 反馈系统实现（粒子特效/3D 飘字）
2. 阵亡单位跨层复活机制
3. BattleFlowController 瘦身

## Codex 复审标注（可选）

- ATK/DEF 提升直接修改 unit dict 是最保守方案——效果"本层永久"符合商店逻辑（花了资源买的应该持续整层）。如果希望有回合限制，可后续改走 BuffManager。
- 能量核心直接改 CardBattleController.max_energy，该变量已设计为跨战斗持久（v0.1.38），所以这是安全操作。但上限卡死 5，避免数值崩溃。
- 商品池目前 5 种，后续可扩展（加新牌、移除诅咒、随机 crest 等），ShopPanel 的 SHOP_ITEM_POOL 是 const Array，改起来方便。
