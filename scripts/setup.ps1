# Claude Brain Setup — Interactive setup wizard (Windows)
# Version 2.0.0 — https://github.com/JanniEinfach/claude-brain-setup
#
# Usage:
#   .\scripts\setup.ps1                        interactive wizard
#   .\scripts\setup.ps1 -DryRun                run all questions, print CLAUDE.md, write nothing
#   .\scripts\setup.ps1 -Target <dir>          use <dir> instead of your user profile as base (for tests)
#   .\scripts\setup.ps1 -AnswerFile <file>     read answers from a file (one answer per line, blank = default)
#   .\scripts\setup.ps1 -Help                  show help
#
# PowerShell 5.1 compatible. No admin rights required. This script never deletes
# user files — existing files are renamed or copied to timestamped backups.

[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$Target = '',
    [string]$AnswerFile = '',
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

#region ── Paths ─────────────────────────────────────────────────────────────

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

if ([string]::IsNullOrWhiteSpace($Target)) {
    $HomeDir = $env:USERPROFILE
} else {
    $HomeDir = $Target
}

$ClaudeDir    = Join-Path $HomeDir '.claude'
$BrainDir     = Join-Path $ClaudeDir 'brain'
$SkillsDest   = Join-Path $ClaudeDir 'skills'
$SettingsFile = Join-Path $ClaudeDir 'settings.json'
$ClaudeMdOut  = Join-Path $ClaudeDir 'CLAUDE.md'
$V1ClaudeMd   = Join-Path $HomeDir 'CLAUDE.md'

$TemplateFile = Join-Path $ProjectRoot 'templates\CLAUDE.template.md'
$VaultTplRoot = Join-Path $ProjectRoot 'templates\obsidian'
$SkillsSrc    = Join-Path $ProjectRoot 'skills'
$DocsSrc      = Join-Path $ProjectRoot 'docs'
$VersionFile  = Join-Path $ProjectRoot 'VERSION'

$RepoSlug   = 'JanniEinfach/claude-brain-setup'
$RepoBranch = 'main'

$BrainVersion = '2.0.0'
if (Test-Path $VersionFile) {
    $BrainVersion = (Get-Content $VersionFile -Raw).Trim()
}

$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Today     = Get-Date -Format 'yyyy-MM-dd'

#endregion

#region ── Help ──────────────────────────────────────────────────────────────

if ($Help) {
    Write-Host ""
    Write-Host "Claude Brain Setup $BrainVersion — interactive wizard (Windows)"
    Write-Host ""
    Write-Host "  -DryRun              Alles durchspielen, generiertes CLAUDE.md anzeigen, nichts schreiben."
    Write-Host "                       Run everything, print the generated CLAUDE.md, write nothing."
    Write-Host "  -Target <dir>        Basisordner statt deines Benutzerordners (fuer Tests)."
    Write-Host "                       Base directory instead of your user profile (for testing)."
    Write-Host "  -AnswerFile <file>   Antworten aus Datei lesen: eine Antwort pro Zeile in Frage-"
    Write-Host "                       Reihenfolge, Leerzeile = Standardwert."
    Write-Host "                       Read answers from a file: one answer per line in question"
    Write-Host "                       order, blank line = default."
    Write-Host "  -Help                Diese Hilfe. / This help."
    Write-Host ""
    Write-Host "Installiert / installs:"
    Write-Host "  ~/.claude/CLAUDE.md          personalisierte Konfiguration / personalized config"
    Write-Host "  ~/.claude/skills/brain-*     Brain-Skills"
    Write-Host "  ~/.claude/brain/             Laufzeit: VERSION, config.json, Update-Skripte, docs"
    Write-Host "  <Vault-Pfad>                 Obsidian Master Brain (optional)"
    Write-Host ""
    exit 0
}

#endregion

#region ── Answer file ───────────────────────────────────────────────────────

$Script:Answers      = $null
$Script:AnswerIndex  = 0
$Script:LastFromFile = $false

if (-not [string]::IsNullOrWhiteSpace($AnswerFile)) {
    if (-not (Test-Path -LiteralPath $AnswerFile)) {
        Write-Host "Answer file not found: $AnswerFile" -ForegroundColor Red
        exit 1
    }
    $Script:Answers = @(Get-Content -LiteralPath $AnswerFile)
}

#endregion

#region ── Helper functions ──────────────────────────────────────────────────

function Write-Title {
    param([string]$Text)
    Write-Host ""
    Write-Host $Text -ForegroundColor Cyan
    Write-Host ('=' * $Text.Length) -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Text)
    Write-Host "  $Text" -ForegroundColor Green
}

function Write-Note {
    param([string]$Text)
    Write-Host $Text -ForegroundColor DarkGray
}

function Write-Warn2 {
    param([string]$Text)
    Write-Host $Text -ForegroundColor Yellow
}

# Central input: pulls from the answer file when one is given, otherwise Read-Host.
# Sets $Script:LastFromFile so callers can avoid endless loops on invalid file input.
function Read-Answer {
    param([string]$Prompt)
    if ($null -ne $Script:Answers) {
        $Script:LastFromFile = $true
        $val = ''
        if ($Script:AnswerIndex -lt $Script:Answers.Count) {
            $val = [string]$Script:Answers[$Script:AnswerIndex]
            $Script:AnswerIndex++
        }
        Write-Host ("{0}: {1}" -f $Prompt, $val)
        return $val
    }
    $Script:LastFromFile = $false
    return Read-Host $Prompt
}

# Localized text lookup (falls back to English).
function T {
    param([string]$Key)
    $tbl = $Script:TXT[$Script:Lang]
    if ($tbl.ContainsKey($Key)) { return $tbl[$Key] }
    return $Script:TXT['en'][$Key]
}

# Numbered menu. Returns the 1-based choice. Re-asks on invalid input;
# with an answer file, invalid input falls back to the default (no endless loop).
function Ask-Choice {
    param(
        [string]$Question,
        [string[]]$Options,
        [int]$Default = 1,
        [string]$Explain = ''
    )
    Write-Host ""
    if ($Explain) { Write-Note $Explain }
    Write-Host $Question -ForegroundColor White
    for ($i = 0; $i -lt $Options.Length; $i++) {
        Write-Host ("  {0}) {1}" -f ($i + 1), $Options[$i])
    }
    while ($true) {
        $raw = Read-Answer ("  {0} [{1}]" -f (T 'choice'), $Default)
        if ([string]::IsNullOrWhiteSpace($raw)) { return $Default }
        $n = 0
        if ([int]::TryParse($raw.Trim(), [ref]$n)) {
            if ($n -ge 1 -and $n -le $Options.Length) { return $n }
        }
        if ($Script:LastFromFile) {
            Write-Warn2 ((T 'invalid_num_file') -f $Options.Length, $Default)
            return $Default
        }
        Write-Warn2 ((T 'invalid_num') -f $Options.Length)
    }
}

# Free-text question. $MinLen 0 = optional. With an answer file, too-short input
# falls back to the default (or is accepted as-is when no default exists).
function Ask-Text {
    param(
        [string]$Question,
        [string]$Default = '',
        [int]$MinLen = 0,
        [string]$RetryHint = '',
        [string]$Explain = ''
    )
    Write-Host ""
    if ($Explain) { Write-Note $Explain }
    Write-Host $Question -ForegroundColor White
    $promptSuffix = ''
    if ($Default) { $promptSuffix = " [$Default]" }
    while ($true) {
        $raw = Read-Answer ("  >{0}" -f $promptSuffix)
        if ($null -eq $raw) { $raw = '' }
        $raw = $raw.Trim()
        if ($raw.Length -eq 0) {
            if ($Default) { return $Default }
            if ($MinLen -eq 0) { return '' }
        }
        if ($raw.Length -ge $MinLen -and $raw.Length -gt 0) { return $raw }
        if ($Script:LastFromFile) {
            if ($raw.Length -gt 0) { return $raw }
            if ($Default) { return $Default }
            return ''
        }
        if ($RetryHint) { Write-Warn2 $RetryHint } else { Write-Warn2 (T 'too_short_generic') }
    }
}

# Yes/no question. Accepts j/ja/y/yes/n/nein/no (case-insensitive), Enter = default.
function Ask-YesNo {
    param(
        [string]$Question,
        [bool]$DefaultYes = $true,
        [string]$Explain = ''
    )
    Write-Host ""
    if ($Explain) { Write-Note $Explain }
    if ($DefaultYes) { $suffix = (T 'yn_default_yes') } else { $suffix = (T 'yn_default_no') }
    while ($true) {
        $raw = Read-Answer ("{0} {1}" -f $Question, $suffix)
        if ($null -eq $raw) { $raw = '' }
        $raw = $raw.Trim().ToLowerInvariant()
        if ($raw.Length -eq 0) { return $DefaultYes }
        if ($raw -match '^(j|ja|y|yes)$') { return $true }
        if ($raw -match '^(n|nein|no)$') { return $false }
        if ($Script:LastFromFile) { return $DefaultYes }
        Write-Warn2 (T 'invalid_yn')
    }
}

# Copies a file to <name>.backup-<timestamp> before it gets overwritten.
function Backup-File {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        $backup = "$Path.backup-$Timestamp"
        Copy-Item -LiteralPath $Path -Destination $backup
        Write-Step ((T 'backed_up') -f $Path, $backup)
        return $backup
    }
    return $null
}

function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

# Writes a file as UTF-8 WITHOUT BOM (Set-Content -Encoding UTF8 would add one
# on Windows PowerShell 5.1, which breaks strict JSON parsers).
function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        $Path = Join-Path (Get-Location).ProviderPath $Path
    }
    [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}

