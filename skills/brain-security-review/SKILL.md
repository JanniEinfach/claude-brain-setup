# brain-security-review

## Purpose

A security review checklist for code and repositories. Run this before committing security-sensitive changes or before publishing a repository publicly.

## When to Use

Before committing changes that touch authentication, authorization, payments, user data, file system access, or external API calls. Before pushing any repository to a public host. After modifying any install or setup script.

## When Not to Use

Trivial documentation edits with no code changes. Single-line style or formatting fixes that do not touch logic.

## Workflow

**Secrets and credentials**

- No hardcoded API keys, passwords, tokens, or connection strings anywhere in the codebase.
- No private paths in public files (`/home/username/`, absolute machine-specific paths).
- `.env` files are in `.gitignore` and never committed.
- `CLAUDE.md` and config files contain no credentials.

Run this grep before committing or pushing:
```bash
grep -rn "password\|api.key\|token\|secret\|bearer\|private" . \
  --include="*.md" --include="*.sh" --include="*.json" \
  --include="*.ts" --include="*.js" --include="*.py" \
  -i -l
```

**Private data in public files**

- No internal hostnames, private IP addresses, or server names.
- No customer names, project names, or internal identifiers.
- No user account details.
- No absolute home directory paths (e.g., paths starting with `/home/username/` or system-specific absolute paths)

```bash
grep -rn "home/username\|192\.168\.\|10\.\|172\." . \
  --include="*.md" --include="*.sh" --include="*.json" -l
```

**Shell scripts**

- Review for `rm`, `rmdir`, `unlink` — are these operating on user files?
- Check for privilege escalation: `sudo`, `su`.
- Check for remote code execution: `curl | bash`, `wget | sh`.
- Untrusted input should never be passed directly to `eval` or `exec`.

**Settings files**

- `settings.json` allowlists should contain only commands you have reviewed.
- Write commands (`git commit`, `git push`, `rm`, `mv`, `cp`) should not be in a default allowlist.
- Network commands (`curl`, `wget`, `ssh`) should not be in a default allowlist.

**Auth, payment, and user data code**

Any code touching authentication, payment flows, or personal user data requires a deliberate review:
- Input validation present?
- Authorization check before action (not after)?
- Error messages do not reveal internal structure?
- Parameterized queries (no string-concatenated SQL)?
- HTML output is escaped (no raw user input into the DOM)?

**Before publishing to GitHub**

Run the full grep sweep:
```bash
git diff --stat HEAD~1
grep -r "home/username\|home/yourname" . --include="*.md" --include="*.sh" -l
grep -ri "password\|api.key" . --include="*.md" --include="*.sh" -l
```

Review `.gitignore` covers: `.env`, `*.secret`, `*.key`, backup files.

## Checklist

- [ ] No hardcoded secrets anywhere
- [ ] No private paths in public files
- [ ] `.env` in `.gitignore`
- [ ] Shell scripts reviewed for dangerous operations
- [ ] Settings allowlist reviewed
- [ ] Auth/payment code reviewed if touched
- [ ] Grep sweep clean before pushing

## Token Discipline

This skill is a checklist reference. Load it once when doing a security review pass. Cost: roughly 80 tokens. Re-use the grep commands by copy-pasting.

## Verification

The verification is the grep sweep itself. All listed grep commands should return no results in a clean codebase. If any return results, investigate before proceeding.

## Public Safety Notes

This skill contains no private data, no machine-specific paths, and no credentials. It is safe to include in a public repository.
