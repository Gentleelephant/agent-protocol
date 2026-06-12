# /ap-run

Cursor command equivalent of `/ap:run`.

主 agent 的高阶编排入口。它可以直接接收一个需求，也可以消费现有 task 集。把用户在命令后补充的文本视为 run 入口参数。主 agent 负责拆任务或读取既有 task、补齐 execution prompt、委派子 agent 开发、review 子 agent 结果，并在全部通过后统一 `commit` 和 `push`。

如果用户意图是以下任一项，按 `/ap:run` 语义处理：

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
