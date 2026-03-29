# Mulerun 工作报告

**日期**: 2026-03-29
**版本**: v0.1.21
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- 敌方 AI 可读性增强（Weekly Plan Day 5）

---

## 根因/目标

### 根因
- 敌方回合行动速度过快（0.3-0.4 秒），玩家难以看清敌方做了什么
- 面板只显示"敌方行动"四个字，不知道哪个敌人在动、要做什么
- 敌方攻击没有预警，伤害突然出现令人困惑
- 敌方回合结束时没有明确提示，玩家不知道何时轮到自己

### 目标
- 加长敌方行动间停顿，让玩家看清每一步
- 面板显示每个敌方单位的具体意图（"哨兵甲 → 攻击 刀盾狗"）
- 敌方攻击前目标格闪烁预警
- 敌方回合结束时显示明确文字提示
- 不改动 AI 决策逻辑

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/BattleV2/BattleFlowController.gd` | 新增 `enemy_action_announced` / `enemy_turn_ended` 信号；新增 `_get_unit_display_name()` 辅助方法；`_execute_enemy_actions()` 重写：每步行动前广播意图、加长停顿；`_start_enemy_turn()` 掷骰等待从 0.5s 延长到 0.8s |
| `Project/Scripts/UI/BoardView.gd` | 新增 `play_enemy_warning()` 橙色预警闪烁；新增 `play_enemy_move_indicator()` 移动意图指示 |
| `Project/Scripts/UI/DiceDebugPanel.gd` | 新增 `enemy_intent_label` 敌方意图显示标签；连接 `enemy_action_announced` / `enemy_turn_ended` 信号；玩家阶段自动清空意图文字 |
| `Project/Scripts/Main.gd` | 连接 `enemy_action_announced` / `enemy_turn_ended` 信号；攻击意图广播时在目标格触发预警闪烁 |
| `Logs/Mulerun_Work_Report.md` | 本报告 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.21 条目 |

---

## 实现内容

### 1. 意图广播信号
- `enemy_action_announced(unit_id, action_type, detail)` — 每个敌方单位行动前广播
  - action_type: "attack" 或 "move"
  - detail: 中文描述如 "哨兵甲 → 攻击 刀盾狗" 或 "哨兵乙 → 移动"
- `enemy_turn_ended` — 所有敌方行动完成后广播

### 2. 加长停顿时间
- 掷骰后等待：0.5s → 0.8s
- 攻击意图广播后：新增 0.6s 预读时间
- 攻击执行后：0.4s → 0.7s
- 移动意图广播后：新增 0.5s 预读时间
- 移动执行后：0.3s → 0.6s
- 回合结束后：新增 0.5s 过渡时间

### 3. 面板意图显示
- DiceDebugPanel 底部新增橙色 `enemy_intent_label`
- 实时显示当前敌方行动内容（"哨兵甲 → 攻击 刀盾狗"）
- 敌方回合结束时显示 "敌方回合结束"
- 进入玩家阶段时自动清空

### 4. 攻击预警闪烁
- 攻击意图广播时，目标格显示橙色闪烁（0.6s 渐变动画）
- 闪烁在实际伤害发生前完成，形成"预读 → 攻击"节奏

### 5. 辅助方法
- `_get_unit_display_name()` 统一获取单位显示名称，无名则回退到 unit_id

---

## 当前剩余问题

- **敌方移动无路径预览** — 只能看到移动结果，无法预知移动目的地
- **敌方无行动日志** — 面板只显示最后一条意图，不保留历史
- **BuffManager.tick_turn() 仍未接入** — 持续 buff 暂不生效
- **故障零食盒未放置** — 数据已就绪但调试布局只放了 2 个道具

## 未处理 BUG

### BUG-001：分辨率/窗口模式切换无效
- **发现版本**: v0.1.20
- **现象**: 设置面板选择 1920x1080 + 全屏后应用，窗口仍为 1280x720；内容缩放后偏左不居中；全屏模式选择无效果
- **疑似根因**: `DisplaySettings.apply_settings()` 中 `content_scale_size` 与窗口尺寸/模式的更新顺序可能冲突；Godot 编辑器内运行时 `DisplayServer` 窗口操作可能受限
- **优先级**: 中（不影响核心玩法，但影响展示）
- **相关文件**: `Project/Scripts/System/DisplaySettings.gd`

---

## 建议下一步

1. 在编辑器中验证敌方回合的可读性改善
2. 按 Weekly Plan 继续推进 Day 6：战斗 UI 去调试化第一版
