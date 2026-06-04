---
name: ap:init
description: "Initialize or update project-level personal protocol config."
argument-hint: "[--agent all|claude|mastracode]"
---

# /ap:init

初始化或更新项目级个人协议配置。配置命令，任何 agent 均可执行。会一并安装 `/ap:clean`。

## 工作流

1. 读取 `.agent-memory/agent-protocol.md`（如存在）。
2. 按缺失优先原则创建；若文件或目录已存在则跳过：
   - `.agent-memory/agent-protocol.md`
   - `.agent-memory/tasks.json`（仅缺失时创建 `{"tasks": []}`）
   - `.agent-memory/artifacts/` 及其 `review`、`plan`、`prompt`、`done` 子目录
3. 根据 `--agent` 安装项目级 `/ap:` 子命令；默认 `all`，可选 `claude`、`mastracode`。已有命令文件跳过，不覆盖。
4. 根据 `--agent` 创建对应 agent 的本地入口文件：
   - `claude|all` -> `CLAUDE.local.md`
   - `mastracode|all` -> `.mastracode/AGENTS.md`
5. Git 仓库下更新 `.git/info/exclude` 忽略上述文件。
6. 不修改团队共享的 `AGENTS.md` 或 `CLAUDE.md`。
