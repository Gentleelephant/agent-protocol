#!/usr/bin/env bash
set -euo pipefail

# 用法:
#   skills/agent-protocol/scripts/install-commands.sh --project-root /abs/path/to/project
#   skills/agent-protocol/scripts/install-commands.sh --project-root /abs/path/to/project --agent claude
#   skills/agent-protocol/scripts/install-commands.sh --project-root /abs/path/to/project --agent cursor --scope user
#   skills/agent-protocol/scripts/install-commands.sh --project-root /abs/path/to/project --agent mastracode --scope user
#   skills/agent-protocol/scripts/install-commands.sh --project-root /abs/path/to/project --agent mimocode --scope user
#   skills/agent-protocol/scripts/install-commands.sh --project-root /abs/path/to/project --agent reasonix --scope user
#   skills/agent-protocol/scripts/install-commands.sh --project-root /abs/path/to/project --agent all --scope project

AGENT="all"
SCOPE="project"
PROJECT_ROOT=""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

read_skill_root_from_source() {
  local source_path="$1"
  if [ ! -f "$source_path" ]; then
    return 1
  fi

  python3 - "$source_path" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as handle:
    data = json.load(handle)
value = data.get("skill_root")
if not isinstance(value, str) or not value:
    raise SystemExit(1)
print(value)
PY
}

resolve_skill_root() {
  local candidate
  local project_root="$1"
  local source_path="$project_root/.agent-memory/source.json"

  candidate="$(cd "$SCRIPT_DIR/.." && pwd)"
  if [ -f "$candidate/SKILL.md" ] && [ -d "$candidate/adapters" ]; then
    printf "%s\n" "$candidate"
    return
  fi

  if candidate="$(read_skill_root_from_source "$source_path" 2>/dev/null)"; then
    if [ -f "$candidate/SKILL.md" ] && [ -d "$candidate/adapters" ]; then
      printf "%s\n" "$candidate"
      return
    fi
    echo "error: invalid skill_root in $source_path: $candidate" >&2
    exit 1
  fi

  candidate="$project_root/skills/agent-protocol"
  if [ -f "$candidate/SKILL.md" ] && [ -d "$candidate/adapters" ]; then
    printf "%s\n" "$candidate"
    return
  fi

  candidate="$SCRIPT_DIR/../adapters"
  if [ -d "$candidate" ]; then
    cd "$candidate/.." && pwd
    return
  fi

  echo "error: cannot locate agent-protocol skill root. Run init to create .agent-memory/source.json or invoke this script from the repository copy." >&2
  exit 1
}

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
    --project-root)
      if [ "$#" -lt 2 ]; then
        echo "error: --project-root requires a value" >&2
        exit 1
      fi
      PROJECT_ROOT="$2"
      shift 2
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [ -z "$PROJECT_ROOT" ]; then
  echo "error: --project-root is required" >&2
  exit 1
fi

if [ ! -d "$PROJECT_ROOT" ]; then
  echo "error: project root does not exist: $PROJECT_ROOT" >&2
  exit 1
fi

PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
SKILL_ROOT="$(resolve_skill_root "$PROJECT_ROOT")"
ADAPTER_ROOT="$SKILL_ROOT/adapters"

case "$AGENT" in
  claude|cursor|mastracode|mimocode|reasonix|all)
    ;;
  *)
    echo "error: --agent must be one of: claude, cursor, mastracode, mimocode, reasonix, all" >&2
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
  CLAUDE_BASE="$PROJECT_ROOT/.claude"
  CURSOR_BASE="$PROJECT_ROOT/.cursor"
  MASTRA_BASE="$PROJECT_ROOT/.mastracode"
  MIMOCODE_BASE="$PROJECT_ROOT/.mimocode"
  REASONIX_BASE="$PROJECT_ROOT/.reasonix"
