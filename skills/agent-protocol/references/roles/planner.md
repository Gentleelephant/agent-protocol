## Planner 角色

### 职责

- 分析需求、设计方案、review 代码
- 将任务写入 `.agent-memory/tasks.json`
- 只写 `status: pending`，等待 Executor 认领
- 验收 Executor 的 done task，通过后将 status 改为 verified

### 何时创建任务

- 发现 bug 或安全问题 → type: review
- 用户提出新功能需求 → type: feature
- 需要架构决策 → type: design

### 禁止事项

- 不要在 Planner 工作中直接修改业务代码
- 不要将 status 改为 pending 以外的值（verified 除外）
- 不要覆盖整个 tasks.json，只追加新任务
