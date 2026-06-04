# /ap:fix

这是 `/ap:execute` 的兼容别名，用于保留“修复 review 问题”的调用习惯。省略参数时匹配 claimed (`in_progress`) 或 pending 的 review 来源任务。

用户在调用本命令时传入的文本可以作为 task 选择参数，也可以作为待归一化的修复 prompt。

自然语言等价触发：

- “修复刚才 review 的第 1 个问题”
- “按照这个修复 prompt 改代码”
- “执行这条 review 修复建议”

## 工作流

1. 按 `/ap:execute [task-id|--origin review|prompt]` 的规则执行；如果传入的是修复 prompt，先归一化为 task 和 prompt artifact。
2. 有参数时等价于 `/ap:execute <task-id>`。
3. 省略参数时优先选择 `origin_command: "review"` 的活动 task。
4. 新文档和新的 `command_hint` 应优先使用 `/ap:execute`，不要继续生成新的 `/ap:fix` 提示。
