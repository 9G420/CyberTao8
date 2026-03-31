# CyberTao: Dice Beast Protocol — 交接包

**生成时间**: 2026-03-31
**当前版本**: v0.1.60
**分支**: codex/dice-beast-protocol

---

## 1. 此刻的精确状态（一句话）

v0.1.60 完成相机跟随玩家角色（动态 iso_origin）+全新AI赛博朋克素材（11张 Nano Banana Pro 等距贴图）+UI优化（边缘渐暗+角色放大+面板调整），等距贴图棋盘 TILE_W=192 溢出视口实现沉浸感，美化 Phase 1~6 全部完成，音效系统+UI过渡动画+层间难度递增均已接入，棋盘层和卡牌层全部稳定，下一步是相机平滑过渡和商店格扩展。

---

## 2. 本账号完成的工作

| 版本 | 任务 | 状态 |
|------|------|------|
| v0.1.55 | 美化 Phase 4.2：UITransitions + 面板缓动动画 + 召唤展开演出 | 完成 |
| v0.1.56 | 美化 Phase 5：AudioManager + SFXGenerator + 全局音效接入 + BGM切换 | 完成 |
| v0.1.57 | 层间难度递增（current_floor 缩放敌方 HP/ATK） | 完成 |
| v0.1.58 | 美化 Phase 6：IsoTileRenderer + 等距贴图棋盘 + BoardView 等距化 | 完成 |
| v0.1.59 | 全屏等距棋盘 + 叠层UI + 高起贴图 + 角色放大 | 完成 |
| v0.1.60 | 相机跟随玩家角色 + 全新素材 + UI优化 | 完成 |

---

## 3. 最后版本关键变更

**版本号**: v0.1.60

**修改文件**:
- `Scripts/UI/IsoTileRenderer.gd` — 全面重写：TILE_W=192 + 新常量体系 + calc_origin_for_cell() 相机跟随 + 11 张新素材路径（英文命名）
- `Scripts/UI/BoardView.gd` — 新增 camera_cell + set_camera_target() + 动态 iso_origin + clip_contents + 边缘渐暗渲染
- `Scripts/Main.gd` — 新增 _update_camera_to_player() + _on_move_completed_camera() + 重开/传送/层切换时更新相机
- `Scripts/UI/UnitRenderer.gd` — 等距 scale 0.9→1.1 + HP条宽 60→72 + 选中环半径 24→30 + Y偏移 -16→-20
- `Scripts/UI/DiceDebugPanel.gd` — 面板宽度 232→220 + 圆角 6→8 + alpha 0.75→0.80
- `Scripts/UI/CyberBackground.gd` — 移除棋盘发光边框和角标绘制（相机跟随模式下棋盘超出视口）
- `Assets/Tiles/*.png` — 删除所有旧素材，重新生成 11 张全新贴图（Nano Banana Pro）

**新增接口**:
- `IsoTileRenderer.calc_origin_for_cell(cell, screen_center)` — 反推 iso_origin 使指定格子映射到屏幕中心
- `BoardView.camera_cell: Vector2i` — 相机跟随目标格
- `BoardView.set_camera_target(cell)` — 设置相机跟随目标
- `Main._update_camera_to_player()` — 更新相机到玩家位置
- `Main._on_move_completed_camera()` — move_completed 信号回调更新相机

**遗留问题**:
- 相机跟随暂为瞬间跳转，无平滑 Tween 过渡
- 阵亡单位跨层不复活
- CardRewardPanel 暂未使用 CardRenderer 风格
- 扇形手牌暂无拖拽机制（仅点击出牌）
- 角色立绘/棋盘角色为程序化绘制（后续可考虑专用贴图）
- SettingsPanel 暂未添加音量/音效开关控件
- 路径格无专属贴图（仍使用程序化菱形叠层）

---

## 4. 下一步任务（精确到可以直接开始）

