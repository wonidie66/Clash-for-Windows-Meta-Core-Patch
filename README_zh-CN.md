# Clash for Windows Meta Core Patch

> **项目性质：基于 Clash for Windows 0.20.39 修改的非官方 Windows x64 版本。**
>
> 本项目不是 Clash for Windows 官方版本，也不代表 Fndroid、MetaCubeX、Z-Siqi 或其他上游作者、组织及贡献者。上述主体未对本项目作出背书、担保或技术支持承诺。

## 项目用途

Clash for Windows 已停止维护，旧核心无法完整支持部分现代配置和协议。本项目在保留原有界面与使用习惯的基础上，替换并适配现代核心，修复服务模式、TUN 模式、TAP 虚拟网卡、混合配置和核心更新等功能。

本项目只提供客户端兼容性改造，不提供订阅、节点、代理服务器、账号或任何网络服务。

## 主要功能

- 使用 MetaCubeX 官方 GitHub Release 提供的 Windows x64 compatible 核心。
- 支持本地模式、系统代理、服务模式、TUN 模式和 TAP 虚拟网卡模式。
- 保留 YAML 与 JavaScript 混合配置功能。
- 改进现代订阅配置及 AnyTLS 等协议的兼容性。
- 使用 Windows 原生 UAC 提权辅助程序，并提供 PowerShell 回退路径。
- 将已经停止维护的应用更新入口改为核心更新入口。
- 在 Clash for Windows 内显示核心更新进度。
- 更新前校验文件、测试配置、创建备份；失败时自动回滚。
- 提供一键还原和诊断工具。

## 安装脚本会做什么

为了便于用户审核，安装器的主要操作公开如下：

1. 检查目标目录中是否存在 `Clash for Windows.exe`。
2. 请求 Windows 管理员权限，用于替换程序文件、安装 Windows 服务和配置 TUN/TAP 所需组件。
3. 停止正在运行的 Clash for Windows、旧核心和同名旧服务，避免文件占用。
4. 备份原始 `app.asar`、旧的解包运行目录、原始核心和原始服务辅助程序。
5. 写入修改后的 Clash for Windows Electron 运行文件。
6. 从 MetaCubeX 官方 GitHub Release 下载指定架构的核心，并执行 SHA-256 校验。
7. 将核心安装到 Clash for Windows 的核心目录，同时复制一份到受保护的服务模式目录。
8. 创建仅用于本机服务模式认证的随机令牌，并限制令牌、核心和服务配置文件的 Windows ACL 权限。
9. 移除可能冲突的旧 `Clash Core Service` 服务或同名计划任务，再安装新的本地 Windows 服务。
10. 生成安装日志；任何关键步骤失败时停止安装，不把部分安装误报为成功。

详细目录和文件变化请查看 `SECURITY-TRANSPARENCY.md`。

## 安装脚本不会做什么

按本版本公开源码和脚本设计，安装器不会：

- 上传订阅链接、节点信息、配置文件、日志或设备信息；
- 收集遥测、广告标识或用户行为数据；
- 创建用户账号、远程桌面、远程管理入口或公网监听的控制端口；
- 安装根证书、浏览器扩展、键盘记录、屏幕捕获或文件监控组件；
- 添加与 Clash for Windows 无关的开机启动项或隐藏计划任务；
- 修改 Windows Defender、系统安全策略或防火墙规则；
- 从第三方网盘或不明镜像下载核心；
- 删除用户的订阅、配置文件和代理规则。

这里的“不会”仅针对本项目发布的安装器和更新器。Clash for Windows 自身在用户主动启用系统代理、开机启动、TUN 或 TAP 功能时，仍会按对应功能修改系统网络状态。

## 为什么需要管理员权限

以下操作属于 Windows 系统级操作，普通用户权限无法完成：

- 修改 Program Files 中的程序文件；
- 安装、启动或卸载 Windows 服务；
- 部署受保护的核心文件并设置 ACL；
- 安装或管理 TAP 虚拟网卡；
- 以 SYSTEM 权限运行 TUN 核心。

所有由 Clash for Windows 客户端发起的安装、卸载和更新操作均应显示标准 Windows UAC 确认。用户取消 UAC 后，操作应立即停止。

## 核心更新机制

核心更新器会：

1. 查询上游官方 Release；
2. 对比当前核心与最新稳定版本；
3. 下载 Windows x64 compatible 构建；
4. 校验官方发布文件的 SHA-256；
5. 解压并验证核心真实版本；
6. 使用新核心测试当前配置；
7. 备份本地核心、服务模式核心和服务配置；
8. 停止旧核心并替换文件；
9. 更新服务模式核心哈希并重启服务；
10. 成功后提示重新加载 Clash for Windows，失败时恢复备份。

更新窗口只负责显示更新器写入的本地状态，不会把日志上传到服务器。

## 文件与隐私

用户配置通常位于：

```text
%USERPROFILE%\.config\clash
```

本项目会在该目录创建服务认证令牌和更新日志，但不会主动读取并上传其中的订阅或节点内容。提交 Issue 前必须手动脱敏，不要公开订阅 URL、访问令牌、服务器地址、密码、私钥或完整配置。

## 安装方法

1. 准备 Clash for Windows 0.20.39 Windows x64 安装目录。
2. 从系统托盘完全退出 Clash for Windows。
3. 将发布压缩包完整解压到新的独立文件夹。
4. 运行 `install.cmd`。
5. 选择包含 `Clash for Windows.exe` 的目录。
6. 确认 Windows UAC。
7. 安装完成后正常启动 Clash for Windows。

