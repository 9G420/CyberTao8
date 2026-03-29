# Mulerun Work Report

**Date**: 2026-03-29
**Version**: v0.1.7
**Branch**: `codex/dice-beast-protocol`

---

## Task

Add display settings system: resolution/window mode selection, persistence, settings panel UI.

---

## Files Changed

| File | Change |
|------|--------|
| `Project/project.godot` | Changed default viewport from 1920x1080 to 1280x720 |
| `Project/Scripts/Main.gd` | Added DisplaySettings/SettingsPanel preloads, instantiation, settings button, repositioned layout for 1280x720 |
| `Project/Scripts/System/DisplaySettings.gd` | New file — resolution/mode state, ConfigFile load/save, DisplayServer apply, center window |
| `Project/Scripts/UI/SettingsPanel.gd` | New file — settings UI panel with resolution/mode dropdowns, apply/reset/close buttons |
| `Logs/changelog_v0.1.md` | Added v0.1.7 entry |
| `Logs/CyberTao_Migration_Snapshot.md` | Updated to v0.1.7 |
| `Logs/Mulerun_Work_Report.md` | Overwritten with this report |

---

## What Was Implemented

- `DisplaySettings` node: manages `current_resolution` and `current_mode`, loads from `user://display_settings.cfg` on `_ready()`, applies via `DisplayServer` API
- Three resolution options: 1280x720, 1600x900, 1920x1080
- Three window modes: windowed (0), fullscreen (1), borderless windowed (2)
- `SettingsPanel` UI: Chinese labels, `OptionButton` dropdowns, apply/reset/close buttons
- Settings button ("设置") at top-right of main scene, opens panel overlay
- `project.godot` default viewport changed to 1280x720 to match default resolution
- Main scene layout repositioned for 1280x720 viewport

---

## Key Logic

### Settings persistence

1. On startup: `DisplaySettings._ready()` → `load_settings()` reads ConfigFile → `apply_settings()` calls DisplayServer
2. User opens panel → selects resolution/mode → clicks "应用" → `_on_apply_pressed()` updates DisplaySettings state, calls `apply_settings()` + `save_settings()`
3. `apply_settings()` uses `DisplayServer.window_set_mode()`, `window_set_size()`, `window_set_flag()` based on mode
4. `save_settings()` writes resolution_x, resolution_y, mode to ConfigFile at `user://display_settings.cfg`

### Window centering

After setting windowed/borderless size, `_center_window()` reads screen size and positions window at center.

---

## Remaining Limits

- **No restart** — after victory/defeat, no way to restart without reloading
- **No enemy AI** — enemy never takes a turn
- **No audio settings** — only display settings implemented
- **Not validated in-editor**

---

## Next Suggestion

1. **Enemy AI turn** — ENEMY_ROLL → ENEMY_ACTION
2. **Restart button** — Allow restarting battle after victory/defeat
3. **Audio settings** — Volume controls in settings panel
