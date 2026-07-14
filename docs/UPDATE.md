# The Claude Brain Update System

Claude Brain ships with a small, transparent update system: a session-start
hook that checks GitHub for a newer version at most once per day, and an
update script that installs new versions safely — with backups, and without
ever touching your personalized files.

## How the session-start hook works

During setup (question F19) a `SessionStart` hook is added to
`~/.claude/settings.json`. Every time Claude Code starts a session, the hook
runs `check-update.ps1` (Windows) or `check-update.sh` (Linux/macOS) from
`~/.claude/brain/`.

The check is deliberately boring:

1. If `updateCheck.enabled` in `~/.claude/brain/config.json` is `false`, it exits silently.
2. If the last check is younger than `updateCheck.intervalHours` (default: 24), it exits silently.
3. Otherwise it sends **one GET request** to
   `https://raw.githubusercontent.com/JanniEinfach/claude-brain-setup/main/VERSION`
   (5-second timeout). No data about you or your machine is sent.
4. It compares versions numerically (major.minor.patch). If a newer version
   exists, it prints a short notice into the session context — that is how
   Claude knows to tell you. Otherwise it prints nothing.
5. `updateCheck.lastCheck` is updated after every attempt, even a failed one.

The script always exits with code 0. A broken config, a missing file, or no
internet connection can never break your session start. If `config.json`
cannot be parsed, it is never overwritten — the script instead records the
time of the attempt in a small marker file, `~/.claude/brain/.lastcheck`, so
the at-most-once-per-24-hours promise still holds.

### Hook entry — Linux/macOS

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$HOME/.claude/brain/check-update.sh\""
          }
        ]
      }
    ]
  }
}
```

### Hook entry — Windows

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"%USERPROFILE%\\.claude\\brain\\check-update.ps1\""
          }
        ]
      }
    ]
  }
}
```

The setup and install scripts add this entry idempotently: if a command
containing `brain/check-update` (or `brain\check-update`) already exists, they
leave `settings.json` alone. Existing hooks and other keys are never modified,
and a timestamped backup of `settings.json` is written before any change.

## Configuration fields

All update behavior is controlled by `~/.claude/brain/config.json`:

| Field | Default | Meaning |
|---|---|---|
| `updateCheck.enabled` | `true` | Master switch for the session-start check. |
| `updateCheck.intervalHours` | `24` | Minimum hours between two GitHub queries. |
| `updateCheck.lastCheck` | `null` | Timestamp of the last attempt (UTC, ISO 8601). Managed automatically. |
| `repo` | `JanniEinfach/claude-brain-setup` | GitHub repository to check and download from. |
| `branch` | `main` | Branch used for the VERSION check and the fallback download. |
| `language` | `en` | Language of the update notice and updater messages (`de` or `en`). |
| `version` | — | Currently installed version. Managed automatically. |

## Checking manually

Three equivalent ways:

- **Inside Claude Code:** type `/brain-update` — Claude runs the check and reports the result.
- **Terminal (Linux/macOS):** `bash ~/.claude/brain/update.sh --check`
- **Terminal (Windows, PowerShell):** `& "$env:USERPROFILE\.claude\brain\update.ps1" -Check`
  — or from `cmd.exe`: `powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.claude\brain\update.ps1" -Check`

To force the hook itself past its interval: `check-update.sh --force` /
`check-update.ps1 -Force`.

## Running an update

`update.sh` / `update.ps1` (interactively, or with `--yes` / `-Yes` to skip
the confirmation prompt):

1. Fetches the remote VERSION. If it is not newer, it says so and stops.
2. Downloads the latest GitHub release zip; if no release exists, it falls
   back to the `main` branch zip.
3. **Backs up** your current `brain-*` skills, the Brain scripts, and VERSION
   to `~/.claude/brain/backups/<old-version>-<timestamp>/`.
4. Updates: skills (`~/.claude/skills/brain-*`), Brain scripts, docs
   (`~/.claude/brain/docs/`), and VERSION.
5. Prints the top section of the new CHANGELOG.

**Never touched by an update:** `~/.claude/CLAUDE.md`, your Obsidian vault,
and `~/.claude/settings.json`. In `config.json` only the `version` field is
set and missing default keys are added — your answers and preferences stay
exactly as they are. The scripts delete nothing except their own temporary
download folder.

## Offline behavior

- **Hook:** silent. The check times out after 5 seconds, `lastCheck` is still
  updated (so it will not retry on every session start), and the session
  starts normally.
- **Updater:** prints "Could not reach GitHub" and exits without changing
  anything.
- **Proxy environments:** `curl`/`wget` and PowerShell honor the usual proxy
  environment variables and system settings; if GitHub is blocked entirely,
  disable the check (see below) and update manually from a machine with
  access.

## Backups and rollback

Every update creates `~/.claude/brain/backups/<old-version>-<timestamp>/`
containing:

- `skills/` — your previous `brain-*` skill folders
- `check-update.sh`, `check-update.ps1`, `update.sh`, `update.ps1`
- `VERSION`

To roll back, copy the contents back over the live locations:

Linux/macOS:

```bash
BACKUP=~/.claude/brain/backups/2.0.0-20260714_120000   # pick your backup
cp -R "$BACKUP/skills/." ~/.claude/skills/
cp "$BACKUP"/check-update.* "$BACKUP"/update.* "$BACKUP/VERSION" ~/.claude/brain/
```

Windows (PowerShell):

```powershell
$Backup = "$env:USERPROFILE\.claude\brain\backups\2.0.0-20260714_120000"
Copy-Item "$Backup\skills\*" "$env:USERPROFILE\.claude\skills\" -Recurse -Force
Copy-Item "$Backup\check-update.*", "$Backup\update.*", "$Backup\VERSION" "$env:USERPROFILE\.claude\brain\" -Force
```

Backups are never deleted automatically. If the folder grows too large over
the years, you can prune old entries yourself.

## Disabling update checks

Three options, from setup-time to permanent:

1. **During setup:** answer "no" to question F19 (update notifications) — the
   hook is simply not registered.
2. **Quick install:** run `install.sh --no-update-check` /
   `install.ps1 -NoUpdateCheck` — installs everything but skips the hook.
3. **Anytime later:** set `"enabled": false` under `updateCheck` in
   `~/.claude/brain/config.json`. The hook stays registered but exits
   silently and makes no network requests.

You can also remove the `SessionStart` entry containing `brain/check-update`
from `~/.claude/settings.json` entirely. Manual updates via `/brain-update`
or the update scripts keep working in all cases.
