---
name: agent-protocol
version: v3.52
description: "Use only for explicit agent-protocol workflows. This is the single top-level command entrypoint and supports `/agent-protocol init` and `/agent-protocol install [--agent ...] [--scope ...]`. Installed /ap subcommands provide the actual command behavior."
---

# Agent Protocol

Use this skill only for explicit `agent-protocol` workflows. This is the only top-level command entrypoint.

## Trigger Contract

Trigger this skill for:

- Explicit `agent-protocol` intent.
- `/agent-protocol init` for local protocol state initialization.
- `/agent-protocol install [--agent ...] [--scope ...]` for command adapter installation or refresh.
- Requests to create persistent tasks, execution prompts, handoff prompts, or `.agent-memory` artifacts.

Do not trigger for:

- Ordinary code review, bug fixing, refactoring, architecture discussion, or code explanation.
- Requests that say `直接改`, `直接实现`, `不用创建任务`, `不用 protocol`, or `no protocol`.

## Installed Command Sources

Installed subcommand semantics come from the adapter command templates under `adapters/`. Treat those files as the command-level source of truth after installation.

## Bootstrap Actions

- `/agent-protocol init`: run `scripts/init.sh --project --project-root <absolute-project-path>` to initialize project-local protocol state only. Do not create tasks or install command adapters.
- `/agent-protocol install [--agent ...] [--scope ...]`: run the current skill's `scripts/install-commands.sh --project-root <absolute-project-path>`, using `.agent-memory/source.json` only as a project-local pointer back to this skill root when needed. Do not initialize `.agent-memory`, create tasks, or modify product code.

## Shared Protocol

- `references/protocol.md`: shared task/artifact model, lifecycle, recovery rules, and execution prompt contract.
- `references/schema/tasks.schema.json`: validate or repair `.agent-memory/tasks.json` when needed.

## Persistent State

Project-local protocol state lives in:

```text
.agent-memory/agent-protocol.md
.agent-memory/tasks.json
.agent-memory/artifacts/
```

Keep project-local protocol files private and do not require team-shared `AGENTS.md` or `CLAUDE.md`.
