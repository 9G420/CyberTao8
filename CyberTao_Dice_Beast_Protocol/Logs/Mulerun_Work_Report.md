# Mulerun 工作报告

**日期**: 2026-04-02
**版本**: v0.1.84
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.84：卡牌对战手感优化 + 手牌“自动飞顶部”问题修复（先对齐旧项目丝滑度）

---

## 根因目标

用户反馈当前卡牌对战手感不如旧项目，且存在“手牌会自动飞上顶部”的小 BUG。

代码分析后确认核心根因：
1. 拖拽逻辑混用了 `global_position` 与容器本地坐标；
2. 出牌区判定使用全局 Y，与界面视觉区不是同一坐标系；
3. 悬停/回退动画缺少稳定基准位，易出现漂移与生硬回弹。

本轮目标：在不改卡牌结算逻辑的前提下，仅优化 CardBattlePanel 的输入/动画表现层，让交互稳定且顺滑。

服务层：卡牌战斗层（UI 交互表现）

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/UI/CardBattlePanel.gd` | 拖拽坐标统一改为 `_card_container` 本地坐标；出牌区判定改本地 Y；悬停动画改用固定 `base_pos`；取消拖拽改 tween 回弹；拖拽入口 `_start_card_drag` 签名简化 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.84 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号 + §2.2 完成状态 + §6 任务优先级 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |

---

## 实现内容

### 1) 拖拽坐标系统一（修复“飞顶部”）

- 旧逻辑：`event.global_position` + `widget.global_position` 混算。
- 新逻辑：统一使用 `_card_container.get_local_mouse_position()` 与 `widget.position`。

具体调整：
- `_input` 的拖拽跟随位置更新改为：`_drag_widget.position = local_mouse - _drag_offset`
- 鼠标释放判定改为：`local_mouse.y < PLAY_ZONE_Y`
- `_start_card_drag` 改为内部取本地鼠标坐标，移除外部传入 global mouse 参数

### 2) 悬停动画稳定化

- 在创建扇形手牌时，为每张卡记录 `base_pos`（meta）。
- 鼠标进入/离开时，动画都相对 `base_pos` 计算，不再依赖临时变量，避免累计漂移和抖动。

### 3) 取消拖拽手感优化

- 旧逻辑：取消拖拽直接瞬移回原位。
- 新逻辑：改为 0.12s tween 回弹（位置+旋转+缩放并行），交互更接近旧项目顺滑体验。

---

## 接口变更

- `CardBattlePanel.gd`
  - 修改：`func _start_card_drag(index: int, widget: Panel, mouse_pos: Vector2)`
  - 为：`func _start_card_drag(index: int, widget: Panel)`
  - 说明：函数内部统一读取本地鼠标坐标，避免外部坐标传递不一致。

- 无新增公开信号；`CardBattleController` 无改动。

---

## 测试确认

### 手感与稳定性自查（代码路径）

| 测试项 | 结果 |
|--------|------|
| 手牌拖拽跟随使用本地坐标，无 global/local 混算 | ✅ |
| 出牌区判定与视觉区域一致（本地 Y） | ✅ |
| 取消拖拽卡牌回位为平滑回弹，不再硬跳 | ✅ |
| 悬停提升/复位基于固定 base_pos，无累计位移 | ✅ |
| 卡牌可出牌与不可出牌 gating 逻辑保持不变 | ✅ |
| CardBattleController 战斗结算逻辑零改动 | ✅ |

---

## 剩余问题

- 当前“丝滑度”已提升，但仍未引入旧项目可能存在的高级细节（如拖拽吸附、曲线回弹参数个性化、目标区磁吸）。
- 未在本轮扩展卡牌拖拽到触屏手势兼容（当前面向鼠标流程）。

---

## 建议下一步

1. 增加“拖拽吸附反馈”（进入出牌区时卡牌轻微吸附到目标高度）。
2. 调整 hover/drag 回弹 easing 参数做 A/B（进一步贴近旧项目主观手感）。
3. 在卡牌结算层新增 1~2 个防错提示（能量不足时提示更明确）。
