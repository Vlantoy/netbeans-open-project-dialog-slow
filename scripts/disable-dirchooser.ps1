# Disable NetBeans dirchooser module (fixes Open Project ~30s freeze on some Windows setups)
# Safe: only writes under %APPDATA%\NetBeans\<ver>\config\Modules\
# Restart NetBeans after running.

param(
    [string]$NetBeansVersion = "17"
)

$ErrorActionPreference = "Stop"
$modDir = Join-Path $env:APPDATA "NetBeans\$NetBeansVersion\config\Modules"
$modFile = Join-Path $modDir "org-netbeans-swing-dirchooser.xml"

if (-not (Test-Path (Join-Path $env:APPDATA "NetBeans\$NetBeansVersion"))) {
    Write-Host "NetBeans userdir not found: $env:APPDATA\NetBeans\$NetBeansVersion" -ForegroundColor Red
    Write-Host "Pass -NetBeansVersion (e.g. 20, 21, 22) if you use another release." -ForegroundColor Yellow
    exit 1
}

New-Item -ItemType Directory -Path $modDir -Force | Out-Null

if (Test-Path $modFile) {
    $bak = "$modFile.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $modFile $bak -Force
    Write-Host "Backup: $bak"
}

$xml = @"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE module PUBLIC "-//NetBeans//DTD Module Status 1.0//EN"
                        "http://www.netbeans.org/dtds/module-status-1_0.dtd">
<module name="org.netbeans.swing.dirchooser">
    <param name="autoload">false</param>
    <param name="eager">false</param>
    <param name="enabled">false</param>
    <param name="jar">modules/org-netbeans-swing-dirchooser.jar</param>
    <param name="reloadable">false</param>
</module>
"@

[System.IO.File]::WriteAllText($modFile, $xml.Trim() + "`n", [System.Text.UTF8Encoding]::new($false))

Write-Host "Disabled org.netbeans.swing.dirchooser" -ForegroundColor Green
Write-Host "File: $modFile"
Write-Host ""
Write-Host "NEXT: Fully exit NetBeans (File -> Exit), start again, then File -> Open Project." -ForegroundColor Cyan
if (Get-Process netbeans64 -ErrorAction SilentlyContinue) {
    Write-Host "NetBeans is currently RUNNING - restart required." -ForegroundColor Yellow
}
