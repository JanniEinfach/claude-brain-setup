# Claude Brain Setup — Interactive personalized CLAUDE.md generator (Windows PowerShell)
# Usage:
#   .\scripts\setup.ps1
#   .\scripts\setup.ps1 -DryRun
#   .\scripts\setup.ps1 -Target "C:\Users\You\mydir"
#
# No admin rights required.

[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$Target = $env:USERPROFILE
)

$ErrorActionPreference = 'Stop'

$ScriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot  = Split-Path -Parent $ScriptDir
$TemplateFile = Join-Path $ProjectRoot 'templates\CLAUDE.template.md'
$OutputFile   = Join-Path $Target 'CLAUDE.md'

Write-Host ""
Write-Host "Claude Brain Setup — Interactive Configuration (Windows)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "[DRY RUN] No files will be written." -ForegroundColor Yellow
}
Write-Host "This will generate a personalized CLAUDE.md at: $OutputFile"
Write-Host "Existing CLAUDE.md will be backed up before overwriting."
Write-Host ""

# Verify template exists
if (-not (Test-Path $TemplateFile)) {
    Write-Error "Template not found at: $TemplateFile`nRun this script from the claude-brain-setup directory."
    exit 1
}

# Helper: prompt with default
function Ask-Question {
    param(
        [string]$Prompt,
        [string]$Default = ''
    )
    if ($Default) {
        $display = "$Prompt [$Default]"
    } else {
        $display = $Prompt
    }
    $response = Read-Host $display
    if ([string]::IsNullOrWhiteSpace($response) -and $Default) {
        return $Default
    }
    return $response.Trim()
}

# Helper: numbered menu — returns 1-based choice index
function Show-Menu {
    param(
        [string]$Title,
        [string[]]$Options
    )
    Write-Host ""
    Write-Host $Title
    for ($i = 0; $i -lt $Options.Length; $i++) {
        Write-Host ("  {0}) {1}" -f ($i + 1), $Options[$i])
    }
    $raw = Read-Host "  Choice [1]"
    if ([string]::IsNullOrWhiteSpace($raw)) { return 1 }
    $n = 0
    if (-not [int]::TryParse($raw, [ref]$n)) { return 1 }
    if ($n -lt 1 -or $n -gt $Options.Length) { return 1 }
    return $n
}

# ── Question 1 ──────────────────────────────────────────────────────────────
Write-Host "=== Question 1 of 15 ==="
$UserName = Ask-Question "What should Claude call you?" "User"

# ── Question 2 ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Question 2 of 15 ==="
$q2 = Show-Menu "Preferred response language:" @(
    "English",
    "German",
    "French",
    "Spanish",
    "Other (you can specify)"
)
switch ($q2) {
    1 { $PrimaryLanguage = "English" }
    2 { $PrimaryLanguage = "German" }
    3 { $PrimaryLanguage = "French" }
    4 { $PrimaryLanguage = "Spanish" }
    5 { $PrimaryLanguage = Ask-Question "Which language?" "English" }
    default { $PrimaryLanguage = "English" }
}

# ── Question 3 ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Question 3 of 15 ==="
$q3 = Show-Menu "Main work type:" @(
    "General software development",
    "Web / frontend",
    "Backend / API",
    "Full-stack",
    "FiveM / game scripts",
    "DevOps / infrastructure",
    "Data / AI / ML",
    "Marketing / sales"
)
switch ($q3) {
    1 { $MainWorkType = "General software development" }
    2 { $MainWorkType = "Web / frontend" }
    3 { $MainWorkType = "Backend / API" }
    4 { $MainWorkType = "Full-stack" }
    5 { $MainWorkType = "FiveM / game scripts" }
    6 { $MainWorkType = "DevOps / infrastructure" }
    7 { $MainWorkType = "Data / AI / ML" }
    8 { $MainWorkType = "Marketing / sales" }
    default { $MainWorkType = "General software development" }
}

