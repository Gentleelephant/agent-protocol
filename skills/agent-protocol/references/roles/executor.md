## 实现阶段

### 职责

- 将认领的任务 status 改为 `in_progress`
- 按照 `spec`、来源 artifact 和关联的 `execution_prompt` artifact 实现或修复
- 完成后将 status 改为 `done`，填写 `implementation_notes` 和 `updated_at`
- 将执行摘要和验证结果写入 `.agent-memory/artifacts/done/`

### 工作流

1. 读取已安装的 `agent-protocol` skill。
2. 读取 `.agent-memory/tasks.json`；如果缺失，创建 `{"tasks": []}`，报告没有 pending task，并停止执行。
3. 确保 `.agent-memory/artifacts/` 及对应子目录存在。
4. 先把用户请求归一化为 pending task：
   - 如果用户指定 task、`next` 或 `--origin review|plan`，选择匹配的 pending task。
   - 如果用户传入 prompt artifact 或直接粘贴 execution prompt，优先匹配其中的 `related_task_ids`；没有匹配 task 时，先保存 prompt artifact 并创建 pending task。
   - 如果用户传入 plan artifact 或直接粘贴 plan 文档，先解析其中的可执行项，保存 plan artifact，并为每个可执行项创建 task 和 execution prompt；未指定单个目标时只列出 task，不直接执行全部。
5. 如果多个 task 匹配，按 `priority` high、medium、low 排序，同优先级按 `created_at` 升序。
6. 如果存在 `prompt_artifact_id`，先读取它作为直接执行说明；否则再从 `artifact_refs` 中定位 `execution_prompt` artifact。若与 `task.spec` 冲突，以 `task.spec` 为准并回报冲突。
7. 如果存在 `origin_artifact_id`，在需要补充背景时读取对应 review 或 plan artifact。
8. 将认领任务改为 `in_progress`。
9. 按 `spec` 和关联 prompt 实现，运行相关验证。
10. 写 completion artifact，并在其中记录实现摘要和验证结果。
11. 更新 task 摘要、`artifact_refs`、`last_tested_at`、`implementation_notes` 和 `updated_at`。
12. 完成后改为 `done`。

### 规则

- 不根据 agent 身份做角色门禁。
- 不修改任务契约字段，例如 `spec`、`context`、`title`、`created_by`。
- 不要引入额外的公共子命令来完成验证或完成记录。
- 直接 prompt 或 plan 输入只是入口兼容层，不能跳过 task id、prompt artifact、done artifact 和状态流转。
