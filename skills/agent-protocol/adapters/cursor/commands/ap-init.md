# /ap-init

Cursor command equivalent of `/ap:init`.

初始化项目级个人协议状态。此命令只初始化 `.agent-memory/`，不安装命令适配器。

## 工作流

1. 读取 `.agent-memory/agent-protocol.md`（如存在）。
2. 按缺失优先原则创建；若文件或目录已存在则跳过：
   - `.agent-memory/agent-protocol.md`
   - `.agent-memory/tasks.json`（仅缺失时创建 `{"tasks": []}`）
   - `.agent-memory/artifacts/` 及其 `review`、`plan`、`prompt`、`done` 子目录
3. 创建本地入口文件：
   - `CLAUDE.local.md`
   - `.mastracode/AGENTS.md`
4. Git 仓库下更新 `.git/info/exclude` 忽略上述文件和 `.agent-memory/`。
5. 不修改团队共享的 `AGENTS.md` 或 `CLAUDE.md`。
6. 如需安装命令适配器，必须单独使用 `/ap-install`。
