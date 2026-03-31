# CyberTao: Dice Beast Protocol — AI 员工上岗指令 v3

**发布时间**: 2026-03-31
**替代版本**: v1 / v2（旧版本已归档，本文件为唯一有效版本）
**适用项目**: CyberTao: Dice Beast Protocol（骰兽协议）
**适用分支**: `codex/dice-beast-protocol`
**当前版本**: v0.1.64
**引擎**: Godot 4.6.1 | GDScript | renderer: gl_compatibility
**视口**: 1280x720 | stretch mode: canvas_items

---

> **如果你是新接手的 AI，请从 §0 开始顺序阅读。**
> **如果你被要求"执行交接流程"，请直接跳到 §13。**
> **如果你被要求"更新上岗指令"，请直接跳到 §14。**

---

## 0. 你的身份与职责

你是本项目的**执行层 AI 员工**，负责在 Godot 4.6.1 / GDScript 环境下推进开发任务。

你的职责边界：
- ✅ 执行明确的功能任务
- ✅ 写代码、写日志、报告问题
- ✅ 在任务范围内做最小必要的设计判断
- ❌ 不主动重构架构
- ❌ 不自行扩大任务范围
- ❌ 不跳过日志更新

遇到架构级别的判断时：先记录你的判断依据，执行最保守的方案，在日志里标注"需要 Codex 复审"。

---

## 1. 上岗第一步：阅读与确认

### 1.1 强制阅读顺序

```
1. 本文件（AI_Employee_Guide_v3.md）                          ← 当前行为规范
2. Logs/Handoff_Package_latest.md                             ← 最新交接包（如存在，优先级高于 Snapshot）
3. Logs/CyberTao_Migration_Snapshot_zh_v3.md                  ← 项目全貌
4. Logs/Mulerun_Work_Report.md                                ← 上一轮精确状态
5. Logs/changelog_v0.1.md（最后 5 个版本）                    ← 近期变更
```

Logs 目录下还有 v1/v2 版本的 Snapshot 和旧版 Plan 文件，那些是**归档版本，不要引用**。

### 1.2 上岗确认输出

读完后，第一条回复必须包含以下内容，**等用户确认后再开始写任何代码**：

```
【上岗确认 - v0.1.XX】

当前版本：v0.1.XX
上一轮完成的任务：[从 Work Report 读取]

棋盘走位层状态：
  已完成：[列出 5 项以上关键功能]
  稳定性：[稳定 / 有已知问题（说明）]

卡牌战斗层状态：
  已完成：[列出已实现内容]
  缺口：[列出未实现内容]

我的第一步计划：[具体说明]
我识别到的风险：[至少 2 条]
```

---

## 2. 项目背景

### 2.1 双层玩法结构（核心理念）

```
外层：棋盘走位层（已完成，稳定）
  掷骰 → 6种crest资源 → 棋盘移动/踩格触发 → 遭遇格激活卡牌战斗

内层：卡牌战斗层（第一版完成，持续深化中）
  遭遇触发 → CardBattlePanel启动 → 能量/抽牌/出牌/敌方行动/意图预告
           → 胜利奖励选牌 → HP同步回棋盘 → 返回棋盘继续
```

### 2.2 当前完成状态总览（v0.1.60）

**棋盘走位层（全部稳定）**

