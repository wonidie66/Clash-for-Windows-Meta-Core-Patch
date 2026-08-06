param(
    [Parameter(Mandatory = $true)]
    [string]$CfwRoot,
    [string]$UserHome = $env:USERPROFILE,
    [string]$ProgressFile = '',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$UpdaterVersion = '1.5.4'
$ApiUrl = 'https://api.github.com/repos/MetaCubeX/mihomo/releases/latest'
$ProgressSequence = 0

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Get-ParentDirectory([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    return [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($Path))
}

function Publish-Progress(
    [string]$Stage,
    [int]$Percent,
    [string]$Message,
    [string]$Detail = '',
    [bool]$Done = $false,
    [bool]$Success = $false,
    [string]$ErrorMessage = ''
) {
    if ([string]::IsNullOrWhiteSpace($ProgressFile)) { return }
    try {
        $script:ProgressSequence++
        $parent = Get-ParentDirectory $ProgressFile
        if (-not [string]::IsNullOrWhiteSpace($parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        $state = [ordered]@{
            schema = 1
            updaterVersion = $UpdaterVersion
            sequence = $script:ProgressSequence
            timestamp = (Get-Date).ToString('o')
            stage = $Stage
            percent = [Math]::Max(0, [Math]::Min(100, $Percent))
            message = $Message
            detail = $Detail
            done = $Done
            success = $Success
            error = $ErrorMessage
        }
        $json = $state | ConvertTo-Json -Depth 5
        $tmp = $ProgressFile + '.tmp-' + $PID + '-' + [Guid]::NewGuid().ToString('N')
        Write-Utf8NoBom $tmp $json
        if (Test-Path -LiteralPath $ProgressFile -PathType Leaf) {
            try { [IO.File]::Replace($tmp, $ProgressFile, $null) }
            catch {
                Copy-Item -LiteralPath $tmp -Destination $ProgressFile -Force
                Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
            }
        }
        else {
            [IO.File]::Move($tmp, $ProgressFile)
        }
    }
    catch {
        # Progress reporting must never abort a core update.
    }
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Normalize-Version([string]$Value) {
    if ($Value -match '(?i)v?(\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?)') {
        return $Matches[1]
    }
    return $null
}

function Compare-SemVer([string]$Left, [string]$Right) {
    $l = Normalize-Version $Left
    $r = Normalize-Version $Right
    if ($null -eq $l -or $null -eq $r) {
        return [string]::Compare($Left, $Right, $true)
    }
    $lp = $l.Split('-', 2)
    $rp = $r.Split('-', 2)
    $ln = $lp[0].Split('.') | ForEach-Object { [int]$_ }
    $rn = $rp[0].Split('.') | ForEach-Object { [int]$_ }
    for ($i = 0; $i -lt 3; $i++) {
        if ($ln[$i] -lt $rn[$i]) { return -1 }
        if ($ln[$i] -gt $rn[$i]) { return 1 }
    }
    $lPre = if ($lp.Count -gt 1) { $lp[1] } else { '' }
    $rPre = if ($rp.Count -gt 1) { $rp[1] } else { '' }
    if ($lPre -eq '' -and $rPre -eq '') { return 0 }
    if ($lPre -eq '') { return 1 }
    if ($rPre -eq '') { return -1 }
    return [string]::CompareOrdinal($lPre, $rPre)
}

function Format-Bytes([long]$Value) {
    if ($Value -ge 1GB) { return ('{0:N2} GB' -f ($Value / 1GB)) }
    if ($Value -ge 1MB) { return ('{0:N2} MB' -f ($Value / 1MB)) }
    if ($Value -ge 1KB) { return ('{0:N1} KB' -f ($Value / 1KB)) }
    return "$Value B"
}

function Download-File([string]$Url, [string]$Destination, [hashtable]$Headers) {
    Publish-Progress 'download' 20 '正在下载 Mihomo 官方核心' '正在连接 GitHub Release 资源。'
    try {
        $request = [Net.HttpWebRequest]::Create($Url)
        $request.Method = 'GET'
        $request.AllowAutoRedirect = $true
        $request.MaximumAutomaticRedirections = 10
        $request.Timeout = 30000
        $request.ReadWriteTimeout = 30000
        $request.UserAgent = [string]$Headers['User-Agent']
        $request.Accept = 'application/octet-stream'
        $response = $request.GetResponse()
        try {
            $total = [long]$response.ContentLength
            $input = $response.GetResponseStream()
            $output = [IO.File]::Open($Destination, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
            try {
                $buffer = New-Object byte[] (1024 * 256)
                [long]$received = 0
                $lastPercent = -1
                while (($read = $input.Read($buffer, 0, $buffer.Length)) -gt 0) {
                    $output.Write($buffer, 0, $read)
                    $received += $read
                    if ($total -gt 0) {
                        $downloadPercent = [int][Math]::Floor(($received * 100.0) / $total)
                        $overall = 20 + [int][Math]::Floor($downloadPercent * 0.35)
                        if ($overall -ge ($lastPercent + 1)) {
                            $lastPercent = $overall
                            Publish-Progress 'download' $overall '正在下载 Mihomo 官方核心' ((Format-Bytes $received) + ' / ' + (Format-Bytes $total))
                        }
                    }
                    elseif (($received % (2MB)) -lt $read) {
                        Publish-Progress 'download' 35 '正在下载 Mihomo 官方核心' ((Format-Bytes $received) + '，服务器未提供总大小。')
                    }
                }
            }
            finally {
                if ($null -ne $output) { $output.Dispose() }
                if ($null -ne $input) { $input.Dispose() }
            }
        }
        finally {
            if ($null -ne $response) { $response.Dispose() }
        }
        Publish-Progress 'download' 55 'Mihomo 核心下载完成' (Format-Bytes ((Get-Item -LiteralPath $Destination).Length))
        return
    }
    catch {
        Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
        Log ('Native HTTP download failed, trying curl.exe: ' + $_.Exception.Message)
        Publish-Progress 'download' 30 '原生下载失败，正在使用 curl.exe 重试' $_.Exception.Message
    }

    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($null -eq $curl) { throw 'Download failed and curl.exe is unavailable.' }
    & $curl.Source -L --fail --retry 3 --retry-delay 2 --connect-timeout 20 `
        -A 'CFW-Meta-Core-Patch-Updater/1.5.4' -o $Destination $Url
    if ($LASTEXITCODE -ne 0) { throw "curl.exe download failed with exit code $LASTEXITCODE" }
    Publish-Progress 'download' 55 'Mihomo 核心下载完成' (Format-Bytes ((Get-Item -LiteralPath $Destination).Length))
}

function Get-CoreVersion([string]$CorePath) {
    if (-not (Test-Path -LiteralPath $CorePath -PathType Leaf)) { return $null }
    try {
        $output = (& $CorePath -v 2>&1 | Out-String)
        return Normalize-Version $output
    }
    catch { return $null }
}

function Stop-CoreSafely([string]$TokenFile) {
    if (Test-Path -LiteralPath $TokenFile) {
        try {
            $token = (Get-Content -LiteralPath $TokenFile -Raw).Trim()
            if ($token) {
                Invoke-RestMethod -Uri 'http://127.0.0.1:53000/stop' -Method Get `
                    -Headers @{'X-CFW-Mihomo-Token' = $token} -TimeoutSec 3 | Out-Null
                Log 'Stopped the protected core through the authenticated service API.'
            }
        }
        catch { Log ('Service API stop was unavailable: ' + $_.Exception.Message) }
    }
    Get-Process -Name 'clash-win64' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Get-Process -Name 'mihomo' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 800
}

function Replace-FileAtomically([string]$Source, [string]$Target) {
    $directory = Get-ParentDirectory $Target
    if ([string]::IsNullOrWhiteSpace($directory)) { throw "Unable to resolve the target directory: $Target" }
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    $staged = Join-Path $directory (([IO.Path]::GetFileName($Target)) + '.cfw-new-' + [Guid]::NewGuid().ToString('N'))
    Copy-Item -LiteralPath $Source -Destination $staged -Force
    try {
        if (Test-Path -LiteralPath $Target -PathType Leaf) {
            try { [IO.File]::Replace($staged, $Target, $null) }
            catch { [IO.File]::Copy($staged, $Target, $true) }
        }
        else { Move-Item -LiteralPath $staged -Destination $Target -Force }
    }
    finally { Remove-Item -LiteralPath $staged -Force -ErrorAction SilentlyContinue }
}

function Test-ServiceReady {
    for ($i = 0; $i -lt 30; $i++) {
        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:53000/ping' -TimeoutSec 2
            if ($response.StatusCode -eq 200 -and $response.Content -match '^pong ') { return $true }
        }
        catch {}
        Start-Sleep -Milliseconds 500
    }
    return $false
}

function Get-TextSha256([string]$Text) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally { $sha.Dispose() }
}

function Get-OrCreateServiceToken([string]$Path) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $existing = (Get-Content -LiteralPath $Path -Raw).Trim()
        if (-not [string]::IsNullOrWhiteSpace($existing)) { return $existing }
    }
    $bytes = New-Object byte[] 32
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    $token = [Convert]::ToBase64String($bytes)
    Write-Utf8NoBom $Path $token
    return $token
}

