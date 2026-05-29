# agent-protocol

Codex、Claude Code、Mastra Code 之间的项目级个人协作协议。

## 目标

这个仓库提供一套 Planner / Executor 协作协议，让不同 coding agent 在同一个项目里通过本地任务文件交接工作。

它不会修改团队共享的 `AGENTS.md` 或 `CLAUDE.md`，也不会要求把个人配置提交到 GitHub。

## 安装协议

```bash
curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/main/init.sh | bash
```

这只会安装或更新：

- `~/.agent-protocol/PROTOCOL.md`
- `~/.agent-protocol/roles/planner.md`
- `~/.agent-protocol/roles/executor.md`
- `~/.agent-protocol/schema/tasks.schema.json`
- `~/.agent-protocol/init.sh`

## 安装 Skill

把本仓库的 skill 安装到你使用的 agent 中：

```text
skills/agent-protocol/SKILL.md
```

脚本不负责安装 skill，因为不同 agent 的 skill 安装方式不同。安装后，agent 会知道如何按本协议选择 Planner / Executor 角色、读取项目配置、读写 task。

## 项目级个人配置

在具体项目中运行：

```bash
cd your-project
~/.agent-protocol/init.sh --project --planner-agent Codex --executor-agent mastracode
```

这会创建或更新：

- `AGENTS.override.md`：Codex 项目级个人入口
- `CLAUDE.local.md`：Claude Code 项目级个人入口
- `.mastracode/AGENTS.md`：Mastra Code 项目级个人入口
- `.agent-memory/agent-protocol.md`：项目级个人协议配置
- `.agent-memory/tasks.json`：Planner / Executor 共享任务状态
- `.git/info/exclude`：本地忽略上述个人配置和状态文件

不会写入项目根目录的团队共享 `AGENTS.md` 或 `CLAUDE.md`。

## 角色分工

Planner 负责：

- 分析需求
- 设计方案
- review 代码
- 追加 pending task 到 `.agent-memory/tasks.json`
- 验收 Executor 完成的任务并改为 `verified`

Executor 负责：

- 读取 `.agent-memory/tasks.json`
- 认领 `pending` task 并改为 `in_progress`
- 按 `spec` 实现或修复
- 完成后改为 `done`
- 填写 `implementation_notes`

## 推荐使用方式

1. 安装协议：

```bash
curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/main/init.sh | bash
```

2. 给 Codex、Claude Code、Mastra Code 分别安装 `skills/agent-protocol/SKILL.md`。

3. 在项目里初始化个人配置：

```bash
cd your-project
~/.agent-protocol/init.sh --project --planner-agent Codex --executor-agent mastracode
```

4. 让 Planner 创建任务。安装 skill 和项目入口后，不需要显式说“按 agent-protocol”，可以直接说：

```text
review 当前代码
规划这个需求
把这个需求拆成任务
```

这些会默认触发 Planner，并把结果写入 `.agent-memory/tasks.json`。

5. 让 Executor 执行任务：

```text
处理 pending task
实现 task-001
继续 Executor 工作
```

这些会默认触发 Executor，认领任务并更新状态。

6. 让 Planner 验收：

```text
验收 done task
verify task-001
```

这些会默认触发 Planner 验收，并把通过的任务改为 `verified`。

## /ap: 命令

强触发命令使用 `/ap:` 前缀，避免和 agent 自带命令冲突。

Planner 命令：

- `/ap:review [scope]`
- `/ap:plan [requirement]`
- `/ap:task [summary]`
- `/ap:verify [task-id|all]`

Executor 命令：

- `/ap:execute [task-id|next]`
- `/ap:fix [task-id]`
- `/ap:test [task-id]`
- `/ap:done [task-id]`

通用命令：

- `/ap:tasks`
- `/ap:status`
- `/ap:help`
- `/ap:whoami`
- `/ap:switch planner|executor`

命令会检查项目角色绑定。比如项目配置是 `Planner: Codex`、`Executor: mastracode`，那么 Mastra Code 收到 `/ap:review` 时不能创建 review task，Codex 收到 `/ap:execute next` 时不能执行代码修改。

`/ap:switch` 只切换当前会话视角，不修改项目配置，也不能绕过角色绑定执行副作用命令。

修改项目角色绑定时重新运行：

```bash
~/.agent-protocol/init.sh --project --planner-agent Codex --executor-agent mastracode
```

## Agent 入口文件

Codex 读取：

```text
AGENTS.override.md
```

Claude Code 读取：

```text
CLAUDE.local.md
```

Mastra Code 读取：

```text
.mastracode/AGENTS.md
```

注意：Mastra Code 的 lookup order 是项目根目录 `AGENTS.md` / `CLAUDE.md`，然后 `.claude/AGENTS.md` / `.claude/CLAUDE.md`，最后 `.mastracode/AGENTS.md` / `.mastracode/CLAUDE.md`。如果团队仓库根目录已有 `AGENTS.md` 或 `CLAUDE.md`，Mastra 会先读取团队文件，这是 Mastra Code 的官方行为。

## 文件说明

- `PROTOCOL.md`：协议正文
- `roles/planner.md`：Planner 角色说明
- `roles/executor.md`：Executor 角色说明
- `schema/tasks.schema.json`：任务文件 JSON Schema
- `init.sh`：安装协议和初始化项目级个人配置
- `skills/agent-protocol/SKILL.md`：给各 agent 安装的 skill

## 版本

指定版本安装：

```bash
curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/main/init.sh | bash -s -- --version v1.0
```

指定项目角色：

```bash
~/.agent-protocol/init.sh --project --planner-agent Codex --executor-agent "Claude Code"
~/.agent-protocol/init.sh --project --planner-agent Codex --executor-agent mastracode
```
