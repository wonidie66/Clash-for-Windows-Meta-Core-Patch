# Clash for Windows Meta Core Patch

> **项目性质：这是一个 Clash for Windows 修复脚本。**
>
> 本项目基于 Clash for Windows 0.20.39 Windows x64 版本进行修改，主要目标是将旧 Clash 核心替换为 MetaCubeX/mihomo，并修复 Service Mode、TUN、TAP、Mixin、订阅兼容和软件内核心更新等功能。
>
> 本项目不是 Clash for Windows 官方版本， Clash for Windows 原作者、Fndroid、MetaCubeX、Z-Siqi 或其他上游作者、组织及贡献者未对本项目作出背书、担保或技术支持承诺。

## 项目简介

Clash for Windows Fix Patch 是一个面向 Windows x64 的非官方 Clash for Windows 修复补丁。它主要用于解决原 Clash for Windows 停止维护后出现的核心过旧、订阅兼容性不足、Service Mode 异常、TUN/TAP 功能异常以及新版节点类型不支持等问题。

本项目通过替换旧核心、修复服务模式认证、补充核心更新逻辑、提供离线核心安装方式，使旧版 Clash for Windows 0.20.39 在现代订阅和新版节点环境下继续可用。

Clash for Windows 已停止维护，原版内置旧核心无法完整支持部分现代订阅配置和新协议。本项目保留 Clash for Windows 原有界面和使用习惯，同时通过脚本和辅助程序完成以下兼容性修复：

- 替换为 MetaCubeX/mihomo 核心；
- 支持 AnyTLS 等 Mihomo 新协议和现代节点格式；
- 修复新版订阅导入和配置兼容问题；
- 修复 Service Mode 服务模式；
- 修复 TUN 模式；
- 修复 TAP 虚拟网卡模式；
- 保留 YAML 与 JavaScript Mixin；
- 将原应用更新入口改造为 Mihomo 核心更新入口；
- 安装、更新、还原过程加入 SHA-256 校验、备份和失败回滚；
- 提供诊断脚本，方便排查核心、服务、端口、TUN/TAP 等问题。

本项目只提供客户端兼容性改造，不提供订阅、节点、账号、服务器或任何网络服务。

## 下载哪个版本

请到 GitHub Releases 页面下载正式发布包。

普通用户推荐下载：

```text
Clash-for-Windows-Meta-Core-Patch-v1.5.4.1-full-offline.zip
```

这个 Full 离线版已经内置一份经过校验的官方 Mihomo 核心。网络无法访问 GitHub 时，也可以选择本地核心完成安装。

同时建议下载：

```text
Clash-for-Windows-Meta-Core-Patch-v1.5.4.1-full-offline-SHA256.txt
```

发布者还应在同一个 Release 中提供 Mihomo v1.19.29 对应源代码压缩包，例如：

```text
mihomo-v1.19.29-source.zip
```

## 新手使用说明

### 第一步：完整解压

下载后请先完整解压压缩包。不要直接在压缩包里面双击运行脚本。

建议解压到普通目录，例如：

```text
D:\Tools\Clash-for-Windows-Meta-Core-Patch
```

或：

```text
C:\Users\你的用户名\Desktop\Clash-for-Windows-Meta-Core-Patch
```

### 第二步：退出 Clash for Windows

安装前请完全退出 Clash for Windows。

注意：不是只关闭窗口，而是要在右下角系统托盘找到 Clash for Windows 图标，右键选择退出。

### 第三步：运行安装脚本

在解压后的文件夹中找到：

```text
install.cmd
```

推荐操作方式：

1. 右键点击 `install.cmd`；
2. 选择“以管理员身份运行”；
3. 如果 Windows 弹出 UAC 权限确认，点击“是”。

需要管理员权限的原因是，本项目需要安装或修复 Service Mode、TUN、TAP、Windows 服务和 ProgramData 受保护目录，这些都属于系统级操作。

### 第四步：输入 Clash for Windows 安装目录

安装器会提示输入 Clash for Windows 的安装目录。

例如 Clash for Windows 安装在：

```text
E:\Program Files\Clash.for.Windows
```

就输入：

```text
E:\Program Files\Clash.for.Windows
```

也可以直接粘贴完整程序路径：

```text
E:\Program Files\Clash.for.Windows\Clash for Windows.exe
```

不知道安装目录时，可以右键桌面上的 Clash for Windows 快捷方式，选择“打开文件所在的位置”，复制地址栏路径。

### 第五步：选择 Mihomo 核心来源

安装器会显示类似选项：

```text
请选择 Mihomo 核心来源：
  [1] 从 GitHub 下载官方最新稳定版 Mihomo 核心（默认，需要能够访问 GitHub）
  [2] 使用安装包中的本地 Mihomo 核心：mihomo-windows-amd64-compatible-v1.19.29.zip

请输入 1 或 2，直接按回车默认选择 1：
```

建议：

- 能正常访问 GitHub：直接按回车或输入 `1`；
- 不能访问 GitHub：输入 `2`；
- 在线下载失败且包内存在本地核心时，安装器会询问是否回退到本地核心。

### 第六步：等待安装完成

安装器会自动完成以下操作：

- 检查管理员权限；
- 识别 Clash for Windows 安装目录；
- 停止正在运行的 Clash for Windows 和旧核心进程；
- 备份原始文件；
- 安装修改后的运行文件；
- 下载或读取本地 Mihomo 核心；
- 校验核心 SHA-256；
- 验证核心版本；
- 测试当前配置兼容性；
- 替换旧核心；
- 安装或修复 Service Mode；
- 设置服务认证令牌和 ACL；
- 验证核心、服务和端口状态。

