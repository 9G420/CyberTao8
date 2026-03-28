# CyberTao 项目迁移快照
**生成时间**: 2026-03-29 06:30 UTC

---

## 1. 项目概要

CyberTao: Pixel Awakening（虚拟道境·像素觉醒）是一款基于Godot 4.6.1 (GL Compatibility, 1280×720)开发的赛博朋克×道教主题卡牌Roguelike游戏，对标杀戮尖塔(Slay the Spire)。玩家扮演"阿零·像素觉醒者"，在虚拟道境中通过阴阳平衡的卡牌战斗系统击败数据化敌人。核心玩法包括：回合制卡牌战斗（拖拽打出）、阴阳平衡机制（共鸣/反噬）、召唤物系统、4节点关卡推进、传承轮回。当前项目已具备完整可玩的战斗循环、102张卡牌、6种敌人、程序化像素美术和8bit音频系统，正在进行对标STS的视觉品质升级。GitHub仓库: `https://github.com/9G420/CyberTao8` (main分支, 最新commit: `0f32d7e`)。

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
- 5种类型: 攻击(ATTACK)、防御(DEFENSE)、术法(SPELL)、能力(POWER)、召唤(SUMMON)
- 3种阴阳: 阴(YIN)、阳(YANG)、中性(NEUTRAL)
- 3种稀有度: 普通(0)、稀有(1)、史诗(2)
- 关键词: 消耗(exhaust)、固有(innate)、保留(retain)、不可打出(unplayable)、多段(multi_hit)
- 初始牌组10张，战斗胜利后3选1获取新卡

### 召唤物系统
- 玩家最多4个召唤物同时在场
- 分前排(挡伤)和后排(辅助)
- 每个召唤物有独立HP、攻击力、被动技能
- 9种召唤物各有独立像素精灵

### 敌人梯度
- 普通怪(3种) → 精英(2种) → Boss(1种，双阶段)
- Boss在50%血量时进入第二阶段(增强攻击+AOE)

### 关卡流程
- 当前: 4节点线性地图 (普通→事件+精英→精英→Boss)
- 每轮结束后可传承1张卡进入下一轮(run_number递增)
- 存档系统: `user://cybertao_save.json`

### 美术方案
- 程序化48×64像素精灵(PixelArtGenerator)，NEAREST过滤放大显示
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
| 召唤 | 9张 | sum_ | 召唤战场单位 |
| 衍生 | 1张 | tok_ | 数据碎片(战斗中生成) |

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

### 代码结构
```
CyberTao8/
├── Autoload/               # 全局单例(4个)
│   ├── GameState.gd        # 游戏状态、存档、牌组、地图、阴阳计算
│   ├── Global.gd           # 场景切换(淡入淡出)、is_transitioning锁
│   ├── AudioManager.gd     # BGM+SFX双轨播放、crossfade、音效池(12个)
│   └── AssetLoader.gd      # AI资产加载、程序化回退
├── Scripts/
│   ├── Battle/
│   │   ├── BattleManager.gd  # 战斗主控(~3100行): UI构建、状态机、回合流程、VFX、动画
│   │   ├── EffectSystem.gd   # 102张卡的效果执行(apply_card_effect)
│   │   ├── Enemy.gd          # 6种敌人定义+AI行为模式
│   │   └── SFXGenerator.gd   # 程序化音效合成(~1100行)
│   ├── Card/
│   │   ├── CardData.gd       # Resource类: 卡牌属性定义(5类型、3阴阳、关键词)
│   │   ├── Card.gd           # 卡牌UI节点: 拖拽、悬停放大、类型着色、打出动画
│   │   ├── Deck.gd           # 抽牌堆/弃牌堆管理
│   │   └── Hand.gd           # 手牌扇形布局、悬停邻牌让开
│   ├── UI/
│   │   ├── Title.gd          # 标题画面
│   │   ├── OpeningCG.gd      # 开场CG(打字机文字+BGM)
│   │   ├── Map.gd            # 关卡地图(当前4节点水平)
│   │   ├── Event.gd          # 事件/商店/奖励
│   │   ├── Victory.gd        # 胜利画面(EVA十字光+太极旋转+裂屏)
│   │   ├── Defeat.gd         # 战败画面(3个按钮)
│   │   └── DeckBuilder.gd    # 牌组查看
│   └── Visual/
│       └── PixelArtGenerator.gd  # 程序化像素美术(~1500行): 角色、卡面、太极、UI
├── Scenes/                 # 8个.tscn场景文件
├── Shaders/                # 6个.gdshader
├── Resources/Cards/        # 102个.tres卡牌数据
├── Assets/Audio/           # AI生成的MP3 BGM
└── Logs/                   # 开发日志
```

