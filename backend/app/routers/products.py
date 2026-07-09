import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.models import PlatformListing, PriceHistory, Product
from app.schemas.product import ProductDetailResponse, ProductListResponse, ProductResponse

router = APIRouter()


def product_to_response(p: Product) -> ProductResponse:
    return ProductResponse(
        id=p.id,
        name=p.name,
        brand=p.brand,
        category=p.category,
        model_code=p.model_code or '',
        image_url=p.image_url,
        description=p.description,
        lowest_price=p.lowest_price,
        highest_price=p.highest_price,
        price_spread=p.price_spread,
        historical_low=p.historical_low,
        aggregate_rating=p.aggregate_rating,
        aggregate_score=p.aggregate_score,
        total_review_count=p.total_review_count,
        platform_count=len(p.listings) if p.listings else 0,
        publish_date=p.publish_date
    )


def _detail_price(product: Product) -> float:
    prices = [
        product.lowest_price or 0,
        product.highest_price or 0,
        product.historical_low or 0,
    ]
    return max(prices)


def _detail_listings(product: Product) -> list[dict]:
    listings = [
        {
            'platform': item.platform,
            'price': item.price,
            'rating': item.rating,
            'review_count': item.review_count,
            'in_stock': item.in_stock,
            'url': item.url
        }
        for item in product.listings
    ]
    if listings:
        return listings

    price = _detail_price(product)
    if price <= 0:
        return []
    return [{
        'platform': '\u5b9e\u65f6\u91c7\u96c6',
        'price': price,
        'rating': product.aggregate_rating or 4.0,
        'review_count': product.total_review_count or 0,
        'in_stock': True,
        'url': ''
    }]


def _detail_history(product: Product) -> list[dict]:
    history = [
        {'date': item.date, 'price': item.price}
        for item in sorted(product.price_history, key=lambda record: record.date)
    ]
    if history:
        return history

    current_price = _detail_price(product)
    if current_price <= 0:
        return []

    high_price = product.highest_price or current_price
    low_price = product.historical_low or current_price
    middle_price = round((high_price + current_price) / 2, 2)
    today = datetime.date.today()
    return [
        {
            'date': (today - datetime.timedelta(days=14)).strftime('%Y-%m-%d'),
            'price': low_price
        },
        {
            'date': (today - datetime.timedelta(days=7)).strftime('%Y-%m-%d'),
            'price': middle_price
        },
        {
            'date': today.strftime('%Y-%m-%d'),
            'price': current_price
        }
    ]


def _detail_specs(product: Product) -> list[dict]:
    specs: list[dict] = [
        {'key': '\u54c1\u724c', 'value': product.brand or ''},
        {'key': '\u54c1\u7c7b', 'value': product.category or ''}
    ]
    if product.model_code:
        specs.append({'key': '\u578b\u53f7', 'value': product.model_code})
    if product.publish_date:
        specs.append({'key': '\u91c7\u96c6\u65e5\u671f', 'value': product.publish_date})
    return specs


def _detail_tags(product: Product, listings: list[dict]) -> list[dict]:
    platform_count = len(listings)
    review_count = product.total_review_count or sum(
        item.get('review_count', 0) for item in listings
    )
    tags = [
        {'text': '\u53ef\u6bd4\u4ef7', 'type': 0, 'count': max(platform_count, 1)},
        {'text': '\u6709\u5b9e\u65f6\u4ef7\u683c', 'type': 0, 'count': max(platform_count, 1)}
    ]
    if review_count > 0:
        tags.append({'text': '\u6709\u8bc4\u4ef7\u6837\u672c', 'type': 0, 'count': review_count})
    if platform_count <= 1:
        tags.append({'text': '\u5e73\u53f0\u62a5\u4ef7\u504f\u5c11', 'type': 1, 'count': 1})
    return tags


