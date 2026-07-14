# Troubleshooting

## CLAUDE.md is not being loaded

Since version 2.0.0, the global configuration lives at `~/.claude/CLAUDE.md` (it applies in every project). Check that the file exists:

```bash
# Linux / macOS
ls -la ~/.claude/CLAUDE.md

# Windows PowerShell
Get-Item "$env:USERPROFILE\.claude\CLAUDE.md"
```

If it is missing, run the installer:

```bash
./scripts/install.sh          # Linux / macOS
.\scripts\install.ps1         # Windows PowerShell
```

To verify Claude loaded it, start a session and ask:

```
What instructions are you following from CLAUDE.md?
```

Claude should summarise the key sections. If it cannot, the file is either missing, empty, or in the wrong location.

## Two CLAUDE.md files after upgrading from V1

Version 1 installed to `~/CLAUDE.md`; version 2 installs to `~/.claude/CLAUDE.md`. If both exist, they can contradict each other and confuse Claude.

The V2 setup detects this and offers to rename the old file to `~/CLAUDE.md.backup-<timestamp>` (it is never deleted). If you declined during setup, fix it manually:

```bash
# Linux / macOS
mv ~/CLAUDE.md ~/CLAUDE.md.backup-manual

# Windows PowerShell
Rename-Item "$env:USERPROFILE\CLAUDE.md" "CLAUDE.md.backup-manual"
```

Keep only `~/.claude/CLAUDE.md` as the active global configuration.

## Claude is using the wrong model

The model is set at launch. It cannot change mid-session. Type `/model` inside a session to see what you are running.

```bash
# Launch explicitly:
claude --model claude-sonnet-5
```

If no `--model` flag is used and no default is set in `settings.json`, Claude Code uses its own built-in default. To set a persistent default:

```json
{
  "model": "claude-sonnet-5"
}
```

Save this in `~/.claude/settings.json` (or start from `settings.example.json`). See `docs/MODEL_ROUTING.md` for the full Claude 5 family guide. Note: `claude-fable-5` is only available on some plans — if it is rejected, use `claude-opus-4-8`.

## The update hook does not fire

Symptoms: you never see update notices even though a newer version exists on GitHub.

1. **Check the hook is registered.** Open `~/.claude/settings.json` and look for a `SessionStart` entry whose command contains `brain/check-update` (or `brain\check-update` on Windows). If missing, re-run setup or add the entry shown in `docs/UPDATE.md`.
2. **Check the script exists.**
   ```bash
   ls ~/.claude/brain/check-update.sh          # Linux / macOS
   Get-Item "$env:USERPROFILE\.claude\brain\check-update.ps1"   # Windows
   ```
