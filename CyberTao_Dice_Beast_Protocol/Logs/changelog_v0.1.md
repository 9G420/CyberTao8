# CyberTao: Dice Beast Protocol Changelog

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