| 系统 | 版本 | 状态 |
|------|------|------|
| 8x8 棋盘可视化（赛博朋克风格） | v0.1.0 | 稳定 |
| 掷骰 → 6种crest资源池 | v0.1.1 | 稳定 |
| 单位选中 + BFS移动（含地形权重） | v0.1.1 | 稳定 |
| 基础近战攻击（含地形适性加成） | v0.1.4 | 稳定 |
| HP显示 + 胜负判定 + 重新开始 | v0.1.6/12 | 稳定 |
| 攻击反馈（闪光+飘字） | v0.1.12 | 稳定 |
| 敌方AI最小回合（优先攻击/追踪） | v0.1.13 | 稳定 |
| 召唤铺路（SUMMON→路径格+召唤单位） | v0.1.14 | 稳定 |
| 地形系统（高台+陷阱） | v0.1.15 | 稳定 |
| 单位地形适性（3种） | v0.1.19 | 稳定 |
| 道具拾取（2种即时效果） | v0.1.20 | 稳定 |
| 敌方意图广播 + 攻击预警 | v0.1.21 | 稳定 |
| 9种可交互格子（含恢复/事件/商店/宝箱） | v0.1.41 | 稳定 |
| 遭遇暂停与ENCOUNTER阶段 | v0.1.23 | 稳定 |
| 统一赛博朋克视觉风格（CyberStyle） | v0.1.29 | 稳定 |
| DEFEND/SKILL/TRICK crest 消耗入口 | v0.1.33 | 稳定 |
| 棋盘随机生成（BoardGenerator） | v0.1.35 | 稳定 |
| BuffManager 接入（tick_turn+伤害修正+道具buff） | v0.1.39 | 稳定 |
| 多层地图（3层推进+层间奖励+HP保留） | v0.1.42 | 稳定 |
| 美化 Phase 1（BoardCellRenderer+UnitRenderer+高亮升级） | v0.1.45 | 稳定 |
| 美化 Phase 2（DiceRollAnimation+BattleEffects） | v0.1.46 | 稳定 |
| 美化 Phase 3（CardRenderer+CardBattlePanel 重设计） | v0.1.47 | 稳定 |
| 美化 Phase 4.1（CyberBackground 背景氛围升级） | v0.1.48 | 稳定 |
| 掷骰演出升级（伪3D等距骰子+全屏居中） | v0.1.49 | 稳定 |
| Boss锁定+哨兵前置+传送门机制 | v0.1.50 | 稳定 |
| Boss/遭遇格击败消失 Bug 修复（resolve_encounter 三分支） | v0.1.51 | 稳定 |
| 单位精简（1主角+伙伴槽系统）+ 英雄存活制胜负判定 | v0.1.52 | 稳定 |
| Boss解锁自动传送 + 宝可梦式卡牌战斗过渡 | v0.1.53 | 稳定 |
| 全屏独立卡牌战斗界面+角色立绘+扇形手牌+棋盘单位美化 | v0.1.54 | 稳定 |
| 美化 Phase 4.2（UITransitions+面板缓动动画+召唤展开演出） | v0.1.55 | 稳定 |
| 美化 Phase 5（AudioManager+SFXGenerator+全局音效接入+BGM切换） | v0.1.56 | 稳定 |
| 层间难度递增（current_floor缩放敌方HP/ATK） | v0.1.57 | 稳定 |
| 美化 Phase 6（IsoTileRenderer+等距贴图棋盘+BoardView等距化） | v0.1.58 | 稳定 |
| 全屏等距棋盘+叠层UI+高起贴图+角色放大 | v0.1.59 | 稳定 |
| 相机跟随玩家角色+全新素材+UI优化 | v0.1.60 | 稳定 |
| 棋盘渲染回退至程序化（移除AI贴图+程序化菱形绘制） | v0.1.61 | 稳定 |
| 鼠标拖拽相机+平滑跟随+悬停高亮+棋盘扩展12x12 | v0.1.62 | 稳定 |
| 大世界环境填充+缩放+敌方跟随+光标+UI紧凑化 | v0.1.63 | 稳定 |
| 镜头跟随优化+掷骰动画增强 | v0.1.64 | 稳定 |

**卡牌战斗层（第一版完成，持续深化）**

| 系统 | 版本 | 状态 |
|------|------|------|
| 双层闭环首次跑通 | v0.1.25 | 稳定 |
| CardBattleController独立状态机 | v0.1.26 | 稳定 |
| 能量系统（每回合3点，成长至上限5） | v0.1.27/38 | 稳定 |
| 双牌堆系统（抽牌/弃牌/洗牌） | v0.1.27 | 稳定 |
| 3种敌方行为模式 + 意图预告 | v0.1.27 | 稳定 |
| 胜利奖励crest | v0.1.27 | 稳定 |
| 调试快捷按钮（一键测试卡牌战斗） | v0.1.28 | 稳定 |
| 持久牌组系统（跨战斗保留） | v0.1.31 | 稳定 |
| 战斗胜利选牌机制（3选1加入牌组） | v0.1.31 | 稳定 |
| CardRewardPanel 奖励选牌面板 | v0.1.31 | 稳定 |
| 5种遭遇敌方（含3种新敌方） | v0.1.32 | 稳定 |
| 5个遭遇格（覆盖棋盘多条路线） | v0.1.32 | 稳定 |
| DeckViewPanel 牌组查看面板 | v0.1.34 | 稳定 |
| 卡牌升级机制（14种牌升级数据+奖励面板双模式） | v0.1.36 | 稳定 |
| Boss 遭遇（零号协议 HP20/ATK3/6阶段+独立视觉+增强奖励） | v0.1.37 | 稳定 |
| 能量成长机制（遭遇胜利+1/Boss+2，上限5） | v0.1.38 | 稳定 |

### 2.3 当前牌组数据（14种牌，初始10张，均可升级一次）

**初始牌组（10张）**

