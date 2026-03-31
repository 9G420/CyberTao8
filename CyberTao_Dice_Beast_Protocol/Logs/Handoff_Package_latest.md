# CyberTao: Dice Beast Protocol — 交接包

**生成时间**: 2026-03-31
**当前版本**: v0.1.70
**分支**: codex/dice-beast-protocol

---

## 1. 此刻的精确状态（一句话）

v0.1.70 完成玩家角色精灵动画集成（4方向 spritesheet 替代程序化绘制），棋盘层和卡牌层全部稳定，v0.1.67-70 四版完成了移动逐格动画+卡牌拖拽出牌+即时伤害反馈+头像HUD+精灵动画，下一步是商店格扩展。

---

## 2. 本账号完成的工作

| 版本 | 任务 | 状态 |
|------|------|------|
| v0.1.67 | 移动逐格行走动画+敌方移动动画+我方回合镜头切回优化 | 完成 |
| v0.1.68 | 卡牌拖拽出牌+即时伤害反馈 | 完成 |
| v0.1.69 | 顶部单位头像 HUD | 完成 |
| v0.1.70 | 玩家角色精灵动画（4方向 spritesheet 集成） | 完成 |

---

## 3. 最后版本关键变更

**版本号**: v0.1.70

**修改文件**:
- `Scripts/UI/PlayerSpriteAnimator.gd` — **新文件**：精灵动画管理器，加载4张spritesheet+帧切换+方向检测
- `Scripts/UI/BoardView.gd` — 新增 `_sprite_animator` + `_draw_player_sprite()` + 移动时启动/停止动画 + tick推进帧
- `Scripts/UI/DiceDebugPanel.gd` — 版本标记 v0.1.70

**新增接口**:
- `PlayerSpriteAnimator.is_loaded()` — 4张纹理是否全部加载成功
- `PlayerSpriteAnimator.set_direction(dir)` — 设置朝向 "up"/"down"/"left"/"right"
- `PlayerSpriteAnimator.set_animating(val)` — 开始/停止帧动画
- `PlayerSpriteAnimator.tick()` — 推进一个时间步（由 BoardView._on_anim_tick 调用）
- `PlayerSpriteAnimator.get_texture()` / `get_source_rect()` — 获取当前帧纹理和区域
- `PlayerSpriteAnimator.direction_from_cells(from, to)` — 静态方法，根据格子计算方向
- `BoardView._draw_player_sprite()` — 精灵渲染玩家角色

**遗留问题**:
- spritesheet 背景透明度需实际运行确认（如有白底需预处理）
- 精灵渲染大小（80px）可能需要微调
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
| spritesheet 背景透明度待确认 | 中 | 否 | 用户测试后立即处理 |
| 精灵渲染大小可能需微调 | 低 | 否 | 用户反馈后调整 |
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

- PlayerSpriteAnimator 是 RefCounted（非 Node），在 BoardView._ready() 中 new() 创建
- 4张 spritesheet 路径硬编码在 PlayerSpriteAnimator._init() 中：`res://Assets/Tiles/刀盾向{上/下/左/右}走.png`
- 帧率 10fps（TICKS_PER_FRAME=2，每次 _on_anim_tick 50ms），如需加快可改为 1
- 方向检测基于网格坐标 dx/dy 比较，等距视图下可能需要调整映射
- 所有玩家单位（主角+伙伴）共用同一套精灵，伙伴需要独立素材时需扩展 PlayerSpriteAnimator
- UnitPortraitHUD 仍用 UnitRenderer._draw_player_char 绘制迷你头像（缩放 0.45），未接入精灵
- 拖拽系统（v0.1.68）使用 `_input()` override，CardBattlePanel 在 `not visible` 时 return
- 移动动画信号链（v0.1.67）：BFC.move_step_visual → Main → BoardView.play_move_step → move_anim_done → Main → BFC.move_step_done
- `_last_operated_unit_id` 仅在 Main 层追踪
- AI_Employee_Guide_v3.md 是**每轮强制更新**的（三件套缺一不可）
