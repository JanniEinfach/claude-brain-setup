# brain-permission-broker

## Purpose

Claude acts as the approving authority for Codex and Antigravity. Explains how
the broker decides, how to extend the policy safely, and what to do when an
agent is blocked.

## When to Use

When an agent reports it was denied something. When adding a new tool or command
to the allowed set. When reviewing whether the setup is still safe.

## When Not to Use

Normal development. The broker is silent when everything is permitted.

---

## The problem it solves

Antigravity in headless mode (`agy -p`) cannot ask anyone for permission, so it
auto-denies every tool call. Its own error message suggests
`--dangerously-skip-permissions`.

That is a blanket grant to a model running unattended on a work machine: delete
files, read credentials, call paid APIs. **Never issue it.**

---

## How it works

```
Agent wants to use a tool
        |
        v
[1] PreToolUse hook  ->  ~/.claude/brain/trio/broker.mjs
        |                 checks against policy.json
        |                 CAN ALWAYS DENY
        v
[2] The tool's own permission system
        v
    Execution
```

**Layer 1 is the authority. Layer 2 is only a doorman.**

Proven: a `deny` from the broker aborts the call even when the tool's own
settings explicitly allow it. The reason text reaches the model verbatim, so it
knows why it was refused and what to do instead.

---

## Policy structure

`.agents/policy.json` in the project, or `~/.claude/brain/trio/policy.json`
globally. The project file wins if present.

| Section | Purpose |
|---|---|
| `denyCommands` | Hard blocks. **Checked first** |
| `protectedPaths` | Untouchable files, even inside the project |
| `writeTools` | May only write inside the project |
| `allowTools` | Tools that cannot change anything |
| `allowCommands` | Permitted command patterns |
| `seedShellCommands` | Exact shell lines seeded into Antigravity's settings |

### Why the order matters

Deny is checked **before** allow. Otherwise this slips through:

```
cat README.md && rm -rf /
```

The line starts with a permitted command. If allow ran first, the whole thing —
including the delete — would be approved. Tested; it fails correctly.

---

## Extending the policy

When an agent reports a legitimate block:

1. **Read the reason.** The broker names the exact pattern that fired.
2. **Ask whether the task really needs it.** Usually a permitted tool does the
   same job — `view_file` instead of `cat`, `grep_search` instead of `grep`.
3. **If it is genuinely needed, add the narrowest possible rule.** A pattern for
   one command, not for a whole program.
4. **Run the tests.** `node ~/.claude/brain/trio/broker.test.mjs`
5. **Never** add a rule that reopens one of these:
   - network access (cost risk)
   - package installation (changes the machine)
   - credential paths
   - the policy, broker or hook files themselves
   - starting another agent

---

## Non-obvious behaviour

These were established by testing, not documentation.

**1. `decision: "allow"` covers tools but not the shell.**
Enough for `view_file`, `edit_file`, `grep_search`. Not enough for
`run_command` — Antigravity still consults its own settings afterwards.

**2. `permissionOverrides` does not work for shell commands.**
The documentation implies the hook can grant shell access this way. It cannot.

**3. Shell grants must match the EXACT command line.**

| Grant | Command | Result |
|---|---|---|
| `command(cat README.md)` | `cat README.md` | runs |
| `command(cat)` | `cat PROGRESS.md` | **denied** |

There is no grant for a program, only for a string. That is why
`seedShellCommands` holds full lines and stays short — everything else goes
through tools, which the broker governs directly.

**4. `workspacePaths` only arrives with `--add-dir`.**
Without it the broker cannot tell which project it is deciding for. Every call
from `trio.mjs` sets it.

---

## Fail behaviour

The barrier always fails **closed**:

| Fault | Result |
|---|---|
| policy missing or broken | deny |
| stdin unreadable | deny |
| exception in the broker | deny |
| unknown tool | deny |
| command not in policy | deny, with explanation |

This was not assumed but triggered: a real bug in the broker produced `deny`,
not `allow`.

---

## Checking

```bash
node ~/.claude/brain/trio/broker.test.mjs
```

48 cases: normal work, destruction, command chaining, cost protection, self
protection, loop protection, credentials, escaping the project, fail-closed
behaviour.

**Run it after every change to the policy or the broker.** A policy that
silently stops matching is worse than no policy — it looks protective and is not.

---

## Codex

Codex does not need the broker. It ships its own sandbox:

| Mode | Effect |
|---|---|
| `--sandbox read-only` | Read only. For counter-review |
| `--full-auto` | Write inside the working directory, network blocked |

`--full-auto` is **not** the dangerous switch — that one is
`--dangerously-bypass-approvals-and-sandbox` and is never used.

On top of that, every Codex task runs in its own git worktree. Even a complete
sandbox failure would only affect a throwaway branch, never `main`.
