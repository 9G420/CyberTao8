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
