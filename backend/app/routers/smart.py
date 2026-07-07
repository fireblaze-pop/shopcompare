import random
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.database import get_db
from app.models.models import Product, PlatformListing, PriceHistory
from app.services.auth_service import get_current_user

router = APIRouter()

BRAND_REPUTATION: dict[str, int] = {
  'Apple': 95, '华为': 92, '戴森': 88, '联想': 82, '美的': 80,
  '兰蔻': 90, 'Nike': 86, '戴尔': 80, '小米': 84, '三星': 85,
  'OPPO': 78, 'vivo': 76, '格力': 83, '海尔': 82, '飞利浦': 80,
  '雅诗兰黛': 88, 'SK-II': 90, '欧莱雅': 75, 'Adidas': 82,
  'Zara': 72, 'Coach': 78, '茅台': 92, '三只松鼠': 70,
  '良品铺子': 68, '百草味': 65
}

CATEGORY_PRICE_RANGES: dict[str, tuple[float, float]] = {
  '手机数码': (500, 15000), '电脑办公': (800, 20000), '家用电器': (200, 10000),
  '美妆个护': (50, 3000), '服饰鞋包': (80, 5000), '食品生鲜': (10, 3000)
}


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

    category = product.category
    all_cat = db.query(Product).filter(Product.category == category).all()
    prices = [p.lowest_price for p in all_cat]
    pmin, pmax = (min(prices), max(prices)) if prices else (0, 1)
    pct = (product.lowest_price - pmin) / (pmax - pmin + 0.01)

    listings = db.query(PlatformListing).filter(PlatformListing.product_id == product_id).all()
    in_stock_count = sum(1 for l in listings if l.in_stock)
    stock_rate = in_stock_count / max(len(listings), 1)

    brand_score = BRAND_REPUTATION.get(product.brand, 70)

    log_rating = product.aggregate_rating if product.aggregate_rating > 0 else 4.0
    log_count = max(product.total_review_count, 1)

    cost_perf = round(min(100, max(0, (100 - pct * 50) * (product.aggregate_score / 10))))
    quality = round(min(100, max(0, log_rating * 20 * (0.7 + 0.3 * min(1, __import__('math').log10(log_count + 1) / 4)))))
    brand_dim = round(min(100, max(0, brand_score)))
    after_sales = round(min(100, max(0, brand_score * 0.6 + stock_rate * 100 * 0.4)))
    logistics = round(min(100, max(0, stock_rate * 100)))
    appearance = round(min(100, max(0, log_rating * 16 + min(28, __import__('math').log(log_count + 1) * 4))))

    return {'dimensions': [
        {'label': '性价比', 'value': cost_perf},
        {'label': '品质', 'value': quality},
        {'label': '品牌', 'value': brand_dim},
        {'label': '售后', 'value': after_sales},
        {'label': '物流', 'value': logistics},
        {'label': '外观', 'value': appearance}
    ]}


@router.get('/filters')
def get_filters(category: str = Query(''), db: Session = Depends(get_db)):
    query = db.query(Product)
    if category:
        query = query.filter(Product.category == category)
    products = query.all()

    brands: list[str] = list(set(p.brand for p in products if p.brand))

    prices = [p.lowest_price for p in products if p.lowest_price > 0]
    pmin = int(min(prices)) if prices else 0
    pmax = int(max(prices)) + 1 if prices else 10000

    return {
        'category': category,
        'brands': sorted(brands),
        'price_range': {'min': pmin, 'max': pmax},
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
    prices = [p.lowest_price for p in products]
    return {
        'min': min(prices),
        'max': max(prices),
        'avg': round(sum(prices) / len(prices), 2),
        'count': len(products)
    }


def _product_to_item(p: Product) -> dict:
    listings = p.listings if p.listings else []
    platform_count = len(set(l.platform for l in listings)) if listings else 0
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
