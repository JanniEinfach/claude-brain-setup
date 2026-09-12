# brain-trio-orchestration

## Purpose

Work with Claude, Codex and Antigravity on one codebase without producing merge
chaos or contradictory decisions. Covers role split, the task spec protocol, the
acceptance gate, and when the overhead is not worth it.

## When to Use

When a task is large enough that a second and third model genuinely pay for
themselves: bulk implementation under a fixed contract, repo-wide analysis, or a
decision that benefits from an opposing view.

## When Not to Use

Anything you can finish alone in under 15 minutes. Single-file edits. Quick
questions. Projects with fewer than roughly 20 files. The coordination cost is
real — writing a task spec takes longer than making a small change yourself.

---

## The one rule that makes this work

**There is exactly one integrator.**

Claude decides and merges. Codex and Antigravity contribute. Nobody else writes
to `main`.

The obvious alternative — point all three at the same directory and hope — fails
reliably for three reasons:

1. **No shared memory.** Codex does not know what Antigravity decided ten
   minutes ago. Both invent their own solution to the same problem.
2. **No shared rules.** Every model has different defaults. Without a hard
   contract, naming, error handling and structure drift apart.
3. **Write conflicts.** Two agents editing one file means silent data loss —
   last write wins.

---

## Role split

| Role | Who | Why that one |
|---|---|---|
| Integrator | Claude | Holds the long context, knows every contract, only writer on `main` |
| Parallel builder | **Codex** | The only one with a working unattended write mode, sandboxed |
| Analyst, second opinion | **Antigravity** | Large context, never edits, different blind spots |
| Images and characters | Gemini image model, driven by Claude | Only one with reference-image fidelity |

Antigravity does not write. That is not a limitation to work around — it is the
safer split. Only one tool writes code unattended, and it does so inside a
throwaway git worktree.

---

## Choosing the right one

| Situation | Use | Reason |
|---|---|---|
| Design a new mechanism | Claude | Needs all the rules held at once |
| 30 similar files to create | Codex | Dull bulk work, parallelisable, cheap |
| Security-sensitive code | Claude **+ Codex counter-review** | Two models, two failure modes |
| "Where in the repo does X happen?" | Antigravity | Reads a lot of context in one go |
| Translate a large doc set | Codex, then Claude accepts | Bulk work behind a quality gate |
| Balancing numbers, simulation | Claude | Must actually understand the rules |
| An architecture decision you are unsure about | `trio council` | Both models, opposing views, cheap |

---

## The task spec protocol

No agent ever gets a vague instruction. Every delegation is a file under
`.ai/tasks/T-<n>-<name>.md`:

```markdown
---
id: T-042
agent: codex
branch: ai/T-042
---

## Goal
One sentence. What must be true afterwards?

## Permitted files
- src/games/raid/phases/*.ts
NOTHING ELSE. Changes outside this list are discarded.

## Contracts (not negotiable)
Paste the relevant interfaces. The agent implements AGAINST these types
and may not change them.

## Acceptance
- [ ] npm test green
- [ ] npm run typecheck clean

## Forbidden
- Adding dependencies
- Changing existing tests
- Touching files outside the list
```

**The permitted-files line is the most important line in the spec.** An agent
without boundaries tries to be helpful and rebuilds things nobody asked about.

---

## Isolation

Every delegated task runs in its own working directory:

```bash
node ~/.claude/brain/trio/trio.mjs task run T-042
```

This creates a git worktree on its own branch. Three agents can run at once
without seeing each other, and none can damage `main`. Rejecting a task is
`task drop` — no cleanup, no half-finished state in the main tree.

---

## The acceptance gate

Results are never taken on trust. Always in this order:

```
1. Typecheck   -> fails: straight back, unread
2. Tests       -> fails: straight back, unread
3. File limits -> touched files outside the list? discarded
4. Claude reads the diff   <- only now is reading worth the context
5. Counter-review (security-sensitive code only)
6. Merge
```

Steps 1–3 are automatic and cost no attention. That is the point: **machines
check first, expensive models last.**

The scarcest resource here is not the model — it is Claude's context. Every line
Claude reads is context unavailable later for architecture decisions.

---

## Permissions

Claude is the approving authority. Codex and Antigravity have no blanket rights.

- Every Antigravity tool call passes through `~/.claude/brain/trio/broker.mjs`
- The policy lives in `.agents/policy.json` (project) or
  `~/.claude/brain/trio/policy.json` (global)
- A `deny` from the broker overrides any permission the tool grants itself
- Unknown commands are denied with an explanation, never waved through

`--dangerously-skip-permissions` is never used. If an agent needs something the
policy forbids, it says so in its report and Claude decides.

See `/brain-permission-broker` for the details.

---

## Costs

Both CLIs bill through their subscription, not per token — no API key, no
per-call charge. The real cost risks are elsewhere:

- **Agents starting agents.** Blocked by policy. Without it, an unattended loop
  runs until something breaks.
- **Network calls.** Blocked by policy. Prevents an agent reaching a paid API.
- **Runaway loops.** Cap the iterations per task. Two models fixing each other's
  changes can run forever.

---

## When to propose this setup

Suggest the trio when you notice:

- A task spans more than roughly 10 files
- Genuinely independent workstreams exist
- The project has a real test suite (the gate only works with one)
- A decision is hard enough that an opposing view is worth the wait
- Bulk mechanical work is coming (translations, migrations, boilerplate)

Advise **against** it when:

- The project has fewer than ~20 files
- There are no tests (the acceptance gate has nothing to check)
- The work is exploratory and the target keeps moving
- The user is alone on a small task

Say so plainly. Recommending overhead that does not pay off is worse than not
mentioning the option.
