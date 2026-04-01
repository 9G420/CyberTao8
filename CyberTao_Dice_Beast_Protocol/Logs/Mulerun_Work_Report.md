# Mulerun 工作报告

**日期**: 2026-04-02
**版本**: v0.1.91
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.91：2D 单位美术同步像素化（替换旧矢量 Q 版）

---

## 根因说明

用户反馈 2D 模式仍是旧丑风格。

根因：
- v0.1.89 改的是 3D 棋盘单位（UnitMeshFactory3D）
- v0.1.90 改的是卡牌战斗立绘（BattleCharRenderer）
- 2D 棋盘仍走 `UnitRenderer.draw_full_unit_iso()` 旧矢量路径

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/UI/UnitRenderer.gd` | 新增 2D 像素纹理缓存与映射（玩家/召唤/敌方）；`draw_full_unit_iso()` 改为优先绘制像素贴图，旧矢量绘制保留 fallback |
| `Logs/changelog_v0.1.md` | 追加 v0.1.91 条目 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |

---

## 实现内容

1) 新增 `_get_iso_unit_tex(unit)`：
- player -> `_gen_player_hero()`
- summoned -> `_gen_summoned_ally()`
- enemy -> `_gen_enemy_by_id(encounter_id)`

2) `draw_full_unit_iso()` 改造：
- 优先 `draw_texture_rect` 绘制像素单位
- 附加脚底微光（玩家青色 / 敌方橙色）
- 若纹理异常，回退旧 `_draw_player_char/_draw_enemy_char`

---

## 测试点

| 测试项 | 结果 |
|--------|------|
| 2D 模式单位外观已切到像素纹理风格 | ✅ |
| 2D/3D/卡牌战斗三端风格一致性提升 | ✅ |
| 选中环与 HP 条逻辑保持不变 | ✅ |
| 纹理异常时可回退，不影响功能 | ✅ |

---

## 下一步

- v0.1.92：继续敌方第二批（05~07 + boss）重绘并微调 2D 渲染尺寸/位置对齐。
