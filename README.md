# Clash for Windows Meta Core Patch

> 修改过的非官方 Clash for Windows 版本。  
> 将旧版 Clash 核心替换为 MetaCubeX/mihomo，并补充新版协议、Service Mode、TUN Mode、TAP 虚拟网卡、订阅兼容和软件内核心更新功能。

---

## 目录

- [项目简介](#项目简介)
- [重要声明](#重要声明)
- [新手使用说明](#新手使用说明)
- [主要功能](#主要功能)
- [当前支持的节点类型](#当前支持的节点类型)
- [安装脚本大致做了什么](#安装脚本大致做了什么)
- [文件和目录说明](#文件和目录说明)
- [诊断方法](#诊断方法)
- [还原方法](#还原方法)
- [注意事项](#注意事项)
- [安全透明说明](#安全透明说明)
- [常见问题](#常见问题)
- [第三方项目](#第三方项目)
- [免责声明](#免责声明)
- [反馈问题](#反馈问题)
- [许可证和发布边界](#许可证和发布边界)

---

## 项目简介

Clash for Windows 已经停止维护，原版内置 Clash 核心也较旧，无法很好支持一些新的代理协议和新版配置格式。

本项目基于 Clash for Windows 0.20.39 进行兼容性修改，主要目标是：

- 将旧 Clash 核心替换为 MetaCubeX/mihomo；
- 修复新版订阅和新版节点的兼容性；
- 新增 AnyTLS 等新版节点支持；
- 恢复并修复 Service Mode；
- 恢复并修复 TUN Mode；
- 恢复并修复 TAP 虚拟网卡模式；
- 增加 Mihomo 核心版本检查和软件内一键更新；
- 保留 Clash for Windows 原有界面和使用习惯。

本项目适合已经习惯 Clash for Windows，但希望继续使用新版 mihomo 核心和新版节点格式的 Windows 用户。

---

## 重要声明

本项目是修改过的非官方 Clash for Windows 版本。

本项目不是 Clash for Windows 官方版本，也不代表 Clash for Windows 原作者、Fndroid、MetaCubeX、Z-Siqi 或其他上游作者、组织及贡献者。上述主体未对本项目作出背书、担保或技术支持承诺。

项目名称中的 “Clash for Windows” 仅用于说明被修改的软件和兼容目标，不表示官方授权、官方发布或上游合作关系。

本项目不提供订阅、节点、服务器、账号或任何代理服务。用户应自行确保使用行为符合所在国家或地区的法律法规、网络服务协议和学校/单位网络管理规定。

使用前请阅读：

- [免责声明](./DISCLAIMER_zh-CN.md)
- [非官方声明](./UNOFFICIAL-NOTICE_zh-CN.md)
- [安全透明说明](./SECURITY-TRANSPARENCY.md)
- [第三方项目说明](./THIRD_PARTY_NOTICES.md)
- [法律与发布边界说明](./LEGAL-NOTICE.md)

---

## 使用说明

这一节面向第一次使用本项目的新手用户，按照下面步骤操作即可。

### 1.下载文件

请进入本项目的 **Releases** 页面，下载正式发布包：

```text
Clash-for-Windows-Meta-Core-Patch-v1.5.3-public-release-with-disclaimer.zip
```

建议同时下载 SHA-256 校验文件：

```text
Clash-for-Windows-Meta-Core-Patch-v1.5.3-public-release-with-disclaimer-SHA256.txt
```

普通用户只需要下载正式发布包即可。源码包主要给开发者、审查脚本的人、或者想自己重新构建项目的人使用。

### 2. 运行脚本

下载完成后先解压。

不要直接在压缩包里面双击运行脚本。先完整解压到一个普通文件
普通用户主要会用到这三个脚本：

| 文件名         | 用途                                 | 是否建议管理员运行 |
| -------------- | ------------------------------------ | ------------------ |
| `install.cmd`  | 安装或修复本补丁                     | 是                 |
| `restore.cmd`  | 尝试恢复安装前的 Clash for Windows   | 是                 |
| `diagnose.cmd` | 诊断核心、服务、端口、TUN/TAP 等状态 | 建议是             |

一般情况下，只需要运行：

```text
install.cmd
```

---

## 安装步骤

### 第一步：退出 Clash for Windows

安装前请先完全退出 Clash for Windows。

注意，不只是关闭窗口，要在右下角系统托盘中找到 Clash for Windows 图标，右键退出。

如果没有退出，安装器会尝试自动关闭 Clash for Windows 和旧核心进程。

### 第二步：运行 install.cmd

在解压后的文件夹中找到：

```text
install.cmd
```

推荐操作方式：

1. 右键点击 `install.cmd`；
2. 选择“以管理员身份运行”；
3. 如果 Windows 弹出 UAC 权限确认窗口，点击“是”。

为什么需要管理员权限？

因为本项目会安装或修复：

- Service Mode；
- TUN Mode；
- TAP 虚拟网卡；
- Windows 服务；
- ProgramData 受保护核心目录。

这些操作都属于系统级操作，需要管理员权限。

### 第三步：输入 Clash for Windows 安装目录

安装器启动后，会显示类似内容：

```text
Clash for Windows Meta Core Patch installer

Administrator privileges confirmed.

Enter the Clash for Windows installation directory.
You may also paste the full path of Clash for Windows.exe.
CFW path:
```

这时需要输入你的 Clash for Windows 安装目录。

例如你的 Clash for Windows 安装在：

```text
E:\Program Files\Clash.for.Windows
```

那就输入：

```text
E:\Program Files\Clash.for.Windows
```

也可以直接粘贴完整程序路径：

```text
E:\Program Files\Clash.for.Windows\Clash for Windows.exe
```

输入后按回车。

如果你不知道 Clash for Windows 安装在哪里，可以右键桌面上的 Clash for Windows 快捷方式，选择“打开文件所在的位置”，然后复制地址栏里的路径。

### 第四步：等待安装器执行

安装器会自动执行安装过程。过程中你可能会看到类似内容：

```text
Administrator privileges confirmed.
CFW directory: E:\Program Files\Clash.for.Windows
Stopping Clash for Windows and local core processes.
Backed up the existing Electron runtime.
Installed the modified Clash for Windows runtime.
Downloading official MetaCubeX/mihomo core.
Official release package SHA-256 verified.
Candidate executable version verified.
Replaced the local Clash for Windows core.
Installed or repaired Clash Core Service.
Installation completed successfully.
```

这些信息表示安装器正在：

- 检查管理员权限；
- 识别 Clash for Windows 安装目录；
- 停止旧核心；
- 备份原文件；
- 安装修改后的运行文件；
- 下载并校验 Mihomo 核心；
- 替换旧 Clash 核心；
- 安装或修复服务模式；
- 检查安装是否成功。

### 第五步：看到成功提示

如果安装成功，最后会看到类似内容：

```text
Installation completed successfully.
```

或：

```text
Clash for Windows Meta Core Patch was installed successfully.
```

这表示补丁已经安装完成。

然后按任意键关闭安装窗口。

### 第六步：启动 Clash for Windows

安装完成后，正常启动 Clash for Windows。

进入“主页”或“设置”页面后，核心版本应显示为 Mihomo，例如：

```text
v1.19.29 Mihomo
```

日志页面中应出现类似内容：

```text
RESTful API listening at: 127.0.0.1:xxxxx
Mixed(http+socks) proxy listening at: 127.0.0.1:7890
```

如果可以看到这些内容，说明核心已经正常启动。

---

## 软件内更新 Mihomo 核心

本项目将原版 Clash for Windows 的更新功能改成了 Mihomo 核心更新功能。

### 检查更新

在 Clash for Windows 首页点击版本号，例如：

```text
0.20.3 Mihomo-1.5.3
```

如果发现新版本，会提示当前版本和最新版本。

例如：

```text
当前版本：v1.19.28
最新版本：v1.19.29
```

### 更新操作

点击更新后，软件内部会显示更新进度窗口。

更新器会自动执行：

1. 检查官方 MetaCubeX/mihomo Release；
2. 下载新版 Windows x64 compatible 核心；
3. 校验 SHA-256；
4. 解压核心；
5. 测试新核心能否加载当前配置；
6. 备份旧核心；
7. 停止当前核心；
8. 替换本地核心；
9. 替换服务模式使用的核心；
10. 更新服务模式核心哈希；
11. 重启服务；
12. 成功后提示重新加载 Clash for Windows。

更新期间请不要强制关闭 Clash for Windows，也不要手动删除安装目录文件。

如果更新失败，更新器会尝试自动回滚旧核心。

---

## 主要功能

### 1. 替换为 MetaCubeX/mihomo 核心

本项目会将 Clash for Windows 原有旧核心替换为 MetaCubeX/mihomo Windows x64 compatible 核心。

替换后可以继续使用 Clash for Windows 原来的界面，同时使用 mihomo 提供的新协议、新配置和新特性。

### 2. 新增 AnyTLS 等新版节点支持

原版 Clash for Windows 的旧核心无法识别部分新版节点，例如 AnyTLS。

本项目更换为 mihomo 后，支持能力以当前安装的 mihomo 核心为准。

### 3. 修复订阅兼容性

本项目修改了订阅下载逻辑，提升对新版 Clash/Mihomo 订阅格式的兼容性。

主要修复：

- 订阅下载时使用更适合现代 Clash/Mihomo 的请求头；
- 避免部分订阅服务把新版节点过滤为空；
- 提升 AnyTLS 等新版节点在订阅中的识别成功率；
- 保留 Clash for Windows 原有的配置管理方式。

注意：如果订阅服务端本身没有输出 Mihomo/Clash Meta 格式，客户端无法凭空恢复被服务端过滤掉的节点。

### 4. 修复 Service Mode

本项目修复了 Clash for Windows 原版在新版 Windows 环境中可能无法安装、卸载或启动 Service Mode 的问题。

Service Mode 主要用于需要高权限的网络功能，例如 TUN Mode。

安装器会创建本机服务辅助程序，并使用本机随机令牌进行认证，避免任意程序调用服务接口启动未知程序。

### 5. 修复 TUN Mode

本项目恢复并修复 TUN Mode，使 Clash for Windows 可以通过 mihomo 核心接管系统流量。

TUN Mode 需要管理员权限和服务模式支持。使用时建议不要同时开启 TAP 虚拟网卡模式。

### 6. 修复 TAP 虚拟网卡模式

本项目修复了 Clash for Windows 中 TAP 虚拟网卡安装、卸载和管理功能。

TAP 模式和 TUN 模式属于两套不同方案，一般不建议同时开启。

### 7. 保留混合配置功能

本项目保留 Clash for Windows 原有的 Mixin 混合配置功能。

包括：

- YAML Mixin；
- JavaScript Mixin；
- 订阅配置合并；
- 自定义 DNS、规则、代理组等高级配置。

### 8. 新增软件内 Mihomo 核心更新

原版 Clash for Windows 已经停止更新，因此本项目将原来的更新功能改为 Mihomo 核心更新功能。

软件内更新功能会：

- 检查当前 Mihomo 核心版本；
- 查询官方 MetaCubeX/mihomo Release；
- 下载新版 Windows x64 compatible 核心；
- 校验 SHA-256；
- 测试新核心能否加载当前配置；
- 备份旧核心；
- 替换本地核心和服务模式核心；
- 更新服务模式核心哈希；
- 更新失败时自动回滚；
- 在界面中显示更新进度。

---

## 当前支持的节点类型

支持范围取决于当前安装的 MetaCubeX/mihomo 核心版本。本项目本身不重新实现代理协议，只负责让 Clash for Windows 调用 mihomo 核心。

常见支持类型包括：

| 类型               | 说明                                            |
| ------------------ | ----------------------------------------------- |
| Shadowsocks / SS   | 常见加密代理协议                                |
| ShadowsocksR / SSR | 旧版兼容协议                                    |
| VMess              | V2Ray 常见协议                                  |
| VLESS              | 支持 TCP、WS、gRPC、REALITY、XTLS Vision 等配置 |
| Trojan             | Trojan 协议                                     |
| Hysteria           | Hysteria v1                                     |
| Hysteria2          | Hysteria v2                                     |
| TUIC               | QUIC 类代理协议                                 |
| WireGuard          | WireGuard 出站                                  |
| AnyTLS             | 新版 AnyTLS 节点                                |
| Snell              | Snell 协议                                      |
| SSH                | SSH 出站                                        |
| HTTP / SOCKS5      | HTTP、SOCKS5 代理                               |
| Mieru              | Mieru 出站                                      |
| MASQUE             | MASQUE 出站                                     |
| OpenVPN            | OpenVPN 出站                                    |
| Tailscale          | Tailscale 出站                                  |
| GostRelay          | Gost Relay 出站                                 |

注意：

- 上表为 mihomo 核心能力说明，不代表所有订阅都一定能自动转换成功；
- 节点是否可用还取决于订阅服务端输出格式；
- 如果订阅文件中没有对应节点，客户端无法自行生成；
- 如果订阅服务端只输出 sing-box 格式，可能需要服务商提供 Clash Meta/Mihomo 格式订阅。

---

## 安装脚本大致做了什么

为了让用户了解脚本行为，下面说明安装器大致会做什么。

安装器会：

1. 检查 Clash for Windows 安装目录；
2. 请求 Windows 管理员权限；
3. 停止正在运行的 Clash for Windows 和旧核心进程；
4. 备份原有 Clash for Windows 运行文件；
5. 安装修改后的 Electron 运行文件；
6. 下载官方 MetaCubeX/mihomo Windows x64 compatible 核心；
7. 校验下载文件的 SHA-256；
8. 使用当前配置测试新核心是否能正常启动；
9. 替换本地 Clash 核心；
10. 安装或修复 Service Mode 辅助程序；
11. 部署服务模式使用的受保护核心；
12. 生成本机随机服务令牌；
13. 设置 ProgramData 目录 ACL；
14. 安装或修复 Clash Core Service；
15. 验证服务接口和核心是否可用；
16. 生成安装日志，便于排查问题。

安装器不会：

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
- 创建无关的开机启动项；
- 捆绑广告、挖矿或其他第三方软件；
- 删除你的订阅、规则和用户配置。

---

## 文件和目录说明

安装后可能涉及以下路径：

```text
Clash for Windows 安装目录\resources\
Clash for Windows 安装目录\resources\static\files\win\x64\clash-win64.exe
C:\ProgramData\CFW-Mihomo\
%USERPROFILE%\.config\clash\
```

其中：

- `resources\static\files\win\x64\clash-win64.exe` 是本地模式使用的 Mihomo 核心；
- `C:\ProgramData\CFW-Mihomo\` 是服务模式使用的受保护核心和服务配置；
- `%USERPROFILE%\.config\clash\` 是 Clash for Windows 原有用户配置目录。

---

## 诊断方法

如果遇到以下问题：

- 核心无法启动；
- 日志不可用；
- 端口显示为 0；
- 节点无法显示；
- Service Mode 失败；
- TUN Mode 无法使用；
- TAP 虚拟网卡无法安装；
- 更新失败；

可以运行：

```text
diagnose.cmd
```

推荐右键选择：

```text
以管理员身份运行
```

诊断脚本会检查：

- Clash for Windows 安装路径；
- 当前核心版本；
- 配置文件位置；
- mixed-port；
- external-controller；
- Mihomo 进程；
- 本地监听端口；
- Service Mode 状态；
- 53000 服务接口；
- TUN / TAP 虚拟网卡；
- 关键日志文件。

如果你要提交 Issue，请提供诊断结果，但注意隐藏敏感信息。

不要公开：

- 订阅链接；
- token；
- 节点密码；
- UUID；
- 私钥；
- 服务器真实地址；
- 未脱敏配置文件。

---

## 还原方法

如果你想恢复安装前的状态，可以运行：

```text
restore.cmd
```

推荐右键选择：

```text
以管理员身份运行
```

还原脚本会尝试：

- 停止 Clash for Windows；
- 停止 Mihomo 核心；
- 恢复安装前备份的运行文件；
- 恢复原始核心；
- 移除或还原本项目安装的服务组件。

注意：

如果你手动删除过备份目录，或者原 Clash for Windows 安装目录已经损坏，还原脚本可能无法完整恢复。

这种情况下，可以重新安装原版 Clash for Windows。

---

## 常见安装结果说明

### 安装成功

看到类似内容：

```text
Installation completed successfully.
```

表示安装完成。

### 提示没有管理员权限

如果看到类似内容：

```text
Administrator privileges are required.
```

说明没有管理员权限。

请右键 `install.cmd`，选择“以管理员身份运行”。

### 提示找不到 Clash for Windows

如果看到类似内容：

```text
Clash for Windows.exe was not found.
```

说明你输入的路径不正确。

请重新输入 Clash for Windows 的安装目录，或者粘贴完整的：

```text
Clash for Windows.exe
```

路径。

### 提示下载失败

可能原因：

- 无法访问 GitHub；
- 网络代理没有开启；
- DNS 异常；
- 安全软件拦截；
- GitHub 临时不可用。

可以稍后重试，或者先打开 Clash for Windows 的系统代理后再运行安装器。

### 提示 SHA-256 校验失败

如果出现 SHA-256 校验失败，请不要继续安装。

这可能表示：

- 下载文件损坏；
- 网络中断；
- 文件被安全软件修改；
- 下载来源异常。

请删除临时文件后重新运行安装器。

---

## 哪些文件不要随便运行

普通用户只需要运行：

```text
install.cmd
restore.cmd
diagnose.cmd
```

不要随便运行：

```text
*.ps1
*.exe
src 目录里的文件
tools 目录里的文件
service-helper 目录里的文件
elevation-helper 目录里的文件
```

这些通常是给安装器自动调用、给开发者审查或重新构建使用的。

如果你不知道某个文件是做什么的，不要直接运行。

---

## 新手推荐使用顺序

第一次使用建议按这个顺序：

1. 下载正式发布包；
2. 完整解压；
3. 退出 Clash for Windows；
4. 右键 `install.cmd`；
5. 选择“以管理员身份运行”；
6. 输入 Clash for Windows 安装目录；
7. 等待出现安装成功提示；
8. 启动 Clash for Windows；
9. 导入订阅；
10. 开启系统代理；
11. 确认普通代理可用；
12. 再测试 Service Mode；
13. 再测试 TUN Mode；
14. 最后根据需要测试 TAP 虚拟网卡模式。

普通用户不要一开始就同时打开 TUN、TAP、Service Mode 和复杂 Mixin。建议一个功能一个功能测试。

---

## 注意事项

1. 本项目仅支持 Windows x64 环境；
2. 建议使用 Clash for Windows 0.20.39 作为基础版本；
3. 安装前请退出 Clash for Windows；
4. 安装过程中请不要手动删除安装目录中的文件；
5. Service Mode、TUN Mode、TAP 虚拟网卡需要管理员权限；
6. TUN Mode 和 TAP 虚拟网卡模式不建议同时开启；
7. 如果安全软件拦截脚本，请先查看脚本内容和日志，不建议盲目放行未知来源文件；
8. 如果订阅下载后节点为空，通常是订阅服务端没有输出 Clash Meta/Mihomo 格式；
9. 本项目不保证所有机场、所有订阅转换器、所有节点参数都可用；
10. 使用前建议备份 Clash for Windows 配置目录。

---

## 安全透明说明

本项目包含需要管理员权限的脚本和服务辅助程序，因为 Service Mode、TUN Mode、TAP 虚拟网卡和 ProgramData 受保护核心目录都属于系统级操作。

为了便于用户审查，项目提供了：

- 安装脚本；
- 更新脚本；
- 诊断脚本；
- 提权辅助程序源码；
- 服务辅助程序源码；
- SHA-256 校验文件；
- 安全透明说明；
- 第三方项目声明；
- 免责声明。

如果你不信任本项目，请不要运行安装脚本。建议先阅读脚本内容，或在虚拟机中测试。

---

## 常见问题

### 为什么需要管理员权限？

因为安装 Service Mode、TUN、TAP 虚拟网卡、写入 ProgramData 受保护目录、停止和注册 Windows 服务都需要管理员权限。

### 为什么安全软件可能会提示风险？

安装器会停止进程、替换程序文件、注册服务、写入 ProgramData、启动系统级服务，这些行为对安全软件来说属于高权限操作。项目已尽量公开脚本行为，但用户仍应自行判断是否信任。

### 为什么我的订阅导入后没有节点？

通常是订阅服务端没有输出 Clash Meta/Mihomo 格式，或者订阅转换器把新版协议过滤掉了。客户端无法从空配置中恢复节点。

### 为什么 AnyTLS 节点以前不能用，现在可以用？

原版 Clash for Windows 的旧核心不支持 AnyTLS。本项目替换为 mihomo 核心后，核心具备 AnyTLS 适配器能力，因此可以识别符合 Mihomo 配置格式的 AnyTLS 节点。

### 这个项目会提供节点吗？

不会。本项目只修改客户端，不提供订阅、节点、账号、服务器或任何代理服务。

---

## 第三方项目

本项目涉及或兼容以下第三方项目：

- Clash for Windows
- MetaCubeX/mihomo
- Z-Siqi/Clash-for-Windows_Chinese
- Wintun
- Electron
- Node.js 相关依赖

具体说明见：

- [第三方项目说明](./THIRD_PARTY_NOTICES.md)
- [法律与发布边界说明](./LEGAL-NOTICE.md)

---

## 免责声明

本项目按“现状”提供，不承诺适用于所有系统环境、所有订阅服务、所有节点格式或所有网络环境。

使用本项目造成的配置损坏、网络异常、系统代理异常、服务异常、订阅失效、数据丢失、软件冲突或其他后果，由用户自行承担。

本项目不提供任何规避监管、绕过限制或违反法律法规的建议。用户应自行确保使用行为合法合规。

请在使用前阅读完整免责声明：

- [DISCLAIMER_zh-CN.md](./DISCLAIMER_zh-CN.md)

---

## 反馈问题

提交 Issue 前请注意：

- 不要公开订阅链接；
- 不要公开 token；
- 不要公开节点密码；
- 不要公开 UUID；
- 不要公开服务器真实地址；
- 不要上传未脱敏配置文件。

建议提供：

- Windows 版本；
- Clash for Windows 安装路径；
- 安装日志；
- 诊断脚本输出；
- 核心日志中已脱敏的错误部分；
- 是否开启 Service Mode、TUN 或 TAP。

---

## 许可证和发布边界

本项目中的独立补丁脚本、安装器、更新器、诊断工具和辅助程序源码可按本仓库声明的许可使用。

但修改后的 Clash for Windows 运行文件、上游核心、第三方依赖和相关资源仍归其原权利人所有。本项目的许可证不自动覆盖第三方文件。

请阅读：

- [LEGAL-NOTICE.md](./LEGAL-NOTICE.md)
- [THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md)
