# brain-skill-authoring

## Purpose

A guide for contributors writing new bundled Brain skills for this repository. Ensures new skills are portable, honest, and useful to all users.

## When to Use

When writing a new bundled skill for the claude-brain-setup repository.

## When Not to Use

When editing an existing skill — just edit its SKILL.md directly. When writing project-specific skills that live outside this repository.

## Workflow

**Required section structure**

Every bundled skill must contain these sections in this order:

1. `# Skill Name` — the skill name as an H1 heading
2. `## Purpose` — one paragraph, what problem this skill solves
3. `## When to Use` — specific triggers for loading this skill
4. `## When Not to Use` — explicit cases where loading this skill is wrong
5. `## Workflow` — the actionable steps, commands, or checklist
6. `## Checklist` — bullet list of items to verify before marking done
7. `## Token Discipline` — estimated token cost to load and when loading is worth it
8. `## Verification` — a concrete way to test that the skill worked correctly
9. `## Public Safety Notes` — confirmation that the skill contains no private data

**Naming convention**

All bundled Brain skills use the prefix `brain-`. The folder name and the H1 heading should match.

Examples: `brain-core-workflow`, `brain-security-review`, `brain-session-handoff`

**Folder structure**

```
skills/
  brain-my-skill/
    SKILL.md
```

No other files are needed for a basic skill. If the skill references external files (templates, examples), document them in the Workflow section rather than bundling them.

**Portability rules**

- No absolute paths specific to any machine (no user home directories, machine-specific system paths, or `C:\Users\name\` style Windows paths)
- No assumptions about installed tools beyond bash, python3, git, and Claude Code itself
- If a tool is required that is not universally installed, document how to install it in the Workflow section
- No hardcoded credentials, API keys, tokens, or private data of any kind

**Honesty rules**

Do not claim capabilities Claude Code does not have:
- Do not claim Claude switches models automatically mid-session
- Do not claim `/dream` automatically edits CLAUDE.md
- Do not claim guaranteed token savings with specific percentages
- Do not claim Claude knows its exact context window usage as a percentage

**Length limit**

Skills must be under 200 lines. The target is 80–150 lines. If a skill is longer, it is probably trying to do too much. Split it or cut the fluff.

**Testing a new skill before submitting**

Read the SKILL.md as if you have never seen it before. Ask:
- Can you follow the Workflow without guessing?
- Is there anything in the file that could be private or machine-specific?
- Does the skill make any claim Claude cannot actually fulfill?
- Can the Verification section tell you whether the skill succeeded?

If all four answers are satisfactory, the skill is ready for review.

## Checklist

- [ ] All 9 required sections present and in order
- [ ] Skill name follows `brain-<topic>` convention
- [ ] File is under 200 lines
- [ ] No absolute paths, private data, or credentials
- [ ] No false claims about Claude Code capabilities
- [ ] Workflow is actionable without external knowledge
- [ ] Verification section has a concrete test
- [ ] Public Safety Notes confirm the skill is safe to publish

## Token Discipline

This skill is a contributor reference. Load it when writing a new bundled skill, not during regular development sessions. Cost: roughly 80 tokens.

## Verification

After writing a new skill, read it aloud as if explaining it to a new user. If any part requires background knowledge not provided in the skill itself, the skill is incomplete.

## Public Safety Notes

This skill contains no private data, no machine-specific paths, and no credentials. It is safe to include in a public repository.
