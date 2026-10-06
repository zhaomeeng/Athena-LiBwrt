# A 版构建记录

## 2026-10-06 固件通过验收，Release 拒绝零字节资产

[Run 37397399906](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37397399906) 所有编译阶段、镜像验收与固件 artifact 上传均成功；仅 Publish firmware release 在 11:08:09（Asia/Shanghai）失败。GitHub 上传 native-source.diff 返回 HTTP 400: Bad Content-Length，该文件正常为零字节。固件 artifact 11387975025 已保存，不需要重编。镜像公钥与构建公钥一致，12 个软件包索引签名全部通过，protected.diff/native-source.diff 均为空。

新增 scripts/athena-release-assets.sh：先校验原产物的 SHA256SUMS，再建立独立发布目录；非空文件保持原样，所有空诊断文件收入非空 empty-evidence.tar.gz，并为发布目录重新生成/验证 SHA256SUMS。原 Actions 产物不变。工作流调用同一脚本，Release 标签固定指向实际构建提交，补发不使用新的文档/修复提交冒充构建来源。Bash、ShellCheck、actionlint、有效产物准备及损坏哈希拒绝回归通过；现有固件补发结果见状态页和发布验证记录。

本地大文件传输反复中断后改为 GitHub 内部补发。初次补发 Run 37437284517 的 artifact/清单校验成功，但 GITHUB_TOKEN 在创建指向旧构建提交的 Release 时返回 HTTP 403；预建标签后仍被拒绝。使用已授权 CLI 创建原构建标签及无资产草稿，恢复工作流先核对标签，仅上传到空草稿并发布，不向 Actions 保存个人 Token。[Run 37437950779](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37437950779) 全部成功；Release athena-a-37397399906 的 46 个资产摘要与发布清单一致，标签为原构建 efde7d2。再次用实时 API 验证通过，固件/包未重新编译或修改。

## 2026-10-06 镜像阶段失败与签名修复

正式 [Run 37338264335](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37338264335) 于 02:38:32（Asia/Shanghai）失败。工具链、软件包任务及三次检查点恢复成功；镜像任务的 package/index 找不到 key-build，退出 2，未发布固件。不是超时或磁盘耗尽。最终配置仍为 ea1c79fc6d216cba35b9f2505e65c152a9a2f277ff5fc1bbf12906163af55d1c，protected.diff/native-source.diff/Rust 消费包均为空。

原因：检查点排除 key-build*，却保留 base-files 的配置标记和含旧公钥的打包结果；原生 Build/Configure 因已完成而不再生成密钥。修复为最终任务先运行原生 package/base-files/clean、package/base-files/compile，再执行完整构建，使新签名密钥与镜像内公钥一起更新。交付检查逐一验证软件包索引签名，并比较 Factory 镜像内的公钥。不传递私钥，不关闭签名，不修改原生源码/配置。

同时修复与 B 相同的 IPQ6018 文件名检查：固定固件修订 0c817c46568ef6871042c7e2efc95ac24a1f02e6 的 IPQ6018 使用 q6_fw.mdt、m3_fw.mdt 和分段文件，并无 amss.bin；QCN9074 仍使用 amss.bin。检查对应元数据、board-2.bin 和全部非空分段。依据为固定源码 package/firmware/ath11k-firmware/Makefile 与 laipeng668/ath11k-firmware-ddwrt 的对应 Git 树。无线包、驱动、NSS 与设备定义保持原样。

Bash、ShellCheck、actionlint、git diff --check 通过。修复后的真实密钥生成、镜像公钥及签名检查由新正式构建验证，当前不能宣称交付或实机验证成功。

Run 37335414789 的配置/保护比较通过，但检查器尚未接受合法条件名 PACKAGE_smartdns-ui（含连字符），已补齐。用该 Run 的实际 final.config/packageinfo 全量复核：有效 Rust 消费包为空，Ruby YJIT/smartdns-ui 未启用，protected.diff/native-source.diff 为空；配置 SHA256 ea1c79fc6d216cba35b9f2505e65c152a9a2f277ff5fc1bbf12906163af55d1c。之后重新运行完整 A 预检，未修改固件源配置。

