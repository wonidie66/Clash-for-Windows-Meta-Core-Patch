# Clash for Windows Meta Core Patch v1.5.3

> 基于 Clash for Windows 0.20.39 修改的非官方 Windows x64 版本。
>
> 本项目与 Clash for Windows 原作者、Fndroid、MetaCubeX、Z-Siqi 及其他上游作者不存在官方隶属或背书关系。

## 主要变化

- 替换旧核心并适配现代配置；
- 支持服务模式、TUN、TAP 和混合配置；
- 修复客户端内服务/虚拟网卡安装与卸载的 UAC 提权；
- 改进现代订阅及 AnyTLS 兼容性；
- 将旧应用更新改为核心一键更新；
- 增加更新进度、SHA-256 校验、配置验证、备份和失败回滚；
- 移除所有固定版本降级与测试脚本；
- 提供还原和诊断工具。

## 安全透明

安装器会备份原文件、下载并校验官方核心、部署本地和服务核心、安装本机 Windows 服务并设置 ACL。它不会上传订阅或配置，不会关闭安全软件、安装根证书、开放公网远程管理、创建隐藏计划任务或捆绑其他软件。

安装器需要管理员权限，因为它需要修改 Program Files、安装 Windows 服务以及管理 TUN/TAP。完整操作清单请阅读压缩包中的 `SECURITY-TRANSPARENCY.md`。

## 安装

1. 完全退出 Clash for Windows；
2. 解压到新文件夹；
3. 运行 `install.cmd`；
4. 选择包含 `Clash for Windows.exe` 的目录；
5. 确认 UAC 后等待安装完成。

## 注意

- 仅支持 Windows x64 和 Clash for Windows 0.20.39；
- TUN 与 TAP 不建议同时开启；
- 不要公开订阅链接、Token、密码、私钥或未脱敏日志；
- 请核对本 Release 提供的 SHA-256；
- 软件按现状提供，使用风险由用户自行承担。
