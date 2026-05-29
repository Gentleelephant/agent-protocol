#!/usr/bin/env bash
set -euo pipefail

# 用法:
#   安装/更新协议: curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/main/init.sh | bash
#   初始化/更新项目: ~/.agent-protocol/init.sh --project
#   指定版本:       ~/.agent-protocol/init.sh --project --version v1.0

REPO_RAW="https://raw.githubusercontent.com/Gentleelephant/agent-protocol"
VERSION="main"
PROJECT_MODE=0
PROTOCOL_DIR="$HOME/.agent-protocol"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project)
      PROJECT_MODE=1
      shift
      ;;
    --version)
      if [ "$#" -lt 2 ]; then
        echo "error: --version requires a value" >&2
        exit 1
      fi
      VERSION="$2"
      shift 2
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

install_protocol() {
  mkdir -p "$PROTOCOL_DIR/roles" "$PROTOCOL_DIR/schema"

  curl -fsSL "$REPO_RAW/$VERSION/PROTOCOL.md" -o "$PROTOCOL_DIR/PROTOCOL.md"
  curl -fsSL "$REPO_RAW/$VERSION/roles/planner.md" -o "$PROTOCOL_DIR/roles/planner.md"
  curl -fsSL "$REPO_RAW/$VERSION/roles/executor.md" -o "$PROTOCOL_DIR/roles/executor.md"
  curl -fsSL "$REPO_RAW/$VERSION/schema/tasks.schema.json" -o "$PROTOCOL_DIR/schema/tasks.schema.json"
  curl -fsSL "$REPO_RAW/$VERSION/init.sh" -o "$PROTOCOL_DIR/init.sh"
  chmod +x "$PROTOCOL_DIR/init.sh"

  echo "✓ 协议已安装: $PROTOCOL_DIR (version: $VERSION)"
}

write_managed_block() {
  local file="$1"
  local start_marker="$2"
  local end_marker="$3"
  local legacy_role_file="$4"
  local content="$5"
  local tmp_file

  tmp_file="$(mktemp)"
  touch "$file"

  awk -v start="$start_marker" -v end="$end_marker" -v legacy_role_file="$legacy_role_file" '
    $0 == start {
      skip_managed = 1
      next
    }
    $0 == end {
      skip_managed = 0
      next
    }
    !skip_managed && $0 ~ /^## Agent 协作协议/ {
      skip_legacy = 1
      next
    }
    skip_legacy && index($0, legacy_role_file) {
      skip_legacy = 0
      next
    }
    !skip_managed && !skip_legacy {
      print
    }
  ' "$file" > "$tmp_file"

  {
    cat "$tmp_file"
    printf "\n%s\n%s\n%s\n" "$start_marker" "$content" "$end_marker"
  } > "$file"

  rm -f "$tmp_file"
}

init_project() {
  mkdir -p .agent-memory

  write_managed_block "AGENTS.md" "<!-- agent-protocol:start -->" "<!-- agent-protocol:end -->" "@file ~/.agent-protocol/roles/planner.md" "## Agent 协作协议 (version: $VERSION)
@file ~/.agent-protocol/PROTOCOL.md
@file ~/.agent-protocol/roles/planner.md"

  write_managed_block "CLAUDE.md" "<!-- agent-protocol:start -->" "<!-- agent-protocol:end -->" "@file ~/.agent-protocol/roles/executor.md" "## Agent 协作协议 (version: $VERSION)
协议详见 AGENTS.md，本文件角色为 Executor。
@file ~/.agent-protocol/roles/executor.md"

  if [ ! -f ".agent-memory/tasks.json" ]; then
    printf '{"tasks": []}\n' > .agent-memory/tasks.json
    tasks_message=".agent-memory/tasks.json 已创建"
  else
    tasks_message=".agent-memory/tasks.json 已保留"
  fi

  echo "✓ 项目已接入/更新协议"
  echo "  - AGENTS.md 已更新（Planner/Codex）"
  echo "  - CLAUDE.md 已更新（Executor/Claude Code）"
  echo "  - $tasks_message"
}

install_protocol

if [ "$PROJECT_MODE" -eq 1 ]; then
  init_project
fi
