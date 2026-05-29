# agent-protocol

Codex、Claude Code、Mastra Code 之间的项目级个人协作协议。

## 核心模式

`skills/agent-protocol/SKILL.md` 是协议唯一来源。

你只需要把这个 skill 安装到 Codex、Claude Code、Mastra Code。之后在任意项目里使用：

```text
/ap:init planner=Codex executor=mastracode
```

它会创建项目级个人配置和任务状态。

## 项目文件

`/ap:init` 或可选脚本会创建：

- `AGENTS.override.md`：Codex 项目级个人入口
- `CLAUDE.local.md`：Claude Code 项目级个人入口
- `.mastracode/AGENTS.md`：Mastra Code 项目级个人入口
- `.agent-memory/agent-protocol.md`：项目级个人协议配置
- `.agent-memory/tasks.json`：Planner / Executor 共享任务状态
- `.git/info/exclude`：本地忽略上述个人配置和状态文件

这些文件不会提交到团队仓库。

## 使用流程

1. 安装 skill：

```text
skills/agent-protocol/SKILL.md
```

2. 在项目中初始化：

```text
/ap:init planner=Codex executor=mastracode
```

也可以使用可选脚本：

```bash
curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/main/init.sh | bash -s -- --project --planner-agent Codex --executor-agent mastracode
```

3. 创建任务：

```text
review 当前代码
/ap:review 当前模块
/ap:task 把刚才讨论的方案保存成任务
```

4. 执行任务：

```text
处理 pending task
/ap:execute next
```

5. 验收任务：

```text
验收 done task
/ap:verify all
```

## 角色

Planner 负责：

- 分析需求
- 设计方案
- review 代码
- 追加 pending task 到 `.agent-memory/tasks.json`
- 验收 done task 并改为 `verified`

Executor 负责：

- 读取 `.agent-memory/tasks.json`
- 认领 `pending` task 并改为 `in_progress`
- 按 `spec` 实现或修复
- 完成后改为 `done`
- 填写 `implementation_notes`

## /ap: 命令

Planner：

- `/ap:review [scope]`
- `/ap:plan [requirement]`
- `/ap:task [summary]`
- `/ap:verify [task-id|all]`

Executor：

- `/ap:execute [task-id|next]`
- `/ap:fix [task-id]`
- `/ap:test [task-id]`
- `/ap:done [task-id]`

通用：

- `/ap:init planner=<agent> executor=<agent>`
- `/ap:tasks`
- `/ap:status`
- `/ap:help`
- `/ap:whoami`
- `/ap:switch planner|executor`

除 `/ap:init` 和只读命令外，命令会检查项目角色绑定。比如项目配置是 `Planner: Codex`、`Executor: mastracode`，那么 Mastra Code 收到 `/ap:review` 时不能创建 review task，Codex 收到 `/ap:execute next` 时不能执行代码修改。

`/ap:switch` 只切换当前会话视角，不修改项目配置，也不能绕过角色绑定执行副作用命令。

## Agent 入口文件

Codex：

```text
AGENTS.override.md
```

Claude Code：

```text
CLAUDE.local.md
```

Mastra Code：

```text
.mastracode/AGENTS.md
```

注意：Mastra Code 的 lookup order 是项目根目录 `AGENTS.md` / `CLAUDE.md`，然后 `.claude/AGENTS.md` / `.claude/CLAUDE.md`，最后 `.mastracode/AGENTS.md` / `.mastracode/CLAUDE.md`。如果团队仓库根目录已有 `AGENTS.md` 或 `CLAUDE.md`，Mastra 会先读取团队文件，这是 Mastra Code 的官方行为。

## 可选脚本

`init.sh` 现在只是 `/ap:init` 的 shell 版本，方便不用 agent 时初始化项目。

运行：

```bash
./init.sh --project --planner-agent Codex --executor-agent mastracode
```
