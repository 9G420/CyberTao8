# CyberTao: Dice Beast Protocol Changelog

## v0.1.80 - 2026-04-01

### 修改（数值平衡调优）
- **能量虹吸**：cost 0→1（0费抽2张过于强势，1费仍为优质抽牌卡）
- **毒素注入**：持续回合 3→2（总伤害 6→4，降低延迟伤害的性价比，升级后 4→3 回合）
- **反击**：防御值 2→1，反击伤害 3→2（原数值严格优于防御牌，升级后 3→2 def / 4→3 counter）
- **赛博彩票（商店）**：费用 步x1→步x2（原费用下几乎必买，提高决策成本）
- **脉冲猎手（encounter_04）**：行为模式 重击→攻→攻 改为 攻→重击→攻（首回合 8 伤害=玩家满血一击毙命，不合理）
- **赛博巫医（encounter_07）**：HP 11→9（高HP+治疗+buff三叠加，11HP过于持久）
- DiceDebugPanel.gd: 版本标记 → v0.1.80

### 备注
- 本轮为纯数值调整，无新增功能/接口/信号
- 平衡思路：
  - 卡牌DPE（每能量伤害）基线为 3.0（斩击 3/1），超过 4.0 的需有附加限制
  - 能量虹吸从"无条件最强卡"降级为"优质工具卡"（1费抽2在STS参考下仍强于平均）
  - 反击定位为"防御+条件伤害"，不应无条件优于纯防御牌
  - 脉冲猎手仍保持高ATK(4)玻璃炮定位，但给玩家一个回合准备防御
  - 赛博巫医从"几乎无法击杀"降为"需要策略但可管理"

## v0.1.79 - 2026-04-01

### 新增
- **4 种新卡牌效果**：
  - 毒素注入（poison）：cost 1，施加持续毒素伤害（2伤/回合，持续3回合，可叠加回合数）
  - 能量虹吸（draw）：cost 0，额外抽 2 张牌（升级后抽 3 张）
  - 反击（counter）：cost 1，获得防御+2 并蓄力反击 3 伤害（敌方攻击时触发）
  - 裂空斩（combo）：cost 2，3 连击各 2 伤害（每击独立计算防御减免）
- **2 种新敌方行为模式**：
  - buff：敌方永久 ATK+1（长战斗中威胁递增）
  - multi_attack：敌方连续攻击 2 次（每次 60% ATK）
- **2 个新遭遇敌方**：
  - encounter_06 量子分裂体：HP 7 / ATK 2，含 buff + multi_attack 行为
  - encounter_07 赛博巫医：HP 11 / ATK 2，含 buff + heal 行为
- **CardRenderer 新增 4 种卡牌类型**：poison/draw/counter/combo 配色+图标+标签+数值格式
- **BattleCharRenderer 新增 2 个敌方立绘**：量子分裂体（紫色菱形晶体）、赛博巫医（绿色兜帽治疗者）

### 修改
- CardBattleController.gd: 新增 _poison_turns/_poison_dmg/_counter_dmg 状态变量；_resolve_card 新增 4 种卡牌类型；_enemy_act 新增 buff/multi_attack + 反击触发；end_turn 新增毒素结算；_update_enemy_intent 新增 buff/multi_attack 意图；新增 2 个遭遇数据；奖励卡池 13→17 张；升级数据新增 4 张
- CardRenderer.gd: TYPE_COLORS/TYPE_ICONS/TYPE_LABELS 各新增 4 项；_format_value 新增 4 种格式
- BoardGenerator.gd: ENCOUNTER_IDS 5→7 个
- Main.gd: 遭遇显示名映射新增 2 条
- BattleCharRenderer.gd: draw_enemy 新增 2 个分支；新增 _draw_quantum_splitter/_draw_cyber_shaman
- CardBattlePanel.gd: _on_enemy_intent_changed 新增"连续"/"强化"意图图标
- DiceDebugPanel.gd: 版本标记 → v0.1.79

### 备注
- 毒素在 end_turn 中结算（敌方回合开始前），可在敌方行动前击杀
- 反击伤害通过 _resolve_counter() 统一处理，所有敌方攻击类行为（attack/heavy/defend_attack/mega/multi）都会触发
- combo 连击每击独立检查敌方防御，对高防敌方效果显著减弱（设计意图）
- buff 行为使敌方 ATK 永久递增，量子分裂体 5 回合循环含 1 次 buff，长战斗中 ATK 会持续增长
- multi_attack 每击 60% ATK，2 击共 120% ATK 但分别受防御减免（比 heavy_attack 弱但对低防有效）
- 新遭遇均受层间难度缩放影响（HP+30%/层, ATK+1/层）

## v0.1.78 - 2026-04-01

### 新增
- **商品池扩展**：商店从 5 种商品扩展至 9 种，新增 4 类策略性商品
  - 数据芯片（add_card）：花费 策x1，从奖励卡池随机获得 1 张卡牌加入持久牌组
  - 数据清洗（remove_card）：花费 术x1，移除牌组中效费比最低的 1 张牌（牌组≤3张时不可用）
  - 赛博彩票（random_crest）：花费 步x1，随机获得 2 个 crest 资源
  - 生体强化（max_hp_up）：花费 盾x2，最大HP+2 并同时回复 2HP

### 修改
- ShopPanel.gd: SHOP_ITEM_POOL 5→9 种；`_pick_random_items()` 新增牌组过小过滤；`_can_purchase()` 新增 add_card/remove_card 前置检查；`_execute_purchase()` 新增 4 种效果结算
- DiceDebugPanel.gd: 版本标记 → v0.1.78

### 备注
- add_card 从 `CardBattleController._build_reward_pool()` 取卡，复用现有 13 张奖励卡池
- remove_card 按 value/cost 比值选择最弱牌，确保牌组≤3张时自动禁用
- random_crest 从 6 种 crest 中随机选取，直接修改 `crest_pool` 字典
- max_hp_up 同时提升 max_hp 和当前 hp，避免购买后 HP 条看起来反而更低
- 商店仍然每次随机展示 3 件商品（从 9 种中选），丰富策略选择

## v0.1.77 - 2026-04-01

### 新增
- **3D 单位精灵化**：billboard Sprite3D 替代 CapsuleMesh/CylinderMesh
  - 玩家英雄：使用现有 4 方向 spritesheet（刀盾向X走.png），支持行走帧动画（10fps，15帧循环）
  - 敌方单位：程序化生成 128px 红色菱形图标（发光边缘+中心高亮）
  - 召唤伙伴：程序化生成 128px 青色圆形图标
- **UnitMeshFactory3D 精灵动画接口**：`is_spritesheet_unit()` / `set_sprite_direction()` / `set_sprite_frame()` / `reset_sprite_idle()`
- **BoardView3D 精灵动画**：移动时自动检测方向、切换 spritesheet、推进帧动画

### 修改
- UnitMeshFactory3D.gd: 完整重写（133→250 行），从几何体工厂变为精灵工厂
- BoardView3D.gd: 新增精灵动画逻辑（701→736 行）
- DiceDebugPanel.gd: 版本标记 → v0.1.77

### 修复
- UnitMeshFactory3D: is_summoned 检测改为检查 tags 数组（原实现检查不存在的 "is_summoned" 字段）
- **BUG-002：v0.1.76 回归 — DiceDebugPanel/Main.gd 直接访问已移除的 `current_floor` 属性**：v0.1.76 将 `current_floor` 从 BFC 移至 FloorManager，但 DiceDebugPanel（3处）和 Main.gd（2处）仍直接访问 `battle_flow.current_floor`，导致运行时崩溃。修复：全部改为 `get_current_floor()` 方法调用

### 备注
- 使用 `ALPHA_CUT_DISCARD`（gl_compatibility 兼容），阈值 0.4
- 程序化图标缓存为静态变量，仅首次生成
- 外部信号接口零变更，Main.gd 无需修改
- 敌方/召唤图标为临时程序化方案，后续可替换为美术资源

## v0.1.76 - 2026-04-01

### 新增
- **FloorManager 独立类**（`Scripts/BattleV2/FloorManager.gd`，~162 行）：从 BattleFlowController 剥离多层地图逻辑
  - `advance_floor()` — 层间推进（HP 快照 → 清理 → 递增 → 重生 → 生成新棋盘）
  - `snapshot_player_hp()` / `_spawn_player_units_with_hp()` — HP 快照/复活/回复
  - `try_unlock_boss()` / `warp_hero_to_boss()` — Boss 解锁/英雄传送
  - `spawn_portal_near()` / `check_portal()` — 传送门生成/检测
  - `get_current_floor()` / `get_max_floor()` / `reset_floor()` — 层数管理

### 修改
- BattleFlowController.gd: 移除 `MAX_FLOOR`/`REVIVE_HP_RATIO`/`FLOOR_HEAL_RATIO` 常量和 `current_floor` 变量（移至 FloorManager）
- BattleFlowController.gd: 移除 `_snapshot_player_hp()`/`_spawn_player_units_with_hp()` 方法（移至 FloorManager）
- BattleFlowController.gd: `_try_unlock_boss()`/`_warp_hero_to_boss()`/`_spawn_portal_near()`/`_check_portal()`/`advance_to_next_floor()` 改为委托 FloorManager
- BattleFlowController.gd: `restart_battle()` 改用 `floor_manager.reset_floor()`
- BattleFlowController.gd: 行数从 881 行减至 791 行（-90 行）
- DiceDebugPanel.gd: 版本标记 → v0.1.76

### 备注
- 外部信号接口零变更，Main.gd 无需修改
- FloorManager 返回数据（字典/数组），BFC 保留信号发射权
- 常量和复活/回复逻辑行为完全不变，仅代码位置变更

## v0.1.75 - 2026-04-01

### 新增
- **阵亡单位跨层复活机制**：永久玩家单位（非召唤）在进入下一层时自动复活，HP = 50% max_hp（向上取整，至少 1）
- **存活单位跨层回复**：存活单位在进入下一层时额外回复 30% max_hp（不超过 max_hp），防止低 HP 死亡螺旋
- **常量 `REVIVE_HP_RATIO`**：阵亡复活 HP 比例，默认 0.5（50%）
- **常量 `FLOOR_HEAL_RATIO`**：存活跨层回复比例，默认 0.3（30%）

### 修改
- BattleFlowController.gd: `_spawn_player_units_with_hp()` 从"跳过阵亡单位"改为"阵亡单位复活 + 存活单位回复"
- BattleFlowController.gd: `_snapshot_player_hp()` 新增 `alive` 字段（向前兼容，不影响现有逻辑）
- BattleFlowController.gd: `advance_to_next_floor()` 注释更新
- DiceDebugPanel.gd: 版本标记 → v0.1.75

### 备注
- 仅修改 BattleFlowController.gd 和 DiceDebugPanel.gd，UI 层零改动
- 召唤伙伴（tagged "summoned"）仍为层内临时单位，跨层时消失（设计意图）
- 复活/回复比例（50%/30%）为初始数值，未经平衡测试，后续可调整常量
- 当前只有 1 个永久单位（blade_shield_dog），机制已为多永久单位扩展预留
- `restart_battle()` 不受影响（完全重置，不调用 `_spawn_player_units_with_hp`）

## v0.1.74 - 2026-04-01

### 新增
- **3D 反馈系统完整实现**：9 个桩函数全部替换为真实 3D 特效
- **Label3D billboard 漂浮文字**：`_spawn_float_text_3d()` — 带黑色描边的 billboard 文字，上升 + 渐隐 + 自动释放，用于伤害数字/拾取/治疗/事件/商店/宝箱/遭遇反馈
- **PlaneMesh 格子闪光**：`_spawn_cell_flash_3d()` — 半透明发光平面叠放在目标格子上方，自发光 + 渐隐后释放，用于攻击闪光和敌方预警
- **CPUParticles3D 命中粒子**：`_spawn_hit_particles_3d()` — 球形粒子向上爆散（gl_compatibility 兼容），颜色渐变透明，击杀时数量/速度/范围增大
- **3D 相机震动**：`_shake_camera_3d()` — 通过 `_shake_offset` 变量驱动，6 步衰减抖动，在 `_process()` 中叠加到相机位置
- **`_feedback_root` 容器节点**：所有临时反馈特效（Label3D/MeshInstance3D/CPUParticles3D）统一挂载，与格子/单位/高亮层分离

### 修改
- BoardView3D.gd: v0.1.72 → v0.1.74，9 个桩函数替换为完整实现（~130 行新增），新增 4 个辅助方法 + `_feedback_root` + `_shake_offset`
- BoardView3D.gd: `_process()` 相机更新叠加 `_shake_offset`
- DiceDebugPanel.gd: 版本标记 → v0.1.74

### 备注
- 仅修改 BoardView3D.gd 和 DiceDebugPanel.gd，核心逻辑文件零改动
- 2D 模式不涉及本次修改，零影响
- CPUParticles3D 使用 SphereMesh 作为粒子可见形状，gl_compatibility 渲染器完全兼容
- Label3D 使用 `no_depth_test = true` 确保文字不被棋盘格子遮挡
- 攻击反馈包含 5 层效果（闪光+震动+粒子+伤害飘字+击杀文字），与 2D 版对齐
- 敌方预警使用双次延迟闪烁（0.25s + 0.3s 延迟后 0.2s），模拟 2D 版脉冲效果

## v0.1.73 - 2026-04-01

### 新增
- **ShopPanel.gd**：新文件（~240行），`class_name ShopPanel`，独立商店 UI 面板
- **5 种商品池**：修复药剂（步x1→HP+3）、高级修复（步x2→HP+6）、攻击芯片（攻x1→ATK+1）、防御芯片（盾x1→DEF+1）、能量核心（术x2→能量上限+1）
- **随机 3 选**：每次踩商店格从池中随机展示 3 件商品，可多次购买
- **CyberStyle 风格化面板**：赛博青色边框，显示持有 crest 资源，购买反馈文字，灰掉不可购买项
- **信号 `shop_panel_requested`**：替代旧的 `shop_cell_triggered`，BFC 仅发信号不自动购买
- **`CellEffectHandler.has_valid_shop_cell()`**：仅检查商店格存在性+玩家身份，不执行购买逻辑

### 修改
- CellEffectHandler.gd: 删除 `check_shop_cell()`（自动购买），替换为 `has_valid_shop_cell()`（纯校验）
- BattleFlowController.gd: `_check_shop_cell` 改为仅发 `shop_panel_requested` 信号
- Main.gd: 新增 ShopPanel 导入/实例化/信号连接 + `_on_shop_panel_requested`/`_on_shop_closed` 回调
- DiceDebugPanel.gd: 信号绑定 `shop_cell_triggered` → `shop_panel_requested`，版本标记 → v0.1.73

### 备注
- ATK/DEF 提升直接修改 unit dict（本层永久，跨层时 unit 重建自动重置），未走 BuffManager
- 能量核心修改 CardBattleController.max_energy（跨战斗持久），上限卡 5
- 商品池为 const Array，后续扩展方便（加新牌/移除诅咒/随机 crest 等）
- 旧信号 shop_cell_triggered 已全量清除（grep 确认零引用）

## v0.1.72 - 2026-03-31

### 修复
- **3D 拖拽手感**：改用起始位置+绝对差值映射（替代逐帧增量累积），消除拖拽漂移和精度丢失
- **3D 拖拽实时响应**：拖拽期间相机以 20.0 高速 lerp 追踪（原先拖拽时 lerp 完全关闭，松手才生效）
- **3D 镜头跟随速度**：CAMERA_LERP_SPEED 4.5 → 8.0，修复 60fps 下 lerp 因子过小（0.072→0.128/帧）导致的镜头迟滞
- **3D 缩放轴心**：新增 _apply_zoom()，以鼠标位置为轴心缩放（射线交叉计算缩放前后地面点偏移），与 2D 行为对齐
- **3D 边界限制**：新增 _clamp_drag_offset()，将拖拽偏移夹紧到棋盘世界范围的 ±50%，防止相机无限漂移

