# Ruflo Orchestration

A lightweight orchestration approach for multi-agent work in Claude Code. Under 100 lines.

## The Core Pattern

```
1. Planner      — defines what needs to happen and in what order
2. Implementers — do the actual work (parallel if tasks are independent)
3. Reviewer     — checks the output
4. Verifier     — confirms the task is actually done
```

Do not add orchestration because it looks organised. The overhead is real.

## When Orchestration Saves Time

Use agents when:
- Two or more tasks are genuinely independent and can run in parallel
- A task requires a specialised role (security audit, architecture review)
- The work is too large for one context window
- You need diverse perspectives on a decision

## When Orchestration Wastes Tokens

Do not spawn agents for:
- A single-file edit
- A quick bug fix or simple question
- Config changes or doc updates
- Any task you could finish alone in 10–15 minutes

Every agent spawn has overhead: context passing, coordination messages, result synthesis.

## Practical Workflow

**Step 1 — Decide if you need orchestration at all.**
Ask: "Can I finish this in one focused session without agents?" If yes, skip orchestration.

**Step 2 — Planner first.**
If the task is complex, run `planner` before anything else. Get a written plan. Confirm it before spawning implementers.

**Step 3 — Spawn parallel agents only for independent tasks.**
If task B needs task A's output, run them sequentially. Only go parallel when tasks truly do not depend on each other.

**Step 4 — Review and verify.**
After implementation: run `code-reviewer`. For code touching auth, payments, or user data, run `security-reviewer`. These are not optional for production code.

## Available Agents

Planning: `planner`, `architect`
Implementation: `kraken`, `spark`, `sparc-coder`
Review: `code-reviewer`, `security-reviewer`, `tdd-guide`
Research: `scout`, `oracle`, `debug-agent`, `sleuth`
Utilities: `build-error-resolver`, `refactor-cleaner`

## The 15-Minute Rule

If you estimate the task will take less than 15 minutes to complete alone, skip agents. The orchestration overhead is not worth it.

## Anti-Patterns

- Spawning an agent to read a single file — just read it yourself
- Using the `Explore` task type instead of `scout` — Explore uses Haiku and produces poor results
- Orchestrating agents for a clearly sequential task
- Running `code-reviewer` before the code is written
- Spawning `security-reviewer` on a config change or doc update
