"""
Example: Scrape odds/lines from overtime.ag using Playwright (session) + requests (API).

Usage:
  pip install playwright requests
  playwright install chromium

  python overtime_ag_scraper.py                    # NBA lines (default)
  python overtime_ag_scraper.py --sport Soccer    # list sports first, then use SportSubType
  python overtime_ag_scraper.py --schedule-only  # only fetch schedule event IDs
"""

from __future__ import annotations

import argparse
import json
import re
from typing import Any

import requests
from playwright.sync_api import sync_playwright

BASE = "https://overtime.ag"
SPORTS_API = f"{BASE}/sports/Api/Offering.asmx/GetSports"
OFFERING_API = f"{BASE}/sports/Api/Offering.asmx/GetSportOffering"
SCHEDULE_URL = "https://bv2-us.digitalsportstech.com/api/schedule?sb=ticosports-asi"

USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
)


def _parse_asp_dates(obj: Any) -> Any:
    """Convert ASP.NET /Date(ms)/ strings to ISO-like strings in place."""
    if isinstance(obj, dict):
        for k, v in list(obj.items()):
            obj[k] = _parse_asp_dates(v)
        return obj
    if isinstance(obj, list):
        return [_parse_asp_dates(x) for x in obj]
    if isinstance(obj, str) and re.match(r"^/Date\(\d+\)/$", obj):
        ms = int(re.search(r"\d+", obj).group())
        from datetime import datetime, timezone
        return datetime.fromtimestamp(ms / 1000.0, tz=timezone.utc).isoformat()
    return obj


def get_session_cookies(headless: bool = True) -> list[dict]:
    """Use Playwright to load the sports page and return cookies (handles Cloudflare)."""
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=headless)
        context = browser.new_context(user_agent=USER_AGENT)
        page = context.new_page()

        page.goto(f"{BASE}/sports#/", wait_until="networkidle", timeout=60_000)
        # Optional: wait for an API response so we know session is ready
        page.wait_for_timeout(2000)

        cookies = context.cookies()
        browser.close()
    return cookies


def session_with_cookies(cookies: list[dict]) -> requests.Session:
    """Build a requests session with the given cookies and correct headers."""
    s = requests.Session()
    s.headers.update({
        "User-Agent": USER_AGENT,
        "Accept": "application/json, text/plain, */*",
        "Content-Type": "application/json",
        "Origin": BASE,
        "Referer": f"{BASE}/sports",
    })
    for c in cookies:
        s.cookies.set(c["name"], c["value"], domain=c.get("domain", ""))
    return s


def get_sports(s: requests.Session, include_inactive: bool = False) -> list[dict]:
    """Fetch sports/leagues catalog."""
    r = s.post(SPORTS_API, json={"getInactiveSports": include_inactive}, timeout=30)
    r.raise_for_status()
    data = r.json()
    return data.get("d", {}).get("Data", [])


def get_sport_offering(
    s: requests.Session,
    sport_type: str,
    sport_sub_type: str,
    wager_type: str = "Straight Bet",
) -> list[dict]:
    """Fetch game lines for a sport/league."""
    payload = {
        "sportType": sport_type,
        "sportSubType": sport_sub_type,
        "wagerType": wager_type,
        "hoursAdjustment": 0,
        "periodNumber": None,
        "gameNum": None,
        "parentGameNum": None,
        "teaserName": "",
        "requestMode": None,
    }
    r = s.post(OFFERING_API, json=payload, timeout=30)
    r.raise_for_status()
    data = r.json()
    inner = data.get("d", {}).get("Data", {})
    if isinstance(inner, dict) and "GameLines" in inner:
        return inner["GameLines"]
    return []


def get_schedule(s: requests.Session) -> list[dict]:
    """Fetch schedule event IDs from third-party API (no auth in request)."""
    r = s.get(SCHEDULE_URL, timeout=15)
    r.raise_for_status()
    data = r.json()
    return data.get("data", [])


def main() -> None:
    parser = argparse.ArgumentParser(description="Scrape overtime.ag odds (Playwright + requests)")
    parser.add_argument("--sport", default="Basketball", help="SportType (e.g. Basketball, Soccer)")
    parser.add_argument("--league", default="NBA", help="SportSubType (e.g. NBA, Italy Serie A)")
    parser.add_argument("--schedule-only", action="store_true", help="Only fetch schedule event IDs")
    parser.add_argument("--list-sports", action="store_true", help="List available sports and exit")
    parser.add_argument("--no-headless", action="store_true", help="Show browser window")
    args = parser.parse_args()

    print("Getting session cookies via Playwright...")
    cookies = get_session_cookies(headless=not args.no_headless)
    s = session_with_cookies(cookies)

    if args.schedule_only:
        events = get_schedule(s)
        print(json.dumps(events, indent=2))
        return

    if args.list_sports:
        sports = get_sports(s)
        for x in sports:
            print(x.get("SportType"), "|", x.get("SportSubType"), "|", x.get("FirstRotNum"))
        return

    lines = get_sport_offering(s, args.sport, args.league)
    # Normalize ASP.NET dates for readability
    _parse_asp_dates(lines)

    for g in lines:
        print(
            g.get("GameDateTimeString"),
            "|",
            g.get("Team1ID"),
            "vs",
            g.get("Team2ID"),
            "| spread",
            g.get("Spread"),
            "| ml",
            g.get("MoneyLine1"),
            "/",
            g.get("MoneyLine2"),
            "| total",
            g.get("TotalPoints"),
        )
    print(f"\nTotal: {len(lines)} games")


if __name__ == "__main__":
    main()
