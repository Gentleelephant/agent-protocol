---
name: agent-protocol
version: v3.19
description: "Use when the user wants to generate structured, implementable prompts from requirements or code review — producing detailed task prompts that an AI agent can execute. This skill covers the full protocol loop: analyze requirements and produce plan prompts, review code and produce fix prompts, then execute those prompts. Always trigger when users ask for task breakdown with execution prompts, code audit with fix directions, or to execute a previously generated prompt. Trigger on Chinese phrases like 审查代码, 整理开发计划, 拆解任务, 生成prompt, 修复prompt, 执行开发prompt, 按优先级执行任务, 分析需求生成可执行说明. Skip ONLY when the user explicitly says 直接改/不用创建任务/no protocol, or when the request is pure code explanation, architecture diagrams, ad-hoc debugging, or non-engineering tasks like English resume review."
---

# Agent Protocol

Use this skill to reduce friction when working with project-level personal `agent-protocol` configuration.

## Source Of Truth

The installed `agent-protocol` skill directory is the protocol source of truth. `SKILL.md` is the main workflow. Supporting details live next to it:

- `references/protocol.md`
- `references/roles/planner.md`
- `references/roles/executor.md`
- `references/execution-prompt-template.md`
- `references/examples/plan-execution-prompt.example.md`
- `references/examples/review-fix-prompt.example.md`
- `references/schema/tasks.schema.json`
- `scripts/init.sh`
- `scripts/install-commands.sh`

For Claude Code bootstrap, this repository may also provide a separate top-level
skill at `skills/ap:init/SKILL.md`. That bootstrap skill is intentionally thin:
it exists only so Claude can expose `/ap:init` immediately after installation,
then delegate to this skill's Init Workflow.

Read supporting files only when needed:

- Read `references/protocol.md` when lifecycle, task ownership, artifact storage, or recovery rules are unclear.
- Read `references/roles/planner.md` before detailed review or planning work.
- Read `references/roles/executor.md` before implementing pending tasks or recovering in-progress work.
- Read `references/execution-prompt-template.md` when generating or consuming implementation prompt artifacts.
- Read `references/examples/plan-execution-prompt.example.md` or `references/examples/review-fix-prompt.example.md` when you need a concrete example of a high-quality prompt artifact.
- Read `references/schema/tasks.schema.json` before validating or repairing `.agent-memory/tasks.json`.

Use project-local private files for per-project behavior and task state:

- `.agent-memory/agent-protocol.md`
- `.agent-memory/tasks.json`
- `.agent-memory/artifacts/`

Do not require team-shared project `AGENTS.md` or `CLAUDE.md`. This protocol is intended to work from project-level personal entries that are ignored by Git:

- `CLAUDE.local.md` for Claude Code
- `.mastracode/AGENTS.md` for Mastra Code
- `.reasonix/commands/ap/` for Reasonix project commands

If the project has no task state and the user wants protocol handoff, run `/ap:init` or tell the user to run:

```bash
curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/main/skills/agent-protocol/scripts/init.sh | bash -s -- --project
```

## Core Workflow

Treat this protocol as three primary commands plus compatibility aliases:

- `/ap:plan`: read the user requirement plus project code, then create development tasks and execution prompts
- `/ap:review`: review code, then create review findings and fix prompts
- `/ap:execute`: implement a task produced by `/ap:plan` or `/ap:review`
- `/ap:fix`: compatibility alias for `/ap:execute` when the task originated from review
- `/ap:clean`: clean `.agent-memory` historical data

Keep the public workflow minimal. Validation and completion recording should happen inside `/ap:execute` rather than through extra public commands.

Agents that do not support subcommands, such as Codex, must still support this workflow. In those environments, interpret natural-language requests as command-equivalent intents rather than requiring literal `/ap:` syntax.

## Trigger Rules

Default trigger rules:

- User says install commands, install subcommands, install /ap: commands, install agent-protocol commands, 安装子命令: copy command files from this skill's adapters/ directory to the current agent's command path. See Install Workflow below.
- User says review, audit, inspect, check code, find bugs, security issue, performance issue, design issue: run the `/ap:review` workflow.
- User says plan, design, break down, analyze requirement, architecture decision: run the `/ap:plan` workflow.
- User says process pending task, implement task, fix task, continue work: run the `/ap:execute` workflow.
- User says clean history, clean tasks, clean agent memory, 清理历史数据, 清理 .agent-memory: run the `/ap:clean` workflow.
- User explicitly says directly implement, directly edit code, do not create tasks, or no protocol: follow normal coding behavior for that request.

