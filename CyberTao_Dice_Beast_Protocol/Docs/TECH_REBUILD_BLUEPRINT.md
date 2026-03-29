# Technical Rebuild Blueprint

## Working Title

CyberTao: Dice Beast Protocol

## Positioning

This is a parallel rebuild track for a new combat mode that combines:

- dice resource generation
- beast-unit tactics
- board movement
- path-building
- card-based meta progression
- buff item pickups
- CN meme and cyber furry flavor

## Legacy Reference

The existing project at the repository root remains the source of reference for:

- procedural visual generation
- audio systems
- UI factory patterns
- global run state structure
- content style and world tone

## New Core Modules

Planned high-level modules:

- `BattleFlowController`
- `DiceManager`
- `BoardManager`
- `UnitManager`
- `ActionResolver`
- `BuffManager`
- `BattleAI`

## New Data Layers

Planned data resources:

- `UnitData`
- `SkillData`
- `ItemData`
- `CoreData`
- `DiceFaceData`

## Migration Principle

Do not force the new mode into the old `BattleManager.gd`.

Instead:

1. keep legacy systems intact
2. prototype the new battle loop in isolation
3. migrate content in batches
4. reconnect roguelike meta systems after the combat prototype is stable
