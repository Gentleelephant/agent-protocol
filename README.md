# agent-protocol

一个围绕单一职责命令组织，并提供 team orchestration 高阶入口的 agent 协议：

- `/ap:run`：主 agent 自动拆任务、生成子 agent 执行 prompt、编排开发、review 并最终 commit/push
- `/ap:plan`：根据用户需求和项目代码，生成开发计划和可执行 prompt
- `/ap:review`：review 代码，输出 review 结果和修复 prompt
- `/ap:import`：只把外部 execution prompt、prompt artifact、plan artifact 或 plan 文档归一化为 task / artifact，不执行代码
- `/ap:execute`：只执行已存在的 pending task，不创建 task，不接收直接 prompt 或 plan
- `/agent-protocol init`：只初始化 `.agent-memory` 本地协议状态
- `/agent-protocol install`：只安装或刷新项目级 / 用户级命令适配器
- `/ap:prune`：只清理已完成或已取消的历史 task 和对应历史 artifact
- `/ap:reset`：只重置本地 `.agent-memory` 状态

对于不支持子命令的 agent，例如 Codex，也必须支持。做法不是依赖 `/ap:` 语法，而是把这些命令视为自然语言意图：

- “按 agent-protocol 自动完成这个需求并提交” = `/ap:run`
- “按 agent-protocol 根据这个需求结合项目代码整理开发计划” = `/ap:plan`
- “按 agent-protocol review 这段代码并给出修复 prompt” = `/ap:review`
- “导入这个执行 prompt 并创建 task” = `/ap:import`
- “执行刚才 plan 产出的 task” = `/ap:execute`
- “执行刚才 review 产出的修复 task” = `/ap:execute`
- “按 agent-protocol 初始化本地协议状态” = `/agent-protocol init`
- “安装 agent-protocol 命令适配器” = `/agent-protocol install`
- “清理 .agent-memory 历史记录” = `/ap:prune`
- “重置 .agent-memory 本地状态” = `/ap:reset`

## 核心结构

主线分两层：

1. 高阶自动编排链路：`run`
2. 基础需求实现链路：`plan -> execute`
3. 基础代码修复链路：`review -> execute`
4. 基础外部交接链路：`import -> execute`

## 缓存与检索策略

协议要求把大模型缓存命中率作为核心约束：默认只读取当前命令需要的稳定入口文档、目标 task、目标 prompt 和必要源码，不批量展开历史 artifact。

如果项目中存在 `graphify-out/`，在 `/ap:plan` 或宽范围 `/ap:review` 中应优先用 graphify 图谱查询定位相关模块、文件和概念，再按需读取源码或文档确认事实。graphify 只作为检索索引，不接管 `.agent-memory` 状态流转。

对于复杂方案设计，可以使用 superpower 等外部 planning / reasoning skill 作为顾问，但最终输出必须归一化为当前协议的 plan/review/run artifact、task 和 execution prompt。外部 prompt 或 plan 文档只能通过 `/ap:import` 归一化；`/ap:execute` 不负责导入或创建 task，`/ap:run` 负责主 agent 编排。

无子命令兼容规则：

- 支持 `/ap:` 子命令的 agent，优先用子命令
- 不支持 `/ap:` 子命令的 agent，必须通过明确的 agent-protocol 自然语言意图完成同样效果
- 无论走哪种入口，输出物和 prompt 质量要求必须一致

初始化与安装入口：

- `/agent-protocol init`：初始化本地协议目录，不安装命令适配器
- `/agent-protocol install`：安装 Claude / Cursor / Mastra Code / MiMo Code / Reasonix 命令适配器；协议脚本优先使用项目下 `.agent-memory/scripts/`

执行方式说明：

- 顶层命令：直接使用 `/agent-protocol init` 或 `/agent-protocol install [--agent ...] [--scope ...]`
- 脚本阶段：需要确定性执行时，直接运行仓库里的 `scripts/init.sh` 或 `scripts/install-commands.sh`
- 安装完成后：其余功能通过已安装的 `/ap:*` 子命令提供；`init/install` 本身不作为安装后的 `/ap:` 子命令公开

