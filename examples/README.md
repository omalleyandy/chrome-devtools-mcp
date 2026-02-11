# Examples

## overtime.ag scraper (Python + Playwright + requests)

Scrapes odds/lines from [overtime.ag](https://overtime.ag/sports#/) using:

- **Playwright** to open the page once (obtain session cookies and pass Cloudflare).
- **requests** to call the site’s JSON APIs (`GetSports`, `GetSportOffering`, and optional schedule).

### Setup

```bash
cd examples
pip install -r requirements-scraping.txt
playwright install chromium
```

### Usage

```bash
# Default: NBA game lines
python overtime_ag_scraper.py

# List all sports/leagues
python overtime_ag_scraper.py --list-sports

# Another sport/league (use exact names from --list-sports)
python overtime_ag_scraper.py --sport Soccer --league "Italy Serie A"

# Only fetch schedule event IDs (third-party API)
python overtime_ag_scraper.py --schedule-only

# Show browser window (useful if Cloudflare challenges appear)
python overtime_ag_scraper.py --no-headless
```

### APIs used

| Purpose     | Method     | URL / Body                                                                               |
| ----------- | ---------- | ---------------------------------------------------------------------------------------- |
| Session     | Playwright | `GET https://overtime.ag/sports#/`                                                       |
| Sports list | POST       | `Offering.asmx/GetSports` → `{"getInactiveSports":false}`                                |
| Game lines  | POST       | `Offering.asmx/GetSportOffering` → `{"sportType":"Basketball","sportSubType":"NBA",...}` |
| Event IDs   | GET        | `https://bv2-us.digitalsportstech.com/api/schedule?sb=ticosports-asi`                    |

Cookie handling (and optional `cf_clearance`) is done via the Playwright session; the same cookies are then used in the `requests` session.