### 修改
- BoardView3D.gd: 重写 handle_input() 拖拽逻辑（_drag_start_offset 快照 + 绝对偏移计算）
- BoardView3D.gd: 重写 _process() 相机更新（拖拽中/非拖拽双路径 lerp）
- BoardView3D.gd: 新增 _clamp_drag_offset() / _apply_zoom() / _screen_to_ground() 三个内部方法
- BoardView3D.gd: 新增 _drag_start_offset 变量、ZOOM_STEP 常量
- DiceDebugPanel.gd: 版本标记 → v0.1.72

### 备注
- 仅修改 BoardView3D.gd 和 DiceDebugPanel.gd，核心逻辑文件零改动
- 2D 模式不涉及本次修改，零影响
- _screen_to_ground() 使用 camera.project_ray_origin/normal 投射，当相机位置因 lerp 未完全到位时存在微小偏差（可接受）

## v0.1.71.1 - 2026-03-31 (hotfix)

### 修复
- **BoardView3D.gd**：`Environment.TONE_MAP_ACES` → `Environment.TONE_MAPPER_ACES`（Godot 4.x 正确枚举常量），修复 3D 视图解析错误导致无法运行

## v0.1.71 - 2026-03-31

### 新增
- **3D 渐进迁移 P0**：新增完整 3D 表现层，与 2D 视图可切换共存
- **GridMapper3D.gd**：新文件，`class_name GridMapper3D`，棋盘格坐标(Vector2i) ↔ 3D世界坐标(Vector3) 双向转换
- **TileMeshFactory3D.gd**：新文件，`class_name TileMeshFactory3D`，为 9 种格子类型创建程序化 BoxMesh + StandardMaterial3D（配色沿用 CyberStyle）
- **UnitMeshFactory3D.gd**：新文件，`class_name UnitMeshFactory3D`，为玩家（CapsuleMesh）/敌方（CylinderMesh）创建 3D 单位 + billboard HP 条
- **BoardView3D.gd**：新文件，`class_name BoardView3D`，extends Node3D，完整 3D 棋盘视图，信号接口与 BoardView(2D) 对齐
- **SubViewport 嵌入**：通过 SubViewportContainer + SubViewport 将 3D 场景嵌入 2D UI 树
- **F5 切换 2D/3D**：运行时按 F5 键切换视图模式
- **3D 相机系统**：透视相机（55° 俯视），平滑跟随 + 鼠标拖拽平移 + 滚轮缩放
- **3D 射线检测**：地面平面射线交叉实现鼠标→格子映射
- **3D 高亮系统**：半透明薄片叠层显示移动/攻击/召唤高亮
- **3D 逐格移动动画**：Tween 驱动 Vector3 插值
- **赛博朋克 3D 光照**：DirectionalLight3D（冷调光）+ WorldEnvironment（暗色背景+辉光+ACES 色调映射）

### 修改
- Main.gd: 新增 `_use_3d` 标志 + `_active_view()` duck typing 路由 + `_reset_drag_offset()` 兼容方法
- Main.gd: 新增 `_setup_3d_view()` 初始化 SubViewport + BoardView3D + 信号绑定
- Main.gd: 新增 `toggle_3d_view()` + `_input()` F5 快捷键
- Main.gd: 所有 ~40 处 `_board_view.` 调用替换为 `_active_view().` 路由
- Main.gd: 召唤演出、拖拽偏移等 2D-specific 代码用 `_use_3d` 守卫
- DiceDebugPanel: 版本标记 → v0.1.71

### 架构说明
- **不修改核心逻辑文件**：BattleFlowController、CardBattleController、BoardManager、UnitManager 零改动
- **duck typing 路由**：BoardView(2D) 和 BoardView3D(3D) 共享信号名和方法名，Main.gd 通过 `_active_view()` 无类型返回实现统一路由
- **2D 始终可用**：`_use_3d` 默认 false，2D 为生产模式，3D 为实验预览
- **3D 反馈方法暂为桩**：play_attack_feedback 等 3D 版暂返回空，后续迭代补充粒子/飘字

### 备注
- 4 个新文件均在 `Scripts/UI3D/` 目录下
- BoardView3D 内嵌于 SubViewport（1280x720），由 SubViewportContainer 显示
- 3D 格子使用 BoxMesh（CELL_SIZE=2.0），高台格额外抬高 0.4
- 3D 单位使用 CapsuleMesh（玩家蓝）/ CylinderMesh（敌方红），发光色匹配 CyberStyle
- 3D 模式下鼠标事件通过 Main._input() 转发给 BoardView3D.handle_input()

## v0.1.70 - 2026-03-31

### 新增
- **玩家角色精灵动画**：替代程序化绘制，使用 spritesheet 渲染玩家单位
- **PlayerSpriteAnimator.gd**：新文件，`class_name PlayerSpriteAnimator`，管理 4 方向行走 spritesheet 帧切换
- **4方向行走动画**：上/下/左/右各一张 4x4 网格 spritesheet（15帧），移动时自动播放对应方向
- **方向自动检测**：根据移动起终格计算朝向（dx/dy 比较）
- **静止时显示第一帧**：未移动时显示当前朝向的第一帧（默认向下）

### 修改
- BoardView.gd: 新增 `_sprite_animator` + `_draw_player_sprite()` 方法，移动时启动/停止动画
- BoardView.gd: `_on_anim_tick()` 中推进精灵帧，`play_move_step()` 中设置方向
- DiceDebugPanel: 版本标记 → v0.1.70

### 备注
- 4 张 spritesheet 尺寸不同（向上 3032x2596，向下 3532x2888，向左/右 3840x3840），渲染时统一缩放至 80px 高
- 敌方单位仍使用程序化绘制（UnitRenderer）
- HUD 头像仍使用程序化绘制（UnitRenderer._draw_player_char）
- 如果 spritesheet 背景不透明（非 RGBA alpha），需要用户预处理去白底
- 帧率：10fps（每 100ms 切帧），15 帧一个完整循环

## v0.1.69 - 2026-03-31

### 新增
- **顶部单位头像 HUD**：屏幕顶部横排显示各方单位头像 + HP 条 + 名称
- **UnitPortraitHUD.gd**：新文件，`class_name UnitPortraitHUD`，`_draw` 渲染所有单位肖像
- **玩家单位左排、敌方右排**：自动按阵营分组布局
- **点击头像切换镜头**：点击玩家头像 → 选中单位 + 镜头跟随；点击敌方头像 → 仅镜头跟随
- **选中高亮 + 悬停反馈**：当前选中单位边框高亮，悬停时背景变亮
- **卡牌战斗时自动隐藏**：进入遭遇时隐藏 HUD，返回棋盘时显示
- **与 BoardView 选中同步**：BoardView 的 unit_selected/unit_deselected 信号联动 HUD 高亮

### 修改
- Main.gd: 新增 `_portrait_hud` 实例化 + 信号连接 + `_on_portrait_clicked` 回调
- Main.gd: 卡牌战斗进出时切换 `_portrait_hud.visible`
- DiceDebugPanel: 版本标记 → v0.1.69

### 备注
- UnitRenderer._draw_player_char / _draw_enemy_char 以 0.45 缩放绘制迷你头像
- HUD 通过 units_changed 信号自动重建，单位阵亡/新增时自动更新
- 起始 X=90px 避开左上角设置按钮

## v0.1.68 - 2026-03-31

### 新增
- **卡牌拖拽出牌系统**：替代原有点击出牌，mousedown 开始拖拽 → mousemove 跟随手指 → mouseup 在上半区（y<380）释放即打出
- **出牌区视觉提示**：拖拽时顶部出现半透明蓝色区域 + "拖到此处出牌" 文字，卡牌进入区域时高亮加深
- **即时伤害反馈**：每次出牌后立即刷新 HP 条（不再等到结束回合），同时显示伤害/治疗飘字
- **伤害飘字系统**：`_spawn_effect_popup()` 方法，红色上浮 "-X" 伤害 / 绿色 "+X" 治疗，0.7s Tween 动画后自动消失
- **敌方行动即时反馈**：敌方行动后也立即刷新 HP 条 + 伤害飘字

### 修改
- CardBattlePanel._create_battle_card: 移除 callback 参数，gui_input 从直接调用 play_card 改为启动拖拽
- CardBattlePanel._on_card_played: 新增 `_refresh_status()` 调用 + HP 差值比对 + 飘字生成
- CardBattlePanel._on_hand_changed: 新增 `_cancel_drag()` 防止手牌重建时拖拽残留
- CardBattlePanel._on_enemy_acted: 新增即时 HP 刷新 + 飘字
- CardBattlePanel._on_battle_started: 初始化 HP 追踪变量
- CardBattlePanel hover 回调: 拖拽进行时抑制 hover 缩放动画
- DiceDebugPanel: 版本标记 → v0.1.68

### 备注
- 拖拽使用 `_input()` override 而非 `_gui_input`，确保鼠标离开卡牌区域后仍能跟踪
- HP 追踪变量 `_hp_before_enemy/_hp_before_player` 在出牌前快照、出牌后比对，用于计算飘字数值
- 敌方行动后也更新追踪变量，防止连续行动时飘字数值累积错误

## v0.1.67 - 2026-03-31

### 新增
- **移动逐格行走动画**：玩家/敌方单位移动时逐格 Tween 插值（0.15s/格），告别瞬移
- **BFS 路径重建（BoardManager）**：`get_path_to_cell()` 方法，基于 came_from 回溯完整路径
- **移动动画信号链**：BFC.move_step_visual → Main → BoardView.play_move_step → move_anim_done → BFC.move_step_done
- **validate_move 纯验证方法**：不消耗资源的同步移动校验，供 Main 预检
- **我方回合镜头切回优化**：敌方回合结束后镜头优先切回上一轮操作的我方单位（非固定切主角）
- **_last_operated_unit_id 追踪**：移动/攻击/召唤操作时记录，用于镜头切回

### 修改
- BattleFlowController.try_move_unit: 从同步返回 bool 改为 async void，逐格移动+await 动画
- BattleFlowController._execute_enemy_actions: 敌方移动接入 move_step_visual 动画信号链
- 敌方移动后等待从 0.9s 降至 0.5s（动画已提供视觉反馈）
- BoardView._draw_layer_units: 动画中的单位绘制在 from→to 插值位置
- Main._on_move_requested: 改用 validate_move 同步校验 + fire-and-forget 异步执行
- Main._on_enemy_turn_ended: 优先切回 _last_operated_unit_id
- DiceDebugPanel: 版本标记 → v0.1.67

### 备注
- 中途经过的格子不触发效果（陷阱/遭遇等仅在最终目的地检查），这是设计决定
- try_move_unit 返回类型变更（bool→void）为架构级改动，需确认无其他调用方依赖返回值

## v0.1.66 - 2026-03-31

### 新增
- **角色形象全面重构（咩咩启示录风格）**：玩家英雄+全部敌方单位（哨兵/游魂/爬虫/猎手/幽灵/Boss）重新设计为 Cult of the Lamb 风格——大圆头、大眼睛、萌系 Q 版身材
- **棋盘迷你角色重构（UnitRenderer）**：同步重构，所有棋盘上的迷你角色与战斗立绘风格统一
- **音效设置面板**：SettingsPanel 新增 BGM/SFX 音量滑块（0-100）和开关按钮，实时调节
- **AudioManager 音量控制 API**：新增 set_bgm_volume/set_sfx_volume/get_bgm_volume/get_sfx_volume/is_sfx_enabled/is_bgm_enabled 方法

### 修改
- SettingsPanel: 标题改为"设置"，面板扩大至 440x520，新增音效设置区域
- Main.gd: 新增 bind_audio_manager 调用，调整 SettingsPanel 位置
- DiceDebugPanel: 版本标记 → v0.1.66

### 备注
- 角色设计灵感来源：咩咩启示录（Cult of the Lamb）——大头萌系 Q 版+赛博朋克配色
- 音效设置为实时生效，无需点击"应用"按钮（滑块和开关即时响应）

## v0.1.65 - 2026-03-31

### 修改
- **敌方移动后相机跟随**：_execute_enemy_actions 中敌方 move_unit 后发射 move_completed 信号，相机自动跟踪敌方移动目标位置
- **敌方回合结束延迟切回**：Main._on_enemy_turn_ended 增加 0.8 秒延迟再切回玩家，避免生硬跳转
- **BFC 敌方回合结束延长等待**：敌方全部行动完毕后先等 0.6 秒再 emit enemy_turn_ended，再等 1.2 秒才推进玩家回合
- **相机 Lerp 速度降低**：CAMERA_LERP_SPEED 从 8.0 降至 4.5，过渡更柔和平滑
- **敌方移动后等待延长**：敌方移动后等待从 0.6 秒增至 0.9 秒，便于观察
- **敌方掷骰等待动画完成**：新增 dice_animation_done 信号，BFC 在敌方掷骰后 await 该信号直到动画真正结束，而非固定 0.8 秒（动画实际约 4 秒）
- DiceDebugPanel: 版本标记 → v0.1.65

### 备注
- 本版本专注于敌方回合镜头体验优化，解决 v0.1.64 反馈中镜头过快过硬的问题

## v0.1.64 - 2026-03-31

### 新增
- **选中单位即居中相机**：点击可控制单位时相机立即移到该单位位置
- **敌方回合预告镜头**：敌方掷骰前先将相机移到即将行动的敌方单位
- **掷骰动画增强**：骰子放大65%（34→56），总动画时长约4秒，新增落地阴影、中心光晕、减速翻滚效果
- **enemy_turn_starting 信号**：敌方回合开始前通知 UI 层

### 修改
- BoardView._select_unit: 选中时调用 set_camera_target + 重置 _drag_offset
- BattleFlowController._start_enemy_turn: 掷骰前 emit enemy_turn_starting，等待 0.5 秒
- Main.gd: 所有自动相机跟随回调重置 _drag_offset，新增 _on_enemy_turn_starting
- DiceRollAnimation: 全面重写——更大骰子、更长动画、多层辉光、阴影、减速翻滚、旋转效果
- DiceDebugPanel: 版本标记 → v0.1.64

## v0.1.63 - 2026-03-31

### 新增
- **大世界环境填充**：棋盘外绘制暗色环境菱形格子，消除黑色空白区域
- **鼠标滚轮缩放**：滚轮放大/缩小棋盘视角（0.4x~1.6x），以鼠标位置为中心缩放
- **敌方回合相机跟随**：敌方行动时相机跟随敌人，玩家回合自动切回
- **赛博风格鼠标光标**：程序化十字准星光标
- **UI紧凑化**：DiceDebugPanel 从 220x680 右全栏改为 260x200 底部右侧紧凑 HUD

### 修改
- IsoTileRenderer: 全部绘制方法支持 zoom 参数
- BoardView: 新增缩放系统（_zoom/ZOOM_MIN/ZOOM_MAX）
- Main.gd: 敌方跟随+自定义光标
- DiceDebugPanel: 全面紧凑化重设计

## v0.1.62 - 2026-03-31

### 新增
- **鼠标拖拽平移相机**：右键/中键拖拽可自由平移棋盘视角
- **平滑相机跟随**：set_camera_target 改为 Lerp 插值过渡（CAMERA_LERP_SPEED=8.0）
- **悬停高亮**：鼠标悬停格子显示白色菱形高亮反馈
- **棋盘扩展至 12x12**：GRID_SIZE 从 8 扩展到 12，内容更丰富

### 修改
- IsoTileRenderer: GRID_SIZE → DEFAULT_GRID_SIZE=12，draw_board 动态从 board_mgr 读取尺寸
- BoardView: 移除 GRID_W/GRID_H 常量，改用 board_manager.is_in_bounds() 动态判定
- BoardView: 新增 _drag_active/_drag_offset/_iso_origin_target 拖拽和平滑相机状态
- BattleFlowController: 新增 BOARD_SIZE 常量，所有 Vector2i(8,8) 替换为 BOARD_SIZE
- BattleFlowController: 硬编码 bounds check (adj >= 8) 改为 board_manager.board_size 动态判定
- BoardGenerator: 所有生成参数按 12x12 棋盘比例上调（遭遇4-6/高台3-5/陷阱3-5/道具3/回复3/事件3-5/商店2/宝箱2-3/敌人3）
- BoardGenerator: 玩家出生区调整至 row 9-11，新增哨兵丙敌方模板
- CyberBackground: board_size 更新至 864x864

