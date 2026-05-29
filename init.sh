#!/usr/bin/env bash
set -euo pipefail

# 用法:
#   安装/更新协议: curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/main/init.sh | bash
#   初始化/更新项目本地状态: ~/.agent-protocol/init.sh --project
#   指定版本:             ~/.agent-protocol/init.sh --version v1.0
#   指定扮演者:           ~/.agent-protocol/init.sh --planner-agent opencode --executor-agent opencode

REPO_RAW="https://raw.githubusercontent.com/Gentleelephant/agent-protocol"
VERSION="main"
PROJECT_MODE=0
PLANNER_AGENT="Codex"
EXECUTOR_AGENT="Claude Code"
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
    --planner-agent)
      if [ "$#" -lt 2 ]; then
        echo "error: --planner-agent requires a value" >&2
        exit 1
      fi
      PLANNER_AGENT="$2"
      shift 2
      ;;
    --executor-agent)
      if [ "$#" -lt 2 ]; then
        echo "error: --executor-agent requires a value" >&2
        exit 1
      fi
      EXECUTOR_AGENT="$2"
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
  write_protocol_file
  write_role_files
  write_personal_configs

  echo "✓ 协议已安装: $PROTOCOL_DIR (version: $VERSION)"
  echo "  - Planner: $PLANNER_AGENT"
  echo "  - Executor: $EXECUTOR_AGENT"
  echo "✓ 个人级规则已更新"
  echo "  - ~/.codex/AGENTS.md"
  echo "  - ~/.claude/CLAUDE.md"
  echo "  - ~/.config/opencode/AGENTS.md"
}