# ── Question 4 ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Question 4 of 15 ==="
$q4 = Show-Menu "Default model strategy:" @(
    "Sonnet (good default for most work)",
    "Start with Haiku for cheap tasks",
    "Opus when I need depth"
)
switch ($q4) {
    1 {
        $DefaultModel = "Recommended:`n" +
            "- ``claude --model claude-haiku-4-5-20251001`` — formatting, renaming, simple edits`n" +
            "- ``claude --model claude-sonnet-4-6`` — standard development work (default)`n" +
            "- ``claude --model claude-opus-4-7`` — architecture, security, complex multi-file work"
    }
    2 {
        $DefaultModel = "Recommended:`n" +
            "- ``claude --model claude-haiku-4-5-20251001`` — start here for most tasks (default)`n" +
            "- ``claude --model claude-sonnet-4-6`` — when Haiku is not enough`n" +
            "- ``claude --model claude-opus-4-7`` — architecture, security only"
    }
    3 {
        $DefaultModel = "Recommended:`n" +
            "- ``claude --model claude-sonnet-4-6`` — standard work and quick tasks`n" +
            "- ``claude --model claude-opus-4-7`` — default for complex reasoning (default)`n" +
            "- ``claude --model claude-haiku-4-5-20251001`` — formatting, renaming only"
    }
    default { $DefaultModel = "Use ``claude --model claude-sonnet-4-6`` as default. See docs/MODEL_ROUTING.md." }
}

# ── Question 5 ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Question 5 of 15 ==="
$q5 = Show-Menu "Token-saving strictness:" @(
    "Conservative — search before reading, handoff when needed",
    "Balanced",
    "Aggressive — strict handoffs, short focused sessions"
)
switch ($q5) {
    1 { $TokenStrategy = "Conservative" }
    2 { $TokenStrategy = "Balanced" }
    3 { $TokenStrategy = "Aggressive" }
    default { $TokenStrategy = "Balanced" }
}

# ── Question 6 ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Question 6 of 15 ==="
$q6 = Show-Menu "Planning preference:" @(
    "Auto-plan for 3+ file tasks (recommended)",
    "Ask before planning",
    "Minimal plans only"
)
switch ($q6) {
    1 { $PlanStyle = "Always plan first when the task touches 3 or more files, changes a public API or database schema, involves auth/payments/user data, or has unclear scope. No plan needed for single-file edits, 1-2 line fixes, config tweaks, or doc updates." }
    2 { $PlanStyle = "Ask the user before creating a plan. Suggest planning when the task touches 3 or more files or has unclear scope." }
    3 { $PlanStyle = "Keep plans minimal. Only create a written plan when the user explicitly asks for one." }
    default { $PlanStyle = "Always plan first when the task touches 3 or more files or has unclear scope." }
}

# ── Question 7 ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Question 7 of 15 ==="
$q7 = Show-Menu "Code style:" @(
    "Simple / minimal — readable over fancy",
    "Production-grade — patterns, error handling, tests",
    "Strict / architectural — strict conventions, full type safety"
)
switch ($q7) {
    1 { $CodeStyle = "Keep code simple and readable. Avoid over-engineering. Favour explicitness over abstraction." }
    2 { $CodeStyle = "Write production-grade code: proper error handling, consistent patterns, tests for new functionality. Functions under 50 lines. No nesting beyond 4 levels." }
    3 { $CodeStyle = "Strict conventions: full type safety, architectural patterns, no shortcuts. All edge cases handled. Comprehensive tests." }
    default { $CodeStyle = "Write clean, readable code with proper error handling." }
}

# ── Question 8 ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Question 8 of 15 ==="
$q8 = Show-Menu "Testing preference:" @(
    "Always add tests for new functionality",
    "Tests for risky or complex changes only",
    "Ask the user before writing tests"
)
switch ($q8) {
    1 { $TestPreference = "Always write tests for new functionality. Use /tdd for test-first workflow. Do not mark a task done without tests." }
    2 { $TestPreference = "Write tests for risky, complex, or user-facing changes. Skip tests for trivial edits, config changes, and doc updates." }
    3 { $TestPreference = "Ask the user before writing tests. Do not add tests without being asked." }
    default { $TestPreference = "Write tests for new functionality where appropriate." }
}

# ── Question 9 ──────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Question 9 of 15 ==="
$q9 = Show-Menu "Security level:" @(
    "Standard — basic secret hygiene, no hardcoded credentials",
    "Strict — run /security before any security-relevant commit",
    "Very strict — auth, payment, and user data must use /security every time"
)
switch ($q9) {
    1 { $SecurityLevel = "Standard" }
    2 { $SecurityLevel = "Strict" }
    3 { $SecurityLevel = "Very Strict" }
    default { $SecurityLevel = "Standard" }
}

# ── Question 10 ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Question 10 of 15 ==="
$rawStacks = Read-Host "Primary programming stacks (e.g. TypeScript, Python, Go — comma-separated, or press Enter to skip)"
if ([string]::IsNullOrWhiteSpace($rawStacks)) {
    $PreferredStacks = "(not specified)"
} else {
    $PreferredStacks = $rawStacks.Trim()
}

