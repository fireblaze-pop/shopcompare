import datetime
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
from app.product_scoring import compute_overall_score


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
    category_products = db.query(Product).filter(Product.category == product.category).all()
    listings = db.query(PlatformListing).filter(PlatformListing.product_id == product.id).all()
    score = compute_overall_score(product, category_products, listings)
    product.aggregate_score = score
    product.aggregate_rating = score
