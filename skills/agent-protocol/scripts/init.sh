#!/usr/bin/env bash
set -euo pipefail

# 用法:
#   skills/agent-protocol/scripts/init.sh --project
#   skills/agent-protocol/scripts/init.sh --project --agent claude
#   skills/agent-protocol/scripts/init.sh --project --agent mastracode
#   skills/agent-protocol/scripts/init.sh --project --agent reasonix

PROJECT_MODE=0
AGENT="all"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project)
      PROJECT_MODE=1
      shift
      ;;
    --agent)
      if [ "$#" -lt 2 ]; then
        echo "error: --agent requires a value" >&2
        exit 1
      fi
      AGENT="$2"
      shift 2
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [ "$PROJECT_MODE" -ne 1 ]; then
  echo "error: this script only initializes project-local personal config. Use --project." >&2
  exit 1
fi

case "$AGENT" in
  claude|mastracode|reasonix|all)
    ;;
  *)
    echo "error: --agent must be one of: claude, mastracode, reasonix, all" >&2
    exit 1
    ;;
esac

ensure_dir() {
  local dir="$1"
  if [ -d "$dir" ]; then
    echo "  - $dir 已存在，跳过"
  else
    mkdir -p "$dir"
    echo "  - $dir 已创建"
  fi
}

write_file_if_missing() {
  local path="$1"
  local content="$2"
  if [ -e "$path" ]; then
    echo "  - $path 已存在，跳过"
  else
    printf "%s\n" "$content" > "$path"
    echo "  - $path 已创建"
  fi
}

copy_if_missing() {
  local src="$1"
  local dest="$2"
  if [ -e "$dest" ]; then
    echo "  - $dest 已存在，跳过"
  else
    cp "$src" "$dest"
    echo "  - $dest 已创建"
  fi
}

AGENT_PROTOCOL_CONTENT=$(cat <<'EOF'
# Agent 协作协议（项目级个人配置）

这是当前项目的个人私有配置，位于 `.agent-memory/` 下，不需要提交到团队仓库。

协议来源：已安装的 `agent-protocol` skill。

## 工作模式

- 不要求显式声明角色
- 任何 agent 都可以读取并推进 task 与 artifact
- 支持 `/ap:` 子命令时可以直接使用子命令
- 不支持 `/ap:` 子命令时，必须把自然语言请求解释成等价命令意图

## 读取顺序

1. 先读取已安装的 `agent-protocol` skill
2. 再读取当前文件 `.agent-memory/agent-protocol.md`
3. 当前项目任务状态读取 `.agent-memory/tasks.json`
4. 详细结果工件读取 `.agent-memory/artifacts/`

## 共享记忆结构

- `.agent-memory/tasks.json`：任务索引和状态流转的唯一来源
- `.agent-memory/artifacts/`：review、plan、prompt、done 等结果工件
- 读取状态优先看 task，读取细节优先看 artifact
- artifact 只补充证据和历史，不反向修改 task 语义

## /ap: 命令

- `/ap:review [scope]`
- `/ap:plan [requirement]`
- `/ap:execute [task-id|next|--origin review|plan|prompt|plan-artifact]`
- `/ap:fix [task-id]`（兼容别名）
- `/ap:clean [history|all]`
- `/ap:init`

## 自然语言等价意图

- “根据这个需求结合项目代码整理开发计划” => `plan`
- “review 这段代码并给出修复 prompt” => `review`
- “执行刚才 plan 产出的 prompt” => `execute`
- “执行刚才 review 产出的修复 prompt” => `execute`
- “清理 .agent-memory 里的历史数据” => `clean`
- 对不支持子命令的 agent，上述自然语言必须产出与 `/ap:` 相同的 task，并持久化保存到相同的 artifact 目录

## 项目规则

- 不要修改项目根目录的 `AGENTS.md` 或 `CLAUDE.md` 来启用本协议
- 不需要用户显式说“按 agent-protocol”或声明角色
- `/ap:plan` 和 `/ap:review` 必须把开发计划、review 结果和 execution prompt 持久化写入 `.agent-memory/artifacts/`
- `/ap:execute` 接收直接 prompt 或 plan 文档时，必须先归一化为 task 和 artifact，再执行
- 不支持子命令时，等价自然语言请求也必须写入同样的 `.agent-memory/artifacts/`
- `.agent-memory/` 是个人本地状态目录，应保持不提交
EOF
)