### 关键类与函数

**BattleManager.gd (核心, ~3100行)**
- `_setup_ui()` — 构建全部战斗UI(场内HP条、能量宝珠、结束回合按钮、角色精灵、阴影)
- `_init_battle()` — 初始化战斗数据(从GameState读取)
- `_start_player_turn()` / `_start_enemy_turn()` — 回合状态切换
- `_execute_card()` — 卡牌执行入口(调用EffectSystem)
- `_on_enemy_defeated()` / `_on_player_defeated()` — 胜败处理
- `_play_player_attack_anim()` / `_play_enemy_attack_anim()` — 攻击帧动画
- `_flash_enemy_hit()` — 受击VFX(红闪+震动+飘字)
- `_spawn_damage_popup()` — 伤害飘字(32/44px, 缩放入场)
- `_show_turn_banner()` — 回合横幅动画
- `_screen_shake()` — 屏幕震动
- `_update_summon_display()` — 召唤物战场显示
- `_apply_target_ring()` — 目标指示光环
- `_play_defeat_transition()` — 战败过渡动画
- `_play_victory_transition()` — 胜利过渡动画
- `static func _ai_sprite()` — 精灵获取(AI优先→程序化回退)

**EffectSystem.gd**
- `static func apply_card_effect(card, battle_mgr)` — 根据card_id分发102种效果

**Enemy.gd**
- `EnemyUnit.create_enemy(type)` — 工厂方法创建敌人
- `_decide_next_action()` — AI决策(基于回合数+血量比的固定模式)
- 6种AI模式: GRUNT三回合循环、SWARM召唤、THIEF偷能量、PUPPET自增强、OBSESSION腐化、BOSS双阶段

**Card.gd**
- 160×220px卡牌UI，拖拽释放到play_zone打出
- 类型着色边框(红/蓝/紫/金/绿)、费用宝珠shader、悬停1.35x放大+投影
- `play_cast_animation()` — 膨胀→飞向目标→缩小旋转淡出

**Hand.gd**
- 扇形布局: FAN_RADIUS=900, FAN_MAX_ANGLE=25°, 最多8张
- 悬停时邻牌偏移30px让开

### Godot 4.6.1 技术陷阱
- `:=` 不能用于数组字面量、字符串拼接、untyped数组索引 → 必须显式类型声明
- `await` 调用不存在的函数 → 协程永久挂起(不报错)
- Tween必须用 `node.create_tween()` 绑定生命周期
- shader中 `fragment()` 不能用 `return`
- shader注释必须用 `//` 不能用 `#`

---

## 5. 当前对话的关键结论

1. **视觉品质对标STS**: 通过逐帧分析STS游戏视频，识别出卡牌类型着色、场内HP条、能量宝珠、伤害飘字、回合横幅、屏幕震动等关键视觉差距并逐一实现
2. **战败卡死根因**: `await`调用不存在的函数导致协程永久挂起，不是UI bug而是语言级陷阱
3. **Boss后地图卡死根因**: 是一条4步连锁故障(未advance_node → 重复advance → is_transitioning锁死 → 静默拦截场景切换)，需要在4个文件中同时修复
4. **角色精灵品质**: 程序化48×64像素在192×256显示下仍显粗糙，但已是程序化方案的合理上限，进一步提升需要手绘资产或AI生成
5. **地图系统需要重写**: 当前4节点水平布局与STS的垂直分支路线图差距最大，是下一阶段最高优先级
6. **按钮UI风格**: STS使用卷轴/绸带/金属质感的主题化按钮，当前项目使用扁平StyleBoxFlat，需要全面升级
7. **卡牌奖励流程**: 需要实现STS式的"3选1大卡展示"界面替代当前简陋的Event奖励

---

## 6. 待办清单（按优先级）

### 🔴 紧急
- **地图系统重写**: 将4节点水平布局改为STS式垂直分支路线图(15层, 每层2-4节点, 虚线连接, 节点类型图标: 敌人/精英/商店/休息/未知/宝箱)，GameState数据结构需配套改造
- **按钮UI全面升级**: 复刻STS风格按钮(红色卷轴"返回"、银灰六边形"结束回合"、红色箭头"跳过奖励"、青色圆角"跳过"等)，提取通用按钮样式工厂
- **卡牌奖励界面**: 实现STS式战斗胜利→横幅"太好了!"→金币奖励→3选1大卡展示→关键词说明面板

