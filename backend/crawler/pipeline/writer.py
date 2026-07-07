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
    'Apple', '华为', '小米', 'OPPO', 'vivo', '三星', '联想', '戴尔',
    '美的', '格力', '海尔', '戴森', '飞利浦', '兰蔻', '雅诗兰黛',
    'SK-II', '欧莱雅', 'Nike', 'Adidas', 'Zara', 'Coach', '茅台',
    '三只松鼠', '良品铺子', '百草味', '茅台', '农夫山泉', '丝芙兰',
    '雅诗兰黛', 'Levi\'s'
  ]
  name_lower: str = name.lower()
  for kw in brand_list:
    if kw.lower() in name_lower:
      return kw
  return ''


def find_existing_product(db: Session, name: str, brand: str) -> Optional[Product]:
  normalized: str = normalize_name(name)
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

  brand: str = raw.get('brand', '') or guess_brand(raw.get('name', ''))

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

  db.commit()
  return product.id
