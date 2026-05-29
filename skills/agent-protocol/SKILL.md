---
name: agent-protocol
description: Use when the user asks to plan, review, create tasks, hand work to an executor, process .agent-memory/tasks.json, or coordinate Planner/Executor work across Codex, Claude Code, and Mastra Code using project-level personal agent-protocol configuration.
---

# Agent Protocol

Use this skill to reduce friction when working with project-level personal `agent-protocol` configuration.

## Source Of Truth

The installed `agent-protocol` skill is the protocol source of truth.

Use project-local private files for per-project behavior and task state:

- `.agent-memory/agent-protocol.md`
- `.agent-memory/tasks.json`

Do not require team-shared project `AGENTS.md` or `CLAUDE.md`. This protocol is intended to work from project-level personal entries that are ignored by Git:

- `AGENTS.override.md` for Codex
- `CLAUDE.local.md` for Claude Code
- `.mastracode/AGENTS.md` for Mastra Code

Each agent should have this skill installed separately. The skill defines the shared workflow; the project entry file tells the specific agent where to read the project-level personal protocol config.

If the project has no task state and the user wants protocol handoff, run `/ap:init` or tell the user to run:

```bash
curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/main/init.sh | bash -s -- --project
```

## Role Selection

Choose the role from the user's intent:

- Planner: review, code audit, issue finding, analysis, design, decomposition, architecture decisions, creating work for another agent.
- Executor: processing pending tasks, implementing an existing task, fixing an assigned task, testing a claimed task.

Default trigger rules:

- User says review, audit, inspect, check code, find bugs, security issue, performance issue, design issue: act as Planner and create pending tasks.
- User says plan, design, break down, analyze requirement, architecture decision: act as Planner and create feature or design tasks.
- User says process pending task, implement task, fix task, continue Executor work: act as Executor and update task state.
- User says verify, validate, review done task, accept done task: act as Planner and mark valid done tasks as verified.
- User explicitly says directly implement, directly edit code, do not create tasks, or no protocol: follow normal coding behavior for that request.

If the user asks for planning, review, task creation, or handoff, do not edit production code. Act as Planner and append tasks.

If the user asks to implement pending tasks or continue executor work, act as Executor.

If the user asks to directly implement a feature and does not mention protocol/task handoff, follow normal coding behavior unless project-level personal instructions explicitly require protocol workflow.

## Commands

All protocol commands use the `/ap:` namespace to avoid collisions with agent-native commands.

Planner-only:

- `/ap:review [scope]`: review code and create review tasks; do not edit production code.
- `/ap:plan [requirement]`: analyze requirements or architecture and create feature/design tasks.
- `/ap:task [summary]`: save the current discussion result as a pending task.
- `/ap:verify [task-id|all]`: verify done tasks and mark valid tasks as verified.

Executor-only:

- `/ap:execute [task-id|next]`: claim and execute pending tasks.
- `/ap:fix [task-id]`: fix a specific bug/review task.
- `/ap:test [task-id]`: run verification and record results.
- `/ap:done [task-id]`: mark a task done and fill implementation notes.

Any role:

- `/ap:init planner=<agent> executor=<agent>`: initialize or update personal protocol files and project-local private config.
- `/ap:tasks`: list tasks.
- `/ap:status`: summarize task counts and next recommended action.
- `/ap:help`: show command help.
- `/ap:whoami`: show configured Planner and Executor for this project.
- `/ap:switch planner|executor`: switch current-session perspective only; do not modify project config.

## Command Role Gate

Before executing any `/ap:` command with side effects, except `/ap:init`:

1. Read `.agent-memory/agent-protocol.md`.
2. Identify the configured `Planner` and `Executor`.
3. Identify the current agent name from the project entry or runtime context.
4. If the command is Planner-only, execute it only when the current agent matches the configured Planner.
5. If the command is Executor-only, execute it only when the current agent matches the configured Executor.
6. If the command is any-role, execute only the read-only behavior unless it is `/ap:init`.

When roles do not match, do not create tasks, edit code, or change task status. Tell the user:

- current agent role
- required role for the command
- configured agent that should run it
- the command to change project binding:

```bash
/ap:init planner=<agent> executor=<agent>
```

`/ap:switch` changes only current-session perspective. It must not bypass project role binding for side-effect commands.

## Init Workflow

`/ap:init` is a configuration command. Any agent may run it because it does not implement product code or complete protocol tasks.

Syntax:

```text
/ap:init planner=<agent> executor=<agent>
```

Examples:

```text
/ap:init planner=Codex executor=mastracode
/ap:init planner="Claude Code" executor=mastracode
```

If `planner` or `executor` is omitted, use the existing value from `.agent-memory/agent-protocol.md` when present. If no existing value exists, use `Planner: Codex` and `Executor: Claude Code`, then report the defaults.

When running `/ap:init`, create or update these project-local private files:

```text
.agent-memory/agent-protocol.md
.agent-memory/tasks.json
AGENTS.override.md
CLAUDE.local.md
.mastracode/AGENTS.md
```

If the current directory is a git repo, add these patterns to `.git/info/exclude` if missing:

```text
.agent-memory/
AGENTS.override.md
CLAUDE.local.md
.mastracode/AGENTS.md
```

Do not edit team-shared project `AGENTS.md` or `CLAUDE.md`.

`/ap:init` should preserve existing `.agent-memory/tasks.json`. Create it as `{"tasks": []}` only when it is missing.

After init, summarize the configured Planner, Executor, created/updated files, and whether `.git/info/exclude` was updated.

Init file content requirements:

- `.agent-memory/agent-protocol.md`: include configured Planner/Executor, skill as protocol source, role split, default trigger rules, `/ap:` command table, command role gate, task lifecycle, and project-local privacy rules.
- `AGENTS.override.md`, `CLAUDE.local.md`, `.mastracode/AGENTS.md`: keep these short; they should point to `.agent-memory/agent-protocol.md`, mention default trigger behavior, list `/ap:` commands, and require command role gate checks before side effects.
- `.agent-memory/tasks.json`: preserve existing tasks. If missing, create exactly `{"tasks": []}`.

## Planner Workflow

1. Read `.agent-memory/agent-protocol.md` if present.
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

1. Read `.agent-memory/agent-protocol.md` if present.
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

Do not require the user to say "use agent-protocol" or "act as Planner/Executor" when the intent clearly matches the default trigger rules.

Keep the protocol file as the shared state; do not rely on conversation memory for handoff-critical details.