# Builds a file-safe slug: lowercase, umlauts transliterated,
# spaces to hyphens, only [a-z0-9-].
function New-Slug {
    param([string]$Name)
    $s = $Name.ToLowerInvariant()
    $s = $s.Replace([string][char]0x00E4, 'ae').Replace([string][char]0x00F6, 'oe')
    $s = $s.Replace([string][char]0x00FC, 'ue').Replace([string][char]0x00DF, 'ss')
    $s = $s -replace '\s+', '-'
    $s = $s -replace '[^a-z0-9-]', ''
    $s = $s -replace '-{2,}', '-'
    return $s.Trim('-')
}

# Question header: "Frage N von 20" / "Question N of 20"
function Show-QHeader {
    param([int]$Number)
    Write-Host ""
    Write-Host ("--- {0} ---" -f ((T 'q_of') -f $Number)) -ForegroundColor Cyan
}

#endregion

#region ── Texts (DE / EN) ───────────────────────────────────────────────────

$Script:Lang = 'en'

$Script:TXT = @{
    'de' = @{
        'choice'            = 'Auswahl'
        'invalid_num'       = 'Bitte gib eine Zahl zwischen 1 und {0} ein.'
        'invalid_num_file'  = 'Ungueltige Antwort in der Answer-Datei (erlaubt: 1-{0}) - Standard {1} wird verwendet.'
        'invalid_yn'        = 'Bitte antworte mit j (ja) oder n (nein).'
        'too_short_generic' = 'Bitte gib etwas mehr Text ein.'
        'yn_default_yes'    = '[J/n]'
        'yn_default_no'     = '[j/N]'
        'q_of'              = 'Frage {0} von 20'
        'backed_up'         = 'Backup: {0} -> {1}'

        'f2_q' = 'Wie soll Claude dich nennen?'
        'f2_x' = 'Der Name landet oben in deiner Konfiguration. Vorname reicht voellig.'
        'f2_r' = 'Bitte gib mindestens 2 Zeichen ein, z. B. "Alex".'

        'f3_q' = 'Wie viel Erfahrung hast du mit Claude Code?'
        'f3_x' = 'Ehrlich antworten lohnt sich: Als Anfaenger erklaert Claude dir mehr und fragt oefter nach, bevor er etwas Kompliziertes tut.'
        'f3_o' = @('Anfaenger - ich fange gerade erst an', 'Fortgeschritten - ich nutze es regelmaessig', 'Profi - ich kenne Skills, Agents und Hooks')

        'f4_q' = 'Was hast du mit Claude vor? Beschreib es in 1-3 Saetzen.'
        'f4_x' = 'z. B. "FiveM-Scripts fuer meinen Server bauen", "eine Web-App entwickeln", "Python lernen". Claude richtet sich danach und vergisst es nicht.'
        'f4_r' = 'Beschreib es in einem Satz, z. B.: "Ich will eine kleine Web-App fuer meinen Verein bauen."'

        'f5_q' = 'Was ist dein Haupt-Arbeitsgebiet?'
        'f5_x' = 'Danach richtet sich, welche Extra-Regeln und fertigen Arbeitsanleitungen (Skills) Claude bekommt.'
        'f5_o' = @('Allgemein', 'Web-Frontend', 'Backend/APIs', 'Full-Stack', 'FiveM/Spiele-Scripts', 'DevOps', 'Daten/Python', 'Marketing/Texte')

        'f6_q' = 'Mit welchen Programmiersprachen/Technologien arbeitest du? Kommagetrennt.'
        'f6_x' = 'z. B. "JavaScript, React" oder "Python". Wenn du es nicht weisst, drueck einfach Enter - Claude findet es beim Arbeiten heraus.'
        'f6_d' = 'weiss ich noch nicht'

        'f7_found'   = 'Ich habe nachgesehen: Du nutzt gerade {0}. Stimmt das?'
        'f7_found_x' = 'Claude gibt es in mehreren Modellen (von schnell und guenstig bis maximal schlau). Ich habe in deinen Claude-Code-Einstellungen nachgesehen, welches du nutzt.'
        'f7_x'       = 'Claude gibt es in mehreren Modellen - von schnell und guenstig (Haiku) bis maximal schlau (Opus/Fable). Wenn du es nicht weisst: Starte Claude Code und tipp /model - dann siehst du es. Du kannst auch einfach "Weiss nicht" waehlen.'
        'f7_q'       = 'Welches Claude-Modell nutzt du?'
        'f7_o'       = @('Haiku (schnell und guenstig)', 'Sonnet (Standard)', 'Opus (sehr stark)', 'Fable (Spitzenmodell)', 'Weiss ich nicht')

        'f8_q' = 'Wie bezahlst du Claude?'
        'f8_x' = 'Bei Pro ist das Kontingent kleiner - dann stellt Claude sich sparsamer ein.'
        'f8_o' = @('Claude Pro (ca. 20 Euro/Monat)', 'Claude Max', 'API-Guthaben', 'Weiss ich nicht')

        'f9_q' = 'Wie sparsam soll Claude mit Tokens umgehen?'
        'f9_x' = 'Tokens sind Claudes "Verbrauchseinheit". Sparsam = Claude liest gezielter und fasst kuerzer zusammen.'
        'f9_o' = @('Konservativ (Qualitaet vor Sparsamkeit)', 'Ausgewogen', 'Aggressiv (maximal sparsam)')

        'f10_q' = 'Wie soll Claude planen?'
        'f10_x' = 'Bei groesseren Aufgaben lohnt ein kurzer Plan, bevor Code entsteht.'
        'f10_o' = @('Automatisch planen bei groesseren Aufgaben (empfohlen)', 'Vorher fragen', 'Minimal planen')

        'f11_q' = 'Welchen Code-Style soll Claude schreiben?'
        'f11_x' = 'Produktionsreif heisst: saubere Fehlerbehandlung, Tests, konsistente Muster.'
        'f11_o' = @('Einfach (kleine private Skripte)', 'Produktionsreif (empfohlen)', 'Streng', 'Architektur-fokussiert')

        'f12_q' = 'Wann soll Claude Tests schreiben?'
        'f12_x' = 'Tests sichern ab, dass Aenderungen nichts kaputt machen.'
        'f12_o' = @('Immer Tests', 'Nur bei riskanten/komplexen Aenderungen (empfohlen)', 'Erst fragen')

        'f13_q' = 'Wie streng soll Claude bei Sicherheit sein?'
        'f13_x' = 'Baust du etwas mit Login, Bezahlung oder Nutzerdaten? Dann waehl mindestens "Streng".'
        'f13_o' = @('Standard', 'Streng', 'Sehr streng')

        'f14_q'    = 'FiveM-Modul aktivieren?'
        'f14_x'    = 'FiveM ist eine Mod-Plattform fuer GTA V. Nur relevant, wenn du dafuer Scripts baust.'
        'f14_skip' = 'FiveM-Modul wird automatisch aktiviert, weil dein Haupt-Arbeitsgebiet FiveM/Spiele-Scripts ist.'

        'f15_q' = 'Marketing-Modul aktivieren?'
        'f15_x' = 'Fuegt Schreibregeln fuer Marketing- und Verkaufstexte hinzu.'

        'f16_q' = 'Wie soll Claude mit dir umgehen?'
        'f16_x' = 'Option 1 heisst: Claude sagt dir ehrlich, wenn ein Plan Probleme machen wird, und schlaegt Besseres vor.'
        'f16_o' = @('Partner mit eigener Meinung - widerspricht, wenn etwas keine gute Idee ist (empfohlen)', 'Zurueckhaltend - macht einfach, was du sagst')

        'f17_q' = 'Obsidian Master Brain einrichten?'
        'f17_x' = 'Das Master Brain ist Claudes Langzeitgedaechtnis: ein Ordner mit Notizen, in dem Claude Projekte, Entscheidungen und Wissen ueber eure Zusammenarbeit speichert - ueber Sessions hinweg. Obsidian (obsidian.md, kostenlos) ist eine App, die diese Notizen schoen anzeigt und verlinkt. Das Gedaechtnis funktioniert aber auch ohne die App - es sind normale Textdateien.'

        'f17a_q'    = 'Hast du Obsidian schon installiert?'
        'f17a_o'    = @('Ja', 'Nein', 'Weiss ich nicht')
        'f17a_how'  = 'So pruefst du das: Such im Startmenue/Programme nach "Obsidian".'
        'f17a_note' = 'Kein Problem - ich lege das Gedaechtnis trotzdem an. Obsidian kannst du spaeter von https://obsidian.md installieren und den Ordner als Vault oeffnen.'

        'f17b_q'      = 'Wo soll das Gedaechtnis (der Vault) liegen?'
        'f17b_x'      = 'Enter uebernimmt den Vorschlag. Der Ordner wird angelegt, falls er fehlt.'
        'f17b_exists' = 'Dieser Ordner existiert schon und ist nicht leer. Was tun?'
        'f17b_o'      = @('Als bestehenden Vault weiterverwenden (nur fehlende Dateien ergaenzen, NICHTS ueberschreiben)', 'Anderen Pfad waehlen')

        'f18_q' = 'Woran willst du als Erstes arbeiten? Kurzer Name reicht (Enter = ueberspringen).'
        'f18_x' = 'z. B. "mein-server" oder "shop-website". Claude legt dafuer eine Projekt-Notiz im Gedaechtnis an.'

        'f19_q' = 'Soll Claude dich ueber Brain-Updates informieren?'
        'f19_x' = 'Einmal am Tag prueft ein Mini-Skript beim Start, ob es eine neue Brain-Version auf GitHub gibt (eine einzige kleine Anfrage, keine Daten von dir werden gesendet). Gibt es eine, sagt Claude dir Bescheid und du kannst mit /brain-update aktualisieren.'

        'f20_q' = 'Brain-Skills installieren?'
        'f20_x' = 'Skills sind fertige Arbeitsanleitungen fuer Claude (z. B. ein Sicherheits-Check). Reine Textdateien, fuehren nichts von selbst aus.'

        'sum_title'    = 'Zusammenfassung deiner Antworten'
        'sum_confirm'  = 'Passt das?'
        'sum_abort'    = 'Alles klar - es wurde nichts geschrieben. Starte das Setup einfach neu, wenn du bereit bist.'
        'sum_name'     = 'Name'
        'sum_lang'     = 'Sprache'
        'sum_exp'      = 'Erfahrung'
        'sum_goals'    = 'Ziele'
        'sum_work'     = 'Arbeitsgebiet'
        'sum_stacks'   = 'Tech-Stacks'
        'sum_model'    = 'Modell'
        'sum_plan'     = 'Abo/Plan'
        'sum_token'    = 'Token-Strategie'
        'sum_planning' = 'Planung'
        'sum_style'    = 'Code-Style'
        'sum_testing'  = 'Testing'
        'sum_security' = 'Security-Level'
        'sum_fivem'    = 'FiveM-Modul'
        'sum_mkt'      = 'Marketing-Modul'
        'sum_partner'  = 'Umgang'
        'sum_vault'    = 'Master Brain (Vault)'
        'sum_project'  = 'Erstes Projekt'
        'sum_update'   = 'Update-Benachrichtigung'
        'sum_skills'   = 'Skills installieren'
        'sum_yes'      = 'ja'
        'sum_no'       = 'nein'
        'sum_none'     = '(keins)'
        'sum_disabled' = 'deaktiviert'

        'mig_info'    = 'Hinweis: Es existiert noch ein CLAUDE.md aus Version 1 an: {0}. Die neue Version liegt unter ~/.claude/CLAUDE.md. Zwei Dateien koennen sich widersprechen.'
        'mig_q'       = 'Soll ich die alte Datei sicher umbenennen (nichts wird geloescht)?'
        'mig_done'    = 'Alte Datei umbenannt nach: {0}'
        'mig_warn'    = 'Achtung: Beide CLAUDE.md-Dateien bleiben bestehen und koennen sich widersprechen. Du kannst die alte Datei spaeter selbst entfernen.'

        'wr_writing'    = 'Schreibe Dateien...'
        'wr_claudemd'   = 'CLAUDE.md geschrieben: {0}'
        'wr_skills'     = 'Skill installiert: {0}'
        'wr_skills_n'   = '{0} Skill(s) installiert nach: {1}'
        'wr_skills_src' = 'Warnung: skills-Ordner nicht gefunden ({0}) - Skills uebersprungen.'
        'wr_vault_new'  = 'Master Brain angelegt: {0}'
        'wr_vault_add'  = 'Bestehender Vault ergaenzt (nur fehlende Dateien): {0}'
        'wr_vault_tpl'  = 'Warnung: Vault-Vorlagen nicht gefunden ({0}) - Vault uebersprungen.'
        'wr_config'     = 'config.json geschrieben: {0}'
        'wr_hook_ok'    = 'Update-Hook in settings.json registriert.'
        'wr_hook_have'  = 'Update-Hook ist bereits registriert - nichts geaendert.'
        'wr_hook_skip'  = 'Update-Benachrichtigung deaktiviert - kein Hook registriert.'
        'wr_hook_fail'  = 'settings.json konnte nicht automatisch angepasst werden ({0}). Fuege diesen Eintrag manuell unter "hooks" ein:'
        'wr_brain'      = 'Brain-Laufzeit installiert: {0}'

        'dry_note'  = '[DRY RUN] Es wird nichts geschrieben.'
        'dry_done'  = '[DRY RUN] Fertig. Oben steht das generierte CLAUDE.md. Es wurde nichts geschrieben.'

        'fin_title'   = 'Fertig! Claude Brain ist eingerichtet.'
        'fin_where'   = 'Das liegt jetzt auf deinem Rechner:'
        'fin_claudemd'= 'Deine Konfiguration:  {0}'
        'fin_skills'  = 'Brain-Skills:         {0}'
        'fin_brain'   = 'Brain-Laufzeit:       {0}'
        'fin_vault'   = 'Master Brain (Vault): {0}'
        'fin_start1'  = 'So geht es los: Oeffne ein Terminal und tipp einfach:'
        'fin_start2'  = 'Dann kannst du direkt lostippen - Claude kennt jetzt deinen Namen, deine Ziele und deine Regeln.'
        'fin_update'  = 'Updates: Claude sagt dir Bescheid, wenn es eine neue Brain-Version gibt. Aktualisieren geht mit /brain-update (oder manuell: {0}).'
        'fin_obsidian'= 'Tipp: Installiere Obsidian von https://obsidian.md und oeffne den Vault-Ordner darin, um dein Master Brain zu durchstoebern.'
    }
    'en' = @{
        'choice'            = 'Choice'
        'invalid_num'       = 'Please enter a number between 1 and {0}.'
        'invalid_num_file'  = 'Invalid answer in answer file (allowed: 1-{0}) - using default {1}.'
        'invalid_yn'        = 'Please answer y (yes) or n (no).'
        'too_short_generic' = 'Please enter a bit more text.'
        'yn_default_yes'    = '[Y/n]'
        'yn_default_no'     = '[y/N]'
        'q_of'              = 'Question {0} of 20'
        'backed_up'         = 'Backup: {0} -> {1}'

        'f2_q' = 'What should Claude call you?'
        'f2_x' = 'The name goes at the top of your configuration. First name is plenty.'
        'f2_r' = 'Please enter at least 2 characters, e.g. "Alex".'

        'f3_q' = 'How much experience do you have with Claude Code?'
        'f3_x' = 'Honest answers pay off: as a beginner, Claude explains more and checks in before doing anything complicated.'
        'f3_o' = @('Beginner - I am just getting started', 'Intermediate - I use it regularly', 'Pro - I know skills, agents, and hooks')

        'f4_q' = 'What do you want to do with Claude? Describe it in 1-3 sentences.'
        'f4_x' = 'e.g. "build FiveM scripts for my server", "develop a web app", "learn Python". Claude aligns with this and will not forget it.'
        'f4_r' = 'Describe it in one sentence, e.g.: "I want to build a small web app for my club."'

        'f5_q' = 'What is your main type of work?'
        'f5_x' = 'This decides which extra rules and ready-made work instructions (skills) Claude gets.'
        'f5_o' = @('General', 'Web frontend', 'Backend/APIs', 'Full-stack', 'FiveM/game scripts', 'DevOps', 'Data/Python', 'Marketing/copy')

        'f6_q' = 'Which programming languages/technologies do you work with? Comma-separated.'
        'f6_x' = 'e.g. "JavaScript, React" or "Python". If you do not know yet, just press Enter - Claude will figure it out while working.'
        'f6_d' = 'not sure yet'

        'f7_found'   = 'I checked: you are currently using {0}. Is that right?'
        'f7_found_x' = 'Claude comes in several models (from fast and cheap to maximally smart). I checked your Claude Code settings to see which one you use.'
        'f7_x'       = 'Claude comes in several models - from fast and cheap (Haiku) to maximum intelligence (Opus/Fable). If you do not know: start Claude Code and type /model - it will show you. You can also just pick "I do not know".'
        'f7_q'       = 'Which Claude model do you use?'
        'f7_o'       = @('Haiku (fast and cheap)', 'Sonnet (standard)', 'Opus (very strong)', 'Fable (top model)', 'I do not know')

        'f8_q' = 'How do you pay for Claude?'
        'f8_x' = 'On Pro the quota is smaller - Claude will configure itself to be more frugal.'
        'f8_o' = @('Claude Pro (about 20 EUR/month)', 'Claude Max', 'API credits', 'I do not know')

        'f9_q' = 'How frugal should Claude be with tokens?'
        'f9_x' = 'Tokens are Claude''s "unit of consumption". Frugal = Claude reads more selectively and summarizes more briefly.'
        'f9_o' = @('Conservative (quality over frugality)', 'Balanced', 'Aggressive (maximum savings)')

        'f10_q' = 'How should Claude plan?'
        'f10_x' = 'For bigger tasks, a short plan before writing code pays off.'
        'f10_o' = @('Plan automatically for bigger tasks (recommended)', 'Ask first', 'Minimal planning')

        'f11_q' = 'Which code style should Claude write?'
        'f11_x' = 'Production-grade means: proper error handling, tests, consistent patterns.'
        'f11_o' = @('Simple (small private scripts)', 'Production-grade (recommended)', 'Strict', 'Architecture-focused')

        'f12_q' = 'When should Claude write tests?'
        'f12_x' = 'Tests make sure changes do not break things.'
        'f12_o' = @('Always write tests', 'Only for risky/complex changes (recommended)', 'Ask first')

        'f13_q' = 'How strict should Claude be about security?'
        'f13_x' = 'Building something with login, payments, or user data? Then pick at least "Strict".'
        'f13_o' = @('Standard', 'Strict', 'Very strict')

        'f14_q'    = 'Enable the FiveM module?'
        'f14_x'    = 'FiveM is a modding platform for GTA V. Only relevant if you build scripts for it.'
        'f14_skip' = 'FiveM module is enabled automatically because your main work type is FiveM/game scripts.'

        'f15_q' = 'Enable the marketing module?'
        'f15_x' = 'Adds writing rules for marketing and sales copy.'

        'f16_q' = 'How should Claude interact with you?'
        'f16_x' = 'Option 1 means: Claude tells you honestly when a plan will cause problems, and suggests something better.'
        'f16_o' = @('Partner with its own opinion - pushes back when something is a bad idea (recommended)', 'Reserved - just does what you say')

        'f17_q' = 'Set up the Obsidian Master Brain?'
        'f17_x' = 'The Master Brain is Claude''s long-term memory: a folder of notes where Claude stores projects, decisions, and knowledge about your collaboration - across sessions. Obsidian (obsidian.md, free) is an app that displays and links these notes nicely. The memory works without the app too - the notes are plain text files.'

        'f17a_q'    = 'Do you already have Obsidian installed?'
        'f17a_o'    = @('Yes', 'No', 'I do not know')
        'f17a_how'  = 'How to check: search your Start menu/applications for "Obsidian".'
        'f17a_note' = 'No problem - I will create the memory anyway. You can install Obsidian later from https://obsidian.md and open the folder as a vault.'

        'f17b_q'      = 'Where should the memory (the vault) live?'
        'f17b_x'      = 'Press Enter to accept the suggestion. The folder is created if it does not exist.'
        'f17b_exists' = 'That folder already exists and is not empty. What should we do?'
        'f17b_o'      = @('Keep using it as an existing vault (only add missing files, overwrite NOTHING)', 'Choose a different path')

        'f18_q' = 'What do you want to work on first? A short name is enough (Enter = skip).'
        'f18_x' = 'e.g. "my-server" or "shop-website". Claude creates a project note for it in the memory.'

        'f19_q' = 'Should Claude notify you about Brain updates?'
        'f19_x' = 'Once a day, a tiny script checks at startup whether a new Brain version exists on GitHub (a single small request; none of your data is sent). If there is one, Claude tells you and you can update with /brain-update.'

        'f20_q' = 'Install the Brain skills?'
        'f20_x' = 'Skills are ready-made work instructions for Claude (e.g. a security check). Plain text files - they never execute anything by themselves.'

        'sum_title'    = 'Summary of your answers'
        'sum_confirm'  = 'Does this look right?'
        'sum_abort'    = 'All good - nothing was written. Just restart the setup when you are ready.'
        'sum_name'     = 'Name'
        'sum_lang'     = 'Language'
        'sum_exp'      = 'Experience'
        'sum_goals'    = 'Goals'
        'sum_work'     = 'Work type'
        'sum_stacks'   = 'Tech stacks'
        'sum_model'    = 'Model'
        'sum_plan'     = 'Plan'
        'sum_token'    = 'Token strategy'
        'sum_planning' = 'Planning'
        'sum_style'    = 'Code style'
        'sum_testing'  = 'Testing'
        'sum_security' = 'Security level'
        'sum_fivem'    = 'FiveM module'
        'sum_mkt'      = 'Marketing module'
        'sum_partner'  = 'Interaction'
        'sum_vault'    = 'Master Brain (vault)'
        'sum_project'  = 'First project'
        'sum_update'   = 'Update notifications'
        'sum_skills'   = 'Install skills'
        'sum_yes'      = 'yes'
        'sum_no'       = 'no'
        'sum_none'     = '(none)'
        'sum_disabled' = 'disabled'

        'mig_info'    = 'Note: a CLAUDE.md from version 1 still exists at: {0}. The new version lives at ~/.claude/CLAUDE.md. Two files can contradict each other.'
        'mig_q'       = 'Should I safely rename the old file (nothing gets deleted)?'
        'mig_done'    = 'Old file renamed to: {0}'
        'mig_warn'    = 'Warning: both CLAUDE.md files remain and may contradict each other. You can remove the old file yourself later.'

        'wr_writing'    = 'Writing files...'
        'wr_claudemd'   = 'CLAUDE.md written: {0}'
        'wr_skills'     = 'Installed skill: {0}'
        'wr_skills_n'   = '{0} skill(s) installed to: {1}'
        'wr_skills_src' = 'Warning: skills folder not found ({0}) - skipping skills.'
        'wr_vault_new'  = 'Master Brain created: {0}'
        'wr_vault_add'  = 'Existing vault extended (missing files only): {0}'
        'wr_vault_tpl'  = 'Warning: vault templates not found ({0}) - skipping vault.'
        'wr_config'     = 'config.json written: {0}'
        'wr_hook_ok'    = 'Update hook registered in settings.json.'
        'wr_hook_have'  = 'Update hook already registered - nothing changed.'
        'wr_hook_skip'  = 'Update notifications disabled - no hook registered.'
        'wr_hook_fail'  = 'settings.json could not be updated automatically ({0}). Add this entry manually under "hooks":'
        'wr_brain'      = 'Brain runtime installed: {0}'

        'dry_note'  = '[DRY RUN] Nothing will be written.'
        'dry_done'  = '[DRY RUN] Done. Above is the generated CLAUDE.md. Nothing was written.'

        'fin_title'   = 'Done! Claude Brain is set up.'
        'fin_where'   = 'This is now on your machine:'
        'fin_claudemd'= 'Your configuration:   {0}'
        'fin_skills'  = 'Brain skills:         {0}'
        'fin_brain'   = 'Brain runtime:        {0}'
        'fin_vault'   = 'Master Brain (vault): {0}'
        'fin_start1'  = 'Getting started: open a terminal and simply type:'
        'fin_start2'  = 'Then just start typing - Claude now knows your name, your goals, and your rules.'
        'fin_update'  = 'Updates: Claude will tell you when a new Brain version is available. Update with /brain-update (or manually: {0}).'
        'fin_obsidian'= 'Tip: install Obsidian from https://obsidian.md and open the vault folder in it to browse your Master Brain.'
    }
}

