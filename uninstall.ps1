param(
    [string]$TargetDir = '',
    [string]$UserHome = ''
)

$ErrorActionPreference = 'Stop'
$LogFile = Join-Path $PSScriptRoot 'uninstall.log'
if ([string]::IsNullOrWhiteSpace($UserHome)) { $UserHome = $env:USERPROFILE }

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

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$Arguments = @()
    )
    $PreviousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $null = @(& $FilePath @Arguments 2>&1)
        $ExitCode = $LASTEXITCODE
        if ($null -eq $ExitCode) { $ExitCode = -1 }
    }
    finally {
        $ErrorActionPreference = $PreviousErrorActionPreference
    }
    return [int]$ExitCode
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
    if (Test-Path -LiteralPath (Join-Path $Resolved 'Clash for Windows.exe')) { return $Resolved }
    return $null
}

function Restart-Elevated {
    $Args = '-NoLogo -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $PSCommandPath
    if (-not [string]::IsNullOrWhiteSpace($TargetDir)) {
        $Args += ' -TargetDir "{0}"' -f ($TargetDir -replace '"', '\"')
    }
    $Args += ' -UserHome "{0}"' -f ($UserHome -replace '"', '\"')
    $Process = Start-Process -FilePath 'powershell.exe' -Verb RunAs -Wait -PassThru -ArgumentList $Args
    exit $Process.ExitCode
}

try {
    if (-not (Test-IsAdministrator)) { Restart-Elevated }

    Set-Content -LiteralPath $LogFile -Value ('Clash for Windows Meta Core Patch v1.5.4.1 restore started at ' + (Get-Date)) -Encoding UTF8
    $Resolved = Normalize-Target $TargetDir
    if ($null -eq $Resolved) {
        foreach ($Candidate in @($PSScriptRoot, (Split-Path $PSScriptRoot -Parent), (Get-Location).Path)) {
            $Resolved = Normalize-Target $Candidate
            if ($null -ne $Resolved) { break }
        }
    }
    if ($null -eq $Resolved) {
        $InputPath = Read-Host 'Enter the Clash for Windows installation directory or full exe path'
        $Resolved = Normalize-Target $InputPath
    }
    if ($null -eq $Resolved) { throw 'The selected path does not contain Clash for Windows.exe.' }

    $ResourcesDir = Join-Path $Resolved 'resources'
    $RuntimeApp = Join-Path $ResourcesDir 'app'
    $RuntimeAppBackup = Join-Path $ResourcesDir 'app.cfw-before-mihomo'
    $BackupAsar = Join-Path $ResourcesDir 'app.asar.cfw-original'
    $OriginalAsar = Join-Path $ResourcesDir 'app.asar'
    $CoreDir = Join-Path $ResourcesDir 'static\files\win\x64'
    $CoreExe = Join-Path $CoreDir 'clash-win64.exe'
    $BackupCore = Join-Path $CoreDir 'clash-win64.cfw-original.exe'
    $StaticServiceDir = Join-Path $CoreDir 'service'
    $StaticHelper = Join-Path $StaticServiceDir 'clash-core-service.exe'
    $StaticHelperBackup = Join-Path $StaticServiceDir 'clash-core-service.cfw-original.exe'

    Get-Process -Name 'Clash for Windows' -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    try {
        $TokenPath = Join-Path $UserHome '.config\clash\.service-token'
        if (Test-Path -LiteralPath $TokenPath) {
            $Token = [IO.File]::ReadAllText($TokenPath).Trim()
            Invoke-RestMethod -Uri 'http://127.0.0.1:53000/stop' -Headers @{'X-CFW-Mihomo-Token'=$Token} -TimeoutSec 2 -ErrorAction SilentlyContinue | Out-Null
        }
    } catch {}

    $ServiceRoot = if ($env:ProgramW6432) { $env:ProgramW6432 } else { $env:ProgramFiles }
    $ServiceDir = Join-Path $ServiceRoot 'Clash for Windows Service'
    $ServiceExe = Join-Path $ServiceDir 'service.exe'
    if (Test-Path -LiteralPath $ServiceExe) {
        [void](Invoke-NativeCommand -FilePath $ServiceExe -Arguments @('stop'))
        [void](Invoke-NativeCommand -FilePath $ServiceExe -Arguments @('uninstall'))
    }
    [void](Invoke-NativeCommand -FilePath 'schtasks.exe' -Arguments @('/End', '/TN', 'Clash Core Service'))
    [void](Invoke-NativeCommand -FilePath 'schtasks.exe' -Arguments @('/Delete', '/F', '/TN', 'Clash Core Service'))
    if ($null -ne (Get-Service -Name 'Clash Core Service' -ErrorAction SilentlyContinue)) {
        try { Stop-Service -Name 'Clash Core Service' -Force -ErrorAction SilentlyContinue } catch {}
        [void](Invoke-NativeCommand -FilePath 'sc.exe' -Arguments @('delete', 'Clash Core Service'))
    }
    Start-Sleep -Milliseconds 800
    Remove-Item -LiteralPath $ServiceDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $env:ProgramData 'CFW-Mihomo') -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $UserHome '.config\clash\.service-token') -Force -ErrorAction SilentlyContinue
    Log 'Removed the patch privileged service and protected core.'

    if (Test-Path -LiteralPath $RuntimeApp) { Remove-Item -LiteralPath $RuntimeApp -Recurse -Force }
    if (Test-Path -LiteralPath $BackupAsar) {
        Move-Item -LiteralPath $BackupAsar -Destination $OriginalAsar -Force
        Log 'Restored app.asar.'
    }
    elseif (Test-Path -LiteralPath $RuntimeAppBackup) {
        Move-Item -LiteralPath $RuntimeAppBackup -Destination $RuntimeApp -Force
        Log 'Restored the previous unpacked app directory.'
    }
    if (Test-Path -LiteralPath $BackupCore) {
        Copy-Item -LiteralPath $BackupCore -Destination $CoreExe -Force
        Log 'Restored the original Clash core.'
    }
    if (Test-Path -LiteralPath $StaticHelperBackup) {
        Copy-Item -LiteralPath $StaticHelperBackup -Destination $StaticHelper -Force
        Log 'Restored the original Clash for Windows service helper.'
    }
    Remove-Item -LiteralPath (Join-Path $CoreDir 'MIHOMO_VERSION.txt') -Force -ErrorAction SilentlyContinue
    Log 'Restore completed. User profiles and subscription files were not deleted.'
    exit 0
}
catch {
    Log ('ERROR: ' + $_.Exception.Message)
    exit 1
}
