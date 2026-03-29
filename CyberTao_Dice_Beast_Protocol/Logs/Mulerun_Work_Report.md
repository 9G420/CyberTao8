# Mulerun Work Report

**Date**: 2026-03-29
**Version**: v0.1.1 → v0.1.2
**Branch**: `codex/dice-beast-protocol`

---

## Task

Two tasks were completed in this session:

1. **v0.1.1** — Implement unit selection + movable cell highlighting + MOVE crest movement on the board prototype
2. **v0.1.2** — Fix two bugs: dice roll should be limited to once per turn; movable cell highlights must sync with MOVE resource availability

---

## Files Changed

### v0.1.1 (8 files)

| File | Change |
|------|--------|
| `Project/Scripts/UI/BoardView.gd` | Rewrote: enabled click input, added selection state, highlight drawing, move request signal |
| `Project/Scripts/BattleV2/BoardManager.gd` | Added `get_reachable_cells()` BFS algorithm |
| `Project/Scripts/BattleV2/UnitManager.gd` | Added `board_manager` sync, `move_range` storage, `unit_moved` signal, `get_player_units()` |
| `Project/Scripts/BattleV2/BattleFlowController.gd` | Added `try_move_unit()`, `get_reachable_cells_for()`, `move_completed` signal, `move_range` in spawn payload |
| `Project/Scripts/UI/DiceDebugPanel.gd` | Added "Selected: ..." label, `bind_board_view()`, move-completed crest refresh |
| `Project/Scripts/Main.gd` | Wired BoardView signals to BattleFlowController, bound board view to debug panel |
| `Logs/changelog_v0.1.md` | Added v0.1.1 entry |
| `Logs/CyberTao_Migration_Snapshot.md` | Updated version, current state, priority checklist |

### v0.1.2 (4 files)

| File | Change |
|------|--------|
| `Project/Scripts/BattleV2/BattleFlowController.gd` | `start_player_roll()` phase guard + auto-transition; `get_reachable_cells_for()` MOVE<=0 check |
| `Project/Scripts/UI/DiceDebugPanel.gd` | `roll_button` promoted to member var; disabled when phase != PLAYER_ROLL |
| `Project/Scripts/Main.gd` | `_on_move_requested()` always refreshes highlights after move attempt |
| `Logs/changelog_v0.1.md` | Added v0.1.2 entry |

---

## What Was Implemented

### v0.1.1: Unit Selection + Movement

- Click a player unit on the board to select it (gold ring indicator)
- BFS-based reachable cell calculation respecting `move_range` and occupied cells
- Cyan highlight overlay on all valid move targets
- Click a highlighted cell to move the unit, consuming 1 MOVE crest
- Debug panel shows currently selected unit name
- `BoardManager.occupied_cells` kept in sync by `UnitManager` on spawn/move/despawn
- `move_range` field stored in unit state and loaded from `UnitData` on spawn

### v0.1.2: Roll-Once + Highlight Sync

- Dice roll limited to once per turn
- Roll Dice button visually disabled after rolling
- Movable cell highlights disappear when MOVE crest reaches 0
- Highlights refresh after every move attempt regardless of success

---

## Key Logic

### How roll-once is enforced

1. `BattleFlowController.start_player_roll()` checks `current_phase != PLAYER_ROLL` and returns early if not in roll phase
2. After rolling, `current_phase` is immediately set to `PLAYER_ACTION` — subsequent button presses fail the guard
3. UI side: `DiceDebugPanel._on_phase_changed()` sets `roll_button.disabled = true` when phase string != "PLAYER_ROLL"

### How highlights sync with MOVE resource

1. `BattleFlowController.get_reachable_cells_for()` checks `dice_manager.crest_pool["move"] <= 0` before computing BFS — returns empty array if no MOVE available
2. All highlight computation paths go through this function: unit selection, post-move refresh, state change callbacks
3. `Main._on_move_requested()` unconditionally refreshes highlights after every move attempt, so MOVE exhaustion clears highlights immediately

### How BFS reachable cells work

1. `BoardManager.get_reachable_cells(origin, move_range)` runs BFS from origin
2. Each neighbor is checked: must be in bounds, not in `occupied_cells`, not already visited
3. Distance tracked per cell; expansion stops at `move_range` depth
4. Only orthogonal directions (up/down/left/right)

---

## Remaining Limits

- **No End Turn button** — after rolling and spending resources, there is no way to advance to the next turn and roll again
- **Dice crest pool accumulates** — `DiceManager.roll_turn_dice()` adds to existing pool; a turn-reset mechanism is needed to clear pool at turn start
- **No attack system** — selecting a unit near an enemy does nothing
- **No movement animation** — unit position updates are instant (no tween)
- **No enemy AI** — enemy grunt sits idle; no enemy turn logic
- **Not validated in-editor** — code is structurally correct but has not been run in Godot yet
- **Single player unit only** — only `blade_shield_dog` exists as a prototype unit

---

## Next Suggestion

1. **End Turn button + turn cycle** — Add "End Turn" to debug panel, reset phase to PLAYER_ROLL, clear crest pool, increment round. This completes the basic turn loop.
2. **Attack system** — When a selected unit is adjacent to an enemy, show red attack highlights. Click to attack consuming 1 ATTACK crest. Use existing `ActionResolver.try_attack()`.
3. **Enemy AI turn** — After player ends turn, enemy rolls dice and takes a simple move+attack action using `BattleAI`.
4. **Victory/defeat check** — When enemy HP reaches 0, call `mark_victory()`. When player unit HP reaches 0, call `mark_defeat()`.

These four steps would close the minimum combat loop.
