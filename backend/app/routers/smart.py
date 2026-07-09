import math

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.models import PlatformListing, Product

router = APIRouter()

BRAND_REPUTATION: dict[str, int] = {
    'Apple': 95, '\u534E\u4E3A': 92, 'Huawei': 92,
    'Xiaomi': 84, '\u5C0F\u7C73': 84,
    'OPPO': 78,
    'vivo': 76,
    'Samsung': 85, '\u4E09\u661F': 85,
    'Lenovo': 82, '\u8054\u60F3': 82,
    'Dell': 80, '\u6234\u5C14': 80,
    'Midea': 80, '\u7F8E\u7684': 80,
    'Gree': 83, '\u683C\u529B': 83,
    'Haier': 82, '\u6D77\u5C14': 82,
    'Nike': 86,
    'Adidas': 82,
    '\u6234\u68EE': 88, 'Dyson': 88,
    '\u5170\u853B': 90, 'Lancome': 90,
    '\u8305\u53F0': 95,
}

PRICE_BINS: list[tuple[str, int, int]] = [
    ('1-100', 1, 100),
    ('100-1000', 100, 1000),
    ('1000-5000', 1000, 5000),
    ('5000-10000', 5000, 10000),
    ('10000-15000', 10000, 15000),
    ('15000\u4EE5\u4E0A', 15000, 999999),
]


@router.get('/recommendations')
def get_recommendations(size: int = Query(10, ge=1, le=50), db: Session = Depends(get_db)):
    products = db.query(Product).order_by(
        (Product.aggregate_score * func.log(Product.total_review_count + 2)).desc()
    ).limit(size).all()
    return {'items': [_product_to_item(p) for p in products], 'total': len(products)}


@router.get('/hot-products')
def get_hot_products(size: int = Query(10, ge=1, le=50), db: Session = Depends(get_db)):
    products = db.query(Product).order_by(
        (Product.aggregate_rating * func.log(Product.total_review_count + 1)).desc()
    ).limit(size).all()
    return {'items': [_product_to_item(p) for p in products], 'total': len(products)}


@router.get('/products/{product_id}/similar')
def get_similar_products(product_id: str, size: int = Query(6), db: Session = Depends(get_db)):
    source = db.query(Product).filter(Product.id == product_id).first()
    if source is None:
        return {'items': [], 'total': 0}
    similar = db.query(Product).filter(
        Product.id != product_id,
        Product.category == source.category
    ).order_by(func.random()).limit(size).all()
    return {'items': [_product_to_item(p) for p in similar], 'total': len(similar)}


@router.get('/products/{product_id}/dimensions')
def get_product_dimensions(product_id: str, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if product is None:
        return {'dimensions': []}

    products = db.query(Product).filter(Product.category == product.category).all()
    prices = [p.lowest_price for p in products if p.lowest_price > 0]
    pmin = min(prices) if prices else 0
    pmax = max(prices) if prices else 1
    pct = (product.lowest_price - pmin) / (pmax - pmin + 0.01)

    listings = db.query(PlatformListing).filter(PlatformListing.product_id == product_id).all()
    in_stock_count = sum(1 for item in listings if item.in_stock)
    stock_rate = in_stock_count / max(len(listings), 1)
    brand_score = BRAND_REPUTATION.get(product.brand, 70)
    rating = product.aggregate_rating if product.aggregate_rating > 0 else 4.0
    review_count = max(product.total_review_count, 1)

    cost_perf = round(min(100, max(0, (100 - pct * 50) * (product.aggregate_score / 10))))
    quality = round(min(100, max(0, rating * 20 * (0.7 + 0.3 * min(1, math.log10(review_count + 1) / 4)))))
    after_sales = round(min(100, max(0, brand_score * 0.6 + stock_rate * 100 * 0.4)))
    appearance = round(min(100, max(0, rating * 16 + min(28, math.log(review_count + 1) * 4))))

    return {'dimensions': [
        {'label': 'cost', 'value': cost_perf},
        {'label': 'quality', 'value': quality},
        {'label': 'brand', 'value': brand_score},
        {'label': 'after_sales', 'value': after_sales},
        {'label': 'logistics', 'value': round(stock_rate * 100)},
        {'label': 'appearance', 'value': appearance},
    ]}


@router.get('/filters')
def get_filters(category: str = Query(''), db: Session = Depends(get_db)):
    query = db.query(Product)
    if category:
        query = query.filter(Product.category == category)

    products = query.all()
    brand_counts: dict[str, int] = {}
    prices: list[float] = []

    for product in products:
        if product.brand:
            brand_counts[product.brand] = brand_counts.get(product.brand, 0) + 1
        if product.lowest_price > 0:
            prices.append(product.lowest_price)

    brands = [
        {'name': name, 'count': count}
        for name, count in sorted(brand_counts.items(), key=lambda item: (-item[1], item[0]))[:50]
    ]

    price_bins = []
    for label, min_value, max_value in PRICE_BINS:
        count = sum(1 for price in prices if price >= min_value and price <= max_value)
        price_bins.append({'label': label, 'min': min_value, 'max': max_value, 'count': count})

    return {
        'category': category,
        'brands': brands,
        'price_bins': price_bins,
        'product_count': len(products)
    }


@router.get('/brands/reputation')
def get_brand_reputation():
    return {'reputations': BRAND_REPUTATION}


@router.get('/categories/{category_id}/stats')
def get_category_stats(category_id: str, db: Session = Depends(get_db)):
    products = db.query(Product).filter(Product.category == category_id).all()
    if not products:
        return {'min': 0, 'max': 0, 'avg': 0, 'count': 0}
    prices = [p.lowest_price for p in products if p.lowest_price > 0]
    if not prices:
        return {'min': 0, 'max': 0, 'avg': 0, 'count': len(products)}
    return {
        'min': min(prices),
        'max': max(prices),
        'avg': round(sum(prices) / len(prices), 2),
        'count': len(products)
    }


def _product_to_item(p: Product) -> dict:
    listings = p.listings if p.listings else []
    platform_count = len(set(item.platform for item in listings)) if listings else 0
    return {
        'id': p.id,
        'name': p.name,
        'brand': p.brand,
        'category': p.category,
        'image_url': p.image_url,
        'lowest_price': p.lowest_price,
        'highest_price': p.highest_price,
        'price_spread': p.price_spread,
        'historical_low': p.historical_low,
        'aggregate_rating': p.aggregate_rating or 0,
        'aggregate_score': p.aggregate_score or 0,
        'total_review_count': p.total_review_count or 0,
        'platform_count': platform_count,
        'description': p.description or '',
        'publish_date': p.publish_date or ''
    }
