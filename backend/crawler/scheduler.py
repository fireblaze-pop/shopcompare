import sys
import time
import datetime
from sqlalchemy.orm import Session
from app.database import get_db
from crawler.base.base_crawler import BaseCrawler, CATEGORY_KEYWORDS
from crawler.sources.jd_search import JdCrawler
from crawler.sources.suning_search import SuningCrawler
from crawler.pipeline.writer import save_raw_product


def run_sync(db: Session):
  print(f'[{datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}] 爬虫开始运行')
  total_new: int = 0
  total_updated: int = 0
  total_errors: int = 0

  jd = JdCrawler(min_delay=2.0, max_delay=5.0)
  suning = SuningCrawler(min_delay=2.0, max_delay=5.0)

  for category, keywords in CATEGORY_KEYWORDS.items():
    print(f'  [{category}] 开始爬取...')
    for keyword in keywords:
      try:
        jd_products = jd.search(keyword, page=1)
        suning_products = suning.search(keyword, page=1)

        for raw in jd_products + suning_products:
          if raw.get('price', 0) > 0:
            product_id = save_raw_product(db, raw)
            if product_id is not None:
              total_new = total_new + 1

        print(f'    关键词 [{keyword}]: JD={len(jd_products)}条 Suning={len(suning_products)}条')
      except Exception as e:
        print(f'    关键词 [{keyword}] 出错: {e}')
        total_errors = total_errors + 1

  print(f'[完成] 新增/更新: {total_new} 条, 错误: {total_errors} 次')
  return total_new


if __name__ == '__main__':
  db_session = next(get_db())
  count = run_sync(db_session)
  db_session.close()
  print(f'最终新增商品数: {count}')
