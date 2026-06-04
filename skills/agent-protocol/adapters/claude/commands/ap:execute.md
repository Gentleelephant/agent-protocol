---
name: ap:execute
description: "Claim and execute pending tasks, or normalize direct prompt/plan input before execution. Any agent."
argument-hint: "[task-id|next|--origin review|plan|prompt|plan-artifact]"
---

# /ap:execute

认领并执行 pending task。省略参数时默认为 `next`。`--origin review|plan` 可用于只处理特定来源的任务。也可以传入 prompt artifact、直接粘贴的 execution prompt、plan artifact 或 plan 文档；这些输入必须先归一化为 task 和 artifact，再执行。

如果当前 agent 不支持 `/ap:` 子命令，则以下自然语言请求应触发同样效果：

- “执行刚才 plan 生成的第 2 个任务”
- “按照这个开发 prompt 去实现”
- “根据这个 task 继续做代码实现”
- “执行刚才 review 产出的修复 prompt”

## 工作流

1. 读取 `.agent-memory/agent-protocol.md`（如存在）。
2. 加载 `.agent-memory/tasks.json`。
3. 确保相关 artifact 目录存在，执行结果和验证结果会写入 `.agent-memory/artifacts/done/`。
4. 归一化执行目标：task 选择器按现有规则选择 pending task；prompt artifact 或直接 prompt 先匹配 `related_task_ids`，没有匹配时保存 prompt 并创建 pending task；plan artifact 或直接 plan 先保存 plan、拆出可执行项、生成 task 和 prompt。
5. 如果 plan 包含多个可执行项且用户未指定单个目标，只创建或列出 task，不隐式连续执行全部任务。
6. 选择 task：按 `priority`（high > medium > low）排序，同优先级按 `created_at` 升序；若指定 `--origin`，只在匹配来源的 task 中选择。
7. 若 task 存在 `prompt_artifact_id`，先读取该 prompt；否则从 `artifact_refs` 中定位 `execution_prompt` artifact。若它与 `task.spec` 冲突，以 `task.spec` 为准并报告不一致。
8. 若 task 存在 `origin_artifact_id`，在需要补充背景时读取对应 review 或 plan artifact。
9. 将选中的 task 改为 `in_progress`。
10. 按 `spec` 和关联 prompt 实现，运行验证，并把完成总结写入 artifact 和 `implementation_notes` 摘要。
11. 不修改任务契约字段；直接 prompt / plan 输入也不能跳过 task id、prompt artifact、done artifact 和状态流转。
