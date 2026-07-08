import os

from app.database import Base, SessionLocal, engine
from app.models.models import PlatformListing, PriceHistory, Product, User

DEMO_PRODUCTS = [
    {
        'id': 'demo_phone_huawei',
        'name': 'Huawei Mate 70 Pro',
        'model_code': 'ALN-AL80',
        'brand': '\u534e\u4e3a',
        'category': '\u624b\u673a\u6570\u7801',
        'lowest_price': 6999,
        'highest_price': 7299,
        'price_spread': 300,
        'historical_low': 6599,
        'aggregate_rating': 4.7,
        'aggregate_score': 8.8,
        'total_review_count': 23400,
        'description': 'Demo product for local development.',
        'image_url': 'https://consumer.huawei.com/content/dam/huawei-cbg-site/common/mkt/pdp/phones/mate70-pro/list/list-img-black.png',
        'publish_date': '2026-06-01',
    },
    {
        'id': 'demo_phone_apple',
        'name': 'iPhone 16 Pro Max',
        'model_code': 'MYW93CH/A',
        'brand': 'Apple',
        'category': '\u624b\u673a\u6570\u7801',
        'lowest_price': 8999,
        'highest_price': 9499,
        'price_spread': 500,
        'historical_low': 8499,
        'aggregate_rating': 4.8,
        'aggregate_score': 9.2,
        'total_review_count': 15680,
        'description': 'Demo product for local development.',
        'image_url': 'https://store.storeimages.cdn-apple.com/8756/as-images.apple.com/is/iphone-16-pro-max-blacktitanium-select?wid=470&hei=556&fmt=png-alpha&.v=1722843844951',
        'publish_date': '2026-06-01',
    },
    {
        'id': 'demo_laptop_huawei',
        'name': 'Huawei MateBook X Pro',
        'model_code': 'MRG-AL00',
        'brand': '\u534e\u4e3a',
        'category': '\u7535\u8111\u529e\u516c',
        'lowest_price': 10999,
        'highest_price': 11599,
        'price_spread': 600,
        'historical_low': 9999,
        'aggregate_rating': 4.6,
        'aggregate_score': 8.8,
        'total_review_count': 6700,
        'description': 'Demo product for local development.',
        'image_url': 'https://consumer.huawei.com/content/dam/huawei-cbg-site/common/mkt/pdp/pc/matebook-x-pro-2024/list/list-img.png',
        'publish_date': '2026-06-01',
    },
]

DEMO_LISTINGS = [
    {'product_id': 'demo_phone_huawei', 'platform': 'JD', 'price': 6999, 'rating': 4.6, 'review_count': 900, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_phone_huawei', 'platform': 'Tmall', 'price': 7299, 'rating': 4.5, 'review_count': 1500, 'in_stock': True, 'url': 'https://www.tmall.com/'},
    {'product_id': 'demo_phone_apple', 'platform': 'JD', 'price': 8999, 'rating': 4.5, 'review_count': 1200, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_phone_apple', 'platform': 'Tmall', 'price': 9499, 'rating': 4.3, 'review_count': 800, 'in_stock': True, 'url': 'https://www.tmall.com/'},
    {'product_id': 'demo_laptop_huawei', 'platform': 'JD', 'price': 10999, 'rating': 4.5, 'review_count': 600, 'in_stock': True, 'url': 'https://www.jd.com/'},
]

DEMO_HISTORY = [
    {'product_id': 'demo_phone_huawei', 'date': '2026-06-01', 'price': 7299},
    {'product_id': 'demo_phone_huawei', 'date': '2026-07-01', 'price': 6999},
    {'product_id': 'demo_phone_apple', 'date': '2026-06-01', 'price': 9299},
    {'product_id': 'demo_phone_apple', 'date': '2026-07-01', 'price': 8999},
    {'product_id': 'demo_laptop_huawei', 'date': '2026-06-01', 'price': 11599},
    {'product_id': 'demo_laptop_huawei', 'date': '2026-07-01', 'price': 10999},
]


def seed() -> None:
    Base.metadata.create_all(bind=engine)
    if os.getenv('SHOPCOMPARE_ENABLE_DEMO_SEED', '').lower() in ('1', 'true', 'yes'):
        seed_demo_products()
    else:
        print('Runtime product seed disabled. Use SHOPCOMPARE_ENABLE_DEMO_SEED=1 or app.init_db demo for demo data.')


def seed_demo_products() -> None:
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        for item in DEMO_PRODUCTS:
            if db.query(Product).filter(Product.id == item['id']).first() is None:
                db.add(Product(**item))
        for item in DEMO_LISTINGS:
            exists = db.query(PlatformListing).filter(
                PlatformListing.product_id == item['product_id'],
                PlatformListing.platform == item['platform']
            ).first()
            if exists is None:
                db.add(PlatformListing(**item))
        for item in DEMO_HISTORY:
            exists = db.query(PriceHistory).filter(
                PriceHistory.product_id == item['product_id'],
                PriceHistory.date == item['date'],
                PriceHistory.price == item['price']
            ).first()
            if exists is None:
                db.add(PriceHistory(**item))
        db.commit()
        print(f'Demo seed inserted: {len(DEMO_PRODUCTS)} products')
    except Exception as exc:
        db.rollback()
        print(f'Demo seed failed: {exc}')
        raise
    finally:
        db.close()


def seed_test_user() -> None:
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.phone == '13800000000').first()
        if user is None:
            user = User(
                phone='13800000000',
                password_hash='$2b$12$kCQ.pqPnKU8SbQE4k2.1puaN/hivMW3n5YWBB9hpmvC..H1UkQWWK'
            )
            db.add(user)
            db.commit()
            print('Test user created: 13800000000 / test123456')
        else:
            print('Test user already exists: 13800000000 / test123456')
    finally:
        db.close()


if __name__ == '__main__':
    import sys

    if len(sys.argv) > 1 and sys.argv[1] == 'user':
        seed_test_user()
    elif len(sys.argv) > 1 and sys.argv[1] == 'demo':
        seed_demo_products()
    else:
        seed()
