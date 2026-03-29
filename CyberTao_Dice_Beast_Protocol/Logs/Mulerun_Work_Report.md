# Mulerun 工作报告

**日期**: 2026-03-29
**版本**: v0.1.13
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- 实现敌方 AI 最小回合，让敌人不再是静态靶子

---

## 根因/目标

- 当前战斗原型中敌方单位完全不会行动，玩家只是单方面输出
- 需要最小可用的敌方回合，让战斗真正"打起来"
- 不追求复杂 AI，只要能移动和攻击即可

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/BattleV2/BattleAI.gd` | 重写：添加 get_enemy_units、find_nearest_player_cell、get_adjacent_player_cells、pick_move_toward |
| `Project/Scripts/BattleV2/BattleFlowController.gd` | 添加 enemy_attack_completed 信号、_start_enemy_turn、_execute_enemy_actions、_advance_to_next_player_round；修改 end_player_turn 进入敌方回合 |
| `Project/Scripts/Main.gd` | 连接 enemy_attack_completed 信号，敌方攻击时显示白色闪光 + 红色飘字反馈 |
| `Project/Scripts/UI/DiceDebugPanel.gd` | 连接 enemy_attack_completed 信号，敌方攻击后刷新 crest 面板显示 |
| `Logs/Mulerun_Work_Report.md` | 用中文重写本报告 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.13 条目 |

---

## 实现内容

1. **敌方回合流程**
   - 玩家点击"结束回合"后，不再直接跳回 PLAYER_ROLL
   - 改为进入 ENEMY_ROLL → 敌方掷骰 → 0.5s 延迟 → ENEMY_ACTION → 敌方逐个行动 → 回到 PLAYER_ROLL

2. **敌方 AI 行为（最小可用）**
   - 遍历所有存活敌方单位
   - 如果相邻有玩家单位且有 ATTACK crest → 优先攻击
   - 如果没有相邻目标且有 MOVE crest → 朝最近玩家单位方向移动 1 格
   - 移动后如果进入攻击范围且有 ATTACK crest → 再尝试攻击

3. **敌方攻击反馈**
   - 敌方攻击玩家单位时，在目标格显示白色闪光 + 红色伤害飘字
   - 与玩家攻击反馈完全一致的视觉表现

4. **调试面板同步**
   - 敌方回合期间，掷骰按钮和结束回合按钮自动禁用
   - 敌方掷骰结果和 crest 池实时刷新显示
   - 阶段标签显示"敌方掷骰"/"敌方行动"

---

## 关键逻辑

### 回合流程变化
```
之前: PLAYER_ROLL → PLAYER_ACTION → (结束回合) → PLAYER_ROLL
现在: PLAYER_ROLL → PLAYER_ACTION → (结束回合) → ENEMY_ROLL → ENEMY_ACTION → PLAYER_ROLL
```

### 敌方 AI 决策树（极简）
```
对于每个敌方单位:
  1. 检查四方向相邻格是否有玩家单位
     → 有且有 ATTACK crest → 攻击（消耗 1 ATTACK）
  2. 否则检查是否有 MOVE crest
     → 有 → 找到最近玩家单位 → 选择曼哈顿距离最小的相邻空格 → 移动
     → 移动后再检查是否相邻玩家 → 有且有 ATTACK → 攻击
```

### 异步执行
- 使用 `await get_tree().create_timer()` 在敌方行动之间添加短延迟
- ENEMY_ROLL 后 0.5s 延迟让玩家看到掷骰结果
- 每次移动后 0.3s、每次攻击后 0.4s 延迟
- 全程检查 `is_battle_over()` 防止战斗结束后继续执行

---

## 当前剩余问题

- **敌方只有 1 个调试单位** — 未来需要多敌人测试
- **无音效** — 攻击反馈仍然只有视觉
- **敌方掷骰也有保底 1 MOVE** — 使用与玩家相同的 DiceManager.roll_turn_dice()
- **AI 不考虑远程攻击** — 当前只检查相邻格（attack_range = 1）
- **移动无动画** — 敌方和玩家移动都是瞬间位移
- **未在编辑器中验证运行**

---

## 建议下一步

1. **移动动画** — 用 Tween 做单位位移动画，替代瞬移
2. **HP 条** — 用可视化 HP 条替代文字叠加
3. **多敌人测试** — 增加 2-3 个敌方单位验证 AI 稳定性
4. **召唤 / 铺路系统** — summon + path-building 是核心玩法差异点