不要直接在压缩包内运行脚本，也不要把不同版本的补丁解压到同一个目录中混用。

## 还原与诊断

- `restore.cmd`：停止并移除补丁服务，删除受保护核心和令牌，在备份存在时恢复原始 Clash for Windows 文件。
- `diagnose.cmd`：只读取本机核心版本、配置路径、相关进程、监听端口和服务状态，并测试本机 `127.0.0.1` 服务接口。

还原脚本不会删除用户订阅、配置文件和规则。

## 风险说明

- Clash for Windows 本身已经停止维护，其 Electron 运行环境和依赖可能存在未修复的安全问题。
- 系统代理、TUN 和 TAP 会改变系统网络路径，错误配置可能导致暂时无法联网。
- 第三方订阅内容不受本项目控制，用户应自行判断来源可信度。
- 任何软件都无法保证绝对不存在缺陷；建议在使用前查看源码、核对 SHA-256，并保留原程序备份。

## 非官方及责任声明

本项目是修改过的非官方 Clash for Windows 版本。项目名称仅用于说明兼容目标，不表示官方关系、商标授权或上游背书。

软件按“现状”提供，不作适销性、特定用途适用性、持续可用性或无错误保证。用户应自行承担安装、配置、更新和使用产生的风险，并遵守所在地法律、网络管理规定及第三方服务条款。

## 许可与第三方文件

- 本项目独立编写的安装器、更新器、诊断工具、提权辅助程序和服务辅助程序源码，以仓库中的许可证为准。
- 修改后的 Clash for Windows 运行文件、汉化材料、Electron/npm 依赖和下载的第三方核心，仍受各自权利人及上游许可证约束。
- 本项目的补丁代码许可证不自动覆盖第三方文件，也不表示对第三方作品重新授权。
- 完整发布包与纯源码仓库的许可范围不同，请同时阅读 `LEGAL-NOTICE.md` 和 `THIRD_PARTY_NOTICES.md`。

为兼容已经验证通过的旧版本，程序内部目录、HTTP 请求头或变量名中可能保留 `CFW` 或旧内部标识；这些仅用于技术兼容，不作为项目公开名称。

## 问题反馈

提交问题时请提供：

- Windows 版本；
- Clash for Windows 安装类型和补丁版本；
- 复现步骤；
- 脱敏后的 `install.log`、`uninstall.log`、更新日志或 `diagnose.cmd` 输出。

不要提交订阅链接、服务商 Token、节点密码、私钥、Cookie 或能够识别个人身份的信息。


## v1.5.4 核心来源选择

安装器现在支持两种 Mihomo 核心来源：

1. **在线安装**：从 MetaCubeX/mihomo 官方 GitHub Release 查询并下载最新稳定版 `windows-amd64-compatible` 核心。直接按回车时默认选择此方式。
2. **本地安装**：从安装包的 `bundled-core` 文件夹读取 `mihomo-windows-amd64-compatible-v*.zip`。

如果在线查询或下载失败，并且 `bundled-core` 中存在已校验的本地核心，安装器会询问是否自动回退到本地核心。

本地核心安装前仍会执行文件名检查、SHA-256 校验、真实版本验证以及当前 Clash for Windows 配置兼容性测试。校验或测试失败时不会替换现有核心。

### 安装时如何选择

运行 `install.cmd` 后会看到：

```text
请选择 Mihomo 核心来源：
  [1] 从 GitHub 下载官方最新稳定版 Mihomo 核心（默认，需要能够访问 GitHub）
  [2] 使用安装包中的本地 Mihomo 核心：文件名或未检测到

请输入 1 或 2，直接按回车默认选择 1：
```

网络可以正常访问 GitHub 时选择 `1`；无法访问 GitHub 或网络不稳定时，将官方核心压缩包放入 `bundled-core` 后选择 `2`。


## v1.5.4.1 服务安装修复

如果 v1.5.4 在日志末尾出现 `WMI.WmiException: NoSuchService`，不需要先还原。完全退出 Clash for Windows 后，以管理员身份直接运行 v1.5.4.1 的 `install.cmd`，安装器会清理残留服务目录并继续完成服务注册。

`icacls` 输出中的中文用户名乱码只影响旧版日志显示；v1.5.4.1 不再记录该原生乱码输出，而是记录实际执行的 Unicode 路径。

## Full 离线版内置核心

本 Full 离线版已经在 `bundled-core` 目录内置 MetaCubeX/mihomo v1.19.29 官方 `windows-amd64-compatible` 压缩包。该文件保持上游原始内容不变，SHA-256 为：

```text
322AAA5957BA9E72AFDDA9B71CC4329F691D2D45EC39E70BBCA3F7BF5AA93D52
```

运行 `install.cmd` 后，网络正常时仍可选择 `[1]` 在线安装最新稳定版；无法访问 GitHub 时选择 `[2]` 即可使用内置核心。安装器会在安装前再次完成哈希、版本和配置兼容性验证。

内置 Mihomo 核心适用 GPL-3.0。本项目没有修改或重新编译该核心。发布者和二次分发者必须同时保留 GPLv3 文本、第三方来源说明，并保证对应版本源代码可获得。详见：

- `MIHOMO-THIRD-PARTY-NOTICE.md`
- `MIHOMO-SOURCE-OFFER.md`
- `LICENSES/MIHOMO-GPL-3.0.txt`
