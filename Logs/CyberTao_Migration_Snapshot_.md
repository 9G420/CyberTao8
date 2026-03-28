# CyberTao 项目迁移快照
**生成时间**: 2026-03-29 16:00 UTC (v0.3.3 retain卡崩溃修复后)

---

## 1. 项目概要

CyberTao: Pixel Awakening（虚拟道境·像素觉醒）是一款基于 **Godot 4.6.1** (GL Compatibility, 1280×720) 开发的赛博朋克×道教主题卡牌Roguelike游戏，对标杀戮尖塔(Slay the Spire)。玩家扮演"阿零·像素觉醒者"，在虚拟道境中通过阴阳平衡的卡牌战斗系统击败数据化敌人。

**核心玩法**: 回合制拖拽卡牌战斗、阴阳平衡机制（共鸣/反噬）、召唤物系统（最多4个前/后排单位）、STS式15层垂直分支地图（7列×15层）、传承轮回（每轮保留1张卡）。

**当前进度**: 项目已具备 **完整可玩的战斗循环**，包含102张卡牌（每张有唯一card_color和hash-based独特视觉）、6种敌人（3普通+2精英+1双阶段Boss）、128×128高清程序化像素美术（带bloom/vignette后处理）、96×128角色精灵、640×360战斗背景、STS式地图/奖励/牌组查看界面、8bit程序化音频系统（18种SFX+5首BGM）。

**GitHub仓库**: `https://github.com/9G420/CyberTao8` (main分支)
**认证token**: `<由用户提供>`
**Git配置**: `user.name="9G420"`, `user.email="9g420@users.noreply.github.com"`
**最新commit**: `326fef7` (修复回合结束弃牌导致保留卡牌被释放的崩溃)

---

## 2. 已确认的设计方案

### 核心战斗系统
- **能量(算力)**: 每回合3点，打出卡牌消耗对应算力，X费卡消耗全部剩余算力
- **阴阳平衡**: 每张卡带阴/阳/中性属性，打出后累计阴阳计数
  - **道境共鸣**: `|阴-阳| ≤ 2` → +1能量 +1伤害加成
  - **心魔反噬**: `|阴-阳| ≥ 4` → -2伤害惩罚
  - 每场战斗开始重置阴阳计数
- **护盾(格挡)**: 回合结束清零，先扣护盾再扣血
- **腐化(corruption)**: 叠加型状态，每回合造成等值伤害，每回合自然-1

### 卡牌系统
- **5种类型**: 攻击(ATTACK)、防御(DEFENSE)、术法(SPELL)、能力(POWER)、召唤(SUMMON)
- **3种阴阳**: 阴(YIN)、阳(YANG)、中性(NEUTRAL)
- **3种稀有度**: 普通(0)、稀有(1)、史诗(2)
- **关键词**: 消耗(exhaust)、固有(innate)、保留(retain)、不可打出(unplayable/弃牌触发)、多段(multi_hit)
- **CardData Resource字段**: card_id, card_name, description, cost, card_type, yinyang, yinyang_value, attack_power, defense_power, summon_hp, effect_id, rarity, card_color, upgraded_version, fusable, fusion_result, shop_price, exhaust, innate, retain, multi_hit, summon_passive, unplayable
- 初始牌组10张，战斗胜利后3选1获取新卡

### 召唤物系统
- 玩家最多4个召唤物同时在场
- 分前排(挡伤)和后排(辅助)
- 每个召唤物有独立HP、攻击力、被动技能
- 9种召唤物各有独立像素精灵: fox, crane, dragon, golem, sprite, clone, familiar, swarm, beast

### 敌人梯度
- 普通怪(3种): grunt/grunt2(swarm)/grunt3(thief) → 精英(2种): elite(puppet)/elite2(obsession) → Boss(1种，双阶段)
- Boss在50%血量时进入第二阶段(增强攻击+AOE)
- 6种AI模式: GRUNT三回合循环、SWARM召唤、THIEF偷能量、PUPPET自增强、OBSESSION腐化、BOSS双阶段

