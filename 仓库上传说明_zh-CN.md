# 仓库上传说明

本压缩包用于上传到 GitHub 仓库根目录。

## 上传方式

1. 解压本压缩包；
2. 打开 GitHub 仓库首页；
3. 点击 `Add file`；
4. 选择 `Upload files`；
5. 将本压缩包解压后的所有文件和文件夹拖入上传区域；
6. 提交到 `main` 分支。

## 同名文件怎么处理

如果仓库中已经存在旧版文件，建议直接用本压缩包中的文件覆盖。

本压缩包已经把 README、更新日志、免责声明、第三方声明、Mihomo 再分发说明等文档统一整理为中文版本。

## 不要上传到仓库根目录的内容

以下文件不建议直接放在仓库普通文件列表中：

```text
Clash-for-Windows-Meta-Core-Patch-v1.5.4.1-full-offline.zip
mihomo-windows-amd64-compatible-v1.19.29.zip
修改后的 Clash for Windows 运行时文件
其他大型第三方二进制文件
```

这些文件应放到 GitHub Release 的 Assets 中。

## Release 中建议上传的文件

```text
Clash-for-Windows-Meta-Core-Patch-v1.5.4.1-full-offline.zip
Clash-for-Windows-Meta-Core-Patch-v1.5.4.1-full-offline-SHA256.txt
mihomo-v1.19.29-source.zip
```

## 提交信息建议

```text
Update repository files for v1.5.4.1 Full release
```

中文也可以写：

```text
更新 v1.5.4.1 Full 离线版仓库文件和中文说明
```