If the user asks to install agent-protocol commands or subcommands, copy the command files and report what was installed. Do not create tasks. See Install Workflow below.

If the user asks for planning, review, task creation, or handoff, do not edit production code. Append tasks and persist artifacts to disk.

If the user asks to implement pending tasks or continue work, update task state and implement against the task contract.

If the user asks to directly implement a feature and does not mention protocol/task handoff, follow normal coding behavior unless project-level personal instructions explicitly require protocol workflow.

Natural-language equivalence rules:

- "根据这个需求结合项目代码整理开发计划" means `/ap:plan`
- "review 这段代码并给出修复 prompt" means `/ap:review`
- "执行刚才 plan 产出的 prompt" means `/ap:execute`
- "执行刚才 review 产出的修复 prompt" means `/ap:execute`
- "清理 .agent-memory 里的历史数据" means `/ap:clean`
- The same artifact, task, and prompt rules apply whether the trigger was `/ap:` syntax or natural language

## Commands

All protocol commands use the `/ap:` namespace to avoid collisions with agent-native commands.

If the current agent does not support subcommands, treat the command descriptions below as semantic operations that can be invoked through natural language.

All parameters are optional. When a parameter is omitted, the command uses the default behavior described below. When a parameter is provided, it must follow the syntax shown; unsupported values should be rejected with a clear hint.

- `/ap:review [scope]`: review code and create review tasks; do not edit production code. Also write a review artifact under `.agent-memory/artifacts/review/` and a fix prompt artifact under `.agent-memory/artifacts/prompt/`. Omitted scope means the entire project or current uncommitted changes.
- `/ap:plan [requirement]`: analyze requirements or architecture and create feature/design tasks. Also write a plan artifact under `.agent-memory/artifacts/plan/` and an execution prompt artifact under `.agent-memory/artifacts/prompt/`. Omitted requirement means extract from recent conversation context.
- `/ap:execute [task-id|next|--origin review|plan]`: claim and execute pending tasks; omitted target means `next`. `--origin` narrows selection when the user wants only review-derived or plan-derived work.
- `/ap:fix [task-id]`: compatibility alias for `/ap:execute`. Preserve it for existing habits, but prefer `/ap:execute`.
- `/ap:clean [history|all]`: clean `.agent-memory` historical data. Omitted mode means `history`. `all` resets `.agent-memory` to an initialized empty state.
- `/ap:init`: initialize or update personal protocol files, project-local private config, and project-level `/ap:` subcommands.

By default, only `/ap:` command flows persist artifacts. Equivalent natural-language requests may create or update tasks, but should not silently create artifact files unless they are handled through the protocol path.

Exception: when the current agent does not support subcommands, equivalent natural-language requests must be treated as the protocol path and should persist the same tasks and artifacts that `/ap:` would have produced.

When `/ap:plan` or `/ap:review` runs through the protocol path, the generated plan/review records and execution prompts must be saved under `.agent-memory/artifacts/`; do not keep them only in conversation output.

## Command Execution Rule

Before executing any `/ap:` command with side effects, except `/ap:init`:

1. Read `.agent-memory/agent-protocol.md` when present.
2. Use `tasks.json` as the task state source of truth.
3. Use `.agent-memory/artifacts/` as the detailed evidence and prompt store.
4. Do not block execution based on agent identity.
5. Do not require role-specific configuration to run the workflow.

## Init Workflow

`/ap:init` is a configuration command. Any agent may run it because it does not implement product code or complete protocol tasks.

Syntax:

```text
/ap:init
/ap:init --agent claude
/ap:init --agent mastracode
/ap:init --agent reasonix
```

Claude bootstrap note:

- `skills/ap:init/SKILL.md` may expose `/ap:init` before any other `/ap:` command exists
- that bootstrap entry should only dispatch into this Init Workflow
- `/ap:init` remains the one-step path that initializes local protocol files and installs project-level command adapters

Arguments:

- `--project`: required by the shell script entrypoint
- `--agent all|claude|mastracode|reasonix`: optional, default `all`

When running `/ap:init`, create these project-local private files when missing and skip them when already present:

