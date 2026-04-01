# Mulerun 工作报告

**日期**: 2026-04-02
**版本**: v0.1.87
**分支**: `codex/dice-beast-protocol`

---

## 本轮任务

- v0.1.87：启用用户提供外部 BGM，临时替换程序化 BGM

---

## 根因目标

用户反馈程序化 BGM 仍不理想，要求先使用提供的 MP3 音轨。

目标：快速落地“可听”的 BGM 方案，不改变现有播放调用链。

服务层：系统层（AudioManager 资源加载）

---

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `Project/Audio/bgm_tension_fast.mp3` | 新增用户提供音轨（从 inbound 导入项目） |
| `Project/Scripts/System/AudioManager.gd` | BGM 改为优先加载外部音轨，失败回退程序化生成；四类 BGM 暂统一映射到该 MP3 |
| `Logs/changelog_v0.1.md` | 追加 v0.1.87 条目 |
| `Logs/AI_Employee_Guide_v3.md` | 同步版本号 + §2.2 完成状态 + §6 任务优先级 |
| `Logs/Mulerun_Work_Report.md` | 本文件 |

---

## 实现内容

### 1) 外部 BGM 资源接入

- 将用户提供文件加入项目：
  - `res://Audio/bgm_tension_fast.mp3`

### 2) AudioManager 加载策略升级

- `_get_or_generate(name)` 改为：
  1. 先尝试 `_try_load_external_bgm(name)`
  2. 若加载失败，再按原逻辑回退 `SFXGenerator.generate_*_bgm_loop()`

### 3) 当前映射策略（临时统一）

- `bgm_battle / bgm_map / bgm_boss / bgm_title` → 统一使用 `bgm_tension_fast.mp3`

目的：你现在马上就能摆脱程序化 BGM 的刺耳问题，先保证听感可接受。

---

## 接口变更

- 无外部 API 变更。
- `play_bgm("bgm_xxx")` 调用方式不变，仅内部音源选择逻辑变更。

---

## 测试确认

| 测试项 | 结果 |
|--------|------|
| 外部音轨文件已进入项目目录 | ✅ |
| AudioManager 优先走外部 BGM 加载 | ✅ |
| 外部资源缺失时仍会回退程序化 BGM（容错） | ✅ |
| Main 侧 BGM 切换调用无需改动 | ✅ |

---

## 剩余问题

- 当前 map/battle/boss/title 使用同一条 BGM，仅作为快速过渡方案。
- 未实现“每场景独立音轨 + 淡入淡出过渡”优化。

---

## 建议下一步

1. 你再给 2~3 条风格音轨，我帮你按场景拆分：map/battle/boss/title。
2. 加一个 BGM crossfade（0.4~0.8s）避免切歌突兀。
3. 设置面板增加“外部BGM优先/程序化优先”切换项。
