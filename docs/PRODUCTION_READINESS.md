# Production Readiness Checklist

This document tracks production-worthiness of the **chrome-devtools-mcp** server and **overtime-ag-plugin** skills for deployment.

## Chrome DevTools MCP

| Check                  | Status | Notes                                                            |
| ---------------------- | ------ | ---------------------------------------------------------------- |
| Unit/integration tests | [OK]   | `npm run test` - full suite in `tests/`                          |
| CI (GitHub Actions)    | [OK]   | `run-tests.yml` - ubuntu, windows, macos x node 20-24            |
| Build/bundle           | [OK]   | `npm run bundle` produces distributable                          |
| TypeScript strict      | [OK]   | `tsc --noEmit`                                                   |
| Lint/format            | [OK]   | ESLint + Prettier via `check-format`                             |
| Documentation          | [OK]   | `docs/`, `tool-reference.md`, skill in `skills/chrome-devtools/` |
| Release pipeline       | [OK]   | release-please, publish-to-npm-on-tag                            |

**Pre-deploy**: Run `npm run test` and `npm run bundle` from repo root.

---

## Overtime-ag-plugin

| Check              | Status      | Notes                                                                    |
| ------------------ | ----------- | ------------------------------------------------------------------------ |
| Unit tests (116)   | [OK]        | `uv run pytest tests/` - 13 test files covering all modules + edge cases |
| Replay smoke       | [OK]        | `run_tests.ps1` - replay-only from `data/cbb_recording.json`             |
| E2E (record)       | [!!] Manual | Requires headed browser + live site; run setup/record-cbb skill          |
| CI                 | [OK]        | `overtime-ag-tests.yml` on push/PR to plugin paths                       |
| Playwright install | [OK]        | `uv run playwright install chromium`                                     |
| .env setup         | [OK]        | Copy `.env.example` to `.env` for OT\_\* vars                            |

**Pre-deploy**: Run `.\run_tests.ps1` from `project/` or `.\scripts\test-production-readiness.ps1` from repo root.

---

## Skills Coverage

| Skill               | Purpose                                    | Tested By                    |
| ------------------- | ------------------------------------------ | ---------------------------- |
| **chrome-devtools** | MCP reference for browser automation       | Chrome DevTools MCP suite    |
| **setup**           | Init uv + Playwright, verify advanced-mode | `run_tests.ps1` step 3       |
| **record-cbb**      | Record CBB network calls                   | E2E manual                   |
| **scrape-cbb**      | Replay and export to JSON/CSV/Parquet      | `run_tests.ps1` replay smoke |

---

## Unified Test Script

From repo root:

```powershell
.\scripts\test-production-readiness.ps1
```

Use `-SkipE2E` to skip E2E instructions. The script:

1. Builds and runs Chrome DevTools MCP tests
2. Runs overtime-ag pytest
3. Runs replay-only smoke (if `data/cbb_recording.json` exists)
4. Prints manual E2E instructions

---

## Recent Changes

- **2026-02-11**: Fixed Windows crash on negative ASP.NET timestamps (`parse.py`). Added 116 tests across 13 files covering edge cases for all modules. Synced plugin copy with canonical `omalleyandy-plugins` repo. Added `Data.GameLines` nested extraction, `--replay-only` CLI flag, rotator/UA support, and login automation.

## Gaps / Future Work

- **Overtime-ag CI**: Add `.github/workflows/overtime-ag-tests.yml` to run pytest + replay smoke on push/PR
- **E2E automation**: Full record+replay in CI would require headed browser or mocked overtime.ag; low priority
- **Chrome DevTools + overtime integration**: Optional eval using MCP tools to discover overtime.ag APIs (reference in `skills/chrome-devtools/network-for-scraping-discovery.md`)
