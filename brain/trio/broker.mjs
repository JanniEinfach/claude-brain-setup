#!/usr/bin/env node
/**
 * Claude Brain — Permission Broker
 *
 * Makes Claude the approving authority for the other CLI agents.
 *
 * WHY THIS EXISTS
 * ---------------
 * Antigravity in headless mode (`agy -p`) cannot ask anyone for permission, so
 * it auto-denies every tool call. Its own error message suggests
 * `--dangerously-skip-permissions`. That is a blanket grant to a model running
 * unattended on a work machine — delete files, read credentials, call paid
 * APIs. We do not issue it.
 *
 * Instead this broker decides, using a policy that Claude maintains. Every
 * decision is logged. Anything the policy does not know is denied — with a
 * reason that tells the agent what to do instead.
 *
 * PROVEN BEHAVIOUR (tested, not assumed)
 * --------------------------------------
 * A `deny` here overrides an explicit `allow` in Antigravity's own
 * settings.json. The hook is the authority; settings.json is only a doorman.
 *
 * CONTRACT (Antigravity PreToolUse hook)
 * --------------------------------------
 *   stdin : { toolCall: { name, args }, stepIdx, workspacePaths, ... }
 *   stdout: { decision: "allow"|"deny"|"ask"|"force_ask", reason?, ... }
 *
 * Only the result JSON may go to stdout. Anything else breaks the contract.
 * Diagnostics go to stderr.
 */

import { readFileSync, appendFileSync, mkdirSync, existsSync } from 'node:fs'
import { dirname, join, resolve, sep } from 'node:path'
import { fileURLToPath } from 'node:url'
import { homedir } from 'node:os'

const HERE = dirname(fileURLToPath(import.meta.url))
const BRAIN_HOME = join(homedir(), '.claude', 'brain', 'trio')

// Set in main() once the payload reveals which project we are in.
let PROJECT = resolve(HERE, '..')
let LOGFILE = join(BRAIN_HOME, 'decisions.jsonl')

/** Fail closed: whatever goes wrong, the answer is "no". */
const FAILSAFE = {
  decision: 'deny',
  reason:
    'Permission broker could not load its policy. Denied for safety. ' +
    'Ask Claude — the policy lives in .agents/policy.json or ~/.claude/brain/trio/policy.json.',
}

function answer(result) {
  process.stdout.write(JSON.stringify(result))
  process.exit(0)
}

function logDecision(entry) {
  try {
    mkdirSync(dirname(LOGFILE), { recursive: true })
    appendFileSync(LOGFILE, JSON.stringify({ at: new Date().toISOString(), ...entry }) + '\n')
  } catch {
    // Logging must never block a decision.
  }
}

function readStdin() {
  try {
    return readFileSync(0, 'utf8')
  } catch {
    return ''
  }
}

/**
 * Where the project lives. Comes from the payload, not from this file's
 * location — the broker is installed once globally but decides for many
 * projects. Antigravity only fills workspacePaths when started with --add-dir.
 */
function projectFrom(input) {
  const paths = input?.workspacePaths
  if (Array.isArray(paths) && typeof paths[0] === 'string' && paths[0].trim() !== '') {
    return resolve(paths[0])
  }
  return resolve(HERE, '..')
}

/**
 * Policy lookup order: project override first, then the global default.
 * A project can tighten or loosen its own rules without touching the global one.
 */
function policyPath(project) {
  const candidates = [
    join(project, '.agents', 'policy.json'),
    join(BRAIN_HOME, 'policy.json'),
    join(HERE, 'policy.default.json'),
  ]
  for (const candidate of candidates) {
    if (existsSync(candidate)) return candidate
  }
  return candidates[candidates.length - 1]
}

function loadPolicy(path) {
  if (!existsSync(path)) return null
  try {
    return JSON.parse(readFileSync(path, 'utf8'))
  } catch (error) {
    process.stderr.write(`policy unreadable (${path}): ${error.message}\n`)
    return null
  }
}

/** Turns policy strings into real regular expressions, skipping broken ones. */
function toPatterns(list) {
  if (!Array.isArray(list)) return []
  const out = []
  for (const entry of list) {
    try {
      out.push(new RegExp(entry, 'i'))
    } catch {
      process.stderr.write(`skipped invalid pattern: ${entry}\n`)
    }
  }
  return out
}

/** Antigravity names the command field differently per tool. Check all spellings. */
function commandFrom(args) {
  if (!args || typeof args !== 'object') return ''
  for (const key of ['CommandLine', 'commandLine', 'command', 'Command', 'cmd']) {
    const value = args[key]
    if (typeof value === 'string' && value.trim() !== '') return value
  }
  return ''
}

/** Every path-like argument, so write targets can be checked. */
function pathsFrom(args) {
  if (!args || typeof args !== 'object') return []
  const keys = [
    'AbsolutePath', 'absolutePath', 'TargetFile', 'targetFile',
    'path', 'Path', 'file', 'File', 'filePath', 'FilePath',
  ]
  const out = []
  for (const key of keys) {
    const value = args[key]
    if (typeof value === 'string' && value.trim() !== '') out.push(value)
  }
  return out
}

function insideProject(candidate) {
  try {
    const full = resolve(PROJECT, candidate)
    return full === PROJECT || full.startsWith(PROJECT + sep)
  } catch {
    return false
  }
}

