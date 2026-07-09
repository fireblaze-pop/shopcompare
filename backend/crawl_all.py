import sys
import os

backend_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, backend_dir)

from app.database import SessionLocal
from app.models.models import Product, PlatformListing, PriceHistory
from crawler.scheduler import run_sync


def main():
    print('=' * 50)
    print('  ShopCompare \u5168\u91CF\u722C\u53D6 v0.3')
    print('  \u6570\u636E\u6E90: \u6162\u6162\u4E70\u805A\u5408\u7AD9')
    print('=' * 50)
    print()

    db = SessionLocal()
    try:
        before_products = db.query(Product).count()
        before_listings = db.query(PlatformListing).count()
        print(f'\u722C\u53D6\u524D: {before_products} \u4EF6\u5546\u54C1, {before_listings} \u6761\u62A5\u4EF7')

        print('\n\u6B63\u5728\u722C\u53D6...\n')
        count = run_sync(db)

        after_products = db.query(Product).count()
        after_listings = db.query(PlatformListing).count()
        new_products = after_products - before_products
        new_listings = after_listings - before_listings

        print(f'\n\u722C\u53D6\u540E: {after_products} \u4EF6\u5546\u54C1, {after_listings} \u6761\u62A5\u4EF7')
        print(f'\u672C\u6B21\u65B0\u589E: {new_products} \u4EF6\u5546\u54C1, {new_listings} \u6761\u62A5\u4EF7')

        multi_count = db.query(Product).filter(
            Product.id.in_(
                db.query(PlatformListing.product_id)
                .group_by(PlatformListing.product_id)
                .having(PlatformListing.id >= PlatformListing.id)  # placeholder, will be replaced
            )
        ).count()

        multi_platform = db.query(PlatformListing.product_id).group_by(
            PlatformListing.product_id
        ).having(
            PlatformListing.product_id == PlatformListing.product_id
        ).count()

        tmp = db.execute(db.query(
            PlatformListing.product_id, PlatformListing.platform
        ).subquery()).fetchall()

        prod_platforms: dict[str, int] = {}
        for row in tmp:
            pid: str = row[0]
            if pid not in prod_platforms:
                prod_platforms[pid] = 0
            prod_platforms[pid] += 1

        multi = sum(1 for c in prod_platforms.values() if c >= 2)
        print(f'\u591A\u5E73\u53F0\u5546\u54C1: {multi}/{after_products}')

        products_with_images = db.query(Product).filter(
            Product.image_url != ''
        ).count()
        print(f'\u6709\u56FE\u7247\u5546\u54C1: {products_with_images}')

        if after_products >= 100:
            print('\n[OK] \u5546\u54C1\u6570\u91CF\u8FBE\u6807 (>=100)')
        else:
            print(f'\n[WARN] \u5546\u54C1\u6570\u91CF\u4E0D\u8DB3 ({after_products}/100)')
    except Exception as e:
        print(f'\n[ERROR] {e}')
        import traceback
        traceback.print_exc()
    finally:
        db.close()

    print('\n' + '=' * 50)
    print('  \u722C\u53D6\u5B8C\u6210')
    print('=' * 50)


if __name__ == '__main__':
    main()
