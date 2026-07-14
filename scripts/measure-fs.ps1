# Quick filesystem timing: local project folder vs OneDrive defaults
# Helps prove "disk is fine, dialog is not".

$ErrorActionPreference = "Continue"

function Measure-List([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host ("MISSING  {0}" -f $Path) -ForegroundColor DarkYellow
        return
    }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $n = @(Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue).Count
    $sw.Stop()
    Write-Host ("{0,6} ms  n={1,-5}  {2}" -f $sw.ElapsedMilliseconds, $n, $Path)
}

Write-Host "=== Folder list timings ===" -ForegroundColor Cyan

$candidates = @(
    "D:\NetBeansProjects",
    "C:\Users\$env:USERNAME\NetBeansProjects",
    "$env:USERPROFILE\Documents\NetBeansProjects",
    "$env:OneDrive\Desktop",
    "$env:OneDrive\Documents"
)

# Discover OneDrive commercial path if present
Get-ChildItem "$env:USERPROFILE" -Directory -Filter "OneDrive*" -ErrorAction SilentlyContinue | ForEach-Object {
    $candidates += (Join-Path $_.FullName "Desktop")
    $candidates += (Join-Path $_.FullName "Documents")
}

$candidates | Select-Object -Unique | ForEach-Object { Measure-List $_ }

Write-Host ""
Write-Host "If local project dirs are a few ms but Open Project still takes ~30s," -ForegroundColor Green
Write-Host "the bottleneck is almost certainly the file dialog / ShellFolder path." -ForegroundColor Green
Write-Host "Try: .\scripts\disable-dirchooser.ps1" -ForegroundColor Cyan
