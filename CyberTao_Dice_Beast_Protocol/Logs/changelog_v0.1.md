# CyberTao: Dice Beast Protocol Changelog

## v0.1.111 - 2026-04-04

记录时间: 2026-04-04 13:51 SGT

- 修复: 移除设置按钮旁的“生图”入口，断开主流程内所有生图调用。
- 修改: 顶部单位头像选择 HUD 重做样式，增强选中/悬停反馈与血量可读性。
- 新增: 六个基础骰面功能语义补齐，减少空功能测试感。
- 备注: 从仓库删除 `OpenAIImageService.gd` 与 `ImageGenerationPanel.gd`，彻底剔除生图模块。

## v0.1.110 - 2026-04-04

记录时间: 2026-04-04 13:15 SGT

### 修复
- `BattleFlowController.gd` / `CellEffectHandler.gd` / `BoardView.gd` / `BoardView3D.gd` / `UnitPortraitHUD.gd` / `Main.gd`：主角与召唤物规则边界完成拆分，召唤物不再触发事件、遭遇、商店、宝箱与传送门，也不再混入主角头像与核心选择链路。
- `CardBattleController.gd` / `CardBattlePanel.gd` / `Main.gd`：卡牌战斗玩家名改为按实际触发遭遇的主角动态显示，修复“玩家名写死”导致的身份混乱。

### 修改
- `CardBattleData.gd` / `BoardGenerator.gd`：第一章遭遇与 Boss 命名收口到“灰链封锁区 / 天枢治域”语气，降低原型测试感并避免终局设定前置。
- `MainViewCoordinator.gd`：补齐 `chapter_label` / `objective_label` 视图属性，修复 headless 启动时报错。

### 新增
- `ChapterContent.gd`：新增章节内容中心，统一开场简报、章节标题、楼层目标、遭遇显示名与流程反馈文案。
- `MissionBriefOverlay.gd`：新增开局任务简报覆盖层，形成“开场简报 -> 棋盘推进 -> 遭遇切换”的章节入口链路。
- `UnitManager.gd`：新增 `get_player_hero_units()`、`is_player_hero_unit()`、`is_summoned_unit()`，用于主角/召唤物全链路分层。

### 备注
- 本轮新增私有创意推进文件 `Logs/Private_Chapter1_Flow_local.md` 已保持本地排除，不进入仓库。
- headless 启动已通过，仍有 Godot 退出时资源未释放警告（历史残留，未阻塞本轮交付）。

## v0.1.109 - 2026-04-03

### 修复
- `Main.gd` / `BoardView.gd` / `BoardView3D.gd`：高亮格子数组 (`highlight_cells`、`attack_highlight_cells`、`summon_highlight_cells`) 不再直接赋 `[]`，而是调用 `.clear()`，避免在数组声明为 `Array[Vector2i]` 的场景中被赋入未指定类型的空值导致 `_on_card_battle_ended` 报错。

## v0.1.108 - 2026-04-03

### 修改
- `AI_Employee_Guide_v3.md`：同步到 v0.1.108，补齐当前真实状态与文档同步硬规则
- `Art_Beautification_Strategy_zh.md`：同步到 v0.1.108，补齐构筑界面与生图面板的当前视觉基线
- `Handoff_Package_latest.md`：更新当前版本并记录本轮文档补齐
- `Mulerun_Work_Report.md`：覆盖为本轮工作报告

### 备注
- 本轮无代码行为变化；目标是把入口文档重新拉回和主日志同一基线

## v0.1.107 - 2026-04-03

### 修复
- `Main.gd`：移除对 `ImageGenerationPanel` 的强类型依赖，避免 headless 首次装载时出现类型解析失败
- `MainViewCoordinator.gd`：移除对 `OpenAIImageService` / `ImageGenerationPanel` 的强依赖，降低 `class_name` 注册顺序造成的装载风险
- `ImageGenerationPanel.gd`：移除对 `OpenAIImageService` 的强类型依赖，保持生图面板在最小启动时可装载