#endregion

#region ── Questions (F1-F20) ─────────────────────────────────────────────────

Write-Title "Claude Brain Setup $BrainVersion (Windows)"
Write-Host "Interaktive Einrichtung / Interactive setup"
if ($DryRun) { Write-Warn2 '[DRY RUN] Es wird nichts geschrieben. / Nothing will be written.' }
Write-Host ""

if (-not (Test-Path $TemplateFile)) {
    Write-Host "Template not found: $TemplateFile" -ForegroundColor Red
    Write-Host "Run this script from inside the claude-brain-setup folder."
    exit 1
}

# ── F1: Language ── (asked bilingually, before a language is set)
$langDefault = 2
try {
    if ((Get-Culture).TwoLetterISOLanguageName -eq 'de') { $langDefault = 1 }
} catch { $langDefault = 2 }

Show-QHeader 1
$f1 = Ask-Choice -Question 'Sprache / Language' -Options @('Deutsch', 'English') -Default $langDefault `
    -Explain 'In welcher Sprache soll dieses Setup und spaeter Claude mit dir sprechen? / Which language should this setup and Claude use?'
if ($f1 -eq 1) {
    $Script:Lang = 'de'
    $LanguageName = 'German'
} else {
    $Script:Lang = 'en'
    $LanguageName = 'English'
}

# ── F2: Name ──
Show-QHeader 2
$UserName = Ask-Text -Question (T 'f2_q') -MinLen 2 -RetryHint (T 'f2_r') -Explain (T 'f2_x')
if ([string]::IsNullOrWhiteSpace($UserName)) { $UserName = 'User' }

# ── F3: Experience ──
Show-QHeader 3
$f3 = Ask-Choice -Question (T 'f3_q') -Options (T 'f3_o') -Default 1 -Explain (T 'f3_x')
$ExperienceKey   = @('beginner', 'intermediate', 'pro')[$f3 - 1]
$ExperienceLabel = (T 'f3_o')[$f3 - 1]

# ── F4: Goals ──
Show-QHeader 4
$Goals = Ask-Text -Question (T 'f4_q') -MinLen 10 -RetryHint (T 'f4_r') -Explain (T 'f4_x')
if ([string]::IsNullOrWhiteSpace($Goals)) { $Goals = '(not specified yet)' }

# ── F5: Main work type ──
Show-QHeader 5
$f5 = Ask-Choice -Question (T 'f5_q') -Options (T 'f5_o') -Default 1 -Explain (T 'f5_x')
$MainWorkTypes = @(
    'General software development', 'Web frontend', 'Backend/APIs', 'Full-stack',
    'FiveM / game scripts', 'DevOps', 'Data / Python', 'Marketing / copywriting'
)
$MainWorkType      = $MainWorkTypes[$f5 - 1]
$MainWorkTypeLabel = (T 'f5_o')[$f5 - 1]

# ── F6: Tech stacks ──
Show-QHeader 6
$Stacks = Ask-Text -Question (T 'f6_q') -Default (T 'f6_d') -Explain (T 'f6_x')

# ── F7: Model detection ──
Show-QHeader 7
$ModelKey = 'unknown'
$ModelRaw = $null
$detected = $null
if (Test-Path $SettingsFile) {
    try {
        $existingSettings = Get-Content $SettingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($existingSettings.PSObject.Properties['model']) {
            $rawModel = [string]$existingSettings.model
            if (-not [string]::IsNullOrWhiteSpace($rawModel)) {
                $lower = $rawModel.ToLowerInvariant()
                if ($lower.Contains('fable'))      { $detected = 'fable' }
                elseif ($lower.Contains('opus'))   { $detected = 'opus' }
                elseif ($lower.Contains('sonnet')) { $detected = 'sonnet' }
                elseif ($lower.Contains('haiku'))  { $detected = 'haiku' }
                if ($detected) { $ModelRaw = $rawModel }
            }
        }
    } catch {
        $detected = $null
    }
}

$ModelDisplayNames = @{ 'haiku' = 'Haiku'; 'sonnet' = 'Sonnet'; 'opus' = 'Opus'; 'fable' = 'Fable' }

$modelConfirmed = $false
if ($detected) {
    $ok = Ask-YesNo -Question ((T 'f7_found') -f $ModelDisplayNames[$detected]) -DefaultYes $true -Explain (T 'f7_found_x')
    if ($ok) {
        $ModelKey = $detected
        $modelConfirmed = $true
    }
}
if (-not $modelConfirmed) {
    $f7 = Ask-Choice -Question (T 'f7_q') -Options (T 'f7_o') -Default 5 -Explain (T 'f7_x')
    $ModelKey = @('haiku', 'sonnet', 'opus', 'fable', 'unknown')[$f7 - 1]
    if ($ModelKey -ne $detected) { $ModelRaw = $null }
}
if ($ModelKey -eq 'unknown') {
    $ModelLabel = (T 'f7_o')[4]
} else {
    $ModelLabel = $ModelDisplayNames[$ModelKey]
}

# ── F8: Plan tier ──
Show-QHeader 8
$f8 = Ask-Choice -Question (T 'f8_q') -Options (T 'f8_o') -Default 4 -Explain (T 'f8_x')
$PlanTier  = @('pro', 'max', 'api', 'unknown')[$f8 - 1]
$PlanLabel = (T 'f8_o')[$f8 - 1]

# ── F9: Token strategy (default depends on F8) ──
Show-QHeader 9
if ($PlanTier -eq 'pro') { $tokenDefault = 3 } else { $tokenDefault = 2 }
$f9 = Ask-Choice -Question (T 'f9_q') -Options (T 'f9_o') -Default $tokenDefault -Explain (T 'f9_x')
$TokenStrategy = @('Conservative', 'Balanced', 'Aggressive')[$f9 - 1]
$TokenLabel    = (T 'f9_o')[$f9 - 1]

# ── F10: Planning ──
Show-QHeader 10
$f10 = Ask-Choice -Question (T 'f10_q') -Options (T 'f10_o') -Default 1 -Explain (T 'f10_x')
$PlanningKey   = $f10
$PlanningLabel = (T 'f10_o')[$f10 - 1]

# ── F11: Code style ──
Show-QHeader 11
$f11 = Ask-Choice -Question (T 'f11_q') -Options (T 'f11_o') -Default 2 -Explain (T 'f11_x')
$CodeStyleKey   = $f11
$CodeStyleLabel = (T 'f11_o')[$f11 - 1]

# ── F12: Testing ──
Show-QHeader 12
$f12 = Ask-Choice -Question (T 'f12_q') -Options (T 'f12_o') -Default 2 -Explain (T 'f12_x')
$TestingKey   = $f12
$TestingLabel = (T 'f12_o')[$f12 - 1]

# ── F13: Security level ──
Show-QHeader 13
$f13 = Ask-Choice -Question (T 'f13_q') -Options (T 'f13_o') -Default 1 -Explain (T 'f13_x')
$SecurityLevel = @('Standard', 'Strict', 'Very Strict')[$f13 - 1]
$SecurityLabel = (T 'f13_o')[$f13 - 1]

# ── F14: FiveM module (auto-yes if F5 = FiveM) ──
Show-QHeader 14
if ($f5 -eq 5) {
    Write-Note (T 'f14_skip')
    $FivemEnabled = $true
} else {
    $FivemEnabled = Ask-YesNo -Question (T 'f14_q') -DefaultYes $false -Explain (T 'f14_x')
}

# ── F15: Marketing module ──
Show-QHeader 15
$MarketingEnabled = Ask-YesNo -Question (T 'f15_q') -DefaultYes $false -Explain (T 'f15_x')

# ── F16: Partner mode ──
Show-QHeader 16
$f16 = Ask-Choice -Question (T 'f16_q') -Options (T 'f16_o') -Default 1 -Explain (T 'f16_x')
$PartnerMode  = $f16
$PartnerLabel = (T 'f16_o')[$f16 - 1]

# ── F17: Obsidian Master Brain ──
Show-QHeader 17
$ObsidianEnabled      = Ask-YesNo -Question (T 'f17_q') -DefaultYes $true -Explain (T 'f17_x')
$ObsidianAppInstalled = $false
$VaultPath            = ''
$VaultReuse           = $false

if ($ObsidianEnabled) {
    # F17a: app installed?
    $f17a = Ask-Choice -Question (T 'f17a_q') -Options (T 'f17a_o') -Default 3
    if ($f17a -eq 1) {
        $ObsidianAppInstalled = $true
    } else {
        if ($f17a -eq 3) { Write-Note (T 'f17a_how') }
        Write-Note (T 'f17a_note')
    }

    # F17b: vault path (loop until a usable path is chosen)
    $vaultDefault = Join-Path $HomeDir 'Documents\ClaudeBrainVault'
    $vaultDone = $false
    while (-not $vaultDone) {
        $VaultPath = Ask-Text -Question (T 'f17b_q') -Default $vaultDefault -Explain (T 'f17b_x')
        if ($VaultPath.StartsWith('~')) {
            $VaultPath = Join-Path $HomeDir ($VaultPath.TrimStart('~').TrimStart('\', '/'))
        }
        $isNonEmpty = $false
        if (Test-Path -LiteralPath $VaultPath) {
            $children = @(Get-ChildItem -LiteralPath $VaultPath -Force -ErrorAction SilentlyContinue)
            if ($children.Count -gt 0) { $isNonEmpty = $true }
        }
        if ($isNonEmpty) {
            $f17b = Ask-Choice -Question (T 'f17b_exists') -Options (T 'f17b_o') -Default 1
            if ($f17b -eq 1) {
                $VaultReuse = $true
                $vaultDone = $true
            }
            # option 2: loop and ask for another path
        } else {
            $vaultDone = $true
        }
    }
}

# ── F18: First project ──
Show-QHeader 18
$ProjectName = Ask-Text -Question (T 'f18_q') -Explain (T 'f18_x')
$ProjectSlug = ''
if (-not [string]::IsNullOrWhiteSpace($ProjectName)) {
    $ProjectSlug = New-Slug $ProjectName
    if ([string]::IsNullOrWhiteSpace($ProjectSlug)) { $ProjectSlug = 'projekt-1' }
} else {
    $ProjectName = ''
}

# ── F19: Update notifications ──
Show-QHeader 19
$UpdateCheckEnabled = Ask-YesNo -Question (T 'f19_q') -DefaultYes $true -Explain (T 'f19_x')

# ── F20: Install skills ──
Show-QHeader 20
$InstallSkills = Ask-YesNo -Question (T 'f20_q') -DefaultYes $true -Explain (T 'f20_x')

#endregion

#region ── Summary + confirmation ────────────────────────────────────────────

function Format-YesNo {
    param([bool]$Value)
    if ($Value) { return (T 'sum_yes') }
    return (T 'sum_no')
}

Write-Title (T 'sum_title')
$langDisplay = @('Deutsch', 'English')[$f1 - 1]
Write-Host ("  {0,-24} {1}" -f ((T 'sum_name') + ':'),     $UserName)
Write-Host ("  {0,-24} {1}" -f ((T 'sum_lang') + ':'),     $langDisplay)
Write-Host ("  {0,-24} {1}" -f ((T 'sum_exp') + ':'),      $ExperienceLabel)
Write-Host ("  {0,-24} {1}" -f ((T 'sum_goals') + ':'),    $Goals)
Write-Host ("  {0,-24} {1}" -f ((T 'sum_work') + ':'),     $MainWorkTypeLabel)
Write-Host ("  {0,-24} {1}" -f ((T 'sum_stacks') + ':'),   $Stacks)
Write-Host ("  {0,-24} {1}" -f ((T 'sum_model') + ':'),    $ModelLabel)
Write-Host ("  {0,-24} {1}" -f ((T 'sum_plan') + ':'),     $PlanLabel)
Write-Host ("  {0,-24} {1}" -f ((T 'sum_token') + ':'),    $TokenLabel)
Write-Host ("  {0,-24} {1}" -f ((T 'sum_planning') + ':'), $PlanningLabel)
Write-Host ("  {0,-24} {1}" -f ((T 'sum_style') + ':'),    $CodeStyleLabel)
Write-Host ("  {0,-24} {1}" -f ((T 'sum_testing') + ':'),  $TestingLabel)
Write-Host ("  {0,-24} {1}" -f ((T 'sum_security') + ':'), $SecurityLabel)
Write-Host ("  {0,-24} {1}" -f ((T 'sum_fivem') + ':'),    (Format-YesNo $FivemEnabled))
Write-Host ("  {0,-24} {1}" -f ((T 'sum_mkt') + ':'),      (Format-YesNo $MarketingEnabled))
Write-Host ("  {0,-24} {1}" -f ((T 'sum_partner') + ':'),  $PartnerLabel)
if ($ObsidianEnabled) {
    Write-Host ("  {0,-24} {1}" -f ((T 'sum_vault') + ':'), $VaultPath)
} else {
    Write-Host ("  {0,-24} {1}" -f ((T 'sum_vault') + ':'), (T 'sum_disabled'))
}
if ($ProjectName) {
    Write-Host ("  {0,-24} {1}" -f ((T 'sum_project') + ':'), $ProjectName)
} else {
    Write-Host ("  {0,-24} {1}" -f ((T 'sum_project') + ':'), (T 'sum_none'))
}
Write-Host ("  {0,-24} {1}" -f ((T 'sum_update') + ':'),  (Format-YesNo $UpdateCheckEnabled))
Write-Host ("  {0,-24} {1}" -f ((T 'sum_skills') + ':'),  (Format-YesNo $InstallSkills))

$confirmed = Ask-YesNo -Question (T 'sum_confirm') -DefaultYes $true
if (-not $confirmed) {
    Write-Host ""
    Write-Host (T 'sum_abort')
    exit 0
}

#endregion

#region ── Generation (CLAUDE.md content blocks) ─────────────────────────────

# All generated CLAUDE.md content is English by design; the language directive
# controls the language Claude responds in.

$NL = "`n"

