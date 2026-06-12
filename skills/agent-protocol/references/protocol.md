# Agent Protocol Reference

## 工作模式

- 不要求显式声明角色
- 任何 agent 都可以读取并推进 task 与 artifact

## 共享记忆位置

项目根目录下：

```text
.agent-memory/tasks.json
.agent-memory/artifacts/
.agent-memory/agent-protocol.md
```

## 任务类型

- `review`
- `feature`
- `design`
- `bug`

这些类型表示“待执行工作”。不要把 `review_result`、`plan_record`、`execution_prompt`、`completion_record` 之类结果类型塞进 `task.type`。

新任务应优先使用：

- `bug`
- `feature`
- `design`

分类规则：

- `bug`：修复已存在错误、回归、风险、review finding 或行为校正。
- `feature`：新增或扩展用户可见能力、命令能力或产品行为。
- `design`：协议、架构、接口契约、文档规范、跨模块设计调整，或主要交付物是设计约束而非直接功能。
- `review`：仅兼容旧 task，新 task 不得使用。

`origin_command` 表示任务来源，只能是 `review`、`plan`、`import` 或 `run`。它不同于 `task.type`；例如 `/ap:review` 产生的新 task 通常是 `type: "bug"` 且 `origin_command: "review"`；`/ap:run` 若在启动时按 plan 语义一次性创建 task，则这些 task 的来源可以写成 `run`。

## 任务结构（JSON）

```json
{
  "id": "task-001",
  "type": "review|feature|design|bug",
  "created_by": "agent",
  "status": "pending|in_progress|blocked|done|cancelled",
  "priority": "high|medium|low",
  "title": "简短描述",
  "context": "背景和原因",
  "spec": "具体实现契约",
  "origin_command": "review|plan|import|run",
  "origin_artifact_id": "artifact-review-001",
  "prompt_artifact_id": "artifact-prompt-001",
  "source_summary": "任务来源摘要",
  "acceptance": "验收标准摘要",
  "depends_on": [],
  "implementation_notes": "实现备注摘要",
  "artifact_refs": ["artifact-review-001", "artifact-prompt-001"],
  "last_reviewed_at": "",
  "last_tested_at": "",
  "created_at": "",
  "updated_at": ""
}
```

新任务统一写 `created_by: "agent"`。

## Artifact 结构

`artifact` 是 `.agent-memory/artifacts/` 下的 Markdown 结果文件，用于保存完整 review、plan、run、prompt、done 记录。

推荐目录：

```text
.agent-memory/artifacts/
  review/
  plan/
  run/
  prompt/
  done/
```

推荐命名：

```text
<timestamp>__<command>__<task-id-or-scope>.md
```

推荐 artifact 逻辑类型：

- `review_result`
- `plan_record`
- `run_record`
- `execution_prompt`
- `completion_record`

## Execution Prompt Artifact

对于 `/ap:review`、`/ap:plan` 或 `/ap:run` 准备执行的每个可执行 task，还应生成一个可直接交给其他 agent 或当前 agent 自己执行的 prompt artifact，存放到：

```text
.agent-memory/artifacts/prompt/
```

这个 prompt 必须持久化保存，并明确：

- 要解决什么问题
- 允许改哪些范围
- 禁止改哪些内容
- 推荐怎样修复或实现
- 如何验证完成
- 该使用哪个 `/ap:` 子命令继续执行

推荐头部字段：

```text
artifact_id:
artifact_type: execution_prompt
command:
related_task_ids:
origin_artifact_id:
scope:
created_at:
created_by_role:
agent:
command_hint:
target_role: implementing-agent
summary:
```

推荐正文结构：

```text
## Goal
## Priority
## Source Context
## Task Contract Snapshot
## Scope
## Problem
## Constraints
## Suggested Fix
## Validation
## Deliverable
## Command Hint
```

约束：

