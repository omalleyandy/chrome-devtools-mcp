# Network & Console Data Flow

Deep dive into how Chrome DevTools MCP collects, stores, and formats
network requests and console messages.

## Collection Layer (PageCollector.ts)

### Storage Model

Both collectors use `PageCollector<T>` base class with per-navigation
bucketing:

```
WeakMap<Page, T[][]>
  Page -> [
    [items from current navigation],     // bucket 0
    [items from previous navigation],    // bucket 1
    [items from 2 navigations ago],      // bucket 2
  ]
```

On `framenavigated` (main frame), a new empty bucket is pushed and the
oldest is dropped. This gives 3-navigation retention.

Each item gets a **stable ID** (monotonic counter per page) that
persists across the session. IDs are used as `reqid` and `msgid` in
tool responses.

### NetworkCollector

- Subscribes to `page.on('request')` for every HTTPRequest
- On navigation, keeps the triggering request in the new bucket
  (so the navigation request itself is visible)
- Stores raw `HTTPRequest` objects (Puppeteer)

### ConsoleCollector

Collects three types of items into one stream:

| Type | Source | How Collected |
|------|--------|---------------|
| `ConsoleMessage` | `console.log/warn/error/...` | `page.on('console')` |
| `UncaughtError` | Unhandled exceptions | CDP `Runtime.exceptionThrown` |
| `AggregatedIssue` | DevTools audit issues | CDP `Audits.issueAdded` |

Uses `PageEventSubscriber` internally to bridge Puppeteer events to CDP:
- Enables `Audits.enable()` on the CDP session
- Runs `IssueAggregator` to deduplicate issues by primary key
- Resets issue tracking on navigation

## Formatting Layer (Formatters)

### NetworkFormatter

**Short format** (`toString()`):
```
reqid=1 GET https://example.com/api/data [200]
reqid=2 POST https://example.com/submit [302]
```

**Detailed format** (`toStringDetailed()`):
```markdown
## Request: GET https://example.com/api/data
### Request headers
- Accept: application/json
- Cookie: session=abc123

### Response headers
- Content-Type: application/json
- Cache-Control: no-cache

### Response body
{"users": [{"id": 1, "name": "Alice"}]}
```

Key behaviors:
- **Lazy loading**: Bodies only fetched when `fetchData: true`
- **Size limit**: Response bodies truncated at 10KB inline
- **File save**: `requestFilePath`/`responseFilePath` bypass truncation
- **Binary check**: Non-UTF-8 responses show `<binary data>`
- **Redirect chains**: Recursively formatted with indentation
- **Expiration**: Bodies expire from browser memory quickly

### ConsoleFormatter

**Short format** (`toString()`):
```
msgid=1 [log] Hello world (0 args)
msgid=2 [error] TypeError: Cannot read properties of undefined (1 args)
```

**Detailed format** (`toStringDetailed()`):
```markdown
## Console message
- msgid: 2
- type: error
- text: TypeError: Cannot read properties of undefined

### Arguments
- Argument 0: {"type": "object", "value": {...}}

### Stack trace
  at fetchData (src/api.ts:42:15)
  at handleClick (src/components/Button.tsx:18:5)
  --- setTimeout ---
  at scheduleUpdate (src/scheduler.ts:7:3)

### Caused by: NetworkError: Failed to fetch
  at doFetch (src/api.ts:30:11)
  at fetchData (src/api.ts:40:20)
```

Key behaviors:
- **Argument resolution**: Async `jsonValue()` extraction from RemoteObjects
- **Source-mapped stacks**: Waits up to 1000ms for source maps to load
  via `SymbolizedError.createStackTrace()`
- **Error.cause chains** (v0.17.0): Recursively resolves `error.cause`
  property, each rendered as "Caused by:" section
- **Error objects in console.log** (v0.17.0): When an Error instance is
  passed to `console.log()`, shows its message and stack trace
- **Frame filtering**: Frames from ignored scripts (node_modules,
  browser internals) are hidden
- **50-line limit**: Stack traces capped at 50 frames
- **Async fragments**: Shows async boundaries ("--- setTimeout ---")

### IssueFormatter

**Short format**: `msgid=3 [issue] Mixed Content (count: 2)`

**Detailed format**: Markdown with issue description, learn-more links,
and affected resources (elements mapped to `uid`, requests to `reqid`).

Issues are aggregated -- multiple occurrences of the same issue type
are pooled into one `AggregatedIssue` with a count.

## SymbolizedError (DevtoolsUtils.ts)

Central class for resolved error data with source-mapped stack traces.

### Creation paths

1. `fromDetails(opts)` -- From `Runtime.ExceptionDetails` (uncaught)
2. `fromError(opts)` -- From `RemoteObject` with `subtype='error'`
   (error objects in console.log)

### Resolution process

1. Extract message from exception details
2. Collect script IDs from all call frames (sync + async)
3. Wait for scripts to parse (`waitForScript`, up to 1000ms)
4. Wait for source maps (`sourceMapManager.sourceMapForClientPromise`)
5. Call `DebuggerWorkspaceBinding.createStackTraceFromProtocolRuntime()`
6. Result: frames with original file paths, line numbers, column numbers

### Cause chain

Walks `error.cause` property via CDP `Runtime.getProperties`:
1. Get error object's properties
2. Find `cause` property
3. If cause is an Error, recursively create `SymbolizedError`
4. Result: linked list of `SymbolizedError` objects

## Practical Tips

### Catching API responses

```
# Option A: Network panel (bodies may expire)
list_network_requests(resourceTypes: ["xhr", "fetch"])
get_network_request(reqid=5, responseFilePath: "response.json")

# Option B: evaluate_script (reliable, no expiration)
evaluate_script(function: "async () => {
  const r = await fetch('/api/data');
  return r.json();
}")
```

### Debugging errors efficiently

```
# 1. Find errors
list_console_messages(types: ["error"])

# 2. Get details (stack trace + cause chain)
get_console_message(msgid=2)

# 3. Check preserved messages from prior navigations
list_console_messages(includePreservedMessages: true)
```

### Monitoring network across navigations

```
# See requests from last 3 page loads
list_network_requests(includePreservedRequests: true)

# Filter to just API calls
list_network_requests(resourceTypes: ["xhr", "fetch"])
```
