# Token Efficiency

Practical rules to keep token costs under control. No magic — just habits.

## The Biggest Wins

### 1. Pick the right model before starting

Using Opus or Opus (1M context) when Sonnet would do costs several times more per token. Using Sonnet when Haiku would do wastes money too. See `MODEL_ROUTING.md` for the Claude 5 family decision table.

```bash
claude --model haiku   # Simple, bounded tasks
claude --model sonnet             # Standard development
claude --model opus             # Architecture, security, complex work
```

### 2. Do not resume huge sessions

Resuming a session with a large conversation history costs tokens on every message because the full history is re-read. When a session has grown large:

- Use `/brain-session-handoff` inside the session to generate a context summary.
- End the session.
- Start fresh, paste the handoff summary.

A fresh session with a 500-token handoff is far cheaper than continuing a 50,000-token conversation.

### 3. Search before reading

Do not read an entire file to find one function.

```bash
# Find where a function is defined
grep -n "function_name" src/module.py
rg "function_name" src/

# Then read only the relevant section
```

### 4. Summarise output, do not paste it

When you run a command with long output, do not paste 200 lines into the conversation. Summarise in 3–5 bullet points. If you need Claude to analyse raw output, use `head` or `tail` to limit it first.

```bash
some_command | head -30
some_command | tail -20
some_command | wc -l   # Just the count, when you only need the count
```

### 5. Batch independent operations

Multiple independent file reads or writes should happen in one message, not sequentially. Claude can issue parallel tool calls.

Bad pattern:
```
Read file A → wait → Read file B → wait → Read file C
```

Good pattern:
```
Read file A, Read file B, Read file C — one message, parallel
```

### 6. Use targeted structure analysis before reading

Before reading a file you have not seen before, get its structure:

```bash
grep -n "^def \|^class " src/module.py    # Python functions and classes
grep -n "^function \|^const \|^export " src/module.ts   # JS/TS exports
find . -name "*.py" | head -20             # File list without reading
```

This gives you function names, classes, and imports at a fraction of the cost.

### 7. Compact only at natural breakpoints

`/compact` summarises the current conversation. Use it when:

- You have completed a major sub-task.
- You are about to start a different phase of work.

Do not use `/compact` reflexively. It costs tokens to summarise and loses detail. A clean session start is usually better.

### 8. Audit your hooks

Hooks that run on every tool call add overhead. Only enable hooks you actually use every day. Periodically check `settings.json` and remove hooks that are not earning their cost.

(The Brain update-check hook runs only once at session start, finishes in well under six seconds, and stays silent unless an update exists — its overhead is negligible. You can still disable it; see `docs/UPDATE.md`.)

### 9. Keep context focused

Do not paste long reference docs into the conversation unless you are actively using them. A 500-line API reference pasted once stays in context for every subsequent message even when you stop referring to it.

### 10. End sessions at natural breakpoints

A session for "fix the auth bug" should end when the bug is fixed — not drift into "also let me refactor the user module". Start a new session for the next task.

## Warnings

**Large CLAUDE.md files:** A very long CLAUDE.md is re-read on every message. Keep it under 150 lines. Move detailed reference material to `docs/` files instead.

**Preloaded skills:** Loading multiple skills speculatively at session start is expensive. Load one skill at a time, when you actually need it.

**Long conversation histories:** The cost of a session grows with its length. After completing a major chunk of work, consider starting fresh.

**Cache reads:** Claude Code uses prompt caching. Cache reads are cheaper than input tokens but still cost something at scale. Large system prompts generate significant cache read costs over many sessions.

## Quick Reference

| Habit | Token impact |
|-------|-------------|
| Right model from the start | High |
| Fresh session instead of resuming | High |
| Search before reading | Medium |
| Batch parallel reads | Medium |
| Summarise command output | Medium |
| Targeted structure analysis | Medium |
| Compact at natural breakpoints | Low |
| Focused context, no pastes | Low |

## Common Tools for Token-Efficient Search

```bash
grep -n "pattern" file.py           # Line numbers, single file
grep -rn "pattern" src/             # Recursive
rg "pattern" src/                   # ripgrep, faster
rg -l "pattern" src/                # Only filenames
find . -name "*.py" -newer file.py  # Find by modification time
head -50 file.py                    # First 50 lines only
tail -30 file.py                    # Last 30 lines only
sed -n '40,80p' file.py             # Lines 40-80 only
wc -l file.py                       # Line count only
find src/ -name "*.ts" | sort       # File tree by extension
grep -n "^def \|^class " file.py    # Code structure without full read
```
