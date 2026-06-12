# /ap:install

安装或刷新命令适配器。此命令只复制命令文件并清理已废弃的旧 fix 入口，不初始化 `.agent-memory`，不创建 task，不修改业务代码。

用户在调用本命令时传入的文本作为安装参数处理。

## 工作流

1. 检测 `--agent`：`all`、`claude`、`cursor`、`mastracode`、`mimocode`、`reasonix`，默认 `all`。
2. 检测 `--scope`：`project` 或 `user`，默认 `project`。
3. 如果 `.agent-memory/scripts/install-commands.sh` 存在，优先运行该项目本地脚本。
4. 否则再定位当前仓库根目录；不要假设当前工作目录就是仓库根目录。
5. 回退运行 `<repo-root>/skills/agent-protocol/scripts/install-commands.sh`，传入相同参数。
6. 对协议管理的命令文件：缺失则创建，内容不同则覆盖更新，内容相同则跳过写入。
7. 报告安装位置、已创建文件、已更新文件、已是最新的文件和已删除的旧 fix 文件。
