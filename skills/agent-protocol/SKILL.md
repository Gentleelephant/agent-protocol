---
name: agent-protocol
description: Use when a project has agent-protocol enabled or the user asks to plan, review, create tasks, hand work to an executor, process .agent-memory/tasks.json, or coordinate Planner/Executor agents across Codex, Claude Code, opencode, or other agents.
---

# Agent Protocol

Use this skill to reduce friction when working in projects that use `agent-protocol`.

## Source Of Truth

Before acting, inspect the project-level protocol files when present:

- `AGENTS.md`
- `CLAUDE.md`
- `.agent-memory/tasks.json`
- `~/.agent-protocol/PROTOCOL.md`
- `~/.agent-protocol/roles/planner.md`
- `~/.agent-protocol/roles/executor.md`

If the project has not been initialized, tell the user to run:

```bash
~/.agent-protocol/init.sh --project
```

## Role Selection

Choose the role from the user's intent:

- Planner: analysis, design, decomposition, review, architecture decisions, creating work for another agent.
- Executor: implementation, bug fixing, tests, applying an existing pending task.

If the user asks for planning, review, task creation, or handoff, do not edit production code. Act as Planner and append tasks.

If the user asks to implement pending tasks or continue executor work, act as Executor.

If the user asks to directly implement a feature and does not mention protocol/task handoff, follow normal coding behavior unless `AGENTS.md` explicitly requires protocol workflow.

## Planner Workflow

1. Read protocol and planner role files.
2. Inspect enough project context to create concrete tasks.
3. Load `.agent-memory/tasks.json`; create it as `{"tasks": []}` if missing.
4. Append new tasks only. Do not overwrite existing tasks.
5. Use `status: "pending"` and `created_by: "planner"`.
6. Fill `id`, `type`, `title`, `context`, `spec`, `created_at`, and `updated_at`.
7. Do not fill `implementation_notes` unless preserving an existing value.

Task ids should continue the existing `task-NNN` sequence.

Allowed task types:

- `review`
- `feature`
- `design`
- `bug`

When reviewing Executor work, Planner may change completed tasks from `done` to `verified` after checking the implementation.

## Executor Workflow

1. Read protocol and executor role files.
2. Load `.agent-memory/tasks.json`.
3. Pick pending tasks relevant to the user's request.
4. Change claimed tasks to `in_progress`.
5. Implement or fix according to `spec`.
6. Run appropriate verification.
7. Change completed tasks to `done`.
8. Fill `implementation_notes` and `updated_at`.

Do not modify Planner-owned fields such as `spec`, `context`, `title`, or `created_by`.

Do not mark tasks `verified`; that is Planner's job.

## Task JSON Shape

Use this shape for new tasks:

```json
{
  "id": "task-001",
  "type": "review",
  "created_by": "planner",
  "status": "pending",
  "title": "Short actionable title",
  "context": "Why this task exists.",
  "spec": "Concrete instructions for Executor.",
  "implementation_notes": "",
  "created_at": "YYYY-MM-DDTHH:MM:SSZ",
  "updated_at": "YYYY-MM-DDTHH:MM:SSZ"
}
```

## User-Facing Behavior

When Planner creates tasks, summarize the task ids and titles.

When Executor completes tasks, summarize changed files, verification, and task statuses.

Keep the protocol file as the shared state; do not rely on conversation memory for handoff-critical details.
