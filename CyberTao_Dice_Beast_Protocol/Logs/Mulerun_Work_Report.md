# Mulerun 工作报告

**日期**: 2026-04-02
**版本**: v0.1.88
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.88：优化 3D 棋盘视觉（功能格立体感 + 单位可见性）并新增 2D/3D 切换炫光特效

---

## 根因目标

用户反馈：
1) 3D 模式功能格缺乏立体感；
2) 场上单位发黑、看不清；
3) 2D/3D 切换没有炫酷过渡。

目标：先修可用性和辨识度，再加切换视觉反馈。

服务层：3D 表现层（UnitMeshFactory3D/TileMeshFactory3D）+ 主场景切换表现层（Main）

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/UI3D/UnitMeshFactory3D.gd` | 放宽 alpha 剪裁阈值；强制白色 modulate；纹理为空时兜底默认敌方纹理，避免黑块不可见 |
| `Project/Scripts/UI3D/TileMeshFactory3D.gd` | 新增 `_get_tile_lift(tile_key)`，给功能格增加额外高度，增强立体辨识 |
| `Project/Scripts/Main.gd` | 新增 `_view_switch_fx` 覆盖层和 `_play_view_switch_fx()`，在 `toggle_3d_view()` 中触发迷幻霓虹切换特效 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.88 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号 + §2.2 完成状态 + §6 任务优先级 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |

---

## 实现内容

### 1) 单位可见性修复（3D）

- `alpha_scissor_threshold` 从 `0.4` 调到 `0.25`，减少纹理边缘被过度裁掉导致的黑块感。
- 强制 `sprite.modulate = Color(1,1,1,1)`，避免受异常色调影响。
- 新增兜底：若单位纹理为空，直接使用 `_gen_enemy_default()`，确保至少可见。

### 2) 功能格立体感增强

在 `TileMeshFactory3D` 增加按 tile_key 的抬升策略：
- `encounter / portal`：高抬升
- `shop/chest/item/event/heal/trap`：中抬升
- normal 保持平面

效果：功能格不再只是平涂色块，3D 下更容易一眼区分。

### 3) 2D/3D 切换特效

- Main 新增全屏 `ColorRect` 特效层（高 z-index）。
- 切换时触发 Tween：紫青炫光闪入再淡出（迷幻感过渡）。
- 不改变原有切换逻辑，仅增强过渡视觉体验。

---

## 接口变更

- 无公开信号/外部 API 变更。
- 仅内部表现层方法新增：`Main._play_view_switch_fx()`。

---

## 测试确认

| 测试项 | 结果 |
|--------|------|
| 3D 单位纹理为空时不再黑块消失（有兜底纹理） | ✅ |
| 3D 功能格出现明显高度层次差异 | ✅ |
| F5 切换 2D/3D 时出现炫光过渡，不影响功能 | ✅ |
| 2D 视图逻辑与输入不受影响 | ✅ |

---

## 剩余问题

- 当前切换特效是 ColorRect 级别，尚未上屏幕扭曲/色散 shader。
- 单位“黑色”若由显卡/驱动渲染差异引起，仍建议在你机器上实测确认。

---

## 建议下一步

1. 若你还想更炫：下一轮上 shader 级切换（色散 + 轻微屏幕扭曲 + 扫描线）。
2. 给功能格再加顶面图标（shop/chest/event），进一步增强远距辨识。
3. 单位可见性继续加强：加底部光圈（owner 区分色）和轮廓描边。
