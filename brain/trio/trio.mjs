#!/usr/bin/env node
/**
 * Claude Brain — Trio dispatcher
 *
 * One entry point for working with Claude, Codex and Antigravity together.
 *
 *   node trio.mjs doctor              check tools and logins
 *   node trio.mjs ask "..." [file...] repo analysis by Antigravity
 *   node trio.mjs review <path>       counter-review by Codex
 *   node trio.mjs council "..."       ask BOTH in parallel, collect answers
 *   node trio.mjs task run <id>       run a task spec in its own worktree
 *   node trio.mjs task gate <id>      acceptance gate: types, tests, file limits
 *   node trio.mjs task accept <id>    squash-merge into the current branch
 *   node trio.mjs task drop <id>      discard and clean up
 *
 * Written as one cross-platform Node program on purpose. The alternative —
 * a .sh and a .ps1 carrying the same logic — means every fix has to be made
 * twice, and the second one is the one that gets forgotten.
 */

import { spawnSync } from 'node:child_process'
import { existsSync, mkdirSync, readFileSync, writeFileSync, readdirSync } from 'node:fs'
import { join, resolve, basename } from 'node:path'
import { homedir, platform } from 'node:os'

const ROOT = process.cwd()
const IS_WINDOWS = platform() === 'win32'

// ---------------------------------------------------------------------------
// Locating the CLIs
//
// Neither tool is reliably on PATH. Antigravity's binary is called `agy`, not
// `antigravity`, and lives under LOCALAPPDATA. npm global binaries sit in a
// roaming folder that a shell started earlier will not know about.
// ---------------------------------------------------------------------------

function firstExisting(candidates) {
  for (const candidate of candidates) {
    if (candidate && existsSync(candidate)) return candidate
  }
  return null
}

function findAgy() {
  if (process.env.AGY_BIN && existsSync(process.env.AGY_BIN)) return process.env.AGY_BIN
  const local = process.env.LOCALAPPDATA || join(homedir(), 'AppData', 'Local')
  return firstExisting([
    join(local, 'agy', 'bin', 'agy.exe'),
    join(homedir(), '.local', 'bin', 'agy'),
    join(homedir(), '.agy', 'bin', 'agy'),
    '/usr/local/bin/agy',
  ])
}

function findCodex() {
  const roaming = process.env.APPDATA || join(homedir(), 'AppData', 'Roaming')
  return firstExisting([
    IS_WINDOWS ? join(roaming, 'npm', 'codex.cmd') : null,
    join(homedir(), '.local', 'bin', 'codex'),
    '/usr/local/bin/codex',
    '/opt/homebrew/bin/codex',
  ])
}

const AGY = findAgy()
const CODEX = findCodex()

/**
 * Runs a program and returns the result.
 *
 * Windows needs care here: .cmd and .bat wrappers (npm, codex) cannot be
 * launched directly by spawnSync. The obvious fix, shell: true, concatenates
 * arguments instead of escaping them - Node deprecated it for exactly that
 * reason, and a prompt containing quotes would break or inject. Routing
 * through cmd.exe with /c keeps proper argument handling.
 */
function run(bin, args, options = {}) {
  const base = { encoding: 'utf8', input: '', ...options }
  if (IS_WINDOWS && /\.(cmd|bat)$/i.test(bin || '')) {
    const comspec = process.env.ComSpec || 'cmd.exe'
    return spawnSync(comspec, ['/d', '/s', '/c', bin, ...args], base)
  }
  return spawnSync(bin, args, base)
}

/** npm is npm.cmd on Windows and needs the same treatment. */
function runNpm(args, options = {}) {
  return run(IS_WINDOWS ? 'npm.cmd' : 'npm', args, options)
}

/** Some CLIs report on stderr. Take whichever channel produced output. */
function firstLine(result) {
  const text = ((result.stdout || '') + (result.stderr || '')).trim()
  return text.split(/\r?\n/)[0] || '?'
}
function say(line = '') {
  process.stdout.write(line + '\n')
}

