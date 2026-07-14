# Security

## What This Project Touches

Claude Brain Setup is a configuration project. It:

- Writes a personalised `CLAUDE.md` to `~/.claude/CLAUDE.md`
- Copies Markdown skills to `~/.claude/skills/brain-*/`
- Installs a small runtime to `~/.claude/brain/` (version file, `config.json`, update scripts, backups, docs copy)
- Optionally creates an Obsidian vault folder (plain Markdown files) at a path you choose
- Optionally registers one `SessionStart` hook in `~/.claude/settings.json` (the daily update check — with your consent, opt-out at any time)
- Collects your answers to 20 questions during setup
- Never requires admin rights or `sudo`, and writes only inside your home directory (unless you pass `--target` / `-Target`)
- Contains no telemetry and no analytics

## Network Access — Full Disclosure

Most scripts in this project are fully offline. Exactly three script families access the network, and only for the purposes listed here. No personal data is ever transmitted — the requests are plain HTTP GETs to GitHub, which sees the same standard request metadata (IP address, user agent) as when you open github.com in a browser.

| Script | URL(s) contacted | When | What is sent |
|--------|------------------|------|--------------|
| `setup.ps1` / `setup.sh` | none | — | nothing — fully offline |
| `install.ps1` / `install.sh` | none | — | nothing — fully offline |
| `bootstrap.ps1` / `bootstrap.sh` | `https://codeload.github.com/JanniEinfach/claude-brain-setup/zip/refs/heads/main` and `https://codeload.github.com/JanniEinfach/claude-brain-setup/tar.gz/refs/heads/main` (fallback when unzip is missing) | once, when you run the one-line installer | a plain download request for the repository archive |
| `check-update.ps1` / `check-update.sh` | `https://raw.githubusercontent.com/JanniEinfach/claude-brain-setup/main/VERSION` | at most once per 24 hours, at session start (interval configurable) | a plain GET for a version string (a few bytes) |
| `update.ps1` / `update.sh` | `https://api.github.com/repos/JanniEinfach/claude-brain-setup/releases/latest` and `https://codeload.github.com/JanniEinfach/claude-brain-setup/zip/refs/heads/main` (fallback) | only when you explicitly run an update | a release-metadata request and a zip download |

Opting out of the update check:

- Answer **no** to Question 19 during setup, or
- run `install` with `--no-update-check` / `-NoUpdateCheck`, or
- set `"enabled": false` under `updateCheck` in `~/.claude/brain/config.json`, or
- remove the hook entry from `~/.claude/settings.json`.

## The SessionStart Hook Explained

