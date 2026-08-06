# Clash for Windows Meta Core Patch v1.5.4.1 Full 离线版

这是一个修改过的非官方 Clash for Windows 版本，基于 Clash for Windows 0.20.39 Windows x64 版本进行兼容性改造。

本项目不是 Clash for Windows 官方版本，也不代表 Clash for Windows 原作者、Fndroid、MetaCubeX、Z-Siqi 或其他上游作者、组织及贡献者。本项目不提供订阅、节点、服务器、账号或任何代理服务。

## 本版本主要变化

- 新增在线下载最新版 Mihomo 核心；
- 新增本地内置 Mihomo 核心离线安装；
- 在线下载失败时可回退到本地核心；
- 核心来源选择和关键交互提示改为中文；
- 修复旧服务不存在时触发 `NoSuchService` 导致安装失败的问题；
- 修复 CMD 中文提示残留被误识别为命令的问题；
- 保留 Service Mode、TUN、TAP、Mixin、订阅兼容和软件内核心更新功能。

## Full 离线版内置核心

本 Full 离线版包含一份未修改的 MetaCubeX/mihomo 官方发布文件：

```text
mihomo-windows-amd64-compatible-v1.19.29.zip
```

官方 SHA-256：

```text
322AAA5957BA9E72AFDDA9B71CC4329F691D2D45EC39E70BBCA3F7BF5AA93D52
```

Mihomo v1.19.29 适用 GPL-3.0。请同时下载本 Release 中提供的 `mihomo-v1.19.29-source.zip`，或通过 MetaCubeX/mihomo 官方仓库获取对应源代码。

## 新手安装方法

1. 下载 Full 离线版 ZIP；
2. 完整解压压缩包；
3. 退出正在运行的 Clash for Windows；
4. 右键 `install.cmd`；
5. 选择“以管理员身份运行”；
6. 按提示输入 Clash for Windows 安装目录；
7. 能访问 GitHub 时可选择 `[1]` 在线最新版；无法访问 GitHub 时选择 `[2]` 本地核心；
8. 等待安装完成；
9. 启动 Clash for Windows 并导入订阅。

## 注意事项

- 本项目仅面向 Windows x64；
- 建议基于 Clash for Windows 0.20.39 使用；
- Service Mode、TUN、TAP 需要管理员权限；
- TUN 和 TAP 不建议同时开启；
- 订阅、节点和网络服务需要用户自行准备；
- 使用前请阅读 README、免责声明、安全透明说明和第三方声明。
