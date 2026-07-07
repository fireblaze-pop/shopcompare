from crawler.sources.jd_search import JdCrawler
from crawler.sources.suning_search import SuningCrawler
from crawler.base.base_crawler import BaseCrawler

SOURCES: dict[str, type[BaseCrawler]] = {
  'jd': JdCrawler,
  'suning': SuningCrawler,
}
