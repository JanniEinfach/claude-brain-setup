#!/usr/bin/env bash
# Claude Brain Setup — Interactive setup wizard (Linux/macOS)
# Version 2.0.0 — https://github.com/JanniEinfach/claude-brain-setup
#
# Usage:
#   ./scripts/setup.sh                         interactive wizard
#   ./scripts/setup.sh --dry-run               run all questions, print CLAUDE.md, write nothing
#   ./scripts/setup.sh --target <dir>          use <dir> instead of your home directory as base (for tests)
#   ./scripts/setup.sh --answer-file <file>    read answers from a file (one answer per line, blank = default)
#   ./scripts/setup.sh --help                  show help
#
# Compatible with bash 3.2+ (macOS) and bash 4/5 (Linux). No admin rights
# required. This script never deletes user files — existing files are renamed
# or copied to timestamped backups.

set -euo pipefail

# ── Paths ─────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DRY_RUN=0
TARGET_DIR=''
ANSWER_FILE=''
SHOW_HELP=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --target)
      if [ -z "${2:-}" ]; then
        echo "Error: --target requires a path argument." >&2
        exit 1
      fi
      TARGET_DIR="$2"; shift 2 ;;
    --answer-file)
      if [ -z "${2:-}" ]; then
        echo "Error: --answer-file requires a file argument." >&2
        exit 1
      fi
      ANSWER_FILE="$2"; shift 2 ;;
    --help|-h) SHOW_HELP=1; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [ -n "$TARGET_DIR" ]; then
  HOME_DIR="$TARGET_DIR"
else
  HOME_DIR="$HOME"
fi

CLAUDE_DIR="$HOME_DIR/.claude"
BRAIN_DIR="$CLAUDE_DIR/brain"
SKILLS_DEST="$CLAUDE_DIR/skills"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
CLAUDE_MD_OUT="$CLAUDE_DIR/CLAUDE.md"
V1_CLAUDE_MD="$HOME_DIR/CLAUDE.md"

TEMPLATE_FILE="$PROJECT_ROOT/templates/CLAUDE.template.md"
VAULT_TPL_ROOT="$PROJECT_ROOT/templates/obsidian"
SKILLS_SRC="$PROJECT_ROOT/skills"
DOCS_SRC="$PROJECT_ROOT/docs"
TRIO_SRC="$PROJECT_ROOT/brain/trio"
COMMANDS_SRC="$PROJECT_ROOT/commands"
COMMANDS_DEST="$CLAUDE_DIR/commands"
VERSION_FILE="$PROJECT_ROOT/VERSION"

REPO_SLUG='JanniEinfach/claude-brain-setup'
REPO_BRANCH='main'

BRAIN_VERSION='2.0.0'
if [ -f "$VERSION_FILE" ]; then
  _v="$(tr -d ' \t\r\n' < "$VERSION_FILE")"
  if [ -n "$_v" ]; then BRAIN_VERSION="$_v"; fi
fi

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
TODAY="$(date +%Y-%m-%d)"

# ── Help ──────────────────────────────────────────────────────────────────────

if [ "$SHOW_HELP" = "1" ]; then
  echo ""
  echo "Claude Brain Setup $BRAIN_VERSION — interactive wizard (Linux/macOS)"
  echo ""
  echo "  --dry-run             Alles durchspielen, generiertes CLAUDE.md anzeigen, nichts schreiben."
  echo "                        Run everything, print the generated CLAUDE.md, write nothing."
  echo "  --target <dir>        Basisordner statt deines Home-Verzeichnisses (fuer Tests)."
  echo "                        Base directory instead of your home directory (for testing)."
  echo "  --answer-file <file>  Antworten aus Datei lesen: eine Antwort pro Zeile in Frage-"
  echo "                        Reihenfolge, Leerzeile = Standardwert."
  echo "                        Read answers from a file: one answer per line in question"
  echo "                        order, blank line = default."
  echo "  --help                Diese Hilfe. / This help."
  echo ""
  echo "Installiert / installs:"
  echo "  ~/.claude/CLAUDE.md          personalisierte Konfiguration / personalized config"
  echo "  ~/.claude/skills/brain-*     Brain-Skills"
  echo "  ~/.claude/brain/             Laufzeit: VERSION, config.json, Update-Skripte, docs"
  echo "  <Vault-Pfad>                 Obsidian Master Brain (optional)"
  echo ""
  exit 0
fi

# ── Answer file ───────────────────────────────────────────────────────────────

HAVE_ANSWER_FILE=0
ANSWER_COUNT=0
ANSWER_INDEX=0
ANSWERS=()
LAST_FROM_FILE=0

if [ -n "$ANSWER_FILE" ]; then
  if [ ! -f "$ANSWER_FILE" ]; then
    echo "Answer file not found: $ANSWER_FILE" >&2
    exit 1
  fi
  HAVE_ANSWER_FILE=1
  while IFS= read -r _line || [ -n "$_line" ]; do
    ANSWERS[$ANSWER_COUNT]="$_line"
    ANSWER_COUNT=$((ANSWER_COUNT + 1))
  done < "$ANSWER_FILE"
fi

# ── Colors ────────────────────────────────────────────────────────────────────

if [ -t 1 ]; then
  C_CYAN=$'\033[36m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_GRAY=$'\033[90m'
  C_WHITE=$'\033[1m'
  C_RED=$'\033[31m'
  C_RESET=$'\033[0m'
else
  C_CYAN=''; C_GREEN=''; C_YELLOW=''; C_GRAY=''; C_WHITE=''; C_RED=''; C_RESET=''
fi

# ── Helper functions ──────────────────────────────────────────────────────────

write_title() {
  local t="$1"
  echo ""
  printf '%s%s%s\n' "$C_CYAN" "$t" "$C_RESET"
  printf '%s' "$C_CYAN"
  printf '%*s' "${#t}" '' | tr ' ' '='
  printf '%s\n' "$C_RESET"
}

write_step() {
  printf '%s  %s%s\n' "$C_GREEN" "$1" "$C_RESET"
}

write_note() {
  printf '%s%s%s\n' "$C_GRAY" "$1" "$C_RESET"
}

write_warn() {
  printf '%s%s%s\n' "$C_YELLOW" "$1" "$C_RESET"
}

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# Central input: pulls from the answer file when one is given, otherwise reads
# from stdin. Sets LAST_FROM_FILE so callers can avoid endless loops on invalid
# file input. On stdin EOF the input is treated like answer-file input (falls
# back to defaults instead of looping forever). Result in REPLY_ANSWER.
read_answer() {
  local prompt="$1"
  if [ "$HAVE_ANSWER_FILE" = "1" ]; then
    LAST_FROM_FILE=1
    local val=''
    if [ "$ANSWER_INDEX" -lt "$ANSWER_COUNT" ]; then
      val="${ANSWERS[$ANSWER_INDEX]}"
      ANSWER_INDEX=$((ANSWER_INDEX + 1))
    fi
    printf '%s: %s\n' "$prompt" "$val"
    REPLY_ANSWER="$val"
    return 0
  fi
  LAST_FROM_FILE=0
  printf '%s: ' "$prompt"
  if ! IFS= read -r REPLY_ANSWER; then
    REPLY_ANSWER=''
    LAST_FROM_FILE=1
    printf '\n'
  fi
}

# Numbered menu over the global OPTS array. Result (1-based) in CHOICE.
# Re-asks on invalid input; with an answer file, invalid input falls back to
# the default (no endless loop).
ask_choice() {
  local question="$1"
  local default="$2"
  local explain="${3:-}"
  echo ""
  if [ -n "$explain" ]; then write_note "$explain"; fi
  printf '%s%s%s\n' "$C_WHITE" "$question" "$C_RESET"
  local i=1 opt
  for opt in "${OPTS[@]}"; do
    printf '  %d) %s\n' "$i" "$opt"
    i=$((i + 1))
  done
  local raw
  while true; do
    read_answer "  $(T choice) [$default]"
    raw="$(trim "$REPLY_ANSWER")"
    if [ -z "$raw" ]; then
      CHOICE="$default"
      return 0
    fi
    case "$raw" in
      *[!0-9]*) : ;;
      *)
        if [ "$raw" -ge 1 ] && [ "$raw" -le "${#OPTS[@]}" ]; then
          CHOICE="$raw"
          return 0
        fi
        ;;
    esac
    if [ "$LAST_FROM_FILE" = "1" ]; then
      write_warn "$(printf "$(T invalid_num_file)" "${#OPTS[@]}" "$default")"
      CHOICE="$default"
      return 0
    fi
    write_warn "$(printf "$(T invalid_num)" "${#OPTS[@]}")"
  done
}

# Free-text question. minlen 0 = optional. With an answer file, too-short input
# falls back to the default (or is accepted as-is when no default exists).
# Result in TEXT.
ask_text() {
  local question="$1"
  local default="${2:-}"
  local minlen="${3:-0}"
  local retryhint="${4:-}"
  local explain="${5:-}"
  echo ""
  if [ -n "$explain" ]; then write_note "$explain"; fi
  printf '%s%s%s\n' "$C_WHITE" "$question" "$C_RESET"
  local suffix=''
  if [ -n "$default" ]; then suffix=" [$default]"; fi
  local raw
  while true; do
    read_answer "  >$suffix"
    raw="$(trim "$REPLY_ANSWER")"
    if [ "${#raw}" -eq 0 ]; then
      if [ -n "$default" ]; then TEXT="$default"; return 0; fi
      if [ "$minlen" -eq 0 ]; then TEXT=''; return 0; fi
    fi
    if [ "${#raw}" -ge "$minlen" ] && [ "${#raw}" -gt 0 ]; then
      TEXT="$raw"
      return 0
    fi
    if [ "$LAST_FROM_FILE" = "1" ]; then
      if [ "${#raw}" -gt 0 ]; then TEXT="$raw"; return 0; fi
      if [ -n "$default" ]; then TEXT="$default"; return 0; fi
      TEXT=''
      return 0
    fi
    if [ -n "$retryhint" ]; then write_warn "$retryhint"; else write_warn "$(T too_short_generic)"; fi
  done
}

# Yes/no question. Accepts j/ja/y/yes/n/nein/no (case-insensitive),
# Enter = default. defaultyes: 1 = yes, 0 = no. Result in YESNO (1/0).
ask_yesno() {
  local question="$1"
  local defaultyes="$2"
  local explain="${3:-}"
  echo ""
  if [ -n "$explain" ]; then write_note "$explain"; fi
  local suffix
  if [ "$defaultyes" = "1" ]; then suffix="$(T yn_default_yes)"; else suffix="$(T yn_default_no)"; fi
  local raw
  while true; do
    read_answer "$question $suffix"
    raw="$(trim "$REPLY_ANSWER")"
    raw="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]')"
    case "$raw" in
      '') YESNO="$defaultyes"; return 0 ;;
      j|ja|y|yes) YESNO=1; return 0 ;;
      n|nein|no) YESNO=0; return 0 ;;
    esac
    if [ "$LAST_FROM_FILE" = "1" ]; then
      YESNO="$defaultyes"
      return 0
    fi
    write_warn "$(T invalid_yn)"
  done
}

# Copies a file to <name>.backup-<timestamp> before it gets overwritten.
backup_file() {
  local p="$1"
  if [ -e "$p" ]; then
    local b="$p.backup-$TIMESTAMP"
    cp "$p" "$b"
    write_step "$(printf "$(T backed_up)" "$p" "$b")"
  fi
}

ensure_dir() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
  fi
}

# Builds a file-safe slug: lowercase, umlauts transliterated,
# spaces to hyphens, only [a-z0-9-].
new_slug() {
  local s="$1"
  s="${s//Ä/ae}"; s="${s//Ö/oe}"; s="${s//Ü/ue}"
  s="${s//ä/ae}"; s="${s//ö/oe}"; s="${s//ü/ue}"; s="${s//ß/ss}"
  s="$(printf '%s' "$s" | tr '[:upper:]' '[:lower:]')"
  s="$(printf '%s' "$s" | sed -e 's/[[:space:]][[:space:]]*/-/g' -e 's/[^a-z0-9-]//g' -e 's/--*/-/g' -e 's/^-*//' -e 's/-*$//')"
  printf '%s' "$s"
}

# Question header: "Frage N von 20" / "Question N of 20"
show_qheader() {
  echo ""
  printf '%s--- %s ---%s\n' "$C_CYAN" "$(printf "$(T q_of)" "$1")" "$C_RESET"
}

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

bool_json() {
  if [ "$1" = "1" ]; then printf 'true'; else printf 'false'; fi
}

