# Clash for Windows Fix Patch

> ** Clash for Windows 修复补丁。**
>
> 本项目用于修复 Clash for Windows 停止维护后出现的不兼容新节点、Service Mode失效、TUN失效和软件内核心更新等问题。
>
> 本项目不是 Clash for Windows 官方版本，也不代表 Clash for Windows 原作者、Fndroid、MetaCubeX、Z-Siqi 或其他上游作者、组织及贡献者。本项目不提供订阅、节点、账号、服务器或任何网络服务。

## 项目简介

**Clash for Windows Fix Patch** 是一个面向旧版 Clash for Windows 的非官方修复补丁。它保留 Clash for Windows 原有界面和使用习惯，通过替换旧核心和修复相关组件，使 Clash for Windows 在现代订阅、新版节环境下继续可用。

本项目适合遇到以下问题的用户：

- Clash for Windows 原版核心失效；
- 新版订阅导入失败或节点不完整；
- AnyTLS 等新版节点类型无法识别；
- Service Mode 无法安装、启动或正常工作；
- TUN Mode 异常；
- TAP 虚拟网卡模式异常；
- 软件内核心更新功能失效。

## 主要功能

- 将旧 Clash 核心替换为 MetaCubeX/mihomo 官方核心；
- 修复新版订阅导入和配置兼容问题；
- 支持 AnyTLS 等新版 Mihomo 节点类型；
- 修复 Service Mode 服务模式；
- 修复 TUN Mode；
- 修复 TAP 虚拟网卡模式；
- 保留 YAML 与 JavaScript Mixin；
- 将软件内更新入口改造为 Mihomo 核心更新入口；
- 支持在线下载官方最新稳定版核心；
- 支持使用安装包内置的本地核心；
- 在线下载失败时可回退到本地核心；
- 提供安装前备份、SHA-256 校验、配置测试和失败回滚；
- 提供 `diagnose.cmd` 诊断脚本和 `restore.cmd` 还原脚本。

## 下载说明

普通用户请到 GitHub Releases 页面下载正式发布包。

推荐下载：

```text
Clash-for-Windows-Meta-Core-Patch-v1.5.4.1-full-offline.zip
```

建议同时下载校验文件：

```text
Clash-for-Windows-Meta-Core-Patch-v1.5.4.1-full-offline-SHA256.txt
```

Full 离线版已经内置一份经过校验的官方 Mihomo 核心。无法访问 GitHub 时，也可以选择本地核心完成安装。

Release 中还应提供 Mihomo 对应源码包，例如：

```text
mihomo-v1.19.29-source.zip
```

这是为了配合 Mihomo GPLv3 二进制再分发时的源码获取要求。

## 安装方法

### 1. 解压发布包

下载后请先完整解压压缩包，不要直接在压缩包里运行脚本。

推荐解压到类似位置：

```text
D:\Tools\Clash-for-Windows-Fix-Patch
```

### 2. 退出 Clash for Windows

安装前请完全退出正在运行的 Clash for Windows，包括右下角托盘中的程序。

### 3. 以管理员身份运行安装脚本

右键运行：

```text
install.cmd
```

选择：

```text
以管理员身份运行
```

### 4. 输入 Clash for Windows 安装目录

按提示输入 Clash for Windows 的安装目录，例如：

```text
E:\Program Files\Clash.for.Windows
```

也可以输入完整程序路径：

```text
E:\Program Files\Clash.for.Windows\Clash for Windows.exe
```

### 5. 选择 Mihomo 核心来源

安装器会提示：

```text
请选择 Mihomo 核心来源：
  [1] 从 GitHub 下载官方最新稳定版 Mihomo 核心（默认）
  [2] 使用安装包中的本地 Mihomo 核心
```

建议：

- 能访问 GitHub：直接回车或输入 `1`；
- 无法访问 GitHub：输入 `2`；
- 在线下载失败：按提示回退到本地核心。

### 6. 完成安装并测试

安装完成后启动 Clash for Windows，导入订阅并依次测试：

1. 系统代理；
2. Service Mode；
3. TUN Mode；
4. TAP 虚拟网卡模式。

不需要的功能不要同时开启，尤其不建议同时开启 TUN 和 TAP。

## 常用脚本

| 文件                 | 作用                                    |
| -------------------- | --------------------------------------- |
| `install.cmd`        | 安装或修复补丁，普通用户主要运行这个    |
| `restore.cmd`        | 尝试恢复安装前的 Clash for Windows 状态 |
| `diagnose.cmd`       | 诊断核心、服务、端口、TUN/TAP 等问题    |
| `生成Full离线包.cmd` | 发布者用于生成带内置核心的 Full 离线包  |

普通用户不要随意运行 `.ps1`、`.exe`、`tools`、`src` 等目录中的文件。它们通常由安装器自动调用，或用于开发者审查。

## 使用注意

- 仅支持 Windows x64；
- 建议基于 Clash for Windows 0.20.39 使用；
- 安装、Service Mode、TUN、TAP 通常需要管理员权限；
- 不建议同时开启 TUN 和 TAP；
- 如果订阅导入后节点为空，通常是订阅服务端没有输出兼容的 Clash Meta/Mihomo 配置；
- 本项目不保证所有订阅、所有节点参数、所有系统环境都可用；
- 如果安全软件拦截，请先查看脚本内容和日志，不建议盲目放行未知来源文件。

## 安全透明说明

本项目不会：

- 上传你的订阅链接、节点信息、配置文件或日志；
- 收集遥测或用户行为数据；
- 安装根证书或浏览器扩展；
- 创建远程桌面、反向 Shell 或公网管理接口；
- 关闭 Windows Defender；
- 修改防火墙规则；
- 捆绑广告、挖矿或其他第三方软件；
- 删除你的订阅、规则和用户配置。

安装过程会进行管理员权限操作，主要用于写入 Clash for Windows 安装目录、替换核心、修复 Service Mode、设置必要的本地文件权限。具体行为可以查看脚本源码和安装日志。

## 第三方组件与许可证

本项目涉及多个第三方项目和组件，包括但不限于：

- Clash for Windows；
- MetaCubeX/mihomo；
- WinSW；
- Electron 及相关依赖；
- 汉化和社区维护材料。

其中，内置 Mihomo 核心为官方未修改二进制，适用 GPLv3。发布 Full 离线版时，应同时提供对应版本的 Mihomo 源码包或明确的源码获取说明。

请阅读：

- `THIRD_PARTY_NOTICES.md`
- `LEGAL-NOTICE.md`
- `MIHOMO-THIRD-PARTY-NOTICE.md`
- `MIHOMO-SOURCE-OFFER.md`
- `LICENSES/MIHOMO-GPL-3.0.txt`

## 免责声明

本项目按“现状”提供，不承诺适用于所有系统环境、订阅服务、节点格式或网络环境。

使用本项目造成的配置损坏、网络异常、系统代理异常、服务异常、订阅失效、数据丢失、软件冲突或其他后果，由用户自行承担。

本项目不提供任何规避监管、绕过限制或违反法律法规的建议。用户应自行确保使用行为合法合规。

## 反馈问题

提交 Issue 前，请先运行：

```text
diagnose.cmd
```

反馈时请说明：

- Windows 版本；
- Clash for Windows 安装路径；
- 使用的是在线核心还是本地核心；
- 是否启用 Service Mode、TUN 或 TAP；
- 安装日志或诊断日志中的关键错误。

请不要公开上传未打码的订阅链接、节点密码、UUID、私钥、访问令牌或完整配置文件。
