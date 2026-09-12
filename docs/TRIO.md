# The Trio — Claude, Codex and Antigravity on one codebase

Three AI command lines working on the same project, with Claude as the
approving authority.

---

## Why bother

Each tool has a real, different strength:

| Tool | Strength | Billing |
|---|---|---|
| **Claude Code** | Long context, holds the architecture, integrates | Your Claude plan |
| **Codex** (OpenAI) | Unattended implementation in a sandbox; a second opinion with different blind spots | Your ChatGPT plan |
| **Antigravity** (Google) | Very large context for repo-wide analysis | Your Google AI plan |

**No API keys. No per-token charges.** All three bill through subscriptions you
already have. That is what makes running three models practical instead of an
expensive novelty.

---

## The one rule

**There is exactly one integrator.** Claude decides and merges. The other two
contribute. Nobody else writes to `main`.

The obvious alternative — point all three at the same folder — fails reliably:

1. **No shared memory.** Codex does not know what Antigravity decided ten
   minutes ago. Both invent their own solution to the same problem.
2. **No shared rules.** Every model has different defaults. Naming, error
   handling and structure drift apart within a day.
3. **Write conflicts.** Two agents editing one file means silent data loss.

---

## Install

```bash
node ~/.claude/brain/trio/install.mjs --check     # what is present?
node ~/.claude/brain/trio/install.mjs             # asks before each step
```

The Brain setup wizard offers this as question 21. The installer detects what
you have, skips what you do not, backs up everything it touches, and verifies
itself by running the broker test suite.

### Prerequisites

```bash
# Codex — signs in with your ChatGPT account
npm install -g @openai/codex
codex login

# Antigravity — signs in with your Google account
# Windows:
irm https://antigravity.google/cli/install.ps1 | iex
# then run `agy` once and sign in
```

Node 18+ is required. The broker and dispatcher are Node programs.

---

## Daily use

```bash
node ~/.claude/brain/trio/trio.mjs doctor
node ~/.claude/brain/trio/trio.mjs ask "where is auth handled?" [file ...]
node ~/.claude/brain/trio/trio.mjs review src/auth.ts
node ~/.claude/brain/trio/trio.mjs council "should this be a queue or a cron job?"
```

`council` is the one most people underuse. It asks both models the same
question in parallel and lays the answers side by side. When they agree you can
move on; when they disagree, that disagreement is the actual decision material.

### Converting an existing project

Inside a Claude Code session:

```
/CLIcombo
```

Claude analyses the project first — language, size, test coverage, existing
rules — and only then proposes a role split that fits it. A React landing page
and a Rust service need different splits, and assigning roles from a template
is the fastest way to end up with useless agents.

---

## Delegating work

Every delegation is a spec file under `.ai/tasks/`:

```markdown
---
id: T-042
agent: codex
branch: ai/T-042
---

## Goal
One sentence. What must be true afterwards?

## Permitted files
- src/api/routes/*.ts
NOTHING ELSE.

## Contracts
Paste the interfaces. The agent implements against them and may not change them.

## Acceptance
- [ ] npm test green
- [ ] npm run typecheck clean
```

```bash
node ~/.claude/brain/trio/trio.mjs task run T-042     # own git worktree
node ~/.claude/brain/trio/trio.mjs task gate T-042    # types, tests, file limits
node ~/.claude/brain/trio/trio.mjs task accept T-042  # squash-merge
node ~/.claude/brain/trio/trio.mjs task drop T-042    # discard
```

The permitted-files line is the most important line in the spec. An agent
without boundaries tries to be helpful and rebuilds things nobody asked about.

### The gate matters more than it looks

```
1. Typecheck   -> fails: straight back, unread
2. Tests       -> fails: straight back, unread
3. File limits -> outside the list? discarded
4. Claude reads the diff
5. Merge
```

Steps 1–3 cost no attention. That is the point: **machines check first,
expensive models last.** The scarcest resource is not the model — it is
Claude's context window.

`task run` needs a git repo with **at least one commit**. `git worktree` cannot
create a branch from nothing.

---

## Permissions

Claude is the approving authority. See `docs/PERMISSION_BROKER.md` for the full
picture. In short:

- Every Antigravity tool call passes through `~/.claude/brain/trio/broker.mjs`
- A `deny` from the broker overrides any permission the tool grants itself
- Unknown commands are denied **with an explanation**, never waved through
- Network access and package installs are blocked — that is the cost protection
- No agent may start another agent — that is the loop protection
- `--dangerously-skip-permissions` is never used

---

## When not to use this

Be honest about the overhead. Skip the trio when:

- The project has fewer than roughly 20 files
- There are no tests — the acceptance gate has nothing to check
- The work is exploratory and the target keeps moving
- You can finish the task alone in under 15 minutes

Writing a task spec takes longer than making a small change yourself. Three
models on a small project is slower than one.

---

## Troubleshooting

**Antigravity returns nothing and mentions permissions.**
The broker is not registered, or the workspace was not passed. Check
`~/.gemini/config/hooks.json` exists and that calls use `--add-dir`.
`trio.mjs` always sets it.

**A shell command is refused although the policy allows it.**
Antigravity grants shell access only for **exact command lines**.
`command(npm)` does not cover `npm test`. Add the exact line to
`seedShellCommands` in the policy and re-run the installer.

**`task run` fails with a worktree error.**
The repository has no commit yet. Make one.

**Codex answers but could not read any files.**
Expected. `--sandbox read-only` blocks shell access. `trio.mjs` supplies file
contents inline rather than relying on the agent to read them — more reliable
and cheaper.

**A council answer is empty.**
That tool is not signed in. Run `trio.mjs doctor`.
