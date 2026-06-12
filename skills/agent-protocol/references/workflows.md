# Agent Protocol Workflows

This file is now a compact index. Shared protocol rules stay in `protocol.md`; installed subcommand behavior lives in `adapters/*/commands/*`, and bootstrap-only actions `init` and `install` live directly in `../SKILL.md`.

## Installed Subcommands

- `/ap:run`: see the installed adapter command template for the current agent
- `/ap:plan`: see the installed adapter command template for the current agent
- `/ap:review`: see the installed adapter command template for the current agent
- `/ap:import`: see the installed adapter command template for the current agent
- `/ap:execute`: see the installed adapter command template for the current agent
- `/ap:prune`: see the installed adapter command template for the current agent
- `/ap:reset`: see the installed adapter command template for the current agent

## Shared References

- Shared state model, lifecycle, and recovery: `protocol.md`
- Planning and review quality guardrails: `roles/planner.md`
- Execution guardrails: `roles/executor.md`
- Execution prompt contract: `execution-prompt-template.md`
- Task schema: `schema/tasks.schema.json`
- Concrete prompt examples: `examples/*.example.md`

## User-Facing Output

- Task creation commands should summarize task ids and titles.
- Implementation commands should summarize changed files, validation, and task status updates.
- Handoff-critical details are not complete until saved under `.agent-memory/`.