| 卡牌 | 数量 | 费用 | 效果 | 升级后 |
|------|------|------|------|--------|
| 斩击 | 2 | 1E | 造成3伤害 | 斩击+ → 4伤害 |
| 重击 | 1 | 2E | 造成5伤害 | 重击+ → 7伤害 |
| 防御 | 2 | 1E | 减伤2点 | 防御+ → 减伤3 |
| 修复 | 1 | 1E | 回复2HP | 修复+ → 回复3 |
| 连斩 | 2 | 1E | 造成2伤害 | 连斩+ → 3伤害 |
| 猛攻 | 1 | 3E | 造成8伤害 | 猛攻+ → 11伤害 |
| 急救 | 1 | 2E | 回复4HP | 急救+ → 回复6 |

**奖励卡池（7种，战斗胜利后3选1）**

| 卡牌 | 费用 | 效果 | 升级后 |
|------|------|------|--------|
| 穿刺 | 2E | 无视防御造成4伤害 | 穿刺+ → 6伤害 |
| 铁壁 | 2E | 减伤4点 | 铁壁+ → 减伤6 |
| 吸血斩 | 2E | 造成3伤害+回复1HP | 吸血斩+ → 4伤害+回复2 |
| 超频修复 | 3E | 回复6HP | 超频修复+ → 回复9 |
| 电弧 | 1E | 造成2伤害+敌方ATK-1 | 电弧+ → 3伤害+ATK-1 |
| 强化斩击 | 1E | 造成4伤害 | 强化斩击+ → 6伤害 |
| 双重防御 | 1E | 减伤3点 | 双重防御+ → 减伤4 |

### 2.4 当前遭遇敌方数据

| 遭遇ID | 名称 | HP | ATK | 行为模式 | 定位 | 位置 |
|--------|------|-----|-----|----------|------|------|
| encounter_01 | 异常哨兵 | 8 | 2 | 攻→攻→防击→重击(4回合) | 均衡型 | (4,4) |
| encounter_02 | 赛博游魂 | 4 | 3 | 攻→重击→攻(3回合) | 爆发型 | (6,5) |
| encounter_03 | 暗网爬虫 | 12 | 1 | 防击→防击→重击→攻(4回合) | 坦克型 | (2,2) |
| encounter_04 | 脉冲猎手 | 5 | 4 | 重击→攻→攻(3回合) | 玻璃炮型 | (7,4) |
| encounter_05 | 数据幽灵 | 9 | 2 | 攻→防击→重击→重击→攻(5回合) | 长周期型 | (5,1) |
| encounter_boss_01 | 零号协议 | 20 | 3 | 攻→防攻→重击→回复→攻→超载(6回合) | Boss | 右上象限随机 |

---

## 3. 架构概览

### 3.1 模块结构

```
BattleFlowController（棋盘层核心控制器）         ~693行（含多层地图）
├── DiceManager          — 掷骰 + crest 资源池
├── BoardManager         — 棋盘状态（9个格子字典+locked_encounters+portal_cells + BFS）
├── BoardGenerator       — 棋盘程序化生成（静态工具类）
├── UnitManager          — 单位状态（生成/移动/伤害/击杀）
├── ActionResolver       — 攻击范围计算
├── BuffManager          — buff管理（已接入：tick_turn+伤害修正） ✅
├── BattleAI             — 敌方决策
├── AttackRuleHelper     — 伤害公式
├── VictoryRuleHelper    — 胜负判定
├── CrestActionHandler   — Crest消耗操作（从BFC剥离）      ~66行
└── CellEffectHandler    — 格子效果处理（从BFC剥离）       ~205行

CardBattleController（卡牌层独立状态机）         ~540行
└── 状态：IDLE/PLAYER_TURN/ENEMY_TURN/VICTORY/DEFEAT/REWARD_SELECT

UI层
├── BoardView            — 棋盘渲染+点击交互+反馈动画+相机跟随    ~475行（v0.1.60 相机跟随+边缘渐暗）
├── BoardCellRenderer    — 格子渲染静态类（class_name）   ~210行（Phase 6 后仅供参考）
├── UnitRenderer         — 单位渲染（v0.1.60 scale=1.1+等距适配）  ~270行
├── IsoTileRenderer      — 等距程序化渲染器（class_name）   ~200行 ✅ v0.1.61 程序化重写
├── DiceRollAnimation    — 掷骰演出动画（class_name）     ~252行 ✅ v0.1.49 重写
├── BattleEffects        — 战斗特效静态类（class_name）   ~103行 ✅ Phase 2 新增
├── DiceDebugPanel       — 棋盘层HUD（含层数显示）       ~540行
├── CardRenderer         — 卡牌渲染静态类（class_name）     ~233行 ✅ Phase 3 新增
├── CardBattlePanel      — 卡牌战斗UI（v0.1.54 全屏重设计）  ~420行
├── CardRewardPanel      — 奖励选牌/升级面板             ~230行
├── DeckViewPanel        — 牌组查看面板                 ~160行
├── CyberStyle           — 全局视觉风格（class_name注册）~149行
├── CyberBackground      — 背景氛围系统（class_name注册）  ~155行 ✅ Phase 4.1 新增
├── TransitionOverlay    — 宝可梦式百叶窗过渡（CanvasLayer 10） ~110行 ✅ v0.1.53 新增
├── BattleCharRenderer  — 战斗角色立绘渲染（class_name注册）   ~180行 ✅ v0.1.54 新增
├── UITransitions       — UI过渡动画工具类（class_name注册）    ~60行 ✅ v0.1.55 新增
└── SettingsPanel        — 显示设置

System/
├── DisplaySettings     — 显示设置管理
├── AudioManager        — 音效管理器（class_name注册，多通道SFX+BGM）  ~120行 ✅ v0.1.56 新增
└── SFXGenerator        — 程序化音频引擎（28种音效+4种BGM循环）       ~1100行 ✅ v0.1.56 迁入

Main.gd（场景组合+信号中转+音效触发+相机跟随）                      ~500行
```