### 关卡流程
- STS式15层垂直分支路线图 (7列, 每层2-5节点, 虚线连接)
- 节点类型: 战斗(⚔)/精英(☠)/休息(🔥)/商店(💰)/事件(？)/宝箱(✦)/Boss(💀)
- 可达节点高亮(alpha=1.0), 不可达暗淡(alpha=0.35), 路径线高亮(青色粗线vs灰色细线)
- 当前位置金色脉冲光环 + "▼你在这里" 标签
- 每轮结束后可传承1张卡进入下一轮(run_number递增)
- 存档系统: `user://cybertao_save.json`

### 美术方案
- 程序化128×128像素卡面画(PixelArtGenerator, 64基础+2x NEAREST上采样)
- Bloom光效后处理(高亮像素3px柔和辉光) + Vignette暗角效果
- 渐变背景(垂直方向深浅变化) + 渐变稀有度边框(3-7px, 二次函数衰减)
- 角色精灵96×128(48×64基础+2x上采样), 16bit描边+高光+阴影后处理
- 战斗背景640×360(320×180基础+2x上采样)
- Hash-based每卡唯一视觉: `card_id.hash()`驱动颜色/位置/图案参数化变化
- 8种几何徽章(circles/cross/nested_squares/starburst/dot_grid/stripes/corner_brackets/diamond)
- AI资产优先加载(AssetLoader)，无AI资产时回退到程序化生成
- 6个shader特效层: CRT扫描线、能量场、墨迹流动、召唤光环、故障效果、阴阳粒子

### 音频方案
- 双轨机制: AI生成MP3优先 → 程序化8bit回退
- SFXGenerator运行时PCM合成(22050Hz 8bit mono)
- 5首BGM(battle/title/map/boss/opening) + 18种SFX

---

## 3. 卡牌数据总览

### 按类型分布 (102张)

| 类型 | 数量 | 前缀 | 说明 |
|------|------|------|------|
| 攻击 | 32张 | atk_ | 直接伤害、多段、穿透、AOE |
| 防御 | 24张 | def_ | 护盾、荆棘、闪避、反击 |
| 术法 | 23张 | spl_ | 抽牌、能量操控、状态施加、牌组操作 |
| 能力 | 10张 | pow_ | 永久增益(打出后持续生效) |
| 召唤 | 9张  | sum_ | 召唤战场单位 |
| 衍生 | 1张  | tok_ | 数据碎片(战斗中生成) |

### 初始牌组 (10张)
```
atk_basic_strike ×2, atk_yang_strike, atk_yin_strike
def_basic_guard ×2, def_yang_guard, def_yin_guard
spl_dao_guidance, sum_pixel_sprite
```

### 攻击卡 (32张)
```
atk_basic_strike, atk_yang_strike, atk_yin_strike, atk_cyber_slash,
atk_neon_flash, atk_pixel_storm, atk_data_pierce, atk_void_slash,
atk_flame_sigil, atk_thunder_chain, atk_dark_pulse, atk_dao_judgement,
atk_dao_thorn, atk_double_tap, atk_dagger_rain, atk_quick_compile,
atk_glass_blade, atk_precise_strike, atk_data_flood, atk_circuit_break,
atk_core_breach, atk_data_shatter, atk_disaster_algo, atk_elegant_finish,
atk_finisher, atk_strangle, atk_all_in, atk_apocalypse,
atk_bone_erode, atk_poison_inject, atk_void_wrath
```

### 防御卡 (24张)
```
def_basic_guard, def_yang_guard, def_yin_guard, def_pixel_barrier,
def_dao_ward, def_code_armor, def_firewall, def_talisman,
def_spirit_guard, def_data_fortress, def_digital_cloak, def_dao_bulwark,
def_thorn_armor, def_yin_shield, def_spirit_scatter, def_harmony_light,
def_deflect, def_backflip, def_cloak_weave, def_ghost_form,
def_time_fold, def_leg_sweep, def_crippling_cloud, def_planned_well,
def_settle_accounts, def_delayed, def_afterimage
```

