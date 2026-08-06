# Clash for Windows Meta Core Patch v1.5.4.1 更新说明

## 新增

- 安装时可选择从 GitHub 下载官方最新稳定版 Mihomo 核心；
- 可使用 `bundled-core` 文件夹中的本地 Mihomo 核心离线安装；
- 在线查询或下载失败时，可自动回退到本地核心；
- 核心来源选择和关键交互提示改为中文；
- 本地核心执行文件名、SHA-256、真实版本和配置兼容性验证。

## 保留

- Service Mode 服务模式；
- TUN 模式；
- TAP 虚拟网卡模式；
- AnyTLS 和现代 Mihomo 节点支持；
- 订阅兼容修复；
- Mixin 混合配置；
- 软件内 Mihomo 核心更新、进度显示、备份和失败回滚。

## 安全说明

安装器只接受符合 `mihomo-windows-amd64-compatible-v*.zip` 命名规则的核心包。缺少可信 SHA-256、哈希不匹配、版本不一致或无法加载当前配置时，安装将停止，不会替换现有核心。

## v1.5.4.1 修复

- 修复旧服务目录存在、但 Windows 服务不存在时触发的 `WMI.WmiException: NoSuchService`；
- 原生程序输出不再直接受 PowerShell `ErrorActionPreference=Stop` 影响；
- 修复中文用户名在 `icacls` 日志中显示乱码的问题；
- CMD 启动器改为纯 ASCII 内容，中文交互仍由 PowerShell 正常显示；
- 支持直接覆盖修复 v1.5.4 留下的半安装状态。

## Full 离线版说明

本变体在 `bundled-core` 中预置未修改的 MetaCubeX/mihomo v1.19.29 官方核心，适合无法访问 GitHub 的用户。安装时选择 `[2]` 即可离线安装。内置核心适用 GPL-3.0，发布者应同时提供对应源代码获取方式，详见 `MIHOMO-SOURCE-OFFER.md`。
