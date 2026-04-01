# CyberTao: Dice Beast Protocol — 交接包

**生成时间**: 2026-04-01
**当前版本**: v0.1.80
**分支**: codex/dice-beast-protocol

---

## 1. 此刻的精确状态（一句话）

v0.1.80 完成首轮数值平衡调优：修正能量虹吸（cost 0→1）、毒素注入（3→2回合）、反击（2def+3dmg→1def+2dmg）、脉冲猎手（首回合不再重击）、赛博巫医（HP 11→9）、赛博彩票（cost x1→x2）共 6 项数值。卡牌战斗层深化（v0.1.79）、商品池扩展（v0.1.78）、3D 精灵化（v0.1.77）均稳定。敌方美术资源阻塞中（无 spritesheet），下一步可选商店手动选牌UI或新遭遇/Boss。

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

---

## 3. 最后版本关键变更

**版本号**: v0.1.80

**修改文件**:
- `Scripts/BattleV2/CardBattleController.gd` — 3张卡牌数值 + 2个遭遇数值 + 升级数据
- `Scripts/UI/ShopPanel.gd` — 赛博彩票费用
- `Scripts/UI/DiceDebugPanel.gd` — 版本标记 → v0.1.80

**无新增接口/信号**，纯数值调整

---

## 4. 下一步任务

**任务队列**:
1. 敌方单位美术资源（阻塞：需美术资源 PNG）
2. 商店 remove_card 手动选择UI
3. 更多遭遇/Boss

---

## 5. 当前未解决问题清单

| 问题 | 严重程度 | 是否阻塞 | 建议处理时机 |
|------|----------|----------|--------------|
| 敌方/召唤使用程序化图标 | 低 | 否（功能不受影响） | 美术资源就绪后 |
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

- v0.1.80 纯数值调整，无架构变更
- 平衡基线：斩击(3伤/1E)=3.0 DPE，超过4.0的卡牌需有附加限制（延迟/条件/多段被防御克制等）
- 脉冲猎手的调整仅改变攻击顺序，ATK=4仍是最高（第2回合重击8伤仍很致命，但给了准备时间）
- 赛博巫医 HP 9 + 每5回合 heal 3 + buff，实际有效HP约12，仍需策略性应对
- 复活/回复比例（50%/30%）本轮未调整，如测试发现过难/过易可调 FloorManager 常量
