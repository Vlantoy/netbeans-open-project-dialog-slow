# Re-enable NetBeans dirchooser module (undo disable-dirchooser.ps1)

param(
    [string]$NetBeansVersion = "17"
)

$ErrorActionPreference = "Stop"
$modFile = Join-Path $env:APPDATA "NetBeans\$NetBeansVersion\config\Modules\org-netbeans-swing-dirchooser.xml"

if (-not (Test-Path $modFile)) {
    Write-Host "No override file found (module already at install default)." -ForegroundColor Yellow
    Write-Host "Looked for: $modFile"
    exit 0
}

$xml = @"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE module PUBLIC "-//NetBeans//DTD Module Status 1.0//EN"
                        "http://www.netbeans.org/dtds/module-status-1_0.dtd">
<module name="org.netbeans.swing.dirchooser">
    <param name="autoload">false</param>
    <param name="eager">false</param>
    <param name="enabled">true</param>
    <param name="jar">modules/org-netbeans-swing-dirchooser.jar</param>
    <param name="reloadable">false</param>
</module>
"@

[System.IO.File]::WriteAllText($modFile, $xml.Trim() + "`n", [System.Text.UTF8Encoding]::new($false))

Write-Host "Enabled org.netbeans.swing.dirchooser" -ForegroundColor Green
Write-Host "File: $modFile"
Write-Host "Restart NetBeans for changes to apply." -ForegroundColor Cyan
