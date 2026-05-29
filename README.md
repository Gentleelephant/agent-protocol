# agent-protocol

Claude Code、Mastra Code 之间的项目级个人协作协议。

## 项目结构

```text
agent-protocol/
├── skills/
│   ├── agent-protocol/          # 共享协议 skill
│   │   ├── SKILL.md             # 协议唯一来源（工作流、角色门禁、任务结构）
│   │   ├── scripts/init.sh
│   │   └── references/
│   ├── ap:init/SKILL.md         # Claude Code 命令 skill → /ap:init
│   ├── ap:review/SKILL.md       # → /ap:review
│   ├── ...
│   └── ap:whoami/SKILL.md
├── adapters/
│   └── mastracode/
│       └── commands/
│           └── ap/              # Mastra Code 命令 → /ap:<file>
│               ├── init.md
│               ├── review.md
│               └── ...
├── scripts/install.sh           # 安装 /ap: 命令适配层（skill 由用户自行管理）
└── README.md
```

## 核心模式

`skills/agent-protocol/SKILL.md` 是协议唯一来源。命令适配层只做一件事：把平台原生 slash command 映射到同一个 skill 工作流。

- Claude Code：14 个独立 skill（`skills/ap:*/SKILL.md`），安装到 `~/.claude/skills/` 后暴露为 `/ap:xxx`。
- Mastra Code：14 个 custom slash command（`adapters/mastracode/commands/ap/*.md`），安装后为 `/ap:xxx`。
- `/ap:init` 只初始化项目级个人配置和任务状态，不负责安装命令。

## 安装

agent-protocol skill 由用户自行管理安装。`scripts/install.sh` 仅安装 `/ap:` 命令适配层。

推荐通过 tag URL 直接执行远程脚本，无需克隆仓库：

```bash
# 安装 Claude Code 命令（用户级，所有项目可用）
curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/v3.4/scripts/install.sh | bash -s -- --agent claude --scope user

# 安装 Mastra Code 命令
curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/v3.4/scripts/install.sh | bash -s -- --agent mastracode --scope user

# 同时安装两个平台
curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/v3.4/scripts/install.sh | bash -s -- --agent all --scope user

# 项目级安装（在项目目录下执行，安装到 .claude/ 或 .mastracode/）
curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/v3.4/scripts/install.sh | bash -s -- --agent claude --scope project
```

替换 `v3.4` 为所需的版本 tag。本地开发时可直接运行：

```bash
scripts/install.sh --agent claude --scope user
scripts/install.sh --agent mastracode --scope user

# 或安装到当前项目
scripts/install.sh --agent claude --scope project
scripts/install.sh --agent mastracode --scope project
```

### Claude Code

安装脚本会创建：

```text
~/.claude/skills/ap:init/
~/.claude/skills/ap:review/
...
```

项目级安装时对应目录是 `.claude/skills/`。Claude Code 当前推荐用 skills 创建自定义命令；`ap:init` 这样的命令 skill 直接暴露为 `/ap:init`。

### Mastra Code

安装脚本会创建：

```text
~/.mastracode/commands/ap/init.md
~/.mastracode/commands/ap/review.md
...
```

项目级安装时对应目录是 `.mastracode/`。Mastra Code 会按 `commands/ap/*.md` 目录结构识别 `/ap:init`、`/ap:review` 等命令。

## 使用流程

1. 在项目中初始化：

```text
/ap:init planner="Claude Code" executor=mastracode
```

也可以使用可选脚本：

```bash
curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/main/skills/agent-protocol/scripts/init.sh | bash -s -- --project --planner-agent "Claude Code" --executor-agent mastracode
```

2. 创建任务：

```text
review 当前代码
/ap:review 当前模块
/ap:task 把刚才讨论的方案保存成任务
```

3. 执行任务：

```text
处理 pending task
/ap:execute next
```

4. 验收任务：

```text
验收 done task
/ap:verify all
```

## 项目文件

`/ap:init` 或可选脚本会创建：

- `CLAUDE.local.md`：Claude Code 项目级个人入口
- `.mastracode/AGENTS.md`：Mastra Code 项目级个人入口
- `.agent-memory/agent-protocol.md`：项目级个人协议配置
- `.agent-memory/tasks.json`：Planner / Executor 共享任务状态
- `.git/info/exclude`：本地忽略上述个人配置和状态文件

这些文件不会提交到团队仓库。

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

所有协议命令都使用 `/ap:` 前缀。

