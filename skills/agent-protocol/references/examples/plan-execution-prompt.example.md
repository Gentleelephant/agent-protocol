artifact_id: artifact-prompt-101
artifact_type: execution_prompt
command: /ap:plan
related_task_ids: [task-101]
scope: [internal/auth/service.go, internal/auth/service_test.go, internal/http/login_handler.go]
created_at: 2026-06-04T10:00:00Z
created_by_role: agent
agent: Codex
command_hint: /ap:execute task-101
target_role: implementing-agent
summary: Add JWT-based login flow using the existing auth and HTTP layers.

## Goal

Implement a JWT login flow that validates username and password, issues a signed token, and returns it from the existing login API.

## Priority

high

## Scope

- Allowed:
  - `internal/auth/service.go`
  - `internal/auth/service_test.go`
  - `internal/http/login_handler.go`
- Allowed if required by existing patterns:
  - request/response structs already used by the login handler
- Not allowed:
  - database schema changes
  - unrelated refactors in other HTTP handlers
  - replacing the current auth package structure

## Problem

The project currently exposes login-related handler code but does not complete the token issuance flow. Users can submit credentials, but the backend does not consistently validate them and return a JWT through the existing API path. This blocks downstream authenticated requests and leaves the login path incomplete.

## Constraints

- Reuse the current auth service and handler structure.
- Keep the public login endpoint shape compatible unless the existing code already requires a minimal correction.
- Do not introduce a new auth framework or move files across packages.
- Do not rename unrelated symbols.

## Suggested Fix

1. Inspect the current login handler and auth service responsibilities.
2. Add or complete credential validation inside the auth service using the existing user lookup flow.
3. Generate the JWT in the auth service or the existing token helper layer, following current project conventions.
4. Return the token from the login handler using the project’s existing response style.
5. Add focused tests for successful login, invalid password, and missing user cases.

## Validation

- Run the auth service tests.
- Run the login handler tests.
- Confirm the success path returns a token and failure paths return the expected error response.
- If there is an existing API test command, run the smallest command that covers the login path.

## Deliverable

- Updated implementation in the allowed files
- Tests covering success and error paths
- `implementation_notes` summarizing what changed and how it was verified

## Command Hint

/ap:execute task-101