### 🟡 本周
- **敌人意图图标化**: 敌人头顶显示行动图标(剑+数值=攻击, 盾=防御, 特殊图标)替代纯文字
- **牌组查看界面升级**: 全屏网格布局、顶部排序栏(获取顺序/类型/耗能)、悬停关键词tooltip
- **战斗背景增强**: 多层shader背景(远景墙壁+中景柱子+近景地面纹理)或程序化生成背景
- **Boss HP提升**: 当前80HP偏低，考虑120-150HP + 更复杂的阶段机制

### 🟢 之后
- **角色精灵品质提升**: 手绘或AI生成更高质量的角色立绘替换程序化像素
- **卡牌升级系统**: 休息点升级卡牌(升级版.tres已有upgraded_version字段预留)
- **更多敌人种类**: 每层2-3种普通怪随机、更多精英类型
- **遗物系统**: STS核心系统之一，被动增益道具
- **商店系统**: 金币购买卡牌/遗物/移除卡牌
- **音频替换**: 用专业音乐文件替换程序化8bit BGM
- **卡牌融合系统**: CardData已预留fusable/fusion_result字段

---

## 7. 已知问题 & 未解决疑问

### Bug
1. **PixelArtGenerator.gd:1308** — INTEGER_DIVISION警告(小数部分被丢弃)，不影响运行但应修复
2. **PixelArtGenerator.gd:1495** — `sign`变量名与内置函数冲突(SHADOWED_GLOBAL_IDENTIFIER)
3. **SFXGenerator.gd:106** — 未使用变量`t`警告
4. **AssetLoader.gd:164** — `tex`变量在父块中声明(CONFUSABLE_LOCAL_DECLARATION)
5. **资源泄漏**: 退出时偶发"ObjectDB instances leaked"和"1 resources still in use"

### 设计疑问
1. **地图分支结构**: 具体用几层？每层几个节点？分支连线规则？是否参照STS的15层3-4列?
2. **休息点机制**: 休息回血多少？是否同时提供卡牌升级选项？
3. **商店定价**: 卡牌按稀有度定价？移除卡牌费用？
4. **遗物系统优先级**: 是否在地图重写后立即实现？
5. **多周目差异**: run_number递增后，敌人是否变强？地图是否变化？
6. **卡牌平衡性**: 102张卡未经大量测试，数值平衡需要playtesting调整

---

## 8. 新账号启动指令

```
我正在开发一款Godot 4.6.1的赛博朋克×道教卡牌Roguelike游戏「CyberTao: Pixel Awakening（虚拟道境·像素觉醒）」，对标杀戮尖塔(Slay the Spire)。

GitHub仓库: https://github.com/9G420/CyberTao8 (main分支)
仓库认证token: [使用你的GitHub Personal Access Token]
Git配置: user.name="9G420", user.email="9g420@users.noreply.github.com"

请先克隆仓库到本地，然后阅读 Logs/changelog_v0.3_sts_upgrade.md 了解已完成的工作，再阅读本消息下方的迁移快照文档了解完整项目状态。

当前项目状态：102张卡牌、6种敌人、完整战斗循环已可玩。已完成v0.3视觉升级（卡牌类型着色、场内HP条、能量宝珠、伤害飘字、精灵放大、idle帧动画、目标光环、屏幕震动等）。

最高优先级待办：
1. 🔴 地图系统重写 — 当前是4个水平按钮，需要改为STS式垂直分支路线图（15层多分支、虚线连接、节点类型图标），GameState.gd的map_nodes数据结构需要从Array[Dictionary]改为多层多分支图结构
2. 🔴 按钮UI全面升级 — 复刻STS风格：红色卷轴"返回"按钮、银灰六边形"结束回合"、红色箭头"跳过奖励"等主题化按钮，替代当前扁平StyleBoxFlat
3. 🔴 卡牌奖励界面 — 实现STS式战斗胜利后的横幅+金币奖励+3选1大卡展示

技术注意事项：
- Godot 4.6.1的 `:=` 不能用于数组字面量、字符串拼接、untyped数组索引，必须显式类型声明
- `await`调用不存在的函数会导致协程永久挂起且不报错
- Tween必须用 `node.create_tween()` 绑定生命周期
- BattleManager.gd约3100行，是最核心也最大的文件
- 程序化像素美术在PixelArtGenerator.gd（~1500行），48×64画布

请先拉取代码并阅读项目结构，然后从🔴优先级任务开始工作。如有任何疑问请直接问我。
```