### 3.2 双层通信信号链

```
棋盘层                              卡牌层
encounter_triggered ─────────────→ CardBattleController.start_battle()
                                         ↓
                                    battle_ended(victory, hp_remaining)
                                         ↓
resolve_encounter(victory, hp) ←─── Main._on_card_battle_ended()

多层地图信号链（v0.1.50 Boss锁定+传送门）：
击杀哨兵 → _check_battle_outcome() → _try_unlock_boss() → boss_unlocked
踩Boss遭遇格 → _check_encounter() → encounter_triggered → 卡牌战斗
Boss战斗胜利 → resolve_encounter() → _spawn_portal_near() → portal_spawned
踩传送门 → _check_portal() → floor_cleared / game_won
```

### 3.3 关键文件路径

```
主工作目录：CyberTao_Dice_Beast_Protocol/Project/

BattleFlowController：Scripts/BattleV2/BattleFlowController.gd
CardBattleController：Scripts/BattleV2/CardBattleController.gd
BoardManager：        Scripts/BattleV2/BoardManager.gd
BoardGenerator：      Scripts/BattleV2/BoardGenerator.gd
UnitManager：         Scripts/BattleV2/UnitManager.gd
CrestActionHandler：  Scripts/BattleV2/CrestActionHandler.gd
CellEffectHandler：   Scripts/BattleV2/CellEffectHandler.gd
BoardView：           Scripts/UI/BoardView.gd（v0.1.58 等距化重写）
BoardCellRenderer：   Scripts/UI/BoardCellRenderer.gd（Phase 6 后仅供参考）
UnitRenderer：        Scripts/UI/UnitRenderer.gd
IsoTileRenderer：     Scripts/UI/IsoTileRenderer.gd
DiceRollAnimation：   Scripts/UI/DiceRollAnimation.gd
BattleEffects：       Scripts/UI/BattleEffects.gd
DiceDebugPanel：      Scripts/UI/DiceDebugPanel.gd
CardRenderer：        Scripts/UI/CardRenderer.gd
CardBattlePanel：     Scripts/UI/CardBattlePanel.gd
CardRewardPanel：     Scripts/UI/CardRewardPanel.gd
DeckViewPanel：       Scripts/UI/DeckViewPanel.gd
CyberStyle：          Scripts/UI/CyberStyle.gd
CyberBackground：     Scripts/UI/CyberBackground.gd
TransitionOverlay：   Scripts/UI/TransitionOverlay.gd
BattleCharRenderer：  Scripts/UI/BattleCharRenderer.gd
UITransitions：       Scripts/UI/UITransitions.gd
AudioManager：        Scripts/System/AudioManager.gd
SFXGenerator：        Scripts/System/SFXGenerator.gd
Main：                Scripts/Main.gd
旧项目参考（只读）：   [仓库根目录] Scripts/ （不要修改）
```

---

## 4. 技术硬规则

以下规则每一条都有历史 bug 教训，**违反会导致运行时崩溃或静默错误**：

```
✗ 不要用 := 于数组字面量、字符串拼接、untyped数组索引
✗ 不要用 btn.flat = true（StyleBoxFlat 不渲染）
✗ 不要 await 一个不存在的函数（协程永久挂起）
✗ Tween 必须用 node.create_tween()，不用裸 create_tween()
✗ 不要修改仓库根目录旧项目的任何 .gd / .tscn 文件
✗ 不要在 ENCOUNTER 阶段以外调用 resolve_encounter()
✗ 新功能必须在 _bootstrap() 和 restart_battle() 里都注册
✗ 不要修改 BoardManager 的核心字典结构（occupied_cells等）
✗ 卡牌战斗期间不能改变棋盘状态（不动格子、不移动单位）
✗ CardBattleController 的逻辑不能写进 BattleFlowController
✗ 不要往 BoardView.gd 继续堆渲染逻辑（已423行，渲染委托 Renderer）
```

