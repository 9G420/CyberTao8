# Mulerun Work Report

**Date**: 2026-03-29
**Version**: v0.1.11
**Branch**: `codex/dice-beast-protocol`

---

## Task

Fix prototype playability: guarantee MOVE crest availability and reduce enemy distance.

---

## Files Changed

| File | Change |
|------|--------|
| `Project/Scripts/BattleV2/DiceManager.gd` | Added MOVE floor: if roll produces 0 MOVE, set pool to 1 MOVE |
| `Project/Scripts/BattleV2/BattleFlowController.gd` | Changed enemy spawn from (7,1) to (3,4) |
| `Logs/changelog_v0.1.md` | Added v0.1.11 entry |
| `Logs/Mulerun_Work_Report.md` | Overwritten with this report |

---

## Approach

**MOVE guarantee (方案A):** After `roll_turn_dice()` rolls 3 random dice, if the resulting crest pool has `move <= 0`, it is set to `1`. This is the simplest approach — no weight tables, no extra dice, no complex logic. The random roll results array is unchanged (still shows the actual faces rolled), but the pool always has at least 1 MOVE available.

**Why 方案A over others:**
- 方案B (weighted faces) changes probability curves in ways that are hard to predict
- 方案C (more dice) inflates all crest types, not just MOVE
- 方案A is a targeted floor that only activates when needed (57.9% of rolls)

**Enemy repositioned to (3,4):**
- Player starts at (0,6), enemy was at (7,1) — manhattan distance 12
- New position (3,4) — manhattan distance 5
- With guaranteed 1 MOVE per turn and move_range of 3, player can reach enemy in ~2 rounds
- Close enough to test attack within first few turns, far enough that movement still matters

---

## Expected Gameplay Flow

1. Round 1: Roll → get at least 1 MOVE → select unit → move toward (3,4)
2. Round 2: Roll → move adjacent to enemy → if ATTACK crest available, attack
3. Round 3+: Continue attacking until enemy HP reaches 0 → VICTORY

---

## Remaining Limits

- **No enemy AI** — enemy still never moves or attacks
- **No restart** — must reload after victory/defeat
- **MOVE floor is hardcoded** — future design may want configurable floors per crest type
- **Not validated in-editor**

---

## Next Suggestion

1. **Enemy AI turn** — ENEMY_ROLL → ENEMY_ACTION
2. **Restart button** — Allow restarting after terminal phase
3. **Attack feedback** — Damage popup or flash
