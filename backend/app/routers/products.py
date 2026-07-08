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


@router.get('/products', response_model=ProductListResponse)
def get_products(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    category: str = Query(''),
    brand: str = Query(''),
    min_price: float = Query(0.0),
    max_price: float = Query(0.0),
    sort: str = Query('recommend'),
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

    if sort == 'price_low':
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

    history = [
        {'date': item.date, 'price': item.price}
        for item in product.price_history
    ]

    tags = [
        {'text': 'quality', 'type': 1, 'count': 0},
        {'text': 'value', 'type': 1, 'count': 0}
    ]

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
        specs=[],
        platform_listings=listings,
        price_history=history,
        review_tags=tags
    )


@router.get('/products/{product_id}/prices')
def get_product_prices(product_id: str, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if product is None:
        raise HTTPException(status_code=404, detail='product not found')

    return [
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


@router.get('/products/{product_id}/history')
def get_product_price_history(product_id: str, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if product is None:
        raise HTTPException(status_code=404, detail='product not found')

    history = db.query(PriceHistory).filter(
        PriceHistory.product_id == product_id
    ).order_by(PriceHistory.date.asc()).all()

    return [{'date': item.date, 'price': item.price} for item in history]


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
