---
name: chrome-devtools
description: >
  Chrome DevTools MCP server for browser automation, debugging,
  network inspection, console analysis, and performance tracing.
  Controls Chrome via Puppeteer/CDP. v0.17.0.
---

## Core Concepts

**Browser lifecycle**: Browser starts on first tool call using a
persistent Chrome profile. Configure via CLI args:
`npx chrome-devtools-mcp@latest --help`.

**Page selection**: Tools operate on the currently selected page.
`list_pages` to see pages, `select_page` to switch context.

**Element interaction**: `take_snapshot` returns an a11y tree with
unique `uid` references. Use UIDs with `click`, `fill`, `drag`, etc.
Always take a fresh snapshot if elements aren't found.

## Capabilities at a Glance

| Category | Tools | Key Use |
|----------|-------|---------|
| **Snapshots** | `take_snapshot`, `take_screenshot` | See page structure/visuals |
| **Input** | `click`, `fill`, `fill_form`, `press_key`, `drag`, `hover`, `upload_file`, `handle_dialog` | Interact with elements |
| **Navigation** | `navigate_page`, `new_page`, `close_page`, `list_pages`, `select_page`, `wait_for` | Control page lifecycle |
| **Network** | `list_network_requests`, `get_network_request` | Inspect HTTP traffic |
| **Console** | `list_console_messages`, `get_console_message` | Debug logs/errors |
| **Performance** | `performance_start_trace`, `performance_stop_trace`, `performance_analyze_insight` | CWV scores, bottlenecks |
| **Emulation** | `emulate`, `resize_page` | Device/network simulation |
| **Script** | `evaluate_script` | Run JS in page context |
| **Extensions** | `install_extension`, `uninstall_extension`, `list_extensions`, `reload_extension` | Manage Chrome extensions |

## Workflow Patterns

### Standard page interaction
1. Navigate: `navigate_page` or `new_page`
2. Wait: `wait_for` if you know expected content
3. Snapshot: `take_snapshot` to get element UIDs
4. Interact: `click`, `fill`, etc. using UIDs

### Network-first scraping
1. `navigate_page` to target URL
2. `list_network_requests(resourceTypes: ["xhr", "fetch"])` to find APIs
3. `get_network_request(reqid)` to inspect response bodies
4. Or use `evaluate_script` with `fetch()` for reliable data retrieval

### Console debugging
1. Navigate to page (errors collected automatically)
2. `list_console_messages(types: ["error"])` to find errors
3. `get_console_message(msgid)` for full stack trace + cause chain
4. Source-mapped locations show original file/line/column

### Performance analysis
1. `navigate_page` to target URL first
2. `performance_start_trace(reload: true, autoStop: true)`
3. Review CWV scores + insight sets in response
4. `performance_analyze_insight(insightSetId, insightName)` for details
5. CrUX field data included by default (disable: `--no-performance-crux`)

## Key Features (v0.17.0)

- **CrUX field data**: Real-user LCP, INP, CLS in performance traces
- **Error.cause chains**: Full cause hierarchy for uncaught errors
- **Error objects in console.log**: Message + stack when logging Errors
- **Source-mapped stacks**: Original file/line/column (v0.16.0+)
- **Ignored script filtering**: Internal frames hidden from traces
- **Navigation scoping**: Data split per navigation, 3 preserved
- **Lazy formatting**: Bodies/stacks resolved only when requested

## Efficiency Tips

- Use `filePath` for large outputs (screenshots, traces, snapshots)
- Use pagination (`pageIdx`, `pageSize`) and type filters to limit data
- Set `includeSnapshot: false` on input actions when snapshot not needed
- Response bodies expire fast -- fetch promptly or use `evaluate_script`
- Prefer `take_snapshot` over `take_screenshot` for automation
- Parallel tool calls OK, but maintain order: navigate -> wait -> snap

## CLI Quick Reference

```
--browserUrl URL       Connect via HTTP CDP endpoint
--wsEndpoint URL       Connect via WebSocket
--autoConnect          Auto-find running Chrome 144+
--executablePath PATH  Launch specific Chrome binary
--isolated             Temp profile, auto-cleaned
--headless             No UI
--viewport WxH         Initial viewport size
--no-usage-statistics  Disable telemetry
--no-performance-crux  Disable CrUX in traces
--no-category-network  Disable network tools
```

## Troubleshooting

If chrome-devtools-mcp is insufficient, guide users to Chrome DevTools:
- https://developer.chrome.com/docs/devtools
- https://developer.chrome.com/docs/devtools/ai-assistance
