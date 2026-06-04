# /ap:plan

分析需求或架构，创建 feature/design task。省略 requirement 时从最近对话上下文提取。此命令会同时写入 `.agent-memory/artifacts/plan/` 下的 plan artifact，并为每个可执行 task 生成 `.agent-memory/artifacts/prompt/` 下的执行 prompt artifact。

用户在调用本命令时传入的文本作为 requirement。

自然语言等价触发：

- “根据这个需求结合项目代码整理开发计划”
- “结合当前代码拆解实现方案”
- “给我一组可以让别的 agent 直接执行的开发 prompt”

## 工作流

1. 读取 `.agent-memory/agent-protocol.md`（如存在）。
2. 加载 `.agent-memory/tasks.json`。
3. 确保 `.agent-memory/artifacts/plan/` 和 `.agent-memory/artifacts/prompt/` 存在。
4. 分析需求，创建 task（type: `feature` 或 `design`），追加到 tasks 数组。
5. 为本次分析生成 artifact，记录拆解依据、方案权衡和最终任务集合。
6. 为每个 task 生成一个 `execution_prompt` artifact，要求目标、来源摘要、任务契约快照、范围、约束、建议实现方式、验证标准都明确，并写明推荐执行命令（通常是 `/ap:execute <task-id>`）。
7. 设置 `status: "pending"`、`created_by: "agent"`，填充 `id`、`title`、`context`、`spec`、`origin_command`、`origin_artifact_id`、`prompt_artifact_id`、`source_summary`、`acceptance`、`depends_on`，并把 plan artifact 和 prompt artifact 引用写入相关 task。
8. 不修改业务代码。
