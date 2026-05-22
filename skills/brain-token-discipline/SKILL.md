# brain-token-discipline

## Purpose

Practical habits that reduce token consumption without reducing quality. Useful as a session-start reminder or when a session feels like it is growing too large.

## When to Use

At the start of any long development session. When you notice the session is getting large. When you are about to load several skills at once.

## When Not to Use

Short sessions under 10 minutes with a single well-scoped task. You do not need to think about tokens for a two-message interaction.

## Workflow

**Search before reading**
Use grep, find, or a structural search tool to locate the relevant code before opening files. Do not read a 500-line file to find a 10-line function.

```bash
grep -r "functionName" src/ --include="*.ts" -l
```

**Read only what you need**
If you need lines 40–80 of a file, say so. Read by section, not by full file. Batch independent reads in one message so they execute in parallel.

**Summarize output, do not paste it**
When a command produces long output, summarize the key finding in one or two sentences. Pasting raw output in full fills context with noise.

**Load skills on demand only**
Load a skill only when you are about to use it. Do not preload skills speculatively. One skill at a time, when needed.

**Keep CLAUDE.md under 150 lines**
A longer CLAUDE.md costs tokens on every message. Move details to docs/ files and reference them.

**Use handoff before sessions grow too large**
When the session feels large, run `/create_handoff` to write a structured summary, then start a new session. A fresh session is almost always cheaper than extending a large one.

**Do not resume huge sessions**
Resuming a very large session costs as much as the original session in cache miss scenarios. Prefer starting fresh with a handoff document.

**Batch independent operations**
If you need to read five unrelated files, read them all in one message. If you need to run three independent grep searches, chain them in one bash call.

## Checklist

- [ ] Used grep/find before opening files
- [ ] Read only relevant sections, not entire files
- [ ] Summarized command output instead of pasting it raw
- [ ] Loaded only skills actually needed
- [ ] CLAUDE.md is under 150 lines
- [ ] Session is not resume-able (handoff created if it was large)

## Token Discipline

This skill itself is low cost. Reading it once at the start of a session is worthwhile if the session is going to be long. It costs roughly 60–80 tokens to load.

## Verification

To check if your session habits are working, ask: "Could I have done this with fewer file reads?" If the answer is often yes, revisit the search-before-reading habit.

## Public Safety Notes

This skill contains no private data, no machine-specific paths, and no credentials. It is safe to include in a public repository.
