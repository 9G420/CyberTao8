# CyberTao: Dice Beast Protocol — 交接包

**生成时间**: 2026-04-01
**当前版本**: v0.1.77
**分支**: codex/dice-beast-protocol

---

## 1. 此刻的精确状态（一句话）

v0.1.77 完成 3D 单位精灵化：玩家英雄使用 billboard Sprite3D + 现有 4 方向 spritesheet（含行走帧动画），敌方和召唤伙伴使用程序化生成的赛博朋克图标。BFC 瘦身（v0.1.76）、跨层复活/回复（v0.1.75）、3D 反馈系统（v0.1.74）和商店面板（v0.1.73）均稳定。下一步是商品池扩展或卡牌层深化。

---

## 2. 本账号完成的工作

| 版本 | 任务 | 状态 |
|------|------|------|
| v0.1.74 | 3D 反馈系统实现（9个桩函数→完整3D特效） | 完成 |
| v0.1.75 | 阵亡单位跨层复活 + 存活单位跨层回复 | 完成 |
| v0.1.76 | BFC 瘦身：FloorManager 独立类 | 完成 |
| v0.1.77 | 3D 单位精灵化（billboard Sprite3D） | 完成 |

---

## 3. 最后版本关键变更

**版本号**: v0.1.77

**修改文件**:
- `Scripts/UI3D/UnitMeshFactory3D.gd` — 完整重写：CapsuleMesh/CylinderMesh → billboard Sprite3D；spritesheet 行走动画支持；程序化敌方/召唤图标
- `Scripts/UI3D/BoardView3D.gd` — 新增精灵帧动画逻辑（移动时方向检测+10fps帧推进+结束重置）
- `Scripts/UI/DiceDebugPanel.gd` — 版本标记 → v0.1.77

**新增接口**:
- `UnitMeshFactory3D.is_spritesheet_unit(node)` — 判断是否为 spritesheet 精灵
- `UnitMeshFactory3D.set_sprite_direction(node, dir)` — 设置精灵朝向
- `UnitMeshFactory3D.set_sprite_frame(node, dir, frame)` — 设置精灵帧
- `UnitMeshFactory3D.reset_sprite_idle(node)` — 重置待机姿态

**无外部信号变更**

**遗留问题**:
- spritesheet 背景透明度（v0.1.70 遗留）
- DiceDebugPanel 仍绑定 2D BoardView（v0.1.71 遗留）
- 敌方/召唤单位使用程序化图标（无独立美术资源）

---

## 4. 下一步任务（精确到可以直接开始）

**立刻要做的**:
根据用户指派的任务方向选择：
- 商品池扩展：在 `Scripts/UI/ShopPanel.gd` 添加新商品类型（加新牌/移除诅咒/随机 crest）
- 卡牌战斗层深化：新卡牌效果、新敌方行为模式

**任务队列**:
1. 商品池扩展
2. 卡牌战斗层深化
3. 敌方单位美术资源（替换程序化图标）

---

## 5. 当前未解决问题清单

| 问题 | 严重程度 | 是否阻塞 | 建议处理时机 |
|------|----------|----------|--------------|
| spritesheet 背景透明度待确认 | 中 | 否 | 用户测试后处理 |
| DiceDebugPanel 绑定 2D BoardView | 低 | 否 | 3D 完善轮次 |
| CardRewardPanel 未使用 CardRenderer 风格 | 低 | 否 | UI 统一轮次 |
| 商店 ATK/DEF 提升未走 BuffManager | 低 | 否 | 如需回合限制时改 |
| BoardView3D.rebuild_board() 全量重建 | 低 | 否 | 3D 优化轮次 |
| 复活/回复数值未经平衡测试 | 低 | 否 | 数值调优轮次 |
| 敌方/召唤使用程序化图标 | 低 | 否 | 美术资源就绪后替换 |

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

- v0.1.77 的 UnitMeshFactory3D 完全重写，从几何体工厂变为精灵工厂
- 玩家精灵使用 `Sprite3D` + `region_enabled`，通过 `region_rect` 选择 spritesheet 帧
- 程序化图标通过 `Image` + `ImageTexture.create_from_image()` 生成，缓存到静态变量
- `alpha_cut = ALPHA_CUT_DISCARD` + `alpha_scissor_threshold = 0.4` 处理透明度（gl_compatibility 兼容）
- 精灵动画由 BoardView3D._update_sprite_animation() 驱动，仅在 _move_anim_unit 非空时推帧
- 要替换敌方/召唤图标为美术资源，只需修改 `_create_body_sprite()` 中的纹理分支
- v0.1.76 FloorManager 详见上一版交接包
