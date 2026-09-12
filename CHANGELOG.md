# Changelog

All notable changes to this project will be documented here.

Format: [Semantic Versioning](https://semver.org/). Dates are YYYY-MM-DD.

## [3.0.0] — 2026-09-12

Major release: Claude Brain becomes a **Trio**. Codex and Antigravity can now work on the same project, with Claude as the approving authority for everything they do.

Added:
- **Permission broker** (`brain/trio/broker.mjs`): Claude decides what the other agents may do. Registered as an Antigravity `PreToolUse` hook. A `deny` from the broker overrides any permission the tool grants itself — verified by test, not assumed. The reason text reaches the model verbatim, so a blocked agent knows why and what to do instead. `--dangerously-skip-permissions` is never used anywhere in this project.
- **Broker test suite** (`brain/trio/broker.test.mjs`): 48 cases covering ordinary work, destruction, command chaining (`cat README.md && rm -rf /`), cost protection, self protection, loop protection, credentials, escaping the project, and fail-closed behaviour. Run it after every policy change.
- **Default policy** (`brain/trio/policy.default.json`): deny-first ordering, protected paths, project-scoped writes. Blocks network commands (cost protection), package installs (machine protection), credential paths, the supervision files themselves (self protection), and agents starting other agents (loop protection).
- **Trio dispatcher** (`brain/trio/trio.mjs`): `doctor`, `ask`, `review`, `council`, and a `task` workflow that runs delegated work in isolated git worktrees behind an acceptance gate (typecheck → tests → file limits → read). One cross-platform Node program instead of a `.sh`/`.ps1` pair carrying duplicate logic.
- **Trio installer** (`brain/trio/install.mjs`): detects what is present, merges into existing hooks and permissions instead of overwriting, backs up every file it touches, and verifies itself by running the broker tests. Supports `--check`, `--yes`, `--uninstall`, `--home`.
- **Configuration analyser** (`brain/trio/analyze-claude-md.mjs`): before offering to wipe a CLAUDE.md, the wizard reports what exists and recommends keep / rebuild / look-first. Looks at `CLAUDE.md`, `AGENTS.md` **and** `~/.claude/rules/` — an analyser that only checked `CLAUDE.md` would tell a user with a large handwritten ruleset that there is nothing to lose.
- **`/CLIcombo` command**: converts an existing project to the trio. Analyses language, size, tests and existing rules first, then assigns roles that fit — never from a template.
- Two skills: `brain-trio-orchestration` (role split, task specs, acceptance gate) and `brain-permission-broker` (how the supervision works, how to extend it safely). 16 bundled skills total.
- Docs: `docs/TRIO.md`, `docs/CLI_PLUGINS.md` (plugin recommendations for both CLIs, including the warning that plugin traffic bypasses the shell policy).
- Setup questions F21 (wire in Codex and Antigravity) and F22 (rebuild existing configuration, preceded by the analysis). Bilingual, asked only when relevant — F21 is skipped entirely when neither CLI is installed.
- `commands/` directory, installed to `~/.claude/commands/` by both installers.

Fixed:
- **`setup.sh` died silently on Windows.** `write_config_json` called `python3`. On Windows, `python3` is usually the Microsoft Store placeholder: `command -v python3` finds it, executing it exits with code 49, and the wizard stopped there without an error message — no config, no update hook, no final screen. The function now writes JSON with plain shell using the existing `json_escape`, removing the interpreter dependency entirely.
- `--target` was not honoured by the new components. The trio installer and the analyser now accept `--home` so a test run cannot write into the user's real configuration.

Changed:
- **Model IDs replaced with aliases** throughout docs, skills and scripts: `claude --model opus` instead of `claude --model claude-opus-4-8`. Pinned IDs silently become wrong when a new version ships and nothing warns you; aliases always resolve to the current release. `/model` inside a session shows what is actually active.
- `CLAUDE.md` and the generated template gained a Trio section with explicit triggers for when to propose the setup — and when to advise against it (projects under ~20 files, no test suite, work finishable alone in under 15 minutes).
- `install.sh` / `install.ps1`: five steps instead of four; commands and the trio runtime are installed unconditionally, while the wiring itself stays opt-in.
- `docs/SKILLS.md` updated for 16 skills.

Unchanged:
- The iron rules: scripts never delete user files, every overwrite is preceded by a timestamped backup, everything installs under the home directory, no admin rights, no secrets.
- The Obsidian Master Brain, the update system, and the bilingual wizard from 2.0.0.
- MIT license.

## [2.0.0] — 2026-07-13

Major release: Claude Brain becomes a Master Brain — persistent cross-project memory, an update system with `/brain-update`, one-line bootstrap installers, and a rebuilt bilingual beginner-proof setup wizard.

Added:
- Obsidian Master Brain: optional persistent cross-project memory as a plain-Markdown vault; scaffolds in `templates/obsidian/de/` and `templates/obsidian/en/`; default location `~/Documents/ClaudeBrainVault`; concept documented in `docs/OBSIDIAN_BRAIN.md`
- Update system: `scripts/check-update.ps1/.sh` (daily version check, installed as a Claude Code `SessionStart` hook, one GET request to GitHub, opt-out available), `scripts/update.ps1/.sh` (applies updates with backup to `~/.claude/brain/backups/`), `VERSION` file, brain runtime under `~/.claude/brain/` with `config.json`, and `docs/UPDATE.md`
- New skill `skills/brain-update/SKILL.md` — check for and apply Claude Brain updates from inside a session (14 bundled skills total)
- `scripts/bootstrap.ps1/.sh`: one-line web installers (`irm ... | iex` / `curl ... | bash`) — download the repo ZIP to a temp folder and start the interactive setup; no git required
- `README.de.md`: full German README with language-switch links in both directions
- `INSTALL.md`: step-by-step installation guide for both platforms, written for absolute beginners
- Answer-file mode (`--answer-file` / `-AnswerFile`) in the setup wizard for unattended and CI runs
- Migration handling for V1 installs: an existing `~/CLAUDE.md` is detected and can be renamed to `~/CLAUDE.md.backup-<timestamp>` (never deleted)

Changed:
- Interactive wizard rebuilt for absolute beginners: 20 questions (was 15), fully bilingual German/English with the language chosen in question 1, a plain-language explanation before every question, input validation with friendly re-prompts, a final answer summary with confirmation before anything is written, and automatic model detection from `~/.claude/settings.json`
- Personalized `CLAUDE.md` now installs to `~/.claude/CLAUDE.md` (Claude Code's global location) instead of `~/CLAUDE.md`
- Model IDs updated to the Claude 5 family throughout docs, scripts, and skills: `claude-sonnet-5`, `claude-opus-4-8`, `claude-fable-5` added as the top-tier model (availability depends on plan); `claude-haiku-4-5-20251001` unchanged
- `skills/brain-model-routing` and `skills/brain-session-handoff` updated to Claude 5 model IDs; all bundled skills reviewed and refreshed
- Orchestration level is no longer a setup question — fixed at "Balanced" with the 15-minute rule
- `scripts/install.ps1/.sh`: now also installs the brain runtime (`~/.claude/brain/`) and registers the update hook; new flag `--no-update-check` / `-NoUpdateCheck` to skip hook registration
- `settings.example.json`: added a `SessionStart` hook example for the update check
- `docs/ONBOARDING_QUESTIONS.md`: rewritten for the V2 question catalog (F1–F20)
- `docs/MODEL_ROUTING.md`: rewritten for the Claude 5 family with a decision tree and exact `--model` examples
- `docs/SECURITY.md`: documents every network access (bootstrap, check-update, update) with exact URLs and the opt-out
- `docs/TROUBLESHOOTING.md`: new entries for hook not firing, broken umlauts (PowerShell 5.1 / BOM), execution policy, missing python3/jq, updates behind a proxy or offline, and two conflicting CLAUDE.md files after V1 migration
- `docs/FAQ.md`, `docs/TOKEN_EFFICIENCY.md`, `docs/RUFLO_ORCHESTRATION.md`, `docs/SKILLS.md`: updated for 14 skills, the new questions, and Claude 5 model IDs
- `README.md`: rewritten around the Master Brain message with bootstrap one-liners first

Unchanged:
- The iron rules: scripts never delete user files, every overwrite is preceded by a timestamped backup, everything installs under the home directory, no admin rights, no secrets
- `docs/PRINCIPLES.md`, `docs/DREAM_CYCLE.md`, `docs/GITHUB_LABELS.md` carried over from V1 as-is
- MIT license

## [0.4.0] — 2026-05-22

13 bundled Brain skills added; installer updated with skill install flags; documentation restructured.

Added:
- `skills/brain-core-workflow/SKILL.md` — disciplined six-step development workflow
- `skills/brain-token-discipline/SKILL.md` — token-efficient working habits
- `skills/brain-model-routing/SKILL.md` — model selection guide before session start
- `skills/brain-karpathy-principles/SKILL.md` — think before coding, simplicity, surgical changes
- `skills/brain-security-review/SKILL.md` — security checklist for code and repositories
- `skills/brain-cross-platform-setup/SKILL.md` — script validation across Linux, macOS, Windows
- `skills/brain-session-handoff/SKILL.md` — structured handoff before ending or switching sessions
- `skills/brain-pr-review/SKILL.md` — PR review checklist for this repository
- `skills/brain-ruflo-orchestration/SKILL.md` — when and how to use multi-agent workflows
- `skills/brain-skill-authoring/SKILL.md` — guide for writing new bundled Brain skills
- `skills/brain-github-release/SKILL.md` — checklist for preparing a public GitHub release
- `skills/brain-marketing-support/SKILL.md` — sales, marketing, and SEO copy guidance (optional)
- `skills/brain-fivem-development/SKILL.md` — FiveM Lua, NUI, and framework guidance (optional)

Updated:
- `scripts/install.sh`: added `--with-skills` and `--skills-only` flags
- `scripts/setup.sh`: added bundled skill install prompt after setup questions
- `scripts/install.ps1`: added `-WithSkills` and `-SkillsOnly` parameters
- `scripts/setup.ps1`: added bundled skill install prompt after setup questions
- `docs/SKILLS.md`: restructured into Bundled Brain Skills and Optional External Skills sections
- `docs/SECURITY.md`: added note that bundled skills are Markdown files, not executable code
- `docs/TROUBLESHOOTING.md`: added entry for bundled skills not installing
- `CONTRIBUTING.md`: added "How to add a bundled skill" section
- `README.md`: added Bundled Brain Skills section with table and install commands; updated file structure
- `CLAUDE.md`: added bundled Brain skills to the skills section
- `templates/CLAUDE.template.md`: added bundled Brain skills to the skills section
- `.github/pull_request_template.md`: added bundled skills checklist item

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
