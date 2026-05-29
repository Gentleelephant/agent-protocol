---
name: ap:plan
description: "Analyze requirements and create feature/design tasks. Planner-only."
argument-hint: "[requirement]"
---

# /ap:plan

分析需求或架构，创建 feature/design task。省略 requirement 时从最近对话上下文提取。

## 工作流

1. 读取 `.agent-memory/agent-protocol.md` 确认角色匹配。
2. 加载 `.agent-memory/tasks.json`。
3. 分析需求，创建 task（type: `feature` 或 `design`），追加到 tasks 数组。
4. 设置 `status: "pending"`、`created_by: "planner"`，填充 `id`、`title`、`context`、`spec`。
5. 不修改业务代码。
