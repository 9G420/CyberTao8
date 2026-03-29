# Mulerun Work Report

**Date**: 2026-03-29
**Version**: v0.1.12
**Branch**: `codex/dice-beast-protocol`

---

## Task

Attack feedback enhancement + restart button after victory/defeat.

---

## Files Changed

| File | Change |
|------|--------|
| `Project/Scripts/UI/BoardView.gd` | Added attack flash + floating damage number via tween |
| `Project/Scripts/Main.gd` | Added restart button, wired attack_completed signal for feedback |
| `Project/Scripts/BattleV2/BattleFlowController.gd` | Added `restart_battle()` method |
| `Project/Scripts/BattleV2/UnitManager.gd` | Added `clear_all_units()` method |
| `Project/Scripts/BattleV2/BoardManager.gd` | Added `clear_board()` method |
| `Logs/changelog_v0.1.md` | Added v0.1.12 entry |
| `Logs/Mulerun_Work_Report.md` | Overwritten with this report |

---

## Approach

**Attack feedback:**
- White flash overlay on the attacked cell, fading from alpha 0.85 to 0.0 over 0.35s via `create_tween()` + `tween_method()`
- Red floating damage label ("-N") spawned as a child of BoardView, tweens upward 40px and fades out over 0.6s, then `queue_free()`
- `_draw_attack_flash()` added to `_draw()` pipeline for the flash rect
- Feedback triggered from `_on_attack_requested` after successful `try_attack_unit()`

**Restart button:**
- "重新开始" Button at (560, 60), hidden by default
- Shown alongside result label when phase is VICTORY or DEFEAT
- Hidden when phase changes to anything else
- On press: clears BoardView selection, calls `restart_battle()` on BattleFlowController
- `restart_battle()` resets DiceManager, clears all units, rebuilds board, re-spawns debug units, sets round to 1 and phase to PLAYER_ROLL

---

## Expected Gameplay Flow

1. Roll → Move → Attack → see white flash + red "-N" floating up
2. Repeat until enemy HP 0 → "胜利" label + "重新开始" button appear
3. Click "重新开始" → board resets to initial state, round 1

---

## Remaining Limits

- **No enemy AI** — enemy still never moves or attacks
- **No sound effects** — feedback is visual only
- **MOVE floor is hardcoded** — future design may want configurable floors
- **Not validated in-editor**

---

## Next Suggestion

1. **Enemy AI turn** — ENEMY_ROLL → ENEMY_ACTION
2. **Movement animation** — Tween unit position instead of instant teleport
3. **HP bar** — Visual HP bar instead of text overlay
