# Agent Protocol Workflows

This file contains command details that are intentionally kept out of `SKILL.md` to reduce default context cost.

## Commands

- `/ap:review [scope]`: review code and create review-derived tasks. Write a review artifact under `.agent-memory/artifacts/review/` and one execution prompt artifact per actionable task under `.agent-memory/artifacts/prompt/`.
- `/ap:plan [requirement]`: analyze requirements and create feature/design tasks. Write a plan artifact under `.agent-memory/artifacts/plan/` and one execution prompt artifact per actionable task under `.agent-memory/artifacts/prompt/`.
- `/ap:execute [task-id|next|--origin review|plan]`: claim and implement pending tasks. Omitted target means `next`.
- `/ap:fix [task-id]`: compatibility alias for `/ap:execute`.
- `/ap:clean [history|all]`: clean `.agent-memory`. Omitted mode means `history`.
- `/ap:init [--agent all|claude|mastracode|reasonix]`: initialize local protocol files and command adapters.

## Init Workflow

`/ap:init` is configuration-only. It must not implement product code or create tasks.

Prefer running:

```bash
bash <skill-root>/scripts/init.sh --project
bash <skill-root>/scripts/init.sh --project --agent claude
bash <skill-root>/scripts/init.sh --project --agent mastracode
bash <skill-root>/scripts/init.sh --project --agent reasonix
```

Create missing project-local private files and skip existing files:

```text
.agent-memory/agent-protocol.md
.agent-memory/tasks.json
.agent-memory/artifacts/
CLAUDE.local.md
.mastracode/AGENTS.md
.reasonix/commands/ap/
```

Install selected command adapters without overwriting existing files:

```text
.claude/commands/
.mastracode/commands/ap/
.reasonix/commands/ap/
```

If the current directory is a git repo, add these patterns to `.git/info/exclude` when missing:

```text
.agent-memory/
.claude/
.mastracode/
.reasonix/
CLAUDE.local.md
```

Preserve existing `.agent-memory/tasks.json`. Create it as exactly `{"tasks": []}` only when missing. After init, summarize selected agent scope, created vs skipped files, and whether `.git/info/exclude` changed.

## Install Workflow

Use this when the user asks only to install or refresh command adapters.

1. Detect selected platform: explicit `claude`, `mastracode`, or `reasonix`; default `all`.
2. Detect scope: `user` or `global` means user-level install; default project-level install.
3. Prefer `bash <skill-root>/scripts/install-commands.sh`, adding `--agent <name>` and `--scope user` when applicable.
4. Existing command files should be skipped, not overwritten.
5. Report what was installed and where.

Do not create tasks for install-only requests.

## Task Creation Workflow

Use for `/ap:plan` and `/ap:review`.

1. Read `.agent-memory/agent-protocol.md` only if present and relevant.
2. Inspect enough project context to create concrete tasks.
3. Load `.agent-memory/tasks.json`; create `{"tasks": []}` if missing.
4. Ensure `.agent-memory/artifacts/{review,plan,prompt,done}/` exists.
5. Validate `tasks.json` with `references/schema/tasks.schema.json` when possible. Stop before side effects if invalid.
6. Append new tasks only. Do not overwrite existing tasks.
7. New tasks must include `id`, `type`, `created_by: "agent"`, `status: "pending"`, `priority`, `title`, `context`, `spec`, `artifact_refs`, `created_at`, and `updated_at`.
8. Also fill `origin_command`, `origin_artifact_id`, `prompt_artifact_id`, `source_summary`, `acceptance`, and `depends_on` when known.
9. Do not fill `implementation_notes` for new tasks unless preserving an existing value.
10. Write the plan/review artifact and one execution prompt artifact per actionable task before reporting completion.

Task creation rules:

- `/ap:plan`: prefer existing architecture, naming, dependency patterns, and test style. Split unrelated deliverables into separate tasks. Prioritize dependency order, risk, and user-facing impact.
- `/ap:review`: create tasks only for concrete actionable findings. Use `type: "bug"` for new defect tasks; keep old `review` tasks readable for compatibility.
- The prompt artifact must contain enough source context for another agent to execute without reconstructing the entire conversation.

## Execution Prompt Contract

Execution prompt artifacts belong under `.agent-memory/artifacts/prompt/`.

Required sections:

```text
Goal
Priority
Source Context
Task Contract Snapshot
Scope
Problem
Constraints
Suggested Fix
Validation
Deliverable
Command Hint
```

Required header fields:

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

Quality requirements:

- `task.spec` is the canonical task contract. If prompt and spec conflict, execution must follow `task.spec` and report the mismatch.
- `Problem` must state current behavior, expected behavior, and why it matters.
- `Scope` must identify allowed files/modules as specifically as possible.
- `Constraints` must list explicit non-goals and forbidden changes.
- `Suggested Fix` should recommend a concrete implementation path.
- `Validation` must include tests, commands, checks, or observable acceptance criteria.

## Implementation Workflow

Use for `/ap:execute` and `/ap:fix`.

1. Read `.agent-memory/agent-protocol.md` only if present and relevant.
2. Load `.agent-memory/tasks.json`; if missing, create `{"tasks": []}`, report no pending tasks, and stop unless the user also asked to initialize or create tasks.
3. Ensure `.agent-memory/artifacts/{review,plan,prompt,done}/` exists.
4. Validate `tasks.json` when possible. Stop before side effects if invalid.
5. Pick pending tasks relevant to the request. If several match, sort by `priority` then `created_at`.
6. Read `prompt_artifact_id` first when present; otherwise locate the execution prompt through `artifact_refs`.
7. Read `origin_artifact_id` only when additional evidence is needed.
8. Mark claimed tasks `in_progress`.
9. Implement according to `spec` and the prompt artifact.
10. Run appropriate verification.
11. Write a completion artifact under `.agent-memory/artifacts/done/` with implementation summary and validation results.
12. Append the completion artifact reference, update `last_tested_at` when validation ran, fill `implementation_notes`, mark completed tasks `done`, and update `updated_at`.

Do not modify task contract fields such as `spec`, `context`, `title`, or `created_by`.

## Cleanup Workflow

`/ap:clean history`:

1. Read `.agent-memory/tasks.json`.
2. Keep tasks with status `pending`, `in_progress`, or `blocked`.
3. Remove tasks with status `done` or `cancelled`.
4. Delete completion artifacts under `.agent-memory/artifacts/done/`.
5. Delete review, plan, and prompt artifacts referenced only by removed terminal tasks.
6. Preserve `.agent-memory/agent-protocol.md` and directory structure.

`/ap:clean all`:

1. Preserve `.agent-memory/agent-protocol.md`.
2. Reset `.agent-memory/tasks.json` to `{"tasks": []}`.
3. Empty `.agent-memory/artifacts/review/`, `plan/`, `prompt/`, and `done/`.
4. Preserve artifact directories.

## Error Recovery

- Missing `tasks.json`: create `{"tasks": []}`.
- Missing `artifacts/`: create required subdirectories.
- Invalid `tasks.json`: stop before side effects and report the exact repair needed.
- Task id gaps: continue from the highest numeric suffix plus one.
- Blocked task: set `status: "blocked"` and explain the blocker in `implementation_notes`.
- Missing artifact refs: warn in read-only output; do not fail the command solely because a referenced artifact is missing.

## User-Facing Output

- Task creation commands should summarize task ids and titles.
- Implementation commands should summarize changed files, validation, and task status updates.
- Handoff-critical details are not complete until saved under `.agent-memory/`.