# ── Texts (DE / EN) ───────────────────────────────────────────────────────────
# Format strings use %s (printf). Texts match the Windows wizard (setup.ps1).

UI_LANG='en'

T() {
  local k="$1"
  if [ "$UI_LANG" = "de" ]; then
    case "$k" in
      choice)            printf '%s' 'Auswahl' ;;
      invalid_num)       printf '%s' 'Bitte gib eine Zahl zwischen 1 und %s ein.' ;;
      invalid_num_file)  printf '%s' 'Ungueltige Antwort in der Answer-Datei (erlaubt: 1-%s) - Standard %s wird verwendet.' ;;
      invalid_yn)        printf '%s' 'Bitte antworte mit j (ja) oder n (nein).' ;;
      too_short_generic) printf '%s' 'Bitte gib etwas mehr Text ein.' ;;
      yn_default_yes)    printf '%s' '[J/n]' ;;
      yn_default_no)     printf '%s' '[j/N]' ;;
      q_of)              printf '%s' 'Frage %s von 22' ;;
      backed_up)         printf '%s' 'Backup: %s -> %s' ;;

      f2_q) printf '%s' 'Wie soll Claude dich nennen?' ;;
      f2_x) printf '%s' 'Der Name landet oben in deiner Konfiguration. Vorname reicht voellig.' ;;
      f2_r) printf '%s' 'Bitte gib mindestens 2 Zeichen ein, z. B. "Alex".' ;;

      f3_q) printf '%s' 'Wie viel Erfahrung hast du mit Claude Code?' ;;
      f3_x) printf '%s' 'Ehrlich antworten lohnt sich: Als Anfaenger erklaert Claude dir mehr und fragt oefter nach, bevor er etwas Kompliziertes tut.' ;;

      f4_q) printf '%s' 'Was hast du mit Claude vor? Beschreib es in 1-3 Saetzen.' ;;
      f4_x) printf '%s' 'z. B. "FiveM-Scripts fuer meinen Server bauen", "eine Web-App entwickeln", "Python lernen". Claude richtet sich danach und vergisst es nicht.' ;;
      f4_r) printf '%s' 'Beschreib es in einem Satz, z. B.: "Ich will eine kleine Web-App fuer meinen Verein bauen."' ;;

      f5_q) printf '%s' 'Was ist dein Haupt-Arbeitsgebiet?' ;;
      f5_x) printf '%s' 'Danach richtet sich, welche Extra-Regeln und fertigen Arbeitsanleitungen (Skills) Claude bekommt.' ;;

      f6_q) printf '%s' 'Mit welchen Programmiersprachen/Technologien arbeitest du? Kommagetrennt.' ;;
      f6_x) printf '%s' 'z. B. "JavaScript, React" oder "Python". Wenn du es nicht weisst, drueck einfach Enter - Claude findet es beim Arbeiten heraus.' ;;
      f6_d) printf '%s' 'weiss ich noch nicht' ;;

      f7_found) printf '%s' 'Ich habe nachgesehen: Du nutzt gerade %s. Stimmt das?' ;;
      f7_found_x) printf '%s' 'Claude gibt es in mehreren Modellen (von schnell und guenstig bis maximal schlau). Ich habe in deinen Claude-Code-Einstellungen nachgesehen, welches du nutzt.' ;;
      f7_x)     printf '%s' 'Claude gibt es in mehreren Modellen - von schnell und guenstig (Haiku) bis maximal schlau (Opus/Fable). Wenn du es nicht weisst: Starte Claude Code und tipp /model - dann siehst du es. Du kannst auch einfach "Weiss nicht" waehlen.' ;;
      f7_q)     printf '%s' 'Welches Claude-Modell nutzt du?' ;;

      f8_q) printf '%s' 'Wie bezahlst du Claude?' ;;
      f8_x) printf '%s' 'Bei Pro ist das Kontingent kleiner - dann stellt Claude sich sparsamer ein.' ;;

      f9_q) printf '%s' 'Wie sparsam soll Claude mit Tokens umgehen?' ;;
      f9_x) printf '%s' 'Tokens sind Claudes "Verbrauchseinheit". Sparsam = Claude liest gezielter und fasst kuerzer zusammen.' ;;

      f10_q) printf '%s' 'Wie soll Claude planen?' ;;
      f10_x) printf '%s' 'Bei groesseren Aufgaben lohnt ein kurzer Plan, bevor Code entsteht.' ;;

      f11_q) printf '%s' 'Welchen Code-Style soll Claude schreiben?' ;;
      f11_x) printf '%s' 'Produktionsreif heisst: saubere Fehlerbehandlung, Tests, konsistente Muster.' ;;

      f12_q) printf '%s' 'Wann soll Claude Tests schreiben?' ;;
      f12_x) printf '%s' 'Tests sichern ab, dass Aenderungen nichts kaputt machen.' ;;

      f13_q) printf '%s' 'Wie streng soll Claude bei Sicherheit sein?' ;;
      f13_x) printf '%s' 'Baust du etwas mit Login, Bezahlung oder Nutzerdaten? Dann waehl mindestens "Streng".' ;;

      f14_q)    printf '%s' 'FiveM-Modul aktivieren?' ;;
      f14_x)    printf '%s' 'FiveM ist eine Mod-Plattform fuer GTA V. Nur relevant, wenn du dafuer Scripts baust.' ;;
      f14_skip) printf '%s' 'FiveM-Modul wird automatisch aktiviert, weil dein Haupt-Arbeitsgebiet FiveM/Spiele-Scripts ist.' ;;

      f15_q) printf '%s' 'Marketing-Modul aktivieren?' ;;
      f15_x) printf '%s' 'Fuegt Schreibregeln fuer Marketing- und Verkaufstexte hinzu.' ;;

      f16_q) printf '%s' 'Wie soll Claude mit dir umgehen?' ;;
      f16_x) printf '%s' 'Option 1 heisst: Claude sagt dir ehrlich, wenn ein Plan Probleme machen wird, und schlaegt Besseres vor.' ;;

      f17_q) printf '%s' 'Obsidian Master Brain einrichten?' ;;
      f17_x) printf '%s' 'Das Master Brain ist Claudes Langzeitgedaechtnis: ein Ordner mit Notizen, in dem Claude Projekte, Entscheidungen und Wissen ueber eure Zusammenarbeit speichert - ueber Sessions hinweg. Obsidian (obsidian.md, kostenlos) ist eine App, die diese Notizen schoen anzeigt und verlinkt. Das Gedaechtnis funktioniert aber auch ohne die App - es sind normale Textdateien.' ;;

      f17a_q)    printf '%s' 'Hast du Obsidian schon installiert?' ;;
      f17a_how)  printf '%s' 'So pruefst du das: Such im Startmenue/Programme nach "Obsidian".' ;;
      f17a_note) printf '%s' 'Kein Problem - ich lege das Gedaechtnis trotzdem an. Obsidian kannst du spaeter von https://obsidian.md installieren und den Ordner als Vault oeffnen.' ;;

      f17b_q)      printf '%s' 'Wo soll das Gedaechtnis (der Vault) liegen?' ;;
      f17b_x)      printf '%s' 'Enter uebernimmt den Vorschlag. Der Ordner wird angelegt, falls er fehlt.' ;;
      f17b_exists) printf '%s' 'Dieser Ordner existiert schon und ist nicht leer. Was tun?' ;;

      f18_q) printf '%s' 'Woran willst du als Erstes arbeiten? Kurzer Name reicht (Enter = ueberspringen).' ;;
      f18_x) printf '%s' 'z. B. "mein-server" oder "shop-website". Claude legt dafuer eine Projekt-Notiz im Gedaechtnis an.' ;;

      f19_q) printf '%s' 'Soll Claude dich ueber Brain-Updates informieren?' ;;
      f19_x) printf '%s' 'Einmal am Tag prueft ein Mini-Skript beim Start, ob es eine neue Brain-Version auf GitHub gibt (eine einzige kleine Anfrage, keine Daten von dir werden gesendet). Gibt es eine, sagt Claude dir Bescheid und du kannst mit /brain-update aktualisieren.' ;;

      f20_q) printf '%s' 'Brain-Skills installieren?' ;;
      f20_x) printf '%s' 'Skills sind fertige Arbeitsanleitungen fuer Claude (z. B. ein Sicherheits-Check). Reine Textdateien, fuehren nichts von selbst aus.' ;;

      f21_q) printf '%s' 'Codex und Antigravity mit einbinden?' ;;
      f21_x) printf '%s' 'Du kannst neben Claude noch zwei weitere KI-Kommandozeilen nutzen: Codex (von OpenAI) und Antigravity (von Google). Beide laufen ueber dein jeweiliges Abo - es entstehen KEINE zusaetzlichen Kosten und du brauchst keinen API-Schluessel. Claude bleibt der Chef und entscheidet, was die beiden duerfen. Wenn eines der Programme nicht installiert ist, wird es einfach uebersprungen.' ;;
      f21_none) printf '%s' 'Weder Codex noch Antigravity gefunden - Frage wird uebersprungen.' ;;

      f22_q) printf '%s' 'Bestehende Konfiguration komplett neu aufbauen?' ;;
      f22_x) printf '%s' 'Wenn du schon eine CLAUDE.md hast, kann das Setup sie entweder ergaenzen oder komplett neu schreiben. Neu schreiben ist sauberer, verliert aber alles Selbstgeschriebene. Ich sehe gleich nach, was bei dir liegt, und sage dir ehrlich, was sinnvoller ist. In beiden Faellen wird vorher eine datierte Sicherung angelegt - es geht nie etwas verloren.' ;;
      f22_analyzing) printf '%s' 'Ich sehe mir deine bestehende Konfiguration an ...' ;;
      f22_rec_reset) printf '%s' 'Meine Empfehlung: Neu aufbauen. Es geht nichts Wertvolles verloren.' ;;
      f22_rec_merge) printf '%s' 'Meine Empfehlung: BEHALTEN und ergaenzen. Du hast selbstgeschriebene Inhalte, die beim Neuaufbau verloren gingen.' ;;
      f22_rec_review) printf '%s' 'Kein klarer Fall. Sieh dir die Datei selbst an, bevor du entscheidest.' ;;
      f22_ask) printf '%s' 'Trotzdem komplett neu aufbauen?' ;;

      sum_trio)  printf '%s' 'Codex + Antigravity' ;;
      sum_reset) printf '%s' 'Konfiguration neu' ;;
      wr_commands) printf '%s' 'Befehle installiert: %s' ;;
      wr_trio)     printf '%s' 'Trio eingerichtet - Claude ist die Genehmigungsinstanz' ;;
      wr_trio_skip) printf '%s' 'Trio uebersprungen' ;;
      wr_trio_fail) printf '%s' 'Trio-Einrichtung meldete einen Fehler - siehe Ausgabe oben' ;;

      sum_title)    printf '%s' 'Zusammenfassung deiner Antworten' ;;
      sum_confirm)  printf '%s' 'Passt das?' ;;
      sum_abort)    printf '%s' 'Alles klar - es wurde nichts geschrieben. Starte das Setup einfach neu, wenn du bereit bist.' ;;
      sum_name)     printf '%s' 'Name' ;;
      sum_lang)     printf '%s' 'Sprache' ;;
      sum_exp)      printf '%s' 'Erfahrung' ;;
      sum_goals)    printf '%s' 'Ziele' ;;
      sum_work)     printf '%s' 'Arbeitsgebiet' ;;
      sum_stacks)   printf '%s' 'Tech-Stacks' ;;
      sum_model)    printf '%s' 'Modell' ;;
      sum_plan)     printf '%s' 'Abo/Plan' ;;
      sum_token)    printf '%s' 'Token-Strategie' ;;
      sum_planning) printf '%s' 'Planung' ;;
      sum_style)    printf '%s' 'Code-Style' ;;
      sum_testing)  printf '%s' 'Testing' ;;
      sum_security) printf '%s' 'Security-Level' ;;
      sum_fivem)    printf '%s' 'FiveM-Modul' ;;
      sum_mkt)      printf '%s' 'Marketing-Modul' ;;
      sum_partner)  printf '%s' 'Umgang' ;;
      sum_vault)    printf '%s' 'Master Brain (Vault)' ;;
      sum_project)  printf '%s' 'Erstes Projekt' ;;
      sum_update)   printf '%s' 'Update-Benachrichtigung' ;;
      sum_skills)   printf '%s' 'Skills installieren' ;;
      sum_yes)      printf '%s' 'ja' ;;
      sum_no)       printf '%s' 'nein' ;;
      sum_none)     printf '%s' '(keins)' ;;
      sum_disabled) printf '%s' 'deaktiviert' ;;

      mig_info) printf '%s' 'Hinweis: Es existiert noch ein CLAUDE.md aus Version 1 an: %s. Die neue Version liegt unter ~/.claude/CLAUDE.md. Zwei Dateien koennen sich widersprechen.' ;;
      mig_q)    printf '%s' 'Soll ich die alte Datei sicher umbenennen (nichts wird geloescht)?' ;;
      mig_done) printf '%s' 'Alte Datei umbenannt nach: %s' ;;
      mig_warn) printf '%s' 'Achtung: Beide CLAUDE.md-Dateien bleiben bestehen und koennen sich widersprechen. Du kannst die alte Datei spaeter selbst entfernen.' ;;

      wr_writing)    printf '%s' 'Schreibe Dateien...' ;;
      wr_claudemd)   printf '%s' 'CLAUDE.md geschrieben: %s' ;;
      wr_skills)     printf '%s' 'Skill installiert: %s' ;;
      wr_skills_n)   printf '%s' '%s Skill(s) installiert nach: %s' ;;
      wr_skills_src) printf '%s' 'Warnung: skills-Ordner nicht gefunden (%s) - Skills uebersprungen.' ;;
      wr_vault_new)  printf '%s' 'Master Brain angelegt: %s' ;;
      wr_vault_add)  printf '%s' 'Bestehender Vault ergaenzt (nur fehlende Dateien): %s' ;;
      wr_vault_tpl)  printf '%s' 'Warnung: Vault-Vorlagen nicht gefunden (%s) - Vault uebersprungen.' ;;
      wr_config)     printf '%s' 'config.json geschrieben: %s' ;;
      wr_hook_ok)    printf '%s' 'Update-Hook in settings.json registriert.' ;;
      wr_hook_have)  printf '%s' 'Update-Hook ist bereits registriert - nichts geaendert.' ;;
      wr_hook_skip)  printf '%s' 'Update-Benachrichtigung deaktiviert - kein Hook registriert.' ;;
      wr_hook_fail)  printf '%s' 'settings.json konnte nicht automatisch angepasst werden (%s). Fuege diesen Eintrag manuell unter "hooks" ein:' ;;
      wr_brain)      printf '%s' 'Brain-Laufzeit installiert: %s' ;;

      dry_note) printf '%s' '[DRY RUN] Es wird nichts geschrieben.' ;;
      dry_done) printf '%s' '[DRY RUN] Fertig. Oben steht das generierte CLAUDE.md. Es wurde nichts geschrieben.' ;;

      fin_title)    printf '%s' 'Fertig! Claude Brain ist eingerichtet.' ;;
      fin_where)    printf '%s' 'Das liegt jetzt auf deinem Rechner:' ;;
      fin_claudemd) printf '%s' 'Deine Konfiguration:  %s' ;;
      fin_skills)   printf '%s' 'Brain-Skills:         %s' ;;
      fin_brain)    printf '%s' 'Brain-Laufzeit:       %s' ;;
      fin_vault)    printf '%s' 'Master Brain (Vault): %s' ;;
      fin_start1)   printf '%s' 'So geht es los: Oeffne ein Terminal und tipp einfach:' ;;
      fin_start2)   printf '%s' 'Dann kannst du direkt lostippen - Claude kennt jetzt deinen Namen, deine Ziele und deine Regeln.' ;;
      fin_update)   printf '%s' 'Updates: Claude sagt dir Bescheid, wenn es eine neue Brain-Version gibt. Aktualisieren geht mit /brain-update (oder manuell: %s).' ;;
      fin_obsidian) printf '%s' 'Tipp: Installiere Obsidian von https://obsidian.md und oeffne den Vault-Ordner darin, um dein Master Brain zu durchstoebern.' ;;
      *) printf '%s' "$k" ;;
    esac
  else
    case "$k" in
      choice)            printf '%s' 'Choice' ;;
      invalid_num)       printf '%s' 'Please enter a number between 1 and %s.' ;;
      invalid_num_file)  printf '%s' 'Invalid answer in answer file (allowed: 1-%s) - using default %s.' ;;
      invalid_yn)        printf '%s' 'Please answer y (yes) or n (no).' ;;
      too_short_generic) printf '%s' 'Please enter a bit more text.' ;;
      yn_default_yes)    printf '%s' '[Y/n]' ;;
      yn_default_no)     printf '%s' '[y/N]' ;;
      q_of)              printf '%s' 'Question %s of 22' ;;
      backed_up)         printf '%s' 'Backup: %s -> %s' ;;

      f2_q) printf '%s' 'What should Claude call you?' ;;
      f2_x) printf '%s' 'The name goes at the top of your configuration. First name is plenty.' ;;
      f2_r) printf '%s' 'Please enter at least 2 characters, e.g. "Alex".' ;;

      f3_q) printf '%s' 'How much experience do you have with Claude Code?' ;;
      f3_x) printf '%s' 'Honest answers pay off: as a beginner, Claude explains more and checks in before doing anything complicated.' ;;

      f4_q) printf '%s' 'What do you want to do with Claude? Describe it in 1-3 sentences.' ;;
      f4_x) printf '%s' 'e.g. "build FiveM scripts for my server", "develop a web app", "learn Python". Claude aligns with this and will not forget it.' ;;
      f4_r) printf '%s' 'Describe it in one sentence, e.g.: "I want to build a small web app for my club."' ;;

      f5_q) printf '%s' 'What is your main type of work?' ;;
      f5_x) printf '%s' 'This decides which extra rules and ready-made work instructions (skills) Claude gets.' ;;

      f6_q) printf '%s' 'Which programming languages/technologies do you work with? Comma-separated.' ;;
      f6_x) printf '%s' 'e.g. "JavaScript, React" or "Python". If you do not know yet, just press Enter - Claude will figure it out while working.' ;;
      f6_d) printf '%s' 'not sure yet' ;;

      f7_found) printf '%s' 'I checked: you are currently using %s. Is that right?' ;;
      f7_found_x) printf '%s' 'Claude comes in several models (from fast and cheap to maximally smart). I checked your Claude Code settings to see which one you use.' ;;
      f7_x)     printf '%s' 'Claude comes in several models - from fast and cheap (Haiku) to maximum intelligence (Opus/Fable). If you do not know: start Claude Code and type /model - it will show you. You can also just pick "I do not know".' ;;
      f7_q)     printf '%s' 'Which Claude model do you use?' ;;

      f8_q) printf '%s' 'How do you pay for Claude?' ;;
      f8_x) printf '%s' 'On Pro the quota is smaller - Claude will configure itself to be more frugal.' ;;

      f9_q) printf '%s' 'How frugal should Claude be with tokens?' ;;
      f9_x) printf '%s' 'Tokens are Claude'"'"'s "unit of consumption". Frugal = Claude reads more selectively and summarizes more briefly.' ;;

      f10_q) printf '%s' 'How should Claude plan?' ;;
      f10_x) printf '%s' 'For bigger tasks, a short plan before writing code pays off.' ;;

      f11_q) printf '%s' 'Which code style should Claude write?' ;;
      f11_x) printf '%s' 'Production-grade means: proper error handling, tests, consistent patterns.' ;;

      f12_q) printf '%s' 'When should Claude write tests?' ;;
      f12_x) printf '%s' 'Tests make sure changes do not break things.' ;;

      f13_q) printf '%s' 'How strict should Claude be about security?' ;;
      f13_x) printf '%s' 'Building something with login, payments, or user data? Then pick at least "Strict".' ;;

      f14_q)    printf '%s' 'Enable the FiveM module?' ;;
      f14_x)    printf '%s' 'FiveM is a modding platform for GTA V. Only relevant if you build scripts for it.' ;;
      f14_skip) printf '%s' 'FiveM module is enabled automatically because your main work type is FiveM/game scripts.' ;;

      f15_q) printf '%s' 'Enable the marketing module?' ;;
      f15_x) printf '%s' 'Adds writing rules for marketing and sales copy.' ;;

      f16_q) printf '%s' 'How should Claude interact with you?' ;;
      f16_x) printf '%s' 'Option 1 means: Claude tells you honestly when a plan will cause problems, and suggests something better.' ;;

      f17_q) printf '%s' 'Set up the Obsidian Master Brain?' ;;
      f17_x) printf '%s' 'The Master Brain is Claude'"'"'s long-term memory: a folder of notes where Claude stores projects, decisions, and knowledge about your collaboration - across sessions. Obsidian (obsidian.md, free) is an app that displays and links these notes nicely. The memory works without the app too - the notes are plain text files.' ;;

      f17a_q)    printf '%s' 'Do you already have Obsidian installed?' ;;
      f17a_how)  printf '%s' 'How to check: search your Start menu/applications for "Obsidian".' ;;
      f17a_note) printf '%s' 'No problem - I will create the memory anyway. You can install Obsidian later from https://obsidian.md and open the folder as a vault.' ;;

      f17b_q)      printf '%s' 'Where should the memory (the vault) live?' ;;
      f17b_x)      printf '%s' 'Press Enter to accept the suggestion. The folder is created if it does not exist.' ;;
      f17b_exists) printf '%s' 'That folder already exists and is not empty. What should we do?' ;;

      f18_q) printf '%s' 'What do you want to work on first? A short name is enough (Enter = skip).' ;;
      f18_x) printf '%s' 'e.g. "my-server" or "shop-website". Claude creates a project note for it in the memory.' ;;

      f19_q) printf '%s' 'Should Claude notify you about Brain updates?' ;;
      f19_x) printf '%s' 'Once a day, a tiny script checks at startup whether a new Brain version exists on GitHub (a single small request; none of your data is sent). If there is one, Claude tells you and you can update with /brain-update.' ;;

      f20_q) printf '%s' 'Install the Brain skills?' ;;
      f20_x) printf '%s' 'Skills are ready-made work instructions for Claude (e.g. a security check). Plain text files - they never execute anything by themselves.' ;;

      f21_q) printf '%s' 'Wire in Codex and Antigravity?' ;;
      f21_x) printf '%s' 'Alongside Claude you can use two more AI command lines: Codex (OpenAI) and Antigravity (Google). Both bill through your existing subscription - there are NO extra costs and no API key is needed. Claude stays in charge and decides what the other two are allowed to do. If a tool is not installed it is simply skipped.' ;;
      f21_none) printf '%s' 'Neither Codex nor Antigravity found - skipping this question.' ;;

      f22_q) printf '%s' 'Rebuild an existing configuration from scratch?' ;;
      f22_x) printf '%s' 'If you already have a CLAUDE.md, setup can either extend it or rewrite it completely. Rewriting is cleaner but loses anything you wrote yourself. I will look at what you have and tell you honestly which makes more sense. Either way a timestamped backup is written first - nothing is ever lost.' ;;
      f22_analyzing) printf '%s' 'Looking at your existing configuration ...' ;;
      f22_rec_reset) printf '%s' 'My recommendation: rebuild. Nothing of value is lost.' ;;
      f22_rec_merge) printf '%s' 'My recommendation: KEEP and extend. You have handwritten content that a rebuild would destroy.' ;;
      f22_rec_review) printf '%s' 'No clear call. Read the file yourself before deciding.' ;;
      f22_ask) printf '%s' 'Rebuild completely anyway?' ;;

      sum_trio)  printf '%s' 'Codex + Antigravity' ;;
      sum_reset) printf '%s' 'Rebuild config' ;;
      wr_commands) printf '%s' 'Commands installed: %s' ;;
      wr_trio)     printf '%s' 'Trio wired up - Claude is the approving authority' ;;
      wr_trio_skip) printf '%s' 'Trio skipped' ;;
      wr_trio_fail) printf '%s' 'Trio setup reported an error - see the output above' ;;

      sum_title)    printf '%s' 'Summary of your answers' ;;
      sum_confirm)  printf '%s' 'Does this look right?' ;;
      sum_abort)    printf '%s' 'All good - nothing was written. Just restart the setup when you are ready.' ;;
      sum_name)     printf '%s' 'Name' ;;
      sum_lang)     printf '%s' 'Language' ;;
      sum_exp)      printf '%s' 'Experience' ;;
      sum_goals)    printf '%s' 'Goals' ;;
      sum_work)     printf '%s' 'Work type' ;;
      sum_stacks)   printf '%s' 'Tech stacks' ;;
      sum_model)    printf '%s' 'Model' ;;
      sum_plan)     printf '%s' 'Plan' ;;
      sum_token)    printf '%s' 'Token strategy' ;;
      sum_planning) printf '%s' 'Planning' ;;
      sum_style)    printf '%s' 'Code style' ;;
      sum_testing)  printf '%s' 'Testing' ;;
      sum_security) printf '%s' 'Security level' ;;
      sum_fivem)    printf '%s' 'FiveM module' ;;
      sum_mkt)      printf '%s' 'Marketing module' ;;
      sum_partner)  printf '%s' 'Interaction' ;;
      sum_vault)    printf '%s' 'Master Brain (vault)' ;;
      sum_project)  printf '%s' 'First project' ;;
      sum_update)   printf '%s' 'Update notifications' ;;
      sum_skills)   printf '%s' 'Install skills' ;;
      sum_yes)      printf '%s' 'yes' ;;
      sum_no)       printf '%s' 'no' ;;
      sum_none)     printf '%s' '(none)' ;;
      sum_disabled) printf '%s' 'disabled' ;;

      mig_info) printf '%s' 'Note: a CLAUDE.md from version 1 still exists at: %s. The new version lives at ~/.claude/CLAUDE.md. Two files can contradict each other.' ;;
      mig_q)    printf '%s' 'Should I safely rename the old file (nothing gets deleted)?' ;;
      mig_done) printf '%s' 'Old file renamed to: %s' ;;
      mig_warn) printf '%s' 'Warning: both CLAUDE.md files remain and may contradict each other. You can remove the old file yourself later.' ;;

      wr_writing)    printf '%s' 'Writing files...' ;;
      wr_claudemd)   printf '%s' 'CLAUDE.md written: %s' ;;
      wr_skills)     printf '%s' 'Installed skill: %s' ;;
      wr_skills_n)   printf '%s' '%s skill(s) installed to: %s' ;;
      wr_skills_src) printf '%s' 'Warning: skills folder not found (%s) - skipping skills.' ;;
      wr_vault_new)  printf '%s' 'Master Brain created: %s' ;;
      wr_vault_add)  printf '%s' 'Existing vault extended (missing files only): %s' ;;
      wr_vault_tpl)  printf '%s' 'Warning: vault templates not found (%s) - skipping vault.' ;;
      wr_config)     printf '%s' 'config.json written: %s' ;;
      wr_hook_ok)    printf '%s' 'Update hook registered in settings.json.' ;;
      wr_hook_have)  printf '%s' 'Update hook already registered - nothing changed.' ;;
      wr_hook_skip)  printf '%s' 'Update notifications disabled - no hook registered.' ;;
      wr_hook_fail)  printf '%s' 'settings.json could not be updated automatically (%s). Add this entry manually under "hooks":' ;;
      wr_brain)      printf '%s' 'Brain runtime installed: %s' ;;

      dry_note) printf '%s' '[DRY RUN] Nothing will be written.' ;;
      dry_done) printf '%s' '[DRY RUN] Done. Above is the generated CLAUDE.md. Nothing was written.' ;;

      fin_title)    printf '%s' 'Done! Claude Brain is set up.' ;;
      fin_where)    printf '%s' 'This is now on your machine:' ;;
      fin_claudemd) printf '%s' 'Your configuration:   %s' ;;
      fin_skills)   printf '%s' 'Brain skills:         %s' ;;
      fin_brain)    printf '%s' 'Brain runtime:        %s' ;;
      fin_vault)    printf '%s' 'Master Brain (vault): %s' ;;
      fin_start1)   printf '%s' 'Getting started: open a terminal and simply type:' ;;
      fin_start2)   printf '%s' 'Then just start typing - Claude now knows your name, your goals, and your rules.' ;;
      fin_update)   printf '%s' 'Updates: Claude will tell you when a new Brain version is available. Update with /brain-update (or manually: %s).' ;;
      fin_obsidian) printf '%s' 'Tip: install Obsidian from https://obsidian.md and open the vault folder in it to browse your Master Brain.' ;;
      *) printf '%s' "$k" ;;
    esac
  fi
}

