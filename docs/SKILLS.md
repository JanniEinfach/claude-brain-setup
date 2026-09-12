# Skills Reference

Skills in `~/.claude/skills/` are loaded on demand with `/skill-name` inside a Claude Code session. Only load a skill when you need it — speculative loading wastes tokens.

## Bundled Brain Skills (16)

These skills are included in this repository and installed by the setup scripts (Question 20 of the wizard). They are portable, public-safe Markdown instruction files — they never execute anything by themselves.

Install them during setup or separately:

```bash
# Linux / macOS
./scripts/install.sh --with-skills

# Windows PowerShell
.\scripts\install.ps1 -WithSkills
```

| Skill | Purpose | Token risk |
|-------|---------|-----------|
| `brain-core-workflow` | Six-step disciplined development workflow for non-trivial tasks | Low |
| `brain-token-discipline` | Practical habits that reduce token consumption without reducing quality | Low |
| `brain-model-routing` | Choosing the right Claude model before a session starts (Claude 5 family), with escalation path | Low |
| `brain-karpathy-principles` | Engineering discipline: think before coding, simplicity, surgical changes | Low |
| `brain-security-review` | Security review checklist for code and repositories | Low–Medium |
| `brain-cross-platform-setup` | Checklist for verifying install/setup scripts on Linux, macOS, and Windows PowerShell | Low |
| `brain-session-handoff` | Structured handoff before ending a large session, switching models, or pausing work | Low |
| `brain-pr-review` | PR review checklist for this repository | Low |
| `brain-ruflo-orchestration` | Lightweight multi-agent orchestration guidance — when agents are worth their overhead | Low–Medium |
| `brain-skill-authoring` | Guide for contributors writing new bundled Brain skills | Low |
| `brain-github-release` | Checklist for preparing and publishing a public GitHub release | Low |
| `brain-trio-orchestration` | **New in 3.0.0** — working with Codex and Antigravity: role split, task specs, acceptance gate | Low–Medium |
| `brain-permission-broker` | **New in 3.0.0** — how Claude governs the other agents' permissions | Low |
| `brain-update` | **New in 2.0.0** — check for and apply Claude Brain updates via `~/.claude/brain/update.{sh,ps1}` | Low |
| `brain-marketing-support` | Writing guidance for sales, marketing, and SEO copy (optional) | Low |
| `brain-fivem-development` | FiveM Lua scripting, NUI, and framework guidance (optional) | Low–Medium |

Notes:

- `brain-marketing-support` and `brain-fivem-development` are optional. Enable them during setup (Questions 15 and 14 respectively) or load them manually when needed.
- `brain-update` is the only skill whose instructions involve running a script (`~/.claude/brain/update.sh` / `update.ps1`). The skill itself is still plain Markdown; Claude asks through the normal permission flow before executing anything, and the update script never deletes files — it backs up to `~/.claude/brain/backups/` first. See `docs/UPDATE.md`.

## Optional External Skills

The skills below are part of the ECC (Everything Claude Code) skill collection. They are **not** bundled with this repository. Each section is marked `(requires optional ECC skill collection)` to make this clear.

The list below was verified against the actual skills directory in a full ECC setup. Skills requiring a separate install are noted.

---

## Planning *(requires optional ECC skill collection)*

| Skill | When to use | Token risk |
|-------|-------------|-----------|
| `plan-agent` | Before implementing anything touching 3+ files | Low |
| `premortem` | Before a risky change or large deploy | Low |
| `research` | Before implementing — find what already exists | Low–Medium |
| `research-external` | External docs, libraries, or APIs | Medium |
| `system_overview` | Understand an unfamiliar codebase | Medium |

## Debugging *(requires optional ECC skill collection)*

| Skill | When to use | Token risk |
|-------|-------------|-----------|
| `debug` | Systematic bug investigation | Low–Medium |
| `fix` | Known bug, need implementation | Medium |
| `environment-triage` | Env setup or dependency issues | Low |
| `debug-hooks` | Claude Code hook not firing correctly | Low |

