# brain-karpathy-principles

## Purpose

Engineering discipline principles for coding agents. A reminder of the habits that separate good AI-assisted development from sloppy AI-assisted development.

## When to Use

At the start of a complex or ambiguous task. When you have not thought through the approach yet. When scope is unclear or the task involves multiple components.

## When Not to Use

When the task is straightforward and you already know exactly what to do. Do not load this skill to delay starting simple work.

## Workflow

**Principle 1 — Think Before Coding**

State your understanding of the task before writing a single line of code. Name the assumptions you are making. If something is ambiguous, ask one focused question now. Assumptions surfaced before implementation are easy to correct. Assumptions discovered after implementation mean rework.

Questions to ask before starting:
- What exactly is the user asking for?
- What are the edge cases?
- What should NOT change?
- What does "done" look like concretely?

**Principle 2 — Simplicity First**

Write the minimum code that solves the problem as stated. Do not add abstractions for hypothetical future requirements. Do not create utility functions that are only used once. If you cannot explain why a line of code exists, delete it.

Signs of over-engineering:
- Abstraction layers with no current users
- Config options for behavior that never varies
- Generalization for cases that have not been requested
- Design patterns applied because they feel right, not because they solve a problem

**Principle 3 — Surgical Changes**

Touch only what the task requires. Do not refactor unrelated code you happen to notice. Do not clean up formatting in files you are not changing. Do not add features that were not asked for. Every unexpected change is a diff the user did not ask to review.

Before editing a file, ask: "Is changing this file necessary for the task at hand?"

**Principle 4 — Goal-Driven Execution**

Define what "done" means before you start. Write it down in one sentence. When you think you are finished, check against that definition. Verify with tests or checks — do not declare something done because it looks right. If the task required a test, the task is not done until the test exists and passes.

Definition of done template: "This task is complete when [specific outcome] is verified by [specific check]."

## Checklist

- [ ] Stated task understanding before writing code
- [ ] Named assumptions explicitly
- [ ] Asked clarifying questions if ambiguous, before implementing
- [ ] Wrote only what was needed, no speculative abstractions
- [ ] Touched only files required by the task
- [ ] Defined "done" before starting
- [ ] Verified against the definition of done

## Token Discipline

This skill is a principles reference. Load it once when starting an ambiguous task. Cost: roughly 70 tokens. It is not meant to be re-read mid-task.

## Verification

After completing a task, ask: "Did I add anything that was not asked for?" If the answer is yes, consider reverting those additions and asking the user if they want them.

## Public Safety Notes

This skill contains no private data, no machine-specific paths, and no credentials. It is safe to include in a public repository.
