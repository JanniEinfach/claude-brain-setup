# Claude Brain — Development System

You are Claude Code on a development machine. Work efficiently. See `docs/PRINCIPLES.md` for engineering principles.

## Core Behaviour

- Do only what was asked. No extras, no unsolicited refactoring.
- Read files before editing them.
- Prefer editing existing files over creating new ones.
- Keep files under 500 lines. Hard limit: 800 lines. Split when necessary.
- Never hardcode secrets. Use env vars.
- Never commit `.env` or credentials.
- Never use `--no-verify` or bypass git hooks.
- Summarise command output briefly instead of pasting it raw.

## Model Discipline

**Claude cannot switch models mid-session.** The model is fixed at launch.

```bash
claude --model claude-haiku-4-5-20251001   # Simple edits, formatting, renaming
claude --model claude-sonnet-4-6            # Standard development (good default)
claude --model claude-opus-4-7              # Architecture, security, complex multi-file work
```

If a task outgrows the current session, use `/create_handoff`, end the session, and start a new one with the right model.

See `docs/MODEL_ROUTING.md` for the full decision guide.

## When to Plan Before Coding

Always plan first when the task:
- Touches 3 or more files
- Changes a public API or database schema
- Involves auth, payments, or user data
- Has unclear scope

Type `/plan-agent` to run the planning skill. Wait for your own confirmation before writing code.

No plan needed for: single-file edits, 1–2 line fixes, config tweaks, doc updates.

## Skills

Skills live in `~/.claude/skills/`. Load one with `/skill-name` inside a Claude Code session when needed.

Only load a skill when you actually need it. Loading skills speculatively wastes tokens.

Core skills:
- `/debug` — systematic bug investigation
- `/tdd` — test-first workflow
- `/review` — code quality review
- `/security` — security audit checklist
- `/refactor` — safe refactoring steps
- `/plan-agent` — structured planning before implementation
- `/research` — check what exists before writing new code
- `/commit` — commit message and pre-commit checklist
- `/dead-code` — find unused code before deleting
- `/ast-grep-find` — structural search across a codebase
- `/create_handoff` — save session context before ending

Full list with token costs: `docs/SKILLS.md`

## Code Quality Gates

Before marking any task done:
- [ ] No hardcoded values (use constants or config)
- [ ] Errors handled explicitly — never silently swallowed
- [ ] New functionality has tests
- [ ] No `console.log` or debug prints left in production paths
- [ ] Functions under 50 lines
- [ ] No nesting deeper than 4 levels — use early returns
- [ ] Security-sensitive changes reviewed with `/security`

## Session Discipline

- Do not resume a session that has grown very large. Create a handoff and start fresh.
- Search before reading full files.
- Issue multiple independent reads in one message, not sequentially.
- At the end of complex sessions, run `/create_handoff` so the next session can continue cleanly.

## Orchestration

Use agents when work is genuinely parallel or needs specialization. Do not spawn agents for single-file edits, quick questions, or config changes.

Agents: `planner`, `architect`, `code-reviewer`, `security-reviewer`, `tdd-guide`, `scout`, `oracle`, `spark`, `debug-agent`, `build-error-resolver`.

Rule: if you can finish the task alone in under 15 minutes, skip the agents.

See `docs/RUFLO_ORCHESTRATION.md`.

## Token Efficiency

Short version:
- Search before reading.
- Summarize instead of pasting.
- Start a new session rather than resuming a huge one.
- Keep context focused on the current task.

See `docs/TOKEN_EFFICIENCY.md` for the full guide.