function Set-ObjectProperty($Object, [string]$Name, $Value) {
    if ($Object.PSObject.Properties.Name -contains $Name) { $Object.$Name = $Value }
    else { $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $Value }
}

function Repair-ServiceConfig([string]$ProtectedHash) {
    $configObject = $null
    if (Test-Path -LiteralPath $ServiceConfig -PathType Leaf) {
        try {
            $raw = [IO.File]::ReadAllText($ServiceConfig, [Text.Encoding]::UTF8)
            $configObject = $raw | ConvertFrom-Json
        }
        catch {
            Log ('Existing service-config.json is invalid and will be rebuilt: ' + $_.Exception.Message)
            Publish-Progress 'service-config' 90 '检测到损坏的服务配置，正在自动重建' $_.Exception.Message
        }
    }
    if ($null -eq $configObject) { $configObject = New-Object PSObject }
    $token = Get-OrCreateServiceToken $TokenFile
    Set-ObjectProperty $configObject 'tokenSha256' (Get-TextSha256 $token)
    Set-ObjectProperty $configObject 'requestedCorePath' ([IO.Path]::GetFullPath($LocalCore))
    Set-ObjectProperty $configObject 'protectedCorePath' ([IO.Path]::GetFullPath($ProtectedCore))
    Set-ObjectProperty $configObject 'protectedCoreSha256' $ProtectedHash
    Set-ObjectProperty $configObject 'allowedWorkingDirectory' ([IO.Path]::GetFullPath($ClashHome))
    Set-ObjectProperty $configObject 'pidFile' ([IO.Path]::GetFullPath((Join-Path $ProgramDataDir 'core.pid')))
    Write-Utf8NoBom $ServiceConfig ($configObject | ConvertTo-Json -Depth 6)
    # Read it back immediately so invalid JSON can never reach the service.
    [void]([IO.File]::ReadAllText($ServiceConfig, [Text.Encoding]::UTF8) | ConvertFrom-Json)
}

