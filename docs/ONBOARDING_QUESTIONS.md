# Onboarding Questions Reference

This document explains each of the 20 questions asked by the interactive setup wizard (`scripts/setup.sh` on Linux/macOS, `scripts/setup.ps1` on Windows), why each question matters, and what it affects.

General wizard behaviour:

- The wizard is fully bilingual. After Question 1, every prompt, explanation, and error message appears in the language you chose.
- Every menu question shows numbered options with the default in square brackets. Pressing Enter accepts the default.
- Each question is preceded by a short plain-language explanation of what it means and why it is asked.
- Answers are validated: menus only accept valid numbers, required free-text answers are re-asked with an example if too short, and yes/no questions accept `y/yes/j/ja/n/no/nein` case-insensitively.
- Nothing is written to disk until you confirm the final summary. `--dry-run` prints the generated `CLAUDE.md` without writing anything.
- `--answer-file <path>` feeds answers from a file (one answer per line, empty line = default) for tests and automation.

---

## Question 1 — Language / Sprache

**Question:** In which language should this setup — and later Claude — talk to you? 1) Deutsch 2) English

**Default:** Detected from your system locale (a German locale pre-selects Deutsch; anything else pre-selects English).

**Why it matters:** The whole wizard, the generated configuration, and the Obsidian vault scaffold exist in German and English. Choosing here means you never have to remind Claude which language to answer in.

**What it affects:** The language of all remaining wizard prompts, the language directive in `CLAUDE.md`, the language variant of the Obsidian vault scaffold, the language of update notifications, and `config.json` (`language`).

---

## Question 2 — Your name

**Question:** What should Claude call you?

**Required:** Yes (free text; a first name is enough).

**Why it matters:** Personalizes the `CLAUDE.md` header and the vault profile note, and makes it clear whose configuration this is on shared machines.

**What it affects:** The `CLAUDE.md` heading, the vault's `me/profil.md`, and `config.json` (`userName`).

---

## Question 3 — Experience level

**Question:** How much experience do you have with Claude Code? 1) Beginner — I am just getting started 2) Intermediate — I use it regularly 3) Pro — I know skills, agents, and hooks

**Default:** 1 (Beginner).

**Why it matters:** Answering honestly pays off. As a beginner, Claude explains steps in simpler language, asks before doing anything complicated, and suggests exactly one next step at a time instead of overwhelming you.

**What it affects:** Beginners get a dedicated "Beginner mode" block in `CLAUDE.md`. Also stored in `config.json` (`experience`) and the vault profile.

---

## Question 4 — Your goals

**Question:** What do you want to do with Claude? Describe it in 1–3 sentences.

**Required:** Yes (at least 10 characters — shorter answers get a friendly follow-up with examples such as "build FiveM scripts for my server", "develop a web app", "learn Python").

**Why it matters:** Claude aligns its suggestions, explanations, and priorities with your goals — and does not forget them between sessions.

**What it affects:** The "Goals" section of `CLAUDE.md` and the vault's `me/profil.md`.

---

## Question 5 — Main work type

**Question:** What kind of work will you mainly do? 1) General 2) Web frontend 3) Backend/APIs 4) Full-stack 5) FiveM/game scripts 6) DevOps 7) Data/Python 8) Marketing/copy

**Default:** 1 (General).

**Why it matters:** Determines the work context Claude assumes by default and whether optional modules are relevant to you.

**What it affects:** The Work Context section in `CLAUDE.md`. Choosing option 5 (FiveM/game scripts) automatically enables the FiveM module — Question 14 is then skipped and the wizard tells you so.

---

## Question 6 — Tech stacks

**Question:** Which programming languages / technologies do you work with? (comma-separated)

**Default:** "Don't know yet" — if you are unsure, just press Enter; Claude figures it out while working with you.

**Why it matters:** Documents your tech context so Claude does not need to ask what language you use or suggest irrelevant tools.

**What it affects:** The Work Context section of `CLAUDE.md` and the vault profile.

---

## Question 7 — Model detection

