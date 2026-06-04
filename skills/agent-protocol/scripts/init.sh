#!/usr/bin/env bash
set -euo pipefail

# 用法:
#   skills/agent-protocol/scripts/init.sh --project
#   skills/agent-protocol/scripts/init.sh --project --planner-agent "Claude Code" --executor-agent "Mastra Code"
#   skills/agent-protocol/scripts/init.sh --project planner="Claude Code" executor="Mastra Code"
# 说明:
#   planner/executor 参数仅用于兼容旧配置，不再参与命令门禁。

PROJECT_MODE=0
PLANNER_AGENT="Claude Code"
EXECUTOR_AGENT="Mastra Code"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project)
      PROJECT_MODE=1
      shift
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
    planner=*)
      PLANNER_AGENT="${1#planner=}"
      shift
      ;;
    executor=*)
      EXECUTOR_AGENT="${1#executor=}"
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

mkdir -p .agent-memory
mkdir -p \
  .agent-memory/artifacts/review \
  .agent-memory/artifacts/plan \
  .agent-memory/artifacts/prompt \
  .agent-memory/artifacts/done

cat > ".agent-memory/agent-protocol.md" << EOF
# Agent 协作协议（项目级个人配置）

这是当前项目的个人私有配置，位于 \`.agent-memory/\` 下，不需要提交到团队仓库。

协议来源：已安装的 \`agent-protocol\` skill。

## 工作模式

- 默认采用单 agent 工作流
- 同一个 agent 可以 review、plan、task、fix、execute、test、done、verify
- 支持 \`/ap:\` 子命令时可以直接使用子命令
- 不支持 \`/ap:\` 子命令时，必须把自然语言请求解释成等价命令意图
- 如保留 legacy 字段，仅用于兼容展示：
  - Planner: $PLANNER_AGENT
  - Executor: $EXECUTOR_AGENT

## 读取顺序

1. 先读取已安装的 \`agent-protocol\` skill
2. 再读取当前文件 \`.agent-memory/agent-protocol.md\`
3. 当前项目任务状态读取 \`.agent-memory/tasks.json\`
4. 详细结果工件读取 \`.agent-memory/artifacts/\`

## 共享记忆结构

- \`.agent-memory/tasks.json\`：任务索引和状态流转的唯一来源
- \`.agent-memory/artifacts/\`：review、plan、prompt、done 等结果工件
- 读取状态优先看 task，读取细节优先看 artifact
- artifact 只补充证据和历史，不反向修改 task 语义

## /ap: 命令

- \`/ap:review [scope]\`
- \`/ap:plan [requirement]\`
- \`/ap:execute [task-id|next]\`
- \`/ap:fix [task-id]\`
- \`/ap:init planner=<agent> executor=<agent>\`

## 自然语言等价意图

- “根据这个需求结合项目代码整理开发计划” => \`plan\`
- “review 这段代码并给出修复 prompt” => \`review\`
- “执行刚才 plan 产出的 prompt” => \`execute\`
- “执行刚才 review 产出的修复 prompt” => \`fix\`
- 对不支持子命令的 agent，上述自然语言必须产出与 \`/ap:\` 相同的 task 和 artifact

## 项目规则

- 不要修改项目根目录的 \`AGENTS.md\` 或 \`CLAUDE.md\` 来启用本协议
- 不需要用户显式说“按 agent-protocol”或“作为 Planner/Executor”
- legacy \`planner\` / \`executor\` 字段不参与命令门禁
- 支持子命令时，\`/ap:\` 命令默认会自动写入 \`.agent-memory/artifacts/\`
- 不支持子命令时，等价自然语言请求也必须写入同样的 \`.agent-memory/artifacts/\`
- \`.agent-memory/\` 是个人本地状态目录，应保持不提交
EOF

entry_content="## Agent 协作协议（项目级个人配置）

这是当前项目的个人私有配置入口，不需要提交到团队仓库。

请先读取已安装的 \`agent-protocol\` skill，再读取 \`.agent-memory/agent-protocol.md\`。

默认行为：

- review / 审查 / 检查代码 / 找问题 => 创建 pending task 和修复 prompt
- 规划 / 设计 / 拆任务 / 需求分析 => 创建 pending task 和执行 prompt
- 处理 pending task / 实现 task / 修复 task => 更新 task 状态、执行验证并记录完成结果

同一个 agent 可以执行完整流程。legacy \`planner\` / \`executor\` 字段仅用于兼容展示，不参与门禁。

如果当前 agent 不支持 \`/ap:\` 子命令，就把上述意图当作自然语言工作流执行，并产出相同的 task 与 artifact。

支持命令：\`/ap:init\`, \`/ap:review\`, \`/ap:plan\`, \`/ap:execute\`, \`/ap:fix\`。"

printf "%s\n" "$entry_content" > CLAUDE.local.md
mkdir -p .mastracode
printf "%s\n" "$entry_content" > .mastracode/AGENTS.md

if [ ! -f ".agent-memory/tasks.json" ]; then
  printf '{"tasks": []}\n' > .agent-memory/tasks.json
  tasks_message=".agent-memory/tasks.json 已创建"
else
  tasks_message=".agent-memory/tasks.json 已保留"
fi

if [ -d ".git" ] && [ -f ".git/info/exclude" ]; then
  for pattern in ".agent-memory/" "CLAUDE.local.md" ".mastracode/AGENTS.md"; do
    if ! grep -Fxq "$pattern" ".git/info/exclude"; then
      printf "%s\n" "$pattern" >> ".git/info/exclude"
    fi
  done
  exclude_message=".git/info/exclude 已更新"
else
  exclude_message=".git/info/exclude 未修改"
fi

echo "✓ 项目级个人配置已初始化/更新"
echo "  - legacy Planner: $PLANNER_AGENT"
echo "  - legacy Executor: $EXECUTOR_AGENT"
echo "  - CLAUDE.local.md 已更新（Claude Code）"
echo "  - .mastracode/AGENTS.md 已更新（Mastra Code）"
echo "  - .agent-memory/agent-protocol.md 已更新"
echo "  - $tasks_message"
echo "  - .agent-memory/artifacts/ 目录已确保存在"
echo "  - $exclude_message"
