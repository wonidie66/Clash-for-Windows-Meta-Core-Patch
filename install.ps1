param(
    [string]$TargetDir = '',
    [string]$MihomoZip = '',
    [string]$UserHome = '',
    [string]$UserSid = ''
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try {
    [Console]::InputEncoding = New-Object System.Text.UTF8Encoding($false)
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
    $OutputEncoding = [Console]::OutputEncoding
} catch {}
$PatchVersion = 'v1.5.4.1'
$GitHubLatestApi = 'https://api.github.com/repos/MetaCubeX/mihomo/releases/latest'
$KnownCoreSha256 = @{
    'mihomo-windows-amd64-compatible-v1.19.29.zip' = '322AAA5957BA9E72AFDDA9B71CC4329F691D2D45EC39E70BBCA3F7BF5AA93D52'
}
$Version = ''
$AssetName = ''
$DownloadUrl = ''
$ExpectedSha256 = ''
$LogFile = Join-Path $PSScriptRoot 'install.log'
if ([string]::IsNullOrWhiteSpace($UserHome)) { $UserHome = $env:USERPROFILE }
if ([string]::IsNullOrWhiteSpace($UserSid)) { $UserSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value }

function Log([string]$Message) {
    $Line = ('[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message)
    Write-Host $Line
    Add-Content -LiteralPath $LogFile -Value $Line -Encoding UTF8
}

function Test-IsAdministrator {
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
    return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Quote-Argument([string]$Value) {
    return '"' + ($Value -replace '"', '\"') + '"'
}

function Restart-Elevated {
    $Arguments = New-Object System.Collections.Generic.List[string]
    $Arguments.Add('-NoLogo')
    $Arguments.Add('-NoProfile')
    $Arguments.Add('-ExecutionPolicy')
    $Arguments.Add('Bypass')
    $Arguments.Add('-File')
    $Arguments.Add((Quote-Argument $PSCommandPath))
    if (-not [string]::IsNullOrWhiteSpace($TargetDir)) {
        $Arguments.Add('-TargetDir')
        $Arguments.Add((Quote-Argument $TargetDir))
    }
    if (-not [string]::IsNullOrWhiteSpace($MihomoZip)) {
        $Arguments.Add('-MihomoZip')
        $Arguments.Add((Quote-Argument $MihomoZip))
    }
    $Arguments.Add('-UserHome')
    $Arguments.Add((Quote-Argument $UserHome))
    $Arguments.Add('-UserSid')
    $Arguments.Add((Quote-Argument $UserSid))
    Write-Host '安装服务模式和 TUN 模式需要管理员权限，正在请求 Windows UAC 授权...'
    $Process = Start-Process -FilePath 'powershell.exe' -Verb RunAs -Wait -PassThru -ArgumentList ($Arguments -join ' ')
    exit $Process.ExitCode
}

function Normalize-Target([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    $Value = $Value.Trim().Trim('"')
    if (-not (Test-Path -LiteralPath $Value)) { return $null }
    $Resolved = (Resolve-Path -LiteralPath $Value).Path
    if ((Test-Path -LiteralPath $Resolved -PathType Leaf) -and
        ([IO.Path]::GetFileName($Resolved) -ieq 'Clash for Windows.exe')) {
        $Resolved = Split-Path -LiteralPath $Resolved -Parent
    }
    if (Test-Path -LiteralPath (Join-Path $Resolved 'Clash for Windows.exe')) {
        return $Resolved
    }
    return $null
}

function Resolve-TargetDir([string]$Requested) {
    $Resolved = Normalize-Target $Requested
    if ($null -ne $Resolved) { return $Resolved }

    $Candidates = New-Object System.Collections.Generic.List[string]
    $Candidates.Add($PSScriptRoot)
    $Candidates.Add((Split-Path $PSScriptRoot -Parent))
    $Candidates.Add((Get-Location).Path)
    if ($env:LOCALAPPDATA) {
        $Candidates.Add((Join-Path $env:LOCALAPPDATA 'Programs\Clash for Windows'))
        $Candidates.Add((Join-Path $env:LOCALAPPDATA 'Clash for Windows'))
    }
    if (-not [string]::IsNullOrWhiteSpace($UserHome)) {
        $OriginalLocalAppData = Join-Path $UserHome 'AppData\Local'
        $Candidates.Add((Join-Path $OriginalLocalAppData 'Programs\Clash for Windows'))
        $Candidates.Add((Join-Path $OriginalLocalAppData 'Clash for Windows'))
    }
    if ($env:ProgramFiles) { $Candidates.Add((Join-Path $env:ProgramFiles 'Clash for Windows')) }
    if (${env:ProgramFiles(x86)}) { $Candidates.Add((Join-Path ${env:ProgramFiles(x86)} 'Clash for Windows')) }

    foreach ($Candidate in ($Candidates | Select-Object -Unique)) {
        $Resolved = Normalize-Target $Candidate
        if ($null -ne $Resolved) {
            Log "Detected Clash for Windows directory: $Resolved"
            return $Resolved
        }
    }

    Write-Host ''
    Write-Host '请输入 Clash for Windows 安装目录。'
    Write-Host '也可以直接粘贴 Clash for Windows.exe 的完整路径。'
    $InputPath = Read-Host 'Clash for Windows 路径'
    $Resolved = Normalize-Target $InputPath
    if ($null -eq $Resolved) {
        throw '所选路径中没有找到 Clash for Windows.exe。'
    }
    return $Resolved
}

function Download-File([string]$Url, [string]$OutFile, [string]$DisplayName) {
    Log "Downloading official Mihomo core: $DisplayName"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $OutFile -TimeoutSec 120
    }
    catch {
        Log "Invoke-WebRequest failed: $($_.Exception.Message)"
        $Curl = Get-Command curl.exe -ErrorAction SilentlyContinue
        if ($null -eq $Curl) { throw }
        & $Curl.Source -L --fail --retry 3 --connect-timeout 20 --max-time 300 -o $OutFile $Url
        if ($LASTEXITCODE -ne 0) {
            throw '下载失败。如果无法访问 GitHub，请将已校验的 Mihomo 核心压缩包放入 bundled-core 文件夹并选择本地安装。'
        }
    }
}

function Get-CoreVersionFromName([string]$Name) {
    if ($Name -match '^mihomo-windows-amd64-compatible-v(?<ver>[0-9]+(\.[0-9]+){1,3})\.zip$') {
        return ('v' + $Matches['ver'])
    }
    return $null
}

function Get-Sha256FromSidecar([string]$ZipPath) {
    $Name = [IO.Path]::GetFileName($ZipPath)
    if ($KnownCoreSha256.ContainsKey($Name)) { return $KnownCoreSha256[$Name].ToUpperInvariant() }

    $Candidates = New-Object System.Collections.Generic.List[string]
    $Candidates.Add($ZipPath + '.sha256')
    $Candidates.Add($ZipPath + '.SHA256')
    $Candidates.Add((Join-Path ([IO.Path]::GetDirectoryName($ZipPath)) ($Name + '.sha256')))
    $Candidates.Add((Join-Path ([IO.Path]::GetDirectoryName($ZipPath)) 'SHA256SUMS.txt'))

    foreach ($Candidate in ($Candidates | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $Candidate -PathType Leaf)) { continue }
        $Content = Get-Content -LiteralPath $Candidate -Raw
        $RegexName = [Regex]::Escape($Name)
        if ($Content -match "(?im)^\s*([a-f0-9]{64})\s+[\* ]?$RegexName\s*$") {
            return $Matches[1].ToUpperInvariant()
        }
        if ($Content -match '(?im)^\s*([a-f0-9]{64})\s*$') {
            return $Matches[1].ToUpperInvariant()
        }
    }
    return $null
}

function New-CorePackageInfo(
    [string]$Source,
    [string]$Path,
    [string]$Url,
    [string]$Asset,
    [string]$VersionText,
    [string]$Sha256
) {
    return [pscustomobject]@{
        Source = $Source
        Path = $Path
        Url = $Url
        AssetName = $Asset
        Version = $VersionText
        ExpectedSha256 = $Sha256
    }
}

function Find-BundledCorePackage {
    $SearchDirs = New-Object System.Collections.Generic.List[string]
    $SearchDirs.Add((Join-Path $PSScriptRoot 'bundled-core'))
    $SearchDirs.Add($PSScriptRoot)

    $Packages = @()
    foreach ($Dir in ($SearchDirs | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $Dir -PathType Container)) { continue }
        $Packages += Get-ChildItem -LiteralPath $Dir -File -Filter 'mihomo-windows-amd64-compatible-v*.zip' -ErrorAction SilentlyContinue |
            Where-Object { Get-CoreVersionFromName $_.Name }
    }

    if ($Packages.Count -eq 0) { return $null }
    $Selected = $Packages | Sort-Object Name -Descending | Select-Object -First 1
    $Ver = Get-CoreVersionFromName $Selected.Name
    $Sha = Get-Sha256FromSidecar $Selected.FullName
    return New-CorePackageInfo 'local' $Selected.FullName '' $Selected.Name $Ver $Sha
}

function Get-OnlineLatestCorePackageInfo {
    Log 'Checking latest official MetaCubeX/mihomo release from GitHub.'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $Headers = @{ 'User-Agent' = 'Clash-for-Windows-Meta-Core-Patch-Installer/1.5.4' }
    $Release = Invoke-RestMethod -Uri $GitHubLatestApi -Headers $Headers -UseBasicParsing -TimeoutSec 30
    $Asset = $Release.assets |
        Where-Object { $_.name -match '^mihomo-windows-amd64-compatible-v[0-9]+(\.[0-9]+){1,3}\.zip$' } |
        Select-Object -First 1
    if ($null -eq $Asset) { throw 'The latest Mihomo release does not contain windows-amd64-compatible zip asset.' }

    $Sha = $null
    if ($Asset.PSObject.Properties.Name -contains 'digest' -and $Asset.digest -match '^sha256:([a-fA-F0-9]{64})$') {
        $Sha = $Matches[1].ToUpperInvariant()
    }
    elseif ($KnownCoreSha256.ContainsKey([string]$Asset.name)) {
        $Sha = $KnownCoreSha256[[string]$Asset.name].ToUpperInvariant()
    }
    else {
        throw 'GitHub did not provide a SHA-256 digest for the latest asset. Use bundled-core local installation for this release.'
    }

    $Ver = Get-CoreVersionFromName ([string]$Asset.name)
    return New-CorePackageInfo 'online' '' ([string]$Asset.browser_download_url) ([string]$Asset.name) $Ver $Sha
}

function Resolve-ManualCorePackage([string]$ZipPath) {
    $ZipPath = $ZipPath.Trim().Trim('"')
    if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) { throw "Manual Mihomo package not found: $ZipPath" }
    $Name = [IO.Path]::GetFileName($ZipPath)
    $Ver = Get-CoreVersionFromName $Name
    if ([string]::IsNullOrWhiteSpace($Ver)) {
        throw 'Manual package name must look like mihomo-windows-amd64-compatible-v1.19.29.zip'
    }
    $Sha = Get-Sha256FromSidecar $ZipPath
    if ([string]::IsNullOrWhiteSpace($Sha)) {
        throw 'Manual package requires a .sha256 sidecar file, or must be a known checked release.'
    }
    return New-CorePackageInfo 'manual' $ZipPath '' $Name $Ver $Sha
}

