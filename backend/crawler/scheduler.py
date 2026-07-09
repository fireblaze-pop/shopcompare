import datetime
import re
from typing import Optional
from sqlalchemy.orm import Session
from app.database import get_db
from crawler.sources.manmanbuy_search import ManmanbuyCrawler, CATEGORY_MAP, SEARCH_KEYWORDS
from crawler.pipeline.writer import save_raw_product, normalize_name


def _group_by_name(items: list[dict]) -> list[list[dict]]:
    groups: dict[str, list[dict]] = {}
    for item in items:
        key: str = normalize_name(item.get('name', ''))
        if len(key) < 3:
            continue
        if key not in groups:
            groups[key] = []
        groups[key].append(item)
    result: list[list[dict]] = []
    for key in groups:
        group: list[dict] = groups[key]
        if len(group) >= 1:
            result.append(group)
    return result


def run_sync(db: Session) -> int:
    print(f'[{datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}] Crawler started (Manmanbuy aggregator)')
    total_products: int = 0
    total_listings: int = 0
    total_errors: int = 0

    crawler = ManmanbuyCrawler(min_delay=1.0, max_delay=2.0)

    for keyword in SEARCH_KEYWORDS:
        all_items: list[dict] = []
        for page in range(1, 6):
            try:
                products = crawler.search(keyword, page=page)
                all_items.extend(products)
                if len(products) == 0:
                    break
            except Exception as e:
                print(f'  [{keyword}] page={page} error: {e}')
                total_errors += 1

        if len(all_items) == 0:
            continue

        groups = _group_by_name(all_items)
        saved_products: int = 0
        saved_listings: int = 0

        for group in groups:
            first: dict = group[0]
            first['platform'] = first.get('platform', '\u4EAC\u4E1C')
            product_id: Optional[str] = save_raw_product(db, first)
            if product_id is not None:
                saved_products += 1
                saved_listings += 1

            i: int = 1
            while i < len(group):
                item: dict = group[i]
                pid: Optional[str] = save_raw_product(db, item)
                if pid is not None:
                    saved_listings += 1
                i += 1

        multi_count: int = sum(1 for g in groups if len(g) > 1)
        print(f'  [{keyword}] {len(all_items)} items -> {saved_products} products, {saved_listings} listings ({multi_count} multi-platform)')
        total_products += saved_products
        total_listings += saved_listings

    print(f'[Done] Products: {total_products}, Listings: {total_listings}, Errors: {total_errors}')
    return total_products


if __name__ == '__main__':
    db_session = next(get_db())
    count = run_sync(db_session)
    db_session.close()
    print(f'Final count: {count}')
