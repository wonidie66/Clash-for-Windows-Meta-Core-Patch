param(
    [string]$TargetDir = '',
    [string]$MihomoZip = '',
    [string]$UserHome = '',
    [string]$UserSid = ''
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$PatchVersion = 'v1.5.3'
$Version = 'v1.19.29'
$AssetName = 'mihomo-windows-amd64-compatible-v1.19.29.zip'
$DownloadUrl = "https://github.com/MetaCubeX/mihomo/releases/download/$Version/$AssetName"
$ExpectedSha256 = '322AAA5957BA9E72AFDDA9B71CC4329F691D2D45EC39E70BBCA3F7BF5AA93D52'
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
    Write-Host 'Service/TUN installation requires Administrator privileges. Requesting UAC elevation...'
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
    Write-Host 'Enter the Clash for Windows installation directory.'
    Write-Host 'You may also paste the full path of Clash for Windows.exe.'
    $InputPath = Read-Host 'Clash for Windows path'
    $Resolved = Normalize-Target $InputPath
    if ($null -eq $Resolved) {
        throw 'The selected path does not contain Clash for Windows.exe.'
    }
    return $Resolved
}

function Download-File([string]$Url, [string]$OutFile) {
    Log "Downloading official Mihomo core: $AssetName"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $OutFile
    }
    catch {
        Log "Invoke-WebRequest failed: $($_.Exception.Message)"
        $Curl = Get-Command curl.exe -ErrorAction SilentlyContinue
        if ($null -eq $Curl) { throw }
        & $Curl.Source -L --fail --retry 3 --connect-timeout 20 -o $OutFile $Url
        if ($LASTEXITCODE -ne 0) {
            throw "Download failed. Put $AssetName next to install.ps1 and run install.cmd again."
        }
    }
}

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    $Encoding = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($Path, $Content, $Encoding)
}

function Invoke-Icacls([string[]]$Arguments) {
    & icacls.exe @Arguments | ForEach-Object { Log $_ }
    if ($LASTEXITCODE -ne 0) {
        throw "icacls failed with exit code $LASTEXITCODE"
    }
}

function Stop-ExistingService([string]$ServiceDir) {
    try {
        Invoke-RestMethod -Uri 'http://127.0.0.1:53000/stop' -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue | Out-Null
    } catch {}

    $ExistingWinSW = Join-Path $ServiceDir 'service.exe'
    if (Test-Path -LiteralPath $ExistingWinSW) {
        & $ExistingWinSW stop 2>$null | Out-Null
        & $ExistingWinSW uninstall 2>$null | Out-Null
    }
    & schtasks.exe /End /TN 'Clash Core Service' 2>$null | Out-Null
    & schtasks.exe /Delete /F /TN 'Clash Core Service' 2>$null | Out-Null
    Get-Service -Name 'Clash Core Service' -ErrorAction SilentlyContinue |
        Stop-Service -Force -ErrorAction SilentlyContinue
    Get-Process -Name 'clash-core-service' -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    for ($i = 0; $i -lt 20; $i++) {
        if ($null -eq (Get-Service -Name 'Clash Core Service' -ErrorAction SilentlyContinue)) { break }
        Start-Sleep -Milliseconds 500
    }
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
    & $ServiceExe install | ForEach-Object { Log $_ }
    if ($LASTEXITCODE -ne 0) { throw "WinSW service install failed with exit code $LASTEXITCODE" }
    & $ServiceExe start | ForEach-Object { Log $_ }
    if ($LASTEXITCODE -ne 0) { throw "WinSW service start failed with exit code $LASTEXITCODE" }

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
    if ($RendererText -notmatch 'Mihomo-1\.5\.3' -or $RendererText -notmatch 'native-uac-v1\.5\.3' -or $RendererText -notmatch 'CFW-Meta-Core-Patch-Updater/1\.5\.3') {
        throw 'The v1.5.3 Electron payload failed its integrity marker check.'
    }

    if ([string]::IsNullOrWhiteSpace($MihomoZip)) {
        $LocalZip = Join-Path $PSScriptRoot $AssetName
        if (Test-Path -LiteralPath $LocalZip) {
            $MihomoZip = $LocalZip
            Log 'Using Mihomo package found next to the installer.'
        }
        else {
            $MihomoZip = Join-Path ([IO.Path]::GetTempPath()) $AssetName
            if (-not (Test-Path -LiteralPath $MihomoZip)) {
                Download-File $DownloadUrl $MihomoZip
            }
            else {
                Log 'Using Mihomo package from the temporary directory.'
            }
        }
    }

    if (-not (Test-Path -LiteralPath $MihomoZip)) { throw "Mihomo package not found: $MihomoZip" }
    $ActualSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $MihomoZip).Hash.ToUpperInvariant()
    if ($ActualSha256 -ne $ExpectedSha256) {
        Remove-Item -LiteralPath $MihomoZip -Force -ErrorAction SilentlyContinue
        throw "SHA-256 mismatch. Expected $ExpectedSha256 but received $ActualSha256."
    }
    Log 'Mihomo package SHA-256 verified.'

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
            if (-not (Test-Path -LiteralPath $RuntimeAppBackup)) {
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
        if ($UpdaterText -notmatch "UpdaterVersion = '1\.5\.3'" -or $UpdaterText.IndexOf([char]0x201C) -ge 0 -or $UpdaterText.IndexOf([char]0x201D) -ge 0) { throw 'The installed updater failed its PowerShell compatibility check.' }

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
            'Mihomo v1.19.29',
            "SHA256(package): $ExpectedSha256",
            'Clash for Windows Meta Core Patch v1.5.3',
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
    Write-Host 'Clash for Windows Meta Core Patch v1.5.3 is ready.'
    Write-Host 'Service Mode, TUN Mode, TAP/Virtual Adapter Mode, Mixin and the in-app Mihomo updater are enabled.'
    Write-Host 'Start Clash for Windows normally. Service Mode should already show as installed/running.'
    exit 0
}
catch {
    Log ('ERROR: ' + $_.Exception.Message)
    Write-Host ''
    Write-Host 'Installation stopped. Review install.log. Do not treat a partial installation as successful.'
    exit 1
}