# {{LANGUAGE_DIRECTIVE}}
if ($Script:Lang -eq 'de') {
    $LanguageDirective = 'Antworte immer auf Deutsch. Code, Befehle und Fachbegriffe bleiben im Original.'
} else {
    $LanguageDirective = ''
}

# {{EXPERIENCE_SECTION}}
$ExperienceSection = ''
if ($ExperienceKey -eq 'beginner') {
    $ExperienceSection = '## Beginner Mode' + $NL + $NL +
        ($UserName + ' is new to Claude Code. Therefore:') + $NL +
        '- Explain each step in simple language before doing it.' + $NL +
        '- Ask before any risky or hard-to-reverse action.' + $NL +
        '- Suggest exactly ONE next step at a time - never a wall of options.' + $NL +
        '- When a technical term is unavoidable, add a one-line explanation.'
}

# {{MODEL_SECTION}} (Claude 5 family routing table, §5.3)
$RoutingTable =
    '| Task | Model | Launch |' + $NL +
    '|---|---|---|' + $NL +
    '| Formatting, renaming, simple edits | Haiku 4.5 | `claude --model claude-haiku-4-5-20251001` |' + $NL +
    '| Standard development work | Sonnet 5 | `claude --model claude-sonnet-5` |' + $NL +
    '| Architecture, security, complex multi-file work | Opus 4.8 | `claude --model claude-opus-4-8` |' + $NL +
    '| Hardest problems, top-tier reasoning | Fable 5 | `claude --model claude-fable-5` |' + $NL + $NL +
    '(Fable access depends on your plan.)'

