# AGENTS.md

本文件记录 agent 在本仓库中工作的核心要求。进入仓库后优先阅读本文件，再按任务需要读取更具体的文档。

## 项目定位

本仓库维护 `agent-protocol`：一套围绕 `/ap:plan`、`/ap:review`、`/ap:import`、`/ap:execute`、`/ap:init`、`/ap:install`、`/ap:prune`、`/ap:reset` 的 agent 协议与适配器。

协议目标不是堆叠会话上下文，而是把计划、review、可执行 prompt 和完成记录持久化为清晰 artifact，使其他 agent 能够按明确契约继续执行。

## 缓存命中率要求

必须把大模型缓存命中率当作一等约束。

- 优先读取稳定入口文档：`AGENTS.md`、`README.md`、`skills/agent-protocol/SKILL.md`。
- 只读取当前任务真正需要的文件，不要批量展开 `.agent-memory`、`references/`、`adapters/` 或历史 artifact。
- 不要无差别读取 `.agent-memory/tasks.json`。只有执行、清理、恢复、查询具体 task 状态时才读取。
- 不要广泛读取历史 artifact。只读取目标 task 的 `prompt_artifact_id`、`origin_artifact_id` 或用户明确指定的 artifact。
- 如果仓库存在 `graphify-out/`，优先使用 graphify 图谱查询做定位，再决定是否需要读取源码或文档。
- 保持文档结构和标题稳定；修改文档时尽量局部编辑，避免无意义重排导致缓存失效。
- 生成 prompt 或任务时复制必要摘要，而不是要求后续 agent 重新读取大量上下文。

## 可选图谱索引

graphify 可以作为代码库理解和检索的可选索引层，用于减少无目标文件读取和重复上下文消耗。

使用规则：

- 如果 `graphify-out/` 已存在，涉及代码结构、模块关系、文档关系、架构理解或方案规划时，应先使用 graphify 的 `query`、`explain` 或 `path` 做定位。
- graphify 的结果只作为检索和理解线索，不能替代源码、脚本、schema 或协议文档中的事实依据。
- 只有当 graphify 定位结果不足、过期、含糊或需要验证具体实现时，才继续使用 `rg`、读取文件或运行命令。
- 不要为了普通小改动主动重建全量图谱；只有用户要求、图谱缺失且任务确实需要跨文件理解、或现有图谱明显过期时才考虑生成或更新。
- graphify 不接管 `.agent-memory`、task 状态流转或 artifact 写入；协议状态仍由 agent-protocol 流程统一管理。
- 在 `/ap:plan` 和复杂 `/ap:review` 中，可以把 graphify 检索摘要写入 `Source Context`，但必须压缩为必要背景。

## 协议触发边界

只有用户明确表达 agent-protocol 工作流意图时，才进入持久化 task / artifact 流程。

应触发协议流程的情况：

- 用户使用 `/ap:init`、`/ap:install`、`/ap:plan`、`/ap:review`、`/ap:import`、`/ap:execute`、`/ap:prune`、`/ap:reset`。
- 用户要求安装 `/ap` 命令或适配器。
- 用户要求生成可执行任务、交接 prompt、持久化计划、持久化 review 或 `.agent-memory` artifact。
- 用户明确说“按 agent-protocol”、“生成可执行任务”、“生成交接 prompt”、“导入执行 prompt”、“执行已有 task”等。

不应触发协议流程的情况：

- 普通代码 review、debug、重构、解释代码或直接实现需求。
- 用户明确说“直接改”、“不用创建任务”、“不用 protocol”。
- 仅出现 “plan”、“review”、“fix”、“debug” 等泛化词。

## 产物要求

协议产物应保存在项目根目录的 `.agent-memory/` 下：

```text
.agent-memory/tasks.json
.agent-memory/artifacts/plan/
.agent-memory/artifacts/review/
.agent-memory/artifacts/prompt/
.agent-memory/artifacts/done/
```

每个 `/ap:plan` 或 `/ap:review` 产生的可执行 task 都必须有对应 execution prompt artifact。prompt 至少包含：

- `Goal`
- `Priority`
- `Source Context`
- `Task Contract Snapshot`
- `Scope`
- `Problem`
- `Constraints`
- `Suggested Fix`
- `Validation`
- `Deliverable`
- `Command Hint`

`Priority` 只能使用 `high`、`medium`、`low`。

## 任务与 artifact 约束

- `tasks.json` 是任务索引和状态流转的唯一来源。
- artifact 保存完整 plan、review、prompt 或 done 记录；task 只保留摘要和引用。
- 新任务优先使用 `bug`、`feature`、`design` 类型；`review` 仅保留给旧 task 兼容。
- 新任务统一写 `created_by: "agent"`。
- 追加任务时不要覆盖已有任务。
- task 至少保留 `origin_command`、`origin_artifact_id`、`prompt_artifact_id`、`source_summary`、`acceptance`、`depends_on`。
- prompt 不得与 `task.spec` 冲突；若发现冲突，以 `task.spec` 为准并报告不一致。

## 实现与修改原则

- 先读相关代码和文档，再拆任务或实现，不要只根据需求文本空想。
- 优先沿用现有目录结构、命名方式、Markdown 风格和脚本约定。
- 修改范围保持最小，避免顺手重构无关内容。
- 对适配器变更，应分别检查 Claude、Mastra Code、Reasonix 的命令路径和语义一致性。
- 对脚本变更，应优先验证 `skills/agent-protocol/scripts/` 下的确定性脚本行为。
- 每次修改 `skills/` 下的协议内容、命令适配器、脚本或 bootstrap skill 时，必须同步递增 `skills/agent-protocol/SKILL.md` 的 `version`，并在相关修改提交后创建同名 git tag（例如 `version: v3.23` 对应 tag `v3.23`）。
- `skills/ap:init/SKILL.md` 和 `skills/ap:install/SKILL.md` 是主协议的 bootstrap 入口，也必须写入与 `skills/agent-protocol/SKILL.md` 完全一致的 `version`，避免入口 skill 与主协议版本不一致。
- 项目级个人状态和本地运行产物不应作为团队共享规范提交，除非用户明确要求。

## 验证要求

根据修改范围选择验证方式：

- 文档变更：检查链接、路径、命令名和协议术语是否一致。
- JSON schema 或任务结构变更：验证示例 task 与 schema 仍匹配。
- Shell 脚本变更：运行语法检查，并在可行时做最小端到端验证。
- 适配器命令变更：确认各 agent 入口仍能映射到同一协议语义，且不存在已移除的旧 fix 入口。

最终回复需要说明做了哪些文件修改，以及执行过哪些验证；如果未运行验证，也要明确说明。
