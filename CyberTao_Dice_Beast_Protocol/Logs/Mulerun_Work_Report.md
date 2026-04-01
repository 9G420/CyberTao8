# Mulerun 工作报告

**日期**: 2026-04-02
**版本**: v0.1.86
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.86：优化 BGM 与音效听感，降低刺耳度与整体炸耳问题

---

## 根因目标

用户反馈当前程序化 BGM/SFX 听感“太难听、耳朵要炸”。

分析结果：
1) 默认音量偏高（尤其 SFX）；
2) 多条 BGM 使用方波/窄脉冲主旋律，齿音较重；
3) 鼓组噪声（snare/hat）在高频段偏突出；
4) 个别缓存音效（dice_roll/boss_attack）本身音色激进。

本轮目标：不改架构前提下，通过“音量下调 + 波形柔化 + 噪声减量 + 映射替换”四步先把听感拉回可接受区间。

服务层：系统层（AudioManager + SFXGenerator）/ UI 设置层

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Scripts/System/AudioManager.gd` | 默认音量下调（BGM -18dB / SFX -12dB）；替换刺耳缓存映射（dice_roll / boss_attack / player_hurt） |
| `Project/Scripts/System/SFXGenerator.gd` | battle/title/map/boss 四条 BGM：主旋律改三角波、snare/hat 降噪、总增益下调 |
| `Project/Scripts/UI/SettingsPanel.gd` | 默认滑块改为 BGM 18%、SFX 35%；重置默认同步改为 18%/35% |
| `Logs/changelog_v0.1.md` | 追加 v0.1.86 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号 + §2.2 完成状态 + §6 任务优先级 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |

---

## 实现内容

### 1) 默认响度下调（先止血）

- AudioManager：
  - `BGM_VOLUME_DB: -12.0 -> -18.0`
  - `SFX_VOLUME_DB: -6.0 -> -12.0`
- SettingsPanel 默认值：
  - BGM：25% -> 18%
  - SFX：50% -> 35%
- Reset 默认同步：
  - `set_bgm_volume(0.18)`
  - `set_sfx_volume(0.35)`

### 2) 刺耳音效映射替换

- `dice_roll`：从 `generate_cyber_glitch_sfx()` 改为 `generate_draw_sfx()`（降低尖锐噪声）
- `boss_attack`：改为 `generate_attack_sfx()`（保留攻击感，减轻爆裂感）
- `player_hurt`：改为较温和的 `generate_enemy_hurt_sfx()`

### 3) BGM 波形柔化 + 噪声减量

对 4 条主 BGM（battle/title/map/boss）统一做：
- 主旋律从方波/窄脉冲改三角波（降低齿音）
- snare/hat 噪声音量降低
- 输出总增益下调

目标是先把“刺耳疲劳”压下去，同时保留节奏语义。

---

## 接口变更

- 无新增公开接口/信号。
- 仅参数与内部生成策略调整，调用方无需改动。

---

## 测试确认

### 听感自查（代码路径）

| 测试项 | 结果 |
|--------|------|
| 默认 BGM/SFX 初始响度明显下降 | ✅ |
| 设置面板默认值与重置值一致（18%/35%） | ✅ |
| battle/title/map/boss 四条 BGM 均完成波形柔化 | ✅ |
| 主要高刺耳缓存音效已替换 | ✅ |
| 音效系统 API 与调用链保持兼容 | ✅ |

---

## 剩余问题

- 纯程序化音频的上限仍低于高质量外部音乐资源（这是架构上限，不是单次参数能完全解决）。
- 目前是“一刀切降刺耳”，后续可按场景做更细化母线均衡（如战斗/地图分开 EQ）。

---

## 建议下一步

1. 增加“音色模式”选项：Classic（复古）/ Soft（柔和）/ Punch（强打击）。
2. 引入可选外部 BGM 资源（程序化保底 fallback）。
3. 为关键 SFX 增加轻度低通 + 瞬态限制器，进一步避免尖峰刺耳。