**Question:** The wizard first checks `~/.claude/settings.json` for a configured model. If it finds one, it asks: "I checked: you are currently using **<model name>**. Is that right? [Y/n]". If nothing is found (or you say no), you get a menu: 1) Haiku (fast and cheap) 2) Sonnet (standard) 3) Opus (very strong) 4) Fable (flagship) 5) I don't know

**Default:** 5 (I don't know) in the manual menu.

**Why it matters:** Claude comes in several models — from fast and cheap (Haiku) to maximum capability (Opus/Fable). Knowing which one you run lets the generated configuration give the right routing advice. If you are unsure, start Claude Code and type `/model` to see it — or simply pick "I don't know".

**What it affects:** The Model Discipline section of `CLAUDE.md`:
- **Haiku** → routing table plus a warning to start a stronger-model session for architecture, security, or multi-file work.
- **Sonnet / I don't know** → standard routing table ("I don't know" additionally gets a tip to run `/model`).
- **Opus / Fable** → routing table plus a hint that mechanical bulk work can be delegated to cheaper agent models such as Haiku.

Also stored in `config.json` (`model`, `modelRaw`). See `docs/MODEL_ROUTING.md` for the full guide.

---

## Question 8 — Subscription / plan

**Question:** How do you pay for Claude? 1) Claude Pro (about 20 €/month) 2) Claude Max 3) API credits 4) I don't know

**Default:** 4 (I don't know).

**Why it matters:** On the Pro plan the usage quota is smaller — so Claude configures itself to be more economical with tokens.

**What it affects:** The default answer for Question 9: Pro pre-selects "Aggressive"; everything else pre-selects "Balanced". Also stored in `config.json` (`planTier`).

---

## Question 9 — Token strategy

**Question:** How economical should Claude be with tokens? 1) Conservative (quality over savings) 2) Balanced 3) Aggressive (maximum savings)

**Default:** Derived from Question 8 (Pro → Aggressive, otherwise Balanced).

**Why it matters:** Tokens are Claude's "unit of consumption". Economical means Claude reads more selectively and summarizes more briefly.

**What it affects:** The Token Strategy section of `CLAUDE.md` and its concrete rules. See `docs/TOKEN_EFFICIENCY.md`.

---

## Question 10 — Planning preference

**Question:** When should Claude plan before coding? 1) Plan automatically for larger tasks (recommended) 2) Ask me first 3) Minimal planning

**Default:** 1.

**Why it matters:** Some developers want a plan before any multi-file change; others find planning friction and prefer to decide case by case.

**What it affects:** The "When to Plan Before Coding" section of `CLAUDE.md`.

---

## Question 11 — Code style

**Question:** What quality level should code have by default? 1) Simple (small private scripts) 2) Production-grade (recommended) 3) Strict 4) Architecture-focused

**Default:** 2 (Production-grade).

**Why it matters:** A production API serving thousands of users needs different defaults than a personal automation script.

**What it affects:** The Code Style section of `CLAUDE.md`.

---

## Question 12 — Testing

**Question:** When should Claude write tests? 1) Always 2) Only for risky/complex changes (recommended) 3) Ask first

**Default:** 2.

**Why it matters:** Over-testing wastes time on trivial code; under-testing causes production bugs.

**What it affects:** The Testing section of `CLAUDE.md`.

---

## Question 13 — Security level

**Question:** How strict should security be? 1) Standard 2) Strict 3) Very strict

**Default:** 1 (Standard).

**Why it matters:** Anything handling logins, payments, or user data deserves at least "Strict". A personal side-project usually does not need mandatory audits on every change.

**What it affects:** The Security section of `CLAUDE.md` (rules and mandatory checks) and the security item in the Code Quality Gates checklist.

---

## Question 14 — FiveM module

**Question:** Enable FiveM-specific guidance? (y/n)

**Default:** n. **Skipped and set to yes automatically** if you chose "FiveM/game scripts" in Question 5.

**Why it matters:** FiveM is a modding platform for GTA V. The module contains rules about script performance, server-side validation, and NUI interfaces — only relevant if you build scripts for it.

