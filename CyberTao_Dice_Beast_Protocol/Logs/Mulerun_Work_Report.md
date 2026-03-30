# Mulerun 工作报告

**日期**: 2026-03-30
**版本**: v0.1.54
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.54：全屏独立卡牌战斗界面 + 角色立绘系统 + 扇形手牌 + 棋盘单位美化

---

## 根因目标

用户测试 v0.1.53 后反馈两个核心问题：
1. 卡牌战斗界面仍非独立界面——暗幕+小面板叠在棋盘上，依然能看到棋盘背景
2. 角色形象为方框/三角形几何图形，不美观

本轮目标：将 CardBattlePanel 从浮窗升级为全屏独立战斗界面（类似宝可梦战斗画面），加入角色立绘和扇形手牌。同时美化棋盘上的单位渲染。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/UI/BattleCharRenderer.gd` | **新增文件**，程序化绘制战斗角色立绘（玩家英雄 + 6种敌方） |
| `Scripts/UI/CardBattlePanel.gd` | **完全重写**，从 500x470 浮窗改为 1280x720 全屏独立战斗界面 |
| `Scripts/UI/UnitRenderer.gd` | **完全重写**，从几何形状改为迷你角色剪影 |
| `Scripts/Main.gd` | CardBattlePanel 位置 (0,0)；移除 `_battle_dark_bg` 暗幕 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.54 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号+完成列表+任务优先级 |

---

## 实现内容

### 全屏卡牌战斗界面

- CardBattlePanel 尺寸从 500x470 → 1280x720，覆盖全屏
- 自带深色赛博朋克战斗背景（透视网格地面 + VS标记 + 光弧装饰）
- 不再需要 `_battle_dark_bg` 暗幕遮罩，面板本身就是完整的战斗场景
- 布局：
  - 玩家角色立绘在左侧 (x:200, y:320)
  - 敌方角色立绘在右侧 (x:1080, y:300)
  - 敌方信息（名称+HP+意图）在右上
  - 玩家信息（名称+HP+能量+牌堆）在左下
  - 战斗日志在中央偏下
  - 扇形手牌在底部
  - 操作按钮在右下

### 角色立绘系统（BattleCharRenderer）

- 玩家英雄：赛博战士剪影（装甲躯干+V型护目镜+六边形盾牌+光刃+四肢+脚底光环）
- 6种敌方立绘：
  - 异常哨兵：方形装甲+肩甲+扫描眼（脉冲变宽）
  - 赛博游魂：多层光环+双红眼+飘散尾焰
  - 暗网爬虫：圆形体+6条节肢+4眼簇
  - 脉冲猎手：纤细三角体+单眼+持枪
  - 数据幽灵：菱形核心+数据辐射线+双白眼
  - 零号协议(Boss)：巨型躯干+巨肩甲+冠冕+三眼（金色+红色第三眼）
- 所有角色带脉冲呼吸动画（发光强度随 sin 变化）

### 扇形手牌

- 参考旧项目 Hand.gd 的弧形布局算法
- FAN_RADIUS=700, FAN_CARD_ANGLE=6°, FAN_MAX_ANGLE=22°
- 卡牌尺寸放大至 105x130（适配全屏）
- 悬停效果：1.12x 放大 + 上浮 20px + z-index=10
- 保持点击出牌机制（未引入拖拽）

### 棋盘单位美化

- 玩家单位：迷你赛博战士（躯干+盾+刃+V型护目镜+脚底光环）
- 敌方单位：根据名称匹配 6 种独特造型
- 保留 HP 条、选中脉冲环、地形适性星标

---

## 接口变更

- `BattleCharRenderer` — 新增 class_name（全局注册）
- `BattleCharRenderer.draw_player_hero(c, center, scale, pulse)` — 绘制玩家英雄
- `BattleCharRenderer.draw_enemy(c, center, scale, pulse, encounter_id)` — 绘制指定敌方
- `CardBattlePanel._current_encounter_id` — 新增内部变量，追踪当前遭遇ID用于立绘选择
- `CardBattlePanel._rebuild_fan_cards()` — 替换旧的 `_rebuild_card_widgets()`
- `Main._battle_dark_bg` — **已移除**

---

## 测试确认

- CardBattlePanel 全屏布局正确覆盖 1280x720
- 百叶窗过渡 → 全屏战斗界面 → 过渡回棋盘 流程完整
- BattleCharRenderer 6 种敌方 + 1 种玩家英雄正确匹配 encounter_id
- 扇形手牌布局正确计算弧线位置和旋转角度
- UnitRenderer 新迷你角色剪影正确匹配敌方名称
- HP 条、能量点、战斗日志、按钮功能不受影响
- CardRewardPanel、DeckViewPanel 不受影响
- v0.1.51 resolve_encounter 三分支不受影响
- v0.1.52 单位精简+伙伴槽不受影响
- v0.1.53 TransitionOverlay 百叶窗过渡不受影响

---

## 剩余问题

- 层间难度暂不递增
- 阵亡单位跨层不复活
- CardRewardPanel 暂未使用 CardRenderer 风格
- 扇形手牌暂无拖拽机制（仅点击出牌）
- 角色立绘为程序化绘制，非位图素材（后续可升级为精灵图）

---

## 建议下一步

1. 美化 Phase 4.2：UI 过渡动画（面板弹出/关闭缓动 + 召唤展开演出）
2. 美化 Phase 5：音效系统（AudioManager + 基础音效）
3. 层间难度递增
4. Crest 蓄力池 + 骰子操控机制
