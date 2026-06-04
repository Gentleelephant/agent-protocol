# /ap:import

导入外部 execution prompt、prompt artifact、plan artifact 或 plan 文档，只创建或匹配 task 与 artifact，不执行代码。

用户在调用本命令时传入的文本作为待导入内容或 artifact 路径处理。

自然语言等价触发：

- “导入这个执行 prompt 并创建 task”
- “把这个 plan 文档转换成 agent-protocol task”
- “根据这个外部 prompt 生成可执行任务”

## 工作流

1. 读取 `.agent-memory/agent-protocol.md`（如存在）。
2. 加载 `.agent-memory/tasks.json`；缺失时创建 `{"tasks": []}`。
3. 确保 `.agent-memory/artifacts/plan/` 和 `.agent-memory/artifacts/prompt/` 存在。
4. 如果输入是 execution prompt 或 prompt artifact，验证必要章节，保存或引用 prompt artifact，匹配 `related_task_ids`；没有匹配 task 时创建一个 pending task。
5. 如果输入是 plan artifact 或 plan 文档，保存 plan artifact，拆出可执行项，并为每个可执行项创建 pending task 和 execution prompt artifact。
6. 新 task 根据导入内容推断 `type: "bug"|"feature"|"design"`；无法可靠判断时默认 `feature`，并在 `source_summary` 记录推断依据。设置 `origin_command: "import"`，并填充 `origin_artifact_id`、`prompt_artifact_id`、`source_summary`、`acceptance`、`depends_on`。
7. 只报告创建或匹配到的 task id；不修改业务代码，不把 task 改为 `in_progress`。
