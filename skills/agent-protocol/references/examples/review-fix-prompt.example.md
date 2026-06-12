artifact_id: artifact-prompt-20260604T100500Z-task-201
artifact_type: execution_prompt
command: /ap:review
related_task_ids: [task-201]
origin_artifact_id: artifact-review-20260604T100300Z-task-201
scope: [pkg/cache/store.go, pkg/cache/store_test.go]
created_at: 2026-06-04T10:05:00Z
created_by_role: agent
agent: Codex
command_hint: /ap:execute task-201
target_role: implementing-agent
summary: Fix missing lock coverage around cache map writes that can panic under concurrent access.

## Goal

Fix the concurrent write bug in the cache store so writes and deletes are safe under parallel access.

## Priority

high

## Source Context

Confirmed facts:
- The review found unsynchronized mutation paths in `pkg/cache/store.go`.
- Shared map write and delete paths do not consistently hold the write lock for the full mutation window.

Risk note:
- This is high risk because `concurrent map writes` panics and race detector failures can crash or invalidate the process under parallel access.

## Task Contract Snapshot

- Title: Fix concurrent map writes in cache store
- Spec: Make cache writes and deletes safe under parallel access without changing the public API or eviction semantics.
- Acceptance: Targeted tests pass, and race or concurrent write failures no longer reproduce in the scoped package.
- Dependencies: none

## Scope

- Allowed:
  - `pkg/cache/store.go`
  - `pkg/cache/store_test.go`
- Not allowed:
  - redesigning the cache API
  - changing unrelated cache eviction behavior
  - broad performance refactors

## Problem

`pkg/cache/store.go` updates the shared map from multiple methods without consistently holding the write lock. Under concurrent traffic this can trigger `concurrent map writes` panics or race detector failures. The issue is concrete, reproducible under parallel tests, and high risk because it can crash the process.

## Constraints

- Keep the current public API unchanged.
- Apply the minimal safe locking fix.
- Do not change TTL or eviction semantics unless required to preserve correctness.
- Keep the fix local to the cache store implementation and targeted tests.

## Suggested Fix

1. Inspect all map mutation paths in `store.go`.
2. Ensure every write/delete path holds the appropriate mutex for the full mutation window.
3. Check whether read paths require matching protection for consistency with the existing locking model.
4. Add or tighten concurrent tests that would fail before the fix.

## Validation

- Run the targeted cache tests, for example `go test ./pkg/cache -run TestStore`.
- Run `go test -race ./pkg/cache` if the environment supports the race detector.
- Confirm the targeted concurrent scenario no longer produces a race report or `concurrent map writes` failure.

## Deliverable

- Minimal locking fix in `store.go`
- Concurrency-focused regression tests in `store_test.go`
- `implementation_notes` describing the original race, which paths were protected, and how the fix was validated

## Command Hint

/ap:execute task-201
