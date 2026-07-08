import os
import threading

from fastapi import APIRouter, Depends
from fastapi.responses import HTMLResponse
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.models import PlatformListing, Product

router = APIRouter()


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
