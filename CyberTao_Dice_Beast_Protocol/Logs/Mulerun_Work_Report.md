# Mulerun 工作报告

**日期**: 2026-03-31
**版本**: v0.1.58
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.58：美化 Phase 6 — 等距棋盘贴图替换（IsoTileRenderer + BoardView 等距化 + UnitRenderer 等距适配）

---

## 根因目标

AI_Employee_Guide_v3 §6 长期方向「美化 Phase 6：2.5D 棋盘」。当前棋盘使用程序化绘制的正方形格子（BoardCellRenderer），视觉上是纯 2D 平面棋盘。本轮目标：利用已提交的 9 张等距方块贴图（Assets/Tiles/），将棋盘从正方形网格替换为等距菱形贴图渲染，实现 2.5D 视觉升级，同时保证点击检测、高亮、单位定位、反馈动画全部适配等距坐标。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/UI/IsoTileRenderer.gd` | 新增：等距棋盘贴图渲染器（贴图加载/缓存、格坐标↔屏幕坐标转换、painter's algorithm 绘制、菱形高亮/角标辅助） |
| `Scripts/UI/BoardView.gd` | 重写：_ready 尺寸适配等距、_pixel_to_cell 等距逆变换、_draw_layer_grid 调用 IsoTileRenderer、_draw_layer_overlays 菱形叠层、_draw_layer_highlights 菱形高亮、_draw_layer_units 等距定位、_draw_attack_flash 菱形闪光、7个反馈方法等距坐标 |
| `Scripts/UI/UnitRenderer.gd` | 新增：draw_full_unit_iso / draw_affinity_star_iso 等距专用绘制（0.55缩放+菱形中心定位，立绘不变） |
| `Scripts/Main.gd` | CyberBackground 尺寸适配 576×350、summon_completed 使用 IsoTileRenderer 坐标 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.58 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号+完成列表+架构+任务优先级 |

---

## 实现内容

### IsoTileRenderer.gd（新增，~145行）

| 功能 | 说明 |
|------|------|
| 贴图缓存 | 9张等距方块贴图按 key 加载缓存（lazy load） |
| grid_to_screen | 格坐标→屏幕坐标：sx = origin.x + (gx-gy)*TILE_W/2, sy = origin.y + (gx+gy)*TILE_H_HALF |
| screen_to_grid | 屏幕坐标→格坐标（逆变换+四舍五入） |
| diamond_points | 菱形顶面四顶点（用于高亮/叠层） |
| draw_board | painter's algorithm 按 depth=gx+gy 从后向前绘制整张棋盘 |
| draw_diamond_highlight | 菱形半透明填充+边框高亮 |
| draw_diamond_corners | 菱形 L 角标（移动高亮用） |

### 等距参数

| 参数 | 值 | 说明 |
|------|-----|------|
| TILE_W | 72 | 菱形宽度（像素） |
| TILE_H_DIAMOND | 36 | 菱形高度 = TILE_W/2 |
| TILE_H_HALF | 18 | 菱形半高 = 行步进 |
| TILE_FULL_H | 72 | 贴图完整高度（含方块体） |
| iso_origin | (288, 30) | 棋盘原点（菱形顶端中心） |
| 控件尺寸 | 576×350 | 等距棋盘占用区域 |

### BoardView.gd 改动要点

| 方法 | 改动 |
|------|------|
| _ready | size 576×576 → 576×350 |
| _pixel_to_cell | 正方形网格除法 → IsoTileRenderer.screen_to_grid |
| _draw_layer_grid | BoardCellRenderer.draw_base_cell 循环 → IsoTileRenderer.draw_board |
| _draw_layer_overlays | Rect2 覆盖层 → 菱形中心居中文字/符号（BOSS/LOCKED/?/回复量/商店/道具/路径/传送门） |
| _draw_layer_highlights | 正方形 L 角标/准星 → 菱形 diamond_corners/diamond_highlight |
| _draw_layer_units | cell×CELL_SIZE → IsoTileRenderer.grid_to_screen + depth排序 |
| _draw_attack_flash | 正方形白闪 → 菱形白闪 |
| 7个反馈方法 | cell×CELL_SIZE 偏移 → _iso_cell_center 定位 |

### UnitRenderer.gd 新增

| 方法 | 说明 |
|------|------|
| draw_full_unit_iso | 以屏幕中心点定位、0.55 缩放、角色上移 10px 站立在菱形上 |
| draw_affinity_star_iso | 适性星标在等距位置 |

### Main.gd 改动

| 改动 | 说明 |
|------|------|
| CyberBackground | set_board_rect 576×576 → 576×350 |
| _on_summon_completed | pixel_pos 改用 IsoTileRenderer.grid_to_screen |

---

## 接口变更

- `IsoTileRenderer`（新增 class_name 全局注册）：所有静态方法
- `BoardView.iso_origin: Vector2` — 新增公开变量，等距原点坐标
- `BoardView._iso_cell_center(cell)` — 新增辅助方法
- `BoardView._draw_iso_label(center, text, col, font, font_size)` — 新增菱形居中文字绘制
- `UnitRenderer.draw_full_unit_iso(c, center, unit, is_selected, pulse, idle_y, font)` — 新增
- `UnitRenderer.draw_affinity_star_iso(c, center, unit, board_mgr, cell, font)` — 新增
- 原有 `draw_full_unit` / `draw_affinity_star` 保留不动，旧代码兼容

---

## 测试确认

- 等距贴图 9 张按格子类型正确加载和绘制
- painter's algorithm 遮挡正确（depth=gx+gy 从后向前）
- 点击菱形格子正确转换为格坐标（screen_to_grid 逆变换）
- 移动/攻击/召唤高亮使用菱形而非正方形
- 单位按等距位置绘制，缩放 0.55 适配菱形格
- 攻击闪光、伤害飘字、拾取/回复/事件/商店/宝箱反馈均在等距位置
- 遭遇触发→卡牌战斗→返回棋盘流程正常
- 层间通关→下一层→重新开始流程正常
- 召唤展开演出使用等距坐标
- BoardCellRenderer 不再用于基础格绘制，但保留文件（叠层符号仍可参考）

---

## 剩余问题

- 阵亡单位跨层不复活
- CardRewardPanel 暂未使用 CardRenderer 风格
- 扇形手牌暂无拖拽机制（仅点击出牌）
- 角色立绘为程序化绘制（0.55 缩放后较小，后续可考虑专用等距角色贴图）
- SettingsPanel 暂未添加音量/音效开关控件
- 事件格/路径格/传送门格无专属贴图，仍使用程序化叠层

---

## 建议下一步

1. 商店格扩展（多选商品 + 独立 UI 面板）
2. 阵亡单位跨层复活机制
3. SettingsPanel 添加音量滑块 + SFX/BGM 开关
4. 等距角色专属贴图（替代 0.55 缩放的程序化剪影）
