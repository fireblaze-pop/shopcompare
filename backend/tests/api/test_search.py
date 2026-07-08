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
