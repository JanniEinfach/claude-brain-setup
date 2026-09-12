#!/usr/bin/env node
/**
 * Claude Brain — configuration analyser
 *
 * Answers one question honestly: is it worth wiping your existing Claude
 * configuration and starting over, or would that throw away work?
 *
 *   node analyze-claude-md.mjs              human-readable report
 *   node analyze-claude-md.mjs --json       machine-readable, for the wizard
 *   node analyze-claude-md.mjs --lang de    German report
 *
 * The wizard must never offer "delete everything" without this. These files
 * are usually the only place a user's working agreements live, they are not in
 * version control, and deleting them destroys something irreplaceable.
 *
 * Deliberately looks wider than CLAUDE.md. Claude Code also reads AGENTS.md,
 * and many setups keep their real rules in ~/.claude/rules/. An analyser that
 * only checks CLAUDE.md would report "nothing here, safe to wipe" to a user
 * with a large handwritten ruleset — the worst possible failure.
 */

import { existsSync, readFileSync, statSync, readdirSync } from 'node:fs'
import { join } from 'node:path'
import { homedir } from 'node:os'

// Honour the setup wizard's --target: analysing the real home during a test
// run would report the wrong files and could talk a user into a wrong decision.
const homeFlag = process.argv.indexOf('--home')
const HOME = homeFlag >= 0 && process.argv[homeFlag + 1] ? process.argv[homeFlag + 1] : homedir()

const LOCATIONS = [
  { path: join(HOME, '.claude', 'CLAUDE.md'), kind: 'claude-md', label: 'CLAUDE.md (current global location)', primary: true },
  { path: join(HOME, 'CLAUDE.md'), kind: 'claude-md', label: 'CLAUDE.md (legacy V1 location)', primary: false },
  { path: join(HOME, '.claude', 'AGENTS.md'), kind: 'agents-md', label: 'AGENTS.md (also read by Claude Code)', primary: false },
]

const RULES_DIR = join(HOME, '.claude', 'rules')

const TEMPLATE_MARKERS = [
  'Claude Brain', 'Core Behaviour', 'Working Principles', 'Team Rules',
  'Model Discipline', 'Token Efficiency', 'Code Quality Gates',
]

const STALE_MODEL_IDS = [
  'claude-3-5-sonnet', 'claude-3-opus', 'claude-3-haiku',
  'claude-sonnet-4', 'claude-opus-4-8', 'claude-fable-5',
]

const V3_SECTIONS = [
  { pattern: /codex|antigravity|trio/i, label: { en: 'Trio (Codex + Antigravity)', de: 'Trio (Codex + Antigravity)' } },
  { pattern: /permission broker|genehmigungsinstanz/i, label: { en: 'Permission broker', de: 'Genehmigungsinstanz' } },
]

