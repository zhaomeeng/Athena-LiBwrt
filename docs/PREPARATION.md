# A 版编译准备

日期：2026-10-05，Asia/Shanghai。用户已明确要求在等待 B 版时先准备 A 版；正式固件编译仍在 B 版成功后进行。

## 本轮可检查的结果

- 新建 `config/athena-apps.config`，最后覆盖作者的设备配置、compile_base、nss、docker_deps、proxy。按要求精简应用，选择 OpenClash、PassWall2、Aurora Theme/Config、Docker/dockerd/containerd/runc 和作者已有 Dockerman。
- 作者 `build.sh`、`wrt_core/` 全部保持原样。保留四个设备、雅典娜 QCN9074/DDWRT 与 Athena LED 的设备包字符串；新增 Aurora，保留作者主题及默认设置。
- `scripts/athena-preview.sh` 实际通过原生 config_preview、末次赋值合并、应用选择和排除检查；目标/内核/NSS/无线/全部 kmod/USB/eMMC/防火墙输入差异为空。注入 TARGET 修改的拒绝检查通过。证据记录在 [preparation-2026-10-05.json](validation/preparation-2026-10-05.json)。
- 查询并记录 38 个 Git 候选修订以及一个 Mihomo 二进制来源。原生更新脚本尚未消费此清单，不能称为已经实现完整版本锁。
- 在固定提交上读取 18 个包/设备/配置文件，记录 SHA256；OpenClash 0.47.156、PassWall2 26.10.1-2、Aurora 1.4.0/配置 1.2.5、Docker CLI/dockerd 29.6.1 的定义存在。此检查没有验证完整依赖树的兼容性。
- 下载官方 Mihomo v1.19.32 ARM64 核心，压缩包 SHA256 与官方资产摘要一致，解压结果为 AArch64 ELF64；尚未装入镜像或在路由器执行。
- `files/etc/uci-defaults/zz-athena-services` 在应用默认配置脚本之后执行，关闭两个代理的 UCI 开关并禁止两代理及 dockerd 自启。文件已准备，待镜像集成和实际验证。
- 新建仅手动触发的 `ATHENA-PREP.yml`，检查脚本、配置输入和核心摘要，上传证据；没有 feeds/defconfig/编译/发布步骤。Bash、ShellCheck 和 actionlint 本地检查通过。
- 云端 [Run 37316216811](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37316216811) 全部成功（21:21:54–21:22:20，Asia/Shanghai）。已下载证据，Linux 与本地两份配置输入 SHA256 完全一致，原生 Git blob 和核心摘要一致，两类保护差异均为零。成功结果仅对应准备工作范围。

## 复核命令

在仓库根目录，Git Bash 或 Linux Bash：

```bash
bash scripts/athena-preview.sh
bash scripts/athena-core.sh
```

本地证据与核心位于忽略的 `audit/`。规范化配置输入的 SHA256 不受 Windows CRLF 转换影响；原生输入的摘要取自固定框架提交的 Git blob。下载核心时先校验压缩包，再校验 ELF 头。

## 已查明的集成依赖

| 范围 | 后续接入方式/限制 |
| --- | --- |
| 作者配置组合 | 保持 nss,docker_deps,proxy；最后应用本路线 overlay，不能调用原生 normal/debug 后再任由其重新覆盖配置。 |
| QuickFile | 原生 build.sh 在 QuickFile=y 时删除 LuCI 的 luci-light 依赖。定制配置须在该判断前生效；保留原生 uhttpd/LuCI 的可用入口。 |
| 删除应用的源码 | custom_feed 的必需目录检查及 verify 模块依然要求 PW1、MosDNS、EasyTier、QuickStart/Store 等。接入时同步调整应用取源/检查，保持底层阶段顺序。 |
| 新增应用 | 从清单中的固定提交接入官方 OpenClash、PassWall2 和两项 Aurora；解决原 custom_feed 中 OpenClash 的重复定义。不能靠 CONFIG=y 假定软件包已安装。 |
| OpenClash | 官方 LuCI 包不带代理核心；将已验证 clash_meta 安装到镜像 /etc/openclash/core/，保留执行权限并核对最终根文件系统。 |
| PassWall2 首启 | 固定提交中 /etc/config/passwall2 由 luci-app-passwall2 的 uci-defaults 脚本从 0_default_config 生成；zz-athena-services 必须在它之后。 |
| 作者取源锁 | 接入 source-candidates.tsv 中的源仓库/feeds/自定义应用，以及原生 raw 下载。删除 QuickStart 后去掉其浮动 gist 下载；记录 geoip 等数据资产及摘要。 |
| 原生无线处理 | LiBwrt 原始 Makefile 提供普通 QCN9074，作者原有 update_ath11k_fw 换入 DDWRT 定义。已核对其候选固定来源包含 qcn9074-ddwrt；仍须执行同一原生处理后的基线/定制 defconfig 比较。不得自行改无线实现。 |
| 原生软件源 | 作者 install_opkg_distfeeds 写入 24.10-SNAPSHOT 软件源；当前源码分支为 25.12-nss。暂未改动，正式准备时核对 ABI 与包管理器来源，避免用错误版本软件源补依赖。 |

## 进入正式编译前的门槛

1. 在同一固定源码/feeds 和作者处理阶段中分别解析原版与定制 `make defconfig`，保存最终配置与差异；输入预检不能替代该步骤。
2. 验证 RE-CS-02、NSS、ath11k、QCN9074、USB/eMMC、LuCI/Firewall；必要应用必须实际进入雅典娜设备包集合，排除应用不能回选。
3. 若底层失效或需要独立改 NSS/无线/DTS/Firewall 核心，停止报告；仅在这些门槛通过且 B 版成功后启动正式 A 版构建。
4. 固件完成后检查 Factory/Sysupgrade、manifest/packages、最终 .config、来源/差异、核心与首次启动关闭脚本，以及 SHA256；设备稳定性仍需用户实机验证。

## 原始资料

包定义以候选清单中固定提交读取，链接为其上游：[OpenClash](https://github.com/vernesong/OpenClash)、[PassWall2](https://github.com/Openwrt-Passwall/openwrt-passwall2)、[Aurora](https://github.com/eamonxg/luci-theme-aurora)、[Aurora Config](https://github.com/eamonxg/luci-app-aurora-config)、[Mihomo v1.19.32](https://github.com/MetaCubeX/mihomo/releases/tag/v1.19.32)。完整候选修订见 `config/source-candidates.tsv`。
