# Frequently Asked Questions

## Does Claude automatically switch to a cheaper model for simple tasks?

No. The model is fixed when you launch Claude Code with `--model`. Claude cannot change models mid-session. You pick the right model for the task before starting — see `docs/MODEL_ROUTING.md` for the Claude 5 family decision table.

## How does the setup know which model I use?

During Question 7 the wizard reads `~/.claude/settings.json` and looks at the `model` field. If it finds one (e.g. a string containing `sonnet`), it asks you to confirm. If nothing is found, you pick from a menu — or choose "I don't know", in which case the generated configuration includes a tip to run `/model` inside Claude Code to find out.

## What is Opus (1M context) and why can't I select it?

Opus (1M context) (`opus[1m]`) is the flagship of the new Mythos model class. Access depends on your subscription plan. If `/model` does not list it, your plan does not include it — Opus (`opus`) is the strongest alternative.

## What is the Obsidian Master Brain?

Claude's long-term memory: a folder of linked Markdown notes where Claude records projects, decisions, durable knowledge, and observations about how you work — across sessions. The setup scaffolds the vault (default `~/Documents/ClaudeBrainVault`) and teaches Claude the conventions via your `CLAUDE.md`. Full concept in `docs/OBSIDIAN_BRAIN.md`.

## Do I need the Obsidian app for the Master Brain?

No. The memory is plain text files — Claude reads and writes them without any app. Obsidian (free, from https://obsidian.md) is only a nice viewer: install it whenever you like and open the vault folder in it. Nothing breaks without it.

## How does the update system work?

Once a day, at session start, a tiny hook script fetches the `VERSION` file from GitHub (one small GET request to `raw.githubusercontent.com`; no data about you is sent). If a newer version exists, Claude tells you. You then run `/brain-update` inside Claude Code — or `~/.claude/brain/update.sh` / `update.ps1` manually. The updater backs everything up to `~/.claude/brain/backups/` before changing anything and never touches your personalised `CLAUDE.md`, your answers, or your vault. Details in `docs/UPDATE.md`.

## How do I turn the update check off?

Any of these: answer no to Question 19 during setup, run `install` with `--no-update-check` / `-NoUpdateCheck`, set `updateCheck.enabled` to `false` in `~/.claude/brain/config.json`, or remove the `brain/check-update` entry from `~/.claude/settings.json`.

## Is the setup available in German?

Yes. Question 1 of the wizard lets you choose Deutsch or English (pre-selected from your system locale). Everything after that — prompts, explanations, the generated configuration, the vault scaffold, and update notices — uses your chosen language. The reference docs in `docs/` are English; the README exists in both languages (`README.md` / `README.de.md`).

## Does this automatically reduce my token usage?

No. Good habits reduce token usage. This project documents those habits in `CLAUDE.md` and `docs/TOKEN_EFFICIENCY.md`. The habits work when you follow them.

## Do I need all the skills listed in SKILLS.md?

No. Load a skill only when you need it. Most sessions need just one or two. Loading many skills speculatively wastes tokens. The list in `docs/SKILLS.md` is a reference — not a load order.

## When should I use Opus or Fable?

Use Opus (or Opus (1M context), if your plan includes it) when:

- Designing system architecture or making broad design decisions
- Running a security audit on auth, payment, or user data code
- Orchestrating multiple agents for a complex parallel task
- Doing a large cross-module refactor where missing a coupling would be costly

Use Sonnet for most development work. Use Haiku for simple single-file edits and formatting.

## Can I use this with multiple programming languages?

Yes. During setup (Question 6), specify multiple stacks (e.g. "TypeScript, Python, Go") — or press Enter if you do not know yet; Claude figures it out while working. The generated `CLAUDE.md` includes them in the Work Context section.

## Can I use this for marketing or copywriting work?

Yes. Enable marketing support during setup (Question 15) and the generated `CLAUDE.md` includes writing guidelines, plus the bundled `brain-marketing-support` skill.

## Can I run the setup multiple times?

Yes. Each run backs up the existing `CLAUDE.md` with a timestamp before overwriting, so nothing is lost. An existing vault is reused — the wizard only adds missing files and never overwrites your notes. Re-running is also the intended way to change your language or other answers later.

## What if I want to go back to the default CLAUDE.md?

Either run `./scripts/install.sh` (or `.\scripts\install.ps1`) to reinstall the generic default, or restore a backup:

```bash
ls ~/.claude/CLAUDE.md.backup*
cp ~/.claude/CLAUDE.md.backup-<timestamp> ~/.claude/CLAUDE.md
```

## Does this work on Windows?

Yes, natively. Version 2 ships PowerShell scripts (`setup.ps1`, `install.ps1`, `bootstrap.ps1`) that are feature-identical to the bash versions and compatible with Windows PowerShell 5.1 — no WSL or Git Bash required (though the `.sh` scripts also work there if you prefer).

## Do I need to be online to use this?

Mostly no. The setup and install scripts run entirely locally. Network is needed only for: the one-line bootstrap installer (downloads the repository), the optional daily update check (one tiny request, opt-out available), and running an actual update. Claude Code itself needs an internet connection to reach the API, but your configuration files are purely local. See `docs/SECURITY.md` for the complete list of network accesses.

## I upgraded from V1 and now have two CLAUDE.md files. Which one counts?

V1 wrote to `~/CLAUDE.md`; V2 writes to `~/.claude/CLAUDE.md` (the global location that applies in every project). Keep the V2 file and rename the old one — the setup offers to do this for you, and `docs/TROUBLESHOOTING.md` shows the manual commands. The old file is renamed, never deleted.

## Is there a way to test the setup script without writing any files?

Yes:

```bash
./scripts/setup.sh --dry-run          # Linux / macOS
.\scripts\setup.ps1 -DryRun           # Windows PowerShell
```

This runs through all 20 questions and prints the generated `CLAUDE.md` to the terminal without writing anything to disk.