```text
.agent-memory/agent-protocol.md
.agent-memory/tasks.json
.agent-memory/artifacts/
CLAUDE.local.md
.mastracode/AGENTS.md
.reasonix/commands/ap/
```

Also install project-level command files to the selected agent target. Existing command files should be skipped instead of overwritten:

```text
.claude/commands/
.mastracode/commands/ap/
.reasonix/commands/ap/
```

Selected agent behavior:

- `all`: create local entry files and install Claude, Mastra Code, and Reasonix command sets
- `claude`: create `CLAUDE.local.md` and install `.claude/commands/`
- `mastracode`: create `.mastracode/AGENTS.md` and install `.mastracode/commands/ap/`
- `reasonix`: install `.reasonix/commands/ap/`

If the current directory is a git repo, ensure `.git/info/exclude` exists and add these patterns if missing:

```text
.agent-memory/
.claude/
.mastracode/
.reasonix/
CLAUDE.local.md
```

Do not edit team-shared project `AGENTS.md` or `CLAUDE.md`.

`/ap:init` should preserve existing `.agent-memory/tasks.json`. Create it as `{"tasks": []}` only when it is missing. Existing directories, local instruction files, and command files should be treated as already initialized and skipped.

After init, summarize the selected agent scope, the created vs skipped files, and whether `.git/info/exclude` was updated.

Init file content requirements:

- `.agent-memory/agent-protocol.md`: keep this as a small project binding file. Include skill as protocol source, project-local task paths, execution rules, and project-local privacy rules.
- `.agent-memory/artifacts/`: create review/plan/prompt/done subdirectories for persistent command artifacts.
- `CLAUDE.local.md`, `.mastracode/AGENTS.md`: keep these short; they should point to `.agent-memory/agent-protocol.md`, mention default trigger behavior, and list `/ap:` commands.
- `.claude/commands/`, `.mastracode/commands/ap/`, `.reasonix/commands/ap/`: install the packaged `/ap:` command adapters for the selected agent target. Reasonix uses namespace directories, so `ap/plan.md` becomes `/ap:plan`.
- `.agent-memory/tasks.json`: preserve existing tasks. If missing, create exactly `{"tasks": []}`.

## Install Workflow

When the user asks to install agent-protocol commands or subcommands, this is a configuration action. Any agent may handle it because it only copies files.

Workflow:

1. Detect the current agent from runtime context.
2. If the user specifies a platform (`claude`, `mastracode`, `reasonix`), install only that platform. Default: install all supported platforms (`all`).
3. Prefer running `<skill-root>/scripts/install-commands.sh` instead of manually copying files.
4. Determine scope:
   - If the user mentions `user` or `global`: install to user-level (`~/.claude/`, `~/.mastracode/`, `~/.config/reasonix/`)
   - Default: install to project-level (`.claude/`, `.mastracode/`, `.reasonix/`)
5. Run:
   - `bash <skill-root>/scripts/install-commands.sh`
   - `bash <skill-root>/scripts/install-commands.sh --agent claude`
   - `bash <skill-root>/scripts/install-commands.sh --agent mastracode`
   - `bash <skill-root>/scripts/install-commands.sh --agent reasonix`
   - add `--scope user` when the user asked for user-level install
6. Existing command files should be skipped instead of overwritten.
7. Report what was installed and where.

Do not create tasks for this action. Do not edit repository code. Use `/ap:init` when the user wants one-step initialization plus project-level command installation; use `install-commands.sh` only for standalone command refresh or alternate scope.

## Execution Prompt Contract

When `/ap:plan` or `/ap:review` finds an actionable task, generate an agent-ready execution prompt artifact under:

```text
.agent-memory/artifacts/prompt/
```

This prompt is meant to be passed directly to another agent or reused by the same agent. It must be strict, bounded, prioritized, and implementation-oriented.

Rules:

- Generate one prompt artifact per actionable task created by `/ap:review` or `/ap:plan`.
- Use artifact type `execution_prompt`.
- Add the prompt artifact identifier to the task `artifact_refs`.
- Keep `task.spec` as the canonical short task contract; the prompt artifact is the expanded execution brief.
- If the prompt and `task.spec` conflict, the implementing agent should treat `task.spec` as source of truth and report the mismatch.
- Prefer one prompt per independent problem or feature slice. Do not bundle unrelated work into one prompt.
- Copy the decisive review or plan context into the prompt itself instead of requiring another agent to re-open every source artifact.