**UI 相关**：
- CyberStyle 已全局注册（`class_name CyberStyle`），无需 preload，直接用 `CyberStyle.xxx`
- 所有新 UI 组件必须使用 CyberStyle 风格化，不要用裸颜色硬编码
- 面板背景用 `CyberStyle.make_panel_bg()`，按钮用 `CyberStyle.style_button(btn, "cyan"/"orange")`

---

## 5. 当前技术债清单

| 问题 | 严重程度 | 是否阻塞 | 建议处理时机 |
|------|----------|----------|--------------|
| ~~BUG-001：分辨率/窗口模式切换无效~~ | ~~低~~ | ~~否~~ | ✅ v0.1.43 已解决 |
| ~~BuffManager.tick_turn() 未接入~~ | ~~中~~ | ~~否~~ | ✅ v0.1.39 已解决 |
| ~~BattleFlowController 795行，需瘦身~~ | ~~中~~ | ~~否~~ | ✅ v0.1.40 已瘦身至588行 |
| BattleFlowController 693行（多层地图后增长） | 中 | 否 | 下次大功能前考虑瘦身 |
| ~~BoardView 640行，职责混杂~~ | ~~中~~ | ~~否~~ | ✅ v0.1.45 Phase 1 瘦身至423行 |
| 电弧牌 ATK-1 效果仅单场生效（设计缺陷） | 低 | 否 | 卡牌数据结构重构时修 |
| 升级数值未经平衡测试 | 低 | 否 | 数值调优轮次 |
| 多层地图难度暂不递增（各层敌方数值相同） | ~~低~~ | ~~否~~ | ✅ v0.1.57 已实现层间难度缩放 |
| 阵亡单位跨层不复活（可能导致后续层过难） | 低 | 否 | 数值调优轮次 |

---

## 6. 下一阶段任务优先级

以下任务来自 v0.1.60 Work Report，按优先级排列：

### 🔴 高优先级（当前阶段核心）

| 任务 | 说明 |
|------|------|
| **相机跟随平滑过渡** | Tween 插值 iso_origin，而非瞬间跳转 |
| **商店格扩展** | 多选商品 + 独立 UI 面板 |

### 🟡 中优先级

| 任务 | 说明 |
|------|------|
| **阵亡单位跨层复活机制** | 防止后续层无伙伴可用 |

### 🟢 中低优先级

| 任务 | 说明 |
|------|------|
| **SettingsPanel 音量控件** | 添加音量滑块 + SFX/BGM 开关 |

### ✅ 已完成

| 任务 | 版本 |
|------|------|
| 棋盘渲染回退至程序化（移除AI贴图） | v0.1.61 |
| 鼠标拖拽相机+平滑跟随+悬停高亮+棋盘扩展12x12 | v0.1.62 |
| 大世界环境填充+缩放+敌方跟随+光标+UI紧凑化 | v0.1.63 |
| 镜头跟随优化（选中即居中+敌方预告）+掷骰动画增强 | v0.1.64 |
| 相机跟随玩家角色+全新素材+UI优化 | v0.1.60 |
| 全屏等距棋盘+叠层UI+高起贴图+角色放大 | v0.1.59 |
| 美化 Phase 6（IsoTileRenderer+等距贴图棋盘+BoardView等距化） | v0.1.58 |
| 层间难度递增（current_floor缩放敌方HP/ATK） | v0.1.57 |
| 美化 Phase 5（AudioManager+SFXGenerator+全局音效接入+BGM切换） | v0.1.56 |
| 美化 Phase 4.2（UITransitions+面板缓动+召唤展开演出） | v0.1.55 |
| 多层地图（3层推进+层间奖励+HP保留） | v0.1.42 |
| BUG-001 修复（分辨率/全屏/无边框/窗口模式切换） | v0.1.43 |
| 美化 Phase 1（BoardCellRenderer+UnitRenderer+高亮升级+BoardView瘦身） | v0.1.45 |
| 美化 Phase 2（DiceRollAnimation+BattleEffects+掷骰演出+攻击增强） | v0.1.46 |
| 美化 Phase 3（CardRenderer+CardBattlePanel 重设计+HP条+能量点） | v0.1.47 |
| 美化 Phase 4.1（CyberBackground 背景氛围升级） | v0.1.48 |
| 掷骰演出升级（伪3D等距骰子+全屏居中） | v0.1.49 |
| Boss锁定+哨兵前置+传送门机制 | v0.1.50 |
| Boss/遭遇格击败消失 Bug 修复 | v0.1.51 |
| 单位精简（1主角+伙伴槽系统）| v0.1.52 |
| Boss解锁自动传送+宝可梦式过渡 | v0.1.53 |
| 全屏独立卡牌战斗界面+角色立绘+扇形手牌 | v0.1.54 |
| 商店格+宝箱格（9种可交互格子） | v0.1.41 |
| BattleFlowController 瘦身（795→588行） | v0.1.40 |
| BuffManager 接入 | v0.1.39 |
| 能量成长机制 | v0.1.38 |
| Boss 遭遇（零号协议） | v0.1.37 |
| 卡牌升级机制 | v0.1.36 |
| 棋盘随机生成 | v0.1.35 |
| 牌组查看面板 | v0.1.34 |
| DEFEND/SKILL/TRICK crest 消耗入口 | v0.1.33 |