- `task.spec` 仍然是 task 的规范来源，prompt artifact 是给实现阶段直接使用的展开版说明。
- prompt 不应与 `task.spec` 冲突；若冲突，以 `task.spec` 为准并回报不一致。
- `Goal` 应只包含一个主要目标，不要把多个实现结果混成一个 prompt。
- prompt 必须复制足够的 review 或 plan 摘要，不能要求执行 agent 仅靠会话上下文还原任务背景。
- `Source Context` 应尽量附带压缩后的证据锚点，例如文件、符号、测试、报错或依赖关系；如果存在推断，应显式标出。
- prompt 必须具体到文件、模块、行为和验证标准，不能只写笼统建议。
- `Validation` 应优先写明确命令和预期通过信号；如果环境不稳定，至少写最小替代验证路径。
- `Deliverable` 应说明执行完成后要回报哪些结果，例如改动摘要、验证结果和 blocker。
- `/ap:plan`、`/ap:review` 和 `/ap:run` 无论通过子命令还是自然语言等价意图触发，都必须把对应 artifact 持久化写入 `.agent-memory/artifacts/`。

## 状态流转

```text
pending → in_progress → done
             │
             └→ blocked

pending|blocked|in_progress → cancelled
```

辅助状态：

- `blocked`：当前实现无法继续，需要用户输入、外部依赖、凭据或其他 task。
- `cancelled`：该任务不再需要。

## 规则

- `tasks.json` 是任务索引和状态流转的唯一来源
- `artifact` 保存完整结果，task 只保留摘要和引用
- 开发计划、review 结果和 execution prompt 必须落盘保存，不能只留在对话上下文
- `/ap:run` 的编排记录、主 agent review 结论与最终提交结果也必须落盘保存
- task 应保存最小但关键的来源索引，执行 agent 不应被迫重新猜测 prompt 和来源 artifact
- `/ap:import` 可以接收直接粘贴的 execution prompt、prompt artifact、plan artifact 或 plan 文档作为入口，并且只能把输入归一化为 task 和 artifact；不能直接改代码
- 直接 prompt 输入应保存到 `.agent-memory/artifacts/prompt/` 并创建或匹配一个 pending task；直接 plan 输入应保存到 `.agent-memory/artifacts/plan/`，再拆成 task 和对应 execution prompt
- 如果 plan 文档包含多个可执行项，只能创建或列出 task，不应隐式连续执行多个任务
- `/ap:run` 可以接收自然语言需求、`--all` 或显式 task 集作为入口；当入口是自然语言需求时，主 agent 可以在 run 开头一次性创建整组 task，但不应在执行中无限扩散新增 task
- `/ap:execute` 只能接收已有 task id、`next`、`--all` 和可选 `--origin review|plan|import|run` 来源过滤，不能创建 task，不能接收直接 prompt 或 plan；协议不提供 `--one` 或 `--loop`
- `/ap:execute --all` 是当前 agent 会话内的安全串行批处理：每轮重新读取 `tasks.json`，一次只认领一个 task，优先恢复匹配的 `in_progress` task，不并行，不启动外部 supervisor
- `/ap:run` 是主 agent orchestration 入口：主 agent 负责拆任务或读取既有 task、准备 execution prompt、委派子 agent、review 子 agent 结果，并在全部通过后统一 `commit/push`
- `/ap:run` 默认串行处理 task，不并行，不让子 agent 直接提交 git 历史
- `/ap:install` 应刷新协议管理的命令文件：缺失则创建，内容变化则覆盖更新，内容一致才跳过
- `/ap:prune` 应优先复用确定性脚本 `skills/agent-protocol/scripts/prune.sh`，避免不同 agent 各自实现不同的清理口径
- 追加任务，不覆盖整个文件
- 项目级个人配置不提交到团队仓库

## 异常恢复

- `tasks.json` 缺失：创建 `{"tasks": []}`。
- `artifacts/` 缺失：创建目录，不影响既有 task。
- `tasks.json` 非法：停止副作用操作，说明需要修复的位置。
- task 引用缺失的 artifact：提示引用失效，但不要中断只读查询。
- task id 有间断：从最大编号继续递增。
