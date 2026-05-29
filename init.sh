#!/usr/bin/env bash
set -euo pipefail

# 用法:
#   安装/更新协议: curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/main/init.sh | bash
#   初始化项目:   ~/.agent-protocol/init.sh --project
#   指定版本:     ~/.agent-protocol/init.sh --project --version v1.0

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

append_once() {
  local file="$1"
  local marker="$2"
  local content="$3"

  touch "$file"
  if ! grep -Fq "$marker" "$file"; then
    printf "\n%s\n" "$content" >> "$file"
  fi
}

init_project() {
  mkdir -p .agent-memory

  append_once "AGENTS.md" "## Agent 协作协议" "## Agent 协作协议 (version: $VERSION)
@file ~/.agent-protocol/PROTOCOL.md
@file ~/.agent-protocol/roles/planner.md"

  append_once "CLAUDE.md" "## Agent 协作协议" "## Agent 协作协议
协议详见 AGENTS.md，本文件角色为 Executor。
@file ~/.agent-protocol/roles/executor.md"

  if [ ! -f ".agent-memory/tasks.json" ]; then
    printf '{"tasks": []}\n' > .agent-memory/tasks.json
  fi

  echo "✓ 项目已接入协议"
  echo "  - AGENTS.md 已更新（Planner/Codex）"
  echo "  - CLAUDE.md 已更新（Executor/Claude Code）"
  echo "  - .agent-memory/tasks.json 已创建"
}

install_protocol

if [ "$PROJECT_MODE" -eq 1 ]; then
  init_project
fi
