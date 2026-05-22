# Onboarding Questions Reference

This document explains each of the 15 questions asked by `scripts/setup.sh`, why each question matters, and what it affects in the generated `CLAUDE.md`.

---

## Question 1 — Your name

**Question:** What should Claude call you?

**Why it matters:** Personalizes the CLAUDE.md header and makes it immediately clear that the configuration belongs to you on shared machines.

**What it affects:** The CLAUDE.md heading and a few contextual references throughout.

---

## Question 2 — Preferred response language

**Question:** Preferred response language (English, German, French, Spanish, Other)

**Why it matters:** Claude Code reads the system language from CLAUDE.md. Setting this here means you do not need to remind Claude every session which language to use.

**What it affects:** A language directive in the Core Behaviour section.

---

## Question 3 — Main work type

**Question:** Main work type (General / Web / Backend / Full-stack / FiveM / DevOps / Data / Marketing)

**Why it matters:** Determines which skills are listed in the Core Skills section and enables optional sections (FiveM, marketing). Someone doing data science needs different skills than someone building web UIs.

**What it affects:** The skills list in CLAUDE.md, the MAIN_WORK_TYPE label, and optional section inclusion.

---

## Question 4 — Default model strategy

**Question:** Default model strategy (Sonnet default / Haiku-first / Opus default)

**Why it matters:** The model is set at launch, not mid-session. Agreeing on a default model strategy upfront saves the cognitive overhead of choosing each time.

**What it affects:** The Model Discipline section, which lists recommended CLI commands and default guidance.

---

## Question 5 — Token-saving strictness

**Question:** Token-saving strictness (Conservative / Balanced / Aggressive)

**Why it matters:** Different workflows benefit from different token habits. A solo developer doing exploratory research has different needs than a team doing cost-controlled production work.

**What it affects:** The Token Strategy section and its specific rules (how strictly to search before reading, handoff frequency, output summarization).

---

## Question 6 — Planning preference

**Question:** Planning preference (Auto-plan for 3+ file tasks / Ask before planning / Minimal plans)

**Why it matters:** Some developers prefer a plan before any multi-file change. Others find planning friction and prefer to decide case by case.

**What it affects:** The "When to Plan Before Coding" section. Controls whether Claude automatically plans or waits to be asked.

---

## Question 7 — Code style

**Question:** Code style (Simple / Production-grade / Strict / Architectural)

**Why it matters:** A production API serving thousands of users needs different defaults than a personal automation script.

**What it affects:** The Code Style section, which describes the default conventions Claude should apply.

---

## Question 8 — Testing preference

**Question:** Testing preference (Always add tests / Risky changes only / Ask first)

**Why it matters:** Over-testing wastes time on trivial code. Under-testing causes production bugs. This lets you set the right default.

**What it affects:** The Testing section in CLAUDE.md, controlling when Claude adds tests by default.

---

## Question 9 — Security level

**Question:** Security level (Standard / Strict / Very strict)

**Why it matters:** Systems handling auth, payments, or user data need explicit security review steps that a personal side-project might not.

**What it affects:** The Security section (specific rules and mandatory checks) and the Code Quality Gates checklist item about running `/security`.

---

## Question 10 — Primary stacks

**Question:** Primary programming stacks (comma-separated, e.g. TypeScript, Python, Go)

**Why it matters:** Documents your tech context so Claude does not ask what language you are using or suggest irrelevant tools.

**What it affects:** The Work Context section. Also informs which language-specific skills might be useful.

---

## Question 11 — Frontend style

**Question:** Frontend style (Clean SaaS / Dashboard / Marketing / FiveM NUI / None)

**Why it matters:** Different frontend contexts have different conventions, constraints, and quality bars.

**What it affects:** The Work Context section. If FiveM NUI is chosen alongside FiveM support, the NUI rules are included.

---

## Question 12 — Marketing / sales support

**Question:** Enable marketing / sales support? (y/n)

**Why it matters:** Copy and messaging work has different rules than code — avoid AI-sounding bullet lists, write in flowing prose, match brand voice.

**What it affects:** If enabled, appends a Marketing and Sales Support section to CLAUDE.md with writing guidelines and relevant skills.

---

## Question 13 — FiveM support

**Question:** Enable FiveM-specific guidance? (y/n)

**Why it matters:** FiveM Lua scripting has specific rules around performance (adaptive Wait, no Wait(0) in loops), security (server-side validation), and NUI (transparent backgrounds). These are not relevant to most developers.

**What it affects:** If enabled, appends a FiveM Development section to CLAUDE.md with Lua, NUI, and framework rules.

---

## Question 14 — Memory / dream guidance

**Question:** Memory / dream guidance (Manual only / Remind me / Disabled)

**Why it matters:** The `/dream` and `/remember` skills provide session memory consolidation, but some developers never use them. Others want reminders. Setting this avoids either forgetting about it or being nagged when you do not want it.

**What it affects:** If "Remind me" is selected, appends a Memory section to CLAUDE.md. Otherwise, no memory section is included.

---

## Question 15 — Agent orchestration level

**Question:** Agent orchestration level (Minimal / Balanced / Advanced)

**Why it matters:** Multi-agent workflows add overhead. Someone doing solo work on a small project should not spawn orchestration agents for every task. Someone managing a complex parallel build genuinely benefits from them.

**What it affects:** The Orchestration section, which lists available agents and the rule for when to use them. Advanced includes the full agent list and the 15-minute rule.
