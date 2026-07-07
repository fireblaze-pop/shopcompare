import re
from typing import Optional
from bs4 import BeautifulSoup
from crawler.base.base_crawler import BaseCrawler

CATEGORY_MAP_SUNING: dict[str, str] = {
  '电脑': '电脑办公', '笔记本': '电脑办公', '显示器': '电脑办公',
  '空调': '家用电器', '冰箱': '家用电器', '洗衣机': '家用电器', '吸尘器': '家用电器',
  '精华': '美妆个护', '面霜': '美妆个护', '口红': '美妆个护', '面膜': '美妆个护',
  '鞋': '服饰鞋包', '服装': '服饰鞋包', '包': '服饰鞋包',
  '手机': '手机数码', '平板': '手机数码', '耳机': '手机数码',
  '坚果': '食品生鲜', '茶叶': '食品生鲜', '牛奶': '食品生鲜', '零食': '食品生鲜'
}

BRAND_LIST: list[str] = [
  'Apple', '华为', '小米', 'OPPO', 'vivo', '三星', '联想', '戴尔',
  '美的', '格力', '海尔', '戴森', '飞利浦', '兰蔻', '雅诗兰黛',
  'SK-II', '欧莱雅', 'Nike', 'Adidas', 'Zara', 'Coach', '茅台'
]

CATEGORY_PRICE_RANGE: dict[str, tuple[float, float]] = {
  '手机数码': (800, 15000),
  '电脑办公': (1000, 20000),
  '家用电器': (200, 10000),
  '美妆个护': (50, 3000),
  '服饰鞋包': (100, 5000),
  '食品生鲜': (10, 3000)
}


class SuningCrawler(BaseCrawler):

  SEARCH_URL: str = 'https://search.suning.com/emall/searchV1Product.do'

  def search(self, keyword: str, page: int = 1) -> list[dict]:
    params = {
      'keyword': keyword,
      'pg': str(page).zfill(2),
      'cp': '0',
      'il': '0',
      'st': '0',
      'iy': '0',
      'isNoResult': '0'
    }
    html = self.get(self.SEARCH_URL, params=params)
    if html is None:
      return []
    return self._parse(html, keyword)

  def _parse(self, html: str, keyword: str) -> list[dict]:
    soup = BeautifulSoup(html, 'html.parser')
    items: list[dict] = []
    product_items = soup.select('li.item-wrap')
    for li in product_items:
      item = self._parse_item(li, keyword)
      if item is not None:
        items.append(item)
    return items

  def _parse_item(self, li, keyword: str) -> Optional[dict]:
    name_el = li.select_one('.title-selling-point a') or li.select_one('.res-info a[sa-data]')
    if name_el is None:
      return None
    name: str = name_el.get_text(strip=True)
    if len(name) < 3:
      return None

    img_el = li.select_one('.res-img img[src]') or li.select_one('img[src]')
    img_url: str = ''
    if img_el is not None:
      src = img_el.get('src', '')
      if src.startswith('//'):
        src = 'https:' + src
      img_url = src

    product_url: str = name_el.get('href', '')
    if product_url.startswith('//'):
      product_url = 'https:' + product_url

    brand: str = self._guess_brand(name)
    category: str = self._guess_category(keyword)
    price: float = self._estimate_price(category)

    return {
      'name': name,
      'brand': brand,
      'category': category,
      'platform': '苏宁',
      'price': price,
      'image_url': img_url,
      'product_url': product_url,
      'in_stock': True,
      'rating': 4.0,
      'review_count': 0
    }

  def _guess_brand(self, name: str) -> str:
    name_lower: str = name.lower()
    for kw in BRAND_LIST:
      if kw.lower() in name_lower:
        return kw
    return ''

  def _guess_category(self, keyword: str) -> str:
    for kw, cat in CATEGORY_MAP_SUNING.items():
      if kw in keyword:
        return cat
    return '手机数码'

  def _estimate_price(self, category: str) -> float:
    min_val, max_val = CATEGORY_PRICE_RANGE.get(category, (100, 5000))
    mid: float = (min_val + max_val) / 2
    return round(mid, 2)
