# 源码目录说明

- `src/installer`：安装与还原逻辑。
- `src/updater`：上游核心检查、下载、校验、更新和回滚逻辑。
- `src/service-helper`：带本机令牌认证的高权限服务源码。
- `src/elevation-helper`：Windows 原生 UAC 启动辅助程序源码。
- `src/diagnostics`：诊断工具。
- `src/launchers`：Windows CMD 入口。

## 有意不包含的内容

纯源码仓库不包含：

- `payload/app`，因为它是修改后的 Clash for Windows 运行文件并包含第三方材料；
- 预编译的高权限辅助程序；
- 上游核心二进制，正式安装时从官方 Release 下载；
- 固定版本降级和更新测试脚本。

发布构建者应只注入有权分发的运行文件，保留第三方声明，并避免把完整派生运行时笼统标注为 MIT 或“全部开源”。
