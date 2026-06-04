---
name: agent-protocol
version: v3.20
description: "Use only for explicit agent-protocol workflows: /ap:init, /ap:plan, /ap:review, /ap:execute, /ap:fix, /ap:clean, installing /ap commands, creating persistent agent handoff tasks/prompts, or Chinese requests that explicitly ask for agent-protocol handoff such as 按 agent-protocol, 生成可执行任务, 生成交接 prompt, 执行已有 task. Do not use for ordinary code review, debugging, planning, implementation, or code explanation unless the user explicitly asks to create protocol tasks/artifacts or use /ap."
---

# Agent Protocol

Use this skill only when the user explicitly wants the persistent `/ap:` task-and-artifact workflow. Keep the entrypoint lean: load supporting files only for the command being executed.

## Cache-Aware Rules

- Do not load `.agent-memory/tasks.json` or artifacts unless the current `/ap:` command needs them.
- Do not read historical artifacts broadly. Read only the target task, its `prompt_artifact_id`, or directly referenced artifacts.
- Do not treat generic words like "review", "plan", "fix", or "debug" as protocol intent by themselves.
- Prefer normal coding-agent behavior when the user asks for direct implementation or ordinary analysis without handoff artifacts.

## Trigger Contract

Trigger this skill for:

- Literal `/ap:init`, `/ap:plan`, `/ap:review`, `/ap:execute`, `/ap:fix`, or `/ap:clean`.
- Requests to install `/ap` commands or agent-protocol command adapters.
- Requests to create persistent tasks, execution prompts, handoff prompts, or `.agent-memory` artifacts.
- Explicit Chinese protocol intent such as `按 agent-protocol`, `生成可执行任务`, `生成交接 prompt`, `执行已有 task`, `清理 .agent-memory`.

Do not trigger for:

- Ordinary code review, bug fixing, refactoring, architecture discussion, or code explanation.
- Requests that say `直接改`, `直接实现`, `不用创建任务`, `不用 protocol`, or `no protocol`.

## Source Files

Read only the file needed for the active command:

- `references/workflows.md`: command procedures for `/ap:init`, install, task creation, execution, and cleanup.
- `references/protocol.md`: task/artifact data model, lifecycle, and recovery rules.
- `references/roles/planner.md`: planning or review quality checklist.
- `references/roles/executor.md`: implementation checklist for executing tasks.
- `references/execution-prompt-template.md`: execution prompt shape.
- `references/schema/tasks.schema.json`: validate or repair `.agent-memory/tasks.json`.
- `references/examples/*.example.md`: use only when a concrete prompt example is needed.
- `scripts/init.sh` and `scripts/install-commands.sh`: preferred deterministic implementation for init/install.

## Command Routing

- `/ap:init`: initialize or update project-local personal protocol files and command adapters. Read `references/workflows.md`; prefer `scripts/init.sh`.
- Install commands: refresh command adapters only. Read `references/workflows.md`; prefer `scripts/install-commands.sh`.
- `/ap:plan`: inspect the requirement and project context, create tasks, and write plan plus execution prompt artifacts. Read `references/workflows.md`, `references/protocol.md`, and planner guidance.
- `/ap:review`: inspect code, create actionable bug/design tasks, and write review plus execution prompt artifacts. Read `references/workflows.md`, `references/protocol.md`, and planner guidance.
- `/ap:execute` or `/ap:fix`: pick the requested pending task, read only its prompt/source artifacts as needed, implement, verify, write completion artifact, and update state. Read `references/workflows.md`, `references/protocol.md`, and executor guidance.
- `/ap:clean`: clean `.agent-memory` history or reset it. Read `references/workflows.md`.

## Persistent State

Project-local protocol state lives in:

```text
.agent-memory/agent-protocol.md
.agent-memory/tasks.json
.agent-memory/artifacts/
```

Keep project-local protocol files private and do not require team-shared `AGENTS.md` or `CLAUDE.md`.
