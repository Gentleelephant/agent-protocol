# agent-protocol

一个围绕 4 个核心命令组织的 agent 协议：

- `/ap:plan`：根据用户需求和项目代码，生成开发计划和可执行 prompt
- `/ap:review`：review 代码，输出 review 结果和修复 prompt
- `/ap:execute`：执行 `/ap:plan` 生成的 prompt
- `/ap:fix`：执行 `/ap:review` 生成的 prompt

默认是单 agent 工作流。同一个 agent 可以从分析一直做到执行和验收。

对于不支持子命令的 agent，例如 Codex，也必须支持。做法不是依赖 `/ap:` 语法，而是把这些命令视为自然语言意图：

- “根据这个需求结合项目代码整理开发计划” = `/ap:plan`
- “review 这段代码并给出修复 prompt” = `/ap:review`
- “执行刚才 plan 产出的 prompt” = `/ap:execute`
- “执行刚才 review 产出的修复 prompt” = `/ap:fix`

## 核心结构

主线只有两条：

1. 需求实现链路：`plan -> execute`
2. 代码修复链路：`review -> fix`

无子命令兼容规则：

- 支持 `/ap:` 子命令的 agent，优先用子命令
- 不支持 `/ap:` 子命令的 agent，必须通过自然语言完成同样效果
- 无论走哪种入口，输出物和 prompt 质量要求必须一致

可选初始化命令：

- `/ap:init`：初始化本地协议目录

## 输出物

协议对外的关键不是内部 task 记录，而是可直接执行的 prompt。

生成位置：

```text
.agent-memory/tasks.json
.agent-memory/artifacts/plan/
.agent-memory/artifacts/review/
.agent-memory/artifacts/prompt/
```

规则：

- `/ap:plan` 为每个开发任务生成一个执行 prompt
- `/ap:review` 为每个问题生成一个修复 prompt
- `/ap:execute` 和 `/ap:fix` 优先读取关联 prompt，并在执行后自动完成验证与完成记录
- 协议内部会用 `tasks.json` 保存状态；对使用者来说，真正需要关注的是 prompt 内容

## 四个核心命令

### `/ap:plan`

输入：用户给出的需求、目标或设计意图。
行为：结合项目代码、现有结构、依赖和边界，拆成开发任务，并生成指导其他 agent 执行的 prompt。

自然语言等价触发：

- “帮我根据这个需求整理开发计划”
- “结合当前代码拆解实现方案”
- “给我一组可以让别的 agent 直接执行的开发 prompt”

`plan` 产物必须包含：

- 任务标题
- 优先级
- 背景和目标
- 明确范围
- 建议实现方式
- 验收标准
- 推荐执行命令，通常是 `/ap:execute <plan-prompt>`

### `/ap:review`

输入：代码范围、模块、最近改动或整个项目。
行为：输出 review 结果，并为每个明确问题生成修复 prompt。

自然语言等价触发：

- “review 这段代码”
- “检查这个模块有没有问题，并给出修复 prompt”
- “审查最近改动并整理可执行修复项”

`review` 产物必须包含：

- 问题描述
- 影响范围
- 风险级别
- 复现或观察依据
- 修复建议
- 验收方式
- 推荐执行命令，通常是 `/ap:fix <review-prompt>`

### `/ap:execute`

输入：`plan` 生成的 prompt。
行为：读取 prompt，并按约束实现需求，不扩散修改范围。

自然语言等价触发：

- “执行刚才 plan 生成的第 2 条 prompt”
- “按照这个开发 prompt 去实现”
- “根据这个开发 prompt 继续做代码实现”

### `/ap:fix`

输入：`review` 生成的 prompt。
行为：读取 prompt，针对问题修复，不顺手做无关重构。

自然语言等价触发：

- “修复刚才 review 的第 1 个问题”
- “按照这个修复 prompt 改代码”
- “执行这条 review 修复建议”

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

每个执行 prompt 至少包含：

- `Goal`
- `Priority`
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

- `Priority` 只能用 `high` / `medium` / `low`
- `Scope` 必须尽量落到具体文件、目录、模块、接口
- `Constraints` 必须写出禁止项
- `Suggested Fix` 必须优先写推荐方案，避免给一堆无排序选项
- `Validation` 必须写具体命令、测试点或验收现象

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

## 初始化

初始化：

```text
/ap:init
```

兼容旧参数：

```text
/ap:init planner="Claude Code" executor="Mastra Code"
```

这两个参数只作为兼容信息保留，不参与门禁。

## 说明

- `tasks.json` 是协议内部状态唯一来源
- `.agent-memory/artifacts/prompt/` 是给 agent 直接执行的核心输出
- 如果 prompt 和内部 `task.spec` 冲突，以 `task.spec` 为准
- 不支持 `/ap:` 子命令的 agent 也必须通过自然语言执行同样工作流
- 协议公开接口默认只保留 `plan / review / execute / fix`，其余步骤由执行流程自动完成
