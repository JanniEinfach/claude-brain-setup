# Contributing

Thank you for your interest in contributing to Claude Brain Setup.

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for community standards.

## How to Open Issues

Open a GitHub issue for:
- Bugs in the setup, install, bootstrap, or update scripts
- Incorrect or outdated skill/agent names
- False claims in any documentation
- Missing troubleshooting cases
- Confusing or unclear questions in the setup flow

Please include your OS and shell version when reporting script bugs:

```bash
uname -a
bash --version
```

For Windows:

```powershell
$PSVersionTable.PSVersion
[System.Environment]::OSVersion
```

## How to Fork and Create a Branch

1. Fork the repository on GitHub.
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/claude-brain-setup.git`
3. Create a branch with a descriptive name:
   - `fix/setup-sh-dry-run`
   - `add/windows-installer`
   - `docs/principles-update`
4. Make your changes.
5. Run validation checks (see below).
6. Commit with a clear message: `git commit -m "fix: setup.sh dry-run not exiting correctly"`
7. Push your branch: `git push origin your-branch-name`
8. Open a pull request on GitHub.

## Validation Checks

Run these before submitting and confirm all pass:

```bash
# Syntax check all Linux/macOS scripts
for f in scripts/*.sh; do bash -n "$f"; done

# Validate settings JSON
python3 -m json.tool settings.example.json

# Check for private paths or sensitive data
grep -r "/home/" . --include="*.md" --include="*.sh" -l
grep -ri "password\|api.key\|token\|secret" . --include="*.md" --include="*.sh" -l

# Check for false claims
grep -ri "automatically switch\|auto.*model\|dream.*automatically\|context percentage\|exact.*percent" . --include="*.md" -l
```

For PowerShell scripts, run a real parse check (works in PowerShell 5.1):

```powershell
$errors = $null
[System.Management.Automation.PSParser]::Tokenize((Get-Content scripts\setup.ps1 -Raw), [ref]$errors) | Out-Null
$errors.Count   # must be 0
```

Repeat for every `.ps1` file you changed. None of the grep checks should return results. If they do, fix the issues before submitting.

## Contribution Rules

- No secrets, private paths, IP addresses, or API keys in any file.
- No false claims about Claude Code capabilities (no auto model switching, no guaranteed token savings, no automatic CLAUDE.md editing by /dream).
- Install and update scripts must remain non-destructive: never delete user files, always backup before overwriting.
- Linux/macOS scripts must be portable bash 3.x compatible (no associative arrays, no mapfile).
- Windows PowerShell scripts must work without admin rights.
- Every overwrite must be preceded by a timestamped backup.

## PowerShell 5.1 Compatibility

All `.ps1` scripts must run on Windows PowerShell 5.1 (the version preinstalled on Windows), not just PowerShell 7. That means:

- No pipeline chain operators `&&` and `||` — use `if ($?) { ... }` or separate statements.
- No ternary operator (`?:`), no null-coalescing (`??`), no null-conditional (`?.`) — use `if/else` and explicit `$null` checks.
- No PowerShell-7-only cmdlets or parameters (e.g. `ConvertFrom-Json -AsHashtable`).
- Test on 5.1 if you can: `powershell -NoProfile -File scripts\setup.ps1 -DryRun` (note: `powershell`, not `pwsh`).

## File Encodings and Line Endings

Mixed encodings break umlauts and shebangs. The rules are:

- **`.sh` files:** UTF-8 **without** BOM, **LF** line endings, first line `#!/usr/bin/env bash`. A CRLF bash script fails with cryptic errors.
- **`.ps1` files:** UTF-8 **with** BOM. Without the BOM, Windows PowerShell 5.1 misreads non-ASCII characters (umlauts in the bilingual wizard texts).
- `.gitattributes` should keep these stable; do not "normalize" line endings across the board in an editor.

Quick check before committing:

```bash
file scripts/*.sh          # must not say "CRLF"
head -c 3 scripts/setup.ps1 | xxd   # should start with ef bb bf (BOM)
```

## Script Parity: setup.ps1 ↔ setup.sh

The Windows and Unix wizards must stay **feature-identical**: same questions, same order, same option numbers, same defaults, same validation, same generated files. The same applies to the other script pairs (`install`, `bootstrap`, `check-update`, `update`).

If you change one side, change the other in the same PR. A PR that touches only one of a pair needs a very good reason in its description.

## Releases: VERSION and CHANGELOG

The update system compares the repository's `VERSION` file against the locally installed version, so releases must keep both files correct:

1. Bump `VERSION` (single line, semantic version, e.g. `2.1.0`, followed by a newline).
2. Add a matching `## [x.y.z] — YYYY-MM-DD` section at the **top** of `CHANGELOG.md`. The update script prints this section to the user after updating, so write it for end users.
3. Never re-use or lower a version number — the checker compares numerically per segment (major, minor, patch).
4. Tag the release on GitHub; the updater prefers `releases/latest` and falls back to the `main` branch ZIP.

## Adding New Setup Questions

1. Add your question to `scripts/setup.sh` with the next number in sequence — in both languages (German and English).
2. Mirror the question in `scripts/setup.ps1` (keep both in sync — see Script Parity above).
3. Add the corresponding placeholder to `templates/CLAUDE.template.md`.
4. Add the substitution logic in both `setup.sh` and `setup.ps1`.
5. Give the question a plain-language explanation line and a sensible default (Enter must always work).
6. Document the new question in `docs/ONBOARDING_QUESTIONS.md` following the existing format.

## How to Add a Bundled Skill

Bundled Brain skills live in `skills/<brain-skill-name>/SKILL.md`. They are portable instruction files included with this repository.

Rules for new bundled skills:

1. Follow the naming convention: `brain-<topic>`
2. Create `skills/brain-<topic>/SKILL.md`
3. Include all required sections in order: Purpose, When to Use, When Not to Use, Workflow, Checklist, Token Discipline, Verification, Public Safety Notes
4. Keep the file under 200 lines (target 80–150)
5. No private data: no absolute machine-specific paths, no credentials, no internal hostnames
6. No false capability claims (see Contribution Rules above)
7. The Verification section must contain a concrete, testable check

See `skills/brain-skill-authoring/SKILL.md` for the full guide.

Before submitting a PR with a new skill, run the security sweep from the Validation Checks section and confirm no private data appears.

## Updating the Skills List

The skills list in `docs/SKILLS.md` should only include skills that actually exist. To verify:

```bash
ls ~/.claude/skills/ | sort
```

When adding or removing skills:
- Update `docs/SKILLS.md` only.
- Do not add skills to `CLAUDE.md` or the template unless they are genuinely core skills.
- Note the token risk level (Low / Low-Medium / Medium / Medium-High / High).
- If a skill requires separate installation, mark it with "(optional, requires separate install)".

## Testing the Setup Script

Test `setup.sh` in dry-run mode to verify your changes work without writing files:

```bash
./scripts/setup.sh --dry-run
```

Test unattended with an answer file (one answer per line, empty line = default):

```bash
./scripts/setup.sh --dry-run --answer-file test-answers.txt
```

Also test with a custom target directory to confirm `--target` works:

```bash
mkdir -p /tmp/test-brain
./scripts/setup.sh --target /tmp/test-brain
cat /tmp/test-brain/CLAUDE.md
```

For PowerShell (Windows):

```powershell
.\scripts\setup.ps1 -DryRun
.\scripts\setup.ps1 -DryRun -AnswerFile test-answers.txt
```

## PR Checklist

Before submitting a pull request, confirm:

- [ ] `bash -n` passes for every changed `.sh` script
- [ ] PowerShell parse check passes for every changed `.ps1` script (see Validation Checks)
- [ ] Changed `.ps1` scripts are PowerShell 5.1 compatible (no `&&`/`||`, no ternary, no `??`)
- [ ] `.sh` files are LF/no-BOM; `.ps1` files are UTF-8 with BOM
- [ ] `setup.ps1` and `setup.sh` (and other script pairs) remain feature-identical
- [ ] `python3 -m json.tool settings.example.json` passes
- [ ] No secrets, private paths, or API keys included
- [ ] No false claims about Claude Code capabilities
- [ ] Scripts remain non-destructive
- [ ] README updated if behavior changes (README.md **and** README.de.md)
- [ ] SECURITY.md updated if install permissions or network access change
- [ ] CHANGELOG.md updated — and VERSION bumped if this lands in a release

## Code Style for Scripts

- Portable bash: no bash 4+ features (no associative arrays, no `mapfile`)
- `set -euo pipefail` at the top of every bash script
- Every prompt must accept Enter as the default
- Never use `rm`, `rmdir`, `unlink`, or any deletion on user files (deleting a temp folder the script itself created is acceptable)
- Every overwrite must be preceded by a timestamped backup
- PowerShell: `$ErrorActionPreference = 'Stop'` at the top, no `[void]` for required output
- `check-update` scripts must always exit 0 — they run as a session hook and must never break a Claude Code start

## Documentation Style

- Clear, plain English (README.de.md mirrors README.md in German)
- No excessive markdown formatting (avoid `---` dividers, avoid bullet lists for things that read naturally as prose)
- Honest about limitations — never claim Claude can do something it cannot
- Code examples should be copy-pasteable and correct
