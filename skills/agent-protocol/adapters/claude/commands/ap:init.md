---
name: ap:init
description: "Initialize or update project-level personal protocol config. Any role."
argument-hint: "planner=<agent> executor=<agent>"
---

# /ap:init

初始化或更新项目级个人协议配置。配置命令，任何 agent 均可执行。

## 工作流

1. 读取 `.agent-memory/agent-protocol.md`（如存在）。
2. 确定 Planner 和 Executor：参数指定 > 已有配置 > 默认值。
3. 创建或更新：
   - `.agent-memory/agent-protocol.md`
   - `.agent-memory/tasks.json`（仅缺失时创建 `{"tasks": []}`）
   - `CLAUDE.local.md`
   - `.mastracode/AGENTS.md`
4. Git 仓库下更新 `.git/info/exclude` 忽略上述文件。
5. 不修改团队共享的 `AGENTS.md` 或 `CLAUDE.md`。
