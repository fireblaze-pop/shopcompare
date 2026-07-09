from fastapi import APIRouter, Depends, Query
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.brand_catalog import dedupe_products, infer_brand_from_title
from app.category_catalog import (
    apply_sub_category_filter,
    find_sub_category,
    product_matches_sub_category,
    resolve_category,
)
from app.database import get_db
from app.models.models import PlatformListing, Product
from app.product_scoring import BRAND_REPUTATION, compute_dimensions

router = APIRouter()

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
    listings = db.query(PlatformListing).filter(PlatformListing.product_id == product_id).all()
    return {'dimensions': compute_dimensions(product, products, listings)}


@router.get('/filters')
def get_filters(
    category_id: str = Query(''),
    sub_category_id: str = Query(''),
    category: str = Query(''),
    db: Session = Depends(get_db)
):
    query = db.query(Product)
    category_meta = resolve_category(category_id, category)

    if category_id and category_meta is None:
        return {
            'category': '',
            'category_id': category_id,
            'sub_category_id': sub_category_id,
            'brands': [],
            'price_bins': [],
            'sub_categories': [],
            'product_count': 0
        }

    if category_meta is not None:
        query = query.filter(Product.category == category_meta['name'])
    elif category:
        query = query.filter(Product.category == category)

    sub_category = None
    if sub_category_id:
        sub_category = find_sub_category(category_meta, sub_category_id)
        if sub_category is None:
            return {
                'category': category_meta['name'] if category_meta is not None else category,
                'category_id': category_id,
                'sub_category_id': sub_category_id,
                'brands': [],
                'price_bins': [],
                'sub_categories': [],
                'product_count': 0
            }
        query = apply_sub_category_filter(query, sub_category)

    products = dedupe_products(query.all())
    brand_counts: dict[str, int] = {}
    prices: list[float] = []

    for product in products:
        brand_name = infer_brand_from_title(product.name or '', product.brand or '')
        if brand_name:
            brand_counts[brand_name] = brand_counts.get(brand_name, 0) + 1
        if product.lowest_price > 0:
            prices.append(product.lowest_price)

    brands = [
        {'name': name, 'count': count}
        for name, count in sorted(brand_counts.items(), key=lambda item: (-item[1], item[0]))[:50]
    ]

    price_bins = []
    for label, min_value, max_value in PRICE_BINS:
        count = sum(1 for price in prices if price >= min_value and price <= max_value)
        if count > 0:
            price_bins.append({'label': label, 'min': min_value, 'max': max_value, 'count': count})

    sub_categories = []
    if category_meta is not None and not sub_category_id:
        category_products = dedupe_products(
            db.query(Product).filter(Product.category == category_meta['name']).all()
        )
        for item in category_meta['sub_categories']:
            count = sum(1 for product in category_products if product_matches_sub_category(product, item))
            if count > 0:
                sub_categories.append({'id': item['id'], 'name': item['name'], 'count': count})

    return {
        'category': category_meta['name'] if category_meta is not None else category,
        'category_id': category_meta['id'] if category_meta is not None else category_id,
        'sub_category_id': sub_category_id,
        'brands': brands,
        'price_bins': price_bins,
        'sub_categories': sub_categories,
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
        'brand': infer_brand_from_title(p.name or '', p.brand or ''),
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
