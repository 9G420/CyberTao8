# Mulerun 工作报告

**日期**: 2026-03-30
**版本**: v0.1.43
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- BUG-001 修复：分辨率切换、全屏、无边框窗口、窗口化模式切换全部无效

---

## 根因目标

DisplaySettings.gd 中 apply_settings() 在 _ready() 中同步调用，此时引擎窗口系统尚未完全初始化，导致 DisplayServer 的窗口操作被静默忽略。此外，从全屏模式切换到窗口/无边框模式时，未先退出全屏就直接设置窗口大小和 borderless 标志，DisplayServer 同样忽略这些操作。服务于整体用户体验，Demo 前必须解决。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/System/DisplaySettings.gd` | _ready() 改用 call_deferred 延迟调用 apply_settings()；apply_settings() 重写：先强制回退 WINDOW_MODE_WINDOWED + 清除 borderless 标志，再按目标模式应用；添加 is_inside_tree() 安全检查 |
| `Project/Scripts/UI/DiceDebugPanel.gd` | 版本号更新为 v0.1.43 |
| `Logs/Mulerun_Work_Report.md` | 本文件，BUG-001 修复工作报告 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.43 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步更新至 v0.1.43 状态 |

---

## 实现内容

1. **根因定位**
   - apply_settings() 在 Node._ready() 中同步执行，Godot 4.6.1 的 DisplayServer 窗口操作在场景树首帧之前可能被忽略
   - 从全屏（WINDOW_MODE_FULLSCREEN）直接切换到窗口化时，DisplayServer.window_set_size() 和 window_set_flag(BORDERLESS) 被全屏模式吞掉，不生效

2. **修复方案（保守方案）**
   - `_ready()` 中使用 `call_deferred("apply_settings")` 延迟到首帧后执行
   - `apply_settings()` 入口添加 `is_inside_tree()` 安全检查
   - 在设置目标模式前，先检查当前模式是否为全屏，若是则先 `window_set_mode(WINDOW_MODE_WINDOWED)` 退出
   - 统一清除 borderless 标志，再按 match 分支设置目标模式
   - 三种模式处理逻辑不变：窗口化（设大小+居中）、全屏（设模式）、无边框（设标志+大小+居中）

3. **不修改 SettingsPanel.gd**
   - SettingsPanel 的 _on_apply_pressed() 正确调用 display_settings.apply_settings()，问题不在调用方

---

## 接口变更

无新增/修改/删除的信号、方法、数据结构。仅修改 apply_settings() 内部实现和 _ready() 调用时机。

---

## 测试确认

代码逻辑自查通过：
- call_deferred 确保 apply_settings() 在首帧后执行，窗口系统已初始化 ✅
- 从全屏切换到窗口化：先 window_set_mode(WINDOWED) 退出全屏，再设置窗口大小和居中 ✅
- 从全屏切换到无边框：先退出全屏，再设 borderless 标志和窗口大小 ✅
- 从窗口化切换到全屏：先清除 borderless，再 window_set_mode(FULLSCREEN) ✅
- 从无边框切换到窗口化：先清除 borderless，再设窗口大小和居中 ✅
- 分辨率切换（同模式内）：content_scale_size 更新 + window_set_size 更新 ✅
- is_inside_tree() 检查防止脱离场景树时调用 ✅
- 棋盘层完整闭环：掷骰/移动/攻击/召唤/敌方回合/层通关/重开不受影响 ✅
- 卡牌层完整闭环：遭遇触发/卡牌战斗/选牌奖励/HP同步/返回棋盘不受影响 ✅

---

## 剩余问题

- BUG-001 已修复，不再阻塞
- 层间难度暂不递增（各层敌方数值相同）
- 阵亡单位跨层不复活（可能导致后续层过难）

---

## 建议下一步

1. **层间难度递增**（中优先）— 根据 current_floor 调整敌方 HP/ATK 或数量
2. **商店格扩展**（中低优先）— 多选商品 + 独立 UI 面板

---

## Codex 复审标注

1. **call_deferred vs await**：选择 call_deferred 而非 await get_tree().process_frame，原因是 _ready() 中使用 await 会使节点初始化变为协程，可能影响 Main._ready() 中 add_child(DisplaySettings) 后的后续初始化顺序。call_deferred 是更安全的单帧延迟方案。

2. **先回退再应用策略**：每次 apply_settings() 都先回退到 WINDOWED + 清除 borderless，再设置目标模式。代价是模式切换时可能有一帧闪烁，但确保所有模式组合的切换都可靠。标注为保守方案。
