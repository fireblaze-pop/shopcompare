import json
import os
import random
import time
from typing import Optional
from scrapling.fetchers import Fetcher, DynamicFetcher, StealthyFetcher, StealthySession

USER_AGENTS: list[str] = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/119.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36',
]

REQUEST_DELAY_MIN: float = 2.0
REQUEST_DELAY_MAX: float = 5.0
MAX_RETRIES: int = 2
TIMEOUT: int = 30
BROWSER_TIMEOUT: int = 60000


class ScraplingBaseCrawler:

    def __init__(self, min_delay: float = REQUEST_DELAY_MIN, max_delay: float = REQUEST_DELAY_MAX,
                 cookies_file: Optional[str] = None):
        self.min_delay = min_delay
        self.max_delay = max_delay
        self.cookies_file = cookies_file
        self._session: Optional[StealthySession] = None
        self._cookies_injected: bool = False

    def _load_cookies(self) -> Optional[list[dict]]:
        if not self.cookies_file or not os.path.exists(self.cookies_file):
            return None
        try:
            with open(self.cookies_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            if isinstance(data, list):
                return data
            if isinstance(data, dict) and 'cookies' in data:
                return data['cookies']
        except Exception as e:
            print(f'  [Cookie] Load failed: {e}')
        return None

    def _to_playwright_cookies(self, raw_cookies: list[dict]) -> list[dict]:
        pw_cookies: list[dict] = []
        for c in raw_cookies:
            pc: dict = {
                'name': c.get('name', ''),
                'value': c.get('value', ''),
                'domain': c.get('domain', ''),
                'path': c.get('path', '/'),
            }
            if c.get('expirationDate'):
                pc['expires'] = c['expirationDate']
            if 'httpOnly' in c:
                pc['httpOnly'] = c['httpOnly']
            if 'secure' in c:
                pc['secure'] = c['secure']
            if 'sameSite' in c:
                s = c['sameSite']
                same_site_map: dict[str, str] = {
                    'no_restriction': 'None', 'unspecified': 'None',
                    'lax': 'Lax', 'strict': 'Strict'
                }
                pc['sameSite'] = same_site_map.get(s, 'Lax')
            pw_cookies.append(pc)
        return pw_cookies

    def _get_or_create_session(self) -> Optional[StealthySession]:
        if self._session is not None and self._cookies_injected:
            return self._session

        raw_cookies = self._load_cookies()
        if raw_cookies is None:
            return None

        try:
            if self._session is None:
                self._session = StealthySession(headless=True, solve_cloudflare=False)
                self._session.start()

            pw_cookies = self._to_playwright_cookies(raw_cookies)
            self._session.context.add_cookies(pw_cookies)
            self._cookies_injected = True
            print(f'  [Session] Injected {len(pw_cookies)} cookies from {self.cookies_file}')
            return self._session
        except Exception as e:
            print(f'  [Session] Error: {e}')
            self._close_session()
            return None

    def _close_session(self):
        if self._session is not None:
            try:
                self._session.close()
            except Exception:
                pass
            self._session = None
            self._cookies_injected = False

    def _delay(self):
        time.sleep(random.uniform(self.min_delay, self.max_delay))

    def _build_query(self, params: Optional[dict[str, str]]) -> str:
        if not params:
            return ''
        from urllib.parse import urlencode
        return '?' + urlencode(params)

    def get(self, url: str, params: Optional[dict[str, str]] = None,
            retries: int = MAX_RETRIES) -> Optional[str]:
        session = self._get_or_create_session()
        if session is not None:
            return self._fetch_with_session(url, params, retries)

        self._delay()
        query_string: str = self._build_query(params)
        for attempt in range(retries):
            try:
                page = Fetcher.get(
                    url + query_string,
                    impersonate='chrome',
                    stealthy_headers=True,
                    timeout=TIMEOUT
                )
                html: str = page.html_content
                if len(html) > 500:
                    return html
            except Exception as e:
                print(f'  [HTTP] attempt {attempt+1}/{retries}: {e}')
                time.sleep((attempt + 1) * 5)
        return None

    def get_dynamic(self, url: str, params: Optional[dict[str, str]] = None,
                    retries: int = MAX_RETRIES, headless: bool = True,
                    network_idle: bool = True) -> Optional[str]:
        session = self._get_or_create_session()
        if session is not None:
            return self._fetch_with_session(url, params, retries)

        self._delay()
        query_string: str = self._build_query(params)
        for attempt in range(retries):
            try:
                page = DynamicFetcher.fetch(
                    url + query_string,
                    headless=headless,
                    network_idle=network_idle,
                    timeout=BROWSER_TIMEOUT,
                    disable_resources=True
                )
                html: str = page.html_content
                if len(html) > 500:
                    return html
            except Exception as e:
                print(f'  [Dynamic] attempt {attempt+1}/{retries}: {e}')
                time.sleep((attempt + 1) * 10)
        return None

    def get_stealthy(self, url: str, params: Optional[dict[str, str]] = None,
                     retries: int = MAX_RETRIES, headless: bool = True,
                     solve_cloudflare: bool = False) -> Optional[str]:
        session = self._get_or_create_session()
        if session is not None:
            return self._fetch_with_session(url, params, retries)

        self._delay()
        query_string: str = self._build_query(params)
        for attempt in range(retries):
            try:
                page = StealthyFetcher.fetch(
                    url + query_string,
                    headless=headless,
                    solve_cloudflare=solve_cloudflare,
                    timeout=BROWSER_TIMEOUT,
                    google_search=False
                )
                html: str = page.html_content
                if len(html) > 500:
                    return html
            except Exception as e:
                print(f'  [Stealthy] attempt {attempt+1}/{retries}: {e}')
                time.sleep((attempt + 1) * 10)
        return None

    def _fetch_with_session(self, url: str, params: Optional[dict[str, str]],
                            retries: int = MAX_RETRIES) -> Optional[str]:
        if self._session is None:
            return None
        self._delay()
        query_string: str = self._build_query(params)
        for attempt in range(retries):
            try:
                page = self._session.fetch(
                    url + query_string,
                    headless=True,
                    google_search=False,
                    timeout=BROWSER_TIMEOUT
                )
                html: str = page.html_content
                if len(html) > 500:
                    return html
            except Exception as e:
                print(f'  [Session] attempt {attempt+1}/{retries}: {e}')
                time.sleep((attempt + 1) * 10)
        return None

    def close(self):
        self._close_session()
