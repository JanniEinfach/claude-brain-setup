# Changelog

All notable changes to this project will be documented here.

Format: [Semantic Versioning](https://semver.org/). Dates are YYYY-MM-DD.

## [0.3.0] — 2026-05-22

Public release polish: Windows PowerShell support, GitHub community files, engineering principles, and security wording improvements.

Added:
- `scripts/install.ps1`: non-interactive Windows installer with `-DryRun` and `-Target` support
- `scripts/setup.ps1`: interactive Windows setup with all 15 questions, matching setup.sh behavior
- `docs/PRINCIPLES.md`: engineering principles (think before coding, simplicity, surgical changes, goal-driven execution)
- `docs/GITHUB_LABELS.md`: suggested GitHub label set with CLI creation commands
- `CODE_OF_CONDUCT.md`: community standards for contributors
- `.github/pull_request_template.md`: structured PR template with checklist
- `.github/ISSUE_TEMPLATE/bug_report.md`: bug report template
- `.github/ISSUE_TEMPLATE/feature_request.md`: feature request template
- `.github/ISSUE_TEMPLATE/security_report.md`: security report template

Updated:
- `README.md`: added banner image, Anthropic disclaimer, Windows PowerShell install section, PRINCIPLES.md in file structure, updated Requirements to include Windows/PowerShell
- `CLAUDE.md`: added reference to docs/PRINCIPLES.md; unified skill load phrasing to "/skill-name inside a Claude Code session"
- `templates/CLAUDE.template.md`: unified skill load phrasing
- `CONTRIBUTING.md`: expanded with fork/branch workflow, Windows validation steps, PowerShell testing, PR checklist
- `docs/SECURITY.md`: precise wording distinguishing user files from script-created temp files; added Windows scripts to coverage
- `docs/SKILLS.md`: tldr-code and tldr-overview noted as optional (require separate install); unified skill load phrasing
- `docs/TOKEN_EFFICIENCY.md`: removed tldr commands, replaced with grep/find equivalents
- `scripts/setup.sh`: replaced tldr reference with grep/find in Conservative token rule
- `.gitignore`: added Windows-specific entries

Removed:
- `SETUP_PROMPT.md` (stub redirecting to MASTER_PROMPT.md — obsolete)
- `docs/SKILLS_ARSENAL.md` (stub redirecting to SKILLS.md — obsolete)
- `docs/TOKEN_MANAGEMENT.md` (stub redirecting to TOKEN_EFFICIENCY.md — obsolete)
- Empty directories: `claude-md/`, `skills/`

Skill/agent audit results:
- All 43 skills listed in docs/SKILLS.md verified present in ~/.claude/skills/
- All 18 agents listed in docs/SKILLS.md verified present in ~/.claude/agents/
- tldr-code and tldr-overview marked optional (not installed by default in base setup)

## [0.2.0] — 2026-05-22

Major expansion: interactive setup flow, personalized template, and complete documentation.

Added:
- `scripts/setup.sh`: interactive setup with 15 questions, dry-run mode, and `--target` flag
- `templates/CLAUDE.template.md`: template with 11 placeholders for personalization
- `docs/ONBOARDING_QUESTIONS.md`: explains each setup question and what it affects
- `docs/SECURITY.md`: what this project touches, script safety, secrets handling
- `docs/TROUBLESHOOTING.md`: common issues and fixes
- `docs/FAQ.md`: short answers to common questions
- `CONTRIBUTING.md`: how to open issues, submit PRs, add questions, update skills

Updated:
- `README.md`: complete rewrite with quick start, both install options, example workflows, file structure
- `CLAUDE.md`: cleaned to under 150 lines, removed Sales and Marketing section (now optional via setup)
- `docs/MODEL_ROUTING.md`: added escalation via handoff workflow, clearer alias examples
- `docs/TOKEN_EFFICIENCY.md`: added common search tool examples, expanded warnings section
- `docs/SKILLS.md`: added Marketing/Content category, verified agent list, expanded Backend and Memory sections
- `docs/RUFLO_ORCHESTRATION.md`: trimmed to under 100 lines, tightened anti-patterns list
- `settings.example.json`: added `rg`, `which`, `echo`, `pwd`, and `git blame` to allowlist
- `LICENSE`: updated copyright holder to "Claude Brain Setup Contributors"
- `.gitignore`: added `*.secret`, `*.bak`, `generated/`, `node_modules/`, `__pycache__/`

Removed:
- Obsolete files redirected or cleaned: `INSTALL.md`, `SETUP_PROMPT.md`, `docs/SKILLS_ARSENAL.md`, `docs/TOKEN_MANAGEMENT.md`, `docs/DREAM_CYCLE.md`

## [0.1.0] — 2025-05-22

Initial release.

- `CLAUDE.md`: concise English system instruction file
- `MASTER_PROMPT.md`: one-time setup verification prompt
- `scripts/install.sh`: safe, non-destructive install script with backup
- `settings.example.json`: example Claude Code settings with Sonnet as default
- `docs/MODEL_ROUTING.md`: honest guide to model selection via CLI flag
- `docs/TOKEN_EFFICIENCY.md`: practical token reduction habits
- `docs/SKILLS.md`: verified skill list with categories and token cost notes
- `docs/RUFLO_ORCHESTRATION.md`: lightweight agent orchestration guide
- `LICENSE`: MIT
- `.gitignore`: OS, editor, secrets, and backup files

Corrections in 0.1.0:
- Removed all auto model-switching claims (not possible mid-session)
- Removed auto CLAUDE.md update claims (/dream does not edit files automatically)
- Replaced German content with English
- Removed inflated token savings estimates
- Removed FiveM-specific rules from generic system instructions
- Verified all referenced skills against actual skills directory
- Removed unsubstantiated token savings marketing claims
