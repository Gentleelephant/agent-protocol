# /ap:execute

认领并执行已有 pending task。省略参数时默认为 `next`。`--all` 是当前会话内的安全串行批处理：每轮重新读取 `tasks.json`，一次只认领一个 task，优先恢复匹配的 `in_progress` task，不并行，不启动外部 supervisor。`--origin review|plan|import|run` 只作为 `origin_command` 来源过滤，不表示 task 类型。本命令不创建 task，不接收直接粘贴的 execution prompt、prompt artifact、plan artifact 或 plan 文档，不支持 `--one` 或 `--loop`。

用户在调用本命令时传入的文本只能作为 task 选择参数。

自然语言等价触发：

- “执行刚才 plan 生成的第 2 个任务”
- “执行所有 pending task”
- “根据这个 task 继续做代码实现”
- “执行刚才 review 产出的修复 task”

## 工作流

1. 读取 `.agent-memory/agent-protocol.md`（如存在）。
2. 加载 `.agent-memory/tasks.json`。
3. 确保相关 artifact 目录存在，执行结果和验证结果会写入 `.agent-memory/artifacts/done/`。
4. 选择执行目标：只接受 task id、`next`、`--all` 和可选 `--origin review|plan|import|run`。如果用户传入直接 prompt、直接 plan、prompt artifact 或 plan artifact，停止并要求先使用 `/ap:import`。
5. 选择 task：`--origin` 只过滤 `origin_command`；按 `priority`（high > medium > low）排序，同优先级按 `created_at` 升序。若 `task-id` 与 `--origin` 同时指定，先校验来源匹配，不匹配则停止。
6. 若 task 存在 `prompt_artifact_id`，先读取该 prompt；否则从 `artifact_refs` 中定位 `execution_prompt` artifact。若它与 `task.spec` 冲突，以 `task.spec` 为准并报告不一致。
7. 若 task 存在 `origin_artifact_id`，在需要补充背景时读取对应 review、plan 或 import artifact。
8. 将选中的 task 改为 `in_progress`。
9. 按 `spec` 和关联 prompt 实现，运行验证，并把完成总结写入 artifact 和 `implementation_notes` 摘要。
10. 若使用 `--all`，每轮重新加载 `.agent-memory/tasks.json`，优先恢复匹配的 `in_progress` task，否则选择下一个匹配的 `pending` task；一次只认领一个 task。逐个 task 重复读取 prompt、状态流转、验证和 completion artifact 写入；遇到未满足 `depends_on` 时跳过或标记 `blocked`，遇到实现失败、验证失败或 blocker 时记录当前 task 结果并停止后续执行。若 agent 会话中断，下次 `/ap:execute --all` 必须从 `tasks.json` 状态恢复。
11. 不修改任务契约字段；执行阶段不能创建 task 或归一化外部 prompt / plan。若需要主 agent 自动拆任务、委派、review 和提交，应改用 `/ap:run`。
