# /ap:execute

认领并执行 pending task。省略参数时默认为 `next`。`--origin review|plan` 可用于只处理特定来源的任务。

用户在调用本命令时传入的文本作为 task 选择参数。

自然语言等价触发：

- “执行刚才 plan 生成的第 2 个任务”
- “按照这个开发 prompt 去实现”
- “根据这个 task 继续做代码实现”
- “执行刚才 review 产出的修复 prompt”

## 工作流

1. 读取 `.agent-memory/agent-protocol.md`（如存在）。
2. 加载 `.agent-memory/tasks.json`。
3. 确保相关 artifact 目录存在，执行结果和验证结果会写入 `.agent-memory/artifacts/done/`。
4. 选择 task：按 `priority`（high > medium > low）排序，同优先级按 `created_at` 升序；若指定 `--origin`，只在匹配来源的 task 中选择。
5. 若 task 存在 `prompt_artifact_id`，先读取该 prompt；否则从 `artifact_refs` 中定位 `execution_prompt` artifact。若它与 `task.spec` 冲突，以 `task.spec` 为准并报告不一致。
6. 若 task 存在 `origin_artifact_id`，在需要补充背景时读取对应 review 或 plan artifact。
7. 将选中的 task 改为 `in_progress`。
8. 按 `spec` 和关联 prompt 实现，运行验证，并把完成总结写入 artifact 和 `implementation_notes` 摘要。
9. 不修改任务契约字段。
