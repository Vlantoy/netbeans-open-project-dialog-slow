# Find NetBeans JVM and print how to capture EDT stacks during Open Project freeze.

$ErrorActionPreference = "Continue"

$jps = @(
    "${env:ProgramFiles}\Java\jdk-17\bin\jps.exe",
    "${env:ProgramFiles}\Java\jdk-21\bin\jps.exe",
    "${env:JAVA_HOME}\bin\jps.exe"
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

$jcmd = $null
if ($jps) {
    $jcmd = Join-Path (Split-Path $jps) "jcmd.exe"
}

Write-Host "=== NetBeans / Java processes ===" -ForegroundColor Cyan
Get-Process netbeans64, java -ErrorAction SilentlyContinue |
    Format-Table Id, ProcessName, @{N='MB';E={[math]::Round($_.WorkingSet64/1MB)}} -AutoSize

if ($jps) {
    Write-Host "=== jps -l ===" -ForegroundColor Cyan
    & $jps -l
    Write-Host ""
    Write-Host "While Open Project is FROZEN, run:" -ForegroundColor Yellow
    Write-Host "  & `"$jcmd`" <PID> Thread.print > `$env:TEMP\nb-edt-dump.txt" -ForegroundColor Green
    Write-Host "Then open the file and search for: AWT-EventQueue, ShellFolder, dirchooser, JFileChooser" -ForegroundColor Cyan
} else {
    Write-Host "jps not found. Install a JDK and use: jcmd <pid> Thread.print" -ForegroundColor Yellow
}

$nb = Get-Process netbeans64 -ErrorAction SilentlyContinue | Select-Object -First 1
if ($nb -and $jcmd -and (Test-Path $jcmd)) {
    Write-Host ""
    Write-Host "Attempting one dump of PID $($nb.Id) (may be the launcher JVM on some installs)..." -ForegroundColor Cyan
    & $jcmd $nb.Id Thread.print 2>&1 | Select-String -Pattern 'AWT-EventQueue|ShellFolder|dirchooser|JFileChooser' | Select-Object -First 20
}
