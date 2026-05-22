# Master Prompt — One-Time Setup

Paste this into Claude Code after installing `CLAUDE.md`. You only need to do this once per machine to verify Claude has loaded the configuration correctly.

---

```
I have installed a CLAUDE.md configuration file on this machine. Please confirm you have loaded it by summarising the following from it:

1. The model discipline rules (how models are chosen)
2. The planning threshold (when to plan before coding)
3. The code quality gates
4. The session discipline rules

Then confirm you are ready to work.
```

---

That is the full prompt. Keep it short. There is no need to paste the entire CLAUDE.md into the conversation — Claude Code reads it automatically from disk.

## What Happens Next

Claude will confirm it has read the configuration. If it cannot summarise those four points, check that `~/CLAUDE.md` exists and is readable.

## Useful Commands to Know

```bash
# Check which model you are on
claude --version

# Start with a specific model
claude --model claude-sonnet-4-6
claude --model claude-haiku-4-5-20251001
claude --model claude-opus-4-7

# Ask Claude to read the skill list
# Inside a session: /plan-agent
# Inside a session: /debug
# Inside a session: /create_handoff
```

## If Something Seems Off

Run this to check the file is in place:

```bash
ls -la ~/CLAUDE.md
head -20 ~/CLAUDE.md
```

If the file is missing, run `./scripts/install.sh` again from the repo directory.
