# Production Readiness Checklist

This document tracks production-worthiness of the **chrome-devtools-mcp** server and **overtime-ag-plugin** skills for deployment.

## Chrome DevTools MCP

| Check | Status | Notes |
|-------|--------|-------|
| Unit/integration tests | [OK] | `npm run test` - full suite in `tests/` |
| CI (GitHub Actions) | [OK] | `run-tests.yml` - ubuntu, windows, macos x node 20-24 |
| Build/bundle | [OK] | `npm run bundle` produces distributable |
| TypeScript strict | [OK] | `tsc --noEmit` |
| Lint/format | [OK] | ESLint + Prettier via `check-format` |
| Documentation | [OK] | `docs/`, `tool-reference.md`, skill in `skills/chrome-devtools/` |
| Release pipeline | [OK] | release-please, publish-to-npm-on-tag |

**Pre-deploy**: Run `npm run test` and `npm run bundle` from repo root.

---

## Overtime-ag-plugin

| Check | Status | Notes |
|-------|--------|-------|
| Unit tests | [OK] | `uv run pytest tests/` - recording, replay, parse, output, api_normalize, utils |
| Replay smoke | [OK] | `run_tests.ps1` - replay-only from `data/cbb_recording.json` |
| E2E (record) | [!!] Manual | Requires headed browser + live site; run setup/record-cbb skill |
| CI | [OK] | `overtime-ag-tests.yml` on push/PR to plugin paths |
| Playwright install | [OK] | `uv run playwright install chromium` |
| .env setup | [OK] | Copy `.env.example` to `.env` for OT_* vars |

**Pre-deploy**: Run `.\run_tests.ps1` from `project/` or `.\scripts\test-production-readiness.ps1` from repo root.

---

## Skills Coverage

| Skill | Purpose | Tested By |
|-------|---------|-----------|
| **chrome-devtools** | MCP reference for browser automation | Chrome DevTools MCP suite |
| **setup** | Init uv + Playwright, verify advanced-mode | `run_tests.ps1` step 3 |
| **record-cbb** | Record CBB network calls | E2E manual |
| **scrape-cbb** | Replay and export to JSON/CSV/Parquet | `run_tests.ps1` replay smoke |

---

## Unified Test Script

From repo root:

```powershell
.\scripts\test-production-readiness.ps1
```

Use `-SkipE2E` to avoid E2E instructions (default). The script:

1. Builds and runs Chrome DevTools MCP tests
2. Runs overtime-ag pytest
3. Runs replay-only smoke (if `data/cbb_recording.json` exists)
4. Prints manual E2E instructions

---

## Gaps / Future Work

- **Overtime-ag CI**: Add `.github/workflows/overtime-ag-tests.yml` to run pytest + replay smoke on push/PR
- **E2E automation**: Full record+replay in CI would require headed browser or mocked overtime.ag; low priority
- **Chrome DevTools + overtime integration**: Optional eval using MCP tools to discover overtime.ag APIs (reference in `skills/chrome-devtools/network-for-scraping-discovery.md`)
