# CyberTao: Dice Beast Protocol — 交接包

**生成时间**: 2026-03-31
**当前版本**: v0.1.69
**分支**: codex/dice-beast-protocol

---

## 1. 此刻的精确状态（一句话）

v0.1.69 完成顶部单位头像 HUD（各方单位横排头像+HP条+点击切换镜头），棋盘层和卡牌层全部稳定，v0.1.67-69 三版完成了移动逐格动画+卡牌拖拽出牌+即时伤害反馈+头像HUD，下一步是商店格扩展。

---

## 2. 本账号完成的工作

| 版本 | 任务 | 状态 |
|------|------|------|
| v0.1.67 | 移动逐格行走动画+敌方移动动画+我方回合镜头切回优化 | 完成 |
| v0.1.68 | 卡牌拖拽出牌+即时伤害反馈 | 完成 |
| v0.1.69 | 顶部单位头像 HUD | 完成 |

---

## 3. 最后版本关键变更

**版本号**: v0.1.69

**修改文件**:
- `Scripts/UI/UnitPortraitHUD.gd` — **新文件**：顶部单位头像 HUD
- `Scripts/Main.gd` — 新增 HUD 实例化 + 信号连接 + 点击回调 + 卡牌战斗时隐藏
- `Scripts/UI/DiceDebugPanel.gd` — 版本标记 v0.1.69

**新增接口**:
- `UnitPortraitHUD.bind_unit_manager(um)` — 绑定 UnitManager
- `UnitPortraitHUD.set_selected(unit_id)` — 设置选中高亮
- `UnitPortraitHUD.portrait_clicked` 信号 — 头像被点击
- `Main._on_portrait_clicked(unit_id)` — 处理镜头切换+选中

**遗留问题**:
- CardRewardPanel 暂未使用 CardRenderer 风格
- 阵亡单位跨层不复活

---

## 4. 下一步任务（精确到可以直接开始）

**立刻要做的**:
商店格扩展：
- 当前商店格仅 -1 步 +HP 固定效果
- 需要：独立 ShopPanel UI 面板，展示多种商品（HP回复/卡牌/buff），玩家选择购买
- 在 `CellEffectHandler.gd` 中修改 shop_cell 逻辑，触发 ShopPanel 而非自动结算
- 新建 `Scripts/UI/ShopPanel.gd`

**任务队列**:
1. 商店格扩展（多选商品 + 独立 UI 面板）
2. 阵亡单位跨层复活机制
3. BattleFlowController 瘦身

---

## 5. 当前未解决问题清单

| 问题 | 严重程度 | 是否阻塞 | 建议处理时机 |
|------|----------|----------|--------------|
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

- UnitPortraitHUD 调用 UnitRenderer 的 `_` 前缀静态方法绘制迷你头像，缩放 0.45
- HUD 通过 `units_changed` 信号自动 rebuild，全量重建 _portraits 数组
- `_portrait_hud.visible` 在遭遇进出时手动切换（Main.gd 中两处）
- BoardView 的 `unit_selected` / `unit_deselected` 信号联动 HUD 选中高亮
- 拖拽系统（v0.1.68）使用 `_input()` override，CardBattlePanel 在 `not visible` 时 return
- 移动动画信号链（v0.1.67）：BFC.move_step_visual → Main → BoardView.play_move_step → move_anim_done → Main → BFC.move_step_done
- `_last_operated_unit_id` 仅在 Main 层追踪
- AI_Employee_Guide_v3.md 是**每轮强制更新**的（三件套缺一不可）