Required prompt sections:

- `Goal`
- `Priority`
- `Source Context`
- `Task Contract Snapshot`
- `Scope`
- `Problem`
- `Constraints`
- `Suggested Fix`
- `Validation`
- `Deliverable`
- `Command Hint`

Prompt quality requirements:

- `Problem` must state current behavior, expected behavior, and why it matters.
- `Source Context` must summarize the relevant review finding or planning rationale, with the key evidence or dependency notes needed to act.
- `Task Contract Snapshot` must restate the canonical task contract fields that execution depends on.
- `Scope` must identify the allowed change surface as specifically as possible.
- `Constraints` must list explicit non-goals and forbidden changes.
- `Suggested Fix` must recommend a preferred implementation path, not generic advice.
- `Validation` must include concrete tests, checks, commands, or observable acceptance criteria.
- The prompt must be strong enough that another agent can execute it without re-inferring the task.
- The prompt artifact must be written to disk before the planning/review command is considered complete.

Prompt artifact header should include:

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

## Task Creation Workflow

1. Read `.agent-memory/agent-protocol.md` if present.
2. Inspect enough project context to create concrete tasks.
3. Load `.agent-memory/tasks.json`; create it as `{"tasks": []}` if missing.
4. Ensure `.agent-memory/artifacts/` and the relevant subdirectory for the command exist, including `.agent-memory/artifacts/prompt/` when creating actionable tasks.
5. Validate the task file against `references/schema/tasks.schema.json` when possible. If it is invalid, report the problem and do not append tasks until it is repaired.
6. Append new tasks only. Do not overwrite existing tasks.
7. Use `status: "pending"` and `created_by: "agent"` for new tasks.
8. Fill `id`, `type`, `priority`, `title`, `context`, `spec`, `created_at`, and `updated_at`.
9. For `/ap:review` and `/ap:plan`, also write a Markdown artifact under `.agent-memory/artifacts/` and store its identifier in `artifact_refs`.
10. For each actionable task created by `/ap:review` or `/ap:plan`, also write an `execution_prompt` artifact under `.agent-memory/artifacts/prompt/` and store its identifier in `artifact_refs`.
11. For new tasks, also fill `origin_command`, `origin_artifact_id`, `prompt_artifact_id`, `source_summary`, `acceptance`, and `depends_on` whenever that information is known.
12. Do not fill `implementation_notes` unless preserving an existing value.

New tasks must always include `priority` and `artifact_refs`; task consumers rely on them for ordering and prompt lookup.

Prompt generation rules for `/ap:plan`:

- Read the relevant code before decomposing work.
- Prefer the existing architecture, naming, dependency patterns, and test style.
- Split large requirements into several prompts when one prompt would cover multiple independent deliverables.
- Assign `priority` based on dependency order, risk, and user-facing impact.
- Each prompt should have exactly one primary outcome.

Prompt generation rules for `/ap:review`:

- Only generate a fix prompt for issues that are concrete and actionable.
- Do not merge unrelated findings into one prompt.
- State the observed issue first, then the repair direction.
- Include severity or priority in the task and prompt.
- If evidence is incomplete, say what must be confirmed before implementation.
- New tasks created from review should normally use `type: "bug"`. The legacy `review` task type may still exist in old task files and should remain readable.

## Implementation Workflow

1. Read `.agent-memory/agent-protocol.md` if present.
2. Load `.agent-memory/tasks.json`; if it is missing, create it as `{"tasks": []}`, report that no pending tasks exist, and stop unless the user also asked to initialize or create tasks.
3. Ensure `.agent-memory/artifacts/` and the relevant subdirectory for the command exist.
4. Validate the task file against `references/schema/tasks.schema.json` when possible. If it is invalid, report the problem and do not claim tasks until it is repaired.
5. Pick pending tasks relevant to the user's request. If several match, sort by `priority` and then by `created_at` ascending.
6. If the task has `prompt_artifact_id`, read it first. Otherwise fall back to locating the `execution_prompt` through `artifact_refs`. If the prompt conflicts with `task.spec`, use `task.spec`.
7. If the task has `origin_artifact_id`, read it when additional review or planning evidence is needed.
8. Change claimed tasks to `in_progress`.
9. Implement or fix according to `spec` and any related prompt artifact.
10. Run appropriate verification.
11. Write a completion artifact under `.agent-memory/artifacts/done/` that includes the implementation summary and validation results.
12. Append the completion artifact reference, update `last_tested_at` when validation ran, and fill `implementation_notes`.
13. Change completed tasks to `done` and update `updated_at`.