### 🔵 长期方向（视觉演出）

| 任务 | 说明 |
|------|------|
| 美化 Phase 4：氛围与细节 | 背景氛围+UI过渡动画+召唤展开演出 |
| 美化 Phase 5：音效系统 | AudioManager + 基础音效接入 |
| 美化 Phase 6：2.5D 棋盘 | ✅ v0.1.58 等距贴图棋盘已实现 |

> 完整美化策略详见 `Logs/Art_Beautification_Strategy_zh.md`

---

## 7. 每轮工作标准流程

```
1. git pull origin codex/dice-beast-protocol
2. 读上一轮 Mulerun_Work_Report.md，确认起点
3. 确认任务边界（服务棋盘层还是卡牌层？都不是则不优先做）
3.5 版本号以 git log 实际为准，目标版本顺延
    （如当前为 v0.1.50，则 P0 目标为 v0.1.51，P1 目标为 v0.1.52）
4. 写代码
5. 自查六项闭环是否完好：
   掷骰 / 移动 / 攻击 / 召唤 / 敌方回合 / 胜负重开
   + 遭遇触发 / 卡牌战斗 / 选牌奖励 / HP同步回棋盘
6. 更新以下四个日志文件（全部强制，缺一不推送）：
   ✅ Logs/Mulerun_Work_Report.md        — 本轮精确状态
   ✅ Logs/changelog_v0.1.md             — 追加版本条目
   ✅ Logs/AI_Employee_Guide_v3.md       — 同步版本号+§2.2完成列表+§6任务优先级
   ✅ 如有架构变化：Logs/CyberTao_Migration_Snapshot_zh_v3.md
7. 提交并推送
8. 聊天里回复一句：已完成 v0.1.XX，日志已写入并推送
```

> **⚠️ 日志完整性检查**：推送前自查——Mulerun_Work_Report.md、changelog_v0.1.md、AI_Employee_Guide_v3.md 是否全部在本次 commit 中？如果缺少任何一个，**停下来补上再推送**。

---

## 8. 日志规范（强制要求）

### 8.1 每轮必须更新

```
必须（每轮，缺一不可）：
  Logs/Mulerun_Work_Report.md            — 本轮精确状态（覆盖）
  Logs/changelog_v0.1.md                 — 版本条目（追加）
  Logs/AI_Employee_Guide_v3.md           — 版本号+完成列表+任务优先级（同步）

条件更新（阶段状态明显变化时）：
  Logs/CyberTao_Migration_Snapshot_zh_v3.md
```

> **注意**：AI_Employee_Guide_v3.md 从 v0.1.52 起由"条件更新"升级为**每轮强制更新**。每个版本完成后至少同步三处：文件头版本号、§2.2 完成列表、§6 已完成任务列表。忘记更新等同于未完成任务。

### 8.2 Work Report 完整格式

```markdown
# Mulerun 工作报告

**日期**: YYYY-MM-DD
**版本**: v0.1.XX
**分支**: codex/dice-beast-protocol

## 本轮任务
[一句话]

## 根因目标
[为什么做这件事，服务棋盘层还是卡牌层]

## 修改文件
| 文件 | 修改内容 |
|------|----------|
| 文件路径 | 改了什么 |

## 实现内容
[具体做了什么，用户能看到什么]

## 接口变更
[新增/修改/删除的信号、方法、数据结构]

## 测试确认
[验证了哪些流程，结果正常或有异常]

## 剩余问题
[已知未解决的问题]

## 建议下一步
[下一轮应该做什么]

## Codex 复审标注（可选）
[如有架构判断，在此说明]
```

### 8.3 Changelog 格式

