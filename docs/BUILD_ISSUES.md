# A 版构建记录

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
