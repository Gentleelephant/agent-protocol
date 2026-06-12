---
name: ap:run
description: "Main-agent orchestration for requirements or existing tasks. Any agent."
argument-hint: "[requirement|--all|--tasks task-001,task-002] [--origin review|plan|import|run]"
---

# /ap:run

主 agent 的高阶编排入口。它可以直接接收一个需求，也可以消费现有 task 集。主 agent 负责拆任务或读取既有 task、补齐 execution prompt、委派子 agent 开发、review 子 agent 结果，并在全部通过后统一 `commit` 和 `push`。

如果当前 agent 不支持 `/ap:` 子命令，则以下自然语言请求应触发同样效果：

- “按 agent-protocol 自动完成这个需求并提交”
- “按 agent-protocol 执行所有 task，主 agent review 后 push”
- “按 agent-protocol 把刚才 review 产出的 task 全部跑完”

## 工作流

1. 读取 `.agent-memory/agent-protocol.md`（如存在）。
2. 加载 `.agent-memory/tasks.json`。
3. 确保 `.agent-memory/artifacts/run/`、`plan/`、`review/`、`prompt/` 和 `done/` 存在。
4. 解析入口：
   - 如果传入自然语言 requirement，主 agent 先按 `/ap:plan` 语义一次性拆出本次 run 需要的 task。
   - 如果传入 `--all`，使用现有全部匹配 task。
   - 如果传入 `--tasks ...`，只处理指定 task。
   - `--origin review|plan|import|run` 只过滤 `origin_command`。
5. 写入 `.agent-memory/artifacts/run/` 下的 run artifact，记录编排依据、任务顺序和恢复信息。
6. 为每个 in-scope task 生成或确认 `execution_prompt` artifact。
7. 按 `depends_on`、`priority` 和 `created_at` 串行处理 task，一次只派发一个 task 给子 agent。
8. 子 agent 完成后，主 agent 必须 review 改动、验证结果和风险说明；不通过时退回重做或停止 run，不得直接标记 `done`。
9. 所有 task 全部通过后，由主 agent 统一 `commit` 与 `push`，并把结果写入 run artifact。
10. `/ap:run` 不并行执行 task，不让子 agent 直接提交 git 历史，也不在执行中无限扩散新增 task。
