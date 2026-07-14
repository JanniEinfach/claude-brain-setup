# update.ps1 — Claude Brain updater (Windows PowerShell)
#
# Downloads the latest Claude Brain Setup package from GitHub and updates:
#   - bundled skills   ~/.claude/skills/brain-*
#   - Brain scripts    ~/.claude/brain/check-update.*, update.*
#   - documentation    ~/.claude/brain/docs/
#   - VERSION          ~/.claude/brain/VERSION
#
# It NEVER touches: ~/.claude/CLAUDE.md, your Obsidian vault, or
# ~/.claude/settings.json. In config.json only the "version" field is
# updated and missing default keys are added — all other values stay as
# they are. Nothing is ever deleted: the previous state is copied to
# ~/.claude/brain/backups/<old-version>-<timestamp>/ before anything is
# overwritten. Remove-Item is used exclusively on the temporary download
# folder this script creates itself.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File update.ps1          # interactive
#   powershell -NoProfile -ExecutionPolicy Bypass -File update.ps1 -Check   # check only
#   powershell -NoProfile -ExecutionPolicy Bypass -File update.ps1 -Yes     # no prompt

[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'

$BrainDir    = Join-Path $env:USERPROFILE '.claude\brain'
$SkillsDir   = Join-Path $env:USERPROFILE '.claude\skills'
$ConfigPath  = Join-Path $BrainDir 'config.json'
$VersionPath = Join-Path $BrainDir 'VERSION'

# Defaults; overridden by config.json when present.
$Repo     = 'JanniEinfach/claude-brain-setup'
$Branch   = 'main'
$Language = 'en'

function Msg {
    param([string]$De, [string]$En)
    if ($Language -eq 'de') { return $De }
    return $En
}

function Get-VersionParts {
    # Parses "2.1.0" (optionally "v2.1.0") into @(2, 1, 0). Returns $null
    # when the string is not a usable three-segment version.
    param([string]$Version)
    if ([string]::IsNullOrWhiteSpace($Version)) { return $null }
    $clean = $Version.Trim()
    if ($clean.StartsWith('v')) { $clean = $clean.Substring(1) }
    $parts = $clean.Split('.')
    if ($parts.Count -lt 3) { return $null }
    $nums = @()
    for ($i = 0; $i -lt 3; $i++) {
        $m = [regex]::Match($parts[$i], '^\d+')
        if (-not $m.Success) { return $null }
        $nums += [int]$m.Value
    }
    return ,$nums
}

function Test-RemoteNewer {
    # Numeric semver comparison per segment — never a string comparison.
    param([int[]]$Remote, [int[]]$Local)
    for ($i = 0; $i -lt 3; $i++) {
        if ($Remote[$i] -gt $Local[$i]) { return $true }
        if ($Remote[$i] -lt $Local[$i]) { return $false }
    }
    return $false
}

function Update-BrainConfig {
    # Only sets the "version" field and adds missing default keys.
    # Every other user value in config.json stays untouched.
    param([string]$NewVersion)
    if ($script:ConfigBroken) {
        Write-Host (Msg 'Hinweis: config.json ist beschädigt und wurde nicht angefasst.' `
                        'Note: config.json is damaged and was left untouched.') -ForegroundColor Yellow
        return
    }
    $cfg = $script:ConfigObj
    $defaultUpdateCheck = [PSCustomObject]@{
        enabled       = $true
        intervalHours = 24
        lastCheck     = $null
    }
    if ($null -eq $cfg) {
        $cfg = [PSCustomObject]@{
            version     = $NewVersion
            repo        = $Repo
            branch      = $Branch
            language    = $Language
            updateCheck = $defaultUpdateCheck
        }
    } else {
        $cfg | Add-Member -NotePropertyName 'version' -NotePropertyValue $NewVersion -Force
        if ($null -eq $cfg.PSObject.Properties['repo']) {
            $cfg | Add-Member -NotePropertyName 'repo' -NotePropertyValue $Repo
        }
        if ($null -eq $cfg.PSObject.Properties['branch']) {
            $cfg | Add-Member -NotePropertyName 'branch' -NotePropertyValue $Branch
        }
        if ($null -eq $cfg.PSObject.Properties['updateCheck'] -or $null -eq $cfg.updateCheck) {
            $cfg | Add-Member -NotePropertyName 'updateCheck' -NotePropertyValue $defaultUpdateCheck -Force
        } else {
            $uc = $cfg.updateCheck
            if ($null -eq $uc.PSObject.Properties['enabled']) {
                $uc | Add-Member -NotePropertyName 'enabled' -NotePropertyValue $true
            }
            if ($null -eq $uc.PSObject.Properties['intervalHours']) {
                $uc | Add-Member -NotePropertyName 'intervalHours' -NotePropertyValue 24
            }
            if ($null -eq $uc.PSObject.Properties['lastCheck']) {
                $uc | Add-Member -NotePropertyName 'lastCheck' -NotePropertyValue $null
            }
        }
    }
    $json = $cfg | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($ConfigPath, $json, (New-Object System.Text.UTF8Encoding($false)))
}

# --- preflight ----------------------------------------------------------------

if (-not (Test-Path $BrainDir)) {
    Write-Host 'Claude Brain runtime not found at ~/.claude/brain.'
    Write-Host 'Install it first: https://github.com/JanniEinfach/claude-brain-setup'
    exit 1
}

$script:ConfigObj    = $null
$script:ConfigBroken = $false
if (Test-Path $ConfigPath) {
    try {
        $script:ConfigObj = (Get-Content -Path $ConfigPath -Raw -Encoding UTF8) | ConvertFrom-Json
    } catch {
        $script:ConfigObj = $null
        $script:ConfigBroken = $true
    }
}
if ($null -ne $script:ConfigObj) {
    if ($script:ConfigObj.repo)     { $Repo = "$($script:ConfigObj.repo)" }
    if ($script:ConfigObj.branch)   { $Branch = "$($script:ConfigObj.branch)" }
    if ($script:ConfigObj.language) { $Language = "$($script:ConfigObj.language)".ToLower() }
}

$LocalVersion = $null
if (Test-Path $VersionPath) {
    try { $LocalVersion = (Get-Content -Path $VersionPath -Raw).Trim() } catch { }
}
if (-not $LocalVersion -and $null -ne $script:ConfigObj -and $script:ConfigObj.version) {
    $LocalVersion = "$($script:ConfigObj.version)"
}
if (-not $LocalVersion) { $LocalVersion = '0.0.0' }
$LocalParts = Get-VersionParts $LocalVersion
if ($null -eq $LocalParts) {
    $LocalVersion = '0.0.0'
    $LocalParts   = @(0, 0, 0)
}

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
} catch { }

# --- check remote version -------------------------------------------------------

$RemoteVersion = $null
try {
    $resp = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$Repo/$Branch/VERSION" -UseBasicParsing -TimeoutSec 5
    $RemoteVersion = "$($resp.Content)".Trim()
} catch { }

if (-not $RemoteVersion) {
    Write-Host (Msg 'GitHub ist nicht erreichbar (offline oder blockiert). Bitte später erneut versuchen.' `
                    'Could not reach GitHub (offline or blocked). Please try again later.')
    exit 1
}

$RemoteParts = Get-VersionParts $RemoteVersion
if ($null -eq $RemoteParts) {
    Write-Host (Msg "Unerwartete Antwort von GitHub: '$RemoteVersion'" `
                    "Unexpected response from GitHub: '$RemoteVersion'")
    exit 1
}

if (-not (Test-RemoteNewer -Remote $RemoteParts -Local $LocalParts)) {
    Write-Host (Msg "Bereits aktuell — Version $LocalVersion ist installiert." `
                    "Already up to date — version $LocalVersion is installed.") -ForegroundColor Green
    exit 0
}

if ($Check) {
    Write-Host (Msg "Update verfügbar: $RemoteVersion (installiert: $LocalVersion)." `
                    "Update available: $RemoteVersion (installed: $LocalVersion).") -ForegroundColor Cyan
    Write-Host (Msg 'Ausführen: /brain-update in Claude Code oder ~/.claude/brain/update.ps1' `
                    'Run: /brain-update inside Claude Code or ~/.claude/brain/update.ps1')
    exit 0
}

if (-not $Yes) {
    $answer = Read-Host (Msg "Auf Version $RemoteVersion aktualisieren? [J/n]" `
                             "Update to version $RemoteVersion? [Y/n]")
    $a = "$answer".Trim().ToLower()
    if ($a -ne '' -and $a -ne 'j' -and $a -ne 'ja' -and $a -ne 'y' -and $a -ne 'yes') {
        Write-Host (Msg 'Abgebrochen. Es wurde nichts verändert.' 'Aborted. Nothing was changed.')
        exit 0
    }
}

# --- download, backup, install ----------------------------------------------------

$TempDir   = Join-Path $env:TEMP ('claude-brain-update-' + [Guid]::NewGuid().ToString('N'))
$BackupDir = $null
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    # Package source: latest GitHub release first, branch zip as fallback.
    $candidates = @()
    try {
        $api = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -UseBasicParsing -TimeoutSec 15
        if ($api.zipball_url) { $candidates += "$($api.zipball_url)" }
    } catch { }
    $candidates += "https://codeload.github.com/$Repo/zip/refs/heads/$Branch"

    Write-Host (Msg 'Lade Update-Paket herunter ...' 'Downloading update package ...')

    $PkgRoot    = $null
    $NewVersion = $null
    $i = 0
    foreach ($url in $candidates) {
        $i++
        try {
            $zipPath    = Join-Path $TempDir "pkg$i.zip"
            $extractDir = Join-Path $TempDir "pkg$i"
            Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing -TimeoutSec 120
            Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
            $top = Get-ChildItem -Path $extractDir -Directory | Select-Object -First 1
            if ($null -eq $top) { continue }
            $pvPath = Join-Path $top.FullName 'VERSION'
            if (-not (Test-Path $pvPath)) { continue }
            $pv = (Get-Content -Path $pvPath -Raw).Trim()
            $pvParts = Get-VersionParts $pv
            if ($null -eq $pvParts) { continue }
            # Skip a stale release package that is not actually newer.
            if (Test-RemoteNewer -Remote $pvParts -Local $LocalParts) {
                $PkgRoot    = $top.FullName
                $NewVersion = $pv
                break
            }
        } catch {
            # Try the next candidate URL.
        }
    }

    if ($null -eq $PkgRoot) {
        throw (Msg 'Download oder Entpacken fehlgeschlagen — kein neueres Paket gefunden.' `
                   'Download or extraction failed — no newer package found.')
    }

    # Backup: copy the current state before anything is overwritten.
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $BackupDir = Join-Path $BrainDir ('backups\' + $LocalVersion + '-' + $timestamp)
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Write-Host (Msg "Sichere aktuellen Stand nach: $BackupDir" "Backing up current state to: $BackupDir")

    if (Test-Path $SkillsDir) {
        $existingSkills = @(Get-ChildItem -Path $SkillsDir -Directory -Filter 'brain-*' -ErrorAction SilentlyContinue)
        if ($existingSkills.Count -gt 0) {
            $backupSkills = Join-Path $BackupDir 'skills'
            New-Item -ItemType Directory -Path $backupSkills -Force | Out-Null
            foreach ($d in $existingSkills) {
                Copy-Item -Path $d.FullName -Destination (Join-Path $backupSkills $d.Name) -Recurse -Force
            }
        }
    }
    foreach ($f in @('check-update.ps1', 'check-update.sh', 'update.ps1', 'update.sh', 'VERSION')) {
        $src = Join-Path $BrainDir $f
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination (Join-Path $BackupDir $f) -Force
        }
    }

    # Install: skills.
    $pkgSkills = Join-Path $PkgRoot 'skills'
    if (Test-Path $pkgSkills) {
        Write-Host (Msg 'Aktualisiere Skills ...' 'Updating skills ...')
        if (-not (Test-Path $SkillsDir)) {
            New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
        }
        Get-ChildItem -Path $pkgSkills -Directory -Filter 'brain-*' | ForEach-Object {
            $dest = Join-Path $SkillsDir $_.Name
            if (-not (Test-Path $dest)) {
                New-Item -ItemType Directory -Path $dest -Force | Out-Null
            }
            Copy-Item -Path (Join-Path $_.FullName '*') -Destination $dest -Recurse -Force
            Write-Host "  + $($_.Name)"
        }
    }

    # Install: Brain scripts. (PowerShell parses a script fully before running
    # it, so update.ps1 may safely overwrite itself here.)
    Write-Host (Msg 'Aktualisiere Brain-Skripte ...' 'Updating Brain scripts ...')
    $pkgScripts = Join-Path $PkgRoot 'scripts'
    foreach ($f in @('check-update.ps1', 'check-update.sh', 'update.ps1', 'update.sh')) {
        $src = Join-Path $pkgScripts $f
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination (Join-Path $BrainDir $f) -Force
        }
    }

    # Install: docs.
    $pkgDocs = Join-Path $PkgRoot 'docs'
    if (Test-Path $pkgDocs) {
        Write-Host (Msg 'Aktualisiere Dokumentation ...' 'Updating documentation ...')
        $destDocs = Join-Path $BrainDir 'docs'
        if (-not (Test-Path $destDocs)) {
            New-Item -ItemType Directory -Path $destDocs -Force | Out-Null
        }
        Copy-Item -Path (Join-Path $pkgDocs '*') -Destination $destDocs -Recurse -Force
    }

    # Install: VERSION.
    Copy-Item -Path (Join-Path $PkgRoot 'VERSION') -Destination $VersionPath -Force

    # config.json: version field + missing default keys only.
    Update-BrainConfig -NewVersion $NewVersion

    # Show the top section of the new CHANGELOG.
    $clPath = Join-Path $PkgRoot 'CHANGELOG.md'
    if (Test-Path $clPath) {
        $section = @()
        $inSection = $false
        foreach ($line in (Get-Content -Path $clPath)) {
            if ($line -match '^## ') {
                if ($inSection) { break }
                $inSection = $true
            }
            if ($inSection) { $section += $line }
        }
        if ($section.Count -gt 0) {
            Write-Host ''
            Write-Host (Msg 'Neu in dieser Version:' "What's new in this version:") -ForegroundColor Cyan
            foreach ($line in $section) { Write-Host $line }
        }
    }

    Write-Host ''
    Write-Host (Msg "Fertig! Claude Brain wurde auf Version $NewVersion aktualisiert." `
                    "Done! Claude Brain was updated to version $NewVersion.") -ForegroundColor Green
    Write-Host (Msg "Backup der vorherigen Version: $BackupDir" `
                    "Backup of the previous version: $BackupDir")
    Write-Host (Msg 'Nicht angefasst: ~/.claude/CLAUDE.md, settings.json, dein Vault.' `
                    'Left untouched: ~/.claude/CLAUDE.md, settings.json, your vault.')
} catch {
    Write-Host ''
    Write-Host (Msg "Update fehlgeschlagen: $($_.Exception.Message)" `
                    "Update failed: $($_.Exception.Message)") -ForegroundColor Red
    if ($BackupDir -and (Test-Path $BackupDir)) {
        Write-Host (Msg "Dein vorheriger Stand liegt unverändert in: $BackupDir" `
                        "Your previous state is preserved in: $BackupDir")
    }
    exit 1
} finally {
    # Remove ONLY the temp folder this script created itself.
    if (Test-Path $TempDir) {
        try { Remove-Item -Path $TempDir -Recurse -Force -Confirm:$false } catch { }
    }
}

exit 0