function Select-CorePackage([string]$ManualZip) {
    if (-not [string]::IsNullOrWhiteSpace($ManualZip)) {
        Log 'Using manually specified Mihomo package.'
        return Resolve-ManualCorePackage $ManualZip
    }

    $Local = Find-BundledCorePackage
    Write-Host ''
    Write-Host ''
    Write-Host '安装器支持在线和本地两种核心来源。'
    Write-Host '网络可以访问 GitHub 时建议选择在线最新版；无法访问时请选择本地核心。'
    Write-Host '请选择 Mihomo 核心来源：'
    Write-Host '  [1] 从 GitHub 下载官方最新稳定版 Mihomo 核心（默认，需要能够访问 GitHub）'
    if ($null -ne $Local) {
        Write-Host ("  [2] 使用安装包中的本地 Mihomo 核心：{0}" -f $Local.AssetName)
    }
    else {
        Write-Host '  [2] 使用安装包中的本地 Mihomo 核心：未检测到可用文件'
    }
    Write-Host ''
    $Choice = Read-Host '请输入 1 或 2，直接按回车默认选择 1'
    if ([string]::IsNullOrWhiteSpace($Choice)) { $Choice = '1' }

    if ($Choice -eq '2') {
        if ($null -eq $Local) {
            throw '没有找到本地 Mihomo 核心。请将 mihomo-windows-amd64-compatible-v*.zip 放入 bundled-core 文件夹，并附带 .sha256 校验文件。'
        }
        return $Local
    }

    try {
        $Online = Get-OnlineLatestCorePackageInfo
        $Online.Path = Join-Path ([IO.Path]::GetTempPath()) $Online.AssetName
        if (-not (Test-Path -LiteralPath $Online.Path -PathType Leaf)) {
            Download-File $Online.Url $Online.Path $Online.AssetName
        }
        else {
            Log "Using Mihomo package from the temporary directory: $($Online.AssetName)"
        }
        return $Online
    }
    catch {
        Log ('Online Mihomo core download/check failed: ' + $_.Exception.Message)
        if ($null -ne $Local) {
            $Fallback = Read-Host '在线下载失败。是否改用安装包中的本地核心继续安装？[Y/n]'
            if ([string]::IsNullOrWhiteSpace($Fallback) -or $Fallback -match '^(y|Y)') {
                return $Local
            }
        }
        throw
    }
}

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    $Encoding = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($Path, $Content, $Encoding)
}

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$Arguments = @(),
        [switch]$LogOutput
    )

    $PreviousErrorActionPreference = $ErrorActionPreference
    try {
        # Windows PowerShell 5.1 converts native stderr into ErrorRecord objects.
        # With ErrorActionPreference=Stop, harmless WinSW messages such as
        # WMI.WmiException: NoSuchService become terminating PowerShell errors.
        $ErrorActionPreference = 'Continue'
        $Output = @(& $FilePath @Arguments 2>&1)
        $ExitCode = $LASTEXITCODE
        if ($null -eq $ExitCode) { $ExitCode = -1 }
    }
    finally {
        $ErrorActionPreference = $PreviousErrorActionPreference
    }

    if ($LogOutput) {
        foreach ($Line in $Output) {
            $Text = [string]$Line
            if (-not [string]::IsNullOrWhiteSpace($Text)) { Log $Text }
        }
    }
    return [int]$ExitCode
}