仓库现在只保留一个顶层 skill：

- `skills/agent-protocol/SKILL.md`

它既是顶层命令入口，也是协议总规范与路由入口。初始化与安装通过 `/agent-protocol init` 和 `/agent-protocol install ...` 提供；其余 `/ap:run`、`/ap:plan`、`/ap:review`、`/ap:import`、`/ap:execute`、`/ap:prune`、`/ap:reset` 继续由安装后的命令适配器提供，命令级语义以 `skills/agent-protocol/adapters/*/commands/*` 为准。

## 输出物

协议对外的关键不是内部 task 记录，而是可直接执行的 prompt。

生成位置：

```text
.agent-memory/tasks.json
.agent-memory/artifacts/plan/
.agent-memory/artifacts/run/
.agent-memory/artifacts/review/
.agent-memory/artifacts/prompt/
```

规则：

- `/ap:run` 为一次自动编排生成 run artifact，并在需要时补齐或确认每个 task 的执行 prompt
- `/ap:plan` 为每个开发任务生成一个执行 prompt
- `/ap:review` 为每个问题生成一个修复 prompt
- `/ap:run`、`/ap:plan` 和 `/ap:review` 生成的编排记录、开发计划、review 结果和 prompt 必须持久化保存到 `.agent-memory/artifacts/`
- 不支持 `/ap:` 子命令的 agent 走自然语言等价流程时，也必须保存到同样的位置
- `/ap:import` 只导入外部 prompt / plan 并创建 task，不执行
- `/ap:execute` 只读取已存在 task 的关联 prompt，并在执行后自动完成验证与完成记录；它不是主 agent 的 team orchestration 入口
- 协议内部会用 `tasks.json` 保存状态；对使用者来说，真正需要关注的是 prompt 内容
- 新写入 artifact 的文件名必须使用 `<timestamp>__<artifact-kind>__<scope-token>.md`
- 其中 `timestamp` 必须是 UTC 基本格式 `YYYYMMDDTHHMMSSZ`，`artifact-kind` 只能是 `run|plan|review|prompt|done`
- `scope-token` 必须是小写 ASCII kebab-case；单 task 必须直接使用 `task-<number>`，多 task batch 使用 `tasks-<task-id>-<task-id>...`，纯范围场景使用 `scope-<kebab-slug>`
- 新写入 artifact 的 `artifact_id` 必须使用 `artifact-<artifact-kind>-<timestamp>-<scope-token>`
- 禁止在 artifact 文件名或 `artifact_id` 中使用下划线、空格、中文、camelCase 或直接拼接 `task.title`
- 历史 artifact 继续兼容读取；只要发生新写入、重写或补写，必须切换到上述统一命名

同时，task 本身也要带上最小但关键的来源索引，至少包括：

- `origin_command`
- `origin_artifact_id`
- `prompt_artifact_id`
- `source_summary`
- `acceptance`
- `depends_on`

命令边界是协议稳定性的硬约束：

- 主 agent 自动拆任务、委派、review 和 `commit/push` 只能由 `/ap:run` 完成
- 创建任务只能由 `/ap:plan`、`/ap:review`、`/ap:import` 完成，或由 `/ap:run` 在启动时按 `plan` 语义一次性创建
- 执行业务代码修改只能由 `/ap:execute` 完成；`/ap:run` 只负责编排与验收，不替代底层执行语义
- 初始化本地状态只能由 `/agent-protocol init` 完成
- 安装命令适配器只能由 `/agent-protocol install` 或 `install-commands.sh` 完成
- 清理历史只能由 `/ap:prune` 完成
- 重置状态只能由 `/ap:reset` 完成
- 不存在 fix 兼容命令；review 修复任务也必须通过 `/ap:execute <task-id>` 执行

## 命令

### `/ap:run`

