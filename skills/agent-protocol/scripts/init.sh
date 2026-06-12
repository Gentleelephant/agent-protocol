#!/usr/bin/env bash
set -euo pipefail

# 用法:
#   skills/agent-protocol/scripts/init.sh --project

PROJECT_MODE=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project)
      PROJECT_MODE=1
      shift
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

sync_file() {
  local src="$1"
  local dest="$2"
  if [ ! -e "$dest" ]; then
    cp "$src" "$dest"
    echo "  - $dest 已创建"
    return
  fi

  if cmp -s "$src" "$dest"; then
    echo "  - $dest 已是最新，跳过写入"
  else
    cp "$src" "$dest"
    echo "  - $dest 已更新"
  fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AGENT_PROTOCOL_CONTENT=$(cat <<'EOF'
# Agent 协作协议（项目级个人配置）

这是当前项目的个人私有配置，位于 `.agent-memory/` 下，不需要提交到团队仓库。

协议来源：已安装的 `agent-protocol` skill。

## 工作模式

- 不要求显式声明角色
- 任何 agent 都可以读取并推进 task 与 artifact
- 支持 `/ap:` 子命令时可以直接使用子命令
- 不支持 `/ap:` 子命令时，只有明确 agent-protocol 意图的自然语言请求才解释成等价命令意图

## 读取顺序

1. 先读取当前项目下的 `.agent-memory/scripts/` 本地协议脚本（如存在）
2. 再读取已安装的 `agent-protocol` skill
3. 再读取当前文件 `.agent-memory/agent-protocol.md`
4. 当前项目任务状态读取 `.agent-memory/tasks.json`
5. 详细结果工件读取 `.agent-memory/artifacts/`

## 共享记忆结构

- `.agent-memory/tasks.json`：任务索引和状态流转的唯一来源
- `.agent-memory/artifacts/`：review、plan、prompt、done 等结果工件
- `.agent-memory/scripts/`：项目本地协议脚本镜像，优先于 user scope 调用
- 读取状态优先看 task，读取细节优先看 artifact
- artifact 只补充证据和历史，不反向修改 task 语义

## /ap: 命令

- `/ap:review [scope]`
- `/ap:plan [requirement]`
- `/ap:import [prompt|prompt-artifact|plan-artifact|plan-document]`
- `/ap:execute [task-id|next|--all] [--origin review|plan|import]`
- `/ap:install [--agent all|claude|cursor|mastracode|mimocode|reasonix] [--scope project|user]`
- `/ap:prune`
- `/ap:reset`
- `/ap:init`

## 自然语言等价意图

- “按 agent-protocol 根据这个需求结合项目代码整理开发计划” => `plan`
- “按 agent-protocol review 这段代码并给出修复 prompt” => `review`
- “导入这个执行 prompt 并创建 task” => `import`
- “执行已有 task-001” => `execute`
- “安装 agent-protocol 命令适配器” => `install`
- “清理 .agent-memory 里的历史数据” => `prune`
- “重置 .agent-memory 本地状态” => `reset`
- 对不支持子命令的 agent，上述自然语言必须产出与 `/ap:` 相同的 task，并持久化保存到相同的 artifact 目录

## 项目规则

- 不要修改项目根目录的 `AGENTS.md` 或 `CLAUDE.md` 来启用本协议
- 普通 review、debug、fix、plan 不自动进入协议流程；需要显式 `/ap:` 或明确 agent-protocol / task / artifact 意图
- `/ap:plan` 和 `/ap:review` 必须把开发计划、review 结果和 execution prompt 持久化写入 `.agent-memory/artifacts/`
- `/ap:import` 接收直接 prompt 或 plan 文档时，只归一化为 task 和 artifact，不执行
- `/ap:execute` 只能执行已有 task，不能创建 task，不能接收直接 prompt 或 plan 文档
- 不支持子命令时，等价自然语言请求也必须写入同样的 `.agent-memory/artifacts/`
- `.agent-memory/` 是个人本地状态目录，应保持不提交
EOF
)

ENTRY_CONTENT=$(cat <<'EOF'
## Agent 协作协议（项目级个人配置）

这是当前项目的个人私有配置入口，不需要提交到团队仓库。

请先读取已安装的 `agent-protocol` skill，再读取 `.agent-memory/agent-protocol.md`。
如果 `.agent-memory/scripts/` 存在，优先使用其中的项目本地脚本，而不是 user scope 脚本。

默认行为：

- 明确 `/ap:review` 或“按 agent-protocol review” => 创建 pending task 和修复 prompt
- 明确 `/ap:plan` 或“按 agent-protocol 规划” => 创建 pending task、开发计划 artifact 和执行 prompt
- 明确 `/ap:import` 或“导入执行 prompt” => 只创建 task 和 artifact，不执行
- 明确 `/ap:execute` 或“执行已有 task” => 更新 task 状态、执行验证并记录完成结果

不要求显式区分角色。任何 agent 都可以读取并推进 task 与 artifact。

如果当前 agent 不支持 `/ap:` 子命令，就把上述意图当作自然语言工作流执行，并产出相同且持久化保存的 task 与 artifact。

支持命令：`/ap:init`, `/ap:install`, `/ap:review`, `/ap:plan`, `/ap:import`, `/ap:execute`, `/ap:prune`, `/ap:reset`。
EOF
)

echo "✓ 项目级个人配置初始化"

ensure_dir ".agent-memory"
ensure_dir ".agent-memory/artifacts"
ensure_dir ".agent-memory/artifacts/review"
ensure_dir ".agent-memory/artifacts/plan"
ensure_dir ".agent-memory/artifacts/prompt"
ensure_dir ".agent-memory/artifacts/done"
ensure_dir ".agent-memory/scripts"
write_file_if_missing ".agent-memory/agent-protocol.md" "$AGENT_PROTOCOL_CONTENT"
sync_file "$SCRIPT_DIR/init.sh" ".agent-memory/scripts/init.sh"
sync_file "$SCRIPT_DIR/install-commands.sh" ".agent-memory/scripts/install-commands.sh"
sync_file "$SCRIPT_DIR/prune.sh" ".agent-memory/scripts/prune.sh"

if [ ! -f ".agent-memory/tasks.json" ]; then
  printf '{"tasks": []}\n' > .agent-memory/tasks.json
  echo "  - .agent-memory/tasks.json 已创建"
else
  echo "  - .agent-memory/tasks.json 已存在，跳过"
fi

write_file_if_missing "CLAUDE.local.md" "$ENTRY_CONTENT"
ensure_dir ".mastracode"
write_file_if_missing ".mastracode/AGENTS.md" "$ENTRY_CONTENT"

if [ -d ".git" ]; then
  mkdir -p ".git/info"
  touch ".git/info/exclude"
  for pattern in ".agent-memory/" "CLAUDE.local.md" ".mastracode/AGENTS.md"; do
    if ! grep -Fxq "$pattern" ".git/info/exclude"; then
      printf "%s\n" "$pattern" >> ".git/info/exclude"
    fi
  done
  echo "  - .git/info/exclude 已更新"
else
  echo "  - .git/info/exclude 未修改"
fi