3. **Run it manually with `--force`** (the `--force` flag skips the 24-hour interval):
   ```bash
   bash ~/.claude/brain/check-update.sh --force
   ```
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\brain\check-update.ps1" -Force
   ```
   If a newer version exists, this prints the update banner. If it prints nothing, you are up to date (or the check is disabled in `~/.claude/brain/config.json` → `updateCheck.enabled`).
4. **Remember the interval.** The hook checks at most once per 24 hours. A session started five minutes after the last check makes no request and prints nothing — that is by design.
5. The hook always exits 0 by design, so it never surfaces errors into your session. To debug network problems, run step 3 manually and watch the output.

## Umlauts or special characters look broken (Windows)

Windows PowerShell 5.1 only reads non-ASCII characters (ä, ö, ü, ß, é, …) correctly from script files saved as **UTF-8 with BOM**. The `.ps1` files in this repository ship with a BOM.

If prompts show garbage like `FÃ¼r` instead of `Für`:

1. You (or an editor/download tool) may have re-saved the script without the BOM. Re-download the repository or restore the original file.
2. Set the console to UTF-8 before running:
   ```powershell
   chcp 65001
   [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
   ```
3. If broken characters ended up inside your generated `CLAUDE.md`, re-run the wizard — it regenerates the file (with a backup of the old one).

## PowerShell blocks the scripts (ExecutionPolicy)

If you see "running scripts is disabled on this system":

```powershell
# One-off, no system change (recommended):
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup.ps1

# Or allow local scripts permanently for your user:
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Neither option requires admin rights. The update hook installed by setup already uses `-ExecutionPolicy Bypass` in its command, so it is unaffected by a restrictive policy.

## python3 or jq is missing (Linux/macOS)

The bash scripts write and merge JSON (`config.json`, `settings.json`) using `python3` when available, falling back to `jq`, and finally to a manual path:

- **config.json** — without python3/jq, a template with your escaped values is written directly.
- **settings.json hook merge** — without python3/jq, the script does not modify `settings.json`; instead it prints the exact JSON snippet and instructions so you can paste it in yourself. Setup still completes.

To install one of them:

```bash
# macOS
brew install python3        # or: brew install jq

# Ubuntu / Debian
sudo apt install python3    # or: sudo apt install jq
```

## Update check or update fails offline / behind a proxy

- **check-update** is deliberately silent about failures: offline or blocked, it exits 0 and simply tries again after the interval. Nothing to fix.
- **update.sh / update.ps1** will report a network error. Behind a corporate proxy, set the standard environment variables before running:
  ```bash
  export HTTPS_PROXY="http://proxy.example.com:8080"
  bash ~/.claude/brain/update.sh
  ```
  (PowerShell honours system proxy settings; if needed set `$env:HTTPS_PROXY` the same way.)
- Fully offline machines: download the repository zip on another machine from `https://github.com/JanniEinfach/claude-brain-setup`, copy it over, extract it, and run `setup` from the extracted folder — the wizard itself needs no network.

## Permission denied when running scripts (Linux/macOS)

The scripts need execute permission:

```bash
chmod +x scripts/setup.sh scripts/install.sh
```

Or run them explicitly with bash:

```bash
bash scripts/setup.sh
```

## Finding your backups

Every overwrite creates a timestamped backup first — backups are never deleted.

```bash
# Global CLAUDE.md backups (V2 location)
ls ~/.claude/CLAUDE.md.backup*

# V1-migration backup of the old home-directory file
ls ~/CLAUDE.md.backup*

# settings.json backups
ls ~/.claude/settings.json.backup*

# Update backups (previous skills, scripts, VERSION per updated version)
ls ~/.claude/brain/backups/
```

To restore, copy the backup over the current file:

```bash
cp ~/.claude/CLAUDE.md.backup-<timestamp> ~/.claude/CLAUDE.md
```

## Bundled Brain skills did not install

Check whether the Brain skills are present:

```bash
ls ~/.claude/skills/ | grep brain-
```

You should see 14 `brain-*` directories. If not, install them:

```bash
# Linux / macOS
./scripts/install.sh --with-skills

# Windows PowerShell
.\scripts\install.ps1 -WithSkills
```

If `~/.claude/skills/` does not exist, create it and retry:

```bash
mkdir -p ~/.claude/skills/
```

## External ECC skills are missing

Skills listed in `docs/SKILLS.md` under "requires optional ECC skill collection" are not bundled with this repository. If `ls ~/.claude/skills/skill-name` finds nothing, that skill was never installed on your machine. Install the ECC collection separately or skip that skill — all 14 bundled `brain-*` skills work without it.

## Token usage seems high

Common causes:

1. **Wrong model.** Check that you are not using Opus 4.8 or Fable 5 for simple tasks.
2. **Session is too large.** Use `/brain-session-handoff`, end the session, start fresh.
3. **CLAUDE.md is too long.** Keep it under 150 lines. Move details to `docs/`.
4. **Skills preloaded unnecessarily.** Only load skills when you actually need them.
5. **Long command output pasted raw.** Summarise output instead of pasting it.

See `docs/TOKEN_EFFICIENCY.md` for the full guide.

## The generated CLAUDE.md looks wrong

Run setup again with `--dry-run` to preview without writing:

```bash
./scripts/setup.sh --dry-run          # Linux / macOS
.\scripts\setup.ps1 -DryRun           # Windows PowerShell
```

Review the output. If a `{{PLACEHOLDER}}` survives in the output, the template substitution failed — check that `templates/CLAUDE.template.md` exists in the repository.

## CLAUDE.md was overwritten unintentionally

The scripts create a timestamped backup before every overwrite. Find it:

```bash
ls ~/.claude/CLAUDE.md.backup*
```

Restore the one you want:

```bash
cp ~/.claude/CLAUDE.md.backup-<timestamp> ~/.claude/CLAUDE.md
```
