# CyberTao: Dice Beast Protocol - 美术与表现推进策略

**更新日期**: 2026-04-02
**当前基线**: v0.1.105
**适用范围**: 2D/3D 棋盘表现、卡牌战斗界面、商店/奖励/HUD、音频氛围

> 本文已按当前代码基线重写。旧文档里的 Phase 1~6 目标已经完成，现在只记录当前视觉现状、后续优先级和实现约束。

---

## 1. 当前视觉基线

项目当前不再是“纯调试原型”，而是“程序化视觉为主、少量外部资源辅助”的可玩版本。

| 层级 | 当前状态 | 说明 |
|------|----------|------|
| 2D 棋盘 | 已稳定 | `BoardView.gd` + `IsoTileRenderer.gd`，支持等距棋盘、外场台座、高亮、反馈、相机拖拽 |
| 3D 棋盘 | 已接通 | `BoardView3D.gd` + `TileMeshFactory3D.gd` + `UnitMeshFactory3D.gd`，支持 F5 切换、拖拽、缩放、基础反馈 |
| 单位表现 | 已升级 | 2D 和卡牌战斗均已复用像素化单位纹理，3D 侧使用 billboard 纹理与程序化模型 |
| 卡牌战斗界面 | 已稳定 | `CardBattlePanel.gd`、`CardRenderer.gd`、`CardRewardPanel.gd` 已可用，支持拖拽出牌与奖励选牌 |
| 辅助面板 | 已可用 | 商店、牌组、设置、顶部头像 HUD 全部接入主流程 |
| 音频氛围 | 已可用 | `AudioManager.gd` + `SFXGenerator.gd`，并支持外部 BGM 文件优先加载 |

---

## 2. 当前主要视觉债务

### 2.1 2D 与 3D 反馈强度不一致

- 2D 侧的命中、悬停、格子识别、外场层次更完整。
- 3D 侧已经可玩，但部分反馈仍是占位实现或简化版本。

### 2.2 多个面板的风格语言还不够统一

- `CardBattlePanel`、`CardRewardPanel`、`DeckViewPanel`、`ShopPanel` 已能使用，但“同一系统”的视觉关系还不够强。
- 卡牌、奖励、商店商品的类型色和信息层级仍可进一步统一。

### 2.3 棋盘外场氛围已经建立，但信息分层还能更清晰

- 目前外场台座、四角结构件和背景装饰已经补上。
- 下一步不是继续堆装饰，而是让“可互动格子”“敌方威胁”“Boss 路线”更一眼可读。

### 2.4 表现逻辑分布较散

- 当前表现层代码分散在 `Main.gd`、`BoardView.gd`、`BoardView3D.gd`、`UI/`、`UI3D/`。
- 如果继续把特效触发写回入口层，会明显提高后续维护成本。

---

## 3. 下一阶段优先级

### P0：统一可读性与反馈

优先处理：

- 统一 2D / 3D 的选中、攻击、召唤、受击反馈强度。
- 统一 Boss / 传送门 / 商店 / 宝箱 / 事件 / 回复格在 2D 与 3D 中的识别语言。
- 强化 3D 侧的命中反馈、治疗反馈、商店与宝箱反馈，减少“逻辑触发了但手感偏空”的感觉。

### P1：统一卡牌相关界面

目标：

- 让 `CardBattlePanel`、`CardRewardPanel`、`DeckViewPanel`、`ShopPanel` 使用更一致的色彩、标题、边框和信息分区。
- 让“卡牌”“商品”“升级选项”这三类对象在信息密度上更接近，不再各写一套视觉语法。

### P2：整理棋盘环境表现

目标：

- 继续做“舞台感”而不是“堆景物”。
- 优先处理棋盘内外边界、Boss 路线、敌方威胁方向、关键事件格辨识。
- 外场装饰只在不抢主体信息的前提下补充。

### P3：建立更稳定的资产策略

当前项目已经同时存在：

- 程序化几何和绘制
- 程序化像素纹理
- 外部音频资源

后续如果新增图片、贴图、音频或 UI 素材，必须先写清：

- 来源
- 风格目的
- 回退方案
- 是否会影响 `gl_compatibility` 路径

---

## 4. 文件归属建议

| 路径 | 责任 |
|------|------|
| `Project/Scripts/UI/BoardView.gd` | 2D 棋盘输入、2D 相机、2D 反馈触发 |
| `Project/Scripts/UI/IsoTileRenderer.gd` | 2D 棋盘与外场绘制语言 |
| `Project/Scripts/UI/UnitRenderer.gd` | 2D 单位绘制与纹理复用 |
| `Project/Scripts/UI/CardRenderer.gd` | 卡牌视觉语法 |
| `Project/Scripts/UI/CardBattlePanel.gd` | 卡牌战斗主界面表现 |
| `Project/Scripts/UI/CardRewardPanel.gd` | 奖励与升级界面表现 |
| `Project/Scripts/UI/DeckViewPanel.gd` | 牌组展示 |
| `Project/Scripts/UI/ShopPanel.gd` | 商店界面与商品呈现 |
| `Project/Scripts/UI3D/BoardView3D.gd` | 3D 棋盘输入、3D 相机、3D 反馈触发 |
| `Project/Scripts/UI3D/TileMeshFactory3D.gd` | 3D 格子造型语言 |
| `Project/Scripts/UI3D/UnitMeshFactory3D.gd` | 3D 单位与像素纹理生成 |
| `Project/Scripts/System/AudioManager.gd` | BGM/SFX 管理与播放策略 |

---

## 5. 技术硬规则

- 逻辑和表现继续分离，不把纯表现逻辑反向塞回 `BattleFlowController.gd`。
- 新颜色优先复用 `CyberStyle`，不要每个面板私自扩散配色体系。
- 保持 `1280x720` 的现有布局基线，不随意改整体坐标体系。
- 继续兼容 `gl_compatibility`，避免引入依赖更高渲染特性的方案。
- 若新增外部资产，必须写入日志说明来源和用途。
- 若只为改善表现，优先做局部可验证改动，不做整层推倒重来。

---

## 6. 完成标准

当下一轮表现优化完成时，应至少满足：

1. 2D 与 3D 的关键反馈差距明显缩小。
2. 卡牌、奖励、商店、牌组四类界面不再像四套独立设计。
3. 棋盘主体信息优先级高于背景装饰。
4. 入口层没有继续因为表现需求明显膨胀。
5. 新增视觉资产和风格决策都能在日志里追溯。

---

## 7. 当前建议

如果下一轮继续做表现层，推荐顺序：

1. 先补 3D 反馈与 2D/3D 可读性统一。
2. 再统一卡牌相关面板的视觉语法。
3. 最后再考虑新增更重的场景氛围和素材投入。
