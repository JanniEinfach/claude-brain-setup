#!/usr/bin/env bash
# Claude Brain Setup — Quick non-interactive installer (Linux/macOS)
#
# Installs the generic default configuration without asking any questions:
#   - Root CLAUDE.md            -> ~/.claude/CLAUDE.md          (timestamped backup first)
#   - Brain runtime (always)    -> ~/.claude/brain/             (VERSION, config.json,
#                                                                check-update / update scripts, docs/)
#   - SessionStart update hook  -> ~/.claude/settings.json      (idempotent, backup first)
#   - Bundled Brain skills      -> ~/.claude/skills/            (only with --with-skills)
#
# Usage:
#   ./scripts/install.sh
#   ./scripts/install.sh --with-skills       # also install bundled Brain skills
#   ./scripts/install.sh --skills-only       # only skills + Brain runtime, skip CLAUDE.md
#   ./scripts/install.sh --dry-run           # show what would happen, write nothing
#   ./scripts/install.sh --no-update-check   # do not register the update hook
#
# No admin rights required. This script never deletes files — existing files
# are backed up with a timestamp before they are replaced.
#
# For a personalized configuration, run the interactive wizard instead:
#   ./scripts/setup.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"

SOURCE_CLAUDE_MD="$REPO_DIR/CLAUDE.md"
SOURCE_VERSION="$REPO_DIR/VERSION"
SOURCE_SKILLS="$REPO_DIR/skills"
SOURCE_DOCS="$REPO_DIR/docs"

CLAUDE_DIR="$HOME/.claude"
CLAUDE_MD_DEST="$CLAUDE_DIR/CLAUDE.md"
SKILLS_DEST="$CLAUDE_DIR/skills"
BRAIN_DIR="$CLAUDE_DIR/brain"
BRAIN_BACKUPS="$BRAIN_DIR/backups"
BRAIN_DOCS="$BRAIN_DIR/docs"
CONFIG_PATH="$BRAIN_DIR/config.json"
SETTINGS_PATH="$CLAUDE_DIR/settings.json"
V1_CLAUDE_MD="$HOME/CLAUDE.md"

# Hook command per spec — $HOME stays literal, Claude Code expands it at runtime.
HOOK_COMMAND='bash "$HOME/.claude/brain/check-update.sh"'
RUNTIME_SCRIPTS="check-update.sh update.sh check-update.ps1 update.ps1"

DRY_RUN=0
WITH_SKILLS=0
SKILLS_ONLY=0
NO_UPDATE_CHECK=0

usage() {
  # Print the header comment block (everything after the shebang up to the
  # first non-comment line) as help text.
  awk 'NR > 1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "$0"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --with-skills)     WITH_SKILLS=1; shift ;;
    --skills-only)     SKILLS_ONLY=1; WITH_SKILLS=1; shift ;;
    --dry-run)         DRY_RUN=1; shift ;;
    --no-update-check) NO_UPDATE_CHECK=1; shift ;;
    --help|-h)         usage; exit 0 ;;
    *) echo "Unknown option: $1 (try --help)" >&2; exit 1 ;;
  esac
done

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

ensure_dir() {
  # $1 = directory
  if [ -d "$1" ]; then return 0; fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [DRY RUN] Would create directory: $1"
  else
    mkdir -p "$1"
  fi
}

backup_file() {
  # Copies an existing file to <file>.backup_<timestamp>. Never deletes.
  # $1 = file path
  if [ ! -f "$1" ]; then return 0; fi
  local backup="$1.backup_${TIMESTAMP}"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [DRY RUN] Would back up: $1 -> $backup"
  else
    cp "$1" "$backup"
    echo "  Backed up: $1 -> $backup"
  fi
}

detect_os() {
  case "$(uname -s 2>/dev/null)" in
    Darwin) echo "macos" ;;
    *)      echo "linux" ;;
  esac
}

