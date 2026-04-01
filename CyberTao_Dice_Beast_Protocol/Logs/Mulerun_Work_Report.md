# Mulerun 工作报告

**日期**: 2026-04-01
**版本**: v0.1.81
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.81：全单位程序化 BGA 宝可梦像素风格重构 — 移除所有 spritesheet 外部美术资源依赖，所有单位（玩家英雄/7种敌方+Boss/召唤伙伴）均使用程序化像素风格生成

---

## 根因目标

用户明确指示：取消敌方美术资源任务、取消玩家角色 spritesheet 素材，全部改回程序化设计，参考 BGA 宝可梦像素角色怪物设计来替换。暂时不使用任何外部美术资产。

本轮将 UnitMeshFactory3D 从"玩家用 spritesheet + 敌方用简单几何图标"重构为"全单位使用程序化 BGA 宝可梦像素风格生成"。同时移除 BoardView3D 中已无用的 spritesheet 帧动画系统。

服务层：3D 表现层 / 美术资源层

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/UI3D/UnitMeshFactory3D.gd` | 完全重写：移除 spritesheet 加载（4方向 PNG）和简单几何图标，新增 BGA 宝可梦像素风格程序化生成器（1 玩家英雄 + 7 遭遇敌方 + 1 Boss + 1 召唤伙伴 + 1 默认敌方）。32×32 逻辑像素网格，含发光轮廓。统一 pixel_size 为 0.009 |
| `Scripts/UI3D/BoardView3D.gd` | 移除精灵帧动画系统（_sprite_anim_accum / _sprite_frame_idx / _sprite_move_dir 变量、_update_sprite_animation() 方法、play_move_step 和 _on_move_step_finished 中的 spritesheet 逻辑）|
| `Scripts/UI/DiceDebugPanel.gd` | 版本标记 → v0.1.81 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.81 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号 + §2.2/§3.1/§6 更新 |
| `Logs/Handoff_Package_latest.md` | 覆盖为 v0.1.81 交接包 |

---

## 实现内容

### UnitMeshFactory3D 重构

**移除**:
- 4 方向 spritesheet 加载（刀盾向X走.png × 4）
- `_player_textures`、`_player_frame_sizes` 缓存
- `is_spritesheet_unit()`、`set_sprite_direction()`、`set_sprite_frame()`、`reset_sprite_idle()` 方法
- `COLUMNS`、`TOTAL_FRAMES`、`PLAYER_PIXEL_SIZE`、`ICON_PIXEL_SIZE` 常量
- 旧版 `_generate_icon()` 简单几何图标生成器

**新增**:
- 绘图原语系统：`_px()` 逻辑像素块（4×4 实际像素）、`_fill_rect_l()` 逻辑矩形、`_fill_ellipse_l()` 逻辑椭圆、`_apply_glow()` 发光轮廓
- 12 个独立程序化像素生物生成器：
  - `_gen_player_hero()` — 刀盾狗：蓝色赛博犬战士，大头比例，刀+盾+护甲
  - `_gen_summoned_ally()` — 赛博小精灵：青色飞行小伙伴
  - `_gen_enc01_sentinel()` — 异常哨兵：红色方形机器人
  - `_gen_enc02_ghost()` — 赛博游魂：紫色飘浮幽灵（渐隐底部）
  - `_gen_enc03_crawler()` — 暗网爬虫：绿色多腿蜘蛛
  - `_gen_enc04_hunter()` — 脉冲猎手：橙色流线型猎食者
  - `_gen_enc05_phantom()` — 数据幽灵：灰蓝色兜帽幽影
  - `_gen_enc06_splitter()` — 量子分裂体：紫色菱形晶体生物
  - `_gen_enc07_shaman()` — 赛博巫医：绿色兜帽治疗者+法杖
  - `_gen_boss_zero()` — 零号协议：大型暗红铠甲实体，角+核心发光
  - `_gen_enemy_default()` — 默认回退敌方
- 按 encounter_id 延迟生成 + 缓存（`_get_enemy_tex()`）
- 统一 SPRITE_PIXEL_SIZE = 0.009（所有单位相同大小）

### BoardView3D 精简

- 移除 `_sprite_anim_accum`、`_sprite_frame_idx`、`_sprite_move_dir` 变量
- 移除 `_update_sprite_animation(delta)` 方法
- `play_move_step()` 精简：不再设置精灵方向和帧
- `_on_move_step_finished()` 精简：不再重置精灵帧

---

## 接口变更

**移除**（UnitMeshFactory3D）:
- `static func is_spritesheet_unit(node: Node3D) -> bool` — 不再有 spritesheet 单位
- `static func set_sprite_direction(node: Node3D, dir: String) -> void`
- `static func set_sprite_frame(node: Node3D, dir: String, frame_index: int) -> void`
- `static func reset_sprite_idle(node: Node3D) -> void`
- `const COLUMNS`、`TOTAL_FRAMES` — 帧动画参数

**保留不变**:
- `static func create_unit_node()` — 签名不变
- `static func update_unit_position()` — 签名不变
- `static func update_hp_bar()` — 签名不变

---

## 测试确认

### 自查闭环

| 测试项 | 结果 |
|--------|------|
| UnitMeshFactory3D 无外部资源引用 | ✅ 不再 load() 任何 PNG |
| 所有 12 种生物生成器有实际绘图代码 | ✅ |
| _create_body_sprite 按 owner/tags/encounter_id 路由 | ✅ |
| 纹理缓存避免重复生成 | ✅ _tex_cache + _get_enemy_tex |
| BoardView3D 不再引用已移除的 spritesheet API | ✅ |
| HP 条逻辑保持不变 | ✅ |
| create_unit_node 接口签名不变 | ✅ |

---

## 剩余问题

- 单位均为静态贴图（无行走帧动画）— 视觉效果降级但符合用户"程序化设计"的要求
- 如需行走动画，可后续实现简单的上下弹跳 tween（不需要 spritesheet）
- PlayerSpriteAnimator.gd 文件仍存在但不再被引用（可在清理轮次移除）
- 电弧 ATK-1 效果永久（单场内，设计取舍）
- remove_card 自动选择最弱牌（无手动选择UI）

---

## 建议下一步

1. 商店 remove_card 手动选择UI
2. 更多遭遇/Boss 丰富战斗多样性
3. 如需行走动画：可给移动中的单位添加简单弹跳 tween 效果（无需 spritesheet）
