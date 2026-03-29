# Attack Rules v0.1

This document defines the first intended attack prototype for Dice Beast Protocol.

## Attack Goal

The attack prototype should be minimal and testable.

It should support:

- attack target highlighting
- basic attack resource consumption
- melee adjacency
- ranged attack distance for future units
- damage application

## Resource Cost

Prototype attack rule:

- a normal attack consumes `1 attack`

Skills may consume:

- `attack`
- `skill`
- `trick`

depending on the unit.

## Attackable Target Rule

An enemy cell is attackable when:

- it contains an enemy unit
- it is inside the attacker's Manhattan attack range
- the attacker is alive

Current simplified range model:

- melee units: `attack_range = 1`
- ranged units: `attack_range > 1`

## Prototype Damage Rule

Current damage formula:

`max(1, attacker.atk - defender.def)`

This is intentionally simple for the prototype.

## First Planned Attack UX

When a player unit is selected:

- moveable cells appear in cyan
- attackable enemy cells should later appear in red

If the player clicks a red target:

- spend `1 attack`
- resolve damage
- refresh board

## First Prototype Attack Units

### Blade Shield Dog

- melee attacker
- can use basic direct attack
- can use retaliate-style skill attacks

### Hacker Fox

- short ranged disruption
- can apply `jammed`

### Crow Caster

- longer-range control attack
- can weaken or trap

## Out of Scope for v0.1

- facing direction
- diagonal attack shapes
- line-of-sight blockers
- reaction chains
- area attacks
- split damage
