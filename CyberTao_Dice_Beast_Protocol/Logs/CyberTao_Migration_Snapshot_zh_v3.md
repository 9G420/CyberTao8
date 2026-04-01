# CyberTao: Dice Beast Protocol 项目迁移快照（中文 v3）

**更新时间**: 2026-04-01
**当前版本**: v0.1.72
**GitHub 仓库**: `https://github.com/9G420/CyberTao8`
**主要开发分支**: `codex/dice-beast-protocol`
**主工作目录**: `CyberTao_Dice_Beast_Protocol/Project/`
**引擎**: Godot 4.6.1 | GDScript | renderer: gl_compatibility
**视口**: 1280x720 | stretch mode: canvas_items

---

## 0. 新接手 AI 必读（快速上手指南）

**你正在接手一个 Godot 赛博朋克战术 Roguelike 项目。** 请按以下顺序阅读文件：

1. **`Logs/AI_Employee_Guide_v3.md`** — AI 员工上岗指令（行为规范+技术硬规则+日志规范）
2. **`Logs/Handoff_Package_latest.md`** — 最新交接包（如存在，优先级高于本文件）
3. **本文件**（`Logs/CyberTao_Migration_Snapshot_zh_v3.md`）— 项目全貌、架构、数据结构、当前状态
4. **`Logs/Mulerun_Work_Report.md`** — 最近一轮工作报告
5. **`Logs/changelog_v0.1.md`** — 完整版本变更记录（v0.1.0 ~ v0.1.60）

**关键规则：**
- **只在 `CyberTao_Dice_Beast_Protocol/Project/` 目录下开发**，不要修改旧项目 `CyberTao8` 根目录
- **所有日志必须写中文**
- 每轮任务完成后必须更新三件套：`Mulerun_Work_Report.md` + `changelog_v0.1.md` + `AI_Employee_Guide_v3.md`
- 每次任务前确认：服务于棋盘走位层 or 卡牌战斗层，两者都不是则不优先做

**当前阶段状态：双层玩法结构完整闭环，卡牌战斗层第一版完成并持续深化，美化 Phase 1~6 全部完成，等距贴图棋盘+相机跟随+鼠标拖拽+缩放+角色形象重构+逐格移动动画+卡牌拖拽出牌+头像HUD+玩家精灵动画已实现。3D 渐进迁移 P0 完成（BoardView3D+SubViewport+F5切换双视图），v0.1.72 完成 3D 交互手感修复（拖拽+镜头跟随+边界限制+缩放轴心）。下一阶段聚焦 3D 反馈系统或商店格扩展。**

---

## 1. 项目定位

`CyberTao: Dice Beast Protocol（骰兽协议）` 是旧项目 `CyberTao8` 的并行重构方向。

**正式主玩法方向（v0.1.22 起生效）：**

### "骰子走位棋盘推进 + 遭遇触发卡牌战斗"

双层玩法结构：

1. **外层：棋盘走位层** — 掷骰获得资源 → 在棋盘上移动/走位/踩格 → 路线选择/抢点/占高台/避陷阱/铺路推进 → 触发遭遇
2. **内层：卡牌战斗层** — 遭遇触发后切入 → 抽牌/出牌/能量费用/攻防博弈/构筑成长 → 战斗结算 → 回到棋盘继续

核心理念：
- 棋盘层负责"走到哪里、遇到什么、占什么优势"
- 卡牌层负责"真正打起来时怎么赢"
- 两层互相增益：棋盘走位影响战斗条件，战斗结果影响棋盘推进

风格标签：骰子驱动 / 怪兽对抗 / 召唤铺路 / CN meme / 赛博 furry

---

## 2. 当前已完成内容（v0.1.0 → v0.1.72）

