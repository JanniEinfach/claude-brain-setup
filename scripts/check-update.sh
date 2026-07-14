#!/usr/bin/env bash
# check-update.sh — Claude Brain update check (SessionStart hook, Linux/macOS)
#
# Runs at every Claude Code session start via the SessionStart hook.
# Prints a short notice when a newer version exists on GitHub; otherwise
# prints nothing. It must never break a session start, so it ALWAYS exits
# with code 0 — even offline, without config.json, or on any internal error.
#
# Network: a single GET request to raw.githubusercontent.com (the VERSION
# file of the configured repo). No user data is sent. Timeout: 5 seconds.
# Total runtime target: under 6 seconds.
#
# Dependencies: coreutils plus curl or wget. python3 or jq are used when
# available; a plain-text fallback covers systems without either.
#
# Usage:
#   bash "$HOME/.claude/brain/check-update.sh" [--force]
#
#   --force   Ignore the configured check interval and query GitHub now.

# Deliberately no `set -e`: nothing here may abort the session start.

BRAIN_DIR="$HOME/.claude/brain"
CONFIG="$BRAIN_DIR/config.json"
VERSION_FILE="$BRAIN_DIR/VERSION"
MARKER_FILE="$BRAIN_DIR/.lastcheck"

FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
  esac
done

# Brain runtime not installed -> nothing to check.
[ -d "$BRAIN_DIR" ] || exit 0

have() { command -v "$1" >/dev/null 2>&1; }

# --- defaults (survive a missing or broken config.json) ---------------------
REPO="JanniEinfach/claude-brain-setup"
BRANCH="main"
LANGUAGE="en"
ENABLED="true"
INTERVAL_HOURS="24"
LAST_CHECK=""

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
    v="$(json_get updateCheck.enabled)"; [ -n "$v" ] && ENABLED="$v"
    v="$(json_get updateCheck.intervalHours)"
    case "$v" in
      ''|*[!0-9]*) : ;;
      *) INTERVAL_HOURS="$v" ;;
    esac
    v="$(json_get updateCheck.lastCheck)"; [ -n "$v" ] && LAST_CHECK="$v"
  else
    # Plain-text fallback — works with the pretty-printed config.json that
    # the Brain scripts write themselves.
    v="$(sed -n 's/.*"repo"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG" | head -n1)"
    [ -n "$v" ] && REPO="$v"
    v="$(sed -n 's/.*"branch"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG" | head -n1)"
    [ -n "$v" ] && BRANCH="$v"
    v="$(sed -n 's/.*"language"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG" | head -n1)"
    [ -n "$v" ] && LANGUAGE="$v"
    block="$(sed -n '/"updateCheck"/,/}/p' "$CONFIG")"
    if printf '%s\n' "$block" | grep -q '"enabled"[[:space:]]*:[[:space:]]*false'; then
      ENABLED="false"
    fi
    v="$(printf '%s\n' "$block" | sed -n 's/.*"intervalHours"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' | head -n1)"
    [ -n "$v" ] && INTERVAL_HOURS="$v"
    v="$(printf '%s\n' "$block" | sed -n 's/.*"lastCheck"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
    [ -n "$v" ] && LAST_CHECK="$v"
  fi
fi

case "$ENABLED" in
  false|False|FALSE|0) exit 0 ;;
esac

case "$INTERVAL_HOURS" in
  ''|*[!0-9]*|0) INTERVAL_HOURS=24 ;;
esac

# Broken or missing config leaves no usable lastCheck: fall back to the
# .lastcheck marker file so the interval gate still applies. config.json
# itself is never touched in that state.
if [ -z "$LAST_CHECK" ] && [ -f "$MARKER_FILE" ]; then
  LAST_CHECK="$(head -n1 "$MARKER_FILE" 2>/dev/null | tr -d '[:space:]')"
fi

# --- interval gate (skipped with --force) ------------------------------------
now_epoch="$(date -u +%s)"
if [ "$FORCE" -eq 0 ] && [ -n "$LAST_CHECK" ]; then
  # GNU date first, BSD/macOS date as fallback. Unparseable -> check is due.
  last_epoch="$(date -u -d "$LAST_CHECK" +%s 2>/dev/null)"
  if [ -z "$last_epoch" ]; then
    last_epoch="$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$LAST_CHECK" +%s 2>/dev/null)"
  fi
  if [ -n "$last_epoch" ]; then
    age=$(( now_epoch - last_epoch ))
    if [ "$age" -ge 0 ] && [ "$age" -lt $(( INTERVAL_HOURS * 3600 )) ]; then
      exit 0
    fi
  fi
