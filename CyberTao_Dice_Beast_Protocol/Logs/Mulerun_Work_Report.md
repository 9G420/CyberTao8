# Mulerun Work Report

**Date**: 2026-03-29
**Version**: v0.1.9
**Branch**: `codex/dice-beast-protocol`

---

## Task

Fix Chinese text encoding corruption across all three UI scripts by full rewrite.

---

## Files Changed

| File | Change |
|------|--------|
| `Project/Scripts/Main.gd` | Full rewrite via Python with Unicode escapes to guarantee clean UTF-8 |
| `Project/Scripts/UI/DiceDebugPanel.gd` | Full rewrite via Python with Unicode escapes to guarantee clean UTF-8 |
| `Project/Scripts/UI/SettingsPanel.gd` | Full rewrite via Python with Unicode escapes to guarantee clean UTF-8 |
| `Logs/changelog_v0.1.md` | Added v0.1.9 entry |
| `Logs/Mulerun_Work_Report.md` | Overwritten with this report |

---

## What Was Done

- All three UI scripts were rewritten from scratch using Python with `\uXXXX` Unicode escape sequences for every Chinese character
- Files written using `open(path, 'wb')` with explicit `.encode('utf-8')` to bypass any intermediate encoding layer
- Every expected Chinese string verified byte-by-byte after rewrite
- No logic or layout changes — identical behavior to previous version

---

## Verified Chinese Strings

Main.gd:
- `CyberTao：骰兽协议`
- `原型战斗沙盒已启动：掷骰、移动、攻击、结束回合`
- `左侧棋盘：点击我方单位，再点击青色格移动或红色格攻击`
- `设置`

DiceDebugPanel.gd:
- `战斗调试`, `回合：`, `阶段：玩家掷骰`, `选中：无`
- `掷骰`, `结束回合`, `生成测试路径`, `上次掷骰：`
- `显化`, `步进`, `杀伐`, `护持`, `术式`, `机巧`
- `玩家掷骰`, `玩家行动`, `敌方掷骰`, `敌方行动`, `胜利`, `失败`

SettingsPanel.gd:
- `显示设置`, `分辨率`, `窗口模式`
- `窗口化`, `全屏`, `无边框窗口`
- `应用`, `恢复默认`, `关闭`

---

## Remaining Limits

- **No restart** — after victory/defeat, no way to restart without reloading
- **No enemy AI** — enemy never takes a turn
- **Not validated in-editor**

---

## Next Suggestion

1. **Enemy AI turn** — ENEMY_ROLL → ENEMY_ACTION
2. **Restart button** — Allow restarting battle after victory/defeat
3. **Attack feedback** — Damage popup or flash