### 棋盘走位层（外层 — 全部稳定）

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
| 遭遇暂停与ENCOUNTER阶段 | v0.1.23 | 稳定 |
| 统一赛博朋克视觉风格（CyberStyle） | v0.1.29 | 稳定 |
| DEFEND/SKILL/TRICK crest 消耗入口 | v0.1.33 | 稳定 |
| 棋盘随机生成（BoardGenerator） | v0.1.35 | 稳定 |
| BuffManager 接入（tick_turn+伤害修正+道具buff） | v0.1.39 | 稳定 |
| BattleFlowController 瘦身（795→588行，CrestActionHandler+CellEffectHandler 剥离） | v0.1.40 | 稳定 |
| 9种可交互格子（含恢复/事件/商店/宝箱） | v0.1.41 | 稳定 |
| 多层地图（3层推进+层间奖励+HP保留） | v0.1.42 | 稳定 |
| BUG-001 修复（分辨率/全屏/无边框/窗口模式切换） | v0.1.43 | 稳定 |
| 美化 Phase 1（BoardCellRenderer+UnitRenderer+高亮升级） | v0.1.45 | 稳定 |
| 美化 Phase 2（DiceRollAnimation+BattleEffects） | v0.1.46 | 稳定 |
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
| 敌方回合镜头跟随优化（移动跟踪+延迟切回+柔和过渡） | v0.1.65 | 稳定 |
| 角色形象重构（咩咩启示录风格）+音效设置面板 | v0.1.66 | 稳定 |
| 移动逐格行走动画+敌方移动动画+我方回合镜头切回优化 | v0.1.67 | 稳定 |
| 卡牌拖拽出牌+即时伤害反馈 | v0.1.68 | 稳定 |
| 顶部单位头像 HUD | v0.1.69 | 稳定 |
| 玩家角色精灵动画（4方向 spritesheet） | v0.1.70 | 稳定 |
| 3D 渐进迁移 P0（BoardView3D+SubViewport+F5切换双视图） | v0.1.71 | 稳定 |
| 3D 交互手感修复（拖拽+镜头跟随+边界限制+缩放轴心） | v0.1.72 | 稳定 |

### 卡牌战斗层（内层 — 第一版完成，持续深化）

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
| 美化 Phase 3（CardRenderer+CardBattlePanel 重设计） | v0.1.47 | 稳定 |

### 视觉演出系统

| 系统 | 版本 | 状态 |
|------|------|------|
| CyberStyle 统一风格系统（class_name 全局注册） | v0.1.29 | 稳定 |
| BoardCellRenderer 格子渲染（9种格子+Boss锁定+传送门） | v0.1.45/50 | 稳定 |
| UnitRenderer 单位渲染（迷你角色剪影） | v0.1.54 | 稳定 |
| DiceRollAnimation 伪3D等距骰子演出 | v0.1.49 | 稳定 |
| BattleEffects 战斗特效 | v0.1.46 | 稳定 |
| CardRenderer 卡牌渲染（6种类型独立配色+升级标记） | v0.1.47 | 稳定 |
| CyberBackground 背景氛围（渐变+网格+粒子+扫描线） | v0.1.48 | 稳定 |
| TransitionOverlay 宝可梦式百叶窗过渡 | v0.1.53 | 稳定 |
| BattleCharRenderer 战斗角色立绘（玩家+6种敌方） | v0.1.54 | 稳定 |
| UITransitions UI过渡动画工具类 | v0.1.55 | 稳定 |
| AudioManager+SFXGenerator 程序化音效系统（28种SFX+4种BGM） | v0.1.56 | 稳定 |
| IsoTileRenderer 等距贴图渲染器（TILE_W=192） | v0.1.58/60 | 稳定 |
| UnitPortraitHUD 顶部单位头像 HUD | v0.1.69 | 稳定 |
| PlayerSpriteAnimator 玩家精灵动画（4方向 spritesheet） | v0.1.70 | 稳定 |
| GridMapper3D 格坐标↔3D世界坐标转换 | v0.1.71 | 稳定 |
| TileMeshFactory3D 9种格子 BoxMesh+StandardMaterial3D 工厂 | v0.1.71 | 稳定 |
| UnitMeshFactory3D 单位 CapsuleMesh/CylinderMesh+billboard HP 条 | v0.1.71 | 稳定 |
| BoardView3D 完整 3D 棋盘视图（信号接口对齐 BoardView） | v0.1.71/72 | 稳定 |

