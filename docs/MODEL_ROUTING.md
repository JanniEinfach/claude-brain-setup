# Model Routing

## How Model Selection Actually Works

Claude Code does not automatically switch models during a session. The model is fixed when you launch the CLI. You pick it. This document helps you pick correctly.

## The Claude 5 Model Family

| Model | ID | Role |
|-------|----|------|
| Haiku 4.5 | `claude-haiku-4-5-20251001` | Fast and cheap — simple, bounded tasks |
| Sonnet 5 | `claude-sonnet-5` | The standard workhorse — most development work |
| Opus 4.8 | `claude-opus-4-8` | Heavyweight — architecture, security, complex multi-file work; has a Fast Mode for lower-latency responses |
| Fable 5 | `claude-fable-5` | Flagship of the new Mythos model class — the hardest reasoning and coordination work. Access depends on your subscription plan |

```bash
claude --model claude-haiku-4-5-20251001   # Fast, cheap
claude --model claude-sonnet-5             # Good default
claude --model claude-opus-4-8             # Heavyweight
claude --model claude-fable-5              # Flagship (if your plan includes it)
```

You can also set a default in `settings.json` (see `settings.example.json` in the project root). To see which model a running session uses, type `/model` inside Claude Code.

## Decision Tree

```
Is it a single-file edit, formatting, renaming,
a config tweak, or a simple question?
├── yes → Haiku 4.5
└── no
    Does it involve architecture decisions, security-sensitive
    code, or many tightly coupled files?
    ├── no  → Sonnet 5
    └── yes
        Is it the hardest kind of work you have — system design,
        deep multi-agent orchestration, high-stakes refactors —
        AND does your plan include Fable?
        ├── yes → Fable 5
        └── no  → Opus 4.8
```

## Decision Table

| Task type | Recommended model | Why |
|-----------|-------------------|-----|
| Fix a bug in one file | Haiku 4.5 | Single file, bounded scope |
| Explain a function | Haiku 4.5 | Read-only, no reasoning chain needed |
| Write a unit test for existing code | Haiku 4.5 | Straightforward generation |
| Update config or docs | Haiku 4.5 | Simple output, no synthesis |
| Implement a new feature (2–5 files) | Sonnet 5 | Multi-file, needs coherence |
| Debug a complex failure | Sonnet 5 | Requires context across files |
| Code review across a PR | Sonnet 5 | Multi-file analysis |
| Design a system architecture | Opus 4.8 | Needs deep reasoning |
| Security audit of auth or payment code | Opus 4.8 | High stakes, needs thoroughness |
| Large cross-module refactor | Opus 4.8 | High coupling risk |
| Orchestrate multiple agents on a complex build | Fable 5 (or Opus 4.8) | Complex coordination benefits from the strongest model available |
| Hardest reasoning problems, novel system design | Fable 5 | Flagship capability, if your plan includes it |

## Cost Relationship

Exact prices change; the ordering does not: Haiku is the cheapest by a wide margin, Sonnet costs several times more per token, and Opus and Fable are premium models on top of that. Starting with the right model is the single biggest lever for cost control. If you run Opus or Fable, consider delegating mechanical bulk work (mass renames, formatting, boilerplate) to cheaper agent models such as Haiku.

## When the Task Grows Mid-Session

If you started with Haiku and the task turns out larger than expected:

1. Type `/brain-session-handoff` — Claude writes a structured summary of what was done and what remains.
2. End the session.
3. Start a new session with Sonnet 5 or Opus 4.8 and paste the handoff summary.

There is no way to escalate inside a running session. Trying to push through a complex task on Haiku produces poor results and wastes tokens on failed attempts.

## Haiku Limitations

Do not use Haiku for:

- Tasks that require understanding relationships across 3 or more files
- Architecture or design decisions
- Security analysis
- Orchestrating agents
- Research that requires nuanced synthesis

## Notes on Opus 4.8 and Fable 5

- **Opus 4.8 Fast Mode:** Opus 4.8 offers a Fast Mode for lower-latency responses. This makes Opus more usable for mixed sessions where only some turns need deep reasoning.
- **Fable 5 availability:** Fable 5 is the flagship of the new Mythos class. Whether you can select it depends on your subscription plan. If `claude --model claude-fable-5` is rejected or `/model` does not list it, your plan does not include it — Opus 4.8 is the strongest alternative.

## Setting a Default Model

In `~/.claude/settings.json`:

```json
{
  "model": "claude-sonnet-5"
}
```

This makes Sonnet 5 the default so you only need the `--model` flag when deviating.

## Practical Shell Aliases

Add to your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
alias cc='claude --model claude-sonnet-5'
alias cch='claude --model claude-haiku-4-5-20251001'
alias cco='claude --model claude-opus-4-8'
alias ccf='claude --model claude-fable-5'
```

Then:

```bash
cc    # Standard development
cch   # Quick edits and formatting
cco   # Architecture, security, complex multi-file work
ccf   # Flagship (plan-dependent)
```

## Escalation via Handoff

When you need a stronger model mid-task:

```
# Inside the current session:
/brain-session-handoff

# Claude writes a summary. Copy it.
# Exit the session.
# Start a new session with the right model:
cco

# Paste the handoff summary.
# Continue where you left off.
```

This is the correct escalation path. There is no shortcut inside a session.
