# Mulerun Start Prompt

Copy the prompt below into Mulerun when starting or continuing work on this project.

---

```text
我正在开发一个新的 Godot 4.6.1 项目，工作命名为：

CyberTao: Dice Beast Protocol

仓库：
https://github.com/9G420/CyberTao8

当前工作分支：
codex/dice-beast-protocol

主工作目录：
CyberTao_Dice_Beast_Protocol/Project/

重要说明：
这个仓库里现在同时存在两个项目：

1. 旧项目 `CyberTao8`
- 是原来的 Godot 项目
- 已完成较多 STS-like 卡牌 Roguelike 内容
- 仅作为参考基线
- 不要随意修改旧战斗系统或旧核心文件，除非我明确要求

2. 新项目 `CyberTao_Dice_Beast_Protocol/`
- 这是新的并行重构项目
- 当前主要开发工作全部在这个目录下进行

请先执行以下步骤：

1. 拉取仓库并切换到分支 `codex/dice-beast-protocol`
2. 先阅读以下文件：
- `CyberTao_Dice_Beast_Protocol/README.md`
- `CyberTao_Dice_Beast_Protocol/Docs/TECH_REBUILD_BLUEPRINT.md`
- `CyberTao_Dice_Beast_Protocol/Logs/CyberTao_Migration_Snapshot.md`
- `CyberTao_Dice_Beast_Protocol/Logs/changelog_v0.1.md`
- `CyberTao_Dice_Beast_Protocol/Logs/Mulerun_Handoff_Template.md`

3. 把旧项目以下文件作为参考阅读，但不要直接继续往旧系统里堆功能：
- `Scripts/Battle/BattleManager.gd`
- `Scripts/Visual/PixelArtGenerator.gd`
- `Autoload/GameState.gd`
- `Scripts/UI/UIFactory.gd`

新项目定位：
这是一个赛博朋克×道教×CN meme×cyber furry 风格的战术 Roguelike 原型，融合：
- 骰子资源生成
- 怪兽棋盘战斗
- 斗兽棋/战棋式推进
- 卡牌式构筑
- buff道具拾取
- meme单位与兽人阵营风格

当前新项目的核心方向：
- 外层保留 Roguelike 结构
- 单场战斗改成棋盘制
- 每回合掷骰获得资源
- 资源类型包括：召唤、移动、攻击、防御、技能、机巧
- 单位在棋盘上移动、攻击、占位、拾取道具
- 召唤不只是下怪，还要带有“铺路/路径块扩展”
- 卡牌将逐步转化为单位卡、技能卡、道具卡、核心模块卡

当前新项目已完成内容：
- 已创建独立 Godot 子项目：
  - `CyberTao_Dice_Beast_Protocol/Project/project.godot`
- 已创建入口场景：
  - `Scenes/Main.tscn`
  - `Scripts/Main.gd`
- 已创建 BattleV2 架构脚手架：
  - `Scripts/BattleV2/BattleFlowController.gd`
  - `Scripts/BattleV2/DiceManager.gd`
  - `Scripts/BattleV2/BoardManager.gd`
  - `Scripts/BattleV2/UnitManager.gd`
  - `Scripts/BattleV2/ActionResolver.gd`
  - `Scripts/BattleV2/BuffManager.gd`
  - `Scripts/BattleV2/BattleAI.gd`
- 已创建数据资源类：
  - `Scripts/Data/UnitData.gd`
  - `Scripts/Data/SkillData.gd`
  - `Scripts/Data/ItemData.gd`
  - `Scripts/Data/CoreData.gd`
  - `Scripts/Data/DiceFaceData.gd`
- 已有第一批可见原型：
  - 可视化 8x8 棋盘
  - 右侧骰子调试面板
  - 第一只原型单位资源：`blade_shield_dog.tres`（刀盾狗）
  - 棋盘上已有玩家测试单位和敌方测试单位
  - 可点击按钮进行掷骰与生成 demo path 的调试

当前最高优先级任务：
1. 让棋盘支持点击格子
2. 让 `MOVE` 资源真正驱动单位移动
3. 继续完善“刀盾狗”原型技能
4. 建立最小战斗闭环：
   - 掷骰
   - 获得资源
   - 生成路径
   - 移动单位
   - 攻击
   - 回合切换

首批原型阵营方向：
- 刀盾狗：前排、防反、推进、抽象硬汉风
- 灵狐骇客：位移、偷资源、控制
- 鸦机术士：远程、陷阱、Debuff
- 虎机斗士：冲锋、爆发、斩首

技术注意事项（非常重要）：
- Godot 4.6.1 中，`:=` 不要用于数组字面量、字符串拼接、untyped 数组索引，必须显式类型声明
- 不要使用 `btn.flat = true`，否则 `StyleBoxFlat` 背景不会渲染
- `await` 不要调用不存在的函数，否则协程会永久挂起
- Tween 必须优先使用 `node.create_tween()`
- 新模式不要继续塞进旧的 `BattleManager.gd`
- 旧项目只作参考，不要破坏原有版本
- 所有新开发默认都放在 `CyberTao_Dice_Beast_Protocol/Project/`
- 每次有明显开发推进后，更新：
  - `CyberTao_Dice_Beast_Protocol/Logs/changelog_v0.1.md`
- 如果架构、方向或阶段状态有明显变化，也更新：
  - `CyberTao_Dice_Beast_Protocol/Logs/CyberTao_Migration_Snapshot.md`

工作方式要求：
- 先阅读和总结理解，不要直接乱改
- 先说明你理解到的当前项目状态，再开始动手
- 不要随意修改旧项目
- 优先做最小可运行原型
- 每次修改后说明：
  - 改了哪些文件
  - 为什么这样改
  - 下一步建议
- 如果发现设计冲突或结构问题，请先指出再行动

如果你接手时上下文不完整，请优先输出：
1. 你对当前项目的理解
2. 当前最合理的下一步
3. 你准备如何实现

请先阅读并总结当前新项目状态，等我确认后再继续实现。
```

---

Recommended use:

- Use this as the startup prompt for a fresh Mulerun account.
- Pair it with the latest migration snapshot and changelog.
- Update this file when the project's architecture or priorities significantly change.