### 术法卡 (23张)
```
spl_dao_guidance, spl_system_scan, spl_overclock, spl_adrenaline,
spl_quick_patch, spl_crazy_compile, spl_dao_heart_cycle,
spl_yinyang_reverse, spl_glitch_wave, spl_dual_existence,
spl_system_reboot, spl_universal_balance, spl_terror_data,
spl_lethal_corrode, spl_nightmare_copy, spl_blade_dance,
spl_bounce_vial, spl_bullet_time, spl_catalyze, spl_concentrate,
spl_corpse_explode, spl_instinct_reaction, spl_preparation,
spl_seize_initiative
```

### 能力卡 (10张)
```
pow_nimble_step, pow_poison_protocol, pow_infinite_blade,
pow_precision, pow_thorns, pow_afterimage, pow_lingchi,
pow_poison_fog, pow_essential_tools, pow_dao_awakening
```

### 召唤卡 (9张)
```
sum_pixel_sprite, sum_cyber_fox, sum_dao_crane, sum_neon_golem,
sum_shadow_clone, sum_spirit_dragon, sum_byte_familiar,
sum_swarm, sum_beast
```

---

## 4. 技术实现现状

### 代码结构 (~14,000行GDScript)
```
CyberTao8/
├── Autoload/                    # 全局单例(4个)
│   ├── GameState.gd (606行)     # 游戏状态、存档、牌组、地图、阴阳计算
│   ├── Global.gd (74行)         # 场景切换(淡入淡出)、is_transitioning锁
│   ├── AudioManager.gd (217行)  # BGM+SFX双轨播放、crossfade、音效池(12个)
│   └── AssetLoader.gd (277行)   # AI资产加载、程序化回退
├── Scripts/
│   ├── Battle/
│   │   ├── BattleManager.gd (3170行) # 战斗主控: UI构建、状态机、回合流程、VFX、动画
│   │   ├── EffectSystem.gd (426行)   # 102张卡的效果执行(apply_card_effect)
│   │   ├── Enemy.gd (525行)          # 6种敌人定义+AI行为模式
│   │   └── SFXGenerator.gd (1103行)  # 程序化音效合成
│   ├── Card/
│   │   ├── CardData.gd (133行)  # Resource类: 卡牌属性定义(5类型、3阴阳、关键词)
│   │   ├── Card.gd (572行)      # 卡牌UI节点: 拖拽、悬停放大、类型着色、打出动画
│   │   ├── Deck.gd (62行)       # 抽牌堆/弃牌堆管理
│   │   └── Hand.gd (178行)      # 手牌扇形布局、悬停邻牌让开
│   ├── UI/
│   │   ├── Title.gd (366行)       # 标题画面
│   │   ├── OpeningCG.gd (305行)   # 开场CG(打字机文字+BGM)
│   │   ├── Map.gd (940行)         # STS式15层垂直分支路线图
│   │   ├── Event.gd (715行)       # 事件/商店/奖励
│   │   ├── CardReward.gd (477行)  # STS式3选1卡牌奖励
│   │   ├── DeckBuilder.gd (1072行)# 牌组查看+悬停预览
│   │   ├── Victory.gd (371行)     # 胜利画面(EVA十字光+太极旋转+裂屏)
│   │   └── Defeat.gd (257行)      # 战败画面(3个按钮)
│   └── Visual/
│       └── PixelArtGenerator.gd (2150行) # 程序化高清像素美术
├── Scenes/           # 9个.tscn: Battle/CardReward/DeckBuilder/Defeat/Event/Map/OpeningCG/Title/Victory
├── Shaders/          # 6个.gdshader: crt/energy_field/glitch/ink_flow/summon_aura/yinyang_particle
├── Resources/Cards/  # 102个.tres卡牌数据
├── Assets/Audio/     # AI生成的MP3 BGM
└── Logs/             # 开发日志
```