# ── Question 11 ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Question 11 of 15 ==="
$q11 = Show-Menu "Frontend style (or 'none' if no frontend work):" @(
    "Clean SaaS UI",
    "Dashboard / admin",
    "Marketing / landing pages",
    "FiveM NUI",
    "No frontend work"
)
switch ($q11) {
    1 { $FrontendStyle = "Clean SaaS UI" }
    2 { $FrontendStyle = "Dashboard / admin" }
    3 { $FrontendStyle = "Marketing / landing pages" }
    4 { $FrontendStyle = "FiveM NUI" }
    5 { $FrontendStyle = "none" }
    default { $FrontendStyle = "none" }
}

# ── Question 12 ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Question 12 of 15 ==="
$q12 = Read-Host "Enable marketing / sales support? Adds writing guidance for copy and messaging. (y/n) [n]"
if ($q12 -match '^[yY]') {
    $MarketingSupport = "yes"
} else {
    $MarketingSupport = "no"
}

# ── Question 13 ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Question 13 of 15 ==="
$q13 = Read-Host "Enable FiveM-specific guidance? Adds Lua patterns, NUI rules, and framework notes. (y/n) [n]"
if ($q13 -match '^[yY]') {
    $FivemSupport = "yes"
} else {
    $FivemSupport = "no"
}

# ── Question 14 ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Question 14 of 15 ==="
$q14 = Show-Menu "Memory / dream guidance:" @(
    "Manual only — I will run /dream or /remember myself (recommended)",
    "Remind me to run /dream after major sessions",
    "Disabled — do not mention memory skills"
)
switch ($q14) {
    1 { $MemoryGuidance = "manual" }
    2 { $MemoryGuidance = "remind" }
    3 { $MemoryGuidance = "disabled" }
    default { $MemoryGuidance = "manual" }
}

# ── Question 15 ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== Question 15 of 15 ==="
$q15 = Show-Menu "Agent orchestration level:" @(
    "Minimal — solo work preferred, agents only when clearly needed",
    "Balanced — agents for complex parallel tasks",
    "Advanced — multi-agent workflows, orchestration patterns"
)
switch ($q15) {
    1 { $OrchestrationLevel = "Minimal" }
    2 { $OrchestrationLevel = "Balanced" }
    3 { $OrchestrationLevel = "Advanced" }
    default { $OrchestrationLevel = "Balanced" }
}

Write-Host ""
Write-Host "Building your personalized CLAUDE.md..." -ForegroundColor Cyan
Write-Host ""

# ── Build derived content ────────────────────────────────────────────────────

$SecurityRules = switch ($SecurityLevel) {
    "Standard" {
        "- Never hardcode API keys, passwords, or tokens. Use environment variables.`n" +
        "- Never commit .env files or credentials.`n" +
        "- Validate user input at system boundaries."
    }
    "Strict" {
        "- Never hardcode any secret. Use environment variables or a secrets manager.`n" +
        "- Never commit .env files or credentials.`n" +
        "- Run ``/security`` before any commit that touches auth, payments, user data, file system access, or external API calls.`n" +
        "- Validate all user input. Parameterize all SQL queries. Sanitize HTML output.`n" +
        "- Rate limit all user-facing endpoints."
    }
    "Very Strict" {
        "- Never hardcode any secret under any circumstances.`n" +
        "- Run ``/security`` before every commit that touches auth, payments, user data, file system, or external APIs. This is not optional.`n" +
        "- Validate all input at every boundary. No exceptions.`n" +
        "- All SQL queries parameterized. All HTML output sanitized.`n" +
        "- Rate limit all endpoints. CSRF protection on all state-changing forms.`n" +
        "- Error messages must not leak sensitive data or stack traces to users."
    }
    default { "- Never hardcode secrets. Use env vars." }
}

$SecurityGate = switch ($SecurityLevel) {
    "Standard"    { "- [ ] Security-sensitive changes reviewed with ``/security``" }
    "Strict"      { "- [ ] Security-sensitive changes reviewed with ``/security`` before committing" }
    "Very Strict" { "- [ ] /security skill run and all issues addressed before committing" }
    default       { "" }
}