## Implementation *(requires optional ECC skill collection)*

| Skill | When to use | Token risk |
|-------|-------------|-----------|
| `implement_task` | Structured task implementation | Medium |
| `implement_plan` | Execute an existing written plan | Medium |
| `implement_plan_micro` | Small scoped single-task work | Low |
| `tdd` | Test-first development workflow | Medium |
| `tdd-workflow` | TDD process reference | Low |
| `modular-code` | Break large files into modules | Medium |
| `refactor` | Safe refactoring with impact analysis | Medium |
| `dead-code` | Find unused code before removing | Medium |
| `migrate` | Migration work (DB, API, framework) | Medium–High |

## Testing *(requires optional ECC skill collection)*

| Skill | When to use | Token risk |
|-------|-------------|-----------|
| `e2e-testing` | End-to-end test setup and patterns | Medium |
| `python-testing` | pytest patterns, fixtures, mocking | Low |
| `golang-testing` | Go table-driven tests, benchmarks | Low |
| `rust-testing` | Rust unit, integration, doc tests | Low |
| `cpp-testing` | C++ gtest/catch2 patterns | Low |
| `ai-regression-testing` | Regression tests for AI/LLM features | Medium |
| `django-tdd` | TDD patterns for Django | Medium |

## Review and Quality *(requires optional ECC skill collection)*

| Skill | When to use | Token risk |
|-------|-------------|-----------|
| `review` | General code quality review | Medium |
| `security` | Security audit checklist | Medium–High |
| `coding-standards` | Style and convention check | Low |
| `plankton-code-quality` | Lightweight quality scan | Low |
| `qlty-check` | Quality gate before commit | Low |
| `qlty-during-development` | Periodic quality check in a session | Low |

## Search and Navigation *(requires optional ECC skill collection)*

| Skill | When to use | Token risk |
|-------|-------------|-----------|
| `ast-grep-find` | Structural code search (patterns, not text) | Low |
| `search-tools` | Choose the right search tool | Low |
| `search-hierarchy` | Multi-level search strategy | Low |
| `search-router` | Route to best search method automatically | Low |
| `morph-search` | Semantic code search | Medium |
| `tldr-code` | Code analysis via tldr CLI (optional, requires separate install) | Low |
| `tldr-overview` | Project overview via tldr (optional, requires separate install) | Low |
| `repo-research-analyst` | Deep repository research | High |

## Memory and Session *(requires optional ECC skill collection)*

| Skill | When to use | Token risk |
|-------|-------------|-----------|
| `remember` | Store a learning or decision for later | Low |
| `recall` | Retrieve past learnings before similar work | Low |
| `dream` | Consolidate session learnings manually | Medium |
| `create_handoff` | Save context before ending a session | Low |
| `resume_handoff` | Load a handoff in a new session | Low |
| `continuous-learning-v2` | Ongoing learning integration | Low |
| `compound-learnings` | Synthesise multiple learnings | Low |

**Note on `/dream`:** This skill does not automatically edit `CLAUDE.md`. It is a manual tool you run deliberately at the end of a significant session. The bundled `brain-session-handoff` skill covers the handoff use case without any external install.

**Note on the Master Brain:** If you enabled the Obsidian Master Brain during setup, cross-session memory lives in your vault (see `docs/OBSIDIAN_BRAIN.md`) — no external memory skills are required for that.

## Frontend and Web *(requires optional ECC skill collection)*

| Skill | When to use | Token risk |
|-------|-------------|-----------|
| `frontend-patterns` | React/component architecture patterns | Low |
| `shadcn-ui` | shadcn/ui component library usage | Low |
| `imagegen-frontend-web` | Web UI with image generation | Medium |
| `imagegen-frontend-mobile` | Mobile UI with image generation | Medium |
| `frontend-slides` | Slide/presentation UI | Medium |

