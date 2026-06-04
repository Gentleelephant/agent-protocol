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

<Describe the single desired outcome.>

## Priority

<Use exactly one of: high | medium | low.>

## Source Context

<Summarize the decisive review finding or planning rationale, including the key evidence, dependency, or risk notes another agent needs immediately.>

## Task Contract Snapshot

<Restate the canonical task contract fields that execution depends on: title, spec, acceptance, and dependency notes. If the task has explicit `depends_on`, list them here.>

## Scope

<List the exact files, modules, endpoints, or components that may be changed. Be specific.>

## Problem

<Describe the issue or requirement concretely, including current behavior, expected behavior, evidence, and risk.>

## Constraints

<List hard boundaries, non-goals, forbidden changes, compatibility constraints, and assumptions. Explicitly say what must not be changed.>

## Suggested Fix

<Describe the recommended implementation approach in concrete steps. Put the preferred approach first. Avoid vague advice.>

## Validation

<List the exact tests, checks, commands, or acceptance criteria the implementing agent should run.>

## Deliverable

<State what the implementing agent should update and what notes or artifacts should be produced.>

## Command Hint

<Repeat the recommended next command, usually `/ap:execute <task-id>`.>
