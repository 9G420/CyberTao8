# Mulerun 工作报告

**日期**: 2026-04-02
**版本**: v0.1.83
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.83：商店 `remove_card` 改为手动选择 UI（替换自动移除最弱牌）

---

## 根因目标

当前商店“数据清洗”会自动移除牌组中 value/cost 最低的卡，玩家无法进行构筑取舍，导致机制决策深度不足。

本轮目标是把 remove_card 从“系统代删”改为“玩家手动选牌后确认删除”，提升构筑可控性。

服务层：棋盘走位层（商店系统）+ 卡牌构筑成长

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/UI/ShopPanel.gd` | 新增 remove_card 手动选牌弹窗 UI（遮罩+列表+移除按钮+取消按钮）；`_execute_purchase` 增加 `remove_deck_index` 参数；`remove_card` 从自动删最弱牌改为按玩家选择索引删除；新增 `_apply_purchase_result` 统一购买反馈；修复 `_refresh_display` 会覆盖状态提示的问题 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.83 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步当前版本、完成状态与任务优先级 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |

---

## 实现内容

### 1) remove_card 手动选牌

- 在 ShopPanel 内新增“移除卡牌选择弹窗”：
  - 半透明遮罩层（阻断底层点击）
  - 列表滚动区（展示当前持久牌组每一张卡）
  - 每行独立“移除”按钮
  - 取消按钮（关闭弹窗，不扣资源）

### 2) 购买流程调整

- 点击 `remove_card` 商品时不再直接执行扣费/删牌，先打开选牌弹窗。
- 仅当玩家在弹窗中明确点某张卡的“移除”按钮时才执行 `_execute_purchase`：
  - 检查索引有效
  - 扣除 crest 费用
  - 从 `persistent_deck` 删除该卡

### 3) 反馈与交互修正

- 统一成功/失败提示到 `_apply_purchase_result()`，避免分支文案不一致。
- `_refresh_display()` 不再无条件清空 `_status_label`，避免购买后提示被立即抹掉。

---

## 接口变更

- `ShopPanel.gd`
  - 修改：`func _execute_purchase(item: Dictionary)`
  - 为：`func _execute_purchase(item: Dictionary, remove_deck_index: int = -1)`
  - 说明：仅 remove_card 分支使用新增参数，其它商品行为不变。

- 新增私有方法：
  - `_apply_purchase_result(item, result)`
  - `_open_remove_picker(item)`
  - `_refresh_remove_picker_list()`
  - `_format_card_entry(card)`
  - `_on_remove_card_selected(deck_index)`
  - `_on_remove_picker_cancel_pressed()`
  - `_build_remove_picker_ui()`

---

## 测试确认

### 自查闭环（代码路径）

| 测试项 | 结果 |
|--------|------|
| 商店显示 remove_card 时文案为手动选择 | ✅ |
| 点击 remove_card 会先弹出选牌面板，不直接扣费 | ✅ |
| 取消选牌不会扣费、不会改牌组 | ✅ |
| 选择某张牌后执行扣费并删除该指定卡 | ✅ |
| 牌组 <=3 时 remove_card 仍不可购买 | ✅ |
| 其他商品（heal/atk/def/energy/add_card/random_crest/max_hp_up）流程未改 | ✅ |
| 购买成功/失败状态提示可见，不被刷新覆盖 | ✅ |

---

## 剩余问题

- 当前手动移牌列表仍是“逐张显示”，未做同名聚合（功能正确，后续可优化）
- 选牌列表仅显示 `type` 原始字段，未做中文类型映射（可读性可继续提升）

---

## 建议下一步

1. 继续机制深化：战后奖励加入“跳过换资源”分支，补足构筑节奏选择。
2. 做敌方遭遇前关键词预览（克制信息），提升棋盘路径决策质量。
3. remove_card 体验优化：同名卡聚合 + 预估强度提示（可选）。
