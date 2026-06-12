---
name: ap:init
version: v3.30
description: "Bootstrap agent-protocol project initialization for Claude Code. Creates local protocol state only."
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

- No arguments: initialize local protocol state.
- Command adapter installation is a separate `/ap:install` responsibility.
