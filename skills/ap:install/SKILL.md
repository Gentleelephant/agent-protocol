---
name: ap:install
version: v3.37
description: "Bootstrap agent-protocol command adapter installation for Claude Code. Installs or refreshes project/user /ap: subcommands only."
argument-hint: "[--agent all|claude|cursor|mastracode|mimocode|reasonix] [--scope project|user]"
---

# /ap:install

Bootstrap `agent-protocol` command adapter installation for Claude Code.

This command exists as a thin entry skill so Claude Code can expose `/ap:install`
immediately after the skill is installed, before project-local command adapters
exist.

## Workflow

1. Read the installed `agent-protocol` skill.
2. Follow its Install Workflow.
3. Prefer `.agent-memory/scripts/install-commands.sh` when it exists so the project uses local protocol scripts instead of relying on user-scope script locations.
4. Otherwise resolve the repository root first, then run `<repo-root>/skills/agent-protocol/scripts/install-commands.sh`. Do not assume the current working directory is the repo root.
5. Treat this command as adapter-installation-only work.
6. Do not initialize `.agent-memory`.
7. Do not create protocol tasks or modify product code.

## Arguments

- No arguments: install all supported project-level command adapters.
- `--agent claude`: install only Claude Code commands.
- `--agent cursor`: install only Cursor commands.
- `--agent mastracode`: install only Mastra Code commands.
- `--agent mimocode`: install only MiMo Code commands.
- `--agent reasonix`: install only Reasonix commands.
- `--agent all`: install all supported command sets.
- `--scope project`: install into the current project.
- `--scope user`: install into user-level command directories.