## v0.1.61 - 2026-03-31

### 修改
- **棋盘渲染回退至程序化**：IsoTileRenderer 从 AI 贴图渲染改为程序化菱形绘制
  - 移除所有贴图加载代码（TILE_PATHS / _textures / _loaded / _ensure_loaded）
  - 移除 TILE_FULL_H / TILE_ELEVATED_H / ELEVATION_OFFSET 常量（不再有高耸方块）
  - 新增 `_draw_tile_procedural()` 程序化绘制：菱形填充+内部渐变+网格边框+类型装饰
  - 9种格子类型（高台/陷阱/遭遇/回复/商店/宝箱/道具/事件/传送门）各有独立配色和符号
  - draw_board() 新增 pulse 参数，格子装饰支持脉冲呼吸效果
- BoardView._draw_layer_grid() 传入 pulse 参数
- 删除 Assets/Tiles/ 下全部 11 张 AI 生成 PNG 贴图

### 备注
- 等距坐标系（TILE_W=192 / grid_to_screen / screen_to_grid）完全保留
- 相机跟随系统（calc_origin_for_cell / camera_cell / set_camera_target）完全保留
- 根因：AI 贴图为高耸 3D 方块图，渲染后棋盘如积木墙，视觉严重异常
- 后续如有合适的扁平等距贴图资源，可在 _draw_tile_procedural 中替换回贴图路径

## v0.1.60 - 2026-03-31

### 新增
- **相机跟随玩家角色 + 全新素材 + UI优化**
- IsoTileRenderer.calc_origin_for_cell()：反推 iso_origin 使指定格子映射到屏幕中心
- BoardView.camera_cell + set_camera_target()：相机跟随系统
- BoardView._draw_edge_vignette()：四边 80px 渐暗带柔化棋盘边界
- Main._update_camera_to_player() / _on_move_completed_camera()：移动/重开/传送/层切换时更新相机
- 11 张全新 AI 生成赛博朋克等距方块贴图（Nano Banana Pro，统一英文命名）

### 修改
- IsoTileRenderer 等距参数再次放大：TILE_W 144→192, TILE_H_HALF 36→48, TILE_FULL_H 144→192, TILE_ELEVATED_H 192→256, ELEVATION_OFFSET 48→64
- BoardView iso_origin 从固定 (640,72) 改为动态计算（相机跟随）
- BoardView 启用 clip_contents=true 裁剪溢出视口的棋盘
- UnitRenderer 等距角色放大：scale 0.9→1.1，HP条宽 60→72，选中环半径 24→30，Y偏移 -16→-20
- DiceDebugPanel 面板宽度 232→220，圆角 6→8，alpha 0.75→0.80，版本 v0.1.59→v0.1.60
- DiceDebugPanel 位置 (1040,8)→(1052,8)
- CyberBackground 移除棋盘发光边框和角标绘制（相机跟随下棋盘超出视口）
- 删除所有旧 PNG 素材文件（含中文命名和 v0.1.59 elevated 版本）

### 备注
- 相机跟随暂为瞬间跳转，后续可加 Tween 平滑过渡
- TILE_W=192 使 8 格棋盘宽度 1536px，溢出 1280px 视口约 128px/侧

## v0.1.59 - 2026-03-31

### 新增
- **全屏等距棋盘 + 叠层 UI + 高起贴图 + 角色放大**
- 8张 AI 生成高起贴图（Nano Banana Pro）：高台/遭遇/回复/商店/宝箱/道具/事件/传送门
- IsoTileRenderer 高起渲染：TILE_ELEVATED_H=192 + ELEVATION_OFFSET=48，特殊格自动堆叠突起
- IsoTileRenderer 新增贴图路径：event_tile.png / portal_tile.png（事件格和传送门专属贴图）
- IsoTileRenderer._get_tile_key 新增 portal/event 优先级分支

### 修改
- IsoTileRenderer 等距参数放大 2x：TILE_W 72→144, TILE_H_HALF 18→36, TILE_FULL_H 72→144
- BoardView 全屏化：size 576×350 → 1280×720, iso_origin (288,30)→(640,72)
- BoardView 叠层简化：事件格/传送门已有专属贴图，移除程序化菱形叠层
- BoardView 反馈飘字字号放大（18→22/24），偏移适配大格子
- UnitRenderer 等距角色放大：scale 0.55→0.9，HP条宽 40→60，选中环半径 16→24
- Main.gd 布局重构：棋盘 (0,0) 全屏，DiceDebugPanel 右侧半透明叠加 (1040,8)
- Main.gd 移除标题/副标题/提示条（全屏棋盘无需占位标题栏）
- DiceDebugPanel 半透明叠加模式：宽度 280→232，StyleBoxFlat bg_color alpha=0.75
- DiceDebugPanel 版本标记更新 v0.1.50→v0.1.59
- CyberBackground 覆盖全屏 (0,0)→(1280,720)
- 掷骰演出中心 (328,382)→(640,360)

### 备注
- 旧平面贴图文件保留在 Assets/Tiles/ 但不再被引用（trap 除外）
- BoardCellRenderer 不再被 BoardView 引用
- DiceDebugPanel 使用独立 StyleBoxFlat 代替 CyberStyle.make_panel_bg 以实现半透明

## v0.1.58 - 2026-03-31

### 新增
- **美化 Phase 6：等距棋盘贴图替换**
- **IsoTileRenderer.gd**（~145行）：等距棋盘贴图渲染器（class_name 全局注册）
  - 9张等距方块贴图按格子类型加载缓存（普通浅/深、高台、陷阱、遭遇、恢复、道具、商店、宝箱）
  - grid_to_screen / screen_to_grid 格坐标↔屏幕坐标双向转换
  - painter's algorithm 按 depth=gx+gy 正确遮挡绘制
  - diamond_points / draw_diamond_highlight / draw_diamond_corners 菱形辅助绘制
- `UnitRenderer.draw_full_unit_iso()`：等距棋盘专用单位绘制（0.55缩放+菱形中心定位）
- `UnitRenderer.draw_affinity_star_iso()`：等距棋盘适性星标

### 修改
- `BoardView.gd`：全面等距化重写
  - 控件尺寸 576×576 → 576×350；新增 iso_origin = (288, 30)
  - _pixel_to_cell 从正方形网格除法改为 IsoTileRenderer.screen_to_grid
  - _draw_layer_grid 从 BoardCellRenderer.draw_base_cell 循环改为 IsoTileRenderer.draw_board
  - _draw_layer_overlays 从 Rect2 覆盖层改为菱形中心居中文字/符号
  - _draw_layer_highlights 从正方形 L 角标/准星改为菱形 diamond_corners/diamond_highlight
  - _draw_layer_units 从 cell×CELL_SIZE 改为 IsoTileRenderer.grid_to_screen + depth 排序
  - _draw_attack_flash 从正方形白闪改为菱形白闪
  - 7个反馈方法全部使用等距坐标定位
- `Main.gd`：CyberBackground 576×350 + summon_completed 等距坐标

### 备注
- BoardCellRenderer.gd 不再用于基础格绘制，文件保留供参考
- 原有 UnitRenderer.draw_full_unit / draw_affinity_star 保留，旧路径兼容
- 事件格/路径格/传送门格无专属贴图，使用程序化菱形叠层
- 逻辑层（BattleFlowController / UnitManager / BoardManager）零修改
- 卡牌面板（CardBattlePanel）零修改

## v0.1.57 - 2026-03-31

### 新增
- **层间难度递增**：根据 current_floor 动态缩放敌方 HP/ATK
- `BoardGenerator._floor_scaling()` 缩放函数：第1层基准，第2层 HP×1.3/ATK+1，第3层 HP×1.6/ATK+2
- 棋盘层哨兵单位按层缩放（第1层 HP5/ATK2 → 第3层 HP8/ATK4）
- 卡牌层遭遇敌方按层缩放（含 Boss：第1层 HP20/ATK3 → 第3层 HP32/ATK5）

### 修改
- `BoardGenerator.gd`：generate_board / _spawn_enemies 新增 current_floor 参数，缩放哨兵 HP/ATK
- `CardBattleController.gd`：get_encounter_enemy_data / start_battle 新增 current_floor 参数，缩放遭遇敌方 HP/ATK
- `BattleFlowController.gd`：3处 generate_board 调用传入 current_floor
- `Main.gd`：2处 start_battle 调用传入 _battle_flow.current_floor

### 备注
- 所有新增参数均有默认值 = 1，不破坏现有无参调用路径
- HP 缩放使用 ceil 向上取整，确保至少增加 1 点
- 缩放公式线性简单，后续可根据玩测反馈调整系数
- UI 面板 / BoardView / AudioManager 零修改

## v0.1.56 - 2026-03-31

### 新增
- **美化 Phase 5：音效系统**
- **SFXGenerator.gd**（~1100行）：从旧项目迁入完整程序化音频引擎（28种音效+4种BGM循环）
  - 8bit 芯片音风格 + 赛博朋克合成器音色 + EVA 暗色环境音
  - 所有音频运行时生成，无外部音频文件依赖
- **AudioManager.gd**（~120行）：音效管理器（class_name 全局注册）
  - 6通道 SFX 多路复用播放 + 1通道 BGM 循环播放
  - 启动时预缓存 18 种常用音效（attack_hit/defense/card_draw/card_play/victory/defeat 等）
  - BGM 按需生成并缓存（bgm_map/bgm_battle/bgm_boss/bgm_title）
  - `play_sfx(name)` / `play_bgm(name)` / `stop_bgm()` / `set_sfx_enabled()` / `set_bgm_enabled()` API

### 修改
- `Main.gd`：新增 `_audio: AudioManager` 成员，_ready 中创建并启动棋盘 BGM
  - 棋盘层接入：移动(click)/攻击(attack_hit)/召唤(summon)/掷骰(dice_roll)/地形伤害(player_hurt)/道具拾取(pickup)/回复(heal)/防御(defense)/商店(shop)/宝箱(chest)/遭遇(encounter)/Boss解锁(encounter)
  - 卡牌层接入：出牌(card_play)/敌方行动(enemy_hurt)/抽牌(card_draw)
  - 胜负反馈：胜利(victory)/失败(defeat)
  - BGM 切换：棋盘→遭遇(bgm_battle)/Boss(bgm_boss)→返回棋盘(bgm_map)
  - 设置按钮点击(click)

### 备注
- SFXGenerator 使用 class_name 全局注册，AudioManager 同样 class_name 注册
- AudioManager 在 _ready 时预生成并缓存常用音效，避免首次播放延迟
- BGM 在场景切换时自动切换（棋盘↔战斗↔Boss），相同 BGM 不重复启动
- 所有音效触发集中在 Main.gd 信号回调中，不侵入子模块代码
- BattleFlowController / CardBattleController / BoardView / UI面板均零修改

## v0.1.55 - 2026-03-31

### 新增
- **美化 Phase 4.2：UI 过渡动画**
- **UITransitions.gd**（~60行）：UI 过渡动画工具类（class_name 全局注册）
  - `popup()` 面板弹出动画：scale 0.9→1.0（EASE_OUT+TRANS_BACK 弹跳）+ alpha 0→1，0.2秒
  - `close()` 面板关闭动画：scale 1.0→0.95 + alpha 1→0，0.15秒，自动隐藏+复位
  - `close_await()` 异步关闭版本，可 await 等待完成
  - `summon_unit_spawn()` 召唤出场闪光：青色 ColorRect scale 弹跳 0.3→1.3→1.0 + 淡出
- **召唤展开演出**：路径格逐格铺展（每格 0.1s 延迟重绘）+ 单位出场闪光弹跳

### 修改
- `CardRewardPanel.gd`：奖励面板弹出/关闭/跳过/升级完成均接入 UITransitions 缓动动画
- `DeckViewPanel.gd`：open/close 接入 UITransitions 缓动动画
- `SettingsPanel.gd`：open/close 接入 UITransitions 缓动动画
- `Main.gd`：_on_summon_completed 重写为路径逐格铺展 + 召唤单位出场闪光
- 三个面板均新增 pivot_offset 设为面板中心，确保缩放动画从中心开始

### 备注
- UITransitions 使用 class_name 全局注册，无需 preload
- close() 完成后自动复位 scale=Vector2.ONE 和 modulate=Color.WHITE，防止残留状态
- 召唤展开演出为 async（使用 await timer），不阻塞棋盘操作但有视觉延迟
- BattleFlowController / CardBattleController / BoardView 零修改
- Phase 4.2 完成标准：面板弹出/关闭有缓动过渡感；召唤有展开演出而非直接出现

## docs: Snapshot 全面同步 - 2026-03-31

### 修改
- **CyberTao_Migration_Snapshot_zh_v3.md 全面重写**：从 v0.1.30 同步至 v0.1.54 状态
  - §2 已完成内容：棋盘层新增 18 项、卡牌层新增 9 项、视觉演出系统独立分类 9 模块
  - §3 架构概述：BattleV2 新增 3 模块、UI 层新增 10 模块、信号/数据结构全面更新
  - §4 技术债：标记 3 项已解决、新增当前 7 项
  - §5~§8 推进建议/文件索引/里程碑/状态描述全部更新
- Mulerun_Work_Report.md 更新为本轮文档同步任务

### 备注
- 纯文档任务，无代码修改
- AI_Employee_Guide_v3.md 已在 v0.1.54 时同步至最新，本轮确认无需修改

## v0.1.54 - 2026-03-30

### 新增
- **全屏独立卡牌战斗界面**：CardBattlePanel 从 500x470 浮窗重设计为 1280x720 全屏独立界面
  - 独立战斗背景：赛博朋克透视网格地面 + VS 标记 + 光弧装饰
  - 不再依赖暗幕（`_battle_dark_bg` 已移除），面板自带深色战斗场景背景
- **角色立绘系统**：新增 `BattleCharRenderer.gd`（~180行），程序化绘制战斗角色
  - 玩家英雄（刀盾犬）：赛博战士剪影（盾牌+光刃+V型护目镜+装甲躯干）
  - 6 种敌方角色立绘：异常哨兵（扫描眼）、赛博游魂（飘渺尾焰）、暗网爬虫（多足蜘蛛）、脉冲猎手（三角射手）、数据幽灵（菱形数据体）、零号协议（巨型三眼冠冕Boss）
  - 角色随脉冲参数实时动画（呼吸光效 + 发光变化）
- **扇形手牌布局**：卡牌以弧形排列在画面底部
  - FAN_RADIUS=700 / FAN_CARD_ANGLE=6° / FAN_MAX_ANGLE=22°
  - 卡牌尺寸从 90x108 放大到 105x130（全屏适配）
  - 悬停放大 1.12x + 上浮 20px + z-index 提升
- **棋盘单位美化**：UnitRenderer 重写为迷你角色剪影
  - 玩家角色：迷你赛博战士（躯干+四肢+盾+刃+护目镜）
  - 敌方 6 种独特造型匹配全屏战斗立绘
  - 替代旧版几何方框/三角形/菱形

### 修改
- `CardBattlePanel.gd` 完全重写（500x470 → 1280x720 全屏）
- `UnitRenderer.gd` 完全重写（几何形状 → 迷你角色剪影）
- `Main.gd`：CardBattlePanel 位置从 (390,125) 改为 (0,0)；移除 `_battle_dark_bg` 暗幕
- 全屏布局：敌方信息右上 / 玩家信息左下 / 战斗日志中央 / 手牌底部 / 操作按钮右下

### 备注
- BattleCharRenderer 使用 class_name 全局注册，无需 preload
- 角色绘制通过 Control._draw 回调实现，每帧更新脉冲动画
- CardBattlePanel 的 encounter_id 从 controller 获取，用于选择正确的敌方立绘
- Boss 立绘使用 2.8x 缩放，普通敌方使用 2.2x 缩放

