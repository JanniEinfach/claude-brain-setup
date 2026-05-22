# Dream Cycle

The `dream` skill (`~/.claude/skills/dream/`) consolidates learnings from a session into persistent memory.

## What It Actually Does

Running `/dream` inside a Claude Code session causes Claude to:
1. Review the current session for decisions, corrections, patterns, and preferences
2. Write findings to `~/.claude/projects/-root/memory/` as structured memory files

It does not automatically update `CLAUDE.md`. Any updates to `CLAUDE.md` are manual and deliberate.

## When to Use It

Run `/dream` at the end of a session where:
- You discovered a non-obvious pattern or solution
- You made an architectural decision worth recording
- Something failed and you want to avoid repeating it
- The user stated a preference you want to persist

Do not run it after every session. It costs tokens and produces low-signal output for routine sessions.

## Pairing With Recall

At the start of a new session on a related topic, run `/recall` to surface relevant past learnings before starting work. This prevents re-solving problems you already solved.

## What It Is Not

- Not a self-learning AI that improves automatically
- Not a system that edits `CLAUDE.md` without your review
- Not required for normal development work

## Practical Use

```
# End of a complex session
/dream

# Start of a new session on a related topic
/recall

# Store a specific learning immediately (without full dream)
/remember
```
