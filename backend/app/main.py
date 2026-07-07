from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.database import engine, Base
from app.routers import auth, products, search, prices, favorites, alerts, smart, behaviors
from crawler.bg_service import get_bg_service, BgCrawlerService

Base.metadata.create_all(bind=engine)


@asynccontextmanager
async def lifespan(app: FastAPI):
    svc: BgCrawlerService = get_bg_service()
    svc.start()
    yield
    svc.stop()


app = FastAPI(
    title='ShopCompare API',
    description='跨平台商品比价后端服务',
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

app.include_router(auth.router, prefix='/api/v1/auth', tags=['认证'])
app.include_router(products.router, prefix='/api/v1', tags=['商品'])
app.include_router(search.router, prefix='/api/v1', tags=['搜索'])
app.include_router(prices.router, prefix='/api/v1', tags=['价格'])
app.include_router(favorites.router, prefix='/api/v1', tags=['收藏'])
app.include_router(alerts.router, prefix='/api/v1', tags=['提醒'])
app.include_router(smart.router, prefix='/api/v1', tags=['智能推荐'])
app.include_router(behaviors.router, prefix='/api/v1', tags=['用户行为'])


@app.get('/')
def root():
    return {'name': 'ShopCompare API', 'version': '0.3.0'}


@app.get('/health')
def health():
    return {'status': 'ok'}


@app.get('/api/v1/crawler/status')
def crawler_status():
    svc: BgCrawlerService = get_bg_service()
    return svc.status()