## v0.1.53 - 2026-03-30

### 新增
- **Boss 解锁自动传送**：哨兵全灭后英雄自动传送到 Boss 格旁边，消除无意义的走路回合
  - `BattleFlowController._warp_hero_to_boss()` 查找英雄单位并传送到 Boss 旁空格
  - 新增 `hero_warped` 信号，Main.gd 连接后飘字"传送至 Boss！"
- **宝可梦式卡牌战斗过渡**：遭遇触发时播放全屏百叶窗过渡动画
  - 新增 `TransitionOverlay.gd`（CanvasLayer 10）：8 条水平百叶窗合拢/展开
  - 进入战斗：百叶窗合拢(0.35s) → 闪烁敌方名称(0.45s) → 展示战斗界面 → 百叶窗展开(0.3s)
  - 退出战斗：等待结果(0.8s) → 百叶窗合拢 → 隐藏面板 → 展开回棋盘
  - Boss 遭遇使用暗红色百叶窗
- **全屏暗幕**：卡牌战斗时黑色遮罩覆盖棋盘，营造独立场景感
- **遭遇名称闪字**：过渡时在百叶窗合拢后闪烁敌方中文名称

### 修改
- `CardBattlePanel._on_battle_started()` / `_on_battle_ended()` 不再自动控制 visible，由 Main.gd 通过过渡统一管理
- `Main._on_encounter_triggered()` 重写为异步过渡流程
- `Main._on_card_battle_ended()` 重写为异步过渡流程
- 调试按钮"测试战斗"也走过渡流程

### 备注
- CardBattlePanel 内部布局保持 500x470 不变，通过暗幕+居中实现场景隔离感
- TransitionOverlay 不影响任何现有 UI 层级（CanvasLayer 10 独立）
- v0.1.51 resolve_encounter 三分支、v0.1.52 单位精简均不受影响

## v0.1.52 - 2026-03-30

### 改进
- **单位精简**：玩家出场单位从 3 个减为 1 个主角（blade_shield_dog）
- **伙伴槽系统**：召唤改为伙伴部署，每层上限 2 次部署、场上上限 1 只伙伴
  - `BattleFlowController` 新增 `SUMMON_FLOOR_LIMIT=2`、`SUMMON_FIELD_LIMIT=1`、`_summon_this_floor` 计数
  - `get_summon_cells_for()` / `try_summon()` 增加层/场限制检查
  - `restart_battle()` / `advance_to_next_floor()` 重置 `_summon_this_floor`
- **英雄存活制胜负判定**：`VictoryRuleHelper.get_battle_outcome()` 改用 `has_hero_unit()`，仅非 summoned 的玩家单位视为英雄
  - 新增 `VictoryRuleHelper.has_hero_unit()` 静态方法
- **HUD 部署提示**：DiceDebugPanel 在 Crest 池下方显示本层部署剩余次数

### 精简
- `_spawn_player_units()` 仅生成 blade_shield_dog（移除 fire_fox、aqua_turtle）
- `_spawn_player_units_with_hp()` spawn_data 仅保留 blade_shield_dog 一条

### 备注
- v0.1.51 三分支 resolve_encounter 不受影响
- v0.1.50 传送门/Boss 锁定机制不受影响
- CardBattleController / CardBattlePanel / BoardManager 零修改

## v0.1.51 - 2026-03-30

### 修复
- **Boss/遭遇格击败消失 Bug**（阻塞性）
  - 根因：`resolve_encounter()` 无论胜败都调用 `board_manager.clear_encounter_cell()`
  - 修复：重写为三分支判断
    - 胜利 → 清除遭遇格 + Boss 生成传送门 + encounter_resolved 信号
    - 失败但存活 → 遭遇格保留（不清除），HP 保底 1，回到 PLAYER_ACTION，可再次挑战
    - 失败且全灭 → 触发 DEFEAT
  - 影响文件：BattleFlowController.gd、Main.gd
- Main.gd `_on_card_battle_ended()` 新增失败反馈飘字（"战斗失败..."）

### 备注
- 函数签名不变，信号签名不变，下游（CardBattleController/CardBattlePanel）零修改
- 失败时不发射 encounter_resolved 信号（遭遇未真正结束，DiceDebugPanel 的 encounter_panel 通过 phase_changed 正确隐藏）
- v0.1.50 的 Boss 传送门机制完整保留（is_boss + _spawn_portal_near 在胜利分支中）

## v0.1.50 - 2026-03-30

### 新增
- Boss 锁定机制：哨兵（grunt）全灭前 Boss 遭遇格显示为锁定状态（灰暗+锁链符号），不可触发
- 哨兵全灭自动解锁：所有 grunt 单位被击杀后，BFC 自动解锁 Boss 遭遇格，飘字提示"BOSS 解锁！"
- 传送门系统：击败 Boss 遭遇后在 Boss 格附近（优先下方）生成传送门
- 传送门格视觉：青蓝色旋涡同心圆环 + 脉冲辉光（BoardCellRenderer._draw_portal）
- Boss 锁定格视觉：灰暗红 + X 锁链符号 + LOCKED 文字（BoardCellRenderer._draw_boss_locked）
- VictoryRuleHelper.has_grunt_units()：检查是否还有存活哨兵单位
- BoardManager：locked_encounters/portal_cells 字典 + lock/unlock/portal 方法
- BFC 新信号：boss_unlocked(cell)、portal_spawned(cell)

### 修改
- BattleFlowController._check_battle_outcome()：不再简单判"全敌方死=胜利"
  - 哨兵全灭 → 解锁 Boss
  - 遭遇格仍存在时不判胜（等玩家踩 Boss 格触发卡牌战斗）
  - 传送门存在时不判胜（等玩家踩传送门触发通关）
- BattleFlowController._check_encounter()：锁定遭遇格不可触发
- BattleFlowController.resolve_encounter()：Boss 遭遇胜利 → 生成传送门
- BattleFlowController.try_move_unit()：新增 _check_portal() 调用
- BoardGenerator：Boss 遭遇格生成后自动调用 lock_encounter()
- BoardView：encounter_cells 渲染区分 boss/boss_locked/encounter 三种类型
- BoardView：新增 portal_cells 渲染循环
- Main.gd：连接 boss_unlocked/portal_spawned 信号，反馈飘字

### 备注
- 胜利条件链：击杀哨兵→Boss解锁→踩Boss格→卡牌战斗→胜利→传送门→踩传送门→通关/下一层
- BoardManager locked_encounters/portal_cells 在 build_test_board/clear_board 中正确清理
- advance_to_next_floor() 无需额外修改（clear_board 已清理新字典）

## v0.1.49 - 2026-03-30

### 新增
- 掷骰演出升级：伪 3D 等距骰子 + 全屏居中演出
- DiceRollAnimation.gd 完全重写（~252行）：
  - 全屏遮罩 PRESET_FULL_RECT，MOUSE_FILTER_STOP 阻止穿透
  - 3 枚等距立方体（六边形轮廓+三面着色+骰面符号+名称标签）
  - 翻滚→逐个定格→持显→淡出 四阶段动画
  - set_board_center() 接口，居中于棋盘中央而非右侧面板
- Main.gd 创建 DiceRollAnimation 实例并传入 DiceDebugPanel

### 修改
- DiceDebugPanel.gd：移除旧内嵌骰子创建代码，改由 Main 传入外部引用
  - 新增 set_dice_animation(anim) 方法

### 备注
- 骰子动画不再与 HUD 面板重叠，居中于棋盘区域（328, 382）
- Tween 动画链：遮罩淡入→翻滚→逐颗定格（弹跳缩放+辉光）→淡出
- DiceRollAnimation 作为 Main 最后一个 add_child，z-order 在最上层

## v0.1.48 - 2026-03-30

### 新增
- 美化 Phase 4.1 完整实现：背景氛围升级
- CyberBackground.gd（~155行）：背景氛围渲染系统
  - 三段渐变背景（12级色阶，深暗蓝→暗蓝灰→微亮蓝灰）
  - 透视网格线（棋盘下方，水平线带漂移动画+垂直线中心渐强）
  - 浮动粒子（CPUParticles2D，35个蓝光微粒，Gradient 淡入淡出）
  - 棋盘发光边框（4层外辉光+内层亮线+sin脉冲呼吸）
  - 四角 L 形装饰标记（青色短线）
  - 全屏缓慢扫描线（6px 半透明青色条循环）

### 修改
- Main.gd：纯色 ColorRect 背景 → CyberBackground 动态背景
  - 新增 CyberBackground preload
  - set_board_rect() 传入棋盘位置(40,94)和尺寸(576,576)

### 备注
- CyberBackground 纯视觉层，mouse_filter = IGNORE，不影响任何交互
- CPUParticles2D gl_compatibility 安全，不依赖 GPU 粒子
- 颜色常量定义在文件内部（背景专用，不污染 CyberStyle）
- 所有动画用 Time.get_ticks_msec() + sin() 驱动，不创建 Tween
- BattleFlowController/CardBattleController/BoardView 零修改
- Phase 4.1 完成标准：画面有赛博朋克氛围感，背景有动态层次而非纯色

## v0.1.47 - 2026-03-30

### 新增
- 美化 Phase 3 完整实现：卡牌战斗面板重设计
- CardRenderer.gd（~233行）：卡牌渲染工具类
  - create_card()：90x108 卡牌控件，类型图标+配色+费用+数值+悬浮效果
  - 6种卡牌类型独立配色：攻击橙/穿透金/吸血品红/电击紫/防御蓝/治疗绿
  - 升级卡牌：青色边框+发光阴影，不可用卡牌：暗灰+灰色文字
  - create_hp_bar()：圆角可视化血条（填充+高光+数值文字，<30%变色）
  - create_energy_dots()：圆角发光能量圆点（活跃蓝光/消耗暗灰）

### 修改
- CardBattlePanel.gd 重写（~329行）：
  - 手牌：105x48 文字按钮 → 90x108 CardRenderer 卡牌控件
  - HP 显示：纯文字 → 可视化血条（敌方红/我方绿）
  - 能量显示：文字 → 发光圆点（最多5个）
  - 敌方意图：增加图标前缀（⚔/⚔⚔/■⚔/✚/⚠）+ 独立配色
  - 面板尺寸：480x460 → 500x470
- Main.gd CardBattlePanel 位置居中：(280,140) → (390,125)

### 备注
- CardRenderer 纯静态设计，与 CyberStyle/BoardCellRenderer/UnitRenderer/BattleEffects 一致
- HP 条/能量点采用 container 清空+重建模式，简单可靠
- CardBattleController 零修改，所有信号签名不变
- CardRewardPanel 暂未同步升级（独立面板，后续统一处理）
- gl_compatibility 安全：Panel + StyleBoxFlat 圆角，无 GPU 依赖
- Phase 3 完成标准：卡牌战斗面板看起来像"卡牌游戏"而非"调试按钮列表"

## v0.1.0 - 2026-03-29

### Added

- created the parallel rebuild workspace `CyberTao_Dice_Beast_Protocol/`
- added top-level project documentation and technical blueprint
- created a standalone Godot subproject scaffold under `Project/`
- added a minimal entry scene and startup script
- added the first pass of the `BattleV2` architecture scaffold
- added resource script stubs for units, skills, items, cores, and dice faces
- added a dedicated `Logs/` folder for migration and version tracking
- added a reusable Mulerun handoff template for account-to-account continuity
- added the first debug board view and dice debug panel
- added a first prototype unit resource: blade shield dog

### Improved

- wired the main scene to the new BattleV2 managers
- added manager signals for board, units, phase, and dice roll updates
- spawned debug units and demo path support for the visual prototype
- expanded the skill data model for cooldown, targeting, and trait gating
- added the first skill resource definitions for blade shield dog
- added a reusable skill effect library stub for combat effect execution
- added a first explicit combat rules document for the prototype phase
- added the first pickup item resource set
- added the first dice face resource set
- added a second prototype faction unit: hacker fox
- added a content roadmap document for prototype batching
- added an item effect library stub
- added a third prototype unit: crow caster
- added first prototype core resource
- added a unit keyword reference document
- added first attack helper and target query support
- added prototype attack rule documentation
- added early attack-oriented skill resources for dog and fox units
- added first victory-rule helper for post-attack battle-end checks
- added explicit HP and victory rule documentation for prototype combat

### Notes

- legacy `CyberTao8` remains preserved as reference
- new development should prioritize the new `Project/` folder
- future updates should append to this changelog and keep migration snapshot in sync

## v0.1.1 - 2026-03-29

### Added

- unit selection: click a player unit on the board to select it (gold ring indicator)
- movable cell highlighting: BFS-based reachable cell calculation respecting move_range and occupied cells
- cyan highlight overlay on all valid move targets when a unit is selected
- click-to-move: click a highlighted cell to move the selected unit there
- MOVE crest cost: each move consumes 1 MOVE resource from the dice crest pool
- "Selected: ..." display in the debug panel showing current selection state
- debug panel auto-refreshes crest pool display after each move
- `BoardManager.get_reachable_cells()`: BFS within move_range, skipping occupied cells
- `UnitManager.board_manager` sync: spawn/move/despawn now keep `BoardManager.occupied_cells` in sync
- `UnitManager.unit_moved` signal for move event tracking
- `UnitManager.get_player_units()` helper
- `BattleFlowController.try_move_unit()`: validates reachability, pays MOVE crest, executes move
- `BattleFlowController.get_reachable_cells_for()`: delegates to BoardManager BFS
- `BattleFlowController.move_completed` signal
- `BoardView` signals: `unit_selected`, `unit_deselected`, `move_requested`
- `DiceDebugPanel.bind_board_view()` for selection event subscription
- `move_range` field now stored in unit state and passed from UnitData on spawn

### Changed

- `BoardView.mouse_filter` changed from `MOUSE_FILTER_IGNORE` to `MOUSE_FILTER_STOP` to enable click input
- debug panel height increased from 380 to 440 to accommodate new selected unit label
- `Main._wire_debug_views()` now connects board view signals and binds board view to debug panel

### Notes

- only player units can be selected and moved
- only orthogonal movement (up/down/left/right) is supported
- no attack system implemented yet
- no pathfinding beyond BFS range check
- no movement animation; position updates are instant

## v0.1.2 - 2026-03-29

### Fixed

- dice roll now limited to once per turn: `start_player_roll()` only executes during PLAYER_ROLL phase, then auto-transitions to PLAYER_ACTION
- Roll Dice button in debug panel is disabled after rolling (re-enabled only in PLAYER_ROLL phase)
- movable cell highlights now respect MOVE crest availability: `get_reachable_cells_for()` returns empty when MOVE <= 0
- highlights refresh immediately after every move attempt (success or failure), clearing when MOVE is exhausted

### Notes

- no "End Turn" button yet; to roll again after spending resources, a phase-reset mechanism is still needed
- the roll-once restriction is per phase transition, not a stored flag — future turn flow will manage this naturally

## v0.1.3 - 2026-03-29

### Added

- End Turn button in debug panel: ends player action phase and advances to next round
- `BattleFlowController.end_player_turn()`: clears crest pool, increments round_index, resets to PLAYER_ROLL
- `BattleFlowController.round_changed` signal emitted on round advance
- `DiceManager.reset_for_turn()`: clears crest pool and last roll results at turn boundary
- round number display ("Round: N") in debug panel
- End Turn button enabled only during PLAYER_ACTION, disabled otherwise
- BoardView deselects unit and clears highlights on any phase transition

### Changed

- debug panel height increased from 440 to 500 to accommodate End Turn button and round label
- debug panel layout reorganized: round label, phase label, selected label, Roll Dice, End Turn, Spawn Demo Path, roll results, crest pool
- `_on_phase_changed` now also refreshes crest pool display (shows zeroed pool after turn reset)

### Notes

