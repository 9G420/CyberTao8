# Mulerun 工作报告

**日期**: 2026-03-31
**版本**: v0.1.64
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.64：镜头跟随优化+掷骰动画增强

---

## 根因目标

用户反馈：
1. 镜头跟随不够智能——需要移动后才跟随，应该点击选中单位时就居中
2. 敌方回合时应先将镜头移到即将行动的敌方单位，再开始掷骰
3. 掷骰动画太快太小，需要放大并延长动画时间，提升视觉表现

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/UI/BoardView.gd` | _select_unit 新增：选中单位时立即居中相机+重置拖拽偏移 |
| `Scripts/BattleV2/BattleFlowController.gd` | 新增 enemy_turn_starting 信号，_start_enemy_turn 掷骰前先通知 UI |
| `Scripts/Main.gd` | 连接 enemy_turn_starting 信号，相机跟随时重置拖拽偏移，新增 _on_enemy_turn_starting 回调 |
| `Scripts/UI/DiceRollAnimation.gd` | 全面增强：骰子放大（34→56），动画延长（总时长约4秒），新增阴影/光晕/减速翻滚效果 |
| `Scripts/UI/DiceDebugPanel.gd` | 版本标记更新至 v0.1.64 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.64 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号 |

---

## 实现内容

### 1. 镜头跟随优化

- **选中单位即居中**：BoardView._select_unit 中查询单位位置，立即调用 set_camera_target 并重置 _drag_offset
- **敌方回合开始前镜头先移到敌方**：BattleFlowController._start_enemy_turn 在掷骰前 emit enemy_turn_starting 信号，Main.gd 收到后将相机移到第一个敌方单位，等待 0.5 秒后才开始掷骰
- **所有自动跟随时重置拖拽偏移**：_on_move_completed_camera、_on_enemy_turn_starting、_on_enemy_turn_ended 三个回调都清零 _drag_offset，确保自动跟随不受之前手动拖拽的影响

### 2. 掷骰动画增强

- **骰子放大**：DICE_HW 从 34 增加到 56（约 65% 放大）
- **动画延长**：翻滚阶段 0.6→1.4秒，定格间隔 0.18→0.4秒，展示保持 0.45→0.8秒，淡出 0.28→0.4秒
- **减速翻滚**：面切换速度随时间递增（模拟骰子物理减速），wobble 振幅也逐渐衰减
- **落地阴影**：每颗骰子下方绘制菱形半透明阴影
- **中心光晕**：遮罩中心绘制径向发光，营造舞台聚光灯效果
- **多层辉光**：定格时 3 层光晕叠加（宽度递增、透明度递减）
- **边框增强**：定格后边框更粗更亮
- **旋转效果**：翻滚期间骰子有微小旋转偏移，定格后平滑回正
- **更大字号**：结果文字 15→20，骰面名称 10→14

---

## 接口变更

- `BattleFlowController.enemy_turn_starting(first_enemy_id: String)` 新增信号
- `DiceRollAnimation._die_rotation` / `_tumble_time` 新增内部状态
- `DiceRollAnimation._draw_center_glow()` / `_draw_die_shadow()` 新增绘制方法

---

## 测试确认

- 选中单位时相机立即居中（重置拖拽偏移确保不漂移）
- 敌方回合前相机先移到敌方单位位置，0.5秒后才掷骰
- 敌方回合结束后相机切回玩家
- 掷骰动画明显更大更慢，翻滚有减速感
- 定格时多层光晕+弹跳缩放
- 需用户在 Godot 中实际运行确认视觉效果

---

## 剩余问题

- UI 布局尚未重新设计（底部卡牌栏、侧面信息面板等 Dino Card Hunt 风格）
- CardRewardPanel 暂未使用 CardRenderer 风格
- 扇形手牌暂无拖拽机制
- SettingsPanel 暂未添加音量控件
- 阵亡单位跨层不复活

---

## 建议下一步

1. 用户在 Godot 中运行确认镜头跟随+掷骰动画效果
2. UI 布局重新设计（底部卡牌栏、顶部资源条、侧面信息面板）
3. 更丰富的棋盘内容（更多遭遇类型、NPC、地标等）
4. 卡牌拖拽使用机制
