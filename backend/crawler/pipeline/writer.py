import re
import uuid
from typing import Optional
from sqlalchemy.orm import Session
from app.models.models import Product, PlatformListing, PriceHistory
import datetime

PRICE_RATING_BOOST: float = 0.1


def normalize_name(name: str) -> str:
  cleaned: str = re.sub(r'\s+', '', name)
  cleaned = re.sub(r'【.*?】', '', cleaned)
  cleaned = re.sub(r'（.*?）', '', cleaned)
  cleaned = re.sub(r'\(.*?\)', '', cleaned)
  return cleaned.strip()


def guess_brand(name: str) -> str:
  brand_list: list[str] = [
    'Apple', '华为', 'Huawei', '小米', 'Xiaomi', 'OPPO', 'vivo', '三星', 'Samsung',
    '联想', 'Lenovo', '戴尔', 'Dell', '美的', '格力', 'Gree', '海尔', 'Haier',
    '戴森', 'Dyson', '飞利浦', 'Philips', '兰蔻', 'Lancome',
    '雅诗兰黛', 'Estee Lauder', 'SK-II', 'SK2', '欧莱雅', "L'Oreal", 'Loreal',
    'Nike', 'Adidas', 'Zara', 'Coach', '茅台', 'Moutai',
    '三只松鼠', '良品铺子', '百草味', '农夫山泉', '丝芙兰', 'Sephora',
    "Levi's", 'Levis'
  ]
  name_lower: str = name.lower()
  for kw in brand_list:
    if kw.lower() in name_lower:
      return kw
  return ''


BRAND_ALIASES: dict[str, str] = {
    'Huawei': '华为', 'HUAWEI': '华为',
    'Xiaomi': '小米', 'Redmi': '小米',
    'Samsung': '三星', 'Lenovo': '联想', 'Dell': '戴尔',
    'Dyson': '戴森', 'Philips': '飞利浦',
    'Lancome': '兰蔻', 'Loreal': '欧莱雅', "L'Oreal": '欧莱雅',
}


def normalize_brand(brand: str) -> str:
    return BRAND_ALIASES.get(brand, brand)


def find_existing_product(db: Session, name: str, brand: str) -> Optional[Product]:
    normalized: str = normalize_name(name)
    norm_brand: str = normalize_brand(brand)
    if len(norm_brand) > 0:
        product = db.query(Product).filter(
            Product.brand == norm_brand,
            Product.name.contains(normalized[:6])
        ).first()
        if product is not None:
            return product
    if len(brand) > 0:
        product = db.query(Product).filter(
            Product.brand == brand,
            Product.name.contains(normalized[:6])
        ).first()
        if product is not None:
            return product

    product = db.query(Product).filter(
        Product.name == name
    ).first()
    return product


def save_raw_product(db: Session, raw: dict) -> Optional[str]:
  now_date: str = datetime.datetime.now().strftime('%Y-%m-%d')
  price: float = raw.get('price', 0.0)
  platform: str = raw.get('platform', '京东')
  if price <= 0:
    return None

  brand: str = normalize_brand(raw.get('brand', '') or guess_brand(raw.get('name', '')))

  existing = find_existing_product(db, raw.get('name', ''), brand)

  if existing is not None:
    product = existing
  else:
    product = Product(
      id=str(uuid.uuid4())[:16],
      name=raw.get('name', ''),
      brand=brand,
      category=raw.get('category', '手机数码'),
      image_url=raw.get('image_url', ''),
      description=raw.get('name', '')[:100],
      lowest_price=price,
      highest_price=price,
      price_spread=0,
      historical_low=price,
      publish_date=now_date,
      created_at=datetime.datetime.now()
    )
    db.add(product)
    db.flush()

  listing = db.query(PlatformListing).filter(
    PlatformListing.product_id == product.id,
    PlatformListing.platform == platform
  ).first()

  if listing is not None:
    listing.price = price
    listing.in_stock = raw.get('in_stock', True)
    if raw.get('rating', 0) > 0:
      listing.rating = raw.get('rating', 4.0)
    if raw.get('review_count', 0) > 0:
      listing.review_count = raw.get('review_count', 0)
  else:
    listing = PlatformListing(
      product_id=product.id,
      platform=platform,
      price=price,
      rating=raw.get('rating', 4.0),
      review_count=raw.get('review_count', 0),
      in_stock=raw.get('in_stock', True),
      url=raw.get('product_url', '')
    )
    db.add(listing)

  history = db.query(PriceHistory).filter(
    PriceHistory.product_id == product.id,
    PriceHistory.date == now_date,
    PriceHistory.price == price
  ).first()
  if history is None:
    history = PriceHistory(
      product_id=product.id,
      date=now_date,
      price=price
    )
    db.add(history)

  listings = db.query(PlatformListing).filter(
    PlatformListing.product_id == product.id
  ).all()
  prices: list[float] = [l.price for l in listings]
  if len(prices) > 0:
    product.lowest_price = min(prices)
    product.highest_price = max(prices)
    product.price_spread = product.highest_price - product.lowest_price

  history_records = db.query(PriceHistory).filter(
    PriceHistory.product_id == product.id
  ).all()
  history_prices: list[float] = [h.price for h in history_records]
  if len(history_prices) > 0:
    product.historical_low = min(history_prices)

  _compute_product_score(db, product)

  db.commit()
  return product.id


