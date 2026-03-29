# Mulerun Work Report

**Date**: 2026-03-29
**Version**: v0.1.3
**Branch**: `codex/dice-beast-protocol`

---

## Task

Implement the minimum turn cycle: Roll Dice → spend MOVE to move unit → End Turn → next round with fresh dice roll.

---

## Files Changed

| File | Change |
|------|--------|
| `Project/Scripts/BattleV2/BattleFlowController.gd` | Added `end_player_turn()`, `round_changed` signal |
| `Project/Scripts/BattleV2/DiceManager.gd` | Added `reset_for_turn()` to clear crest pool at turn boundary |
| `Project/Scripts/UI/DiceDebugPanel.gd` | Added End Turn button, round label, button enable/disable logic |
| `Project/Scripts/UI/BoardView.gd` | Added phase_changed listener to deselect on turn end |
| `Logs/changelog_v0.1.md` | Added v0.1.3 entry |
| `Logs/CyberTao_Migration_Snapshot.md` | Updated to v0.1.3, marked end turn as done |
| `Logs/Mulerun_Work_Report.md` | Overwritten with this report |

---

## What Was Implemented

- End Turn button in debug panel (enabled only during PLAYER_ACTION)
- `BattleFlowController.end_player_turn()`: guards on PLAYER_ACTION phase, calls `dice_manager.reset_for_turn()`, increments `round_index`, resets to PLAYER_ROLL phase
- `DiceManager.reset_for_turn()`: clears `last_roll_results` and zeroes all crest pool values
- `round_changed` signal emitted on round advance, drives round label update
- Round number label ("Round: N") in debug panel
- End Turn button disabled outside PLAYER_ACTION; Roll Dice button disabled outside PLAYER_ROLL
- BoardView listens to `phase_changed` and deselects unit + clears highlights on any phase transition
- Debug panel refreshes crest pool display on phase change (shows zeroed pool after end turn)

---

## Key Logic

### Turn cycle flow

1. Game starts in `PLAYER_ROLL` (round 1). Roll Dice enabled, End Turn disabled.
2. Player clicks Roll Dice → `start_player_roll()` rolls 3 dice, adds to pool, transitions to `PLAYER_ACTION`. Roll Dice disabled, End Turn enabled.
3. Player selects unit, moves using MOVE crests. Highlights clear when MOVE = 0.
4. Player clicks End Turn → `end_player_turn()` clears pool, increments round, transitions to `PLAYER_ROLL`. End Turn disabled, Roll Dice enabled.
5. Cycle repeats from step 2.

### Crest pool reset rule

Simple full reset: `reset_for_turn()` zeroes all 6 crest types. No carry-over between rounds.

### Selection cleanup on phase change

BoardView connects to `battle_flow.phase_changed`. On any phase transition, if a unit is selected, `_deselect()` is called. This prevents stale selection/highlights across turn boundaries.

---

## Remaining Limits

- **No enemy turn** — End Turn skips directly back to PLAYER_ROLL; no ENEMY_ROLL or ENEMY_ACTION phase is used
- **No attack system** — ATTACK crests are generated but cannot be spent
- **No movement animation** — unit position updates are instant
- **No enemy AI** — enemy grunt sits idle
- **Not validated in-editor** — code is structurally correct but has not been run in Godot yet
- **Single player unit only** — only `blade_shield_dog` exists

---

## Next Suggestion

1. **Attack system** — When a selected unit is adjacent to an enemy, show red attack highlights. Click to attack consuming 1 ATTACK crest. Use existing `ActionResolver.try_attack()`.
2. **Enemy AI turn** — After player ends turn, run a simple enemy phase: enemy rolls dice, moves toward player, attacks if adjacent.
3. **HP display** — Show unit HP on the board (text or bar overlay).
4. **Victory/defeat check** — When enemy HP reaches 0, call `mark_victory()`. When player unit HP reaches 0, call `mark_defeat()`.