### BattleManager.gd 关键函数位置

| 函数 | 行号 | 功能 |
|------|------|------|
| `_setup_ui()` | 139 | 构建全部战斗UI(HP条、能量宝珠、结束回合按钮、角色精灵) |
| `_init_battle()` | 801 | 初始化战斗数据(从GameState读取) |
| `_start_player_turn()` | 867 | 玩家回合开始(抽牌、重置能量) |
| `_execute_card_effect()` | 1242 | 卡牌效果执行入口(调用EffectSystem) |
| `_start_enemy_turn()` | 1592 | 敌人回合(AI决策、攻击、状态结算) |
| `_end_turn_discard()` | 1748 | 回合结束弃牌(处理retain保留卡) |
| `_on_enemy_defeated()` | 2201 | 胜利处理(→CardReward或Victory) |
| `_on_player_defeated()` | 2231 | 战败处理(→Defeat) |

### GameState.gd 关键数据
- `player_deck: Array[String]` — 当前牌组(CardData资源路径)
- `map_graph: Array` — 15层×7列地图结构
- `map_current_floor / map_current_node` — 当前地图位置
- `get_reachable_next_nodes()` — 计算可达下一层节点集合
- `MAP_FLOORS := 15`, `MAP_COLUMNS := 7`
- 节点类型常量: `NT_BATTLE/NT_ELITE/NT_REST/NT_SHOP/NT_EVENT/NT_TREASURE/NT_BOSS`

### PixelArtGenerator.gd 关键API
- `generate_card_art(card_type, yinyang, rarity, seed_val) → ImageTexture` — 128×128卡面画(64绘制+2x NEAREST+bloom+vignette+渐变边框)
- `generate_character_sprite(char_type, frame) → ImageTexture` — 96×128角色精灵(48×64绘制+2x NEAREST+描边后处理)
- `generate_battle_background(stage) → ImageTexture` — 640×360战斗背景
- `generate_taiji_symbol(size, rotation_frame) → ImageTexture` — 太极图
- `generate_status_icon(status_type) → ImageTexture` — 16×16状态图标
- 辅助函数: `_draw_gradient_circle`, `_draw_thick_circle`, `_draw_ellipse`, `_apply_bloom`, `_apply_vignette`

---

## 5. 当前对话的关键结论

1. **视觉品质对标STS**: 通过逐帧分析STS游戏视频，识别出卡牌类型着色、场内HP条、能量宝珠、伤害飘字、回合横幅、屏幕震动等关键视觉差距并逐一实现
2. **战败卡死根因**: `await`调用不存在的函数导致协程永久挂起，不是UI bug而是语言级陷阱
3. **Boss后地图卡死根因**: 4步连锁故障(未advance_node → 重复advance → is_transitioning锁死 → 静默拦截场景切换)，需要在4个文件中同时修复
4. **地图系统已重写**: 从4节点水平布局改为STS式15层垂直分支路线图，含可达节点高亮、路径线高亮、当前位置金色指示
5. **卡牌奖励已实现**: STS式3选1大卡展示，含悬停放大动效和card_color着色
6. **牌组查看已升级**: 全屏网格+400×520悬停预览面板(z_index=50, 自动定位左/右)
7. **每卡独特视觉**: 基于card_id.hash()的参数化系统，8种几何徽章+card_color主色+像素画参数化。Power卡从2种扩展至6种变体(金丹/天眼/螺旋/回路/太极/结晶)
8. **高清像素画**: 从64×64升级到128×128(2x NEAREST上采样)，bloom+vignette后处理，移除retro扫描线和噪点标记，渐变背景+渐变边框
9. **retain保留卡崩溃已修复**: `_end_turn_discard()`中`clear_hand()`会queue_free所有卡牌包括retain卡，改为只逐个释放弃置卡牌，保留卡留在手牌中不动。同时给`_update_drag_targeting()`和`_arrange_hand()`增加`is_instance_valid`安全检查
10. **Card.gd卡面着色**: 战斗手牌卡面艺术区域背景使用card_data.card_color，阴卡偏冷/阳卡偏暖/中性均匀