Do not modify task contract fields such as `spec`, `context`, `title`, or `created_by`.

Verification is part of `/ap:execute`. Do not rely on a separate public verification command.

## Cleanup Workflow

`/ap:clean` is a maintenance command for `.agent-memory/`.

Modes:

- `history` (default): remove historical data while preserving active work
- `all`: reset `.agent-memory` to an initialized empty state

`history` mode rules:

1. Read `.agent-memory/tasks.json`.
2. Keep tasks with status `pending`, `in_progress`, or `blocked`.
3. Remove tasks with status `done` or `cancelled`.
4. Delete completion artifacts under `.agent-memory/artifacts/done/`.
5. Delete review, plan, and prompt artifacts that are referenced only by removed terminal tasks.
6. Preserve `.agent-memory/agent-protocol.md` and directory structure.

`all` mode rules:

1. Preserve `.agent-memory/agent-protocol.md`.
2. Reset `.agent-memory/tasks.json` to `{"tasks": []}`.
3. Empty `.agent-memory/artifacts/review/`, `plan/`, `prompt/`, and `done/`.
4. Preserve the artifact directory structure so the next protocol command can reuse it immediately.

## Task JSON Shape

Use this shape for new tasks:

```json
{
  "id": "task-001",
  "type": "review",
  "created_by": "agent",
  "status": "pending",
  "priority": "medium",
  "title": "Short actionable title",
  "context": "Why this task exists.",
  "spec": "Concrete implementation contract.",
  "origin_command": "plan",
  "origin_artifact_id": "artifact-plan-001",
  "prompt_artifact_id": "artifact-prompt-001",
  "source_summary": "Why this task was created.",
  "acceptance": "Observable acceptance criteria.",
  "depends_on": [],
  "implementation_notes": "",
  "artifact_refs": ["artifact-plan-001", "artifact-prompt-001"],
  "last_reviewed_at": "YYYY-MM-DDTHH:MM:SSZ",
  "last_tested_at": "YYYY-MM-DDTHH:MM:SSZ",
  "created_at": "YYYY-MM-DDTHH:MM:SSZ",
  "updated_at": "YYYY-MM-DDTHH:MM:SSZ"
}
```

Allowed task types:

- `review`
- `feature`
- `design`
- `bug`

Use `bug`, `feature`, or `design` for new tasks. Keep `review` readable for backward compatibility only.

Artifact types are separate from task types:

- `review_result`
- `plan_record`
- `execution_prompt`
- `completion_record`

Status values:

- `pending`: a task is ready to implement.
- `in_progress`: an agent has claimed or is actively repairing the task.
- `blocked`: the implementing agent cannot continue because it needs user input, dependency changes, credentials, or another task.
- `done`: implementation and verification are complete.
- `cancelled`: the task is no longer needed.

Read state from `tasks.json` first. Read details from referenced artifacts.

## Error Recovery

- If `.agent-memory/tasks.json` is missing, create `{"tasks": []}`.
- If `.agent-memory/artifacts/` is missing, create the required subdirectories before writing artifacts.
- If `.agent-memory/tasks.json` is invalid JSON or violates the schema, stop before side effects and report the exact repair needed.
- If task ids have gaps, continue from the highest numeric suffix plus one.
- If a task is blocked, set `status: "blocked"` and explain the blocker in `implementation_notes`.
- If a blocked task becomes actionable, the implementing agent may move it back to `in_progress`.
- If an `artifact_refs` entry points to a missing file, warn in read-only output but do not fail the command.
- If `origin_artifact_id` or `prompt_artifact_id` is missing, fall back to `artifact_refs` and report the weaker linkage.

## User-Facing Behavior

When task-creation commands create tasks, summarize the task ids and titles.

When implementation commands complete tasks, summarize changed files, verification, and task statuses.

Do not require the user to say "use agent-protocol" or mention any role when the intent clearly matches the default trigger rules.

Keep `tasks.json` as the task state source and `.agent-memory/artifacts/` as the detailed evidence store; do not rely on conversation memory for handoff-critical details. Development plans, review results, and execution prompts are not complete until they are saved there.
