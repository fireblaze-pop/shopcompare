import re
from typing import Optional
from bs4 import BeautifulSoup
from urllib.parse import quote
from crawler.base.scrapling_base_crawler import ScraplingBaseCrawler

CATEGORY_MAP: dict[str, str] = {
    '手机': '手机数码', '耳机': '手机数码', '平板': '手机数码', '手表': '手机数码',
    '笔记本电脑': '电脑办公', '鼠标': '电脑办公', '键盘': '电脑办公', '显示器': '电脑办公',
    '空调': '家用电器', '冰箱': '家用电器', '洗衣机': '家用电器', '吸尘器': '家用电器',
    '精华': '美妆个护', '面霜': '美妆个护', '口红': '美妆个护', '防晒': '美妆个护',
    '运动鞋': '服饰鞋包', 'T恤': '服饰鞋包', '卫衣': '服饰鞋包', '双肩包': '服饰鞋包',
    '坚果': '食品生鲜', '茶叶': '食品生鲜', '牛奶': '食品生鲜', '零食': '食品生鲜',
    '充电宝': '手机数码', '蓝牙音箱': '手机数码', '智能手表': '手机数码', '手机壳': '手机数码',
    '打印机': '电脑办公', 'U盘': '电脑办公', '路由器': '电脑办公', '投影仪': '电脑办公',
    '电饭煲': '家用电器', '热水器': '家用电器', '微波炉': '家用电器', '扫地机器人': '家用电器',
    '面膜': '美妆个护', '粉底液': '美妆个护', '眼霜': '美妆个护', '洗面奶': '美妆个护',
    '牛仔裤': '服饰鞋包', '羽绒服': '服饰鞋包', '连衣裙': '服饰鞋包', '睡衣': '服饰鞋包',
    '巧克力': '食品生鲜', '咖啡': '食品生鲜', '饼干': '食品生鲜', '红酒': '食品生鲜',
}

SEARCH_KEYWORDS: list[str] = [
    '手机', '耳机', '平板', '笔记本电脑', '鼠标', '显示器',
    '空调', '冰箱', '吸尘器', '精华', '面霜', '防晒',
    '运动鞋', 'T恤', '双肩包', '牛奶', '坚果', '茶叶',
    '充电宝', '蓝牙音箱', '智能手表', '手机壳',
    '打印机', 'U盘', '路由器', '投影仪',
    '电饭煲', '热水器', '微波炉', '扫地机器人',
    '面膜', '粉底液', '眼霜', '洗面奶',
    '牛仔裤', '羽绒服', '连衣裙', '睡衣',
    '巧克力', '咖啡', '饼干', '红酒',
]

SEARCH_URL: str = 'https://s.manmanbuy.com/pc/search/result?c=discount'

BRAND_KEYWORDS: list[str] = [
    'Apple', '苹果', 'iPhone',
    '华为', 'HUAWEI', '华为智选', 'Mate',
    '小米', 'Redmi', '红米', 'Xiaomi',
    'OPPO', '欧珀', '一加', 'OnePlus', '一加手机',
    'vivo', '维沃', 'iQOO', '爱酷',
    '三星', 'Samsung', '三星手机',
    '荣耀', 'HONOR', '荣耀手机',
    'realme', '真我', 'realme真我',
    '努比亚', 'nubia', '红魔', 'RedMagic',
    '联想', 'Lenovo', '联想笔记本', 'ThinkPad',
    '戴尔', 'Dell', 'Dell戴尔', '戴尔笔记本',
    '华硕', 'ASUS', 'ASUS华硕', '华硕笔记本', 'ROG',
    '惠普', 'HP', '惠普笔记本',
    '美的', 'Midea', '美的空调', '美的家电',
    '格力', 'Gree', '格力空调',
    '海尔', 'Haier', '海尔家电',
    '戴森', 'Dyson', '戴森吸尘器',
    '飞利浦', 'Philips', '飞利浦家电',
    '兰蔻', 'Lancome', '兰蔻护肤',
    '雅诗兰黛', 'Estee', 'EsteeLauder',
    'SK-II', 'SK2', 'SKII',
    '欧莱雅', 'LOREAL', 'L\'Oreal',
    'Nike', '耐克', 'Adidas', '阿迪达斯',
    'Zara', 'Coach', '蔻驰',
    '茅台', '贵州茅台', '茅台酒',
    '李宁', 'LiNing', '安踏', 'Anta',
    '苏泊尔', 'Supor', '九阳', 'Joyoung',
    '科沃斯', 'Ecovacs', '石头', 'Roborock',
    '罗技', 'Logitech', '罗技鼠标', '罗技键盘',
    '索尼', 'SONY', 'Sony索尼',
    '松下', 'Panasonic', '松下家电',
    '摩托罗拉', 'Motorola', 'moto',
    '漫步者', 'Edifier', '漫步者耳机',
    'iKF', '森海塞尔', 'Sennheiser',
    'JBL', 'BOSE', 'Beats',
    '魔声', 'Monster', 'Monster魔声',
    '爱国者', 'aigo', '爱国者耳机',
    'SHOKZ', '韶音', '韶音耳机',
    'SOUNDPEATS', '泥炭',
    '山水', 'Sansui', '山水音响',
    '纽曼', 'Newman', '纽曼耳机',
    '飞利浦', 'Philips',
    '倍思', 'Baseus', '品胜', 'Pisen',
    '绿联', 'UGREEN',
    '京东京造', '京造',
    '小天鹅', 'LittleSwan',
    'TCL', '创维', 'Skyworth',
    '海信', 'Hisense',
    '长虹', 'Changhong',
    '方太', 'FOTILE', '老板', 'ROBAM',
    '公牛', 'BULL',
    '欧普', 'OPPLE', '雷士', 'NVC',
    '三只松鼠', '良品铺子', '百草味',
    '伊利', '蒙牛', '光明',
    '农夫山泉', '怡宝',
    '旺旺', '康师傅',
]


