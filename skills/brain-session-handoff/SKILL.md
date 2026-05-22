# brain-session-handoff

## Purpose

Creates a structured handoff document before ending a large session, switching to a stronger model, or pausing work that will continue later.

## When to Use

When the session has grown large and continuing would be expensive. When you are about to end a session but the task is not complete. When you need to switch to a stronger model for the next phase. When work will resume tomorrow or in another session.

## When Not to Use

Short sessions under 10 minutes with one simple task that is fully complete. No handoff needed if the task is done and the session ends cleanly.

## Workflow

Write the following handoff document and present it to the user. Save it to a file if the user wants persistence.

```
## Session Handoff

**Goal:** [one sentence describing what was being worked on]

**Status:** [one of: done / in-progress / blocked]

**Files changed:**
- path/to/file.ts — [one-line description of what changed]
- path/to/other.py — [one-line description of what changed]

**Commands run:**
- [list any important commands that were executed and their outcomes]

**Tests and verification:**
- [what was tested, what passed, what was not tested yet]

**Next steps:**
1. [first thing to do in the next session]
2. [second thing]
3. [continue as needed]

**Blockers:**
- [anything waiting on a decision, external input, or that is currently failing]
- (none if no blockers)

**Model recommendation for next session:**
- Haiku — if the remaining work is simple formatting or config
- Sonnet — if the remaining work is standard development
- Opus — if the remaining work involves architecture decisions, security review, or the current model has been struggling

**Context note:**
[one paragraph describing the state of the codebase as it stands, so the next session does not have to re-read everything]
```

**How to continue in a new session**

Start the new session with the right model:
```bash
claude --model claude-sonnet-4-6
```

Then paste the handoff document into the first message of the new session and ask Claude to continue from where it left off.

## Checklist

- [ ] Goal stated clearly in one sentence
- [ ] All changed files listed with descriptions
- [ ] Next steps are numbered and concrete
- [ ] Blockers identified (or confirmed none)
- [ ] Model recommendation included
- [ ] Context note written for cold-start reading

## Token Discipline

Creating a handoff document costs 50–150 tokens. Starting a new session from a handoff is almost always cheaper than extending a very large session. This is the correct trade.

## Verification

After writing a handoff, ask: "Could someone start a new session from this document and know exactly what to do next?" If yes, the handoff is complete.

## Public Safety Notes

This skill contains no private data, no machine-specific paths, and no credentials. It is safe to include in a public repository. Handoff documents written during sessions may contain project-specific information — do not commit handoff files to public repositories without reviewing them for private content.