### 双层闭环完整流程（v0.1.72）

```
棋盘走位层                              卡牌战斗层
掷骰 → 获得 crest
选中单位 → 移动/攻击/召唤
踩遭遇格 → ENCOUNTER 暂停
  → 百叶窗过渡（TransitionOverlay）──→ CardBattleController.start_battle()
                                        ↓
                                      全屏战斗界面（角色立绘+扇形手牌）
                                        ↓
                                      抽牌 3 张 → 显示意图
                                        ↓
                                      玩家出牌（消耗能量）→ 效果结算
                                        ↓
                                      结束回合 → 弃手牌 → 敌方行动
                                        ↓
                                      循环至一方 HP ≤ 0
                                        ↓
                                      胜利 → 奖励选牌（3选1 新牌/升级）
                                        ↓
  ← 百叶窗过渡回棋盘 ←───────────── battle_ended 信号
棋盘单位 HP 同步 ←──────────────── resolve_encounter(victory, hp)
  胜利 → 遭遇格消失（Boss→生成传送门）
  失败但存活 → 遭遇格保留，HP保底1，可再战
  失败全灭 → DEFEAT

多层地图信号链（v0.1.50+）：
击杀哨兵 → _check_battle_outcome() → _try_unlock_boss() → boss_unlocked
踩Boss遭遇格 → encounter_triggered → 卡牌战斗
Boss胜利 → resolve_encounter() → _spawn_portal_near() → portal_spawned
踩传送门 → _check_portal() → floor_cleared / game_won
```

### 玩家单位（v0.1.52 精简后）

| 单位 | 定位 | HP | ATK | DEF | 移动 | 攻击范围 | 适性 |
|------|------|-----|-----|-----|------|----------|------|
| 刀盾狗（英雄） | 前排坦克 | 8 | 3 | 1 | 1 | 1 | 路径（DEF+1） |
| 伙伴（召唤） | 辅助 | — | — | — | — | — | 每层上限2次/场上1只 |

> 灵狐骇客、鸦机术士在 v0.1.52 移除出场，仅保留 1 主角 + 伙伴槽系统

### 6 个遭遇敌方（v0.1.32/37）

| 遭遇ID | 名称 | HP | ATK | 行为模式 | 定位 |
|--------|------|-----|-----|----------|------|
| encounter_01 | 异常哨兵 | 8 | 2 | 攻→攻→防击→重击(4回合) | 均衡型 |
| encounter_02 | 赛博游魂 | 4 | 3 | 攻→重击→攻(3回合) | 爆发型 |
| encounter_03 | 暗网爬虫 | 12 | 1 | 防击→防击→重击→攻(4回合) | 坦克型 |
| encounter_04 | 脉冲猎手 | 5 | 4 | 重击→攻→攻(3回合) | 玻璃炮型 |
| encounter_05 | 数据幽灵 | 9 | 2 | 攻→防击→重击→重击→攻(5回合) | 长周期型 |
| encounter_boss_01 | 零号协议 | 20 | 3 | 攻→防攻→重击→回复→攻→超载(6回合) | Boss |

### 14种卡牌牌组（v0.1.36 升级机制）

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

---

## 3. 架构概述

### BattleV2 模块化架构

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
├── VictoryRuleHelper    — 胜负判定（has_hero_unit 英雄存活制）
├── CrestActionHandler   — Crest消耗操作（从BFC剥离）      ~66行
└── CellEffectHandler    — 格子效果处理（从BFC剥离）       ~205行

