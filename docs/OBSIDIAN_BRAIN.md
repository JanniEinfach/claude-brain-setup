# Obsidian Master Brain

The Master Brain is Claude Code's long-term memory: a folder of plain Markdown notes in which Claude records projects, decisions, and knowledge about your collaboration — persisting across sessions and across projects.

Claude Code sessions are stateless: when a session ends, everything Claude learned is gone. The Master Brain fixes that. Claude reads it at session start and writes back durable insights, so the second week of working together is smarter than the first.

The name comes from [Obsidian](https://obsidian.md), a free note app that displays and links these notes beautifully. **The app is optional** — the memory is ordinary text files and works without it (see FAQ).

## One vault for everything

The Master Brain is deliberately a **single vault** (one folder tree), not one vault per project:

- Obsidian wikilinks (`[[note]]`) do not work across vaults. One vault means a decision made in project A can be linked from project B.
- A new project gets a new **note** in `projects/`, never a new vault.
- Related projects link to each other and share knowledge notes instead of duplicating them.

This is written into the vault conventions (`CLAUDE.md` inside the vault), so every Claude session follows it.

## Structure

The setup wizard creates this scaffold (German or English variant, matching your setup language):

```
<vault>/                          default: ~/Documents/ClaudeBrainVault
├── CLAUDE.md                     vault conventions — writing rules, reading rules,
│                                 frontmatter standard, tag vocabulary, maintenance
├── index.md                      master index; entry point for every session
├── projects/                     one hub note per project
├── knowledge/                    atomic knowledge notes (flat); MOCs prefixed moc-
├── decisions/                    YYYY-MM-DD-decision-<project>-<slug>.md
├── sessions/                     YYYY-MM-DD-<project>.md session logs
├── me/                           your profile and working style (2 notes to start)
└── meta/templates/               note templates for project, knowledge,
                                  decision, and session notes
```

Notes carry YAML frontmatter (`type`, `created`, plus type-specific fields such as `status` for projects or `confidence` for knowledge notes). The exact rules live in the vault's own `CLAUDE.md` — that file, not this document, is the authority for how notes are written.

The tag vocabulary is intentionally open: it starts with a few cross-cutting tags (`performance`, `security`, `workflow`) and you — or Claude — extend it with tags from your own stacks. New tags are added to the vocabulary list first, then used.

## How Claude uses the vault

Your personalized `~/.claude/CLAUDE.md` (written by the setup wizard) contains the vault path and these standing instructions:

1. **Session start:** read the vault's `CLAUDE.md` + `index.md`, then the relevant `projects/<name>.md` hub note. Follow links from there — never scan the whole vault. This keeps token cost low and context relevant.
2. **During work:** a durable, non-obvious insight becomes an atomic note in `knowledge/`, linked from a MOC or project hub. A significant decision becomes `decisions/YYYY-MM-DD-decision-<project>-<slug>.md` with context, decision, and rationale.
3. **Session end (complex sessions):** write a session log to `sessions/`, update the project hub and `index.md`.
4. **About you:** observations about your working style and preferences go into `me/` — so Claude adapts to you over time instead of starting from zero.

Claude never deletes vault notes without your consent; outdated knowledge is marked `confidence: deprecated` instead.

## Installing Obsidian (optional)

If you want the visual layer — graph view, backlinks, quick search:

1. Download Obsidian from https://obsidian.md (free, Windows/Linux/macOS).
2. Open Obsidian → "Open folder as vault" → select your vault folder (default `~/Documents/ClaudeBrainVault`).
3. Done. No plugins required; the scaffold uses only core Markdown and wikilinks.

You can install the app at any time — before or long after setup. The files do not change.

## FAQ

**Do I need Obsidian for this to work?**
No. The Master Brain is plain Markdown files. Claude reads and writes them directly. Obsidian only adds a nice viewer with link navigation and graph view.

**Can I write and edit notes myself?**
Yes — it is your vault. Follow the conventions in the vault's `CLAUDE.md` (frontmatter, linking, tag vocabulary) so Claude's and your notes stay consistent.

**I already have an Obsidian vault. Can I use it?**
Yes. When the wizard asks for the vault path, point it at your existing vault. The wizard only adds missing files and never overwrites existing ones. If you prefer to keep work and personal notes separate, choose a fresh folder instead.

**I skipped the Master Brain during setup. How do I add it later?**
Run the setup wizard again (`scripts/setup.ps1` or `scripts/setup.sh`) and answer yes to the Master Brain question. Existing files are backed up before any overwrite.

**Does any of this leave my machine?**
No. The vault is local files under your home directory. Nothing is uploaded anywhere by this package.

**How big does the vault get?**
Slowly. The conventions enforce a quality bar (only non-obvious, reusable insights; no trivia) and a monthly maintenance routine: session logs older than about six weeks are archived after asking you, and stale knowledge is marked deprecated rather than piling up.

**Can I move the vault later?**
Yes. Move the folder, then update the vault path in the Obsidian section of `~/.claude/CLAUDE.md` (and in `~/.claude/brain/config.json`, field `obsidian.vaultPath`). If you use the Obsidian app, open the folder from its new location.

**Why does the vault have its own CLAUDE.md?**
Claude Code automatically picks up `CLAUDE.md` files as instructions. The vault's copy holds the writing and reading conventions, so any session that touches the vault follows the same rules — regardless of which project it started from.
