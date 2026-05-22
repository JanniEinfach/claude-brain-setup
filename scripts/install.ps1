# Claude Brain Setup — Quick non-interactive installer (Windows PowerShell)
# Usage:
#   .\scripts\install.ps1
#   .\scripts\install.ps1 -DryRun
#   .\scripts\install.ps1 -Target "C:\Users\You\mydir"
#   .\scripts\install.ps1 -WithSkills     # also install bundled Brain skills
#   .\scripts\install.ps1 -SkillsOnly     # only install skills, skip CLAUDE.md
#
# No admin rights required.

[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$Target = $env:USERPROFILE,
    [switch]$WithSkills,
    [switch]$SkillsOnly
)

$ErrorActionPreference = 'Stop'

# -SkillsOnly implies -WithSkills
if ($SkillsOnly) { $WithSkills = $true }

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

# Install CLAUDE.md unless -SkillsOnly
if (-not $SkillsOnly) {
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
    } else {
        Copy-Item $SourceFile $OutputFile
        Write-Host "Done! CLAUDE.md installed to: $OutputFile" -ForegroundColor Green
    }
}

# Install bundled Brain skills if requested
if ($WithSkills) {
    $SkillsSrc  = Join-Path $ProjectRoot 'skills'
    $SkillsDest = Join-Path $env:USERPROFILE '.claude\skills'

    if (-not (Test-Path $SkillsSrc)) {
        Write-Warning "skills\ directory not found at: $SkillsSrc. Skipping skill install."
    } else {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would install bundled Brain skills to: $SkillsDest"
        } else {
            if (-not (Test-Path $SkillsDest)) {
                New-Item -ItemType Directory -Path $SkillsDest -Force | Out-Null
            }
            Write-Host ""
            Write-Host "Installing bundled Brain skills to: $SkillsDest" -ForegroundColor Cyan
            $Timestamp    = Get-Date -Format 'yyyyMMdd_HHmmss'
            $InstalledCount = 0

            Get-ChildItem -Path $SkillsSrc -Directory | ForEach-Object {
                $SkillName = $_.Name
                $DestSkill = Join-Path $SkillsDest $SkillName

                if (Test-Path $DestSkill) {
                    $BackupName = "${DestSkill}.backup_${Timestamp}"
                    Rename-Item -Path $DestSkill -NewName $BackupName
                    Write-Host "  Backed up existing: $SkillName"
                }

                Copy-Item -Path $_.FullName -Destination $DestSkill -Recurse
                Write-Host "  Installed: $SkillName"
                $InstalledCount++
            }

            Write-Host "  Total: $InstalledCount skill(s) installed" -ForegroundColor Green
        }
    }
}

if ($DryRun) {
    Write-Host ""
    Write-Host "[DRY RUN] Complete. No files were written." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Next steps:"
if (-not $SkillsOnly) {
    Write-Host "  1. Launch Claude Code with your preferred model:"
    Write-Host "     claude --model claude-sonnet-4-6"
    Write-Host ""
    Write-Host "  2. Verify Claude loaded your configuration:"
    Write-Host "     Ask: `"What instructions are you following from CLAUDE.md?`""
    Write-Host ""
    Write-Host "  3. For a personalized setup (recommended), run:"
    Write-Host "     .\scripts\setup.ps1"
    Write-Host ""
}
if (-not $WithSkills) {
    Write-Host "  Install bundled Brain skills:"
    Write-Host "     .\scripts\install.ps1 -WithSkills"
    Write-Host ""
}