输入：自然语言需求、`--all`、`--tasks task-001,task-002`，可选 `--origin review|plan|import|run`。不接收直接粘贴的 execution prompt、prompt artifact、plan artifact 或 plan 文档。
行为：作为 team orchestration 高阶入口，由主 agent 负责拆任务或读取既有 task、生成或确认 execution prompt、委派子 agent 开发、review 子 agent 结果，并在全部通过后统一 `commit` 与 `push`。如果最终没有形成主 agent 创建的 commit，则本次 `/ap:run` 不算成功完成。

自然语言等价触发：

- “按 agent-protocol 自动完成这个需求并提交”
- “按 agent-protocol 执行所有 task，主 agent review 后 push”
- “按 agent-protocol 把刚才 review 产出的 task 全部跑完”

`run` 产物必须包含：

- 编排摘要
- task 选择或拆分依据
- 每个 task 的 prompt 准备情况
- 子 agent 执行与主 agent review 结果
- 最终提交和推送结果
- 推荐恢复命令，例如 `/ap:execute <task-id>` 或 `/ap:run --all --origin review`
- 新写入 run artifact 的文件名和 `artifact_id` 必须遵守统一命名；对于自然语言需求，优先使用 `scope-<kebab-slug>`，不要把自由格式标题直接写进名字

### `/ap:plan`

输入：用户给出的需求、目标或设计意图。
行为：结合项目代码、现有结构、依赖和边界，拆成开发任务，并生成指导其他 agent 执行的 prompt。

自然语言等价触发：

- “按 agent-protocol 帮我根据这个需求整理开发计划”
- “按 agent-protocol 结合当前代码拆解实现方案”
- “给我一组可以让别的 agent 直接执行的开发 prompt 并持久化 task”

`plan` 产物必须包含：

- 任务标题
- 优先级
- 背景和目标
- 明确范围
- 建议实现方式
- 验收标准
- 推荐执行命令，必须是 `/ap:execute <task-id>`
- 新建 task 的 `title` 只作为人类可读摘要，不参与 `task.id`、artifact 文件名或 `artifact_id` 生成

### `/ap:review`

输入：代码范围、模块、最近改动或整个项目。
行为：输出 review 结果，并为每个明确问题生成修复 prompt。

自然语言等价触发：

- “按 agent-protocol review 这段代码”
- “按 agent-protocol 检查这个模块并生成修复 task”
- “审查最近改动并持久化可执行修复项”

`review` 产物必须包含：

- 问题描述
- 影响范围
- 风险级别
- 复现或观察依据
- 修复建议
- 验收方式
- 推荐执行命令，通常是 `/ap:execute <task-id>`

### `/ap:import`

输入：外部 execution prompt、prompt artifact、plan artifact 或 plan 文档。
行为：只把输入归一化为 `.agent-memory` 下的 task 和 artifact，不修改业务代码，不运行实现。

自然语言等价触发：

- “导入这个执行 prompt 并创建 task”
- “把这个 plan 文档转换成 agent-protocol task”
- “根据这个外部 prompt 生成可执行任务”

导入规则：

- 如果输入是 prompt artifact 或直接粘贴的 execution prompt，先匹配 `related_task_ids`；没有匹配 task 时保存 prompt artifact，并创建一个 pending task。
- 如果输入是 plan artifact 或直接粘贴的 plan 文档，先解析可执行项，保存 plan artifact，并为每个可执行项创建 task 和 execution prompt。
- 如果 plan 中包含多个可执行项，只创建或列出 task，不执行任何任务。
- 导入产生的新 task 使用 `origin_command: "import"`。

### `/ap:execute`

输入：已有 task id、`next`、`--all`，可选 `--origin review|plan|import|run`。不提供 `--one` 或 `--loop`；执行单个任务使用 `task-id` 或 `next`，批量执行使用 `--all`。
行为：只读取已存在 task、来源 artifact 和 prompt，并按约束实现需求或修复问题，不创建 task，不接收直接 prompt 或 plan，不扩散修改范围，不承担主 agent team orchestration 或自动 `commit/push`。