### 修改
- `Handoff_Package_latest.md`：同步到 v0.1.107，回补 v0.1.106 的真实状态与当前风险
- `Mulerun_Work_Report.md`：覆盖为本轮工作报告
- `CyberTao_Migration_Snapshot_zh_v3.md`：更新为当前结构快照，修正 `hacker_fox` 已接入主流程这一事实

### 备注
- 本轮清理了本地 Godot 测试产物，不再把 `.codex_tmp` / `godot_headless.log` 留在仓库状态中
- 隔离用户目录下的最小 headless 启动已通过；当前仍有根证书读取警告和退出资源未释放警告

## v0.1.106 - 2026-04-02

### 新增
- `MainViewCoordinator.gd`：抽离主界面视图构建、按钮创建、面板绑定与 3D 视图初始化
- `OpenAIImageService.gd`：接入 OpenAI 图片生成请求、本地配置保存与 PNG 输出
- `ImageGenerationPanel.gd`：新增独立生图面板，支持 API Key、Prompt、尺寸 / 质量与预览
- `CardBattleData.gd`：集中管理起始牌组、奖励池、升级规则与遭遇敌人数据

### 修改
- `Main.gd`：将大段界面搭建与连线逻辑下沉到 `MainViewCoordinator.gd`，并增加生图面板入口
- `CardBattleController.gd`：改为读取 `CardBattleData.gd`，不再维护大块内嵌数据表
- `FloorManager.gd` / `BattleFlowController.gd`：把 `hacker_fox` 接入主流程出生与跨层恢复逻辑
- `CardRenderer.gd`、`CardRewardPanel.gd`、`DeckViewPanel.gd`、`ShopPanel.gd`：统一到新的构筑展示方案
- `BoardView3D.gd`：整理 3D 格子爆发反馈与相机震动调用

### 备注
- 当前项目已从“单英雄主循环”进入“双英雄开局”状态，`crow_caster` 仍保留在资源层
- OpenAI 生图功能依赖 API Key、网络和本机证书环境，v0.1.106 时未补完正式验证记录

## v0.1.105 - 2026-04-02

### 修复
- 重写 `AI_Employee_Guide_v3.md`，清理残留乱码并同步当前接手流程
- 重写 `Art_Beautification_Strategy_zh.md`，替换过时的旧阶段策略正文
- 重写 `CyberTao_Migration_Snapshot_zh_v3.md`，同步当前版本、结构、模块和风险说明
- 修复最近几版 changelog 顶部条目的可读性，避免接手时直接撞上乱码

### 修改
- `Handoff_Package_latest.md`：更新到 v0.1.105，并记录当前已消除的交接风险
- `Mulerun_Work_Report.md`：覆盖为本轮工作报告

### 备注
- 本轮没有改动游戏逻辑、数值或界面行为
- 当前已清理的是“接手主路径”文档；更早历史归档如需精修，应另开轮次处理

## v0.1.104 - 2026-04-02

### 修复
- 对 `AI_Employee_Guide_v3.md`、`Art_Beautification_Strategy_zh.md`、`Mulerun_Work_Report.md` 进行了保守编码修复，恢复核心中文内容可读性

### 修改
- `AI_Employee_Guide_v3.md`：重写文档顶部说明，明确当前执行应以 Handoff / Work Report / Changelog 为准
- `Handoff_Package_latest.md`：同步当前版本到 v0.1.104，并记录日志编码修复状态
- `CyberTao_Migration_Snapshot_zh_v3.md`：同步顶部提示中的真实项目基线版本

### 备注
- 本轮没有改动游戏逻辑或界面行为
- 日志正文仍残留少量历史损坏字符，后续建议单独开轮次精修
## 历史归档说明

- `v0.1.103` 及更早的 changelog 正文曾受历史编码损坏影响，原始中文段落已无法无损恢复。
- 为保证接手可读性，下面按 Git 提交标题整理为可读摘要；需要更细节时，可结合对应 commit 查看代码差异。

## 历史版本摘要（v0.1.103 及更早）

