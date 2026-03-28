# CyberTao v0.2 Visual Upgrade Changelog
# 虚拟道境·像素觉醒 美化升级日志
# Date: 2026-03-27

---

## 用户需求记录 / User Requests Log

### 需求1: 编译错误修复
- **描述**: 项目存在多个编译错误无法运行，包括着色器错误、未使用变量警告
- **具体错误**:
  - Shader中使用`#`注释导致GLSL预处理器冲突 → 改为`//`
  - Godot 4.6不允许fragment()中使用`return` → 改为if/else结构
  - 多个脚本中未使用变量警告（SFXGenerator.gd, Title.gd, OpeningCG.gd, Map.gd）→ 加`_`前缀
  - OpeningCG.gd `_line_pause`未使用类变量 → 改为`line_pause_base`并标注可供外部调用

### 需求2: CRT效果太突兀难看
- **用户原话**: "模拟复古RCT电视的这个效果贴图也太突兀了超级难看有明显的分层太恶心了，你参考下风来之国的效果好吧"
- **问题**: 原CRT有厚重紫色暗角(0.45)、桶形畸变、色差、噪声带，视觉分层明显
- **修复**: 完全重写crt.gdshader，参考风来之国(Eastward)风格：
  - 仅保留细扫描线(intensity 0.06) + 极轻暗角(0.12) + 微弱闪烁(0.008)
  - 纯黑叠加无颜色偏移，最大透明度限制0.25
  - 去掉桶形畸变、色差、紫色暗角等所有突兀效果

### 需求3: BGM音质差，噪音破音，氛围不对
- **用户原话**: "BGM还是非常难听...破音噪音...氛围也太欢乐了不够贴合这个游戏"
- **用户原话**: "音乐还是很难听没任天堂的那种感觉，大部分都还是噪音"
- **问题**: 原BGM使用drone/ambient风格，大量noise层，sine波叠加产生噪音和破音
- **第一轮修复**: 重写5首BGM为暗色氛围风格，减少噪音，用sine/tri为主
- **第二轮修复(v0.2.1)**: 完全重写为任天堂8bit风格：
  - 使用经典NES音色：square 25%/12.5% duty做旋律，triangle做bass，pulse做和声
  - 写真正的旋律音符序列（不是drone），有明确的和弦进行
  - 极少使用noise（仅用于鼓组hi-hat和snare），不做噪音层
  - 参考风格：Pokemon战斗曲、Pokemon薰衣草镇、Castlevania菜单、Megaman Boss
  - battle: Dm调140BPM，方波旋律+三角波bass+脉冲琶音+鼓组
  - title: Am调90BPM，薄方波旋律+三角波bass+安静脉冲和声pad
  - map: Am调100BPM，方波旋律+行走三角波bass+轻和声
  - boss: Dm调160BPM，激进方波旋律+8分音符三角波bass+快鼓+副旋律
  - opening: Em调70BPM，阴森方波旋律+深沉三角波bass+Em和弦pad

### 需求4: 召唤卡牌没有独立形象
- **用户原话**: "召唤出来的角色形象怎么和本角色一样的"
- **问题**: 所有召唤兽共用玩家角色sprite
- **修复**: 在PixelArtGenerator中新增7种独立召唤兽sprite函数：
  - summon_fox: 橙色灵狐，尖耳蓬尾，青色眼睛
  - summon_crane: 白色仙鹤，长颈紫色翼尖
  - summon_dragon: 紫色灵龙，蛇形身段，金色装饰
  - summon_golem: 灰色石像/机器人，青色电路线
  - summon_sprite: 漂浮绿色发光精灵圆环
  - summon_clone: 暗紫色影分身轮廓
  - summon_familiar: 小黑猫，青色数据点
- BattleManager中增加card_id→sprite_type映射系统

### 需求5: 卡牌特效太重复
- **用户原话**: "每种不同的卡牌的动态效果都太重复了"
- **修复**: 为4种卡牌类型设计完全不同的VFX：
  - 攻击: 3条45度红橙斜线斩击
  - 防御: 8个蓝色方块向外扩散环
  - 术法: 12个紫金光点旋转环
  - 召唤: 绿色光柱+上升粒子

