# agent-protocol

一个围绕 3 个核心命令和 2 个辅助命令组织的 agent 协议：

- `/ap:plan`：根据用户需求和项目代码，生成开发计划和可执行 prompt
- `/ap:review`：review 代码，输出 review 结果和修复 prompt
- `/ap:execute`：执行 `/ap:plan` 或 `/ap:review` 生成的 task / prompt
- `/ap:fix`：`/ap:execute` 的兼容别名，保留给 review 修复语义
- `/ap:clean`：清理 `.agent-memory` 历史数据或重置本地协议状态

对于不支持子命令的 agent，例如 Codex，也必须支持。做法不是依赖 `/ap:` 语法，而是把这些命令视为自然语言意图：

- “根据这个需求结合项目代码整理开发计划” = `/ap:plan`
- “review 这段代码并给出修复 prompt” = `/ap:review`
- “执行刚才 plan 产出的 prompt” = `/ap:execute`
- “执行刚才 review 产出的修复 prompt” = `/ap:execute`

## 核心结构

主线只有两条：

1. 需求实现链路：`plan -> execute`
2. 代码修复链路：`review -> execute`

## 缓存与检索策略

协议要求把大模型缓存命中率作为核心约束：默认只读取当前命令需要的稳定入口文档、目标 task、目标 prompt 和必要源码，不批量展开历史 artifact。

如果项目中存在 `graphify-out/`，在 `/ap:plan` 或宽范围 `/ap:review` 中应优先用 graphify 图谱查询定位相关模块、文件和概念，再按需读取源码或文档确认事实。graphify 只作为检索索引，不接管 `.agent-memory` 状态流转。

对于复杂方案设计，可以使用 superpower 等外部 planning / reasoning skill 作为顾问，但最终输出必须归一化为当前协议的 plan/review artifact、task 和 execution prompt；`/ap:execute` 默认仍按已生成 prompt 执行，避免实现阶段发散。

无子命令兼容规则：

- 支持 `/ap:` 子命令的 agent，优先用子命令
- 不支持 `/ap:` 子命令的 agent，必须通过自然语言完成同样效果
- 无论走哪种入口，输出物和 prompt 质量要求必须一致

可选初始化命令：

- `/ap:init`：初始化本地协议目录，并安装项目级 `/ap:` 子命令

对 Claude Code，仓库现在额外提供了一个顶层 bootstrap skill：

- `skills/ap:init/SKILL.md`

它的作用只有一个：让 Claude 在安装 skill 后立刻能发现 `/ap:init`，再由 `/ap:init` 调用主 `agent-protocol` skill 完成初始化和子命令安装。

可选安装命令：

- 安装 Claude / Mastra Code / Reasonix 子命令：`skills/agent-protocol/scripts/install-commands.sh`

## 输出物

协议对外的关键不是内部 task 记录，而是可直接执行的 prompt。

生成位置：

```text
.agent-memory/tasks.json
.agent-memory/artifacts/plan/
.agent-memory/artifacts/review/
.agent-memory/artifacts/prompt/
```

规则：

- `/ap:plan` 为每个开发任务生成一个执行 prompt
- `/ap:review` 为每个问题生成一个修复 prompt
- `/ap:plan` 和 `/ap:review` 生成的开发计划、review 结果和 prompt 必须持久化保存到 `.agent-memory/artifacts/`
- 不支持 `/ap:` 子命令的 agent 走自然语言等价流程时，也必须保存到同样的位置
- `/ap:execute` 优先读取关联 prompt，并在执行后自动完成验证与完成记录
- 协议内部会用 `tasks.json` 保存状态；对使用者来说，真正需要关注的是 prompt 内容

同时，task 本身也要带上最小但关键的来源索引，至少包括：

- `origin_command`
- `origin_artifact_id`
- `prompt_artifact_id`
- `source_summary`
- `acceptance`
- `depends_on`

## 命令

### `/ap:plan`

输入：用户给出的需求、目标或设计意图。
行为：结合项目代码、现有结构、依赖和边界，拆成开发任务，并生成指导其他 agent 执行的 prompt。

自然语言等价触发：

- “帮我根据这个需求整理开发计划”
- “结合当前代码拆解实现方案”
- “给我一组可以让别的 agent 直接执行的开发 prompt”