自然语言等价触发：

- “执行 task-001”
- “执行下一个 pending task”
- “执行所有 pending task”
- “执行刚才 review 生成的第 2 个 task”

执行规则：

- 只能选择 `pending` 或按恢复规则允许继续的既有 task。
- `task-id`、`next`、`--all` 是执行目标；`--origin` 只是来源过滤，不表示 task 类型。
- `/ap:execute` 是底层执行入口；需要主 agent 自动拆任务、委派、review 和提交时应使用 `/ap:run`。
- `--all` 是安全批处理，不是外部 supervisor，也不负责重启 agent。agent 会话中断时，下次再次运行 `/ap:execute --all` 继续按状态恢复。
- `--all` 每轮只认领一个 task；每轮开始前必须重新读取 `.agent-memory/tasks.json`，优先处理已有 `in_progress` task，再选择下一个匹配的 `pending` task。
- `--all` 串行执行，不并行执行；每个 task 必须独立读取 prompt、独立状态流转、独立写 completion artifact。
- 若 task 的 `depends_on` 尚未完成，跳过该 task 或标记为 `blocked` 并说明原因，不能强行执行。
- 批量执行中遇到实现失败、验证失败或 blocker 时，记录当前 task 结果并停止后续执行。
- 如果用户传入直接 prompt、直接 plan 或 artifact 内容，必须停止并要求先使用 `/ap:import`。
- 如果多个 task 匹配，按 `priority` high、medium、low 排序，同优先级按 `created_at` 升序。
- 真正开始实现前，被执行工作单元必须已有 task id、`prompt_artifact_id` 和正常状态流转记录。
- 新写入 completion artifact 时，文件名和 `artifact_id` 也必须遵守统一命名。

### `/agent-protocol init`

输入：无。
行为：只初始化 `.agent-memory/`、`tasks.json` 和 artifact 目录，不安装命令适配器，不创建业务 task。

触发方式：

- 顶层命令：`/agent-protocol init`
- 自然语言：例如“按 agent-protocol 初始化本地协议状态”
- 确定性脚本：

```bash
bash /Users/zhangpeng/GolandProjects/github.com/Gentleelephant/agent-protocol/skills/agent-protocol/scripts/init.sh --project
```

参数兼容：

- 顶层命令本身不要求业务参数
- 底层脚本参数保持不变，继续使用 `--project`

### `/agent-protocol install`

输入：`--agent all|claude|cursor|mastracode|mimocode|reasonix` 和 `--scope project|user`。
行为：只安装或刷新命令适配器，不初始化 `.agent-memory`，不创建 task。
刷新规则：对本协议管理的命令文件，如果目标文件不存在则创建；如果已存在且内容不同则覆盖更新；如果内容相同则跳过写入。

触发方式：

- 顶层命令：`/agent-protocol install [--agent ...] [--scope ...]`
- 自然语言：例如“按 agent-protocol 安装命令适配器”或“安装 agent-protocol 命令适配器”
- 确定性脚本：

```bash
bash /Users/zhangpeng/GolandProjects/github.com/Gentleelephant/agent-protocol/skills/agent-protocol/scripts/install-commands.sh
```

参数兼容：

- `--agent all|claude|cursor|mastracode|mimocode|reasonix`
- `--scope project|user`
- 与之前的安装脚本参数保持一致

### `/ap:prune`

输入：无。
行为：保留活动 task，删除 `done` / `cancelled` task 和仅被这些终态 task 引用的历史 artifact。
实现：优先运行 `.agent-memory/scripts/prune.sh`；项目本地脚本不可用时再回退到仓库里的 `skills/agent-protocol/scripts/prune.sh`，而不是由不同 agent 各自手写清理逻辑。

### `/ap:reset`

输入：无。
行为：保留 `.agent-memory/agent-protocol.md` 和目录结构，把 `tasks.json` 重置为 `{"tasks": []}` 并清空 artifact 子目录。

## Prompt 质量规则

