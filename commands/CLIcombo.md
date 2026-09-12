---
description: Convert this project to the three-CLI setup (Claude + Codex + Antigravity). Analyses the project first, then assigns roles that fit it.
---

# /CLIcombo — convert this project to the Trio

You are converting the current project so Claude, Codex and Antigravity can work
on it together, with Claude as the approving authority.

**Do not skip the analysis. Do not assign roles from a template.** A React
landing page and a Rust codebase need different role splits. Assigning roles
before understanding the project is the single most common way this setup
produces useless agents.

---

## Step 1 — Analyse the project (mandatory)

Work this out before proposing anything. Use parallel reads.

| Question | How to find out |
|---|---|
| What language and framework? | manifest files: `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `*.csproj` |
| How big? | `git ls-files \| wc -l`, lines of code in the main source folder |
| Are there tests? | test folders, test scripts in the manifest, CI config |
| Is there a typecheck or lint gate? | scripts in the manifest |
| Does a rules file exist? | `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `CONTRIBUTING.md` |
| Is it a git repo with at least one commit? | `git log --oneline -1` |
| What is genuinely hard here? | read the largest and most-changed files |

Report what you found in **five lines or fewer** before moving on. If the
project is empty or has no commit, say so — the worktree workflow needs a
commit and will fail without one.

---

## Step 2 — Assign roles that fit

Claude is always the integrator and the only one who writes to `main`. The
other two get roles derived from what you actually found:

| What you found | Codex is best at | Antigravity is best at |
|---|---|---|
| Large codebase, many files | bulk edits under a tight spec | reading everything at once to answer "where is X?" |
| Strong test suite | test-driven tasks — the gate is objective | reviewing whether tests cover the right things |
| Weak or no tests | writing tests first | judging what is worth testing |
| Heavy typing (TS, Rust, Go) | implementing against fixed interfaces | spotting type design problems |
| Security-sensitive code | nothing unsupervised | counter-review with different blind spots |
| Documentation debt | drafting docs | checking docs against the actual code |

Two rules that hold regardless of project:

- **Only Codex writes code unsupervised**, and only inside a git worktree.
  Antigravity analyses and advises; it never edits.
- **Anything security-sensitive gets a counter-review** by the model that did
  not write it. Two models have different blind spots; that is the whole value.

State your proposed split in a short table and say **why** each role fits this
project. If a role does not make sense here, leave it out — an unused agent is
better than a wrong one.

---

## Step 3 — Wire it up

```bash
node ~/.claude/brain/trio/install.mjs --check     # what is present?
node ~/.claude/brain/trio/install.mjs             # asks before each step
```

Then create the project scaffolding:

```
.ai/
  tasks/          task specs for Codex
  handoff/        results and council answers
.agents/
  policy.json     project-specific permission policy (optional override)
AGENTS.md         the shared rules all three read
PROGRESS.md       shared memory and handover log
```

If `AGENTS.md` already exists, **extend it, do not replace it**. If only
`CLAUDE.md` exists, keep it and add `AGENTS.md` pointing at the same content —
Codex and Antigravity read `AGENTS.md`, Claude Code reads both.

---

## Step 4 — Prove it works

Do not declare success on configuration alone. Run these and show the output:

```bash
node ~/.claude/brain/trio/trio.mjs doctor
node ~/.claude/brain/trio/broker.test.mjs
node ~/.claude/brain/trio/trio.mjs council "one real question about this project"
```

The council call is the real test: it proves both models answer **with project
context**. If one returns an empty answer or a permission error, the wiring is
broken — say so plainly instead of reporting success.

---

## What to tell the user at the end

- The role split and the reason for it
- What each CLI may and may not do here
- The exact commands they now have
- Anything that is **not** wired up and why

Keep it short. If the project turns out to be too small to benefit — a handful
of files, no tests, solo work — **say that and recommend against the setup.**
The overhead is real and is not worth it for every project.
