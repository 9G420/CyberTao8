# CyberTao v0.3 杀戮尖塔品质升级快报
# 虚拟道境·像素觉醒 — STS对标升级日志
# Date: 2026-03-28 ~ 2026-03-29

---

## 本轮已完成的优化 / Completed Upgrades

### 1. 编译错误修复
- **PixelArtGenerator.gd**: Godot 4.6.1 `:=` 类型推断bug，`trigram_positions`/`thunder_pts`/`star_colors`/`rune_positions` 改为显式 `Array[Vector2i]`/`Array[Color]` 类型声明
- **DeckBuilder.gd**: `var header :=` 字符串拼接推断失败，改为 `var header: String =`
- **BattleManager.gd**: 删除重复的 `_play_defeat_transition()` 函数定义（第676行和第2168行重复）

### 2. 战败画面卡死修复
- **根因**: `_on_player_defeated()` 中 `await _play_defeat_transition()` 调用了不存在的函数，导致协程永远不会完成
- **修复**: 创建完整的 `_play_defeat_transition()` 函数，红色覆盖层 + "意识崩溃" 文字 + 屏幕震动

### 3. Boss胜利后地图节点无法选择BUG修复
- **根因链**:
  1. Boss胜利后未调用 `advance_node()`，boss节点未标记完成
  2. Victory界面 → "选择奖励" → Event界面 → "继续" 时 Event 再次调用 `advance_node()`，`current_node_index` 变为4
  3. Map检测到所有节点完成，通过 `Global.change_scene` 跳转Victory，但 `is_transitioning` 仍为true，跳转被静默拦截
  4. 玩家卡在所有节点已完成且无法点击的Map界面
- **修复**:
  - BattleManager: Boss胜利时调用 `advance_node()`
  - Map: 所有节点完成后用直接场景切换绕过 `is_transitioning` 锁
  - Event: 检测奖励模式跳过重复 `advance_node()`
  - GameState: `start_new_run_with_legacy` 在重置后再保存

### 4. 角色精灵放大 + 动作动画
- 玩家/敌人精灵: 144×192 → 192×256 显示尺寸
- 召唤物精灵: 72×96 → 120×160 显示尺寸，间距78→130px
- 新增idle帧循环: 玩家 frame 0↔3 (1.5s间隔)，敌人 frame 0↔1 (2s间隔产生威胁感)
- 阴影位置同步调整

### 5. 目标指示器优化（替换丑陋方框）
- 删除旧 `_apply_edge_glow` 矩形框高亮
- 新增 `_apply_target_ring` 脚下椭圆光环 + 精灵modulate脉冲

### 6. 卡牌系统升级（对标STS）
- **类型着色边框**: 攻击=红, 防御=蓝, 术法=紫, 能力=金, 召唤=绿（边框脉冲在类型色和亮色之间）
- **费用宝珠**: 左上角费用改为径向渐变shader发光球体
- **悬停增强**: 放大1.35倍, 上移60px, 投影效果, 0.12s动画
- **相邻卡牌让开**: 悬停时左右邻牌偏移30px
- **不可用灰化**: 更强的灰暗处理 (modulate 0.4)
- **打出动画**: 膨胀→飞向目标→缩小+旋转+淡出

### 7. 战斗界面升级（对标STS）
- **场内HP条**: 玩家和敌人脚下新增红色HP条 + 白字 "XX/XX"（STS风格）
- **能量宝珠**: 左下角60×60 shader发光球体替代文字面板
- **结束回合按钮**: 独立160×50按钮, 青色边框发光, 右侧醒目位置
- **伤害飘字增强**: 普通32px, 暴击44px带"暴击!"前缀, 1.5倍缩放入场动画
- **回合横幅**: 大号居中文字 + 缩放进入动画 + 暗色背景
- **屏幕震动**: 攻击/受击时递减强度随机偏移
- **护盾徽章**: 蓝色盾牌shader + 数值标签

### 8. 音频系统升级
- 新增5个战斗音效: `player_hurt`, `card_play`, `turn_start`, `enemy_hurt`, `end_turn`
- 音频触发: 打出卡牌、回合开始、结束回合、受伤+屏幕震动、攻击敌人

---

## 修改文件清单 / Modified Files (v0.3)

| File | Changes |
|------|---------|
| `Scripts/Battle/BattleManager.gd` | 场内HP条, 能量宝珠, 结束回合按钮, 伤害飘字, 精灵放大, idle帧动画, 战败过渡, Boss advance_node, 目标光环, 回合横幅, 屏幕震动, 护盾徽章, 召唤物放大, 音效触发 |
| `Scripts/Card/Card.gd` | 类型着色边框, 费用宝珠shader, 悬停增强(1.35x+投影), 不可用灰化, 打出动画 |
| `Scripts/Card/Hand.gd` | 悬停卡牌邻牌让开(30px) |
| `Scripts/Battle/SFXGenerator.gd` | 5个新音效生成函数 |
| `Autoload/AudioManager.gd` | 注册5个新音效 |
| `Scripts/Visual/PixelArtGenerator.gd` | 类型推断修复 |
| `Scripts/UI/DeckBuilder.gd` | 类型推断修复 |
| `Scripts/UI/Map.gd` | 全节点完成时直接场景切换 |
| `Scripts/UI/Event.gd` | 奖励模式跳过advance_node |
| `Autoload/GameState.gd` | start_new_run_with_legacy 保存时序修复 |