这是协议里最重要的部分。

一个高质量 prompt 必须做到 4 件事：

1. 问题定义清楚
   不能写“优化这里”或“修一下这个逻辑”，必须写出当前行为、期望行为、风险或症状。

2. 边界清楚
   必须明确允许改哪些文件、模块、接口、测试；明确哪些内容不能动。

3. 指导性强
   不是只指出问题，还要给出建议修复路径、优先方案、兼容要求和验证方法。

4. 可验收
   必须给出测试、检查步骤或可观察的完成标准。

## Prompt 标准结构

本协议继续使用稳定的 Markdown 标题结构作为持久化 artifact 格式，而不是切换到 XML 或自由文本。原因是 OpenAI 更强调清晰的 section 组织，Anthropic 虽然推荐在复杂 prompt 中使用 XML 分隔内容，但当前项目的 execution prompt 首要目标是跨 agent 可移植、可 diff、可局部编辑、可缓存命中，因此固定标题的 Markdown 更适合作为统一规范。

每个执行 prompt 至少包含：

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

示例可参考：

- [plan-execution-prompt.example.md](/Users/zhangpeng/GolandProjects/github.com/Gentleelephant/agent-protocol/skills/agent-protocol/references/examples/plan-execution-prompt.example.md)
- [review-fix-prompt.example.md](/Users/zhangpeng/GolandProjects/github.com/Gentleelephant/agent-protocol/skills/agent-protocol/references/examples/review-fix-prompt.example.md)

补充要求：

- `Goal` 必须只描述一个主要结果；必要时可以顺带点明执行者角色，但不能把多个结果塞进同一 prompt
- `Priority` 只能用 `high` / `medium` / `low`
- `Source Context` 必须复制 review 结论或计划依据的关键摘要，并尽量包含证据锚点，例如文件、符号、测试名、报错、依赖关系；如果存在推断，应和已确认事实区分开
- `Task Contract Snapshot` 必须重述 task 的 `spec`、`acceptance` 和依赖信息；若 prompt 与 `task.spec` 有冲突，以 `task.spec` 为准
- `Scope` 必须尽量落到具体文件、目录、模块、接口；最好显式区分允许修改、按现有模式可连带修改、禁止修改
- `Problem` 必须同时写清当前行为、期望行为、证据和影响，不能只写“需要优化”或“逻辑有问题”
- `Constraints` 必须同时写出必须遵守的条件和明确禁止项，避免只写抽象话术，例如“尽量少改”
- `Suggested Fix` 必须优先写推荐方案，避免给一堆无排序选项；如果存在备选路径，要说明默认选择条件
- `Validation` 必须写具体命令、测试点或验收现象；若命令可能不存在，应说明最小替代验证方式和预期通过信号
- `Deliverable` 必须说明执行 agent 最终应交付什么，例如修改文件、测试结果摘要、`implementation_notes`、遗留风险或 blocker 说明
- `Command Hint` 只保留推荐的下一条协议命令，不要在这里重复正文说明
- prompt 必须自包含，执行 agent 不应被迫重新读取大段历史对话才能开工
- 标题顺序应保持稳定，避免无意义改写造成缓存失效

## Task 分类规则

`task.type` 表示任务性质，`origin_command` 表示任务来源。`/ap:execute --origin` 只过滤 `origin_command`，不要把它当作类型过滤器。

- `bug`：修复已存在错误、回归、风险、review finding 或行为校正。
- `feature`：新增或扩展用户可见能力、命令能力或产品行为。
- `design`：协议、架构、接口契约、文档规范、跨模块设计调整，或主要交付物是设计约束而非直接功能。
- `review`：仅兼容旧 task，新 task 不得使用。

`/ap:plan` 应在 `feature` 与 `design` 之间按主要交付物选择；`/ap:review` 产出的可执行问题默认使用 `bug`；`/ap:import` 必须根据输入内容推断 `bug`、`feature` 或 `design`，无法可靠判断时默认 `feature`，并在 `source_summary` 记录推断依据。