If you enable update notifications, setup adds exactly one entry to `~/.claude/settings.json` (after backing the file up):

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          { "type": "command", "command": "bash \"$HOME/.claude/brain/check-update.sh\"" }
        ]
      }
    ]
  }
}
```

(On Windows the command runs `check-update.ps1` via `powershell -NoProfile -ExecutionPolicy Bypass -File`.)

Properties of the hook script:

- It runs once per Claude Code session start and always exits with code 0 — even offline, behind a proxy, or with a missing config. It can never break your session.
- It finishes in under six seconds (5-second network timeout).
- It is silent unless a newer version exists; then it prints a short notice that Claude relays to you.
- It respects the 24-hour interval — most session starts make no network request at all.
- If `config.json` is missing or cannot be parsed, the config is never overwritten; the 24-hour interval is then enforced via a small marker file, `~/.claude/brain/.lastcheck`, so the at-most-once-per-day promise still holds.
- Registration is idempotent: re-running setup never duplicates the hook, and existing hooks or other settings keys are left untouched.

To remove it, delete the entry containing `brain/check-update` from `~/.claude/settings.json` (a backup `settings.json.backup-<timestamp>` was created when it was added).

## Scripts Never Delete Your Files — the Guarantee

All scripts in this project (`setup`, `install`, `bootstrap`, `check-update`, `update`) follow these iron rules:

- **No deletion of pre-existing files, ever.** No `rm`, `rmdir`, `unlink`, or `Remove-Item` is applied to any file that existed before the script ran. Deletion commands appear only for temporary extraction folders the scripts created themselves during the same run.
- **Backup before overwrite.** Before overwriting `CLAUDE.md`, `settings.json`, skills, or brain runtime files, a timestamped backup is created. The update script additionally snapshots the previous skills, scripts, and VERSION to `~/.claude/brain/backups/<oldVersion>-<timestamp>/` before writing anything.
- **V1 migration renames, never deletes.** If a V1-era `~/CLAUDE.md` is found, setup asks first and, on yes, renames it to `~/CLAUDE.md.backup-<timestamp>`.
- **The updater never touches your personal files.** `~/.claude/CLAUDE.md`, your `config.json` answers, your vault, and your `settings.json` are never overwritten by an update (config only gains new default keys and a refreshed version field).
- **No admin rights**, no writes outside `$HOME` (unless you explicitly pass `--target`).

You can verify the Linux/macOS scripts yourself:

```bash
bash -n scripts/setup.sh       # Syntax check without executing
bash -n scripts/install.sh
grep -n "rm -\|rmdir\|unlink" scripts/*.sh
```

On Windows, search the PowerShell scripts for `Remove-Item` and confirm every occurrence targets a temp extraction directory created by the script itself.

## Shell Permissions and settings.json

The `settings.example.json` file grants Claude Code permission to run a set of read-only shell commands without prompting, and shows the update-check hook as an example. Review it before copying anything into `~/.claude/settings.json`.

The default allowlist contains only read-only commands: `git log`, `git diff`, `git status`, `ls`, `find`, `grep`, `cat`, `head`, `tail`, `wc`, and similar. It does not include:

- Write commands (`git commit`, `git push`, `mv`, `cp`, `rm`)
- Network commands (`curl`, `wget`, `ssh`)
- Privilege escalation (`sudo`, `su`)

If you add your own tools to the allowlist, review what each permission enables before doing so.

## Secrets and CLAUDE.md

Do not put secrets in `CLAUDE.md`. The file is read by Claude Code as a system prompt and should contain only instructions, not credentials.

Never add to CLAUDE.md:

- API keys
- Passwords or tokens
- Database connection strings
- Server IPs or hostnames tied to private infrastructure
- Customer names or private project data

If you fork this project, review your CLAUDE.md before pushing to ensure no private data was added during personalization.

## What the Setup Stores

Your wizard answers are held in memory during the run. After you confirm the summary, the following is written to disk:

- The generated `~/.claude/CLAUDE.md` (name, goals, preferences — readable plain text; review it any time).
- `~/.claude/brain/config.json` with non-sensitive metadata: version, language, your name, experience level, detected model, plan tier, vault path, and update-check settings. No secrets, no credentials.
- If the vault is enabled: a profile note (`me/`) containing your name, goals, and work context.

With `--dry-run`, nothing is written at all. Everything stays local — none of this is transmitted anywhere.

## Bundled Skills

The bundled Brain skills (in `skills/`) are Markdown instruction files. They do not execute code on their own. They are read by Claude Code as context when you load them with `/skill-name`. Installing a skill is equivalent to copying a Markdown document into `~/.claude/skills/` — nothing runs automatically.

The `brain-update` skill instructs Claude to run the local update script (`~/.claude/brain/update.sh` or `update.ps1`) on your behalf. That execution goes through Claude Code's normal permission flow — you approve it — and the script follows the never-delete guarantee above, backing up to `~/.claude/brain/backups/` before changing anything.

## Reporting Vulnerabilities

If you find a security issue in this project, please open a GitHub issue with the label `security`. Do not include working exploit code in the issue body. A brief description of the class of vulnerability is enough.

For sensitive issues, you can reach the maintainers via the GitHub Discussions feature or by direct message before disclosing publicly.