CardBattleController（卡牌层独立状态机）         ~540行
└── 状态：IDLE/PLAYER_TURN/ENEMY_TURN/VICTORY/DEFEAT/REWARD_SELECT
```

### UI 层

```
Main.gd（场景组合+信号中转+音效触发+相机跟随+3D视图路由）       ~670行
├── BoardView            — 棋盘渲染+点击交互+反馈动画+相机跟随    ~610行（v0.1.70 精灵动画）
├── BoardCellRenderer    — 格子渲染静态类（class_name）   ~210行（Phase 6 后仅供参考）
├── UnitRenderer         — 单位渲染（v0.1.66 咩咩启示录风格）  ~490行
├── IsoTileRenderer      — 等距程序化渲染器（class_name）   ~200行 ✅ v0.1.61 程序化重写
├── PlayerSpriteAnimator — 玩家精灵动画管理器（class_name）  ~70行 ✅ v0.1.70 新增
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
├── BattleCharRenderer   — 战斗角色立绘渲染（class_name注册）   ~180行 ✅ v0.1.54 新增
├── UITransitions        — UI过渡动画工具类（class_name注册）    ~60行 ✅ v0.1.55 新增
├── UnitPortraitHUD      — 顶部单位头像 HUD（class_name注册）   ~130行 ✅ v0.1.69 新增
└── SettingsPanel        — 显示设置+音量控件

UI3D/（v0.1.71 新增 — 3D 渐进迁移表现层）
├── GridMapper3D         — 格坐标↔3D世界坐标转换（class_name，纯数学工具）  ~40行 ✅ v0.1.71 新增
├── TileMeshFactory3D    — 9种格子 BoxMesh+StandardMaterial3D 工厂（class_name）  ~120行 ✅ v0.1.71 新增
├── UnitMeshFactory3D    — 单位 CapsuleMesh/CylinderMesh+billboard HP 条（class_name）  ~130行 ✅ v0.1.71 新增
└── BoardView3D          — 完整 3D 棋盘视图（SubViewport 嵌入+信号接口对齐 BoardView）  ~380行 ✅ v0.1.71 新增 / v0.1.72 交互修复

System/
├── AudioManager         — 音效管理器（class_name注册，多通道SFX+BGM）  ~120行 ✅ v0.1.56 新增
└── SFXGenerator         — 程序化音频引擎（28种音效+4种BGM循环）       ~1100行 ✅ v0.1.56 迁入
```

### 信号体系

```
棋盘层信号（BattleFlowController）：
  setup_completed / phase_changed / round_changed
  move_completed / attack_completed / enemy_attack_completed
  summon_completed / terrain_damage_triggered / item_picked_up
  enemy_action_announced / enemy_turn_ended
  encounter_triggered / encounter_resolved
  heal_cell_triggered / event_cell_triggered
  boss_unlocked / portal_spawned / hero_warped       ← v0.1.50/53 新增
  floor_cleared / game_won                           ← v0.1.42 新增

卡牌层信号（CardBattleController）：
  battle_started / hand_changed / card_played
  enemy_acted / enemy_intent_changed / turn_resolved
  battle_ended / victory_reward

调试信号（DiceDebugPanel）：
  test_card_battle_requested
```

### 关键数据结构

```
BoardManager:
  occupied_cells: Dictionary     # cell -> unit_id
  path_cells: Dictionary         # cell -> owner_id
  item_cells: Dictionary         # cell -> item_id
  terrain_cells: Dictionary      # cell -> "high_ground" / "trap"
  encounter_cells: Dictionary    # cell -> encounter_id
  heal_cells: Dictionary         # cell -> int (heal_amount)
  event_cells: Dictionary        # cell -> String (event_id)
  shop_cells: Dictionary         # cell -> shop_data          ← v0.1.41 新增
  chest_cells: Dictionary        # cell -> chest_data         ← v0.1.41 新增
  locked_encounters: Dictionary  # cell -> bool               ← v0.1.50 新增
  portal_cells: Dictionary       # cell -> bool               ← v0.1.50 新增