switch ($ModelKey) {
    'haiku' {
        $ModelSection = "Current model: **Haiku 4.5**." + $NL + $NL + $RoutingTable + $NL + $NL +
            '**Note:** For architecture, security, or multi-file work, start a session with a stronger model.'
    }
    'opus' {
        $ModelSection = "Current model: **Opus 4.8**." + $NL + $NL + $RoutingTable + $NL + $NL +
            'You are running a top-tier model - delegate mechanical bulk work to cheaper agent models (Haiku) where sensible.'
    }
    'fable' {
        $ModelSection = "Current model: **Fable 5**." + $NL + $NL + $RoutingTable + $NL + $NL +
            'You are running a top-tier model - delegate mechanical bulk work to cheaper agent models (Haiku) where sensible.'
    }
    'sonnet' {
        $ModelSection = "Current model: **Sonnet 5**." + $NL + $NL + $RoutingTable
    }
    default {
        $ModelSection = $RoutingTable + $NL + $NL +
            'Tip: run `/model` inside Claude Code to see which model the current session uses.'
    }
}

# {{PLANNING_PREFERENCE}}
switch ($PlanningKey) {
    1 { $PlanningPreference = 'Always plan first when the task touches 3 or more files, changes a public API or database schema, involves auth/payments/user data, or has unclear scope. Wait for confirmation of the plan before writing code.' }
    2 { $PlanningPreference = 'Ask the user before creating a plan. Suggest planning when the task touches 3 or more files or has unclear scope.' }
    3 { $PlanningPreference = 'Keep plans minimal. Only create a written plan when the user explicitly asks for one.' }
}