```markdown
## v0.1.XX - YYYY-MM-DD

### 新增
- [功能点]

### 修改
- [改了什么，为什么]

### 修复
- [bug 根因和修复方式]

### 备注
- [注意事项、已知限制]
```

### 8.4 日志纪律

- **全部写中文**（代码注释和文件路径除外）
- 不要只在聊天里说完成，必须写进文件
- 不要省略任何字段
- 不要合并两轮任务进同一条日志
- 要写过程中的判断和取舍，不只是结果

---

## 9. 禁止事项

```
✗ 不要修改旧项目（仓库根目录任何文件）
✗ 不要把任何逻辑写进 BattleFlowController（已785行）
✗ 不要把卡牌逻辑写进 BoardView 或 DiceDebugPanel
✗ 不要在 ENCOUNTER 阶段允许棋盘操作
✗ 不要在一个任务里自行扩大范围
✗ 不要新增硬编码颜色，统一使用 CyberStyle 常量
✗ 不要跳过日志更新（Work Report + Changelog + AI_Employee_Guide 三件套缺一不可）
```

---

## 10. 遇到问题的处理方式

| 情况 | 处理方式 |
|------|----------|
| 技术 bug | 定位根因，日志写清楚"发现→根因→修复" |
| 设计冲突 | 不自行决定，日志记录冲突，标"需要Codex复审"，选保守方案继续 |
| 范围不清晰 | 先在聊天里澄清，不自行扩大 |
| 发现可以重构的地方 | 写进日志"建议下一步"，不顺手重构 |
| 遇到数值平衡问题 | 先实现，在日志Codex复审标注里说明你的判断 |
| 任务单与仓库不一致 | 发现任务单信息与仓库实际状态不一致（版本号/文件路径/函数名等）→ 不要自行假设，先在聊天里说明差异，等用户确认后再执行 |

---

## 11. 工作哲学

**小步推进，持续可测，每步都有日志。**

每次提交后，以下全部闭环必须能跑通：
- 棋盘层：掷骰 → 移动 → 攻击 → 召唤 → 敌方回合 → 胜负 → 重开
- 卡牌层：遭遇触发 → 卡牌战斗 → 出牌/敌方行动 → 奖励选牌 → HP同步 → 返回棋盘

这是底线，任何新功能都不能破坏它。

---

## 12. 自查触发词

当用户说以下任何词时，你需要执行对应动作：

| 用户说 | 你的动作 |
|--------|----------|
| "执行交接流程" / "准备交接" | 执行 §13 完整流程 |
| "生成交接包" | 只生成 Handoff_Package_latest.md 并推送 |
| "更新上岗指令" / "同步指令" | 执行 §14 完整流程 |
| "理解确认" | 输出 §1.2 格式 |
| "自查" | 检查棋盘+卡牌双层全部闭环 |
| "Codex 复审" | 在 Work Report 复审标注字段说明，等待人工介入 |

---

## 13. 账号交接机制（积分耗尽前执行）

> 当用户说"执行交接流程"或"准备交接"时触发本节。
> **建议在还有 200+ 积分时执行，不要等到断开再做。**

### 13.1 为什么不导出对话

对话包含大量噪音：试错过程、反复确认、废弃方案。
真正有价值的上下文全在 Git 里。交接的本质是生成一个"此刻精确状态的快照"文件。

### 13.2 交接包文件

生成（或覆盖）：
```
CyberTao_Dice_Beast_Protocol/Logs/Handoff_Package_latest.md
```
文件名固定为 `latest`，永远只保留最新一份，新账号只读这一个文件。

### 13.3 交接包标准格式

```markdown
# CyberTao: Dice Beast Protocol — 交接包

**生成时间**: YYYY-MM-DD
**当前版本**: v0.1.XX
**分支**: codex/dice-beast-protocol

---

## 1. 此刻的精确状态（一句话）

[精确描述项目当前状态，例如：
"v0.1.32 完成5种遭遇敌方，持久牌组+奖励选牌已实现，
下一步是牌组查看面板，棋盘层全部稳定。"]

---

## 2. 本账号完成的工作

| 版本 | 任务 | 状态 |
|------|------|------|
| v0.1.XX | [任务名] | 完成/部分完成 |

---

## 3. 最后版本关键变更

**版本号**: v0.1.XX

**修改文件**:
- `文件路径` — 改了什么

**新增接口**:
- `signal xxx(参数)` — 用途
- `func xxx()` — 用途

**遗留问题**:
- [问题及影响]

---

## 4. 下一步任务（精确到可以直接开始）

**立刻要做的**:
[具体到：在哪个文件改什么、预期结果、完成标准]

**任务队列**:
1. [任务]
2. [任务]
3. [任务]

---

## 5. 当前未解决问题清单

| 问题 | 严重程度 | 是否阻塞 | 建议处理时机 |
|------|----------|----------|--------------|
| BUG-001 分辨率切换无效 | 低 | 否 | Demo前 |
| BuffManager 未接入 | 中 | 否 | 下阶段 |
| [其他] | ... | ... | ... |

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

[当前账号对下一账号的补充说明，例如：
- "某某文件第XX行有临时hack，下一步要清理"
- "数值平衡问题见Work Report的Codex复审标注"
- "旧项目CardData.gd可参考，但不要直接复用"]
```

