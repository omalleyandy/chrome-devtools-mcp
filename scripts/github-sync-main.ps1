# GitHub: check state and sync main with origin
# Run from repo root: .\scripts\github-sync-main.ps1
# Optional: .\scripts\github-sync-main.ps1 -Sync  to also pull and push main

param(
    [switch]$Sync  # If set, run git pull and push on main
)

$ErrorActionPreference = "Stop"
$repoRoot = (Get-Item $PSScriptRoot).Parent.FullName
Set-Location $repoRoot

$logPath = Join-Path $repoRoot "github-sync-report.txt"
$out = @()
$out += "Repo: $repoRoot"
$out += ""
$out += "=== Branch ==="
$out += (git branch --show-current 2>&1)
$out += ""
$out += "=== Status ==="
$out += (git status --short 2>&1)
$out += ""
$out += "=== Remote branches ==="
$out += (git branch -a 2>&1)
$out += ""
$out += "=== Open PRs (origin main) ==="
$out += (gh pr list --repo omalleyandy/chrome-devtools-mcp --state open --base main 2>&1)
$out += ""

if ($Sync) {
    $out += "=== Syncing main ==="
    git switch main 2>&1 | ForEach-Object { $out += $_ }
    git pull origin main --rebase 2>&1 | ForEach-Object { $out += $_ }
    git push origin main 2>&1 | ForEach-Object { $out += $_ }
    $out += "Done."
} else {
    $out += "To sync main (pull + push), run: .\scripts\github-sync-main.ps1 -Sync"
}

$text = $out -join "`r`n"
$text | Out-File -FilePath $logPath -Encoding utf8
Write-Host $text
