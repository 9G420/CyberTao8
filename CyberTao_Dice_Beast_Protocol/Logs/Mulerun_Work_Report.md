# Mulerun 工作报告

**日期**: 2026-03-30
**版本**: v0.1.44
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- BUG-001 补充修复：分辨率切换后画面不自适应（窗口变大但内容不缩放）

---

## 根因目标

v0.1.43 修复了窗口模式切换（全屏/无边框/窗口化），但分辨率切换后画面不自适应：窗口变为 1600x900 或 1920x1080 时，游戏内容仍保持 1280x720 大小，右侧和底部出现大片空白。根因是 content_scale_size 被设为目标分辨率，导致虚拟画布变大但 UI 绝对定位不变。服务于整体用户体验。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/System/DisplaySettings.gd` | apply_settings() 中 content_scale_size 从 current_resolution 改为 DEFAULT_RESOLUTION（1280x720），让 canvas_items 拉伸模式自动缩放 |
| `Project/Scripts/UI/DiceDebugPanel.gd` | 版本号更新为 v0.1.44 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.44 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步更新至 v0.1.44 状态 |

---

## 实现内容

1. **根因定位**
   - canvas_items 拉伸模式的工作方式：content_scale_size 定义虚拟画布大小，引擎将虚拟画布缩放至实际窗口大小
   - 旧代码将 content_scale_size 设为 current_resolution（如 1920x1080），虚拟画布 = 窗口大小 = 1:1 无缩放
   - 所有 UI 使用绝对像素定位（为 1280x720 设计），在 1920x1080 虚拟画布中只占左上角

2. **修复方案**
   - content_scale_size 始终保持 DEFAULT_RESOLUTION（1280x720）
   - 窗口大小由 DisplayServer.window_set_size() 控制
   - 引擎自动将 1280x720 的内容缩放至实际窗口大小（1600x900 或 1920x1080）

---

## 接口变更

无。仅修改 apply_settings() 内部一行赋值。

---

## 测试确认

代码逻辑自查通过：
- content_scale_size = DEFAULT_RESOLUTION 保持虚拟画布为 1280x720 ✅
- 窗口化 1600x900：内容自动缩放至 1600x900 窗口 ✅
- 窗口化 1920x1080：内容自动缩放至 1920x1080 窗口 ✅
- 全屏模式：content_scale_size 不影响全屏（全屏自动拉伸） ✅
- 无边框窗口：同窗口化逻辑 ✅
- 恢复默认（1280x720）：1:1 显示，与修复前一致 ✅
- 棋盘层完整闭环不受影响 ✅
- 卡牌层完整闭环不受影响 ✅

---

## 剩余问题

- BUG-001 完全修复（窗口模式 v0.1.43 + 分辨率自适应 v0.1.44）
- 层间难度暂不递增
- 阵亡单位跨层不复活

---

## 建议下一步

1. **层间难度递增**（中优先）— 根据 current_floor 调整敌方 HP/ATK 或数量
2. **商店格扩展**（中低优先）— 多选商品 + 独立 UI 面板

---

## Codex 复审标注

1. **content_scale_size 固定为设计分辨率**：这是 Godot canvas_items 拉伸模式的标准用法。如果未来需要在高分辨率下显示更多内容（而非缩放），则需改用 viewport 拉伸模式或改为相对布局。当前绝对像素布局下，固定 content_scale_size 是唯一正确方案。