# Option lists per question (bash 3 compatible: sets the global OPTS array).
set_opts() {
  if [ "$UI_LANG" = "de" ]; then
    case "$1" in
      f3_o)   OPTS=('Anfaenger - ich fange gerade erst an' 'Fortgeschritten - ich nutze es regelmaessig' 'Profi - ich kenne Skills, Agents und Hooks') ;;
      f5_o)   OPTS=('Allgemein' 'Web-Frontend' 'Backend/APIs' 'Full-Stack' 'FiveM/Spiele-Scripts' 'DevOps' 'Daten/Python' 'Marketing/Texte') ;;
      f7_o)   OPTS=('Haiku (schnell und guenstig)' 'Sonnet (Standard)' 'Opus (sehr stark)' 'Fable (Spitzenmodell)' 'Weiss ich nicht') ;;
      f8_o)   OPTS=('Claude Pro (ca. 20 Euro/Monat)' 'Claude Max' 'API-Guthaben' 'Weiss ich nicht') ;;
      f9_o)   OPTS=('Konservativ (Qualitaet vor Sparsamkeit)' 'Ausgewogen' 'Aggressiv (maximal sparsam)') ;;
      f10_o)  OPTS=('Automatisch planen bei groesseren Aufgaben (empfohlen)' 'Vorher fragen' 'Minimal planen') ;;
      f11_o)  OPTS=('Einfach (kleine private Skripte)' 'Produktionsreif (empfohlen)' 'Streng' 'Architektur-fokussiert') ;;
      f12_o)  OPTS=('Immer Tests' 'Nur bei riskanten/komplexen Aenderungen (empfohlen)' 'Erst fragen') ;;
      f13_o)  OPTS=('Standard' 'Streng' 'Sehr streng') ;;
      f16_o)  OPTS=('Partner mit eigener Meinung - widerspricht, wenn etwas keine gute Idee ist (empfohlen)' 'Zurueckhaltend - macht einfach, was du sagst') ;;
      f17a_o) OPTS=('Ja' 'Nein' 'Weiss ich nicht') ;;
      f17b_o) OPTS=('Als bestehenden Vault weiterverwenden (nur fehlende Dateien ergaenzen, NICHTS ueberschreiben)' 'Anderen Pfad waehlen') ;;
    esac
  else
    case "$1" in
      f3_o)   OPTS=('Beginner - I am just getting started' 'Intermediate - I use it regularly' 'Pro - I know skills, agents, and hooks') ;;
      f5_o)   OPTS=('General' 'Web frontend' 'Backend/APIs' 'Full-stack' 'FiveM/game scripts' 'DevOps' 'Data/Python' 'Marketing/copy') ;;
      f7_o)   OPTS=('Haiku (fast and cheap)' 'Sonnet (standard)' 'Opus (very strong)' 'Fable (top model)' 'I do not know') ;;
      f8_o)   OPTS=('Claude Pro (about 20 EUR/month)' 'Claude Max' 'API credits' 'I do not know') ;;
      f9_o)   OPTS=('Conservative (quality over frugality)' 'Balanced' 'Aggressive (maximum savings)') ;;
      f10_o)  OPTS=('Plan automatically for bigger tasks (recommended)' 'Ask first' 'Minimal planning') ;;
      f11_o)  OPTS=('Simple (small private scripts)' 'Production-grade (recommended)' 'Strict' 'Architecture-focused') ;;
      f12_o)  OPTS=('Always write tests' 'Only for risky/complex changes (recommended)' 'Ask first') ;;
      f13_o)  OPTS=('Standard' 'Strict' 'Very strict') ;;
      f16_o)  OPTS=('Partner with its own opinion - pushes back when something is a bad idea (recommended)' 'Reserved - just does what you say') ;;
      f17a_o) OPTS=('Yes' 'No' 'I do not know') ;;
      f17b_o) OPTS=('Keep using it as an existing vault (only add missing files, overwrite NOTHING)' 'Choose a different path') ;;
    esac
  fi
}