if (-not (Test-IsAdministrator)) {
    Publish-Progress 'error' 100 '更新程序未获得管理员权限' '请通过 Clash for Windows 内部的一键更新按钮启动。' $true $false 'Administrator privileges are required.'
    Write-Error 'The updater must be started through the Clash for Windows Meta Core Patch elevation helper.'
    exit 5
}
if (-not (Test-Path -LiteralPath $CfwRoot -PathType Container)) { Write-Error "Clash for Windows root does not exist: $CfwRoot"; exit 6 }
$CfwRoot = (Resolve-Path -LiteralPath $CfwRoot).Path
if (-not (Test-Path -LiteralPath (Join-Path $CfwRoot 'Clash for Windows.exe') -PathType Leaf)) {
    Write-Error "The selected directory is not a Clash for Windows installation: $CfwRoot"; exit 7
}
if ([string]::IsNullOrWhiteSpace($UserHome)) { $UserHome = $env:USERPROFILE }
$ClashHome = Join-Path $UserHome '.config\clash'
New-Item -ItemType Directory -Path $ClashHome -Force | Out-Null
$LogFile = Join-Path $ClashHome 'mihomo-updater.log'

function Log([string]$Message) {
    $line = '[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Write-Host $line
    Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8
}

$CfwExe = Join-Path $CfwRoot 'Clash for Windows.exe'
$ResourcesDir = Join-Path $CfwRoot 'resources'
$CoreDir = Join-Path $ResourcesDir 'static\files\win\x64'
$LocalCore = Join-Path $CoreDir 'clash-win64.exe'
$MarkerFile = Join-Path $CoreDir 'MIHOMO_VERSION.txt'
$ProgramDataDir = Join-Path $env:ProgramData 'CFW-Mihomo'
$ProtectedCore = Join-Path $ProgramDataDir 'clash-win64.exe'
$ServiceConfig = Join-Path $ProgramDataDir 'service-config.json'
$TokenFile = Join-Path $ClashHome '.service-token'
$ServiceName = 'Clash Core Service'
$TempDir = Join-Path $env:TEMP ('CFW-Mihomo-Update-' + [Guid]::NewGuid().ToString('N'))
$LocalBackup = $LocalCore + '.cfw-last-good'
$ProtectedBackup = $ProtectedCore + '.cfw-last-good'
$ConfigBackup = $ServiceConfig + '.cfw-last-good'
$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
$serviceWasRunning = $null -ne $service -and $service.Status -eq 'Running'
$changedLocal = $false
$changedProtected = $false
$changedConfig = $false