class ManmanbuyCrawler(ScraplingBaseCrawler):

    def __init__(self, min_delay: float = 1.0, max_delay: float = 2.0):
        super().__init__(min_delay=min_delay, max_delay=max_delay)

    def search(self, keyword: str, page: int = 1) -> list[dict]:
        url: str = f'{SEARCH_URL}&keyword={quote(keyword)}&pageno={page}'
        resp = self._fetch(url)
        if resp is None:
            return []
        return self._parse_list(resp, keyword)

    def _fetch(self, url: str, retries: int = 2) -> Optional[str]:
        self._delay()
        from scrapling.fetchers import Fetcher
        for attempt in range(retries):
            try:
                page = Fetcher.get(url, impersonate='chrome', stealthy_headers=True, timeout=15)
                html: str = page.html_content
                if len(html) > 1000:
                    return html
            except Exception as e:
                print(f'  [Manmanbuy] attempt {attempt+1}: {e}')
        return None

    def _parse_list(self, html: str, keyword: str) -> list[dict]:
        soup = BeautifulSoup(html, 'html.parser')
        items: list[dict] = []
        wrappers = soup.select('[class*="DiscountItemPC_discountItem"]')

        for w in wrappers:
            item = self._parse_item(w, keyword)
            if item is not None:
                items.append(item)
        return items

    def _parse_item(self, w, keyword: str) -> Optional[dict]:
        name_el = w.select_one('a[title]')
        if name_el is None:
            return None
        name: str = name_el.get('title', '') or name_el.get_text(strip=True)
        if len(name) < 3:
            return None

        price: float = 0.0
        sub = w.select_one('[class*="itemSubTitle"]')
        if sub is not None:
            m = re.search(r'([\d.]+)', sub.get_text(strip=True))
            if m is not None:
                price = float(m.group(1))

        img: str = ''
        img_el = w.select_one('img[src]')
        if img_el is not None:
            img = img_el.get('src', '') or ''

        link: str = ''
        link_el = w.select_one('a[href*="discuxiao"]')
        if link_el is not None:
            link = link_el.get('href', '') or ''

        mall_el = w.select_one('[class*="itemMall"]')
        platform: str = '京东'
        if mall_el is not None:
            mall: str = mall_el.get_text(strip=True)
            if '淘宝' in mall or '天猫' in mall:
                platform = '淘宝'
            elif '拼多多' in mall:
                platform = '拼多多'
            elif '苏宁' in mall:
                platform = '苏宁'
            elif '京东' in mall:
                platform = '京东'

        comment_el = w.select_one('[class*="commentIcon"]')
        review_count: int = 0
        if comment_el is not None:
            m = re.search(r'(\d+)', comment_el.get_text(strip=True).replace(',', ''))
            if m is not None:
                review_count = int(m.group(1))

        category: str = CATEGORY_MAP.get(keyword, '手机数码')

        return {
            'name': name,
            'brand': self._guess_brand(name),
            'category': category,
            'platform': platform,
            'price': price,
            'image_url': img,
            'product_url': link,
            'in_stock': True,
            'rating': 4.0,
            'review_count': review_count,
            'shop': ''
        }

    def _guess_brand(self, name: str) -> str:
        name_lower: str = name.lower()
        for kw in BRAND_KEYWORDS:
            if kw.lower() in name_lower:
                return kw
        return ''