# ── Questions (F1-F20) ────────────────────────────────────────────────────────

write_title "Claude Brain Setup $BRAIN_VERSION (Linux/macOS)"
echo "Interaktive Einrichtung / Interactive setup"
if [ "$DRY_RUN" = "1" ]; then
  write_warn '[DRY RUN] Es wird nichts geschrieben. / Nothing will be written.'
fi
echo ""

if [ ! -f "$TEMPLATE_FILE" ]; then
  printf '%sTemplate not found: %s%s\n' "$C_RED" "$TEMPLATE_FILE" "$C_RESET" >&2
  echo "Run this script from inside the claude-brain-setup folder." >&2
  exit 1
fi

# ── F1: Language ── (asked bilingually, before a language is set)
LANG_DEFAULT=2
case "${LANG:-}" in
  de*) LANG_DEFAULT=1 ;;
esac

show_qheader 1
OPTS=('Deutsch' 'English')
ask_choice 'Sprache / Language' "$LANG_DEFAULT" \
  'In welcher Sprache soll dieses Setup und spaeter Claude mit dir sprechen? / Which language should this setup and Claude use?'
F1="$CHOICE"
if [ "$F1" = "1" ]; then
  UI_LANG='de'
  LANGUAGE_NAME='German'
else
  UI_LANG='en'
  LANGUAGE_NAME='English'
fi

# ── F2: Name ──
show_qheader 2
ask_text "$(T f2_q)" '' 2 "$(T f2_r)" "$(T f2_x)"
USER_NAME="$TEXT"
if [ -z "$(trim "$USER_NAME")" ]; then USER_NAME='User'; fi

# ── F3: Experience ──
show_qheader 3
set_opts f3_o
ask_choice "$(T f3_q)" 1 "$(T f3_x)"
F3="$CHOICE"
_exp_keys=('beginner' 'intermediate' 'pro')
EXPERIENCE_KEY="${_exp_keys[$((F3 - 1))]}"
EXPERIENCE_LABEL="${OPTS[$((F3 - 1))]}"

# ── F4: Goals ──
show_qheader 4
ask_text "$(T f4_q)" '' 10 "$(T f4_r)" "$(T f4_x)"
GOALS="$TEXT"
if [ -z "$(trim "$GOALS")" ]; then GOALS='(not specified yet)'; fi

# ── F5: Main work type ──
show_qheader 5
set_opts f5_o
ask_choice "$(T f5_q)" 1 "$(T f5_x)"
F5="$CHOICE"
_work_types=('General software development' 'Web frontend' 'Backend/APIs' 'Full-stack' 'FiveM / game scripts' 'DevOps' 'Data / Python' 'Marketing / copywriting')
MAIN_WORK_TYPE="${_work_types[$((F5 - 1))]}"
MAIN_WORK_TYPE_LABEL="${OPTS[$((F5 - 1))]}"

# ── F6: Tech stacks ──
show_qheader 6
ask_text "$(T f6_q)" "$(T f6_d)" 0 '' "$(T f6_x)"
STACKS="$TEXT"

# ── F7: Model detection ──
show_qheader 7
MODEL_KEY='unknown'
MODEL_RAW=''
DETECTED=''

read_settings_model() {
  # Prints the "model" string from settings.json, or nothing.
  if [ ! -f "$SETTINGS_FILE" ]; then return 0; fi
  if command -v python3 >/dev/null 2>&1; then
    CB_SETTINGS="$SETTINGS_FILE" python3 -c '
import json, os
try:
    with open(os.environ["CB_SETTINGS"], "r", encoding="utf-8") as f:
        s = json.load(f)
    m = s.get("model")
    if isinstance(m, str) and m.strip():
        print(m)
except Exception:
    pass
' 2>/dev/null || true
  elif command -v jq >/dev/null 2>&1; then
    jq -r 'if (.model | type) == "string" then .model else empty end' "$SETTINGS_FILE" 2>/dev/null || true
  fi
}

RAW_MODEL="$(read_settings_model)"
RAW_MODEL="$(trim "$RAW_MODEL")"
if [ -n "$RAW_MODEL" ]; then
  _lower="$(printf '%s' "$RAW_MODEL" | tr '[:upper:]' '[:lower:]')"
  case "$_lower" in
    *fable*)  DETECTED='fable' ;;
    *opus*)   DETECTED='opus' ;;
    *sonnet*) DETECTED='sonnet' ;;
    *haiku*)  DETECTED='haiku' ;;
  esac
  if [ -n "$DETECTED" ]; then MODEL_RAW="$RAW_MODEL"; fi
fi

model_display_name() {
  case "$1" in
    haiku)  printf 'Haiku' ;;
    sonnet) printf 'Sonnet' ;;
    opus)   printf 'Opus' ;;
    fable)  printf 'Fable' ;;
  esac
}

MODEL_CONFIRMED=0
if [ -n "$DETECTED" ]; then
  ask_yesno "$(printf "$(T f7_found)" "$(model_display_name "$DETECTED")")" 1 "$(T f7_found_x)"
  if [ "$YESNO" = "1" ]; then
    MODEL_KEY="$DETECTED"
    MODEL_CONFIRMED=1
  fi
