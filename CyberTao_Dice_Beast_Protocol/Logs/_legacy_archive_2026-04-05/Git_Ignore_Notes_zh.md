# Git 噪音文件说明（中文）

为避免 Godot 测试时反复产生大量无意义改动，仓库根 `.gitignore` 已加入以下忽略规则：

- `*.uid`
- `*.import`
- `CyberTao_Dice_Beast_Protocol/Signals/*.json`
- `CyberTao_Dice_Beast_Protocol/Signals/*.log`

## 这些文件是什么

### `.uid`

Godot 自动生成的本地标识文件。  
多数情况下只是编辑器噪音，不是正式业务改动。

### `.import`

Godot 导入缓存/导入状态文件。  
测试或重新打开项目时很容易反复出现。

### `Signals/*.json` / `Signals/*.log`

这是本地 Mulerun 监听器写入的临时信号文件，用来提醒“网页代理已完成”，不属于项目正式资源。

## 以后提交时应该关注什么

优先关注真正业务文件：

- `.gd`
- `.tscn`
- `.tres`
- `.md`

## 结论

以后如果只是测试 Godot 或运行监听器，GitHub Desktop 不应该再被这些噪音文件刷屏。  
如果仍然看到它们，先确认 `.gitignore` 已同步到本地并生效。