UnitManager:
  units_by_id: Dictionary     # unit_id -> {hp, max_hp, atk, def, move_range, attack_range, owner, cell, terrain_affinity, display_name, is_summoned}
  units_by_cell: Dictionary   # cell -> unit_id

DiceManager:
  crest_pool: Dictionary      # "summon"/"move"/"attack"/"defend"/"skill"/"trick" -> int

CardBattleController:
  _draw_pile: Array           # 抽牌堆
  _discard_pile: Array        # 弃牌堆
  _hand: Array                # 当前手牌（每张 = {name, type, value, cost, upgraded}）
  energy / max_energy: int    # 当前能量 / 每回合能量上限（3起步，上限5）
  _enemy_pattern: Array       # 敌方行为循环序列
  _persistent_deck: Array     # 持久牌组（跨战斗保留）      ← v0.1.31 新增
```

### 战斗阶段流程

```
棋盘层:
  BattlePhase: BOOT → PLAYER_ROLL → PLAYER_ACTION → [ENCOUNTER] → ENEMY_ROLL → ENEMY_ACTION → (loop)
  终态: VICTORY / DEFEAT
  遭遇分支: PLAYER_ACTION → ENCOUNTER → [百叶窗过渡] → [全屏卡牌战斗] → resolve_encounter(三分支) → PLAYER_ACTION
  Boss 链: 哨兵全灭 → Boss解锁 → 英雄自动传送 → Boss战斗 → 传送门 → 下一层/通关

卡牌层:
  BattleState: IDLE → PLAYER_TURN → ENEMY_TURN → (loop) → VICTORY → REWARD_SELECT / DEFEAT
