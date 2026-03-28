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

### 9. STS式垂直分支路线图 (Map.gd 重写)
- **15层多分支地图**: 7列布局，每层2-5个节点，底部起始→顶部Boss
- **节点类型**: 战斗(⚔)、精英(☠)、休息(🔥)、商店(💰)、事件(？)、宝箱(✦)、Boss(💀)
- **路径连线**: 虚线连接，可达路径高亮(青色粗线)、不可达路径暗淡(灰色细线)
- **可达节点高亮**: 玩家当前位置可选节点alpha=1.0，不可达节点alpha=0.35
- **当前位置指示**: 金色脉冲光环 + "▼你在这里" 标签
- **悬停Tooltip**: 显示节点类型中文描述
- **ScrollContainer**: 支持上下滚动浏览全部15层

### 10. 卡牌奖励界面 (CardReward.gd 新建)
- **STS式3选1**: 横幅"战斗胜利!" → 金币奖励动画 → 3张大卡展示
- **Card panels**: 220×300尺寸，card_color主色调着色
- **悬停效果**: 1.08x放大+上浮10px+边框变亮，smooth tween回弹
- **跳过按钮**: 底部"跳过奖励"选项

### 11. 每张卡独特视觉系统
- **Hash-based唯一性**: card_id.hash()作为seed，确保每张卡视觉独特
- **8种几何徽章**: circles/cross/nested_squares/starburst/dot_grid/stripes/corner_brackets/diamond
- **card_color主色**: 每张卡有唯一card_color，用于UI着色（背景、边框、徽章）
- **像素画参数化**: 攻击/防御/召唤/术法/能力所有motif函数都加入seed-based参数变化（颜色、位置、大小）
- **Power卡扩展**: 从2种变体扩展到6种（金丹/天眼/螺旋/回路/太极/结晶）

### 12. 牌组查看悬停预览 (DeckBuilder.gd)
- **400×520预览面板**: z_index=50，悬停时显示
- **预览内容**: 大尺寸卡面图(280×180)、卡名(22pt+稀有度颜色)、类型|阴阳|费用、完整描述(15pt)、数值、关键词、effect_id
- **自动定位**: 优先显示在卡牌右侧，屏幕边缘时切换到左侧

### 13. 高清像素画升级 (PixelArtGenerator.gd 重大重构)
- **分辨率翻倍**: 卡牌画作从64×64升级为128×128（基础64绘制+NEAREST上采样）
- **移除扫描线**: 去掉每隔一行darkened(0.15)的retro扫描线效果
- **移除噪点标记**: 去掉随机accent pixels和accent line（看起来像噪点不像装饰）
- **渐变背景**: 从纯色改为垂直渐变（顶亮底暗），更有层次感
- **Bloom光效**: 新增后处理pass，高亮像素周围产生3px柔和辉光
- **暗角效果**: 边角自然过渡变暗（vignette），聚焦视觉中心
- **渐变边框**: 稀有度边框从1-3px升级为3-7px，二次函数衰减+内侧高光线
- **新绘图辅助**: `_draw_gradient_circle`(径向渐变圆), `_draw_thick_circle`(带粗细圆环), `_draw_ellipse`(椭圆填充)
- **Motif升级**: 剑尖/雷电/交叉斩/盾脉冲/六角核心/召唤法阵/金丹中心全部改用gradient_circle
- **角色精灵**: 从48×64升级为96×128（2x上采样）
- **战斗背景**: 从320×180升级为640×360（2x上采样）
- **调色板增强**: 所有颜色略微提高饱和度，新增GOLD/SOFT_WHITE常量

### 14. 战斗卡牌card_color染色
- **Card.gd**: 卡面艺术区域背景使用card_data.card_color着色
- **阴阳区分**: 阴卡偏冷色调、阳卡偏暖色调、中性卡均匀混合

---

## 修改文件清单 / Modified Files (v0.3 完整)

| File | Changes |
|------|---------|
| `Scripts/Battle/BattleManager.gd` (~3162行) | 场内HP条, 能量宝珠, 结束回合按钮, 伤害飘字, 精灵放大, idle帧动画, 战败过渡, Boss advance_node, 目标光环, 回合横幅, 屏幕震动, 护盾徽章, 召唤物放大, 音效触发 |
| `Scripts/Card/Card.gd` | 类型着色边框, 费用宝珠shader, 悬停增强, 不可用灰化, 打出动画, card_color卡面着色 |
| `Scripts/Card/Hand.gd` | 悬停卡牌邻牌让开(30px) |
| `Scripts/Battle/SFXGenerator.gd` | 5个新音效生成函数 |
| `Autoload/AudioManager.gd` | 注册5个新音效 |
| `Scripts/Visual/PixelArtGenerator.gd` (~2150行) | 128×128高清输出, bloom光效, 渐变背景, 暗角效果, 渐变边框, 新绘图辅助函数, motif升级, 角色精灵96×128, 战斗背景640×360, 6种Power变体, 全类型参数化, 调色板增强 |
| `Scripts/UI/DeckBuilder.gd` (~1072行) | card_color主色调, 8种几何徽章, 悬停预览面板400×520, 卡面图扩大200×100 |
| `Scripts/UI/CardReward.gd` (~477行) | 全新STS式3选1奖励界面, 悬停放大动效, card_color着色, 增强边框阴影, 卡面图140×125 |
| `Scripts/UI/Map.gd` (~940行) | 全新15层垂直分支路线图, 可达节点高亮, 路径线高亮, 当前位置指示, 悬停tooltip |
| `Scripts/UI/Event.gd` | 奖励模式跳过advance_node, 卡面缩略图扩大100×70 |
| `Autoload/GameState.gd` | start_new_run_with_legacy 保存时序修复, map_graph多层分支数据, get_reachable_next_nodes() |

