# CyberTao: Dice Beast Protocol — 交接包

**生成时间**: 2026-04-01
**当前版本**: v0.1.78
**分支**: codex/dice-beast-protocol

---

## 1. 此刻的精确状态（一句话）

v0.1.78 完成商品池扩展：商店从 5 种基础商品扩展至 9 种，新增加牌（trick x1）、移除牌（skill x1）、随机crest（move x1）、最大HP提升（defend x2）四种策略性商品，连接棋盘层 crest 资源与卡牌层牌组构筑。BUG-002 修复（v0.1.77 hotfix）、3D 单位精灵化（v0.1.77）、BFC 瘦身（v0.1.76）、跨层复活/回复（v0.1.75）、3D 反馈系统（v0.1.74）均稳定。下一步是卡牌战斗层深化。

---

## 2. 本账号完成的工作

| 版本 | 任务 | 状态 |
|------|------|------|
| v0.1.74 | 3D 反馈系统实现（9个桩函数→完整3D特效） | 完成 |
| v0.1.75 | 阵亡单位跨层复活 + 存活单位跨层回复 | 完成 |
| v0.1.76 | BFC 瘦身：FloorManager 独立类 | 完成 |
| v0.1.77 | 3D 单位精灵化（billboard Sprite3D）+ BUG-002 修复 | 完成 |
| v0.1.78 | 商品池扩展（5→9种商品） | 完成 |

---

## 3. 最后版本关键变更

**版本号**: v0.1.78

**修改文件**:
- `Scripts/UI/ShopPanel.gd` — SHOP_ITEM_POOL 5→9种；新增 add_card/remove_card/random_crest/max_hp_up 四种效果；新增牌组过小过滤和前置检查
- `Scripts/UI/DiceDebugPanel.gd` — 版本标记 → v0.1.78

**无新增公开接口**

**无外部信号变更**

**遗留问题**:
- spritesheet 背景透明度（v0.1.70 遗留）
- DiceDebugPanel 仍绑定 2D BoardView（v0.1.71 遗留）
- remove_card 自动选择最弱牌，无手动选择UI
- 敌方/召唤单位使用程序化图标（无独立美术资源）

---

## 4. 下一步任务（精确到可以直接开始）

**立刻要做的**:
根据用户指派的任务方向选择：
- 卡牌战斗层深化：在 `Scripts/BattleV2/CardBattleController.gd` 添加新卡牌效果（如"连击"/"护盾"/"毒素"）和新敌方行为模式
- 敌方单位美术资源：替换 `UnitMeshFactory3D._create_body_sprite()` 中程序化图标为独立 spritesheet

**任务队列**:
1. 卡牌战斗层深化
2. 敌方单位美术资源
3. 商店 remove_card 手动选择UI

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
| remove_card 自动选择最弱牌 | 低 | 否 | 需手动选择时加二级UI |

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

- v0.1.78 商品池扩展纯 UI 层改动，仅修改 ShopPanel.gd，不涉及任何控制器或状态机
- add_card 调用 `CardBattleController._build_reward_pool()`（静态方法），不需要战斗进行中
- remove_card 按 value/cost 比值自动选最弱牌，后续如需手动选择需新增牌组选择 UI（类似 DeckViewPanel 但带选择按钮）
- random_crest 直接写入 `_dice_manager.crest_pool` 字典，DiceManager 当前无 earn 方法
- max_hp_up 同时加 max_hp 和当前 hp，这是有意设计（避免购买后 HP 条反而变低）
- 商品池 9 种每次展示 3 件，概率分布均匀，无权重系统
