---
name: ap:install
description: "Bootstrap agent-protocol command adapter installation for Claude Code. Installs or refreshes project/user /ap: subcommands only."
argument-hint: "[--agent all|claude|mastracode|reasonix] [--scope project|user]"
---

# /ap:install

Bootstrap `agent-protocol` command adapter installation for Claude Code.

This command exists as a thin entry skill so Claude Code can expose `/ap:install`
immediately after the skill is installed, before project-local command adapters
exist.

## Workflow

1. Read the installed `agent-protocol` skill.
2. Follow its Install Workflow.
3. Prefer `skills/agent-protocol/scripts/install-commands.sh`.
4. Treat this command as adapter-installation-only work.
5. Do not initialize `.agent-memory`.
6. Do not create protocol tasks or modify product code.

## Arguments

- No arguments: install all supported project-level command adapters.
- `--agent claude`: install only Claude Code commands.
- `--agent mastracode`: install only Mastra Code commands.
- `--agent reasonix`: install only Reasonix commands.
- `--agent all`: install all supported command sets.
- `--scope project`: install into the current project.
- `--scope user`: install into user-level command directories.
