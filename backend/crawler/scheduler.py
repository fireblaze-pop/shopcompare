import datetime
from sqlalchemy.orm import Session
from app.database import get_db
from crawler.sources.manmanbuy_search import ManmanbuyCrawler, CATEGORY_MAP, SEARCH_KEYWORDS
from crawler.pipeline.writer import save_raw_product


def run_sync(db: Session) -> int:
    print(f'[{datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}] Crawler started')
    total_new: int = 0
    total_errors: int = 0

    crawler = ManmanbuyCrawler(min_delay=1.0, max_delay=2.0)

    for keyword in SEARCH_KEYWORDS:
        for page in range(1, 4):
            try:
                products = crawler.search(keyword, page=page)
                for raw in products:
                    if raw.get('price', 0) > 0:
                        product_id = save_raw_product(db, raw)
                        if product_id is not None:
                            total_new += 1
                print(f'  [{keyword}] page={page}: {len(products)} products')
            except Exception as e:
                print(f'  [{keyword}] page={page} error: {e}')
                total_errors += 1

    print(f'[Done] New/updated: {total_new}, Errors: {total_errors}')
    return total_new


if __name__ == '__main__':
    db_session = next(get_db())
    count = run_sync(db_session)
    db_session.close()
    print(f'Final count: {count}')