$TokenRules = switch ($TokenStrategy) {
    "Conservative" {
        "- Search before reading. Use grep or find to locate code before reading full files.`n" +
        "- Issue multiple independent reads in one message, not sequentially.`n" +
        "- Summarise command output — do not paste raw long output.`n" +
        "- Create a handoff and start a fresh session when the conversation grows large."
    }
    "Balanced" {
        "- Search before reading when the target is unclear.`n" +
        "- Batch independent operations in one message.`n" +
        "- Start a new session instead of resuming a very large one."
    }
    "Aggressive" {
        "- Always search before reading any file.`n" +
        "- Batch all independent operations in a single message.`n" +
        "- Hard limit on session length: use ``/create_handoff`` proactively before the session grows too large.`n" +
        "- Never paste raw command output. Always summarise.`n" +
        "- Do not load skills speculatively. One skill at a time, on demand only."
    }
    default { "- Search before reading. Summarise instead of pasting. Handoff when sessions grow large." }
}

$OrchestrationRules = switch ($OrchestrationLevel) {
    "Minimal" {
        "Use agents only when the task is clearly too large or complex for a single session. Default to solo work. If you can finish in under 15 minutes, skip agents.`n`n" +
        "Available agents when needed: ``planner``, ``code-reviewer``, ``security-reviewer``, ``debug-agent``."
    }
    "Balanced" {
        "Use agents when work is genuinely parallel or needs specialisation. Do not spawn agents for single-file edits, quick questions, or config changes. Rule: if you can finish the task alone in under 15 minutes, skip agents.`n`n" +
        "Agents: ``planner``, ``architect``, ``code-reviewer``, ``security-reviewer``, ``tdd-guide``, ``scout``, ``oracle``, ``spark``, ``debug-agent``, ``build-error-resolver``."
    }
    "Advanced" {
        "Use multi-agent workflows when tasks are genuinely parallel or need specialised roles. Pattern: planner -> implementers (parallel if independent) -> reviewer -> verifier.`n`n" +
        "Core agents: ``planner``, ``architect``, ``kraken``, ``spark``, ``code-reviewer``, ``security-reviewer``, ``tdd-guide``, ``scout``, ``oracle``, ``debug-agent``, ``sleuth``, ``build-error-resolver``.`n`n" +
        "See ``docs/RUFLO_ORCHESTRATION.md`` for the full orchestration guide."
    }
    default { "Use agents when the task genuinely needs parallel work or specialised roles." }
}

$SelectedSkills = "- ``/debug`` — systematic bug investigation`n" +
    "- ``/tdd`` — test-first workflow`n" +
    "- ``/review`` — code quality review`n" +
    "- ``/security`` — security audit checklist`n" +
    "- ``/refactor`` — safe refactoring steps`n" +
    "- ``/plan-agent`` — structured planning before implementation`n" +
    "- ``/research`` — check what exists before writing new code`n" +
    "- ``/commit`` — commit message and pre-commit checklist`n" +
    "- ``/dead-code`` — find unused code before deleting`n" +
    "- ``/ast-grep-find`` — structural search across a codebase`n" +
    "- ``/create_handoff`` — save session context before ending"

if ($MainWorkType -in @("Web / frontend", "Full-stack")) {
    $SelectedSkills += "`n- ``/frontend-patterns`` — React/component patterns`n" +
        "- ``/shadcn-ui`` — shadcn/ui component library`n" +
        "- ``/e2e-testing`` — end-to-end test patterns"
}
if ($MainWorkType -in @("Backend / API", "Full-stack")) {
    $SelectedSkills += "`n- ``/backend-patterns`` — server-side architecture patterns`n" +
        "- ``/api-design`` — REST API design decisions"
}
if ($MainWorkType -eq "Data / AI / ML") {
    $SelectedSkills += "`n- ``/python-patterns`` — idiomatic Python patterns`n" +
        "- ``/python-testing`` — pytest patterns and fixtures"
}

$MemoryNote = ""
if ($MemoryGuidance -eq "remind") {
    $MemoryNote = "`n`n## Memory`n`n" +
        "After major sessions, consider running ``/dream`` to consolidate learnings. Use ``/remember`` to save specific decisions. Use ``/recall`` to retrieve past learnings before starting similar work.`n`n" +
        "Note: ``/dream`` does not automatically edit CLAUDE.md. It is a manual consolidation step you run deliberately."
}

