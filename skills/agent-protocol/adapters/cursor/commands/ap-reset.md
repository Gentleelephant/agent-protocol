# /ap-reset

Cursor command equivalent of `/ap:reset`.

重置本地 `.agent-memory` 状态。此命令清空 task 和 artifact 历史，保留 `.agent-memory/agent-protocol.md` 和目录结构。

## 工作流

1. 保留 `.agent-memory/agent-protocol.md`。
2. 把 `.agent-memory/tasks.json` 重置为 `{"tasks": []}`。
3. 清空 `.agent-memory/artifacts/review/`、`plan/`、`prompt/`、`done/`。
4. 保留 artifact 目录结构。
