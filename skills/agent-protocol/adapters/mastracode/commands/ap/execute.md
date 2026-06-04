---
name: ap:execute
description: "Claim and execute pending tasks. Any agent."
argument-hint: "[task-id|next]"
---

# /ap:execute

认领并执行 pending task。省略参数时默认为 `next`。

如果当前 agent 不支持 `/ap:` 子命令，则以下自然语言请求应触发同样效果：

- “执行刚才 plan 生成的第 2 个任务”
- “按照这个开发 prompt 去实现”
- “根据这个 task 继续做代码实现”

## 工作流

1. 读取 `.agent-memory/agent-protocol.md`（如存在）。
2. 加载 `.agent-memory/tasks.json`。
3. 确保相关 artifact 目录存在，执行结果和验证结果会写入 `.agent-memory/artifacts/done/`。
4. 选择 task：按 `priority`（high > medium > low）排序，同优先级按 `created_at` 升序。
5. 若 task 的 `artifact_refs` 中存在 `execution_prompt` artifact，先读取该 prompt，优先把它当作直接执行说明；若它与 `task.spec` 冲突，以 `task.spec` 为准并报告不一致。
6. 将选中的 task 改为 `in_progress`。
7. 按 `spec` 和关联 prompt 实现，运行验证，并把完成总结写入 artifact 和 `implementation_notes` 摘要。
8. 不修改任务契约字段。
