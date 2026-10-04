# 开发状态

更新时间：2026-10-05（Asia/Shanghai）。

目标：A 版 ZqinKing + LiBwrt，按交接要求在 B 版完成后实施。

已完成：克隆并核对框架提交、ini、deconfig、三种片段、模块阶段和最近 LiBwrt 发布；原生 config_preview 通过。保留作者全部源码，其他设备工作流移至 docs/upstream-workflows 存档，避免新仓库自动启动非目标构建。

尚未完成：应用精简/新增、版本锁、真实 defconfig、定制 Actions、完整编译与设备测试。

下一步：B 版成功后，以本路线独立基线实施应用层调整；处理待删除应用在原脚本中的源码校验依赖。若现有底层修正失效，停止报告。

关键记录：[BASELINE.md](BASELINE.md)、[REQUIREMENTS.md](REQUIREMENTS.md)。
