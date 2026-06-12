---
name: agent-protocol
version: v3.37
description: "Use only for explicit agent-protocol workflows: /ap:init, /ap:install, /ap:run, /ap:plan, /ap:review, /ap:import, /ap:execute, /ap:prune, /ap:reset, installing /ap commands, creating persistent agent handoff tasks/prompts, or Chinese requests that explicitly ask for agent-protocol handoff such as 按 agent-protocol, 自动完成并提交, 生成可执行任务, 生成交接 prompt, 导入执行 prompt, 执行已有 task. Do not use for ordinary code review, debugging, planning, implementation, or code explanation unless the user explicitly asks to create protocol tasks/artifacts or use /ap."
---

# Agent Protocol

Use this skill only when the user explicitly wants the persistent `/ap:` task-and-artifact workflow. Keep the entrypoint lean: load supporting files only for the command being executed.

## Cache-Aware Rules

- Do not load `.agent-memory/tasks.json` or artifacts unless the current `/ap:` command needs them.
- Do not read historical artifacts broadly. Read only the target task, its `prompt_artifact_id`, or directly referenced artifacts.
- If `graphify-out/` exists and the command needs architecture, module, or cross-file orientation, use the `graphify` skill to `query`, `explain`, or `path` before broad grep or multi-file reads.
- Treat Graphify as an orientation index only. Verify concrete behavior in source files, scripts, schemas, or protocol docs before writing tasks or fixes.
- Optional planning or reasoning skills may advise `/ap:plan` and complex `/ap:review`, but they must not own `.agent-memory` state or write protocol artifacts directly.
- Do not treat generic words like "review", "plan", "fix", or "debug" as protocol intent by themselves.
- Prefer normal coding-agent behavior when the user asks for direct implementation or ordinary analysis without handoff artifacts.

## Trigger Contract

Trigger this skill for:

- Literal `/ap:init`, `/ap:install`, `/ap:run`, `/ap:plan`, `/ap:review`, `/ap:import`, `/ap:execute`, `/ap:prune`, or `/ap:reset`.
- Requests to install `/ap` commands or agent-protocol command adapters.
- Requests to create persistent tasks, execution prompts, handoff prompts, or `.agent-memory` artifacts.
- Explicit Chinese protocol intent such as `按 agent-protocol`, `自动完成并提交`, `生成可执行任务`, `生成交接 prompt`, `导入执行 prompt`, `执行已有 task`, `清理 .agent-memory`, `重置 .agent-memory`.

Do not trigger for:

- Ordinary code review, bug fixing, refactoring, architecture discussion, or code explanation.
- Requests that say `直接改`, `直接实现`, `不用创建任务`, `不用 protocol`, or `no protocol`.

## Source Files

Read only the file needed for the active command:

- `references/workflows.md`: command procedures for `/ap:init`, install, orchestration, task creation, execution, and cleanup.
- `references/protocol.md`: task/artifact data model, lifecycle, and recovery rules.
- `references/roles/planner.md`: planning or review quality checklist.
- `references/roles/executor.md`: implementation checklist for executing tasks.
- `references/execution-prompt-template.md`: execution prompt shape.
- `references/schema/tasks.schema.json`: validate or repair `.agent-memory/tasks.json`.
- `references/examples/*.example.md`: use only when a concrete prompt example is needed.
- `scripts/init.sh`, `scripts/install-commands.sh`, and `scripts/prune.sh`: preferred deterministic implementation for init/install/prune.

## Command Routing

- `/ap:init`: initialize project-local personal protocol state only. Read `references/workflows.md`; prefer `scripts/init.sh`.
- `/ap:install`: refresh command adapters only. Read `references/workflows.md`; prefer `scripts/install-commands.sh`.
- `/ap:run`: orchestrate a requirement or an existing task set. The main agent may create tasks using plan semantics, prepare execution prompts, delegate implementation, review results, and finish with commit/push. Read `references/workflows.md`, `references/protocol.md`, and both planner/executor guidance.
- `/ap:plan`: inspect the requirement and project context, using Graphify first when available for cross-file orientation, then create tasks and write plan plus execution prompt artifacts. Read `references/workflows.md`, `references/protocol.md`, and planner guidance.
- `/ap:review`: inspect code, using Graphify first when available for broad scope review, then create actionable bug/design tasks and write review plus execution prompt artifacts. Read `references/workflows.md`, `references/protocol.md`, and planner guidance.
- `/ap:import`: normalize external execution prompt, prompt artifact, plan artifact, or plan document into task and artifact state only; do not implement code. Read `references/workflows.md`, `references/protocol.md`, and planner guidance.
- `/ap:execute`: pick and implement an existing pending task only. Do not accept direct prompt or plan input. This is the low-level execution path, not the main-agent orchestration entrypoint. Read `references/workflows.md`, `references/protocol.md`, and executor guidance.
- `/ap:prune`: remove completed/cancelled history only. Read `references/workflows.md`; prefer `scripts/prune.sh`.
- `/ap:reset`: reset local `.agent-memory` state only. Read `references/workflows.md`.

## Persistent State

Project-local protocol state lives in:

```text
.agent-memory/agent-protocol.md
.agent-memory/tasks.json
.agent-memory/artifacts/
```

Keep project-local protocol files private and do not require team-shared `AGENTS.md` or `CLAUDE.md`.
