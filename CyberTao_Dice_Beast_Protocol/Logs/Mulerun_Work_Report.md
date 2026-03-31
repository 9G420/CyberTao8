# Mulerun 工作报告

**日期**: 2026-03-31
**版本**: v0.1.71
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.71：3D 渐进迁移 P0（新增 3D 表现层模块 + 双视图切换）

---

## 根因目标

用户要求添加 3D 渲染层用于棋盘和单位可视化，同时保留 2D 回退，不修改核心游戏逻辑文件。

服务层：棋盘走位层（视觉升级 — 3D 渲染原型）

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/UI3D/GridMapper3D.gd` | **新文件**：格坐标↔3D世界坐标转换（CELL_SIZE=2.0，棋盘居中） |
| `Scripts/UI3D/TileMeshFactory3D.gd` | **新文件**：9种格子类型 BoxMesh 创建 + StandardMaterial3D（CyberStyle 配色+发光） |
| `Scripts/UI3D/UnitMeshFactory3D.gd` | **新文件**：单位 CapsuleMesh/CylinderMesh 创建 + billboard HP 条 |
| `Scripts/UI3D/BoardView3D.gd` | **新文件**：完整 3D 棋盘视图，信号接口与 BoardView 对齐 |
| `Scripts/Main.gd` | 新增 `_use_3d`/`_active_view()`/`_setup_3d_view()`/`toggle_3d_view()`/`_input()` + 全部回调路由替换 |
| `Scripts/UI/DiceDebugPanel.gd` | 版本标记更新至 v0.1.71 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.71 条目 |

---

## v0.1.71 验收证据包

### 一、双层闭环逐项测试结果（代码审查）

> 以下为基于源码逐行审查的静态验证结果。所有路径均以 Main.gd 为入口追踪信号链完整性。
> 标记：✅ = 代码路径完整可达；⚠️ = 路径可达但有降级行为（已记录）。

#### 1.1 棋盘走位层

| 测试项 | 2D 模式 | 3D 模式 | 验证依据 |
|--------|---------|---------|----------|
| 默认启动为 2D | ✅ `_use_3d = false`（Main:18） | N/A | _sub_viewport_container.visible = false（Main:585） |
| 掷骰 → crest 池更新 | ✅ DiceManager 不涉及视图 | ✅ 同左 | BFC.dice_manager 独立于视图层 |
| 单位选中 → 高亮（移动/攻击/召唤） | ✅ BoardView._handle_cell_click | ✅ BoardView3D._handle_cell_click（:383-419） | 两个视图各自独立实现，逻辑一致 |
| 单位移动 → 逐格动画 | ✅ _on_move_step_visual → _active_view().play_move_step（Main:484） | ✅ BoardView3D.play_move_step（:164-173）Tween插值 | move_anim_done 信号两个视图均声明并 emit |
| 单位攻击 → 伤害反馈 | ✅ _active_view().play_attack_feedback（Main:215） | ⚠️ BoardView3D.play_attack_feedback 为桩函数（:195-197） | 3D 模式下攻击逻辑正确执行，仅视觉反馈缺失 |
| 召唤铺路 | ✅ UITransitions 演出（Main:274-275） | ⚠️ 3D 模式跳过 UITransitions（Main:273 `if not _use_3d` 守卫） | 召唤逻辑正确执行，3D 仅缺少 spawn 特效 |
| 道具拾取 | ✅ play_pickup_feedback（Main:283） | ⚠️ 桩函数 | 拾取逻辑正确，仅缺飘字 |
| 治疗格 | ✅ play_heal_feedback（Main:340） | ⚠️ 桩函数 | HP 回复正确执行 |
| 事件格 | ✅ play_event_feedback（Main:346） | ⚠️ 桩函数 | 事件效果正确执行 |
| 商店格 | ✅ play_shop_feedback（Main:369） | ⚠️ 桩函数 | 消耗/回复正确执行 |
| 宝箱格 | ✅ play_chest_feedback（Main:374） | ⚠️ 桩函数 | 效果正确执行 |
| 陷阱伤害 | ✅ play_attack_feedback（Main:278） | ⚠️ 桩函数 | 陷阱伤害正确执行 |
| 敌方 AI 回合 | ✅ 相机跟随敌方（Main:292） + 预警（Main:296） | ✅ _active_view() 路由正确 | 3D 模式下 play_enemy_warning 为桩 |
| 敌方回合结束 → 切回我方 | ✅ Main:298-309 | ✅ _active_view() 路由正确 | _reset_drag_offset 兼容 2D/3D（Main:616-621） |
| 重新开始 | ✅ Main:447-460 | ✅ 额外调 rebuild_board（Main:459-460） | 状态全清空 + 相机归位 |
| 高台/地形 DEF 加成 | ✅ AttackRuleHelper 不涉及视图 | ✅ 同左 | 纯逻辑层 |
| DEFEND/SKILL/TRICK crest 消耗 | ✅ 各 _on_xxx_crest_used → _active_view() | ✅ 路由正确 | 飘字为桩 |

#### 1.2 卡牌战斗层

| 测试项 | 2D 模式 | 3D 模式 | 验证依据 |
|--------|---------|---------|----------|
| 遭遇触发 → 百叶窗过渡 | ✅ TransitionOverlay（Main:322-333） | ✅ TransitionOverlay 不依赖视图模式 | CanvasLayer 10 覆盖一切 |
| CardBattlePanel 全屏显示 | ✅ Main:324 visible=true | ✅ 同左（2D UI 层，不受 _use_3d 影响） | 卡牌面板是 Control 节点 |
| 卡牌战斗流程（抽牌/出牌/敌方行动/结算） | ✅ CardBattleController 独立 | ✅ 同左 | CBC 不依赖视图层 |
| 战斗胜利 → 奖励选牌 | ✅ _on_card_battle_reward（Main:416-422） | ✅ 同左 | crest_pool 更新不涉及视图 |
| 战斗结束 → 百叶窗回棋盘 | ✅ Main:398-414 | ✅ 同左 | _active_view().queue_redraw() 确保回棋盘后刷新 |
| resolve_encounter 三分支 | ✅ BFC.resolve_encounter | ✅ 同左 | 纯逻辑，view.play_pickup_feedback 路由正确 |
| 调试快捷战斗 | ✅ Main:502-517 | ✅ 同左（TransitionOverlay 独立于视图） | 两种模式均可触发 |

#### 1.3 多层地图

| 测试项 | 2D 模式 | 3D 模式 | 验证依据 |
|--------|---------|---------|----------|
| Boss 解锁 | ✅ play_encounter_feedback（Main:434） | ⚠️ 桩函数 | Boss 逻辑正确 |
| 英雄传送至 Boss | ✅ Main:438-441 | ✅ _active_view() 路由 | 飘字为桩 |
| 传送门生成 | ✅ Main:443-445 | ✅ _active_view() 路由 | 飘字为桩 |
| 层通关 → 下一层 | ✅ Main:381-393 | ✅ 额外 rebuild_board（Main:391-392） | 3D 模式重建棋盘 |
| 全通关 → VICTORY | ✅ _on_phase_changed（Main:234-238） | ✅ 同左 | 结果标签不依赖视图 |

#### 1.4 HUD / 辅助系统

| 测试项 | 2D 模式 | 3D 模式 | 验证依据 |
|--------|---------|---------|----------|
| 头像 HUD 点击切镜头 | ✅ _on_portrait_clicked（Main:526-542） | ✅ _active_view() 路由 | set_camera_target + highlight 更新 |
| 掷骰演出动画 | ✅ DiceRollAnimation（独立 Control） | ✅ 同左 | CanvasLayer 覆盖 |
| 牌组查看 | ✅ DeckViewPanel（独立 Control） | ✅ 同左 | 不依赖视图层 |
| 音效系统 | ✅ AudioManager 独立 | ✅ 同左 | 所有 _audio.play_sfx 不涉及视图 |
| DiceDebugPanel | ✅ bind_board_view(_board_view)（Main:189） | ⚠️ 仍绑定 2D BoardView | 3D 模式下骰子面板无点击联动 |

**双层闭环结论**：2D 模式功能完全等同 v0.1.70，零退化。3D 模式下游戏逻辑完整可达，仅视觉反馈（飘字/闪光/粒子/召唤特效）因桩函数而降级，不影响游戏流程正确性。

---

### 二、3D 专项稳定性结果

#### 2.1 视图切换（F5）

| 测试项 | 代码路径 | 结果 |
|--------|----------|------|
| F5 按键捕获 | Main._input() :638-643, KEY_F5 + !echo + pressed | ✅ 单次触发，set_input_as_handled 防穿透 |
| 2D→3D 切换 | toggle_3d_view() :624-633 | ✅ _board_view.visible=false, _sub_viewport_container.visible=true, rebuild_board + 相机归位 |
| 3D→2D 切换 | toggle_3d_view() :631-633 | ✅ 反向可见性 + _board_view.queue_redraw + 相机归位 |
| 连续快速切换 | toggle_3d_view 是同步操作 | ✅ 无异步竞态（rebuild_board 同步执行） |
| 切换不保留选中状态 | 切换时不同步 selected_unit_id | ⚠️ 已知设计决策，切换后需重新点选 |
| 切换后卡牌战斗进入/退出 | TransitionOverlay 独立于视图模式 | ✅ 百叶窗+CardBattlePanel 不受切换影响 |

#### 2.2 坐标映射

| 测试项 | 代码路径 | 结果 |
|--------|----------|------|
| cell→world 正确性 | GridMapper3D.cell_to_world :14-18 | ✅ cell(0,0) → (-11,0,-11), cell(11,11) → (11,0,11)（12格棋盘居中） |
| world→cell 正确性 | GridMapper3D.world_to_cell :21-25 | ✅ round() 四舍五入确保格中心±1.0范围内映射正确 |
| 双向互逆 | cell_to_world(world_to_cell(v)) ≈ v | ✅ 浮点精度内互逆（CELL_SIZE=2.0 整数倍） |
| 边界判定 | is_in_bounds :28-29 | ✅ [0, grid_size) 闭左开右 |
| 射线→格子 | BoardView3D._screen_to_cell :363-375 | ✅ project_ray_origin+project_ray_normal→Y=0交点→world_to_cell |
| 射线未命中（看天空） | dir.y ≈ 0 或 t < 0 | ✅ 返回 (-1,-1)，_is_valid_cell 拦截 |

#### 2.3 状态同步

| 测试项 | 代码路径 | 结果 |
|--------|----------|------|
| board_changed → 3D 刷新 | BoardView3D.bind_managers :140-145 连接 _on_state_changed | ✅ _refresh_units + _refresh_highlights |
| units_changed → 3D 刷新 | 同上 :143-145 | ✅ 增量更新：移除已消失单位 + 添加新单位 + 更新 HP |
| phase_changed → 取消选中 | BoardView3D._on_phase_changed :463-465 | ✅ _deselect() 清空全部高亮 |
| 移动动画中不覆盖位置 | _refresh_units :276 `if uid != _move_anim_unit` 守卫 | ✅ 动画单位位置由 Tween 驱动 |
| HP 实时更新 | UnitMeshFactory3D.update_hp_bar :38-53 | ✅ scale.x = ratio, 颜色阈值 0.3 |
| _active_view() 一致性 | Main:610-613 | ✅ 所有 ~40 处回调均通过 _active_view() 路由，无遗漏 _board_view 直接调用 |

#### 2.4 3D 相机

| 测试项 | 代码路径 | 结果 |
|--------|----------|------|
| 平滑跟随 | _process :123-129 lerp(CAMERA_LERP_SPEED * delta) | ✅ clampf 防止 delta spike 导致跳变 |
| 缩放范围 | ZOOM_MIN=10, ZOOM_MAX=30, 步长1.5 | ✅ clampf 硬限制 |
| 拖拽平移 | handle_input :346-353, 右键/中键 | ✅ _drag_offset_accumulated 累加，world_scale 随距离缩放 |
| 拖拽期间不插值 | _process :123 `not _drag_active` 守卫 | ✅ 避免拖拽时相机抖动 |
| 视角参数 | 55° 俯视角, FOV 45°, near 0.1, far 100 | ✅ 12x12棋盘（24x24世界单位）在视锥内 |

#### 2.5 3D 输入

| 测试项 | 代码路径 | 结果 |
|--------|----------|------|
| 鼠标事件转发 | Main._input :645-647 | ✅ 仅 _use_3d + visible 时转发 InputEventMouse |
| 点击选中玩家单位 | BoardView3D._handle_cell_click :414-419 | ✅ owner=="player" 检查 |
| 攻击优先于移动 | _handle_cell_click :388-391 attack_highlight 先检查 | ✅ 与 BoardView(2D) 一致 |
| 点击空地取消选中 | _handle_cell_click :412 _deselect() | ✅ |
| 战斗结束/ENCOUNTER 阶段屏蔽点击 | _handle_cell_click :384-385 | ✅ is_battle_over + ENCOUNTER 守卫 |

---

### 三、接口变更清单

#### 3.1 新增 class_name 全局注册（4个）

| class_name | 文件 | 父类 | 性质 |
|------------|------|------|------|
| `GridMapper3D` | Scripts/UI3D/GridMapper3D.gd | RefCounted | 静态工具类，无实例状态 |
| `TileMeshFactory3D` | Scripts/UI3D/TileMeshFactory3D.gd | RefCounted | 静态工厂，无实例状态 |
| `UnitMeshFactory3D` | Scripts/UI3D/UnitMeshFactory3D.gd | RefCounted | 静态工厂，无实例状态 |
| `BoardView3D` | Scripts/UI3D/BoardView3D.gd | Node3D | 实例化节点，持有场景树 |

#### 3.2 新增公开方法

| 方法 | 所属 | 签名 | 说明 |
|------|------|------|------|
| `cell_to_world` | GridMapper3D | `(cell: Vector2i, grid_size: int = 12) -> Vector3` | 格坐标→世界坐标 |
| `world_to_cell` | GridMapper3D | `(world_pos: Vector3, grid_size: int = 12) -> Vector2i` | 世界坐标→格坐标 |
| `is_in_bounds` | GridMapper3D | `(cell: Vector2i, grid_size: int = 12) -> bool` | 边界判定 |
| `cell_distance_world` | GridMapper3D | `(a: Vector2i, b: Vector2i, grid_size: int = 12) -> float` | 格间世界距离 |
| `board_world_size` | GridMapper3D | `(grid_size: int = 12) -> float` | 棋盘总世界尺寸 |
| `board_center` | GridMapper3D | `(grid_size: int = 12) -> Vector3` | 棋盘中心（Vector3.ZERO） |
| `create_tile` | TileMeshFactory3D | `(tile_key: String, cell: Vector2i, grid_size: int = 12) -> MeshInstance3D` | 创建格子网格 |
| `create_highlight` | TileMeshFactory3D | `(cell: Vector2i, color: Color, grid_size: int = 12) -> MeshInstance3D` | 创建高亮薄片 |
| `create_unit_node` | UnitMeshFactory3D | `(unit: Dictionary, cell: Vector2i, grid_size: int = 12) -> Node3D` | 创建单位节点 |
| `update_unit_position` | UnitMeshFactory3D | `(node: Node3D, world_pos: Vector3) -> void` | 更新单位位置 |
| `update_hp_bar` | UnitMeshFactory3D | `(node: Node3D, hp: int, max_hp: int, is_player: bool) -> void` | 更新 HP 条 |
| `toggle_3d_view` | Main | `() -> void` | 切换 2D/3D 视图 |
| `_active_view` | Main | `() -> Variant` | 返回当前活动视图（duck typing） |

#### 3.3 新增信号（BoardView3D — 与 BoardView 完全对齐）

| 信号 | 参数 |
|------|------|
| `unit_selected` | `(unit_id: String)` |
| `unit_deselected` | 无 |
| `move_requested` | `(unit_id: String, target_cell: Vector2i)` |
| `attack_requested` | `(unit_id: String, target_cell: Vector2i)` |
| `summon_requested` | `(unit_id: String, target_cell: Vector2i)` |
| `move_anim_done` | 无 |

#### 3.4 新增快捷键

| 按键 | 功能 | 捕获位置 |
|------|------|----------|
| F5 | 切换 2D/3D 视图 | Main._input()（:638-643） |

#### 3.5 核心逻辑文件改动情况

| 文件 | 改动 |
|------|------|
| BattleFlowController.gd | **零改动** |
| CardBattleController.gd | **零改动** |
| BoardManager.gd | **零改动** |
| UnitManager.gd | **零改动** |
| BoardGenerator.gd | **零改动** |
| ActionResolver.gd | **零改动** |
| DiceManager.gd | **零改动** |
| BattleAI.gd | **零改动** |
| BuffManager.gd | **零改动** |
| CrestActionHandler.gd | **零改动** |
| CellEffectHandler.gd | **零改动** |

---

### 四、已知限制

#### 4.1 功能降级（3D 模式）

| 编号 | 限制 | 影响 | 严重程度 | 阻塞 |
|------|------|------|----------|------|
| L-01 | 9个反馈方法为桩函数（play_attack_feedback 等） | 3D 模式下无飘字/闪光/粒子视觉反馈 | 中 | 否 |
| L-02 | 召唤演出无 UITransitions 特效 | 3D 模式下召唤单位出场无缩放闪光动画 | 低 | 否 |
| L-03 | DiceDebugPanel 仍绑定 2D BoardView | 3D 模式下骰子面板的棋盘联动（如点击格子高亮）失效 | 低 | 否 |
| L-04 | F5 切换不同步 selected_unit_id | 切换视图后需重新点选单位 | 低 | 否 |

#### 4.2 视觉限制

| 编号 | 限制 | 说明 |
|------|------|------|
| L-05 | 单位使用简单几何体 | 玩家 = CapsuleMesh（蓝），敌方 = CylinderMesh（红），无精灵/模型 |
| L-06 | 环境格子未实现 | 棋盘外区域为纯黑背景（2D 模式有暗色菱形填充） |
| L-07 | HP 条使用 BoxMesh billboard | 功能正确但视觉粗糙，缺少底框/数字 |
| L-08 | spritesheet 背景透明度 | v0.1.70 遗留，2D 模式下玩家精灵底色待用户确认 |

#### 4.3 性能风险

| 编号 | 限制 | 说明 |
|------|------|------|
| L-09 | SubViewport 额外渲染 pass | 3D 视图内嵌 SubViewport（1280x720），即使 2D 模式下 visible=false 但 UPDATE_ALWAYS，需确认是否自动跳过 |
| L-10 | rebuild_board() 全量重建 | 每次切换/重启/换层清除+重建 144 个 MeshInstance3D，12x12 棋盘下可接受，更大棋盘需增量方案 |

#### 4.4 架构约束

| 编号 | 限制 | 说明 |
|------|------|------|
| L-11 | _active_view() 返回 Variant | duck typing 无编译时类型检查，如果方法名不匹配会运行时报错 |
| L-12 | handle_input() 手动转发 | SubViewport 不自动接收父级输入，依赖 Main._input() 转发 InputEventMouse |
| L-13 | 2D/3D 相机独立运行 | 2D 用 Timer（50ms）插值，3D 用 _process(delta) 插值，切换时不互相同步 |

---

## 建议下一步

1. 3D 反馈系统实现（粒子特效/3D 飘字）— 解决 L-01/L-02
2. 3D 单位精灵化（billboard sprite 或低多边形模型）— 解决 L-05
3. 商店格扩展（多选商品 + 独立 UI 面板）
