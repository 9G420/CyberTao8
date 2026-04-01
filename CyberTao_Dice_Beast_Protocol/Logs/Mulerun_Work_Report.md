# Mulerun 工作报告

**日期**: 2026-04-01
**版本**: v0.1.82
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.82：2D 渲染路径 spritesheet 移除 — 修复默认模式（2D）仍显示旧 spritesheet 插图的 BUG

---

## 根因目标

用户拉取 v0.1.81 后本地测试发现玩家角色仍显示旧 spritesheet 插图。原因：v0.1.81 仅修改了 3D 渲染路径（UnitMeshFactory3D + BoardView3D），而游戏默认运行在 2D 模式（Main.gd `_use_3d = false`），2D 渲染路径（BoardView.gd + PlayerSpriteAnimator）未被修改。

本轮将 BoardView.gd 中的 PlayerSpriteAnimator 依赖完全移除，使玩家单位走 UnitRenderer 程序化渲染路径，与敌方单位一致。

服务层：2D 表现层

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/UI/BoardView.gd` | 移除 `_sprite_animator` 变量/初始化/tick 调用/方向设置/停止调用/`_draw_player_sprite()` 方法，玩家单位改为 `UnitRenderer.draw_full_unit_iso()` 程序化渲染 |
| `Scripts/UI/DiceDebugPanel.gd` | 版本标记 → v0.1.82 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.82 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号 + §2.2/§3.1/§6 更新 |
| `Logs/Handoff_Package_latest.md` | 覆盖为 v0.1.82 交接包 |

---

## 实现内容

### BoardView.gd spritesheet 移除

**移除**:
- `_sprite_animator` 变量（PlayerSpriteAnimator 实例）
- `_ready()` 中的 `PlayerSpriteAnimator.new()` 初始化
- `_on_anim_tick()` 中的 `_sprite_animator.tick()` 调用
- `play_move_step()` 中的方向设置和动画启动（`set_direction` / `set_animating(true)`）
- `_on_move_step_finished()` 中的动画停止（`set_animating(false)`）
- `_draw_layer_units()` 中的 spritesheet 分支（`is_player and _sprite_animator.is_loaded()` → `_draw_player_sprite()`）
- `_draw_player_sprite()` 整个方法（23行）

**替代**:
- 所有单位统一使用 `UnitRenderer.draw_full_unit_iso()` 程序化渲染

---

## 接口变更

**无新增/无删除公开接口**（`_draw_player_sprite` 为私有方法）

**保留不变**:
- `play_move_step()` — 签名不变
- `_on_move_step_finished()` — 签名不变
- `_draw_layer_units()` — 签名不变

---

## 测试确认

### 自查闭环

| 测试项 | 结果 |
|--------|------|
| BoardView.gd 不再引用 PlayerSpriteAnimator | ✅ |
| _sprite_animator 变量已移除 | ✅ |
| _draw_player_sprite 方法已移除 | ✅ |
| play_move_step 不再设置精灵方向 | ✅ |
| _on_move_step_finished 不再停止精灵动画 | ✅ |
| 所有单位走 UnitRenderer.draw_full_unit_iso | ✅ |
| HP 条/选中效果由 UnitRenderer 统一处理 | ✅ |

---

## 剩余问题

- PlayerSpriteAnimator.gd 文件仍存在但已无任何引用方（可在清理轮次安全删除）
- 2D 模式使用 UnitRenderer Q版风格，3D 模式使用 UnitMeshFactory3D BGA 像素风格（两种风格略有差异但均为程序化）
- remove_card 自动选择最弱牌（无手动选择UI）
- 电弧 ATK-1 效果永久（单场内，设计取舍）

---

## 建议下一步

1. 商店 remove_card 手动选择UI
2. 更多遭遇/Boss 丰富战斗多样性
3. 如需行走动画：可给移动中的单位添加简单弹跳 tween 效果（无需 spritesheet）
