# Model Routing

## How Model Selection Actually Works

Claude Code does not automatically switch models during a session. The model is fixed when you launch the CLI. You pick it. This document helps you pick correctly.

## The Claude 5 Model Family

| Model | ID | Role |
|-------|----|------|
| Haiku | `haiku` | Fast and cheap — simple, bounded tasks |
| Sonnet | `sonnet` | The standard workhorse — most development work |
| Opus | `opus` | Heavyweight — architecture, security, complex multi-file work; has a Fast Mode for lower-latency responses |
| Opus (1M context) | `opus[1m]` | Flagship of the new Mythos model class — the hardest reasoning and coordination work. Access depends on your subscription plan |

```bash
claude --model haiku   # Fast, cheap
claude --model sonnet             # Good default
claude --model opus             # Heavyweight
claude --model opus[1m]              # Flagship (if your plan includes it)
```

You can also set a default in `settings.json` (see `settings.example.json` in the project root). To see which model a running session uses, type `/model` inside Claude Code.

## Decision Tree

```
Is it a single-file edit, formatting, renaming,
a config tweak, or a simple question?
├── yes → Haiku
└── no
    Does it involve architecture decisions, security-sensitive
    code, or many tightly coupled files?
    ├── no  → Sonnet
    └── yes
        Is it the hardest kind of work you have — system design,
        deep multi-agent orchestration, high-stakes refactors —
        AND does your plan include Fable?
        ├── yes → Opus (1M context)
        └── no  → Opus
```

## Decision Table

| Task type | Recommended model | Why |
|-----------|-------------------|-----|
| Fix a bug in one file | Haiku | Single file, bounded scope |
| Explain a function | Haiku | Read-only, no reasoning chain needed |
| Write a unit test for existing code | Haiku | Straightforward generation |
| Update config or docs | Haiku | Simple output, no synthesis |
| Implement a new feature (2–5 files) | Sonnet | Multi-file, needs coherence |
| Debug a complex failure | Sonnet | Requires context across files |
| Code review across a PR | Sonnet | Multi-file analysis |
| Design a system architecture | Opus | Needs deep reasoning |
| Security audit of auth or payment code | Opus | High stakes, needs thoroughness |
| Large cross-module refactor | Opus | High coupling risk |
| Orchestrate multiple agents on a complex build | Opus (1M context) (or Opus) | Complex coordination benefits from the strongest model available |
| Hardest reasoning problems, novel system design | Opus (1M context) | Flagship capability, if your plan includes it |

## Cost Relationship

Exact prices change; the ordering does not: Haiku is the cheapest by a wide margin, Sonnet costs several times more per token, and Opus and Fable are premium models on top of that. Starting with the right model is the single biggest lever for cost control. If you run Opus or Fable, consider delegating mechanical bulk work (mass renames, formatting, boilerplate) to cheaper agent models such as Haiku.

## When the Task Grows Mid-Session

If you started with Haiku and the task turns out larger than expected:

1. Type `/brain-session-handoff` — Claude writes a structured summary of what was done and what remains.
2. End the session.
3. Start a new session with Sonnet or Opus and paste the handoff summary.

There is no way to escalate inside a running session. Trying to push through a complex task on Haiku produces poor results and wastes tokens on failed attempts.

## Haiku Limitations

Do not use Haiku for:

- Tasks that require understanding relationships across 3 or more files
- Architecture or design decisions
- Security analysis
- Orchestrating agents
- Research that requires nuanced synthesis

## Notes on Opus and Opus (1M context)

- **Opus Fast Mode:** Opus offers a Fast Mode for lower-latency responses. This makes Opus more usable for mixed sessions where only some turns need deep reasoning.
- **Opus (1M context) availability:** Opus (1M context) is the flagship of the new Mythos class. Whether you can select it depends on your subscription plan. If `claude --model opus[1m]` is rejected or `/model` does not list it, your plan does not include it — Opus is the strongest alternative.

## Setting a Default Model

In `~/.claude/settings.json`:

```json
{
  "model": "sonnet"
}
```

This makes Sonnet the default so you only need the `--model` flag when deviating.

## Practical Shell Aliases

Add to your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
alias cc='claude --model sonnet'
alias cch='claude --model haiku'
alias cco='claude --model opus'
alias ccf='claude --model opus[1m]'
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
