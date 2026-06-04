---
name: ap:fix
description: "Compatibility alias for /ap:execute when handling review-derived tasks. Any agent."
argument-hint: "[task-id]"
---

# /ap:fix

这是 `/ap:execute` 的兼容别名，用于保留“修复 review 问题”的调用习惯。省略参数时匹配 claimed (`in_progress`) 或 pending 的 review 来源任务。

如果当前 agent 不支持 `/ap:` 子命令，则以下自然语言请求应触发同样效果：

- “修复刚才 review 的第 1 个问题”
- “按照这个修复 prompt 改代码”
- “执行这条 review 修复建议”

## 工作流

1. 按 `/ap:execute [task-id|--origin review|prompt]` 的规则执行；如果传入的是修复 prompt，先归一化为 task 和 prompt artifact。
2. 有参数时等价于 `/ap:execute <task-id>`。
3. 省略参数时优先选择 `origin_command: "review"` 的活动 task。
4. 新文档和新的 `command_hint` 应优先使用 `/ap:execute`，不要继续生成新的 `/ap:fix` 提示。
