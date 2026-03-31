# CyberTao: Dice Beast Protocol — 交接包

**生成时间**: 2026-03-31
**当前版本**: v0.1.68
**分支**: codex/dice-beast-protocol

---

## 1. 此刻的精确状态（一句话）

v0.1.68 完成卡牌拖拽出牌系统（替代点击出牌）+即时伤害反馈（HP 条每次出牌后立即刷新+伤害飘字），棋盘层和卡牌层全部稳定，下一步是顶部单位头像HUD（v0.1.69）。

---

## 2. 本账号完成的工作

| 版本 | 任务 | 状态 |
|------|------|------|
| v0.1.67 | 移动逐格行走动画+敌方移动动画+我方回合镜头切回优化 | 完成 |
| v0.1.68 | 卡牌拖拽出牌+即时伤害反馈 | 完成 |

---

## 3. 最后版本关键变更

**版本号**: v0.1.68

**修改文件**:
- `Scripts/UI/CardBattlePanel.gd` — 新增拖拽出牌系统（_input全局追踪+拖拽状态管理）；即时HP刷新+伤害飘字；出牌区视觉提示
- `Scripts/UI/DiceDebugPanel.gd` — 版本标记更新至 v0.1.68

**新增接口**:
- `CardBattlePanel._input(event)` — 全局鼠标追踪（拖拽跟随+释放判定）
- `CardBattlePanel._start_card_drag(index, widget, mouse_pos)` — 启动拖拽
- `CardBattlePanel._end_drag()` — 释放打出卡牌
- `CardBattlePanel._cancel_drag()` — 取消拖拽归位
- `CardBattlePanel._spawn_effect_popup(text, color, pos)` — 伤害/治疗飘字

**遗留问题**:
- 顶部单位头像 HUD 未实现（v0.1.69）
- CardRewardPanel 暂未使用 CardRenderer 风格
- 阵亡单位跨层不复活

---

## 4. 下一步任务（精确到可以直接开始）

**立刻要做的**:
v0.1.69 顶部单位头像 HUD：
- 在 `Main.gd` 或新建 `UnitPortraitHUD.gd` 中实现顶部横排单位头像
- 读取 `unit_manager.get_all_units()` 获取各方单位列表
- 为每个单位绘制小头像（使用 UnitRenderer 风格）+ HP 条
- 点击头像 → `_board_view.set_camera_target(unit_cell)` 切换镜头
- 当前选中单位高亮标记

**任务队列**:
1. v0.1.69：顶部单位头像 HUD
2. 商店格扩展
3. 阵亡单位跨层复活机制

---

## 5. 当前未解决问题清单

| 问题 | 严重程度 | 是否阻塞 | 建议处理时机 |
|------|----------|----------|--------------|
| 顶部单位头像 HUD 不存在 | 中 | 否 | v0.1.69 |
| 阵亡单位跨层不复活 | 低 | 否 | 数值调优轮次 |
| CardRewardPanel 未使用 CardRenderer 风格 | 低 | 否 | UI 统一轮次 |
| 电弧牌 ATK-1 效果仅单场生效 | 低 | 否 | 卡牌数据重构时 |
| BattleFlowController ~710行 | 中 | 否 | 下次大功能前 |

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

- 拖拽系统使用 `_input()` override 而非 `_gui_input`，这是因为拖拽时鼠标可能离开卡牌 widget 区域
- `_hp_before_enemy/_hp_before_player` 在 `_end_drag()` 中快照、`_on_card_played()` 中比对——依赖 `play_card()` 是同步的（当前确实是同步的）
- `_on_hand_changed` 首行调用 `_cancel_drag()` 是关键防护：`play_card` → `hand_changed` → 手牌重建会销毁正在拖拽的 widget
- 出牌区判定线 `PLAY_ZONE_Y = 380.0`，可以根据用户反馈调整
- 移动动画信号链（v0.1.67）：BFC.move_step_visual → Main → BoardView.play_move_step → move_anim_done → Main → BFC.move_step_done
- `_last_operated_unit_id` 仅在 Main 层追踪，BFC 不知道这个概念
- AI_Employee_Guide_v3.md 是**每轮强制更新**的（三件套缺一不可）
