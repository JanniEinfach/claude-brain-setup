---
type: meta
created: {{DATE}}
updated: {{DATE}}
---

# Vault-Konventionen — Claude Brain

Dieser Vault ist das projektübergreifende Gedächtnis von Claude Code auf dem System von {{USER_NAME}}.
Hauptleser und -schreiber: Claude Code. Pflichtlektüre zu Beginn jeder Session, die den Vault nutzt.

## Struktur

- `index.md` — Master-Index, Einstiegspunkt. Nach jedem Schreiben aktualisieren.
- `projects/` — eine Hub-Notiz pro Projekt (Vorlage: `meta/templates/projekt.md`). Ein neues Projekt bekommt eine neue Notiz — niemals einen neuen Vault.
- `knowledge/` — atomare Wissensnotizen, FLACH halten (keine Unterordner). MOCs (Maps of Content, Themen-Übersichten) tragen das Präfix `moc-`.
- `decisions/` — Entscheidungen im ADR-Stil: `YYYY-MM-DD-decision-<projekt>-<slug>.md`
- `sessions/` — Session-Logs: `YYYY-MM-DD-<projekt>.md`. Rohmaterial mit Verfallsdatum.
- `me/` — Profil, Arbeitsweise und Vorlieben von {{USER_NAME}}. Wenige, stabile Notizen.
- `meta/templates/` — Notiz-Vorlagen
- `inbox/`, `archive/` — erst anlegen, wenn Inhalt da ist

## Schreibregeln

1. Jede neue Notiz bekommt: Frontmatter nach Vorlage, mindestens einen Link von Projekt-Hub oder MOC, einen Eintrag im `index.md`. Keine verwaisten Notizen (Orphans).
2. Dateinamen: kebab-case, klein, sprechend. Datumspräfix `YYYY-MM-DD` nur für Sessions und Decisions.
3. Eine Idee pro Wissensnotiz (atomar). Keine Monolith-Notizen über 150 Zeilen.
4. Tags nur aus dem Vokabular unten — keine freien Tag-Erfindungen. Neue Tags erst dort eintragen, dann verwenden.
5. Qualitätsschwelle: nur nicht-offensichtliche, wiederverwendbare Erkenntnisse festhalten. Kein Horten von Trivialitäten.
6. Session-Logs destillieren: Dauerhaftes wandert nach `knowledge/` oder `decisions/`, danach darf das Log archiviert werden.
7. Nichts löschen ohne Zustimmung von {{USER_NAME}} — Veraltetes stattdessen auf `confidence: deprecated` setzen.

## Leseregeln

1. Session-Start: `index.md` + relevante Projekt-Hub-Notiz lesen, von dort Links folgen.
2. Nie den ganzen Vault scannen — der Index ist der Einstiegspunkt.
3. Wenn der Vault eine Antwort hat, gilt sie vor Trainingswissen.

## Frontmatter-Standard

Pflichtfelder je nach Typ (siehe Vorlagen in `meta/templates/`): `type` (project | knowledge | decision | session | moc | meta | person), `created`, bei Projekten `status` (active | paused | archived), bei Wissensnotizen `confidence` (verified | assumed | deprecated) und `source`.

## Tag-Vokabular

Bewusst klein halten und in dieser Liste pflegen. Starte mit Tags aus deinen eigenen Sprachen und Stacks (z. B. `js`, `python`, `lua` — was immer du tatsächlich benutzt) plus Querschnittsthemen:

`performance`, `security`, `workflow`

Ein neuer Tag kommt zuerst in diese Liste, dann in Notizen.

## Wartung (monatlich, durch Claude)

Orphans verlinken, Sessions älter als ~6 Wochen nach `archive/` verschieben (nach Rückfrage), `index.md` gegen den Ist-Zustand abgleichen, veraltete Wissensnotizen auf `deprecated` setzen, diese Konventionen bei Bedarf aktualisieren.
