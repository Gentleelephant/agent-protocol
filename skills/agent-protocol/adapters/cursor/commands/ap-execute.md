# /ap-execute

Cursor command equivalent of `/ap:execute`.

认领并执行已有 pending task。省略目标时默认为下一个可执行 task。你应把用户在命令后补充的说明一并视为执行参数，但本命令不接收直接粘贴的 execution prompt、prompt artifact、plan artifact 或 plan 文档。

如果用户意图是以下任一项，按 `/ap:execute` 语义处理：

- “执行 task-001”
- “执行下一个 pending task”
- “执行所有 pending task”
- “执行刚才 review 产出的修复 task”

## 工作流

1. 读取 `.agent-memory/agent-protocol.md`（如存在）。
2. 加载 `.agent-memory/tasks.json`。
3. 确保相关 artifact 目录存在，执行结果和验证结果会写入 `.agent-memory/artifacts/done/`。
4. 只接受已有 task id、`next`、`--all` 和可选 `--origin review|plan|import|run` 语义。若用户提供直接 prompt、直接 plan 或 artifact 内容，停止并要求先使用导入流程。
5. 按 `priority`（high > medium > low）和 `created_at` 选择 task；`--origin` 只过滤 `origin_command`。
6. 若 task 存在 `prompt_artifact_id`，先读取对应 prompt；若与 `task.spec` 冲突，以 `task.spec` 为准并报告不一致。
7. 将 task 切到 `in_progress`，按 `spec` 和 prompt 实现，运行验证，写 completion artifact 和必要摘要。
8. `--all` 必须串行执行，一次只认领一个 task；每轮开始前重新读取 `tasks.json`，优先恢复已有 `in_progress` task。
9. 不创建 task，不扩散修改范围；若需要主 agent 自动拆任务、委派、review 和提交，应改用 `/ap-run`。