# {{FIRST_PROJECT_LINE}}
$FirstProjectLine = ''
if ($ProjectName) {
    $FirstProjectLine = '**Current project:** ' + $ProjectName
    if ($ObsidianEnabled) {
        $FirstProjectLine += ' (hub note: `projects/' + $ProjectSlug + '.md` in the vault)'
    }
}

# {{CODE_STYLE}}
switch ($CodeStyleKey) {
    1 { $CodeStyle = 'Keep code simple and readable. Avoid over-engineering. Favour explicitness over abstraction.' }
    2 { $CodeStyle = 'Write production-grade code: proper error handling, consistent patterns, tests for new functionality. Functions under 50 lines. No nesting beyond 4 levels.' }
    3 { $CodeStyle = 'Strict conventions: full type safety, architectural patterns, no shortcuts. All edge cases handled. Comprehensive tests.' }
    4 { $CodeStyle = 'Architecture first: define module boundaries and interfaces before implementation. Full type safety where the language supports it. Document key design decisions. Proper error handling and tests throughout.' }
}

# {{TESTING_PREFERENCE}}
switch ($TestingKey) {
    1 { $TestingPreference = 'Always write tests for new functionality. Do not mark a task done without tests.' }
    2 { $TestingPreference = 'Write tests for risky, complex, or user-facing changes. Skip tests for trivial edits, config changes, and doc updates.' }
    3 { $TestingPreference = 'Ask the user before writing tests. Do not add tests without being asked.' }
}

# {{SECURITY_RULES}} / {{SECURITY_GATE}}
switch ($SecurityLevel) {
    'Standard' {
        $SecurityRules =
            '- Never hardcode API keys, passwords, or tokens. Use environment variables.' + $NL +
            '- Never commit .env files or credentials.' + $NL +
            '- Validate user input at system boundaries.'
        $SecurityGate = '- [ ] Security-sensitive changes reviewed with `/brain-security-review`'
    }
    'Strict' {
        $SecurityRules =
            '- Never hardcode any secret. Use environment variables or a secrets manager.' + $NL +
            '- Never commit .env files or credentials.' + $NL +
            '- Run `/brain-security-review` before any commit that touches auth, payments, user data, file system access, or external API calls.' + $NL +
            '- Validate all user input. Parameterize all SQL queries. Sanitize HTML output.' + $NL +
            '- Rate limit all user-facing endpoints.'
        $SecurityGate = '- [ ] Security-sensitive changes reviewed with `/brain-security-review` before committing'
    }
    'Very Strict' {
        $SecurityRules =
            '- Never hardcode any secret under any circumstances.' + $NL +
            '- Run `/brain-security-review` before every commit that touches auth, payments, user data, file system, or external APIs. This is not optional.' + $NL +
            '- Validate all input at every boundary. No exceptions.' + $NL +
            '- All SQL queries parameterized. All HTML output sanitized.' + $NL +
            '- Rate limit all endpoints. CSRF protection on all state-changing forms.' + $NL +
            '- Error messages must not leak sensitive data or stack traces to users.'
        $SecurityGate = '- [ ] `/brain-security-review` run and all issues addressed before committing'
    }
}

# {{TOKEN_RULES}}
switch ($TokenStrategy) {
    'Conservative' {
        $TokenRules =
            '- Search before reading. Use grep or find to locate code before reading full files.' + $NL +
            '- Issue multiple independent reads in one message, not sequentially.' + $NL +
            '- Summarise command output - do not paste raw long output.' + $NL +
            '- Create a handoff and start a fresh session when the conversation grows large.'
    }
    'Balanced' {
        $TokenRules =
            '- Search before reading when the target is unclear.' + $NL +
            '- Batch independent operations in one message.' + $NL +
            '- Start a new session instead of resuming a very large one.'
    }
    'Aggressive' {
        $TokenRules =
            '- Always search before reading any file.' + $NL +
            '- Batch all independent operations in a single message.' + $NL +
            '- Hard limit on session length: use `/brain-session-handoff` proactively before the session grows too large.' + $NL +
            '- Never paste raw command output. Always summarise.' + $NL +
            '- Do not load skills speculatively. One skill at a time, on demand only.'
    }
}

# Orchestration is fixed at "Balanced" in V2 (no longer asked).
$OrchestrationLevel = 'Balanced'
$OrchestrationRules =
    'Use agents when work is genuinely parallel or needs specialisation. Do not spawn agents for single-file edits, quick questions, or config changes. Rule: if you can finish the task alone in under 15 minutes, skip agents.'

# {{TEAM_RULES}}
if ($PartnerMode -eq 1) {
    $TeamRules = '## Team Rules' + $NL + $NL +
        '- Claude is a partner with its own judgment, not a yes-man. Never agree just to please.' + $NL +
        '- Push back when a request is pointless, risky, or clearly worse than an obvious alternative - say why and propose the better way.' + $NL +
        '- If a prompt is too vague to finish the job well, ask for a sharper definition before writing code.' + $NL +
        '- Important decisions - architecture, public APIs, deletions - are made together.' + $NL +
        "- While working in $UserName's code, keep an eye out for bugs beyond the immediate task; flag them, don't silently fix out-of-scope." + $NL +
        '- Otherwise act autonomously: no permission-asking for reversible steps that follow from the task.' + $NL +
        '- ALWAYS ask before deleting files/data or any destructive, hard-to-reverse action - regardless of the active permission mode.'
} else {
    $TeamRules = '## Interaction Mode' + $NL + $NL +
        '- Execute requests as given; keep unsolicited opinions to a minimum.' + $NL +
        '- Exception: always warn before destructive or hard-to-reverse actions, and always ask before deleting files or data.'
}

# {{OBSIDIAN_SECTION}}
if ($ObsidianEnabled) {
    $ObsidianSection = '## Obsidian Master Brain' + $NL + $NL +
        ('Vault: `' + $VaultPath + '` - Claude''s cross-project memory. One vault for everything; wikilinks do not work across vaults. A new independent project gets a new NOTE in `projects/`, never a new vault. Related projects link to each other and share knowledge notes.') + $NL + $NL +
        'For every non-trivial task:' + $NL +
        '1. Session start: read the vault''s `CLAUDE.md` + `index.md`, then the relevant `projects/<name>.md` hub note. Follow links from there - never scan the whole vault.' + $NL +
        '2. Durable insight -> atomic note in `knowledge/`, linked from a MOC or project hub. Decision -> `decisions/YYYY-MM-DD-decision-<project>-<slug>.md`.' + $NL +
        '3. End of a complex session: write `sessions/YYYY-MM-DD-<project>.md`, update the project hub and `index.md`.' + $NL +
        ('4. New observations about ' + $UserName + ' (working style, code style, preferences) go into `me/`.') + $NL +
        '5. The vault''s own `CLAUDE.md` holds the full writing conventions - follow them.'
} else {
    $ObsidianSection = 'Note: the Obsidian Master Brain (persistent cross-project memory) is not set up. Re-run the Claude Brain setup wizard anytime to add it.'
}

# {{UPDATE_SECTION}}
$UpdateSection = '## Brain Updates' + $NL + $NL +
    ('- Installed Claude Brain version: ' + $BrainVersion + ' (see `~/.claude/brain/VERSION`).') + $NL