try {
    Set-Content -LiteralPath $LogFile -Value ("Clash for Windows Meta Core Patch updater $UpdaterVersion started at " + (Get-Date)) -Encoding UTF8
    Publish-Progress 'initializing' 2 '正在初始化 Mihomo 更新程序' "Clash for Windows：$CfwRoot"
    Log "Clash for Windows root: $CfwRoot"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $headers = @{
        'User-Agent' = 'CFW-Meta-Core-Patch-Updater/1.5.4'
        'Accept' = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
    }
    Publish-Progress 'checking' 6 '正在检查 Mihomo 官方最新版本' '数据来源：MetaCubeX/mihomo GitHub Releases'
    Log 'Checking the official MetaCubeX/mihomo latest release.'
    $release = Invoke-RestMethod -Uri $ApiUrl -Headers $headers -Method Get -TimeoutSec 30
    if ($release.draft -or $release.prerelease) { throw 'The GitHub latest endpoint returned a draft or prerelease.' }

    $latestVersion = Normalize-Version ([string]$release.tag_name)
    if ($null -eq $latestVersion) { throw 'Unable to parse the latest Mihomo version.' }
    $assetPattern = '^mihomo-windows-amd64-compatible-v?([0-9A-Za-z.-]+)\.zip$'
    $asset = @($release.assets | Where-Object { $_.name -match $assetPattern } | Select-Object -First 1)
    if ($asset.Count -eq 0) { throw 'The compatible Windows AMD64 Mihomo asset was not found.' }
    $asset = $asset[0]
    $digestText = [string]$asset.digest
    if ($digestText -notmatch '^sha256:([0-9a-fA-F]{64})$') {
        throw 'GitHub did not provide a trustworthy SHA-256 digest for the selected asset.'
    }
    $expectedSha256 = $Matches[1].ToUpperInvariant()
    $currentVersion = Get-CoreVersion $LocalCore
    if ($null -eq $currentVersion) { $currentVersion = '0.0.0' }
    Log "Current Mihomo: $currentVersion; latest: $latestVersion"
    Publish-Progress 'checking' 12 '版本检查完成' ("当前：v$currentVersion；最新：v$latestVersion")

    if (-not $Force -and (Compare-SemVer $currentVersion $latestVersion) -ge 0) {
        Log 'Mihomo is already up to date.'
        Publish-Progress 'complete' 100 'Mihomo 已是最新版本' ("当前版本：v$currentVersion") $true $true ''
        Write-Host "UP_TO_DATE $currentVersion"
        exit 0
    }

    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    $zipPath = Join-Path $TempDir ([string]$asset.name)
    Log ('Downloading ' + [string]$asset.name)
    Download-File ([string]$asset.browser_download_url) $zipPath $headers

    Publish-Progress 'verify' 58 '正在校验官方 SHA-256' $expectedSha256
    $actualSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath).Hash.ToUpperInvariant()
    if ($actualSha256 -ne $expectedSha256) {
        throw "Downloaded package SHA-256 mismatch. Expected $expectedSha256, got $actualSha256"
    }
    Log 'Official package SHA-256 verified.'
    Publish-Progress 'verify' 62 '官方 SHA-256 校验通过' $actualSha256

    $extractDir = Join-Path $TempDir 'extracted'
    Publish-Progress 'extract' 65 '正在解压 Mihomo 核心' ([string]$asset.name)
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force
    $candidate = Get-ChildItem -LiteralPath $extractDir -Recurse -File -Filter '*.exe' |
        Where-Object { $_.Name -match '^mihomo.*\.exe$' } | Select-Object -First 1
    if ($null -eq $candidate) { throw 'The downloaded package did not contain a Mihomo executable.' }

    Publish-Progress 'validate' 69 '正在验证新核心版本和配置兼容性' ("目标版本：v$latestVersion")
    $candidateVersion = Get-CoreVersion $candidate.FullName
    if ($candidateVersion -ne $latestVersion) {
        throw "Candidate version mismatch. Expected $latestVersion, got $candidateVersion"
    }
    if (Test-Path -LiteralPath (Join-Path $ClashHome 'config.yaml')) {
        $validationOutput = (& $candidate.FullName -t -d $ClashHome 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0) { throw ('The new core rejected the current configuration: ' + $validationOutput.Trim()) }
        Log 'The new core accepted the current Clash for Windows configuration.'
    }
    Publish-Progress 'validate' 73 '新核心验证通过' ("Mihomo v$candidateVersion")

    if (-not (Test-Path -LiteralPath $LocalCore -PathType Leaf)) { throw "The installed Clash for Windows core was not found: $LocalCore" }
    Publish-Progress 'backup' 76 '正在备份当前核心和服务配置' '出现异常时将自动回滚。'
    Copy-Item -LiteralPath $LocalCore -Destination $LocalBackup -Force
    if (Test-Path -LiteralPath $ProtectedCore -PathType Leaf) {
        Copy-Item -LiteralPath $ProtectedCore -Destination $ProtectedBackup -Force
    }
    if (Test-Path -LiteralPath $ServiceConfig -PathType Leaf) {
        Copy-Item -LiteralPath $ServiceConfig -Destination $ConfigBackup -Force
    }

    Publish-Progress 'stopping' 80 '正在停止当前核心' 'Clash for Windows 界面将保持打开，更新完成后再重新加载。'
    Stop-CoreSafely $TokenFile
    if ($serviceWasRunning) {
        Stop-Service -Name $ServiceName -Force -ErrorAction Stop
        for ($i = 0; $i -lt 30; $i++) {
            $currentService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
            if ($null -eq $currentService -or $currentService.Status -eq 'Stopped') { break }
            Start-Sleep -Milliseconds 300
        }
        Log 'Stopped the privileged helper service for atomic core replacement.'
    }

    Publish-Progress 'replace-local' 84 '正在替换 Clash for Windows 本地核心' ([IO.Path]::GetFileName($LocalCore))
    $changedLocal = $true
    Replace-FileAtomically $candidate.FullName $LocalCore
    Log 'Updated the local Clash for Windows core.'

    if (Test-Path -LiteralPath $ProgramDataDir -PathType Container) {
        Publish-Progress 'replace-service' 88 '正在同步 Service Mode 核心' $ProtectedCore
        $changedProtected = $true
        Replace-FileAtomically $candidate.FullName $ProtectedCore
        $newProtectedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $ProtectedCore).Hash.ToLowerInvariant()
        $changedConfig = $true
        Repair-ServiceConfig $newProtectedHash
        Log 'Updated and validated the Service Mode configuration and core hash pin.'
        Publish-Progress 'service-config' 92 'Service Mode 配置已同步并校验' '中文用户名路径已按 UTF-8 JSON 重新写入。'

        & icacls.exe $ProgramDataDir /inheritance:r /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Failed to restore the protected ProgramData ACL.' }
    }

    $installedVersion = Get-CoreVersion $LocalCore
    if ($installedVersion -ne $latestVersion) { throw "Post-installation version verification failed: $installedVersion" }

    @(
        "Mihomo v$latestVersion",
        "SHA256(package): $expectedSha256",
        "Updated: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))",
        'Updater: Clash for Windows Meta Core Patch v1.5.4 official-release updater',
        'Asset: windows-amd64-compatible'
    ) | Set-Content -LiteralPath $MarkerFile -Encoding UTF8

    $stateObject = [ordered]@{
        version = $latestVersion
        updatedAt = (Get-Date).ToString('o')
        asset = [string]$asset.name
        packageSha256 = $expectedSha256.ToLowerInvariant()
        releaseUrl = [string]$release.html_url
        updaterVersion = $UpdaterVersion
    }
    Write-Utf8NoBom (Join-Path $ClashHome 'mihomo-update.json') ($stateObject | ConvertTo-Json -Depth 4)

    if ($serviceWasRunning) {
        Publish-Progress 'restart-service' 96 '正在重新启动并验证 Service Mode' '等待 127.0.0.1:53000 响应。'
        Start-Service -Name $ServiceName -ErrorAction Stop
        if (-not (Test-ServiceReady)) { throw 'The privileged helper service did not become ready after the update.' }
        Log 'Restarted and verified the privileged helper service.'
    }

    Log "Mihomo update completed successfully: $currentVersion -> $latestVersion"
    Publish-Progress 'complete' 100 'Mihomo 核心更新完成' ("v$currentVersion → v$latestVersion；点击 [重新加载 Clash for Windows] 恢复连接。") $true $true ''
    Write-Host "UPDATED $currentVersion $latestVersion"
    exit 0
}
catch {
    $failure = $_.Exception.Message
    try { Log ('ERROR: ' + $failure) } catch {}
    Publish-Progress 'rollback' 96 '更新失败，正在自动回滚' $failure
    try {
        if ($serviceWasRunning) { Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue }
        Stop-CoreSafely $TokenFile
        if ($changedLocal -and (Test-Path -LiteralPath $LocalBackup)) { Replace-FileAtomically $LocalBackup $LocalCore }
        if ($changedProtected -and (Test-Path -LiteralPath $ProtectedBackup)) { Replace-FileAtomically $ProtectedBackup $ProtectedCore }
        if ($changedConfig -and (Test-Path -LiteralPath $ConfigBackup)) { Replace-FileAtomically $ConfigBackup $ServiceConfig }
        if ($serviceWasRunning) { Start-Service -Name $ServiceName -ErrorAction SilentlyContinue }
        Log 'Rollback completed.'
        Publish-Progress 'failed' 100 'Mihomo 更新失败，已完成回滚' $failure $true $false $failure
    }
    catch {
        $rollbackFailure = $_.Exception.Message
        try { Log ('ROLLBACK ERROR: ' + $rollbackFailure) } catch {}
        Publish-Progress 'failed' 100 'Mihomo 更新失败，回滚也发生异常' ($failure + "`n回滚错误：" + $rollbackFailure) $true $false ($failure + '; ' + $rollbackFailure)
    }
    Write-Error $failure
    exit 1
}
finally {
    Remove-Item -LiteralPath $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
