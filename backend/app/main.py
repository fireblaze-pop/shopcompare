import os
import threading
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, SessionLocal, engine
from app.routers import admin, alerts, auth, behaviors, favorites, prices, products, search, smart

Base.metadata.create_all(bind=engine)


def crawler_enabled() -> bool:
    value = os.getenv('SHOPCOMPARE_DISABLE_CRAWLER', '').lower()
    return value not in ('1', 'true', 'yes')


def crawler_available() -> bool:
    try:
        from crawler.bg_service import get_bg_service  # noqa: F401
        return True
    except ImportError:
        return False


def crawler_disabled_status() -> dict:
    if not crawler_enabled():
        return {
            'running': False, 'total_products': 0,
            'last_run': '', 'last_count': 0,
            'last_error': 'crawler disabled', 'interval_minutes': 0
        }
    return {
        'running': False, 'total_products': 0,
        'last_run': '', 'last_count': 0,
        'last_error': 'scrapling not installed. pip install scrapling[fetchers]',
        'interval_minutes': 0
    }


@asynccontextmanager
async def lifespan(app: FastAPI):
    svc = None
    if crawler_enabled() and crawler_available():
        from crawler.bg_service import get_bg_service
        from crawler.scheduler import run_sync

        svc = get_bg_service()
        svc.start()

        def delayed_first_crawl():
            time.sleep(3)
            db = SessionLocal()
            try:
                run_sync(db)
            finally:
                db.close()

        threading.Thread(target=delayed_first_crawl, daemon=True).start()
    try:
        yield
    finally:
        if svc is not None:
            svc.stop()


app = FastAPI(
    title='ShopCompare API',
    description='ShopCompare backend service',
    version='0.3.0',
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)

app.include_router(auth.router, prefix='/api/v1/auth', tags=['auth'])
app.include_router(products.router, prefix='/api/v1', tags=['products'])
app.include_router(search.router, prefix='/api/v1', tags=['search'])
app.include_router(prices.router, prefix='/api/v1', tags=['prices'])
app.include_router(favorites.router, prefix='/api/v1', tags=['favorites'])
app.include_router(alerts.router, prefix='/api/v1', tags=['alerts'])
app.include_router(smart.router, prefix='/api/v1', tags=['smart'])
app.include_router(behaviors.router, prefix='/api/v1', tags=['behaviors'])
app.include_router(admin.router, prefix='/api/v1', tags=['admin'])


@app.get('/')
def root():
    return {'name': 'ShopCompare API', 'version': '0.3.0'}


@app.get('/health')
def health():
    return {'status': 'ok'}


@app.get('/api/v1/health')
def api_health():
    return health()


@app.get('/api/v1/crawler/status')
def crawler_status():
    if not crawler_enabled():
        return crawler_disabled_status()

    from crawler.bg_service import get_bg_service

    svc = get_bg_service()
    return svc.status()


@app.post('/api/v1/crawler/run')
def crawler_run():
    if not crawler_enabled():
        return {'success': False, 'error': 'crawler disabled'}

    from crawler.scheduler import run_sync

    db = SessionLocal()
    try:
        count = run_sync(db)
        return {'success': True, 'count': count}
    except Exception as e:
        return {'success': False, 'error': str(e)}
    finally:
        db.close()
