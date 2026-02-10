# Network-First Scraping & API Discovery

Guide for using Chrome DevTools MCP's network tools to discover and
extract data from web applications by intercepting their API calls.

## Why Network-First?

Most modern web apps load data via XHR/fetch APIs. Instead of parsing
DOM structures (fragile, slow), intercept the underlying API calls to
get clean, structured JSON data. This approach is:

- **Faster**: Skip DOM rendering, get raw data directly
- **More reliable**: APIs change less frequently than UI markup
- **Richer**: API responses often contain more data than what's displayed

## Discovery Workflow

### Step 1: Navigate and observe

```
navigate_page(url: "https://example.com/dashboard")
wait_for(text: "Dashboard")
```

### Step 2: List API calls

```
list_network_requests(resourceTypes: ["xhr", "fetch"])
```

Output:
```
reqid=3 GET https://api.example.com/v1/users [200]
reqid=5 GET https://api.example.com/v1/stats?range=7d [200]
reqid=8 POST https://api.example.com/v1/search [200]
```

### Step 3: Inspect interesting responses

```
get_network_request(reqid=5)
```

Returns full headers + response body with the actual JSON data.

### Step 4: Save large responses to files

```
get_network_request(
  reqid=5,
  responseFilePath: "stats_response.json"
)
```

## Handling Body Expiration

Network response bodies expire quickly in browser memory. Two
strategies:

### Strategy A: Fetch promptly after navigation

List and retrieve immediately after the page loads. Don't wait too long
between `list_network_requests` and `get_network_request`.

### Strategy B: Use evaluate_script (recommended for reliability)

```
evaluate_script(function: "async () => {
  const response = await fetch('https://api.example.com/v1/stats?range=7d', {
    credentials: 'include'
  });
  return response.json();
}")
```

This re-issues the request using the page's cookies/session, bypassing
the expiration problem entirely. Use `credentials: 'include'` to send
cookies for authenticated endpoints.

## Discovering Hidden APIs

### Trigger UI actions to reveal API endpoints

```
# 1. Snapshot to find interactive elements
take_snapshot

# 2. Click a button that loads data
click(uid: "ref_15")

# 3. Check what API calls were made
list_network_requests(resourceTypes: ["xhr", "fetch"])
```

### Search/filter interactions

```
# 1. Fill a search box
fill(uid: "ref_8", value: "search term")

# 2. Submit
press_key(key: "Enter")

# 3. Capture the search API call
list_network_requests(resourceTypes: ["xhr", "fetch"])
get_network_request(reqid=12)
```

### Pagination discovery

```
# 1. Click "next page" or scroll
click(uid: "ref_22")

# 2. See the pagination API pattern
list_network_requests(resourceTypes: ["xhr", "fetch"])
```

Look for patterns like `?page=2`, `?offset=20`, `?cursor=abc123`.

## Filtering by Resource Type

Available resource types for `list_network_requests`:

| Type | Use For |
|------|---------|
| `xhr` | XMLHttpRequest API calls |
| `fetch` | Fetch API calls |
| `document` | HTML page loads |
| `script` | JavaScript files |
| `stylesheet` | CSS files |
| `image` | Images |
| `media` | Audio/video |
| `websocket` | WebSocket connections |
| `font` | Web fonts |

Most useful for scraping: `["xhr", "fetch"]`

## Cross-Navigation Tracking

```
# See requests from last 3 navigations
list_network_requests(includePreservedRequests: true)
```

Useful when a multi-step flow (login -> dashboard -> detail page)
makes API calls across navigations.

## WebSocket Discovery

WebSocket connections appear in network requests with type `websocket`.
While you can see the connection was made, inspect the actual message
frames using `evaluate_script` to tap into the WebSocket:

```
evaluate_script(function: "() => {
  // Intercept future messages
  const origSend = WebSocket.prototype.send;
  window.__wsMessages = [];
  WebSocket.prototype.send = function(data) {
    window.__wsMessages.push({dir: 'out', data});
    return origSend.call(this, data);
  };
}")
```

## Example: ESPN API Discovery

Real-world pattern discovered using this approach:

1. Navigate to ESPN scoreboard
2. Filter network to `xhr`/`fetch`
3. Discover endpoints like:
   - `/apis/site/v2/sports/basketball/mens-college-basketball/scoreboard`
   - Key params: `groups=50` (all D1), `dates=YYYYMMDD-YYYYMMDD`
   - `limit=1000` (max effective, >1000 falls back to 25)
4. Use `evaluate_script` + `fetch()` to reliably pull data
5. Event detail via `/summary?event={id}` includes betting lines

## Tips

- Always check `resourceTypes: ["xhr", "fetch"]` first -- most data
  comes through these channels
- Use `evaluate_script` with `fetch()` for reliable data retrieval;
  network panel bodies expire fast
- Add `credentials: 'include'` when re-fetching authenticated endpoints
- Save large responses to files instead of reading inline (10KB limit)
- Check response headers for pagination hints (`Link`, `X-Total-Count`)
- Look for GraphQL endpoints (`POST` to `/graphql`) -- the request body
  contains the query