else
  CLAUDE_BASE="$HOME/.claude"
  CURSOR_BASE="$HOME/.cursor"
  MASTRA_BASE="$HOME/.mastracode"
  MIMOCODE_BASE="$HOME/.config/mimocode"
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
  for obsolete in "$target_dir/ap:fix.md" "$target_dir/ap:clean.md" "$target_dir/ap:init.md" "$target_dir/ap:install.md"; do
    if [ -e "$obsolete" ]; then
      rm -f "$obsolete"
      echo "    - $(basename "$obsolete") 已删除（废弃命令）"
    fi
  done
  for src in "$ADAPTER_ROOT"/claude/commands/ap:*.md; do
    local dest="$target_dir/$(basename "$src")"
    sync_command_file "$src" "$dest"
  done
}

install_cursor() {
  local base="$1"
  local target_dir="$base/commands"
  mkdir -p "$target_dir"
  echo "  - Cursor -> $target_dir"
  for obsolete in "$target_dir/ap-fix.md" "$target_dir/ap-clean.md" "$target_dir/ap-init.md" "$target_dir/ap-install.md"; do
    if [ -e "$obsolete" ]; then
      rm -f "$obsolete"
      echo "    - $(basename "$obsolete") 已删除（废弃命令）"
    fi
  done
  for src in "$ADAPTER_ROOT"/cursor/commands/*.md; do
    local dest="$target_dir/$(basename "$src")"
    sync_command_file "$src" "$dest"
  done
}

install_mastracode() {
  local base="$1"
  local target_dir="$base/commands/ap"
  mkdir -p "$target_dir"
  echo "  - Mastra Code -> $target_dir"
  for obsolete in "$target_dir/fix.md" "$target_dir/clean.md" "$target_dir/init.md" "$target_dir/install.md"; do
    if [ -e "$obsolete" ]; then
      rm -f "$obsolete"
      echo "    - $(basename "$obsolete") 已删除（废弃命令）"
    fi
  done
  for src in "$ADAPTER_ROOT"/mastracode/commands/ap/*.md; do
    local dest="$target_dir/$(basename "$src")"
    sync_command_file "$src" "$dest"
  done
}

install_mimocode() {
  local base="$1"
  local target_dir="$base/commands"
  mkdir -p "$target_dir"
  echo "  - MiMo Code -> $target_dir"
  for obsolete in "$target_dir/ap:fix.md" "$target_dir/ap:clean.md" "$target_dir/ap:init.md" "$target_dir/ap:install.md"; do
    if [ -e "$obsolete" ]; then
      rm -f "$obsolete"
      echo "    - $(basename "$obsolete") 已删除（废弃命令）"
    fi
  done
  for src in "$ADAPTER_ROOT"/mimocode/commands/ap:*.md; do
    local dest="$target_dir/$(basename "$src")"
    sync_command_file "$src" "$dest"
  done
}

install_reasonix() {
  local base="$1"
  local target_dir="$base/commands/ap"
  mkdir -p "$target_dir"
  echo "  - Reasonix -> $target_dir"
  for obsolete in "$target_dir/fix.md" "$target_dir/clean.md" "$target_dir/init.md" "$target_dir/install.md"; do
    if [ -e "$obsolete" ]; then
      rm -f "$obsolete"
      echo "    - $(basename "$obsolete") 已删除（废弃命令）"
    fi
  done
  for src in "$ADAPTER_ROOT"/reasonix/commands/ap/*.md; do
    local dest="$target_dir/$(basename "$src")"
    sync_command_file "$src" "$dest"
  done
}

echo "✓ agent-protocol 子命令已安装"
echo "  - scope: $SCOPE"
echo "  - project root: $PROJECT_ROOT"
echo "  - skill root: $SKILL_ROOT"

if [ "$AGENT" = "claude" ] || [ "$AGENT" = "all" ]; then
  install_claude "$CLAUDE_BASE"
fi

if [ "$AGENT" = "cursor" ] || [ "$AGENT" = "all" ]; then
  install_cursor "$CURSOR_BASE"
fi

if [ "$AGENT" = "mastracode" ] || [ "$AGENT" = "all" ]; then
  install_mastracode "$MASTRA_BASE"
fi

if [ "$AGENT" = "mimocode" ] || [ "$AGENT" = "all" ]; then
  install_mimocode "$MIMOCODE_BASE"
fi

if [ "$AGENT" = "reasonix" ] || [ "$AGENT" = "all" ]; then
  install_reasonix "$REASONIX_BASE"
fi
