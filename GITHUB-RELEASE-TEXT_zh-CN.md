# Clash for Windows Meta Core Patch v1.5.4.1 Full

这是已经完成在线安装、本地安装和核心还原实机测试的正式 Full 离线版。

## 本版本重点

- 修复 `WMI.WmiException: NoSuchService` 导致服务安装中止的问题；
- 修复 CMD 中文编码导致提示文本被当作命令的问题；
- 支持在线下载 Mihomo 最新稳定版；
- 支持使用发布包内置的 Mihomo v1.19.29 核心离线安装；
- 在线失败时可以回退到本地核心；
- 保留 SHA-256 校验、真实版本检查、配置测试、备份和失败回滚；
- 在线安装、本地安装和核心还原均已完成实机验证。

## 内置核心

- 文件：`mihomo-windows-amd64-compatible-v1.19.29.zip`
- 来源：MetaCubeX/mihomo 官方 v1.19.29 Release
- SHA-256：`322AAA5957BA9E72AFDDA9B71CC4329F691D2D45EC39E70BBCA3F7BF5AA93D52`
- 许可证：GPL-3.0

无法访问 GitHub时，运行 `install.cmd` 并选择 `[2]` 使用本地核心。网络正常时可以选择 `[1]` 在线获取最新稳定版。

## 许可说明

本 Full 包内置的 Mihomo 核心是未修改的上游官方二进制，适用 GPL-3.0。发布本包时，请同时在同一 Release 提供 Mihomo v1.19.29 对应源代码压缩包，或采用 GPLv3 第 6 条允许的其他有效方式提供对应源代码。

请阅读：

- `MIHOMO-THIRD-PARTY-NOTICE.md`
- `MIHOMO-SOURCE-OFFER.md`
- `LICENSES/MIHOMO-GPL-3.0.txt`
- `DISCLAIMER_zh-CN.md`
- `LEGAL-NOTICE.md`
