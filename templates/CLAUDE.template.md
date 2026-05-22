# Claude Brain — {{USER_NAME}}'s Development System

You are Claude Code on {{USER_NAME}}'s development machine. Work efficiently and in {{PRIMARY_LANGUAGE}}.

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

{{DEFAULT_MODEL}}

If a task outgrows the current session, use `/create_handoff`, end the session, and start a new one with the right model.

See `docs/MODEL_ROUTING.md` for the full decision guide.

## When to Plan Before Coding

{{PLANNING_PREFERENCE}}

Type `/plan-agent` to run the planning skill. Wait for your own confirmation before writing code.

## Work Context

**Primary work type:** {{MAIN_WORK_TYPE}}
**Primary stacks:** {{PREFERRED_STACKS}}

## Code Style

{{CODE_STYLE}}

## Testing

{{TESTING_PREFERENCE}}

## Skills

Skills live in `~/.claude/skills/`. Load one with `/skill-name` inside a Claude Code session when needed.

Only load a skill when you actually need it. Loading skills speculatively wastes tokens.

Core skills for {{USER_NAME}}'s workflow:
{{SELECTED_SKILLS}}

Full list with token costs: `docs/SKILLS.md`

## Code Quality Gates

Before marking any task done:
- [ ] No hardcoded values (use constants or config)
- [ ] Errors handled explicitly — never silently swallowed
- [ ] New functionality has tests
- [ ] No `console.log` or debug prints in production paths
- [ ] Functions under 50 lines
- [ ] No nesting deeper than 4 levels — use early returns
{{SECURITY_GATE}}

## Security

**Security level: {{SECURITY_LEVEL}}**

{{SECURITY_RULES}}

## Session Discipline

- Do not resume a session that has grown very large. Create a handoff and start fresh.
- Search before reading full files.
- Issue multiple independent reads in one message, not sequentially.
- At the end of complex sessions, run `/create_handoff`.

## Token Strategy

**Strategy: {{TOKEN_STRATEGY}}**

{{TOKEN_RULES}}

See `docs/TOKEN_EFFICIENCY.md` for the full guide.

## Orchestration

**Level: {{AGENT_ORCHESTRATION}}**

{{ORCHESTRATION_RULES}}

See `docs/RUFLO_ORCHESTRATION.md`.

{{MARKETING_SUPPORT}}

{{FIVEM_SUPPORT}}
