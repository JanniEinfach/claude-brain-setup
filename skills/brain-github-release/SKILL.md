# brain-github-release

## Purpose

A step-by-step checklist for preparing and publishing a public GitHub release of this project. Covers pre-release validation, git steps, and post-release tasks.

## When to Use

When preparing a new public GitHub release of claude-brain-setup or a fork of it.

## When Not to Use

Internal or private repository publishes where the security sweep and public-safety checks are not relevant. General software release work outside this project.

## Workflow

**Pre-release validation**

Run all syntax and format checks:
```bash
bash -n scripts/install.sh && echo "install.sh OK"
bash -n scripts/setup.sh && echo "setup.sh OK"
python3 -m json.tool settings.example.json && echo "JSON OK"
```

Security sweep — all commands should return no results:
```bash
grep -r "home/username\|home/yourname\|192\.168\." . --include="*.md" --include="*.sh" --include="*.ps1" --include="*.json" -l
grep -ri "password\|api.key\|token\|secret" . --include="*.md" --include="*.sh" --include="*.ps1" --include="*.json" -l
grep -ri "automatically switch\|guaranteed token\|dream.*automatically.*claude.md" . --include="*.md" -l
```

Documentation check:
- README has an honest "What this is NOT" or equivalent section
- CHANGELOG updated for this release
- LICENSE present
- CONTRIBUTING.md present
- .gitignore covers `.env`, `*.secret`, backup files, OS junk

Community files check:
- `.github/pull_request_template.md` present
- `.github/ISSUE_TEMPLATE/` has at least a bug report template
- No empty directories committed

**Git steps**

```bash
git status
git add .
git commit -m "feat: describe the release"
```

Create a new public repository (if first time):
```bash
gh repo create claude-brain-setup --public \
  --description "Practical Claude Code configuration toolkit" \
  --source . --remote origin --push
```

Push to existing repository:
```bash
git push origin main
```

Tag the release:
```bash
git tag v0.4.0
git push origin v0.4.0
```

Create a GitHub release with notes:
```bash
gh release create v0.4.0 --title "v0.4.0 — Bundled Brain Skills" \
  --notes "See CHANGELOG.md for full details."
```

**Post-release tasks**

- Set up GitHub issue labels: see `docs/GITHUB_LABELS.md`
- Enable Discussions if you want community feedback
- Verify the README renders correctly on GitHub
- Check that the install commands in README work from a clean clone

## Checklist

- [ ] `bash -n` passes for both bash scripts
- [ ] JSON files validate with `python3 -m json.tool`
- [ ] Security grep sweep returns no results
- [ ] False-claims grep sweep returns no results
- [ ] README has honest "What this is NOT" section
- [ ] CHANGELOG updated
- [ ] LICENSE present
- [ ] CONTRIBUTING.md present
- [ ] .gitignore covers secrets and backups
- [ ] Community files present
- [ ] Git commit created
- [ ] Release tagged

## Token Discipline

This skill is a release checklist. Load it once per release. Cost: roughly 75 tokens.

## Verification

After publishing, clone the repository from scratch in a fresh directory and run the install:
```bash
git clone https://github.com/yourname/claude-brain-setup.git /tmp/brain-verify
cd /tmp/brain-verify
bash -n scripts/install.sh
bash scripts/install.sh --target /tmp/brain-verify-home
ls /tmp/brain-verify-home/CLAUDE.md
```

The install should succeed without errors.

## Public Safety Notes

This skill contains no private data, no machine-specific paths, and no credentials. It is safe to include in a public repository.
