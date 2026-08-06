param([string]$CoreZip = '')
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try {
    [Console]::InputEncoding = New-Object System.Text.UTF8Encoding($false)
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
    $OutputEncoding = [Console]::OutputEncoding
} catch {}

$Root = Split-Path $PSScriptRoot -Parent
$Bundled = Join-Path $Root 'bundled-core'
$KnownOfficialSha256 = @{
    'mihomo-windows-amd64-compatible-v1.19.29.zip' = '322AAA5957BA9E72AFDDA9B71CC4329F691D2D45EC39E70BBCA3F7BF5AA93D52'
}

if ([string]::IsNullOrWhiteSpace($CoreZip)) {
    Write-Host '请输入官方 Mihomo windows-amd64-compatible 核心 ZIP 的完整路径。'
    $CoreZip = Read-Host '核心 ZIP 路径'
}
$CoreZip = $CoreZip.Trim().Trim('"')
if (-not (Test-Path -LiteralPath $CoreZip -PathType Leaf)) { throw '核心 ZIP 不存在。' }

$Name = [IO.Path]::GetFileName($CoreZip)
if ($Name -notmatch '^mihomo-windows-amd64-compatible-v(?<version>[0-9]+(\.[0-9]+){1,3})\.zip$') {
    throw '核心文件名不符合 windows-amd64-compatible 官方命名规则。'
}
$Version = $Matches['version']
$ActualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $CoreZip).Hash.ToUpperInvariant()
$ExpectedHash = $null

Write-Host ('正在核对官方 Release：v' + $Version)
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $Headers = @{ 'User-Agent' = 'Clash-for-Windows-Meta-Core-Patch-Full-Builder/1.5.4' }
    $Release = Invoke-RestMethod -Uri ('https://api.github.com/repos/MetaCubeX/mihomo/releases/tags/v' + $Version) -Headers $Headers -UseBasicParsing -TimeoutSec 30
    $Asset = $Release.assets | Where-Object { $_.name -eq $Name } | Select-Object -First 1
    if ($null -eq $Asset) { throw '官方 Release 中没有找到同名核心文件。' }
    if ($Asset.PSObject.Properties.Name -contains 'digest' -and $Asset.digest -match '^sha256:([a-fA-F0-9]{64})$') {
        $ExpectedHash = $Matches[1].ToUpperInvariant()
    }
}
catch {
    Write-Host ('在线核对失败：' + $_.Exception.Message)
    if ($KnownOfficialSha256.ContainsKey($Name)) {
        Write-Host '将使用脚本内置的已知官方 SHA-256 继续核对。'
        $ExpectedHash = $KnownOfficialSha256[$Name]
    }
    else {
        throw '无法取得该版本的官方 SHA-256，已停止生成 Full 包。'
    }
}

if ([string]::IsNullOrWhiteSpace($ExpectedHash)) { throw '官方 Release 未提供 SHA-256 digest。' }
if ($ActualHash -ne $ExpectedHash) {
    throw ('核心 SHA-256 与官方 Release 不一致。实际：' + $ActualHash + '；官方：' + $ExpectedHash)
}
Write-Host '官方 SHA-256 校验通过。'

New-Item -ItemType Directory -Path $Bundled -Force | Out-Null
Get-ChildItem -LiteralPath $Bundled -File -Filter 'mihomo-windows-amd64-compatible-v*.zip' -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem -LiteralPath $Bundled -File -Filter 'mihomo-windows-amd64-compatible-v*.zip.sha256' -ErrorAction SilentlyContinue | Remove-Item -Force
$Dest = Join-Path $Bundled $Name
Copy-Item -LiteralPath $CoreZip -Destination $Dest -Force
[IO.File]::WriteAllText(($Dest + '.sha256'), ($ExpectedHash + '  ' + $Name + [Environment]::NewLine), (New-Object Text.UTF8Encoding($false)))

$Parent = Split-Path $Root -Parent
$OutZip = Join-Path $Parent ('Clash-for-Windows-Meta-Core-Patch-v1.5.4.1-full-v' + $Version + '.zip')
if (Test-Path -LiteralPath $OutZip) { Remove-Item -LiteralPath $OutZip -Force }
Compress-Archive -Path (Join-Path $Root '*') -DestinationPath $OutZip -CompressionLevel Optimal
$PackageHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $OutZip).Hash.ToUpperInvariant()
[IO.File]::WriteAllText(($OutZip + '.sha256.txt'), ($PackageHash + '  ' + [IO.Path]::GetFileName($OutZip) + [Environment]::NewLine), (New-Object Text.UTF8Encoding($false)))
Write-Host ('已生成 Full 离线包：' + $OutZip)
Write-Host ('内置核心版本：v' + $Version)
Write-Host ('内置核心 SHA-256：' + $ExpectedHash)
Write-Host ('Full 包 SHA-256：' + $PackageHash)