## Prompt 生成要求

### 对 `/ap:plan`

生成 prompt 时必须：

- 先读代码再拆任务，不能只按需求文本空想
- 优先沿用现有架构、命名、依赖和测试模式
- 把大需求拆成多个小 prompt，而不是一个大而模糊的 prompt
- 每个 prompt 只对应一个主要结果
- 标出任务之间的依赖和优先级

### 对 `/ap:review`

生成 prompt 时必须：

- 先给 review 结论，再决定是否需要生成修复 prompt
- 只有“可执行问题”才生成 prompt
- 每个 prompt 只处理一个独立问题，避免混合多个问题
- 明确这是 bug fix、风险修复，还是行为校正
- 如果问题信息不足，prompt 要写明需要先确认什么
- review 产出的新 task 应优先使用 `bug` 类型，而不是 `review`

## Prompt 优点与常见模糊点

当前协议已有的强项：

- 固定标题结构稳定，适合缓存、diff 和 artifact 持久化
- `Scope`、`Constraints`、`Validation`、`Deliverable` 已经比通用 prompt 模板更工程化
- `Task Contract Snapshot` 能把 task 约束显式复制进执行 prompt，减少执行期漂移
- `Command Hint` 让 handoff 路径明确，适合多 agent 串联

生成 prompt 时要避免的模糊点：

- 只写“优化”“修一下”“按现有模式处理”，但没有说当前错误、目标行为和影响
- `Source Context` 只有结论，没有证据锚点，导致执行 agent 需要重新猜原因
- `Scope` 写成“相关文件”或“必要模块”，没有明确允许改动边界
- `Constraints` 只写“不要大改”之类的抽象要求，没有写清禁止变更什么
- `Suggested Fix` 罗列多个方向但不指定默认推荐路径
- `Validation` 只写“跑测试”或“自行验证”，没有最小命令和通过信号

## 初始化

初始化：

```text
/agent-protocol init
```

执行后只初始化 `.agent-memory/` 本地状态，并同步项目本地脚本镜像到 `.agent-memory/scripts/`、命令适配器模板镜像到 `.agent-memory/adapters/`。命令适配器安装必须单独执行 `/agent-protocol install` 或安装脚本。

Claude Code 入口规则：

- `skills/agent-protocol/SKILL.md` 是唯一顶层 skill 入口
- 它直接承载 `/agent-protocol init` 和 `/agent-protocol install ...` 的顶层命令说明
- 其他 `/ap:run`、`/ap:plan`、`/ap:review`、`/ap:import`、`/ap:execute`、`/ap:prune`、`/ap:reset` 通过 `install-commands.sh` 安装到项目目录或用户目录
- 协议运行依赖脚本优先使用 `.agent-memory/scripts/`，不依赖 user scope 的脚本位置
- install 所需的命令模板优先使用 `.agent-memory/adapters/`，避免在其他项目里找不到 `skills/agent-protocol/adapters/`

脚本参数：

- `--project`：必填

幂等规则：

- 已存在的目录会跳过
- 已存在的文件会跳过
- 已存在的 `.agent-memory/tasks.json` 会保留
- `.agent-memory/scripts/init.sh`、`install-commands.sh`、`prune.sh` 会创建或更新
- `.agent-memory/adapters/` 会同步当前协议支持的命令模板

示例：

```bash
bash /Users/zhangpeng/GolandProjects/github.com/Gentleelephant/agent-protocol/skills/agent-protocol/scripts/init.sh --project
```

## 安装子命令

安装当前项目下的 Claude Code、Cursor、Mastra Code、MiMo Code 和 Reasonix 命令适配器：

```bash
bash /Users/zhangpeng/GolandProjects/github.com/Gentleelephant/agent-protocol/skills/agent-protocol/scripts/install-commands.sh
```

只安装 Claude Code：

```bash
bash /Users/zhangpeng/GolandProjects/github.com/Gentleelephant/agent-protocol/skills/agent-protocol/scripts/install-commands.sh --agent claude
```

