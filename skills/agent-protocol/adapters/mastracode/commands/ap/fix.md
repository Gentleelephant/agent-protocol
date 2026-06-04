---
name: ap:fix
description: "Fix a specific bug or review task. Any agent."
argument-hint: "[task-id]"
---

# /ap:fix

修复指定 bug/review task。省略参数时匹配 claimed (`in_progress`) 或 pending bug/review task。

如果当前 agent 不支持 `/ap:` 子命令，则以下自然语言请求应触发同样效果：

- “修复刚才 review 的第 1 个问题”
- “按照这个修复 prompt 改代码”
- “执行这条 review 修复建议”

## 工作流

1. 读取 `.agent-memory/agent-protocol.md`（如存在）。
2. 加载 `.agent-memory/tasks.json`。
3. 确保相关 artifact 目录存在，修复后的验证和完成总结写入 `.agent-memory/artifacts/done/`。
4. 定位 task：有参数按 task-id 查找，省略时找 type 为 `bug` 或 `review` 的 `in_progress` 或 `pending` task。
5. 若 task 的 `artifact_refs` 中存在 `execution_prompt` artifact，先读取该 prompt，优先把它当作直接执行说明；若它与 `task.spec` 冲突，以 `task.spec` 为准并报告不一致。
6. 改为 `in_progress`，按 `spec` 和关联 prompt 修复。
7. 完成后记录验证结果，写入完成 artifact，并将任务标记为 `done`。
