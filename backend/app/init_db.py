import os

from app.database import Base, SessionLocal, engine
from app.models.models import PlatformListing, PriceHistory, Product, User

DEMO_PRODUCTS = [
    # 手机数码 (5)
    {'id': 'demo_phone_huawei', 'name': 'Huawei Mate 70 Pro', 'model_code': 'ALN-AL80', 'brand': '华为', 'category': '手机数码', 'lowest_price': 6999, 'highest_price': 7299, 'price_spread': 300, 'historical_low': 6599, 'aggregate_rating': 4.7, 'aggregate_score': 8.8, 'total_review_count': 23400, 'description': '华为旗舰手机', 'image_url': 'https://consumer.huawei.com/content/dam/huawei-cbg-site/common/mkt/pdp/phones/mate70-pro/list/list-img-black.png', 'publish_date': '2026-06-01'},
    {'id': 'demo_phone_apple', 'name': 'iPhone 16 Pro Max', 'model_code': 'MYW93CH/A', 'brand': 'Apple', 'category': '手机数码', 'lowest_price': 8999, 'highest_price': 9499, 'price_spread': 500, 'historical_low': 8499, 'aggregate_rating': 4.8, 'aggregate_score': 9.2, 'total_review_count': 15680, 'description': '苹果最新旗舰手机', 'image_url': 'https://store.storeimages.cdn-apple.com/8756/as-images.apple.com/is/iphone-16-pro-max-blacktitanium-select?wid=470&hei=556&fmt=png-alpha&.v=1722843844951', 'publish_date': '2026-06-01'},
    {'id': 'demo_phone_xiaomi', 'name': '小米 15 Pro', 'model_code': '23116PN5CC', 'brand': '小米', 'category': '手机数码', 'lowest_price': 4999, 'highest_price': 5299, 'price_spread': 300, 'historical_low': 4699, 'aggregate_rating': 4.6, 'aggregate_score': 8.6, 'total_review_count': 18900, 'description': '小米影像旗舰手机', 'image_url': '', 'publish_date': '2026-06-01'},
    {'id': 'demo_phone_samsung', 'name': '三星 Galaxy S25 Ultra', 'model_code': 'SM-S938B', 'brand': '三星', 'category': '手机数码', 'lowest_price': 8499, 'highest_price': 8899, 'price_spread': 400, 'historical_low': 7999, 'aggregate_rating': 4.5, 'aggregate_score': 8.7, 'total_review_count': 9800, 'description': '三星安卓机皇', 'image_url': '', 'publish_date': '2026-06-01'},
    {'id': 'demo_phone_airpods', 'name': 'AirPods Pro 3', 'model_code': 'MTV83CH/A', 'brand': 'Apple', 'category': '手机数码', 'lowest_price': 1899, 'highest_price': 2099, 'price_spread': 200, 'historical_low': 1699, 'aggregate_rating': 4.7, 'aggregate_score': 9.0, 'total_review_count': 34500, 'description': '主动降噪耳机', 'image_url': '', 'publish_date': '2026-06-01'},
    # 电脑办公 (5)
    {'id': 'demo_laptop_huawei', 'name': 'Huawei MateBook X Pro', 'model_code': 'MRG-AL00', 'brand': '华为', 'category': '电脑办公', 'lowest_price': 10999, 'highest_price': 11599, 'price_spread': 600, 'historical_low': 9999, 'aggregate_rating': 4.6, 'aggregate_score': 8.8, 'total_review_count': 6700, 'description': '华为轻薄商务本', 'image_url': 'https://consumer.huawei.com/content/dam/huawei-cbg-site/common/mkt/pdp/pc/matebook-x-pro-2024/list/list-img.png', 'publish_date': '2026-06-01'},
    {'id': 'demo_laptop_apple', 'name': 'MacBook Pro 14', 'model_code': 'MRX33CH/A', 'brand': 'Apple', 'category': '电脑办公', 'lowest_price': 14999, 'highest_price': 15999, 'price_spread': 1000, 'historical_low': 13999, 'aggregate_rating': 4.7, 'aggregate_score': 9.1, 'total_review_count': 8900, 'description': '苹果专业笔记本', 'image_url': '', 'publish_date': '2026-06-01'},
    {'id': 'demo_laptop_lenovo', 'name': 'ThinkPad X1 Carbon', 'model_code': '21HM0001CD', 'brand': '联想', 'category': '电脑办公', 'lowest_price': 9999, 'highest_price': 10799, 'price_spread': 800, 'historical_low': 9199, 'aggregate_rating': 4.5, 'aggregate_score': 8.5, 'total_review_count': 5600, 'description': '商务旗舰笔记本', 'image_url': '', 'publish_date': '2026-06-01'},
    {'id': 'demo_laptop_dell', 'name': '戴尔 U2723QE', 'model_code': 'U2723QE', 'brand': '戴尔', 'category': '电脑办公', 'lowest_price': 3499, 'highest_price': 3999, 'price_spread': 500, 'historical_low': 2999, 'aggregate_rating': 4.6, 'aggregate_score': 8.7, 'total_review_count': 7800, 'description': '4K专业显示器', 'image_url': '', 'publish_date': '2026-06-01'},
    {'id': 'demo_laptop_xiaomi_mnt', 'name': '小米 Redmi G Pro 显示器', 'model_code': 'REDMIG27Q', 'brand': '小米', 'category': '电脑办公', 'lowest_price': 1299, 'highest_price': 1499, 'price_spread': 200, 'historical_low': 1099, 'aggregate_rating': 4.4, 'aggregate_score': 8.2, 'total_review_count': 12300, 'description': '2K高刷电竞显示器', 'image_url': '', 'publish_date': '2026-06-01'},
    # 家用电器 (5)
    {'id': 'demo_app_dyson', 'name': '戴森 V15 吸尘器', 'model_code': 'SV48', 'brand': '戴森', 'category': '家用电器', 'lowest_price': 4990, 'highest_price': 5390, 'price_spread': 400, 'historical_low': 4590, 'aggregate_rating': 4.6, 'aggregate_score': 8.6, 'total_review_count': 12300, 'description': '无绳吸尘器旗舰款', 'image_url': '', 'publish_date': '2026-06-01'},
    {'id': 'demo_app_midea', 'name': '美的空调 1.5匹', 'model_code': 'KFR-35GW', 'brand': '美的', 'category': '家用电器', 'lowest_price': 2999, 'highest_price': 3199, 'price_spread': 200, 'historical_low': 2799, 'aggregate_rating': 4.4, 'aggregate_score': 8.3, 'total_review_count': 45600, 'description': '变频冷暖空调', 'image_url': '', 'publish_date': '2026-06-01'},
    {'id': 'demo_app_gree', 'name': '格力空调 1.5匹', 'model_code': 'KFR-35GW', 'brand': '格力', 'category': '家用电器', 'lowest_price': 3199, 'highest_price': 3499, 'price_spread': 300, 'historical_low': 2999, 'aggregate_rating': 4.5, 'aggregate_score': 8.5, 'total_review_count': 38900, 'description': '格力变频冷暖空调', 'image_url': '', 'publish_date': '2026-06-01'},
    {'id': 'demo_app_haier', 'name': '海尔冰箱 501L', 'model_code': 'BCD-501WDPR', 'brand': '海尔', 'category': '家用电器', 'lowest_price': 3299, 'highest_price': 3699, 'price_spread': 400, 'historical_low': 3099, 'aggregate_rating': 4.4, 'aggregate_score': 8.4, 'total_review_count': 25600, 'description': '海尔风冷无霜冰箱', 'image_url': '', 'publish_date': '2026-06-01'},
    {'id': 'demo_app_philips', 'name': '飞利浦剃须刀', 'model_code': 'S5079', 'brand': '飞利浦', 'category': '家用电器', 'lowest_price': 599, 'highest_price': 699, 'price_spread': 100, 'historical_low': 499, 'aggregate_rating': 4.5, 'aggregate_score': 8.3, 'total_review_count': 34500, 'description': '飞利浦电动剃须刀', 'image_url': '', 'publish_date': '2026-06-01'},
    # 美妆个护 (5)
    {'id': 'demo_beauty_lancome', 'name': '兰蔻小黑瓶', 'model_code': 'LAN001', 'brand': '兰蔻', 'category': '美妆个护', 'lowest_price': 1080, 'highest_price': 1280, 'price_spread': 200, 'historical_low': 880, 'aggregate_rating': 4.7, 'aggregate_score': 8.9, 'total_review_count': 67800, 'description': '经典肌底精华液', 'image_url': '', 'publish_date': '2026-06-01'},
    {'id': 'demo_beauty_esteelauder', 'name': '雅诗兰黛小棕瓶', 'model_code': 'EST001', 'brand': '雅诗兰黛', 'category': '美妆个护', 'lowest_price': 1280, 'highest_price': 1480, 'price_spread': 200, 'historical_low': 1080, 'aggregate_rating': 4.7, 'aggregate_score': 9.0, 'total_review_count': 56000, 'description': '雅诗兰黛修护精华', 'image_url': '', 'publish_date': '2026-06-01'},
    {'id': 'demo_beauty_skii', 'name': 'SK-II 神仙水', 'model_code': 'SKII001', 'brand': 'SK-II', 'category': '美妆个护', 'lowest_price': 1590, 'highest_price': 1890, 'price_spread': 300, 'historical_low': 1390, 'aggregate_rating': 4.8, 'aggregate_score': 9.1, 'total_review_count': 43000, 'description': 'SK-II护肤精华露', 'image_url': '', 'publish_date': '2026-06-01'},
    {'id': 'demo_beauty_loreal', 'name': '欧莱雅紫熨斗', 'model_code': 'LOR001', 'brand': '欧莱雅', 'category': '美妆个护', 'lowest_price': 399, 'highest_price': 499, 'price_spread': 100, 'historical_low': 329, 'aggregate_rating': 4.5, 'aggregate_score': 8.5, 'total_review_count': 78000, 'description': '欧莱雅抗老精华', 'image_url': '', 'publish_date': '2026-06-01'},
    {'id': 'demo_beauty_sephora', 'name': '丝芙兰保湿面膜', 'model_code': 'SEPH001', 'brand': '丝芙兰', 'category': '美妆个护', 'lowest_price': 149, 'highest_price': 199, 'price_spread': 50, 'historical_low': 99, 'aggregate_rating': 4.3, 'aggregate_score': 8.0, 'total_review_count': 23000, 'description': '丝芙兰补水面膜', 'image_url': '', 'publish_date': '2026-06-01'},
    # 服饰鞋包 (5)
    {'id': 'demo_fashion_nike', 'name': 'Nike Air Force 1', 'model_code': 'AF1-001', 'brand': 'Nike', 'category': '服饰鞋包', 'lowest_price': 799, 'highest_price': 949, 'price_spread': 150, 'historical_low': 649, 'aggregate_rating': 4.6, 'aggregate_score': 8.4, 'total_review_count': 23400, 'description': '经典空军一号板鞋', 'image_url': '', 'publish_date': '2026-06-01'},
    {'id': 'demo_fashion_adidas', 'name': 'Adidas Ultraboost', 'model_code': 'UB22-001', 'brand': 'Adidas', 'category': '服饰鞋包', 'lowest_price': 1299, 'highest_price': 1499, 'price_spread': 200, 'historical_low': 1099, 'aggregate_rating': 4.6, 'aggregate_score': 8.6, 'total_review_count': 18900, 'description': '阿迪达斯跑鞋旗舰', 'image_url': '', 'publish_date': '2026-06-01'},
    {'id': 'demo_fashion_levis', 'name': "Levi's 501 牛仔裤", 'model_code': '501-001', 'brand': "Levi's", 'category': '服饰鞋包', 'lowest_price': 599, 'highest_price': 749, 'price_spread': 150, 'historical_low': 449, 'aggregate_rating': 4.5, 'aggregate_score': 8.4, 'total_review_count': 27800, 'description': '李维斯经典直筒牛仔', 'image_url': '', 'publish_date': '2026-06-01'},
    {'id': 'demo_fashion_zara', 'name': 'Zara 风衣外套', 'model_code': 'ZA-CT001', 'brand': 'Zara', 'category': '服饰鞋包', 'lowest_price': 699, 'highest_price': 899, 'price_spread': 200, 'historical_low': 499, 'aggregate_rating': 4.2, 'aggregate_score': 8.0, 'total_review_count': 15600, 'description': 'Zara春秋风衣', 'image_url': '', 'publish_date': '2026-06-01'},
    {'id': 'demo_fashion_coach', 'name': 'Coach 男士钱包', 'model_code': 'COA-WL001', 'brand': 'Coach', 'category': '服饰鞋包', 'lowest_price': 899, 'highest_price': 1099, 'price_spread': 200, 'historical_low': 699, 'aggregate_rating': 4.4, 'aggregate_score': 8.5, 'total_review_count': 9800, 'description': 'Coach真皮短款钱包', 'image_url': '', 'publish_date': '2026-06-01'},
    # 食品生鲜 (5)
    {'id': 'demo_food_squirrel', 'name': '三只松鼠坚果礼盒', 'model_code': 'SZS-NUT01', 'brand': '三只松鼠', 'category': '食品生鲜', 'lowest_price': 168, 'highest_price': 218, 'price_spread': 50, 'historical_low': 128, 'aggregate_rating': 4.6, 'aggregate_score': 8.4, 'total_review_count': 56000, 'description': '三只松鼠每日坚果', 'image_url': '', 'publish_date': '2026-06-01'},
    {'id': 'demo_food_moutai', 'name': '茅台飞天 53度', 'model_code': 'MOUTAI-53', 'brand': '茅台', 'category': '食品生鲜', 'lowest_price': 2999, 'highest_price': 3499, 'price_spread': 500, 'historical_low': 2799, 'aggregate_rating': 4.9, 'aggregate_score': 9.3, 'total_review_count': 12000, 'description': '贵州茅台酱香白酒', 'image_url': '', 'publish_date': '2026-06-01'},
    {'id': 'demo_food_nongfu', 'name': '农夫山泉天然水', 'model_code': 'NFC-550', 'brand': '农夫山泉', 'category': '食品生鲜', 'lowest_price': 12, 'highest_price': 14, 'price_spread': 2, 'historical_low': 10, 'aggregate_rating': 4.5, 'aggregate_score': 8.2, 'total_review_count': 234000, 'description': '农夫山泉饮用天然水', 'image_url': '', 'publish_date': '2026-06-01'},
    {'id': 'demo_food_lppz', 'name': '良品铺子肉松饼', 'model_code': 'LPP-MSB01', 'brand': '良品铺子', 'category': '食品生鲜', 'lowest_price': 39, 'highest_price': 49, 'price_spread': 10, 'historical_low': 29, 'aggregate_rating': 4.5, 'aggregate_score': 8.3, 'total_review_count': 89000, 'description': '良品铺子肉松饼礼盒', 'image_url': '', 'publish_date': '2026-06-01'},
    {'id': 'demo_food_baicaowei', 'name': '百草味牛肉干', 'model_code': 'BCW-BJG01', 'brand': '百草味', 'category': '食品生鲜', 'lowest_price': 49, 'highest_price': 59, 'price_spread': 10, 'historical_low': 39, 'aggregate_rating': 4.4, 'aggregate_score': 8.2, 'total_review_count': 67000, 'description': '百草味五香牛肉干', 'image_url': '', 'publish_date': '2026-06-01'},
]

