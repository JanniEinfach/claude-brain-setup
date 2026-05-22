# Security

## What This Project Touches

Claude Brain Setup is a configuration project. It:

- Writes a `CLAUDE.md` file to your home directory
- Optionally copies `docs/` to your home directory
- Reads your answers to 15 questions in memory during setup
- Does not transmit any data
- Does not install daemons, background processes, or shell hooks
- Does not modify any Claude Code settings files unless you explicitly copy `settings.example.json`

## Install Script Safety

The install and setup scripts (`scripts/install.sh`, `scripts/setup.sh`, `scripts/install.ps1`, `scripts/setup.ps1`) never delete user files. Specifically:

- They do not use `rm`, `rmdir`, `unlink`, or equivalent deletion on any file that existed before the script ran.
- Before overwriting an existing `CLAUDE.md`, they copy it to a timestamped backup (e.g. `CLAUDE.md.backup_20260522_143000`). The original is always preserved.
- Temporary working files created by the scripts themselves during their run are stored in `/tmp` on Linux/macOS and are cleaned up when the script exits. These temporary files are created by the script — they are never your files.
- The scripts do not require root or `sudo`.
- The scripts do not write outside your home directory unless you specify `--target` / `-Target`.
- The scripts do not download or execute remote code.

You can verify the Linux/macOS scripts yourself:

```bash
bash -n scripts/install.sh    # Syntax check without executing
bash -n scripts/setup.sh      # Syntax check without executing
grep -n "rm \|rmdir\|unlink" scripts/install.sh scripts/setup.sh
```

## Shell Permissions and settings.json

The `settings.example.json` file grants Claude Code permission to run a set of read-only shell commands without prompting. Review it before copying it to `~/.claude/settings.json`.

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

## Setup Answers Are Not Persisted

The interactive setup script (`setup.sh`) collects your answers in shell variables during the session. They are not written to disk in raw form. Only the generated `CLAUDE.md` is saved. If you run `--dry-run`, nothing is written at all.

## Bundled Skills

The bundled Brain skills (in `skills/`) are Markdown instruction files. They do not execute code on their own. They are read by Claude Code as context during a session when you load them with `/skill-name`. Installing a skill is equivalent to copying a Markdown document to your `~/.claude/skills/` directory — nothing runs automatically.

## Reporting Vulnerabilities

If you find a security issue in this project, please open a GitHub issue with the label `security`. Do not include working exploit code in the issue body. A brief description of the class of vulnerability is enough.

For sensitive issues, you can reach the maintainers via the GitHub Discussions feature or by direct message before disclosing publicly.
