# Agent Protocol Reference

## 角色分工

- **Planner**：负责分析、设计、review、创建 pending task、验收 done task。
- **Executor**：负责认领 pending task、实现或修复、更新任务状态。

## 共享记忆位置

项目根目录下的 `.agent-memory/tasks.json`

项目角色绑定位置：

```text
.agent-memory/agent-protocol.md
```

## 任务类型

- `review`：代码审查，Planner 发现问题
- `feature`：新功能，Planner 提出方案
- `design`：架构设计，Planner 提出方案
- `bug`：缺陷修复

## 任务结构（JSON）

```json
{
  "id": "task-001",
  "type": "review|feature|design|bug",
  "created_by": "planner",
  "status": "pending|in_progress|done|verified",
  "title": "简短描述",
  "context": "背景和原因",
  "spec": "具体方案或问题描述（Planner 填写）",
  "implementation_notes": "实现备注（Executor 填写）",
  "created_at": "",
  "updated_at": ""
}
```

## 状态流转

pending → in_progress → done → verified

（Planner 写入）  （Executor 认领） （Executor 完成） （Planner 验收）

辅助状态：

- `blocked`：Executor 暂时不能继续，需要用户输入、外部依赖、凭据或其他 task。
- `cancelled`：Planner 判断任务不再需要。

验证未通过时，Planner 将 `done` 退回 `in_progress`，并在 `implementation_notes` 中补充反馈。

## 优先级

任务可以包含可选字段：

```json
"priority": "high|medium|low"
```

Executor 默认先处理 `high`，再处理 `medium`，最后处理 `low`。同优先级按 `created_at` 升序处理。

## 规则

- Planner 只写 pending 状态，不修改 Executor 的字段
- Executor 只改 status / implementation_notes，不修改 spec
- 追加任务，不覆盖整个文件
- 验收通过后只有 Planner 可以把 done 改为 verified
- 项目级个人配置不提交到团队仓库

## 异常恢复

- `tasks.json` 缺失：创建 `{"tasks": []}`。
- `tasks.json` 非法：停止副作用操作，说明需要修复的位置。
- task id 有间断：从最大编号继续递增。
- 当前 agent 与项目角色绑定不一致：按项目绑定拒绝副作用命令，并提示应该使用哪个 agent。
