# brain-update

## Purpose

Check for and install Claude Brain updates using the bundled update scripts in `~/.claude/brain/`. Gives the user a safe, one-command way to keep skills, scripts, and docs current without ever touching their personalized CLAUDE.md, config values, or vault.

## When to Use

When the user types `/brain-update`, asks whether a newer Brain version exists, or a session-start notice reported an available update.

## When Not to Use

For updating Claude Code itself, the user's own projects, or anything outside the Claude Brain installation. This skill only manages the Brain package.

## Workflow

**Step 1 — Detect the operating system**
Windows uses `update.ps1`, Linux/macOS use `update.sh`. Both live in `~/.claude/brain/`.

**Step 2 — Check for an update**
Run the check and report the result to the user in one sentence (current version, available version, or "already up to date").

Windows:
```
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\brain\update.ps1" -Check
```

Linux/macOS:
```
bash "$HOME/.claude/brain/update.sh" --check
```

**Step 3 — Install only on explicit user confirmation**
If an update is available and the user confirms, run the real update non-interactively and summarize the output: the new version number, the backup location, and the highlights from the printed changelog section. Do not paste the raw output.

Windows:
```
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\brain\update.ps1" -Yes
```

Linux/macOS:
```
bash "$HOME/.claude/brain/update.sh" --yes
```

**Step 4 — Handle a missing installation**
If `~/.claude/brain/` or the update scripts do not exist, the Brain runtime is not (or no longer) installed. Explain that updating is not possible in this state and that a reinstall via the repository fixes it: https://github.com/JanniEinfach/claude-brain-setup — either through the bootstrap one-liner or by cloning the repo and running the setup script (see the repo README and INSTALL.md). Do not attempt to rebuild the runtime by hand.

## Safety Notes

- The update scripts never delete user files. Before anything is overwritten, the previous skills, scripts, and VERSION are copied to `~/.claude/brain/backups/<old-version>-<timestamp>/`.
- The update never modifies `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, or the Obsidian vault. In `config.json` only the `version` field is updated and missing default keys are added.
- Rollback is always possible by copying files back from the backup folder (see `docs/UPDATE.md`).

## Token Discipline

Cheap to run: two short script invocations plus a one-paragraph summary. Never dump the full script output — condense it to version, backup path, and changelog highlights.

## Verification

After an update, confirm success by checking that `~/.claude/brain/VERSION` contains the new version number and reporting it to the user.

## Public Safety Notes

This skill contains no private data, no machine-specific paths, and no credentials. It is safe to include in a public repository.
