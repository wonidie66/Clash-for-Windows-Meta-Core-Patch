# 安全透明与脚本行为说明

本文用于说明 Clash for Windows Meta Core Patch 在安装、更新、服务模式和还原过程中会进行的主要操作，方便用户审查。它不是“绝对安全保证”，用户仍应从可信发布页下载、核对 SHA-256 并查看源码。

## 1. 会修改的 Clash for Windows 文件

安装器可能修改或创建：

```text
<Clash for Windows 安装目录>\resources\app
<Clash for Windows 安装目录>\resources\app.asar.cfw-original
<Clash for Windows 安装目录>\resources\app.cfw-before-mihomo
<Clash for Windows 安装目录>\resources\static\files\win\x64\clash-win64.exe
<Clash for Windows 安装目录>\resources\static\files\win\x64\clash-win64.cfw-original.exe
<Clash for Windows 安装目录>\resources\static\files\win\x64\service\clash-core-service.exe
<Clash for Windows 安装目录>\resources\static\files\win\common\cfw-elevate.exe
<Clash for Windows 安装目录>\resources\static\files\win\common\cfw-mihomo-update.ps1
```

带有 `cfw`、`mihomo` 的部分文件名是历史兼容标识，不代表公开项目名称。

## 2. 会创建的系统级目录

```text
C:\Program Files\Clash for Windows Service
C:\ProgramData\CFW-Mihomo
```

其中保存本地 Windows 服务、受保护核心、Wintun DLL、服务配置和核心 PID 文件。`C:\ProgramData\CFW-Mihomo` 是兼容旧版本保留的内部路径。

安装器会使用 `icacls` 限制 ProgramData 目录仅由 SYSTEM 和 Administrators 修改，防止普通进程替换以高权限运行的核心。

## 3. 会创建的用户文件

```text
%USERPROFILE%\.config\clash\.service-token
%USERPROFILE%\.config\clash\cfw-elevation.log
%USERPROFILE%\.config\clash\mihomo-updater.log
%USERPROFILE%\.config\clash\mihomo-update-progress.json
```

`.service-token` 是随机生成的本机服务认证令牌。令牌用于阻止其他普通网页或本机进程随意调用高权限服务接口，不会发送到远程服务器。

## 4. Windows 服务和计划任务

安装器会：

- 停止并卸载旧的 `Clash Core Service`；
- 删除可能残留的同名旧计划任务；
- 安装新的 `Clash Core Service` Windows 服务；
- 启动本机服务并测试 `127.0.0.1:53000/ping`。

项目不会创建新的隐藏计划任务。删除同名计划任务是为了清理旧 Clash for Windows 服务模式可能遗留的实现。

## 5. 本机监听接口

高权限服务控制接口绑定：

```text
127.0.0.1:53000
```

它只监听本机回环地址，不直接接受局域网或公网连接。启动、停止等敏感请求使用随机令牌验证，并限制允许启动的核心路径、核心哈希和工作目录。

Clash for Windows 的代理端口、控制端口以及“允许局域网”行为由用户配置决定，不属于安装器额外创建的远程管理接口。

## 6. 网络下载

安装和更新核心时，脚本连接 MetaCubeX 官方 GitHub Release。下载完成后执行 SHA-256 校验，再解压和替换核心。

脚本不会把配置、订阅、节点、日志或令牌上传到 GitHub。GitHub 只能像普通文件下载服务一样看到网络请求的常规信息，例如来源 IP 和 User-Agent。

## 7. 更新时的操作

更新器会：

- 查询最新稳定 Release；
- 下载并校验核心；
- 测试新核心版本和当前配置；
- 备份本地核心、服务核心和服务配置；
- 停止旧核心；
- 替换两个核心副本；
- 更新服务核心 SHA-256 固定值；
- 重启服务；
- 失败时自动恢复备份。

更新进度窗口读取本地 JSON 状态文件，不建立远程进度上报连接。

## 8. 不包含的高风险行为

本项目安装器和更新器源码中不包含用于以下目的的逻辑：

- 绕过或关闭 Windows UAC；
- 关闭 Microsoft Defender；
- 添加防火墙放行规则；
- 安装根证书；
- 创建新用户或修改用户密码；
- 远程桌面、反向 Shell、远程命令控制；
- 截屏、录音、键盘记录；
- 搜索并上传浏览器数据、Cookie、钱包或个人文档；
- 挖矿、广告注入或捆绑软件安装；
- 静默上传配置、订阅和使用数据。

## 9. 用户可自行核验

建议发布者提供：

- Release ZIP 的 SHA-256；
- `SHA256SUMS.txt` 文件清单；
- 安装器、更新器、服务辅助程序和提权辅助程序源码；
- 清晰的 Release Notes；
- 可复现或至少可审计的辅助程序构建说明。

用户可以在运行前阅读 `install.ps1`、`uninstall.ps1` 和更新器脚本；安装后可通过 `diagnose.cmd`、任务管理器、服务管理器和 `Get-NetTCPConnection` 检查实际状态。
