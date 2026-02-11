# Production-readiness test for chrome-devtools-mcp + overtime-ag-plugin
# Run from repo root: .\scripts\test-production-readiness.ps1
# Use -SkipE2E to skip headed browser / live-site tests

param(
    [switch]$SkipE2E = $false
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot

function Write-Step { param($n, $msg) Write-Host "`n=== [$n] $msg ===" -ForegroundColor Cyan }
function Write-Pass { param($msg) Write-Host "PASS: $msg" -ForegroundColor Green }
function Write-Fail { param($msg) Write-Host "FAIL: $msg" -ForegroundColor Red; exit 1 }
function Write-Skip { param($msg) Write-Host "SKIP: $msg" -ForegroundColor Yellow }

Push-Location $RepoRoot

# --- 1. Chrome DevTools MCP ---
Write-Step 1 "Chrome DevTools MCP: build + lint + tests"
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Fail "Node.js not found. Install Node 20+ and ensure it's in PATH."
}
if (-not (Test-Path "package.json")) {
    Write-Fail "Not in chrome-devtools-mcp repo root. Expected package.json."
}
if (-not (Test-Path "node_modules")) { npm install } else { npm ci 2>$null; if ($LASTEXITCODE -ne 0) { npm install } }
npm run bundle 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Chrome DevTools MCP bundle failed"
}
$env:CHROME_DEVTOOLS_MCP_NO_USAGE_STATISTICS = "true"
npm run test:no-build 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Chrome DevTools MCP tests failed"
}
Write-Pass "Chrome DevTools MCP tests passed"

# --- 2. Overtime-ag-plugin: unit tests ---
Write-Step 2 "Overtime-ag-plugin: pytest"
$PluginProject = Join-Path $RepoRoot ".claude\plugins\overtime-ag-plugin\project"
if (-not (Test-Path (Join-Path $PluginProject "pyproject.toml"))) {
    Write-Fail "Overtime-ag-plugin project not found at $PluginProject"
}
Push-Location $PluginProject
uv sync --extra dev 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Fail "uv sync failed" }
uv run pytest tests/ -v 2>&1
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Fail "Overtime-ag-plugin pytest failed"
}
Write-Pass "Overtime-ag-plugin pytest passed"
Pop-Location

# --- 3. Overtime-ag-plugin: replay smoke (from existing recording) ---
Write-Step 3 "Overtime-ag-plugin: replay-only smoke"
$RecordingPath = Join-Path $PluginProject "data\cbb_recording.json"
if (Test-Path $RecordingPath) {
    Push-Location $PluginProject
    uv run overtime-ag-scrape --advanced-mode --replay-only --recording data/cbb_recording.json --out data/cbb_test.json --log-level INFO 2>&1
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        Write-Fail "Overtime-ag replay-only smoke failed"
    }
    $OutPath = Join-Path $PluginProject "data\cbb_test.json"
    if (Test-Path $OutPath) {
        $size = (Get-Item $OutPath).Length
        Write-Pass "Replay produced data/cbb_test.json ($size bytes)"
    } else {
        Pop-Location
        Write-Fail "Replay did not create data/cbb_test.json"
    }
    Pop-Location
} else {
    Write-Skip "data/cbb_recording.json not found. Run record-cbb skill first."
}

# --- 4. E2E: headed record (optional, requires browser) ---
if (-not $SkipE2E) {
    Write-Step 4 "E2E: Full record+replay (headed) - manual verification"
    Write-Skip "E2E requires headed browser and live site. Run manually:"
    Write-Host "  cd .claude\plugins\overtime-ag-plugin\project"
    Write-Host "  uv run overtime-ag-scrape --advanced-mode --no-headless --log-level DEBUG --recording data/cbb_recording.json --out data/cbb.json"
    Write-Host "  # Then verify data/cbb.json and data/cbb_recording.json contain Offering.asmx calls"
} else {
    Write-Step 4 "E2E: skipped (use without -SkipE2E to see manual instructions)"
}

# --- Summary ---
Write-Host "`n=== Production-readiness checks complete ===" -ForegroundColor Green
Pop-Location
