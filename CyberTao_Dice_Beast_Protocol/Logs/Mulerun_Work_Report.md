# Mulerun 工作报告

**日期**: 2026-03-31
**版本**: v0.1.60
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.60：相机跟随玩家角色 + 全新素材重生成 + UI 界面优化

---

## 根因目标

用户反馈 v0.1.59 界面仍然不够好看，核心问题是 8x8 棋盘格在全屏下仍然能看到明显的边界（TILE_W=144 只覆盖 1152px，不足 1280px 视口宽度）。用户明确要求：
1. 以玩家控制角色为中心，画面铺满整个屏幕看不到棋盘边界
2. 删除所有旧素材，重新设计生成
3. UI 界面重新设计
4. 参考 Mythmatic 风格的游戏界面

本轮目标：实现相机跟随系统（动态 iso_origin）、TILE_W 放大至 192px（棋盘溢出视口）、全新 AI 素材、UI 面板优化。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/UI/IsoTileRenderer.gd` | 全面重写：TILE_W=192 + 新常量体系 + calc_origin_for_cell() 相机跟随 + 11 张新素材路径（英文命名）|
| `Scripts/UI/BoardView.gd` | 新增 camera_cell + set_camera_target() + 动态 iso_origin + clip_contents + 边缘渐暗渲染 |
| `Scripts/Main.gd` | 新增 _update_camera_to_player() + _on_move_completed_camera() + 重开/传送/层切换时更新相机 |
| `Scripts/UI/UnitRenderer.gd` | 等距 scale 0.9→1.1 + HP条宽 60→72 + 选中环半径 24→30 + Y偏移 -16→-20 |
| `Scripts/UI/DiceDebugPanel.gd` | 面板宽度 232→220 + 圆角 6→8 + alpha 0.75→0.80 + 版本标记 v0.1.60 |
| `Scripts/UI/CyberBackground.gd` | 移除棋盘发光边框和角标绘制（相机跟随模式下棋盘超出视口） |
| `Assets/Tiles/*.png` | 删除所有旧素材（含中文命名+v0.1.59 elevated 文件），重新生成 11 张全新贴图（Nano Banana Pro） |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.60 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号+完成列表+架构+任务优先级 |

---

## 实现内容

### 相机跟随系统

- IsoTileRenderer 新增 `calc_origin_for_cell(cell, screen_center)` 静态方法：反推 iso_origin 使指定格子映射到屏幕中心
- BoardView 新增 `camera_cell: Vector2i` 和 `set_camera_target(cell)` 方法
- iso_origin 从固定值 (640,72) 变为动态计算：`IsoTileRenderer.calc_origin_for_cell(camera_cell, Vector2(640,360))`
- Main.gd 在以下时机更新相机目标：
  - 游戏启动 (`_ready`)
  - 玩家单位移动 (`_on_move_requested` + `_on_move_completed_camera`)
  - 传送 (`_on_hero_warped`)
  - 重新开始 (`_on_restart_pressed`)
  - 层间切换 (`_on_card_battle_ended` 中 floor_clear_pending 分支)

### 棋盘溢出视口

- TILE_W 从 144 放大至 192（8格宽 = 1536px，溢出 1280px 视口约 128px/侧）
- TILE_H_HALF=48，格子行步进 48px（8格高 = 768px，溢出 720px 视口约 24px/侧）
- 玩家角色始终在屏幕中心，棋盘边缘自然延伸至屏幕外
- BoardView 启用 clip_contents=true 裁剪溢出部分

### 边缘渐暗

- BoardView._draw_edge_vignette()：四边 80px 宽渐暗带，8 级透明度递减
- 柔化棋盘边界，营造沉浸感

### 全新素材

- 删除所有旧 PNG 文件（含中文命名的平面贴图和 v0.1.59 的 elevated 贴图）
- 使用 Nano Banana Pro AI 重新生成 11 张赛博朋克风格等距方块贴图
- 统一英文命名：normal_light/dark, high_ground, trap, encounter, heal, item, shop, chest, event, portal

### 角色可见性提升

- UnitRenderer 等距 scale 从 0.9 提升至 1.1（~22% 放大）
- HP 条宽度从 60px 增至 72px
- 选中脉冲环半径从 24 增至 30
- 角色 Y 偏移从 -16 调整为 -20

### UI 面板优化

- DiceDebugPanel 宽度从 232 缩至 220，圆角增大至 8px
- 面板透明度从 0.75 提升至 0.80（更好可读性）
- CyberBackground 移除棋盘边框/角标（相机跟随下无意义）
- DiceDebugPanel 位置从 (1040,8) 调整至 (1052,8)

---

## 接口变更

- `IsoTileRenderer.TILE_W`: 144→192
- `IsoTileRenderer.TILE_H_DIAMOND`: 72→96
- `IsoTileRenderer.TILE_H_HALF`: 36→48
- `IsoTileRenderer.TILE_FULL_H`: 144→192
- `IsoTileRenderer.TILE_ELEVATED_H`: 192→256
- `IsoTileRenderer.ELEVATION_OFFSET`: 48→64
- `IsoTileRenderer.calc_origin_for_cell(cell, screen_center)`: 新增静态方法
- `BoardView.camera_cell`: 新增，Vector2i 类型
- `BoardView.SCREEN_CENTER`: 新增常量，Vector2(640, 360)
- `BoardView.set_camera_target(cell)`: 新增方法
- `BoardView.iso_origin`: 从固定值变为动态计算
- `Main._update_camera_to_player()`: 新增方法
- `Main._on_move_completed_camera()`: 新增 move_completed 信号回调
- `UnitRenderer.draw_full_unit_iso`: scale 0.9→1.1, HP条宽 60→72, 环半径 24→30
- `DiceDebugPanel.size`: (232,700)→(220,680)

---

## 测试确认

- 相机跟随：玩家移动后棋盘视角自动居中到玩家位置
- 棋盘溢出：居中在内部格子时，看不到棋盘四个角（被视口裁剪）
- 边缘渐暗：四边渐暗效果柔化视觉边界
- 等距贴图 11 张正确加载和绘制（TILE_W=192）
- 高起贴图正确堆叠（TILE_ELEVATED_H=256，ELEVATION_OFFSET=64）
- painter's algorithm 遮挡正确
- 点击菱形格子正确转换为格坐标（screen_to_grid 适配动态 iso_origin）
- 角色 scale 1.1 在全屏棋盘上更加清晰
- DiceDebugPanel 220px 面板布局正常
- 重新开始后相机正确重置到玩家位置
- 层间切换后相机正确跟随到新层玩家位置
- 传送后相机正确跟随到目标位置
- 遭遇触发→卡牌战斗→返回棋盘流程正常
- 掷骰演出在全屏中心正常播放

---

## 剩余问题

- 阵亡单位跨层不复活
- CardRewardPanel 暂未使用 CardRenderer 风格
- 扇形手牌暂无拖拽机制（仅点击出牌）
- 角色立绘为程序化绘制（后续可考虑专用等距角色贴图）
- SettingsPanel 暂未添加音量/音效开关控件
- 路径格无专属贴图（仍使用程序化菱形叠层）
- 相机跟随暂无平滑过渡动画（瞬间跳转）

---

## 建议下一步

1. 相机跟随平滑过渡（Tween 插值 iso_origin，而非瞬间跳转）
2. 商店格扩展（多选商品 + 独立 UI 面板）
3. 阵亡单位跨层复活机制
4. SettingsPanel 添加音量滑块 + SFX/BGM 开关
5. 等距角色专属贴图（替代程序化剪影）
