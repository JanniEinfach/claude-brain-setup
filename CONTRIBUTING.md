# Contributing

Thank you for your interest in contributing to Claude Brain Setup.

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for community standards.

## How to Open Issues

Open a GitHub issue for:
- Bugs in the setup or install scripts
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
# Syntax check both Linux/macOS scripts
bash -n scripts/install.sh
bash -n scripts/setup.sh

# Validate settings JSON
python3 -m json.tool settings.example.json

# Check for private paths or sensitive data
grep -r "/home/" . --include="*.md" --include="*.sh" -l
grep -ri "password\|api.key\|token\|secret" . --include="*.md" --include="*.sh" -l

# Check for false claims
grep -ri "automatically switch\|auto.*model\|dream.*automatically\|context percentage\|exact.*percent" . --include="*.md" -l
```

For PowerShell scripts, review them manually or use:

```powershell
# Parse check (Windows)
Get-Content scripts\install.ps1 | Out-Null
Get-Content scripts\setup.ps1 | Out-Null
```

None of the grep checks should return results. If they do, fix the issues before submitting.

## Contribution Rules

- No secrets, private paths, IP addresses, or API keys in any file.
- No false claims about Claude Code capabilities (no auto model switching, no guaranteed token savings, no automatic CLAUDE.md editing by /dream).
- Install scripts must remain non-destructive: never delete user files, always backup before overwriting.
- Linux/macOS scripts must be portable bash 3.x compatible (no associative arrays, no mapfile).
- Windows PowerShell scripts must work without admin rights.
- Every overwrite must be preceded by a timestamped backup.

## PR Checklist

Before submitting a pull request, confirm:

- [ ] `bash -n scripts/install.sh` passes
- [ ] `bash -n scripts/setup.sh` passes
- [ ] `python3 -m json.tool settings.example.json` passes
- [ ] PowerShell scripts reviewed (if changed)
- [ ] No secrets, private paths, or API keys included
- [ ] No false claims about Claude Code capabilities
- [ ] Install scripts remain non-destructive
- [ ] README updated if behavior changes
- [ ] SECURITY.md updated if install permissions change
- [ ] CHANGELOG.md updated

## Adding New Setup Questions

1. Add your question to `scripts/setup.sh` with the next number in sequence.
2. Mirror the question in `scripts/setup.ps1` (keep both in sync).
3. Add the corresponding placeholder to `templates/CLAUDE.template.md`.
4. Add the substitution logic in both `setup.sh` and `setup.ps1`.
5. Document the new question in `docs/ONBOARDING_QUESTIONS.md` following the existing format.

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

Also test with a custom target directory to confirm `--target` works:

```bash
mkdir -p /tmp/test-brain
./scripts/setup.sh --target /tmp/test-brain
cat /tmp/test-brain/CLAUDE.md
```

For PowerShell (Windows):

```powershell
.\scripts\setup.ps1 -DryRun
```

## Code Style for Scripts

- Portable bash: no bash 4+ features (no associative arrays, no `mapfile`)
- `set -euo pipefail` at the top of every bash script
- Every prompt must accept Enter as the default
- Never use `rm`, `rmdir`, `unlink`, or any deletion on user files
- Every overwrite must be preceded by a timestamped backup
- PowerShell: `$ErrorActionPreference = 'Stop'` at the top, no `[void]` for required output

## Documentation Style

- Clear, plain English
- No excessive markdown formatting (avoid `---` dividers, avoid bullet lists for things that read naturally as prose)
- Honest about limitations — never claim Claude can do something it cannot
- Code examples should be copy-pasteable and correct
