# Claude Brain Setup - Quick non-interactive installer (Windows PowerShell)
#
# Installs the generic default configuration without asking any questions:
#   - Root CLAUDE.md            -> ~/.claude/CLAUDE.md          (timestamped backup first)
#   - Brain runtime (always)    -> ~/.claude/brain/             (VERSION, config.json,
#                                                                check-update / update scripts, docs/)
#   - SessionStart update hook  -> ~/.claude/settings.json      (idempotent, backup first)
#   - Bundled Brain skills      -> ~/.claude/skills/            (only with -WithSkills)
#
# Usage:
#   .\scripts\install.ps1
#   .\scripts\install.ps1 -WithSkills       # also install bundled Brain skills
#   .\scripts\install.ps1 -SkillsOnly       # only skills + Brain runtime, skip CLAUDE.md
#   .\scripts\install.ps1 -DryRun           # show what would happen, write nothing
#   .\scripts\install.ps1 -NoUpdateCheck    # do not register the update hook
#
# No admin rights required. This script never deletes files - existing files
# are backed up with a timestamp before they are replaced.
#
# For a personalized configuration, run the interactive wizard instead:
#   .\scripts\setup.ps1

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$WithSkills,
    [switch]$SkillsOnly,
    [switch]$NoUpdateCheck
)

$ErrorActionPreference = 'Stop'

# -SkillsOnly implies -WithSkills
if ($SkillsOnly) { $WithSkills = $true }

# ---------------------------------------------------------------------------
# Paths and constants
# ---------------------------------------------------------------------------

$ScriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot   = Split-Path -Parent $ScriptDir
$Timestamp     = Get-Date -Format 'yyyyMMdd_HHmmss'

$SourceClaudeMd = Join-Path $ProjectRoot 'CLAUDE.md'
$SourceVersion  = Join-Path $ProjectRoot 'VERSION'
$SourceSkills   = Join-Path $ProjectRoot 'skills'
$SourceDocs     = Join-Path $ProjectRoot 'docs'

$ClaudeDir      = Join-Path $env:USERPROFILE '.claude'
$ClaudeMdDest   = Join-Path $ClaudeDir 'CLAUDE.md'
$SkillsDest     = Join-Path $ClaudeDir 'skills'
$BrainDir       = Join-Path $ClaudeDir 'brain'
$BrainBackups   = Join-Path $BrainDir 'backups'
$BrainDocs      = Join-Path $BrainDir 'docs'
$ConfigPath     = Join-Path $BrainDir 'config.json'
$SettingsPath   = Join-Path $ClaudeDir 'settings.json'
$V1ClaudeMd     = Join-Path $env:USERPROFILE 'CLAUDE.md'

$HookCommand    = 'powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.claude\brain\check-update.ps1"'
$RuntimeScripts = @('check-update.ps1', 'update.ps1', 'check-update.sh', 'update.sh')

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Confirm-Directory {
    param([string]$Path)
    if (Test-Path $Path) { return }
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would create directory: $Path"
    } else {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Backup-File {
    # Copies an existing file to <file>.backup_<timestamp>. Never deletes.
    param([string]$Path)
    if (-not (Test-Path $Path)) { return }
    $BackupPath = "$Path.backup_$Timestamp"
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would back up: $Path -> $BackupPath"
    } else {
        Copy-Item -Path $Path -Destination $BackupPath
        Write-Host "  Backed up: $Path -> $BackupPath"
    }
}

function Write-TextFile {
    # Writes text as UTF-8 without BOM (safe for JSON consumed by other tools).
    param([string]$Path, [string]$Content)
    [System.IO.File]::WriteAllText($Path, $Content)
}

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "Claude Brain Setup 2.0.0 - Quick Installer (Windows)" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "[DRY RUN] No files will be written." -ForegroundColor Yellow
}
Write-Host "Repository : $ProjectRoot"
Write-Host "Target     : $ClaudeDir"
Write-Host ""

# ---------------------------------------------------------------------------
# Step 1: CLAUDE.md -> ~/.claude/CLAUDE.md (unless -SkillsOnly)
# ---------------------------------------------------------------------------

