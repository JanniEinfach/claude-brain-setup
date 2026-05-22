# Suggested GitHub Labels

Apply these labels to issues and pull requests for consistent triage.

| Label | Color | Description |
|-------|-------|-------------|
| `bug` | #d73a4a | Something is not working correctly |
| `documentation` | #0075ca | Improvements or corrections to docs |
| `enhancement` | #a2eeef | A new feature or improvement |
| `security` | #e4e669 | Security concern, vulnerability, or hardening |
| `windows` | #bfd4f2 | Affects Windows / PowerShell scripts |
| `linux` | #d4edda | Affects Linux scripts or behavior |
| `macos` | #f9d0c4 | Affects macOS scripts or behavior |
| `installer` | #c5def5 | Affects install.sh, setup.sh, install.ps1, or setup.ps1 |
| `token-efficiency` | #e2d8f7 | Relates to token cost or context management |
| `good first issue` | #7057ff | Good for new contributors |

## Creating Labels via GitHub CLI

```bash
gh label create bug --color d73a4a --description "Something is not working correctly"
gh label create documentation --color 0075ca --description "Improvements or corrections to docs"
gh label create enhancement --color a2eeef --description "A new feature or improvement"
gh label create security --color e4e669 --description "Security concern, vulnerability, or hardening"
gh label create windows --color bfd4f2 --description "Affects Windows / PowerShell scripts"
gh label create linux --color d4edda --description "Affects Linux scripts or behavior"
gh label create macos --color f9d0c4 --description "Affects macOS scripts or behavior"
gh label create installer --color c5def5 --description "Affects install or setup scripts"
gh label create token-efficiency --color e2d8f7 --description "Relates to token cost or context management"
gh label create "good first issue" --color 7057ff --description "Good for new contributors"
```
