---
name: ap:prune
description: "Prune completed or cancelled agent-protocol history only. Any agent."
---

# /ap:prune

清理 `.agent-memory` 历史数据。只删除 `done` / `cancelled` task 和仅被这些终态 task 引用的历史 artifact，保留所有活动 task。

## 工作流

1. 优先运行 `bash skills/agent-protocol/scripts/prune.sh`。
2. 如果脚本不可用，再按协议工作流执行等价清理。
3. 保留 `pending`、`in_progress`、`blocked` task。
4. 删除 `done`、`cancelled` task。
5. 删除 `.agent-memory/artifacts/done/` 下的完成记录。
6. 删除仅被已移除终态 task 引用的 `review`、`plan`、`prompt` artifact。
7. 保留 `.agent-memory/agent-protocol.md` 和目录结构，并报告删除摘要。
