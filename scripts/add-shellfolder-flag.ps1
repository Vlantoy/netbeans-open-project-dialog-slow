# Optional: append -J-Dnb.FileChooser.useShellFolder=false to netbeans.conf
# Requires Administrator. Prefer disable-dirchooser.ps1 first (no admin).

param(
    [string]$ConfPath = "C:\Program Files\NetBeans-17\netbeans\etc\netbeans.conf"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ConfPath)) {
    Write-Host "Conf not found: $ConfPath" -ForegroundColor Red
    Write-Host "Pass -ConfPath to your install's netbeans\etc\netbeans.conf"
    exit 1
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
    IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Re-launching elevated..." -ForegroundColor Yellow
    $arg = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -ConfPath `"$ConfPath`""
    Start-Process powershell -Verb RunAs -ArgumentList $arg -Wait
    exit $LASTEXITCODE
}

$bak = "$ConfPath.bak-shellfolder"
if (-not (Test-Path $bak)) {
    Copy-Item $ConfPath $bak -Force
    Write-Host "Backup: $bak"
}

$c = [System.IO.File]::ReadAllText($ConfPath)
if ($c -match 'nb\.FileChooser\.useShellFolder') {
    Write-Host "Flag already present." -ForegroundColor Yellow
    exit 0
}

if ($c -notmatch 'netbeans_default_options="') {
    Write-Host "Could not find netbeans_default_options in conf." -ForegroundColor Red
    exit 1
}

$flag = " -J-Dnb.FileChooser.useShellFolder=false"
$c2 = $c -replace '(netbeans_default_options=")([^"]*)(")', ('$1$2' + $flag + '$3')
[System.IO.File]::WriteAllText($ConfPath, $c2)
Write-Host "Patched: $ConfPath" -ForegroundColor Green
Write-Host "Restart NetBeans. If still slow, run disable-dirchooser.ps1" -ForegroundColor Cyan
