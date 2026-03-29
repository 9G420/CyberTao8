# Mulerun Work Report

**Date**: 2026-03-29
**Version**: v0.1.10
**Branch**: `codex/dice-beast-protocol`

---

## Task

Fix interaction regression: board clicks not reaching BoardView, preventing unit selection, movement, and attack.

---

## Root Cause

Multiple Controls in Main.gd used the default `mouse_filter = MOUSE_FILTER_STOP`, which in Godot 4 means "intercept all mouse events in my rect." These decorative/overlay nodes were stealing clicks before they could reach BoardView:

1. **`bg` (ColorRect)**: `PRESET_FULL_RECT` covering entire 1280x720 viewport with default `MOUSE_FILTER_STOP`
2. **Title/subtitle/hint labels**: Full 1280px width with default `MOUSE_FILTER_STOP`, overlapping the board's vertical range
3. **`SettingsPanel`**: Position (440,200) size 400x320 with `MOUSE_FILTER_STOP` even when `visible = false` — overlapped board region [440,200]-[616,520]
4. **`_result_label`**: Full 1280px width with default `MOUSE_FILTER_STOP`
5. **BoardView**: Never called `accept_event()` after handling clicks, allowing input to propagate unexpectedly

---

## Files Changed

| File | Change |
|------|--------|
| `Project/Scripts/Main.gd` | Set `mouse_filter = MOUSE_FILTER_IGNORE` on bg, title, subtitle, hint, _result_label |
| `Project/Scripts/UI/SettingsPanel.gd` | Start with `MOUSE_FILTER_IGNORE`; toggle to `STOP` on open(), back to `IGNORE` on close |
| `Project/Scripts/UI/BoardView.gd` | Added `accept_event()` call after `_handle_cell_click()` in `_gui_input()` |
| `Logs/changelog_v0.1.md` | Added v0.1.10 entry |
| `Logs/Mulerun_Work_Report.md` | Overwritten with this report |

---

## What Was Restored

- Click player unit to select (gold ring + "选中：" update)
- Roll dice, then click cyan-highlighted cell to move (MOVE crest consumed)
- Click red-highlighted adjacent enemy cell to attack (ATTACK crest consumed, HP updated)
- End Turn button advances round
- Victory/defeat judgment still intact
- Settings panel still works when opened via "设置" button

---

## Remaining Limits

- **No enemy AI** — enemy never takes a turn
- **No restart** — no way to restart after victory/defeat
- **No attack animation** — damage is instant
- **Not validated in-editor**

---

## Next Suggestion

1. **Enemy AI turn** — ENEMY_ROLL → ENEMY_ACTION
2. **Restart button** — Allow restarting after terminal phase
3. **Attack feedback** — Damage popup or flash