- the minimum turn cycle now works: Roll Dice → move unit → End Turn → Roll Dice again
- crest pool is fully cleared at turn start (simple reset, no carry-over)
- no enemy turn yet; End Turn skips directly back to PLAYER_ROLL
- no attack system implemented

## v0.1.4 - 2026-03-29

### Added

- attack highlighting: red overlay on adjacent enemy cells when a player unit is selected and ATTACK crest > 0
- click-to-attack: clicking a red-highlighted enemy cell triggers a basic attack
- `BattleFlowController.try_attack_unit()`: validates adjacency, pays 1 ATTACK crest, applies damage via `AttackRuleHelper.calc_basic_damage()`
- `BattleFlowController.get_attackable_cells_for()`: delegates to `ActionResolver.get_attackable_cells()`, gated on ATTACK crest availability
- `BattleFlowController.attack_completed` signal (attacker_id, defender_id, damage, killed)
- `BoardView.attack_requested` signal for attack click events
- `BoardView.attack_highlight_cells` array for red attack target rendering
- `BoardView._draw_attack_highlights()`: red filled + red border rectangles on attackable cells
- `DiceDebugPanel._on_attack_completed()`: refreshes crest pool display after each attack
- `Main._on_attack_requested()`: wires attack signal, refreshes both move and attack highlights after attack
- if target HP <= 0, unit is despawned from board via existing `UnitManager.apply_damage()` → `despawn_unit()`

### Changed

- `_handle_cell_click()` now checks attack targets before move targets (attack takes priority on enemy-occupied cells)
- `_select_unit()` and `_on_state_changed()` now compute both move and attack highlights
- `_deselect()` now clears both highlight arrays
- `_on_move_requested()` now refreshes attack highlights alongside move highlights

### Notes

- minimum combat loop now works: Roll → Move → Attack → End Turn
- attack is melee-only (orthogonal adjacent, range 1)
- damage formula: max(1, attacker.atk - defender.def)
- no attack animation; damage is applied instantly
- no HP display on units yet
- no enemy turn or enemy AI
- no victory/defeat check on kill

## v0.1.5 - 2026-03-29

### Fixed

- `UnitManager.spawn_unit()` now stores `attack_range` in unit state (was missing, causing `ActionResolver.get_attackable_cells()` to always fall back to default)
- `BattleFlowController._spawn_debug_units()` now passes `attack_range` from `UnitData` resource for player unit and from hardcoded payload for enemy unit

### Notes

- this is a data-link fix only; no new features or behavior changes
- all units already defaulted to `attack_range = 1` via fallback, so visible behavior is unchanged for the current prototype
- the fix ensures future units with non-default attack_range will work correctly

## v0.1.6 - 2026-03-29

### Added

- HP display on all units: white `hp/max_hp` text drawn on each unit rectangle
- victory/defeat check after every attack using `VictoryRuleHelper.get_battle_outcome()`
- `BattleFlowController._check_battle_outcome()`: calls `mark_victory()` when all enemies dead, `mark_defeat()` when all player units dead
- `BattleFlowController.is_battle_over()`: returns true if phase is VICTORY or DEFEAT
- result banner label in Main scene: large "VICTORY" (green) or "DEFEAT" (red) text appears at top center
- debug panel phase label turns green on VICTORY, red on DEFEAT
- all buttons disabled on terminal phase (VICTORY/DEFEAT)
- board click input blocked when battle is over

### Changed

- `try_move_unit()`, `try_attack_unit()`, `start_player_roll()`, `end_player_turn()` all guard on `is_battle_over()`
- `_on_phase_changed` in DiceDebugPanel now handles terminal phases with colored text and full button disable
- `Main._wire_debug_views()` now connects `phase_changed` for result banner display

### Notes

- minimum combat prototype is now complete: Roll → Move → Attack → End Turn → Victory/Defeat
- HP is displayed as text overlay; no HP bar yet
- no restart mechanism after victory/defeat
- no enemy AI turn; enemy never fights back

## v0.1.7 - 2026-03-29

### Added

- display settings system: `DisplaySettings` node handles resolution, window mode, and persistence via `ConfigFile`
- settings panel UI (`SettingsPanel`): resolution dropdown (1280x720, 1600x900, 1920x1080), window mode dropdown (windowed, fullscreen, borderless), apply/reset/close buttons
- "设置" button in top-right corner of main scene opens settings panel
- settings saved to `user://display_settings.cfg` and loaded on startup
- `DisplayServer` API used for window mode switching, resize, and centering

### Changed

- default viewport changed from 1920x1080 to 1280x720 in `project.godot`
- `Main.gd` layout repositioned for 1280x720: board at (40,160), dice panel at (660,160), labels resized to 1280 width
- `Main.gd` now preloads and instantiates `DisplaySettings` and `SettingsPanel`

### Notes

- settings panel appears centered over the board when opened
- resolution change takes effect immediately on "应用" (apply)
- "恢复默认" resets to 1280x720 windowed
- battle prototype functionality unchanged

## v0.1.8 - 2026-03-29

### Fixed

- `DiceDebugPanel.bind_battle_flow()` round label initialization used English "Round: " instead of Chinese "回合：" — now consistent with all other Chinese UI text

### Notes

- all three UI scripts (Main.gd, DiceDebugPanel.gd, SettingsPanel.gd) verified as valid UTF-8 with correct Chinese encoding
- no logic changes, text-only fix

## v0.1.9 - 2026-03-29

### Fixed

- rewrote all three UI scripts (Main.gd, DiceDebugPanel.gd, SettingsPanel.gd) from scratch via Python with Unicode escape sequences to guarantee clean UTF-8 Chinese encoding
- all Chinese text strings verified byte-by-byte after rewrite

### Notes

- no logic or layout changes; identical behavior to v0.1.8
- rewrite approach used to eliminate any possible encoding layer corruption

## v0.1.10 - 2026-03-29

### Fixed

- board click interaction restored: `bg` ColorRect, title/subtitle/hint labels, and `_result_label` now set `mouse_filter = MOUSE_FILTER_IGNORE` so they never intercept clicks meant for the board
- `SettingsPanel` now starts with `mouse_filter = MOUSE_FILTER_IGNORE` (was `MOUSE_FILTER_STOP`); toggles to `STOP` only when opened, back to `IGNORE` on close — prevents invisible panel from blocking board clicks in its overlapping region
- `BoardView._gui_input()` now calls `accept_event()` after handling a click to properly consume the input event

### Notes

- root cause: Controls in Godot 4 default to `MOUSE_FILTER_STOP`, which can intercept mouse events even for purely decorative nodes; the full-screen `bg` ColorRect and full-width labels were potential input blockers
- `SettingsPanel` at position (440,200) size 400x320 overlapped the board at (40,160) size 576x576 — with `MOUSE_FILTER_STOP` while invisible, it could block clicks in the overlap zone [440,200]-[616,520]
- no logic, layout, or feature changes — interaction-only fix

## v0.1.11 - 2026-03-29

### Changed

- guaranteed minimum 1 MOVE crest per dice roll: if random roll produces 0 MOVE, pool is set to 1 MOVE after rolling
- enemy debug unit spawn position moved from (7,1) to (3,4) — manhattan distance to player reduced from 12 to 5

### Notes

- prototype playability fix: with 3 dice and 6 faces, probability of 0 MOVE per roll was 57.9% — most turns were unplayable
- guaranteed MOVE ensures every turn has at least 1 movement action available
- new enemy position (3,4) means player at (0,6) can reach and attack within 2-3 rounds
- no new features, no enemy AI, no visual changes

## v0.1.12 - 2026-03-29

### Added

- attack feedback: white flash on hit cell (tween fade 0.35s) + red floating damage number (-N) that rises and fades out (0.6s)
- `BoardView.play_attack_feedback()`: creates flash overlay via `_draw_attack_flash()` and spawns a temporary Label for damage number with position+alpha tween
- "重新开始" (restart) button appears on VICTORY or DEFEAT phase, positioned at top center
- `BattleFlowController.restart_battle()`: resets dice, clears all units, rebuilds board, re-spawns debug units, returns to round 1 PLAYER_ROLL
- `UnitManager.clear_all_units()`: clears all unit state and occupied cells
- `BoardManager.clear_board()`: clears occupied, path, and item cells
- `Main._on_attack_completed()`: captures damage for feedback display
- `Main._on_restart_pressed()`: clears board selection and triggers battle restart

### Changed

- `Main._on_phase_changed()` now shows/hides restart button alongside result label
- `Main._on_attack_requested()` triggers `play_attack_feedback()` on successful attack

### Notes

- attack feedback is visual only — no sound effects
- restart fully resets to initial state (same as fresh load)
- no enemy AI; enemy still does not act

## v0.1.13 - 2026-03-29

### 新增

- 敌方 AI 最小回合：玩家点击"结束回合"后，进入 ENEMY_ROLL → ENEMY_ACTION → 自动回到 PLAYER_ROLL
- `BattleAI` 重写：添加 `get_enemy_units()`、`find_nearest_player_cell()`、`get_adjacent_player_cells()`、`pick_move_toward()` 四个核心方法
- `BattleFlowController` 添加 `_start_enemy_turn()`、`_execute_enemy_actions()`、`_advance_to_next_player_round()` 三个敌方回合方法
- `BattleFlowController` 添加 `enemy_attack_completed` 信号（包含 target_cell 参数）
- 敌方攻击时在目标格显示白色闪光 + 红色飘字（与玩家攻击反馈一致）
- `DiceDebugPanel` 连接 `enemy_attack_completed` 信号，敌方攻击后刷新 crest 池显示

### 修改

- `end_player_turn()` 不再直接跳回 PLAYER_ROLL，改为触发敌方回合流程
- 敌方回合期间，掷骰按钮和结束回合按钮自动禁用
- 调试面板阶段标签正确显示"敌方掷骰"/"敌方行动"

### 敌方 AI 行为

- 遍历所有存活敌方单位
- 优先攻击：如果相邻有玩家单位且有 ATTACK crest → 攻击（消耗 1 ATTACK）
- 否则移动：朝最近玩家单位方向移动 1 格（消耗 1 MOVE）
- 移动后再攻击：移动后如果相邻有玩家单位且有 ATTACK crest → 再次攻击
- 使用 await timer 在行动之间添加短延迟（0.3s-0.5s），让玩家可以观察敌方行为

### 备注

- 敌方 AI 为最小可用实现，不包含高级策略或行为树
- 敌方掷骰使用与玩家相同的 DiceManager（保底 1 MOVE）
- 移动仍为瞬间位移，无动画
- 当前只有 1 个调试敌方单位

## v0.1.14 - 2026-03-29

### 新增

- 召唤系统原型（summon + path-building 第一版）
- `BattleFlowController` 添加 `summon_completed` 信号、`get_summon_cells_for()`、`try_summon()` 方法
- `BoardManager` 添加 `get_free_neighbors()` 辅助方法
- `BoardView` 添加 `summon_requested` 信号和 `summon_highlight_cells` 紫色高亮渲染
- 棋盘点击召唤：选中玩家单位且有 SUMMON crest 时，相邻空格显示紫色高亮，点击即触发召唤
- 调试面板"测试召唤"按钮：需选中单位 + 有显化 crest，一键在第一个可用格召唤
- 召唤时自动铺设 2 格路径（目标格 + 向外延伸 1 格），归属 player
- 召唤在目标格生成 summoned_fox 测试单位（HP 4 / ATK 2 / DEF 0 / 移动 2 / 攻击 1）
- 每次召唤生成唯一 ID（summoned_fox_1, summoned_fox_2, ...）
- 路径格可视化改进：玩家路径为青色发光、其他路径为橙色

### 修改

- `BoardView._draw_paths()` 重写：区分 player/other 路径颜色，添加边框渲染
- 调试面板"生成测试路径"按钮替换为"测试召唤（需选中单位+显化）"
- `Main.gd` 提示文字更新为"青色=移动 红色=攻击 紫色=召唤铺路"
- 移动、攻击后同时刷新召唤高亮
- 重开战斗时清空 summon_highlight_cells 和 _summon_counter

### 备注

- 本轮为最小原型，验证"召唤即铺路"概念
- 召唤单位为 hardcoded 数据，未接入 UnitData 资源
- 路径格目前不影响移动规则（仅视觉标记）
- 无召唤动画、无召唤数量限制
- 路径形状固定为 2 格直线延伸

## v0.1.15 - 2026-03-29

### 新增

- 地形系统原型（高台格 + 陷阱格 第一版）
- `BoardManager` 添加 `terrain_cells` 字典、`add_terrain_cell()`、`get_terrain_type()`、`get_move_cost()` 方法
- 高台格规则：进入高台格消耗 2 移动点（普通格 1 点）；站在高台上攻击范围 +1
- 陷阱格规则：单位进入陷阱格时立即受到 1 点伤害，可致死并触发胜负判定
- `BattleFlowController` 添加 `terrain_damage_triggered` 信号和 `_check_terrain_trap()` 方法
- `BattleFlowController._spawn_debug_terrain()`：预置 2 个高台格 (2,4)(2,5) 和 2 个陷阱格 (1,5)(3,6)
- `ActionResolver.get_attackable_cells()` 高台加成：检测单位是否站在高台上，是则 attack_range += 1
- `BoardView._draw_terrain()`：高台格金色填充+边框+"HIGH"标记文字，陷阱格暗红填充+边框+"TRAP"标记文字
- 地形与路径格可共存（terrain_cells 和 path_cells 独立存储）
- 陷阱伤害触发攻击反馈（白色闪光 + 红色飘字）
- 提示文字更新："金色=高台 暗红=陷阱"

### 修改

- `BoardManager.get_reachable_cells()` BFS 重写：从固定 cost=1 改为使用 `get_move_cost()` 计算每格移动消耗
- `BoardManager.build_test_board()` 和 `clear_board()` 现在清空 `terrain_cells`
- `BattleFlowController.try_move_unit()` 移动后检查陷阱地形
- `BattleFlowController._execute_enemy_actions()` 敌方移动后检查陷阱地形
- `BattleFlowController.restart_battle()` 重开时重新放置调试地形
- `DiceDebugPanel` 连接 `terrain_damage_triggered` 信号，地形伤害后刷新 crest 池显示

### 备注

- 地形格为纯数据标记，不阻挡移动（高台只是消耗更多，不是不可进入）
- 陷阱格可重复触发（每次进入都受伤）
- 当前只有 hardcoded 调试布局，无地形编辑器
- 高台攻击加成对玩家和敌方均生效（ActionResolver 不区分阵营）
- 无地形相关动画或音效

## v0.1.16 - 2026-03-29

### 修复

- 修复敌方单位踩陷阱死亡后仍尝试攻击的 bug：`_execute_enemy_actions()` 在陷阱检查后增加单位存活判定，死亡则跳过后续攻击
- 修复选中单位被击杀后残留幽灵选中状态的 bug：`BoardView._on_state_changed()` 检测选中单位是否仍存活，不存在则自动取消选中

### 备注

- 本轮为 summon / path-building 第一版收口，只修稳定性问题，不增加新功能
- 审查了召唤流程、路径格生成、召唤单位落位、召唤后对原有闭环的影响
- 审查确认以下流程在召唤后均正常：选中单位、MOVE 移动、ATTACK 攻击、敌方回合、Victory/Defeat、重新开始
- 召唤资源消耗（SUMMON crest）、路径格视觉区分、路径格与单位共存逻辑均稳定

## v0.1.17 - 2026-03-29

### 修复

- 修复棋盘底部被裁切的布局问题：标题区从 160px 压缩到 94px，棋盘底部从 736 降至 670，完全在 720 视口内
- 修复分辨率设置无视觉效果的问题：`DisplaySettings.apply_settings()` 现在同步更新 `root.content_scale_size`，使不同分辨率有真实视觉变化

### 修改

- `Main.gd` 布局重排：标题 y=4（原 42）、副标题 y=44（原 96）、提示 y=68（原 126）、棋盘/调试面板 y=94（原 160）
- 标题字号 30（原 34）、副标题字号 16（原 18）、提示字号 13（原 15）
- 胜负标签和重开按钮位置同步调整
- `DisplaySettings.apply_settings()` 新增 `root.content_scale_size` 更新

