import time
import datetime
import threading
from app.database import SessionLocal
from crawler.sources.suning_search import SuningCrawler
from crawler.base.base_crawler import CATEGORY_KEYWORDS
from crawler.pipeline.writer import save_raw_product


class BgCrawlerService:
  def __init__(self, interval_minutes: int = 30):
    self.interval: int = interval_minutes
    self.thread: threading.Thread | None = None
    self.running: bool = False
    self.total_products: int = 0
    self.last_run: str = ''
    self.last_count: int = 0
    self.last_error: str = ''

  def start(self):
    if self.thread is not None:
      return
    self.running = True
    self.thread = threading.Thread(target=self._run_loop, daemon=True)
    self.thread.start()
    print(f'[CrawlerService] 启动后台爬虫, 间隔 {self.interval} 分钟')

  def stop(self):
    self.running = False
    if self.thread is not None:
      self.thread.join(timeout=10)
    print('[CrawlerService] 已停止')

  def status(self) -> dict:
    return {
      'running': self.running,
      'total_products': self.total_products,
      'last_run': self.last_run,
      'last_count': self.last_count,
      'last_error': self.last_error,
      'interval_minutes': self.interval
    }

  def _run_loop(self):
    while self.running:
      try:
        self._run_all()
      except Exception as e:
        self.last_error = str(e)
        print(f'[CrawlerService] 错误: {e}')
      time.sleep(self.interval * 60)

  def _run_all(self):
    db = SessionLocal()
    total: int = 0
    try:
      print(f'[CrawlerService] 开始全品类爬取 ({datetime.datetime.now().strftime("%H:%M")})')
      suning = SuningCrawler(min_delay=2.0, max_delay=4.0)

      for category, keywords in CATEGORY_KEYWORDS.items():
        for keyword in keywords:
          try:
            products = suning.search(keyword, page=1)
            for raw in products:
              if raw.get('price', 0) > 0:
                product_id = save_raw_product(db, raw)
                if product_id is not None:
                  total = total + 1
          except Exception as e:
            print(f'  [CrawlerService] 关键词 [{keyword}] 错误: {e}')

      self.last_count = total
      self.total_products = self.total_products + total
      self.last_run = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
      print(f'[CrawlerService] 完成: +{total}件商品, 数据库累计 {self.total_products}')
    except Exception as e:
      self.last_error = str(e)
    finally:
      db.close()


_bg_service: BgCrawlerService = BgCrawlerService()


def get_bg_service() -> BgCrawlerService:
  return _bg_service
