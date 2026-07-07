import re
from typing import Optional
from bs4 import BeautifulSoup
from crawler.base.base_crawler import BaseCrawler

JD_SEARCH_URL: str = 'https://search.jd.com/Search'

CATEGORY_MAP_JD: dict[str, str] = {
  '手机': '手机数码', '平板电脑': '手机数码', '耳机': '手机数码', '智能手表': '手机数码', '充电器': '手机数码',
  '笔记本电脑': '电脑办公', '显示器': '电脑办公', '键盘': '电脑办公', '鼠标': '电脑办公', '打印机': '电脑办公',
  '空调': '家用电器', '冰箱': '家用电器', '洗衣机': '家用电器', '吸尘器': '家用电器', '电饭煲': '家用电器',
  '精华液': '美妆个护', '面霜': '美妆个护', '口红': '美妆个护', '面膜': '美妆个护', '防晒霜': '美妆个护',
  '运动鞋': '服饰鞋包', 'T恤': '服饰鞋包', '牛仔裤': '服饰鞋包', '双肩包': '服饰鞋包', '钱包': '服饰鞋包',
  '坚果': '食品生鲜', '茶叶': '食品生鲜', '牛奶': '食品生鲜', '零食大礼包': '食品生鲜', '牛肉干': '食品生鲜'
}

BRAND_KEYWORDS: list[str] = ['Apple', '华为', '小米', 'OPPO', 'vivo', '三星', '联想', '戴尔', '美的',
  '格力', '海尔', '戴森', '飞利浦', '兰蔻', '雅诗兰黛', 'SK-II', '欧莱雅', 'Nike', 'Adidas',
  'Zara', 'Coach', '茅台', '三只松鼠', '良品铺子', '百草味']


class JdCrawler(BaseCrawler):

  def search(self, keyword: str, page: int = 1) -> list[dict]:
    params = {
      'keyword': keyword,
      'page': page,
      'enc': 'utf-8'
    }
    html = self.get(JD_SEARCH_URL, params=params)
    if html is None:
      return []
    return self._parse_list(html, keyword)

  def _parse_list(self, html: str, keyword: str) -> list[dict]:
    soup = BeautifulSoup(html, 'html.parser')
    items: list[dict] = []
    product_items = soup.select('li.gl-item')
    if len(product_items) == 0:
      product_items = soup.select('div.gl-i-wrap')
    for li in product_items:
      item = self._parse_item(li, keyword)
      if item is not None:
        items.append(item)
    return items

  def _parse_item(self, li, fallback_keyword: str) -> Optional[dict]:
    name_el = li.select_one('.p-name em') or li.select_one('.p-name a em') or li.select_one('[data-title]')
    if name_el is None:
      return None
    name: str = name_el.get_text(strip=True)
    if len(name) < 3:
      return None

    price_el = li.select_one('.p-price i') or li.select_one('.p-price strong')
    price: float = 0.0
    if price_el is not None:
      price_text: str = price_el.get_text(strip=True)
      price = self._parse_price(price_text)

    img_el = li.select_one('.p-img img') or li.select_one('img[src]')
    img_url: str = ''
    if img_el is not None:
      img_url = img_el.get('src', '') or img_el.get('data-lazy-img', '') or ''
      if img_url.startswith('//'):
        img_url = 'https:' + img_url

    shop_el = li.select_one('.p-shop a') or li.select_one('.J_im_icon a')
    brand: str = self._guess_brand(name)
    category: str = CATEGORY_MAP_JD.get(fallback_keyword, '手机数码')

    product_url: str = ''
    link_el = li.select_one('.p-name a[href]') or li.select_one('a[href*="item.jd.com"]')
    if link_el is not None:
      href = link_el.get('href', '')
      if href.startswith('//'):
        href = 'https:' + href
      product_url = href

    comment_el = li.select_one('.p-commit a') or li.select_one('.p-commit strong')
    review_count: int = 0
    if comment_el is not None:
      review_str: str = re.sub(r'[^\d]', '', comment_el.get_text(strip=True))
      try:
        review_count = int(review_str) if review_str else 0
      except ValueError:
        review_count = 0

    return {
      'name': name,
      'brand': brand,
      'category': category,
      'platform': '京东',
      'price': price,
      'image_url': img_url,
      'product_url': product_url,
      'in_stock': True,
      'rating': 4.0,
      'review_count': review_count,
      'shop': shop_el.get_text(strip=True) if shop_el else ''
    }

  def _guess_brand(self, name: str) -> str:
    name_lower: str = name.lower()
    for kw in BRAND_KEYWORDS:
      if kw.lower() in name_lower:
        return kw
    return ''

  def _parse_price(self, text: str) -> float:
    cleaned: str = re.sub(r'[^\d.]', '', text)
    try:
      return float(cleaned)
    except ValueError:
      return 0.0