成功时会看到类似：

```text
Installation completed successfully.
```

或：

```text
安装完成
```

### 第七步：启动 Clash for Windows

安装完成后，正常启动 Clash for Windows。

进入配置页面导入订阅，然后先测试系统代理，再测试 Service Mode、TUN Mode 或 TAP 虚拟网卡模式。

普通用户不要一开始同时打开 TUN、TAP、Service Mode 和复杂 Mixin。建议一个功能一个功能测试。

## 普通用户主要运行哪些文件

| 文件 | 用途 | 是否建议管理员运行 |
|---|---|---|
| `install.cmd` | 安装或修复本补丁 | 是 |
| `restore.cmd` | 尝试恢复安装前状态 | 是 |
| `diagnose.cmd` | 诊断核心、服务、端口、TUN/TAP 等状态 | 是 |
| `生成Full离线包.cmd` | 发布者制作 Full 离线包使用 | 是，普通用户不用 |

普通用户不要随意运行 `.ps1`、`.exe`、`src`、`tools`、`service-helper-src`、`elevation-helper-src` 中的文件。它们主要用于安装器自动调用、源码审查或重新构建。

## 当前支持的常见节点类型

具体支持能力取决于当前安装的 MetaCubeX/mihomo 版本。本项目不重新实现代理协议，只负责让 Clash for Windows 正确调用 Mihomo 核心。

常见支持类型包括：

- Shadowsocks / ShadowsocksR
- VMess
- VLESS
- Trojan
- Hysteria / Hysteria2
- TUIC
- WireGuard
- AnyTLS
- Snell
- SSH
- HTTP / SOCKS5
- Mieru
- MASQUE
- OpenVPN
- Tailscale
- GostRelay

节点是否可用还取决于订阅服务端输出格式、节点参数和 Mihomo 版本。如果订阅服务端没有输出 Clash Meta/Mihomo 格式，客户端无法凭空恢复被服务端过滤掉的节点。

## Full 离线版内置 Mihomo 说明

Full 离线版内置一份未修改的 MetaCubeX/mihomo 官方发布文件：

```text
mihomo-windows-amd64-compatible-v1.19.29.zip
```

官方 SHA-256：

```text
322AAA5957BA9E72AFDDA9B71CC4329F691D2D45EC39E70BBCA3F7BF5AA93D52
```

Mihomo v1.19.29 适用 GNU GPL v3.0。本项目没有修改、重新编译或重新许可该核心，也不代表 MetaCubeX 对本项目作出背书。

再分发 Full 离线包时，请同时保留：

```text
MIHOMO-THIRD-PARTY-NOTICE.md
MIHOMO-SOURCE-OFFER.md
LICENSES/MIHOMO-GPL-3.0.txt
```

并在同一个 Release 中提供对应源代码压缩包，例如：

```text
mihomo-v1.19.29-source.zip
```

## 安装器不会做什么

本项目不会：

- 上传你的订阅链接；
- 上传你的节点信息；
- 上传你的配置文件；
- 上传你的日志文件；
- 收集遥测或用户行为数据；
- 安装根证书；
- 安装浏览器扩展；
- 创建远程桌面、反向 Shell 或公网管理接口；
- 关闭 Windows Defender；
- 修改防火墙规则；
- 捆绑广告、挖矿或其他第三方软件；
- 删除你的订阅、规则和用户配置。

## 诊断方法

遇到以下情况可以运行：

```text
diagnose.cmd
```

适用问题包括：

- 核心无法启动；
- 日志不可用；
- 端口显示异常；
- 节点无法显示；
- Service Mode 失败；
- TUN Mode 无法使用；
- TAP 虚拟网卡无法安装；
- 更新失败。

提交 Issue 前，请隐藏敏感信息，例如订阅链接、Token、UUID、节点密码、私钥、服务器地址和完整配置文件。

## 还原方法

需要恢复安装前状态时，可以运行：

```text
restore.cmd
```

建议右键选择“以管理员身份运行”。还原脚本会尝试恢复安装前备份的运行文件、旧核心和服务组件。

如果你手动删除过备份目录，或者原 Clash for Windows 安装目录已经损坏，还原可能无法完整完成。此时建议重新安装原版 Clash for Windows。

## 注意事项

- 本项目仅面向 Windows x64；
- 建议基于 Clash for Windows 0.20.39 使用；
- 安装前请退出 Clash for Windows；
- Service Mode、TUN Mode、TAP 虚拟网卡需要管理员权限；
- TUN Mode 和 TAP 虚拟网卡模式不建议同时开启；
- 如果安全软件拦截，请先查看脚本内容和日志，不建议盲目放行未知来源文件；
- 如果订阅导入后节点为空，通常是订阅服务端没有输出 Clash Meta/Mihomo 格式；
- 本项目不保证所有机场、所有订阅转换器、所有节点参数都可用。

## 免责声明

本项目按“现状”提供，不承诺适用于所有系统环境、所有订阅服务、所有节点格式或所有网络环境。

使用本项目造成的配置损坏、网络异常、系统代理异常、服务异常、订阅失效、数据丢失、软件冲突或其他后果，由用户自行承担。

本项目不提供任何规避监管、绕过限制或违反法律法规的建议。用户应自行确保使用行为合法合规。

更多说明请阅读：

- `DISCLAIMER_zh-CN.md`
- `UNOFFICIAL-NOTICE_zh-CN.md`
- `SECURITY-TRANSPARENCY.md`
- `LEGAL-NOTICE.md`
- `THIRD_PARTY_NOTICES.md`
- `MIHOMO-THIRD-PARTY-NOTICE.md`
- `MIHOMO-SOURCE-OFFER.md`
