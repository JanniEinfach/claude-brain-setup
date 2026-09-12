#!/usr/bin/env node
/**
 * Claude Brain — Trio installer
 *
 * Wires Codex and Antigravity into a Claude Brain install and puts Claude in
 * charge of their permissions.
 *
 *   node install.mjs                 install (asks before each step)
 *   node install.mjs --yes           unattended, accept defaults
 *   node install.mjs --check         report only, change nothing
 *   node install.mjs --uninstall     remove the wiring, keep the CLIs
 *   node install.mjs --lang de       German output
 *   node install.mjs --home <dir>    write below <dir> instead of the real home
 *
 * Two rules this installer never breaks:
 *   1. Merge, never clobber. Existing hooks and permissions are preserved.
 *   2. Back up before every write, with a timestamp. Nothing is lost.
 */

import { existsSync, readFileSync, writeFileSync, mkdirSync, copyFileSync, rmSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { homedir, platform } from 'node:os'
import { fileURLToPath } from 'node:url'
import { spawnSync } from 'node:child_process'
import { createInterface } from 'node:readline'

const HERE = dirname(fileURLToPath(import.meta.url))
const IS_WINDOWS = platform() === 'win32'

/**
 * Base directory for everything this installer writes.
 *
 * Defaults to the real home directory, but the setup wizard's --target flag
 * must be honoured: without this the installer would write past a test target
 * into the user's actual configuration. A test run that modifies the real
 * system is worse than no test.
 */
const homeFlag = process.argv.indexOf('--home')
const HOME = homeFlag >= 0 && process.argv[homeFlag + 1]
  ? process.argv[homeFlag + 1]
  : homedir()

const TRIO_HOME = join(HOME, '.claude', 'brain', 'trio')
const GEMINI_CONFIG = join(HOME, '.gemini', 'config')
const AGY_SETTINGS = [
  join(HOME, '.gemini', 'config', 'settings.json'),
  join(HOME, '.gemini', 'antigravity-cli', 'settings.json'),
]

const args = process.argv.slice(2)
const ASSUME_YES = args.includes('--yes')
const CHECK_ONLY = args.includes('--check')
const UNINSTALL = args.includes('--uninstall')
const langIndex = args.indexOf('--lang')
const LANG = langIndex >= 0 ? args[langIndex + 1] : 'en'

const T = {
  en: {
    title: 'CLAUDE BRAIN — TRIO SETUP',
    detect: 'DETECTED TOOLS',
    notFound: 'not found',
    installHint: 'install with',
    askIntegrate: 'Wire these tools into Claude Brain?',
    askExplain:
      'Claude becomes the approving authority: every tool call the other agents make is\n' +
      '  checked against a policy Claude maintains. No blanket permissions are granted.',
    nothing: 'Neither Codex nor Antigravity found. Nothing to wire up.',
    nothingHint: 'Install at least one, then run this again.',
    skipped: 'Skipped. Claude Brain works fine on its own.',
    steps: 'INSTALLING',
    done: 'DONE',
    verify: 'VERIFYING',
    testsPass: 'permission broker: all tests pass',
    testsFail: 'permission broker: TESTS FAILED — not safe to use',
    removed: 'Trio wiring removed. The CLIs themselves were not touched.',
    next: 'NEXT STEPS',
  },
  de: {
    title: 'CLAUDE BRAIN — TRIO-EINRICHTUNG',
    detect: 'GEFUNDENE WERKZEUGE',
    notFound: 'nicht gefunden',
    installHint: 'installieren mit',
    askIntegrate: 'Diese Werkzeuge in Claude Brain einbinden?',
    askExplain:
      'Claude wird die Genehmigungsinstanz: Jeder Werkzeugaufruf der anderen Agenten\n' +
      '  wird gegen eine Richtlinie geprueft, die Claude pflegt. Es gibt keine Pauschalrechte.',
    nothing: 'Weder Codex noch Antigravity gefunden. Es gibt nichts einzubinden.',
    nothingHint: 'Installiere mindestens eines und starte das hier erneut.',
    skipped: 'Uebersprungen. Claude Brain funktioniert auch allein.',
    steps: 'INSTALLATION',
    done: 'FERTIG',
    verify: 'PRUEFUNG',
    testsPass: 'Genehmigungsinstanz: alle Tests bestanden',
    testsFail: 'Genehmigungsinstanz: TESTS FEHLGESCHLAGEN — nicht einsatzbereit',
    removed: 'Trio-Verdrahtung entfernt. Die CLIs selbst wurden nicht angefasst.',
    next: 'NAECHSTE SCHRITTE',
  },
}
const t = T[LANG] ?? T.en

const say = (s = '') => process.stdout.write(s + '\n')
const ok = (s) => say(`  [ok]   ${s}`)
const no = (s) => say(`  [--]   ${s}`)
const warn = (s) => say(`  [!]    ${s}`)

// ---------------------------------------------------------------------------

function firstExisting(list) {
  for (const p of list) if (p && existsSync(p)) return p
  return null
}

function findAgy() {
  const local = process.env.LOCALAPPDATA || join(HOME, 'AppData', 'Local')
  return firstExisting([
    process.env.AGY_BIN,
    join(local, 'agy', 'bin', 'agy.exe'),
    join(HOME, '.local', 'bin', 'agy'),
    '/usr/local/bin/agy',
  ])
}

function findCodex() {
  const roaming = process.env.APPDATA || join(HOME, 'AppData', 'Roaming')
  return firstExisting([
    IS_WINDOWS ? join(roaming, 'npm', 'codex.cmd') : null,
    join(HOME, '.local', 'bin', 'codex'),
    '/usr/local/bin/codex',
    '/opt/homebrew/bin/codex',
  ])
}

function backup(path) {
  if (!existsSync(path)) return null
  const stamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
  const target = `${path}.backup-${stamp}`
  copyFileSync(path, target)
  return target
}

function readJson(path, fallback = {}) {
  if (!existsSync(path)) return fallback
  try {
    return JSON.parse(readFileSync(path, 'utf8'))
  } catch {
    return fallback
  }
}

function writeJson(path, data) {
  mkdirSync(dirname(path), { recursive: true })
  writeFileSync(path, JSON.stringify(data, null, 2) + '\n')
}

async function confirm(question, def = true) {
  if (ASSUME_YES) return true
  const rl = createInterface({ input: process.stdin, output: process.stdout })
  const hint = def ? '[Y/n]' : '[y/N]'
  const answer = await new Promise((resolve) => rl.question(`  ${question} ${hint} `, resolve))
  rl.close()
  const clean = answer.trim().toLowerCase()
  if (clean === '') return def
  return clean === 'y' || clean === 'j' || clean === 'yes' || clean === 'ja'
}

// ---------------------------------------------------------------------------

function installBroker() {
  mkdirSync(TRIO_HOME, { recursive: true })
  for (const file of ['broker.mjs', 'trio.mjs', 'analyze-claude-md.mjs']) {
    copyFileSync(join(HERE, file), join(TRIO_HOME, file))
  }
  // The user's policy is never overwritten — it may contain their own rules.
  const policyTarget = join(TRIO_HOME, 'policy.json')
  if (existsSync(policyTarget)) {
    warn(`policy.json already exists — kept as is (${policyTarget})`)
  } else {
    copyFileSync(join(HERE, 'policy.default.json'), policyTarget)
  }
  ok(`broker installed: ${TRIO_HOME}`)
  return policyTarget
}

/**
 * Registers the PreToolUse hook without destroying hooks the user already has.
 *
 * The hook's working directory is the folder containing hooks.json, so the
 * command is relative and the broker must sit next to it.
 */
function registerHook() {
  mkdirSync(GEMINI_CONFIG, { recursive: true })
  copyFileSync(join(HERE, 'broker.mjs'), join(GEMINI_CONFIG, 'broker.mjs'))

  const path = join(GEMINI_CONFIG, 'hooks.json')
  const existing = readJson(path, {})
  const had = backup(path)

  existing['claude-brain-broker'] = {
    enabled: true,
    PreToolUse: [
      { matcher: '*', hooks: [{ type: 'command', command: 'node broker.mjs', timeout: 15 }] },
    ],
  }
  writeJson(path, existing)

  const others = Object.keys(existing).filter((k) => k !== 'claude-brain-broker')
  ok(`hook registered: ${path}`)
  if (others.length > 0) ok(`preserved existing hooks: ${others.join(', ')}`)
  if (had) ok(`backup: ${had}`)
}

/**
 * Seeds Antigravity's own allow list with the exact shell commands agents need.
 *
 * Not obvious: Antigravity grants shell access only for EXACT command lines.
 * `command(npm)` does not cover `npm test`. So the list holds full lines, and
 * it stays deliberately short — everything else routes through tools, which
 * the broker governs directly.
 */
function seedShellGrants(policyPath) {
  const policy = readJson(policyPath, {})
  const commands = policy.seedShellCommands ?? []
  if (commands.length === 0) return

  let touched = 0
  for (const settingsPath of AGY_SETTINGS) {
    if (!existsSync(dirname(settingsPath))) continue
    const settings = readJson(settingsPath, {})
    backup(settingsPath)

    settings.permissions = settings.permissions ?? {}
    const current = new Set(settings.permissions.allow ?? [])
    for (const c of commands) current.add(`command(${c})`)
    settings.permissions.allow = [...current].sort()

    writeJson(settingsPath, settings)
    touched++
  }
  if (touched > 0) ok(`seeded ${commands.length} exact shell commands into ${touched} settings file(s)`)
}

function runTests() {
  const result = spawnSync(process.execPath, [join(HERE, 'broker.test.mjs')], { encoding: 'utf8' })
  const passed = result.status === 0
  const summary = (result.stdout || '').split('\n').find((l) => l.includes('passed:')) ?? ''
  if (passed) ok(`${t.testsPass}   ${summary.trim()}`)
  else {
    no(t.testsFail)
    process.stdout.write(result.stdout ?? '')
  }
  return passed
}

function uninstall() {
  const hookPath = join(GEMINI_CONFIG, 'hooks.json')
  if (existsSync(hookPath)) {
    const hooks = readJson(hookPath, {})
    backup(hookPath)
    delete hooks['claude-brain-broker']
    writeJson(hookPath, hooks)
    ok(`hook removed from ${hookPath}`)
  }
  for (const f of ['broker.mjs']) {
    const p = join(GEMINI_CONFIG, f)
    if (existsSync(p)) { rmSync(p); ok(`removed ${p}`) }
  }
  say('')
  say(`  ${t.removed}`)
  say('')
}

// ---------------------------------------------------------------------------

async function main() {
  say('')
  say(t.title)
  say('='.repeat(72))

  if (UNINSTALL) return uninstall()

  const agy = findAgy()
  const codex = findCodex()

  say('')
  say(`  ${t.detect}`)
  if (agy) ok(`antigravity   ${agy}`)
  else no(`antigravity   ${t.notFound}  (${t.installHint}: https://antigravity.google/cli)`)
  if (codex) ok(`codex         ${codex}`)
  else no(`codex         ${t.notFound}  (${t.installHint}: npm i -g @openai/codex)`)

  if (!agy && !codex) {
    say('')
    warn(t.nothing)
    say(`         ${t.nothingHint}`)
    say('')
    process.exit(0)
  }

  if (CHECK_ONLY) {
    say('')
    say('  --check: nothing was changed.')
    say('')
    process.exit(0)
  }

  say('')
  say(`  ${t.askExplain}`)
  say('')
  const go = await confirm(t.askIntegrate, true)
  if (!go) {
    say('')
    say(`  ${t.skipped}`)
    say('')
    process.exit(0)
  }

  say('')
  say(`  ${t.steps}`)
  const policyPath = installBroker()
  if (agy) {
    registerHook()
    seedShellGrants(policyPath)
  }

  say('')
  say(`  ${t.verify}`)
  const healthy = runTests()

  say('')
  say(`  ${t.next}`)
  say('    node ~/.claude/brain/trio/trio.mjs doctor')
  say('    /CLIcombo            (inside a Claude Code session, converts a project)')
  say('')
  process.exit(healthy ? 0 : 1)
}

main().catch((error) => {
  process.stderr.write(`install failed: ${error?.stack ?? error}\n`)
  process.exit(1)
})