**What it affects:** If enabled, a FiveM Development section is appended to `CLAUDE.md` and the `brain-fivem-development` skill becomes relevant.

---

## Question 15 — Marketing module

**Question:** Enable marketing / copywriting support? (y/n)

**Default:** n.

**Why it matters:** Copy and messaging work follows different rules than code — flowing prose instead of AI-sounding bullet lists, brand voice, benefit-focused writing.

**What it affects:** If enabled, a Marketing and Sales Support section is appended to `CLAUDE.md` and the `brain-marketing-support` skill becomes relevant.

---

## Question 16 — Partner mode

**Question:** How should Claude treat you? 1) Partner with its own opinion — pushes back when something is a bad idea (recommended) 2) Reserved — just does what you say

**Default:** 1.

**Why it matters:** Option 1 means Claude tells you honestly when a plan will cause problems and proposes something better — like a good teammate, not a yes-man.

**What it affects:** The Team Rules block in `CLAUDE.md` (push back on pointless or risky requests, ask for sharper definitions on vague prompts, always ask before deletions).

---

## Question 17 — Obsidian Master Brain

**Question:** Set up the Obsidian Master Brain (Claude's long-term memory)? (y/n)

**Default:** y.

**Why it matters:** The Master Brain is a folder of linked notes in which Claude records projects, decisions, and knowledge about your collaboration — across sessions. Obsidian (obsidian.md, free) is an app that displays and links these notes nicely, but the memory also works without the app: the notes are plain text files.

**What it affects:** Whether the vault scaffold is created, the Obsidian section in `CLAUDE.md`, and `config.json` (`obsidian`). See `docs/OBSIDIAN_BRAIN.md`.

### Question 17a — Is Obsidian installed?

**Question:** Do you already have Obsidian installed? 1) Yes 2) No 3) I don't know

**Default:** 3 ("I don't know" — treated as no; the wizard shows a tip: search your Start menu / Applications for "Obsidian").

Only asked if Question 17 = yes. If the answer is not "Yes": the wizard creates the memory anyway and tells you that you can install Obsidian later from https://obsidian.md and open the folder as a vault.

### Question 17b — Vault path

**Question:** Where should the vault live?

**Default:** `~/Documents/ClaudeBrainVault`.

If the path already exists and is not empty, the wizard asks whether to reuse it as an existing vault (only missing files are added — **nothing is overwritten**) or to choose a different path.

---

## Question 18 — First project

**Question:** What do you want to work on first? A short name is enough (e.g. "my-server" or "shop-website"). Press Enter to skip.

**Default:** Skipped (optional).

**Why it matters:** Gives Claude an immediate anchor: the project gets its own hub note in the vault and a line in the Work Context.

**What it affects:** A `projects/<slug>.md` hub note in the vault (created from the project template) and the first-project line in `CLAUDE.md`.

---

## Question 19 — Update notifications

**Question:** Check for Brain updates automatically? (y/n)

**Default:** y.

**Why it matters:** Once a day, a tiny script checks at session start whether a new Brain version exists on GitHub — a single small request; no data about you is sent. If there is one, Claude tells you and you can update with `/brain-update`.

**What it affects:** Whether the SessionStart hook is registered in `~/.claude/settings.json` and `config.json` (`updateCheck.enabled`). Full details in `docs/UPDATE.md` and `docs/SECURITY.md`.

---

## Question 20 — Install skills

**Question:** Install the bundled Brain skills? (y/n)

**Default:** y.

**Why it matters:** Skills are ready-made working instructions for Claude (for example a security checklist). They are plain text files and never execute anything by themselves.

**What it affects:** Whether the 14 bundled skills are copied to `~/.claude/skills/`. See `docs/SKILLS.md`.

---

## Final step — Summary and confirmation

After the last question, the wizard shows a summary of all your answers and asks: "Does this look right? [Y/n]".

- **Yes** → files are written in this order: backups, `CLAUDE.md`, skills, vault, `config.json`, update hook, V1 migration check, closing screen (what was installed where, how to start Claude, `/brain-update` hint).
- **No** → the wizard exits **without writing anything** and suggests simply running the setup again.