/**
 * Temporary grants handed back to Antigravity.
 *
 * Not obvious and hard-won: `decision: "allow"` alone is enough for tools
 * (view_file, edit_file, grep_search) but NOT for run_command. For shell
 * commands Antigravity still consults its own settings.json afterwards.
 *
 * The grant is kept as narrow as possible — the exact command line, never the
 * program. A grant for "git" would otherwise permit every git subcommand.
 * Entries of any other shape make the list unusable, so it stays single.
 */
function grantsFor(command) {
  return command ? [`command(${command})`] : []
}

// ---------------------------------------------------------------------------

function main() {
  const raw = readStdin()
  let input
  try {
    input = JSON.parse(raw)
  } catch {
    logDecision({ decision: 'deny', why: 'stdin was not valid JSON' })
    answer(FAILSAFE)
  }

  PROJECT = projectFrom(input)
  LOGFILE = join(PROJECT, '.ai', 'permissions.jsonl')

  const policy = loadPolicy(policyPath(PROJECT))
  if (!policy) {
    logDecision({ decision: 'deny', why: 'policy missing or broken' })
    answer(FAILSAFE)
  }

  const tool = input?.toolCall?.name ?? 'unknown'
  const args = input?.toolCall?.args ?? {}
  const command = commandFrom(args)

  const base = {
    tool,
    command: command.slice(0, 400),
    stepIdx: input?.stepIdx,
    project: PROJECT,
  }

  // 1. Escape hatch for deliberate exceptions. Off by default.
  if (policy.mode === 'permissive') {
    logDecision({ ...base, decision: 'allow', why: 'mode=permissive' })
    answer({ decision: 'allow', reason: 'mode=permissive', permissionOverrides: grantsFor(command) })
  }

  // 2. Hard blocks. Checked FIRST so a chained command cannot slip through on
  //    a harmless first word, e.g. `cat README.md && rm -rf /`.
  for (const pattern of toPatterns(policy.denyCommands)) {
    if (command && pattern.test(command)) {
      logDecision({ ...base, decision: 'deny', why: `denyCommands: ${pattern.source}` })
      answer({
        decision: 'deny',
        reason:
          `Blocked by policy (pattern: ${pattern.source}). This command is destructive, ` +
          `leaves the project, or costs money. If you genuinely need it, say so in your ` +
          `report — Claude decides.`,
      })
    }
  }

  // 3. Writing tools: protected files first, then the project boundary.
  const isWriter = toPatterns(policy.writeTools ?? []).some((p) => p.test(tool))
  if (isWriter) {
    const targets = pathsFrom(args)
    const protectedPatterns = toPatterns(policy.protectedPaths ?? [])

    for (const target of targets) {
      // The broker lives inside the project. Without this check an agent could
      // rewrite its own supervision and grant itself anything.
      for (const pattern of protectedPatterns) {
        if (pattern.test(target)) {
          logDecision({ ...base, target, decision: 'deny', why: `protectedPaths: ${pattern.source}` })
          answer({
            decision: 'deny',
            reason:
              `Protected path: ${target}. Supervision, project rules and git internals ` +
              `are off limits to agents. Only Claude maintains these files.`,
          })
        }
      }
      if (!insideProject(target)) {
        logDecision({ ...base, target, decision: 'deny', why: 'path outside project' })
        answer({
          decision: 'deny',
          reason: `Write outside the project denied: ${target}. Only ${PROJECT} is allowed.`,
        })
      }
    }

    logDecision({ ...base, targets, decision: 'allow', why: 'write tool, path inside project' })
    answer({
      decision: 'allow',
      reason: 'Write inside the project directory',
      permissionOverrides: grantsFor(command),
    })
  }

  // 4. Tools that cannot change anything.
  for (const pattern of toPatterns(policy.allowTools)) {
    if (pattern.test(tool)) {
      logDecision({ ...base, decision: 'allow', why: `allowTools: ${pattern.source}` })
      answer({
        decision: 'allow',
        reason: 'Tool is harmless per policy',
        permissionOverrides: grantsFor(command),
      })
    }
  }

  // 5. Explicitly permitted commands.
  if (command) {
    for (const pattern of toPatterns(policy.allowCommands)) {
      if (pattern.test(command)) {
        logDecision({ ...base, decision: 'allow', why: `allowCommands: ${pattern.source}` })
        answer({
          decision: 'allow',
          reason: 'Command permitted by policy',
          permissionOverrides: grantsFor(command),
        })
      }
    }
  }

  // 6. Unknown: deny, but explain. This is the heart of the design — not
  //    "allow to be safe" but "deny and say how to proceed".
  logDecision({ ...base, decision: 'deny', why: 'not in policy' })
  answer({
    decision: 'deny',
    reason:
      `Not covered by policy (tool: ${tool}` +
      (command ? `, command: ${command.slice(0, 120)}` : '') +
      `). Denied. Work with the material supplied in your task. If you really ` +
      `need this access, write it in your report — Claude will extend the policy.`,
  })
}

try {
  main()
} catch (error) {
  process.stderr.write(`broker exception: ${error?.stack ?? error}\n`)
  logDecision({ decision: 'deny', why: `exception: ${error?.message}` })
  answer(FAILSAFE)
}
