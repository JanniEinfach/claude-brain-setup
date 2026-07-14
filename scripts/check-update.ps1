# check-update.ps1 — Claude Brain update check (SessionStart hook, Windows)
#
# Runs at every Claude Code session start via the SessionStart hook.
# Prints a short notice when a newer version exists on GitHub; otherwise
# prints nothing. It must never break a session start, so it ALWAYS exits
# with code 0 — even offline, without config.json, or on any internal error.
#
# Network: a single GET request to raw.githubusercontent.com (the VERSION
# file of the configured repo). No user data is sent. Timeout: 5 seconds.
# Total runtime target: under 6 seconds.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File check-update.ps1 [-Force]
#
#   -Force   Ignore the configured check interval and query GitHub now.

[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$script:BrainDir    = Join-Path $env:USERPROFILE '.claude\brain'
$script:ConfigPath  = Join-Path $script:BrainDir 'config.json'
$script:VersionPath = Join-Path $script:BrainDir 'VERSION'
$script:MarkerPath  = Join-Path $script:BrainDir '.lastcheck'

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

function Save-LastCheck {
    # Persists updateCheck.lastCheck after every attempt (even when the
    # network request failed). Never overwrites a config.json that could
    # not be parsed; creates a minimal one when the file is missing.
    param(
        $Config,
        [bool]$ConfigBroken,
        [string]$Repo,
        [string]$Branch,
        [string]$Language,
        [int]$IntervalHours,
        [string]$LocalVersion
    )
    if ($ConfigBroken) { return }
    try {
        $now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        if ($null -eq $Config) {
            $Config = [PSCustomObject]@{
                version     = $LocalVersion
                repo        = $Repo
                branch      = $Branch
                language    = $Language
                updateCheck = [PSCustomObject]@{
                    enabled       = $true
                    intervalHours = $IntervalHours
                    lastCheck     = $now
                }
            }
        } else {
            if ($null -eq $Config.PSObject.Properties['updateCheck'] -or $null -eq $Config.updateCheck) {
                $uc = [PSCustomObject]@{
                    enabled       = $true
                    intervalHours = $IntervalHours
                    lastCheck     = $now
                }
                $Config | Add-Member -NotePropertyName 'updateCheck' -NotePropertyValue $uc -Force
            } else {
                $Config.updateCheck | Add-Member -NotePropertyName 'lastCheck' -NotePropertyValue $now -Force
            }
        }
        $json = $Config | ConvertTo-Json -Depth 5
        [System.IO.File]::WriteAllText($script:ConfigPath, $json, (New-Object System.Text.UTF8Encoding($false)))
    } catch {
        # Persisting lastCheck is best-effort only.
    }
}

function Save-LastCheckMarker {
    # Fallback timestamp store (~/.claude/brain/.lastcheck). Keeps the
    # interval gate working when config.json is broken or missing, without
    # ever touching config.json itself. Best-effort only.
    try {
        $now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        [System.IO.File]::WriteAllText($script:MarkerPath, $now, (New-Object System.Text.UTF8Encoding($false)))
    } catch {
        # Persisting the marker is best-effort only.
    }
}

function Get-LastCheckMarker {
    # Reads the ISO timestamp from the marker file; $null when unavailable.
    try {
        if (Test-Path $script:MarkerPath) {
            $raw = (Get-Content -Path $script:MarkerPath -Raw).Trim()
            if ($raw) { return $raw }
        }
    } catch { }
    return $null
}

function Write-UpdateNotice {
    param([string]$Language, [string]$RemoteVersion, [string]$LocalVersion)
    if ($Language -eq 'de') {
        Write-Output '=============================================='
        Write-Output " Claude Brain Update verfügbar: $RemoteVersion"
        Write-Output " Installiert: $LocalVersion"
        Write-Output ' Update ausführen:  /brain-update  (in Claude Code)'
        Write-Output ' oder manuell:      ~/.claude/brain/update.ps1'
        Write-Output '=============================================='
    } else {
        Write-Output '=============================================='
        Write-Output " Claude Brain update available: $RemoteVersion"
        Write-Output " Installed: $LocalVersion"
        Write-Output ' Run the update:  /brain-update  (inside Claude Code)'
        Write-Output ' or manually:     ~/.claude/brain/update.ps1'
        Write-Output '=============================================='
    }
}

function Invoke-UpdateCheck {
    # Brain runtime not installed -> nothing to check.
    if (-not (Test-Path $script:BrainDir)) { return }

    # --- defaults (survive a missing or broken config.json) ---------------
    $repo          = 'JanniEinfach/claude-brain-setup'
    $branch        = 'main'
    $language      = 'en'
    $enabled       = $true
    $intervalHours = 24
    $lastCheck     = $null
    $config        = $null
    $configBroken  = $false

    if (Test-Path $script:ConfigPath) {
        try {
            $raw = Get-Content -Path $script:ConfigPath -Raw -Encoding UTF8
            $config = $raw | ConvertFrom-Json
        } catch {
            $config = $null
            $configBroken = $true
        }
    }

    if ($null -ne $config) {
        try {
            if ($config.repo)     { $repo = "$($config.repo)" }
            if ($config.branch)   { $branch = "$($config.branch)" }
            if ($config.language) { $language = "$($config.language)".ToLower() }
            $uc = $config.updateCheck
            if ($null -ne $uc) {
                if ($null -ne $uc.PSObject.Properties['enabled'] -and $null -ne $uc.enabled) {
                    $enabled = [bool]$uc.enabled
                }
                if ($uc.intervalHours) {
                    try { $intervalHours = [int]$uc.intervalHours } catch { }
                }
                if ($uc.lastCheck) { $lastCheck = "$($uc.lastCheck)" }
            }
        } catch {
            # Unexpected config shape: keep the defaults.
        }
    }

    if (-not $enabled) { return }
    if ($intervalHours -lt 1) { $intervalHours = 24 }

    # Broken or missing config leaves no usable lastCheck: fall back to the
    # .lastcheck marker file so the interval gate still applies.
    if (-not $lastCheck) {
        $lastCheck = Get-LastCheckMarker
    }

    # --- interval gate (skipped with -Force) -------------------------------
    if (-not $Force -and $lastCheck) {
        try {
            $last = [DateTime]::Parse(
                $lastCheck,
                [System.Globalization.CultureInfo]::InvariantCulture,
                [System.Globalization.DateTimeStyles]::AdjustToUniversal
            )
            $ageHours = ((Get-Date).ToUniversalTime() - $last).TotalHours
            if ($ageHours -ge 0 -and $ageHours -lt $intervalHours) { return }
        } catch {
            # Unparseable timestamp -> treat the check as due.
        }
    }

    # --- local version ------------------------------------------------------
    $localVersion = $null
    if (Test-Path $script:VersionPath) {
        try { $localVersion = (Get-Content -Path $script:VersionPath -Raw).Trim() } catch { }
    }
    if (-not $localVersion -and $null -ne $config -and $config.version) {
        $localVersion = "$($config.version)"
    }
    if (-not $localVersion) { $localVersion = '0.0.0' }

    # --- remote version (single small GET, 5 s timeout) ---------------------
    $remoteVersion = $null
    try {
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
        } catch { }
        $url = "https://raw.githubusercontent.com/$repo/$branch/VERSION"
        $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5
        $remoteVersion = "$($resp.Content)".Trim()
    } catch {
        $remoteVersion = $null
    }

    # lastCheck is updated after EVERY attempt, including network failures,
    # so an offline machine does not retry on every single session start.
    # The marker file is written as well; it is the only gate that works
    # when config.json is broken (config.json is never touched then).
    Save-LastCheck -Config $config -ConfigBroken $configBroken -Repo $repo -Branch $branch `
        -Language $language -IntervalHours $intervalHours -LocalVersion $localVersion
    Save-LastCheckMarker

    if (-not $remoteVersion) { return }

    $remoteParts = Get-VersionParts $remoteVersion
    $localParts  = Get-VersionParts $localVersion
    if ($null -eq $remoteParts) { return }
    if ($null -eq $localParts)  { $localParts = @(0, 0, 0) }
    if (-not (Test-RemoteNewer -Remote $remoteParts -Local $localParts)) { return }

    Write-UpdateNotice -Language $language -RemoteVersion $remoteVersion -LocalVersion $localVersion
}

try {
    Invoke-UpdateCheck
} catch {
    # A session start must never fail because of the update check.
}
exit 0
