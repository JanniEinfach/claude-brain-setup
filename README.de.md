![Brain Setup for Claude Code](brain_setup_for_claude_code.png)

🇬🇧 English version: [README.md](README.md)

# Claude Brain Setup

> **Inoffizielles Konfigurations-Toolkit für Claude Code. Nicht mit Anthropic verbunden.**

**Mach aus Claude Code ein Master Brain.** Ein geführtes Setup gibt Claude Code eine personalisierte System-Instruktionsdatei, ein dauerhaftes projektübergreifendes Gedächtnis, 14 einsatzbereite Skills und ein Update-System, das alles aktuell hält.

## Was du bekommst

1. **Anfängersicheres interaktives Setup** — ein zweisprachiger Assistent (Deutsch/Englisch), der jede Frage in einfacher Sprache erklärt, deine Antworten prüft und sogar erkennt, welches Claude-Modell du gerade nutzt. Am Ende steht ein `CLAUDE.md`, das auf deinen Namen, deine Ziele, deinen Erfahrungsstand und deine Arbeitsweise zugeschnitten ist.
2. **Obsidian Master Brain** — ein optionales Langzeitgedächtnis: ein Ordner mit einfachen Markdown-Notizen, in dem Claude Projekte, Entscheidungen und Wissen über eure Zusammenarbeit festhält — über Sessions und Projekte hinweg. Funktioniert mit und ohne die kostenlose App [Obsidian](https://obsidian.md).
3. **Automatische Update-Benachrichtigungen** — ein kleiner Hook prüft einmal am Tag, ob es eine neue Brain-Version auf GitHub gibt, und sagt dir direkt in Claude Code Bescheid. Aktualisieren geht mit einem Befehl: `/brain-update`.
4. **14 mitgelieferte Skills** — portable Markdown-Anleitungen für disziplinierte Workflows, Token-Effizienz, Security-Reviews, Session-Übergaben und mehr. Sie werden nach `~/.claude/skills/` installiert und führen nie von selbst Code aus.
5. **Windows, Linux und macOS** — featuregleiche PowerShell- und Bash-Skripte. Keine Admin-Rechte nötig. Die Skripte löschen niemals Dateien; vor jedem Überschreiben wird ein Backup mit Zeitstempel angelegt.

## Schnellstart

### Ein-Zeilen-Installation (kein git nötig)

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/JanniEinfach/claude-brain-setup/main/scripts/bootstrap.ps1 | iex
```

**Linux / macOS:**

```bash
curl -fsSL https://raw.githubusercontent.com/JanniEinfach/claude-brain-setup/main/scripts/bootstrap.sh | bash
```

Das Bootstrap-Skript lädt das Repository als ZIP in einen temporären Ordner und startet von dort das interaktive Setup. Ein Skript direkt aus dem Internet auszuführen ist Vertrauenssache — lies gern zuerst `scripts/bootstrap.ps1` / `scripts/bootstrap.sh` in diesem Repository.

### Installation per git clone

```bash
git clone https://github.com/JanniEinfach/claude-brain-setup.git
cd claude-brain-setup
./scripts/setup.sh          # interaktiver Assistent (empfohlen)
```

Windows:

```powershell
git clone https://github.com/JanniEinfach/claude-brain-setup.git
cd claude-brain-setup
.\scripts\setup.ps1
```

Lieber eine schnelle Installation ohne Fragen mit sinnvollen Defaults? Dann `./scripts/install.sh` / `.\scripts\install.ps1` (mit `--with-skills` / `-WithSkills` für die Skills, `--no-update-check` / `-NoUpdateCheck` ohne Update-Hook).

Noch nie ein Terminal benutzt? [INSTALL.md](INSTALL.md) erklärt jeden Schritt — auch, wie man PowerShell oder ein Terminal überhaupt öffnet.

## Was dieses Projekt NICHT tut

- **Es wechselt Modelle nicht automatisch.** Claude kann das Modell mitten in einer Session nicht ändern. Du wählst es beim Start mit `--model`. Dieses Projekt hilft dir, richtig zu wählen.
- **Es spart Tokens nicht automatisch.** Gute Gewohnheiten sparen Tokens. Dieses Projekt gibt dir diese Gewohnheiten schriftlich.
- **Es sendet keine Daten von dir.** Die einzigen Netzwerkzugriffe: der Download dieses Repositories (bootstrap/update) und der tägliche Versions-Check — eine einzige GET-Anfrage nach einer Versionsnummer. Keine Telemetrie, keine Analytics. Der Versions-Check ist abschaltbar (siehe Sicherheitshinweise).
- **Es braucht die Obsidian-App nicht.** Das Master Brain besteht aus normalen Markdown-Dateien. Obsidian ist ein schöner, kostenloser Betrachter dafür — mehr nicht.
- **`/dream` bearbeitet dein CLAUDE.md nicht automatisch.** Der Dream-Skill ist ein manuelles Werkzeug zur Gedächtnis-Konsolidierung, das du bewusst startest.
- **Es kennt deinen exakten Kontextfenster-Stand nicht.** Claude schätzt den verbleibenden Platz; einen präzisen Prozentzähler gibt es nicht.
- **Es braucht keine Root- oder Admin-Rechte.** Alles wird in dein Home-Verzeichnis installiert.
- **Es löscht keine Dateien. Niemals.** Bestehende Dateien werden umbenannt oder mit Zeitstempel gesichert, bevor irgendetwas geschrieben wird.

## Das interaktive Setup

`setup.sh` / `setup.ps1` stellt 20 Fragen — auf Deutsch oder Englisch, du wählst am Anfang. Vor jeder Frage steht eine kurze Erklärung in einfacher Sprache, was sie bedeutet und warum sie gestellt wird. Themen: dein Name, Erfahrungsstand, Ziele, Haupt-Arbeitstyp, Tech-Stacks, Modell (wo möglich automatisch aus `~/.claude/settings.json` erkannt), Abo, Token-Strategie, Planungsstil, Code-Style, Testing, Security-Level, optionale FiveM- und Marketing-Module, Partner-Modus, das Obsidian Master Brain, dein erstes Projekt, Update-Benachrichtigungen und die Skill-Installation.

Am Ende siehst du eine Zusammenfassung aller Antworten und bestätigst, bevor irgendetwas geschrieben wird.

Flags:

```bash
./scripts/setup.sh --dry-run              # alles durchlaufen, Ergebnis anzeigen, nichts schreiben
./scripts/setup.sh --target ~/mydir       # in ein eigenes Verzeichnis schreiben
./scripts/setup.sh --answer-file a.txt    # unbeaufsichtigt: eine Antwort pro Zeile, Leerzeile = Default
./scripts/setup.sh --help
```

Die PowerShell-Gegenstücke heißen `-DryRun`, `-Target`, `-AnswerFile`, `-Help`.

Alle Fragen erklärt: `docs/ONBOARDING_QUESTIONS.md`

### Wohin installiert wird

| Was | Ort |
|-----|-----|
| Personalisiertes `CLAUDE.md` | `~/.claude/CLAUDE.md` (global — gilt in jedem Projekt) |
| Mitgelieferte Skills | `~/.claude/skills/brain-*/` |
| Brain-Laufzeit (Version, Config, Updater) | `~/.claude/brain/` |
| Obsidian-Master-Brain-Vault | frei wählbar, Default `~/Documents/ClaudeBrainVault` |
| Update-Hook | ein Eintrag in `~/.claude/settings.json` (vorher gesichert) |

**Upgrade von V1?** V1 hat `CLAUDE.md` direkt ins Home-Verzeichnis installiert (`~/CLAUDE.md`). Das Setup erkennt das, erklärt die Änderung und bietet an, die alte Datei nach `~/CLAUDE.md.backup-<Zeitstempel>` umzubenennen. Gelöscht wird nichts.

## Das Obsidian Master Brain

Das Master Brain ist Claudes Langzeitgedächtnis: ein Vault aus Markdown-Notizen mit fester Struktur — `projects/`, `knowledge/`, `decisions/`, `sessions/`, `me/` — plus Schreibkonventionen, an die Claude sich hält. Am Sessionstart liest Claude den Vault-Index und die passende Projekt-Hub-Notiz; am Sessionende hält er dauerhafte Erkenntnisse und Entscheidungen fest. Über Wochen entsteht so ein echtes projektübergreifendes Gedächtnis, das jede Session überlebt.

Die Obsidian-App ist dafür nicht nötig — der Vault besteht aus normalen Textdateien. Wenn du [Obsidian](https://obsidian.md) (kostenlos) installierst, bekommst du eine schöne, verlinkte Ansicht auf alles, was Claude weiß.

Konzept, Struktur und FAQ: `docs/OBSIDIAN_BRAIN.md`

## Updates

Ein `SessionStart`-Hook startet beim Start von Claude Code ein kleines Prüfskript — höchstens einmal alle 24 Stunden. Es lädt die `VERSION`-Datei dieses Repositories von GitHub (eine GET-Anfrage, es wird nichts über dich gesendet) und gibt einen Hinweis aus, wenn eine neuere Version existiert. Claude sieht den Hinweis und sagt dir Bescheid.

Aktualisieren:

```
/brain-update            # in Claude Code — prüft, fragt nach, führt aus
```

oder manuell:

```bash
~/.claude/brain/update.sh          # Linux/macOS  (--check nur prüfen, --yes ohne Rückfrage)
```

```powershell
& "$env:USERPROFILE\.claude\brain\update.ps1"   # Windows  (-Check / -Yes)
```

Updates erneuern die mitgelieferten Skills, die Update-Skripte und die Docs-Kopie. Sie fassen **niemals** dein personalisiertes `CLAUDE.md`, deinen Vault oder deine Einstellungen an. Der vorherige Stand wird zuerst nach `~/.claude/brain/backups/` gesichert — Rollback jederzeit möglich. Alle Details: `docs/UPDATE.md`

## Mitgelieferte Brain-Skills (14)

Portable Markdown-Anleitungen — kein Code wird automatisch ausgeführt. Claude Code liest einen Skill als Kontext, wenn du ihn in einer Session mit `/skill-name` lädst.

| Skill | Zweck |
|-------|-------|
| `brain-core-workflow` | Disziplinierter Sechs-Schritte-Entwicklungsworkflow |
| `brain-token-discipline` | Gewohnheiten, die Tokens sparen, ohne Qualität zu verlieren |
| `brain-model-routing` | Das richtige Modell wählen, bevor eine Session startet |
| `brain-karpathy-principles` | Engineering-Disziplin: erst denken, dann coden; Einfachheit; chirurgische Änderungen |
| `brain-security-review` | Security-Checkliste für Code und Repositories |
| `brain-cross-platform-setup` | Skripte auf Linux, macOS und Windows validieren |
| `brain-session-handoff` | Strukturierte Übergabe vor Sessionende oder Modellwechsel |
| `brain-pr-review` | PR-Review-Checkliste für dieses Repository |
| `brain-ruflo-orchestration` | Wann und wie Multi-Agent-Workflows sinnvoll sind |
| `brain-skill-authoring` | Anleitung zum Schreiben neuer Brain-Skills |
| `brain-github-release` | Checkliste für ein öffentliches GitHub-Release |
| `brain-update` | Claude-Brain-Updates prüfen und einspielen |
| `brain-marketing-support` | Schreibhilfe für Sales-, Marketing- und SEO-Texte (optional) |
| `brain-fivem-development` | FiveM-Lua-Scripting, NUI und Framework-Wissen (optional) |

Das interaktive Setup installiert sie für dich. Separat: `./scripts/install.sh --with-skills` / `.\scripts\install.ps1 -WithSkills`.

## Beispiel-Session

```bash
claude --model claude-sonnet-5
# In der Session:
# /brain-core-workflow    — disziplinierter Workflow, bevor 3+ Dateien angefasst werden
# /brain-update           — auf Brain-Updates prüfen
# /brain-session-handoff  — Kontext sichern, bevor eine große Session endet
```

Schnelle Edits und Formatierung:

```bash
claude --model claude-haiku-4-5-20251001
```

Architektur, Security, komplexe Multi-File-Arbeit:

```bash
claude --model claude-opus-4-8
```

Spitzenmodell (Verfügbarkeit hängt von deinem Abo ab):

```bash
claude --model claude-fable-5
```

Modell-Entscheidungshilfe: `docs/MODEL_ROUTING.md`

## Dateistruktur

```
claude-brain-setup/
├── README.md                       — englische Version
├── README.de.md                    — diese Datei
├── CLAUDE.md                       — generische Default-Instruktionsdatei
├── CHANGELOG.md
├── INSTALL.md                      — Schritt-für-Schritt-Anleitung für beide Plattformen
├── VERSION                         — aktuelle Version (liest der Update-Check)
├── LICENSE, CONTRIBUTING.md, CODE_OF_CONDUCT.md, .gitignore, .gitattributes
├── settings.example.json           — sichere Beispiel-Einstellungen inkl. Update-Hook
├── brain_setup_for_claude_code.png
├── .github/                        — Issue- und PR-Vorlagen
├── templates/
│   ├── CLAUDE.template.md          — Vorlage, die der Setup-Assistent befüllt
│   └── obsidian/
│       ├── de/                     — deutsches Vault-Gerüst
│       └── en/                     — englisches Vault-Gerüst
├── scripts/
│   ├── setup.ps1 / setup.sh        — interaktiver Assistent (das Herzstück)
│   ├── install.ps1 / install.sh    — schnelle Installation ohne Fragen
│   ├── bootstrap.ps1 / bootstrap.sh — Ein-Zeilen-Webinstaller
│   ├── check-update.ps1 / check-update.sh — täglicher Versions-Check (als Hook installiert)
│   └── update.ps1 / update.sh      — spielt Updates mit Backup ein
├── skills/                         — 14 mitgelieferte Brain-Skills
└── docs/
    ├── ONBOARDING_QUESTIONS.md     — alle 20 Setup-Fragen erklärt
    ├── MODEL_ROUTING.md            — das richtige Modell wählen (Claude-5-Familie)
    ├── OBSIDIAN_BRAIN.md           — das Master-Brain-Konzept
    ├── UPDATE.md                   — das Update-System im Detail
    ├── TOKEN_EFFICIENCY.md         — praktische Token-Spar-Gewohnheiten
    ├── SKILLS.md                   — verifizierte Skill-Liste mit Token-Kosten
    ├── RUFLO_ORCHESTRATION.md      — wann und wie man Agents nutzt
    ├── SECURITY.md                 — was dieses Projekt anfasst und welche Risiken es gibt
    ├── TROUBLESHOOTING.md          — häufige Probleme und Lösungen
    ├── FAQ.md                      — kurze Antworten auf häufige Fragen
    ├── PRINCIPLES.md               — Engineering-Prinzipien
    ├── DREAM_CYCLE.md              — manuelle Gedächtnis-Konsolidierung
    └── GITHUB_LABELS.md            — empfohlenes Label-Set
```

## Voraussetzungen

- Claude Code installiert (`npm install -g @anthropic-ai/claude-code`)
- Ein Anthropic-API-Key oder ein Claude-Pro/Max-Abo
- Windows: PowerShell 5.1 oder neuer — Linux/macOS: Bash
- `curl` oder `wget` (Linux/macOS, für Bootstrap und Update-Check)
- Optional: `python3` oder `jq` auf Linux/macOS für automatisches Settings-Mergen (manueller Fallback vorhanden)
- Optional: die Obsidian-App zum Anschauen des Master Brains
- `git` nur bei Installation per Clone
- Keine Root- oder Admin-Rechte nötig

## Sicherheitshinweise

- **Die Skripte löschen niemals Dateien.** Sie kopieren, benennen um und sichern. Vor jedem Überschreiben entsteht ein Backup mit Zeitstempel.
- **Netzwerkzugriffe gibt es nur in drei Skripten:** `bootstrap` (lädt das Repo-ZIP von GitHub), `check-update` (holt die `VERSION`-Datei) und `update` (lädt das aktuelle Release). Sonst spricht nichts mit dem Netz.
- **Täglicher Versions-Check — volle Offenlegung:** Nach der Installation stellt ein `SessionStart`-Hook höchstens eine GET-Anfrage pro 24 Stunden an `https://raw.githubusercontent.com/JanniEinfach/claude-brain-setup/main/VERSION`. Es werden keine Daten über dich gesendet — es wird nur eine Versionsnummer heruntergeladen. Abschalten jederzeit möglich: Setup-Frage 19 mit „nein" beantworten, mit `--no-update-check` / `-NoUpdateCheck` installieren oder `updateCheck.enabled` in `~/.claude/brain/config.json` auf `false` setzen.
- Mitgelieferte Skills sind reine Markdown-Dateien. Sie führen keinen Code automatisch aus.
- Keine Secrets, API-Keys oder privaten Pfade in `CLAUDE.md` — die Datei wird als System-Prompt gelesen, nicht als Config.
- `settings.example.json` enthält nur lesende Shell-Berechtigungen und den Update-Hook. Vor Benutzung prüfen.
- Vollständiger Leitfaden: `docs/SECURITY.md`

## Fehlerbehebung

Siehe `docs/TROUBLESHOOTING.md` — u. a. PowerShell Execution Policy, kaputte Umlaute, Hook feuert nicht, Offline-Verhalten und die Migration von V1 zu V2.

## Mitmachen

Siehe [CONTRIBUTING.md](CONTRIBUTING.md) für Fork, Validierung und Pull Requests. Beiträge müssen vor dem Einreichen alle Syntax- und Sicherheitschecks bestehen.

## Lizenz

MIT — siehe `LICENSE`.
