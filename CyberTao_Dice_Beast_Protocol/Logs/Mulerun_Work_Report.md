# Mulerun 工作报告

**日期**: 2026-04-01
**版本**: v0.1.78
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.78：商品池扩展 — 商店从 5 种商品扩展至 9 种

---

## 根因目标

v0.1.73 实现了商店面板，提供 5 种基础商品（治疗/ATK/DEF/能量）。但随着卡牌战斗系统的深化（持久牌组、升级、多敌方），玩家在棋盘层缺乏影响卡牌层的策略性购买选项。本轮新增 4 种商品，让商店成为连接棋盘层（crest 资源）和卡牌层（牌组构筑）的桥梁。

服务层：游戏玩法层（策略深化）

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/UI/ShopPanel.gd` | SHOP_ITEM_POOL 5→9 种；`_pick_random_items()` 新增牌组过小过滤；`_can_purchase()` 新增 4 种前置检查；`_execute_purchase()` 新增 4 种效果结算（321→~380 行） |
| `Scripts/UI/DiceDebugPanel.gd` | 版本标记 v0.1.77 → v0.1.78 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.78 条目 + BUG-002 日志归档 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号 + §2.2/§3.1/§6 更新 |
| `Logs/Handoff_Package_latest.md` | 覆盖为 v0.1.78 交接包 |

---

## 实现内容

### 数据芯片（add_card）— 加牌

- 花费：策(trick) x1
- 效果：从 `CardBattleController._build_reward_pool()` 随机选取 1 张卡牌，加入 `persistent_deck`
- 复用现有 13 张奖励卡池，无需额外卡牌定义
- 返回卡牌名称（如"获得「穿刺」"）

### 数据清洗（remove_card）— 移除牌

- 花费：术(skill) x1
- 效果：移除 `persistent_deck` 中效费比（value/cost）最低的 1 张牌
- 安全阀：牌组 ≤3 张时商品不出现且不可购买
- 返回被移除的卡牌名称

### 赛博彩票（random_crest）— 随机资源

- 花费：步(move) x1
- 效果：随机获得 2 个 crest 资源（从 6 种中独立随机）
- 直接修改 `_dice_manager.crest_pool` 字典
- 返回获得的资源名（如"+攻+召"）

### 生体强化（max_hp_up）— 最大HP提升

- 花费：盾(defend) x2
- 效果：最大HP+2，同时当前HP+2（避免 HP 条占比反而降低的视觉问题）
- 通过 `_unit_manager.emit_signal("units_changed")` 触发 UI 刷新

### 设计取舍

- add_card 使用 `_build_reward_pool()` 而非 `_build_deck()`，确保玩家获得的是奖励级卡牌（含穿刺/吸血斩等强力卡）
- remove_card 按 value/cost 自动选择最弱牌，避免弹出二级选择 UI（保持商店交互一致性）
- random_crest 的 2 个资源独立随机，可能获得相同类型（设计意图：彩票感）
- max_hp_up 同时回复等量 HP，参考 STS"净化"概念——购买即时体验不应为负
- 商品池 9 种、每次展示 3 件，概率上每次商店约 1/3 几率出现新商品类

---

## 接口变更

- 无新增公开接口
- 无信号变更
- ShopPanel 内部新增 `add_card`/`remove_card`/`random_crest`/`max_hp_up` 四种 effect 分支

---

## 测试确认

### 自查闭环（代码审查）

| 测试项 | 结果 |
|--------|------|
| 商店打开 → 显示 3 件商品 | ✅ `_pick_random_items()` 从 9 种中随机选 3 |
| add_card 购买 → 牌组增加 | ✅ `persistent_deck.append(card)` |
| remove_card 购买 → 牌组减少 | ✅ `deck.remove_at(worst_idx)`，牌组≤3 时禁用 |
| remove_card 牌组过小过滤 | ✅ `_pick_random_items()` 和 `_can_purchase()` 双重检查 |
| random_crest 购买 → crest 增加 | ✅ 直接修改 `crest_pool` 字典 |
| max_hp_up 购买 → HP 条刷新 | ✅ `units_changed` 信号触发 UI 更新 |
| energy_up 上限过滤 | ✅ 不受影响 |
| 治疗类 HP 满过滤 | ✅ 不受影响 |
| crest 信息显示刷新 | ✅ `_refresh_display()` 在每次购买后重新读取 crest_pool |

---

## 剩余问题

- spritesheet 背景透明度（v0.1.70 遗留）
- DiceDebugPanel 仍绑定 2D BoardView（v0.1.71 遗留）
- ATK/DEF 商店提升未走 BuffManager（v0.1.73 设计取舍）
- BoardView3D.rebuild_board() 全量重建（大棋盘性能开销）
- 复活/回复数值未经平衡测试
- 敌方/召唤单位使用程序化图标，无独立美术资源
- remove_card 自动选择最弱牌，玩家无法手动指定（后续可改为弹出牌组选择）

---

## 建议下一步

1. 卡牌战斗层深化（新卡牌效果/新敌方行为模式）
2. 敌方单位美术资源（替换程序化图标为独立 spritesheet）
3. 商店 remove_card 改为手动选择（需二级 UI）

## Codex 复审标注（可选）

- `CardBattleController._build_reward_pool()` 是静态方法，ShopPanel 可直接调用无需实例
- remove_card 的 value/cost 比值评估在牌组全为同值时会移除第一张（index 0），这是可接受的边界行为
- random_crest 直接写入 `crest_pool` 字典，绕过了 DiceManager 的正常 earn 流程；当前 DiceManager 没有独立的 earn 方法，直接修改字典是唯一方式
- max_hp_up 的 +2 数值参考当前单位 max_hp（通常 10-15），占比约 13-20%，合理但未经平衡测试
