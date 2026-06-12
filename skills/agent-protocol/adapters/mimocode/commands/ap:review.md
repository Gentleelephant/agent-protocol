---
description: Review code and create bug tasks. Any agent.
---

# /ap:review

审查代码并创建 bug task。省略 scope 时审查整个项目或当前未提交变更。此命令会同时写入 `.agent-memory/artifacts/review/` 下的 review artifact，并为每个可执行问题生成 `.agent-memory/artifacts/prompt/` 下的修复 prompt artifact。`review` task type 仅兼容旧 task，新 task 不得使用。

调用本命令时，把 `/ap:review` 后的文本视为 scope：`$ARGUMENTS`。

如果当前 agent 不支持 `/ap:` 子命令，则以下自然语言请求应触发同样效果：

- “按 agent-protocol review 这段代码”
- “按 agent-protocol 检查这个模块并生成修复 task”
- “审查最近改动并持久化可执行修复项”

## 工作流

1. 读取 `.agent-memory/agent-protocol.md`（如存在）。
2. 加载 `.agent-memory/tasks.json`。
3. 确保 `.agent-memory/artifacts/review/` 和 `.agent-memory/artifacts/prompt/` 存在。
4. 检查代码，发现问题创建 task（新 task 优先使用 type: `bug`；旧 `review` task 仅兼容读取），追加到 tasks 数组。
5. 为本次 review 生成 artifact，记录完整审查结论、问题列表、严重级别、涉及文件。
6. 为每个可执行问题单独生成一个 `execution_prompt` artifact，要求来源摘要清晰、边界清晰、问题描述清晰、建议修复方式清晰，并写明推荐执行命令（通常是 `/ap:execute <task-id>`）。
7. 设置 `status: "pending"`、`created_by: "agent"`，填充 `id`、`title`、`context`、`spec`、`origin_command`、`origin_artifact_id`、`prompt_artifact_id`、`source_summary`、`acceptance`、`depends_on`，并把 review artifact 和 prompt artifact 引用都写入 `artifact_refs`。
8. 更新相关 task 的 `last_reviewed_at`。
9. 不修改业务代码，仅创建 bug task。
