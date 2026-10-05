# 开发状态

更新时间：2026-10-05（Asia/Shanghai）。

目标：A 版 ZqinKing + LiBwrt；用户已要求在等待 B 版时先做 A 版准备，正式编译仍在 B 版成功后进行。

已完成：原生接入审计；新增独立应用 overlay、候选来源清单（38 个 Git 修订 + Mihomo）、输入预检脚本、核心下载校验脚本、首次启动关闭服务脚本和手动准备 Actions。原生 config_preview、配置合并/增删/保护检查、目标修改拒绝检查、Bash/ShellCheck/actionlint 通过。ARM64 Mihomo SHA256/ELF 校验通过。作者 build.sh/wrt_core 未改。

云端准备 [Run 37316216811](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37316216811) 成功；已下载证据核对，Linux/本地规范化配置输入、原生 Git blob 摘要和核心摘要一致，保护差异为零。

尚未完成：将候选版本锁接入原生取源流程、应用源码阶段/重复定义处理、首次启动和核心镜像集成、真实 baseline/custom defconfig、正式构建 Actions、完整编译与设备测试。当前 overlay 仅通过输入检查，不能视为已生成最终 .config。

仓库：[zhaomeeng/Athena-LiBwrt](https://github.com/zhaomeeng/Athena-LiBwrt)，main。

依赖进度：B 版第三次正式 [Run 37297257083](https://github.com/zhaomeeng/Athena-VIKINGYFY/actions/runs/37297257083) 的工具链/内核阶段已成功，Rust 阶段仍在编译（本轮只读快照）；尚无新固件。下一步：接入 A 版原生取源锁与应用源码调整，运行真实 defconfig；B 版成功且 A 版全部门槛通过后正式编译。若现有底层修正失效，停止报告。

关键记录：[PREPARATION.md](PREPARATION.md)、[BASELINE.md](BASELINE.md)、[REQUIREMENTS.md](REQUIREMENTS.md)。
