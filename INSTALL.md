# Installing Claude Brain Setup

This guide walks you through the installation step by step — on Windows, Linux, and macOS. It assumes nothing: if you have never used a terminal before, start at the top.

If you already know your way around, the short version is in the [README Quick Start](README.md#quick-start).

## Before You Start

You need:

1. **Claude Code** — Anthropic's command-line tool. If you don't have it yet:
   - Install [Node.js](https://nodejs.org) (LTS version), then run `npm install -g @anthropic-ai/claude-code` in a terminal.
2. **A Claude account** — an Anthropic API key or a Claude Pro/Max subscription. Claude Code asks you to log in the first time you start it.
3. **About 5 minutes.** The setup asks 20 short questions; all but two (your name and your goals) have a default, so you can press Enter a lot.

You do **not** need admin/root rights, git, or the Obsidian app. Everything installs into your own user folder.

### What is a terminal?

A terminal (also called "console", "command line", "PowerShell", or "shell") is a window where you type commands instead of clicking buttons. You will copy exactly one command from this guide, paste it into that window, and press Enter. That's all the terminal knowledge you need here.

---

## Windows

### Step 1: Open PowerShell

1. Press the **Windows key** on your keyboard.
2. Type `powershell`.
3. Press **Enter**. A blue or black window opens with a blinking cursor — that's PowerShell.

You do **not** need to run it "as administrator". The normal window is correct.

### Step 2: Run the installer

Copy this line, paste it into the PowerShell window (right-click pastes), and press Enter:

```powershell
irm https://raw.githubusercontent.com/JanniEinfach/claude-brain-setup/main/scripts/bootstrap.ps1 | iex
```

This downloads the project into a temporary folder and starts the interactive setup. Nothing is installed yet — the setup asks you first.

> Running a script straight from the internet requires trust. If you prefer, open [`scripts/bootstrap.ps1`](scripts/bootstrap.ps1) on GitHub and read it before running — it is short.

### Step 3: Answer the questions

The setup speaks German or English — the very first question lets you choose. Every question is explained in plain language, has numbered options, and shows its default in square brackets. **Pressing Enter accepts the default.** At the end you see a summary of all your answers and confirm before anything is written to disk.

### Step 4: Start Claude Code

Type:

```powershell
claude
```

and just start typing what you want. Your personalized configuration is active in every project from now on.

### Windows troubleshooting

- **"running scripts is disabled on this system"** — your PowerShell execution policy blocks scripts. The one-liner above bypasses this for the bootstrap; if you run the scripts from a cloned folder instead, start them with:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\setup.ps1
  ```
- **`irm` not recognized** — you are probably in the old `cmd.exe`, not PowerShell. Go back to Step 1.
- More: [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md)

### Kurz auf Deutsch (Windows)

1. Windows-Taste drücken, `powershell` tippen, Enter — das blaue Fenster ist PowerShell (kein Administrator nötig).
2. Diese Zeile einfügen und Enter drücken:
   ```powershell
   irm https://raw.githubusercontent.com/JanniEinfach/claude-brain-setup/main/scripts/bootstrap.ps1 | iex
   ```
3. Die erste Frage des Setups ist die Sprachwahl — dort **Deutsch** wählen, dann ist alles Weitere auf Deutsch. Enter übernimmt jeweils den Vorschlag in eckigen Klammern (nur Name und Ziele brauchen eine eigene Antwort). Geschrieben wird erst nach deiner Bestätigung am Ende.
4. Danach `claude` tippen und loslegen.

---

## Linux / macOS

### Step 1: Open a terminal

- **macOS:** press **Cmd + Space**, type `Terminal`, press Enter.
- **Linux:** press **Ctrl + Alt + T**, or find "Terminal" in your application menu.

### Step 2: Run the installer

Copy this line, paste it into the terminal, and press Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/JanniEinfach/claude-brain-setup/main/scripts/bootstrap.sh | bash
```

This downloads the project into a temporary folder and starts the interactive setup. Nothing is installed yet — the setup asks you first.

> Prefer to read before you run? Open [`scripts/bootstrap.sh`](scripts/bootstrap.sh) on GitHub first — it is short.

### Step 3: Answer the questions

Same as on Windows: choose your language in question 1, press Enter to accept defaults, confirm the summary at the end.

### Step 4: Start Claude Code

```bash
claude
```

Your personalized configuration is active in every project from now on.

### Linux/macOS troubleshooting

- **`curl: command not found`** — install curl (`sudo apt install curl` on Debian/Ubuntu, `brew install curl` on macOS), or download the repository ZIP from GitHub manually and run `bash scripts/setup.sh` inside it.
- **"No TTY available"** — the bootstrap needs an interactive terminal for its questions. If you see this message (rare, e.g. inside some containers), clone or download the repo and run `./scripts/setup.sh` directly.
- More: [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md)

### Kurz auf Deutsch (Linux/macOS)

1. Terminal öffnen (macOS: Cmd + Leertaste, „Terminal" tippen; Linux: Strg + Alt + T).
2. Diese Zeile einfügen und Enter drücken:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/JanniEinfach/claude-brain-setup/main/scripts/bootstrap.sh | bash
   ```
3. In Frage 1 **Deutsch** wählen — der Rest des Setups läuft dann auf Deutsch. Enter übernimmt den Vorschlag (nur Name und Ziele brauchen eine eigene Antwort). Geschrieben wird erst nach deiner Bestätigung am Ende.
4. Danach `claude` tippen und loslegen.

---

## Alternative: Install via git clone

If you have git and want a local copy of the repository:

```bash
git clone https://github.com/JanniEinfach/claude-brain-setup.git
cd claude-brain-setup
./scripts/setup.sh
```

Windows (PowerShell):

```powershell
git clone https://github.com/JanniEinfach/claude-brain-setup.git
cd claude-brain-setup
.\scripts\setup.ps1
```

## Alternative: Quick install without questions

`install.sh` / `install.ps1` installs the generic default configuration with no questions asked — useful for a fast start or automation. It copies the default `CLAUDE.md`, sets up the brain runtime, and registers the update hook.

```bash
./scripts/install.sh --with-skills        # also install the 14 bundled skills
./scripts/install.sh --no-update-check    # skip the daily update check hook
./scripts/install.sh --dry-run            # preview without writing
```

```powershell
.\scripts\install.ps1 -WithSkills
.\scripts\install.ps1 -NoUpdateCheck
.\scripts\install.ps1 -DryRun
```

The quick install is generic by design — run the interactive setup later whenever you want the personalized version.

## What Gets Installed Where

| What | Location |
|------|----------|
| Personalized `CLAUDE.md` | `~/.claude/CLAUDE.md` |
| Bundled skills | `~/.claude/skills/brain-*/` |
| Brain runtime (version, config, updater, backups) | `~/.claude/brain/` |
| Obsidian Master Brain vault (if enabled) | default `~/Documents/ClaudeBrainVault` |
| Update hook | one entry in `~/.claude/settings.json` |

`~` means your home folder — `C:\Users\<you>` on Windows, `/home/<you>` on Linux, `/Users/<you>` on macOS.

Nothing is ever deleted. Existing files are backed up with a timestamp before any overwrite. If you still have a V1 install (`CLAUDE.md` directly in your home folder), the setup detects it and offers to rename it to `CLAUDE.md.backup-<timestamp>`.

## After the Install

- Start Claude Code with `claude` and just start typing.
- Check for Brain updates any time with `/brain-update` inside Claude Code.
- Read [`docs/OBSIDIAN_BRAIN.md`](docs/OBSIDIAN_BRAIN.md) to get the most out of the Master Brain.
- Want to change your answers? Just run the setup again — it backs up the previous configuration first.
