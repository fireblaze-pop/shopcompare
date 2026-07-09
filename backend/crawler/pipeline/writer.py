import datetime
import hashlib
import math
import re
import uuid
from typing import Optional

from sqlalchemy.orm import Session

from app.brand_catalog import (
    infer_brand_from_title,
    normalize_brand as normalize_catalog_brand,
    normalize_product_title,
    product_brand,
)
from app.models.models import PlatformListing, PriceHistory, Product


PRICE_RATING_BOOST: float = 0.1


def normalize_name(name: str) -> str:
    return normalize_product_title(name)


def guess_brand(name: str) -> str:
    return infer_brand_from_title(name, '')


def normalize_brand(brand: str) -> str:
    return normalize_catalog_brand(brand)


def _extract_keywords(name: str, min_len: int = 2) -> list[str]:
    cleaned: str = re.sub(r'[^\w\u4e00-\u9fff]', ' ', name)
    return [part for part in cleaned.split() if len(part) >= min_len]


def _is_same_product(left_name: str, right_name: str) -> bool:
    left = normalize_name(left_name)
    right = normalize_name(right_name)
    if not left or not right:
        return False
    if left == right:
        return True
    return len(left) >= 12 and len(right) >= 12 and (left in right or right in left)


def find_existing_product(db: Session, name: str, brand: str, category: str) -> Optional[Product]:
    norm_brand = infer_brand_from_title(name, brand)
    candidates = db.query(Product).filter(Product.category == category).all()

    for product in candidates:
        if product_brand(product) != norm_brand:
            continue
        if _is_same_product(product.name or '', name):
            return product

    keywords = _extract_keywords(name)
    if len(keywords) < 2:
        return None

    for product in candidates:
        if norm_brand and product_brand(product) != norm_brand:
            continue
        product_text = normalize_name((product.name or '') + ' ' + (product.description or ''))
        if all(normalize_name(keyword) in product_text for keyword in keywords[:3]):
            return product

    return None


def save_raw_product(db: Session, raw: dict) -> Optional[str]:
    now_date: str = datetime.datetime.now().strftime('%Y-%m-%d')
    price: float = raw.get('price', 0.0)
    platform: str = raw.get('platform', '\u5b9e\u65f6\u91c7\u96c6')
    name: str = raw.get('name', '')
    if price <= 0 or not name:
        return None

    raw_brand = raw.get('brand', '') or guess_brand(name)
    brand: str = infer_brand_from_title(name, raw_brand)
    category: str = raw.get('category', '\u672a\u5206\u7c7b')

    product = find_existing_product(db, name, brand, category)
    if product is None:
        product = Product(
            id=str(uuid.uuid4())[:16],
            name=name,
            brand=brand,
            category=category,
            image_url=raw.get('image_url', ''),
            description=name[:100],
            lowest_price=price,
            highest_price=price,
            price_spread=0,
            historical_low=price,
            publish_date=now_date,
            created_at=datetime.datetime.now()
        )
        db.add(product)
        db.flush()
    else:
        product.brand = brand or product.brand
        if raw.get('image_url') and not product.image_url:
            product.image_url = raw.get('image_url', '')
        if not product.description:
            product.description = name[:100]

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
        if raw.get('product_url'):
            listing.url = raw.get('product_url', '')
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
        db.add(PriceHistory(
            product_id=product.id,
            date=now_date,
            price=price
        ))

    _refresh_price_fields(db, product)
    _compute_product_score(db, product)

    db.commit()
    return product.id


def _refresh_price_fields(db: Session, product: Product) -> None:
    listings = db.query(PlatformListing).filter(
        PlatformListing.product_id == product.id
    ).all()
    prices: list[float] = [listing.price for listing in listings if listing.price > 0]
    if prices:
        product.lowest_price = min(prices)
        product.highest_price = max(prices)
        product.price_spread = product.highest_price - product.lowest_price

    history_records = db.query(PriceHistory).filter(
        PriceHistory.product_id == product.id
    ).all()
    history_prices: list[float] = [item.price for item in history_records if item.price > 0]
    if history_prices:
        product.historical_low = min(history_prices)


def _compute_product_score(db: Session, product: Product) -> None:
    def _seed(value: str, suffix: str) -> float:
        digest = hashlib.md5((value + suffix).encode()).hexdigest()
        return int(digest[:8], 16) % 4000 / 1000.0

    name = product.name or ''
    image_url = product.image_url or ''
    brand = product_brand(product)

    appearance = 7.0 + _seed(name, 'a') / 5 if len(image_url) > 10 else 3.0 + _seed(name, 'a') / 5
    appearance = max(0, min(10, appearance))

    review_total = sum((listing.review_count or 0) for listing in product.listings)
    if review_total > 0:
        logistics = math.log10(review_total + 1) / math.log10(100001) * 10
    else:
        logistics = 4.0
    logistics = max(2, min(10, logistics))

    platform_count = len(product.listings)
    after_sales = max(2, min(platform_count * 2.5, 10))

    brand_score = 7.0 + _seed(brand or name, 'b') / 5 if brand else 3.0
    brand_score = max(2, min(10, brand_score))

    lowest_price = product.lowest_price or 0
    historical_low = product.historical_low or 0
    spread = product.price_spread or 0
    if lowest_price > 0 and historical_low > 0 and spread > 0:
        discount_ratio = 1.0 - historical_low / lowest_price
        spread_ratio = min(spread / lowest_price, 0.5)
        cost_perf = 5.0 + discount_ratio * 3.0 + spread_ratio * 4.0
    elif lowest_price > 0 and historical_low > 0:
        cost_perf = 5.0 + (1.0 - historical_low / lowest_price) * 3.0
    else:
        cost_perf = 5.0
    cost_perf = max(2, min(10, cost_perf))

    ratings = [
        listing.rating for listing in product.listings
        if listing.rating and listing.rating > 0
    ]
    if ratings:
        quality = sum(ratings) / len(ratings) * 2.0
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