if ($UpdateCheckEnabled) {
    $UpdateSection += '- A SessionStart hook checks GitHub once a day for a newer version and reports it in the session.' + $NL
} else {
    $UpdateSection += '- Automatic update checks are disabled. Check manually when asked.' + $NL
}
$UpdateSection += '- To update: run `/brain-update`, or manually: `powershell -File ~/.claude/brain/update.ps1`.'

# {{MARKETING_SUPPORT}}
$MarketingBlock = ''
if ($MarketingEnabled) {
    $MarketingBlock = '## Marketing and Sales Support' + $NL + $NL +
        'When writing sales, marketing, or customer-facing copy:' + $NL +
        '- Write in clear, direct language. No corporate filler or AI-sounding bullet lists.' + $NL +
        '- Prefer flowing prose for short messages. Use lists only for 4+ parallel items.' + $NL +
        '- If no brand voice is defined, ask before writing.' + $NL +
        '- Useful skill: `/brain-marketing-support`.'
}

# {{FIVEM_SUPPORT}}
$FivemBlock = ''
if ($FivemEnabled) {
    $FivemBlock = '## FiveM Development' + $NL + $NL +
        'When working on FiveM scripts:' + $NL +
        '- Never use `Wait(0)` in permanent loops. Use adaptive wait based on distance checks.' + $NL +
        '- Server is authoritative. Validate all client events on the server. Never trust client data.' + $NL +
        '- Use ox_lib target zones instead of distance check loops with every-frame threads.' + $NL +
        '- NUI backgrounds must be transparent: `html, body { background: transparent !important; }`' + $NL +
        '- Animate only compositor-friendly properties: `transform` and `opacity`.' + $NL +
        '- Use statebags for state sync. Avoid event spam.' + $NL +
        '- Verify all natives at docs.fivem.net before using them. Never guess native names.' + $NL +
        '- Useful skill: `/brain-fivem-development`.'
}

# {{SELECTED_SKILLS}}
if ($InstallSkills) {
    $SelectedSkills = 'Bundled Brain skills:' + $NL +
        '- `/brain-core-workflow` - disciplined development workflow' + $NL +
        '- `/brain-token-discipline` - token-efficient working habits' + $NL +
        '- `/brain-session-handoff` - session handoff before model switch or end' + $NL +
        '- `/brain-security-review` - security checklist for code and repos' + $NL +
        '- `/brain-model-routing` - pick the right Claude model for the task' + $NL +
        '- `/brain-update` - check for and apply Claude Brain updates' + $NL +
        '- `/brain-karpathy-principles` - guardrails against common LLM coding mistakes' + $NL +
        '- `/brain-github-release` - prepare and publish GitHub releases' + $NL +
        '- `/brain-pr-review` - pull request review workflow' + $NL +
        '- `/brain-ruflo-orchestration` - multi-agent orchestration patterns' + $NL +
        '- `/brain-skill-authoring` - write new skills' + $NL +
        '- `/brain-cross-platform-setup` - project setup across Windows/Linux/macOS' + $NL +
        '- `/brain-marketing-support` - marketing and sales copy support' + $NL +
        '- `/brain-fivem-development` - FiveM script development'
} else {
    $SelectedSkills = 'Bundled Brain skills are not installed. Install them anytime with `scripts/install.sh --skills-only` / `scripts\install.ps1 -SkillsOnly` from the claude-brain-setup folder.'
}

# ── Fill the template ─────────────────────────────────────────────────────────

function Build-ClaudeMd {
    $content = Get-Content $TemplateFile -Raw -Encoding UTF8
    # Normalize to LF while building; Write-Utf8NoBom writes it back as-is.
    $content = $content.Replace("`r`n", "`n")

    $replacements = @{
        '{{USER_NAME}}'           = $UserName
        '{{LANGUAGE_NAME}}'       = $LanguageName
        '{{LANGUAGE_DIRECTIVE}}'  = $LanguageDirective
        '{{GOALS}}'               = $Goals
        '{{EXPERIENCE_SECTION}}'  = $ExperienceSection
        '{{MODEL_SECTION}}'       = $ModelSection
        '{{PLANNING_PREFERENCE}}' = $PlanningPreference
        '{{MAIN_WORK_TYPE}}'      = $MainWorkType
        '{{PREFERRED_STACKS}}'    = $Stacks
        '{{FIRST_PROJECT_LINE}}'  = $FirstProjectLine
        '{{CODE_STYLE}}'          = $CodeStyle
        '{{TESTING_PREFERENCE}}'  = $TestingPreference
        '{{SECURITY_LEVEL}}'      = $SecurityLevel
        '{{SECURITY_RULES}}'      = $SecurityRules
        '{{SECURITY_GATE}}'       = $SecurityGate
        '{{TOKEN_STRATEGY}}'      = $TokenStrategy
        '{{TOKEN_RULES}}'         = $TokenRules
        '{{ORCHESTRATION_LEVEL}}' = $OrchestrationLevel
        '{{ORCHESTRATION_RULES}}' = $OrchestrationRules
        '{{TEAM_RULES}}'          = $TeamRules
        '{{OBSIDIAN_SECTION}}'    = $ObsidianSection
        '{{UPDATE_SECTION}}'      = $UpdateSection
        '{{MARKETING_SUPPORT}}'   = $MarketingBlock
        '{{FIVEM_SUPPORT}}'       = $FivemBlock
        '{{SELECTED_SKILLS}}'     = $SelectedSkills
    }

    # First replace all non-empty values, then remove entire lines that still
    # contain a placeholder whose value is empty (no blank-line leftovers).
    foreach ($key in $replacements.Keys) {
        $val = $replacements[$key]
        if (-not [string]::IsNullOrEmpty($val)) {
            $content = $content.Replace($key, $val)
        }
    }
    $content = $content -replace '(?m)^.*\{\{[A-Z_]+\}\}.*\n?', ''

    # Collapse runs of 3+ newlines into exactly one blank line.
    $content = $content -replace '\n{3,}', "`n`n"
    return $content.TrimEnd("`n") + "`n"
}

$GeneratedClaudeMd = Build-ClaudeMd

#endregion

#region ── Installation ──────────────────────────────────────────────────────

# Dry run: print the generated CLAUDE.md and stop before writing anything.
if ($DryRun) {
    Write-Host ""
    Write-Warn2 (T 'dry_note')
    Write-Host ""
    Write-Host '=== CLAUDE.md ===================================================' -ForegroundColor Cyan
    Write-Host $GeneratedClaudeMd
    Write-Host '=================================================================' -ForegroundColor Cyan
    Write-Host ""
    Write-Warn2 (T 'dry_done')
    exit 0
}

Write-Host ""
Write-Host (T 'wr_writing') -ForegroundColor Cyan

# ── Step 1+2: backup + write CLAUDE.md ────────────────────────────────────────
Ensure-Dir $ClaudeDir
Backup-File $ClaudeMdOut | Out-Null
Write-Utf8NoBom -Path $ClaudeMdOut -Content $GeneratedClaudeMd
Write-Step ((T 'wr_claudemd') -f $ClaudeMdOut)

# ── Step 3: skills ────────────────────────────────────────────────────────────
if ($InstallSkills) {
    if (-not (Test-Path $SkillsSrc)) {
        Write-Warn2 ((T 'wr_skills_src') -f $SkillsSrc)
    } else {
        Ensure-Dir $SkillsDest
        $installedCount = 0
        Get-ChildItem -Path $SkillsSrc -Directory | ForEach-Object {
            $destSkill = Join-Path $SkillsDest $_.Name
            if (Test-Path -LiteralPath $destSkill) {
                Rename-Item -LiteralPath $destSkill -NewName ($_.Name + ".backup-$Timestamp")
            }
            Copy-Item -Path $_.FullName -Destination $destSkill -Recurse
            Write-Step ((T 'wr_skills') -f $_.Name)
            $installedCount++
        }
        Write-Step ((T 'wr_skills_n') -f $installedCount, $SkillsDest)
    }
}

# ── Step 4: Obsidian vault ────────────────────────────────────────────────────

function Expand-VaultPlaceholders {
    param([string]$Text)
    if ($ProjectSlug) {
        $projLink = ('- [[projects/{0}|{1}]]' -f $ProjectSlug, $ProjectName)
    } else {
        if ($Script:Lang -eq 'de') {
            $projLink = '- (noch keine Projekte - Claude legt bei der ersten Aufgabe eines an)'
        } else {
            $projLink = '- (no projects yet - Claude creates one with your first task)'
        }
    }
    $Text = $Text.Replace('{{USER_NAME}}', $UserName)
    $Text = $Text.Replace('{{GOALS}}', $Goals)
    $Text = $Text.Replace('{{EXPERIENCE}}', $ExperienceLabel)
    $Text = $Text.Replace('{{MAIN_WORK_TYPE}}', $MainWorkTypeLabel)
    $Text = $Text.Replace('{{PREFERRED_STACKS}}', $Stacks)
    $Text = $Text.Replace('{{DATE}}', $Today)
    $Text = $Text.Replace('{{FIRST_PROJECT_LINK}}', $projLink)
    return $Text
}