`plan` 产物必须包含：

- 任务标题
- 优先级
- 背景和目标
- 明确范围
- 建议实现方式
- 验收标准
- 推荐执行命令，通常是 `/ap:execute <plan-prompt>`

### `/ap:review`

输入：代码范围、模块、最近改动或整个项目。
行为：输出 review 结果，并为每个明确问题生成修复 prompt。

自然语言等价触发：

- “review 这段代码”
- “检查这个模块有没有问题，并给出修复 prompt”
- “审查最近改动并整理可执行修复项”

`review` 产物必须包含：

- 问题描述
- 影响范围
- 风险级别
- 复现或观察依据
- 修复建议
- 验收方式
- 推荐执行命令，通常是 `/ap:execute <task-id>`

### `/ap:execute`

输入：`plan` 或 `review` 生成的 task / prompt。
行为：读取 task、来源 artifact 和 prompt，并按约束实现需求或修复问题，不扩散修改范围。

自然语言等价触发：

- “执行刚才 plan 生成的第 2 条 prompt”
- “按照这个开发 prompt 去实现”
- “根据这个开发 prompt 继续做代码实现”

### `/ap:fix`

兼容别名：等价于 `/ap:execute`，但保留给“修复 review 问题”的使用习惯。

自然语言等价触发：

- “修复刚才 review 的第 1 个问题”
- “按照这个修复 prompt 改代码”
- “执行这条 review 修复建议”

### `/ap:clean`

输入：`history` 或 `all`。
行为：

- `history`：保留活动 task，删除 `done` / `cancelled` task 和对应历史 artifact
- `all`：保留目录结构与 `agent-protocol.md`，把 `.agent-memory` 重置为初始化后的空状态

## Prompt 质量规则

这是协议里最重要的部分。

一个高质量 prompt 必须做到 4 件事：

1. 问题定义清楚
   不能写“优化这里”或“修一下这个逻辑”，必须写出当前行为、期望行为、风险或症状。

2. 边界清楚
   必须明确允许改哪些文件、模块、接口、测试；明确哪些内容不能动。

3. 指导性强
   不是只指出问题，还要给出建议修复路径、优先方案、兼容要求和验证方法。

4. 可验收
   必须给出测试、检查步骤或可观察的完成标准。

## Prompt 标准结构

每个执行 prompt 至少包含：

- `Goal`
- `Priority`
- `Source Context`
- `Task Contract Snapshot`
- `Scope`
- `Problem`
- `Constraints`
- `Suggested Fix`
- `Validation`
- `Deliverable`
- `Command Hint`

示例可参考：

- [plan-execution-prompt.example.md](/Users/zhangpeng/GolandProjects/github.com/Gentleelephant/agent-protocol/skills/agent-protocol/references/examples/plan-execution-prompt.example.md)
- [review-fix-prompt.example.md](/Users/zhangpeng/GolandProjects/github.com/Gentleelephant/agent-protocol/skills/agent-protocol/references/examples/review-fix-prompt.example.md)

补充要求：

- `Priority` 只能用 `high` / `medium` / `low`
- `Source Context` 必须复制 review 结论或计划依据的关键摘要
- `Task Contract Snapshot` 必须重述 task 的 `spec`、`acceptance` 和依赖信息
- `Scope` 必须尽量落到具体文件、目录、模块、接口
- `Constraints` 必须写出禁止项
- `Suggested Fix` 必须优先写推荐方案，避免给一堆无排序选项
- `Validation` 必须写具体命令、测试点或验收现象

## Prompt 生成要求

### 对 `/ap:plan`

生成 prompt 时必须：

- 先读代码再拆任务，不能只按需求文本空想
- 优先沿用现有架构、命名、依赖和测试模式
- 把大需求拆成多个小 prompt，而不是一个大而模糊的 prompt
- 每个 prompt 只对应一个主要结果
- 标出任务之间的依赖和优先级

### 对 `/ap:review`

生成 prompt 时必须：

- 先给 review 结论，再决定是否需要生成修复 prompt
- 只有“可执行问题”才生成 prompt
- 每个 prompt 只处理一个独立问题，避免混合多个问题
- 明确这是 bug fix、风险修复，还是行为校正
- 如果问题信息不足，prompt 要写明需要先确认什么
- review 产出的新 task 应优先使用 `bug` 类型，而不是 `review`