**立刻要做的**:
在 `BoardView.gd` 的 `set_camera_target(cell)` 方法中，将 iso_origin 的瞬间赋值改为 Tween 插值（create_tween().tween_property()），实现相机平滑跟随。需注意：连续移动时 kill 旧 Tween 防止堆叠，Tween 期间 screen_to_grid 坐标转换需使用当前实际 iso_origin。

**任务队列**:
1. **相机跟随平滑过渡** — Tween 插值 iso_origin
2. **商店格扩展** — 多选商品 + 独立 UI 面板
3. **阵亡单位跨层复活机制** — 防止后续层无伙伴可用
4. **SettingsPanel 音量控件** — 添加音量滑块 + SFX/BGM 开关

---

## 5. 当前未解决问题清单

| 问题 | 严重程度 | 是否阻塞 | 建议处理时机 |
|------|----------|----------|--------------|
| 相机跟随瞬间跳转（无平滑过渡） | 中 | 否 | P0 下一步 |
| 阵亡单位跨层不复活（可能导致后续层过难） | 低 | 否 | 数值调优轮次 |
| CardRewardPanel 未使用 CardRenderer 风格 | 低 | 否 | UI 统一轮次 |
| 电弧牌 ATK-1 效果仅单场生效 | 低 | 否 | 卡牌数据重构时 |
| 升级数值未经平衡测试 | 低 | 否 | 数值调优轮次 |
| BattleFlowController 693行（多层地图后增长） | 中 | 否 | 下次大功能前考虑瘦身 |
| 扇形手牌无拖拽（仅点击） | 低 | 否 | 交互体验优化时 |
| SettingsPanel 无音量控件 | 低 | 否 | 体验打磨轮次 |

---

## 6. 新账号启动指令

```bash
git clone https://github.com/9G420/CyberTao8.git
cd CyberTao8
git checkout codex/dice-beast-protocol
git pull origin codex/dice-beast-protocol
```

然后按顺序阅读：
1. `Logs/AI_Employee_Guide_v3.md`（本上岗指令）
2. 本文件（已在读）
3. `Logs/CyberTao_Migration_Snapshot_zh_v3.md`
4. `Logs/Mulerun_Work_Report.md`

读完输出【上岗确认】，等用户确认后再开始工作。

---

## 7. 给下一个账号的备注

- `IsoTileRenderer.gd` v0.1.60 全面重写，`calc_origin_for_cell()` 是相机跟随的核心方法——反推 iso_origin 使指定格子映射到屏幕中心 (640,360)
- `BoardView.gd` 的 `iso_origin` 从 v0.1.58 的固定值变为 v0.1.60 的动态计算，所有依赖等距坐标的方法（screen_to_grid、grid_to_screen、绘制）都通过 iso_origin 间接获取相机位置
- 相机跟随暂为瞬间跳转（直接赋值 iso_origin），平滑过渡是 P0 任务——在 `set_camera_target` 中加 Tween 即可，但要注意连续移动时 kill 旧 Tween
- `BoardView.clip_contents=true` 裁剪溢出视口的棋盘，`_draw_edge_vignette()` 四边 80px 渐暗带柔化边界
- TILE_W=192 使 8 格棋盘宽度 1536px，溢出 1280px 视口约 128px/侧——这是设计意图，不是 bug
- `AudioManager` 和 `SFXGenerator` 均使用 class_name 全局注册，音效触发集中在 Main.gd 信号回调中
- `UITransitions` 的 `close()` 完成后自动复位 scale/modulate，防止残留状态
- `BoardGenerator._floor_scaling()` 控制层间难度：第2层 HP×1.3/ATK+1，第3层 HP×1.6/ATK+2
- `Assets/Tiles/` 下 11 张贴图全部为 v0.1.60 新生成（Nano Banana Pro），统一英文命名
- AI_Employee_Guide_v3.md 是**每轮强制更新**的（三件套：Work Report + Changelog + Guide），忘记更新等同于未完成任务
