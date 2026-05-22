# Claude Brain Setup — Quick non-interactive installer (Windows PowerShell)
# Usage:
#   .\scripts\install.ps1
#   .\scripts\install.ps1 -DryRun
#   .\scripts\install.ps1 -Target "C:\Users\You\mydir"
#
# No admin rights required.

[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$Target = $env:USERPROFILE
)

$ErrorActionPreference = 'Stop'

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$SourceFile  = Join-Path $ProjectRoot 'CLAUDE.md'
$OutputFile  = Join-Path $Target 'CLAUDE.md'

Write-Host ""
Write-Host "Claude Brain Setup — Quick Installer (Windows)" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "[DRY RUN] No files will be written." -ForegroundColor Yellow
}
Write-Host "Source : $SourceFile"
Write-Host "Target : $OutputFile"
Write-Host ""

# Verify source exists
if (-not (Test-Path $SourceFile)) {
    Write-Error "Source CLAUDE.md not found at: $SourceFile`nRun this script from the claude-brain-setup directory."
    exit 1
}

# Verify target directory exists (create if needed)
if (-not (Test-Path $Target)) {
    if ($DryRun) {
        Write-Host "[DRY RUN] Would create directory: $Target"
    } else {
        New-Item -ItemType Directory -Path $Target -Force | Out-Null
        Write-Host "Created directory: $Target"
    }
}

# Backup existing CLAUDE.md
if (Test-Path $OutputFile) {
    $Timestamp  = Get-Date -Format 'yyyyMMdd_HHmmss'
    $BackupFile = "$OutputFile.backup_$Timestamp"
    if ($DryRun) {
        Write-Host "[DRY RUN] Would back up existing CLAUDE.md to: $BackupFile"
    } else {
        Copy-Item $OutputFile $BackupFile
        Write-Host "Backed up existing CLAUDE.md to: $BackupFile"
    }
}

# Copy CLAUDE.md
if ($DryRun) {
    Write-Host "[DRY RUN] Would copy CLAUDE.md to: $OutputFile"
    Write-Host ""
    Write-Host "[DRY RUN] Complete. No files were written." -ForegroundColor Yellow
    exit 0
}

Copy-Item $SourceFile $OutputFile
Write-Host ""
Write-Host "Done! CLAUDE.md installed to: $OutputFile" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Launch Claude Code with your preferred model:"
Write-Host "     claude --model claude-sonnet-4-6"
Write-Host ""
Write-Host "  2. Verify Claude loaded your configuration:"
Write-Host "     Ask: `"What instructions are you following from CLAUDE.md?`""
Write-Host ""
Write-Host "  3. For a personalized setup (recommended), run:"
Write-Host "     .\scripts\setup.ps1"
Write-Host ""