```

### 关键代码路径

- **移动后检查顺序**：`try_move_unit()` → `_check_terrain_trap()` → `_check_item_pickup()` → `_check_heal_cell()` → `_check_event_cell()` → `_check_encounter()` → `_check_portal()`
- **点击优先级**：attack > move > summon
- **伤害公式**：`max(1, attacker.atk - defender.def - terrain_bonus)`
- **保底机制**：每次掷骰保底 1 MOVE crest
- **遭遇触发链**：`encounter_triggered` → Main.gd → TransitionOverlay 百叶窗 → `CardBattleController.start_battle()` → 全屏战斗界面 → `battle_ended` → 百叶窗回棋盘 → `resolve_encounter(三分支)`
- **resolve_encounter 三分支**（v0.1.51）：胜利→清遭遇格（Boss生传送门）；失败存活→遭遇格保留HP保底1；失败全灭→DEFEAT

---

## 4. 已知问题与技术债

| 问题 | 严重程度 | 是否阻塞 | 说明 |
|------|----------|----------|------|
| ~~BUG-001：分辨率/窗口模式切换无效~~ | ~~低~~ | ~~否~~ | ✅ v0.1.43 已解决 |
| ~~BuffManager.tick_turn() 未接入~~ | ~~中~~ | ~~否~~ | ✅ v0.1.39 已解决 |
| ~~BattleFlowController 795行~~ | ~~中~~ | ~~否~~ | ✅ v0.1.40 已瘦身至588行 |
| BattleFlowController 693行（多层地图后增长） | 中 | 否 | 下次大功能前考虑瘦身 |
| 电弧牌 ATK-1 效果仅单场生效（设计缺陷） | 低 | 否 | 卡牌数据结构重构时修 |
| 升级数值未经平衡测试 | 低 | 否 | 数值调优轮次 |
| 多层地图难度暂不递增（各层敌方数值相同） | ~~低~~ | ~~否~~ | ✅ v0.1.57 已实现层间难度缩放 |
| 阵亡单位跨层不复活（可能导致后续层过难） | 低 | 否 | 数值调优轮次 |
| CardRewardPanel 未使用 CardRenderer 风格 | 低 | 否 | UI 统一轮次 |
| 扇形手牌无拖拽（仅点击出牌） | ~~低~~ | ~~否~~ | ✅ v0.1.68 已实现拖拽出牌 |
| spritesheet 背景透明度待确认 | 中 | 否 | 用户测试后处理 |
| 3D 反馈方法为桩函数（play_attack_feedback 等） | 中 | 否 | 3D 迭代 P1 |
| 3D 单位为简单几何体（CapsuleMesh/CylinderMesh） | 低 | 否 | 3D 迭代 P2 |
| DiceDebugPanel 绑定 2D BoardView（3D 模式下无交互适配） | 低 | 否 | 3D 完善轮次 |
| BoardView3D.rebuild_board() 全量重建（大棋盘性能开销） | 低 | 否 | 3D 优化轮次 |

---

## 5. 下一阶段推进建议

### 当前阶段核心方向：体验打磨 + 功能扩展

v0.1.31~v0.1.72 完成了卡牌深化、全面美化（Phase 1~6）、等距棋盘+相机系统+鼠标拖拽+角色形象重构+逐格移动动画+卡牌拖拽出牌+头像HUD+玩家精灵动画+3D 渐进迁移 P0+3D 交互手感修复。

### 🔴 高优先级

1. **3D 反馈系统实现** — 粒子特效/3D 飘字替代 2D BattleEffects
2. **商店格扩展** — 多选商品 + 独立 UI 面板

### 🟡 中优先级

2. **阵亡单位跨层复活机制** — 防止后续层无伙伴可用
3. **BattleFlowController 瘦身** — 当前约 710 行
4. **3D 单位精灵化** — billboard sprite 或低多边形模型替代简单几何体

### 🟢 中低优先级

4. ~~**相机跟随平滑过渡**~~ — ✅ v0.1.64/65 已完成
5. ~~**SettingsPanel 音量控件**~~ — ✅ v0.1.66 已完成

### 🔵 长期方向

5. ~~**等距角色专属贴图**~~ — ✅ v0.1.70 玩家角色已使用精灵动画
6. **敌方角色精灵化** — 替代程序化敌方剪影
7. **Crest 蓄力池 + 骰子操控机制**
8. **存档系统** — 最小存档/读档

---

## 6. 核心文件索引

### 源代码文件（`Project/Scripts/` 下）

| 文件路径 | 职责 | 行数参考 |
|----------|------|----------|
| `BattleV2/BattleFlowController.gd` | 棋盘层核心控制器：阶段管理/多层地图/Boss锁定传送门 | ~693 行 |
| `BattleV2/CardBattleController.gd` | 卡牌层独立控制器：能量/双牌堆/持久牌组/升级/6种敌方/Boss | ~540 行 |
| `BattleV2/BoardManager.gd` | 棋盘状态：9+2 个格子字典 + BFS 移动 | ~150 行 |
| `BattleV2/BoardGenerator.gd` | 棋盘程序化生成（静态工具类） | ~200 行 |
| `BattleV2/UnitManager.gd` | 单位状态：生成/移动/伤害/击杀 | ~90 行 |
| `BattleV2/ActionResolver.gd` | 攻击范围计算（含地形适性加成） | ~50 行 |
| `BattleV2/DiceManager.gd` | 掷骰 + crest 资源池管理 | ~60 行 |
| `BattleV2/BattleAI.gd` | 敌方 AI（优先攻击/追踪最近玩家） | ~80 行 |
| `BattleV2/BuffManager.gd` | buff 管理（tick_turn 已接入） | ~30 行 |
| `BattleV2/AttackRuleHelper.gd` | 伤害公式 | ~15 行 |
| `BattleV2/VictoryRuleHelper.gd` | 胜负判定（has_hero_unit+has_grunt_units） | ~30 行 |
| `BattleV2/CrestActionHandler.gd` | Crest 消耗操作（从 BFC 剥离） | ~66 行 |
| `BattleV2/CellEffectHandler.gd` | 格子效果处理（从 BFC 剥离） | ~205 行 |
| `UI/BoardView.gd` | 棋盘渲染 + 点击交互 + 反馈动画 + 相机跟随 + 精灵动画 | ~610 行 |
| `UI/BoardCellRenderer.gd` | 格子渲染静态类（Phase 6 后仅供参考） | ~210 行 |
| `UI/UnitRenderer.gd` | 单位渲染（v0.1.66 咩咩启示录风格） | ~490 行 |
| `UI/IsoTileRenderer.gd` | 等距程序化渲染器（TILE_W=192+相机跟随） | ~200 行 |
| `UI/PlayerSpriteAnimator.gd` | 玩家精灵动画管理器（4方向 spritesheet） | ~70 行 |
| `UI/DiceRollAnimation.gd` | 掷骰演出（伪3D等距骰子） | ~252 行 |
| `UI/BattleEffects.gd` | 战斗特效静态类 | ~103 行 |
| `UI/DiceDebugPanel.gd` | 棋盘层 HUD（crest 池/阶段/层数/部署提示） | ~540 行 |
| `UI/CardRenderer.gd` | 卡牌渲染静态类（6种类型配色） | ~233 行 |
| `UI/CardBattlePanel.gd` | 全屏卡牌战斗 UI（1280x720+立绘+扇形手牌） | ~420 行 |
| `UI/CardRewardPanel.gd` | 奖励选牌/升级面板 | ~230 行 |
| `UI/DeckViewPanel.gd` | 牌组查看面板 | ~160 行 |
| `UI/CyberStyle.gd` | 统一赛博朋克视觉风格（全局 class_name） | ~149 行 |
| `UI/CyberBackground.gd` | 背景氛围系统（渐变+网格+粒子+扫描线） | ~155 行 |
| `UI/TransitionOverlay.gd` | 宝可梦式百叶窗过渡（CanvasLayer 10） | ~110 行 |
| `UI/BattleCharRenderer.gd` | 战斗角色立绘渲染（玩家+6种敌方） | ~180 行 |
| `UI/UITransitions.gd` | UI过渡动画工具类（popup/close缓动） | ~60 行 |
| `UI/UnitPortraitHUD.gd` | 顶部单位头像 HUD | ~130 行 |
| `UI/SettingsPanel.gd` | 显示设置+音量控件面板 | ~100 行 |
| `UI3D/GridMapper3D.gd` | 格坐标↔3D世界坐标转换（纯数学工具类） | ~40 行 |
| `UI3D/TileMeshFactory3D.gd` | 9种格子 BoxMesh+StandardMaterial3D 工厂 | ~120 行 |
| `UI3D/UnitMeshFactory3D.gd` | 单位 CapsuleMesh/CylinderMesh+billboard HP 条 | ~130 行 |
| `UI3D/BoardView3D.gd` | 3D 棋盘视图（SubViewport 嵌入+信号接口对齐 BoardView） | ~380 行 |
| `System/AudioManager.gd` | 音效管理器（多通道SFX+BGM） | ~120 行 |
| `System/SFXGenerator.gd` | 程序化音频引擎（28种SFX+4种BGM） | ~1100 行 |
| `Main.gd` | 场景组合 + 信号中转 + 音效触发 + 相机跟随 + 3D视图路由 | ~670 行 |

### 日志文件（`Logs/` 下）

| 文件 | 用途 | 更新频率 |
|------|------|----------|
| `AI_Employee_Guide_v3.md` | AI 员工上岗指令（行为规范） | 每轮强制更新 |
| `Handoff_Package_latest.md` | 最新交接包 | 交接时覆盖 |
| `CyberTao_Migration_Snapshot_zh_v3.md` | 本文件 — 项目全貌+架构 | 阶段性更新 |
| `Mulerun_Work_Report.md` | 上一轮精确状态 | 每轮覆盖 |
| `changelog_v0.1.md` | 完整版本历史 | 每轮追加 |
| `Board_Card_Battle_Concept_zh.md` | 双层玩法设计文档 | 设计变更时 |
| `Demo_Roadmap_2p5D_zh.md` | 中长期路线图 | 阶段性更新 |
| `Art_Beautification_Strategy_zh.md` | 美术美化推进策略（6阶段） | 美化阶段参考 |

---

## 7. 版本里程碑总览

| 版本 | 里程碑 |
|------|--------|
| v0.1.0~v0.1.3 | 基础骨架（棋盘+掷骰+移动+回合） |
| v0.1.4~v0.1.6 | 战斗基础（攻击+HP+胜负） |
| v0.1.7~v0.1.12 | 体验增强（设置+反馈+重开） |
| v0.1.13~v0.1.14 | AI+召唤（敌方回合+铺路） |
| v0.1.15~v0.1.21 | 棋盘深化（地形+适性+道具+意图） |
| v0.1.22~v0.1.24 | 双层入口（遭遇格+暂停+格子事件化） |
| v0.1.25~v0.1.27 | 卡牌战斗（原型→丰富化） |
| v0.1.28~v0.1.30 | 调试+UI+阶段收口 |
| v0.1.31~v0.1.38 | 卡牌深化（构筑/升级/Boss/6种敌方/能量成长） |
| v0.1.39~v0.1.43 | 系统完善（BuffManager接入/BFC瘦身/9种格子/多层地图/BUG-001修复） |
| v0.1.45~v0.1.49 | 美化 Phase 1~4.1（格子/单位/骰子/卡牌/背景 视觉升级） |
| v0.1.50~v0.1.54 | Boss机制+单位精简+全屏卡牌战斗界面+角色立绘+百叶窗过渡 |
| v0.1.55~v0.1.60 | UI过渡动画+音效系统+层间难度递增+等距贴图棋盘+相机跟随+全新AI素材 |
| v0.1.61~v0.1.66 | 程序化棋盘回退+鼠标拖拽相机+12x12扩展+大世界填充+镜头优化+角色重构+音效设置 |
| v0.1.67~v0.1.70 | 逐格移动动画+卡牌拖拽出牌+即时伤害反馈+头像HUD+玩家精灵动画 |
| v0.1.71 | 3D 渐进迁移 P0（BoardView3D+SubViewport+F5切换双视图+3D相机/射线检测/高亮/移动动画） |
| v0.1.72 | 3D 交互手感修复（拖拽即时响应+镜头跟随速度+边界限制+缩放轴心对齐2D体验） |

---

## 8. 一句话状态

**v0.1.72 双层玩法完整闭环+卡牌深化第一版完成。棋盘走位层（9种格子+随机生成+3层推进+Boss锁定传送门+单位精简+层间难度缩放+逐格移动动画+头像HUD）和卡牌战斗层（14种牌+升级+6种敌方+Boss+能量成长+持久牌组+奖励选牌+拖拽出牌+即时伤害反馈）全部稳定。等距程序化棋盘（IsoTileRenderer）+鼠标拖拽相机+缩放+12x12棋盘+角色形象重构（咩咩启示录风格）+玩家精灵动画（4方向spritesheet）+音效系统+全屏独立卡牌战斗界面+角色立绘+宝可梦式百叶窗过渡+赛博朋克全面美化（Phase 1~6）已完成。3D 渐进迁移 P0 完成（BoardView3D+SubViewport+F5切换+3D相机/射线检测/高亮/移动动画），v0.1.72 完成 3D 交互手感修复（拖拽即时响应+镜头跟随速度+边界限制+缩放轴心对齐2D体验，反馈方法暂为桩函数）。下一步：3D 反馈系统或商店格扩展。**