---

## 6. 待办清单（按优先级）

### 🔴 紧急
- **按钮UI全面升级**: 复刻STS风格按钮(红色卷轴"返回"、银灰六边形"结束回合"、红色箭头"跳过奖励"等)，提取通用按钮样式工厂，全局替换Victory/Defeat/Event/Map的按钮
- **敌人意图图标化**: 敌人头顶显示下回合行动图标(剑=攻击+数值, 盾=防御, 特殊图标)替代纯文字enemy_intent_label，用PixelArtGenerator生成小型意图图标sprite

### 🟡 本周
- **卡牌升级系统**: 休息点升级卡牌(CardData已预留upgraded_version字段)，需要实现升级UI+.tres升级版数据
- **Boss HP提升**: 当前80HP偏低，考虑120-150HP + 更复杂的阶段机制
- **数值平衡**: 102张卡未经大量测试，需要playtesting调整

### 🟢 之后
- **遗物系统**: STS核心系统，被动增益道具(宝箱节点/精英掉落/商店购买)
- **商店系统**: 金币购买卡牌/遗物/移除卡牌(CardData已有shop_price字段)
- **更多敌人种类**: 每层2-3种普通怪随机、更多精英类型
- **音频替换**: 用专业音乐文件替换程序化8bit BGM
- **卡牌融合系统**: CardData已预留fusable/fusion_result字段

### ✅ 已完成
- ~~地图系统重写~~ → STS式15层垂直分支路线图 (Map.gd ~940行)
- ~~卡牌奖励界面~~ → STS式3选1大卡展示 (CardReward.gd ~477行)
- ~~牌组查看界面升级~~ → 全屏网格+悬停预览面板 (DeckBuilder.gd ~1072行)
- ~~每卡独特视觉~~ → hash-based参数化+8种徽章+card_color
- ~~高清像素画~~ → 128×128+bloom+vignette (PixelArtGenerator.gd ~2150行)
- ~~战斗背景增强~~ → 640×360高清输出
- ~~角色精灵提升~~ → 96×128高清像素精灵
- ~~retain卡崩溃~~ → 修复弃牌逻辑+is_instance_valid安全检查

---

## 7. 已知问题 & 未解决疑问

### 代码警告 (不影响运行)
1. **PixelArtGenerator.gd** — `main_pink`/`spell_scale` 局部变量声明但未使用(某些motif变体路径)
2. **PixelArtGenerator.gd** — INTEGER_DIVISION警告(多处小数部分被丢弃，已用`@warning_ignore`部分抑制)
3. **PixelArtGenerator.gd** — `sign`变量名与内置函数冲突(SHADOWED_GLOBAL_IDENTIFIER)
4. **SFXGenerator.gd:106** — 未使用变量`t`警告
5. **AssetLoader.gd:164** — `tex`变量在父块中声明(CONFUSABLE_LOCAL_DECLARATION)
6. **Card.gd** — `_preview_panel`类变量声明但未使用
7. **BattleManager.gd** — `_return_card_to_hand`参数`card`未使用
8. **资源泄漏**: 退出时偶发"ObjectDB instances leaked"和"1 resources still in use"

### 设计疑问
1. **休息点机制**: 休息回血多少？是否同时提供卡牌升级选项？
2. **商店定价**: 卡牌按稀有度定价？移除卡牌费用？
3. **遗物系统优先级**: 是否在按钮UI升级后立即实现？
4. **多周目差异**: run_number递增后，敌人是否变强？地图是否变化？
5. **卡牌平衡性**: 102张卡未经大量测试，数值平衡需要playtesting调整

