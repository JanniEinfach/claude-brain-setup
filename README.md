![Brain Setup for Claude Code](brain_setup_for_claude_code.png)

🇩🇪 Deutsche Version: [README.de.md](README.de.md)

# Claude Brain Setup

> **Unofficial Claude Code configuration toolkit. Not affiliated with Anthropic.**

**Turn Claude Code into a Master Brain.** One guided setup gives Claude Code a personalized system instruction file, a persistent cross-project memory, 14 ready-to-use skills, and an update system that keeps everything current.

## What You Get

1. **Beginner-proof interactive setup** — a bilingual (German/English) wizard that explains every question in plain language, validates your answers, and even detects which Claude model you are running. You end up with a `CLAUDE.md` tailored to your name, goals, experience level, and workflow.
2. **Obsidian Master Brain** — an optional persistent memory: a folder of plain Markdown notes where Claude records projects, decisions, and knowledge about your collaboration — across sessions and across projects. Works with or without the free [Obsidian](https://obsidian.md) app.
3. **Automatic update notifications** — a small hook checks once per day whether a new Brain version exists on GitHub and tells you inside Claude Code. Update with a single command: `/brain-update`.
4. **The Trio (new in 3.0.0)** — optionally wire in **Codex** (OpenAI) and **Antigravity** (Google) so three AI command lines work on the same project. Both bill through subscriptions you already have — no API key, no per-token cost. **Claude is the approving authority:** every tool call the others make passes through a permission broker whose policy Claude maintains. `--dangerously-skip-permissions` is never used.
5. **16 bundled skills** — portable Markdown instruction files for disciplined workflows, token efficiency, security reviews, session handoffs, and more. They install to `~/.claude/skills/` and never execute code on their own.
6. **Windows, Linux, and macOS** — feature-identical PowerShell and Bash scripts. No admin rights. The scripts never delete files; every overwrite is preceded by a timestamped backup.

## Quick Start

### One-line install (no git required)

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/JanniEinfach/claude-brain-setup/main/scripts/bootstrap.ps1 | iex
```

**Linux / macOS:**

```bash
curl -fsSL https://raw.githubusercontent.com/JanniEinfach/claude-brain-setup/main/scripts/bootstrap.sh | bash
```

The bootstrap script downloads the repository as a ZIP to a temporary folder and starts the interactive setup from there. Piping a script from the internet requires trust — feel free to read `scripts/bootstrap.ps1` / `scripts/bootstrap.sh` in this repository first.

### Install via git clone

```bash
git clone https://github.com/JanniEinfach/claude-brain-setup.git
cd claude-brain-setup
./scripts/setup.sh          # interactive wizard (recommended)
```

Windows:

```powershell
git clone https://github.com/JanniEinfach/claude-brain-setup.git
cd claude-brain-setup
.\scripts\setup.ps1
```

Prefer a non-interactive install with sensible defaults? Use `./scripts/install.sh` / `.\scripts\install.ps1` (add `--with-skills` / `-WithSkills` for the bundled skills, `--no-update-check` / `-NoUpdateCheck` to skip the update hook).

New to terminals? [INSTALL.md](INSTALL.md) explains every step, including how to open PowerShell or a terminal in the first place.

## What This Does NOT Do

- **Does not auto-switch models.** Claude cannot change models mid-session. You pick the model at launch with `--model`. This project helps you pick correctly.
- **Does not reduce tokens automatically.** Good habits reduce tokens. This project gives you those habits in writing.
- **Does not send your data anywhere.** The only network calls are: downloading this repository (bootstrap/update) and the daily version check — a single GET request for a version number. No telemetry, no analytics. The version check can be disabled (see Security Notes).
- **Does not require the Obsidian app.** The Master Brain is plain Markdown files. Obsidian is a nice, free viewer for them — nothing more.
- **Does not make `/dream` edit your CLAUDE.md automatically.** The dream skill is a manual memory-consolidation tool you run deliberately.
- **Does not know your exact context window percentage.** Claude estimates remaining space; it has no precise percentage counter.
- **Does not require root or admin rights.** Everything installs to your home directory.
- **Does not delete files. Ever.** Existing files are renamed or backed up with a timestamp before anything is written.

## The Interactive Setup

`setup.sh` / `setup.ps1` asks 20 questions — in German or English, your choice at the start. Every question comes with a short plain-language explanation of what it means and why it is asked. Topics: your name, experience level, goals, main work type, tech stacks, model (auto-detected from `~/.claude/settings.json` where possible), plan tier, token strategy, planning style, code style, testing, security level, optional FiveM and marketing modules, partner mode, the Obsidian Master Brain, your first project, update notifications, and skill installation.

At the end you see a summary of all answers and confirm before anything is written.

Flags:

```bash
./scripts/setup.sh --dry-run              # walk through everything, print the result, write nothing
./scripts/setup.sh --target ~/mydir       # write to a custom directory
./scripts/setup.sh --answer-file a.txt    # unattended run: one answer per line, empty line = default
./scripts/setup.sh --help
```

The PowerShell equivalents are `-DryRun`, `-Target`, `-AnswerFile`, `-Help`.

Full question guide: `docs/ONBOARDING_QUESTIONS.md`

### Where things are installed

| What | Location |
|------|----------|
| Personalized `CLAUDE.md` | `~/.claude/CLAUDE.md` (global — applies in every project) |
| Bundled skills | `~/.claude/skills/brain-*/` |
| Brain runtime (version, config, updater) | `~/.claude/brain/` |
| Obsidian Master Brain vault | your choice, default `~/Documents/ClaudeBrainVault` |
| Update hook | one entry in `~/.claude/settings.json` (backed up first) |

**Upgrading from V1?** V1 installed `CLAUDE.md` to your home directory (`~/CLAUDE.md`). The setup detects this, explains the change, and offers to rename the old file to `~/CLAUDE.md.backup-<timestamp>`. Nothing is deleted.

## The Obsidian Master Brain

The Master Brain is Claude's long-term memory: a vault of Markdown notes with a fixed structure — `projects/`, `knowledge/`, `decisions/`, `sessions/`, `me/` — plus writing conventions Claude follows. At session start Claude reads the vault index and the relevant project hub note; at session end it records durable insights and decisions. Over weeks this becomes a genuine cross-project memory that survives every session.

You do not need the Obsidian app for this to work — the vault is ordinary text files. If you install [Obsidian](https://obsidian.md) (free), you get a pleasant graph-linked view of everything Claude knows.

Concept, structure, and FAQ: `docs/OBSIDIAN_BRAIN.md`

## Updates

A `SessionStart` hook runs a small check script when Claude Code starts — at most once every 24 hours. It fetches this repository's `VERSION` file from GitHub (one GET request, nothing about you is sent) and prints a notice if a newer version exists. Claude sees the notice and tells you.

To update:

```
/brain-update            # inside Claude Code — checks, confirms, applies
```

or manually:

```bash
~/.claude/brain/update.sh          # Linux/macOS  (--check to only check, --yes to skip the prompt)
```

```powershell
& "$env:USERPROFILE\.claude\brain\update.ps1"   # Windows  (-Check / -Yes)
```

Updates refresh the bundled skills, the update scripts, and the docs copy. They **never** touch your personalized `CLAUDE.md`, your vault, or your settings. The previous state is backed up to `~/.claude/brain/backups/` first, so you can roll back. Full details: `docs/UPDATE.md`

## Bundled Brain Skills (16)

Portable Markdown instruction files — no code executes automatically. Claude Code reads a skill as context when you load it with `/skill-name` during a session.

| Skill | Purpose |
|-------|---------|
| `brain-core-workflow` | Disciplined six-step development workflow |
| `brain-token-discipline` | Habits that reduce token usage without losing quality |
| `brain-model-routing` | Choosing the right model before a session starts |
| `brain-karpathy-principles` | Engineering discipline: think before coding, simplicity, surgical changes |
| `brain-security-review` | Security checklist for code and repositories |
| `brain-cross-platform-setup` | Validate scripts work on Linux, macOS, and Windows |
| `brain-session-handoff` | Structured handoff before ending a large session or switching models |
| `brain-pr-review` | PR review checklist for this repository |
| `brain-ruflo-orchestration` | When and how to use multi-agent workflows |
| `brain-skill-authoring` | Guide for writing new bundled Brain skills |
| `brain-github-release` | Checklist for preparing a public GitHub release |
| `brain-update` | Check for and apply Claude Brain updates |
| `brain-marketing-support` | Writing guidance for sales, marketing, and SEO copy (optional) |
| `brain-fivem-development` | FiveM Lua scripting, NUI, and framework guidance (optional) |

The interactive setup installs them for you. Separately: `./scripts/install.sh --with-skills` / `.\scripts\install.ps1 -WithSkills`.

## The Trio — Claude + Codex + Antigravity

Three AI command lines on one codebase, with Claude in charge.

| Tool | Strength | Billing |
|---|---|---|
| **Claude Code** | Long context, holds the architecture, integrates | Your Claude plan |
| **Codex** | Unattended implementation in a sandbox; a second opinion with different blind spots | Your ChatGPT plan |
| **Antigravity** | Very large context for repo-wide analysis | Your Google AI plan |

```bash
node ~/.claude/brain/trio/install.mjs --check    # what is present?
node ~/.claude/brain/trio/install.mjs            # asks before each step

node ~/.claude/brain/trio/trio.mjs doctor
node ~/.claude/brain/trio/trio.mjs council "should this be a queue or a cron job?"
```

`council` asks both models the same question in parallel and lays the answers
side by side. When they disagree, that disagreement is the actual decision
material.

Inside a Claude Code session, `/CLIcombo` converts an existing project: it
analyses language, size, tests and existing rules **first**, then assigns roles
that fit — never from a template.

**Safety.** Claude decides what the others may do. A `deny` from the broker
overrides any permission the tool grants itself. Network access and package
installs are blocked (cost protection), the supervision files are untouchable
(self protection), and no agent may start another agent (loop protection).
48 test cases guard this: `node ~/.claude/brain/trio/broker.test.mjs`.

Full guide: [docs/TRIO.md](docs/TRIO.md) · Plugins: [docs/CLI_PLUGINS.md](docs/CLI_PLUGINS.md)

## Example Session

```bash
claude --model sonnet
# Inside the session:
# /brain-core-workflow    — disciplined workflow before touching 3+ files
# /brain-update           — check for Brain updates
# /brain-session-handoff  — save context before ending a large session
```

Quick edits and formatting:

```bash
claude --model haiku
```

Architecture, security, complex multi-file work:

```bash
claude --model opus
```

Top-tier model (availability depends on your plan):

```bash
claude --model opus[1m]
```

Model decision guide: `docs/MODEL_ROUTING.md`

## File Structure

```
claude-brain-setup/
├── README.md                       — this file (English)
├── README.de.md                    — German version
├── CLAUDE.md                       — generic default system instruction file
├── CHANGELOG.md
├── INSTALL.md                      — step-by-step guide for both platforms
├── VERSION                         — current version (read by the update check)
├── LICENSE, CONTRIBUTING.md, CODE_OF_CONDUCT.md, .gitignore, .gitattributes
├── settings.example.json           — safe example Claude Code settings incl. update hook
├── brain_setup_for_claude_code.png
├── .github/                        — issue and PR templates
├── templates/
│   ├── CLAUDE.template.md          — template filled by the setup wizard
│   └── obsidian/
│       ├── de/                     — German vault scaffold
│       └── en/                     — English vault scaffold
├── scripts/
│   ├── setup.ps1 / setup.sh        — interactive wizard (the heart of this project)
│   ├── install.ps1 / install.sh    — quick non-interactive install
│   ├── bootstrap.ps1 / bootstrap.sh — one-line web installer
│   ├── check-update.ps1 / check-update.sh — daily version check (installed as hook)
│   └── update.ps1 / update.sh      — applies updates with backup
├── commands/
│   └── CLIcombo.md                 — /CLIcombo: convert a project to the Trio
├── brain/
│   └── trio/                       — the Trio runtime (new in 3.0.0)
│       ├── broker.mjs              — permission broker: Claude decides
│       ├── broker.test.mjs         — 48 security test cases
│       ├── policy.default.json     — default permission policy
│       ├── hooks.json              — Antigravity PreToolUse registration
│       ├── trio.mjs                — dispatcher: doctor / ask / review / council / task
│       ├── install.mjs             — wires it up, merges, backs up, self-verifies
│       └── analyze-claude-md.mjs   — analyses config before any reset is offered
├── skills/                         — 16 bundled Brain skills
└── docs/
    ├── TRIO.md                     — Claude + Codex + Antigravity
    ├── CLI_PLUGINS.md              — worthwhile plugins for both CLIs
    ├── ONBOARDING_QUESTIONS.md     — all 22 setup questions explained
    ├── MODEL_ROUTING.md            — how to pick the right model (model aliases)
    ├── OBSIDIAN_BRAIN.md           — the Master Brain concept
    ├── UPDATE.md                   — the update system in detail
    ├── TOKEN_EFFICIENCY.md         — practical token-saving habits
    ├── SKILLS.md                   — verified skill list with token costs
    ├── RUFLO_ORCHESTRATION.md      — when and how to use agents
    ├── SECURITY.md                 — what this project touches and risks
    ├── TROUBLESHOOTING.md          — common issues and fixes
    ├── FAQ.md                      — short answers to common questions
    ├── PRINCIPLES.md               — engineering principles
    ├── DREAM_CYCLE.md              — manual memory consolidation
    └── GITHUB_LABELS.md            — suggested label set
```

## Requirements

- Claude Code installed (`npm install -g @anthropic-ai/claude-code`)
- An Anthropic API key or Claude Pro/Max subscription
- Windows: PowerShell 5.1 or newer — Linux/macOS: Bash
- `curl` or `wget` (Linux/macOS, for bootstrap and update check)
- Optional: `python3` or `jq` on Linux/macOS for automatic settings merging (a manual fallback is provided)
- Optional: the Obsidian app for viewing the Master Brain
- `git` only if you install via clone
- No root or admin rights required

## Security Notes

- **The scripts never delete files.** They copy, rename, and back up. Every overwrite is preceded by a timestamped backup.
- **Network access is limited to three scripts:** `bootstrap` (downloads the repo ZIP from GitHub), `check-update` (fetches the `VERSION` file), and `update` (downloads the latest release). Nothing else talks to the network.
- **Daily version check — full disclosure:** once installed, a `SessionStart` hook performs at most one GET request per 24 hours to `https://raw.githubusercontent.com/JanniEinfach/claude-brain-setup/main/VERSION`. It sends no data about you — it only downloads a version string. Opt out any time: answer "no" to setup question 19, install with `--no-update-check` / `-NoUpdateCheck`, or set `updateCheck.enabled` to `false` in `~/.claude/brain/config.json`.
- Bundled skills are Markdown files only. They do not run code automatically.
- Do not put secrets, API keys, or private paths in `CLAUDE.md`. It is read as a system prompt, not a config file.
- `settings.example.json` contains read-only shell permissions and the update hook. Review before using.
- Full guide: `docs/SECURITY.md`

## Troubleshooting

See `docs/TROUBLESHOOTING.md` — including PowerShell execution policy, broken umlauts, hooks not firing, offline behavior, and the V1→V2 migration.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to fork, validate, and submit pull requests. Contributions must pass all syntax and security checks before submission.

## License

MIT — see `LICENSE`.
