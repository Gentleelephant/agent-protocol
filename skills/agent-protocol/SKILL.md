---
name: agent-protocol
version: v3.4
description: "Use when the user wants to coordinate Claude Code and Mastra Code, set up Planner/Executor workflows, create or manage task handoff between agents, initialize agent collaboration config, review code for another agent to fix, or mentions task tracking, agent roles, multi-agent projects, /ap: commands, .agent-memory/tasks.json, or agent-protocol configuration."
---

# Agent Protocol

Use this skill to reduce friction when working with project-level personal `agent-protocol` configuration.

## Source Of Truth

The installed `agent-protocol` skill directory is the protocol source of truth. `SKILL.md` is the main workflow. Supporting details live next to it:

- `references/protocol.md`
- `references/roles/planner.md`
- `references/roles/executor.md`
- `references/schema/tasks.schema.json`
- `scripts/init.sh`

Read supporting files only when needed:

- Read `references/protocol.md` when lifecycle, task ownership, or recovery rules are unclear.
- Read `references/roles/planner.md` before detailed planning, review, or verification work.
- Read `references/roles/executor.md` before implementing pending tasks or recovering in-progress work.
- Read `references/schema/tasks.schema.json` before validating or repairing `.agent-memory/tasks.json`.

Use project-local private files for per-project behavior and task state:

- `.agent-memory/agent-protocol.md`
- `.agent-memory/tasks.json`

Do not require team-shared project `AGENTS.md` or `CLAUDE.md`. This protocol is intended to work from project-level personal entries that are ignored by Git:

- `CLAUDE.local.md` for Claude Code
- `.mastracode/AGENTS.md` for Mastra Code

Each agent should have this skill installed separately. The skill defines the shared workflow; the project entry file tells the specific agent where to read the project-level personal protocol config.

If the project has no task state and the user wants protocol handoff, run `/ap:init` or tell the user to run:

```bash
curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/main/skills/agent-protocol/scripts/init.sh | bash -s -- --project
```

## Role Selection

Choose the role from the user's intent:

- Planner: review, code audit, issue finding, analysis, design, decomposition, architecture decisions, creating work for another agent.
- Executor: processing pending tasks, implementing an existing task, fixing an assigned task, testing a claimed task.

Default trigger rules:

- User says install commands, install subcommands, install /ap: commands, install agent-protocol commands, 安装子命令: copy command files from this skill's adapters/ directory to the current agent's command path. See Install Workflow below.
- User says review, audit, inspect, check code, find bugs, security issue, performance issue, design issue: act as Planner and create pending tasks.
- User says plan, design, break down, analyze requirement, architecture decision: act as Planner and create feature or design tasks.
- User says process pending task, implement task, fix task, continue Executor work: act as Executor and update task state.
- User says verify, validate, review done task, accept done task: act as Planner and mark valid done tasks as verified.
- User explicitly says directly implement, directly edit code, do not create tasks, or no protocol: follow normal coding behavior for that request.

If the user asks to install agent-protocol commands or subcommands, copy the command files and report what was installed. Do not create tasks. See Install Workflow below.

If the user asks for planning, review, task creation, or handoff, do not edit production code. Act as Planner and append tasks.

If the user asks to implement pending tasks or continue executor work, act as Executor.

If the user asks to directly implement a feature and does not mention protocol/task handoff, follow normal coding behavior unless project-level personal instructions explicitly require protocol workflow.

## Commands

All protocol commands use the `/ap:` namespace to avoid collisions with agent-native commands.

All parameters are optional. When a parameter is omitted, the command uses the default behavior described below. When a parameter is provided, it must follow the syntax shown; unsupported values should be rejected with a clear hint.

Planner-only:

