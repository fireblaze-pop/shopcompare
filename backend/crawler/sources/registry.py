from crawler.sources.manmanbuy_search import ManmanbuyCrawler

SOURCES: dict[str, type] = {
    'manmanbuy': ManmanbuyCrawler,
}
