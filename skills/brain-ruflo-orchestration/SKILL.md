# brain-ruflo-orchestration

## Purpose

Lightweight multi-agent orchestration guidance. Helps decide when agents are worth their overhead and provides a basic coordination pattern.

## When to Use

When planning a complex multi-file or multi-specialist task. When deciding whether to use agents or work solo. When spawning multiple agents and need to coordinate them without context bloat.

## When Not to Use

Any task you can finish alone in under 15 minutes. Single-file edits. Quick config changes. Short Q&A. Tasks where explaining the work to agents takes longer than doing it.

## Workflow

**Decision: agents or solo?**

Agents help when:
- Work is genuinely parallel and independent (two components with no shared state)
- Task needs specialization that one session cannot do well (security + implementation simultaneously)
- Multiple files can be edited simultaneously without merge conflicts
- Research and implementation can run in parallel

Agents waste tokens when:
- The task is a single file edit
- The agents need to constantly share results (high coordination overhead)
- The task takes under 15 minutes solo
- The "parallel" work is actually sequential (B depends on A)

Rule of thumb: if you spend more time writing agent instructions than the agent saves, skip the agents.

**Basic orchestration pattern**

```
planner → [implementers in parallel if independent] → reviewer → verifier
```

1. `planner` defines scope, breaks work into bounded units
2. `implementers` work in parallel only if their outputs are independent
3. `code-reviewer` reviews combined output
4. `security-reviewer` reviews if auth, payments, or user data is involved

**File-based coordination**

Agents share state via files, not return values. This avoids context bloat.

- Each agent writes its output to a named file (`plan.md`, `impl-notes.md`, etc.)
- The next agent reads that file at start
- The orchestrator (you) reads the final output files

**Boundaries matter**

Every agent must have a clear, non-overlapping scope. Vague boundaries cause agents to redo each other's work or leave gaps.

Good boundary: "Agent A owns authentication module. Agent B owns payment module. Neither touches the other."
Bad boundary: "Agent A handles the backend. Agent B handles whatever is left."

**Available agents**

`planner`, `architect`, `code-reviewer`, `security-reviewer`, `tdd-guide`, `scout`, `oracle`, `spark`, `debug-agent`, `build-error-resolver`

See `docs/RUFLO_ORCHESTRATION.md` for the full guide.

## Checklist

- [ ] Confirmed the task actually benefits from parallel work
- [ ] Defined clear, non-overlapping boundaries for each agent
- [ ] Agents share state via files, not return values
- [ ] `security-reviewer` included if auth, payments, or user data is touched
- [ ] Estimated coordination cost vs. time saved — agents are worth it

## Token Discipline

Multi-agent work is inherently more expensive than solo work. Use agents only when the total cost (including coordination) is lower than the cost of doing it solo poorly or with rework. This skill costs roughly 70 tokens to load.

## Verification

After a multi-agent task, ask: "Did the agents save time or add overhead?" Track the answer. Adjust your threshold for when to use agents accordingly.

## Public Safety Notes

This skill contains no private data, no machine-specific paths, and no credentials. It is safe to include in a public repository.