ENTRY_CONTENT=$(cat <<'EOF'
## Agent 协作协议（项目级个人配置）

这是当前项目的个人私有配置入口，不需要提交到团队仓库。

请先读取已安装的 `agent-protocol` skill，再读取 `.agent-memory/agent-protocol.md`。

默认行为：

- review / 审查 / 检查代码 / 找问题 => 创建 pending task 和修复 prompt
- 规划 / 设计 / 拆任务 / 需求分析 => 创建 pending task、开发计划 artifact 和执行 prompt
- 处理 pending task / 实现 task / 修复 task => 更新 task 状态、执行验证并记录完成结果

不要求显式区分角色。任何 agent 都可以读取并推进 task 与 artifact。

如果当前 agent 不支持 `/ap:` 子命令，就把上述意图当作自然语言工作流执行，并产出相同且持久化保存的 task 与 artifact。

支持命令：`/ap:init`, `/ap:review`, `/ap:plan`, `/ap:execute`, `/ap:fix`, `/ap:clean`。
EOF
)

install_claude_commands() {
  ensure_dir ".claude"
  ensure_dir ".claude/commands"
  for src in "$SKILL_ROOT"/adapters/claude/commands/ap:*.md; do
    copy_if_missing "$src" ".claude/commands/$(basename "$src")"
  done
}

install_mastracode_commands() {
  ensure_dir ".mastracode"
  ensure_dir ".mastracode/commands"
  ensure_dir ".mastracode/commands/ap"
  for src in "$SKILL_ROOT"/adapters/mastracode/commands/ap/*.md; do
    copy_if_missing "$src" ".mastracode/commands/ap/$(basename "$src")"
  done
}

install_reasonix_commands() {
  ensure_dir ".reasonix"
  ensure_dir ".reasonix/commands"
  ensure_dir ".reasonix/commands/ap"
  for src in "$SKILL_ROOT"/adapters/reasonix/commands/ap/*.md; do
    copy_if_missing "$src" ".reasonix/commands/ap/$(basename "$src")"
  done
}

echo "✓ 项目级个人配置初始化"
echo "  - agent: $AGENT"

ensure_dir ".agent-memory"
ensure_dir ".agent-memory/artifacts"
ensure_dir ".agent-memory/artifacts/review"
ensure_dir ".agent-memory/artifacts/plan"
ensure_dir ".agent-memory/artifacts/prompt"
ensure_dir ".agent-memory/artifacts/done"
write_file_if_missing ".agent-memory/agent-protocol.md" "$AGENT_PROTOCOL_CONTENT"

if [ ! -f ".agent-memory/tasks.json" ]; then
  printf '{"tasks": []}\n' > .agent-memory/tasks.json
  echo "  - .agent-memory/tasks.json 已创建"
else
  echo "  - .agent-memory/tasks.json 已存在，跳过"
fi

if [ "$AGENT" = "claude" ] || [ "$AGENT" = "all" ]; then
  write_file_if_missing "CLAUDE.local.md" "$ENTRY_CONTENT"
  install_claude_commands
fi

if [ "$AGENT" = "mastracode" ] || [ "$AGENT" = "all" ]; then
  ensure_dir ".mastracode"
  write_file_if_missing ".mastracode/AGENTS.md" "$ENTRY_CONTENT"
  install_mastracode_commands
fi

if [ "$AGENT" = "reasonix" ] || [ "$AGENT" = "all" ]; then
  install_reasonix_commands
fi

if [ -d ".git" ]; then
  mkdir -p ".git/info"
  touch ".git/info/exclude"
  for pattern in ".agent-memory/" ".claude/" ".mastracode/" ".reasonix/" "CLAUDE.local.md"; do
    if ! grep -Fxq "$pattern" ".git/info/exclude"; then
      printf "%s\n" "$pattern" >> ".git/info/exclude"
    fi
  done
  echo "  - .git/info/exclude 已更新"
else
  echo "  - .git/info/exclude 未修改"
fi
