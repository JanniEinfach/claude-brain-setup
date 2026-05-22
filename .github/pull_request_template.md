## Summary

<!-- What does this PR change and why? -->

## Type of Change

- [ ] Documentation
- [ ] Installer / setup script (Linux/macOS)
- [ ] Windows PowerShell support
- [ ] Security improvement
- [ ] Bundled Brain skill (new or modified)
- [ ] Skill list update
- [ ] Bug fix
- [ ] Other: 

## Validation Performed

- [ ] `bash -n scripts/setup.sh` passes
- [ ] `bash -n scripts/install.sh` passes
- [ ] `python3 -m json.tool settings.example.json` passes
- [ ] PowerShell scripts reviewed (if changed)
- [ ] Grep for private data run and clear

## Security Impact

<!-- Does this change affect install behavior, permissions, or what the script writes? -->

## Checklist

- [ ] No secrets, private paths, or API keys included
- [ ] No false claims about Claude Code capabilities
- [ ] Install scripts remain non-destructive (no user file deletion)
- [ ] README updated if behavior changes
- [ ] SECURITY.md updated if install permissions change
- [ ] CHANGELOG.md updated
- [ ] Bundled skills: if modified, SKILL.md sections intact, under 200 lines, no private data, no fake capabilities