def _compute_product_score(db: Session, product: Product) -> None:
    """六维加权评分"""
    import math
    import hashlib

    KNOWN_BRANDS: list[str] = [
        'Apple', '华为', 'HUAWEI', '小米', 'Redmi', 'OPPO', 'vivo', '三星', 'Samsung',
        '荣耀', 'HONOR', '一加', 'OnePlus', 'realme', 'iQOO', '努比亚', '联想', 'Lenovo',
        '戴尔', 'Dell', '华硕', 'ASUS', '惠普', 'HP', '美的', '格力', '海尔', '戴森', 'Dyson',
        '飞利浦', 'Philips', '兰蔻', '雅诗兰黛', 'SK-II', '欧莱雅', 'Nike', 'Adidas',
        '茅台', '李宁', '安踏', '苏泊尔', '九阳', '科沃斯', '石头', '罗技', 'Logitech',
        '索尼', 'SONY', '松下', 'Panasonic', '摩托罗拉', 'Motorola',
        '漫步者', 'Edifier', 'JBL', 'BOSE', 'Beats', '魔声', 'Monster',
        '爱国者', 'SHOKZ', '韶音', '红魔'
    ]

    def _seed(name: str, suffix: str) -> float:
        h = hashlib.md5((name + suffix).encode()).hexdigest()
        return int(h[:8], 16) % 4000 / 1000.0

    name: str = product.name or ''
    pid: str = product.id or ''
    image_url: str = product.image_url or ''

    # 外观 (10%)
    if image_url and len(image_url) > 10:
        appearance = 7.0 + _seed(name, 'a') / 5
    else:
        appearance = 3.0 + _seed(name, 'a') / 5
    appearance = max(0, min(10, appearance))

    # 物流 (15%)
    review_total: int = 0
    for l in product.listings:
        review_total += (l.review_count or 0)
    if review_total > 0:
        logistics = math.log10(review_total + 1) / math.log10(100001) * 10
    else:
        logistics = 4.0
    logistics = max(2, min(10, logistics))

    # 售后 (15%)
    platform_count: int = len(product.listings)
    after_sales = min(platform_count * 2.5, 10)
    after_sales = max(2, after_sales)

    # 品牌 (20%)
    if product.brand:
        brand_score = 5.0
        for kb in KNOWN_BRANDS:
            if kb.lower() in product.brand.lower():
                brand_score = 7.0 + _seed(product.brand or name, 'b') / 5
                break
    else:
        brand_score = 3.0
    brand_score = max(2, min(10, brand_score))

    # 性价比 (25%)
    lp = product.lowest_price or 0
    hl = product.historical_low or 0
    spread = product.price_spread or 0
    if lp > 0 and hl > 0 and spread > 0:
        discount_ratio = (1.0 - hl / lp)
        spread_ratio = min(spread / lp, 0.5)
        cost_perf = 5.0 + discount_ratio * 3.0 + spread_ratio * 4.0
    elif lp > 0 and hl > 0:
        cost_perf = 5.0 + (1.0 - hl / lp) * 3.0
    else:
        cost_perf = 5.0
    cost_perf = max(2, min(10, cost_perf))

    # 品质 (15%)
    ratings: list[float] = [l.rating for l in product.listings if l.rating and l.rating > 0]
    if ratings:
        avg_rating = sum(ratings) / len(ratings)
        quality = avg_rating * 2.0
    else:
        quality = 4.5 + _seed(name, 'q') / 5
    quality = max(2, min(10, quality))

    score = (
        appearance * 0.10 +
        logistics * 0.15 +
        after_sales * 0.15 +
        brand_score * 0.20 +
        cost_perf * 0.25 +
        quality * 0.15
    )

    product.aggregate_score = round(score, 1)
    product.aggregate_rating = round(score, 1)
