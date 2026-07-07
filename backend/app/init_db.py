from app.database import engine, Base, SessionLocal
from app.models.models import Product, PlatformListing, PriceHistory, User
from app.services.auth_service import pwd_context

PRODUCTS = [
    {"id":"p1","name":"iPhone 16 Pro Max","model_code":"MYW93CH/A","brand":"Apple","category":"手机数码","lowest_price":8999, "highest_price":9499,"price_spread":500,"historical_low":8499,"aggregate_rating":4.8,"aggregate_score":9.2,"total_review_count":15680,"description":"苹果最新旗舰手机","image_url":"https://placehold.co/400x400/E3F2FD/007AFF?text=iPhone","publish_date":"2025-09-20"},
    {"id":"p2","name":"华为 Mate 70 Pro","model_code":"ALN-AL80","brand":"华为","category":"手机数码","lowest_price":6999,"highest_price":7299,"price_spread":300,"historical_low":6599,"aggregate_rating":4.7,"aggregate_score":8.8,"total_review_count":23400,"description":"华为旗舰手机","image_url":"https://placehold.co/400x400/FFF3E0/FF9800?text=Mate70","publish_date":"2025-10-10"},
    {"id":"p3","name":"MacBook Pro 14","model_code":"MRX33CH/A","brand":"Apple","category":"电脑办公","lowest_price":14999,"highest_price":15999,"price_spread":1000,"historical_low":13999,"aggregate_rating":4.7,"aggregate_score":9.1,"total_review_count":8900,"description":"苹果专业笔记本","image_url":"https://placehold.co/400x400/E8F5E9/4CAF50?text=MacBook","publish_date":"2025-11-01"},
    {"id":"p4","name":"ThinkPad X1 Carbon","model_code":"21HM0001CD","brand":"联想","category":"电脑办公","lowest_price":9999,"highest_price":10799,"price_spread":800,"historical_low":9199,"aggregate_rating":4.5,"aggregate_score":8.5,"total_review_count":5600,"description":"商务旗舰笔记本","image_url":"https://placehold.co/400x400/ECEFF1/607D8B?text=ThinkPad","publish_date":"2025-08-15"},
    {"id":"p5","name":"戴森 V15 吸尘器","model_code":"SV48","brand":"戴森","category":"家用电器","lowest_price":4990,"highest_price":5390,"price_spread":400,"historical_low":4590,"aggregate_rating":4.6,"aggregate_score":8.6,"total_review_count":12300,"description":"无绳吸尘器旗舰款","image_url":"https://placehold.co/400x400/F3E5F5/9C27B0?text=Dyson","publish_date":"2025-06-01"},
    {"id":"p6","name":"美的空调 1.5匹","model_code":"KFR-35GW","brand":"美的","category":"家用电器","lowest_price":2999,"highest_price":3199,"price_spread":200,"historical_low":2799,"aggregate_rating":4.4,"aggregate_score":8.3,"total_review_count":45600,"description":"变频冷暖空调","image_url":"https://placehold.co/400x400/E8EAF6/3F51B5?text=Midea","publish_date":"2025-05-20"},
    {"id":"p7","name":"兰蔻小黑瓶","model_code":"LAN001","brand":"兰蔻","category":"美妆个护","lowest_price":1080,"highest_price":1280,"price_spread":200,"historical_low":880,"aggregate_rating":4.7,"aggregate_score":8.9,"total_review_count":67800,"description":"经典肌底精华液","image_url":"https://placehold.co/400x400/FCE4EC/E91E63?text=Lancome","publish_date":"2025-01-10"},
    {"id":"p8","name":"Nike Air Force 1","model_code":"AF1-001","brand":"Nike","category":"服饰鞋包","lowest_price":799,"highest_price":949,"price_spread":150,"historical_low":649,"aggregate_rating":4.6,"aggregate_score":8.4,"total_review_count":23400,"description":"经典空军一号板鞋","image_url":"https://placehold.co/400x400/FFFDE7/FBC02D?text=Nike","publish_date":"2025-04-01"},
    {"id":"p9","name":"AirPods Pro 3","model_code":"MTV83CH/A","brand":"Apple","category":"手机数码","lowest_price":1899,"highest_price":2099,"price_spread":200,"historical_low":1699,"aggregate_rating":4.7,"aggregate_score":9.0,"total_review_count":34500,"description":"主动降噪耳机","image_url":"https://placehold.co/400x400/E0F7FA/00BCD4?text=AirPods","publish_date":"2025-09-15"},
    {"id":"p10","name":"戴尔 U2723QE","model_code":"U2723QE","brand":"戴尔","category":"电脑办公","lowest_price":3499,"highest_price":3999,"price_spread":500,"historical_low":2999,"aggregate_rating":4.6,"aggregate_score":8.7,"total_review_count":7800,"description":"4K专业显示器","image_url":"https://placehold.co/400x400/EFEBE9/795548?text=Dell","publish_date":"2025-07-01"},
    {"id":"p11","name":"三只松鼠每日坚果礼盒","model_code":"SZS-001","brand":"三只松鼠","category":"食品生鲜","lowest_price":128,"highest_price":168,"price_spread":40,"historical_low":118,"aggregate_rating":4.6,"aggregate_score":8.5,"total_review_count":56000,"description":"每日坚果30袋装","image_url":"https://imgservice3.suning.cn/uimg1/b2c/image/placeholder_food01.png","publish_date":"2025-08-01"},
    {"id":"p12","name":"贵州茅台飞天53度","model_code":"MT-001","brand":"茅台","category":"食品生鲜","lowest_price":2699,"highest_price":2999,"price_spread":300,"historical_low":2599,"aggregate_rating":4.9,"aggregate_score":9.5,"total_review_count":12000,"description":"酱香型白酒500ml","image_url":"https://imgservice3.suning.cn/uimg1/b2c/image/placeholder_food02.png","publish_date":"2025-06-15"},
    {"id":"p13","name":"伊利纯牛奶250ml*24","model_code":"YL-001","brand":"伊利","category":"食品生鲜","lowest_price":59,"highest_price":79,"price_spread":20,"historical_low":49,"aggregate_rating":4.5,"aggregate_score":8.2,"total_review_count":234000,"description":"纯牛奶整箱装","image_url":"https://imgservice3.suning.cn/uimg1/b2c/image/placeholder_food03.png","publish_date":"2025-09-01"},
    {"id":"p14","name":"百草味牛肉干500g","model_code":"BCW-001","brand":"百草味","category":"食品生鲜","lowest_price":39,"highest_price":59,"price_spread":20,"historical_low":29,"aggregate_rating":4.4,"aggregate_score":8.1,"total_review_count":89000,"description":"五香牛肉干零食","image_url":"https://imgservice3.suning.cn/uimg1/b2c/image/placeholder_food04.png","publish_date":"2025-07-20"},
    {"id":"p15","name":"西湖龙井明前特级","model_code":"LJ-001","brand":"西湖","category":"食品生鲜","lowest_price":288,"highest_price":388,"price_spread":100,"historical_low":258,"aggregate_rating":4.7,"aggregate_score":8.8,"total_review_count":15000,"description":"明前龙井绿茶250g","image_url":"https://imgservice3.suning.cn/uimg1/b2c/image/placeholder_food05.png","publish_date":"2025-04-01"},
]

