"""计算所有商品的六维评分并写入数据库。

评分维度（0-10分）：
  外观(10%)  + 物流(15%)  + 售后(15%)  + 品牌(20%)  + 性价比(25%)  + 品质(15%)
"""
import math
import sqlite3
import hashlib

KNOWN_BRANDS: list[str] = [
    'Apple', '华为', 'HUAWEI', '小米', 'Redmi', 'OPPO', 'vivo', '三星', 'Samsung',
    '荣耀', 'HONOR', '一加', 'OnePlus', 'realme', 'iQOO', '努比亚', '联想', 'Lenovo',
    '戴尔', 'Dell', '华硕', 'ASUS', '惠普', 'HP', '美的', '格力', '海尔', '戴森', 'Dyson',
    '飞利浦', 'Philips', '兰蔻', '雅诗兰黛', 'SK-II', '欧莱雅', 'Nike', 'Adidas',
    '茅台', '李宁', '安踏', '苏泊尔', '九阳', '科沃斯', '石头', '罗技', 'Logitech',
    '索尼', 'SONY', '松下', 'Panasonic', '摩托罗拉', 'Motorola',
    '漫步者', 'Edifier', 'JBL', 'BOSE', 'Beats', '魔声', 'Monster',
    '爱国者', 'SHOKZ', '韶音', '红魔'
]


def seed_score(name: str, product_id: str) -> float:
    """为每个商品生成基于其ID的确定性基础分，用于打破平局"""
    h = hashlib.md5((name + product_id).encode()).hexdigest()
    val = int(h[:8], 16) % 4000
    return 4.0 + val / 1000.0


def compute_scores(db_path: str) -> None:
    conn = sqlite3.connect(db_path)
    c = conn.cursor()

    c.execute("SELECT id, name, brand, image_url, lowest_price, historical_low, price_spread FROM products")
    products = c.fetchall()
    print(f'Products to score: {len(products)}')

    updated: int = 0
    for pid, name, brand, image_url, lowest_price, historical_low, price_spread in products:
        # 1. 外观 (10%): 有图片 7-9, 无图片 3-5
        if image_url and len(image_url) > 10:
            appearance = 7.0 + seed_score(name, pid + 'a') / 5  # 7.0-9.0
        else:
            appearance = 3.0 + seed_score(name, pid + 'a') / 5  # 3.0-5.0
        appearance = max(0, min(10, appearance))

        # 2. 物流 (15%): 基于评价数的对数 (proxy)
        c.execute("SELECT COALESCE(SUM(review_count), 0) FROM platform_listings WHERE product_id = ?", (pid,))
        review_total: int = c.fetchone()[0]
        if review_total > 0:
            logistics = math.log10(review_total + 1) / math.log10(100001) * 10
        else:
            logistics = 4.0
        logistics = max(2, min(10, logistics))

        # 3. 售后 (15%): 平台数越多 = 售后覆盖越好
        c.execute("SELECT COUNT(*) FROM platform_listings WHERE product_id = ?", (pid,))
        platform_count: int = c.fetchone()[0]
        after_sales = min(platform_count * 2.5, 10)
        after_sales = max(2, after_sales)

        # 4. 品牌 (20%): 有品牌 + 知名品牌加分
        if brand:
            brand_score = 5.0
            for kb in KNOWN_BRANDS:
                if kb.lower() in brand.lower():
                    brand_score = 7.0 + seed_score(brand, pid + 'b') / 5
                    break
        else:
            brand_score = 3.0
        brand_score = max(2, min(10, brand_score))

        # 5. 性价比 (25%): 价格差越大 / 历史低价越低 = 性价比越好
        if lowest_price > 0 and historical_low > 0 and price_spread > 0:
            discount_ratio = (1.0 - historical_low / lowest_price)
            spread_ratio = min(price_spread / lowest_price, 0.5)
            cost_perf = 5.0 + discount_ratio * 3.0 + spread_ratio * 4.0
        elif lowest_price > 0 and historical_low > 0:
            discount_ratio = (1.0 - historical_low / lowest_price)
            cost_perf = 5.0 + discount_ratio * 3.0
        else:
            cost_perf = 5.0  # no price data → neutral
        cost_perf = max(2, min(10, cost_perf))

        # 6. 品质 (15%): 基于 rating
        c.execute("SELECT COALESCE(AVG(rating), 0) FROM platform_listings WHERE product_id = ?", (pid,))
        avg_rating: float = c.fetchone()[0]
        if avg_rating > 0:
            quality = avg_rating * 2.0  # 0-5 → 0-10
        else:
            quality = 4.5 + seed_score(name, pid + 'q') / 5  # 4.5-6.5
        quality = max(2, min(10, quality))

        # 加权总分
        score = (
            appearance * 0.10 +
            logistics * 0.15 +
            after_sales * 0.15 +
            brand_score * 0.20 +
            cost_perf * 0.25 +
            quality * 0.15
        )

        c.execute("UPDATE products SET aggregate_score = ?, aggregate_rating = ? WHERE id = ?",
                  (round(score, 1), round(score, 1), pid))
        updated += 1

    conn.commit()
    print(f'Updated {updated} products')

    # Show distribution
    c.execute("SELECT ROUND(aggregate_score, -1), COUNT(*) FROM products GROUP BY 1 ORDER BY 1")
    print('Score distribution:')
    for r in c.fetchall():
        print(f'  {r[0]:.0f}: {r[1]}')

    conn.close()


if __name__ == '__main__':
    compute_scores('shopcompare.db')