if (-not $SkillsOnly) {
    Write-Host "[1/4] Installing CLAUDE.md" -ForegroundColor Cyan

    if (-not (Test-Path $SourceClaudeMd)) {
        Write-Error "Source CLAUDE.md not found at: $SourceClaudeMd`nRun this script from inside the claude-brain-setup directory."
        exit 1
    }

    Confirm-Directory $ClaudeDir
    Backup-File $ClaudeMdDest

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would copy CLAUDE.md to: $ClaudeMdDest"
    } else {
        Copy-Item -Path $SourceClaudeMd -Destination $ClaudeMdDest
        Write-Host "  Installed: $ClaudeMdDest" -ForegroundColor Green
    }

    # V1 migration hint: the old install location was ~/CLAUDE.md.
    if (Test-Path $V1ClaudeMd) {
        Write-Host ""
        Write-Warning "Found a CLAUDE.md from a previous version at: $V1ClaudeMd"
        Write-Host "  Two CLAUDE.md files can give Claude conflicting instructions." -ForegroundColor Yellow
        Write-Host "  The interactive wizard (scripts\setup.ps1) can migrate it safely" -ForegroundColor Yellow
        Write-Host "  (it renames the old file to a backup - nothing is deleted)." -ForegroundColor Yellow
    }
    Write-Host ""
} else {
    Write-Host "[1/4] Skipping CLAUDE.md (-SkillsOnly)" -ForegroundColor Cyan
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Step 2: Bundled Brain skills (only with -WithSkills / -SkillsOnly)
# ---------------------------------------------------------------------------

if ($WithSkills) {
    Write-Host "[2/4] Installing bundled Brain skills" -ForegroundColor Cyan

    if (-not (Test-Path $SourceSkills)) {
        Write-Warning "  skills\ directory not found at: $SourceSkills. Skipping skill install."
    } else {
        Confirm-Directory $SkillsDest
        $InstalledCount = 0

        Get-ChildItem -Path $SourceSkills -Directory | ForEach-Object {
            $SkillName = $_.Name
            $DestSkill = Join-Path $SkillsDest $SkillName

            if ($DryRun) {
                if (Test-Path $DestSkill) {
                    Write-Host "  [DRY RUN] Would back up existing skill: $SkillName"
                }
                Write-Host "  [DRY RUN] Would install skill: $SkillName"
            } else {
                if (Test-Path $DestSkill) {
                    Rename-Item -Path $DestSkill -NewName "$SkillName.backup_$Timestamp"
                    Write-Host "  Backed up existing: $SkillName -> $SkillName.backup_$Timestamp"
                }
                Copy-Item -Path $_.FullName -Destination $DestSkill -Recurse
                Write-Host "  Installed: $SkillName"
            }
            $InstalledCount++
        }

        Write-Host "  Total: $InstalledCount skill(s)" -ForegroundColor Green
    }
    Write-Host ""
} else {
    Write-Host "[2/4] Skipping skills (re-run with -WithSkills to install them)" -ForegroundColor Cyan
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Step 3: Brain runtime -> ~/.claude/brain/ (always)
# ---------------------------------------------------------------------------

Write-Host "[3/4] Installing Brain runtime" -ForegroundColor Cyan

Confirm-Directory $BrainDir
Confirm-Directory $BrainBackups

# Back up an existing runtime before refreshing it (never delete).
$BrainVersionPath = Join-Path $BrainDir 'VERSION'
if (Test-Path $BrainVersionPath) {
    $OldVersion = (Get-Content -Path $BrainVersionPath -Raw).Trim()
    $RuntimeBackupDir = Join-Path $BrainBackups "preinstall-$OldVersion-$Timestamp"
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would back up existing runtime to: $RuntimeBackupDir"
    } else {
        New-Item -ItemType Directory -Path $RuntimeBackupDir -Force | Out-Null
        Copy-Item -Path $BrainVersionPath -Destination $RuntimeBackupDir
        foreach ($ScriptName in $RuntimeScripts) {
            $Existing = Join-Path $BrainDir $ScriptName
            if (Test-Path $Existing) {
                Copy-Item -Path $Existing -Destination $RuntimeBackupDir
            }
        }
        Write-Host "  Backed up existing runtime to: $RuntimeBackupDir"
    }
}

# VERSION
if (Test-Path $SourceVersion) {
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would copy VERSION to: $BrainVersionPath"
    } else {
        Copy-Item -Path $SourceVersion -Destination $BrainVersionPath -Force
        Write-Host "  Installed: VERSION"
    }
} else {
    Write-Warning "  VERSION file not found at: $SourceVersion. Skipping."
}

