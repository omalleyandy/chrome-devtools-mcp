# GitHub: Merge to Main and Sync

Use this checklist so **main** is up to date and everything is synced with GitHub.

## 1. Check current state

From the repo root (`chrome-devtools-mcp`):

```powershell
# Auth (one-time or if needed)
gh auth status

# Current branch and status
git branch -a
git status

# Open PRs targeting main (your fork)
gh pr list --repo omalleyandy/chrome-devtools-mcp --state open --base main
```

- If you have **uncommitted changes**: commit or stash first.
- If you have **open PRs** you want to merge: use the steps in **Merge open PRs** below.

## 2. Sync main with remote

Get latest from **origin** (your fork) and keep local main in sync:

```powershell
git switch main
git pull origin main
git push origin main
```

If you also track **upstream** (ChromeDevTools/chrome-devtools-mcp) and want to bring in their latest:

```powershell
git fetch upstream
git switch main
git merge upstream/main
# Resolve conflicts if any, then:
git push origin main
```

## 3. Merge open PRs into main

For each PR you want to land:

```powershell
# 1. Clean main
git switch main
git pull origin main

# 2. Merge the PR (from GitHub; replace 123 with PR number)
gh pr merge 123 --squash
# Or: gh pr merge 123 --rebase   (to keep linear history)

# 3. Pull the updated main locally
git pull origin main
```

Or merge via a temporary integration branch (see [PR Landing Mode](https://cli.github.com/manual/) in the GitHub skill):

```powershell
git switch main
git pull origin main
git switch -c integrate-pr-123
gh pr checkout 123
git switch integrate-pr-123
git merge --squash <pr-branch-name>
# ... fix/changelog, then:
git switch main
git merge integrate-pr-123
git push origin main
git branch -d integrate-pr-123
```

## 4. Final sync check

```powershell
git switch main
git pull origin main
git status
git log -1 --oneline
```

- `git status` should be clean (or only show intended changes).
- Your latest commit should match what you see on GitHub for `main`.

## Quick one-liner (main only, no PR merge)

If you only want to **update local main from origin** and **push any local main commits**:

```powershell
git switch main && git pull origin main --rebase && git push origin main
```

## Remotes (this repo)

- **origin**: `git@github.com:omalleyandy/chrome-devtools-mcp.git` (your fork)
- **upstream**: `https://github.com/ChromeDevTools/chrome-devtools-mcp.git` (upstream)

All merge/sync steps above use **origin**; add **upstream** only when you want to pull from ChromeDevTools.