function Invoke-Icacls([string[]]$Arguments) {
    $ExitCode = Invoke-NativeCommand -FilePath 'icacls.exe' -Arguments $Arguments
    if ($ExitCode -ne 0) {
        throw "icacls failed with exit code $ExitCode"
    }
    # Do not copy icacls native output into install.log. Its OEM encoding can
    # display Chinese profile paths as mojibake even though the ACL is correct.
    Log ("ACL updated: {0}" -f $Arguments[0])
}

function Stop-ExistingService([string]$ServiceDir) {
    try {
        Invoke-RestMethod -Uri 'http://127.0.0.1:53000/stop' -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue | Out-Null
    } catch {}

    $ExistingWinSW = Join-Path $ServiceDir 'service.exe'
    if (Test-Path -LiteralPath $ExistingWinSW) {
        [void](Invoke-NativeCommand -FilePath $ExistingWinSW -Arguments @('stop'))
        [void](Invoke-NativeCommand -FilePath $ExistingWinSW -Arguments @('uninstall'))
    }

    [void](Invoke-NativeCommand -FilePath 'schtasks.exe' -Arguments @('/End', '/TN', 'Clash Core Service'))
    [void](Invoke-NativeCommand -FilePath 'schtasks.exe' -Arguments @('/Delete', '/F', '/TN', 'Clash Core Service'))

    $ExistingService = Get-Service -Name 'Clash Core Service' -ErrorAction SilentlyContinue
    if ($null -ne $ExistingService) {
        try { Stop-Service -Name 'Clash Core Service' -Force -ErrorAction SilentlyContinue } catch {}
        [void](Invoke-NativeCommand -FilePath 'sc.exe' -Arguments @('delete', 'Clash Core Service'))
    }

    Get-Process -Name 'clash-core-service' -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue

    for ($i = 0; $i -lt 30; $i++) {
        if ($null -eq (Get-Service -Name 'Clash Core Service' -ErrorAction SilentlyContinue)) { break }
        Start-Sleep -Milliseconds 500
    }
    if ($null -ne (Get-Service -Name 'Clash Core Service' -ErrorAction SilentlyContinue)) {
        throw 'The existing Clash Core Service could not be removed. Restart Windows and run the installer again.'
    }
    Log 'Existing Clash Core Service cleanup completed; an absent old service is treated as normal.'
}

