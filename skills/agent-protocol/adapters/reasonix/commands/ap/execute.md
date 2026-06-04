# /ap:execute

认领并执行已有 pending task。省略参数时默认为 `next`。`--origin review|plan|import` 可用于只处理特定来源的任务。本命令不创建 task，不接收直接粘贴的 execution prompt、prompt artifact、plan artifact 或 plan 文档。

用户在调用本命令时传入的文本只能作为 task 选择参数。

自然语言等价触发：

- “执行刚才 plan 生成的第 2 个任务”
- “根据这个 task 继续做代码实现”
- “执行刚才 review 产出的修复 task”

## 工作流

1. 读取 `.agent-memory/agent-protocol.md`（如存在）。
2. 加载 `.agent-memory/tasks.json`。
3. 确保相关 artifact 目录存在，执行结果和验证结果会写入 `.agent-memory/artifacts/done/`。
4. 选择执行目标：只接受 task id、`next` 或 `--origin review|plan|import`。如果用户传入直接 prompt、直接 plan、prompt artifact 或 plan artifact，停止并要求先使用 `/ap:import`。
5. 选择 task：按 `priority`（high > medium > low）排序，同优先级按 `created_at` 升序；若指定 `--origin`，只在匹配来源的 task 中选择。
6. 若 task 存在 `prompt_artifact_id`，先读取该 prompt；否则从 `artifact_refs` 中定位 `execution_prompt` artifact。若它与 `task.spec` 冲突，以 `task.spec` 为准并报告不一致。
7. 若 task 存在 `origin_artifact_id`，在需要补充背景时读取对应 review、plan 或 import artifact。
8. 将选中的 task 改为 `in_progress`。
9. 按 `spec` 和关联 prompt 实现，运行验证，并把完成总结写入 artifact 和 `implementation_notes` 摘要。
10. 不修改任务契约字段；执行阶段不能创建 task 或归一化外部 prompt / plan。
