#!/usr/bin/env bash
# update.sh — Claude Brain updater (Linux/macOS)
#
# Downloads the latest Claude Brain Setup package from GitHub and updates:
#   - bundled skills   ~/.claude/skills/brain-*
#   - Brain scripts    ~/.claude/brain/check-update.*, update.*
#   - documentation    ~/.claude/brain/docs/
#   - VERSION          ~/.claude/brain/VERSION
#
# It NEVER touches: ~/.claude/CLAUDE.md, your Obsidian vault, or
# ~/.claude/settings.json. In config.json only the "version" field is
# updated and missing default keys are added — all other values stay as
# they are. Nothing is ever deleted: the previous state is copied to
# ~/.claude/brain/backups/<old-version>-<timestamp>/ before anything is
# overwritten. rm is used exclusively on the temporary download folder
# this script creates itself.
#
# Dependencies: coreutils plus curl or wget. Zip extraction uses unzip,
# python3, or (bsd)tar — whichever is available.
#
# Usage:
#   bash "$HOME/.claude/brain/update.sh"           # interactive
#   bash "$HOME/.claude/brain/update.sh" --check   # check only
#   bash "$HOME/.claude/brain/update.sh" --yes     # no prompt

set -u

BRAIN_DIR="$HOME/.claude/brain"
SKILLS_DIR="$HOME/.claude/skills"
CONFIG="$BRAIN_DIR/config.json"
VERSION_FILE="$BRAIN_DIR/VERSION"

# Defaults; overridden by config.json when present.
REPO="JanniEinfach/claude-brain-setup"
BRANCH="main"
LANGUAGE="en"

CHECK=0
YES=0

usage() {
  cat <<'EOF'
Usage: update.sh [--check] [--yes]

  --check   Only check whether a newer version exists; do not install.
  --yes     Install without asking for confirmation.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --check) CHECK=1 ;;
    --yes)   YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

have() { command -v "$1" >/dev/null 2>&1; }

msg() { # $1 = German, $2 = English
  if [ "$LANGUAGE" = "de" ]; then
    printf '%s\n' "$1"
  else
    printf '%s\n' "$2"
  fi
}

# --- preflight ----------------------------------------------------------------

if [ ! -d "$BRAIN_DIR" ]; then
  echo "Claude Brain runtime not found at ~/.claude/brain."
  echo "Install it first: https://github.com/JanniEinfach/claude-brain-setup"
  exit 1
fi

if ! have curl && ! have wget; then
  echo "Neither curl nor wget found — please install one of them."
  exit 1
fi

json_get() {
  # $1 = dot-separated path inside config.json; prints the value or nothing.
  if have python3; then
    python3 - "$CONFIG" "$1" 2>/dev/null <<'PYEOF'
import json, sys
try:
    with open(sys.argv[1], encoding="utf-8-sig") as fh:
        node = json.load(fh)
    for key in sys.argv[2].split("."):
        node = node[key]
except Exception:
    sys.exit(0)
if node is True:
    print("true")
elif node is False:
    print("false")
elif node is not None:
    print(node)
PYEOF
  elif have jq; then
    jq -r "if .$1 == null then empty else (.$1 | tostring) end" "$CONFIG" 2>/dev/null
  fi
}

if [ -f "$CONFIG" ]; then
  if have python3 || have jq; then
    v="$(json_get repo)";     [ -n "$v" ] && REPO="$v"
    v="$(json_get branch)";   [ -n "$v" ] && BRANCH="$v"
    v="$(json_get language)"; [ -n "$v" ] && LANGUAGE="$v"
  else
    v="$(sed -n 's/.*"repo"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG" | head -n1)"
    [ -n "$v" ] && REPO="$v"
    v="$(sed -n 's/.*"branch"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG" | head -n1)"
    [ -n "$v" ] && BRANCH="$v"
    v="$(sed -n 's/.*"language"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG" | head -n1)"
    [ -n "$v" ] && LANGUAGE="$v"
  fi
fi

LOCAL_VERSION=""
if [ -f "$VERSION_FILE" ]; then
  LOCAL_VERSION="$(head -n1 "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]')"
fi
if [ -z "$LOCAL_VERSION" ] && [ -f "$CONFIG" ]; then
  if have python3 || have jq; then
    LOCAL_VERSION="$(json_get version)"
  else
    LOCAL_VERSION="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG" | head -n1)"
  fi
