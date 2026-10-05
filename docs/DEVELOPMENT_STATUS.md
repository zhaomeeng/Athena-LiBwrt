# 开发状态

更新时间：2026-10-05 23:49（Asia/Shanghai）。

目标：A 版 ZqinKing + LiBwrt。用户本轮明确要求公开 A 并推进至正式编译，取消此前等待 B 成功的顺序限制；两路线保持独立。

已完成：原生接入审计；新增独立应用 overlay、候选来源清单（38 个 Git 修订 + Mihomo）、输入预检脚本、核心下载校验脚本、首次启动关闭服务脚本和手动准备 Actions。原生 config_preview、配置合并/增删/保护检查、目标修改拒绝检查、Bash/ShellCheck/actionlint 通过。ARM64 Mihomo SHA256/ELF 校验通过。作者 build.sh/wrt_core 未改。

云端准备 [Run 37316216811](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37316216811) 成功；已下载证据核对，Linux/本地规范化配置输入、原生 Git blob 摘要和核心摘要一致，保护差异为零。

本轮新增：公开前完成本地 Git 全部历史的凭据特征和敏感文件名检查，仓库已设 Public；取源锁/适配器、原生完整更新阶段入口、新增应用及首启/核心集成、真实 defconfig 门槛、分阶段检查点与编译/镜像校验 Actions 已接入。Bash/ShellCheck/actionlint 和原生输入预检通过。

最新真实预检 [Run 37324802148](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37324802148) 成功，框架 f9b26a7；已下载证据核对：九个 feeds 与锁一致，原生/定制平台源码相同，受保护配置差异为空，block-mount/fstools 保留，OAF 后端排除。最终配置 SHA256 为 7dc041d8e28db33c85ddbce2e52ab1dc5189f075bcb8ba54792b76120f740b8b。详见 [预检记录](validation/preview-37324802148.json)。

正式构建 [Run 37325796881](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37325796881) 已进入工具链编译，固定框架 f9b26a7，preview=false。准备任务 23:44:04 成功，源码下载完成并上传约 1.6 GB 检查点；下载证据中最终配置与预检摘要相同，受保护差异为空。工具链任务 23:48:39 完成检查点恢复/校验并开始编译。尚未生成 A 版固件，四个编译阶段及镜像验证仍待完成。详见 [本轮运行快照](validation/build-37325796881-start.json)。

仓库：[zhaomeeng/Athena-LiBwrt](https://github.com/zhaomeeng/Athena-LiBwrt)，main。

下一步：用户下次要求检查时读取正式构建最新状态，必要时诊断失败并从有效检查点恢复；不进行后台持续轮询。工具链/内核、Rust、软件包、镜像四段分别限编译四小时，预留两小时用于运行器启动、恢复和保存诊断/检查点。若原生底层修正失效或受保护配置改变，停止报告。B 版本轮较早只读检查处于 Rust 阶段，该状态可能已变化，本轮不更改它。

关键记录：[BUILD.md](BUILD.md)、[PREPARATION.md](PREPARATION.md)、[BASELINE.md](BASELINE.md)、[REQUIREMENTS.md](REQUIREMENTS.md)。