## 初始化

初始化：

```text
/ap:init
```

执行后会同时完成两件事：

- 初始化 `.agent-memory/`
- 根据 `--agent` 创建对应的本地入口文件和项目级 `/ap:` 子命令

Claude Code 入口规则：

- `skills/ap:init/SKILL.md` 是默认 bootstrap 入口
- 这个入口只负责把 `/ap:init` 暴露给 Claude，并转发到主 `agent-protocol` skill 的 Init Workflow
- 其他 `/ap:plan`、`/ap:review`、`/ap:execute`、`/ap:fix`、`/ap:clean` 仍然通过 `init.sh` 或 `install-commands.sh` 安装到项目目录或用户目录

脚本参数：

- `--project`：必填
- `--agent all|claude|mastracode|reasonix`：可选，默认 `all`

`--agent` 对应行为：

- `all`：创建 `CLAUDE.local.md`、`.mastracode/AGENTS.md`，并安装 Claude、Mastra Code、Reasonix 三个平台的子命令
- `claude`：只创建 `CLAUDE.local.md`，只安装 `.claude/commands/`
- `mastracode`：只创建 `.mastracode/AGENTS.md`，只安装 `.mastracode/commands/ap/`
- `reasonix`：只安装 `.reasonix/commands/ap/`

幂等规则：

- 已存在的目录会跳过
- 已存在的文件会跳过
- 已存在的子命令文件会跳过
- 已存在的 `.agent-memory/tasks.json` 会保留

示例：

```bash
bash /Users/zhangpeng/GolandProjects/github.com/Gentleelephant/agent-protocol/skills/agent-protocol/scripts/init.sh --project --agent claude
```

## 安装子命令

如果你只想单独重装当前项目下的 Claude Code、Mastra Code 和 Reasonix 子命令，而不重新执行 `init`：

```bash
bash /Users/zhangpeng/GolandProjects/github.com/Gentleelephant/agent-protocol/skills/agent-protocol/scripts/install-commands.sh
```

只安装 Claude Code：

```bash
bash /Users/zhangpeng/GolandProjects/github.com/Gentleelephant/agent-protocol/skills/agent-protocol/scripts/install-commands.sh --agent claude
```

只安装 Mastra Code：

```bash
bash /Users/zhangpeng/GolandProjects/github.com/Gentleelephant/agent-protocol/skills/agent-protocol/scripts/install-commands.sh --agent mastracode
```

只安装 Reasonix：

```bash
bash /Users/zhangpeng/GolandProjects/github.com/Gentleelephant/agent-protocol/skills/agent-protocol/scripts/install-commands.sh --agent reasonix
```

Reasonix 自定义命令规则：

- 项目级命令写入 `.reasonix/commands/ap/*.md`
- 用户级命令写入 `~/.config/reasonix/commands/ap/*.md`
- 子目录构成命名空间，例如 `ap/plan.md` 对应 `/ap:plan`
- Markdown 文件正文就是 prompt 模板；Reasonix 适配文件不包含 frontmatter

安装到用户级目录而不是项目目录：

```bash
bash /Users/zhangpeng/GolandProjects/github.com/Gentleelephant/agent-protocol/skills/agent-protocol/scripts/install-commands.sh --scope user
```

规则：

- 默认 `--agent all`
- 默认 `--scope project`
- `project` 会写入 `.claude/`、`.mastracode/` 和 `.reasonix/`
- `user` 会写入 `~/.claude/`、`~/.mastracode/` 和 `~/.config/reasonix/`
- 已存在的命令文件会跳过，不覆盖
- 这个安装动作只复制命令文件，不会重新初始化 `.agent-memory/`

## 说明

- `tasks.json` 是协议内部状态唯一来源
- `.agent-memory/artifacts/prompt/` 是给 agent 直接执行的核心输出
- 如果 prompt 和内部 `task.spec` 冲突，以 `task.spec` 为准
- 不支持 `/ap:` 子命令的 agent 也必须通过自然语言执行同样工作流
- 协议公开接口默认只保留 `plan / review / execute / fix`，其余步骤由执行流程自动完成
