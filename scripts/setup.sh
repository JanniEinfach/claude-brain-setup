#!/usr/bin/env bash
# Claude Brain Setup — Interactive personalized CLAUDE.md generator
# Usage:
#   ./scripts/setup.sh
#   ./scripts/setup.sh --dry-run
#   ./scripts/setup.sh --target /path/to/dir
#
# Compatible with bash 3.x (macOS) and bash 4+/5 (Linux).
# Does not use associative arrays or bash 4+ features.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_FILE="$PROJECT_ROOT/templates/CLAUDE.template.md"

DRY_RUN=0
TARGET_DIR="$HOME"

# Parse flags
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --target)
      if [ -z "${2:-}" ]; then
        echo "Error: --target requires a path argument." >&2
        exit 1
      fi
      TARGET_DIR="$2"
      shift 2
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Verify template exists
if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "Error: Template not found at $TEMPLATE_FILE" >&2
  echo "Run this script from the claude-brain-setup directory." >&2
  exit 1
fi

OUTPUT_FILE="$TARGET_DIR/CLAUDE.md"

echo ""
echo "Claude Brain Setup — Interactive Configuration"
echo "==============================================="
if [ $DRY_RUN -eq 1 ]; then
  echo "[DRY RUN] No files will be written."
fi
echo "This will generate a personalized CLAUDE.md at: $OUTPUT_FILE"
echo "Existing CLAUDE.md will be backed up before overwriting."
echo ""

# Helper: prompt with default
ask() {
  local prompt="$1"
  local default="$2"
  local response
  if [ -n "$default" ]; then
    printf "%s [%s]: " "$prompt" "$default"
  else
    printf "%s: " "$prompt"
  fi
  read -r response
  if [ -z "$response" ] && [ -n "$default" ]; then
    echo "$default"
  else
    echo "$response"
  fi
}

# Helper: numbered menu
menu() {
  local title="$1"
  shift
  local options=("$@")
  echo ""
  echo "$title"
  local i=1
  for opt in "${options[@]}"; do
    printf "  %d) %s\n" "$i" "$opt"
    i=$((i + 1))
  done
  printf "  Choice [1]: "
  local choice
  read -r choice
  if [ -z "$choice" ]; then
    choice=1
  fi
  # Validate
  if ! echo "$choice" | grep -qE '^[0-9]+$'; then
    choice=1
  fi
  if [ "$choice" -lt 1 ] || [ "$choice" -gt "${#options[@]}" ]; then
    choice=1
  fi
  echo "$choice"
}

echo "=== Question 1 of 15 ==="
USER_NAME=$(ask "What should Claude call you?" "User")

echo ""
echo "=== Question 2 of 15 ==="
Q2=$(menu "Preferred response language:" \
  "English" \
  "German" \
  "French" \
  "Spanish" \
  "Other (you can specify)" \
)
case "$Q2" in
  1) PRIMARY_LANGUAGE="English" ;;
  2) PRIMARY_LANGUAGE="German" ;;
  3) PRIMARY_LANGUAGE="French" ;;
  4) PRIMARY_LANGUAGE="Spanish" ;;
  5) PRIMARY_LANGUAGE=$(ask "Which language?" "English") ;;
  *) PRIMARY_LANGUAGE="English" ;;
esac

echo ""
echo "=== Question 3 of 15 ==="
Q3=$(menu "Main work type:" \
  "General software development" \
  "Web / frontend" \
  "Backend / API" \
  "Full-stack" \
  "FiveM / game scripts" \
  "DevOps / infrastructure" \
  "Data / AI / ML" \
  "Marketing / sales" \
)
case "$Q3" in
  1) MAIN_WORK_TYPE="General software development" ;;
  2) MAIN_WORK_TYPE="Web / frontend" ;;
  3) MAIN_WORK_TYPE="Backend / API" ;;
  4) MAIN_WORK_TYPE="Full-stack" ;;
  5) MAIN_WORK_TYPE="FiveM / game scripts" ;;
  6) MAIN_WORK_TYPE="DevOps / infrastructure" ;;
  7) MAIN_WORK_TYPE="Data / AI / ML" ;;
  8) MAIN_WORK_TYPE="Marketing / sales" ;;
  *) MAIN_WORK_TYPE="General software development" ;;