fi

# --- local version ------------------------------------------------------------
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
[ -z "$LOCAL_VERSION" ] && LOCAL_VERSION="0.0.0"

# --- remote version (single small GET, 5 s timeout) ---------------------------
fetch_url() {
  if have curl; then
    curl -fsSL --max-time 5 "$1" 2>/dev/null
  elif have wget; then
    wget -qO- -T 5 "$1" 2>/dev/null
  fi
}

REMOTE_VERSION="$(fetch_url "https://raw.githubusercontent.com/$REPO/$BRANCH/VERSION" | head -n1 | tr -d '[:space:]')"

# --- persist lastCheck after EVERY attempt (even on network failure) ----------
save_last_check() {
  now_iso="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [ -f "$CONFIG" ]; then
    if have python3; then
      # Never overwrites a config.json that cannot be parsed.
      python3 - "$CONFIG" "$now_iso" 2>/dev/null <<'PYEOF'
import json, os, sys
path, ts = sys.argv[1], sys.argv[2]
try:
    with open(path, encoding="utf-8-sig") as fh:
        data = json.load(fh)
except Exception:
    sys.exit(0)
uc = data.get("updateCheck")
if not isinstance(uc, dict):
    uc = {"enabled": True, "intervalHours": 24}
    data["updateCheck"] = uc
uc["lastCheck"] = ts
tmp = path + ".tmp"
with open(tmp, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
os.replace(tmp, path)
PYEOF
    elif have jq; then
      tmp="$CONFIG.tmp"
      if jq --arg ts "$now_iso" '.updateCheck.lastCheck = $ts' "$CONFIG" >"$tmp" 2>/dev/null; then
        mv -f "$tmp" "$CONFIG"
      else
        rm -f "$tmp" 2>/dev/null   # our own temp file only
      fi
    else
      # Plain-text fallback: only replaces an existing lastCheck value.
      if grep -q '"lastCheck"' "$CONFIG" 2>/dev/null; then
        tmp="$CONFIG.tmp"
        if sed -e 's/"lastCheck"[[:space:]]*:[[:space:]]*null/"lastCheck": "'"$now_iso"'"/' \
               -e 's/"lastCheck"[[:space:]]*:[[:space:]]*"[^"]*"/"lastCheck": "'"$now_iso"'"/' \
               "$CONFIG" >"$tmp" 2>/dev/null; then
          mv -f "$tmp" "$CONFIG"
        else
          rm -f "$tmp" 2>/dev/null   # our own temp file only
        fi
      fi
    fi
  else
    # No config yet: create a minimal one so the interval works next time.
    cat >"$CONFIG" 2>/dev/null <<JSONEOF
{
  "version": "$LOCAL_VERSION",
  "repo": "$REPO",
  "branch": "$BRANCH",
  "language": "$LANGUAGE",
  "updateCheck": {
    "enabled": true,
    "intervalHours": $INTERVAL_HOURS,
    "lastCheck": "$now_iso"
  }
}
JSONEOF
  fi
}

save_lastcheck_marker() {
  # Fallback timestamp store (~/.claude/brain/.lastcheck). Keeps the interval
  # gate working when config.json is broken or missing, without ever touching
  # config.json itself. Best-effort only.
  date -u +%Y-%m-%dT%H:%M:%SZ >"$MARKER_FILE" 2>/dev/null
}

save_last_check
save_lastcheck_marker

[ -n "$REMOTE_VERSION" ] || exit 0

# --- numeric semver comparison per segment (never a string comparison) --------
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

if is_remote_newer "$REMOTE_VERSION" "$LOCAL_VERSION"; then
  if [ "$LANGUAGE" = "de" ]; then
    echo "=============================================="
    echo " Claude Brain Update verfügbar: $REMOTE_VERSION"
    echo " Installiert: $LOCAL_VERSION"
    echo " Update ausführen:  /brain-update  (in Claude Code)"
    echo " oder manuell:      ~/.claude/brain/update.sh"
    echo "=============================================="
  else
    echo "=============================================="
    echo " Claude Brain update available: $REMOTE_VERSION"
    echo " Installed: $LOCAL_VERSION"
    echo " Run the update:  /brain-update  (inside Claude Code)"
    echo " or manually:     ~/.claude/brain/update.sh"
    echo "=============================================="
  fi
fi

exit 0
