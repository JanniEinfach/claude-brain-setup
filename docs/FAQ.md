# Frequently Asked Questions

## Does Claude automatically switch to a cheaper model for simple tasks?

No. The model is fixed when you launch Claude Code with `--model`. Claude cannot change models mid-session. You pick the right model for the task before starting.

See `docs/MODEL_ROUTING.md` for a decision table.

## Does this automatically reduce my token usage?

No. Good habits reduce token usage. This project documents those habits in `CLAUDE.md` and `docs/TOKEN_EFFICIENCY.md`. The habits work when you follow them.

## Do I need all the skills listed in SKILLS.md?

No. Load a skill only when you need it. Most sessions need just one or two. Loading many skills speculatively wastes tokens. The list in `docs/SKILLS.md` is a reference — not a load order.

## When should I use Opus?

Use Opus when:
- Designing system architecture or making broad design decisions
- Running a security audit on auth, payment, or user data code
- Orchestrating multiple agents for a complex parallel task
- Doing a large cross-module refactor where missing a coupling would be costly

Use Sonnet for most development work. Use Haiku for simple single-file edits and formatting.

## Can I use this with multiple programming languages?

Yes. During interactive setup, you can specify multiple stacks (e.g. "TypeScript, Python, Go"). The generated `CLAUDE.md` includes them in the Work Context section. Claude reads this and adjusts accordingly.

## Can I use this for marketing or copywriting work?

Yes. Enable marketing support during setup (Question 12) and the generated `CLAUDE.md` includes writing guidelines and relevant skills like `/article-writing`, `/seo`, and `/brandkit`.

## Does `/dream` automatically update my CLAUDE.md?

No. The `/dream` skill is a manual memory-consolidation tool. You run it deliberately at the end of a significant session to extract learnings. It does not automatically edit any file.

## Can I run setup.sh multiple times?

Yes. Each run backs up the existing `CLAUDE.md` with a timestamp before overwriting, so nothing is lost.

## What if I want to go back to the default CLAUDE.md?

Either run `./scripts/install.sh` to reinstall the default, or find your backup:

```bash
ls ~/CLAUDE.md.backup_*
cp ~/CLAUDE.md.backup_TIMESTAMP ~/CLAUDE.md
```

## Does this work on Windows?

The scripts are bash scripts and require a bash-compatible shell. On Windows, use WSL (Windows Subsystem for Linux) or Git Bash.

## Do I need to be online to use this?

No. The setup script and install script run entirely locally. Claude Code itself requires an internet connection to call the Anthropic API, but the configuration files are purely local.

## Is there a way to test the setup script without writing any files?

Yes:

```bash
./scripts/setup.sh --dry-run
```

This runs through all 15 questions and prints the generated `CLAUDE.md` to the terminal without writing anything to disk.