### 备注

- 棋盘底边 94+576=670，距视口底部 720 有 50px 余量
- 分辨率切换效果：1280x720 为标准布局，1600x900/1920x1080 窗口和虚拟视口同步放大
- 无功能逻辑变化，纯布局和显示修复

## v0.1.18 - 2026-03-29

### 修复

- 修复点击移动时误触召唤的严重 bug：相邻空格同时满足移动和召唤条件时，原代码优先执行召唤而非移动，导致意外生成 4/4 "分身"单位
- 点击优先级从 attack > summon > move 改为 attack > move > summon
- 召唤紫色高亮现在排除已在移动高亮中的格子，仅在"不可移动但可召唤"的格子显示紫色
- `BoardView._filter_summon_cells()`：新增辅助方法，从召唤候选格中移除移动候选格
- `Main.gd` 所有高亮刷新点（移动后、攻击后、召唤后）均使用过滤后的召唤高亮

### 备注

- 根因：adjacent free cells 同时存在于 BFS 可达集和召唤候选集，原 summon 优先导致误触
- 修复后行为：有 MOVE crest 时点击相邻格 = 移动；无 MOVE 但有 SUMMON 时 = 召唤
- 调试面板"测试召唤"按钮不受影响，始终可用

## v0.1.19 - 2026-03-29

### 新增

- 单位地形适性系统第一版：每种单位拥有不同的地形适性标签，影响战斗表现
- `UnitData.gd` 新增 `terrain_affinity` 字段（"high_ground" / "path" / "trap"）
- 刀盾狗（blade_shield_dog）：路径适性 — 站在路径格上 DEF +1
- 灵狐骇客（hacker_fox）：陷阱适性 — 免疫陷阱伤害
- 鸦机术士（crow_caster）：高台适性 — 高台攻击范围加成 +2（非通用的 +1）
- 三个 .tres 单位文件均添加 `terrain_affinity` 属性
- `BattleFlowController._calc_damage_with_terrain()`：含地形适性加成的伤害计算（路径格 DEF +1）
- `BattleFlowController._check_terrain_trap()` 增加陷阱适性免疫检查
- `ActionResolver.get_attackable_cells()` 高台适性单位在高台上攻击范围 +2
- `UnitManager.spawn_unit()` 新增 `terrain_affinity` 和 `display_name` 字段传递
- `BoardView._draw_unit_names()`：单位名称缩写显示（区分不同单位）
- `BoardView._draw_terrain_affinity_indicator()`：单位站在匹配地形上时显示 * 指示器
- 调试布局升级为 3 个玩家单位 + 2 个敌方单位
- 提示栏新增 "*=适性激活" 说明

### 修改

- `_spawn_debug_units()` 重写：生成刀盾狗(0,6)、灵狐骇客(1,7)、鸦机术士(0,5) 三个玩家单位
- 敌方从 1 个增加到 2 个：哨兵甲(3,4) HP5/ATK2 + 哨兵乙(5,3) HP4/ATK3
- 所有伤害计算（玩家攻击、敌方攻击）统一使用 `_calc_damage_with_terrain()`

### 备注

- 三种适性效果简洁且互不重叠：攻击增强（高台）、防御增强（路径）、生存增强（陷阱）
- 适性激活需要"站在匹配地形上"，鼓励地形策略
- 敌方单位暂无地形适性（可在 AI 增强版本中添加）
- 召唤单位暂无地形适性

## v0.1.20 - 2026-03-29

### 新增

- 道具拾取系统第一版：棋盘上放置可拾取道具格，单位移动经过时自动拾取
- `BattleFlowController._spawn_debug_items()`：预置 2 个道具格（补丁凉茶 + 超频骨头）
- `BattleFlowController._check_item_pickup()`：单位移动后检查目标格是否有道具
- `BattleFlowController._apply_item_effect()`：执行道具效果并返回效果描述
- `BattleFlowController.item_picked_up` 信号（unit_id, item_id, effect_text, cell）
- 接入 `ItemEffectLibrary`：3 种道具效果从 stub 变为实际生效
  - 补丁凉茶（patch_tea_cache）：回复 2 HP
  - 超频骨头（overclock_bone）：+1 MOVE crest
  - 故障零食盒（glitch_snack_box）：随机 +1 ATTACK/DEFEND/SKILL crest
- `BoardView._draw_items()`：绿色填充+边框+道具名称缩写渲染
- `BoardView.play_pickup_feedback()`：拾取时绿色飘字显示效果（HP+2 / MOVE+1 等）
- `DiceDebugPanel` 连接 `item_picked_up` 信号，拾取后刷新 crest 池显示
- `Main.gd` 连接 `item_picked_up` 信号，触发拾取反馈
- 提示栏新增 "绿色=道具" 说明

### 修改

- `try_move_unit()` 移动后增加道具拾取检查（陷阱检查之后，确保存活才拾取）
- `restart_battle()` 重开时重新放置调试道具
- `BoardManager.item_cells` 字典从死链变为实际使用

### 备注

- 道具格被拾取后从棋盘消失（不可重复拾取）
- 当前为固定放置，不支持随机生成
- 仅玩家单位触发拾取，敌方移动不触发
- 道具效果为即时生效，无持续 buff（BuffManager.tick_turn 仍未接入）
- 补丁凉茶回复不超过 max_hp

## v0.1.21 - 2026-03-29

### 新增

- 敌方 AI 可读性增强第一版：意图广播 + 加长停顿 + 攻击预警
- `BattleFlowController` 新增 `enemy_action_announced` 信号：每个敌方行动前广播意图（"哨兵甲 → 攻击 刀盾狗"）
- `BattleFlowController` 新增 `enemy_turn_ended` 信号：所有敌方行动完成后广播
- `BattleFlowController._get_unit_display_name()`：统一获取单位显示名称
- `BoardView.play_enemy_warning()`：攻击意图广播时目标格橙色预警闪烁（0.6s）
- `BoardView.play_enemy_move_indicator()`：移动意图指示（橙色单位名称渐隐）
- `DiceDebugPanel` 新增 `enemy_intent_label`：橙色标签实时显示敌方行动内容
- 敌方回合结束时面板显示 "敌方回合结束"
- 玩家阶段开始时自动清空意图文字

### 修改

- `_execute_enemy_actions()` 重写：每步行动前广播意图、等待预读时间后再执行
- 敌方行动停顿时间全面加长：掷骰 0.5→0.8s，攻击后 0.4→0.7s，移动后 0.3→0.6s
- 每步行动前新增意图预读等待：攻击 0.6s，移动 0.5s
- 敌方回合结束后新增 0.5s 过渡等待再回到玩家回合
- `DiceDebugPanel.crest_label` 高度从 180 缩减为 140，为意图标签腾出空间

### 备注

- AI 决策逻辑未变（仍为简单的优先攻击/朝最近玩家移动）
- 本轮仅改善可读性，不增加 AI 策略复杂度
- 面板只显示最后一条意图，不保留敌方行动历史日志
- 预警闪烁使用与攻击反馈相同的 `_flash_cell` 机制，不会同时多格闪烁

## v0.1.22 - 2026-03-29

### 新增

- 遭遇格原型入口（Day 6：棋盘走位层扩展）
- `BoardManager` 新增 `encounter_cells` 字典（cell → encounter_id）
- `BoardManager.add_encounter_cell()`：添加遭遇格，含边界检查
- `BoardManager.clear_encounter_cell()`：清除指定遭遇格
- `BattleFlowController` 新增 `encounter_triggered` 信号（unit_id, encounter_id, cell）
- `BattleFlowController._spawn_debug_encounters()`：预置 2 个遭遇格 (4,4) encounter_01、(6,5) encounter_02
- `BattleFlowController._check_encounter()`：玩家单位移动到遭遇格时触发遭遇信号
- `BoardView._draw_encounters()`：遭遇格渲染为橙红色填充 + 边框 + "遭遇" 文字标记
- `BoardView.play_encounter_feedback()`：遭遇触发时橙红色飘字反馈（"遭遇！"上浮渐隐 0.9s）
- `DiceDebugPanel` 连接 `encounter_triggered` 信号，触发时显示 "遭遇！准备进入战斗... [encounter_id]"
- `Main.gd` 连接 `encounter_triggered` 信号，触发橙红飘字反馈
- 提示栏新增 "橙红=遭遇" 说明

### 修改

- `BoardManager.build_test_board()` 和 `clear_board()` 现在清空 `encounter_cells`
- `BattleFlowController.try_move_unit()` 移动后增加遭遇格检查（道具拾取之后）
- `BattleFlowController._bootstrap()` 和 `restart_battle()` 调用 `_spawn_debug_encounters()`

### 备注

- 本轮为遭遇入口最小验证，不切场景、不实现卡牌战斗
- 当前踩遭遇格只触发信号和占位提示，不暂停棋盘流程
- 遭遇格踩后不消失（Day 7 遭遇暂停流程中处理清除逻辑）
- 遭遇格位置：(4,4) 在玩家前进路线中段，(6,5) 在侧翼可选绕行
- 为 Day 7（遭遇暂停）和 Day 9（卡牌战斗）预留了信号接口

## v0.1.23 - 2026-03-29

### 新增

- 遭遇暂停与战斗占位流程（Day 7：棋盘走位层 → 双层入口）
- `BattlePhase.ENCOUNTER` 新阶段枚举：遭遇触发后棋盘进入暂停状态
- `BattleFlowController.encounter_resolved` 信号（encounter_id, cell）
- `BattleFlowController.resolve_encounter()`：遭遇结算方法，清除遭遇格并回到 PLAYER_ACTION
- `BattleFlowController` 新增遭遇上下文变量：`_encounter_unit_id`、`_encounter_id`、`_encounter_cell`
- `DiceDebugPanel` 新增遭遇战斗占位面板（`encounter_panel`）：橙红色背景 + "战斗开始 [encounter_id]" 标题 + "战斗胜利（占位）"按钮
- 遭遇清除反馈：解除遭遇后在遭遇格位置显示绿色"遭遇清除"飘字
- `_phase_label_text()` 新增 "ENCOUNTER" → "遭遇战斗" 映射

### 修改

- `_check_encounter()` 重写：从仅发信号改为进入 ENCOUNTER 暂停状态 + 保存遭遇上下文
- `BoardView._handle_cell_click()` 新增 ENCOUNTER 阶段点击屏蔽（与 VICTORY/DEFEAT 一致）
- `DiceDebugPanel._on_phase_changed()` 新增 ENCOUNTER 处理：禁用掷骰/结束回合按钮，阶段标签变橙色
- `DiceDebugPanel._on_encounter_triggered()` 更新：除显示文字提示外，同时弹出战斗占位面板
- `Main.gd` 连接 `encounter_resolved` 信号，触发绿色飘字反馈
- `restart_battle()` 清空遭遇上下文变量

### 完整流程

踩遭遇格 → 棋盘进入 ENCOUNTER 暂停 → 禁止所有操作 → 弹出战斗占位面板 → 点击"战斗胜利（占位）" → 遭遇格消失 → 回到 PLAYER_ACTION 继续

### 备注

- 占位面板为 Day 9 最小卡牌战斗原型的替换入口
- `resolve_encounter()` 预留了战斗结果参数扩展空间
- 遭遇格被清除后不再触发（单次遭遇）
- ENCOUNTER 阶段期间，掷骰/移动/攻击/召唤/结束回合均被禁止

## v0.1.30 - 2026-03-29

### 新增

- 阶段收口与日志整理（Day 12）
- `CyberTao_Migration_Snapshot_zh_v3.md` 全面重写：从 v0.1.24 更新到 v0.1.30
  - 新增卡牌战斗层完成状态表（12 项）
  - 新增双层闭环完整流程图
  - 新增遭遇敌方数据表和 10 张卡牌牌组表
  - 新增 CardBattleController / CardBattlePanel / CyberStyle 到文件索引
  - 新增卡牌层信号体系和数据结构
  - 新增技术债清单（6 项）
  - 新增下一阶段推进建议（4 个方向 15+ 具体建议）
  - 新增版本里程碑总览表（v0.1.0 → v0.1.30）
- `Weekly_Mulerun_Plan_zh_v2.md` 收口：Day 11/12 标记已完成，总结更新

### 备注

- 纯日志整理，无代码变更
- 第一阶段（Day 1~12）全部完成
- 30 个版本（v0.1.0 → v0.1.30）从零完成双层玩法闭环
- 所有已知问题和技术债已记录在 Snapshot 第 4 节

---

## v0.1.29 - 2026-03-29

### 新增

- 统一赛博朋克视觉风格系统（Day 11：UI 去调试化第一版）
- `Scripts/UI/CyberStyle.gd`（全新文件）：全局视觉常量和样式工厂
  - 30+ 命名颜色常量：背景/主色调/边框/文字/HP/按钮
  - 三大主色调：青色（信息）/ 橙色（战斗）/ 品红（技能）
  - 面板背景工厂 `make_panel_bg()`：暗底+霓虹边框+阴影
  - 按钮四态工厂：normal/hover/pressed/disabled 各有独立 StyleBoxFlat
  - `style_button(btn, accent)` 一键风格化（支持 cyan/orange 主题）
  - `make_encounter_panel_bg()` 遭遇面板专用背景

### 修改

- **DiceDebugPanel** 视觉全面升级
  - 面板从灰色调试风格变为深蓝黑底+青色霓虹边框
  - 所有按钮使用 `CyberStyle.style_button()` 统一风格化
  - 掷骰=橙色主题、其他=青色主题
  - 新增 3 条青色分隔线划分功能区域
  - Crest 资源池使用 BBCode 彩色文字（显化/步进=青、杀伐/护持=橙、术式/机巧=品红）
  - 新增版本号标记
- **CardBattlePanel** 风格统一
  - 橙色边框主题（战斗面板识别色）
  - 手牌/逃跑按钮=orange 主题、结束回合=cyan 主题
  - 新增 2 条橙色分隔线
- **SettingsPanel** 风格统一
  - 青色边框主题
  - 应用=orange、其他=cyan
- **Main.gd** 标题栏风格统一
  - 背景加深至近纯黑
  - 副标题更新为完整功能列表
  - 所有按钮统一风格化
  - 胜负标签使用统一颜色常量

### 备注

- 纯视觉升级，所有现有功能和信号完全保留
- 按钮 hover 带发光阴影效果，增强赛博朋克交互感
- CyberStyle 使用 class_name 全局注册，所有 UI 文件无需 preload

---

## v0.1.28 - 2026-03-29

### 新增

- "测试卡牌战斗"调试快捷按钮：DiceDebugPanel 新增一键进入卡牌战斗的按钮，无需走到遭遇格即可测试
- `DiceDebugPanel.test_card_battle_requested` 信号
- `DiceDebugPanel._on_test_card_battle_pressed()` 处理方法
- `Main._on_test_card_battle_requested()`：获取第一个玩家单位 HP，直接启动 CardBattleController（encounter_01 异常哨兵）

### 修改

- DiceDebugPanel 面板高度从 500 扩大至 540，各标签位置调整避免重叠
  - roll_label y: 256→294
  - crest_label y: 306→342
  - enemy_intent_label y: 450→488

### 备注

- 解决用户反馈"只能投骰子互殴、无法触发卡牌战斗"的问题
- 根因：遭遇格 (4,4)/(6,5) 距离玩家起点 (0,6)/(1,7)/(0,5) 太远，需多个回合才能走到
- 调试按钮允许任意时刻一键测试卡牌战斗流程

---

## v0.1.27 - 2026-03-29

### 新增