# Runtime scripts (both platform variants, so the runtime dir is complete)
$NativeScriptMissing = $true
foreach ($ScriptName in $RuntimeScripts) {
    $ScriptSrc = Join-Path $ScriptDir $ScriptName
    if (Test-Path $ScriptSrc) {
        if ($ScriptName -eq 'check-update.ps1') { $NativeScriptMissing = $false }
        if ($DryRun) {
            Write-Host "  [DRY RUN] Would copy $ScriptName to: $BrainDir"
        } else {
            Copy-Item -Path $ScriptSrc -Destination (Join-Path $BrainDir $ScriptName) -Force
            Write-Host "  Installed: $ScriptName"
        }
    } else {
        Write-Warning "  Runtime script not found: $ScriptSrc. Skipping."
    }
}

# Docs copy (reference documentation next to the runtime)
if (Test-Path $SourceDocs) {
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would copy docs\ to: $BrainDocs"
    } else {
        Confirm-Directory $BrainDocs
        Copy-Item -Path (Join-Path $SourceDocs '*') -Destination $BrainDocs -Recurse -Force
        Write-Host "  Installed: docs\ -> $BrainDocs"
    }
} else {
    Write-Warning "  docs\ directory not found at: $SourceDocs. Skipping."
}

# config.json - write defaults only if no config exists yet.
# An existing config may contain personal answers from the wizard; keep it.
if (Test-Path $ConfigPath) {
    Write-Host "  Existing config.json found - keeping it untouched."
} else {
    $UpdateEnabled = $true
    if ($NoUpdateCheck) { $UpdateEnabled = $false }

    $Config = [ordered]@{
        version      = '2.0.0'
        repo         = 'JanniEinfach/claude-brain-setup'
        branch       = 'main'
        installedAt  = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss'Z'")
        os           = 'windows'
        language     = 'en'
        userName     = ''
        experience   = 'intermediate'
        model        = 'unknown'
        modelRaw     = $null
        planTier     = 'unknown'
        obsidian     = [ordered]@{
            enabled      = $false
            vaultPath    = ''
            appInstalled = $false
        }
        updateCheck  = [ordered]@{
            enabled       = $UpdateEnabled
            intervalHours = 24
            lastCheck     = $null
        }
        claudeMdPath = $ClaudeMdDest
    }

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would write default config.json to: $ConfigPath"
    } else {
        $ConfigJson = ConvertTo-Json -InputObject $Config -Depth 5
        Write-TextFile -Path $ConfigPath -Content $ConfigJson
        Write-Host "  Installed: config.json (defaults: language=en, update check $(if ($UpdateEnabled) { 'enabled' } else { 'disabled' }))"
    }
}
Write-Host ""

# ---------------------------------------------------------------------------
# Step 4: SessionStart update hook in ~/.claude/settings.json (idempotent)
# ---------------------------------------------------------------------------

function Show-ManualHookSnippet {
    Write-Host "  Add this block manually to $SettingsPath (inside the top-level object):"
    Write-Host '    "hooks": {'
    Write-Host '      "SessionStart": ['
    Write-Host '        {'
    Write-Host '          "matcher": "startup",'
    Write-Host '          "hooks": ['
    Write-Host '            {'
    Write-Host '              "type": "command",'
    Write-Host '              "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"%USERPROFILE%\\.claude\\brain\\check-update.ps1\""'
    Write-Host '            }'
    Write-Host '          ]'
    Write-Host '        }'
    Write-Host '      ]'
    Write-Host '    }'
}