fi
if [ "$MODEL_CONFIRMED" = "0" ]; then
  set_opts f7_o
  ask_choice "$(T f7_q)" 5 "$(T f7_x)"
  F7="$CHOICE"
  _model_keys=('haiku' 'sonnet' 'opus' 'fable' 'unknown')
  MODEL_KEY="${_model_keys[$((F7 - 1))]}"
  if [ "$MODEL_KEY" != "$DETECTED" ]; then MODEL_RAW=''; fi
fi
if [ "$MODEL_KEY" = "unknown" ]; then
  set_opts f7_o
  MODEL_LABEL="${OPTS[4]}"
else
  MODEL_LABEL="$(model_display_name "$MODEL_KEY")"
fi

# ── F8: Plan tier ──
show_qheader 8
set_opts f8_o
ask_choice "$(T f8_q)" 4 "$(T f8_x)"
F8="$CHOICE"
_plan_keys=('pro' 'max' 'api' 'unknown')
PLAN_TIER="${_plan_keys[$((F8 - 1))]}"
PLAN_LABEL="${OPTS[$((F8 - 1))]}"

# ── F9: Token strategy (default depends on F8) ──
show_qheader 9
if [ "$PLAN_TIER" = "pro" ]; then TOKEN_DEFAULT=3; else TOKEN_DEFAULT=2; fi
set_opts f9_o
ask_choice "$(T f9_q)" "$TOKEN_DEFAULT" "$(T f9_x)"
F9="$CHOICE"
_token_keys=('Conservative' 'Balanced' 'Aggressive')
TOKEN_STRATEGY="${_token_keys[$((F9 - 1))]}"
TOKEN_LABEL="${OPTS[$((F9 - 1))]}"

# ── F10: Planning ──
show_qheader 10
set_opts f10_o
ask_choice "$(T f10_q)" 1 "$(T f10_x)"
PLANNING_KEY="$CHOICE"
PLANNING_LABEL="${OPTS[$((PLANNING_KEY - 1))]}"

# ── F11: Code style ──
show_qheader 11
set_opts f11_o
ask_choice "$(T f11_q)" 2 "$(T f11_x)"
CODE_STYLE_KEY="$CHOICE"
CODE_STYLE_LABEL="${OPTS[$((CODE_STYLE_KEY - 1))]}"

# ── F12: Testing ──
show_qheader 12
set_opts f12_o
ask_choice "$(T f12_q)" 2 "$(T f12_x)"
TESTING_KEY="$CHOICE"
TESTING_LABEL="${OPTS[$((TESTING_KEY - 1))]}"

# ── F13: Security level ──
show_qheader 13
set_opts f13_o
ask_choice "$(T f13_q)" 1 "$(T f13_x)"
F13="$CHOICE"
_sec_keys=('Standard' 'Strict' 'Very Strict')
SECURITY_LEVEL="${_sec_keys[$((F13 - 1))]}"
SECURITY_LABEL="${OPTS[$((F13 - 1))]}"

# ── F14: FiveM module (auto-yes if F5 = FiveM) ──
show_qheader 14
if [ "$F5" = "5" ]; then
  write_note "$(T f14_skip)"
  FIVEM_ENABLED=1
else
  ask_yesno "$(T f14_q)" 0 "$(T f14_x)"
  FIVEM_ENABLED="$YESNO"
fi

# ── F15: Marketing module ──
show_qheader 15
ask_yesno "$(T f15_q)" 0 "$(T f15_x)"
MARKETING_ENABLED="$YESNO"

# ── F16: Partner mode ──
show_qheader 16
set_opts f16_o
ask_choice "$(T f16_q)" 1 "$(T f16_x)"
PARTNER_MODE="$CHOICE"
PARTNER_LABEL="${OPTS[$((PARTNER_MODE - 1))]}"

# ── F17: Obsidian Master Brain ──
show_qheader 17
ask_yesno "$(T f17_q)" 1 "$(T f17_x)"
OBSIDIAN_ENABLED="$YESNO"
OBSIDIAN_APP_INSTALLED=0
VAULT_PATH=''
VAULT_REUSE=0

if [ "$OBSIDIAN_ENABLED" = "1" ]; then
  # F17a: app installed?
  set_opts f17a_o
  ask_choice "$(T f17a_q)" 3 ''
  F17A="$CHOICE"
  if [ "$F17A" = "1" ]; then
    OBSIDIAN_APP_INSTALLED=1
  else
    if [ "$F17A" = "3" ]; then write_note "$(T f17a_how)"; fi
    write_note "$(T f17a_note)"
  fi

  # F17b: vault path (loop until a usable path is chosen)
  VAULT_DEFAULT="$HOME_DIR/Documents/ClaudeBrainVault"
  VAULT_DONE=0
  while [ "$VAULT_DONE" = "0" ]; do
    ask_text "$(T f17b_q)" "$VAULT_DEFAULT" 0 '' "$(T f17b_x)"
    VAULT_PATH="$TEXT"
    case "$VAULT_PATH" in
      '~'*)
        _rest="${VAULT_PATH#\~}"
        while [ "${_rest#/}" != "$_rest" ]; do _rest="${_rest#/}"; done
        if [ -n "$_rest" ]; then
          VAULT_PATH="$HOME_DIR/$_rest"
        else
          VAULT_PATH="$HOME_DIR"
        fi
        ;;
    esac
    IS_NON_EMPTY=0
    if [ -d "$VAULT_PATH" ]; then
      if [ -n "$(ls -A "$VAULT_PATH" 2>/dev/null)" ]; then IS_NON_EMPTY=1; fi
    fi
    if [ "$IS_NON_EMPTY" = "1" ]; then
      set_opts f17b_o
      ask_choice "$(T f17b_exists)" 1 ''
      if [ "$CHOICE" = "1" ]; then
        VAULT_REUSE=1
        VAULT_DONE=1
      fi
      # option 2: loop and ask for another path
    else
      VAULT_DONE=1
    fi
  done
fi

# ── F18: First project ──
show_qheader 18
ask_text "$(T f18_q)" '' 0 '' "$(T f18_x)"
PROJECT_NAME="$TEXT"
PROJECT_SLUG=''
if [ -n "$(trim "$PROJECT_NAME")" ]; then
  PROJECT_SLUG="$(new_slug "$PROJECT_NAME")"
  if [ -z "$PROJECT_SLUG" ]; then PROJECT_SLUG='projekt-1'; fi
else
  PROJECT_NAME=''
fi

# ── F19: Update notifications ──
show_qheader 19
ask_yesno "$(T f19_q)" 1 "$(T f19_x)"
UPDATE_CHECK_ENABLED="$YESNO"

# ── F20: Install skills ──
show_qheader 20
ask_yesno "$(T f20_q)" 1 "$(T f20_x)"
INSTALL_SKILLS="$YESNO"

# ── F21: Trio (Codex + Antigravity) ──
#
# Only asked when at least one of the two is actually installed. Offering to
# wire up software the user does not have is noise, and a "yes" would silently
# do nothing.
detect_trio_tools() {
  TRIO_AGY=''
  TRIO_CODEX=''
  for c in     "${AGY_BIN:-}"     "${LOCALAPPDATA:-$HOME_DIR/AppData/Local}/agy/bin/agy.exe"     "$HOME_DIR/.local/bin/agy"     "/usr/local/bin/agy"; do
    if [ -n "$c" ] && [ -x "$c" ]; then TRIO_AGY="$c"; break; fi
  done
  for c in     "${APPDATA:-$HOME_DIR/AppData/Roaming}/npm/codex.cmd"     "$HOME_DIR/.local/bin/codex"     "/usr/local/bin/codex"     "/opt/homebrew/bin/codex"; do
    if [ -n "$c" ] && [ -x "$c" ]; then TRIO_CODEX="$c"; break; fi
  done
  command -v codex >/dev/null 2>&1 && [ -z "$TRIO_CODEX" ] && TRIO_CODEX="$(command -v codex)"
  [ -n "$TRIO_AGY" ] || [ -n "$TRIO_CODEX" ]
}

TRIO_ENABLED=0
show_qheader 21
if detect_trio_tools; then
  [ -n "$TRIO_AGY" ]   && write_step "Antigravity: $TRIO_AGY"
  [ -n "$TRIO_CODEX" ] && write_step "Codex: $TRIO_CODEX"
  ask_yesno "$(T f21_q)" 1 "$(T f21_x)"
  TRIO_ENABLED="$YESNO"
else
  write_note "$(T f21_none)"
fi

# ── F22: Rebuild existing configuration ──
#
# The analysis runs BEFORE the question. Offering "delete everything" without
# first checking what would be deleted is how people lose handwritten rules
# that were never in version control.
CONFIG_RESET=0
show_qheader 22
_analyzer="$PROJECT_ROOT/brain/trio/analyze-claude-md.mjs"
if [ -f "$_analyzer" ] && command -v node >/dev/null 2>&1; then
  write_step "$(T f22_analyzing)"
  echo ""
  if [ "$F1" = "1" ]; then node "$_analyzer" --lang de --home "$HOME_DIR"; else node "$_analyzer" --lang en --home "$HOME_DIR"; fi
  _rec="$(node "$_analyzer" --json --home "$HOME_DIR" 2>/dev/null | grep -m1 '"recommendation"' | cut -d'"' -f4)"
  case "$_rec" in
    reset)  write_step "$(T f22_rec_reset)" ;;
    merge)  write_warn "$(T f22_rec_merge)" ;;
    review) write_note "$(T f22_rec_review)" ;;
  esac
  echo ""
  # Default follows the analysis: only pre-select "yes" when a reset is safe.
  if [ "$_rec" = "reset" ] || [ "$_rec" = "fresh" ]; then _def=1; else _def=0; fi
  ask_yesno "$(T f22_ask)" "$_def" "$(T f22_x)"
  CONFIG_RESET="$YESNO"
else
  write_note "node not found - skipping configuration analysis."
fi

# ── Summary + confirmation ────────────────────────────────────────────────────

format_yesno() {
  if [ "$1" = "1" ]; then T sum_yes; else T sum_no; fi
}

sum_row() {
  printf '  %-24s %s\n' "$1:" "$2"
}

write_title "$(T sum_title)"
if [ "$F1" = "1" ]; then LANG_DISPLAY='Deutsch'; else LANG_DISPLAY='English'; fi
sum_row "$(T sum_name)"     "$USER_NAME"
sum_row "$(T sum_lang)"     "$LANG_DISPLAY"
sum_row "$(T sum_exp)"      "$EXPERIENCE_LABEL"
sum_row "$(T sum_goals)"    "$GOALS"
sum_row "$(T sum_work)"     "$MAIN_WORK_TYPE_LABEL"
sum_row "$(T sum_stacks)"   "$STACKS"
sum_row "$(T sum_model)"    "$MODEL_LABEL"
sum_row "$(T sum_plan)"     "$PLAN_LABEL"
sum_row "$(T sum_token)"    "$TOKEN_LABEL"
sum_row "$(T sum_planning)" "$PLANNING_LABEL"
sum_row "$(T sum_style)"    "$CODE_STYLE_LABEL"
sum_row "$(T sum_testing)"  "$TESTING_LABEL"
sum_row "$(T sum_security)" "$SECURITY_LABEL"
sum_row "$(T sum_fivem)"    "$(format_yesno "$FIVEM_ENABLED")"
sum_row "$(T sum_mkt)"      "$(format_yesno "$MARKETING_ENABLED")"
sum_row "$(T sum_partner)"  "$PARTNER_LABEL"
if [ "$OBSIDIAN_ENABLED" = "1" ]; then
  sum_row "$(T sum_vault)" "$VAULT_PATH"
else
  sum_row "$(T sum_vault)" "$(T sum_disabled)"
fi
if [ -n "$PROJECT_NAME" ]; then
  sum_row "$(T sum_project)" "$PROJECT_NAME"
else
  sum_row "$(T sum_project)" "$(T sum_none)"
fi
sum_row "$(T sum_update)" "$(format_yesno "$UPDATE_CHECK_ENABLED")"
sum_row "$(T sum_skills)" "$(format_yesno "$INSTALL_SKILLS")"
sum_row "$(T sum_trio)"   "$(format_yesno "$TRIO_ENABLED")"
sum_row "$(T sum_reset)"  "$(format_yesno "$CONFIG_RESET")"

ask_yesno "$(T sum_confirm)" 1
if [ "$YESNO" != "1" ]; then
  echo ""
  printf '%s\n' "$(T sum_abort)"
  exit 0
