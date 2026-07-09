import os
import sys

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

os.environ['SHOPCOMPARE_DISABLE_CRAWLER'] = '1'
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.database import Base, get_db
from app.main import app
from app.models.models import PlatformListing, PriceHistory, Product

TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "sqlite:///./test_shopcompare.db",
)

_engine_kwargs = {}
if TEST_DATABASE_URL.startswith("sqlite"):
    _engine_kwargs["connect_args"] = {"check_same_thread": False}

engine = create_engine(TEST_DATABASE_URL, **_engine_kwargs)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


def seed_test_products() -> None:
    db = TestingSessionLocal()
    try:
        products = [
            Product(id='p1', name='iPhone 16 Pro Max', model_code='MYW93CH/A', brand='Apple', category='手机数码', image_url='https://store.storeimages.cdn-apple.com/8756/as-images.apple.com/is/iphone-16-pro-max-blacktitanium-select?wid=470&hei=556&fmt=png-alpha&.v=1722843844951', description='test product', aggregate_score=9.2, aggregate_rating=4.8, total_review_count=15680, lowest_price=8999, highest_price=9499, price_spread=500, historical_low=8499, publish_date='2026-06-01'),
            Product(id='p2', name='Huawei Mate 70 Pro', model_code='ALN-AL80', brand='华为', category='手机数码', image_url='https://consumer.huawei.com/content/dam/huawei-cbg-site/common/mkt/pdp/phones/mate70-pro/list/list-img-black.png', description='test product', aggregate_score=8.8, aggregate_rating=4.7, total_review_count=23400, lowest_price=6999, highest_price=7299, price_spread=300, historical_low=6599, publish_date='2026-06-01'),
            Product(id='p3', name='MacBook Pro 14', model_code='MRX33CH/A', brand='Apple', category='电脑办公', image_url='https://store.storeimages.cdn-apple.com/8756/as-images.apple.com/is/mbp14-spaceblack-select-202410?wid=904&hei=840&fmt=jpeg&qlt=90&.v=1728916305295', description='test product', aggregate_score=9.1, aggregate_rating=4.7, total_review_count=8900, lowest_price=14999, highest_price=15999, price_spread=1000, historical_low=13999, publish_date='2026-06-01'),
            Product(id='p4', name='ThinkPad X1 Carbon', model_code='21HM0001CD', brand='Lenovo', category='电脑办公', image_url='https://p1-ofp.static.pub/fes/cms/2024/01/04/7csuwvx9knx6azt7eqzzcrl2jo6l4e263340.png', description='test product', aggregate_score=8.5, aggregate_rating=4.5, total_review_count=5600, lowest_price=9999, highest_price=10799, price_spread=800, historical_low=9199, publish_date='2026-06-01'),
            Product(id='p5', name='Dyson V15 Detect', model_code='SV48', brand='Dyson', category='家用电器', image_url='https://dyson-h.assetsadobe2.com/is/image/content/dam/dyson/images/products/primary/447921-01.png', description='test product', aggregate_score=8.6, aggregate_rating=4.6, total_review_count=12300, lowest_price=4990, highest_price=5390, price_spread=400, historical_low=4590, publish_date='2026-06-01'),
            Product(id='p6', name='Midea Air Conditioner', model_code='KFR-35GW', brand='Midea', category='家用电器', image_url='https://www.midea.com/content/dam/midea-aem/global/air-conditioners/split-ac/products/wall-mounted-ac.png', description='test product', aggregate_score=8.3, aggregate_rating=4.4, total_review_count=45600, lowest_price=2999, highest_price=3199, price_spread=200, historical_low=2799, publish_date='2026-06-01'),
            Product(id='p7', name='Nike Air Force 1', model_code='AF1-001', brand='Nike', category='服饰鞋包', image_url='https://static.nike.com/a/images/t_PDP_1728_v1/f_auto,q_auto:eco/e5d64e1b-3b8c-4f9c-83af-374b5e5a4491/air-force-1-07-shoes.png', description='test product', aggregate_score=8.4, aggregate_rating=4.6, total_review_count=23400, lowest_price=799, highest_price=949, price_spread=150, historical_low=649, publish_date='2026-06-01'),
            Product(id='p8', name='AirPods Pro 3', model_code='MTV83CH/A', brand='Apple', category='手机数码', image_url='https://store.storeimages.cdn-apple.com/8756/as-images.apple.com/is/airpods-pro-2-hero-select-202409?wid=976&hei=916&fmt=jpeg&qlt=90&.v=1724041669458', description='test product', aggregate_score=9.0, aggregate_rating=4.7, total_review_count=34500, lowest_price=1899, highest_price=2099, price_spread=200, historical_low=1699, publish_date='2026-06-01'),
            Product(id='p9', name='Dell U2723QE', model_code='U2723QE', brand='Dell', category='电脑办公', image_url='https://i.dell.com/is/image/DellContent/content/dam/ss2/product-images/peripherals/output-devices/dell/monitors/u2723qe/media-gallery/monitor-u2723qe-black-gallery-1.psd?fmt=png-alpha', description='test product', aggregate_score=8.7, aggregate_rating=4.6, total_review_count=7800, lowest_price=3499, highest_price=3999, price_spread=500, historical_low=2999, publish_date='2026-06-01'),
            Product(id='p10', name='Huawei MateBook X Pro', model_code='MRG-AL00', brand='华为', category='电脑办公', image_url='https://consumer.huawei.com/content/dam/huawei-cbg-site/common/mkt/pdp/pc/matebook-x-pro-2024/list/list-img.png', description='test product', aggregate_score=8.8, aggregate_rating=4.6, total_review_count=6700, lowest_price=10999, highest_price=11599, price_spread=600, historical_low=9999, publish_date='2026-06-01'),
        ]
        db.add_all(products)
        listings = [
            PlatformListing(product_id='p1', platform='JD', price=8999, rating=4.5, review_count=1200, in_stock=True, url='https://www.jd.com/'),
            PlatformListing(product_id='p1', platform='Tmall', price=9499, rating=4.3, review_count=800, in_stock=True, url='https://www.tmall.com/'),
            PlatformListing(product_id='p2', platform='JD', price=6999, rating=4.4, review_count=900, in_stock=True, url='https://www.jd.com/'),
            PlatformListing(product_id='p2', platform='Tmall', price=7299, rating=4.5, review_count=1500, in_stock=True, url='https://www.tmall.com/'),
            PlatformListing(product_id='p3', platform='JD', price=14999, rating=4.6, review_count=600, in_stock=True, url='https://www.jd.com/'),
            PlatformListing(product_id='p4', platform='JD', price=9999, rating=4.3, review_count=400, in_stock=True, url='https://www.jd.com/'),
            PlatformListing(product_id='p5', platform='JD', price=4990, rating=4.5, review_count=800, in_stock=True, url='https://www.jd.com/'),
            PlatformListing(product_id='p6', platform='JD', price=2999, rating=4.2, review_count=2000, in_stock=True, url='https://www.jd.com/'),
            PlatformListing(product_id='p7', platform='JD', price=799, rating=4.5, review_count=1500, in_stock=True, url='https://www.jd.com/'),
            PlatformListing(product_id='p8', platform='JD', price=1899, rating=4.6, review_count=2200, in_stock=True, url='https://www.jd.com/'),
            PlatformListing(product_id='p9', platform='JD', price=3499, rating=4.4, review_count=500, in_stock=True, url='https://www.jd.com/'),
            PlatformListing(product_id='p10', platform='JD', price=10999, rating=4.5, review_count=600, in_stock=True, url='https://www.jd.com/'),
        ]
        db.add_all(listings)
        for product in products:
            db.add(PriceHistory(product_id=product.id, date='2026-06-01', price=product.historical_low))
            db.add(PriceHistory(product_id=product.id, date='2026-07-01', price=product.lowest_price))
        db.commit()
    finally:
        db.close()


@pytest.fixture(autouse=True)
def setup_db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    seed_test_products()
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c


@pytest.fixture
def db_session():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture
def auth_token(client):
    phone = '13800138001'
    client.post('/api/v1/auth/send-code', json={'phone': phone})
    client.post('/api/v1/auth/register', json={
        'phone': phone,
        'code': '123456',
        'password': 'test123456'
    })
    resp = client.post('/api/v1/auth/login', json={
        'phone': phone,
        'password': 'test123456',
        'login_type': 'password'
    })
    return resp.json()['access_token']


@pytest.fixture
def auth_headers(auth_token):
    return {'Authorization': f'Bearer {auth_token}'}
