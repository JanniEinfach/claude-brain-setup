# brain-pr-review

## Purpose

A PR review checklist specific to the claude-brain-setup repository. Ensures contributions meet quality, safety, and accuracy standards before merging.

## When to Use

When reviewing any pull request submitted to this repository.

## When Not to Use

General codebase PR reviews outside this project. Use your project's own review standards for other repositories.

## Workflow

**Safety: private data**

Run a grep sweep on changed files to check for hardcoded private paths and secrets:
```bash
grep -rn "home/username\|home/yourname\|192\.168\." . --include="*.md" --include="*.sh" --include="*.ps1" --include="*.json" -l
grep -ri "password\|api.key\|token\|secret" . --include="*.md" --include="*.sh" --include="*.ps1" --include="*.json" -l
```

Neither command should return results. If they do, request that the contributor remove the private data before merging.

**Accuracy: no false claims**

```bash
grep -ri "automatically switch\|guaranteed token\|exact.*context.*percent\|dream.*automatically.*claude.md" . --include="*.md" -l
```

This should return no results. Common false claims to look for:
- "Claude will automatically switch models" — not possible mid-session
- "Guaranteed X% token savings" — savings are not guaranteed
- "/dream automatically edits CLAUDE.md" — it does not
- "Exact context window percentage" — Claude estimates, does not have a precise counter

**Scripts: non-destructive behavior**

- Bash scripts pass `bash -n`
- No `rm`, `rmdir`, `unlink` on user files
- No `sudo` or `su`
- No `curl | bash` or `wget | sh`
- Every overwrite preceded by a timestamped backup

**JSON validity**
```bash
python3 -m json.tool settings.example.json
```

**Bundled skills (if any skill SKILL.md files were modified)**

- All required sections present: Purpose, When to Use, When Not to Use, Workflow, Checklist, Token Discipline, Verification, Public Safety Notes
- File is under 200 lines
- No private data (same grep sweep as above)
- No fake Claude capabilities claimed
- Naming follows the `brain-<topic>` convention

**Documentation**
- README updated if any user-facing behavior changed
- SECURITY.md updated if install script behavior or permissions changed
- CHANGELOG.md updated with a new entry
- CONTRIBUTING.md updated if validation rules changed

**Cross-platform**
- If bash scripts changed: tested on Linux or macOS with dry-run
- If PowerShell scripts changed: parsed without errors on Windows or with `pwsh`

## Checklist

- [ ] Grep sweep for private data: clear
- [ ] Grep sweep for false claims: clear
- [ ] Bash scripts pass `bash -n`
- [ ] No user-file deletion in scripts
- [ ] JSON files are valid
- [ ] PowerShell scripts reviewed (if changed)
- [ ] Bundled skills: required sections present, under 200 lines (if changed)
- [ ] README updated (if behavior changed)
- [ ] SECURITY.md updated (if install permissions changed)
- [ ] CHANGELOG.md updated
- [ ] PR template checklist complete

## Token Discipline

This skill is a review checklist. Load it when reviewing a PR, not during development. Cost: roughly 75 tokens.

## Verification

A PR passes review when every checklist item above has been checked and all grep sweeps return no results.

## Public Safety Notes

This skill contains no private data, no machine-specific paths, and no credentials. It is safe to include in a public repository.