- 卡牌战斗丰富化（Day 10：卡牌战斗层）
- **能量系统**：每回合 3 点能量，出牌消耗 1~3 能量，不足时按钮禁用
- **双牌堆系统**：10 张牌组（draw pile + discard pile），每回合抽 3 张（上限 6），回合结束弃全部手牌，牌堆空时自动 reshuffle
- **牌组内容**：斩击x2(1E/3伤) / 重击x1(2E/5伤) / 防御x2(1E/减伤2) / 修复x1(1E/回复2) / 连斩x2(1E/2伤) / 猛攻x1(3E/8伤) / 急救x1(2E/回复4)
- **3 种敌方行为模式**：attack（普攻）/ heavy_attack（ATK×2 重击）/ defend_attack（防御+攻击，敌方获 2 减伤）
- **敌方行为循环**：异常哨兵 = attack→attack→defend_attack→heavy_attack / 赛博游魂 = attack→heavy_attack→attack
- **敌方意图预告**：每回合开始显示敌方下一步行动类型和预期伤害
- **敌方防御减伤**：defend_attack 给敌方 +2 减伤，影响玩家下次攻击（最低穿透 1）
- **胜利奖励**：胜利后随机 +1 crest 写入棋盘层 dice_manager
- **结束回合按钮**：玩家可随时结束回合
- `CardBattleController.hand_changed` / `enemy_intent_changed` / `victory_reward` 信号
- `CardBattleController.end_turn()` / `get_draw_count()` / `get_discard_count()` 方法

### 修改

- `CardBattleController.gd` 全面重写：从固定 5 张手牌升级为能量+抽牌+行为模式系统
- `CardBattlePanel.gd` 全面重写：固定按钮改为动态手牌按钮区，增加能量/牌堆/意图显示，面板扩大至 480x460
- `Main.gd` 连接 `victory_reward` 信号，胜利后将 crest 写入 dice_manager.crest_pool
- 遭遇敌方数据增加 pattern 字段和 HP 调整（异常哨兵 HP 6→8）

### 备注

- 能量不保留跨回合（原型简化）
- 敌方防御减伤只影响玩家下一次攻击牌（消费后归零）
- 防御可叠加（同回合多张防御牌效果累加）
- 牌组固定 10 张（后续可参考旧 CardData.gd 引入稀有度和升级）
- 出牌选择有了真正的策略维度：能量分配 + 手牌取舍 + 应对敌方意图

---

## v0.1.26 - 2026-03-29

### 新增

- `Scripts/BattleV2/CardBattleController.gd`（全新文件）：独立卡牌战斗状态机
  - BattleState 枚举：IDLE / PLAYER_TURN / ENEMY_TURN / VICTORY / DEFEAT
  - 5 张固定手牌（斩击/重击/防御/修复/连斩）
  - 遭遇敌方数据映射（static 方法）
  - 完整信号链：battle_started / card_played / enemy_acted / turn_resolved / battle_ended
- `BattleFlowController.get_encounter_unit_id()` 查询方法

### 修改

- `CardBattlePanel.gd` 重写为纯 UI 层：移除所有战斗状态，通过 `bind_controller()` 绑定 CardBattleController 信号
- `BattleFlowController.gd` 瘦身：移除 `card_battle_started`/`card_battle_ended` 信号、`get_encounter_enemy_data()` 方法；`_check_encounter()` 简化为只发射 `encounter_triggered`；`resolve_encounter()` 移除 `card_battle_ended` 发射
- `DiceDebugPanel.gd` 移除 `card_battle_ended` 信号连接和回调
- `Main.gd` 重构信号连接：CardBattleController 独立实例化，encounter_triggered 直接启动 controller，battle_ended 驱动 resolve_encounter

### 备注

- 本版本是 v0.1.25 的架构修正，功能不变，但代码结构符合上岗指令要求
- 卡牌战斗逻辑完全脱离 BattleFlowController，通过 Main.gd 中转信号
- 旧项目盘点结论：BattleManager.gd 不复用（过于复杂），Deck.gd 和 CardData.gd Day 10 可参考
- 需要 Codex 复审：CardBattleController 的独立挂载位置、resolve_encounter 的参数传递方式

---

## v0.1.25 - 2026-03-29

### 新增

- 最小卡牌战斗原型（Day 9：卡牌战斗层）— 双层玩法结构首次完整跑通
- `Scripts/UI/CardBattlePanel.gd`（全新文件）：独立卡牌战斗面板
  - 5 张固定手牌：斩击(3伤害) / 重击(5伤害) / 防御(减伤2) / 修复(回复2HP) / 连斩(2伤害)
  - 敌方每回合固定攻击（穿透防御最低 1 点）
  - 战斗日志实时显示每回合事件
  - 逃跑机制（-1 HP 惩罚后视为失败退出）
  - HP 低于 30% 红色警告
  - 战斗结束 1.2s 延迟后自动关闭面板
  - 赛博朋克风格 UI（暗紫底+橙色边框）
- `BattleFlowController.card_battle_started` 信号（encounter_id, enemy_name, enemy_hp, enemy_atk, unit_id, player_hp, player_max_hp）
- `BattleFlowController.card_battle_ended` 信号（encounter_id, cell, victory, player_hp_remaining）
- `BattleFlowController.get_encounter_enemy_data()`：遭遇敌方数据映射
  - encounter_01 → 异常哨兵（HP 6, ATK 2）
  - encounter_02 → 赛博游魂（HP 4, ATK 3）

### 修改

- `BattleFlowController._check_encounter()` 重写：触发遭遇后同时发射 `card_battle_started` 信号，传递遭遇敌方数据和当前单位 HP
- `BattleFlowController.resolve_encounter()` 重写：接受 `victory` 和 `player_hp_remaining` 参数
  - 胜利：卡牌战斗剩余 HP 同步回棋盘单位
  - 败北/逃跑：剩余 HP 同步（保底 1 HP，原型阶段不因卡牌战斗直接全灭）
  - 无论胜败均清除遭遇格
- `DiceDebugPanel` 遭遇面板按钮改为禁用的"卡牌战斗进行中..."；连接 `card_battle_ended` 信号；战斗结束后更新按钮显示胜败文字
- `Main.gd` 新增 `CardBattlePanel` 实例化和信号连线；新增 `_on_card_battle_started()` / `_on_card_battle_panel_ended()` / `_on_card_battle_ended()` 处理方法

### 完整双层闭环

```
棋盘走位层                          卡牌战斗层
踩遭遇格 → ENCOUNTER 暂停 ──────→ CardBattlePanel 启动
                                    ↓
                                  玩家选牌 → 效果结算
                                    ↓
                                  敌方攻击 → HP 检查
                                    ↓
                                  循环至一方 HP ≤ 0
                                    ↓
PLAYER_ACTION 恢复 ←────────────── battle_ended 信号
棋盘单位 HP 同步 ←──────────────── resolve_encounter(victory, hp)
```

### 备注

- 手牌固定不消耗（Day 10 加入费用系统和抽牌）
- 敌方行为单一（Day 10 加入多种行为模式）
- 卡牌战斗中的 HP 变化会同步回棋盘单位，使两层状态保持一致
- 这是双层玩法结构的关键里程碑：从"占位按钮"进化为"真正的卡牌战斗子流程"

---

## v0.1.24 - 2026-03-29

### 新增

- 棋盘格子事件化（Day 8：棋盘走位层）
- `BoardManager` 新增 `heal_cells` 字典（cell → heal_amount）和 `event_cells` 字典（cell → event_id）
- `BoardManager.add_heal_cell()`：添加恢复格（持久地形）
- `BoardManager.add_event_cell()` / `clear_event_cell()`：添加/清除事件格（一次性触发）
- `BattleFlowController.heal_cell_triggered` 信号（unit_id, cell, heal_amount, actual_heal）
- `BattleFlowController.event_cell_triggered` 信号（unit_id, cell, event_id, effect_text）
- `BattleFlowController._check_heal_cell()`：单位踩恢复格时回复 HP（不超 max_hp，满血不触发）
- `BattleFlowController._check_event_cell()`：单位踩事件格时随机三选一（HP+1 / 随机 crest+1 / HP-1）
- `BattleFlowController._spawn_debug_heal_cells()`：预置 2 个恢复格 (5,6) HP+2、(1,3) HP+3
- `BattleFlowController._spawn_debug_event_cells()`：预置 3 个事件格 (3,5)、(6,3)、(4,6)
- `BoardView._draw_heal_cells()`：蓝白色填充+边框+"回复"+回复量渲染
- `BoardView._draw_event_cells()`：黄紫色填充+边框+"?"标记渲染
- `BoardView.play_heal_feedback()`：蓝色飘字显示回复量
- `BoardView.play_event_feedback()`：正面黄色/负面红色飘字显示效果
- 提示栏新增 "蓝白=回复 黄紫=事件" 说明

### 修改

- `BoardManager.build_test_board()` 和 `clear_board()` 现在清空 `heal_cells` 和 `event_cells`
- `BattleFlowController.try_move_unit()` 移动后增加恢复格和事件格检查（道具拾取之后、遭遇格之前）
- `BattleFlowController._bootstrap()` 和 `restart_battle()` 调用 `_spawn_debug_heal_cells()` 和 `_spawn_debug_event_cells()`
- `DiceDebugPanel` 连接 `heal_cell_triggered` 和 `event_cell_triggered` 信号
- `Main.gd` 连接新信号，触发对应飘字反馈

### 棋盘格子种类（7 种可交互）

| 格子类型 | 颜色 | 行为 | 持久性 |
|----------|------|------|--------|
| 路径格 | 青色 | 路径适性 DEF+1 | 持久 |
| 高台格 | 金色 | 移动消耗 2，攻击范围+1/+2 | 持久 |
| 陷阱格 | 暗红 | 进入受 1 伤害（陷阱适性免疫） | 持久 |
| 道具格 | 绿色 | 拾取道具获得效果 | 一次性 |
| 遭遇格 | 橙红 | 触发遭遇暂停→战斗 | 一次性 |
| 恢复格 | 蓝白 | 踩上回复 HP | 持久 |
| 事件格 | 黄紫 | 踩上随机正/负效果 | 一次性 |

### 备注

- 恢复格为持久地形（可重复踩），满血时不触发
- 事件格为一次性触发（踩后消失），效果等概率三选一
- 事件格负面效果（HP-1）可致死，会触发胜负判定
- 走位路线开始有多条选择：安全路线（回避陷阱/事件）vs 冒险路线（高收益但有风险）
- 仅玩家单位触发恢复格和事件格，敌方不触发

## v0.1.31 - 2026-03-29

### 新增
- 持久牌组系统：牌组跨战斗保留，战斗胜利后可获得新卡牌
- 战斗胜利选牌机制：击败敌人后从 3 张随机候选中选 1 张加入牌组（或跳过）
- CardRewardPanel 奖励选牌面板：品红色边框赛博朋克风格，显示候选卡牌详情
- 5 种新卡牌类型加入奖励卡池：穿刺（无视防御 4 伤害）、吸血斩（3 伤害+回复 1）、电弧（2 伤害+敌方 ATK-1）、强化斩击（4 伤害）、双重防御（防御 3）
- BattleState.REWARD_SELECT 新状态：奖励选牌阶段
- 新信号：reward_cards_offered / reward_card_selected
- 新方法：select_reward_card() / skip_reward() / get_deck_size() / reset_persistent_deck()

### 修改
- CardBattleController._win() 不再直接发出 battle_ended，改为进入 REWARD_SELECT 阶段
- CardBattleController.start_battle() 使用持久牌组复制而非每次重建
- CardBattlePanel._on_battle_ended() 胜利时延迟缩短为 0.5s
- Main.gd 重新开始时重置持久牌组

### 备注
- 奖励卡池共 13 张（5 种新牌 + 8 种基础牌），每次随机 3 选 1
- 牌组在重新开始游戏时重置为初始 10 张
- 电弧效果虽然写为 enemy_atk -= 1，但因 start_battle 重读敌方数据，实际仅单场生效
- 第二阶段首个功能任务，核心目标是让每次遭遇有"收获感"

## v0.1.32 - 2026-03-30

### 新增
- 3 种新遭遇敌方：暗网爬虫（HP12/ATK1 坦克型 4回合循环）、脉冲猎手（HP5/ATK4 玻璃大炮 3回合循环）、数据幽灵（HP9/ATK2 长周期型 5回合循环）
- 3 个新遭遇格：(2,2) 暗网爬虫、(7,4) 脉冲猎手、(5,1) 数据幽灵
- 遭遇敌方总数从 2 种提升至 5 种，棋盘遭遇格从 2 个增至 5 个

### 备注
- 暗网爬虫频繁防御+攻击，鼓励玩家构筑穿刺/高伤牌
- 脉冲猎手首回合重击 8 伤害（ATK4×2），逼迫优先防御或速杀
- 数据幽灵 5 回合长周期含连续重击段，考验资源分配
- 新遭遇格位置已排查不与现有格子冲突

## v0.1.33 - 2026-03-30

### 新增
- 护持(DEFEND) crest 消耗入口：选中单位本回合 DEF+1（可累加，回合结束清零）
- 术式(SKILL) crest 消耗入口：选中单位即时回复 2 HP（满血不可用）
- 机巧(TRICK) crest 消耗入口：消耗 1 机巧转化为 +1 随机实用 crest（步进/杀伐/显化）
- DiceDebugPanel 新增 3 个 crest 操作按钮（护持/术式/机巧）
- 新信号：defend_crest_used / skill_crest_used / trick_crest_used
- 新方法：try_use_defend_crest() / try_use_skill_crest() / try_use_trick_crest()
- 单位临时防御字段 temp_def（参与伤害计算，回合结束清零）

### 修改
- 伤害公式升级：max(1, ATK - DEF - 地形加成 - 临时防御)
- end_player_turn() 新增 _clear_temp_def() 清除所有玩家单位临时防御
- DiceDebugPanel 面板高度从 540 调整为 574，版本号更新

### 备注
- 所有 6 种骰面现在都有实际消耗入口，消除了"废骰"问题
- 护持/术式需要先选中玩家单位，机巧不需要
- 敌方 AI 暂不使用 defend/skill/trick crest

## v0.1.34 - 2026-03-30

### 新增
- 牌组查看面板（DeckViewPanel）：棋盘阶段可查看当前持久牌组所有卡牌
- 卡牌按名称排序、同名合并计数、类型彩色区分（攻击橙/防御青/回复绿/穿透品红）
- DiceDebugPanel 新增"查看牌组"按钮和 deck_view_requested 信号
- Toggle 交互：点击打开/再点关闭，每次打开实时刷新数据

### 修改
- DiceDebugPanel "测试卡牌战斗"按钮拆分为"测试战斗"+"查看牌组"并排布局
- Main.gd 新增 DeckViewPanel 实例化、控制器绑定、信号连接

### 备注
- 纯 UI 查看功能，无逻辑变更，不影响棋盘层和卡牌层闭环
- 面板位置 (160,120)，覆盖棋盘中心区域，使用时需手动关闭
- 支持 RichTextLabel 滚动，牌组变大后可滚动浏览

## v0.1.41 - 2026-03-30

### 新增
- 商店格（Shop Cell）：持久格子，消耗 1 步进 crest 回复 3 HP，每局 1 个
- 宝箱格（Chest Cell）：一次性格子，随机奖励（HP+3 / 随机crest+2 / 全crest+1），每局 1-2 个
- BoardManager 新增 shop_cells/chest_cells 字典，add_shop_cell/add_chest_cell/clear_chest_cell 方法
- CellEffectHandler 新增 check_shop_cell()/check_chest_cell() 效果计算
- BFC 新增 shop_cell_triggered/chest_cell_triggered 信号，_check_shop_cell/_check_chest_cell 薄代理
- BoardGenerator 新增 SHOP_COUNT/CHEST_COUNT 常量和生成逻辑
- BoardView 新增商店格（青绿色）和宝箱格（金琥珀色）绘制方法和飘字反馈

### 修改
- try_move_unit 格子检查链扩展：trap→item→heal→event→shop→chest→encounter
- Main.gd 提示文字新增商店格和宝箱格颜色说明
- DiceDebugPanel 连接新信号，版本号更新为 v0.1.41

### 备注
- 商店格当前为自动触发模式（无选择面板），未来可扩展
- 宝箱格 3 种奖励等概率，数值平衡未经实战测试
- 棋盘层格子类型从 7 种增至 9 种

