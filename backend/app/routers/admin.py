import os
import threading
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from fastapi.responses import HTMLResponse
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.models import Alert, Favorite, PlatformListing, PriceHistory, Product
from app.product_scoring import compute_overall_score

router = APIRouter()


class AdminProductPayload(BaseModel):
    id: str = ''
    name: str
    brand: str
    category: str
    model_code: str = ''
    image_url: str = ''
    description: str = ''
    lowest_price: float = 0
    highest_price: float = 0
    price_spread: float = 0
    historical_low: float = 0
    total_review_count: int = 0
    publish_date: str = ''


class AdminListingPayload(BaseModel):
    platform: str
    price: float
    rating: float = 0
    review_count: int = 0
    in_stock: bool = True
    url: str = ''


def crawler_enabled() -> bool:
    value = os.getenv('SHOPCOMPARE_DISABLE_CRAWLER', '').lower()
    return value not in ('1', 'true', 'yes')


def crawler_disabled_status() -> dict:
    return {
        'running': False,
        'total_products': 0,
        'last_run': '',
        'last_count': 0,
        'last_error': 'crawler disabled',
        'interval_minutes': 0
    }


def get_service_or_none():
    if not crawler_enabled():
        return None
    from crawler.bg_service import get_bg_service

    return get_bg_service()


@router.get('/admin/status')
def admin_status():
    svc = get_service_or_none()
    if svc is None:
        return crawler_disabled_status()
    return svc.status()


@router.get('/admin/logs')
def admin_logs():
    svc = get_service_or_none()
    if svc is None:
        return {'logs': []}
    return {'logs': svc.logs[:50]}


@router.get('/admin/stats')
def admin_stats(db: Session = Depends(get_db)):
    platforms = db.query(
        PlatformListing.platform,
        func.count(PlatformListing.id)
    ).group_by(PlatformListing.platform).all()

    categories = db.query(
        Product.category,
        func.count(Product.id)
    ).group_by(Product.category).all()

    total_products = db.query(Product).count()

    return {
        'total_products': total_products,
        'by_platform': [{'platform': p[0], 'count': p[1]} for p in platforms],
        'by_category': [{'category': c[0], 'count': c[1]} for c in categories]
    }


@router.get('/admin/products/latest')
def admin_latest_products(db: Session = Depends(get_db)):
    products = db.query(Product).order_by(Product.created_at.desc()).limit(20).all()
    return {
        'products': [
            {
                'name': p.name,
                'platform': p.listings[0].platform if p.listings else '',
                'price': p.listings[0].price if p.listings else 0,
                'category': p.category,
                'created_at': p.created_at.strftime('%Y-%m-%d %H:%M') if p.created_at else ''
            }
            for p in products
        ]
    }


def _product_to_admin_dict(product: Product) -> dict:
    return {
        'id': product.id,
        'name': product.name,
        'model_code': product.model_code or '',
        'brand': product.brand,
        'category': product.category,
        'image_url': product.image_url or '',
        'description': product.description or '',
        'aggregate_score': product.aggregate_score or 0,
        'aggregate_rating': product.aggregate_rating or 0,
        'total_review_count': product.total_review_count or 0,
        'lowest_price': product.lowest_price or 0,
        'highest_price': product.highest_price or 0,
        'price_spread': product.price_spread or 0,
        'historical_low': product.historical_low or 0,
        'publish_date': product.publish_date or '',
        'created_at': product.created_at.strftime('%Y-%m-%d %H:%M:%S') if product.created_at else '',
        'listings': [
            {
                'id': item.id,
                'platform': item.platform,
                'price': item.price,
                'rating': item.rating,
                'review_count': item.review_count,
                'in_stock': item.in_stock,
                'url': item.url or '',
            }
            for item in product.listings
        ],
        'history_count': len(product.price_history),
    }


def _refresh_product_prices_and_score(db: Session, product: Product) -> None:
    listings = db.query(PlatformListing).filter(PlatformListing.product_id == product.id).all()
    prices = [item.price for item in listings if item.price > 0]
    if prices:
        product.lowest_price = min(prices)
        product.highest_price = max(prices)
        product.price_spread = product.highest_price - product.lowest_price
    elif product.lowest_price > 0:
        if product.highest_price <= 0:
            product.highest_price = product.lowest_price
        product.price_spread = max(0, product.highest_price - product.lowest_price)

    history = db.query(PriceHistory).filter(PriceHistory.product_id == product.id).all()
    history_prices = [item.price for item in history if item.price > 0]
    if history_prices:
        product.historical_low = min(history_prices)
    elif product.historical_low <= 0 and product.lowest_price > 0:
        product.historical_low = product.lowest_price

    category_products = db.query(Product).filter(Product.category == product.category).all()
    score = compute_overall_score(product, category_products, listings)
    product.aggregate_score = score
    product.aggregate_rating = score


