# Chrome DevTools MCP -- Quick Tool Reference

30 tools across 7 categories. All element-based tools use `uid` from
`take_snapshot`. v0.17.0.

## Input (8 tools)

| Tool | Parameters | Notes |
|------|-----------|-------|
| `click` | `uid`, `dblClick?`, `includeSnapshot?` | Single or double click |
| `click_at` | `x`, `y`, `dblClick?` | Coordinate click (experimental vision) |
| `hover` | `uid`, `includeSnapshot?` | Reveal tooltips/menus |
| `fill` | `uid`, `value`, `includeSnapshot?` | Text input, textarea, or select |
| `fill_form` | `elements: [{uid, value}]`, `includeSnapshot?` | Batch fill multiple fields |
| `press_key` | `key`, `includeSnapshot?` | Keys: `"Enter"`, `"Control+A"`, `"Control+Shift+R"` |
| `drag` | `from_uid`, `to_uid`, `includeSnapshot?` | Drag and drop |
| `upload_file` | `uid`, `filePath`, `includeSnapshot?` | File input or file chooser fallback |

## Navigation (6 tools)

| Tool | Parameters | Notes |
|------|-----------|-------|
| `list_pages` | (none) | Returns pageId + URL for each tab |
| `select_page` | `pageId`, `bringToFront?` | Switch active page context |
| `new_page` | `url`, `background?`, `timeout?` | Open new tab |
| `close_page` | `pageId` | Cannot close last remaining page |
| `navigate_page` | `type?`, `url?`, `ignoreCache?`, `handleBeforeUnload?`, `initScript?`, `timeout?` | type: url/back/forward/reload |
| `wait_for` | `text`, `timeout?` | Block until text appears |

## Debugging (5 tools)

| Tool | Parameters | Notes |
|------|-----------|-------|
| `take_snapshot` | `verbose?`, `filePath?` | A11y tree with UIDs; prefer over screenshots |
| `take_screenshot` | `format?`, `quality?`, `uid?`, `fullPage?`, `filePath?` | PNG/JPEG/WebP; auto-saves if >2MB |
| `list_console_messages` | `pageSize?`, `pageIdx?`, `types?`, `includePreservedMessages?` | Types: log, error, warn, info, debug, issue |
| `get_console_message` | `msgid` | Full stack trace, args, error.cause chain |
| `evaluate_script` | `function`, `args?: [{uid}]` | Run JS in page; return must be JSON-serializable |

## Network (2 tools)

| Tool | Parameters | Notes |
|------|-----------|-------|
| `list_network_requests` | `pageSize?`, `pageIdx?`, `resourceTypes?`, `includePreservedRequests?` | Types: xhr, fetch, document, script, image, etc. |
| `get_network_request` | `reqid?`, `requestFilePath?`, `responseFilePath?` | Omit reqid for DevTools-selected request; bodies truncated at 10KB inline |

## Performance (3 tools)

| Tool | Parameters | Notes |
|------|-----------|-------|
| `performance_start_trace` | `reload`, `autoStop`, `filePath?` | Navigate to URL first if reload=true; one trace at a time |
| `performance_stop_trace` | `filePath?` | Save raw trace as .json or .json.gz |
| `performance_analyze_insight` | `insightSetId`, `insightName` | e.g., "LCPBreakdown", "DocumentLatency" |

## Emulation (2 tools)

| Tool | Parameters | Notes |
|------|-----------|-------|
| `emulate` | `networkConditions?`, `cpuThrottlingRate?`, `geolocation?`, `userAgent?`, `colorScheme?`, `viewport?` | Network: Offline/Slow 3G/Fast 3G/Slow 4G/Fast 4G; CPU: 1-20x |
| `resize_page` | `width`, `height` | Set page dimensions in pixels |

## Dialogs (1 tool)

| Tool | Parameters | Notes |
|------|-----------|-------|
| `handle_dialog` | `action`, `promptText?` | action: accept/dismiss |

## Extensions (4 tools, experimental)

| Tool | Parameters | Notes |
|------|-----------|-------|
| `install_extension` | `path` | Unpacked extension folder path |
| `uninstall_extension` | `id` | Extension ID |
| `list_extensions` | (none) | Name, ID, version, enabled status |
| `reload_extension` | `id` | Reload unpacked extension |

Requires `--experimentalExtensionSupport` flag.

## Interop (1 tool, experimental)

| Tool | Parameters | Notes |
|------|-----------|-------|
| `get_tab_id` | `pageId` | Get Chrome tab ID for a page |

Requires `--experimentalInteropTools` flag.

## Common Patterns

### includeSnapshot parameter
Most input tools accept `includeSnapshot: true` to return an updated
a11y snapshot with the response. Default is server-controlled. Set to
`false` to skip the snapshot and reduce response size.

### includePreserved* parameters
`list_console_messages` and `list_network_requests` accept a flag to
include data from the last 3 navigations (default: current only).

### filePath parameters
`take_snapshot`, `take_screenshot`, `get_network_request`,
`performance_start_trace`, `performance_stop_trace` all support saving
output to a local file path. Use for large outputs.

### Pagination
`list_console_messages` and `list_network_requests` support `pageSize`
and `pageIdx` (0-based) for paginated retrieval.
