## 任务创建阶段（兼容旧引用）

这个文件保留给旧引用路径使用，但当前协议默认不要求独立 Planner 角色。

### 职责

- 分析需求、设计方案、review 代码
- 将任务写入 `.agent-memory/tasks.json`
- 将完整分析和 review 结果写入 `.agent-memory/artifacts/`
- 为每个可执行问题生成 `execution_prompt` artifact

### 工作流

1. 读取已安装的 `agent-protocol` skill。
2. 读取并尽量校验 `.agent-memory/tasks.json`。
3. 确保 `.agent-memory/artifacts/` 及对应子目录存在。
4. 根据用户意图创建 `review`、`feature`、`design` 或 `bug` task。
5. 为新 task 填写明确的 `context` 和可执行的 `spec`。
6. 对 `/ap:review`、`/ap:plan` 新建的每个可执行 task，再额外生成一个 `execution_prompt` artifact，保存到 `.agent-memory/artifacts/prompt/`。
7. 为 `/ap:review`、`/ap:plan` 生成对应 artifact，并把引用写入相关 task。
8. 如需排序，填写 `priority`；默认使用 `medium`。
9. 只追加 task，不重写历史任务。

### 兼容规则

- 新任务默认写 `created_by: "agent"`。
- 旧任务若仍是 `created_by: "planner"`，按兼容模式继续读取。
- 不再根据 agent 身份做角色门禁。