fi
if ! printf '%s' "$LOCAL_VERSION" | grep -Eq '^v?[0-9]+\.[0-9]+\.[0-9]+'; then
  LOCAL_VERSION="0.0.0"
fi

# --- helpers ------------------------------------------------------------------

fetch_url() { # $1 = url, $2 = timeout in seconds (default 5)
  t="${2:-5}"
  if have curl; then
    curl -fsSL --max-time "$t" "$1" 2>/dev/null
  elif have wget; then
    wget -qO- -T "$t" "$1" 2>/dev/null
  fi
}

download() { # $1 = url, $2 = output file
  if have curl; then
    curl -fL --max-time 120 -o "$2" "$1" 2>/dev/null
  elif have wget; then
    wget -q -T 120 -O "$2" "$1"
  else
    return 1
  fi
}

extract_zip() { # $1 = zip file, $2 = destination directory
  if have unzip; then
    unzip -q "$1" -d "$2" >/dev/null 2>&1 && return 0
  fi
  if have python3; then
    mkdir -p "$2"
    python3 -m zipfile -e "$1" "$2" >/dev/null 2>&1 && return 0
  fi
  if have tar; then
    # bsdtar (macOS default) extracts zip archives.
    mkdir -p "$2"
    tar -xf "$1" -C "$2" >/dev/null 2>&1 && return 0
  fi
  return 1
}

semver_part() { # $1 = version, $2 = segment index (1..3)
  printf '%s' "$1" | sed 's/^v//' | cut -d. -f"$2" | sed 's/[^0-9].*$//'
}

is_remote_newer() { # $1 = remote, $2 = local; returns 0 when remote > local
  i=1
  while [ "$i" -le 3 ]; do
    rp="$(semver_part "$1" "$i")"
    lp="$(semver_part "$2" "$i")"
    case "$rp" in ''|*[!0-9]*) return 1 ;; esac
    case "$lp" in ''|*[!0-9]*) lp=0 ;; esac
    if [ "$rp" -gt "$lp" ]; then return 0; fi
    if [ "$rp" -lt "$lp" ]; then return 1; fi
    i=$((i + 1))
  done
  return 1
}

# --- check remote version -------------------------------------------------------

REMOTE_VERSION="$(fetch_url "https://raw.githubusercontent.com/$REPO/$BRANCH/VERSION" 5 | head -n1 | tr -d '[:space:]')"

if [ -z "$REMOTE_VERSION" ]; then
  msg "GitHub ist nicht erreichbar (offline oder blockiert). Bitte später erneut versuchen." \
      "Could not reach GitHub (offline or blocked). Please try again later."
  exit 1
fi

if ! printf '%s' "$REMOTE_VERSION" | grep -Eq '^v?[0-9]+\.[0-9]+\.[0-9]+'; then
  msg "Unerwartete Antwort von GitHub: '$REMOTE_VERSION'" \
      "Unexpected response from GitHub: '$REMOTE_VERSION'"
  exit 1
fi

if ! is_remote_newer "$REMOTE_VERSION" "$LOCAL_VERSION"; then
  msg "Bereits aktuell — Version $LOCAL_VERSION ist installiert." \
      "Already up to date — version $LOCAL_VERSION is installed."
  exit 0
fi

if [ "$CHECK" -eq 1 ]; then
  msg "Update verfügbar: $REMOTE_VERSION (installiert: $LOCAL_VERSION)." \
      "Update available: $REMOTE_VERSION (installed: $LOCAL_VERSION)."
  msg "Ausführen: /brain-update in Claude Code oder ~/.claude/brain/update.sh" \
      "Run: /brain-update inside Claude Code or ~/.claude/brain/update.sh"
  exit 0
fi

if [ "$YES" -eq 0 ]; then
  if [ "$LANGUAGE" = "de" ]; then
    printf "Auf Version %s aktualisieren? [J/n] " "$REMOTE_VERSION"
  else
    printf "Update to version %s? [Y/n] " "$REMOTE_VERSION"
  fi
  read -r answer || answer=""
  case "$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')" in
    ''|j|ja|y|yes) : ;;
    *) msg "Abgebrochen. Es wurde nichts verändert." "Aborted. Nothing was changed."; exit 0 ;;
  esac
fi