PLATFORM_LISTINGS = [
    {"product_id": "p1", "platform": "京东", "price": 8999, "rating": 4.5, "review_count": 1200, "in_stock": True, "url": ""},
    {"product_id": "p1", "platform": "天猫", "price": 9499, "rating": 4.3, "review_count": 800, "in_stock": True, "url": ""},
    {"product_id": "p1", "platform": "拼多多", "price": 8799, "rating": 4.0, "review_count": 500, "in_stock": True, "url": ""},
    {"product_id": "p2", "platform": "京东", "price": 6999, "rating": 4.4, "review_count": 900, "in_stock": True, "url": ""},
    {"product_id": "p2", "platform": "天猫", "price": 7299, "rating": 4.5, "review_count": 1500, "in_stock": True, "url": ""},
    {"product_id": "p3", "platform": "京东", "price": 14999, "rating": 4.6, "review_count": 600, "in_stock": True, "url": ""},
    {"product_id": "p4", "platform": "京东", "price": 9999, "rating": 4.3, "review_count": 400, "in_stock": True, "url": ""},
    {"product_id": "p5", "platform": "京东", "price": 4990, "rating": 4.5, "review_count": 800, "in_stock": True, "url": ""},
    {"product_id": "p6", "platform": "京东", "price": 2999, "rating": 4.2, "review_count": 2000, "in_stock": True, "url": ""},
    {"product_id": "p7", "platform": "京东", "price": 1080, "rating": 4.7, "review_count": 3200, "in_stock": True, "url": ""},
    {"product_id": "p8", "platform": "京东", "price": 799, "rating": 4.5, "review_count": 1500, "in_stock": True, "url": ""},
    {"product_id": "p9", "platform": "京东", "price": 1899, "rating": 4.6, "review_count": 2200, "in_stock": True, "url": ""},
    {"product_id": "p10", "platform": "京东", "price": 3499, "rating": 4.4, "review_count": 500, "in_stock": True, "url": ""},
    {"product_id": "p11", "platform": "京东", "price": 128, "rating": 4.6, "review_count": 3200, "in_stock": True, "url": ""},
    {"product_id": "p11", "platform": "天猫", "price": 148, "rating": 4.5, "review_count": 2100, "in_stock": True, "url": ""},
    {"product_id": "p12", "platform": "京东", "price": 2699, "rating": 4.9, "review_count": 800, "in_stock": True, "url": ""},
    {"product_id": "p12", "platform": "天猫", "price": 2899, "rating": 4.8, "review_count": 600, "in_stock": True, "url": ""},
    {"product_id": "p13", "platform": "京东", "price": 59, "rating": 4.5, "review_count": 15000, "in_stock": True, "url": ""},
    {"product_id": "p14", "platform": "京东", "price": 39, "rating": 4.4, "review_count": 5600, "in_stock": True, "url": ""},
    {"product_id": "p15", "platform": "京东", "price": 288, "rating": 4.7, "review_count": 900, "in_stock": True, "url": ""},
]