esac

echo ""
echo "=== Question 4 of 15 ==="
Q4=$(menu "Default model strategy:" \
  "Sonnet (good default for most work)" \
  "Start with Haiku for cheap tasks" \
  "Opus when I need depth" \
)
case "$Q4" in
  1)
    DEFAULT_MODEL='Recommended:
- `claude --model claude-haiku-4-5-20251001` — formatting, renaming, simple edits
- `claude --model claude-sonnet-4-6` — standard development work (default)
- `claude --model claude-opus-4-7` — architecture, security, complex multi-file work'
    ;;
  2)
    DEFAULT_MODEL='Recommended:
- `claude --model claude-haiku-4-5-20251001` — start here for most tasks (default)
- `claude --model claude-sonnet-4-6` — when Haiku is not enough
- `claude --model claude-opus-4-7` — architecture, security only'
    ;;
  3)
    DEFAULT_MODEL='Recommended:
- `claude --model claude-sonnet-4-6` — standard work and quick tasks
- `claude --model claude-opus-4-7` — default for complex reasoning (default)
- `claude --model claude-haiku-4-5-20251001` — formatting, renaming only'
    ;;
  *) DEFAULT_MODEL='Use `claude --model claude-sonnet-4-6` as default. See docs/MODEL_ROUTING.md.' ;;
esac

echo ""
echo "=== Question 5 of 15 ==="
Q5=$(menu "Token-saving strictness:" \
  "Conservative — search before reading, handoff when needed" \
  "Balanced" \
  "Aggressive — strict handoffs, short focused sessions" \
)
case "$Q5" in
  1) TOKEN_STRATEGY="Conservative" ;;
  2) TOKEN_STRATEGY="Balanced" ;;
  3) TOKEN_STRATEGY="Aggressive" ;;
  *) TOKEN_STRATEGY="Balanced" ;;
esac

echo ""
echo "=== Question 6 of 15 ==="
Q6=$(menu "Planning preference:" \
  "Auto-plan for 3+ file tasks (recommended)" \
  "Ask before planning" \
  "Minimal plans only" \
)
case "$Q6" in
  1) PLANNING_PREFERENCE="Always plan first when the task touches 3 or more files, changes a public API or database schema, involves auth/payments/user data, or has unclear scope. No plan needed for single-file edits, 1–2 line fixes, config tweaks, or doc updates." ;;
  2) PLANNING_PREFERENCE="Ask the user before creating a plan. Suggest planning when the task touches 3 or more files or has unclear scope." ;;
  3) PLANNING_PREFERENCE="Keep plans minimal. Only create a written plan when the user explicitly asks for one." ;;
  *) PLANNING_PREFERENCE="Always plan first when the task touches 3 or more files or has unclear scope." ;;
esac

echo ""
echo "=== Question 7 of 15 ==="
Q7=$(menu "Code style:" \
  "Simple / minimal — readable over fancy" \
  "Production-grade — patterns, error handling, tests" \
  "Strict / architectural — strict conventions, full type safety" \
)
case "$Q7" in
  1) CODE_STYLE="Keep code simple and readable. Avoid over-engineering. Favour explicitness over abstraction." ;;
  2) CODE_STYLE="Write production-grade code: proper error handling, consistent patterns, tests for new functionality. Functions under 50 lines. No nesting beyond 4 levels." ;;
  3) CODE_STYLE="Strict conventions: full type safety, architectural patterns, no shortcuts. All edge cases handled. Comprehensive tests." ;;
  *) CODE_STYLE="Write clean, readable code with proper error handling." ;;
esac

echo ""
echo "=== Question 8 of 15 ==="
Q8=$(menu "Testing preference:" \
  "Always add tests for new functionality" \
  "Tests for risky or complex changes only" \
  "Ask the user before writing tests" \
)
case "$Q8" in
  1) TESTING_PREFERENCE="Always write tests for new functionality. Use /tdd for test-first workflow. Do not mark a task done without tests." ;;
  2) TESTING_PREFERENCE="Write tests for risky, complex, or user-facing changes. Skip tests for trivial edits, config changes, and doc updates." ;;
  3) TESTING_PREFERENCE="Ask the user before writing tests. Do not add tests without being asked." ;;
  *) TESTING_PREFERENCE="Write tests for new functionality where appropriate." ;;