$MarketingBlock = ""
if ($MarketingSupport -eq "yes") {
    $MarketingBlock = "## Marketing and Sales Support`n`n" +
        "When writing sales, marketing, or customer-facing copy:`n" +
        "- Write in clear, direct language. No corporate filler or AI-sounding bullet lists.`n" +
        "- Prefer flowing prose for short messages. Use lists only for 4+ parallel items.`n" +
        "- If no brand voice is defined, ask before writing.`n" +
        "- Useful skills: ``/article-writing``, ``/seo``, ``/brandkit``, ``/strategic-compact``."
}

$FivemBlock = ""
if ($FivemSupport -eq "yes") {
    $FivemBlock = "## FiveM Development`n`n" +
        "When working on FiveM scripts:`n" +
        "- Never use ``Wait(0)`` in permanent loops. Use adaptive wait based on distance checks.`n" +
        "- Server is authoritative. Validate all client events on the server. Never trust client data.`n" +
        "- Use ox_lib target zones instead of distance check loops with every-frame threads.`n" +
        "- NUI backgrounds must be transparent: ``html, body { background: transparent !important; }``" +
        "`n- Animate only compositor-friendly properties: ``transform`` and ``opacity``.`n" +
        "- Use statebags for state sync. Avoid event spam.`n" +
        "- Useful skills: ``/fivem-nui-design`` for NUI work.`n" +
        "- Verify all natives at docs.fivem.net before using them. Never guess native names."
}

# ── Load and substitute template ─────────────────────────────────────────────
$content = Get-Content $TemplateFile -Raw

$replacements = @{
    '{{USER_NAME}}'           = $UserName
    '{{PRIMARY_LANGUAGE}}'    = $PrimaryLanguage
    '{{DEFAULT_MODEL}}'       = $DefaultModel
    '{{MAIN_WORK_TYPE}}'      = $MainWorkType
    '{{PREFERRED_STACKS}}'    = $PreferredStacks
    '{{CODE_STYLE}}'          = $CodeStyle
    '{{TESTING_PREFERENCE}}'  = $TestPreference
    '{{SECURITY_LEVEL}}'      = $SecurityLevel
    '{{SECURITY_RULES}}'      = $SecurityRules
    '{{SECURITY_GATE}}'       = $SecurityGate
    '{{TOKEN_STRATEGY}}'      = $TokenStrategy
    '{{TOKEN_RULES}}'         = $TokenRules
    '{{SELECTED_SKILLS}}'     = $SelectedSkills
    '{{AGENT_ORCHESTRATION}}' = $OrchestrationLevel
    '{{ORCHESTRATION_RULES}}' = $OrchestrationRules
    '{{PLANNING_PREFERENCE}}' = $PlanStyle
    '{{MARKETING_SUPPORT}}'   = $MarketingBlock
    '{{FIVEM_SUPPORT}}'       = $FivemBlock
}

foreach ($key in $replacements.Keys) {
    $content = $content.Replace($key, $replacements[$key])
}

if ($MemoryNote) {
    $content = $content.TrimEnd() + $MemoryNote + "`n"
}

# ── Preview ──────────────────────────────────────────────────────────────────
Write-Host "=== Preview of generated CLAUDE.md ===" -ForegroundColor Cyan
Write-Host ""
Write-Host $content
Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "[DRY RUN] Preview complete. No files were written." -ForegroundColor Yellow
    exit 0
}

# ── Backup existing CLAUDE.md ─────────────────────────────────────────────────
if (Test-Path $OutputFile) {
    $Timestamp  = Get-Date -Format 'yyyyMMdd_HHmmss'
    $BackupFile = "$OutputFile.backup_$Timestamp"
    Copy-Item $OutputFile $BackupFile
    Write-Host "Backed up existing CLAUDE.md to: $BackupFile"
}

# ── Ensure target directory exists ───────────────────────────────────────────
if (-not (Test-Path $Target)) {
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
}

# ── Write output ─────────────────────────────────────────────────────────────
$content | Set-Content $OutputFile -Encoding UTF8

Write-Host ""
Write-Host "Done! CLAUDE.md written to: $OutputFile" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Launch Claude Code with your preferred model:"
Write-Host "     claude --model claude-sonnet-4-6"
Write-Host ""
Write-Host "  2. Verify Claude loaded your configuration:"
Write-Host "     Ask: `"What instructions are you following from CLAUDE.md?`""
Write-Host ""
Write-Host "  3. Optional: copy docs for local reference:"
Write-Host "     Copy-Item -Recurse docs $env:USERPROFILE\claude-brain-docs"
Write-Host ""
