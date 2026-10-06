# 开发状态

更新时间：2026-10-06（Asia/Shanghai）。

当前状态：[Run 37397399906](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37397399906)（构建框架 efde7d2）工具链/软件包/镜像编译、根文件系统验收和固件 artifact 上传全部成功；镜像公钥一致，12 个软件包索引签名通过，底层保护差异为空。仅 Release 上传零字节 native-source.diff 时失败。本轮已修复上传流程，原 Actions 产物保持不变，正在下载、校验并补发同一次构建的 Release，不重新编译。设备验证尚未完成。

目标：A 版 ZqinKing + LiBwrt。用户最新要求取消含 PassWall 的两条构建、移除 PassWall 1/2 与专用核心、公开两库并重新编译；两路线独立并行。

已完成：原生接入审计；新增独立应用 overlay、候选来源清单（38 个 Git 修订 + Mihomo）、输入预检脚本、核心下载校验脚本、首次启动关闭服务脚本和手动准备 Actions。原生 config_preview、配置合并/增删/保护检查、目标修改拒绝检查、Bash/ShellCheck/actionlint 通过。ARM64 Mihomo SHA256/ELF 校验通过。作者 build.sh/wrt_core 未改。

云端准备 [Run 37316216811](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37316216811) 成功；已下载证据核对，Linux/本地规范化配置输入、原生 Git blob 摘要和核心摘要一致，保护差异为零。

本轮新增：公开前完成本地 Git 全部历史的凭据特征和敏感文件名检查，仓库已设 Public；取源锁/适配器、原生完整更新阶段入口、新增应用及首启/核心集成、真实 defconfig 门槛、分阶段检查点与编译/镜像校验 Actions 已接入。Bash/ShellCheck/actionlint 和原生输入预检通过。

最新无 PassWall 真实预检 [Run 37336977204](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37336977204) 成功，框架 85d4788；已下载证据核对：原生/定制平台源码相同，受保护配置差异为空，选中软件包的 Rust host 依赖为空，PassWall 1/2、Xray、Sing-box、Shadowsocks Rust 与 Ruby YJIT 均未启用。最终配置 SHA256 为 ea1c79fc6d216cba35b9f2505e65c152a9a2f277ff5fc1bbf12906163af55d1c。详见 [预检记录](validation/preview-37336977204.json)。

旧正式构建 [Run 37325796881](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37325796881) 已按用户要求取消，无固件产物。此前预检/配置摘要属于含 PassWall 的旧配置，不能作为本轮的有效预检或恢复输入。

本轮已调整：应用 overlay 排除 PassWall 1/2、Xray、Sing-box、Shadowsocks Rust 等专用核心；关闭 Ruby 可选 YJIT，保留 OpenClash 所需 Ruby；删除独立 Rust 编译任务；首启脚本只关闭 OpenClash 与 Docker。仓库为 Public。[Run 37338264335](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37338264335) 工具链/软件包成功，镜像阶段因检查点未传递 key-build 而失败，未发布固件；三次源树恢复和原生保护比较通过。已修复最终阶段用原生目标重建 base-files/密钥，增加镜像公钥与软件包索引签名一致性检查，并纠正 IPQ6018 分段固件检查。详见 BUILD_ISSUES.md。Bash/ShellCheck/actionlint/差异检查通过，待修复后新正式运行。

仓库：[zhaomeeng/Athena-LiBwrt](https://github.com/zhaomeeng/Athena-LiBwrt)，main。

下一步：完成本次 Release 补发并核对远端资产；下载后在刷机电脑再次校验 SHA-256，按 BUILD.md/REQUIREMENTS.md 执行实机启动、NSS、有线和 80/160MHz 验证。A/B 底层保持独立；本轮只处理 A 的上传与交付。

关键记录：[BUILD.md](BUILD.md)、[PREPARATION.md](PREPARATION.md)、[BASELINE.md](BASELINE.md)、[REQUIREMENTS.md](REQUIREMENTS.md)。