@router.get('/admin/products')
def admin_list_products(
    q: str = Query(''),
    category: str = Query(''),
    brand: str = Query(''),
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    query = db.query(Product)
    keyword = q.strip()
    if keyword:
        query = query.filter(
            (Product.name.contains(keyword)) |
            (Product.brand.contains(keyword)) |
            (Product.category.contains(keyword)) |
            (Product.description.contains(keyword))
        )
    if category.strip():
        query = query.filter(Product.category == category.strip())
    if brand.strip():
        query = query.filter(Product.brand == brand.strip())

    total = query.count()
    products = query.order_by(Product.created_at.desc()).offset((page - 1) * size).limit(size).all()
    return {
        'total': total,
        'page': page,
        'size': size,
        'items': [_product_to_admin_dict(product) for product in products],
    }


@router.post('/admin/products')
def admin_create_product(payload: AdminProductPayload, db: Session = Depends(get_db)):
    product_id = payload.id.strip() or str(uuid.uuid4())[:16]
    existing = db.query(Product).filter(Product.id == product_id).first()
    if existing is not None:
        raise HTTPException(status_code=409, detail='product id already exists')

    product = Product(
        id=product_id,
        name=payload.name.strip(),
        model_code=payload.model_code.strip(),
        brand=payload.brand.strip(),
        category=payload.category.strip(),
        image_url=payload.image_url.strip(),
        description=payload.description.strip(),
        lowest_price=payload.lowest_price,
        highest_price=payload.highest_price,
        price_spread=payload.price_spread,
        historical_low=payload.historical_low,
        total_review_count=payload.total_review_count,
        publish_date=payload.publish_date.strip(),
    )
    if not product.name or not product.brand or not product.category:
        raise HTTPException(status_code=422, detail='name, brand and category are required')

    db.add(product)
    db.flush()
    _refresh_product_prices_and_score(db, product)
    db.commit()
    db.refresh(product)
    return {'product': _product_to_admin_dict(product)}


@router.get('/admin/products/{product_id}')
def admin_get_product(product_id: str, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if product is None:
        raise HTTPException(status_code=404, detail='product not found')
    return {'product': _product_to_admin_dict(product)}


@router.put('/admin/products/{product_id}')
def admin_update_product(product_id: str, payload: AdminProductPayload, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if product is None:
        raise HTTPException(status_code=404, detail='product not found')
    if not payload.name.strip() or not payload.brand.strip() or not payload.category.strip():
        raise HTTPException(status_code=422, detail='name, brand and category are required')

    product.name = payload.name.strip()
    product.model_code = payload.model_code.strip()
    product.brand = payload.brand.strip()
    product.category = payload.category.strip()
    product.image_url = payload.image_url.strip()
    product.description = payload.description.strip()
    product.lowest_price = payload.lowest_price
    product.highest_price = payload.highest_price
    product.price_spread = payload.price_spread
    product.historical_low = payload.historical_low
    product.total_review_count = payload.total_review_count
    product.publish_date = payload.publish_date.strip()

    _refresh_product_prices_and_score(db, product)
    db.commit()
    db.refresh(product)
    return {'product': _product_to_admin_dict(product)}


@router.delete('/admin/products/{product_id}')
def admin_delete_product(product_id: str, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if product is None:
        raise HTTPException(status_code=404, detail='product not found')

    db.query(PlatformListing).filter(PlatformListing.product_id == product_id).delete(synchronize_session=False)
    db.query(PriceHistory).filter(PriceHistory.product_id == product_id).delete(synchronize_session=False)
    db.query(Favorite).filter(Favorite.product_id == product_id).delete(synchronize_session=False)
    db.query(Alert).filter(Alert.product_id == product_id).delete(synchronize_session=False)
    db.delete(product)
    db.commit()
    return {'deleted': True, 'id': product_id}


@router.post('/admin/products/{product_id}/listings')
def admin_create_listing(product_id: str, payload: AdminListingPayload, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if product is None:
        raise HTTPException(status_code=404, detail='product not found')
    listing = PlatformListing(
        product_id=product_id,
        platform=payload.platform.strip(),
        price=payload.price,
        rating=payload.rating,
        review_count=payload.review_count,
        in_stock=payload.in_stock,
        url=payload.url.strip(),
    )
    if not listing.platform:
        raise HTTPException(status_code=422, detail='platform is required')
    db.add(listing)
    db.flush()
    _refresh_product_prices_and_score(db, product)
    db.commit()
    db.refresh(product)
    return {'product': _product_to_admin_dict(product)}


@router.put('/admin/listings/{listing_id}')
def admin_update_listing(listing_id: int, payload: AdminListingPayload, db: Session = Depends(get_db)):
    listing = db.query(PlatformListing).filter(PlatformListing.id == listing_id).first()
    if listing is None:
        raise HTTPException(status_code=404, detail='listing not found')
    listing.platform = payload.platform.strip()
    listing.price = payload.price
    listing.rating = payload.rating
    listing.review_count = payload.review_count
    listing.in_stock = payload.in_stock
    listing.url = payload.url.strip()
    if not listing.platform:
        raise HTTPException(status_code=422, detail='platform is required')
    product = db.query(Product).filter(Product.id == listing.product_id).first()
    if product is not None:
        _refresh_product_prices_and_score(db, product)
    db.commit()
    if product is not None:
        db.refresh(product)
        return {'product': _product_to_admin_dict(product)}
    return {'updated': True}


@router.delete('/admin/listings/{listing_id}')
def admin_delete_listing(listing_id: int, db: Session = Depends(get_db)):
    listing = db.query(PlatformListing).filter(PlatformListing.id == listing_id).first()
    if listing is None:
        raise HTTPException(status_code=404, detail='listing not found')
    product_id = listing.product_id
    db.delete(listing)
    product = db.query(Product).filter(Product.id == product_id).first()
    if product is not None:
        _refresh_product_prices_and_score(db, product)
    db.commit()
    if product is not None:
        db.refresh(product)
        return {'product': _product_to_admin_dict(product)}
    return {'deleted': True}


@router.post('/admin/crawler/run')
def admin_trigger_crawl():
    svc = get_service_or_none()
    if svc is None:
        return {'message': 'crawler disabled', 'status': 'disabled'}

    def run():
        svc._run_all()

    t = threading.Thread(target=run, daemon=True)
    t.start()
    return {'message': 'Crawl triggered', 'status': 'started'}


@router.get('/admin', response_class=HTMLResponse)
def admin_dashboard():
    template_path = os.path.join(os.path.dirname(__file__), '..', 'templates', 'admin_dashboard.html')
    with open(template_path, 'r', encoding='utf-8') as f:
        return f.read()
