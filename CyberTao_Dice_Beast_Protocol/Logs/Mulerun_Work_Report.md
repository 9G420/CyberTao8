# Mulerun 工作报告

**日期**: 2026-03-31
**版本**: v0.1.59
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.59：全屏等距棋盘视觉大改 — 棋盘铺满屏幕 + UI叠层化 + 角色放大 + 特殊格高起堆叠 + AI生成高起贴图

---

## 根因目标

用户反馈当前布局（v0.1.58）存在 4 个关键问题：
1. 棋盘仅占屏幕左侧约 45%，右侧大面板浪费空间
2. 角色在棋盘上几乎看不清（scale 0.55 太小）
3. 特殊格（高台/遭遇/回复等）没有视觉突起，与普通格无高度差异
4. 整体布局与参考游戏（Mythmatic）相比差距明显

本轮目标：将棋盘铺满 1280×720 全屏，UI 改为半透明叠加面板，角色放大至清晰可见，特殊格使用 AI 生成的高起贴图实现视觉堆叠。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/UI/IsoTileRenderer.gd` | 等距参数 2x 放大（TILE_W 144）+ 高起渲染（TILE_ELEVATED_H 192）+ 11张贴图路径（新增 event/portal）+ _get_tile_key 新增 portal/event 分支 |
| `Scripts/UI/BoardView.gd` | 全屏化 1280×720 + iso_origin (640,72) + 事件/传送门叠层简化 + 反馈飘字放大 + 攻击闪光适配 |
| `Scripts/UI/UnitRenderer.gd` | 等距角色 scale 0.55→0.9 + HP条宽 40→60 + 选中环半径 16→24 + 适性星标位置调整 |
| `Scripts/Main.gd` | 棋盘 (0,0) 全屏 + 移除标题栏 + DiceDebugPanel 叠加定位 (1040,8) + CyberBackground 全屏 + 掷骰演出中心 (640,360) |
| `Scripts/UI/DiceDebugPanel.gd` | 半透明叠加模式（StyleBoxFlat alpha=0.75）+ 宽度 280→232 + 布局紧凑化 + 版本标记 v0.1.59 |
| `Assets/Tiles/high_ground_elevated.png` | AI 生成：双层堆叠金色边缘等距方块 |
| `Assets/Tiles/encounter_elevated.png` | AI 生成：红色能量水晶信标等距方块 |
| `Assets/Tiles/heal_elevated.png` | AI 生成：蓝色全息医疗十字等距方块 |
| `Assets/Tiles/shop_elevated.png` | AI 生成：青色全息售卖终端等距方块 |
| `Assets/Tiles/chest_elevated.png` | AI 生成：金色宝箱等距方块 |
| `Assets/Tiles/item_elevated.png` | AI 生成：绿色数据方块等距方块 |
| `Assets/Tiles/event_tile.png` | AI 生成：紫色全息问号等距方块 |
| `Assets/Tiles/portal_tile.png` | AI 生成：青蓝色能量漩涡等距方块 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.59 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号+完成列表+架构+任务优先级 |

---

## 实现内容

### 全屏棋盘布局

- BoardView size 从 576×350 扩大至 1280×720，占满整个视口
- iso_origin 从 (288,30) 移至 (640,72)，棋盘在全屏范围内水平居中
- IsoTileRenderer TILE_W 从 72 放大至 144（2 倍），所有等距参数同步放大
- 移除 Main.gd 中的标题栏/副标题/提示条（腾出全部空间给棋盘）

### UI 叠层化

- DiceDebugPanel 改为半透明叠加面板（StyleBoxFlat bg_color alpha=0.75）
- 面板宽度从 280 缩至 232，定位在屏幕右侧 (1040,8)
- 设置按钮移至左上角 (8,8)
- 胜负标签/重新开始按钮居中于屏幕中央

### 角色可见性提升

- UnitRenderer 等距 scale 从 0.55 提升至 0.9（~64% 放大）
- HP 条宽度从 40px 增至 60px
- 选中脉冲环半径从 16 增至 24
- 角色 Y 偏移从 -10 调整为 -16（更好地站立在菱形上）

### 特殊格高起堆叠

- IsoTileRenderer 新增 TILE_ELEVATED_H=192 和 ELEVATION_OFFSET=48
- 8 种特殊格（high_ground/encounter/heal/shop/chest/item/event/portal）使用高起渲染
- 高起贴图绘制区域比普通格高 48px，视觉上呈现堆叠突起效果
- 8 张高起贴图由 Nano Banana Pro AI 生成（1K 分辨率，赛博朋克风格）

### 新增贴图路径

- event_tile.png：事件格专属贴图（紫色全息问号），不再需要程序化菱形叠层
- portal_tile.png：传送门专属贴图（青蓝能量漩涡），不再需要程序化菱形叠层
- _get_tile_key 新增 portal/event 优先级分支

---

## 接口变更

- `IsoTileRenderer.TILE_W`: 72→144
- `IsoTileRenderer.TILE_H_DIAMOND`: 36→72
- `IsoTileRenderer.TILE_H_HALF`: 18→36
- `IsoTileRenderer.TILE_FULL_H`: 72→144
- `IsoTileRenderer.TILE_ELEVATED_H`: 新增，值 192
- `IsoTileRenderer.ELEVATION_OFFSET`: 新增，值 48
- `IsoTileRenderer.ELEVATED_KEYS`: 新增，标记需要高起渲染的 tile key 集合
- `IsoTileRenderer.is_elevated(tile_key)`: 新增静态方法
- `IsoTileRenderer.TILE_PATHS`: 新增 "event" / "portal" 条目，更新 5 个特殊格路径为高起版本
- `BoardView.iso_origin`: (288,30)→(640,72)
- `BoardView.size`: (576,350)→(1280,720)
- `DiceDebugPanel.size`: (280,574)→(232,700)

---

## 测试确认

- 等距贴图 11 张（含 2 张新增）按格子类型正确加载和绘制
- 高起贴图正确堆叠（视觉上比普通格高出一截）
- painter's algorithm 遮挡正确（高起格不会被后方普通格遮挡）
- 点击菱形格子正确转换为格坐标（screen_to_grid 逆变换适配新参数）
- 移动/攻击/召唤高亮使用菱形且尺寸适配放大后的格子
- 角色 scale 0.9 在全屏棋盘上清晰可见
- DiceDebugPanel 半透明叠加正确，不遮挡棋盘核心区域
- 遭遇触发→卡牌战斗→返回棋盘流程正常
- 层间通关→下一层→重新开始流程正常
- 召唤展开演出使用等距坐标
- 掷骰演出在全屏中心正常播放

---

## 剩余问题

- 阵亡单位跨层不复活
- CardRewardPanel 暂未使用 CardRenderer 风格
- 扇形手牌暂无拖拽机制（仅点击出牌）
- 角色立绘为程序化绘制（后续可考虑专用等距角色贴图）
- SettingsPanel 暂未添加音量/音效开关控件
- 路径格无专属贴图（仍使用程序化菱形叠层）

---

## 建议下一步

1. 商店格扩展（多选商品 + 独立 UI 面板）
2. 阵亡单位跨层复活机制
3. SettingsPanel 添加音量滑块 + SFX/BGM 开关
4. 等距角色专属贴图（替代程序化剪影）
5. 路径格/trap格专属高起贴图
