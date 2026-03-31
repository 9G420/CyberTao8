# Mulerun 工作报告

**日期**: 2026-03-31
**版本**: v0.1.55
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.55：美化 Phase 4.2 — UI 过渡动画（面板弹出/关闭缓动 + 召唤展开演出）

---

## 根因目标

AI_Employee_Guide_v3 §6 当前最高优先级任务。所有面板（奖励选牌/牌组查看/设置）目前 visible = true/false 直切，无过渡动画，体验生硬。召唤单位和路径格直接出现，无展开演出。本轮目标：为所有弹出面板加入 scale+alpha 缓动动画，为召唤添加路径铺展和出场闪光演出。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/UI/UITransitions.gd` | **新增文件**，UI 过渡动画工具类（class_name 全局注册），~60行 |
| `Scripts/UI/CardRewardPanel.gd` | 接入 UITransitions：弹出/关闭/跳过均使用缓动动画；pivot_offset 设置 |
| `Scripts/UI/DeckViewPanel.gd` | 接入 UITransitions：open/close 使用缓动动画；pivot_offset 设置 |
| `Scripts/UI/SettingsPanel.gd` | 接入 UITransitions：open/close 使用缓动动画；pivot_offset 设置 |
| `Scripts/Main.gd` | _on_summon_completed 重写：路径格逐格铺展（0.1s/格）+ 召唤单位出场闪光 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.55 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号+完成列表+任务优先级 |

---

## 实现内容

### UITransitions 工具类（新增）

- `UITransitions.popup(panel, duration)` — 面板弹出动画：scale 0.9→1.0（EASE_OUT + TRANS_BACK 弹跳）+ modulate alpha 0→1，默认 0.2 秒
- `UITransitions.close(panel, duration)` — 面板关闭动画：scale 1.0→0.95 + modulate alpha 1→0，默认 0.15 秒，完成后自动 visible=false 并复位 scale/modulate
- `UITransitions.close_await(panel, duration)` — 异步关闭（可 await），返回时面板已隐藏
- `UITransitions.summon_unit_spawn(parent, pixel_pos, cell_size)` — 召唤单位出场：青色闪光从 0.3x→1.3x→1.0x 弹跳 + alpha 淡出
- 使用 class_name 全局注册，所有 UI 文件无需 preload

### 面板弹出/关闭动画

- **CardRewardPanel**：奖励面板弹出使用 popup()；选牌完成后使用 close_await()（等待动画结束后才隐藏）；跳过使用 close()；升级完成后使用 close_await()
- **DeckViewPanel**：open() 使用 popup()；close() 使用 close()
- **SettingsPanel**：open() 使用 popup()；关闭使用 close()
- 所有面板设置 pivot_offset 为面板中心，确保缩放从中心开始

### 召唤展开演出

- 路径格逐格铺展：_on_summon_completed 中遍历 path_cells_created，每格延迟 0.1 秒后触发 queue_redraw，产生路径格从召唤者位置向外依次出现的效果
- 召唤单位出场闪光：在 spawn_cell 像素位置创建青色 ColorRect，scale 从 0.3→1.3（弹跳）→1.0 + alpha 渐隐至 0，自动销毁

---

## 接口变更

- `UITransitions` — 新增 class_name（全局注册）
- `UITransitions.popup(panel, duration)` — 静态方法
- `UITransitions.close(panel, duration)` — 静态方法
- `UITransitions.close_await(panel, duration)` — 静态方法
- `UITransitions.summon_path_spread(board_view, cells, delay)` — 静态方法（预留，当前由 Main.gd 内联实现）
- `UITransitions.summon_unit_spawn(parent, pixel_pos, cell_size)` — 静态方法

---

## 测试确认

- CardRewardPanel 弹出动画（scale+alpha 渐入）→ 选牌 → 关闭动画（scale+alpha 渐出）流程完整
- DeckViewPanel toggle 开关：open 弹出 → 再点 close 关闭，动画正确
- SettingsPanel open → 操作 → close 动画正确
- 召唤路径格逐格出现（0.1s 间隔），召唤单位闪光弹跳后淡出
- 所有面板 close 后 scale/modulate 正确复位为 Vector2.ONE/Color.WHITE
- 棋盘层闭环不受影响：掷骰/移动/攻击/召唤/敌方回合/胜负重开
- 卡牌层闭环不受影响：遭遇触发/百叶窗过渡/全屏战斗/出牌/奖励选牌/HP同步

---

## 剩余问题

- 层间难度暂不递增
- 阵亡单位跨层不复活
- CardRewardPanel 暂未使用 CardRenderer 风格
- 扇形手牌暂无拖拽机制（仅点击出牌）
- 角色立绘为程序化绘制

---

## 建议下一步

1. 美化 Phase 5：音效系统（AudioManager + 基础音效接入）
2. 层间难度递增
3. 商店格扩展（多选商品 + 独立 UI 面板）