| 命令 | 角色 | 参数 | 可选值 / 格式 | 行为 |
|---|---|---|---|---|
| `/ap:init` | 通用 | `planner=<agent>`、`executor=<agent>` | 推荐值：`Claude Code`、`mastracode`；含空格时用引号 | 初始化或更新项目级个人配置 |
| `/ap:review` | Planner | `[scope]` | 可省略；文件、目录、模块名或自然语言范围 | 审查代码并创建 `review` task，不直接改业务代码 |
| `/ap:plan` | Planner | `[requirement]` | 需求描述、架构问题、设计目标 | 创建 `feature` 或 `design` task |
| `/ap:task` | Planner | `[summary]` | 当前讨论结论或任务摘要 | 把讨论结果保存成 pending task |
| `/ap:verify` | Planner | `[task-id\|all]` | `task-001` 或 `all`；省略时检查可验收的 done task | 验收 done task，通过则改为 `verified`，不通过则退回 `in_progress` |
| `/ap:execute` | Executor | `[task-id\|next]` | `task-001` 或 `next`；省略等同于 `next` | 认领并执行 pending task |
| `/ap:fix` | Executor | `[task-id]` | `task-001`；省略时选择匹配的 bug/review task | 修复指定 bug/review task |
| `/ap:test` | Executor | `[task-id]` | `task-001`；省略时针对当前 in_progress task | 运行验证并记录结果 |
| `/ap:done` | Executor | `[task-id]` | `task-001`；省略时针对当前 in_progress task | 标记任务 `done` 并填写实现说明 |
| `/ap:tasks` | 通用 | `[status]` | `pending`、`in_progress`、`blocked`、`done`、`verified`、`cancelled`；省略显示全部 | 列出任务 |
| `/ap:status` | 通用 | 无 | 无 | 汇总任务数量和下一步建议 |
| `/ap:help` | 通用 | `[command]` | 任意 `/ap:` 命令名；省略显示全部帮助 | 显示命令帮助 |
| `/ap:whoami` | 通用 | 无 | 无 | 显示当前项目配置的 Planner / Executor |

除 `/ap:init` 和只读命令外，命令会检查项目角色绑定。比如项目配置是 `Planner: Claude Code`、`Executor: mastracode`，那么 Mastra Code 收到 `/ap:review` 时不能创建 review task，Claude Code 收到 `/ap:execute next` 时不能执行代码修改。

如果要修改项目角色绑定，重新运行 `/ap:init planner=<agent> executor=<agent>`。

## 任务字段

`.agent-memory/tasks.json` 的任务字段和可选值：

| 字段 | 必填 | 可选值 / 格式 | 维护者 |
|---|---|---|---|
| `id` | 是 | `task-001` 递增格式 | Planner 创建 |
| `type` | 是 | `review`、`feature`、`design`、`bug` | Planner 创建 |
| `created_by` | 是 | 固定为 `planner` | Planner 创建 |
| `status` | 是 | `pending`、`in_progress`、`blocked`、`done`、`verified`、`cancelled` | Planner / Executor 按状态流转维护 |
| `priority` | 否 | `high`、`medium`、`low`；默认按 `medium` 理解 | Planner 创建，Executor 用于排序 |
| `title` | 是 | 简短标题 | Planner 创建 |
| `context` | 是 | 背景和原因 | Planner 创建 |
| `spec` | 是 | Executor 可执行的具体要求 | Planner 创建 |
| `implementation_notes` | 否 | 实现、验证、阻塞或退回说明 | Executor 填写，Planner 验收失败时可追加反馈 |
| `created_at` | 是 | ISO 时间字符串 | Planner 创建 |
| `updated_at` | 是 | ISO 时间字符串 | 当前修改者更新 |

状态流转：

```text
pending -> in_progress -> done -> verified
             |            |
             -> blocked   -> in_progress（验收未通过）

pending|blocked|in_progress -> cancelled
```

Executor 选择任务时，先按 `priority` 的 `high`、`medium`、`low` 排序，同优先级按 `created_at` 升序处理。

## Agent 入口文件

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

`skills/agent-protocol/scripts/init.sh` 是 `/ap:init` 的 shell 版本，方便不用 agent 时初始化项目。

运行：

```bash
skills/agent-protocol/scripts/init.sh --project --planner-agent "Claude Code" --executor-agent mastracode
skills/agent-protocol/scripts/init.sh --project planner="Claude Code" executor=mastracode
```
