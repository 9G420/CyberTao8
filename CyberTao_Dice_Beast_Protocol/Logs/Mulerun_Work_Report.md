# Mulerun 工作报告

**日期**: 2026-03-31
**版本**: v0.1.56
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.56：美化 Phase 5 — 音效系统（AudioManager + SFXGenerator 程序化音效 + 全局接入 + BGM 切换）

---

## 根因目标

AI_Employee_Guide_v3 §6 当前最高优先级任务。游戏目前完全无音效，所有操作（掷骰/移动/攻击/出牌/遭遇/胜负）均为静默。本轮目标：从旧项目迁入 SFXGenerator 程序化音频引擎，创建 AudioManager 管理器，在 Main.gd 中将所有关键游戏事件接入对应音效，并实现棋盘/战斗/Boss 三种 BGM 自动切换。

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Scripts/System/SFXGenerator.gd` | **迁入文件**，从旧项目复制完整程序化音频引擎，~1100行 |
| `Scripts/System/AudioManager.gd` | **新增文件**，音效管理器（class_name 全局注册），~120行 |
| `Scripts/Main.gd` | 新增 _audio 成员；_ready 创建 AudioManager+启动 BGM；20+ 处信号回调接入 SFX；BGM 切换 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.56 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号+完成列表+架构+文件路径+任务优先级 |

---

## 实现内容

### SFXGenerator 程序化音频引擎（迁入）

- 从旧项目 `Scripts/Battle/SFXGenerator.gd` 原样迁入
- 28种音效生成函数 + 4种 BGM 循环生成函数
- 8bit 芯片音 + 赛博朋克合成器 + EVA 暗色环境音风格
- 所有音频运行时由 GDScript 程序化生成 AudioStreamWAV，零外部文件依赖
- class_name 全局注册，AudioManager 直接调用静态方法

### AudioManager 音效管理器（新增）

- 6通道 AudioStreamPlayer 用于 SFX 多路复用
- 1通道 AudioStreamPlayer 用于 BGM 循环
- _ready 时预生成并缓存 18 种常用音效（避免首次播放延迟）
- BGM 按需生成并缓存（bgm_map / bgm_battle / bgm_boss / bgm_title）
- API：`play_sfx(name)` / `play_bgm(name)` / `stop_bgm()` / `set_sfx_enabled(bool)` / `set_bgm_enabled(bool)`

### Main.gd 音效接入（20+ 处）

**棋盘层**：
- 移动成功 → click
- 攻击命中 → attack_hit
- 召唤成功 → summon
- 掷骰完成 → dice_roll
- 地形伤害 → player_hurt
- 敌方攻击 → player_hurt
- 道具拾取 → pickup
- 回复格 → heal
- 防御纹章 → defense
- 技能纹章 → heal
- 商店格 → shop
- 宝箱格 → chest
- 遭遇触发 → encounter
- Boss 解锁 → encounter
- 设置按钮 → click

**卡牌层**：
- 出牌 → card_play
- 敌方行动 → enemy_hurt
- 抽牌/手牌变化 → card_draw

**胜负**：
- 通关胜利 → victory
- 失败 → defeat
- 战斗胜利返回 → victory

**BGM 切换**：
- 游戏启动 → bgm_map
- 遭遇进入 → bgm_battle / bgm_boss
- 战斗结束返回棋盘 → bgm_map

---

## 接口变更

- `AudioManager` — 新增 class_name（全局注册）
- `AudioManager.play_sfx(sfx_name: String)` — 播放一次性音效
- `AudioManager.play_bgm(bgm_name: String)` — 播放/切换 BGM
- `AudioManager.stop_bgm()` — 停止 BGM
- `AudioManager.set_sfx_enabled(enabled: bool)` — SFX 开关
- `AudioManager.set_bgm_enabled(enabled: bool)` — BGM 开关
- `SFXGenerator` — class_name 全局注册（从旧项目迁入，接口不变）

---

## 测试确认

- 棋盘层闭环（掷骰/移动/攻击/召唤/敌方回合/地形/道具/回复/商店/宝箱/遭遇/Boss解锁）各环节音效正确触发
- 卡牌层闭环（进入战斗/出牌/敌方行动/抽牌）各环节音效正确触发
- BGM 切换：棋盘 bgm_map → 遭遇 bgm_battle → 返回 bgm_map；Boss 遭遇切 bgm_boss
- 胜利/失败音效正确触发
- 多通道复用：快速连续操作不会丢失音效（6通道轮替）
- 所有子模块零修改验证：BattleFlowController / CardBattleController / BoardView / CardBattlePanel / 各 UI 面板

---

## 剩余问题

- 层间难度暂不递增
- 阵亡单位跨层不复活
- CardRewardPanel 暂未使用 CardRenderer 风格
- 扇形手牌暂无拖拽机制（仅点击出牌）
- 角色立绘为程序化绘制
- SettingsPanel 暂未添加音量/音效开关控件（AudioManager 已预留 API）

---

## 建议下一步

1. 层间难度递增（根据 current_floor 调整敌方 HP/ATK）
2. 商店格扩展（多选商品 + 独立 UI 面板）
3. SettingsPanel 添加音量滑块 + SFX/BGM 开关
