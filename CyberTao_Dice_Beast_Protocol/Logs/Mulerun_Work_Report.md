# Mulerun 工作报告

**日期**: 2026-04-02
**版本**: v0.1.90
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.90：修复“拉取后卡牌战斗形象没变”的同步问题

---

## 根因说明

用户截图是**卡牌战斗界面**（CardBattlePanel），该界面角色来自 `BattleCharRenderer.gd`（矢量绘制）。

而 v0.1.89 重绘的是 `UnitMeshFactory3D.gd`（3D 棋盘单位像素纹理）。

所以出现了：
- 3D棋盘单位已变
- 卡牌战斗立绘看起来没变

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/UI/BattleCharRenderer.gd` | 增加与 UnitMeshFactory3D 的纹理复用：玩家和敌方优先使用像素纹理绘制；旧矢量方案保留为 fallback |
| `Logs/changelog_v0.1.md` | 追加 v0.1.90 条目 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |

---

## 实现内容

1) 新增像素立绘绘制入口 `_draw_pixel_portrait()`
- 统一贴图绘制区域 + 轻微光晕

2) 玩家立绘同步
- `draw_player_hero()` 优先使用 `UnitMeshFactory3D._gen_player_hero()`

3) 敌方立绘同步
- `draw_enemy()` 按 `encounter_id` 优先使用 `UnitMeshFactory3D._gen_enemy_by_id()`
- 与你前一轮重绘（01~04）直接联动

4) 兼容性
- 若纹理获取失败，仍回退原 `BattleCharRenderer` 的矢量绘制路径，保证不崩

---

## 测试点

| 测试项 | 结果 |
|--------|------|
| 卡牌战斗中玩家形象改为像素纹理 | ✅ |
| 卡牌战斗中 encounter_01~04 可看到新重绘敌方风格 | ✅ |
| 纹理异常时仍可回退旧矢量绘制 | ✅ |

---

## 下一步

- v0.1.91：继续重绘 encounter_05~07 + Boss，并同步卡牌战斗立绘展示。
