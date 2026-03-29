# Mulerun Work Report

**Date**: 2026-03-29
**Version**: v0.1.5
**Branch**: `codex/dice-beast-protocol`

---

## Task

Fix attack_range data link: ensure `UnitManager.spawn_unit()` stores `attack_range` in unit state, and `_spawn_debug_units()` passes it from data resources.

---

## Files Changed

| File | Change |
|------|--------|
| `Project/Scripts/BattleV2/UnitManager.gd` | Added `attack_range` field to unit state in `spawn_unit()` |
| `Project/Scripts/BattleV2/BattleFlowController.gd` | Added `attack_range` to player spawn payload (from `dog_data.attack_range`) and enemy spawn payload (hardcoded `1`) |
| `Logs/changelog_v0.1.md` | Added v0.1.5 entry |
| `Logs/Mulerun_Work_Report.md` | Overwritten with this report |

---

## What Was Implemented

- `UnitManager.spawn_unit()` now includes `"attack_range": int(payload.get("attack_range", 1))` in the unit state dictionary
- `_spawn_debug_units()` player payload now includes `"attack_range": dog_data.attack_range`
- `_spawn_debug_units()` enemy payload now includes `"attack_range": 1`

---

## Key Logic

`ActionResolver.get_attackable_cells()` reads `unit.get("attack_range", 1)` from unit state. Previously, `spawn_unit()` never wrote this field, so it always fell back to the default value of 1. This worked by accident for the current melee-only prototype but would break for any unit with a non-default attack range. The fix explicitly stores the value so the data pipeline is correct end-to-end: `UnitData.attack_range` → spawn payload → unit state → `ActionResolver`.

---

## Remaining Limits

- No visible behavior change for current prototype (all units have attack_range = 1)
- No HP display on units
- No victory/defeat check
- No enemy turn or AI
- No ranged attack UI differentiation

---

## Next Suggestion

1. **HP display** — Show unit HP as text overlay on each unit rectangle
2. **Victory/defeat check** — When all enemies dead → `mark_victory()`, when player unit dead → `mark_defeat()`
3. **Enemy AI turn** — ENEMY_ROLL → ENEMY_ACTION with simple move-toward + attack logic
