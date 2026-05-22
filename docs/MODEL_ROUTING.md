# Model Routing

## How Model Selection Actually Works

Claude Code does not automatically switch models during a session. The model is fixed when you launch the CLI. You pick it. This document helps you pick correctly.

```bash
claude --model claude-haiku-4-5-20251001   # Fast, cheap
claude --model claude-sonnet-4-6            # Good default
claude --model claude-opus-4-7              # Heavyweight
```

You can also set a default in `settings.json` (see `settings.example.json` in the project root).

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
| Orchestrate multiple agents | Opus | Complex coordination |
| Large cross-module refactor | Opus | High coupling risk |

## Real Cost Relationship (approximate)

- Haiku: baseline cost
- Sonnet: roughly 5× Haiku input cost
- Opus: roughly 15× Haiku input cost

Starting with the right model is the single biggest lever for cost control.

## When the Task Grows Mid-Session

If you started with Haiku and the task is larger than expected:

1. Type `/create_handoff` — Claude writes a summary of what was done and what remains.
2. End the session.
3. Start a new session with Sonnet or Opus, pasting the handoff summary.

There is no way to escalate inside a running session. Trying to push through a complex task on Haiku produces poor results and wastes tokens on failed attempts.

## Haiku Limitations

Do not use Haiku for:
- Tasks that require understanding relationships across 3 or more files
- Architecture or design decisions
- Security analysis
- Orchestrating agents
- Research that requires nuanced synthesis

## Setting a Default Model

In `~/.claude/settings.json`:

```json
{
  "model": "claude-sonnet-4-6"
}
```

This makes Sonnet the default so you only need the `--model` flag when deviating.

## Practical Shell Aliases

Add to your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
alias cc='claude --model claude-sonnet-4-6'
alias cch='claude --model claude-haiku-4-5-20251001'
alias cco='claude --model claude-opus-4-7'
```

Then:

```bash
cc    # Standard development
cch   # Quick edits and formatting
cco   # Architecture, security, complex multi-file work
```

## Escalation via Handoff

When you need a stronger model mid-task:

```
# Inside current session:
/create_handoff

# Claude writes a summary. Copy it.
# Exit the session.
# Start a new session with the right model:
cco

# Paste the handoff summary.
# Continue where you left off.
```

This is the correct escalation path. There is no shortcut inside a session.
