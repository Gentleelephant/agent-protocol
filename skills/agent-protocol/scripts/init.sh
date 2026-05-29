#!/usr/bin/env bash
set -euo pipefail

# 用法:
#   初始化/更新当前项目级个人配置:
#     skills/agent-protocol/scripts/init.sh --project --planner-agent "Claude Code" --executor-agent mastracode
#     skills/agent-protocol/scripts/init.sh --project planner="Claude Code" executor=mastracode
#   通过远端脚本运行:
#     curl -sSL https://raw.githubusercontent.com/Gentleelephant/agent-protocol/main/skills/agent-protocol/scripts/init.sh | bash -s -- --project --planner-agent "Claude Code" --executor-agent mastracode

PROJECT_MODE=0
PLANNER_AGENT="Claude Code"
EXECUTOR_AGENT="mastracode"

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

cat > ".agent-memory/agent-protocol.md" << EOF
# Agent 协作协议（项目级个人配置）

这是当前项目的个人私有配置，位于 \`.agent-memory/\` 下，不需要提交到团队仓库。

协议来源：已安装的 \`agent-protocol\` skill。

## 项目角色

- Planner: $PLANNER_AGENT
- Executor: $EXECUTOR_AGENT

## 读取顺序

1. 先读取已安装的 \`agent-protocol\` skill
2. 再读取当前文件 \`.agent-memory/agent-protocol.md\`
3. 当前项目任务状态读取 \`.agent-memory/tasks.json\`

## /ap: 命令

Planner-only：

- \`/ap:review [scope]\`：审查代码并创建 review task，不直接改代码。
- \`/ap:plan [requirement]\`：分析需求或架构方案，创建 feature/design task。
- \`/ap:task [summary]\`：把当前讨论结果保存为 pending task。
- \`/ap:verify [task-id|all]\`：验收 done task，通过则标记 verified。

Executor-only：

- \`/ap:execute [task-id|next]\`：认领并执行 pending task。
- \`/ap:fix [task-id]\`：修复指定 bug/review task。
- \`/ap:test [task-id]\`：运行验证并记录结果。
- \`/ap:done [task-id]\`：标记任务 done 并填写实现说明。

Any-role：

- \`/ap:init planner=<agent> executor=<agent>\`：初始化或更新项目级个人配置。
- \`/ap:tasks\`：列出任务状态。
- \`/ap:status\`：汇总任务统计和下一步建议。
- \`/ap:help\`：显示命令帮助。
- \`/ap:whoami\`：显示当前项目配置中的 Planner / Executor。

## /ap:init

- \`/ap:init\` 是配置命令，任意角色都可以执行。
- 语法：\`/ap:init planner=<agent> executor=<agent>\`
- 它可以创建或更新 \`.agent-memory/agent-protocol.md\`、\`.agent-memory/tasks.json\`、\`CLAUDE.local.md\`、\`.mastracode/AGENTS.md\` 和 \`.git/info/exclude\`。
- 它不实现业务代码，不完成 task，也不绕过角色门禁。
- 如果未提供 planner/executor，优先沿用当前 \`.agent-memory/agent-protocol.md\` 中的项目角色；仍缺失时使用 Planner: Claude Code、Executor: mastracode。

## 命令角色门禁

- 除 \`/ap:init\` 外，执行任何会产生副作用的 \`/ap:\` 命令前，先读取“项目角色”。
- Planner-only 命令只有当前 agent 与 \`Planner: $PLANNER_AGENT\` 匹配时才能执行。
- Executor-only 命令只有当前 agent 与 \`Executor: $EXECUTOR_AGENT\` 匹配时才能执行。
- 角色不匹配时，不要创建 task、不要改代码、不要改任务状态；说明当前项目配置中应该由哪个 agent 执行。
- 如需修改项目角色绑定，重新运行：\`/ap:init planner=<agent> executor=<agent>\` 或 \`skills/agent-protocol/scripts/init.sh --project --planner-agent <agent> --executor-agent <agent>\`。

## 项目规则

- 不要修改项目根目录的 \`AGENTS.md\` 或 \`CLAUDE.md\` 来启用本协议
- 不需要用户显式说“按 agent-protocol”或“作为 Planner/Executor”；根据 skill 中的默认触发规则自动选择角色
- 具体工作流、任务状态、优先级、异常恢复规则以已安装的 \`agent-protocol\` skill 为准
- \`.agent-memory/\` 是个人本地状态目录，应保持不提交
EOF

entry_content="## Agent 协作协议（项目级个人配置）

这是当前项目的个人私有配置入口，不需要提交到团队仓库。

请先读取已安装的 \`agent-protocol\` skill，再读取 \`.agent-memory/agent-protocol.md\`，并按其中的角色规则执行。

默认行为：

- review / 审查 / 检查代码 / 找问题 => Planner，创建 pending task
- 规划 / 设计 / 拆任务 / 需求分析 => Planner，创建 pending task
- 处理 pending task / 实现 task / 修复 task => Executor，更新 task 状态
- 验收 / verify done task => Planner，改为 verified

用户不需要显式说“按 agent-protocol”或“作为 Planner/Executor”。

支持命令：\`/ap:init\`, \`/ap:review\`, \`/ap:plan\`, \`/ap:task\`, \`/ap:verify\`, \`/ap:execute\`, \`/ap:fix\`, \`/ap:test\`, \`/ap:done\`, \`/ap:tasks\`, \`/ap:status\`, \`/ap:help\`, \`/ap:whoami\`。

\`/ap:init\` 是配置命令，任意角色都可以执行。执行任何会创建 task、修改代码、修改 task 状态的命令前，必须读取 \`.agent-memory/agent-protocol.md\` 中的“项目角色”和“命令角色门禁”。角色不匹配时不要执行副作用操作。"

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
echo "  - CLAUDE.local.md 已更新（Claude Code）"
echo "  - .mastracode/AGENTS.md 已更新（Mastra Code）"
echo "  - .agent-memory/agent-protocol.md 已更新"
echo "  - $tasks_message"
echo "  - $exclude_message"