# --- download -----------------------------------------------------------------

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/claude-brain-update.XXXXXX")" || {
  msg "Konnte kein Temp-Verzeichnis anlegen." "Could not create a temp directory."
  exit 1
}
cleanup() {
  # Removes ONLY the temp folder this script created itself.
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

# Package source: latest GitHub release first, branch zip as fallback.
ZIP_RELEASE=""
api_json="$(fetch_url "https://api.github.com/repos/$REPO/releases/latest" 15)"
if [ -n "$api_json" ]; then
  if have python3; then
    ZIP_RELEASE="$(printf '%s' "$api_json" | python3 -c 'import json, sys
try:
    print(json.load(sys.stdin).get("zipball_url", "") or "")
except Exception:
    pass' 2>/dev/null)"
  elif have jq; then
    ZIP_RELEASE="$(printf '%s' "$api_json" | jq -r '.zipball_url // empty' 2>/dev/null)"
  else
    ZIP_RELEASE="$(printf '%s' "$api_json" | tr ',' '\n' | sed -n 's/.*"zipball_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
  fi
fi
ZIP_BRANCH="https://codeload.github.com/$REPO/zip/refs/heads/$BRANCH"

msg "Lade Update-Paket herunter ..." "Downloading update package ..."

PKG_ROOT=""
PKG_VERSION=""

try_package() { # $1 = zip url, $2 = internal name
  url="$1"
  name="$2"
  [ -n "$url" ] || return 1
  zip="$TMP_ROOT/$name.zip"
  dest="$TMP_ROOT/$name"
  download "$url" "$zip" || return 1
  extract_zip "$zip" "$dest" || return 1
  root="$(find "$dest" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -n1)"
  [ -n "$root" ] || return 1
  [ -f "$root/VERSION" ] || return 1
  pv="$(head -n1 "$root/VERSION" | tr -d '[:space:]')"
  # Skip a stale release package that is not actually newer.
  is_remote_newer "$pv" "$LOCAL_VERSION" || return 1
  PKG_ROOT="$root"
  PKG_VERSION="$pv"
  return 0
}

try_package "$ZIP_RELEASE" "pkg1" || try_package "$ZIP_BRANCH" "pkg2" || {
  msg "Download oder Entpacken fehlgeschlagen — kein neueres Paket gefunden. (Für das Entpacken wird unzip, python3 oder tar benötigt.)" \
      "Download or extraction failed — no newer package found. (Extraction requires unzip, python3, or tar.)"
  exit 1
}

# --- backup: copy the current state before anything is overwritten -------------

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$BRAIN_DIR/backups/$LOCAL_VERSION-$TIMESTAMP"
mkdir -p "$BACKUP_DIR"
msg "Sichere aktuellen Stand nach: $BACKUP_DIR" "Backing up current state to: $BACKUP_DIR"

if [ -d "$SKILLS_DIR" ]; then
  for d in "$SKILLS_DIR"/brain-*; do
    [ -d "$d" ] || continue
    mkdir -p "$BACKUP_DIR/skills"
    cp -R "$d" "$BACKUP_DIR/skills/"
  done
fi
for f in check-update.sh check-update.ps1 update.sh update.ps1 VERSION; do
  if [ -f "$BRAIN_DIR/$f" ]; then
    cp "$BRAIN_DIR/$f" "$BACKUP_DIR/$f"
  fi
done

# --- install --------------------------------------------------------------------

if [ -d "$PKG_ROOT/skills" ]; then
  msg "Aktualisiere Skills ..." "Updating skills ..."
  mkdir -p "$SKILLS_DIR"
  for d in "$PKG_ROOT/skills"/brain-*; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    mkdir -p "$SKILLS_DIR/$name"
    cp -R "$d/." "$SKILLS_DIR/$name/"
    echo "  + $name"
  done
fi

# Brain scripts: copy to a temp name, then mv into place. mv replaces the
# inode, so this running update.sh keeps executing its old copy safely.
msg "Aktualisiere Brain-Skripte ..." "Updating Brain scripts ..."
for f in check-update.sh check-update.ps1 update.sh update.ps1; do
  src="$PKG_ROOT/scripts/$f"
  [ -f "$src" ] || continue
  cp "$src" "$BRAIN_DIR/$f.new"
  mv -f "$BRAIN_DIR/$f.new" "$BRAIN_DIR/$f"
done
chmod +x "$BRAIN_DIR/check-update.sh" "$BRAIN_DIR/update.sh" 2>/dev/null

if [ -d "$PKG_ROOT/docs" ]; then
  msg "Aktualisiere Dokumentation ..." "Updating documentation ..."
  mkdir -p "$BRAIN_DIR/docs"
  cp -R "$PKG_ROOT/docs/." "$BRAIN_DIR/docs/"
fi

cp "$PKG_ROOT/VERSION" "$VERSION_FILE"

# --- config.json: version field + missing default keys only ---------------------

update_config() {
  if [ ! -f "$CONFIG" ]; then
    # No config yet: create a minimal one.
    cat >"$CONFIG" <<JSONEOF
{
  "version": "$PKG_VERSION",
  "repo": "$REPO",
  "branch": "$BRANCH",
  "language": "$LANGUAGE",
  "updateCheck": {
    "enabled": true,
    "intervalHours": 24,
    "lastCheck": null
  }
}
JSONEOF
    return 0
  fi
  if have python3; then
    python3 - "$CONFIG" "$PKG_VERSION" "$REPO" "$BRANCH" 2>/dev/null <<'PYEOF'
import json, os, sys
path, ver, repo, branch = sys.argv[1:5]
try:
    with open(path, encoding="utf-8-sig") as fh:
        data = json.load(fh)
except Exception:
    sys.exit(1)  # never overwrite a file we could not parse
data["version"] = ver
data.setdefault("repo", repo)
data.setdefault("branch", branch)
uc = data.get("updateCheck")
if not isinstance(uc, dict):
    uc = {}
    data["updateCheck"] = uc
uc.setdefault("enabled", True)
uc.setdefault("intervalHours", 24)
uc.setdefault("lastCheck", None)
tmp = path + ".tmp"
with open(tmp, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
os.replace(tmp, path)
PYEOF
    return $?
  fi
  if have jq; then
    tmp="$CONFIG.tmp"
    if jq --arg v "$PKG_VERSION" --arg r "$REPO" --arg b "$BRANCH" '
        .version = $v
        | .repo = (.repo // $r)
        | .branch = (.branch // $b)
        | .updateCheck = ((.updateCheck // {})
            | .enabled = (if has("enabled") then .enabled else true end)
            | .intervalHours = (.intervalHours // 24)
            | .lastCheck = (if has("lastCheck") then .lastCheck else null end))
      ' "$CONFIG" >"$tmp" 2>/dev/null; then
      mv -f "$tmp" "$CONFIG"
      return 0
    fi
    rm -f "$tmp" 2>/dev/null   # our own temp file only
    return 1
  fi
  # Plain-text fallback: only replaces an existing version value.
  if grep -q '"version"' "$CONFIG" 2>/dev/null; then
    tmp="$CONFIG.tmp"
    if sed 's/"version"[[:space:]]*:[[:space:]]*"[^"]*"/"version": "'"$PKG_VERSION"'"/' "$CONFIG" >"$tmp" 2>/dev/null; then
      mv -f "$tmp" "$CONFIG"
      return 0
    fi
    rm -f "$tmp" 2>/dev/null   # our own temp file only
  fi
  return 1
}

if ! update_config; then
  msg "Hinweis: config.json konnte nicht aktualisiert werden und wurde nicht angefasst. Bitte das Feld \"version\" manuell auf $PKG_VERSION setzen." \
      "Note: config.json could not be updated and was left untouched. Please set its \"version\" field to $PKG_VERSION manually."
fi

# --- show the top section of the new CHANGELOG ----------------------------------

if [ -f "$PKG_ROOT/CHANGELOG.md" ]; then
  echo ""
  msg "Neu in dieser Version:" "What's new in this version:"
  awk '/^## /{ if (seen) exit; seen=1 } seen { print }' "$PKG_ROOT/CHANGELOG.md"
fi

echo ""
msg "Fertig! Claude Brain wurde auf Version $PKG_VERSION aktualisiert." \
    "Done! Claude Brain was updated to version $PKG_VERSION."
msg "Backup der vorherigen Version: $BACKUP_DIR" \
    "Backup of the previous version: $BACKUP_DIR"
msg "Nicht angefasst: ~/.claude/CLAUDE.md, settings.json, dein Vault." \
    "Left untouched: ~/.claude/CLAUDE.md, settings.json, your vault."

exit 0
