# CyberTao: Dice Beast Protocol Migration Snapshot
**Generated**: 2026-03-29
**Version**: v0.1.1
**Branch**: `codex/dice-beast-protocol`

---

## 1. Project Overview

CyberTao: Dice Beast Protocol is the parallel rebuild track of the original CyberTao project.

It is a Godot 4.6.1 tactical roguelike prototype that combines:

- dice-driven resource generation
- board movement and space control
- beast-unit tactics
- card-style meta progression
- buff item pickups
- CN meme and cyber furry style

The legacy project at the repository root remains intact and is used as a reference baseline for:

- procedural visuals
- UI construction patterns
- project tone
- state management ideas

Main active directory:

- `CyberTao_Dice_Beast_Protocol/Project/`

---

## 2. Current State

Current state at v0.1.1:

- a separate Godot subproject has been created
- the new project has its own `project.godot`
- a minimal `Main.tscn` entry scene exists
- the first `BattleV2` architecture scaffold exists
- the first data resource classes exist
- a visible board prototype now exists in the main scene
- a dice debug panel now exists for roll testing
- a first prototype unit resource exists: blade shield dog
- board is now interactive: clicking player units selects them
- selected unit shows gold ring and cyan-highlighted reachable cells
- clicking a highlighted cell moves the unit, consuming 1 MOVE crest
- BoardManager and UnitManager are synced via occupied_cells
- debug panel shows currently selected unit

The board is now minimally interactive. The next step toward a playable loop is attack resolution.

---

## 3. Architecture Direction

The new combat model should not be built on top of the legacy `BattleManager.gd`.

Instead, the new mode is split into these core modules:

- `BattleFlowController`
- `DiceManager`
- `BoardManager`
- `UnitManager`
- `ActionResolver`
- `BuffManager`
- `BattleAI`

Data resources are split into:

- `UnitData`
- `SkillData`
- `ItemData`
- `CoreData`
- `DiceFaceData`

---

## 4. Current File Structure

Primary new project files:

- `CyberTao_Dice_Beast_Protocol/Project/project.godot`
- `CyberTao_Dice_Beast_Protocol/Project/Scenes/Main.tscn`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/Main.gd`

BattleV2 scripts:

- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/BattleFlowController.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/DiceManager.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/BoardManager.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/UnitManager.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/ActionResolver.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/BuffManager.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/BattleAI.gd`

Data scripts:

- `CyberTao_Dice_Beast_Protocol/Project/Scripts/Data/UnitData.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/Data/SkillData.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/Data/ItemData.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/Data/CoreData.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/Data/DiceFaceData.gd`

Logs and handoff:

- `CyberTao_Dice_Beast_Protocol/Logs/Mulerun_Handoff_Template.md`
- `CyberTao_Dice_Beast_Protocol/Logs/CyberTao_Migration_Snapshot.md`
- `CyberTao_Dice_Beast_Protocol/Logs/changelog_v0.1.md`

---

## 5. Intended Gameplay Direction

The target mode is:

- roguelike overworld progression
- board-based tactical combat
- dice-generated crest resources
- summon plus path-building
- unit movement and attacks
- board pickups and buff items
- meme-driven cyber furry unit identity

First recommended prototype factions:

- blade-shield dog
- hacker fox
- crow caster
- tiger striker

---

## 6. Immediate Priorities

Highest priority implementation targets:

1. ~~turn the visual board prototype into clickable board interaction~~ (done in v0.1.1)
2. ~~let dice resources drive at least one real summon or move action~~ (MOVE done in v0.1.1)
3. create the first prototype unit set, starting with blade-shield dog
4. make the minimum combat loop work:
   - roll dice
   - gain resources
   - summon or place path
   - ~~move~~ (done)
   - attack
   - end turn

---

## 7. Technical Notes

- Godot version is `4.6.1`
- avoid `:=` in known problematic contexts
- do not use `btn.flat = true` when styleboxes are required
- use `node.create_tween()`
- do not call nonexistent functions with `await`
- legacy project is reference only unless explicitly requested

---

## 8. Current Risks

- the new project has not been validated in-editor yet
- no unit scene pipeline exists yet (units are drawn as colored rectangles)
- no attack or damage UI exists yet
- no turn-end or phase-advance button exists yet
- no actual data assets exist beyond blade_shield_dog.tres

---

## 9. Recommended Handoff Rule

Whenever a Mulerun account is close to running out of credits:

1. update this migration snapshot
2. update the latest changelog
3. fill the handoff template
4. clearly state the exact next coding task

This should be treated as mandatory maintenance for continuity.
