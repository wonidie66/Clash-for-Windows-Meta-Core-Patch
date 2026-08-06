param([string]$TargetDir = '')
$ErrorActionPreference = 'Continue'
function Normalize-Target([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    $Value = $Value.Trim().Trim('"')
    if (-not (Test-Path -LiteralPath $Value)) { return $null }
    $resolved = (Resolve-Path -LiteralPath $Value).Path
    if (Test-Path -LiteralPath $resolved -PathType Leaf) { $resolved = [IO.Path]::GetDirectoryName($resolved) }
    if (Test-Path -LiteralPath (Join-Path $resolved 'Clash for Windows.exe')) { return $resolved }
    return $null
}
$TargetDir = Normalize-Target $TargetDir
if ($null -eq $TargetDir) { $TargetDir = Normalize-Target (Read-Host 'Clash for Windows path') }
if ($null -eq $TargetDir) { Write-Host 'Invalid Clash for Windows path.'; exit 2 }
$homeDir = Join-Path $env:USERPROFILE '.config\clash'
$core = Join-Path $TargetDir 'resources\static\files\win\x64\clash-win64.exe'
$config = Join-Path $homeDir 'config.yaml'
Write-Host ('Clash for Windows root: ' + $TargetDir)
Write-Host ('User profile: ' + $env:USERPROFILE)
Write-Host ('Core exists: ' + (Test-Path -LiteralPath $core))
if (Test-Path -LiteralPath $core) { & $core -v }
Write-Host ('Config exists: ' + (Test-Path -LiteralPath $config))
if (Test-Path -LiteralPath $config) {
    $text = Get-Content -LiteralPath $config -Raw
    $controllerMatch = [regex]::Match($text, '(?m)^\s*external-controller\s*:\s*([^\r\n]+)')
    $controller = if ($controllerMatch.Success) { $controllerMatch.Groups[1].Value.Trim().Trim('"').Trim("'") } else { '' }
    $mixedMatch = [regex]::Match($text, '(?m)^\s*mixed-port\s*:\s*(\d+)')
    $mixed = if ($mixedMatch.Success) { $mixedMatch.Groups[1].Value } else { '' }
    Write-Host ('Config external-controller: ' + $(if ($controller) {$controller} else {'<missing>'}))
    Write-Host ('Config mixed-port: ' + $(if ($mixed) {$mixed} else {'<missing>'}))
}
Write-Host 'Processes:'
Get-Process -Name 'Clash for Windows','clash-win64','mihomo','clash-core-service' -ErrorAction SilentlyContinue | Select-Object Name,Id,Path | Format-Table -AutoSize
Write-Host 'Listening ports related to Clash for Windows:'
$corePids = @((Get-Process -Name 'clash-win64','mihomo' -ErrorAction SilentlyContinue).Id)
Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -in 7890,7897,9090,53000 -or $_.OwningProcess -in $corePids } | Select-Object LocalAddress,LocalPort,OwningProcess | Sort-Object LocalPort | Format-Table -AutoSize
Write-Host 'Service:'
Get-Service -Name 'Clash Core Service' -ErrorAction SilentlyContinue | Select-Object Name,Status,StartType | Format-Table -AutoSize
try {
    $ping = Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:53000/ping' -TimeoutSec 2
    Write-Host ('Service API: ' + $ping.Content)
} catch { Write-Host ('Service API unavailable: ' + $_.Exception.Message) }