function Register-UpdateHook {
    $Raw = $null
    if (Test-Path $SettingsPath) {
        $Raw = Get-Content -Path $SettingsPath -Raw
        if ($Raw -match 'brain[/\\]+check-update') {
            Write-Host "  Update hook already registered - nothing to do."
            return
        }
    }

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would register SessionStart update hook in: $SettingsPath"
        return
    }

    $Settings = $null
    if ($null -ne $Raw -and $Raw.Trim().Length -gt 0) {
        try {
            $Settings = $Raw | ConvertFrom-Json
        } catch {
            Write-Warning "  Could not parse $SettingsPath as JSON. Hook was NOT registered."
            Show-ManualHookSnippet
            return
        }
    }
    if ($null -eq $Settings) { $Settings = [pscustomobject]@{} }

    try {
        Backup-File $SettingsPath

        $HookItem  = [pscustomobject]@{ type = 'command'; command = $HookCommand }
        $HookEntry = [pscustomobject]@{ matcher = 'startup'; hooks = @($HookItem) }

        if ($null -eq $Settings.PSObject.Properties['hooks']) {
            $Settings | Add-Member -MemberType NoteProperty -Name 'hooks' -Value ([pscustomobject]@{})
        }
        if ($null -eq $Settings.hooks.PSObject.Properties['SessionStart']) {
            $Settings.hooks | Add-Member -MemberType NoteProperty -Name 'SessionStart' -Value @()
        }
        $Settings.hooks.SessionStart = @($Settings.hooks.SessionStart) + @($HookEntry)

        $SettingsJson = ConvertTo-Json -InputObject $Settings -Depth 10
        Write-TextFile -Path $SettingsPath -Content $SettingsJson
        Write-Host "  Registered SessionStart update hook in: $SettingsPath" -ForegroundColor Green
    } catch {
        Write-Warning "  Could not update ${SettingsPath}: $($_.Exception.Message)"
        Show-ManualHookSnippet
    }
}

if ($NoUpdateCheck) {
    Write-Host "[4/4] Skipping update hook (-NoUpdateCheck)" -ForegroundColor Cyan
} elseif ($NativeScriptMissing -and -not $DryRun) {
    Write-Host "[4/4] Update hook" -ForegroundColor Cyan
    Write-Warning "  check-update.ps1 was not installed - hook registration skipped."
} else {
    Write-Host "[4/4] Registering daily update check (SessionStart hook)" -ForegroundColor Cyan
    Confirm-Directory $ClaudeDir
    Register-UpdateHook
}
Write-Host ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

if ($DryRun) {
    Write-Host "[DRY RUN] Complete. No files were written." -ForegroundColor Yellow
    exit 0
}

Write-Host "=====================================================" -ForegroundColor Green
Write-Host " Quick installation complete." -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Installed:"
if (-not $SkillsOnly) { Write-Host "  - CLAUDE.md      -> $ClaudeMdDest" }
if ($WithSkills)      { Write-Host "  - Brain skills   -> $SkillsDest" }
Write-Host "  - Brain runtime  -> $BrainDir"
if (-not $NoUpdateCheck) { Write-Host "  - Update check   -> runs once per day at session start (opt-out: see docs\UPDATE.md)" }
Write-Host ""
Write-Host "Start Claude Code with:  claude"
Write-Host ""
Write-Host "-----------------------------------------------------" -ForegroundColor Yellow
Write-Host " Recommended: run the interactive setup wizard!" -ForegroundColor Yellow
Write-Host "-----------------------------------------------------" -ForegroundColor Yellow
Write-Host " You just installed the generic default configuration."
Write-Host " The wizard asks a few simple questions (in German or"
Write-Host " English) and builds a CLAUDE.md tailored to YOU,"
Write-Host " including the Obsidian Master Brain, Claude's"
Write-Host " long-term memory across projects:"
Write-Host ""
Write-Host "     .\scripts\setup.ps1" -ForegroundColor Cyan
Write-Host ""
