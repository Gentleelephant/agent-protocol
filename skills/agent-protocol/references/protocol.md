# Agent Protocol Reference

## 工作模式

默认采用单 agent 工作流：

- 同一个 agent 可以 review、plan、fix、execute，并在执行中自动完成验证和完成记录
- 不再依赖 Planner / Executor 角色门禁
- 如果项目里还保留 `planner` / `executor` 字段，它们只作为兼容信息展示，不作为执行限制

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

## 任务结构（JSON）

```json
{
  "id": "task-001",
  "type": "review|feature|design|bug",
  "created_by": "agent|planner",
  "status": "pending|in_progress|blocked|done|cancelled",
  "priority": "high|medium|low",
  "title": "简短描述",
  "context": "背景和原因",
  "spec": "具体实现契约",
  "implementation_notes": "实现备注摘要",
  "artifact_refs": ["artifact-review-001"],
  "last_reviewed_at": "",
  "last_tested_at": "",
  "created_at": "",
  "updated_at": ""
}
```

新任务默认写 `created_by: "agent"`。旧任务若保留 `created_by: "planner"`，按兼容模式继续读取。

## Artifact 结构

`artifact` 是 `.agent-memory/artifacts/` 下的 Markdown 结果文件，用于保存完整 review、plan、prompt、done 记录。

推荐目录：

```text
.agent-memory/artifacts/
  review/
  plan/
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
- `execution_prompt`
- `completion_record`

## Execution Prompt Artifact

对于 `/ap:review`、`/ap:plan` 产生的每个可执行 task，还应生成一个可直接交给其他 agent 或当前 agent 自己执行的 prompt artifact，存放到：

```text
.agent-memory/artifacts/prompt/
```

这个 prompt 必须明确：

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
- prompt 必须具体到文件、模块、行为和验证标准，不能只写笼统建议。

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
- 追加任务，不覆盖整个文件
- 项目级个人配置不提交到团队仓库

## 异常恢复

- `tasks.json` 缺失：创建 `{"tasks": []}`。
- `artifacts/` 缺失：创建目录，不影响既有 task。
- `tasks.json` 非法：停止副作用操作，说明需要修复的位置。
- task 引用缺失的 artifact：提示引用失效，但不要中断只读查询。
- task id 有间断：从最大编号继续递增。
- `.agent-memory/agent-protocol.md` 中若存在 legacy `planner` / `executor` 绑定，不要用它们拒绝执行。
