# Mulerun 工作报告

**日期**: 2026-03-29
**版本**: v0.1.14
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- 实现 summon / path-building 第一版原型
- 验证"召唤即铺路"核心概念

---

## 根因/目标

- 当前战斗原型已有移动、攻击、敌方 AI，但缺少"骰兽协议"的核心辨识度
- summon + path-building 是区别于普通战棋的关键玩法
- 本轮只做最小可运行原型，不追求完整卡牌召唤系统

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/BattleV2/BattleFlowController.gd` | 添加 summon_completed 信号、get_summon_cells_for()、try_summon()、_summon_counter |
| `Project/Scripts/BattleV2/BoardManager.gd` | 添加 get_free_neighbors() 辅助方法 |
| `Project/Scripts/UI/BoardView.gd` | 添加 summon_requested 信号、summon_highlight_cells 紫色高亮、改进 _draw_paths() 区分玩家/其他路径颜色 |
| `Project/Scripts/UI/DiceDebugPanel.gd` | "生成测试路径"改为"测试召唤"按钮、连接 summon_completed 信号、添加 _selected_unit_id_cache |
| `Project/Scripts/Main.gd` | 连接 summon_requested / summon_completed 信号、刷新召唤高亮、更新提示文字 |
| `Logs/Mulerun_Work_Report.md` | 本报告 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.14 条目 |

---

## 实现内容

1. **召唤入口（两种方式）**
   - 棋盘点击：选中玩家单位后，如果有 SUMMON crest，相邻空格显示紫色高亮，点击即可召唤
   - 调试面板按钮："测试召唤（需选中单位+显化）"，点击后自动选择第一个可用格召唤

2. **路径格生成**
   - 召唤时自动在目标格铺设 1 个路径格（player 所属）
   - 然后向远离原点方向再延伸 1 格路径（共 2 格路径）
   - 路径格有明确视觉区分：
     - 玩家路径：青色发光边框 + 半透明填充
     - 其他路径：橙色风格（兼容旧 spawn_demo_path）

3. **召唤单位放置**
   - 在目标格（第 1 格路径）上生成一个测试召唤单位（summoned_fox）
   - 属性：HP 4 / ATK 2 / DEF 0 / 移动范围 2 / 攻击范围 1
   - 归属 player 阵营，可正常选中、移动、攻击
   - 每次召唤生成唯一 ID（summoned_fox_1, summoned_fox_2, ...）

4. **资源消耗**
   - 每次召唤消耗 1 SUMMON（显化）crest
   - 面板实时刷新显示

---

## 关键逻辑

### 召唤流程
```
玩家选中己方单位 →
  如果 SUMMON crest > 0 →
    相邻空格（非占据、非路径）显示紫色高亮 →
      点击紫色格 →
        支付 1 SUMMON →
        目标格标记为 player 路径 →
        向远离原点方向延伸 1 格路径 →
        在目标格生成 summoned_fox 单位
```

### 可召唤格判定
- BoardManager.get_free_neighbors()：返回四方向相邻的空闲格（in_bounds && !occupied && !path）
- 只有 SUMMON crest > 0 时才返回可召唤格

### 路径延伸方向
- 在目标格的空闲相邻格中，选择曼哈顿距离离原点最远的格子
- 体现"向外展开路径"的概念

---

## 当前剩余问题

- **召唤单位是固定数据** — 未接入 UnitData 资源，hardcoded summoned_fox
- **路径格目前不影响移动规则** — 路径只是视觉标记，未限制"只能在路径上移动"
- **无召唤动画** — 单位和路径瞬间出现
- **无召唤数量限制** — 只要有 SUMMON crest 就能无限召唤
- **路径形状固定** — 总是 2 格直线延伸，无 L 形 / T 形等变体
- **未在编辑器中验证运行**

---

## 建议下一步

1. **路径限制移动** — 让某些单位只能在路径格上行动，或路径格提供移动加成
2. **召唤来源接入 UnitData** — 从 hacker_fox.tres / crow_caster.tres 读取数据
3. **多种路径形状** — L 形、T 形、十字形等可选路径模板
4. **召唤数量限制** — 每场战斗最多 N 个召唤单位
5. **移动动画** — Tween 位移替代瞬移
