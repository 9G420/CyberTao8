# HP and Victory Rules v0.1

This document defines the simplest battle-resolution rules for the prototype phase.

## 1. Unit HP Model

- every unit has `hp` and `max_hp`
- damage reduces current `hp`
- healing cannot exceed `max_hp`
- when `hp <= 0`, the unit is defeated and removed from the board immediately

## 2. Damage Resolution

Prototype damage resolution stays intentionally simple:

- use the attacker's `atk`
- subtract the defender's `def`
- minimum damage is `1`

Formula:

`damage = max(1, atk - def)`

## 3. Defeat Removal

When a unit is defeated:

1. remove it from `units_by_id`
2. remove it from `units_by_cell`
3. clear its occupied board cell
4. redraw the board

No death animation, corpse state, or delayed cleanup is needed in v0.1.

## 4. Prototype Victory Check

The first battle-end rule should be:

- if all enemy-owned units are gone, player wins
- if all player-owned units are gone, player loses
- if both sides somehow reach zero units in the same resolution step, treat it as `DRAW`

This keeps the prototype deterministic and easy to debug.

## 5. Scope Boundaries

Not included in v0.1:

- boss core HP
- direct-core attacks
- shield layers
- death triggers
- resurrection
- over-time damage
- simultaneous stack resolution

## 6. Recommended Hook Points

These checks should be called:

- after a successful attack
- after any direct damage skill
- after any item effect that changes HP

## 7. UI Recommendation

As soon as practical, the board should show unit HP in one of these simple ways:

- `hp/max_hp` text on top of the unit
- a tiny health bar

For the prototype, readability is more important than polish.
