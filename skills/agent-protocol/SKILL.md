---
name: agent-protocol
description: Use when the user asks to plan, review, create tasks, hand work to an executor, process .agent-memory/tasks.json, or coordinate Planner/Executor agents across coding agents using the personal agent-protocol installation.
---

# Agent Protocol

Use this skill to reduce friction when working with the personal `agent-protocol` installation.

## Source Of Truth

Before acting, inspect these personal protocol files when present:

- `~/.agent-protocol/PROTOCOL.md`
- `~/.agent-protocol/roles/planner.md`
- `~/.agent-protocol/roles/executor.md`

Use project files only for task state:

- `.agent-memory/agent-protocol.md`
- `.agent-memory/tasks.json`

Do not require project-level `AGENTS.md` or `CLAUDE.md`; this protocol is intended to work from personal agent configuration plus project-local private state under `.agent-memory/`.

If the project has no task state and the user wants protocol handoff, tell the user to run:

```bash
~/.agent-protocol/init.sh --project
```

## Role Selection

Choose the role from the user's intent:

- Planner: analysis, design, decomposition, review, architecture decisions, creating work for another agent.
- Executor: implementation, bug fixing, tests, applying an existing pending task.

If the user asks for planning, review, task creation, or handoff, do not edit production code. Act as Planner and append tasks.

If the user asks to implement pending tasks or continue executor work, act as Executor.

If the user asks to directly implement a feature and does not mention protocol/task handoff, follow normal coding behavior unless personal instructions explicitly require protocol workflow.

## Planner Workflow

1. Read protocol and planner role files.
2. Read `.agent-memory/agent-protocol.md` if present.
3. Inspect enough project context to create concrete tasks.
4. Load `.agent-memory/tasks.json`; create it as `{"tasks": []}` if missing.
5. Append new tasks only. Do not overwrite existing tasks.
6. Use `status: "pending"` and `created_by: "planner"`.
7. Fill `id`, `type`, `title`, `context`, `spec`, `created_at`, and `updated_at`.
8. Do not fill `implementation_notes` unless preserving an existing value.

Task ids should continue the existing `task-NNN` sequence.

Allowed task types:

- `review`
- `feature`
- `design`
- `bug`

When reviewing Executor work, Planner may change completed tasks from `done` to `verified` after checking the implementation.

## Executor Workflow

1. Read protocol and executor role files.
2. Read `.agent-memory/agent-protocol.md` if present.
3. Load `.agent-memory/tasks.json`.
4. Pick pending tasks relevant to the user's request.
5. Change claimed tasks to `in_progress`.
6. Implement or fix according to `spec`.
7. Run appropriate verification.
8. Change completed tasks to `done`.
9. Fill `implementation_notes` and `updated_at`.

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
