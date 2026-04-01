# CyberTao: Dice Beast Protocol — 交接包

**生成时间**: 2026-04-01
**当前版本**: v0.1.79
**分支**: codex/dice-beast-protocol

---

## 1. 此刻的精确状态（一句话）

v0.1.79 完成卡牌战斗层深化：新增毒素注入/能量虹吸/反击/裂空斩 4 种机制性卡牌，buff/multi_attack 2 种敌方行为模式，量子分裂体/赛博巫医 2 个新遭遇。奖励卡池从 7 种扩展至 11 种（含初始牌共 17 张），遭遇池从 5 扩展至 7。商品池扩展（v0.1.78）、3D 精灵化（v0.1.77）、BFC 瘦身（v0.1.76）均稳定。下一步是敌方单位美术资源或数值平衡调优。

---

## 2. 本账号完成的工作

| 版本 | 任务 | 状态 |
|------|------|------|
| v0.1.74 | 3D 反馈系统实现（9个桩函数→完整3D特效） | 完成 |
| v0.1.75 | 阵亡单位跨层复活 + 存活单位跨层回复 | 完成 |
| v0.1.76 | BFC 瘦身：FloorManager 独立类 | 完成 |
| v0.1.77 | 3D 单位精灵化（billboard Sprite3D）+ BUG-002 修复 | 完成 |
| v0.1.78 | 商品池扩展（5→9种商品） | 完成 |
| v0.1.79 | 卡牌战斗层深化（4新卡+2新行为+2新遭遇） | 完成 |

---

## 3. 最后版本关键变更

**版本号**: v0.1.79

**修改文件**:
- `Scripts/BattleV2/CardBattleController.gd` — 状态效果变量 + 4 种卡牌结算 + 毒素结算 + 反击触发 + 2 种敌方行为 + 2 个遭遇数据 + 奖励/升级扩展
- `Scripts/UI/CardRenderer.gd` — TYPE_COLORS/ICONS/LABELS +4 项 + _format_value +4 种
- `Scripts/BattleV2/BoardGenerator.gd` — ENCOUNTER_IDS +2
- `Scripts/Main.gd` — 遭遇显示名 +2
- `Scripts/UI/BattleCharRenderer.gd` — 敌方立绘 +2
- `Scripts/UI/CardBattlePanel.gd` — 意图图标 +2
- `Scripts/UI/DiceDebugPanel.gd` — 版本标记 → v0.1.79

**无新增公开接口/信号**

**遗留问题**:
- 新卡牌/新敌方数值未经平衡测试
- 敌方/召唤单位使用程序化图标（无独立美术资源）
- remove_card 自动选择最弱牌（无手动选择UI）

---

## 4. 下一步任务（精确到可以直接开始）

**立刻要做的**:
根据用户指派的任务方向选择：
- 敌方单位美术资源：替换 `UnitMeshFactory3D._create_body_sprite()` 中程序化图标为独立 spritesheet
- 数值平衡调优：卡牌费用/伤害、敌方 HP/ATK/行为模式、商品价格、复活回复比例

**任务队列**:
1. 敌方单位美术资源
2. 数值平衡调优
3. 商店 remove_card 手动选择UI

---

## 5. 当前未解决问题清单

| 问题 | 严重程度 | 是否阻塞 | 建议处理时机 |
|------|----------|----------|--------------|
| spritesheet 背景透明度待确认 | 中 | 否 | 用户测试后处理 |
| DiceDebugPanel 绑定 2D BoardView | 低 | 否 | 3D 完善轮次 |
| 商店 ATK/DEF 提升未走 BuffManager | 低 | 否 | 如需回合限制时改 |
| 新卡牌/新敌方数值未经平衡测试 | 低 | 否 | 数值调优轮次 |
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

- v0.1.79 新增了 _poison_turns/_poison_dmg/_counter_dmg 三个战斗状态变量，每次 start_battle 会重置
- 毒素在 end_turn 中结算（敌方行动前），不在 _enemy_act 中。如果要改为"敌方回合结束后结算"，移动毒素代码到 _enemy_act 之后即可
- 反击通过 _resolve_counter() 统一处理，返回字符串拼接到 enemy_acted 文本。所有攻击类行为末尾都调用了它
- combo 连击对 _enemy_def_bonus 有消耗效果（每击消耗），这是设计意图不是 bug
- buff 行为使 enemy_atk 永久增加，这个值在战斗结束后不保留（每次 start_battle 重新从 enemy_data 读取）
- multi_attack 的 60% 系数是 int(float * 0.6)，对低 ATK 敌方可能只有 1 伤害/击
- 新遭遇 06/07 已加入 BoardGenerator.ENCOUNTER_IDS，棋盘生成时会随机选取
- CardRenderer 的 TYPE 字典是 const Dictionary，新增类型后不需要其他配置
