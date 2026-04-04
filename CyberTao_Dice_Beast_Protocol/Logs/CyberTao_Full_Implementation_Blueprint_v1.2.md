# CyberTao: 逻辑位元·符咒指令合成系统 (Implementation Blueprint v1.2)

**目标**: 将“卡牌构筑”与“自动化指令链”深度融合，创造一种“编写符咒代码并观看自动执行”的高爽感战斗。

---

## 1. 系统架构与数据定义 (System Architecture)

### 1.1 指令块 (Instruction Block)
骰子生成的原子操作。
```gdscript
class_name InstructionBlock
var type: String # MOVE, TURN, SCAN, EXECUTE
var value: int    # 移动格数或旋转角度
var patches: Array[LogicCard] # 该指令块上挂载的卡牌补丁
```

### 1.2 逻辑卡牌 (Logic Card / Patches)
卡牌不再独立存在，而是作为“补丁”修改指令或棋盘。
*   **Augment (增强型)**: 拖拽到指令块上。例：给 [MOVE] 增加 [潜行] 效果，移动时不触发陷阱。
*   **Logic (逻辑型)**: 修改链条结构。例：[循环补丁]——使该指令块执行两次。
*   **Field (领域型)**: 改写棋盘。例：[八卦重写]——将路径点周围变为 [震雷] 属性。

### 1.3 指令链条 (Command Chain)
单位的执行序列。
```gdscript
class_name CommandChain
var slots: Array[InstructionBlock]
var max_slots: int # 取决于骰子兽的“内存”等级
```

---

## 2. 核心战斗循环 (Core Battle Loop)

### 阶段一：算力初始化 (Roll & Draw)
1.  玩家掷骰，骰子面决定了本回合获得的 **[基础指令块]**。
2.  玩家从牌组抽取 5 张 **[逻辑补丁卡]**。

### 阶段二：编程编排 (Programming)
1.  **UI 交互**: 屏幕底部出现空槽位。
2.  **拼装指令**: 玩家将 [前进2]、[左转]、[扫描攻击] 等块拖入槽位。
3.  **注入逻辑**: 玩家将 [离火卡] 拖到 [扫描攻击] 块上。
    *   **预览效果**: 棋盘上实时显示“鬼影路径”，如果路径经过 [木属性格]，预览会显示攻击范围扩大 200%。

### 阶段三：自动化结算 (Auto-Execution)
1.  点击“开始执行”。
2.  骰子兽按照链条逐一动作。
3.  **关键点：八卦检测**
    *   每动一步，系统检测当前格子。
    *   如果 [当前格属性] + [指令块挂载的卡牌属性] 匹配，触发 **[共鸣大招]**。

---

## 3. Codex 推进任务细分 (Task Breakdown for Codex)

### 任务 A: 重构指令序列执行器 (`SequenceExecutor.gd`)
- [ ] 创建一个队列，顺序处理 `InstructionBlock`。
- [ ] 每一跳 (Tick) 需要抛出信号 `step_completed(current_pos)`。
- [ ] 集成 `Tween` 动画，确保骰子兽的移动和转向平滑。

### 任务 B: 开发卡牌挂载系统 (`CardPatchSystem.gd`)
- [ ] 实现拖拽 UI：检测卡牌是否释放到了指令块 UI 上。
- [ ] 逻辑合并：当卡牌挂载到块时，更新该块的 `final_effect` 属性。
- [ ] 实时计算预览路径 (Ghost Path)。

### 任务 C: 编写八卦共鸣逻辑 (`BaguaResonanceManager.gd`)
- [ ] 定义共鸣表（例：`WATER + THUNDER = CHAIN_LIGHTNING`）。
- [ ] 实时轮询单位位置的格子属性。
- [ ] 触发全屏特效和数值计算。

---

## 4. 关键 UI/UX 规范

1.  **指令槽 UI**: 位于屏幕底部中心，像代码行一样排列。
2.  **卡牌插槽**: 每个指令块上方有一个半透明小孔，卡牌拖上去后缩入小孔并让指令块发光。
3.  **鬼影路径 (Ghost Path)**: 使用 Shader 绘制在棋盘上，动态显示单位即将经过的路线。
4.  **共鸣爆发 (The Big Bang)**: 触发共鸣时，画面中心出现该八卦的汉字（如“震”），随后释放覆盖全屏的粒子特效。

---

## 5. 开发者提示 (Hint for Codex/Gemini)

> "在实现 `CommandChain` 时，请务必使用 `yield` 或 `await` 确保物理动画与逻辑结算同步。不要在循环中直接修改坐标，应通过 `InstructionBlock` 定义的路径进行插值移动。卡牌的逻辑注入应采用装饰者模式 (Decorator Pattern)，以动态改变指令块的行为而不破坏原始类结构。"

---

**结论**: 
此方案将卡牌的“构筑感”与棋盘的“空间感”通过“指令链”这一纽带紧密结合。它不再是两个游戏的叠加，而是一个统一的、具有深度的赛博道教战斗模拟器。
