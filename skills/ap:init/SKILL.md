---
name: ap:init
description: "Bootstrap agent-protocol project initialization for Claude Code. Creates local protocol state and installs project-level /ap: subcommands."
argument-hint: "[--agent claude|mastracode|all]"
---

# /ap:init

Bootstrap `agent-protocol` initialization for Claude Code.

This command exists as a thin entry skill so Claude Code can expose `/ap:init`
immediately after the skill is installed.

## Workflow

1. Read the installed `agent-protocol` skill.
2. Follow its `Init Workflow`.
3. Treat this command as configuration-only work.
4. Do not create protocol tasks for this action.

## Arguments

- No arguments: same as `/ap:init --agent all`
- `--agent claude`: initialize protocol files and install only Claude project commands
- `--agent mastracode`: initialize protocol files and install only Mastra Code project commands
- `--agent all`: initialize protocol files and install both command sets