function Install-WinSWService(
    [string]$StaticServiceDir,
    [string]$CommonDir,
    [string]$ServiceDir,
    [string]$HelperSource
) {
    Stop-ExistingService $ServiceDir
    if (Test-Path -LiteralPath $ServiceDir) {
        for ($i = 0; $i -lt 10; $i++) {
            try {
                Remove-Item -LiteralPath $ServiceDir -Recurse -Force -ErrorAction Stop
                break
            } catch {
                if ($i -eq 9) { throw }
                Start-Sleep -Milliseconds 500
            }
        }
    }
    New-Item -ItemType Directory -Path $ServiceDir -Force | Out-Null

    $WinSWSource = Join-Path $StaticServiceDir 'service.exe'
    $YamlSource = Join-Path $CommonDir 'service.yml'
    if (-not (Test-Path -LiteralPath $WinSWSource)) { throw "Missing WinSW executable: $WinSWSource" }
    if (-not (Test-Path -LiteralPath $YamlSource)) { throw "Missing service configuration: $YamlSource" }

    Copy-Item -LiteralPath $HelperSource -Destination (Join-Path $ServiceDir 'clash-core-service.exe') -Force
    Copy-Item -LiteralPath $WinSWSource -Destination (Join-Path $ServiceDir 'service.exe') -Force
    Copy-Item -LiteralPath $YamlSource -Destination (Join-Path $ServiceDir 'service.yml') -Force

    $ServiceExe = Join-Path $ServiceDir 'service.exe'
    $InstallExitCode = Invoke-NativeCommand -FilePath $ServiceExe -Arguments @('install') -LogOutput
    if ($InstallExitCode -ne 0) { throw "WinSW service install failed with exit code $InstallExitCode" }
    $RegisteredService = $null
    for ($i = 0; $i -lt 20; $i++) {
        $RegisteredService = Get-Service -Name 'Clash Core Service' -ErrorAction SilentlyContinue
        if ($null -ne $RegisteredService) { break }
        Start-Sleep -Milliseconds 250
    }
    if ($null -eq $RegisteredService) {
        throw 'WinSW reported a successful install, but Windows did not register Clash Core Service.'
    }

    $StartExitCode = Invoke-NativeCommand -FilePath $ServiceExe -Arguments @('start') -LogOutput
    if ($StartExitCode -ne 0) { throw "WinSW service start failed with exit code $StartExitCode" }

    $Ready = $false
    for ($i = 0; $i -lt 20; $i++) {
        try {
            $Ping = Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:53000/ping' -TimeoutSec 2
            if ($Ping.StatusCode -eq 200 -and $Ping.Content -match '^pong 1\.4\.0') {
                $Ready = $true
                break
            }
        } catch {}
        Start-Sleep -Milliseconds 500
    }
    if (-not $Ready) { throw 'The privileged core service was installed but did not respond on 127.0.0.1:53000.' }
    Log 'Privileged core service is active.'
}

