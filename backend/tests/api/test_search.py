from app.models.models import Product


PHONE_CATEGORY = '\u624b\u673a\u6570\u7801'


def test_search_product(client):
    resp = client.get('/api/v1/search?q=iPhone')
    assert resp.status_code == 200
    data = resp.json()
    assert data['total'] >= 1
    assert any('iPhone' in item['name'] for item in data['items'])


def test_search_empty_query(client):
    resp = client.get('/api/v1/search')
    assert resp.status_code == 422


def test_search_case_insensitive(client):
    resp = client.get('/api/v1/search?q=iphone')
    assert resp.status_code == 200


def test_search_by_brand(client):
    resp = client.get('/api/v1/search?q=华为')
    assert resp.status_code == 200
    data = resp.json()
    assert data['total'] >= 1


def test_search_deduplicates_identical_items(client, db_session):
    duplicate_name = 'Huawei Search Duplicate Phone 12GB 256GB'
    db_session.add_all([
        Product(
            id='search-dup-a',
            name=duplicate_name,
            brand='Huawei',
            category=PHONE_CATEGORY,
            lowest_price=4888,
            highest_price=4888,
            price_spread=0,
            historical_low=4888
        ),
        Product(
            id='search-dup-b',
            name=duplicate_name,
            brand='\u534e\u4e3a',
            category=PHONE_CATEGORY,
            lowest_price=4888,
            highest_price=4888,
            price_spread=0,
            historical_low=4888
        ),
    ])
    db_session.commit()

    resp = client.get('/api/v1/search?q=Search%20Duplicate')
    assert resp.status_code == 200
    data = resp.json()
    assert data['total'] == 1
    assert [item['name'] for item in data['items']].count(duplicate_name) == 1


def test_search_remote_catalog_product(client):
    resp = client.get('/api/v1/search?q=MateBook')
    assert resp.status_code == 200
    data = resp.json()
    assert data['total'] >= 1
    assert any('MateBook' in item['name'] for item in data['items'])


def test_search_low_result_queues_keyword_crawl(client, monkeypatch):
    from app.routers import search as search_router

    calls: list[str] = []

    def fake_enqueue(keyword: str) -> bool:
        calls.append(keyword)
        return True

    monkeypatch.setattr(search_router, 'enqueue_search_crawl', fake_enqueue)

    resp = client.get('/api/v1/search?q=unseen-search-keyword')
    assert resp.status_code == 200
    data = resp.json()
    assert data['total'] == 0
    assert data['crawl_queued'] is True
    assert calls == ['unseen-search-keyword']


def test_search_short_query_does_not_queue_keyword_crawl(client, monkeypatch):
    from app.routers import search as search_router

    def fake_enqueue(keyword: str) -> bool:
        raise AssertionError(f'short query should not queue crawler: {keyword}')

    monkeypatch.setattr(search_router, 'enqueue_search_crawl', fake_enqueue)

    resp = client.get('/api/v1/search?q=x')
    assert resp.status_code == 200
    data = resp.json()
    assert data['crawl_queued'] is False


def test_search_enough_results_does_not_queue_keyword_crawl(client, monkeypatch):
    from app.routers import search as search_router

    def fake_enqueue(keyword: str) -> bool:
        raise AssertionError(f'existing results should not queue crawler: {keyword}')

    monkeypatch.setattr(search_router, 'enqueue_search_crawl', fake_enqueue)
    monkeypatch.setattr(search_router, 'AUTO_CRAWL_RESULT_THRESHOLD', 1)

    resp = client.get('/api/v1/search?q=iPhone')
    assert resp.status_code == 200
    data = resp.json()
    assert data['total'] >= 1
    assert data['crawl_queued'] is False
