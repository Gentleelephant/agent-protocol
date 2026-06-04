# /ap:clean

清理 `.agent-memory` 历史数据。省略参数时默认为 `history`。

用户在调用本命令时传入的文本作为清理模式参数。

自然语言等价触发：

- “清理 .agent-memory 里的历史数据”
- “把已经完成的 task 和历史 artifact 清掉”
- “重置 agent protocol 本地状态”

## 工作流

1. 读取 `.agent-memory/agent-protocol.md`（如存在）。
2. 加载 `.agent-memory/tasks.json`。
3. `history` 模式下，保留 `pending`、`in_progress`、`blocked` task，移除 `done`、`cancelled` task。
4. 删除 `.agent-memory/artifacts/done/` 下的完成记录。
5. 删除仅被已移除终态 task 引用的 `review`、`plan`、`prompt` artifact。
6. `all` 模式下，保留 `.agent-memory/agent-protocol.md` 和目录结构，把 `tasks.json` 重置为 `{"tasks": []}`，并清空所有 artifact 子目录。
7. 输出清理摘要，说明保留了哪些活动任务、删除了哪些历史记录。