---

## 待优化问题 / Pending Issues (用户反馈)

### P1: 关卡选择路线未参照STS
- **用户需求**: 当前地图是4个水平排列的矩形按钮，与STS的垂直分支路线图差距巨大
- **STS参考**: 垂直卷轴羊皮纸地图，多分支路径(3-4列)，虚线连接，节点类型图标(敌人/精英/商人/休息/未知/宝箱)，从底部向上滚动，右侧图例面板
- **需要改造**:
  - Map.gd 完全重写为垂直分支路线图
  - GameState.gd 地图数据结构改为多层多分支 (15层，每层2-4个节点，有连线关系)
  - 节点类型增加: 休息点、商店、未知事件、宝箱
  - 添加羊皮纸/卷轴背景纹理
  - 玩家位置标记在当前层
  - 路径连线动画

### P2: 互动按钮UI未参照STS
- **用户需求**: 所有可交互按钮的样式需要复刻STS风格
- **STS参考**:
  - "返回" 按钮: 红色卷轴/绸带造型，带卷曲边缘
  - "跳过奖励" 按钮: 红色箭头造型
  - "结束回合" 按钮: 银灰色六边形金属质感
  - "启程" 按钮: 大号红色绸带按钮
  - 奖励面板: 蓝灰色羊皮纸底色，条目悬停高亮
  - 卡牌选择界面: 横幅标题 "选择一张牌"，跳过按钮为青色圆角
  - 牌组查看: 网格布局，顶部排序栏，悬停显示关键词tooltip
- **需要改造**:
  - 提取通用按钮样式工厂 (ribbon_button, metal_button, scroll_button 等)
  - Victory.gd / Defeat.gd / Event.gd / Map.gd 的按钮全部换用新样式
  - 奖励界面重写为STS风格面板

### P3: 卡牌选择/奖励界面
- **STS参考**: 战斗胜利后弹出羊皮纸横幅 "太好了!"，显示金币奖励 + "将一张卡牌加入牌组"，点击后展示3张大卡供选择，右侧有关键词说明面板
- **当前差距**: Event.gd 的奖励流程过于简陋，缺少卡牌3选1展示界面

### P4: 牌组查看界面
- **STS参考**: 全屏网格布局，卡牌按获取顺序/类型/耗能排序，顶部排序栏，悬停显示关键词tooltip和说明面板
- **当前差距**: DeckBuilder.gd 界面风格与STS差距较大

### P5: 战斗背景
- **STS参考**: 丰富的手绘地牢背景，多层景深，环境光源(绿色火焰/火把)，地面石板纹理
- **当前状态**: shader生成的渐变背景，缺乏环境细节
- **可行方案**: 增加多层shader背景(远景墙壁+中景柱子+近景地面)，或用PixelArtGenerator生成背景纹理

### P6: 敌人意图图标
- **STS参考**: 敌人头顶显示下回合行动图标(剑=攻击+数值, 盾=防御, 特殊图标)
- **当前状态**: 有enemy_intent_label文字显示，但缺少图标化
- **需要**: 生成小型图标sprite(剑/盾/特殊)放在敌人头顶

---

## 技术备忘 / Technical Notes

- **Godot版本**: 4.6.1 GL Compatibility
- **分辨率**: 1280×720
- **`:=` 类型推断坑**: 数组字面量、字符串拼接、untyped数组索引 不能用 `:=`，必须显式类型声明
- **Tween安全模式**: 始终用 `node.create_tween()` 绑定生命周期，不要用裸 `create_tween()`
- **await陷阱**: `await` 不存在的函数会导致协程永久挂起
- **is_transitioning锁**: `Global.change_scene` 中 `is_transitioning` 未重置会导致后续场景切换全部失败
- **GitHub**: `https://github.com/9G420/CyberTao8` (main branch)
- **最新commit**: f69877a

---

## Git提交历史 (v0.3)

| Commit | Description |
|--------|-------------|
| `f69877a` | STS品质视觉升级: 卡牌颜色, HP条, 能量宝珠, 伤害飘字 |
| `c4f2b3c` | 修复重复函数 + Boss后地图节点选择BUG |
| `f11248f` | 精灵放大, idle帧动画, 战败画面修复 |
| `fbddd60` | (v0.2 最后commit) |
