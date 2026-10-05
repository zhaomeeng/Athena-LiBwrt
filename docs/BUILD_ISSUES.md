# A 版构建记录

## 2026-10-05 首次真实预检：运行器链接权限

[Run 37322723331](https://github.com/zhaomeeng/Athena-LiBwrt/actions/runs/37322723331)，框架 3eb632c。清理磁盘与安装依赖完成，在创建 /mnt/wrt_core 链接时 Permission denied；尚未取源或执行 defconfig。改为 sudo ln，仅修复可销毁运行器上的目录权限，不改作者源代码/配置。
