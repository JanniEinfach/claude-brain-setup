# brain-core-workflow

## Purpose

A six-step disciplined development workflow for non-trivial tasks. Keeps Claude Code focused, predictable, and easy to review.

## When to Use

At the start of any task that touches more than one file, involves a public API, includes auth or user data, or has unclear scope. Not needed for single-line fixes or pure documentation edits.

## When Not to Use

Single-line fixes. Renaming one variable. Docs-only changes. Config tweaks that are self-evident.

## Workflow

**Step 1 — Understand**
Read the request carefully. State your understanding in one or two sentences before doing anything. Surface assumptions explicitly. If something is ambiguous, ask one focused question now rather than after you have written code.

**Step 2 — Inspect**
Read the relevant files before touching them. Use grep or find to locate code rather than reading entire directories. Read only the sections you need. Batch independent reads in one message.

**Step 3 — Plan** *(skip if task is simple)*
When the task touches three or more files, changes a public API, or has unclear scope, write a short plan before coding. List the files you will change, the sequence of changes, and the definition of done. Wait for your own confirmation before writing code.

**Step 4 — Implement**
Make surgical edits. Match the existing code style exactly. Do not refactor unrelated code. Do not add unrequested features. Keep functions under 50 lines and nesting under 4 levels.

**Step 5 — Verify**
After editing, check your work:
- Does it compile or pass a syntax check?
- Do existing tests still pass?
- Did you introduce new tests for new functionality?
- Is there anything hardcoded that should be a constant?

**Step 6 — Summarize**
Report what you did in a short paragraph. State what changed, why, and what the user should verify. No padding, no filler.

## Checklist

- [ ] Stated understanding of the task before writing code
- [ ] Read relevant files before editing
- [ ] Planned if task touches 3+ files
- [ ] Made only the changes the task required
- [ ] Verified syntax and tests
- [ ] Summarized factually without padding

## Token Discipline

This skill costs almost nothing to run — it is a mental framework, not a code generator. Loading it takes a few dozen tokens. Following it saves many more by preventing rework.

## Verification

After completing a task with this workflow, ask yourself:

1. Can I point to where I stated my assumptions?
2. Can I point to where I read before I wrote?
3. Did I make any changes not requested?

If all three answers are satisfactory, the workflow was followed correctly.

## Public Safety Notes

This skill contains no private data, no machine-specific paths, and no credentials. It is safe to include in a public repository.
