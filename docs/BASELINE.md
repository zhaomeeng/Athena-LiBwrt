# A版接入审计

检查日期：2026-10-05（Asia/Shanghai）。实施顺序遵循用户要求，B 版完成后再正式调整和构建 A 版。

- 框架：ZqinKing/wrt_release，main，提交 `4bf1cc018f8f1f08a0e1564f1cd16a38ccb004bc`。
- 设备配置：`wrt_core/compilecfg/jdcloud_ipq60xx_libwrt.ini` 与同名 deconfig。
- 作者指定源码：`LiBwrt/openwrt-6.x`，分支 `25.12-nss`。检查时 HEAD `3a3d0b08595530070ad9cd8a20c0ae4ea3e77f70`，正式准备时需重新核对并锁定。
- 默认片段：`nss,docker_deps,proxy`，已实际运行 `./build.sh jdcloud_ipq60xx_libwrt config_preview` 验证组合顺序。
- 最近对应公开发布：`26.07.20_17.13.36_jdcloud_ipq60xx_libwrt`，内核 6.12.94，已发布雅典娜 Factory/Sysupgrade。该发布不能证明 10 月源码仍能使用相同应用组合编译。

## 原生配置中的设备差异

作者同时构建亚瑟、雅典娜、太乙和京东云 AX5。雅典娜专用软件包字符串已包含 QCN9074 DDWRT、kmod-ath11k-pci 和 Athena LED。全局 `m` 项通过设备选择进入雅典娜镜像，精简时不能误删设备包字符串。

## 继承脚本需要注意的事实

作者 `update.sh` 原本就调用 ath11k 固件、NSS pbuf/affinity、默认网络、Netfilter 和 Docker nftables 兼容修正。这些是作者框架的既有行为，不能当作本轮新增优化。

其中 `wrt_core/modules/target_fixes.sh:update_ath11k_fw` 原本从 VIKINGYFY/immortalwrt main 读取固件 Makefile，但主体源码仍是 LiBwrt。这是上游已有依赖；本轮尚未修改或执行该底层修正。后续需记录固定来源，并以同一作者处理后的基线与应用调整结果比较。若上游修正因当前源码变化而失败，按用户要求停止并报告，不自行移植或重做驱动。

原框架还默认更新/校验多个待删除应用的源码路径（PassWall1、MosDNS、AdGuardHome、EasyTier、iStore 等）。仅修改 CONFIG 不一定能解除源码拉取/路径检查依赖；正式实施应在应用层同步调整这些阶段，并保留所有底层阶段。

## 待实施应用增量

保留 Firewall/Package Manager/TTYD/AutoReboot/eMMC Health/Lucky/UPnP/WOL/DiskMan/Samba4/Athena LED 和 USB 基础。

删除 PassWall1/2、AdGuardHome、MosDNS、SmartDNS、EasyTier、OAF、PBR、SQM、vlmcsd、QuickStart、Store/iStoreX、QuickFile；添加 OpenClash、Aurora Theme/Config、Docker/dockerd 与当前体系必要依赖。首次启动关闭 OpenClash 及 Docker；原始需求中的 PassWall2 已按用户最新指令移除。

必须先运行 config_preview 与真实 defconfig，再验证设备、无线、NSS、USB/eMMC、LuCI、Firewall，之后才正式编译。
