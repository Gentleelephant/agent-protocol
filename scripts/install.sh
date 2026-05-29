#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/install.sh --agent claude|mastracode|all [--scope user|project]

Install custom /ap: commands for the specified agent. The agent-protocol skill
must already be installed (managed separately by the user).

Examples:
  scripts/install.sh --agent claude --scope user
  scripts/install.sh --agent mastracode --scope project
  scripts/install.sh --agent all

Scopes:
  user    - installs into ~/.claude or ~/.mastracode
  project - installs into .claude or .mastracode under the current directory
EOF
}

AGENT=""
SCOPE="project"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --agent)
      if [ "$#" -lt 2 ]; then
        echo "error: --agent requires claude, mastracode, or all" >&2
        exit 1
      fi
      AGENT="$2"
      shift 2
      ;;
    --scope)
      if [ "$#" -lt 2 ]; then
        echo "error: --scope requires user or project" >&2
        exit 1
      fi
      SCOPE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "$AGENT" ]; then
  echo "error: --agent is required" >&2
  usage >&2
  exit 1
fi

case "$AGENT" in
  claude|mastracode|all) ;;
  *)
    echo "error: unsupported agent: $AGENT" >&2
    exit 1
    ;;
esac

case "$SCOPE" in
  user|project) ;;
  *)
    echo "error: unsupported scope: $SCOPE" >&2
    exit 1
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

copy_dir() {
  local src="$1"
  local dst="$2"
  rm -rf "$dst"
  mkdir -p "$(dirname "$dst")"
  cp -R "$src" "$dst"
}

install_claude() {
  local base
  if [ "$SCOPE" = "user" ]; then
    base="$HOME/.claude"
  else
    base=".claude"
  fi

  mkdir -p "$base/skills"
  local found=0
  for command_skill in "$REPO_ROOT"/skills/ap:*; do
    [ -d "$command_skill" ] || continue
    found=1
    copy_dir "$command_skill" "$base/skills/$(basename "$command_skill")"
  done
  if [ "$found" -eq 0 ]; then
    echo "error: no /ap: command skills found at skills/ap:*" >&2
    exit 1
  fi

  echo "✓ Claude Code /ap: commands installed to $base/skills"
  echo "  - commands: $base/skills/ap:*"
}

install_mastracode() {
  local base
  if [ "$SCOPE" = "user" ]; then
    base="$HOME/.mastracode"
  else
    base=".mastracode"
  fi

  if [ ! -d "$REPO_ROOT/adapters/mastracode/commands/ap" ]; then
    echo "error: adapters/mastracode/commands/ap not found at $REPO_ROOT" >&2
    exit 1
  fi

  copy_dir "$REPO_ROOT/adapters/mastracode/commands/ap" "$base/commands/ap"

  echo "✓ Mastra Code /ap: commands installed to $base"
  echo "  - commands: $base/commands/ap"
}

if [ "$AGENT" = "claude" ] || [ "$AGENT" = "all" ]; then
  install_claude
fi

if [ "$AGENT" = "mastracode" ] || [ "$AGENT" = "all" ]; then
  install_mastracode
fi
