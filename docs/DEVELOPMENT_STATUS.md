# 开发状态

更新时间：2026-10-06（Asia/Shanghai）。

目标：A 版 ZqinKing + LiBwrt。用户最新要求取消含 PassWall 的两条构建、移除 PassWall 1/2 与专用核心、公开两库并重新编译；两路线独立并行。

已完成：原生接入审计；新增独立应用 overlay、候选来源清单（38 个 Git 修订 + Mihomo）、输入预检脚本、核心下载校验脚本、首次启动关闭服务脚本和手动准备 Actions。原生 config_preview、配置合并/增删/保护检查、目标修改拒绝检查、Bash/ShellCheck/actionlint 通过。ARM64 Mihomo SHA256/ELF 校验通过。作者 build.sh/wrt_core 未改。

云端准备 [Run 37316216811](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37316216811) 成功；已下载证据核对，Linux/本地规范化配置输入、原生 Git blob 摘要和核心摘要一致，保护差异为零。

本轮新增：公开前完成本地 Git 全部历史的凭据特征和敏感文件名检查，仓库已设 Public；取源锁/适配器、原生完整更新阶段入口、新增应用及首启/核心集成、真实 defconfig 门槛、分阶段检查点与编译/镜像校验 Actions 已接入。Bash/ShellCheck/actionlint 和原生输入预检通过。

最新真实预检 [Run 37324802148](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37324802148) 成功，框架 f9b26a7；已下载证据核对：九个 feeds 与锁一致，原生/定制平台源码相同，受保护配置差异为空，block-mount/fstools 保留，OAF 后端排除。最终配置 SHA256 为 7dc041d8e28db33c85ddbce2e52ab1dc5189f075bcb8ba54792b76120f740b8b。详见 [预检记录](validation/preview-37324802148.json)。

旧正式构建 [Run 37325796881](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37325796881) 已按用户要求取消，无固件产物。此前预检/配置摘要属于含 PassWall 的旧配置，不能作为本轮的有效预检或恢复输入。

本轮已调整：应用 overlay 排除 PassWall 1/2、Xray、Sing-box、Shadowsocks Rust 等专用核心；删除独立 Rust 编译任务；首启脚本只关闭 OpenClash 与 Docker；配置/镜像检查拒绝 PassWall 残留，并核对选中包的 Rust host 依赖。当前待新版真实云端预检。

仓库：[zhaomeeng/Athena-LiBwrt](https://github.com/zhaomeeng/Athena-LiBwrt)，main。

下一步：新版真实预检通过后立即重新编译，工具链/内核、软件包、镜像三段分别限四小时，预留启动、恢复和保存检查点时间。若原生底层修正失效或受保护配置改变，停止报告。B 已取消旧构建、公开并按同一应用需求重编，底层保持独立。

关键记录：[BUILD.md](BUILD.md)、[PREPARATION.md](PREPARATION.md)、[BASELINE.md](BASELINE.md)、[REQUIREMENTS.md](REQUIREMENTS.md)。