## v0.1.40 - 2026-03-30

### 新增
- CrestActionHandler.gd（66行）：从 BFC 剥离的 DEFEND/SKILL/TRICK crest 使用逻辑
- CellEffectHandler.gd（139行）：从 BFC 剥离的陷阱/道具/恢复/事件格效果处理
- _spawn_unit_from_data() 辅助函数：压缩玩家单位生成代码

### 修改
- BattleFlowController 从 795 行瘦身至 588 行（降幅 26%）
- Crest 使用函数替换为薄代理模式（委托 Handler + 信号发射）
- 格子效果函数替换为薄代理模式（委托 Handler + 信号发射）
- _spawn_player_units 压缩为 3 行辅助函数调用
- ItemEffectLibrary 引用从 BFC 转入 CellEffectHandler

### 备注
- 所有 BFC 信号签名和公共方法签名完全不变，消费方零修改
- 总代码量未减少（拆分前 795 行，拆分后 588+66+139=793 行），但职责分离
- _execute_enemy_actions（72行）仍在 BFC，因 async/await 耦合暂不提取

## v0.1.39 - 2026-03-30

### 新增
- BuffManager 正式接入回合流程：tick_turn() 每回合自动衰减 buff 持续时间
- BuffManager 新增 apply_buff()、get_stat_modifier()、get_buff_summary() 等完整 API
- 新信号：buff_applied(unit_id, type, value, duration) / buff_expired(unit_id, type)
- 棋盘伤害计算集成 buff 修正：ATK/DEF 受 buff 系统影响
- overclock_bone 道具拾取新增 ATK+1 buff 持续 3 回合
- DiceDebugPanel 显示 buff 获得/消失提示 + 选中单位 buff 摘要

### 修改
- _calc_damage_with_terrain() 注释和逻辑更新，增加 buff 修正计算
- overclock_bone 效果文本从 "MOVE+1" 改为 "MOVE+1 ATK+1(3回合)"
- BattleFlowController 从 786 行增长到 795 行（+9行接入代码）

### 修复
- BuffManager tick_turn() 从未被调用的历史遗留问题（技术债 BuffManager.tick_turn() 未接入已解决）

### 备注
- buff 系统仅影响棋盘层伤害计算，不影响卡牌战斗层（设计如此）
- 目前只有 overclock_bone 一个 buff 来源，后续可扩展
- BFC 795 行接近上限，下一阶段应考虑瘦身

## v0.1.38 - 2026-03-30

### 新增
- 能量成长机制：每次遭遇胜利后能量上限+1，Boss 胜利+2（初始 3，上限 5）
- 新信号：energy_grown(old_max, new_max) 通知 UI 能量提升
- 新常量：INITIAL_MAX_ENERGY(3)、MAX_ENERGY_CAP(5)
- 战斗日志显示"能量上限提升！X → Y"
- 奖励面板和牌组查看面板显示当前能量上限

### 修改
- max_energy 改为跨战斗持久状态（与 persistent_deck 同级别）
- reset_persistent_deck() 同时重置 max_energy 为初始值 3

### 备注
- 能量上限 5 时一回合可出 3E+2E 或 5 张 1E 牌
- Boss 胜利+2 可从 3 直接跳到 5，提供显著的战胜奖励感
- 逃跑/战败不触发能量成长
- 重新开始游戏时能量上限重置为 3

## v0.1.37 - 2026-03-30

### 新增
- Boss 遭遇系统：特殊高难度遭遇格，深红色视觉标识 + "BOSS" 文字
- Boss 敌方"零号协议"：HP 20 / ATK 3 / 6 阶段行为循环（攻→防攻→重击→回复→攻→超载重击）
- 两种新敌方行为：heal（回复 3 HP）、mega_attack（ATK×3 伤害）
- Boss 遭遇意图预告：heal 显示"修复（回复 HP）"，mega_attack 显示"超载重击（X 伤害）⚠"
- Boss 战胜利提供 4 张奖励牌（普通遭遇 3 张）
- Boss 战不可逃跑，逃跑按钮禁用显示"无法逃跑"
- 棋盘每局放置 1 个 Boss 遭遇格（优先右上象限，远离玩家出生区）
- CardBattlePanel 标题 Boss 战显示 [BOSS] 标记
- 新方法：CardBattleController.is_boss_encounter()
- 新常量：BoardGenerator.BOSS_ENCOUNTER_IDS

### 修改
- _draw_encounters() 重构为区分 Boss（深红/粗边框）和普通遭遇（橙红）
- _generate_reward_options() 根据 is_boss 动态调整奖励牌数量
- Main.gd 棋盘图例提示新增"深红=BOSS"

### 备注
- Boss 行为 heal 和 mega_attack 是通用敌方行为类型，未来普通敌方也可使用
- Boss 数值未经平衡测试，零号协议 6 回合累计输出约 26 点伤害（不含减免和 heal 回复）
- 扩展更多 Boss 只需在 BOSS_ENCOUNTER_IDS 和 get_encounter_enemy_data() 中添加条目

## v0.1.36 - 2026-03-30

### 新增
- 卡牌升级机制：基础牌可升级为强化版本（名称+"+"后缀，数值提升 30%~50%，费用不变）
- 14 种牌的完整升级数据映射（斩击→斩击+、重击→重击+、防御→防御+ 等）
- 奖励面板双模式：胜利后可选"获取新牌"或"升级已有牌"（二选一）
- 升级模式显示所有未升级牌，同名合并，展示升级前后数值对比
- 手牌中升级牌使用青色按钮样式（区分于普通牌橙色）
- 牌组查看面板升级牌名称青色高亮
- 新信号：card_upgrade_completed(old_card, new_card)
- 新方法：get_card_upgrade() / get_upgradeable_indices() / upgrade_deck_card()

### 修改
- 所有卡牌字典新增 upgraded: bool 字段
- 吸血斩新增 heal_value 字段，升级后回复量从 1 提升为 2
- CardRewardPanel 重写为双模式面板（奖励/升级），面板高度 320→340

### 备注
- 每张卡牌只能升级一次（与 STS 一致）
- 每次胜利只能选"加新牌"或"升级一张"之一
- 升级在 REWARD_SELECT 状态执行，不影响棋盘层和战斗流程
- 重新开始游戏时牌组重置，所有升级状态清零

## v0.1.35 - 2026-03-30

### 新增
- 棋盘随机生成系统（BoardGenerator.gd）：每局/每次重开布局随机化
- 高台 2~3 个、陷阱 2~3 个、道具 2 个、遭遇 3~4 个、恢复 2 个、事件 2~3 个随机放置
- 敌方单位 2 个随机生成在棋盘上半区域
- 玩家出生区保护（左下 col0~1 row5~7 不放危险格子）
- 防重叠机制：used_cells 追踪 + Fisher-Yates 洗牌选取

### 修改
- BattleFlowController 删除 5 个 _spawn_debug_* 方法，改用 BoardGenerator.generate_board()
- _spawn_debug_units 改名为 _spawn_player_units（仅保留玩家单位）
- _bootstrap() 和 restart_battle() 统一调用 BoardGenerator

### 备注
- 每局遭遇格从 5 种中随机选 3~4 种，位置每局不同
- 重新开始后自动生成新布局，重玩性大幅提升
- BFC 行数维持 785 行（删除 50 行 debug spawn，新增少量调用）
- 棋盘层和卡牌层完整闭环不受影响

## v0.1.42 - 2026-03-30

### 新增
- 多层地图系统：3层棋盘推进，击杀所有棋盘敌方单位通关当前层
- FLOOR_CLEAR 阶段：层通关后暂停棋盘，等待层间奖励完成
- floor_cleared/game_won 信号：区分层通关和最终通关
- advance_to_next_floor()：保留存活单位 HP，重新生成棋盘，进入下一层
- _snapshot_player_hp()：存活玩家单位 HP 快照（跨层保留）
- _spawn_player_units_with_hp()：带 HP 快照生成玩家单位（阵亡单位不复活）
- CardBattleController.offer_floor_reward()：层间奖励直接进入选牌/升级阶段
- DiceDebugPanel 新增"层数：X/3"标签（品红色）
- MAX_FLOOR 常量（默认 3），current_floor 变量

### 修改
- _check_battle_outcome() 区分层通关（FLOOR_CLEAR）和最终胜利（VICTORY）
- is_battle_over() 包含 FLOOR_CLEAR 阶段，阻止层通关期间操作
- restart_battle() 重置 current_floor = 1
- Main._on_phase_changed() 处理 FLOOR_CLEAR（"第 X 层通关！"）和最终 VICTORY（"通关胜利！"）
- Main._on_card_battle_ended() 通过 _floor_clear_pending 区分层间奖励和遭遇战斗结算
- DiceDebugPanel 版本号更新为 v0.1.42

### 备注
- 层间保留：牌组/能量上限/卡牌升级；层间重置：棋盘/crest/buff/回合
- 难度暂不递增（各层敌方数值相同），后续可根据 floor 调整
- 阵亡单位不复活，可能导致后续层困难，需平衡测试
- BFC 从 605 行增长至约 693 行（+88行）

## v0.1.43 - 2026-03-30

### 修复
- BUG-001：分辨率切换无效 — apply_settings() 在 _ready() 中同步调用，窗口系统尚未初始化，改为 call_deferred 延迟一帧
- BUG-001：全屏/无边框窗口切换无效 — 从全屏切回窗口/无边框时 DisplayServer 忽略后续操作，修复为先强制回退 WINDOW_MODE_WINDOWED 再设置目标模式
- BUG-001：无边框窗口切换无效 — 旧代码先设 WINDOW_MODE_WINDOWED 再设 BORDERLESS 标志，但 borderless 标志可能被模式切换覆盖；修复为先清除 borderless 标志，再按目标模式正确设置

### 修改
- DiceDebugPanel 版本号更新为 v0.1.43

### 备注
- DisplaySettings.gd 核心修复：call_deferred 延迟初始化 + 先回退窗口模式再应用目标模式
- 修复覆盖三种场景：分辨率切换、全屏↔窗口切换、无边框窗口切换
- 棋盘层和卡牌层完整闭环不受影响

## v0.1.44 - 2026-03-30

### 修复
- BUG-001 补充修复：分辨率切换后画面不自适应 — content_scale_size 被设为目标分辨率（如1920x1080），导致虚拟画布变大但 UI 仍按 1280x720 布局，右下方出现大片空白；修复为始终保持 content_scale_size = 设计分辨率（1280x720），由 canvas_items 拉伸模式自动缩放内容至实际窗口大小

### 修改
- DiceDebugPanel 版本号更新为 v0.1.44

### 备注
- 根因：canvas_items 拉伸模式的正确用法是 content_scale_size 固定为设计分辨率，窗口大小随用户选择变化，引擎自动处理缩放
- 窗口模式切换（v0.1.43 修复）不受影响

## v0.1.44-docs - 2026-03-30

### 新增
- 美术美化推进策略文档（Art_Beautification_Strategy_zh.md）：6 阶段分步美化计划
  - Phase 1：棋盘格+单位视觉升级（BoardCellRenderer + UnitRenderer）
  - Phase 2：掷骰演出+攻击演出增强（DiceRollAnimation + BattleEffects）
  - Phase 3：卡牌战斗面板重设计（CardRenderer）
  - Phase 4：背景氛围+UI过渡动画+召唤演出
  - Phase 5：音效系统（AudioManager）
  - Phase 6：2.5D 棋盘（长期目标）

### 修改
- 任务优先级调整：层间难度递增排后，美术美化 Phase 1 提前为当前最高优先

### 备注
- 本条目为纯文档变更，无代码修改
- 全部 UI/渲染代码已完成审计，策略文档基于实际代码状态制定

## v0.1.45 - 2026-03-30

### 新增
- 美化 Phase 1 完整实现：棋盘格+单位+高亮视觉升级
- BoardCellRenderer.gd（~210行）：格子渲染静态类
  - 基础格深色渐变底色 + 发光网格线
  - 9种格子类型独特图标符号 + 霓虹发光效果（高台▲/陷阱✖/遭遇⚡/Boss/回复✚/事件?/商店◆/宝箱六边形/道具菱形）
  - 移动高亮升级为四角L形线条，攻击高亮升级为十字准星+脉冲，召唤高亮升级为圆弧标记
- UnitRenderer.gd（~159行）：单位渲染静态类
  - 玩家单位独特形状（刀盾犬→盾形、黑客狐→菱形、鸦术士→倒三角）+ 发光轮廓
  - 敌方单位暗红发光 + 四角尖角装饰（锯齿威胁感）
  - HP条：底色+填充双层，绿→金→红渐变
  - 选中脉冲金色边框 + idle微动画
  - 地形适性金色星标
- CyberStyle.gd 新增 10 个棋盘美化颜色常量（BOARD_CELL_DARK/LIGHT、BOARD_GRID_LINE/INNER_GLOW、NEON_GOLD/RED/TEAL/PURPLE/BLUE/GREEN）

### 修改
- BoardView.gd 完全重写：648行→423行（降幅35%）
  - 15+个旧 _draw_* 方法替换为 5层分层绘制（Grid→Overlays→Highlights→Units→AttackFlash）
  - 全部渲染委托给 BoardCellRenderer/UnitRenderer 静态方法
  - 新增 Timer 驱动 20fps 动画刷新（50ms 间隔 queue_redraw）
  - 所有点击交互逻辑和反馈动画完整保留，零修改
- DiceDebugPanel 版本号更新为 v0.1.45

### 备注
- 100% 程序化绘制，零外部图片资源依赖
- 100% CyberStyle 颜色常量，无硬编码颜色
- gl_compatibility 安全：全部使用 draw_rect/draw_line/draw_arc/draw_colored_polygon/draw_string
- BoardView 所有公共信号和方法签名不变，消费方（Main.gd/DiceDebugPanel）零修改
- Phase 1 完成标准：棋盘截图看起来像"游戏"而非"调试工具"；单位可区分类型；格子类型一目了然

## v0.1.46 - 2026-03-30

### 新增
- 美化 Phase 2 完整实现：掷骰演出 + 攻击演出增强
- DiceRollAnimation.gd（~158行）：掷骰演出动画控件
  - 3枚骰子翻滚（55ms随机切换crest符号）→ 逐个定格（scale弹跳+霓虹发光）
  - 6种crest独特符号程序化绘制（★箭头✖盾◎⬡）+ 6种独特颜色
  - 总演出时长约 1.1s，动画期间不阻塞操作
- BattleEffects.gd（~103行）：战斗特效静态类
  - 屏幕微震：6步衰减随机偏移，meta存储静止位置防漂移
  - 命中粒子：CPUParticles2D 一次性爆发（普通6粒/击杀12粒）+ 自动释放
  - 增强伤害飘字：scale弹跳（1.0→1.4→1.0）+ 上浮渐隐
  - 击杀文字：金色 "KILL!" 弹出

### 修改
- BoardView.play_attack_feedback() 增强：集成 BattleEffects（微震+粒子+弹跳飘字），新增 is_kill 参数（默认 false 向后兼容）
- BoardView 移除旧 _damage_label 实例变量，被 BattleEffects.enhanced_damage_popup 替代
- DiceDebugPanel 集成 DiceRollAnimation：掷骰后播放动画，crest池立即更新
- Main.gd 新增 _last_attack_killed 变量，传递击杀状态到 play_attack_feedback
- DiceDebugPanel 版本号更新为 v0.1.46

### 备注
- 掷骰动画不阻塞操作：crest池在动画开始时即更新，玩家可立即行动
- CPUParticles2D（gl_compatibility 兼容），one_shot + 自动释放，无节点泄漏
- 击杀时效果全面增强：闪光更亮、震动更强、粒子更多、金色飘字 + KILL!文字
- BattleFlowController / DiceManager 零修改
- Phase 2 完成标准：掷骰有期待感（>1秒演出）；攻击命中有冲击感（屏幕微震+粒子）

