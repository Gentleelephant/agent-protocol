# Agent Protocol Workflows

This file contains command details that are intentionally kept out of `SKILL.md` to reduce default context cost.

## Commands

- `/ap:review [scope]`: review code and create review-derived tasks. Write a review artifact under `.agent-memory/artifacts/review/` and one execution prompt artifact per actionable task under `.agent-memory/artifacts/prompt/`.
- `/ap:plan [requirement]`: analyze requirements and create feature/design tasks. Write a plan artifact under `.agent-memory/artifacts/plan/` and one execution prompt artifact per actionable task under `.agent-memory/artifacts/prompt/`.
- `/ap:import [prompt|prompt-artifact|plan-artifact|plan-document]`: normalize external handoff input into task/artifact state only. It must not implement product code.
- `/ap:execute [task-id|next|--origin review|plan|import]`: claim and implement existing pending tasks only. Omitted target means `next`. It must not create tasks or accept direct prompt/plan input.
- `/ap:init`: initialize local protocol state only.
- `/ap:install [--agent all|claude|mastracode|reasonix] [--scope project|user]`: install or refresh command adapters only.
- `/ap:prune`: remove completed/cancelled history only.
- `/ap:reset`: reset local `.agent-memory` state only.

## Init Workflow

`/ap:init` is configuration-only. It must not implement product code or create tasks.

Prefer running:

```bash
bash <skill-root>/scripts/init.sh --project
```

Create missing project-local private files and skip existing files:

```text
.agent-memory/agent-protocol.md
.agent-memory/tasks.json
.agent-memory/artifacts/
CLAUDE.local.md
.mastracode/AGENTS.md
```

Do not install command adapters during init. Use `/ap:install` or `scripts/install-commands.sh` for adapter installation.

If the current directory is a git repo, add these patterns to `.git/info/exclude` when missing:

```text
.agent-memory/
CLAUDE.local.md
.mastracode/AGENTS.md
```

Preserve existing `.agent-memory/tasks.json`. Create it as exactly `{"tasks": []}` only when missing. After init, summarize created vs skipped files and whether `.git/info/exclude` changed.

## Install Workflow

Use this when the user asks only to install or refresh command adapters.

1. Detect selected platform: explicit `claude`, `mastracode`, or `reasonix`; default `all`.
2. Detect scope: `user` or `global` means user-level install; default project-level install.
3. Prefer `bash <skill-root>/scripts/install-commands.sh`, adding `--agent <name>` and `--scope user` when applicable.
4. Existing command files should be skipped, not overwritten.
5. Remove obsolete installed fix command files when found.
6. Report what was installed and where.

Do not create tasks for install-only requests.

## Task Creation Workflow

Use for `/ap:plan`, `/ap:review`, and `/ap:import`.

1. Read `.agent-memory/agent-protocol.md` only if present and relevant.
2. Inspect enough project context to create concrete tasks.
   - If `graphify-out/` exists and the scope is cross-file, architectural, or unclear, use Graphify `query`, `explain`, or `path` first to identify likely files, modules, and concepts.
   - Use `rg`, file reads, and commands only after Graphify narrows the search or when Graphify is missing, stale, ambiguous, or insufficient.
   - Treat Graphify output as an index, not proof. Verify task facts against source files, scripts, schemas, or protocol docs.
3. For complex `/ap:plan` or broad `/ap:review`, optional planning/reasoning skills may be used as advisors. Their output must be normalized back into this protocol's tasks and artifacts; they must not write `.agent-memory` state directly.
4. Load `.agent-memory/tasks.json`; create `{"tasks": []}` if missing.
5. Ensure `.agent-memory/artifacts/{review,plan,prompt,done}/` exists.
6. Validate `tasks.json` with `references/schema/tasks.schema.json` when possible. Stop before side effects if invalid.
7. Append new tasks only. Do not overwrite existing tasks.
8. New tasks must include `id`, `type`, `created_by: "agent"`, `status: "pending"`, `priority`, `title`, `context`, `spec`, `artifact_refs`, `created_at`, and `updated_at`.
9. Also fill `origin_command`, `origin_artifact_id`, `prompt_artifact_id`, `source_summary`, `acceptance`, and `depends_on` when known.
10. Do not fill `implementation_notes` for new tasks unless preserving an existing value.
11. Write the plan/review artifact and one execution prompt artifact per actionable task before reporting completion.

Task creation rules:

- `/ap:plan`: prefer existing architecture, naming, dependency patterns, and test style. Split unrelated deliverables into separate tasks. Prioritize dependency order, risk, and user-facing impact.
- `/ap:review`: create tasks only for concrete actionable findings. Use `type: "bug"` for new defect tasks; keep old `review` tasks readable for compatibility.
- `/ap:import`: accept only external execution prompt, prompt artifact, plan artifact, or plan document input. Save the imported source under `.agent-memory/artifacts/prompt/` or `.agent-memory/artifacts/plan/`, create missing pending tasks, generate missing execution prompt artifacts, set `origin_command: "import"`, report created task ids, and stop without implementing code.
- If an imported plan contains multiple executable items, create or list tasks only. Do not execute any task implicitly.
- The prompt artifact must contain enough source context for another agent to execute without reconstructing the entire conversation.
- If Graphify or an optional advisor contributed to the analysis, include only the necessary compressed summary in the plan/review artifact or prompt `Source Context`.
- Do not require the execution agent to rerun Graphify or the advisor unless validation genuinely depends on updated cross-file context.

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

Use for `/ap:execute`.

1. Read `.agent-memory/agent-protocol.md` only if present and relevant.
2. Load `.agent-memory/tasks.json`; if missing, create `{"tasks": []}`, report no pending tasks, and stop.
3. Ensure `.agent-memory/artifacts/{review,plan,prompt,done}/` exists.
4. Validate `tasks.json` when possible. Stop before side effects if invalid.
5. Select an existing execution target before claiming work:
   - Allowed selectors are `task-id`, `next`, and `--origin review|plan|import`.
   - Pick pending tasks relevant to the request. If several match, sort by `priority` then `created_at`.
   - If the user provides a direct execution prompt, direct plan, prompt artifact, or plan artifact, stop and tell the user to run `/ap:import` first.
6. Read `prompt_artifact_id` first when present; otherwise locate the execution prompt through `artifact_refs`.
7. Read `origin_artifact_id` only when additional evidence is needed.
8. Mark claimed tasks `in_progress`.
9. Implement according to `spec` and the prompt artifact.
10. Run appropriate verification.
11. Write a completion artifact under `.agent-memory/artifacts/done/` with implementation summary and validation results.
12. Append the completion artifact reference, update `last_tested_at` when validation ran, fill `implementation_notes`, mark completed tasks `done`, and update `updated_at`.

Do not modify task contract fields such as `spec`, `context`, `title`, or `created_by`.

Before implementation, every executed unit of work must already have a task id, an execution prompt artifact, and normal lifecycle state. `/ap:execute` must not create tasks or import external handoff content.

## Cleanup Workflow

`/ap:prune`:

1. Read `.agent-memory/tasks.json`.
2. Keep tasks with status `pending`, `in_progress`, or `blocked`.
3. Remove tasks with status `done` or `cancelled`.
4. Delete completion artifacts under `.agent-memory/artifacts/done/`.
5. Delete review, plan, and prompt artifacts referenced only by removed terminal tasks.
6. Preserve `.agent-memory/agent-protocol.md` and directory structure.

`/ap:reset`:

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