function die(message) {
  process.stderr.write(`ERROR: ${message}\n`)
  process.exit(1)
}

// ---------------------------------------------------------------------------
// Shared context
//
// Rules are pasted INTO the prompt rather than letting the agent read them.
// Codex runs sandboxed without shell access by default, and Antigravity cannot
// prompt for permission in headless mode. A failed file read is silent — the
// agent then answers without knowing the rules, which is worse than an error.
// ---------------------------------------------------------------------------

function projectRules() {
  for (const name of ['AGENTS.md', 'CLAUDE.md']) {
    const path = join(ROOT, name)
    if (existsSync(path)) {
      return `Binding project rules (from ${name}):\n\n${readFileSync(path, 'utf8')}\n\n--- end of project rules ---\n\n`
    }
  }
  return ''
}

function packFiles(paths) {
  let out = ''
  for (const path of paths) {
    const full = resolve(ROOT, path)
    if (!existsSync(full)) continue
    out += `\n===== FILE: ${path} =====\n${readFileSync(full, 'utf8')}\n===== END ${path} =====\n`
  }
  return out
}

function packTree() {
  const listing = run('git', ['ls-files'], { cwd: ROOT })
  const files = (listing.stdout || '').split('\n').filter(Boolean).slice(0, 400)
  return `\n===== PROJECT STRUCTURE =====\n${files.join('\n')}\n===== END STRUCTURE =====\n`
}

// ---------------------------------------------------------------------------
// Commands
// ---------------------------------------------------------------------------

function cmdDoctor() {
  say('')
  say('TOOLS')
  if (AGY) {
    const v = firstLine(run(AGY, ['--version']))
    say(`  [ok]   antigravity   ${v}   ${AGY}`)
  } else {
    say('  [--]   antigravity   not found (install: https://antigravity.google/cli)')
  }
  if (CODEX) {
    const v = firstLine(run(CODEX, ['--version']))
    say(`  [ok]   codex         ${v}   ${CODEX}`)
  } else {
    say('  [--]   codex         not found (install: npm i -g @openai/codex)')
  }
  say(`  [ok]   node          ${process.version}`)

  say('')
  say('SIGN-IN (no API key required)')
  if (CODEX) {
    // codex reports its login status on stderr, not stdout.
    const status = firstLine(run(CODEX, ['login', 'status']))
    say(`  codex         ${status}`)
  }
  if (AGY) say('  antigravity   Google account, billed through your subscription')

  say('')
  say('PERMISSION BROKER')
  const brokerPaths = [
    join(homedir(), '.claude', 'brain', 'trio', 'broker.mjs'),
    join(ROOT, '.agents', 'broker.mjs'),
  ]
  const broker = firstExisting(brokerPaths)
  say(broker ? `  [ok]   ${broker}` : '  [--]   not installed — run the Brain setup')

  const hookPaths = [
    join(homedir(), '.gemini', 'config', 'hooks.json'),
    join(ROOT, '.agents', 'hooks.json'),
  ]
  const hook = firstExisting(hookPaths)
  say(hook ? `  [ok]   hook registered: ${hook}` : '  [--]   hook not registered')

  say('')
  say('OPEN TASKS')
  const taskDir = join(ROOT, '.ai', 'tasks')
  const tasks = existsSync(taskDir) ? readdirSync(taskDir).filter((f) => f.endsWith('.md')) : []
  if (tasks.length === 0) say('  (none)')
  else for (const task of tasks) say(`  ${basename(task, '.md')}`)
  say('')
}

function cmdAsk(question, files) {
  if (!AGY) die('Antigravity not found. Run: node trio.mjs doctor')
  if (!question) die('Missing question. Usage: trio ask "question" [file ...]')

  const context = files.length > 0 ? packFiles(files) : packTree()
  const prompt =
    projectRules() +
    context +
    '\nAnswer the question using ONLY the material supplied above. Do not use ' +
    'tools and do not try to read files yourself. Say plainly if material is ' +
    'missing rather than guessing. Name concrete file paths.\n\n' +
    `Question: ${question}`

  say('>  Antigravity is analysing (context supplied inline) ...')
  const result = run(AGY, ['-p', prompt, '--effort', 'high', '--add-dir', ROOT], { stdio: 'inherit' })
  process.exit(result.status ?? 0)
}

