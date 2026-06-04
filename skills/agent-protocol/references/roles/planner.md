## 任务创建阶段

### 职责

- 分析需求、设计方案、review 代码
- 将任务写入 `.agent-memory/tasks.json`
- 将完整分析和 review 结果写入 `.agent-memory/artifacts/`
- 为每个可执行问题生成 `execution_prompt` artifact

### 工作流

1. 读取已安装的 `agent-protocol` skill。
2. 读取并尽量校验 `.agent-memory/tasks.json`。
3. 确保 `.agent-memory/artifacts/` 及对应子目录存在。
4. 根据用户意图创建 `bug`、`feature` 或 `design` task；旧 `review` task 仅兼容读取。
5. 为新 task 填写明确的 `context`、可执行的 `spec`，以及 `origin_command`、`origin_artifact_id`、`prompt_artifact_id`、`source_summary`、`acceptance`、`depends_on`。
6. 对 `/ap:review`、`/ap:plan` 新建的每个可执行 task，再额外生成一个 `execution_prompt` artifact，保存到 `.agent-memory/artifacts/prompt/`。prompt 必须包含来源摘要和任务契约快照。
7. 为 `/ap:review`、`/ap:plan` 生成对应 artifact，并把引用写入相关 task。
8. 如需排序，填写 `priority`；默认使用 `medium`。
9. 只追加 task，不重写历史任务。

### 兼容规则

- 新任务统一写 `created_by: "agent"`。
- 不根据 agent 身份做角色门禁。
