---
name: ap:install
description: "Install or refresh agent-protocol command adapters only. Any agent."
argument-hint: "[--agent all|claude|mastracode|mimocode|reasonix] [--scope project|user]"
---

# /ap:install

安装或刷新命令适配器。此命令只复制命令文件并清理已废弃的旧 fix 入口，不初始化 `.agent-memory`，不创建 task，不修改业务代码。

## 工作流

1. 检测 `--agent`：`all`、`claude`、`mastracode`、`mimocode`、`reasonix`，默认 `all`。
2. 检测 `--scope`：`project` 或 `user`，默认 `project`。
3. 优先运行 `skills/agent-protocol/scripts/install-commands.sh`，传入相同参数。
4. 对协议管理的命令文件：缺失则创建，内容不同则覆盖更新，内容相同则跳过写入。
5. 报告安装位置、已创建文件、已更新文件、已是最新的文件和已删除的旧 fix 文件。