function Install-Vault {
    $srcRoot = Join-Path $VaultTplRoot $Script:Lang
    if (-not (Test-Path $srcRoot)) {
        # Fall back to the English scaffold if the language variant is missing.
        $srcRoot = Join-Path $VaultTplRoot 'en'
    }
    if (-not (Test-Path $srcRoot)) {
        Write-Warn2 ((T 'wr_vault_tpl') -f $VaultTplRoot)
        return
    }

    Ensure-Dir $VaultPath

    # Copy scaffold: recreate directory structure, copy files that do not exist
    # yet, replace placeholders in every newly copied file. Never overwrite.
    $srcRootItem = Get-Item -LiteralPath $srcRoot
    Get-ChildItem -Path $srcRoot -Recurse | ForEach-Object {
        $relative = $_.FullName.Substring($srcRootItem.FullName.Length).TrimStart('\', '/')
        $destPath = Join-Path $VaultPath $relative
        if ($_.PSIsContainer) {
            Ensure-Dir $destPath
        } else {
            if (-not (Test-Path -LiteralPath $destPath)) {
                Ensure-Dir (Split-Path -Parent $destPath)
                $raw = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
                $raw = Expand-VaultPlaceholders $raw
                Write-Utf8NoBom -Path $destPath -Content $raw
            }
        }
    }

    # Standard working folders (created empty).
    foreach ($dir in @('projects', 'knowledge', 'decisions', 'sessions')) {
        Ensure-Dir (Join-Path $VaultPath $dir)
    }

    # First project note from the project template (F18).
    if ($ProjectSlug) {
        $projNote = Join-Path (Join-Path $VaultPath 'projects') ($ProjectSlug + '.md')
        if (-not (Test-Path -LiteralPath $projNote)) {
            $tplDir = Join-Path (Join-Path $VaultPath 'meta') 'templates'
            $projTpl = $null
            foreach ($candidate in @('projekt.md', 'project.md')) {
                $p = Join-Path $tplDir $candidate
                if (Test-Path -LiteralPath $p) { $projTpl = $p; break }
            }
            if ($projTpl) {
                $raw = Get-Content -LiteralPath $projTpl -Raw -Encoding UTF8
            } else {
                # Minimal fallback hub note if the template is missing.
                $raw = "# {{PROJECT_NAME}}`n`nCreated: {{DATE}}`nStatus: active`n`n## Overview`n`n## Notes`n"
            }
            $raw = $raw.Replace('{{PROJECT_NAME}}', $ProjectName)
            $raw = $raw.Replace('{{PROJECT_SLUG}}', $ProjectSlug)
            $raw = $raw.Replace('{{TITLE}}', $ProjectName)
            $raw = $raw.Replace('{{TITEL}}', $ProjectName)
            # Case-sensitive: the lowercase placeholders exist only in the
            # generated project note, not in the copied meta/templates files.
            $raw = $raw.Replace('{{title}}', $ProjectName)
            $raw = $raw.Replace('{{date}}', $Today)
            $raw = Expand-VaultPlaceholders $raw
            Write-Utf8NoBom -Path $projNote -Content $raw
        }
    }

    if ($VaultReuse) {
        Write-Step ((T 'wr_vault_add') -f $VaultPath)
    } else {
        Write-Step ((T 'wr_vault_new') -f $VaultPath)
    }
}

if ($ObsidianEnabled) {
    Install-Vault
}

# ── Step 5: brain runtime + config.json ──────────────────────────────────────
Ensure-Dir $BrainDir
Ensure-Dir (Join-Path $BrainDir 'backups')

# Update scripts (both platforms, so the folder is complete either way).
foreach ($name in @('check-update.ps1', 'update.ps1', 'check-update.sh', 'update.sh')) {
    $src = Join-Path $ScriptDir $name
    if (Test-Path $src) {
        $dst = Join-Path $BrainDir $name
        Backup-File $dst | Out-Null
        Copy-Item -Path $src -Destination $dst -Force
    }
}

# VERSION
$brainVersionFile = Join-Path $BrainDir 'VERSION'
Backup-File $brainVersionFile | Out-Null
Write-Utf8NoBom -Path $brainVersionFile -Content ($BrainVersion + "`n")

# Docs copy (backup an existing docs folder by renaming, never deleting).
if (Test-Path $DocsSrc) {
    $brainDocs = Join-Path $BrainDir 'docs'
    if (Test-Path $brainDocs) {
        Rename-Item -LiteralPath $brainDocs -NewName ("docs.backup-$Timestamp")
    }
    Copy-Item -Path $DocsSrc -Destination $brainDocs -Recurse
}

Write-Step ((T 'wr_brain') -f $BrainDir)

# config.json (§3)
$configPath = Join-Path $BrainDir 'config.json'
Backup-File $configPath | Out-Null

$osName = 'windows'
$config = [ordered]@{
    version     = $BrainVersion
    repo        = $RepoSlug
    branch      = $RepoBranch
    installedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss'Z'")
    os          = $osName
    language    = $Script:Lang
    userName    = $UserName
    experience  = $ExperienceKey
    model       = $ModelKey
    modelRaw    = $ModelRaw
    planTier    = $PlanTier
    obsidian    = [ordered]@{
        enabled      = [bool]$ObsidianEnabled
        vaultPath    = $VaultPath
        appInstalled = [bool]$ObsidianAppInstalled
    }
    updateCheck = [ordered]@{
        enabled       = [bool]$UpdateCheckEnabled
        intervalHours = 24
        lastCheck     = $null
    }
    claudeMdPath = $ClaudeMdOut
}
$configJson = $config | ConvertTo-Json -Depth 5
Write-Utf8NoBom -Path $configPath -Content ($configJson + "`n")
Write-Step ((T 'wr_config') -f $configPath)

# ── Step 6: SessionStart hook in settings.json (§4.3, idempotent) ────────────

$HookCommand = 'powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.claude\brain\check-update.ps1"'

function Register-UpdateHook {
    $hookSnippet = @"
"hooks": {
  "SessionStart": [
    { "matcher": "startup",
      "hooks": [ { "type": "command", "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"%USERPROFILE%\\.claude\\brain\\check-update.ps1\"" } ] }
  ]
}
"@
    try {
        $settings = $null
        if (Test-Path -LiteralPath $SettingsFile) {
            $rawJson = Get-Content -LiteralPath $SettingsFile -Raw -Encoding UTF8
            if ([string]::IsNullOrWhiteSpace($rawJson)) {
                $settings = New-Object PSObject
            } else {
                $settings = $rawJson | ConvertFrom-Json
            }
        } else {
            $settings = New-Object PSObject
        }

        # Idempotency: is a brain check-update hook already registered anywhere?
        $alreadyThere = $false
        if ($settings.PSObject.Properties['hooks']) {
            $hooksObj = $settings.hooks
            if ($hooksObj.PSObject.Properties['SessionStart']) {
                foreach ($entry in @($hooksObj.SessionStart)) {
                    if ($null -eq $entry) { continue }
                    if (-not $entry.PSObject.Properties['hooks']) { continue }
                    foreach ($h in @($entry.hooks)) {
                        if ($null -eq $h) { continue }
                        $cmd = [string]$h.command
                        if ($cmd -like '*brain/check-update*' -or $cmd -like '*brain\check-update*') {
                            $alreadyThere = $true
                        }
                    }
                }
            }
        }

        if ($alreadyThere) {
            Write-Step (T 'wr_hook_have')
            return
        }

        Backup-File $SettingsFile | Out-Null

        $newHook  = [PSCustomObject]@{ type = 'command'; command = $HookCommand }
        $newEntry = [PSCustomObject]@{ matcher = 'startup'; hooks = @($newHook) }

        if (-not $settings.PSObject.Properties['hooks']) {
            $hooksValue = [PSCustomObject]@{ SessionStart = @($newEntry) }
            $settings | Add-Member -MemberType NoteProperty -Name 'hooks' -Value $hooksValue
        } elseif (-not $settings.hooks.PSObject.Properties['SessionStart']) {
            $settings.hooks | Add-Member -MemberType NoteProperty -Name 'SessionStart' -Value @($newEntry)
        } else {
            $settings.hooks.SessionStart = @($settings.hooks.SessionStart) + @($newEntry)
        }

        $json = $settings | ConvertTo-Json -Depth 20
        Write-Utf8NoBom -Path $SettingsFile -Content ($json + "`n")
        Write-Step (T 'wr_hook_ok')
    } catch {
        Write-Warn2 ((T 'wr_hook_fail') -f $_.Exception.Message)
        Write-Host $hookSnippet
    }
}

if ($UpdateCheckEnabled) {
    Register-UpdateHook
} else {
    Write-Note (T 'wr_hook_skip')
}

# ── Step 7: V1 migration (§2) ────────────────────────────────────────────────
# V1 installed CLAUDE.md directly into the home directory. Two CLAUDE.md files
# can contradict each other, so offer a safe rename (never delete).
if (Test-Path -LiteralPath $V1ClaudeMd) {
    Write-Host ""
    Write-Warn2 ((T 'mig_info') -f $V1ClaudeMd)
    $doRename = Ask-YesNo -Question (T 'mig_q') -DefaultYes $true
    if ($doRename) {
        $newName = "CLAUDE.md.backup-$Timestamp"
        Rename-Item -LiteralPath $V1ClaudeMd -NewName $newName
        Write-Step ((T 'mig_done') -f (Join-Path $HomeDir $newName))
    } else {
        Write-Warn2 (T 'mig_warn')
    }
}

# ── Step 8: final screen ─────────────────────────────────────────────────────
Write-Title (T 'fin_title')
Write-Host (T 'fin_where')
Write-Host ("  " + ((T 'fin_claudemd') -f $ClaudeMdOut))
if ($InstallSkills) { Write-Host ("  " + ((T 'fin_skills') -f $SkillsDest)) }
Write-Host ("  " + ((T 'fin_brain') -f $BrainDir))
if ($ObsidianEnabled) { Write-Host ("  " + ((T 'fin_vault') -f $VaultPath)) }
Write-Host ""
Write-Host (T 'fin_start1')
Write-Host ""
Write-Host "    claude" -ForegroundColor Green
Write-Host ""
Write-Host (T 'fin_start2')
Write-Host ""
Write-Host ((T 'fin_update') -f (Join-Path $BrainDir 'update.ps1'))
if ($ObsidianEnabled -and (-not $ObsidianAppInstalled)) {
    Write-Host ""
    Write-Note (T 'fin_obsidian')
}
Write-Host ""

exit 0

#endregion
