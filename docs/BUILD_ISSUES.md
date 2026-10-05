# A 版构建记录

## 2026-10-05 首次真实预检：运行器链接权限

[Run 37322723331](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37322723331)，框架 3eb632c。清理磁盘与安装依赖完成，在创建 /mnt/wrt_core 链接时 Permission denied；尚未取源或执行 defconfig。改为 sudo ln，仅修复可销毁运行器上的目录权限，不改作者源代码/配置。

## 第二次真实预检：通过，补足挂载依赖

[Run 37323217927](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37323217927)，框架 5a8fd80，23:15:17–23:20:57（Asia/Shanghai）。真实 baseline/custom defconfig、受保护配置及平台源码比较通过；九个 feeds 实际 Git 头与锁一致，所有原生更新阶段成功，准备检查点 173482352 字节。此轮最终配置 SHA256 a636f98182b56199476b84cf124f373c723ce4614dae087f02eafdfba39d29e7。

人工复核应用差异发现删除 QuickFile 会取消其传递依赖 block-mount。为保留原有 USB 挂载基础，显式选回 block-mount，并纳入配置/镜像门槛，重新预检；同时检查实际 OAF 后端 appfilter/kmod-oaf 不回选。

NSS 配置片段写有 HIGH，但固定 qca-nss-drv 的 Config.in 明确 HIGH 仅适用于 ipq807x，ipq60xx 原生默认 MEDIUM。作者原版与定制解析结果均为 MEDIUM，NSS 11.4/IPQ 256/ath11k 512M 及 recycler/mesh 设置相同；保留该原生结果，不强行移植另一平台的 HIGH。
