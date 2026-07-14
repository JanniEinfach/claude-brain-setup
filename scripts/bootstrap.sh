#!/usr/bin/env bash
# Claude Brain Setup — One-line web installer (Linux/macOS)
#
# Downloads the repository archive to a temporary folder, extracts it and
# starts the interactive setup wizard from there. No git required.
#
# One-liner (paste into your terminal):
#   curl -fsSL https://raw.githubusercontent.com/JanniEinfach/claude-brain-setup/main/scripts/bootstrap.sh | bash
#
# Notes:
#   - No admin rights required. Nothing outside your home directory is touched.
#   - Network access: one download from codeload.github.com (the repo archive).
#   - Requires curl or wget, plus unzip or tar.
#   - The wizard is interactive, so this script connects it to your terminal
#     (/dev/tty). Without a terminal it stops with instructions instead.
#   - Cleanup removes ONLY the temporary extraction folder created by this
#     script. It never deletes any of your files.

set -u

REPO="JanniEinfach/claude-brain-setup"
BRANCH="main"
ZIP_URL="https://codeload.github.com/${REPO}/zip/refs/heads/${BRANCH}"
TAR_URL="https://codeload.github.com/${REPO}/tar.gz/refs/heads/${BRANCH}"

echo ""
echo "Claude Brain Setup — Bootstrap (Linux/macOS)"
echo "============================================="
echo ""

# ---------------------------------------------------------------------------
# 0. The setup wizard is interactive — make sure we can reach the terminal.
#    When this script is piped into bash (curl | bash), stdin is the pipe,
#    so the wizard must read its answers from /dev/tty instead.
# ---------------------------------------------------------------------------

if ! { true < /dev/tty; } 2>/dev/null; then
  echo "Error: no interactive terminal (TTY) available." >&2
  echo "" >&2
  echo "The Claude Brain setup wizard needs to ask you a few questions," >&2
  echo "which is not possible in this environment (e.g. CI or a non-" >&2
  echo "interactive shell). Please download the repository and run the" >&2
  echo "wizard yourself:" >&2
  echo "" >&2
  echo "  git clone https://github.com/${REPO}.git" >&2
  echo "  cd claude-brain-setup" >&2
  echo "  bash scripts/setup.sh" >&2
  echo "" >&2
  echo "Or use the non-interactive quick install: bash scripts/install.sh" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 1. Pick a downloader (curl preferred, wget as fallback).
# ---------------------------------------------------------------------------

download() {
  # $1 = url, $2 = output file
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$2" "$1"
  else
    echo "Error: neither curl nor wget is installed." >&2
    echo "Install one of them and try again (e.g. 'sudo apt install curl')." >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# 2. Create a private temporary workspace and make sure ONLY that folder
#    is removed again when the script exits.
# ---------------------------------------------------------------------------

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/claude-brain-bootstrap.XXXXXX")"
if [ -z "$WORK_DIR" ] || [ ! -d "$WORK_DIR" ]; then
  echo "Error: could not create a temporary directory." >&2
  exit 1
fi

cleanup() {
  # Remove ONLY the temporary folder this script created.
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

EXTRACT_DIR="$WORK_DIR/extract"
mkdir -p "$EXTRACT_DIR"

# ---------------------------------------------------------------------------
# 3. Download and extract the repository archive.
#    Prefer zip + unzip; fall back to the tarball if unzip is missing.
# ---------------------------------------------------------------------------

if command -v unzip >/dev/null 2>&1; then
  ARCHIVE="$WORK_DIR/claude-brain-setup.zip"
  echo "Downloading: $ZIP_URL"
  if ! download "$ZIP_URL" "$ARCHIVE"; then
    echo "Error: download failed. Check your internet connection and try again." >&2
    exit 1
  fi
  echo "Extracting archive (unzip)..."
  if ! unzip -q "$ARCHIVE" -d "$EXTRACT_DIR"; then
    echo "Error: could not extract the archive." >&2
    exit 1
  fi
elif command -v tar >/dev/null 2>&1; then
  ARCHIVE="$WORK_DIR/claude-brain-setup.tar.gz"
  echo "Downloading: $TAR_URL"
  if ! download "$TAR_URL" "$ARCHIVE"; then
    echo "Error: download failed. Check your internet connection and try again." >&2
    exit 1
  fi
  echo "Extracting archive (tar)..."
  if ! tar -xzf "$ARCHIVE" -C "$EXTRACT_DIR"; then
    echo "Error: could not extract the archive." >&2
    exit 1
  fi
else
  echo "Error: neither unzip nor tar is installed — cannot extract the archive." >&2
  echo "Install one of them and try again (e.g. 'sudo apt install unzip')." >&2
  exit 1
fi
echo "Download complete."

# ---------------------------------------------------------------------------
# 4. Locate the setup wizard inside the extracted archive.
#    The archive extracts to a single folder named <repo>-<branch>.
# ---------------------------------------------------------------------------

SETUP_SH="$(find "$EXTRACT_DIR" -type f -name 'setup.sh' -path '*/scripts/*' 2>/dev/null | head -n 1)"
if [ -z "$SETUP_SH" ]; then
  echo "Error: setup.sh not found in the downloaded archive." >&2
  echo "The download may be incomplete — please try again." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 5. Run the interactive wizard with its stdin connected to the terminal.
# ---------------------------------------------------------------------------

echo ""
echo "Starting the interactive setup wizard..."
echo ""

bash "$SETUP_SH" < /dev/tty
SETUP_RC=$?

if [ "$SETUP_RC" -ne 0 ]; then
  echo "" >&2
  echo "The setup wizard exited with code $SETUP_RC." >&2
  echo "You can run it again any time:" >&2
  echo "  git clone https://github.com/${REPO}.git" >&2
  echo "  cd claude-brain-setup" >&2
  echo "  bash scripts/setup.sh" >&2
fi

# The EXIT trap removes the temporary folder.
exit "$SETUP_RC"