## Backend and API *(requires optional ECC skill collection)*

| Skill | When to use | Token risk |
|-------|-------------|-----------|
| `backend-patterns` | Server-side architecture patterns | Low |
| `api-design` | REST API design (naming, status codes, pagination) | Low |
| `nestjs-patterns` | NestJS framework patterns | Low |
| `django-patterns` | Django framework patterns | Low |
| `golang-patterns` | Idiomatic Go patterns | Low |
| `rust-patterns` | Idiomatic Rust patterns | Low |
| `python-patterns` | Idiomatic Python patterns | Low |
| `mcp-server-patterns` | Model Context Protocol server development | Low |
| `postgres-patterns` | PostgreSQL query, schema, migration patterns | Low |

## Git and Release *(requires optional ECC skill collection)*

| Skill | When to use | Token risk |
|-------|-------------|-----------|
| `commit` | Structured commit with pre-commit checklist | Low |
| `git-commits` | Commit message conventions | Low |
| `describe_pr` | Generate a PR description from a diff | Low |
| `release` | Release process: versioning, changelog, tags | Low |

## Orchestration *(requires optional ECC skill collection)*

| Skill | When to use | Token risk |
|-------|-------------|-----------|
| `parallel-agents` | Run multiple agents in parallel | Medium–High |
| `sub-agents` | Spawn specialised sub-agents | Medium |
| `agent-orchestration` | Full multi-agent coordination | High |
| `workflow-router` | Route tasks to the right workflow | Low |

## Marketing and Content *(requires optional ECC skill collection)*

| Skill | When to use | Token risk |
|-------|-------------|-----------|
| `article-writing` | Long-form technical or marketing writing | Medium |
| `seo` | SEO strategy and on-page recommendations | Low |
| `brandkit` | Brand voice and messaging guidelines | Low |
| `strategic-compact` | Strategic summary and positioning | Low |

## Verified Agents (in ~/.claude/agents/) *(requires optional ECC skill collection)*

These agents are part of a full ECC setup. Use them via the Task tool for parallel or specialised work.

| Agent | Role | When to use |
|-------|------|-------------|
| `planner` | Implementation planning | Complex features, multi-file work |
| `architect` | System design | Architecture decisions |
| `kraken` | Feature implementation | Complex multi-file implementation |
| `spark` | Focused implementation | Bounded tasks |
| `code-reviewer` | Code quality review | After writing code |
| `security-reviewer` | Security analysis | Before commits touching auth/payments/data |
| `tdd-guide` | TDD guidance | New features and bug fixes |
| `scout` | Codebase exploration | Understanding unfamiliar code |
| `oracle` | External research | Library docs, patterns, APIs |
| `debug-agent` | Systematic debugging | Reproducing and isolating bugs |
| `sleuth` | Root cause investigation | Hard-to-find failures |
| `build-error-resolver` | Build failure fixes | When the build is broken |
| `frontend-dev` | Frontend implementation | Web UI work |
| `backend-dev` | Backend implementation | Server-side work |
| `database-reviewer` | DB schema review | Schema changes |
| `typescript-reviewer` | TypeScript review | TS/JS specific issues |
| `python-reviewer` | Python review | Python specific issues |
| `rust-reviewer` | Rust review | Rust specific issues |

## Skip These Unless You Have a Specific Need

Narrow, experimental, or high-cost skills — do not load speculatively:

- `agentica-*` — Agentica platform specific
- `openfang` — OpenFang multi-agent system specific
- `fivem-nui-design` — FiveM NUI development (load only when building FiveM UIs)
- `imagegen-*` — Image generation workflows
- `gpt-tasteskill`, `taste-skill`, `brutalist-skill`, `minimalist-skill` — design aesthetics tools
- `eval-harness`, `ai-regression-testing` — for AI feature testing only
- `tdd-migration-pipeline`, `tdd-migrate` — migration-specific TDD
