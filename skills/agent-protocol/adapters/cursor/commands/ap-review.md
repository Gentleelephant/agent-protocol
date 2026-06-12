# /ap-review

Cursor command equivalent of `/ap:review`.

审查代码并创建 bug task。把用户在命令后补充的文本视为 scope。省略时审查整个项目或当前未提交变更。此命令会同时写入 `.agent-memory/artifacts/review/` 下的 review artifact，并为每个可执行问题生成 `.agent-memory/artifacts/prompt/` 下的修复 prompt artifact。

如果用户意图是以下任一项，按 `/ap:review` 语义处理：

- “按 agent-protocol review 这段代码”
- “按 agent-protocol 检查这个模块并生成修复 task”
- “审查最近改动并持久化可执行修复项”

## 工作流

1. 读取 `.agent-memory/agent-protocol.md`（如存在）。
2. 加载 `.agent-memory/tasks.json`。
3. 确保 `.agent-memory/artifacts/review/` 和 `.agent-memory/artifacts/prompt/` 存在。
4. 检查代码，发现问题创建 task（新 task 优先使用 type: `bug`），追加到 tasks 数组。
5. 为本次 review 生成 artifact，记录完整审查结论、问题列表、严重级别、涉及文件。
6. 为每个可执行问题单独生成 `execution_prompt` artifact，并写明推荐执行命令。
7. 设置 `status: "pending"`、`created_by: "agent"`，填充必要字段并写入 artifact 引用。
8. 不修改业务代码，仅创建 bug task。
