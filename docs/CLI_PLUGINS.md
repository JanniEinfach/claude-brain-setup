# Plugins for Codex and Antigravity

Both CLIs extend through plugins. This is what is worth installing, what is not,
and one consequence that is easy to miss.

---

## Read this first: plugins bypass the shell policy

The permission broker inspects **shell commands and tool calls**. A plugin that
talks to an external service does so through its own channel — the broker never
sees an outbound HTTP request made inside a plugin.

That matters:

- The policy blocks `curl` and `wget`. A plugin calling the same API is **not**
  blocked by that rule.
- Every connected plugin is a path for project data to leave the machine.
- Some plugins act on live systems: deploy, close tickets, charge customers.

So the rule for plugins is different from the rule for commands:

> **Install only what the current project actually needs, and prefer read-only
> scopes when the service offers them.**

A plugin you installed once "in case it is useful" is a permanently open door.

---

## Codex

```bash
codex plugin list                      # what is available
codex plugin add <name>@openai-curated-remote
codex plugin remove <name>
codex plugin marketplace list
```

Plugins are installed per machine, not per project.

### Worth having for most development work

| Plugin | What it gives you | Caution |
|---|---|---|
| `github` | Issues, PRs, code search without leaving the session | Write scope can push and merge — prefer read-only unless needed |
| `codex-security` | Security review pass over a diff or repo | None. Local analysis |
| `superpowers` | Extra general-purpose tooling | Broad surface — review what it adds |
| `coderabbit` | Automated PR review | Sends diffs to a third party |

### Worth having if the stack matches

| Plugin | When |
|---|---|
| `supabase` | Postgres schema, RLS policies, migrations |
| `vercel` | Deployments, env vars, build logs |
| `cloudflare` | Workers, DNS, edge config |
| `sentry` | Reading production errors while fixing them |
| `posthog` | Product analytics queries |
| `datadog` | Infrastructure metrics and logs |
| `circleci` | CI status and failed job logs |
| `stripe` | Billing integration work |
| `expo` | React Native builds |
| `remotion` | Programmatic video |
| `figma` | Reading design specs into code |
| `linear` | Issue tracking inside the session |

### Skip unless you specifically need them

`adobe`, `canva`, `airtable`, `clickup`, `monday-com`, `notion`, `slack`,
`gmail`, `google-drive`, `dropbox`, `sharepoint`, `teams`, `zoom`, `shopify`,
`zotero`, and the domain research plugins (`life-science-research`,
`ngs-analysis`, `public-equity-investing`).

These are fine tools. They are simply not development tooling, and each one adds
surface area and another place your data can go.

---

## Antigravity

```bash
agy plugin list
agy plugin install <target>            # supports plugin@marketplace
agy plugin import claude               # reuse plugins you already have in Claude Code
agy plugin import gemini
agy plugin uninstall <name>
agy plugin validate [path]
```

### Start with import, not install

`agy plugin import claude` pulls in the plugins already configured for Claude
Code. That is almost always the right first move: the tooling stays consistent
across both CLIs, and there is nothing new to review.

### MCP servers

Antigravity also speaks MCP:

```bash
agy mcp add <name> ...
agy mcp list
agy mcp disable <name>
```

Same caution applies. An MCP server is a process with its own permissions that
the broker does not govern.

---

## A sane default

For a typical web project, this is enough:

```bash
# Codex
codex plugin add github@openai-curated-remote
codex plugin add codex-security@openai-curated-remote
# plus one or two that match the stack, e.g. supabase, vercel

# Antigravity
agy plugin import claude
```

Everything else: add it when a task actually calls for it, and remove it when
the task is done. Plugin sprawl is how a carefully scoped setup quietly turns
into a broad one.

---

## Reviewing what you have

Worth doing every few months:

```bash
codex plugin list        # marked "installed"
agy plugin list
agy mcp list
```

For each one, ask: did I use this in the last three months, and does it still
need write access? If the answer to either is no, remove or downgrade it.