- `v0.1.1`：v0.1.1: unit selection + movable cell highlighting + MOVE crest movement
- `v0.1.2`：v0.1.2: fix dice roll-once and move highlight sync
- `v0.1.3`：v0.1.3: turn cycle — End Turn button, round advance, crest pool reset
- `v0.1.4`：v0.1.4: basic attack — red highlights, click-to-attack, ATTACK crest cost, damage + kill
- `v0.1.5`：v0.1.5: fix attack_range data link in spawn_unit and debug spawn payloads
- `v0.1.6`：v0.1.6: HP display on units + victory/defeat check after attacks
- `v0.1.7`：v0.1.7: add display settings system (resolution, window mode, persistence)
- `v0.1.8`：v0.1.8: fix remaining English string in DiceDebugPanel round label to Chinese
- `v0.1.9`：v0.1.9: rewrite all UI scripts with explicit UTF-8 Unicode escapes to fix Chinese encoding
- `v0.1.10`：v0.1.10: fix input blocking — set MOUSE_FILTER_IGNORE on decorative controls, toggle SettingsPanel filter, add accept_event to BoardView
- `v0.1.11`：v0.1.11: guarantee 1 MOVE per roll, move enemy spawn from (7,1) to (3,4)
- `v0.1.12`：v0.1.12: attack feedback (flash + damage number) and restart button
- `v0.1.13`：v0.1.13: 敌方 AI 最小回合
- `v0.1.14`：v0.1.14: 召唤 + 铺路原型（summon + path-building v1）
- `v0.1.15`：v0.1.15：高台格 + 陷阱格地形系统第一版
- `v0.1.16`：v0.1.16：summon / path-building 第一版收口
- `v0.1.17`：v0.1.17：修复棋盘底部裁切 + 分辨率设置生效
- `v0.1.18`：v0.1.18：修复点击移动误触召唤导致分身的 bug
- `v0.1.19`：v0.1.19: 单位地形适性第一版
- `v0.1.20`：v0.1.20: buff / item 格第一版
- `v0.1.21`：v0.1.21: 敌方 AI 可读性增强 — 意图广播+加长停顿+攻击预警
- `v0.1.22`：v0.1.22 遭遇格原型入口（Day 6 棋盘走位层扩展）
- `v0.1.23`：v0.1.23: Day 7 遭遇暂停与战斗占位流程
- `v0.1.24`：v0.1.24: Day 8 棋盘格子事件化（恢复格+事件格）
- `v0.1.25`：v0.1.25 Day 9: 最小卡牌战斗原型 — 双层玩法结构首次完整跑通
- `v0.1.26`：v0.1.26 Day 9 架构重构：拆分 CardBattleController + CardBattlePanel
- `v0.1.27`：v0.1.27 Day 10: 卡牌战斗丰富化 — 能量系统+双牌堆+敌方行为模式
- `v0.1.28`：v0.1.28: 新增卡牌战斗调试快捷按钮
- `v0.1.29`：v0.1.29: Day 11 UI 去调试化 — 统一赛博朋克视觉风格
- `v0.1.30`：v0.1.30: Day 12 阶段收口 — 全面日志整理与下阶段建议
- `v0.1.31`：v0.1.31 卡牌构筑成长：持久牌组 + 战斗胜利选牌 + 5 种新卡牌 + CardRewardPanel
- `v0.1.32`：v0.1.32 更多敌方种类：新增暗网爬虫/脉冲猎手/数据幽灵 3 种遭遇敌方 + 3 个遭遇格
- `v0.1.33`：v0.1.33 DEFEND/SKILL/TRICK crest 消耗入口：护持临时防御 + 术式即时回复 + 机巧资源转化
- `v0.1.34`：feat: 牌组查看面板 v0.1.34 — 棋盘阶段可查看持久牌组内容
- `v0.1.35`：feat: 棋盘随机生成 v0.1.35 — BoardGenerator 程序化布局替代固定 debug spawn
- `v0.1.36`：feat: 卡牌升级机制 v0.1.36 — 14种牌升级数据+奖励面板双模式+视觉区分
- `v0.1.37`：feat: Boss 遭遇系统 v0.1.37 — 零号协议（HP20/ATK3/6阶段行为）
- `v0.1.38`：feat: 能量成长机制 v0.1.38 — 遭遇胜利+1/Boss+2，上限5
- `v0.1.39`：feat: BuffManager 接入 v0.1.39 — tick_turn回合衰减+伤害修正+道具ATK buff
- `v0.1.40`：refactor: BFC瘦身 v0.1.40 — 795→588行，剥离CrestActionHandler+CellEffectHandler
- `v0.1.41`：feat: v0.1.41 商店格+宝箱格（棋盘格子类型从7种增至9种）
- `v0.1.42`：feat: 多层地图系统 v0.1.42 — 3层棋盘推进+层间奖励+HP保留
- `v0.1.43`：fix: BUG-001 修复分辨率/全屏/无边框/窗口模式切换无效 (v0.1.43)
- `v0.1.44`：fix: BUG-001 补充修复分辨率切换后画面不自适应 (v0.1.44)
- `v0.1.44`：docs: 制定美术美化推进策略 + 调整任务优先级 (v0.1.44-docs)
- `v0.1.45`：feat: 美化 Phase 1 — BoardCellRenderer + UnitRenderer + BoardView 重写 (v0.1.45)
- `v0.1.46`：feat: 美化 Phase 2 — DiceRollAnimation + BattleEffects (v0.1.46)
- `v0.1.47`：feat: 美化 Phase 3 — 卡牌面板重设计（CardRenderer + HP条 + 能量点）v0.1.47
- `v0.1.48`：feat: 美化 Phase 4.1 背景氛围升级 v0.1.48
- `v0.1.49`：v0.1.49-50: 掷骰3D演出升级 + Boss锁定/哨兵前置/传送门机制
- `v0.1.51`：fix: v0.1.51 修复遭遇格击败消失 Bug — resolve_encounter 三分支判断
- `v0.1.52`：feat: v0.1.52 单位精简 — 1 主角 + 伙伴槽系统
- `v0.1.53`：feat: v0.1.53 Boss解锁自动传送 + 宝可梦式卡牌战斗过渡
- `v0.1.54`：feat: v0.1.54 全屏独立卡牌战斗界面+角色立绘+扇形手牌+棋盘单位美化
- `v0.1.54`：docs: Snapshot v3 全面同步至 v0.1.54 状态
- `v0.1.55`：feat: v0.1.55 美化 Phase 4.2 — UI 过渡动画 + 召唤展开演出
- `v0.1.56`：v0.1.56: 美化 Phase 5 — 音效系统（AudioManager + SFXGenerator + 全局音效接入 + BGM切换）
- `v0.1.57`：v0.1.57: 层间难度递增（current_floor 缩放敌方 HP/ATK）
- `v0.1.58`：v0.1.58: 美化 Phase 6 — 等距棋盘贴图替换（IsoTileRenderer + BoardView 等距化 + UnitRenderer 适配）
- `v0.1.59`：feat: v0.1.59 全屏等距棋盘+叠层UI+高起贴图+角色放大
- `v0.1.60`：feat: v0.1.60 相机跟随玩家角色 + 全新素材 + UI优化
- `v0.1.61`：feat: v0.1.61 棋盘渲染回退至程序化（移除AI贴图+程序化菱形绘制）
- `v0.1.62`：feat: v0.1.62 棋盘扩展12x12+鼠标拖拽相机+平滑跟随+悬停高亮
- `v0.1.63`：feat: v0.1.63 大世界+缩放+敌方跟随+自定义光标+UI紧凑化
- `v0.1.64`：feat: v0.1.64 镜头跟随优化+掷骰动画增强
- `v0.1.65`：feat: v0.1.65 敌方回合镜头跟随优化
- `v0.1.65`：fix: v0.1.65 敌方掷骰等待动画完成后再行动
- `v0.1.66`：feat: v0.1.66 角色形象重构（咩咩启示录风格）+ 音效设置面板
- `v0.1.67`：feat: v0.1.67 移动逐格行走动画+敌方移动动画+我方回合镜头切回优化
- `v0.1.68`：feat: v0.1.68 卡牌拖拽出牌+即时伤害反馈
- `v0.1.69`：feat: v0.1.69 顶部单位头像 HUD
- `v0.1.70`：feat: v0.1.70 玩家角色精灵动画（4方向 spritesheet 集成）
- `v0.1.71`：feat: v0.1.71 3D 渐进迁移 P0（BoardView3D + SubViewport + F5 切换）
- `v0.1.71`：fix: v0.1.71.1 hotfix — TONE_MAP_ACES → TONE_MAPPER_ACES 修复 3D 编译错误
- `v0.1.72`：feat: v0.1.72 3D 交互手感修复（拖拽+镜头跟随+边界限制+缩放轴心）
- `v0.1.73`：feat: v0.1.73 商店格扩展（ShopPanel独立面板+5种商品池+crest货币+多次购买）
- `v0.1.74`：feat: v0.1.74 3D 反馈系统实现（Label3D漂浮文字+CPUParticles3D命中粒子+格子闪光+相机震动）
- `v0.1.75`：feat: v0.1.75 阵亡单位跨层复活（50% HP）+ 存活单位跨层回复（+30% HP）
- `v0.1.76`：feat: v0.1.76 BFC瘦身 — FloorManager独立类（多层地图逻辑剥离，881→791行）
- `v0.1.77`：feat: v0.1.77 3D单位精灵化 — billboard Sprite3D替代几何体（spritesheet行走动画+程序化敌方图标）
- `v0.1.78`：feat(v0.1.78): 商品池扩展 — 商店5→9种商品（加牌/移除牌/随机crest/最大HP+）
- `v0.1.79`：feat(v0.1.79): 卡牌战斗层深化 — 4种新卡牌+2种新敌方行为+2个新遭遇
- `v0.1.80`：balance(v0.1.80): 数值平衡调优 — 6项修正
- `v0.1.81`：feat: v0.1.81 全单位程序化 BGA 宝可梦像素风格重构
- `v0.1.82`：fix(v0.1.82): 2D渲染路径移除spritesheet — 修复默认模式仍显示旧插图BUG
- `v0.1.83`：feat(v0.1.83): 商店remove_card手动选牌UI
- `v0.1.84`：fix(v0.1.84): 卡牌拖拽手感优化并修复手牌飞顶BUG
- `v0.1.85`：fix(v0.1.85): 放宽3D棋盘拖拽边界修复卡位
- `v0.1.86`：audio(v0.1.86): 柔化BGM与SFX降低刺耳和默认响度
- `v0.1.87`：audio(v0.1.87): 接入用户BGM并优先外部加载
- `v0.1.88`：feat(v0.1.88): 优化3D可见性立体感并增加切换炫光特效
- `v0.1.89`：art(v0.1.89): GBA风重绘第一批敌方01-04
- `v0.1.90`：fix(v0.1.90): 卡牌战斗立绘同步像素重绘敌方
- `v0.1.91`：fix(v0.1.91): 2D单位绘制同步像素重绘风格
- `v0.1.92`：fix(v0.1.92): 修复3D拉远单位过小不可读
- `v0.1.93`：fix(v0.1.93): 修复3D近景单位溢出并改为动态距离缩放
- `v0.1.94`：feat(v0.1.94): 3D远距可见性+中键视角+功能格立体标识
- `v0.1.95`：feat(v0.1.95): 2D中键视角+3D外环沉浸地台+远距可见性增强
- `v0.1.96`：fix(v0.1.96): 修复MeshInstance3D.modulate导致的3D崩溃
- `v0.1.97`：feat(v0.1.97): 2D中键视角强化与棋盘外背景区分
- `v0.1.98`：fix(v0.1.98): 修复2D中键视角兼容并降低棋盘外黑边
- `v0.1.99`：fix(v0.1.99): 稳定棋盘居中并增强外场平台可见性
- `v0.1.100`：fix(v0.1.100): 回退2D伪视角并修正棋盘歪斜回正异常
- `v0.1.101`：fix(v0.1.101): 2D选中单位居中跟随并强化外场区分
- `v0.1.102`：feat(v0.1.102): 增加棋盘外背景装饰画面
- `v0.1.103`：feat(v0.1.103): 外场边框台座与四角结构件，取消自动回正