@router.get('/products', response_model=ProductListResponse)
def get_products(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    category: str = Query(''),
    brand: str = Query(''),
    min_price: float = Query(0.0),
    max_price: float = Query(0.0),
    sort: str = Query('newest'),
    db: Session = Depends(get_db)
):
    query = db.query(Product)

    if category:
        query = query.filter(Product.category == category)
    if brand:
        brand_list = [item.strip() for item in brand.split(',') if item.strip()]
        if brand_list:
            query = query.filter(Product.brand.in_(brand_list))
    if min_price > 0:
        query = query.filter(Product.lowest_price >= min_price)
    if max_price > 0:
        query = query.filter(Product.lowest_price <= max_price)

    if sort == 'newest':
        query = query.order_by(Product.created_at.desc())
    elif sort == 'price_low':
        query = query.order_by(Product.lowest_price.asc())
    elif sort == 'rating':
        query = query.order_by(Product.aggregate_rating.desc())
    else:
        query = query.order_by(Product.aggregate_score.desc())

    total = query.count()
    items = query.offset((page - 1) * size).limit(size).all()

    return ProductListResponse(
        total=total,
        page=page,
        size=size,
        items=[product_to_response(p) for p in items]
    )


@router.get('/products/{product_id}', response_model=ProductDetailResponse)
def get_product_detail(product_id: str, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if product is None:
        raise HTTPException(status_code=404, detail='product not found')

    listings = _detail_listings(product)
    history = _detail_history(product)
    tags = _detail_tags(product, listings)

    return ProductDetailResponse(
        id=product.id,
        name=product.name,
        brand=product.brand,
        category=product.category,
        model_code=product.model_code or '',
        image_url=product.image_url,
        description=product.description,
        lowest_price=product.lowest_price,
        highest_price=product.highest_price,
        price_spread=product.price_spread,
        historical_low=product.historical_low,
        aggregate_rating=product.aggregate_rating,
        aggregate_score=product.aggregate_score,
        total_review_count=product.total_review_count,
        platform_count=len(product.listings),
        publish_date=product.publish_date,
        specs=_detail_specs(product),
        platform_listings=listings,
        price_history=history,
        review_tags=tags
    )


@router.get('/products/{product_id}/prices')
def get_product_prices(product_id: str, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if product is None:
        raise HTTPException(status_code=404, detail='product not found')

    return _detail_listings(product)


@router.get('/products/{product_id}/history')
def get_product_price_history(product_id: str, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if product is None:
        raise HTTPException(status_code=404, detail='product not found')

    return _detail_history(product)


@router.get('/categories')
def get_categories():
    return [
        {'id': 'cat1', 'name': '手机数码', 'icon': 'phone', 'sub_categories': [
            {'id': 'sub1', 'name': '智能手机'}, {'id': 'sub2', 'name': '平板电脑'}
        ]},
        {'id': 'cat2', 'name': '电脑办公', 'icon': 'computer', 'sub_categories': [
            {'id': 'sub3', 'name': '笔记本'}, {'id': 'sub4', 'name': '台式机'}
        ]},
        {'id': 'cat3', 'name': '家用电器', 'icon': 'home', 'sub_categories': [
            {'id': 'sub5', 'name': '空调'}, {'id': 'sub6', 'name': '冰箱'}
        ]},
        {'id': 'cat4', 'name': '美妆个护', 'icon': 'beauty', 'sub_categories': [
            {'id': 'sub7', 'name': '护肤'}, {'id': 'sub8', 'name': '彩妆'}
        ]},
        {'id': 'cat5', 'name': '服饰鞋包', 'icon': 'fashion', 'sub_categories': [
            {'id': 'sub9', 'name': '男装'}, {'id': 'sub10', 'name': '女装'}
        ]},
        {'id': 'cat6', 'name': '食品生鲜', 'icon': 'food', 'sub_categories': [
            {'id': 'sub11', 'name': '水果'}, {'id': 'sub12', 'name': '零食'}
        ]},
    ]
