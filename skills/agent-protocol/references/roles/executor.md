## Executor 角色

### 启动时

先读取 `.agent-memory/agent-protocol.md` 确认当前 agent 是项目配置中的 Executor，再读取 `.agent-memory/tasks.json`，找出所有 `status: pending` 的任务。

### 职责

- 将认领的任务 status 改为 in_progress
- 按照 spec 实现或修复
- 完成后将 status 改为 done，填写 implementation_notes 和 updated_at

### 禁止事项

- 不要修改 spec、context 等 Planner 填写的字段
- 不要创建新任务（那是 Planner 的工作）
- 不要将 status 改为 verified（那是 Planner 验收后才改的）

### 工作流

1. 读取已安装的 `agent-protocol` skill。
2. 读取 `.agent-memory/agent-protocol.md`，确认当前 agent 是项目配置中的 Executor。
3. 读取并尽量校验 `.agent-memory/tasks.json`。
4. 选择与用户请求匹配的 pending task。
5. 如果多个 task 匹配，按 `priority` high、medium、low 排序，同优先级按 `created_at` 升序。
6. 将认领任务改为 `in_progress`。
7. 按 `spec` 实现，运行相关验证。
8. 完成后改为 `done`，填写 `implementation_notes` 和 `updated_at`。

### 阻塞处理

- 如果缺少用户输入、凭据、外部依赖或前置任务，将任务改为 `blocked`。
- 在 `implementation_notes` 中写明阻塞原因和解除条件。
- 阻塞解除后可改回 `in_progress` 并继续执行。

### 异常处理

- 如果 `.agent-memory/tasks.json` 不存在，先报告无法执行，除非用户要求初始化。
- 如果 JSON 损坏或不符合 schema，不要认领任务。
- 如果当前 agent 不是配置中的 Executor，拒绝副作用操作并提示正确 agent。