fi

# ── Generation (CLAUDE.md content blocks) ─────────────────────────────────────
# All generated CLAUDE.md content is English by design; the language directive
# controls the language Claude responds in.

# {{LANGUAGE_DIRECTIVE}}
if [ "$UI_LANG" = "de" ]; then
  LANGUAGE_DIRECTIVE='Antworte immer auf Deutsch. Code, Befehle und Fachbegriffe bleiben im Original.'
else
  LANGUAGE_DIRECTIVE=''
fi

# {{EXPERIENCE_SECTION}}
EXPERIENCE_SECTION=''
if [ "$EXPERIENCE_KEY" = "beginner" ]; then
  EXPERIENCE_SECTION="## Beginner Mode

$USER_NAME is new to Claude Code. Therefore:
- Explain each step in simple language before doing it.
- Ask before any risky or hard-to-reverse action.
- Suggest exactly ONE next step at a time - never a wall of options.
- When a technical term is unavoidable, add a one-line explanation."
fi

# {{MODEL_SECTION}} (Claude 5 family routing table)
ROUTING_TABLE='| Task | Model | Launch |
|---|---|---|
| Formatting, renaming, simple edits | Haiku | `claude --model haiku` |
| Standard development work | Sonnet | `claude --model sonnet` |
| Architecture, security, complex multi-file work | Opus | `claude --model opus` |
| Hardest problems, top-tier reasoning | Opus (1M context) | `claude --model opus[1m]` |

(Fable access depends on your plan.)'

case "$MODEL_KEY" in
  haiku)
    MODEL_SECTION="Current model: **Haiku**.

$ROUTING_TABLE

**Note:** For architecture, security, or multi-file work, start a session with a stronger model."
    ;;
  opus)
    MODEL_SECTION="Current model: **Opus**.

$ROUTING_TABLE

You are running a top-tier model - delegate mechanical bulk work to cheaper agent models (Haiku) where sensible."
    ;;
  fable)
    MODEL_SECTION="Current model: **Opus (1M context)**.

$ROUTING_TABLE

You are running a top-tier model - delegate mechanical bulk work to cheaper agent models (Haiku) where sensible."
    ;;
  sonnet)
    MODEL_SECTION="Current model: **Sonnet**.

$ROUTING_TABLE"
    ;;
  *)
    MODEL_SECTION="$ROUTING_TABLE

