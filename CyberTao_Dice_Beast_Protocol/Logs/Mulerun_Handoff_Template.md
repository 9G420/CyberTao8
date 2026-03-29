# Mulerun Project Handoff Template

Use this template when a Mulerun account is about to run out of credits and the project needs to be migrated to a new account with minimal context loss.

Replace the placeholders before sending it to the next account.

---

## 1. Project Identity

- Project name: `CyberTao: Dice Beast Protocol`
- Repository: `https://github.com/9G420/CyberTao8`
- Working branch: `<current-branch>`
- Main working directory: `CyberTao_Dice_Beast_Protocol/Project/`
- Legacy reference directory: repository root legacy Godot project

## 2. Read First

The next account must read these files first:

- `CyberTao_Dice_Beast_Protocol/README.md`
- `CyberTao_Dice_Beast_Protocol/Docs/TECH_REBUILD_BLUEPRINT.md`
- `CyberTao_Dice_Beast_Protocol/Logs/CyberTao_Migration_Snapshot.md`
- `CyberTao_Dice_Beast_Protocol/Logs/changelog_v0.1.md`

If more versions exist, also read the latest changelog.

## 3. Current Project Position

Write a short summary here:

- Current version: `<v0.x.x>`
- Current milestone: `<what is playable or scaffolded>`
- Current focus: `<what is being built right now>`
- Last completed task: `<latest finished task>`
- Immediate next task: `<the next concrete implementation target>`

## 4. Working Rules

- The old project is reference only unless explicitly requested.
- New work goes into `CyberTao_Dice_Beast_Protocol/Project/`.
- Do not continue expanding the old `BattleManager.gd`.
- Keep logs updated after each meaningful milestone.
- Create a new migration snapshot whenever major architecture or goals change.
- Update changelog after each implementation batch.

## 5. Technical Constraints

- Godot version: `4.6.1`
- Avoid `:=` for array literals, string concatenation, and untyped array indexing.
- Never use `btn.flat = true` when relying on `StyleBoxFlat`.
- Use `node.create_tween()` instead of bare `create_tween()`.
- Avoid `await` on nonexistent functions.
- Preserve the legacy project as a stable reference baseline.

## 6. Current Architecture State

Document the active modules:

- Battle flow:
- Dice system:
- Board system:
- Unit system:
- Buff/item system:
- AI state:
- UI state:
- Data resources:

## 7. Files Changed Recently

List the most relevant files from the latest work:

- `<file path>` - `<why it changed>`
- `<file path>` - `<why it changed>`

## 8. Open Risks / Known Problems

- `<risk 1>`
- `<risk 2>`
- `<risk 3>`

## 9. Pending Work

Prioritize concrete next steps:

1. `<task>`
2. `<task>`
3. `<task>`

## 10. Suggested Prompt For The Next Account

Paste this and update the placeholders:

```text
This is a project handoff for CyberTao: Dice Beast Protocol.

Repository:
https://github.com/9G420/CyberTao8

Working branch:
<current-branch>

Main working directory:
CyberTao_Dice_Beast_Protocol/Project/

Please first read:
- CyberTao_Dice_Beast_Protocol/README.md
- CyberTao_Dice_Beast_Protocol/Docs/TECH_REBUILD_BLUEPRINT.md
- CyberTao_Dice_Beast_Protocol/Logs/CyberTao_Migration_Snapshot.md
- CyberTao_Dice_Beast_Protocol/Logs/changelog_v0.1.md

Current version:
<v0.x.x>

Current focus:
<current focus>

Important constraints:
- Keep the legacy project as reference only
- Do not expand the old BattleManager.gd
- Continue work in CyberTao_Dice_Beast_Protocol/Project/
- Update logs after each meaningful implementation step

Please summarize your understanding first, then continue from the latest milestone.
```

## 11. Export Checklist

Before handing off to a new account:

- Confirm branch name
- Confirm all latest files are committed or clearly identified as uncommitted
- Update `CyberTao_Migration_Snapshot.md`
- Update the latest changelog file
- Fill in this handoff template
- Record the exact next coding target

---

This template exists to reduce context loss and let different Mulerun accounts continue the same project with minimal interruption.
