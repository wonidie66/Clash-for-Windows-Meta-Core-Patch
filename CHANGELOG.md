# 更新日志

## v1.5.4.1

- Fixed `WMI.WmiException: NoSuchService` when an old WinSW directory exists but the Windows service is absent.
- Native WinSW, `schtasks`, `sc` and `icacls` calls are now handled by exit code instead of native stderr text.
- Suppressed incorrectly decoded `icacls` output for Chinese Windows profile paths.
- Changed CMD launcher contents to ASCII to prevent trailing Chinese commands from being misparsed.
- Re-running the installer now repairs the partial state left by the v1.5.4 failure.

## v1.5.4

- Added online latest / bundled local Mihomo core selection.
- Added automatic local fallback after online download failure.
- Localized core-source prompts in Chinese.
- Added local package SHA-256, version and config validation.
- Removed test-only scripts and descriptions.

## v1.5.3

- 采用经过实机验证的完整安装、核心启动和控制 API 连接逻辑。
- 支持本地模式、系统代理、服务模式、TUN、TAP 虚拟网卡和混合配置。
- 修复 Clash for Windows 客户端内部服务模式及 TAP 安装/卸载提权流程。
- 改进现代订阅配置和 AnyTLS 兼容性。
- 将停止维护的 Clash for Windows 应用更新入口改为上游核心更新入口。
- 增加 Clash for Windows 内部核心更新进度窗口。
- 增加 SHA-256 校验、新核心版本验证、当前配置验证、备份和失败回滚。
- 使用 Windows 原生 UAC 辅助程序并保留 PowerShell 回退路径。
- 支持中文用户名、中文路径、空格和常见特殊字符路径。
- 移除固定版本核心降级、更新测试和开发验证脚本。
- 增加非官方声明、安全透明说明、第三方声明和适合 GitHub Release 的更新说明。
## v1.5.4.1 Full 离线发布变体

- 内置未修改的 MetaCubeX/mihomo v1.19.29 Windows AMD64 compatible 官方压缩包。
- 内置核心 SHA-256 与官方 Release digest 匹配。
- 增加 Mihomo GPL-3.0 许可证副本、第三方再分发说明和对应源代码获取说明。
- 在线安装仍默认获取最新稳定版；网络不可用时可以选择本地 v1.19.29 核心。
