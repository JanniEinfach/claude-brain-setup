# brain-model-routing

## Purpose

A decision guide for choosing the right Claude model before starting a session. Includes shell alias recommendations and an escalation path when the current model is not enough.

## When to Use

Before starting a Claude Code session. When planning a task and choosing how to launch.

## When Not to Use

Mid-session. Claude cannot switch models once a session has started. The model is fixed at launch.

## Workflow

**Understand the constraint first**

Claude cannot change models mid-session. Choosing the wrong model means either accepting lower quality or ending the session and starting a new one. Choose deliberately before launching.

**Model selection guide**

| Model | Flag | Use when |
|-------|------|----------|
| Haiku | `--model claude-haiku-4-5-20251001` | Formatting, renaming, single-file trivial edits, simple config changes |
| Sonnet | `--model claude-sonnet-4-6` | Standard development, multi-file features, debugging, most tasks |
| Opus | `--model claude-opus-4-7` | Architecture decisions, security audits, complex multi-file work, when Sonnet is struggling |

**Cost relationship**

Haiku is cheapest. Sonnet costs roughly 5x Haiku. Opus costs roughly 15x Haiku. Use the cheapest model that can reliably do the job.

**When in doubt, start with Sonnet.** It handles the majority of real development work well.

**Shell aliases (add to ~/.bashrc or ~/.zshrc)**

```bash
alias cc='claude --model claude-sonnet-4-6'
alias cch='claude --model claude-haiku-4-5-20251001'
alias cco='claude --model claude-opus-4-7'
```

**Escalation path when the session model is not enough**

1. Recognize the task needs a stronger model.
2. Run `/brain-session-handoff` (or `/create_handoff`) to write a structured summary.
3. End the current session.
4. Start a new session with the appropriate model, passing in the handoff.

Do not try to muscle through a complex task with an underpowered model. Escalation is cheaper than rework.

**Decision questions**

- Is this a one-file formatting or rename task? → Haiku
- Is this standard development work with clear scope? → Sonnet
- Does this involve system architecture, security analysis, or is Sonnet giving inconsistent results? → Opus

## Checklist

- [ ] Chose the model before launching the session
- [ ] Considered the task complexity against model capability
- [ ] Set up shell aliases for faster launching
- [ ] Know the escalation path if the task outgrows the current session

## Token Discipline

This skill is a reference card. Load it once when planning a session, not on every session. Cost: roughly 60 tokens.

## Verification

After reading this skill, you should be able to answer: "Which model should I use for this task and why?" If the answer is clear, the skill has done its job.

## Public Safety Notes

This skill contains no private data, no machine-specific paths, and no credentials. It is safe to include in a public repository.
