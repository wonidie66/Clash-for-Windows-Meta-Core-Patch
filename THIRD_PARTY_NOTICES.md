# 第三方项目与署名说明

## Clash for Windows

本项目以 Clash for Windows 0.20.39 为兼容和修改目标。发布包中的 Clash for Windows 派生运行文件不被声明为本项目原创，也不因补丁代码许可证而被重新许可。

## Clash for Windows 中文材料

部分运行文件及中文界面基于或参考 `Z-Siqi/Clash-for-Windows_Chinese`。应保留其来源说明和“非官方修改版”属性，不得把相关材料声明为本项目独立原创。

## MetaCubeX/mihomo 核心

在线安装路径从 MetaCubeX 官方 GitHub Release 下载第三方核心。Full 离线版另外内置一份未修改的：

```text
mihomo-windows-amd64-compatible-v1.19.29.zip
```

官方 SHA-256：

```text
322AAA5957BA9E72AFDDA9B71CC4329F691D2D45EC39E70BBCA3F7BF5AA93D52
```

Mihomo v1.19.29 适用 GNU GPL v3.0。本项目不对该核心重新许可，也不声称与 MetaCubeX 存在官方关系。再分发时必须保留 GPLv3 文本、来源和版本说明，并按照 GPLv3 提供对应源代码。

详见：

- `MIHOMO-THIRD-PARTY-NOTICE.md`
- `MIHOMO-SOURCE-OFFER.md`
- `LICENSES/MIHOMO-GPL-3.0.txt`

## Electron、npm、WinSW、Wintun、TAP 及其他依赖

Clash for Windows 运行环境包含 Electron、npm 依赖、Windows 服务包装器、网络驱动和其他第三方组件。它们分别适用各自许可证和声明。不得使用本项目的补丁代码许可证替换这些第三方许可证。

## 其他说明

本项目尽力保留第三方来源、许可证和发布边界说明。若发现遗漏或不准确之处，请提交 Issue 并提供可核验来源。