---

## 待优化问题 / Pending Issues

### P1: 互动按钮UI风格统一 (中优先级)
- **STS参考**: 红色卷轴/绸带"返回"、银灰六边形"结束回合"、红色箭头"跳过"
- **当前状态**: 部分按钮已改进，但整体风格未完全统一
- **需要**: 提取通用按钮样式工厂，全局替换

### P2: 敌人意图图标化 (中优先级)
- **STS参考**: 敌人头顶显示下回合行动图标(剑=攻击+数值, 盾=防御, 特殊图标)
- **当前状态**: 有enemy_intent_label文字显示，缺少图标
- **需要**: PixelArtGenerator生成小型意图图标sprite

### P3: 卡牌升级系统 (低优先级)
- CardData已预留upgraded_version字段
- 休息点/商店可提供升级选项

### P4: 遗物系统 (低优先级)
- STS核心系统，被动增益道具
- 宝箱节点/精英掉落/商店购买

### P5: 商店系统 (低优先级)
- 金币购买卡牌/遗物/移除卡牌

### ~~P1 (已完成): 关卡选择路线~~
- ✅ 已重写为STS式15层垂直分支路线图

### ~~P3 (已完成): 卡牌选择/奖励界面~~
- ✅ 已实现STS式3选1大卡展示

### ~~P4 (已完成): 牌组查看界面~~
- ✅ 已升级为全屏网格+悬停预览面板

### ~~P5 (已完成): 战斗背景~~
- ✅ 已升级为640×360高清输出

---

## 技术备忘 / Technical Notes

- **Godot版本**: 4.6.1 GL Compatibility
- **分辨率**: 1280×720
- **`:=` 类型推断坑**: 数组字面量、字符串拼接、untyped数组索引 不能用 `:=`，必须显式类型声明
- **`btn.flat = true` 禁止**: 会阻止Godot渲染StyleBoxFlat背景，永远不要用
- **Tween安全模式**: 始终用 `node.create_tween()` 绑定生命周期，不要用裸 `create_tween()`
- **await陷阱**: `await` 不存在的函数会导致协程永久挂起
- **is_transitioning锁**: `Global.change_scene` 中 `is_transitioning` 未重置会导致后续场景切换全部失败
- **Hash-based唯一性**: `(card_id + str(salt)).hash()` 实现每张卡确定性视觉差异
- **Panel圆形**: `Panel + StyleBoxFlat + corner_radius` 实现圆形UI元素
- **GitHub**: `https://github.com/9G420/CyberTao8` (main branch)
- **最新commit**: b7a4030

---

## Git提交历史 (v0.3 完整)

| Commit | Description |
|--------|-------------|
| `b7a4030` | 事件界面卡牌缩略图增大至100x70 |
| `a4e9da1` | 战斗卡牌使用card_color染色卡面艺术区域背景 |
| `408376f` | 增强图案细节：渐变光晕+新绘图辅助函数 |
| `c1c156e` | 升级像素画质量：128x128高清输出+bloom光效+渐变背景 |
| `73c5746` | STS式UI/UX全面优化: 地图交互+卡牌悬停预览+奖励卡动效 |
| `c8a85c7` | Power卡像素画增至6种变体+全类型参数化 |
| `93213ff` | 每张卡像素画独特化: seed色调偏移+独特标记 |
| `bc6e9c6` | 重做卡牌UI: card_color主色调+8种几何徽章 |
| `e5bb482` | Hash-based唯一视觉生成 |
| `f746cef` | 圆形Panel替代方形外发光 |
| `a36f901` | 修复地图节点可见性和悬停交互 |
| `718996b` | 优化地图和牌组查看视觉 |
| `5fc48d7` | STS式地图重写+卡牌奖励界面+主题按钮UI |
| `0f32d7e` | 添加v0.3升级日志 |
| `f69877a` | STS品质视觉升级: 卡牌颜色, HP条, 能量宝珠, 伤害飘字 |
| `c4f2b3c` | 修复重复函数 + Boss后地图节点选择BUG |
| `f11248f` | 精灵放大, idle帧动画, 战败画面修复 |