json_escape() {
  # Minimal JSON string escaping for backslashes and double quotes.
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------

echo ""
echo "Claude Brain Setup 2.0.0 — Quick Installer (Linux/macOS)"
echo "========================================================="
if [ "$DRY_RUN" -eq 1 ]; then
  echo "[DRY RUN] No files will be written."
fi
echo "Repository : $REPO_DIR"
echo "Target     : $CLAUDE_DIR"
echo ""

# ---------------------------------------------------------------------------
# Step 1: CLAUDE.md -> ~/.claude/CLAUDE.md (unless --skills-only)
# ---------------------------------------------------------------------------

if [ "$SKILLS_ONLY" -eq 0 ]; then
  echo "[1/4] Installing CLAUDE.md"

  if [ ! -f "$SOURCE_CLAUDE_MD" ]; then
    echo "Error: CLAUDE.md not found at $SOURCE_CLAUDE_MD" >&2
    echo "Run this script from inside the claude-brain-setup directory." >&2
    exit 1
  fi

  ensure_dir "$CLAUDE_DIR"
  backup_file "$CLAUDE_MD_DEST"

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [DRY RUN] Would copy CLAUDE.md to: $CLAUDE_MD_DEST"
  else
    cp "$SOURCE_CLAUDE_MD" "$CLAUDE_MD_DEST"
    echo "  Installed: $CLAUDE_MD_DEST"
  fi

  # V1 migration hint: the old install location was ~/CLAUDE.md.
  if [ -f "$V1_CLAUDE_MD" ]; then
    echo ""
    echo "  Warning: found a CLAUDE.md from a previous version at: $V1_CLAUDE_MD"
    echo "  Two CLAUDE.md files can give Claude conflicting instructions."
    echo "  The interactive wizard (scripts/setup.sh) can migrate it safely"
    echo "  (it renames the old file to a backup — nothing is deleted)."
  fi
  echo ""
else
  echo "[1/4] Skipping CLAUDE.md (--skills-only)"
  echo ""
fi

# ---------------------------------------------------------------------------
# Step 2: Bundled Brain skills (only with --with-skills / --skills-only)
# ---------------------------------------------------------------------------

if [ "$WITH_SKILLS" -eq 1 ]; then
  echo "[2/4] Installing bundled Brain skills"

  if [ ! -d "$SOURCE_SKILLS" ]; then
    echo "  Warning: skills/ directory not found at $SOURCE_SKILLS. Skipping skill install." >&2
  else
    ensure_dir "$SKILLS_DEST"
    INSTALLED_COUNT=0

    for SKILL_DIR in "$SOURCE_SKILLS"/*/; do
      [ -d "$SKILL_DIR" ] || continue
      SKILL_NAME="$(basename "$SKILL_DIR")"
      DEST_SKILL="$SKILLS_DEST/$SKILL_NAME"

      if [ "$DRY_RUN" -eq 1 ]; then
        if [ -d "$DEST_SKILL" ]; then
          echo "  [DRY RUN] Would back up existing skill: $SKILL_NAME"
        fi
        echo "  [DRY RUN] Would install skill: $SKILL_NAME"
      else
        if [ -d "$DEST_SKILL" ]; then
          mv "$DEST_SKILL" "${DEST_SKILL}.backup_${TIMESTAMP}"
          echo "  Backed up existing: $SKILL_NAME -> ${SKILL_NAME}.backup_${TIMESTAMP}"
        fi
        cp -r "$SKILL_DIR" "$DEST_SKILL"
        echo "  Installed: $SKILL_NAME"
      fi
      INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    done

    echo "  Total: $INSTALLED_COUNT skill(s)"
  fi
  echo ""
else
  echo "[2/4] Skipping skills (re-run with --with-skills to install them)"
  echo ""
fi

# ---------------------------------------------------------------------------
# Step 3: Brain runtime -> ~/.claude/brain/ (always)
# ---------------------------------------------------------------------------

echo "[3/4] Installing Brain runtime"

ensure_dir "$BRAIN_DIR"
ensure_dir "$BRAIN_BACKUPS"

# Back up an existing runtime before refreshing it (never delete).
BRAIN_VERSION_PATH="$BRAIN_DIR/VERSION"
if [ -f "$BRAIN_VERSION_PATH" ]; then
  OLD_VERSION="$(tr -d '[:space:]' < "$BRAIN_VERSION_PATH")"
  RUNTIME_BACKUP_DIR="$BRAIN_BACKUPS/preinstall-${OLD_VERSION}-${TIMESTAMP}"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [DRY RUN] Would back up existing runtime to: $RUNTIME_BACKUP_DIR"
  else
    mkdir -p "$RUNTIME_BACKUP_DIR"
    cp "$BRAIN_VERSION_PATH" "$RUNTIME_BACKUP_DIR/"
    for SCRIPT_NAME in $RUNTIME_SCRIPTS; do
      if [ -f "$BRAIN_DIR/$SCRIPT_NAME" ]; then
        cp "$BRAIN_DIR/$SCRIPT_NAME" "$RUNTIME_BACKUP_DIR/"
      fi
    done
    echo "  Backed up existing runtime to: $RUNTIME_BACKUP_DIR"
  fi
fi

# VERSION
if [ -f "$SOURCE_VERSION" ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [DRY RUN] Would copy VERSION to: $BRAIN_VERSION_PATH"
  else
    cp "$SOURCE_VERSION" "$BRAIN_VERSION_PATH"
    echo "  Installed: VERSION"
  fi
else
  echo "  Warning: VERSION file not found at $SOURCE_VERSION. Skipping." >&2
fi

# Runtime scripts (both platform variants, so the runtime dir is complete)
NATIVE_SCRIPT_MISSING=1
for SCRIPT_NAME in $RUNTIME_SCRIPTS; do
  SCRIPT_SRC="$SCRIPT_DIR/$SCRIPT_NAME"
  if [ -f "$SCRIPT_SRC" ]; then
    if [ "$SCRIPT_NAME" = "check-update.sh" ]; then NATIVE_SCRIPT_MISSING=0; fi
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "  [DRY RUN] Would copy $SCRIPT_NAME to: $BRAIN_DIR"
    else
      cp "$SCRIPT_SRC" "$BRAIN_DIR/$SCRIPT_NAME"
      case "$SCRIPT_NAME" in
        *.sh) chmod +x "$BRAIN_DIR/$SCRIPT_NAME" ;;
      esac
      echo "  Installed: $SCRIPT_NAME"
    fi
  else
    echo "  Warning: runtime script not found: $SCRIPT_SRC. Skipping." >&2
  fi
done

# Docs copy (reference documentation next to the runtime)
if [ -d "$SOURCE_DOCS" ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [DRY RUN] Would copy docs/ to: $BRAIN_DOCS"
  else
    mkdir -p "$BRAIN_DOCS"
    cp -r "$SOURCE_DOCS"/. "$BRAIN_DOCS/"
    echo "  Installed: docs/ -> $BRAIN_DOCS"
  fi
else
  echo "  Warning: docs/ directory not found at $SOURCE_DOCS. Skipping." >&2
fi

# ---------------------------------------------------------------------------
# config.json — write defaults only if no config exists yet.
# An existing config may contain personal answers from the wizard; keep it.
# ---------------------------------------------------------------------------

write_config_python3() {
  python3 - "$CONFIG_PATH" "$CLAUDE_MD_DEST" "$OS_NAME" "$UPDATE_ENABLED_JSON" "$INSTALLED_AT" <<'PYEOF'
import json, sys
path, claude_md, os_name, upd, installed_at = sys.argv[1:6]
cfg = {
    "version": "2.0.0",
    "repo": "JanniEinfach/claude-brain-setup",
    "branch": "main",
    "installedAt": installed_at,
    "os": os_name,
    "language": "en",
    "userName": "",
    "experience": "intermediate",
    "model": "unknown",
    "modelRaw": None,
    "planTier": "unknown",
    "obsidian": {"enabled": False, "vaultPath": "", "appInstalled": False},
    "updateCheck": {"enabled": upd == "true", "intervalHours": 24, "lastCheck": None},
    "claudeMdPath": claude_md,
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
PYEOF
}

write_config_jq() {
  jq -n \
    --arg installedAt "$INSTALLED_AT" \
    --arg os "$OS_NAME" \
    --arg claudeMdPath "$CLAUDE_MD_DEST" \
    --argjson updEnabled "$UPDATE_ENABLED_JSON" \
    '{
      version: "2.0.0",
      repo: "JanniEinfach/claude-brain-setup",
      branch: "main",
      installedAt: $installedAt,
      os: $os,
      language: "en",
      userName: "",
      experience: "intermediate",
      model: "unknown",
      modelRaw: null,
      planTier: "unknown",
      obsidian: { enabled: false, vaultPath: "", appInstalled: false },
      updateCheck: { enabled: $updEnabled, intervalHours: 24, lastCheck: null },
      claudeMdPath: $claudeMdPath
    }' > "$CONFIG_PATH"
}

write_config_heredoc() {
  local esc_path
  esc_path="$(json_escape "$CLAUDE_MD_DEST")"
  cat > "$CONFIG_PATH" <<EOF
{
  "version": "2.0.0",
  "repo": "JanniEinfach/claude-brain-setup",
  "branch": "main",
  "installedAt": "$INSTALLED_AT",
  "os": "$OS_NAME",
  "language": "en",
  "userName": "",
  "experience": "intermediate",
  "model": "unknown",
  "modelRaw": null,
  "planTier": "unknown",
  "obsidian": { "enabled": false, "vaultPath": "", "appInstalled": false },
  "updateCheck": { "enabled": $UPDATE_ENABLED_JSON, "intervalHours": 24, "lastCheck": null },
  "claudeMdPath": "$esc_path"
}
EOF
}

if [ -f "$CONFIG_PATH" ]; then
  echo "  Existing config.json found — keeping it untouched."
else
  OS_NAME="$(detect_os)"
  INSTALLED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  UPDATE_ENABLED_JSON="true"
  if [ "$NO_UPDATE_CHECK" -eq 1 ]; then UPDATE_ENABLED_JSON="false"; fi

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [DRY RUN] Would write default config.json to: $CONFIG_PATH"
  else
    if command -v python3 >/dev/null 2>&1 && write_config_python3; then
      :
    elif command -v jq >/dev/null 2>&1 && write_config_jq; then
      :
    else
      write_config_heredoc
    fi
    if [ "$UPDATE_ENABLED_JSON" = "true" ]; then
      echo "  Installed: config.json (defaults: language=en, update check enabled)"
    else
      echo "  Installed: config.json (defaults: language=en, update check disabled)"
    fi
  fi
fi
echo ""

# ---------------------------------------------------------------------------
# Step 4: SessionStart update hook in ~/.claude/settings.json (idempotent)
# ---------------------------------------------------------------------------

show_manual_hook_snippet() {
  echo "  Add this block manually to $SETTINGS_PATH (inside the top-level object):"
  cat <<'SNIPPET'
    "hooks": {
      "SessionStart": [
        {
          "matcher": "startup",
          "hooks": [
            {
              "type": "command",
              "command": "bash \"$HOME/.claude/brain/check-update.sh\""
            }
          ]
        }
      ]
    }
SNIPPET
}

merge_hook_python3() {
  python3 - "$SETTINGS_PATH" "$HOOK_COMMAND" <<'PYEOF'
import json, os, sys
path, cmd = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    with open(path, encoding="utf-8") as f:
        raw = f.read().strip()
    if raw:
        data = json.loads(raw)
hooks = data.setdefault("hooks", {})
session_start = hooks.setdefault("SessionStart", [])
session_start.append({"matcher": "startup",
                      "hooks": [{"type": "command", "command": cmd}]})
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PYEOF
}

merge_hook_jq() {
  local tmp_out
  tmp_out="${SETTINGS_PATH}.tmp_${TIMESTAMP}"
  if [ ! -f "$SETTINGS_PATH" ]; then
    printf '{}\n' > "$SETTINGS_PATH"
  fi
  if jq --arg cmd "$HOOK_COMMAND" \
    '.hooks.SessionStart = ((.hooks.SessionStart // []) + [{"matcher":"startup","hooks":[{"type":"command","command":$cmd}]}])' \
    "$SETTINGS_PATH" > "$tmp_out"; then
    mv "$tmp_out" "$SETTINGS_PATH"
    return 0
  fi
  # Clean up only the temp file this function just created.
  rm -f "$tmp_out"
  return 1
}

register_update_hook() {
  # Idempotency: skip if any command already references the check-update script.
  if [ -f "$SETTINGS_PATH" ] && grep -Eq 'brain[/\\]+check-update' "$SETTINGS_PATH"; then
    echo "  Update hook already registered — nothing to do."
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [DRY RUN] Would register SessionStart update hook in: $SETTINGS_PATH"
    return 0
  fi

  backup_file "$SETTINGS_PATH"

  if command -v python3 >/dev/null 2>&1; then
    if merge_hook_python3; then
      echo "  Registered SessionStart update hook in: $SETTINGS_PATH"
      return 0
    fi
    echo "  Warning: python3 could not update $SETTINGS_PATH (invalid JSON?)." >&2
    show_manual_hook_snippet
    return 0
  fi

  if command -v jq >/dev/null 2>&1; then
    if merge_hook_jq; then
      echo "  Registered SessionStart update hook in: $SETTINGS_PATH"
      return 0
    fi
    echo "  Warning: jq could not update $SETTINGS_PATH (invalid JSON?)." >&2
    show_manual_hook_snippet
    return 0
  fi

  echo "  Neither python3 nor jq found — cannot edit JSON safely." >&2
  show_manual_hook_snippet
  return 0
}

if [ "$NO_UPDATE_CHECK" -eq 1 ]; then
  echo "[4/4] Skipping update hook (--no-update-check)"
elif [ "$NATIVE_SCRIPT_MISSING" -eq 1 ] && [ "$DRY_RUN" -eq 0 ]; then
  echo "[4/4] Update hook"
  echo "  Warning: check-update.sh was not installed — hook registration skipped." >&2
else
  echo "[4/4] Registering daily update check (SessionStart hook)"
  ensure_dir "$CLAUDE_DIR"
  register_update_hook
fi
echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

if [ "$DRY_RUN" -eq 1 ]; then
  echo "[DRY RUN] Complete. No files were written."
  exit 0
fi

echo "========================================================="
echo " Quick installation complete."
echo "========================================================="
echo ""
echo "Installed:"
if [ "$SKILLS_ONLY" -eq 0 ]; then
  echo "  - CLAUDE.md      -> $CLAUDE_MD_DEST"
fi
if [ "$WITH_SKILLS" -eq 1 ]; then
  echo "  - Brain skills   -> $SKILLS_DEST"
fi
echo "  - Brain runtime  -> $BRAIN_DIR"
if [ "$NO_UPDATE_CHECK" -eq 0 ]; then
  echo "  - Update check   -> runs once per day at session start (opt-out: see docs/UPDATE.md)"
fi
echo ""
echo "Start Claude Code with:  claude"
echo ""
echo "---------------------------------------------------------"
echo " Recommended: run the interactive setup wizard!"
echo "---------------------------------------------------------"
echo " You just installed the generic default configuration."
echo " The wizard asks a few simple questions (in German or"
echo " English) and builds a CLAUDE.md tailored to YOU —"
echo " including the Obsidian Master Brain, Claude's"
echo " long-term memory across projects:"
echo ""
echo "     ./scripts/setup.sh"
echo ""
