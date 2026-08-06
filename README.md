# Clash for Windows Meta Core Patch

> 修改过的非官方 Clash for Windows 版本。  
> 将旧版 Clash 核心替换为 MetaCubeX/mihomo，并补充新版协议、服务模式、TUN、TAP、订阅兼容和软件内核心更新功能。

## 项目简介

Clash for Windows 已经停止维护，原版内置 Clash 核心也较旧，无法很好支持一些新的代理协议和新版配置格式。

本项目基于 Clash for Windows 0.20.39 进行兼容性修改，主要目标是：

- 将旧 Clash 核心替换为 MetaCubeX/mihomo；
- 修复新版订阅和新版节点的兼容性；
- 恢复并修复 Service Mode；
- 恢复并修复 TUN Mode；
- 恢复并修复 TAP 虚拟网卡模式；
- 增加 Mihomo 核心版本检查和软件内一键更新；
- 保留 Clash for Windows 原有界面和使用习惯。

本项目适合已经习惯 Clash for Windows，但希望继续使用新版 mihomo 核心和新版节点格式的 Windows 用户。

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

## 主要功能

### 1. 替换为 MetaCubeX/mihomo 核心

本项目会将 Clash for Windows 原有旧核心替换为 MetaCubeX/mihomo Windows x64 compatible 核心。

替换后可以继续使用 Clash for Windows 原来的界面，同时使用 mihomo 提供的新协议、新配置和新特性。

### 2. 新增 AnyTLS 等新版节点支持

原版 Clash for Windows 的旧核心无法识别部分新版节点，例如 AnyTLS。

本项目更换为 mihomo 后，支持能力以当前安装的 mihomo 核心为准。mihomo 当前源码中的适配器类型包括 Shadowsocks、ShadowsocksR、Snell、Socks5、HTTP、VMess、VLESS、Trojan、Hysteria、Hysteria2、WireGuard、TUIC、SSH、Mieru、AnyTLS、MASQUE、OpenVPN、Tailscale、GostRelay 等。具体是否可用还取决于订阅转换格式、节点参数和 mihomo 版本。  
参考：MetaCubeX/mihomo 的适配器类型定义。  

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

TAP 模式和 TUN 模式属于两套不同的接管流量方案，一般不建议同时开启。

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

## 当前支持的节点类型

支持范围取决于当前安装的 MetaCubeX/mihomo 核心版本。本项目本身不重新实现代理协议，只负责让 Clash for Windows 调用 mihomo 核心。

常见支持类型包括：

| 类型 | 说明 |
|---|---|
| Shadowsocks / SS | 常见加密代理协议 |
| ShadowsocksR / SSR | 旧版兼容协议 |
| VMess | V2Ray 常见协议 |
| VLESS | 支持 TCP、WS、gRPC、REALITY、XTLS Vision 等配置 |
| Trojan | Trojan 协议 |
| Hysteria | Hysteria v1 |
| Hysteria2 | Hysteria v2 |
| TUIC | QUIC 类代理协议 |
| WireGuard | WireGuard 出站 |
| AnyTLS | 新版 AnyTLS 节点 |
| Snell | Snell 协议 |
| SSH | SSH 出站 |
| HTTP / SOCKS5 | HTTP、SOCKS5 代理 |
| Mieru | Mieru 出站 |
| MASQUE | MASQUE 出站 |
| OpenVPN | OpenVPN 出站 |
| Tailscale | Tailscale 出站 |
| GostRelay | Gost Relay 出站 |

注意：

- 上表为 mihomo 核心能力说明，不代表所有订阅都一定能自动转换成功；
- 节点是否可用还取决于订阅服务端输出格式；
- 如果订阅文件中没有对应节点，客户端无法自行生成；
- 如果订阅服务端只输出 sing-box 格式，可能需要服务商提供 Clash Meta/Mihomo 格式订阅。

## 安装方法

### 1. 下载发布包

进入本项目的 Releases 页面，下载正式发布包：

```text
Clash-for-Windows-Meta-Core-Patch-v1.5.3-public-release-with-disclaimer.zip