try {
    if (-not (Test-IsAdministrator)) { Restart-Elevated }

    Set-Content -LiteralPath $LogFile -Value ("Clash for Windows Meta Core Patch $PatchVersion installer started at " + (Get-Date)) -Encoding UTF8
    Log "Script directory: $PSScriptRoot"
    Log 'Administrator privileges confirmed.'
    if (-not (Test-Path -LiteralPath $UserHome -PathType Container)) { throw "Original user profile not found: $UserHome" }
    if ($UserSid -notmatch '^S-1-') { throw "Invalid original user SID: $UserSid" }
    Log "Original Clash for Windows user profile: $UserHome"

    $TargetDir = Resolve-TargetDir $TargetDir
    $TargetExe = Join-Path $TargetDir 'Clash for Windows.exe'
    $ResourcesDir = Join-Path $TargetDir 'resources'
    $PayloadApp = Join-Path $PSScriptRoot 'payload\app'
    $HelperPayload = Join-Path $PSScriptRoot 'payload\clash-core-service.exe'
    $ElevatorPayload = Join-Path $PSScriptRoot 'payload\tools\cfw-elevate.exe'
    $UpdaterPayload = Join-Path $PSScriptRoot 'payload\tools\cfw-mihomo-update.ps1'

    if (-not (Test-Path -LiteralPath $TargetExe)) { throw "Missing: $TargetExe" }
    if (-not (Test-Path -LiteralPath $ResourcesDir -PathType Container)) { throw "Missing: $ResourcesDir" }
    if (-not (Test-Path -LiteralPath (Join-Path $PayloadApp 'package.json'))) { throw 'Patch payload is incomplete.' }
    if (-not (Test-Path -LiteralPath $HelperPayload)) { throw 'Privileged service helper is missing from the patch.' }
    if (-not (Test-Path -LiteralPath $ElevatorPayload)) { throw 'Native elevation helper is missing from the patch.' }
    if (-not (Test-Path -LiteralPath $UpdaterPayload)) { throw 'Mihomo updater is missing from the patch.' }

    $RendererPayload = Join-Path $PayloadApp 'dist\electron\renderer.js'
    $RendererText = Get-Content -LiteralPath $RendererPayload -Raw
    if ($RendererText -notmatch 'Mihomo-1\.5\.4' -or $RendererText -notmatch 'native-uac-v1\.5\.4' -or $RendererText -notmatch 'CFW-Meta-Core-Patch-Updater/1\.5\.4') {
        throw 'The v1.5.4 Electron payload failed its integrity marker check.'
    }

    $CorePackage = Select-CorePackage $MihomoZip
    $MihomoZip = $CorePackage.Path
    $AssetName = $CorePackage.AssetName
    $Version = $CorePackage.Version
    $ExpectedSha256 = $CorePackage.ExpectedSha256

    if (-not (Test-Path -LiteralPath $MihomoZip)) { throw "Mihomo package not found: $MihomoZip" }
    if ([string]::IsNullOrWhiteSpace($ExpectedSha256)) {
        throw "Missing SHA-256 for Mihomo package: $AssetName"
    }
    $ActualSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $MihomoZip).Hash.ToUpperInvariant()
    if ($ActualSha256 -ne $ExpectedSha256.ToUpperInvariant()) {
        if ($CorePackage.Source -eq 'online') { Remove-Item -LiteralPath $MihomoZip -Force -ErrorAction SilentlyContinue }
        throw "SHA-256 mismatch. Expected $ExpectedSha256 but received $ActualSha256."
    }
    Log ("Mihomo package SHA-256 verified. Source: {0}; Version: {1}" -f $CorePackage.Source, $Version)

    $TempDir = Join-Path ([IO.Path]::GetTempPath()) ('cfw-mihomo-' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    try {
        Expand-Archive -LiteralPath $MihomoZip -DestinationPath $TempDir -Force
        $MihomoExe = Get-ChildItem -LiteralPath $TempDir -Recurse -File -Filter '*.exe' |
            Where-Object { $_.Name -match '^mihomo.*\.exe$' } |
            Select-Object -First 1
        if ($null -eq $MihomoExe) { throw 'No Mihomo executable was found in the official package.' }

        Log 'Stopping Clash for Windows, service core and stale local cores.'
        Get-Process -Name 'Clash for Windows' -ErrorAction SilentlyContinue |
            Stop-Process -Force -ErrorAction SilentlyContinue
        Get-Process -Name 'clash-win64' -ErrorAction SilentlyContinue |
            Stop-Process -Force -ErrorAction SilentlyContinue
        Get-Process -Name 'mihomo' -ErrorAction SilentlyContinue |
            Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 800

        $OriginalAsar = Join-Path $ResourcesDir 'app.asar'
        $BackupAsar = Join-Path $ResourcesDir 'app.asar.cfw-original'
        $RuntimeApp = Join-Path $ResourcesDir 'app'
        $RuntimeAppBackup = Join-Path $ResourcesDir 'app.cfw-before-mihomo'
        $CoreDir = Join-Path $ResourcesDir 'static\files\win\x64'
        $CommonDir = Join-Path $ResourcesDir 'static\files\win\common'
        $CoreExe = Join-Path $CoreDir 'clash-win64.exe'
        $BackupCore = Join-Path $CoreDir 'clash-win64.cfw-original.exe'
        $WintunDll = Join-Path $CoreDir 'wintun.dll'
        $StaticServiceDir = Join-Path $CoreDir 'service'
        $StaticHelper = Join-Path $StaticServiceDir 'clash-core-service.exe'
        $StaticHelperBackup = Join-Path $StaticServiceDir 'clash-core-service.cfw-original.exe'

        if (-not (Test-Path -LiteralPath $CoreDir)) { throw "Missing Clash for Windows core directory: $CoreDir" }
        if (-not (Test-Path -LiteralPath $StaticServiceDir)) { throw "Missing Clash for Windows service directory: $StaticServiceDir" }
        if (-not (Test-Path -LiteralPath $WintunDll)) { throw "Missing Wintun driver library: $WintunDll" }

        if ((Test-Path -LiteralPath $OriginalAsar) -and -not (Test-Path -LiteralPath $BackupAsar)) {
            Move-Item -LiteralPath $OriginalAsar -Destination $BackupAsar -Force
            Log 'Backed up app.asar.'
        }
        elseif (Test-Path -LiteralPath $OriginalAsar) {
            Remove-Item -LiteralPath $OriginalAsar -Force
        }

        if (Test-Path -LiteralPath $RuntimeApp) {
            if (Test-Path -LiteralPath $BackupAsar) {
                # A previous patch attempt already backed up the original app.asar.
                # The unpacked app directory is therefore patch residue, not an
                # original CFW runtime that should be preserved.
                Remove-Item -LiteralPath $RuntimeApp -Recurse -Force
                Log 'Removed the incomplete runtime left by a previous patch attempt.'
            }
            elseif (-not (Test-Path -LiteralPath $RuntimeAppBackup)) {
                Move-Item -LiteralPath $RuntimeApp -Destination $RuntimeAppBackup -Force
            }
            else {
                Remove-Item -LiteralPath $RuntimeApp -Recurse -Force
            }
        }
        Copy-Item -LiteralPath $PayloadApp -Destination $RuntimeApp -Recurse -Force
        Log 'Installed patched Electron runtime with Service/TUN authentication support.'

        Copy-Item -LiteralPath $ElevatorPayload -Destination (Join-Path $CommonDir 'cfw-elevate.exe') -Force
        Copy-Item -LiteralPath $UpdaterPayload -Destination (Join-Path $CommonDir 'cfw-mihomo-update.ps1') -Force
        Log 'Installed the native UAC helper and Mihomo progress updater.'
        $InstalledUpdater = Join-Path $CommonDir 'cfw-mihomo-update.ps1'
        $UpdaterText = Get-Content -LiteralPath $InstalledUpdater -Raw
        if ($UpdaterText -notmatch "UpdaterVersion = '1\.5\.4'" -or $UpdaterText.IndexOf([char]0x201C) -ge 0 -or $UpdaterText.IndexOf([char]0x201D) -ge 0) { throw 'The installed updater failed its PowerShell compatibility check.' }

        if ((Test-Path -LiteralPath $CoreExe) -and -not (Test-Path -LiteralPath $BackupCore)) {
            Copy-Item -LiteralPath $CoreExe -Destination $BackupCore -Force
            Log 'Backed up the original Clash core.'
        }
        Copy-Item -LiteralPath $MihomoExe.FullName -Destination $CoreExe -Force
        Log 'Installed Mihomo as clash-win64.exe.'

        if ((Test-Path -LiteralPath $StaticHelper) -and -not (Test-Path -LiteralPath $StaticHelperBackup)) {
            Copy-Item -LiteralPath $StaticHelper -Destination $StaticHelperBackup -Force
            Log 'Backed up the original Clash for Windows service helper.'
        }
        Copy-Item -LiteralPath $HelperPayload -Destination $StaticHelper -Force
        Log 'Installed the authenticated privileged service helper into Clash for Windows resources.'

        $ClashHome = Join-Path $UserHome '.config\clash'
        New-Item -ItemType Directory -Path $ClashHome -Force | Out-Null
        $TokenBytes = New-Object byte[] 32
        [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($TokenBytes)
        $Token = [Convert]::ToBase64String($TokenBytes)
        $TokenHashBytes = [Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Token))
        $TokenHash = ([BitConverter]::ToString($TokenHashBytes)).Replace('-', '').ToLowerInvariant()
        $TokenFile = Join-Path $ClashHome '.service-token'
        Write-Utf8NoBom $TokenFile $Token

        $ProgramDataDir = Join-Path $env:ProgramData 'CFW-Mihomo'
        New-Item -ItemType Directory -Path $ProgramDataDir -Force | Out-Null
        $ProtectedCore = Join-Path $ProgramDataDir 'clash-win64.exe'
        $ProtectedWintun = Join-Path $ProgramDataDir 'wintun.dll'
        $ServiceConfig = Join-Path $ProgramDataDir 'service-config.json'
        $PidFile = Join-Path $ProgramDataDir 'core.pid'
        Copy-Item -LiteralPath $CoreExe -Destination $ProtectedCore -Force
        Copy-Item -LiteralPath $WintunDll -Destination $ProtectedWintun -Force
        $ProtectedCoreHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $ProtectedCore).Hash.ToLowerInvariant()

        $ConfigObject = [ordered]@{
            tokenSha256 = $TokenHash
            requestedCorePath = [IO.Path]::GetFullPath($CoreExe)
            protectedCorePath = [IO.Path]::GetFullPath($ProtectedCore)
            protectedCoreSha256 = $ProtectedCoreHash
            allowedWorkingDirectory = [IO.Path]::GetFullPath($ClashHome)
            pidFile = [IO.Path]::GetFullPath($PidFile)
        }
        Write-Utf8NoBom $ServiceConfig ($ConfigObject | ConvertTo-Json -Depth 3)

        Invoke-Icacls -Arguments @($ProgramDataDir, '/inheritance:r', '/grant:r', '*S-1-5-18:(OI)(CI)F', '*S-1-5-32-544:(OI)(CI)F')
        Invoke-Icacls -Arguments @($TokenFile, '/inheritance:r', '/grant:r', '*S-1-5-18:(F)', '*S-1-5-32-544:(F)', ('*{0}:(F)' -f $UserSid))
        Log 'Protected the service core, configuration and authentication token with Windows ACLs.'

        $ServiceRoot = if ($env:ProgramW6432) { $env:ProgramW6432 } else { $env:ProgramFiles }
        $ServiceDir = Join-Path $ServiceRoot 'Clash for Windows Service'
        Install-WinSWService $StaticServiceDir $CommonDir $ServiceDir $HelperPayload

        $Marker = Join-Path $CoreDir 'MIHOMO_VERSION.txt'
        @(
            ("Mihomo {0}" -f $Version),
            ("SHA256(package): {0}" -f $ExpectedSha256),
            'Clash for Windows Meta Core Patch v1.5.4.1 installer / v1.5.4 runtime',
            'Service Mode: supported through authenticated loopback service',
            'TUN Mode: supported through protected SYSTEM core + bundled wintun.dll',
            'TAP/Virtual Adapter Mode: uses original Clash for Windows TAP + go-tun2socks chain',
            'Mixin Mode: original YAML/JavaScript mixin pipeline retained'
        ) | Set-Content -LiteralPath $Marker -Encoding UTF8
    }
    finally {
        Remove-Item -LiteralPath $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Log 'Installation completed successfully.'
    Write-Host ''
    Write-Host 'Clash for Windows Meta Core Patch v1.5.4.1 已安装完成。'
    Write-Host '服务模式、TUN 模式、TAP 虚拟网卡、混合配置和软件内 Mihomo 核心更新功能已启用。'
    Write-Host '现在可以正常启动 Clash for Windows。服务模式应显示为已安装或正在运行。'
    exit 0
}
catch {
    Log ('ERROR: ' + $_.Exception.Message)
    Write-Host ''
    Write-Host '安装已停止。请查看 install.log；不要将未完成的安装视为成功。'
    exit 1
}
