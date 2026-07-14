---
type: meta
created: {{DATE}}
updated: {{DATE}}
---

# Vault Conventions — Claude Brain

This vault is the cross-project memory of Claude Code on {{USER_NAME}}'s system.
Primary reader and writer: Claude Code. Required reading at the start of every session that uses the vault.

## Structure

- `index.md` — master index, the entry point. Update it after every write.
- `projects/` — one hub note per project (template: `meta/templates/project.md`). A new project gets a new note — never a new vault.
- `knowledge/` — atomic knowledge notes, kept FLAT (no subfolders). MOCs (Maps of Content, topic overviews) carry the prefix `moc-`.
- `decisions/` — ADR-style decisions: `YYYY-MM-DD-decision-<project>-<slug>.md`
- `sessions/` — session logs: `YYYY-MM-DD-<project>.md`. Raw material with an expiry date.
- `me/` — {{USER_NAME}}'s profile, working style, and preferences. Few, stable notes.
- `meta/templates/` — note templates
- `inbox/`, `archive/` — create only once there is content for them

## Writing rules

1. Every new note gets: frontmatter per template, at least one link from a project hub or MOC, and an entry in `index.md`. No orphan notes.
2. Filenames: kebab-case, lowercase, descriptive. Date prefix `YYYY-MM-DD` only for sessions and decisions.
3. One idea per knowledge note (atomic). No monolith notes over 150 lines.
4. Tags only from the vocabulary below — no ad-hoc tag inventions. Add new tags to the list first, then use them.
5. Quality bar: capture only non-obvious, reusable insights. No hoarding of trivia.
6. Distill session logs: anything durable moves to `knowledge/` or `decisions/`; after that the log may be archived.
7. Never delete anything without {{USER_NAME}}'s consent — mark outdated notes `confidence: deprecated` instead.

## Reading rules

1. Session start: read `index.md` + the relevant project hub note, then follow links from there.
2. Never scan the whole vault — the index is the entry point.
3. If the vault has an answer, it overrides training knowledge.

## Frontmatter standard

Required fields per type (see templates in `meta/templates/`): `type` (project | knowledge | decision | session | moc | meta | person), `created`, for projects `status` (active | paused | archived), for knowledge notes `confidence` (verified | assumed | deprecated) and `source`.

## Tag vocabulary

Keep it deliberately small and maintain it in this list. Start with tags from your own languages and stacks (e.g. `js`, `python`, `lua` — whatever you actually use) plus cross-cutting topics:

`performance`, `security`, `workflow`

A new tag goes into this list first, then into notes.

## Maintenance (monthly, by Claude)

Link orphans, move sessions older than ~6 weeks to `archive/` (after asking), reconcile `index.md` with the actual vault state, mark outdated knowledge notes `deprecated`, and update these conventions when needed.