### 13.4 交接后的提交流程

```bash
# 生成/覆盖 Handoff_Package_latest.md
# 更新 Mulerun_Work_Report.md（本轮任务注明"执行账号交接"）

git add CyberTao_Dice_Beast_Protocol/Logs/Handoff_Package_latest.md
git add CyberTao_Dice_Beast_Protocol/Logs/Mulerun_Work_Report.md
git commit -m "chore: 生成账号交接包 v0.1.XX → 下一账号"
git push origin codex/dice-beast-protocol
```

聊天回复：
```
交接包已生成并推送。
新账号克隆仓库后读取 Logs/AI_Employee_Guide_v3.md 和
Logs/Handoff_Package_latest.md 即可启动。
```

### 13.5 交接质量原则

- **精确优于全面**：交接包是"此刻状态快照"，不是项目文档
- **下一步要具体**：不写"继续开发"，要写到文件名和完成标准
- **问题标注影响**：说明是否阻塞下一步
- **不复述全项目**：Snapshot v3 已有，交接包只写增量

---

## 14. 上岗指令自更新机制

> 当用户说"更新上岗指令"或"同步指令"时触发本节。

### 14.1 什么情况下需要更新本文件

- 项目完成了新的阶段性里程碑（如完成一批 Day 任务）
- 架构发生明显变化（新增/删除重要模块）
- 技术债清单有变化（解决了旧债、发现了新债）
- 任务优先级发生重大调整
- 用户明确要求更新

### 14.2 更新流程

```
1. 重新读取以下文件获取最新状态：
   - Logs/Mulerun_Work_Report.md
   - Logs/changelog_v0.1.md（最后5个版本）
   - Logs/CyberTao_Migration_Snapshot_zh_v3.md

2. 更新本文件（AI_Employee_Guide_v3.md）中以下部分：
   - 文件头的"当前版本"
   - §2.2 当前完成状态总览（追加新完成项）
   - §2.3 / §2.4 牌组和敌方数据表（如有变更）
   - §3.1 架构概览中的行数（更新为实际值）
   - §5 技术债清单（标记已解决，追加新债）
   - §6 下一阶段任务优先级（根据最新 Work Report 调整）

3. 不要修改以下部分（规范性内容，保持稳定）：
   - §0 身份职责
   - §4 技术硬规则
   - §7 每轮工作标准流程
   - §8 日志规范
   - §9 禁止事项
   - §10 遇到问题的处理方式
   - §11 工作哲学
   - §13 交接机制（除非流程本身改变）

4. 更新文件头的"发布时间"为今天日期

5. 将更新后的文件同步到 Logs 目录：
   - 覆盖 CyberTao_Dice_Beast_Protocol/Logs/AI_Employee_Guide_v3.md

6. 提交：
   git add CyberTao_Dice_Beast_Protocol/Logs/AI_Employee_Guide_v3.md
   git commit -m "docs: 更新上岗指令 v3 至 v0.1.XX 状态"
   git push origin codex/dice-beast-protocol
```

### 14.3 更新后的回复格式

```
上岗指令已更新至 v0.1.XX 状态并推送。

本次更新内容：
- [更新了什么]
- [更新了什么]
```

---

## 附录：常用文件速查

| 文件 | 用途 | 更新频率 |
|------|------|----------|
| `AI_Employee_Guide_v3.md` | 本文件，行为规范 | 里程碑后更新 |
| `Handoff_Package_latest.md` | 最新交接包 | 交接时覆盖 |
| `CyberTao_Migration_Snapshot_zh_v3.md` | 项目全貌+架构 | 阶段性更新 |
| `Mulerun_Work_Report.md` | 上一轮精确状态 | 每轮覆盖 |
| `changelog_v0.1.md` | 完整版本历史 | 每轮追加 |
| `Board_Card_Battle_Concept_zh.md` | 双层玩法设计文档 | 设计变更时 |
| `Demo_Roadmap_2p5D_zh.md` | 中长期路线图 | 阶段性更新 |
| `Art_Beautification_Strategy_zh.md` | 美术美化推进策略（6阶段） | 美化阶段参考 |
