# Agent 协作协议 v1.0

## 角色分工

- **Planner**（默认 Codex，可配置）：负责分析、设计、review，输出任务
- **Executor**（默认 Claude Code，可配置）：负责实现、修复，更新任务状态

## 共享记忆位置

项目根目录下的 `.agent-memory/tasks.json`

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

## 规则

- Planner 只写 pending 状态，不修改 Executor 的字段
- Executor 只改 status / implementation_notes，不修改 spec
- 追加任务，不覆盖整个文件
