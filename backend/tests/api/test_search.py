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
