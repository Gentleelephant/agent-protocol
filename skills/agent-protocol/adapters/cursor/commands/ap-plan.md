# /ap-plan

Cursor command equivalent of `/ap:plan`.

分析需求或架构，创建 feature/design task。把用户在命令后补充的文本视为 requirement。此命令会同时写入 `.agent-memory/artifacts/plan/` 下的 plan artifact，并为每个可执行 task 生成 `.agent-memory/artifacts/prompt/` 下的执行 prompt artifact。

如果用户意图是以下任一项，按 `/ap:plan` 语义处理：

- “按 agent-protocol 根据这个需求结合项目代码整理开发计划”
- “按 agent-protocol 结合当前代码拆解实现方案”
- “给我一组可以让别的 agent 直接执行的开发 prompt 并持久化 task”

## 工作流

1. 读取 `.agent-memory/agent-protocol.md`（如存在）。
2. 加载 `.agent-memory/tasks.json`。
3. 确保 `.agent-memory/artifacts/plan/` 和 `.agent-memory/artifacts/prompt/` 存在。
4. 分析需求，创建 task（type: `feature` 或 `design`），追加到 tasks 数组。
5. 为本次分析生成 artifact，记录拆解依据、方案权衡和最终任务集合。
6. 为每个 task 生成 `execution_prompt` artifact，要求目标、来源摘要、任务契约快照、范围、约束、建议实现方式、验证标准都明确，并写明推荐执行命令。
7. 设置 `status: "pending"`、`created_by: "agent"`，填充必要字段并写入 artifact 引用。
8. 不修改业务代码。