write_protocol_file() {
  cat > "$PROTOCOL_DIR/PROTOCOL.md" << EOF
# Agent 协作协议 v1.0

## 角色分工

- **Planner**（${PLANNER_AGENT}）：负责分析、设计、review，输出任务
- **Executor**（${EXECUTOR_AGENT}）：负责实现、修复，更新任务状态

## 共享记忆位置

项目根目录下的 \`.agent-memory/tasks.json\`

## 任务类型

- \`review\`：代码审查，Planner 发现问题
- \`feature\`：新功能，Planner 提出方案
- \`design\`：架构设计，Planner 提出方案
- \`bug\`：缺陷修复

## 任务结构（JSON）

\`\`\`json
{
  "id": "task-001",
  "type": "review|feature|design|bug",
  "created_by": "planner",
  "status": "pending|in_progress|done|verified",
  "title": "简短描述",
  "context": "背景和原因",
  "spec": "具体方案或问题描述（Planner 填写）",
  "implementation_notes": "实现备注（Executor 填写）",
  "created_at": "",
  "updated_at": ""
}
\`\`\`

## 状态流转

pending → in_progress → done → verified

（Planner 写入）  （Executor 认领） （Executor 完成） （Planner 验收）

## 规则

- Planner 只写 pending 状态，不修改 Executor 的字段
- Executor 只改 status / implementation_notes，不修改 spec
- 追加任务，不覆盖整个文件
EOF
}

write_role_files() {
  cat > "$PROTOCOL_DIR/roles/planner.md" << EOF
## 你是 Planner 角色（由 ${PLANNER_AGENT} 扮演）

### 职责

- 分析需求、设计方案、review 代码
- 将所有输出写入 \`.agent-memory/tasks.json\`
- 只写 \`status: pending\`，等待 Executor 认领
- 完成后验收 Executor 的工作，将 status 改为 verified

### 何时创建任务

- 发现 bug 或安全问题 → type: review
- 用户提出新功能需求 → type: feature
- 需要架构决策 → type: design

### 禁止事项

- 不要自己动手改代码
- 不要将 status 改为 pending 以外的值（verified 除外）
- 不要覆盖整个 tasks.json，只追加新任务
EOF

  cat > "$PROTOCOL_DIR/roles/executor.md" << EOF
## 你是 Executor 角色（由 ${EXECUTOR_AGENT} 扮演）

### 启动时

先读取 \`.agent-memory/tasks.json\`，找出所有 \`status: pending\` 的任务

### 职责

- 将认领的任务 status 改为 in_progress
- 按照 spec 实现或修复
- 完成后将 status 改为 done，填写 implementation_notes 和 updated_at

### 禁止事项

- 不要修改 spec、context 等 Planner 填写的字段
- 不要创建新任务（那是 Planner 的工作）
- 不要将 status 改为 verified（那是 Planner 验收后才改的）
EOF
}

write_managed_block() {
  local file="$1"
  local start_marker="$2"
  local end_marker="$3"
  local content="$4"
  local tmp_file

  tmp_file="$(mktemp)"
  mkdir -p "$(dirname "$file")"
  touch "$file"

  awk -v start="$start_marker" -v end="$end_marker" '
    $0 == start {
      skip_managed = 1
      next
    }
    $0 == end {
      skip_managed = 0
      next
    }
    !skip_managed {
      print
    }
  ' "$file" > "$tmp_file"

  {
    cat "$tmp_file"
    printf "\n%s\n%s\n%s\n" "$start_marker" "$content" "$end_marker"
  } > "$file"

  rm -f "$tmp_file"
}

write_personal_configs() {
  local content

  content="## Agent 协作协议（个人级）

这是本机个人规则，不要求项目提交 AGENTS.md 或 CLAUDE.md。

当当前项目存在 \`.agent-memory/agent-protocol.md\` 或 \`.agent-memory/tasks.json\`，或用户提到 agent-protocol、Planner、Executor、创建 task、处理 pending task、review 后交给另一个 agent 时：

- 读取 \`$PROTOCOL_DIR/PROTOCOL.md\`
- 需要 Planner 行为时读取 \`$PROTOCOL_DIR/roles/planner.md\`
- 需要 Executor 行为时读取 \`$PROTOCOL_DIR/roles/executor.md\`
- 如果当前项目存在 \`.agent-memory/agent-protocol.md\`，先读取它，并以其中的项目级个人设置为准
- Planner 当前由 $PLANNER_AGENT 扮演
- Executor 当前由 $EXECUTOR_AGENT 扮演
- Planner 只追加 \`status: pending\` 的 task，不直接改业务代码
- Executor 认领 pending task，完成后改为 \`done\` 并填写 \`implementation_notes\`
- 不要依赖项目根目录的 AGENTS.md / CLAUDE.md 来启用本协议"

  write_managed_block "$HOME/.codex/AGENTS.md" "<!-- agent-protocol:start -->" "<!-- agent-protocol:end -->" "$content"
  write_managed_block "$HOME/.claude/CLAUDE.md" "<!-- agent-protocol:start -->" "<!-- agent-protocol:end -->" "$content"
  write_managed_block "$HOME/.config/opencode/AGENTS.md" "<!-- agent-protocol:start -->" "<!-- agent-protocol:end -->" "$content"
}

init_project() {
  mkdir -p .agent-memory

  cat > ".agent-memory/agent-protocol.md" << EOF
# Agent 协作协议（项目级个人配置）

这是当前项目的个人私有配置，位于 \`.agent-memory/\` 下，不需要提交到团队仓库。

## 项目角色

- Planner: $PLANNER_AGENT
- Executor: $EXECUTOR_AGENT

## 读取顺序

1. 先读取 \`$PROTOCOL_DIR/PROTOCOL.md\`
2. Planner 行为读取 \`$PROTOCOL_DIR/roles/planner.md\`
3. Executor 行为读取 \`$PROTOCOL_DIR/roles/executor.md\`
4. 当前项目任务状态读取 \`.agent-memory/tasks.json\`

## 项目规则

- 不要修改项目根目录的 \`AGENTS.md\` 或 \`CLAUDE.md\` 来启用本协议
- Planner 只追加 \`status: pending\` 的 task，不直接改业务代码
- Executor 认领 pending task，完成后改为 \`done\` 并填写 \`implementation_notes\`
- \`.agent-memory/\` 是个人本地状态目录，应保持不提交
EOF
  project_config_message=".agent-memory/agent-protocol.md 已更新"

  if [ ! -f ".agent-memory/tasks.json" ]; then
    printf '{"tasks": []}\n' > .agent-memory/tasks.json
    tasks_message=".agent-memory/tasks.json 已创建"
  else
    tasks_message=".agent-memory/tasks.json 已保留"
  fi

  if [ -d ".git" ] && [ -f ".git/info/exclude" ] && ! grep -Fxq ".agent-memory/" ".git/info/exclude"; then
    printf "\n# agent-protocol local state\n.agent-memory/\n" >> ".git/info/exclude"
    exclude_message=".git/info/exclude 已加入 .agent-memory/"
  else
    exclude_message=".git/info/exclude 未修改"
  fi

  echo "✓ 项目本地状态已初始化/更新"
  echo "  - $project_config_message"
  echo "  - $tasks_message"
  echo "  - $exclude_message"
}

install_protocol

if [ "$PROJECT_MODE" -eq 1 ]; then
  init_project
fi
