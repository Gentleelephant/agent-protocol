# /ap:prune

清理 `.agent-memory` 历史数据。默认只删除 `done` / `cancelled` task 和仅被这些终态 task 引用的历史 artifact，保留所有活动 task；传入 `--hard` 时直接删除整个 `.agent-memory/` 目录。

## 工作流

1. 默认运行 `bash .agent-memory/scripts/prune.sh`；如果用户明确要求彻底删除，则运行 `bash .agent-memory/scripts/prune.sh --hard`。
2. 如果项目本地脚本不可用，再回退运行 `bash skills/agent-protocol/scripts/prune.sh` 或 `bash skills/agent-protocol/scripts/prune.sh --hard`。
3. 如果脚本仍不可用，再按协议工作流执行等价清理。
4. 默认模式下保留 `pending`、`in_progress`、`blocked` task。
5. 默认模式下删除 `done`、`cancelled` task。
6. 默认模式下删除 `.agent-memory/artifacts/done/` 下的完成记录。
7. 默认模式下删除仅被已移除终态 task 引用的 `run`、`review`、`plan`、`prompt` artifact。
8. 默认模式下保留 `.agent-memory/agent-protocol.md` 和目录结构，并报告删除摘要。
9. `--hard` 模式直接删除整个 `.agent-memory/` 目录。