DEMO_LISTINGS = [
    {'product_id': 'demo_phone_huawei', 'platform': 'JD', 'price': 6999, 'rating': 4.6, 'review_count': 900, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_phone_huawei', 'platform': 'Tmall', 'price': 7299, 'rating': 4.5, 'review_count': 1500, 'in_stock': True, 'url': 'https://www.tmall.com/'},
    {'product_id': 'demo_phone_apple', 'platform': 'JD', 'price': 8999, 'rating': 4.5, 'review_count': 1200, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_phone_apple', 'platform': 'Tmall', 'price': 9499, 'rating': 4.3, 'review_count': 800, 'in_stock': True, 'url': 'https://www.tmall.com/'},
    {'product_id': 'demo_phone_xiaomi', 'platform': 'JD', 'price': 4999, 'rating': 4.5, 'review_count': 800, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_phone_xiaomi', 'platform': 'Tmall', 'price': 5299, 'rating': 4.3, 'review_count': 600, 'in_stock': True, 'url': 'https://www.tmall.com/'},
    {'product_id': 'demo_phone_samsung', 'platform': 'JD', 'price': 8499, 'rating': 4.4, 'review_count': 500, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_phone_samsung', 'platform': 'Tmall', 'price': 8899, 'rating': 4.2, 'review_count': 400, 'in_stock': True, 'url': 'https://www.tmall.com/'},
    {'product_id': 'demo_phone_airpods', 'platform': 'JD', 'price': 1899, 'rating': 4.6, 'review_count': 2000, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_phone_airpods', 'platform': 'Tmall', 'price': 2099, 'rating': 4.4, 'review_count': 1500, 'in_stock': True, 'url': 'https://www.tmall.com/'},
    {'product_id': 'demo_laptop_huawei', 'platform': 'JD', 'price': 10999, 'rating': 4.5, 'review_count': 600, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_laptop_huawei', 'platform': 'Tmall', 'price': 11599, 'rating': 4.3, 'review_count': 400, 'in_stock': True, 'url': 'https://www.tmall.com/'},
    {'product_id': 'demo_laptop_apple', 'platform': 'JD', 'price': 14999, 'rating': 4.6, 'review_count': 500, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_laptop_apple', 'platform': 'Tmall', 'price': 15999, 'rating': 4.4, 'review_count': 300, 'in_stock': True, 'url': 'https://www.tmall.com/'},
    {'product_id': 'demo_laptop_lenovo', 'platform': 'JD', 'price': 9999, 'rating': 4.4, 'review_count': 400, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_laptop_lenovo', 'platform': 'Tmall', 'price': 10799, 'rating': 4.2, 'review_count': 300, 'in_stock': True, 'url': 'https://www.tmall.com/'},
    {'product_id': 'demo_laptop_dell', 'platform': 'JD', 'price': 3499, 'rating': 4.5, 'review_count': 300, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_laptop_xiaomi_mnt', 'platform': 'JD', 'price': 1299, 'rating': 4.3, 'review_count': 200, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_app_dyson', 'platform': 'JD', 'price': 4990, 'rating': 4.5, 'review_count': 700, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_app_midea', 'platform': 'JD', 'price': 2999, 'rating': 4.3, 'review_count': 2000, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_app_gree', 'platform': 'JD', 'price': 3199, 'rating': 4.4, 'review_count': 1500, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_app_haier', 'platform': 'JD', 'price': 3299, 'rating': 4.3, 'review_count': 1000, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_app_philips', 'platform': 'JD', 'price': 599, 'rating': 4.4, 'review_count': 800, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_beauty_lancome', 'platform': 'JD', 'price': 1080, 'rating': 4.6, 'review_count': 3000, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_beauty_esteelauder', 'platform': 'JD', 'price': 1280, 'rating': 4.6, 'review_count': 2500, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_beauty_skii', 'platform': 'JD', 'price': 1590, 'rating': 4.7, 'review_count': 2000, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_beauty_loreal', 'platform': 'JD', 'price': 399, 'rating': 4.4, 'review_count': 1000, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_beauty_sephora', 'platform': 'JD', 'price': 149, 'rating': 4.2, 'review_count': 500, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_fashion_nike', 'platform': 'JD', 'price': 799, 'rating': 4.5, 'review_count': 1500, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_fashion_adidas', 'platform': 'JD', 'price': 1299, 'rating': 4.5, 'review_count': 800, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_fashion_levis', 'platform': 'JD', 'price': 599, 'rating': 4.4, 'review_count': 900, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_fashion_zara', 'platform': 'JD', 'price': 699, 'rating': 4.1, 'review_count': 400, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_fashion_coach', 'platform': 'JD', 'price': 899, 'rating': 4.3, 'review_count': 300, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_food_squirrel', 'platform': 'JD', 'price': 168, 'rating': 4.5, 'review_count': 3000, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_food_moutai', 'platform': 'JD', 'price': 2999, 'rating': 4.8, 'review_count': 500, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_food_nongfu', 'platform': 'JD', 'price': 12, 'rating': 4.4, 'review_count': 5000, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_food_lppz', 'platform': 'JD', 'price': 39, 'rating': 4.4, 'review_count': 2000, 'in_stock': True, 'url': 'https://www.jd.com/'},
    {'product_id': 'demo_food_baicaowei', 'platform': 'JD', 'price': 49, 'rating': 4.3, 'review_count': 1500, 'in_stock': True, 'url': 'https://www.jd.com/'},
]

DEMO_HISTORY = []
for p in DEMO_PRODUCTS:
    pid = p['id']
    hl = p['historical_low']
    lp = p['lowest_price']
    DEMO_HISTORY.append({'product_id': pid, 'date': '2026-06-01', 'price': hl + 200})
    DEMO_HISTORY.append({'product_id': pid, 'date': '2026-07-01', 'price': lp})


def seed() -> None:
    Base.metadata.create_all(bind=engine)
    seed_demo_products()
    seed_test_user()
    print('Seed data loaded.')


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