PRICE_HISTORY = [
    # Each product gets 3 price points
    {"product_id": "p1", "date": "2025-12-01", "price": 9299}, {"product_id": "p1", "date": "2026-01-01", "price": 8999}, {"product_id": "p1", "date": "2026-06-01", "price": 8499},
    {"product_id": "p2", "date": "2025-12-01", "price": 7299}, {"product_id": "p2", "date": "2026-01-01", "price": 6999}, {"product_id": "p2", "date": "2026-06-01", "price": 6599},
    {"product_id": "p3", "date": "2025-12-01", "price": 15499}, {"product_id": "p3", "date": "2026-01-01", "price": 14999}, {"product_id": "p3", "date": "2026-06-01", "price": 13999},
    {"product_id": "p4", "date": "2025-12-01", "price": 10499}, {"product_id": "p4", "date": "2026-01-01", "price": 9999}, {"product_id": "p4", "date": "2026-06-01", "price": 9199},
    {"product_id": "p5", "date": "2025-12-01", "price": 5190}, {"product_id": "p5", "date": "2026-01-01", "price": 4990}, {"product_id": "p5", "date": "2026-06-01", "price": 4590},
    {"product_id": "p6", "date": "2025-12-01", "price": 3099}, {"product_id": "p6", "date": "2026-01-01", "price": 2999}, {"product_id": "p6", "date": "2026-06-01", "price": 2799},
    {"product_id": "p7", "date": "2025-12-01", "price": 1180}, {"product_id": "p7", "date": "2026-01-01", "price": 1080}, {"product_id": "p7", "date": "2026-06-01", "price": 880},
    {"product_id": "p8", "date": "2025-12-01", "price": 849}, {"product_id": "p8", "date": "2026-01-01", "price": 799}, {"product_id": "p8", "date": "2026-06-01", "price": 649},
    {"product_id": "p9", "date": "2025-12-01", "price": 1999}, {"product_id": "p9", "date": "2026-01-01", "price": 1899}, {"product_id": "p9", "date": "2026-06-01", "price": 1699},
    {"product_id": "p10", "date": "2025-12-01", "price": 3699}, {"product_id": "p10", "date": "2026-01-01", "price": 3499}, {"product_id": "p10", "date": "2026-06-01", "price": 2999},
]


def seed():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    try:
        if db.query(Product).count() > 0:
            print("数据库已有数据，跳过种子数据插入")
            return

        for p in PRODUCTS:
            product = Product(**p)
            db.add(product)

        for pl in PLATFORM_LISTINGS:
            listing = PlatformListing(**pl)
            db.add(listing)

        for ph in PRICE_HISTORY:
            history = PriceHistory(**ph)
            db.add(history)

        db.commit()
        print(f"种子数据导入完成: {len(PRODUCTS)} 件商品, {len(PLATFORM_LISTINGS)} 条价格, {len(PRICE_HISTORY)} 条历史")
    except Exception as e:
        db.rollback()
        print(f"种子数据导入失败: {e}")
    finally:
        db.close()


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == 'user':
        db = SessionLocal()
        user = db.query(User).filter(User.phone == '13800000000').first()
        if user is None:
            user = User(
                phone='13800000000',
                password_hash='$2b$12$kCQ.pqPnKU8SbQE4k2.1puaN/hivMW3n5YWBB9hpmvC..H1UkQWWK'
            )
            db.add(user)
            db.commit()
            print('测试账号已创建: 13800000000 / test123456')
        else:
            print('测试账号已存在: 13800000000 / test123456')
        db.close()
    else:
        seed()
