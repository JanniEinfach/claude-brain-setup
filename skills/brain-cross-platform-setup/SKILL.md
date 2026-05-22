# brain-cross-platform-setup

## Purpose

A checklist and common-issue guide for verifying that install and setup scripts work correctly on Linux, macOS, and Windows PowerShell.

## When to Use

After modifying any setup or install script. Before submitting a PR that changes scripts. When adding a new question to the interactive setup flow.

## When Not to Use

Documentation-only changes with no script modifications.

## Workflow

**Linux and macOS validation**

Syntax check both scripts without executing them:
```bash
bash -n scripts/install.sh && echo "install.sh OK"
bash -n scripts/setup.sh && echo "setup.sh OK"
```

If `shellcheck` is available, run it for deeper static analysis:
```bash
shellcheck scripts/install.sh scripts/setup.sh
```

Test in a clean directory to catch path assumptions:
```bash
mkdir -p /tmp/brain-test-home
./scripts/setup.sh --dry-run --target /tmp/brain-test-home
```

Check that backups are created on overwrite:
```bash
./scripts/install.sh --target /tmp/brain-test-home
# Run again to confirm backup with timestamp is created
./scripts/install.sh --target /tmp/brain-test-home
ls /tmp/brain-test-home/
```

**Windows PowerShell validation**

Parse check (does not execute):
```powershell
Get-Content scripts\install.ps1 | Out-Null; Write-Host "install.ps1 parsed"
Get-Content scripts\setup.ps1 | Out-Null; Write-Host "setup.ps1 parsed"
```

Dry-run test:
```powershell
.\scripts\install.ps1 -DryRun
.\scripts\setup.ps1 -DryRun
```

If `pwsh` is available on Linux/macOS for cross-platform testing:
```bash
pwsh -NoProfile -Command "Get-Content scripts/setup.ps1 | Out-Null; Write-Host 'OK'"
```

**Common cross-platform issues**

| Issue | Linux/macOS fix | Windows fix |
|-------|-----------------|-------------|
| Script not executable | `chmod +x scripts/*.sh` | Scripts run with `.\scripts\name.ps1` |
| Path separator | Forward slash `/` | Backslash `\` (PowerShell also accepts `/`) |
| Home directory | `$HOME` or `~` | `$env:USERPROFILE` |
| Line endings | LF for `.sh` | LF or CRLF both work for `.ps1` |
| Tilde expansion | Works in bash | Use `$env:USERPROFILE` explicitly |

**Bash compatibility rules (bash 3.x on macOS)**

- No associative arrays (`declare -A`)
- No `mapfile` or `readarray`
- No `<<<` here-strings with multiple lines inside subshells when not needed
- Use `$()` not backticks for command substitution
- Test with `[ ]` not `[[ ]]` for maximum portability

**PowerShell compatibility rules**

- `$ErrorActionPreference = 'Stop'` at the top
- Use `$env:USERPROFILE` not `~` for home directory in scripts
- Use `Join-Path` for paths, not string concatenation with `\`
- Use `Test-Path` before accessing files
- `Copy-Item` instead of `cp`; `Rename-Item` instead of `mv`

## Checklist

- [ ] `bash -n` passes for both bash scripts
- [ ] Setup tested with `--dry-run` on Linux or macOS
- [ ] PowerShell scripts parsed without errors
- [ ] Backup behavior confirmed (second run creates `.backup_TIMESTAMP`)
- [ ] No bash 4+ features used in bash scripts
- [ ] No hardcoded `~` in PowerShell scripts

## Token Discipline

This skill is a reference checklist. Load it when validating scripts, not on every session. Cost: roughly 80 tokens.

## Verification

All validation commands listed above should produce no errors. The dry-run test should print a preview without creating any files. A second install run should create a timestamped backup of the previous install.

## Public Safety Notes

This skill contains no private data, no machine-specific paths, and no credentials. It is safe to include in a public repository.
