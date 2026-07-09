import time
import datetime
import threading
from app.database import SessionLocal
from crawler.sources.manmanbuy_search import ManmanbuyCrawler, SEARCH_KEYWORDS
from crawler.pipeline.writer import save_raw_product, normalize_name

MAX_LOG_ENTRIES: int = 100


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


class BgCrawlerService:
    def __init__(self, interval_minutes: int = 30):
        self.interval: int = interval_minutes
        self.thread: threading.Thread | None = None
        self.running: bool = False
        self.total_products: int = 0
        self.last_run: str = ''
        self.last_count: int = 0
        self.last_error: str = ''
        self.logs: list[dict] = []

    def start(self):
        if self.thread is not None:
            return
        self.running = True
        self.thread = threading.Thread(target=self._run_loop, daemon=True)
        self.thread.start()
        print(f'[CrawlerService] Started (Manmanbuy), interval {self.interval} min')

    def stop(self):
        self.running = False
        if self.thread is not None:
            self.thread.join(timeout=10)
        print('[CrawlerService] Stopped')

    def status(self) -> dict:
        return {
            'running': self.running,
            'total_products': self.total_products,
            'last_run': self.last_run,
            'last_count': self.last_count,
            'last_error': self.last_error,
            'interval_minutes': self.interval
        }

    def _add_log(self, keyword: str, count: int, error: str):
        entry: dict = {
            'time': datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            'keyword': keyword,
            'count': count,
            'error': error
        }
        self.logs.insert(0, entry)
        if len(self.logs) > MAX_LOG_ENTRIES:
            self.logs.pop()

    def _run_loop(self):
        while self.running:
            try:
                self._run_all()
            except Exception as e:
                self.last_error = str(e)
                print(f'[CrawlerService] Error: {e}')
            time.sleep(self.interval * 60)

    def _run_all(self):
        db = SessionLocal()
        total_products: int = 0
        total_listings: int = 0
        crawler = ManmanbuyCrawler(min_delay=1.0, max_delay=2.0)
        try:
            print(f'[CrawlerService] Start ({datetime.datetime.now().strftime("%H:%M")})')
            for keyword in SEARCH_KEYWORDS:
                all_items: list[dict] = []
                try:
                    for pg in range(1, 6):
                        products = crawler.search(keyword, page=pg)
                        all_items.extend(products)
                        if len(products) == 0:
                            break
                except Exception as e:
                    self._add_log(keyword, 0, str(e))
                    continue

                if len(all_items) == 0:
                    continue

                groups = _group_by_name(all_items)
                saved_prod: int = 0
                saved_list: int = 0
                for group in groups:
                    first: dict = group[0]
                    first['platform'] = first.get('platform', '\u4EAC\u4E1C')
                    pid = save_raw_product(db, first)
                    if pid is not None:
                        saved_prod += 1
                        saved_list += 1
                    i: int = 1
                    while i < len(group):
                        save_raw_product(db, group[i])
                        saved_list += 1
                        i += 1
                    total_products += saved_prod
                    total_listings += saved_list

                self._add_log(keyword, saved_prod, '')

            self.last_count = total_products
            self.total_products += total_products
            self.last_run = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            print(f'[CrawlerService] Done: {total_products} products, {total_listings} listings')
        except Exception as e:
            self.last_error = str(e)
        finally:
            db.close()


_bg_service: BgCrawlerService = BgCrawlerService()


def get_bg_service() -> BgCrawlerService:
    return _bg_service
