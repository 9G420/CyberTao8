# Mulerun 工作报告

**日期**: 2026-03-30
**版本**: v0.1.46
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- 美化 Phase 2.1 + 2.2：掷骰演出动画 + 攻击演出增强（屏幕微震+粒子+增强飘字）

---

## 根因目标

Phase 1 已完成棋盘格/单位/高亮视觉升级。Phase 2 目标是让关键操作有"感觉"——掷骰有期待感、攻击有冲击感。根据 Art_Beautification_Strategy_zh.md Phase 2（P1 优先级）执行。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/UI/DiceRollAnimation.gd` | **新建**，~158行，掷骰演出动画控件：3枚骰子翻滚→逐个定格→crest图标弹出发光 |
| `Scripts/UI/BattleEffects.gd` | **新建**，~103行，战斗特效静态类：屏幕微震+CPUParticles2D粒子爆发+增强伤害飘字+击杀文字 |
| `Scripts/UI/BoardView.gd` | play_attack_feedback 增强：集成 BattleEffects（微震+粒子+弹跳飘字），新增 is_kill 参数，移除旧 _damage_label |
| `Scripts/UI/DiceDebugPanel.gd` | 集成 DiceRollAnimation：掷骰后播放动画，动画完成后更新结果文字；版本号 v0.1.46 |
| `Scripts/Main.gd` | 新增 _last_attack_killed 变量，play_attack_feedback 调用传递 is_kill 参数 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.46 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 版本更新至 v0.1.46，§3.1/§6 同步 |

---

## 实现内容

### 1. DiceRollAnimation.gd（全新文件，~158行）

- `play(results, crest_pool)` 主方法：启动掷骰演出
- 3枚骰子翻滚效果：55ms 间隔随机切换 crest 符号
- 逐个定格（每枚间隔 150ms）：定格时 scale 1.25→1.0 弹跳 + 霓虹发光闪烁
- 6种 crest 独特符号程序化绘制：
  - 显化 → ★ 五角星
  - 步进 → → 箭头
  - 杀伐 → ✖ 交叉剑
  - 护持 → 盾形
  - 术式 → ◎ 同心圆
  - 机巧 → ⬡ 六边形
- 6种 crest 独特颜色：青/青绿/橙/金/品红/紫
- 总演出时长约 1.1s（tumble 0.55s + settle 3×0.15s + post 0.25s）
- 半透明暗色背景遮罩 + 霓虹边框
- `animation_finished` 信号通知完成
- 使用 `set_process(false/true)` 精确控制，非动画期间零开销

### 2. BattleEffects.gd（全新文件，~103行）

- `shake_screen(target, intensity, duration)` — 6步衰减随机偏移，使用 meta 存储静止位置防止抖动累积
- `spawn_hit_particles(parent, pos, color, is_kill)` — CPUParticles2D 一次性爆发（普通6粒/击杀12粒），全方位扩散+重力下落+透明渐隐，自动释放
- `enhanced_damage_popup(parent, pos, damage, is_kill)` — 双 Tween 驱动：scale 弹跳（1.0→1.4→1.0）+ 上浮渐隐
- `kill_text_popup(parent, pos)` — 击杀时额外弹出金色 "KILL!" 文字

### 3. BoardView 增强

- `play_attack_feedback` 新增 `is_kill: bool = false` 参数（默认值保持向后兼容）
- 集成 BattleEffects：每次攻击命中触发微震+粒子+增强飘字
- 击杀时效果增强：闪光更亮、震动更强、粒子更多、金色飘字+KILL!文字
- 移除旧 `_damage_label` 实例变量（被 BattleEffects.enhanced_damage_popup 替代，支持多个同时存在）

### 4. DiceDebugPanel 集成

- 掷骰后先更新 crest 池显示（玩家可立即行动），同时播放骰子演出
- 动画完成后更新 roll_label 文字（"上次掷骰：move, attack, defend"）
- DiceRollAnimation 定位在掷骰结果区域（y=290），覆盖该区域约 1.1s

### 5. Main.gd 信号传递

- 新增 `_last_attack_killed` 变量，从 `attack_completed` 信号捕获
- 玩家攻击和敌方攻击均传递 is_kill 到 play_attack_feedback

---

## 接口变更

### 新增

- `DiceRollAnimation`（class_name 全局注册）：`play(results, crest_pool)` 方法 + `animation_finished` 信号
- `BattleEffects`（class_name 全局注册）：`shake_screen()`、`spawn_hit_particles()`、`enhanced_damage_popup()`、`kill_text_popup()` 静态方法

### 修改

- `BoardView.play_attack_feedback()` 新增可选参数 `is_kill: bool = false`（向后兼容）

### 删除

- `BoardView._damage_label` 实例变量（被 BattleEffects 替代）

### 无变化

- 所有 BoardView 信号签名不变
- BattleFlowController 零修改
- DiceManager 零修改

---

## 测试确认

代码审查确认：
- play_attack_feedback 默认参数 is_kill=false 保证所有现有调用（terrain_damage 等）不受影响
- DiceRollAnimation 使用 set_process(false) 默认不运行，仅在演出期间激活
- BattleEffects.shake_screen 使用 meta 存储静止位置，防止多次抖动位置漂移
- CPUParticles2D 使用 one_shot + 自动 queue_free，不会泄漏节点
- gl_compatibility 安全：CPUParticles2D（非 GPUParticles2D）+ draw_* 绘制
- 性能：掷骰动画仅在 1.1s 内激活 _process，非动画期间零开销；粒子 one_shot 最多 12 个

---

## 剩余问题

- 层间难度暂不递增（已排后）
- 阵亡单位跨层不复活

---

## 建议下一步

1. **美化 Phase 3**：卡牌战斗面板重设计（CardRenderer.gd）
2. **美化 Phase 4.1**：背景氛围升级（动态网格+粒子+渐变）
3. **美化 Phase 4.2**：UI 过渡动画（面板弹出/关闭）

---

## Codex 复审标注

1. **掷骰动画不阻塞操作**：动画播放期间，crest 池已更新，玩家可以立即移动/攻击。这是有意设计——动画是视觉反馈而非流程门槛，避免了修改 BattleFlowController 的需要。

2. **BattleEffects 纯静态设计**：与 CyberStyle/BoardCellRenderer/UnitRenderer 保持一致的无状态静态方法模式。唯一的"状态"是 shake_screen 通过 node.set_meta 存储的静止位置，用于防止多次抖动的位置漂移。

3. **CPUParticles2D 使用约束**：策略文档要求"不超过 3 个同时活跃实例"。当前实现中，每次攻击命中创建 1 个粒子节点（one_shot，0.4-0.6s 后自动释放）。在正常游戏节奏下不会超过 3 个同时存在。

4. **_damage_label 替换为独立 Label**：旧实现使用实例变量跟踪单个 damage label（后续攻击会先释放前一个）。新实现每次创建独立 Label 并自动释放，支持多个同时显示（如连续攻击），视觉效果更丰富。