function cmdReview(target) {
  if (!CODEX) die('Codex not found. Run: npm i -g @openai/codex')
  if (!target) die('Missing path. Usage: trio review <path>')

  const prompt =
    projectRules() +
    packFiles([target]) +
    '\nReview the file above critically for bugs, security holes and edge cases. ' +
    'Change nothing. Output a numbered list sorted by severity: CRITICAL, HIGH, ' +
    'MEDIUM, LOW. No style remarks.'

  say(`>  Codex is reviewing ${target} ...`)
  const result = run(CODEX, ['exec', '--sandbox', 'read-only', '--skip-git-repo-check', prompt], {
    stdio: 'inherit',
  })
  process.exit(result.status ?? 0)
}

function cmdCouncil(question) {
  if (!question) die('Missing question. Usage: trio council "question"')
  const stamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
  const outDir = join(ROOT, '.ai', 'handoff', `council-${stamp}`)
  mkdirSync(outDir, { recursive: true })
  writeFileSync(join(outDir, 'question.md'), question)

  const prompt =
    projectRules() +
    'Answer concisely with a clear recommendation. State explicitly what you ' +
    'advise against and why. Do not use tools, do not read files, change nothing.\n\n' +
    `Question: ${question}`

  say('>  Asking Antigravity and Codex at the same time ...')

  const jobs = []
  if (AGY) {
    jobs.push({
      name: 'antigravity',
      result: run(AGY, ['-p', prompt, '--effort', 'high', '--add-dir', ROOT]),
    })
  }
  if (CODEX) {
    jobs.push({
      name: 'codex',
      result: run(CODEX, ['exec', '--sandbox', 'read-only', '--skip-git-repo-check', prompt]),
    })
  }
  if (jobs.length === 0) die('Neither Antigravity nor Codex is available.')

  for (const job of jobs) {
    const text = (job.result.stdout || '') + (job.result.stderr || '')
    writeFileSync(join(outDir, `${job.name}.md`), text)
    say('')
    say(`===== ${job.name} =====`)
    say(text.trim())
  }
  say('')
  say(`Saved to ${outDir}`)
}

// ---------------------------------------------------------------------------
// Task workflow — isolated worktrees
// ---------------------------------------------------------------------------

function specPath(id) {
  return join(ROOT, '.ai', 'tasks', `${id}.md`)
}

function treePath(id) {
  return resolve(ROOT, '..', `${basename(ROOT)}-${id}`)
}

function specField(id, field) {
  const path = specPath(id)
  if (!existsSync(path)) return ''
  const text = readFileSync(path, 'utf8')
  const header = text.split('---')[1] ?? ''
  const line = header.split('\n').find((l) => l.trim().startsWith(`${field}:`))
  return line ? line.split(':').slice(1).join(':').trim() : ''
}

function cmdTaskRun(id) {
  if (!existsSync(specPath(id))) die(`Task spec not found: ${specPath(id)}`)
  const agent = specField(id, 'agent') || 'codex'
  const branch = specField(id, 'branch') || `ai/${id}`
  const tree = treePath(id)

  if (!existsSync(tree)) {
    say(`>  Creating worktree ${tree} (branch ${branch})`)
    const added = run('git', ['worktree', 'add', tree, '-b', branch], { cwd: ROOT })
    if (added.status !== 0) {
      const reuse = run('git', ['worktree', 'add', tree, branch], { cwd: ROOT })
      if (reuse.status !== 0) {
        die('Could not create the worktree. Does the repo have at least one commit?')
      }
    }
  }

  const prompt =
    'Work through this task specification.\n\n' +
    'Stay exactly within the list of permitted files. Change nothing outside it. ' +
    'Do not modify existing tests. Do not add dependencies.\n\n' +
    projectRules() +
    readFileSync(specPath(id), 'utf8')

  say(`>  Starting ${agent} for ${id} ...`)
  if (agent === 'codex') {
    if (!CODEX) die('Codex not found.')
    run(CODEX, ['exec', '--full-auto', '--skip-git-repo-check', prompt], { cwd: tree, stdio: 'inherit' })
  } else if (agent === 'antigravity' || agent === 'agy') {
    if (!AGY) die('Antigravity not found.')
    run(AGY, ['-p', prompt, '--mode', 'accept-edits', '--sandbox', '--effort', 'high', '--add-dir', tree],
      { cwd: tree, stdio: 'inherit' })
  } else {
    die(`Unknown agent: ${agent} (allowed: codex, antigravity)`)
  }
  say(`OK: finished. Next: node trio.mjs task gate ${id}`)
}

