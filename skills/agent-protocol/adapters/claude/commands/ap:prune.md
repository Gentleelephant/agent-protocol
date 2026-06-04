---
name: ap:prune
description: "Prune completed or cancelled agent-protocol history only. Any agent."
---

# /ap:prune

清理 `.agent-memory` 历史数据。只删除 `done` / `cancelled` task 和仅被这些终态 task 引用的历史 artifact，保留所有活动 task。

## 工作流

1. 读取 `.agent-memory/tasks.json`。
2. 保留 `pending`、`in_progress`、`blocked` task。
3. 删除 `done`、`cancelled` task。
4. 删除 `.agent-memory/artifacts/done/` 下的完成记录。
5. 删除仅被已移除终态 task 引用的 `review`、`plan`、`prompt` artifact。
6. 保留 `.agent-memory/agent-protocol.md` 和目录结构。
