#!/usr/bin/env bash
# Claude Brain Setup — Quick non-interactive installer
# Copies default CLAUDE.md to ~/CLAUDE.md with a timestamped backup.
# Never deletes any file.
#
# Usage:
#   chmod +x scripts/install.sh
#   ./scripts/install.sh
#
# For a personalized setup, use setup.sh instead.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_MD_SRC="$REPO_DIR/CLAUDE.md"
CLAUDE_MD_DEST="$HOME/CLAUDE.md"

echo ""
echo "Claude Brain Setup — Quick Install"
echo "==================================="
echo "Repository: $REPO_DIR"
echo ""

# Verify source file exists
if [ ! -f "$CLAUDE_MD_SRC" ]; then
  echo "Error: CLAUDE.md not found at $CLAUDE_MD_SRC" >&2
  echo "Run this script from the claude-brain-setup directory." >&2
  exit 1
fi

# Backup existing CLAUDE.md with timestamp if present
if [ -f "$CLAUDE_MD_DEST" ]; then
  TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
  BACKUP="${CLAUDE_MD_DEST}.backup_${TIMESTAMP}"
  cp "$CLAUDE_MD_DEST" "$BACKUP"
  echo "Backed up existing CLAUDE.md to: $BACKUP"
else
  echo "No existing CLAUDE.md found. Fresh install."
fi

# Install
cp "$CLAUDE_MD_SRC" "$CLAUDE_MD_DEST"
LINE_COUNT=$(wc -l < "$CLAUDE_MD_DEST")
echo "Installed CLAUDE.md to $CLAUDE_MD_DEST ($LINE_COUNT lines)"

# Optional: copy docs
echo ""
printf "Copy docs/ to ~/claude-brain-docs/ for local reference? [y/N]: "
read -r COPY_DOCS
if echo "$COPY_DOCS" | grep -qE '^[yY]'; then
  DOCS_DEST="$HOME/claude-brain-docs"
  if [ -d "$DOCS_DEST" ]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    cp -r "$DOCS_DEST" "${DOCS_DEST}.backup_${TIMESTAMP}"
    echo "Backed up existing docs to ${DOCS_DEST}.backup_${TIMESTAMP}"
  fi
  cp -r "$REPO_DIR/docs" "$DOCS_DEST"
  echo "Docs copied to $DOCS_DEST"
fi

echo ""
echo "======================================="
echo " Installation complete."
echo "======================================="
echo ""
echo "Next steps:"
echo ""
echo "  1. Start Claude Code with your preferred model:"
echo "       claude --model claude-sonnet-4-6"
echo ""
echo "  2. Ask Claude: 'What instructions are you following from CLAUDE.md?'"
echo "     It should summarise the key rules from the file."
echo ""
echo "  3. For a personalized CLAUDE.md tailored to your workflow, run:"
echo "       ./scripts/setup.sh"
echo ""
echo "  4. Optional shell aliases (add to ~/.bashrc or ~/.zshrc):"
echo "       alias cc='claude --model claude-sonnet-4-6'"
echo "       alias cch='claude --model claude-haiku-4-5-20251001'"
echo "       alias cco='claude --model claude-opus-4-7'"
echo ""
echo "  See README.md for full documentation."
echo ""
