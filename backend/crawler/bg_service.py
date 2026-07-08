import time
import datetime
import threading
from app.database import SessionLocal
from crawler.sources.manmanbuy_search import ManmanbuyCrawler, SEARCH_KEYWORDS
from crawler.pipeline.writer import save_raw_product

MAX_LOG_ENTRIES: int = 100


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
        print(f'[CrawlerService] Started, interval {self.interval} min')

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
        total: int = 0
        crawler = ManmanbuyCrawler(min_delay=1.0, max_delay=2.0)
        try:
            print(f'[CrawlerService] Start ({datetime.datetime.now().strftime("%H:%M")})')
            for keyword in SEARCH_KEYWORDS:
                try:
                    products = crawler.search(keyword, page=1)
                    saved: int = 0
                    for raw in products:
                        if raw.get('price', 0) > 0:
                            product_id = save_raw_product(db, raw)
                            if product_id is not None:
                                saved += 1
                                total += 1
                    self._add_log(keyword, saved, '')
                except Exception as e:
                    self._add_log(keyword, 0, str(e))
                    print(f'  [{keyword}] error: {e}')

            self.last_count = total
            self.total_products += total
            self.last_run = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            print(f'[CrawlerService] Done: +{total}, total {self.total_products}')
        except Exception as e:
            self.last_error = str(e)
        finally:
            db.close()


_bg_service: BgCrawlerService = BgCrawlerService()


def get_bg_service() -> BgCrawlerService:
    return _bg_service
