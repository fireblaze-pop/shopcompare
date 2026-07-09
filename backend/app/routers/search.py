import os

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.brand_catalog import dedupe_products
from app.database import get_db
from app.models.models import Product
from app.schemas.product import ProductResponse
from app.routers.products import product_to_response

router = APIRouter()

AUTO_CRAWL_MIN_QUERY_LENGTH: int = 2
AUTO_CRAWL_RESULT_THRESHOLD: int = 3


def is_auto_crawler_enabled() -> bool:
    value: str = os.getenv('SHOPCOMPARE_DISABLE_CRAWLER', '').lower()
    return value not in ('1', 'true', 'yes')


def enqueue_search_crawl(keyword: str) -> bool:
    if not is_auto_crawler_enabled():
        return False

    normalized: str = keyword.strip()
    if len(normalized) < AUTO_CRAWL_MIN_QUERY_LENGTH:
        return False

    try:
        from crawler.bg_service import get_bg_service
        return get_bg_service().enqueue_keyword(normalized)
    except ImportError:
        return False


@router.get("/search")
def search_products(
    q: str = Query("", min_length=1),
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    query = db.query(Product).filter(
        (Product.name.contains(q)) |
        (Product.brand.contains(q)) |
        (Product.category.contains(q)) |
        (Product.description.contains(q))
    )

    all_items = dedupe_products(query.all())
    total = len(all_items)
    start = (page - 1) * size
    items = all_items[start:start + size]
    crawl_queued: bool = False
    if len(q.strip()) >= AUTO_CRAWL_MIN_QUERY_LENGTH and total < AUTO_CRAWL_RESULT_THRESHOLD:
        crawl_queued = enqueue_search_crawl(q)

    return {
        "total": total,
        "page": page,
        "size": size,
        "keyword": q,
        "crawl_queued": crawl_queued,
        "items": [product_to_response(p) for p in items]
    }
