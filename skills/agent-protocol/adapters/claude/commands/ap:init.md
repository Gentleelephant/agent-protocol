---
name: ap:init
description: "Initialize or update project-level personal protocol config. Any role."
argument-hint: "planner=<agent> executor=<agent>"
---

# /ap:init

初始化或更新项目级个人协议配置。配置命令，任何 agent 均可执行。

## 工作流

1. 读取 `.agent-memory/agent-protocol.md`（如存在）。
2. 读取或保留已有兼容字段 `planner` / `executor`；这些字段仅用于兼容旧配置，不参与命令门禁。
3. 创建或更新：
   - `.agent-memory/agent-protocol.md`
   - `.agent-memory/tasks.json`（仅缺失时创建 `{"tasks": []}`）
   - `.agent-memory/artifacts/` 及其 `review`、`plan`、`prompt`、`done` 子目录
   - `CLAUDE.local.md`
   - `.mastracode/AGENTS.md`
4. Git 仓库下更新 `.git/info/exclude` 忽略上述文件。
5. 不修改团队共享的 `AGENTS.md` 或 `CLAUDE.md`。
