# Mulerun 工作报告

**日期**: 2026-03-30
**版本**: v0.1.48
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- 美化 Phase 4.1：背景氛围升级（动态网格背景+粒子+渐变+棋盘发光边框）

---

## 根因目标

Phase 3 完成了卡牌战斗面板重设计，卡牌层界面已有"卡牌游戏"感。Phase 4.1 目标是提升整体画面氛围——将纯色 ColorRect 背景替换为有层次感的赛博朋克环境：深色三段渐变、棋盘下方透视网格线（模拟赛博空间纵深感）、全屏浮动微粒子（CPUParticles2D 光点漂浮）、棋盘边缘脉冲发光框+四角装饰标记+缓慢扫描线。根据 Art_Beautification_Strategy_zh.md Phase 4.1（P2 优先级）执行。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/UI/CyberBackground.gd` | **新建**，~155行，背景氛围渲染系统：渐变+网格+粒子+发光框+扫描线+角标 |
| `Scripts/Main.gd` | 替换 ColorRect 为 CyberBackground，新增 preload，传入棋盘位置/尺寸 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.48 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 版本更新至 v0.1.48，§2.2/§3.1/§3.3/§6 同步 |

---

## 实现内容

### 1. CyberBackground.gd（全新文件，~155行）

- `class_name CyberBackground`，extends Control，作为 Main 的第一个子节点（背景层）
- **三段渐变背景**：12 级色阶从深暗蓝（顶）→ 暗蓝灰（中）→ 微亮蓝灰（底），取代原来的纯色 ColorRect
- **透视网格线**：
  - 棋盘下方区域绘制水平+垂直半透明网格线
  - 水平线带缓慢向下漂移动画（drift = t * 3.0），模拟数据流纵深感
  - 垂直线从中心向两侧淡出，中心线加粗强调
  - 远离棋盘的线条 alpha 递减，营造透视消失感
- **浮动粒子（CPUParticles2D）**：
  - 35个粒子，lifetime 6秒，全屏矩形发射区域
  - 方向随机（spread 180°），无重力缓慢漂浮
  - Gradient 色彩渐变：淡入→蓝光→渐弱→淡出
  - gl_compatibility 安全（CPUParticles2D 不依赖 GPU 粒子）
- **棋盘发光边框**：
  - 4层外辉光（半透明递减），内层亮线 3px
  - sin 脉冲呼吸效果（频率 2.0，幅度 ±15%）
  - 发光颜色使用青蓝色系，与 CyberStyle 一致
- **角标装饰**：棋盘四角各画两条 14px 短线（L 形），青色半透明
- **扫描线**：6px 高半透明青色条，缓慢从上至下循环扫过全屏
- **动画刷新**：50ms Timer（20fps），仅驱动 queue_redraw

### 2. Main.gd 修改

- 新增 `CyberBackground` preload
- `_build_debug_view()` 中用 `CyberBackground.new()` 替代旧 `ColorRect.new()`
- 通过 `set_board_rect(Vector2(40, 94), Vector2(576, 576))` 告知背景棋盘位置
- CyberBackground 的 mouse_filter = MOUSE_FILTER_IGNORE，不影响交互

---

## 接口变更

### 新增

- `CyberBackground`（class_name 全局注册）：`set_board_rect(origin, size)` 方法

### 修改

- `Main._build_debug_view()` 背景从 ColorRect 改为 CyberBackground

### 无变化

- BattleFlowController 零修改
- CardBattleController 零修改
- BoardView 零修改
- CardBattlePanel 零修改
- CyberStyle 零修改（CyberBackground 使用内部常量，不污染全局）

---

## 测试确认

代码审查确认：
- CyberBackground mouse_filter = MOUSE_FILTER_IGNORE，不拦截任何输入事件
- CPUParticles2D 数量 35 个，远低于性能警戒线（<3 个发射器同时活跃）
- _draw() 中无每帧创建对象（纯 draw_rect/draw_line 调用）
- 渐变 12 级色阶用循环 draw_rect 实现，无 Shader 依赖，gl_compatibility 安全
- 网格线使用 draw_line，线宽 1px，性能无压力
- 浮动粒子 Gradient 色彩渐变：两端 alpha=0 确保粒子自然淡入淡出
- 棋盘发光脉冲使用 Time.get_ticks_msec() + sin()，与 BoardCellRenderer 模式一致，不创建 Tween
- Main.gd 仅替换一个子节点，所有信号连接不变

---

## 剩余问题

- 层间难度暂不递增（已排后）
- 阵亡单位跨层不复活
- CardRewardPanel 暂未使用 CardRenderer 风格（可在后续统一）

---

## 建议下一步

1. **美化 Phase 4.2**：UI 过渡动画（面板弹出/关闭动画+召唤展开演出）
2. **美化 Phase 5**：音效系统（AudioManager + 基础音效接入）
3. **层间难度递增**：根据 current_floor 调整敌方数值

---

## Codex 复审标注

1. **CyberBackground 独立模块设计**：背景氛围作为独立 Control，不依赖任何游戏逻辑模块。仅通过 `set_board_rect()` 接收棋盘位置参数。这保持了渲染层与逻辑层的完全分离。

2. **颜色常量未加入 CyberStyle**：CyberBackground 的渐变/网格/辉光颜色定义为文件内部常量，未加入 CyberStyle。原因：这些颜色是背景专用的微调值，不会被其他模块复用。如果未来有其他模块需要引用背景配色，可以迁移到 CyberStyle。

3. **粒子数量选择**：35个粒子是在"有氛围感"和"不分散注意力"之间的平衡。粒子 alpha 控制在 0.18-0.22 的低区间，作为背景纹理而非前景元素。实际感受可能需要在 Godot 运行时微调 amount 和 color_ramp。

4. **网格漂移速度**：drift = t * 3.0，每秒漂移 3 个像素单位。偏慢是有意为之——背景动态应该是"呼吸感"而非"运动感"。如果觉得太静可以调大到 5-8。
