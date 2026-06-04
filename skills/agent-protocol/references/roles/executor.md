## 实现阶段（兼容旧引用）

这个文件保留给旧引用路径使用，但当前协议默认不要求独立 Executor 角色。

### 职责

- 将认领的任务 status 改为 `in_progress`
- 按照 `spec` 和关联的 `execution_prompt` artifact 实现或修复
- 完成后将 status 改为 `done`，填写 `implementation_notes` 和 `updated_at`
- 将执行摘要和验证结果写入 `.agent-memory/artifacts/done/`

### 工作流

1. 读取已安装的 `agent-protocol` skill。
2. 读取 `.agent-memory/tasks.json`；如果缺失，创建 `{"tasks": []}`，报告没有 pending task，并停止执行。
3. 确保 `.agent-memory/artifacts/` 及对应子目录存在。
4. 选择与用户请求匹配的 pending task。
5. 如果多个 task 匹配，按 `priority` high、medium、low 排序，同优先级按 `created_at` 升序。
6. 如果 `artifact_refs` 中存在 `execution_prompt` artifact，先读取它作为直接执行说明；若与 `task.spec` 冲突，以 `task.spec` 为准并回报冲突。
7. 将认领任务改为 `in_progress`。
8. 按 `spec` 和关联 prompt 实现，运行相关验证。
9. 写 completion artifact，并在其中记录实现摘要和验证结果。
10. 更新 task 摘要、`artifact_refs`、`last_tested_at`、`implementation_notes` 和 `updated_at`。
11. 完成后改为 `done`。

### 兼容规则

- 不再根据 agent 身份做角色门禁。
- 不修改任务契约字段，例如 `spec`、`context`、`title`、`created_by`。
- 不要引入额外的公共子命令来完成验证或完成记录。
