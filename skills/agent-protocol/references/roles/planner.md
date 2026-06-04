## 任务创建阶段

### 职责

- 分析需求、设计方案、review 代码
- 将任务写入 `.agent-memory/tasks.json`
- 将完整分析和 review 结果写入 `.agent-memory/artifacts/`
- 为每个可执行问题生成 `execution_prompt` artifact

### 工作流

1. 读取已安装的 `agent-protocol` skill。
2. 收集必要上下文。若存在 `graphify-out/` 且任务需要跨文件、架构或模块关系理解，先用 graphify 定位相关概念和文件，再读取必要源码或文档确认事实。
3. 对复杂方案设计或宽范围 review，可以调用外部 planning / reasoning skill 作为顾问；顾问输出只用于辅助判断，必须压缩并归一化为本协议的 task、plan/review artifact 和 execution prompt。
4. 读取并尽量校验 `.agent-memory/tasks.json`。
5. 确保 `.agent-memory/artifacts/` 及对应子目录存在。
6. 根据用户意图创建 `bug`、`feature` 或 `design` task；旧 `review` task 仅兼容读取。
7. 为新 task 填写明确的 `context`、可执行的 `spec`，以及 `origin_command`、`origin_artifact_id`、`prompt_artifact_id`、`source_summary`、`acceptance`、`depends_on`。
8. 对 `/ap:review`、`/ap:plan` 新建的每个可执行 task，再额外生成一个 `execution_prompt` artifact，保存到 `.agent-memory/artifacts/prompt/`。prompt 必须包含来源摘要和任务契约快照。
9. 为 `/ap:review`、`/ap:plan` 生成对应 artifact，并把引用写入相关 task。
10. 如需排序，填写 `priority`；默认使用 `medium`。
11. 只追加 task，不重写历史任务。

### 兼容规则

- 新任务统一写 `created_by: "agent"`。
- 不根据 agent 身份做角色门禁。
- graphify 和外部顾问 skill 都不能直接接管 `.agent-memory` 状态流转。
- prompt 的 `Source Context` 应保留必要检索和方案依据，但不能要求执行 agent 读取大量历史上下文才能开工。