function analyseFile(location) {
  if (!existsSync(location.path)) return null
  const text = readFileSync(location.path, 'utf8')
  const stat = statSync(location.path)
  const lines = text.split('\n')

  const headings = lines.filter((l) => /^#{1,3}\s/.test(l)).map((l) => l.replace(/^#+\s*/, '').trim())
  const templateHits = TEMPLATE_MARKERS.filter((m) =>
    headings.some((h) => h.toLowerCase().includes(m.toLowerCase())),
  ).length
  const customHeadings = headings.filter(
    (h) => !TEMPLATE_MARKERS.some((m) => h.toLowerCase().includes(m.toLowerCase())),
  )

  return {
    path: location.path,
    kind: location.kind,
    label: location.label,
    primary: location.primary,
    bytes: stat.size,
    lines: lines.length,
    modified: stat.mtime.toISOString().slice(0, 10),
    ageDays: Math.round((Date.now() - stat.mtimeMs) / 86_400_000),
    headings: headings.length,
    templateShare: Math.round((templateHits / TEMPLATE_MARKERS.length) * 100),
    customHeadings,
    personalised:
      /##\s*(About you|Ueber dich|Über dich|Your |Dein )/i.test(text) ||
      /\bI am\b|\bIch bin\b/i.test(text) ||
      customHeadings.length >= 3,
    staleModels: STALE_MODEL_IDS.filter((id) => text.includes(id)),
    missingV3: V3_SECTIONS.filter((s) => !s.pattern.test(text)).map((s) => s.label),
  }
}

/** A rules/ directory is a strong signal of a deliberate, handwritten setup. */
function analyseRules() {
  if (!existsSync(RULES_DIR)) return null
  let files = 0
  let bytes = 0
  const groups = []
  for (const entry of readdirSync(RULES_DIR, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      groups.push(entry.name)
      for (const f of readdirSync(join(RULES_DIR, entry.name))) {
        if (!f.endsWith('.md')) continue
        files++
        bytes += statSync(join(RULES_DIR, entry.name, f)).size
      }
    } else if (entry.name.endsWith('.md')) {
      files++
      bytes += statSync(join(RULES_DIR, entry.name)).size
    }
  }
  return { path: RULES_DIR, files, bytes, groups }
}

// Reasons are emitted as keys plus parameters, then rendered per language.
// Building English sentences here and translating later never stays in sync.
function buildVerdict(found, rules) {
  const primary = found.find((f) => f.primary) ?? found.find((f) => f.kind === 'claude-md') ?? found[0]
  const reasons = []
  const warnings = []

  const claudeMds = found.filter((f) => f.kind === 'claude-md')
  if (claudeMds.length > 1) warnings.push({ key: 'twoFiles' })

  if (rules && rules.files >= 5) {
    warnings.push({ key: 'rulesExist', files: rules.files, groups: rules.groups.length, kb: Math.round(rules.bytes / 1024) })
  }

  if (found.length === 0 && !rules) {
    return { recommendation: 'fresh', reasons: [{ key: 'nothingExists' }], warnings, primary: null }
  }

  if (found.length === 0 && rules) {
    return { recommendation: 'merge', reasons: [{ key: 'onlyRules', files: rules.files }], warnings, primary: null }
  }

  const handwritten = primary.customHeadings.length
  const looksLikeTemplate = primary.templateShare >= 70 && handwritten <= 2

  if (looksLikeTemplate && !primary.personalised && !(rules && rules.files >= 5)) {
    reasons.push({ key: 'isTemplate', share: primary.templateShare, own: handwritten })
    if (primary.staleModels.length > 0) reasons.push({ key: 'staleModels', models: primary.staleModels })
    if (primary.missingV3.length > 0) reasons.push({ key: 'missingV3', items: primary.missingV3 })
    return { recommendation: 'reset', reasons, warnings, primary }
  }

  if (primary.personalised || handwritten >= 3 || (rules && rules.files >= 5)) {
    reasons.push({ key: 'hasCustom', own: handwritten, list: primary.customHeadings.slice(0, 6) })
    reasons.push({ key: 'irreplaceable' })
    if (primary.staleModels.length > 0) reasons.push({ key: 'staleButKeep', models: primary.staleModels })
    if (primary.missingV3.length > 0) reasons.push({ key: 'appendV3', items: primary.missingV3 })
    return { recommendation: 'merge', reasons, warnings, primary }
  }

  reasons.push({ key: 'unclear', share: primary.templateShare, own: handwritten })
  return { recommendation: 'review', reasons, warnings, primary }
}

const T = {
  en: {
    title: 'CLAUDE CONFIGURATION — ANALYSIS',
    none: 'No CLAUDE.md or AGENTS.md found.',
    found: 'FOUND',
    rules: 'RULES DIRECTORY',
    verdict: 'RECOMMENDATION',
    why: 'WHY',
    warn: 'IMPORTANT',
    backup: 'Whatever you choose, setup always writes a timestamped backup first. Nothing is ever deleted outright.',
    reset: 'RESET — rebuild from scratch, nothing of value is lost',
    merge: 'KEEP — update in place, do NOT wipe',
    review: 'LOOK FIRST — no clear call, read the file yourself',
    fresh: 'FRESH INSTALL — nothing exists yet',
    r: {
      nothingExists: () => 'No Claude configuration exists yet. Nothing can be lost.',
      onlyRules: (p) => `No CLAUDE.md, but ${p.files} rule files exist. Those are your real configuration — keep them and add the v3 sections.`,
      isTemplate: (p) => `The file is essentially the stock template (${p.share}% standard sections, ${p.own} of your own). Rebuilding loses nothing.`,
      staleModels: (p) => `It still names outdated models: ${p.models.join(', ')}.`,
      missingV3: (p) => `Missing since v3: ${p.items.map((i) => i.en).join(', ')}.`,
      hasCustom: (p) => `The file carries ${p.own} sections that are not from the template: ${p.list.join(', ')}${p.own > 6 ? ', …' : ''}.`,
      irreplaceable: () => 'That is handwritten context — working agreements, stack details, project habits. It is not in version control and cannot be recovered once deleted.',
      staleButKeep: (p) => `It does contain outdated model IDs (${p.models.join(', ')}) — worth updating, but not worth wiping the file for.`,
      appendV3: (p) => `Missing since v3: ${p.items.map((i) => i.en).join(', ')}. These can simply be appended.`,
      unclear: (p) => `Unclear case: ${p.share}% template sections, ${p.own} of your own. Read it yourself before deciding.`,
    },
    w: {
      twoFiles: () => 'Two CLAUDE.md files exist at once (current and legacy V1 location). Claude Code reads only the current one — the other is dead weight and a source of confusion.',
      rulesExist: (p) => `You have ${p.files} rule files in ${p.groups} groups (${p.kb} KB) under ~/.claude/rules/. That is a deliberate, handwritten setup. A reset would NOT touch it, but it means your real configuration lives there, not in CLAUDE.md.`,
    },
  },
  de: {
    title: 'CLAUDE-KONFIGURATION — ANALYSE',
    none: 'Keine CLAUDE.md oder AGENTS.md gefunden.',
    found: 'GEFUNDEN',
    rules: 'REGELVERZEICHNIS',
    verdict: 'EMPFEHLUNG',
    why: 'BEGRUENDUNG',
    warn: 'WICHTIG',
    backup: 'Was du auch waehlst: Das Setup legt immer zuerst eine datierte Sicherung an. Es wird nie etwas ersatzlos geloescht.',
    reset: 'NEU AUFBAUEN — es geht nichts Wertvolles verloren',
    merge: 'BEHALTEN — ergaenzen statt loeschen',
    review: 'ERST ANSEHEN — kein klarer Fall, lies die Datei selbst',
    fresh: 'NEUINSTALLATION — es existiert noch nichts',
    r: {
      nothingExists: () => 'Es existiert noch keine Claude-Konfiguration. Es kann nichts verloren gehen.',
      onlyRules: (p) => `Keine CLAUDE.md, aber ${p.files} Regeldateien. Die sind deine eigentliche Konfiguration — behalten und die v3-Abschnitte ergaenzen.`,
      isTemplate: (p) => `Die Datei ist im Kern die Standardvorlage (${p.share}% Standardabschnitte, ${p.own} eigene). Ein Neuaufbau verliert nichts.`,
      staleModels: (p) => `Sie nennt noch veraltete Modelle: ${p.models.join(', ')}.`,
      missingV3: (p) => `Fehlt seit v3: ${p.items.map((i) => i.de).join(', ')}.`,
      hasCustom: (p) => `Die Datei traegt ${p.own} Abschnitte, die nicht aus der Vorlage stammen: ${p.list.join(', ')}${p.own > 6 ? ', …' : ''}.`,
      irreplaceable: () => 'Das ist handgeschriebener Kontext — Arbeitsabsprachen, Stack-Details, Projektgewohnheiten. Er liegt nicht in der Versionsverwaltung und ist nach dem Loeschen weg.',
      staleButKeep: (p) => `Sie enthaelt zwar veraltete Modell-Kennungen (${p.models.join(', ')}) — die gehoeren aktualisiert, rechtfertigen aber kein Loeschen.`,
      appendV3: (p) => `Fehlt seit v3: ${p.items.map((i) => i.de).join(', ')}. Das laesst sich einfach anhaengen.`,
      unclear: (p) => `Unklarer Fall: ${p.share}% Vorlagenabschnitte, ${p.own} eigene. Sieh selbst hinein, bevor du entscheidest.`,
    },
    w: {
      twoFiles: () => 'Es existieren zwei CLAUDE.md gleichzeitig (aktueller und alter V1-Ort). Claude Code liest nur die aktuelle — die andere ist Ballast und stiftet Verwirrung.',
      rulesExist: (p) => `Du hast ${p.files} Regeldateien in ${p.groups} Gruppen (${p.kb} KB) unter ~/.claude/rules/. Das ist ein bewusst aufgebautes, handgeschriebenes Regelwerk. Ein Reset wuerde es NICHT anfassen — aber es bedeutet, dass deine eigentliche Konfiguration dort liegt, nicht in der CLAUDE.md.`,
    },
  },
}

function render(found, rules, verdict, lang) {
  const t = T[lang] ?? T.en
  const out = ['', t.title, '='.repeat(72)]

  if (found.length === 0) {
    out.push('', `  ${t.none}`)
  } else {
    out.push('', `  ${t.found}`)
    for (const f of found) {
      out.push(`    ${f.path}`)
      out.push(`      ${f.lines} ${lang === 'de' ? 'Zeilen' : 'lines'}, ${f.bytes} bytes, ${lang === 'de' ? 'zuletzt' : 'changed'} ${f.modified} (${f.ageDays}d)`)
      out.push(`      ${f.headings} ${lang === 'de' ? 'Abschnitte' : 'sections'}, ${f.templateShare}% ${lang === 'de' ? 'Standard' : 'standard'}, ${f.customHeadings.length} ${lang === 'de' ? 'eigene' : 'own'}`)
    }
  }

  if (rules) {
    out.push('', `  ${t.rules}`)
    out.push(`    ${rules.path}`)
    out.push(`      ${rules.files} ${lang === 'de' ? 'Dateien' : 'files'}, ${Math.round(rules.bytes / 1024)} KB, ${rules.groups.length} ${lang === 'de' ? 'Gruppen' : 'groups'}: ${rules.groups.join(', ')}`)
  }

  out.push('', `  ${t.verdict}`, `    ${t[verdict.recommendation]}`)

  if (verdict.reasons.length > 0) {
    out.push('', `  ${t.why}`)
    for (const r of verdict.reasons) {
      const fn = t.r[r.key]
      out.push(`    - ${fn ? fn(r) : r.key}`)
    }
  }

  if (verdict.warnings.length > 0) {
    out.push('', `  ${t.warn}`)
    for (const w of verdict.warnings) {
      const fn = t.w[w.key]
      out.push(`    ! ${fn ? fn(w) : w.key}`)
    }
  }

  out.push('', `  ${t.backup}`, '')
  return out.join('\n')
}

// ---------------------------------------------------------------------------

const args = process.argv.slice(2)
const langIndex = args.indexOf('--lang')
const lang = langIndex >= 0 ? args[langIndex + 1] : 'en'

const found = LOCATIONS.map(analyseFile).filter(Boolean)
const rules = analyseRules()
const verdict = buildVerdict(found, rules)

if (args.includes('--json')) {
  process.stdout.write(JSON.stringify({ found, rules, verdict }, null, 2))
} else {
  process.stdout.write(render(found, rules, verdict, lang))
}
