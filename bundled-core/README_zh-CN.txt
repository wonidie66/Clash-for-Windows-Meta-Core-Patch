本地 Mihomo 核心放置说明

将官方 Windows AMD64 compatible 压缩包直接放入本文件夹，例如：
mihomo-windows-amd64-compatible-v1.19.29.zip

建议同时放入同名校验文件：
mihomo-windows-amd64-compatible-v1.19.29.zip.sha256

校验文件可以只包含 64 位 SHA-256，也可以使用以下格式：
<64位SHA-256>  mihomo-windows-amd64-compatible-v1.19.29.zip

安装器会执行：文件名检查、SHA-256 校验、核心版本验证和当前配置兼容性测试。
校验失败时不会安装。

当前 v1.19.29 compatible 官方压缩包 SHA-256：
322AAA5957BA9E72AFDDA9B71CC4329F691D2D45EC39E70BBCA3F7BF5AA93D52
