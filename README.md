# agent-protocol

Codex 和 Claude Code 之间的标准化协作协议。

## 安装

```bash
curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/main/init.sh | bash
```

## 新项目接入

```bash
cd your-project
~/.agent-protocol/init.sh --project
```

## 已接入项目更新

如果 `agent-protocol` 仓库更新了，先更新本机协议：

```bash
curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/main/init.sh | bash
```

然后进入项目目录，刷新项目引用：

```bash
cd your-project
~/.agent-protocol/init.sh --project
```

如果要锁定到某个版本：

```bash
cd your-project
~/.agent-protocol/init.sh --project --version v1.0
```

## 切换 Agent 扮演者

如果 Codex 或 Claude Code 暂时不可用，可以把 Planner / Executor 切换给其他 agent，例如 opencode：

```bash
cd your-project
~/.agent-protocol/init.sh --project --planner-agent opencode --executor-agent opencode
```

这条命令会同时更新：

- `~/.agent-protocol/PROTOCOL.md` 中的角色分工名称
- `~/.agent-protocol/roles/planner.md` 中的 Planner 扮演者
- `~/.agent-protocol/roles/executor.md` 中的 Executor 扮演者
- 当前项目 `AGENTS.md` / `CLAUDE.md` 里的 Agent 名称

也可以只替换其中一个角色：

```bash
~/.agent-protocol/init.sh --project --planner-agent opencode
~/.agent-protocol/init.sh --project --executor-agent opencode
```

## 工作原理

- Planner（默认 Codex，可切换）：分析、设计、Review，输出任务到 `.agent-memory/tasks.json`
- Executor（默认 Claude Code，可切换）：读取任务，实现，更新状态
- `PROTOCOL.md` 是唯一维护协议约定的地方
- `roles/planner.md` 和 `roles/executor.md` 分别定义两个 agent 的职责
- 项目内的 `AGENTS.md` 和 `CLAUDE.md` 只引用协议文件，不重复维护协议正文

## 文件说明

- `README.md`：项目说明和快速开始
- `PROTOCOL.md`：Agent 协作协议正文
- `roles/planner.md`：Codex/Planner 角色说明
- `roles/executor.md`：Claude Code/Executor 角色说明
- `schema/tasks.schema.json`：任务文件 JSON Schema
- `init.sh`：安装协议和初始化项目的脚本

## 版本说明

默认安装 `main` 分支上的最新协议：

```bash
curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/main/init.sh | bash
```

新项目可以锁定到指定版本：

```bash
~/.agent-protocol/init.sh --project --version v1.0
```

更新本地协议时，重新执行安装命令即可覆盖 `~/.agent-protocol` 下的协议文件。

已接入项目重新执行 `~/.agent-protocol/init.sh --project` 会刷新 `AGENTS.md` 和 `CLAUDE.md` 中的协议引用块，不会覆盖 `.agent-memory/tasks.json`。