- `/ap:review [scope]`: review code and create review tasks; do not edit production code. Omitted scope means the entire project or current uncommitted changes. Scope examples: `src/auth/`, `pkg/db/`, `app/api.go`, `recent changes`, `all`.
- `/ap:plan [requirement]`: analyze requirements or architecture and create feature/design tasks. Omitted requirement means extract from recent conversation context. Requirement examples: `add user login with JWT`, `migrate monolith to microservices`, `refactor payment module to clean architecture`.
- `/ap:task [summary]`: save the current discussion result as a pending task. Omitted summary means summarize the most recent discussion topic. Summary examples: `fix N+1 query in order list page`, `add rate limiting to API gateway`, `replace hardcoded config with env vars`.
- `/ap:verify [task-id|all]`: verify done tasks and mark valid tasks as verified. Omitted target defaults to `all`. Examples: `task-003`, `all`.

Executor-only:

- `/ap:execute [task-id|next]`: claim and execute pending tasks; omitted target means `next`. Examples: `task-005`, `next`.
- `/ap:fix [task-id]`: fix a specific bug/review task; omitted target means the matching claimed (`in_progress`) or pending bug/review task. Examples: `task-002`, `task-007`.
- `/ap:test [task-id]`: run verification and record results; omitted target means the current `in_progress` task. Examples: `task-004`, `task-004 --verbose`.
- `/ap:done [task-id]`: mark a task done and fill implementation notes; omitted target means the current `in_progress` task. Examples: `task-004`.

Any role:

- `/ap:init planner=<agent> executor=<agent>`: initialize or update personal protocol files and project-local private config. Agent examples: `Claude Code`, `mastracode`.
- `/ap:tasks [status]`: list tasks. Omitted status lists all tasks. Status examples: `pending`, `in_progress`, `blocked`, `done`, `verified`, `cancelled`.
- `/ap:status`: summarize task counts and next recommended action.
- `/ap:help [command]`: show command help. Omitted command lists all commands with one-line summaries. Examples: `/ap:help review`, `/ap:help execute`.
- `/ap:whoami`: show configured Planner and Executor for this project.

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

To change which agent owns Planner or Executor work for the project, rerun `/ap:init planner=<agent> executor=<agent>`.

## Init Workflow

`/ap:init` is a configuration command. Any agent may run it because it does not implement product code or complete protocol tasks.

Syntax:

```text
/ap:init planner=<agent> executor=<agent>
```

Examples:

```text
/ap:init planner="Claude Code" executor=mastracode
```

If `planner` or `executor` is omitted, use the existing value from `.agent-memory/agent-protocol.md` when present. If no existing value exists, use `Planner: Claude Code` and `Executor: mastracode`, then report the defaults.

When running `/ap:init`, create or update these project-local private files:

```text
.agent-memory/agent-protocol.md
.agent-memory/tasks.json
CLAUDE.local.md
.mastracode/AGENTS.md
```

If the current directory is a git repo, add these patterns to `.git/info/exclude` if missing:

```text
.agent-memory/
CLAUDE.local.md
.mastracode/AGENTS.md
```

Do not edit team-shared project `AGENTS.md` or `CLAUDE.md`.

`/ap:init` should preserve existing `.agent-memory/tasks.json`. Create it as `{"tasks": []}` only when it is missing.

After init, summarize the configured Planner, Executor, created/updated files, and whether `.git/info/exclude` was updated.

Init file content requirements:

- `.agent-memory/agent-protocol.md`: keep this as a small project binding file. Include configured Planner/Executor, skill as protocol source, project-local task paths, command role gate, and project-local privacy rules. Do not duplicate the full workflow from this skill.
- `CLAUDE.local.md`, `.mastracode/AGENTS.md`: keep these short; they should point to `.agent-memory/agent-protocol.md`, mention default trigger behavior, list `/ap:` commands, and require command role gate checks before side effects.
- `.agent-memory/tasks.json`: preserve existing tasks. If missing, create exactly `{"tasks": []}`.

## Install Workflow

When the user asks to install agent-protocol commands/subcommands (e.g. "安装子命令", "install /ap: commands"), this is a configuration action. Any agent may handle it because it only copies files.

Workflow:

1. Detect the current agent from runtime context (Claude Code vs Mastra Code).
2. If the user specifies a platform (`claude`, `mastracode`, `all`), use that. Otherwise use the detected agent.
3. Locate this skill's install directory. The command files live at `<skill-root>/adapters/`.
4. Determine scope:
   - If the user mentions "user" or "global": install to user-level (`~/.claude/`, `~/.mastracode/`)
   - Default: install to project-level (`.claude/`, `.mastracode/`)
