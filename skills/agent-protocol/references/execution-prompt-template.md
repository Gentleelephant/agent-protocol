artifact_id: artifact-prompt-<id>
artifact_type: execution_prompt
command: /ap:review|/ap:plan
related_task_ids: [task-<id>]
origin_artifact_id: artifact-review-<id>|artifact-plan-<id>
scope: <files-or-modules>
created_at: <ISO-8601>
created_by_role: agent
agent: <agent-name>
command_hint: /ap:execute <task-id>
target_role: implementing-agent
summary: <one-line summary>

## Goal

<Describe exactly one desired outcome. If helpful, frame it as the implementing agent's objective, not a broad project roadmap.>

## Priority

<Use exactly one of: high | medium | low.>

## Source Context

<Summarize the decisive review finding or planning rationale. Include the key evidence anchors another agent needs immediately, such as files, symbols, tests, errors, dependencies, or observed behavior. If any part is inference rather than a confirmed fact, say so explicitly.>

## Task Contract Snapshot

<Restate the canonical task contract fields that execution depends on: title, spec, acceptance, and dependency notes. If the task has explicit `depends_on`, list them here. If prompt wording and `task.spec` ever differ, execution must follow `task.spec`.>

## Scope

<List the exact files, modules, endpoints, or components that may be changed. Be specific. Prefer an explicit allowed / conditionally allowed / not allowed split when useful.>

## Problem

<Describe the issue or requirement concretely, including current behavior, expected behavior, evidence, and why it matters. Avoid vague statements like "improve this logic".>

## Constraints

<List hard boundaries, must-keep compatibility rules, assumptions, non-goals, and forbidden changes. Explicitly say what must not be changed.>

## Suggested Fix

<Describe the recommended implementation approach in concrete steps. Put the preferred approach first. If there are alternatives, say when they should be used instead. Avoid vague advice.>

## Validation

<List the exact tests, checks, commands, or acceptance criteria the implementing agent should run. Include the expected pass signal. If a command may not exist in every checkout, state the smallest acceptable fallback validation.>

## Deliverable

<State what the implementing agent should update and what notes or artifacts should be produced. Include how to report changed files, validation results, and any remaining blocker or risk notes if relevant.>

## Command Hint

<Repeat the recommended next command, usually `/ap:execute <task-id>`.>
