import random
import time
import requests
from typing import Optional

USER_AGENTS: list[str] = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:120.0) Gecko/20100101 Firefox/120.0',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Edge/120.0.2210.91 Safari/537.36'
]

CATEGORY_KEYWORDS: dict[str, list[str]] = {
  '手机数码': ['手机', '平板电脑', '耳机', '智能手表', '充电器'],
  '电脑办公': ['笔记本电脑', '显示器', '键盘', '鼠标', '打印机'],
  '家用电器': ['空调', '冰箱', '洗衣机', '吸尘器', '电饭煲'],
  '美妆个护': ['精华液', '面霜', '口红', '面膜', '防晒霜'],
  '服饰鞋包': ['运动鞋', 'T恤', '牛仔裤', '双肩包', '钱包'],
  '食品生鲜': ['坚果', '茶叶', '牛奶', '零食大礼包', '牛肉干']
}

REQUEST_DELAY_MIN: float = 2.0
REQUEST_DELAY_MAX: float = 5.0
MAX_RETRIES: int = 2
TIMEOUT: int = 15


class BaseCrawler:
  def __init__(self, min_delay: float = REQUEST_DELAY_MIN, max_delay: float = REQUEST_DELAY_MAX):
    self.session = requests.Session()
    self.min_delay = min_delay
    self.max_delay = max_delay
    self._init_cookies()

  def _init_cookies(self):
    pass

  def _random_ua(self) -> str:
    return random.choice(USER_AGENTS)

  def _delay(self):
    time.sleep(random.uniform(self.min_delay, self.max_delay))

  def get(self, url: str, params: Optional[dict[str, str]] = None, retries: int = MAX_RETRIES) -> Optional[str]:
    for attempt in range(retries):
      try:
        self._delay()
        headers = {
          'User-Agent': self._random_ua(),
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
          'Accept-Encoding': 'gzip, deflate',
          'Connection': 'keep-alive'
        }
        resp = self.session.get(url, params=params, headers=headers, timeout=TIMEOUT)
        if resp.status_code == 200 and len(resp.text) > 500:
          return resp.text
        if resp.status_code in (302, 403, 503):
          wait = (attempt + 1) * 10
          print(f'  [retry] HTTP {resp.status_code}, waiting {wait}s...')
          time.sleep(wait)
          continue
      except Exception as e:
        print(f'  [error] attempt {attempt+1}/{retries}: {e}')
        time.sleep((attempt + 1) * 5)
    return None