Tip: run \`/model\` inside Claude Code to see which model the current session uses."
    ;;
esac

# {{PLANNING_PREFERENCE}}
case "$PLANNING_KEY" in
  1) PLANNING_PREFERENCE='Always plan first when the task touches 3 or more files, changes a public API or database schema, involves auth/payments/user data, or has unclear scope. Wait for confirmation of the plan before writing code.' ;;
  2) PLANNING_PREFERENCE='Ask the user before creating a plan. Suggest planning when the task touches 3 or more files or has unclear scope.' ;;
  3) PLANNING_PREFERENCE='Keep plans minimal. Only create a written plan when the user explicitly asks for one.' ;;
esac

# {{FIRST_PROJECT_LINE}}
FIRST_PROJECT_LINE=''
if [ -n "$PROJECT_NAME" ]; then
  FIRST_PROJECT_LINE="**Current project:** $PROJECT_NAME"
  if [ "$OBSIDIAN_ENABLED" = "1" ]; then
    FIRST_PROJECT_LINE="$FIRST_PROJECT_LINE (hub note: \`projects/$PROJECT_SLUG.md\` in the vault)"
  fi
fi

# {{CODE_STYLE}}
case "$CODE_STYLE_KEY" in
  1) CODE_STYLE='Keep code simple and readable. Avoid over-engineering. Favour explicitness over abstraction.' ;;
  2) CODE_STYLE='Write production-grade code: proper error handling, consistent patterns, tests for new functionality. Functions under 50 lines. No nesting beyond 4 levels.' ;;
  3) CODE_STYLE='Strict conventions: full type safety, architectural patterns, no shortcuts. All edge cases handled. Comprehensive tests.' ;;
  4) CODE_STYLE='Architecture first: define module boundaries and interfaces before implementation. Full type safety where the language supports it. Document key design decisions. Proper error handling and tests throughout.' ;;
esac

# {{TESTING_PREFERENCE}}
case "$TESTING_KEY" in
  1) TESTING_PREFERENCE='Always write tests for new functionality. Do not mark a task done without tests.' ;;
  2) TESTING_PREFERENCE='Write tests for risky, complex, or user-facing changes. Skip tests for trivial edits, config changes, and doc updates.' ;;
  3) TESTING_PREFERENCE='Ask the user before writing tests. Do not add tests without being asked.' ;;
esac

# {{SECURITY_RULES}} / {{SECURITY_GATE}}
case "$SECURITY_LEVEL" in
  'Standard')
    SECURITY_RULES='- Never hardcode API keys, passwords, or tokens. Use environment variables.
- Never commit .env files or credentials.
- Validate user input at system boundaries.'
    SECURITY_GATE='- [ ] Security-sensitive changes reviewed with `/brain-security-review`'
    ;;
  'Strict')
    SECURITY_RULES='- Never hardcode any secret. Use environment variables or a secrets manager.
- Never commit .env files or credentials.
- Run `/brain-security-review` before any commit that touches auth, payments, user data, file system access, or external API calls.
- Validate all user input. Parameterize all SQL queries. Sanitize HTML output.
- Rate limit all user-facing endpoints.'
    SECURITY_GATE='- [ ] Security-sensitive changes reviewed with `/brain-security-review` before committing'
    ;;
  'Very Strict')
    SECURITY_RULES='- Never hardcode any secret under any circumstances.
- Run `/brain-security-review` before every commit that touches auth, payments, user data, file system, or external APIs. This is not optional.
- Validate all input at every boundary. No exceptions.
- All SQL queries parameterized. All HTML output sanitized.
- Rate limit all endpoints. CSRF protection on all state-changing forms.
- Error messages must not leak sensitive data or stack traces to users.'
    SECURITY_GATE='- [ ] `/brain-security-review` run and all issues addressed before committing'
    ;;
esac

# {{TOKEN_RULES}}
case "$TOKEN_STRATEGY" in
  'Conservative')
    TOKEN_RULES='- Search before reading. Use grep or find to locate code before reading full files.
- Issue multiple independent reads in one message, not sequentially.
- Summarise command output - do not paste raw long output.
- Create a handoff and start a fresh session when the conversation grows large.'
    ;;
  'Balanced')
    TOKEN_RULES='- Search before reading when the target is unclear.
- Batch independent operations in one message.
- Start a new session instead of resuming a very large one.'
    ;;
  'Aggressive')
    TOKEN_RULES='- Always search before reading any file.
- Batch all independent operations in a single message.
- Hard limit on session length: use `/brain-session-handoff` proactively before the session grows too large.
- Never paste raw command output. Always summarise.
- Do not load skills speculatively. One skill at a time, on demand only.'
    ;;
esac

# Orchestration is fixed at "Balanced" in V2 (no longer asked).
ORCHESTRATION_LEVEL='Balanced'
ORCHESTRATION_RULES='Use agents when work is genuinely parallel or needs specialisation. Do not spawn agents for single-file edits, quick questions, or config changes. Rule: if you can finish the task alone in under 15 minutes, skip agents.'

# {{TEAM_RULES}}
if [ "$PARTNER_MODE" = "1" ]; then
  TEAM_RULES="## Team Rules

- Claude is a partner with its own judgment, not a yes-man. Never agree just to please.
- Push back when a request is pointless, risky, or clearly worse than an obvious alternative - say why and propose the better way.
- If a prompt is too vague to finish the job well, ask for a sharper definition before writing code.
- Important decisions - architecture, public APIs, deletions - are made together.
- While working in $USER_NAME's code, keep an eye out for bugs beyond the immediate task; flag them, don't silently fix out-of-scope.
- Otherwise act autonomously: no permission-asking for reversible steps that follow from the task.
- ALWAYS ask before deleting files/data or any destructive, hard-to-reverse action - regardless of the active permission mode."
else
  TEAM_RULES='## Interaction Mode

- Execute requests as given; keep unsolicited opinions to a minimum.
- Exception: always warn before destructive or hard-to-reverse actions, and always ask before deleting files or data.'
fi

# {{OBSIDIAN_SECTION}}
if [ "$OBSIDIAN_ENABLED" = "1" ]; then
  OBSIDIAN_SECTION="## Obsidian Master Brain

Vault: \`$VAULT_PATH\` - Claude's cross-project memory. One vault for everything; wikilinks do not work across vaults. A new independent project gets a new NOTE in \`projects/\`, never a new vault. Related projects link to each other and share knowledge notes.

For every non-trivial task:
1. Session start: read the vault's \`CLAUDE.md\` + \`index.md\`, then the relevant \`projects/<name>.md\` hub note. Follow links from there - never scan the whole vault.
2. Durable insight -> atomic note in \`knowledge/\`, linked from a MOC or project hub. Decision -> \`decisions/YYYY-MM-DD-decision-<project>-<slug>.md\`.
3. End of a complex session: write \`sessions/YYYY-MM-DD-<project>.md\`, update the project hub and \`index.md\`.
4. New observations about $USER_NAME (working style, code style, preferences) go into \`me/\`.
5. The vault's own \`CLAUDE.md\` holds the full writing conventions - follow them."
else
  OBSIDIAN_SECTION='Note: the Obsidian Master Brain (persistent cross-project memory) is not set up. Re-run the Claude Brain setup wizard anytime to add it.'
fi

# {{UPDATE_SECTION}}
UPDATE_SECTION="## Brain Updates

- Installed Claude Brain version: $BRAIN_VERSION (see \`~/.claude/brain/VERSION\`).
"
if [ "$UPDATE_CHECK_ENABLED" = "1" ]; then
  UPDATE_SECTION="$UPDATE_SECTION- A SessionStart hook checks GitHub once a day for a newer version and reports it in the session.
"
else
  UPDATE_SECTION="$UPDATE_SECTION- Automatic update checks are disabled. Check manually when asked.
"
fi
UPDATE_SECTION="$UPDATE_SECTION- To update: run \`/brain-update\`, or manually: \`bash ~/.claude/brain/update.sh\`."

# {{MARKETING_SUPPORT}}
MARKETING_BLOCK=''
if [ "$MARKETING_ENABLED" = "1" ]; then
  MARKETING_BLOCK='## Marketing and Sales Support

When writing sales, marketing, or customer-facing copy:
- Write in clear, direct language. No corporate filler or AI-sounding bullet lists.
- Prefer flowing prose for short messages. Use lists only for 4+ parallel items.
- If no brand voice is defined, ask before writing.
- Useful skill: `/brain-marketing-support`.'
fi

# {{FIVEM_SUPPORT}}
FIVEM_BLOCK=''
if [ "$FIVEM_ENABLED" = "1" ]; then
  FIVEM_BLOCK='## FiveM Development

When working on FiveM scripts:
- Never use `Wait(0)` in permanent loops. Use adaptive wait based on distance checks.
- Server is authoritative. Validate all client events on the server. Never trust client data.
- Use ox_lib target zones instead of distance check loops with every-frame threads.
- NUI backgrounds must be transparent: `html, body { background: transparent !important; }`
- Animate only compositor-friendly properties: `transform` and `opacity`.
- Use statebags for state sync. Avoid event spam.
- Verify all natives at docs.fivem.net before using them. Never guess native names.
- Useful skill: `/brain-fivem-development`.'
fi

# {{SELECTED_SKILLS}}
if [ "$INSTALL_SKILLS" = "1" ]; then
  SELECTED_SKILLS='Bundled Brain skills:
- `/brain-core-workflow` - disciplined development workflow
- `/brain-token-discipline` - token-efficient working habits
- `/brain-session-handoff` - session handoff before model switch or end
- `/brain-security-review` - security checklist for code and repos
- `/brain-model-routing` - pick the right Claude model for the task
- `/brain-update` - check for and apply Claude Brain updates
- `/brain-karpathy-principles` - guardrails against common LLM coding mistakes
- `/brain-github-release` - prepare and publish GitHub releases
- `/brain-pr-review` - pull request review workflow
- `/brain-ruflo-orchestration` - multi-agent orchestration patterns
- `/brain-skill-authoring` - write new skills
- `/brain-cross-platform-setup` - project setup across Windows/Linux/macOS
- `/brain-marketing-support` - marketing and sales copy support
- `/brain-fivem-development` - FiveM script development'
else
  SELECTED_SKILLS='Bundled Brain skills are not installed. Install them anytime with `scripts/install.sh --skills-only` / `scripts\install.ps1 -SkillsOnly` from the claude-brain-setup folder.'
fi

# ── Fill the template ─────────────────────────────────────────────────────────

GENERATED_CLAUDE_MD=''

# Trio block for the generated CLAUDE.md. Empty when the user declined, so the
# whole section disappears instead of leaving an empty heading behind.
TRIO_SECTION=''
if [ "${TRIO_ENABLED:-0}" = "1" ]; then
  TRIO_SECTION="## The Trio (Codex + Antigravity)

Two more CLI agents can work on this machine: **Codex** (OpenAI) and
**Antigravity** (Google). Both bill through existing subscriptions - no API key,
no per-token cost.

**You are the approving authority.** Every tool call the others make passes
through \`~/.claude/brain/trio/broker.mjs\`, whose policy you maintain. Never grant
blanket permissions and never use \`--dangerously-skip-permissions\`.

Propose the trio when a task spans more than ~10 files, when genuinely
independent workstreams exist, or when a decision is hard enough that an
opposing view is worth the wait. Advise against it for projects under ~20 files,
projects without tests, or anything finishable alone in under 15 minutes.

\`\`\`bash
node ~/.claude/brain/trio/trio.mjs doctor
node ~/.claude/brain/trio/trio.mjs council \"question\"
\`\`\`

Type \`/CLIcombo\` to convert a project - it analyses first, then assigns roles.

See \`/brain-trio-orchestration\` and \`/brain-permission-broker\`."
fi

build_claude_md() {
  local content
  content="$(cat "$TEMPLATE_FILE"; printf 'x')"
  content="${content%x}"
  # Normalize to LF while building.
  content="${content//$'\r\n'/$'\n'}"

  # First replace all non-empty values, then remove entire lines that still
  # contain a placeholder whose value is empty (no blank-line leftovers).
  local ph
  ph='{{USER_NAME}}';           if [ -n "$USER_NAME" ];           then content="${content//"$ph"/$USER_NAME}"; fi
  ph='{{LANGUAGE_NAME}}';       if [ -n "$LANGUAGE_NAME" ];       then content="${content//"$ph"/$LANGUAGE_NAME}"; fi
  ph='{{LANGUAGE_DIRECTIVE}}';  if [ -n "$LANGUAGE_DIRECTIVE" ];  then content="${content//"$ph"/$LANGUAGE_DIRECTIVE}"; fi
  ph='{{GOALS}}';               if [ -n "$GOALS" ];               then content="${content//"$ph"/$GOALS}"; fi
  ph='{{EXPERIENCE_SECTION}}';  if [ -n "$EXPERIENCE_SECTION" ];  then content="${content//"$ph"/$EXPERIENCE_SECTION}"; fi
  ph='{{MODEL_SECTION}}';       if [ -n "$MODEL_SECTION" ];       then content="${content//"$ph"/$MODEL_SECTION}"; fi
  ph='{{PLANNING_PREFERENCE}}'; if [ -n "$PLANNING_PREFERENCE" ]; then content="${content//"$ph"/$PLANNING_PREFERENCE}"; fi
  ph='{{MAIN_WORK_TYPE}}';      if [ -n "$MAIN_WORK_TYPE" ];      then content="${content//"$ph"/$MAIN_WORK_TYPE}"; fi
  ph='{{PREFERRED_STACKS}}';    if [ -n "$STACKS" ];              then content="${content//"$ph"/$STACKS}"; fi
  ph='{{FIRST_PROJECT_LINE}}';  if [ -n "$FIRST_PROJECT_LINE" ];  then content="${content//"$ph"/$FIRST_PROJECT_LINE}"; fi
  ph='{{CODE_STYLE}}';          if [ -n "$CODE_STYLE" ];          then content="${content//"$ph"/$CODE_STYLE}"; fi
  ph='{{TESTING_PREFERENCE}}';  if [ -n "$TESTING_PREFERENCE" ];  then content="${content//"$ph"/$TESTING_PREFERENCE}"; fi
  ph='{{SECURITY_LEVEL}}';      if [ -n "$SECURITY_LEVEL" ];      then content="${content//"$ph"/$SECURITY_LEVEL}"; fi
  ph='{{SECURITY_RULES}}';      if [ -n "$SECURITY_RULES" ];      then content="${content//"$ph"/$SECURITY_RULES}"; fi
  ph='{{SECURITY_GATE}}';       if [ -n "$SECURITY_GATE" ];       then content="${content//"$ph"/$SECURITY_GATE}"; fi
  ph='{{TOKEN_STRATEGY}}';      if [ -n "$TOKEN_STRATEGY" ];      then content="${content//"$ph"/$TOKEN_STRATEGY}"; fi
  ph='{{TOKEN_RULES}}';         if [ -n "$TOKEN_RULES" ];         then content="${content//"$ph"/$TOKEN_RULES}"; fi
  ph='{{ORCHESTRATION_LEVEL}}'; if [ -n "$ORCHESTRATION_LEVEL" ]; then content="${content//"$ph"/$ORCHESTRATION_LEVEL}"; fi
  ph='{{ORCHESTRATION_RULES}}'; if [ -n "$ORCHESTRATION_RULES" ]; then content="${content//"$ph"/$ORCHESTRATION_RULES}"; fi
  ph='{{TEAM_RULES}}';          if [ -n "$TEAM_RULES" ];          then content="${content//"$ph"/$TEAM_RULES}"; fi
  ph='{{OBSIDIAN_SECTION}}';    if [ -n "$OBSIDIAN_SECTION" ];    then content="${content//"$ph"/$OBSIDIAN_SECTION}"; fi
  ph='{{UPDATE_SECTION}}';      if [ -n "$UPDATE_SECTION" ];      then content="${content//"$ph"/$UPDATE_SECTION}"; fi
  ph='{{MARKETING_SUPPORT}}';   if [ -n "$MARKETING_BLOCK" ];     then content="${content//"$ph"/$MARKETING_BLOCK}"; fi
  ph='{{FIVEM_SUPPORT}}';       if [ -n "$FIVEM_BLOCK" ];         then content="${content//"$ph"/$FIVEM_BLOCK}"; fi
  ph='{{SELECTED_SKILLS}}';     if [ -n "$SELECTED_SKILLS" ];     then content="${content//"$ph"/$SELECTED_SKILLS}"; fi
  ph='{{TRIO_SECTION}}';        if [ -n "$TRIO_SECTION" ];        then content="${content//"$ph"/$TRIO_SECTION}"; fi

  # Remove lines that still contain an unreplaced {{PLACEHOLDER}}.
  local out='' line re='\{\{[A-Z_]+\}\}'
  while IFS= read -r line; do
    if [[ "$line" =~ $re ]]; then continue; fi
    out="$out$line"$'\n'
  done <<< "$content"

  # Collapse runs of 3+ newlines into exactly one blank line.
  while [ "${out#*$'\n\n\n'}" != "$out" ]; do
    out="${out//$'\n\n\n'/$'\n\n'}"
  done

  # Trim trailing newlines, end with exactly one.
  while [ "${out%$'\n'}" != "$out" ]; do
    out="${out%$'\n'}"
  done
  GENERATED_CLAUDE_MD="$out"$'\n'
}

build_claude_md

# ── Installation ──────────────────────────────────────────────────────────────

# Dry run: print the generated CLAUDE.md and stop before writing anything.
if [ "$DRY_RUN" = "1" ]; then
  echo ""
  write_warn "$(T dry_note)"
  echo ""
  printf '%s=== CLAUDE.md ===================================================%s\n' "$C_CYAN" "$C_RESET"
  printf '%s' "$GENERATED_CLAUDE_MD"
  printf '%s=================================================================%s\n' "$C_CYAN" "$C_RESET"
  echo ""
  write_warn "$(T dry_done)"
  exit 0
fi

echo ""
printf '%s%s%s\n' "$C_CYAN" "$(T wr_writing)" "$C_RESET"

# ── Step 1+2: backup + write CLAUDE.md ────────────────────────────────────────
ensure_dir "$CLAUDE_DIR"
backup_file "$CLAUDE_MD_OUT"
printf '%s' "$GENERATED_CLAUDE_MD" > "$CLAUDE_MD_OUT"
write_step "$(printf "$(T wr_claudemd)" "$CLAUDE_MD_OUT")"

# ── Step 3: skills ────────────────────────────────────────────────────────────
if [ "$INSTALL_SKILLS" = "1" ]; then
  if [ ! -d "$SKILLS_SRC" ]; then
    write_warn "$(printf "$(T wr_skills_src)" "$SKILLS_SRC")"
  else
    ensure_dir "$SKILLS_DEST"
    INSTALLED_COUNT=0
    for _skill_dir in "$SKILLS_SRC"/*/; do
      [ -d "$_skill_dir" ] || continue
      _skill_name="$(basename "$_skill_dir")"
      _dest_skill="$SKILLS_DEST/$_skill_name"
      if [ -e "$_dest_skill" ]; then
        mv "$_dest_skill" "$_dest_skill.backup-$TIMESTAMP"
      fi
      cp -R "$SKILLS_SRC/$_skill_name" "$_dest_skill"
      write_step "$(printf "$(T wr_skills)" "$_skill_name")"
      INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    done
    write_step "$(printf "$(T wr_skills_n)" "$INSTALLED_COUNT" "$SKILLS_DEST")"
  fi
fi

# ── Step 4: Obsidian vault ────────────────────────────────────────────────────

# Replaces the vault placeholders in the global CONTENT variable.
expand_vault_placeholders() {
  local proj_link ph
  if [ -n "$PROJECT_SLUG" ]; then
    proj_link="- [[projects/$PROJECT_SLUG|$PROJECT_NAME]]"
  elif [ "$UI_LANG" = "de" ]; then
    proj_link='- (noch keine Projekte - Claude legt bei der ersten Aufgabe eines an)'
  else
    proj_link='- (no projects yet - Claude creates one with your first task)'
  fi
  ph='{{USER_NAME}}';          CONTENT="${CONTENT//"$ph"/$USER_NAME}"
  ph='{{GOALS}}';              CONTENT="${CONTENT//"$ph"/$GOALS}"
  ph='{{EXPERIENCE}}';         CONTENT="${CONTENT//"$ph"/$EXPERIENCE_LABEL}"
  ph='{{MAIN_WORK_TYPE}}';     CONTENT="${CONTENT//"$ph"/$MAIN_WORK_TYPE_LABEL}"
  ph='{{PREFERRED_STACKS}}';   CONTENT="${CONTENT//"$ph"/$STACKS}"
  ph='{{DATE}}';               CONTENT="${CONTENT//"$ph"/$TODAY}"
  ph='{{FIRST_PROJECT_LINK}}'; CONTENT="${CONTENT//"$ph"/$proj_link}"
}

read_file_into_content() {
  CONTENT="$(cat "$1"; printf 'x')"
  CONTENT="${CONTENT%x}"
}

install_vault() {
  local src_root="$VAULT_TPL_ROOT/$UI_LANG"
  if [ ! -d "$src_root" ]; then
    # Fall back to the English scaffold if the language variant is missing.
    src_root="$VAULT_TPL_ROOT/en"
  fi
  if [ ! -d "$src_root" ]; then
    write_warn "$(printf "$(T wr_vault_tpl)" "$VAULT_TPL_ROOT")"
    return 0
  fi

  ensure_dir "$VAULT_PATH"

  # Copy scaffold: recreate directory structure, copy files that do not exist
  # yet, replace placeholders in every newly copied file. Never overwrite.
  local f rel dest
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    rel="${f#"$src_root"/}"
    dest="$VAULT_PATH/$rel"
    if [ -d "$f" ]; then
      ensure_dir "$dest"
    elif [ ! -e "$dest" ]; then
      ensure_dir "$(dirname "$dest")"
      read_file_into_content "$f"
      expand_vault_placeholders
      printf '%s' "$CONTENT" > "$dest"
    fi
  done <<EOF_VAULT_LIST
$(find "$src_root" -mindepth 1)
EOF_VAULT_LIST

  # Standard working folders (created empty).
  local d
  for d in projects knowledge decisions sessions; do
    ensure_dir "$VAULT_PATH/$d"
  done

  # First project note from the project template (F18).
  if [ -n "$PROJECT_SLUG" ]; then
    local proj_note="$VAULT_PATH/projects/$PROJECT_SLUG.md"
    if [ ! -e "$proj_note" ]; then
      local tpl_dir="$VAULT_PATH/meta/templates"
      local proj_tpl='' candidate
      for candidate in projekt.md project.md; do
        if [ -f "$tpl_dir/$candidate" ]; then
          proj_tpl="$tpl_dir/$candidate"
          break
        fi
      done
      if [ -n "$proj_tpl" ]; then
        read_file_into_content "$proj_tpl"
      else
        # Minimal fallback hub note if the template is missing.
        CONTENT='# {{PROJECT_NAME}}

Created: {{DATE}}
Status: active

## Overview

## Notes
'
      fi
      local ph
      ph='{{PROJECT_NAME}}'; CONTENT="${CONTENT//"$ph"/$PROJECT_NAME}"
      ph='{{PROJECT_SLUG}}'; CONTENT="${CONTENT//"$ph"/$PROJECT_SLUG}"
      ph='{{TITLE}}';        CONTENT="${CONTENT//"$ph"/$PROJECT_NAME}"
      ph='{{TITEL}}';        CONTENT="${CONTENT//"$ph"/$PROJECT_NAME}"
      # Case-sensitive: the lowercase placeholders exist only in the
      # generated project note, not in the copied meta/templates files.
      ph='{{title}}';        CONTENT="${CONTENT//"$ph"/$PROJECT_NAME}"
      ph='{{date}}';         CONTENT="${CONTENT//"$ph"/$TODAY}"
      expand_vault_placeholders
      printf '%s' "$CONTENT" > "$proj_note"
    fi
  fi

  if [ "$VAULT_REUSE" = "1" ]; then
    write_step "$(printf "$(T wr_vault_add)" "$VAULT_PATH")"
  else
    write_step "$(printf "$(T wr_vault_new)" "$VAULT_PATH")"
  fi
}

if [ "$OBSIDIAN_ENABLED" = "1" ]; then
  install_vault
fi

# ── Step 5: brain runtime + config.json ──────────────────────────────────────
ensure_dir "$BRAIN_DIR"
ensure_dir "$BRAIN_DIR/backups"

# Update scripts (both platforms, so the folder is complete either way).
for _name in check-update.ps1 update.ps1 check-update.sh update.sh; do
  if [ -f "$SCRIPT_DIR/$_name" ]; then
    backup_file "$BRAIN_DIR/$_name"
    cp "$SCRIPT_DIR/$_name" "$BRAIN_DIR/$_name"
    case "$_name" in
      *.sh) chmod +x "$BRAIN_DIR/$_name" 2>/dev/null || true ;;
    esac
  fi
done

# VERSION
backup_file "$BRAIN_DIR/VERSION"
printf '%s\n' "$BRAIN_VERSION" > "$BRAIN_DIR/VERSION"

# Docs copy (backup an existing docs folder by renaming, never deleting).
if [ -d "$DOCS_SRC" ]; then
  if [ -d "$BRAIN_DIR/docs" ]; then
    mv "$BRAIN_DIR/docs" "$BRAIN_DIR/docs.backup-$TIMESTAMP"
  fi
  cp -R "$DOCS_SRC" "$BRAIN_DIR/docs"
fi

write_step "$(printf "$(T wr_brain)" "$BRAIN_DIR")"

# config.json
CONFIG_PATH="$BRAIN_DIR/config.json"
backup_file "$CONFIG_PATH"

OS_NAME='linux'
case "$(uname -s 2>/dev/null || printf 'unknown')" in
  Darwin) OS_NAME='macos' ;;
esac
INSTALLED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

write_config_json() {
  # Written with plain shell, deliberately.
  #
  # v2 shelled out to python3 for this. On Windows, `python3` is usually the
  # Microsoft Store placeholder: `command -v python3` finds it, running it exits
  # with code 49, and the whole setup died right here without an error message.
  # Existence is not availability.
  #
  # The config is a flat, known structure, so no interpreter is needed at all.
  # json_escape() handles quoting. One dependency fewer, one failure mode fewer.
  local modelraw_json
  if [ -n "$MODEL_RAW" ]; then
    modelraw_json="\"$(json_escape "$MODEL_RAW")\""
  else
    modelraw_json='null'
  fi

  ensure_dir "$(dirname "$CONFIG_PATH")"
  cat > "$CONFIG_PATH" <<EOFCONFIG
{
  "version": "$(json_escape "$BRAIN_VERSION")",
  "repo": "$(json_escape "$REPO_SLUG")",
  "branch": "$(json_escape "$REPO_BRANCH")",
  "installedAt": "$(json_escape "$INSTALLED_AT")",
  "os": "$(json_escape "$OS_NAME")",
  "language": "$(json_escape "$UI_LANG")",
  "userName": "$(json_escape "$USER_NAME")",
  "experience": "$(json_escape "$EXPERIENCE_KEY")",
  "model": "$(json_escape "$MODEL_KEY")",
  "modelRaw": $modelraw_json,
  "planTier": "$(json_escape "$PLAN_TIER")",
  "trio": {
    "enabled": $(bool_json "$TRIO_ENABLED"),
    "broker": "$(json_escape "$BRAIN_DIR/trio/broker.mjs")"
  },
  "obsidian": {
    "enabled": $(bool_json "$OBSIDIAN_ENABLED"),
    "vaultPath": "$(json_escape "$VAULT_PATH")",
    "appInstalled": $(bool_json "$OBSIDIAN_APP_INSTALLED")
  },
  "updateCheck": {
    "enabled": $(bool_json "$UPDATE_CHECK_ENABLED"),
    "intervalHours": 24,
    "lastCheck": null
  },
  "claudeMdPath": "$(json_escape "$CLAUDE_MD_OUT")"
}
EOFCONFIG
}

write_config_json
write_step "$(printf "$(T wr_config)" "$CONFIG_PATH")"

# ── Step 6: SessionStart hook in settings.json (idempotent) ──────────────────

# The command is stored with a literal $HOME so the shell expands it at
# hook runtime on any machine.
HOOK_COMMAND='bash "$HOME/.claude/brain/check-update.sh"'

HOOK_SNIPPET='"hooks": {
  "SessionStart": [
    { "matcher": "startup",
      "hooks": [ { "type": "command", "command": "bash \"$HOME/.claude/brain/check-update.sh\"" } ] }
  ]
}'

print_hook_fail() {
  write_warn "$(printf "$(T wr_hook_fail)" "$1")"
  printf '%s\n' "$HOOK_SNIPPET"
}

register_update_hook() {
  # Idempotency: is a brain check-update hook already registered?
  if [ -f "$SETTINGS_FILE" ] && grep -Eq 'brain[/\\]+check-update' "$SETTINGS_FILE" 2>/dev/null; then
    write_step "$(T wr_hook_have)"
    return 0
  fi

  if command -v python3 >/dev/null 2>&1; then
    if CB_SETTINGS="$SETTINGS_FILE" CB_CMD="$HOOK_COMMAND" CB_TS="$TIMESTAMP" python3 <<'PYHOOK'
import json
import os
import shutil
import sys

path = os.environ['CB_SETTINGS']
cmd = os.environ['CB_CMD']
ts = os.environ['CB_TS']

settings = {}
if os.path.exists(path):
    with open(path, 'r', encoding='utf-8') as f:
        raw = f.read()
    if raw.strip():
        settings = json.loads(raw)
    if not isinstance(settings, dict):
        sys.exit(1)
    shutil.copyfile(path, path + '.backup-' + ts)

hooks = settings.get('hooks')
if not isinstance(hooks, dict):
    hooks = {}
    settings['hooks'] = hooks
session_start = hooks.get('SessionStart')
if not isinstance(session_start, list):
    session_start = []
session_start.append({'matcher': 'startup', 'hooks': [{'type': 'command', 'command': cmd}]})
hooks['SessionStart'] = session_start

with open(path, 'w', encoding='utf-8') as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write('\n')
PYHOOK
    then
      if [ -f "$SETTINGS_FILE.backup-$TIMESTAMP" ]; then
        write_step "$(printf "$(T backed_up)" "$SETTINGS_FILE" "$SETTINGS_FILE.backup-$TIMESTAMP")"
      fi
      write_step "$(T wr_hook_ok)"
    else
      print_hook_fail 'python3 merge failed'
    fi
    return 0
  fi

  if command -v jq >/dev/null 2>&1; then
    local raw_json='{}'
    if [ -f "$SETTINGS_FILE" ]; then
      raw_json="$(cat "$SETTINGS_FILE")"
      if [ -z "$(trim "$raw_json")" ]; then raw_json='{}'; fi
    fi
    local merged=''
    if merged="$(printf '%s' "$raw_json" | jq --arg cmd "$HOOK_COMMAND" \
      '.hooks.SessionStart = ((.hooks.SessionStart // []) + [{"matcher": "startup", "hooks": [{"type": "command", "command": $cmd}]}])' 2>/dev/null)" \
      && [ -n "$merged" ]; then
      backup_file "$SETTINGS_FILE"
      printf '%s\n' "$merged" > "$SETTINGS_FILE"
      write_step "$(T wr_hook_ok)"
    else
      print_hook_fail 'jq merge failed'
    fi
    return 0
  fi

  # Neither python3 nor jq available: print the snippet and keep going.
  print_hook_fail 'python3/jq not found'
}

if [ "$UPDATE_CHECK_ENABLED" = "1" ]; then
  register_update_hook
else
  write_note "$(T wr_hook_skip)"
fi

# ── Step 7: V1 migration ──────────────────────────────────────────────────────
# V1 installed CLAUDE.md directly into the home directory. Two CLAUDE.md files
# can contradict each other, so offer a safe rename (never delete).
if [ -f "$V1_CLAUDE_MD" ]; then
  echo ""
  write_warn "$(printf "$(T mig_info)" "$V1_CLAUDE_MD")"
  ask_yesno "$(T mig_q)" 1
  if [ "$YESNO" = "1" ]; then
    mv "$V1_CLAUDE_MD" "$HOME_DIR/CLAUDE.md.backup-$TIMESTAMP"
    write_step "$(printf "$(T mig_done)" "$HOME_DIR/CLAUDE.md.backup-$TIMESTAMP")"
  else
    write_warn "$(T mig_warn)"
  fi
fi

# ── Step 7b: commands + Trio ──────────────────────────────────────────────────

# Slash commands (e.g. /CLIcombo) live in ~/.claude/commands/
if [ -d "$COMMANDS_SRC" ]; then
  ensure_dir "$COMMANDS_DEST"
  _cmd_count=0
  for _cmd in "$COMMANDS_SRC"/*.md; do
    [ -e "$_cmd" ] || continue
    backup_file "$COMMANDS_DEST/$(basename "$_cmd")"
    cp "$_cmd" "$COMMANDS_DEST/"
    _cmd_count=$((_cmd_count + 1))
  done
  [ "$_cmd_count" -gt 0 ] && write_step "$(printf "$(T wr_commands)" "$COMMANDS_DEST")"
fi

# The Trio installer does its own detection, backups and verification.
if [ "$TRIO_ENABLED" = "1" ] && [ -f "$TRIO_SRC/install.mjs" ] && command -v node >/dev/null 2>&1; then
  echo ""
  if [ "$F1" = "1" ]; then _trio_lang=de; else _trio_lang=en; fi
  if node "$TRIO_SRC/install.mjs" --yes --lang "$_trio_lang" --home "$HOME_DIR"; then
    write_step "$(T wr_trio)"
  else
    write_warn "$(T wr_trio_fail)"
  fi
else
  [ "$TRIO_ENABLED" = "1" ] || write_step "$(T wr_trio_skip)"
fi

# ── Step 8: final screen ──────────────────────────────────────────────────────
write_title "$(T fin_title)"
printf '%s\n' "$(T fin_where)"
printf '  %s\n' "$(printf "$(T fin_claudemd)" "$CLAUDE_MD_OUT")"
if [ "$INSTALL_SKILLS" = "1" ]; then
  printf '  %s\n' "$(printf "$(T fin_skills)" "$SKILLS_DEST")"
fi
printf '  %s\n' "$(printf "$(T fin_brain)" "$BRAIN_DIR")"
if [ "$OBSIDIAN_ENABLED" = "1" ]; then
  printf '  %s\n' "$(printf "$(T fin_vault)" "$VAULT_PATH")"
fi
echo ""
printf '%s\n' "$(T fin_start1)"
echo ""
printf '%s    claude%s\n' "$C_GREEN" "$C_RESET"
echo ""
printf '%s\n' "$(T fin_start2)"
echo ""
printf '%s\n' "$(printf "$(T fin_update)" "$BRAIN_DIR/update.sh")"
if [ "$OBSIDIAN_ENABLED" = "1" ] && [ "$OBSIDIAN_APP_INSTALLED" = "0" ]; then
  echo ""
  write_note "$(T fin_obsidian)"
fi
echo ""

exit 0