5. Copy files:
   - Claude Code: copy `<skill-root>/adapters/claude/commands/ap:*.md` to `<base>/commands/`
   - Mastra Code: copy `<skill-root>/adapters/mastracode/commands/ap/*.md` to `<base>/commands/ap/`
6. Report what was installed and where.

Do not create tasks for this action. Do not edit repository code. Do not run `/ap:init` unless the user also asked to initialize.

## Planner Workflow

1. Read `.agent-memory/agent-protocol.md` if present.
2. Inspect enough project context to create concrete tasks.
3. Load `.agent-memory/tasks.json`; create it as `{"tasks": []}` if missing.
4. Validate the task file against `references/schema/tasks.schema.json` when possible. If it is invalid, report the problem and do not append tasks until it is repaired.
5. Append new tasks only. Do not overwrite existing tasks.
6. Use `status: "pending"` and `created_by: "planner"`.
7. Fill `id`, `type`, `priority`, `title`, `context`, `spec`, `created_at`, and `updated_at`.
8. Do not fill `implementation_notes` unless preserving an existing value.

Task ids should continue the existing `task-NNN` sequence.

Allowed task types:

- `review`
- `feature`
- `design`
- `bug`

When reviewing Executor work, Planner may change completed tasks from `done` to `verified` after checking the implementation.

Verify flow:

1. Read the task `spec` and `implementation_notes`.
2. Inspect the code changes and confirm they match the task.
3. Run or inspect relevant tests when available.
4. If the task passes, mark it `verified`.
5. If it fails, set it back to `in_progress`, add concise feedback to `implementation_notes`, and update `updated_at`.

## Executor Workflow

1. Read `.agent-memory/agent-protocol.md` if present.
2. Load `.agent-memory/tasks.json`; if it is missing, create it as `{"tasks": []}`, report that no pending tasks exist, and stop unless the user also asked to initialize or create tasks.
3. Validate the task file against `references/schema/tasks.schema.json` when possible. If it is invalid, report the problem and do not claim tasks until it is repaired.
4. Pick pending tasks relevant to the user's request. If several match, sort by `priority` (`high`, then `medium`, then `low`) and then by `created_at` ascending.
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
  "priority": "medium",
  "title": "Short actionable title",
  "context": "Why this task exists.",
  "spec": "Concrete instructions for Executor.",
  "implementation_notes": "",
  "created_at": "YYYY-MM-DDTHH:MM:SSZ",
  "updated_at": "YYYY-MM-DDTHH:MM:SSZ"
}
```

Status values:

- `pending`: Planner created the task and it is ready for Executor.
- `in_progress`: Executor has claimed or is actively repairing the task.
- `blocked`: Executor cannot continue because it needs user input, dependency changes, credentials, or another task.
- `done`: Executor completed implementation and verification.
- `verified`: Planner accepted the done task.
- `cancelled`: Planner decided the task is no longer needed.

## Error Recovery

- If `.agent-memory/tasks.json` is missing, create `{"tasks": []}`.
- If `.agent-memory/tasks.json` is invalid JSON or violates the schema, stop before side effects and report the exact repair needed.
- If task ids have gaps, continue from the highest numeric suffix plus one.
- If `.agent-memory/agent-protocol.md` conflicts with the current agent identity, follow the project binding and tell the user which configured agent should perform the command.
- If a task is blocked, set `status: "blocked"` and explain the blocker in `implementation_notes`.
- If a blocked task becomes actionable, Executor may move it back to `in_progress`.

## User-Facing Behavior

When Planner creates tasks, summarize the task ids and titles.

When Executor completes tasks, summarize changed files, verification, and task statuses.

Do not require the user to say "use agent-protocol" or "act as Planner/Executor" when the intent clearly matches the default trigger rules.

Keep the protocol file as the shared state; do not rely on conversation memory for handoff-critical details.
