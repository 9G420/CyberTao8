# Mulerun 工作报告

**日期**: 2026-04-01
**版本**: v0.1.77
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.77：3D 单位精灵化 — billboard Sprite3D 替代简单几何体

---

## 根因目标

v0.1.71 引入 3D 棋盘视图后，单位使用 CapsuleMesh（玩家）和 CylinderMesh（敌方）作为占位表示。虽然功能完备，但视觉上缺乏角色辨识度，与项目已有的刀盾狗 4 方向 spritesheet（v0.1.70）资源脱节。本轮将 3D 单位从简单几何体升级为 billboard Sprite3D：玩家英雄使用现有 spritesheet（支持行走帧动画），敌方和召唤伙伴使用程序化生成的赛博朋克风格图标。

服务层：3D 表现层（视觉升级）

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/UI3D/UnitMeshFactory3D.gd` | 完整重写（133→250 行）：CapsuleMesh/CylinderMesh → billboard Sprite3D；新增 spritesheet 纹理缓存、程序化图标生成、精灵朝向/帧动画接口 |
| `Scripts/UI3D/BoardView3D.gd` | 新增精灵动画变量和 `_update_sprite_animation()`；`play_move_step()` 检测方向并设置精灵朝向；`_on_move_step_finished()` 重置待机姿态（701→736 行） |
| `Scripts/UI/DiceDebugPanel.gd` | 版本标记 v0.1.76 → v0.1.77 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.77 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号 + §2.2/§3.1/§5/§6 更新 |
| `Logs/Handoff_Package_latest.md` | 覆盖为 v0.1.77 交接包 |

---

## 实现内容

### 玩家英雄精灵（billboard spritesheet）

- 使用 `Sprite3D` 节点替代 `CapsuleMesh`，设置 `billboard = BILLBOARD_ENABLED`
- 加载现有 4 方向 spritesheet（`刀盾向上/下/左/右走.png`）
- `region_enabled = true`，通过 `region_rect` 选择当前帧
- `alpha_cut = ALPHA_CUT_DISCARD`（gl_compatibility 兼容），阈值 0.4
- `pixel_size = 0.002`，使精灵宽度约 1.5 世界单位（略小于一格）
- 默认显示"朝下"方向第 0 帧（待机姿态）

### 精灵行走动画

- `play_move_step()` 调用 `PlayerSpriteAnimator.direction_from_cells()` 检测移动方向
- `UnitMeshFactory3D.set_sprite_direction()` 切换对应方向的 spritesheet 纹理
- `_update_sprite_animation()` 在 `_process()` 中以 10fps（100ms/帧）推进帧索引
- 每 15 帧循环（与 2D PlayerSpriteAnimator 完全一致）
- `_on_move_step_finished()` 调用 `reset_sprite_idle()` 恢复待机姿态

### 敌方单位图标（程序化生成）

- 128×128 分辨率，`pixel_size = 0.01`（约 1.28 世界单位）
- 红色菱形形状 + 发光边缘 + 中心高亮核心
- 外层渐隐光晕（赛博朋克发光效果）
- 使用 `Image.create()` + `ImageTexture.create_from_image()` 程序化生成
- 缓存为静态变量，仅生成一次

### 召唤伙伴图标（程序化生成）

- 青色圆形形状（与敌方菱形区分）
- 同样的发光边缘 + 中心高亮处理
- 视觉上与 CyberStyle.ACCENT_CYAN 风格一致

### 设计取舍

- 使用 `ALPHA_CUT_DISCARD` 而非 `OPAQUE_PREPASS`，确保 gl_compatibility 渲染器兼容
- 敌方/召唤使用程序化图标而非外部资源，避免资源缺失问题，后续可替换为实际美术资源
- spritesheet 背景透明度问题（v0.1.70 遗留）可能影响精灵边缘效果，alpha_scissor_threshold = 0.4 做了初步缓解
- 修复了 is_summoned 检测：改为检查 tags 数组中的 "summoned" 标记（原实现检查不存在的 "is_summoned" 字段）

---

## 接口变更

- **UnitMeshFactory3D 新增静态方法**：
  - `is_spritesheet_unit(node) -> bool` — 判断是否为 spritesheet 精灵
  - `set_sprite_direction(node, dir)` — 设置精灵朝向
  - `set_sprite_frame(node, dir, frame_index)` — 设置精灵帧
  - `reset_sprite_idle(node)` — 重置待机姿态
- **UnitMeshFactory3D 移除**：`_create_body_mesh()` → 替换为 `_create_body_sprite()`
- **UnitMeshFactory3D 移除**：`_get_unit_color()` / `_get_unit_emission()`（程序化几何体配色，不再需要）
- **BoardView3D 新增内部方法**：`_update_sprite_animation(delta)`
- **无外部信号变更**

---

## 测试确认

### 自查闭环（代码审查）

| 测试项 | 结果 |
|--------|------|
| 掷骰 → 移动 → 攻击 → 召唤 | ✅ 单位创建/移动/攻击反馈不涉及 Body 节点类型 |
| 敌方回合 → 镜头跟随 | ✅ 不涉及 |
| 遭遇触发 → 卡牌战斗 → 选牌奖励 → HP同步回棋盘 | ✅ 不涉及 |
| 重新开始（restart_battle） | ✅ rebuild_board() → _refresh_units() 重新创建所有单位节点 |
| 胜负判定 | ✅ 不涉及 |
| HP 条更新 | ✅ update_hp_bar() 未修改，仍通过 "HPBar" 子节点名访问 |
| 玩家精灵行走动画 | ✅ play_move_step 设方向 + _process 推帧 + 结束重置 |
| 敌方移动（move_step_visual） | ✅ 敌方精灵不是 spritesheet，is_spritesheet_unit 返回 false，不执行帧动画 |
| 3D 反馈系统（v0.1.74） | ✅ 反馈方法不依赖 Body 节点类型 |
| create_unit_node 签名兼容 | ✅ 返回 Node3D，子节点名 "Body"/"HPBar" 不变 |

---

## 剩余问题

- spritesheet 背景透明度（v0.1.70 遗留）— alpha_scissor_threshold 做了初步缓解
- DiceDebugPanel 仍绑定 2D BoardView（v0.1.71 遗留）
- ATK/DEF 商店提升未走 BuffManager（v0.1.73 设计取舍）
- BoardView3D.rebuild_board() 全量重建（大棋盘性能开销）
- 复活/回复数值未经平衡测试
- 敌方/召唤单位使用程序化图标，无独立美术资源

---

## 建议下一步

1. 商品池扩展（加新牌/移除诅咒/随机 crest 等）
2. 卡牌战斗层深化（新卡牌效果/新敌方行为模式）
3. 敌方单位美术资源（替换程序化图标为独立 spritesheet）

## Codex 复审标注（可选）

- `alpha_cut = ALPHA_CUT_DISCARD` + `alpha_scissor_threshold = 0.4` 是 gl_compatibility 下处理透明精灵的推荐方案。如果精灵边缘出现锯齿或裁切过度，可调整阈值（降低 = 更多半透明边缘保留，但可能出现 Z-fighting）。
- 程序化图标使用 `Image` 像素级绘制，首次调用 `_ensure_textures()` 时会有一次性开销（两个 128×128 图标 + 4 次 texture load），之后缓存到静态变量。
- 敌方菱形 / 召唤圆形的形状选择是为了在 3D 场景中快速区分单位阵营，即使在远景缩放下也能辨认。后续替换为美术资源只需修改 `_create_body_sprite()` 中的纹理分支。
