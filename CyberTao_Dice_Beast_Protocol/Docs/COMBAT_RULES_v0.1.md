# Combat Rules v0.1

This document defines the current intended combat rules for the Dice Beast Protocol prototype.

## Prototype Goals

The prototype is not trying to recreate the full final ruleset yet.

It should validate:

- dice resource generation
- board-based movement
- unit selection
- path placement
- basic attacks
- one or two prototype skills

## Turn Loop

Current intended turn loop:

1. player roll phase
2. player action phase
3. enemy roll phase
4. enemy action phase

Each turn starts with a 3-dice roll.

## Resource Types

Current crest pool types:

- `summon`
- `move`
- `attack`
- `defend`
- `skill`
- `trick`

## Movement Rules

Prototype movement rules:

- only orthogonal movement
- movement cannot leave the board
- movement cannot enter an occupied cell
- movement range is defined by the unit's `move_range`
- each successful move currently consumes `1 move`
- path cells may later be required for some units, but this is not mandatory in v0.1

## Summon Rules

Prototype summon rules:

- summon consumes `summon` crest
- summon may also place one or more path cells
- initial summon restrictions can be simplified to a starting deployment zone

## Attack Rules

Prototype attack rules:

- attack consumes `1 attack`
- melee units attack adjacent targets
- damage is currently simplified as:
  - `max(1, attacker.atk - defender.def)`

This will likely change later.

## Guard / Counter Rules

The first prototype unit is `blade_shield_dog`.

Intended identity:

- frontliner
- retaliation
- lane control
- low mobility

Current prototype skills:

### `我的刀盾`

- cost: `defend 1 + skill 1`
- self-targeted
- gain temporary guard
- retaliate once if hit in melee this turn

### `糙盾反汪击`

- cost: `attack 1 + skill 1`
- adjacent target
- deal impact damage
- push target by 1 cell if possible

## v0.1 Scope Limits

Do not implement yet unless explicitly required:

- full path dependency logic
- advanced terrain types
- reaction chains
- trap stack logic
- ranged line-of-sight rules
- boss-specific battlefield mechanics
- complete card-to-unit migration

## Coordination Rule

When multiple agents or tools are used:

- UI and debug interaction work can proceed in parallel
- combat rules and effect logic should remain centralized
- logs should be updated after each meaningful milestone
