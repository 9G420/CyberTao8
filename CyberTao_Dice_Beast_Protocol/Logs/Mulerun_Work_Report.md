# Mulerun 工作报告

**日期**: 2026-03-30
**版本**: v0.1.34
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- Day 16：牌组查看面板

---

## 根因目标

持久牌组系统（v0.1.31）引入后，玩家无法在棋盘阶段查看当前牌组内容和大小，只有在选牌奖励时才能看到牌组张数。缺少透明度导致玩家无法做出有效的构筑决策（不知道牌组里有什么牌、多少张）。Day 16 的目标是提供一个随时可查看牌组的面板，让构筑成长可视化。服务于卡牌战斗层。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/UI/DeckViewPanel.gd` | 全新文件，牌组查看面板：显示持久牌组所有卡牌（名称/类型/费用/数值），按名称排序，合并同名卡牌计数，BBCode 彩色区分卡牌类型 |
| `Project/Scripts/UI/DiceDebugPanel.gd` | 原"测试卡牌战斗"按钮拆分为"测试战斗"+"查看牌组"并排两按钮；新增 deck_view_requested 信号；版本号更新为 v0.1.34 |
| `Project/Scripts/Main.gd` | 新增 DeckViewPanel 实例化和定位(160,120)；绑定 CardBattleController；连接 deck_view_requested 信号；新增 _on_deck_view_requested 回调（toggle 开关） |
| `Logs/Mulerun_Work_Report.md` | 本文件，Day 16 工作报告 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.34 条目 |

---

## 实现内容

1. **DeckViewPanel 牌组查看面板**
   - 青色边框赛博朋克风格面板（340x440）
   - 标题"当前牌组" + 牌组张数统计
   - 卡牌列表按名称排序显示，合并同名卡牌（如"斩击 x2"）
   - 每张牌显示：名称（类型色）、数量、费用、类型中文、数值
   - 类型颜色区分：攻击=橙色、防御=青色、回复=绿色、穿透/吸血=品红、电击=紫色
   - RichTextLabel 支持滚动（牌组变大后可滚动浏览）
   - 关闭按钮关闭面板
   - 默认隐藏，隐藏时 mouse_filter=IGNORE 不阻挡棋盘点击

2. **DiceDebugPanel 按钮布局调整**
   - 原"测试卡牌战斗"(248宽) 拆分为"测试战斗"(120宽) + "查看牌组"(122宽) 并排
   - "测试战斗"保持橙色主题，"查看牌组"使用青色主题
   - 不影响其他 UI 元素位置

3. **Toggle 交互**
   - 点击"查看牌组"打开面板，再次点击关闭
   - 每次打开时从 CardBattleController.persistent_deck 实时读取最新数据
   - 选牌奖励后再次打开可看到新增的卡牌

---

## 接口变更

### 新增文件
- `Project/Scripts/UI/DeckViewPanel.gd` — 牌组查看面板（class_name DeckViewPanel）

### 新增信号（DiceDebugPanel）
- `deck_view_requested` — 点击"查看牌组"按钮时发射

### 新增方法（DeckViewPanel）
- `bind_controller(controller: CardBattleController)` — 绑定控制器
- `open()` — 打开面板并刷新牌组数据
- `close()` — 关闭面板
- `is_open() -> bool` — 查询是否打开

### 新增方法（Main）
- `_on_deck_view_requested()` — toggle 牌组查看面板

---

## 测试确认

代码逻辑自查通过：
- DeckViewPanel 默认 visible=false，mouse_filter=IGNORE，不阻挡棋盘交互
- open() 时切换为 MOUSE_FILTER_STOP，close() 时恢复 IGNORE
- _refresh_deck_list() 每次打开重新读取 persistent_deck，确保数据实时
- 同名卡牌合并计数逻辑正确（Dictionary 键唯一）
- RichTextLabel 滚动对大牌组有效
- DiceDebugPanel 按钮拆分后总宽度 120+6gap+122=248，与原 248 一致，不影响布局
- 面板位置 (160,120) 不超出 1280x720 视口（160+340=500, 120+440=560）
- 棋盘层和卡牌层完整闭环不受影响（只新增了 UI 查看功能，无逻辑变更）

---

## 剩余问题

- 牌组面板打开时会遮挡棋盘中心区域（需要时手动关闭）
- 卡牌战斗进行中也可打开牌组面板（不影响功能但可能影响视觉层级）
- 牌组面板不显示卡牌描述文本（只显示类型和数值）
- 排序方式为名称排序，未按费用或类型分组（可后续增加排序选项）

---

## 建议下一步

1. **棋盘随机生成**（高优先）— 从固定布局升级为程序化生成
2. **卡牌升级机制**（高优先）— 基础牌可升级为强化版本
3. **BFC 瘦身**（中优先）— 将 debug spawn 剥离到 DebugScenario.gd
4. **Boss 遭遇**（中优先）— 特殊遭遇格触发 Boss 战

---

## Codex 复审标注

1. **面板定位**：DeckViewPanel 放在 Main.gd 实例化层（与 CardRewardPanel、SettingsPanel 一致），通过 DiceDebugPanel 信号触发，不在 DiceDebugPanel 内部持有引用，符合 UI 分层原则。
2. **数据读取方式**：直接读取 CardBattleController.persistent_deck 数组，没有经过额外的查询方法封装。当前可接受，如果后续需要牌组过滤/搜索功能，建议在 CardBattleController 添加 get_persistent_deck() 方法做一层抽象。