---

## 8. 新账号启动指令

```
我正在开发一款Godot 4.6.1的赛博朋克×道教卡牌Roguelike游戏「CyberTao: Pixel Awakening（虚拟道境·像素觉醒）」，对标杀戮尖塔(Slay the Spire)。

GitHub仓库: https://github.com/9G420/CyberTao8 (main分支)
仓库认证token: <由用户提供>
Git配置: user.name="9G420", user.email="9g420@users.noreply.github.com"

请先克隆仓库到本地，然后阅读 Logs/CyberTao_Migration_Snapshot_.md 了解完整项目状态，再阅读 Logs/changelog_v0.3_sts_upgrade.md 了解已完成的工作。

当前项目状态：102张卡牌（每张独特视觉）、6种敌人、完整战斗循环已可玩。已完成v0.3视觉升级（STS式15层地图、3选1卡牌奖励、牌组悬停预览、128×128高清像素画+bloom+vignette、card_color独特着色、96×128角色精灵、640×360战斗背景）。代码总量约14000行GDScript。

最高优先级待办：
1. 🔴 按钮UI全面升级 — 复刻STS风格：红色卷轴"返回"按钮、银灰六边形"结束回合"、红色箭头"跳过奖励"等主题化按钮，替代当前扁平StyleBoxFlat。需提取通用按钮样式工厂，全局替换
2. 🔴 敌人意图图标化 — 敌人头顶显示行动图标(剑+数值=攻击, 盾=防御, 特殊图标)替代纯文字
3. 🟡 卡牌升级系统 — 休息点升级卡牌(CardData已预留upgraded_version字段)

技术注意事项（踩坑记录，非常重要）：
- Godot 4.6.1的 `:=` 不能用于数组字面量、字符串拼接、untyped数组索引，必须显式类型声明
- `btn.flat = true` 会阻止Godot渲染StyleBoxFlat背景，永远不要用
- `await`调用不存在的函数会导致协程永久挂起且不报错
- Tween必须用 `node.create_tween()` 绑定生命周期，不要用裸 `create_tween()`
- `Global.change_scene`中`is_transitioning`锁未重置会导致后续场景切换全部失败
- Hash-based视觉唯一性: card_id.hash()作为seed驱动颜色/图案参数化
- Panel + StyleBoxFlat + corner_radius 实现圆形UI元素
- BattleManager.gd约3170行，是最核心也最大的文件
- PixelArtGenerator.gd约2150行，128×128卡面+96×128角色+bloom/vignette后处理

请先拉取代码并阅读项目结构，然后从🔴优先级任务开始工作。如有任何疑问请直接问我。
```

---

## Git提交历史 (v0.3 完整, 新→旧)

| Commit | Description |
|--------|-------------|
| `326fef7` | 修复回合结束弃牌导致保留卡牌被释放的崩溃 |
| `889f8e4` | 更新v0.3日志和迁移快照 |
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
| `23f1bfb` | 添加迁移快照 |
| `f69877a` | STS品质视觉升级: 卡牌颜色, HP条, 能量宝珠, 伤害飘字 |
| `c4f2b3c` | 修复重复函数 + Boss后地图节点选择BUG |
| `f11248f` | 精灵放大, idle帧动画, 战败画面修复 |
| `fbddd60` | STS风格体验升级: 回合横幅+屏幕震动+护盾视觉+卡牌飞行动画 |
| `17a2864` | 交互&音效大幅升级: 目标高亮圆环化+5种新音效 |
| `6d5e954` | 修复Godot 4.6.1类型推断错误 |
| `97abe22` | 视觉大幅升级: 卡面图案重写+背景修复+角色阴影 |
| `7bd2ae2` | Visual overhaul: 3 new shaders + summon VFX + battle bg effects |