依赖检查的条件解析曾把 python-setuptools-rust/host 的后缀误当作 rust/host，已改为精确匹配独立 Rust 目标；Ruby 选项未输出到最终配置时按禁用处理。用 B Run 37333460335 的真实配置/包元数据回归通过：现配置无有效 Rust 消费包，单独启用 YJIT 或 Shadowsocks Rust 均能检出。A Run 37333444831 在安装依赖阶段取消，以运行同一修正；未发生固件底层错误。

## 无 PassWall 首次预检：Ruby YJIT 的额外 Rust 依赖

Run 37331824442 排除 PassWall/Xray/Sing-box/Shadowsocks Rust 后，受保护差异为空，但 Ruby 的 RUBY_ENABLE_YJIT 默认 y，Build-Depends 中 RUBY_ENABLE_YJIT:rust/host 仍生效。关闭该应用解释器的可选 YJIT，保留 OpenClash 所需 Ruby/YAML；Rust 消费检查按实际启用条件解析，禁用/启用条件的本地回归通过。包元数据压缩上传以便复核，不改变底层配置。

## 2026-10-06 用户变更：移除 PassWall 后重编

用户要求取消 A Run 37325796881 与 B Run 37297257083，两者已确认 cancelled；两个仓库均 Public。A 应用 overlay 禁用 PassWall 1/2 和专用核心，移除额外 PassWall2 取源及独立 Rust 任务，首启只关闭 OpenClash/Docker。镜像检查拒绝 PassWall 服务/配置文件，真实预检增加选中包的 Rust host 依赖检查；原生 build.sh/wrt_core 保持不变。旧预检和检查点属于旧配置，本轮重新预检/构建。

## 2026-10-05 首次真实预检：运行器链接权限

[Run 37322723331](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37322723331)，框架 3eb632c。清理磁盘与安装依赖完成，在创建 /mnt/wrt_core 链接时 Permission denied；尚未取源或执行 defconfig。改为 sudo ln，仅修复可销毁运行器上的目录权限，不改作者源代码/配置。

## 第二次真实预检：通过，补足挂载依赖

[Run 37323217927](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37323217927)，框架 5a8fd80，23:15:17–23:20:57（Asia/Shanghai）。真实 baseline/custom defconfig、受保护配置及平台源码比较通过；九个 feeds 实际 Git 头与锁一致，所有原生更新阶段成功，准备检查点 173482352 字节。此轮最终配置 SHA256 a636f98182b56199476b84cf124f373c723ce4614dae087f02eafdfba39d29e7。

人工复核应用差异发现删除 QuickFile 会取消其传递依赖 block-mount。为保留原有 USB 挂载基础，显式选回 block-mount，并纳入配置/镜像门槛，重新预检；同时检查实际 OAF 后端 appfilter/kmod-oaf 不回选。

NSS 配置片段写有 HIGH，但固定 qca-nss-drv 的 Config.in 明确 HIGH 仅适用于 ipq807x，ipq60xx 原生默认 MEDIUM。作者原版与定制解析结果均为 MEDIUM，NSS 11.4/IPQ 256/ath11k 512M 及 recycler/mesh 设置相同；保留该原生结果，不强行移植另一平台的 HIGH。

## 第三次真实预检：USB 挂载依赖修正通过

[Run 37324802148](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37324802148)，框架 f9b26a7，23:27:04–23:32:01（Asia/Shanghai）。已下载证据核对：block-mount/fstools=y，appfilter/kmod-oaf 未选中，protected.diff/native-source.diff 均为空，原生与定制平台补丁逐字节一致。最终配置 SHA256 7dc041d8e28db33c85ddbce2e52ab1dc5189f075bcb8ba54792b76120f740b8b；准备检查点 173569165 字节。运行器清理后可用空间约 117 GB。

随后启动正式 [Run 37325796881](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37325796881)，preview=false，固定同一框架提交。此预检证明取源、真实 defconfig 与准备检查点保存通过，不等于编译、检查点恢复或上机验证通过。
