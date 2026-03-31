# Mulerun 工作报告

**日期**: 2026-03-31
**版本**: v0.1.61
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.61：棋盘渲染回退至程序化（移除 AI 贴图 + 程序化菱形绘制）

---

## 根因目标

用户截图反馈 v0.1.60 运行效果严重异常：AI 生成的等距贴图为高耸 3D 方块图（TILE_FULL_H=192 / TILE_ELEVATED_H=256），渲染后整个棋盘看起来像积木墙而非游戏地图。画面大量黑色空白，底部方块严重堆叠遮挡，特殊格与普通格视觉割裂。

用户明确要求：回退到程序化渲染，删除所有 AI 贴图文件。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/UI/IsoTileRenderer.gd` | 全面重写：移除贴图加载体系，改为程序化菱形绘制（填充+渐变+边框+9种类型装饰符号） |
| `Scripts/UI/BoardView.gd` | _draw_layer_grid 传入 pulse 参数适配新 API |
| `Assets/Tiles/*.png` | 删除全部 11 张 AI 生成贴图 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.61 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号+完成列表 |
| `Logs/Handoff_Package_latest.md` | 同步至 v0.1.60 状态（本轮同时完成文档补齐） |
| `Logs/CyberTao_Migration_Snapshot_zh_v3.md` | 同步至 v0.1.60 状态（本轮同时完成文档补齐） |

---

## 实现内容

### IsoTileRenderer 程序化重写

- 移除的内容：
  - TILE_FULL_H / TILE_ELEVATED_H / ELEVATION_OFFSET 常量（导致方块高耸的根因）
  - TILE_PATHS / _textures / _loaded / _ensure_loaded（贴图加载体系）
  - _draw_single_tile 中的 draw_texture_rect 调用
  - ELEVATED_KEYS / is_elevated（高起判断）

- 新增的内容：
  - `_draw_tile_procedural()`：程序化绘制菱形格子
    - 基础菱形填充（CyberStyle 配色，深浅交替）
    - 内部缩小菱形模拟径向渐变
    - 网格边框线（类型格子有独立边框色 + 脉冲呼吸）
    - 9种类型装饰符号（高台▲/陷阱✖/遭遇⚡/回复✚/商店◆/宝箱⬡/道具◇/事件?/传送门旋涡圆环）
  - `draw_board()` 新增 pulse 参数
  - `_get_fill_color()` / `_get_border_color()` / `_draw_tile_decoration()` 分离渲染逻辑

- 完全保留的内容：
  - TILE_W=192 / TILE_H_DIAMOND / TILE_H_HALF / GRID_SIZE
  - grid_to_screen / screen_to_grid / calc_origin_for_cell（坐标转换+相机跟随）
  - diamond_points / draw_diamond_highlight / draw_diamond_corners（叠层辅助）
  - _get_tile_key（格子类型判定）

### 文档补齐

- Handoff_Package_latest.md 从 v0.1.54 更新至 v0.1.60
- CyberTao_Migration_Snapshot_zh_v3.md 从 v0.1.54 更新至 v0.1.60

---

## 接口变更

- `IsoTileRenderer.draw_board(canvas, origin, board_mgr, pulse)`: 新增 pulse 参数（默认 0.5）
- 移除：`IsoTileRenderer.TILE_FULL_H` / `TILE_ELEVATED_H` / `ELEVATION_OFFSET`
- 移除：`IsoTileRenderer.ELEVATED_KEYS` / `is_elevated()`
- 移除：`IsoTileRenderer.TILE_PATHS` / `_textures` / `_loaded` / `_ensure_loaded()`

---

## 测试确认

- 代码层面确认：IsoTileRenderer 不再引用任何贴图文件
- 坐标系完全保留：grid_to_screen / screen_to_grid / calc_origin_for_cell 签名不变
- 相机跟随链完整：BoardView.set_camera_target → iso_origin 动态计算 → 重绘
- BoardView._draw_layer_grid 正确传入 pulse 参数
- 叠层/高亮/单位/攻击闪光/边缘渐暗层零修改
- 需用户在 Godot 中实际运行确认视觉效果

---

## 剩余问题

- 相机跟随暂无平滑过渡（仍为瞬间跳转）
- 阵亡单位跨层不复活
- CardRewardPanel 暂未使用 CardRenderer 风格
- 扇形手牌暂无拖拽机制
- SettingsPanel 暂未添加音量控件
- 路径格无专属装饰（仅半透明菱形叠层，由 BoardView._draw_layer_overlays 处理）

---

## 建议下一步

1. 用户在 Godot 中运行确认程序化渲染效果
2. 相机跟随平滑过渡（Tween 插值 iso_origin）
3. 商店格扩展（多选商品 + 独立 UI 面板）
4. 阵亡单位跨层复活机制

---

## Codex 复审标注

- 判断依据：AI 贴图为高耸 3D 方块（TILE_FULL_H=192，方块体高度远超菱形面），导致棋盘渲染为积木墙。用户明确要求回退。
- 选择方案：程序化菱形渲染（最保守方案），保留等距坐标系和相机跟随，仅替换贴图绘制层。后续如有合适的扁平贴图素材可随时替换回去。
