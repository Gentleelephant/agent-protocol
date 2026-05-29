# agent-protocol

多种 coding agent 之间的标准化协作协议。

## 安装

```bash
curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/main/init.sh | bash
```

这会更新：

- `~/.agent-protocol/`
- `~/.codex/AGENTS.md`
- `~/.claude/CLAUDE.md`
- `~/.config/opencode/AGENTS.md`

不会修改任何项目仓库里的 `AGENTS.md` 或 `CLAUDE.md`。

## 项目级个人配置

如果某个项目要使用自己的 agent-protocol 设置，只在该项目里创建个人私有配置：

```bash
cd your-project
~/.agent-protocol/init.sh --project
```

这只会创建或保留：

- `.agent-memory/agent-protocol.md`
- `.agent-memory/tasks.json`
- `.git/info/exclude` 中的 `.agent-memory/` 忽略规则

不会写入项目根目录的 `AGENTS.md` 或 `CLAUDE.md`。

不同项目可以使用不同的 agent：

```bash
cd project-a
~/.agent-protocol/init.sh --project --planner-agent Codex --executor-agent opencode

cd ../project-b
~/.agent-protocol/init.sh --project --planner-agent opencode --executor-agent opencode
```

## 更新

如果 `agent-protocol` 仓库更新了，先更新本机协议：

```bash
curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/main/init.sh | bash
```

如果项目已经有 `.agent-memory/agent-protocol.md` 和 `.agent-memory/tasks.json`，不需要修改团队文件。需要时可以重新执行：

```bash
cd your-project
~/.agent-protocol/init.sh --project
```

如果要锁定到某个版本：

```bash
~/.agent-protocol/init.sh --version v1.0
```

## 切换 Agent 扮演者

如果 Codex 或 Claude Code 暂时不可用，可以把 Planner / Executor 切换给其他 agent，例如 opencode：

```bash
~/.agent-protocol/init.sh --planner-agent opencode --executor-agent opencode
```

这条命令会同时更新：

- `~/.agent-protocol/PROTOCOL.md` 中的角色分工名称
- `~/.agent-protocol/roles/planner.md` 中的 Planner 扮演者
- `~/.agent-protocol/roles/executor.md` 中的 Executor 扮演者
- `~/.codex/AGENTS.md` 中的个人规则
- `~/.claude/CLAUDE.md` 中的个人规则
- `~/.config/opencode/AGENTS.md` 中的个人规则

也可以只替换其中一个角色：

```bash
~/.agent-protocol/init.sh --planner-agent opencode
~/.agent-protocol/init.sh --executor-agent opencode
```

## 工作原理

- Planner（默认 Codex，可切换）：分析、设计、Review，输出任务到 `.agent-memory/tasks.json`
- Executor（默认 Claude Code，可切换）：读取任务，实现，更新状态
- `PROTOCOL.md` 是唯一维护协议约定的地方
- `roles/planner.md` 和 `roles/executor.md` 分别定义两个 agent 的职责
- 各 agent 通过个人级规则读取协议，并通过 `.agent-memory/agent-protocol.md` 获取项目级个人配置；项目仓库不需要提交协议入口文件

## 文件说明

- `README.md`：项目说明和快速开始
- `PROTOCOL.md`：Agent 协作协议正文
- `roles/planner.md`：Codex/Planner 角色说明
- `roles/executor.md`：Claude Code/Executor 角色说明
- `schema/tasks.schema.json`：任务文件 JSON Schema
- `init.sh`：安装协议和初始化项目的脚本
- `skills/agent-protocol/SKILL.md`：可按需安装到支持 skill 的 agent 中

## 版本说明

默认安装 `main` 分支上的最新协议：

```bash
curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/main/init.sh | bash
```

新项目可以锁定到指定版本：

```bash
~/.agent-protocol/init.sh --version v1.0
```

更新本地协议时，重新执行安装命令即可覆盖 `~/.agent-protocol` 下的协议文件。
