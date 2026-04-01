# CyberTao: Dice Beast Protocol — 交接包

**生成时间**: 2026-04-01
**当前版本**: v0.1.81
**分支**: codex/dice-beast-protocol

---

## 1. 此刻的精确状态（一句话）

v0.1.81 完成全单位程序化 BGA 宝可梦像素风格重构：移除所有 spritesheet 外部 PNG 资源依赖，玩家英雄/7种遭遇敌方/Boss/召唤伙伴均使用程序化像素生成（32×32 逻辑网格+发光轮廓），BoardView3D 帧动画系统已移除。数值平衡（v0.1.80）、卡牌战斗深化（v0.1.79）、商品池扩展（v0.1.78）均稳定。下一步可选商店手动选牌UI或新遭遇/Boss。

---

## 2. 本账号完成的工作

| 版本 | 任务 | 状态 |
|------|------|------|
| v0.1.74 | 3D 反馈系统实现 | 完成 |
| v0.1.75 | 阵亡单位跨层复活 + 存活单位跨层回复 | 完成 |
| v0.1.76 | BFC 瘦身：FloorManager 独立类 | 完成 |
| v0.1.77 | 3D 单位精灵化 + BUG-002 修复 | 完成 |
| v0.1.78 | 商品池扩展（5→9种商品） | 完成 |
| v0.1.79 | 卡牌战斗层深化（4新卡+2新行为+2新遭遇） | 完成 |
| v0.1.80 | 数值平衡调优（6项修正） | 完成 |
| v0.1.81 | 全单位程序化 BGA 宝可梦像素风格重构 | 完成 |

---

## 3. 最后版本关键变更

**版本号**: v0.1.81

**修改文件**:
- `Scripts/UI3D/UnitMeshFactory3D.gd` — 完全重写：移除 spritesheet，新增 12 种程序化 BGA 像素生物生成器
- `Scripts/UI3D/BoardView3D.gd` — 移除精灵帧动画系统（变量+方法+调用点）
- `Scripts/UI/DiceDebugPanel.gd` — 版本标记 → v0.1.81

**删除接口**:
- `UnitMeshFactory3D.is_spritesheet_unit()` / `set_sprite_direction()` / `set_sprite_frame()` / `reset_sprite_idle()`

**无新增接口**，create_unit_node / update_hp_bar 签名不变

---

## 4. 下一步任务

**任务队列**:
1. 商店 remove_card 手动选择UI
2. 更多遭遇/Boss 丰富战斗多样性
3. 如需行走动画：可添加移动中弹跳 tween（无需 spritesheet）

---

## 5. 当前未解决问题清单

| 问题 | 严重程度 | 是否阻塞 | 建议处理时机 |
|------|----------|----------|--------------|
| 单位为静态贴图（无行走帧动画） | 低 | 否（功能不受影响） | 如需可加弹跳 tween |
| PlayerSpriteAnimator.gd 已无引用 | 低 | 否 | 清理轮次移除 |
| remove_card 自动选择 | 低 | 否 | 需手动选择时 |
| DiceDebugPanel 绑定 2D BoardView | 低 | 否 | 3D 完善轮次 |
| 商店 ATK/DEF 未走 BuffManager | 低 | 否 | 如需回合限制时改 |

---

## 6. 新账号启动指令

```bash
git clone https://github.com/9G420/CyberTao8.git
cd CyberTao8
git checkout codex/dice-beast-protocol
git pull origin codex/dice-beast-protocol
```

然后按顺序阅读：
1. `Logs/AI_Employee_Guide_v3.md`
2. 本文件
3. `Logs/CyberTao_Migration_Snapshot_zh_v3.md`
4. `Logs/Mulerun_Work_Report.md`

---

## 7. 给下一个账号的备注

- v0.1.81 移除了所有外部 PNG spritesheet 依赖，Assets/Tiles/刀盾向X走.png 文件仍存在于仓库但不再被代码引用
- UnitMeshFactory3D 的程序化生物通过 encounter_id 匹配敌方纹理，如新增遭遇需在 _gen_enemy_by_id() 添加分支
- 所有纹理在首次需要时生成并缓存，不影响性能
- PlayerSpriteAnimator.gd 可安全删除（已无引用方）
- 复活/回复比例（50%/30%）仍未调整，如测试发现过难/过易可调 FloorManager 常量
