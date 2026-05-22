# Troubleshooting

## CLAUDE.md is not being loaded

Claude Code looks for `CLAUDE.md` in your home directory (`~/CLAUDE.md`) and in the current project directory. Check that the file exists:

```bash
ls -la ~/CLAUDE.md
```

If it is missing, run the installer:

```bash
./scripts/install.sh
```

To verify Claude loaded it, start a session and ask:

```
What instructions are you following from CLAUDE.md?
```

Claude should summarise the key sections. If it cannot, the file is either missing, empty, or in the wrong location.

## Claude is using the wrong model

The model is set at launch. It cannot change mid-session.

Check which model you launched with:

```bash
# If you used an alias, check what the alias expands to:
alias cc
alias cch
alias cco

# Or launch explicitly:
claude --model claude-sonnet-4-6
```

If no `--model` flag is used and no default is set in `settings.json`, Claude Code uses its own built-in default. To set a persistent default:

```json
{
  "model": "claude-sonnet-4-6"
}
```

Save this as `~/.claude/settings.json` (or copy from `settings.example.json`).

## Permission denied when running scripts

The scripts need execute permission:

```bash
chmod +x scripts/install.sh
chmod +x scripts/setup.sh
```

## Finding your backup CLAUDE.md

Backups are written with a timestamp suffix:

```bash
ls ~/CLAUDE.md.backup_*
```

To restore a backup:

```bash
cp ~/CLAUDE.md.backup_20260101_120000 ~/CLAUDE.md
```

The backup is never deleted.

## Bundled Brain skills did not install

Check whether the Brain skills are present:

```bash
ls ~/.claude/skills/ | grep brain-
```

If no results, install them:

```bash
# Linux / macOS
./scripts/install.sh --with-skills

# Windows PowerShell
.\scripts\install.ps1 -WithSkills
```

Also check permissions on the skills directory:

```bash
ls -la ~/.claude/skills/
```

If the directory does not exist, create it:

```bash
mkdir -p ~/.claude/skills/
```

Then retry the install command above.

## External ECC skills are missing

Skills listed in `docs/SKILLS.md` under the "requires optional ECC skill collection" sections are not bundled with this repository. They reference the ECC (Everything Claude Code) skill collection.

To check if a skill is installed:

```bash
ls ~/.claude/skills/skill-name
```

If a skill is missing, it was not part of your Claude Code installation. You can install the ECC skill collection separately or skip that skill.

## Token usage seems high

Common causes:

1. **Wrong model.** Check that you are not using Opus for simple tasks.
2. **Session is too large.** Use `/create_handoff`, end the session, start fresh.
3. **CLAUDE.md is too long.** Keep it under 150 lines. Move details to `docs/`.
4. **Skills preloaded unnecessarily.** Only load skills when you actually need them.
5. **Long command output pasted raw.** Summarise output instead of pasting it.

See `docs/TOKEN_EFFICIENCY.md` for the full guide.

## setup.sh is not executable

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

Or run it explicitly with bash:

```bash
bash scripts/setup.sh
```

## setup.sh fails with "python3 not found"

The setup script uses `python3` to safely replace template placeholders. Install Python 3:

```bash
# macOS
brew install python3

# Ubuntu/Debian
sudo apt install python3
```

Python 3 is available on virtually all modern macOS and Linux systems by default.

## The generated CLAUDE.md looks wrong

Run setup again with `--dry-run` to preview without writing:

```bash
./scripts/setup.sh --dry-run
```

Review the output. If a placeholder was not replaced, the template substitution failed. Check that `templates/CLAUDE.template.md` exists in the project root.

## CLAUDE.md was overwritten unintentionally

The install script creates a timestamped backup before every overwrite. Find it:

```bash
ls ~/CLAUDE.md.backup_*
```

Restore the one you want:

```bash
cp ~/CLAUDE.md.backup_20260101_120000 ~/CLAUDE.md
```
