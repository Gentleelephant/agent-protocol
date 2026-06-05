#!/usr/bin/env bash
set -euo pipefail

# 用法:
#   skills/agent-protocol/scripts/install-commands.sh
#   skills/agent-protocol/scripts/install-commands.sh --agent claude
#   skills/agent-protocol/scripts/install-commands.sh --agent mastracode --scope user
#   skills/agent-protocol/scripts/install-commands.sh --agent reasonix --scope user
#   skills/agent-protocol/scripts/install-commands.sh --agent all --scope project

AGENT="all"
SCOPE="project"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --agent)
      if [ "$#" -lt 2 ]; then
        echo "error: --agent requires a value" >&2
        exit 1
      fi
      AGENT="$2"
      shift 2
      ;;
    --scope)
      if [ "$#" -lt 2 ]; then
        echo "error: --scope requires a value" >&2
        exit 1
      fi
      SCOPE="$2"
      shift 2
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

case "$AGENT" in
  claude|mastracode|reasonix|all)
    ;;
  *)
    echo "error: --agent must be one of: claude, mastracode, reasonix, all" >&2
    exit 1
    ;;
esac

case "$SCOPE" in
  project|user)
    ;;
  *)
    echo "error: --scope must be one of: project, user" >&2
    exit 1
    ;;
esac

if [ "$SCOPE" = "project" ]; then
  CLAUDE_BASE=".claude"
  MASTRA_BASE=".mastracode"
  REASONIX_BASE=".reasonix"
else
  CLAUDE_BASE="$HOME/.claude"
  MASTRA_BASE="$HOME/.mastracode"
  REASONIX_BASE="$HOME/.config/reasonix"
fi

sync_command_file() {
  local src="$1"
  local dest="$2"
  local name
  name="$(basename "$src")"

  if [ ! -e "$dest" ]; then
    cp "$src" "$dest"
    echo "    - $name 已创建"
    return
  fi

  if cmp -s "$src" "$dest"; then
    echo "    - $name 已是最新，跳过写入"
  else
    cp "$src" "$dest"
    echo "    - $name 已更新"
  fi
}

install_claude() {
  local base="$1"
  local target_dir="$base/commands"
  mkdir -p "$target_dir"
  echo "  - Claude Code -> $target_dir"
  for obsolete in "$target_dir/ap:fix.md" "$target_dir/ap:clean.md"; do
    if [ -e "$obsolete" ]; then
      rm -f "$obsolete"
      echo "    - $(basename "$obsolete") 已删除（废弃命令）"
    fi
  done
  for src in "$SKILL_ROOT"/adapters/claude/commands/ap:*.md; do
    local dest="$target_dir/$(basename "$src")"
    sync_command_file "$src" "$dest"
  done
}

install_mastracode() {
  local base="$1"
  local target_dir="$base/commands/ap"
  mkdir -p "$target_dir"
  echo "  - Mastra Code -> $target_dir"
  for obsolete in "$target_dir/fix.md" "$target_dir/clean.md"; do
    if [ -e "$obsolete" ]; then
      rm -f "$obsolete"
      echo "    - $(basename "$obsolete") 已删除（废弃命令）"
    fi
  done
  for src in "$SKILL_ROOT"/adapters/mastracode/commands/ap/*.md; do
    local dest="$target_dir/$(basename "$src")"
    sync_command_file "$src" "$dest"
  done
}

install_reasonix() {
  local base="$1"
  local target_dir="$base/commands/ap"
  mkdir -p "$target_dir"
  echo "  - Reasonix -> $target_dir"
  for obsolete in "$target_dir/fix.md" "$target_dir/clean.md"; do
    if [ -e "$obsolete" ]; then
      rm -f "$obsolete"
      echo "    - $(basename "$obsolete") 已删除（废弃命令）"
    fi
  done
  for src in "$SKILL_ROOT"/adapters/reasonix/commands/ap/*.md; do
    local dest="$target_dir/$(basename "$src")"
    sync_command_file "$src" "$dest"
  done
}

echo "✓ agent-protocol 子命令已安装"
echo "  - scope: $SCOPE"

if [ "$AGENT" = "claude" ] || [ "$AGENT" = "all" ]; then
  install_claude "$CLAUDE_BASE"
fi

if [ "$AGENT" = "mastracode" ] || [ "$AGENT" = "all" ]; then
  install_mastracode "$MASTRA_BASE"
fi

if [ "$AGENT" = "reasonix" ] || [ "$AGENT" = "all" ]; then
  install_reasonix "$REASONIX_BASE"
fi