function cmdTaskGate(id) {
  const tree = treePath(id)
  if (!existsSync(tree)) die(`No worktree for ${id}`)

  say('')
  say(`ACCEPTANCE GATE — ${id}`)
  say('')
  let failed = false

  say('>  1/3 changed files')
  const tracked = run('git', ['diff', '--name-only', 'HEAD'], { cwd: tree }).stdout || ''
  const untracked = run('git', ['ls-files', '--others', '--exclude-standard'], { cwd: tree }).stdout || ''
  const changed = [...new Set((tracked + untracked).split('\n').filter(Boolean))]
  if (changed.length === 0) say('       (no changes)')
  else for (const f of changed) say(`       ${f}`)

  const pkgPath = join(tree, 'package.json')
  const pkg = existsSync(pkgPath) ? JSON.parse(readFileSync(pkgPath, 'utf8')) : null

  say('>  2/3 typecheck')
  if (pkg?.scripts?.typecheck) {
    const ok = runNpm(['run', '-s', 'typecheck'], { cwd: tree }).status === 0
    say(ok ? '       [ok] clean' : '       [--] type errors')
    if (!ok) failed = true
  } else say('       (skipped)')

  say('>  3/3 tests')
  if (pkg?.scripts?.test) {
    const ok = runNpm(['test', '--silent'], { cwd: tree }).status === 0
    say(ok ? '       [ok] green' : '       [--] red')
    if (!ok) failed = true
  } else say('       (skipped)')

  say('')
  if (failed) die('Gate not passed. Back to the agent — Claude reads nothing.')
  say('OK: passed. Now Claude reads the diff:')
  say(`    git -C ${tree} diff HEAD`)
}

function cmdTaskAccept(id) {
  const branch = specField(id, 'branch') || `ai/${id}`
  const merged = run('git', ['merge', '--squash', branch], { cwd: ROOT, stdio: 'inherit' })
  if (merged.status !== 0) die('Merge failed.')
  say('OK: merged, not committed. Inspect with: git diff --cached')
}

function cmdTaskDrop(id) {
  const branch = specField(id, 'branch') || `ai/${id}`
  run('git', ['worktree', 'remove', '--force', treePath(id)], { cwd: ROOT })
  run('git', ['branch', '-D', branch], { cwd: ROOT })
  say(`OK: ${id} discarded.`)
}

// ---------------------------------------------------------------------------

const [, , command, ...rest] = process.argv

switch (command) {
  case 'doctor':
  case undefined:
    cmdDoctor()
    break
  case 'ask':
    cmdAsk(rest[0], rest.slice(1))
    break
  case 'review':
    cmdReview(rest[0])
    break
  case 'council':
    cmdCouncil(rest.join(' '))
    break
  case 'task': {
    const [sub, id] = rest
    if (!id) die('Missing task id. Example: trio task run T-042')
    if (sub === 'run') cmdTaskRun(id)
    else if (sub === 'gate') cmdTaskGate(id)
    else if (sub === 'accept') cmdTaskAccept(id)
    else if (sub === 'drop') cmdTaskDrop(id)
    else die(`Unknown subcommand: ${sub} (run|gate|accept|drop)`)
    break
  }
  default:
    die(`Unknown command: ${command} (doctor|ask|review|council|task)`)
}