esac

echo ""
echo "=== Question 9 of 15 ==="
Q9=$(menu "Security level:" \
  "Standard — basic secret hygiene, no hardcoded credentials" \
  "Strict — run /security before any security-relevant commit" \
  "Very strict — auth, payment, and user data must use /security every time" \
)
case "$Q9" in
  1) SECURITY_LEVEL="Standard" ;;
  2) SECURITY_LEVEL="Strict" ;;
  3) SECURITY_LEVEL="Very Strict" ;;
  *) SECURITY_LEVEL="Standard" ;;
esac

echo ""
echo "=== Question 10 of 15 ==="
echo "Primary programming stacks (e.g. TypeScript, Python, Go — comma-separated, or press Enter to skip):"
printf "  Stacks: "
read -r PREFERRED_STACKS
if [ -z "$PREFERRED_STACKS" ]; then
  PREFERRED_STACKS="(not specified)"
fi

echo ""
echo "=== Question 11 of 15 ==="
Q11=$(menu "Frontend style (or 'none' if no frontend work):" \
  "Clean SaaS UI" \
  "Dashboard / admin" \
  "Marketing / landing pages" \
  "FiveM NUI" \
  "No frontend work" \
)
case "$Q11" in
  1) FRONTEND_STYLE="Clean SaaS UI" ;;
  2) FRONTEND_STYLE="Dashboard / admin" ;;
  3) FRONTEND_STYLE="Marketing / landing pages" ;;
  4) FRONTEND_STYLE="FiveM NUI" ;;
  5) FRONTEND_STYLE="none" ;;
  *) FRONTEND_STYLE="none" ;;
esac

echo ""
echo "=== Question 12 of 15 ==="
printf "Enable marketing / sales support? Adds writing guidance for copy and messaging. (y/n) [n]: "
read -r Q12
case "$Q12" in
  [yY]) MARKETING_SUPPORT_FLAG="yes" ;;
  *) MARKETING_SUPPORT_FLAG="no" ;;
esac

echo ""
echo "=== Question 13 of 15 ==="
printf "Enable FiveM-specific guidance? Adds Lua patterns, NUI rules, and framework notes. (y/n) [n]: "
read -r Q13
case "$Q13" in
  [yY]) FIVEM_SUPPORT_FLAG="yes" ;;
  *) FIVEM_SUPPORT_FLAG="no" ;;
esac

echo ""
echo "=== Question 14 of 15 ==="
Q14=$(menu "Memory / dream guidance:" \
  "Manual only — I will run /dream or /remember myself (recommended)" \
  "Remind me to run /dream after major sessions" \
  "Disabled — do not mention memory skills" \
)
case "$Q14" in
  1) MEMORY_MODE="manual" ;;
  2) MEMORY_MODE="remind" ;;
  3) MEMORY_MODE="disabled" ;;
  *) MEMORY_MODE="manual" ;;
esac

echo ""
echo "=== Question 15 of 15 ==="
Q15=$(menu "Agent orchestration level:" \
  "Minimal — solo work preferred, agents only when clearly needed" \
  "Balanced — agents for complex parallel tasks" \
  "Advanced — multi-agent workflows, orchestration patterns" \
)
case "$Q15" in
  1) AGENT_ORCHESTRATION="Minimal" ;;
  2) AGENT_ORCHESTRATION="Balanced" ;;
  3) AGENT_ORCHESTRATION="Advanced" ;;
  *) AGENT_ORCHESTRATION="Balanced" ;;
esac

echo ""
echo "Building your personalized CLAUDE.md..."
echo ""

# Build security rules section
case "$SECURITY_LEVEL" in
  "Standard")
    SECURITY_RULES="- Never hardcode API keys, passwords, or tokens. Use environment variables.
- Never commit .env files or credentials.
- Validate user input at system boundaries."
    SECURITY_GATE="- [ ] Security-sensitive changes reviewed with \`/security\`"
    ;;
  "Strict")
    SECURITY_RULES="- Never hardcode any secret. Use environment variables or a secrets manager.
