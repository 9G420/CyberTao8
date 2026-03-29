# Mulerun Work Report

**Date**: 2026-03-29
**Version**: v0.1.4
**Branch**: `codex/dice-beast-protocol`

---

## Task

Add basic attack interaction: red attack highlights on adjacent enemies, click-to-attack consuming 1 ATTACK crest, damage resolution with unit removal on kill.

---

## Files Changed

| File | Change |
|------|--------|
| `Project/Scripts/BattleV2/BattleFlowController.gd` | Added `attack_completed` signal, `get_attackable_cells_for()`, `try_attack_unit()`, `AttackRuleHelper` preload |
| `Project/Scripts/UI/BoardView.gd` | Added `attack_requested` signal, `attack_highlight_cells`, `_draw_attack_highlights()`, attack click handling |
| `Project/Scripts/UI/DiceDebugPanel.gd` | Connected `attack_completed` signal, added `_on_attack_completed()` handler |
| `Project/Scripts/Main.gd` | Wired `attack_requested` signal, added `_on_attack_requested()`, refreshes attack highlights after move |
| `Logs/changelog_v0.1.md` | Added v0.1.4 entry |
| `Logs/CyberTao_Migration_Snapshot.md` | Updated to v0.1.4, marked attack as done |
| `Logs/Mulerun_Work_Report.md` | Overwritten with this report |

---

## What Was Implemented

- Red attack highlight overlay on adjacent enemy cells when a player unit is selected and ATTACK crest > 0
- Click a red-highlighted cell to execute a basic melee attack
- `BattleFlowController.try_attack_unit()`: validates target is in attackable cells, pays 1 ATTACK crest, computes damage via `AttackRuleHelper.calc_basic_damage()`, applies damage via `UnitManager.apply_damage()`
- `BattleFlowController.get_attackable_cells_for()`: delegates to `ActionResolver.get_attackable_cells()`, returns empty if ATTACK crest <= 0
- `attack_completed` signal emitted after each attack (attacker_id, defender_id, damage, killed)
- `BoardView` draws red highlights separately from cyan move highlights — both can appear simultaneously
- Attack targets checked before move targets in click handler (attack takes priority on occupied enemy cells)
- If target HP <= 0 after damage, `apply_damage()` calls `despawn_unit()` which removes the unit from board and dictionaries
- Debug panel refreshes crest pool display after each attack

---

## Key Logic

### Attack flow

1. Player selects a unit during PLAYER_ACTION phase.
2. `_select_unit()` computes both `highlight_cells` (move) and `attack_highlight_cells` (attack).
3. Cyan highlights show reachable empty cells (gated on MOVE > 0). Red highlights show adjacent enemy cells (gated on ATTACK > 0).
4. Player clicks a red cell → `attack_requested` signal → `Main._on_attack_requested()` → `BattleFlowController.try_attack_unit()`.
5. `try_attack_unit()` verifies the cell is in attackable list, pays 1 ATTACK crest, calls `AttackRuleHelper.calc_basic_damage(attacker, defender)` → `max(1, atk - def)`, then `unit_manager.apply_damage(defender_id, damage)`.
6. If HP <= 0, `apply_damage()` returns true (killed) and auto-despawns the unit.
7. Both highlight types refresh after attack.

### Damage formula

`max(1, attacker.atk - defender.def)` — minimum 1 damage guaranteed.

### Highlight coexistence

Move highlights (cyan) and attack highlights (red) are independent arrays drawn in separate passes. A cell can only be one or the other since move cells must be unoccupied and attack cells must contain an enemy.

---

## Remaining Limits

- **No enemy turn** — End Turn skips directly back to PLAYER_ROLL
- **No HP display** — unit health is not visible on the board
- **No victory/defeat check** — killing the enemy does not trigger any end state
- **No attack animation** — damage is applied instantly
- **No ranged or area attacks** — melee adjacent only
- **No enemy AI** — enemy grunt sits idle
- **Not validated in-editor** — code is structurally correct but has not been run in Godot yet

---

## Next Suggestion

1. **HP display** — Show unit HP as text or bar overlay on each unit rectangle
2. **Victory/defeat check** — When all enemies are dead, call `mark_victory()`. When player unit dies, call `mark_defeat()`.
3. **Enemy AI turn** — After player ends turn, run ENEMY_ROLL → ENEMY_ACTION: enemy rolls dice, moves toward player, attacks if adjacent
4. **Attack feedback** — Brief visual flash or text popup showing damage dealt
