# Clash for Windows Meta Core Patch v1.5.4.1 更新说明

## 版本定位

v1.5.4.1 是在 v1.5.4 基础上的正式修复版。该版本保留“在线最新版 / 本地内置核心 / 在线失败回退本地核心”的核心安装机制，并修复部分 Windows 环境下旧服务清理失败导致安装中断的问题。

## 新增和改进

- 安装时可选择从 GitHub 下载官方最新稳定版 Mihomo 核心；
- 可使用 `bundled-core` 文件夹中的本地 Mihomo 核心离线安装；
- 在线查询或下载失败时，可自动回退到本地核心；
- 核心来源选择和关键交互提示使用中文；
- 本地核心安装前会验证文件名、SHA-256、真实版本和当前配置兼容性；
- 旧服务不存在时不再误判为安装失败；
- 可从上一次失败留下的半安装状态直接重新运行修复。

## 保留功能

- Service Mode 服务模式；
- TUN 模式；
- TAP 虚拟网卡模式；
- AnyTLS 和现代 Mihomo 节点支持；
- 订阅兼容修复；
- YAML / JavaScript Mixin；
- 软件内 Mihomo 核心更新；
- 更新进度显示；
- 安装前备份；
- 安装失败回滚；
- 核心还原；
- 诊断脚本。

## Full 离线版说明

Full 离线版内置未修改的 MetaCubeX/mihomo v1.19.29 Windows AMD64 compatible 官方核心压缩包。该核心适用 GPL-3.0，发布者应同时提供对应源代码和许可证说明。

## 推荐下载

普通用户建议下载 Full 离线版：

```text
Clash-for-Windows-Meta-Core-Patch-v1.5.4.1-full-offline.zip
```

同时下载 SHA-256 文件用于校验：

```text
Clash-for-Windows-Meta-Core-Patch-v1.5.4.1-full-offline-SHA256.txt
```