- Never commit .env files or credentials.
- Run \`/security\` before any commit that touches auth, payments, user data, file system access, or external API calls.
- Validate all user input. Parameterize all SQL queries. Sanitize HTML output.
- Rate limit all user-facing endpoints."
    SECURITY_GATE="- [ ] Security-sensitive changes reviewed with \`/security\` before committing"
    ;;
  "Very Strict")
    SECURITY_RULES="- Never hardcode any secret under any circumstances.
- Run \`/security\` before every commit that touches auth, payments, user data, file system, or external APIs. This is not optional.
- Validate all input at every boundary. No exceptions.
- All SQL queries parameterized. All HTML output sanitized.
- Rate limit all endpoints. CSRF protection on all state-changing forms.
- Error messages must not leak sensitive data or stack traces to users."
    SECURITY_GATE="- [ ] /security skill run and all issues addressed before committing"
    ;;
  *) SECURITY_RULES="- Never hardcode secrets. Use env vars." ; SECURITY_GATE="" ;;
esac

# Build token rules section
case "$TOKEN_STRATEGY" in
  "Conservative")
    TOKEN_RULES="- Search before reading. Use grep or find to locate code before reading full files.
- Issue multiple independent reads in one message, not sequentially.
- Summarise command output — do not paste raw long output.
- Create a handoff and start a fresh session when the conversation grows large."
    ;;
  "Balanced")
    TOKEN_RULES="- Search before reading when the target is unclear.
- Batch independent operations in one message.
- Start a new session instead of resuming a very large one."
    ;;
  "Aggressive")
    TOKEN_RULES="- Always search before reading any file.
- Batch all independent operations in a single message.
- Hard limit on session length: use \`/create_handoff\` proactively before the session grows too large.
- Never paste raw command output. Always summarise.
- Do not load skills speculatively. One skill at a time, on demand only."
    ;;
  *) TOKEN_RULES="- Search before reading. Summarise instead of pasting. Handoff when sessions grow large." ;;
esac

# Build orchestration rules section
case "$AGENT_ORCHESTRATION" in
  "Minimal")
    ORCHESTRATION_RULES="Use agents only when the task is clearly too large or complex for a single session. Default to solo work. If you can finish in under 15 minutes, skip agents.

Available agents when needed: \`planner\`, \`code-reviewer\`, \`security-reviewer\`, \`debug-agent\`."
    ;;
  "Balanced")
    ORCHESTRATION_RULES="Use agents when work is genuinely parallel or needs specialisation. Do not spawn agents for single-file edits, quick questions, or config changes. Rule: if you can finish the task alone in under 15 minutes, skip agents.

Agents: \`planner\`, \`architect\`, \`code-reviewer\`, \`security-reviewer\`, \`tdd-guide\`, \`scout\`, \`oracle\`, \`spark\`, \`debug-agent\`, \`build-error-resolver\`."
    ;;
  "Advanced")
    ORCHESTRATION_RULES="Use multi-agent workflows when tasks are genuinely parallel or need specialised roles. Pattern: planner → implementers (parallel if independent) → reviewer → verifier.

Core agents: \`planner\`, \`architect\`, \`kraken\`, \`spark\`, \`code-reviewer\`, \`security-reviewer\`, \`tdd-guide\`, \`scout\`, \`oracle\`, \`debug-agent\`, \`sleuth\`, \`build-error-resolver\`.

See \`docs/RUFLO_ORCHESTRATION.md\` for the full orchestration guide."
    ;;
  *) ORCHESTRATION_RULES="Use agents when the task genuinely needs parallel work or specialised roles." ;;
esac

# Build selected skills list
SELECTED_SKILLS="- \`/debug\` — systematic bug investigation
- \`/tdd\` — test-first workflow
- \`/review\` — code quality review
- \`/security\` — security audit checklist
- \`/refactor\` — safe refactoring steps
- \`/plan-agent\` — structured planning before implementation
- \`/research\` — check what exists before writing new code
- \`/commit\` — commit message and pre-commit checklist
- \`/dead-code\` — find unused code before deleting
- \`/ast-grep-find\` — structural search across a codebase
- \`/create_handoff\` — save session context before ending"

if [ "$MAIN_WORK_TYPE" = "Web / frontend" ] || [ "$MAIN_WORK_TYPE" = "Full-stack" ]; then
  SELECTED_SKILLS="$SELECTED_SKILLS
- \`/frontend-patterns\` — React/component patterns
- \`/shadcn-ui\` — shadcn/ui component library
- \`/e2e-testing\` — end-to-end test patterns"
fi

if [ "$MAIN_WORK_TYPE" = "Backend / API" ] || [ "$MAIN_WORK_TYPE" = "Full-stack" ]; then
  SELECTED_SKILLS="$SELECTED_SKILLS
- \`/backend-patterns\` — server-side architecture patterns
- \`/api-design\` — REST API design decisions"
fi

if [ "$MAIN_WORK_TYPE" = "Data / AI / ML" ]; then
  SELECTED_SKILLS="$SELECTED_SKILLS
- \`/python-patterns\` — idiomatic Python patterns
- \`/python-testing\` — pytest patterns and fixtures"
fi

# Build memory section addition
case "$MEMORY_MODE" in
  "manual")
    MEMORY_NOTE=""
    ;;
  "remind")
    MEMORY_NOTE="

## Memory

After major sessions, consider running \`/dream\` to consolidate learnings. Use \`/remember\` to save specific decisions. Use \`/recall\` to retrieve past learnings before starting similar work.

Note: \`/dream\` does not automatically edit CLAUDE.md. It is a manual consolidation step you run deliberately."
    ;;
  "disabled")
    MEMORY_NOTE=""
    ;;
  *) MEMORY_NOTE="" ;;
esac

# Build marketing section (appended if enabled)
if [ "$MARKETING_SUPPORT_FLAG" = "yes" ]; then
  MARKETING_BLOCK="## Marketing and Sales Support

When writing sales, marketing, or customer-facing copy:
- Write in clear, direct language. No corporate filler or AI-sounding bullet lists.
- Prefer flowing prose for short messages. Use lists only for 4+ parallel items.
- If no brand voice is defined, ask before writing.
- Useful skills: \`/article-writing\`, \`/seo\`, \`/brandkit\`, \`/strategic-compact\`."
else
  MARKETING_BLOCK=""
fi

# Build FiveM section (appended if enabled)
if [ "$FIVEM_SUPPORT_FLAG" = "yes" ]; then
  FIVEM_BLOCK="## FiveM Development

When working on FiveM scripts:
- Never use \`Wait(0)\` in permanent loops. Use adaptive wait based on distance checks.
- Server is authoritative. Validate all client events on the server. Never trust client data.
- Use ox_lib target zones instead of distance check loops with every-frame threads.
- NUI backgrounds must be transparent: \`html, body { background: transparent !important; }\`
- Animate only compositor-friendly properties: \`transform\` and \`opacity\`.
- Use statebags for state sync. Avoid event spam.
- Useful skills: \`/fivem-nui-design\` for NUI work.
- Verify all natives at docs.fivem.net before using them. Never guess native names."
else
  FIVEM_BLOCK=""
fi

# Assemble the final CLAUDE.md by substituting template placeholders
# We use a series of sed commands. Each pass handles one placeholder.
# Using | as delimiter to avoid issues with / in paths.

TEMP_FILE="/tmp/claude_brain_setup_$$.md"

cp "$TEMPLATE_FILE" "$TEMP_FILE"

# Function to do safe sed replacement (handles multi-line values via temp approach)
replace_placeholder() {
  local placeholder="$1"
  local value="$2"
  local file="$3"
  # Write value to a temp file to safely handle newlines and special chars
  local value_file="/tmp/cb_val_$$.txt"
  printf '%s' "$value" > "$value_file"
  # Use python3 with env vars to avoid quoting issues with single quotes in values
  CB_FILE="$file" CB_PLACEHOLDER="$placeholder" CB_VALFILE="$value_file" \
  python3 -c "
import os
fpath = os.environ['CB_FILE']
placeholder = os.environ['CB_PLACEHOLDER']
vpath = os.environ['CB_VALFILE']
with open(fpath, 'r') as f:
    content = f.read()
with open(vpath, 'r') as f:
    replacement = f.read()
content = content.replace(placeholder, replacement)
with open(fpath, 'w') as f:
    f.write(content)
"
  rm -f "$value_file"
}

replace_placeholder "{{USER_NAME}}" "$USER_NAME" "$TEMP_FILE"
replace_placeholder "{{PRIMARY_LANGUAGE}}" "$PRIMARY_LANGUAGE" "$TEMP_FILE"
replace_placeholder "{{DEFAULT_MODEL}}" "$DEFAULT_MODEL" "$TEMP_FILE"
replace_placeholder "{{MAIN_WORK_TYPE}}" "$MAIN_WORK_TYPE" "$TEMP_FILE"
replace_placeholder "{{PREFERRED_STACKS}}" "$PREFERRED_STACKS" "$TEMP_FILE"
replace_placeholder "{{CODE_STYLE}}" "$CODE_STYLE" "$TEMP_FILE"
replace_placeholder "{{TESTING_PREFERENCE}}" "$TESTING_PREFERENCE" "$TEMP_FILE"
replace_placeholder "{{SECURITY_LEVEL}}" "$SECURITY_LEVEL" "$TEMP_FILE"
replace_placeholder "{{SECURITY_RULES}}" "$SECURITY_RULES" "$TEMP_FILE"
replace_placeholder "{{SECURITY_GATE}}" "$SECURITY_GATE" "$TEMP_FILE"
replace_placeholder "{{TOKEN_STRATEGY}}" "$TOKEN_STRATEGY" "$TEMP_FILE"
replace_placeholder "{{TOKEN_RULES}}" "$TOKEN_RULES" "$TEMP_FILE"
replace_placeholder "{{SELECTED_SKILLS}}" "$SELECTED_SKILLS" "$TEMP_FILE"
replace_placeholder "{{AGENT_ORCHESTRATION}}" "$AGENT_ORCHESTRATION" "$TEMP_FILE"
replace_placeholder "{{ORCHESTRATION_RULES}}" "$ORCHESTRATION_RULES" "$TEMP_FILE"
replace_placeholder "{{PLANNING_PREFERENCE}}" "$PLANNING_PREFERENCE" "$TEMP_FILE"
replace_placeholder "{{MARKETING_SUPPORT}}" "$MARKETING_BLOCK" "$TEMP_FILE"
replace_placeholder "{{FIVEM_SUPPORT}}" "$FIVEM_BLOCK" "$TEMP_FILE"

# Append memory note if enabled
if [ -n "$MEMORY_NOTE" ]; then
  printf '%s\n' "$MEMORY_NOTE" >> "$TEMP_FILE"
fi

# Show preview
echo "=== Preview of generated CLAUDE.md ==="
echo ""
cat "$TEMP_FILE"
echo ""
echo "======================================="
echo ""

if [ $DRY_RUN -eq 1 ]; then
  echo "[DRY RUN] Preview complete. No files were written."
  rm -f "$TEMP_FILE"
  exit 0
fi

# Backup existing CLAUDE.md if present
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
if [ -f "$OUTPUT_FILE" ]; then
  BACKUP_FILE="${OUTPUT_FILE}.backup_${TIMESTAMP}"
  cp "$OUTPUT_FILE" "$BACKUP_FILE"
  echo "Backed up existing CLAUDE.md to: $BACKUP_FILE"
fi

# Write new file
cp "$TEMP_FILE" "$OUTPUT_FILE"
rm -f "$TEMP_FILE"

echo ""
echo "Done! CLAUDE.md written to: $OUTPUT_FILE"
echo ""
echo "Next steps:"
echo "  1. Launch Claude Code with your preferred model:"
echo "     claude --model claude-sonnet-4-6"
echo ""
echo "  2. Verify Claude loaded your configuration:"
echo "     Ask: \"What instructions are you following from CLAUDE.md?\""
echo ""
echo "  3. Optional: copy docs for local reference:"
echo "     cp -r $PROJECT_ROOT/docs ~/claude-brain-docs"
echo ""
echo "  4. Add shell aliases for convenience (optional):"
echo "     echo \"alias cc='claude --model claude-sonnet-4-6'\" >> ~/.bashrc"
echo "     echo \"alias cch='claude --model claude-haiku-4-5-20251001'\" >> ~/.bashrc"
echo "     echo \"alias cco='claude --model claude-opus-4-7'\" >> ~/.bashrc"
echo ""
