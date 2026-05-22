#!/usr/bin/env bash
# Claude Brain Setup — Quick non-interactive installer
# Copies default CLAUDE.md to ~/CLAUDE.md with a timestamped backup.
# Never deletes any file.
#
# Usage:
#   chmod +x scripts/install.sh
#   ./scripts/install.sh
#   ./scripts/install.sh --with-skills    # also install bundled Brain skills
#   ./scripts/install.sh --skills-only    # only install skills, skip CLAUDE.md
#
# For a personalized setup, use setup.sh instead.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_MD_SRC="$REPO_DIR/CLAUDE.md"
CLAUDE_MD_DEST="$HOME/CLAUDE.md"

WITH_SKILLS=0
SKILLS_ONLY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --with-skills) WITH_SKILLS=1; shift ;;
    --skills-only) SKILLS_ONLY=1; WITH_SKILLS=1; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

echo ""
echo "Claude Brain Setup — Quick Install"
echo "==================================="
echo "Repository: $REPO_DIR"
echo ""

# Install CLAUDE.md unless --skills-only
if [ "$SKILLS_ONLY" -eq 0 ]; then
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
fi

# Install bundled skills if requested
if [ "$WITH_SKILLS" -eq 1 ]; then
  SKILLS_SRC="$REPO_DIR/skills"
  SKILLS_DEST="$HOME/.claude/skills"

  if [ ! -d "$SKILLS_SRC" ]; then
    echo "Warning: skills/ directory not found at $SKILLS_SRC. Skipping skill install." >&2
  else
    mkdir -p "$SKILLS_DEST"
    echo ""
    echo "Installing bundled Brain skills to: $SKILLS_DEST"
    INSTALLED_COUNT=0

    for SKILL_DIR in "$SKILLS_SRC"/*/; do
      SKILL_NAME="$(basename "$SKILL_DIR")"
      DEST_SKILL="$SKILLS_DEST/$SKILL_NAME"

      if [ -d "$DEST_SKILL" ]; then
        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
        mv "$DEST_SKILL" "${DEST_SKILL}.backup_${TIMESTAMP}"
        echo "  Backed up existing: $SKILL_NAME → ${SKILL_NAME}.backup_${TIMESTAMP}"
      fi

      cp -r "$SKILL_DIR" "$DEST_SKILL"
      echo "  Installed: $SKILL_NAME"
      INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    done

    echo ""
    echo "Installed $INSTALLED_COUNT bundled Brain skill(s) to $SKILLS_DEST"
  fi
fi

# Optional: copy docs (only when not skills-only)
if [ "$SKILLS_ONLY" -eq 0 ]; then
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
fi

echo ""
echo "======================================="
echo " Installation complete."
echo "======================================="
echo ""
echo "Next steps:"
echo ""
if [ "$SKILLS_ONLY" -eq 0 ]; then
  echo "  1. Start Claude Code with your preferred model:"
  echo "       claude --model claude-sonnet-4-6"
  echo ""
  echo "  2. Ask Claude: 'What instructions are you following from CLAUDE.md?'"
  echo "     It should summarise the key rules from the file."
  echo ""
  echo "  3. For a personalized CLAUDE.md tailored to your workflow, run:"
  echo "       ./scripts/setup.sh"
  echo ""
fi
if [ "$WITH_SKILLS" -eq 0 ]; then
  echo "  Install bundled Brain skills:"
  echo "       ./scripts/install.sh --with-skills"
  echo ""
fi
echo "  Optional shell aliases (add to ~/.bashrc or ~/.zshrc):"
echo "       alias cc='claude --model claude-sonnet-4-6'"
echo "       alias cch='claude --model claude-haiku-4-5-20251001'"
echo "       alias cco='claude --model claude-opus-4-7'"
echo ""
echo "  See README.md for full documentation."
echo ""