### 需求6: 英文→中文
- **描述**: 界面中仍有英文属性名称
- **修复**:
  - "Attack: " → "攻击力: "
  - "Defense: " → "防御力: "
  - "Cost: " → "算力: "
  - "ATK " → "攻:"
  - "HP " → "血:"
  - "Spell" → "术法效果"
  - 战斗文字: "战 斗 开 始" / "胜 利" / "战 败"

### 需求7: Boss效果需要更有质感
- **修复**:
  - Boss攻击VFX: 红色闪屏+8步强屏幕震动
  - Boss受击: 16px幅度震动(普通敌人8px)
  - 新增SFX: boss_attack(重低音冲击) + boss_hurt(金属撞击)
  - 敌人攻击动画: sprite向左冲刺移动

### 需求8: 开篇CG缺少音效和BGM
- **用户原话**: "开篇的画面文字故事背景加载的时候也没有对应的音效和BGM"
- **修复**:
  - 开场CG _ready()播放opening BGM
  - 每隔一个字符播放typing SFX
  - 结束转场前淡出BGM

---

## 修改文件清单 / Modified Files

### Shaders (着色器)
| File | Description |
|------|-------------|
| `Shaders/crt.gdshader` | 完全重写为风来之国风格微妙CRT（细扫描线+极轻暗角+微弱闪烁） |
| `Shaders/glitch.gdshader` | 修复#注释→//，移除fragment()中return，EVA色调Glitch效果 |
| `Shaders/yinyang_particle.gdshader` | 修复#注释→// |

### Audio (音频)
| File | Description |
|------|-------------|
| `Autoload/AudioManager.gd` | 新增typing/spell/boss_attack/boss_hurt SFX缓存，新增opening BGM缓存 |
| `Scripts/Battle/SFXGenerator.gd` | 全部5首BGM重写为任天堂8bit风格旋律；新增4个SFX函数 |

### Battle (战斗)
| File | Description |
|------|-------------|
| `Scripts/Battle/BattleManager.gd` | 4种卡牌VFX独立设计，Boss攻击/受击增强，召唤兽sprite映射，中文化 |

### Card (卡牌)
| File | Description |
|------|-------------|
| `Scripts/Card/Card.gd` | 悬停预览面板英文→中文 |

### UI (界面)
| File | Description |
|------|-------------|
| `Scripts/UI/OpeningCG.gd` | 新增BGM播放+打字音效，修复_line_pause未使用变量 |
| `Scripts/UI/Title.gd` | 修复_pink未使用变量 |
| `Scripts/UI/Map.gd` | 修复_btn未使用参数 |

### Visual (视觉)
| File | Description |
|------|-------------|
| `Scripts/Visual/PixelArtGenerator.gd` | 新增7种召唤兽独立sprite生成函数 |

---

## 未修改的核心逻辑 / Core Logic Untouched
- BattleState状态机 (INIT/PLAYER_TURN/ENEMY_TURN/RESOLVE_EFFECTS/VICTORY/DEFEAT)
- 卡牌效果系统 (EffectSystem.gd - 完全未修改)
- 敌人AI (Enemy.gd - 完全未修改)
- 阴阳平衡计算 (GameState.is_dao_resonance/is_demon_backlash)
- 能量系统 (算力上限、每回合恢复)
- 牌库管理 (Deck.gd, Hand.gd排列逻辑 - 未修改)
- 卡牌数据 (CardData.gd - 完全未修改)
- 拖拽释放逻辑 (Card._gui_input拖拽核心)
- 地图流程 (GameState.advance_node/map_nodes)
- 存档系统 (GameState.save_game/load_game)
- 所有.tres卡牌资源文件

---

## 已知问题 / Known Issues
1. 程序化像素艺术为简单几何图案，非手绘精细像素画，后续可替换为手绘资源
2. BGM为程序化生成的8bit循环（22050Hz 8bit），后续可替换为专业音乐文件
3. CRT着色器在低端设备可能有轻微性能影响，可通过master_intensity=0关闭
4. 卡牌悬停预览面板在屏幕边缘可能需要进一步位置调整
