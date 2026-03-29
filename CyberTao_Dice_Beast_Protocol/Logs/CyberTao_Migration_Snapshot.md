# CyberTao: Dice Beast Protocol Migration Snapshot
**Generated**: 2026-03-29
**Version**: v0.1.3
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

Current state at v0.1.3:

- a separate Godot subproject has been created
- the new project has its own `project.godot`
- a minimal `Main.tscn` entry scene exists
- the first `BattleV2` architecture scaffold exists
- the first data resource classes exist
- a visible board prototype now exists in the main scene
- a dice debug panel now exists for roll testing
- a first prototype unit resource exists: blade shield dog
- prototype skill resources now exist for blade shield dog
- a first combat rules document now exists for the v0.1 prototype phase
- prototype pickup item resources now exist
- prototype dice face resources now exist
- a second prototype unit resource now exists: hacker fox
- a third prototype unit resource now exists: crow caster
- a first item effect library now exists
- a first prototype core resource now exists
- first attack helper and attack rule support docs now exist
- first HP / victory support helper and prototype battle-end rules now exist
- board is now interactive: clicking player units selects them
- selected unit shows gold ring and cyan-highlighted reachable cells
- clicking a highlighted cell moves the unit, consuming 1 MOVE crest
- BoardManager and UnitManager are synced via occupied_cells
- debug panel shows currently selected unit
- dice roll limited to once per turn with auto phase transition
- End Turn button advances round, clears crest pool, re-enables dice roll
- round number displayed in debug panel
- basic turn cycle works: Roll → Move → End Turn → Roll again

The board now has a functional turn loop. The next step is attack resolution.

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

Skill resources:

- `CyberTao_Dice_Beast_Protocol/Project/Data/Skills/my_blade_and_shield.tres`
- `CyberTao_Dice_Beast_Protocol/Project/Data/Skills/rough_counter.tres`

Item resources:

- `CyberTao_Dice_Beast_Protocol/Project/Data/Items/patch_tea_cache.tres`
- `CyberTao_Dice_Beast_Protocol/Project/Data/Items/overclock_bone.tres`
- `CyberTao_Dice_Beast_Protocol/Project/Data/Items/glitch_snack_box.tres`

Dice resources:

- `CyberTao_Dice_Beast_Protocol/Project/Data/Dice/face_summon_basic.tres`
- `CyberTao_Dice_Beast_Protocol/Project/Data/Dice/face_move_basic.tres`
- `CyberTao_Dice_Beast_Protocol/Project/Data/Dice/face_attack_basic.tres`
- `CyberTao_Dice_Beast_Protocol/Project/Data/Dice/face_defend_basic.tres`
- `CyberTao_Dice_Beast_Protocol/Project/Data/Dice/face_skill_basic.tres`
- `CyberTao_Dice_Beast_Protocol/Project/Data/Dice/face_trick_basic.tres`

Combat support:

- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/SkillEffectLibrary.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/ItemEffectLibrary.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/AttackRuleHelper.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/BattleV2/VictoryRuleHelper.gd`
- `CyberTao_Dice_Beast_Protocol/Docs/COMBAT_RULES_v0.1.md`
- `CyberTao_Dice_Beast_Protocol/Docs/CONTENT_ROADMAP_v0.1.md`
- `CyberTao_Dice_Beast_Protocol/Docs/UNIT_KEYWORDS_v0.1.md`
- `CyberTao_Dice_Beast_Protocol/Docs/ATTACK_RULES_v0.1.md`
- `CyberTao_Dice_Beast_Protocol/Docs/HP_VICTORY_RULES_v0.1.md`

Logs and handoff:

- `CyberTao_Dice_Beast_Protocol/Logs/Mulerun_Handoff_Template.md`
- `CyberTao_Dice_Beast_Protocol/Logs/Mulerun_Work_Report.md`
- `CyberTao_Dice_Beast_Protocol/Logs/CyberTao_Migration_Snapshot.md`
- `CyberTao_Dice_Beast_Protocol/Logs/changelog_v0.1.md`

UI scripts:

- `CyberTao_Dice_Beast_Protocol/Project/Scripts/UI/BoardView.gd`
- `CyberTao_Dice_Beast_Protocol/Project/Scripts/UI/DiceDebugPanel.gd`

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

Completed through v0.1.3:

1. ~~turn the visual board prototype into clickable board interaction~~ (done in v0.1.1)
2. ~~let dice resources drive at least one real move action~~ (done in v0.1.1 — MOVE crest spending)
3. ~~create the first prototype unit set~~ (blade-shield dog, hacker fox, crow caster exist)
4. make the minimum combat loop work:
   - ~~roll dice~~ (done in v0.1.0)
   - ~~gain resources~~ (done in v0.1.0 — crest pool)
   - summon or place path (not yet functional)
   - ~~move~~ (done in v0.1.1)
   - attack (not yet implemented)
   - ~~end turn~~ (done in v0.1.3)

Next priority targets:

5. implement basic attack system (ATTACK crest spending, adjacent target, damage resolution)
6. add HP display on units and hook in victory/defeat checks
7. implement simple enemy AI turn (ENEMY_ROLL → ENEMY_ACTION)

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
- no enemy turn logic exists yet
- data assets exist for blade_shield_dog, hacker_fox, crow_caster, plus skill/item/dice resources

---

## 9. Recommended Handoff Rule

Whenever a Mulerun account is close to running out of credits:

1. update this migration snapshot
2. update the latest changelog
3. fill the handoff template
4. clearly state the exact next coding task

This should be treated as mandatory maintenance for continuity.