只安装 Cursor：

```bash
bash /Users/zhangpeng/GolandProjects/github.com/Gentleelephant/agent-protocol/skills/agent-protocol/scripts/install-commands.sh --agent cursor
```

Cursor 自定义命令规则：

- 项目级命令写入 `.cursor/commands/*.md`
- 用户级命令写入 `~/.cursor/commands/*.md`
- 命令名由文件名决定，因此本仓库映射为 `/ap-run`、`/ap-plan`、`/ap-review`、`/ap-execute` 等等价命令
- 这是对协议 `/ap:run`、`/ap:plan`、`/ap:review`、`/ap:execute` 的 Cursor 适配，不改变协议语义

只安装 Mastra Code：

```bash
bash /Users/zhangpeng/GolandProjects/github.com/Gentleelephant/agent-protocol/skills/agent-protocol/scripts/install-commands.sh --agent mastracode
```

只安装 MiMo Code：

```bash
bash /Users/zhangpeng/GolandProjects/github.com/Gentleelephant/agent-protocol/skills/agent-protocol/scripts/install-commands.sh --agent mimocode
```

MiMo Code 自定义命令规则：

- 项目级命令写入 `.mimocode/commands/ap:*.md`
- 用户级命令写入 `~/.config/mimocode/commands/ap:*.md`
- 文件名即命令名，例如 `ap:plan.md` 对应 `/ap:plan`
- Markdown 文件正文就是 prompt 模板；需要参数的命令模板必须显式包含 `$ARGUMENTS`

只安装 Reasonix：

```bash
bash /Users/zhangpeng/GolandProjects/github.com/Gentleelephant/agent-protocol/skills/agent-protocol/scripts/install-commands.sh --agent reasonix
```

Reasonix 自定义命令规则：

- 项目级命令写入 `.reasonix/commands/ap/*.md`
- 用户级命令写入 `~/.config/reasonix/commands/ap/*.md`
- 子目录构成命名空间，例如 `ap/plan.md` 对应 `/ap:plan`
- Markdown 文件正文就是 prompt 模板；Reasonix 适配文件不包含 frontmatter

安装到用户级目录而不是项目目录：

```bash
bash /Users/zhangpeng/GolandProjects/github.com/Gentleelephant/agent-protocol/skills/agent-protocol/scripts/install-commands.sh --scope user
```

规则：

- 默认 `--agent all`
- 默认 `--scope project`
- `project` 会写入 `.claude/`、`.cursor/`、`.mastracode/`、`.mimocode/` 和 `.reasonix/`
- `user` 会写入 `~/.claude/`、`~/.cursor/`、`~/.mastracode/`、`~/.config/mimocode/` 和 `~/.config/reasonix/`
- 已存在的命令文件若内容不同会覆盖更新，内容相同则跳过
- 已安装的旧 fix 命令文件会被删除
- 这个安装动作只复制命令文件，不会重新初始化 `.agent-memory/`
- 如果由 agent 触发安装，不应直接执行 `./skills/agent-protocol/scripts/install-commands.sh`；必须先定位仓库根目录，再执行 `<repo-root>/skills/agent-protocol/scripts/install-commands.sh`
- 如果 `.agent-memory/scripts/install-commands.sh` 已存在，应优先执行该项目本地脚本，而不是依赖 user scope 脚本位置

## 说明

- `tasks.json` 是协议内部状态唯一来源
- `.agent-memory/artifacts/prompt/` 是给 agent 直接执行的核心输出
- `.agent-memory/artifacts/run/` 保存主 agent 的自动编排记录
- 如果 prompt 和内部 `task.spec` 冲突，以 `task.spec` 为准
- 不支持 `/ap:` 子命令的 agent 也必须通过明确自然语言意图执行同样工作流
- 协议公开接口收敛为 `run / plan / review / import / execute / prune / reset`，顶层命令 `/agent-protocol init` 与 `/agent-protocol install` 负责 bootstrap
