---
name: ap:tasks
description: "List tasks by status. Read-only, any role."
argument-hint: "[status]"
---

# /ap:tasks

列出任务。通用只读命令，任何角色均可执行。省略 status 时列出所有任务。

支持过滤：`pending`、`in_progress`、`blocked`、`done`、`verified`、`cancelled`。
