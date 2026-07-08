def test_get_products(client):
    resp = client.get('/api/v1/products')
    assert resp.status_code == 200
    data = resp.json()
    assert data['total'] >= 10
    assert len(data['items']) <= 20
    assert 'name' in data['items'][0]
    assert 'lowest_price' in data['items'][0]


def test_get_products_with_pagination(client):
    resp = client.get('/api/v1/products?page=1&size=3')
    assert resp.status_code == 200
    data = resp.json()
    assert len(data['items']) == 3


def test_get_products_filter_category(client):
    resp = client.get('/api/v1/products?category=手机数码')
    assert resp.status_code == 200
    data = resp.json()
    for item in data['items']:
        assert item['category'] == '手机数码'


def test_get_products_filter_brand(client):
    resp = client.get('/api/v1/products?brand=Apple')
    assert resp.status_code == 200
    data = resp.json()
    for item in data['items']:
        assert item['brand'] == 'Apple'


def test_get_products_filter_price_range(client):
    resp = client.get('/api/v1/products?category=手机数码&brand=华为&min_price=1000&max_price=8000')
    assert resp.status_code == 200
    data = resp.json()
    assert data['total'] == 1
    assert data['items'][0]['brand'] == '华为'


def test_get_products_sort_price(client):
    resp = client.get('/api/v1/products?sort=price_low')
    assert resp.status_code == 200
    data = resp.json()
    items = data['items']
    for i in range(len(items) - 1):
        assert items[i]['lowest_price'] <= items[i + 1]['lowest_price']


def test_get_product_detail(client):
    resp = client.get('/api/v1/products/p1')
    assert resp.status_code == 200
    data = resp.json()
    assert data['id'] == 'p1'
    assert data['name'] == 'iPhone 16 Pro Max'
    assert len(data['platform_listings']) > 0
    assert len(data['price_history']) > 0


def test_get_product_not_found(client):
    resp = client.get('/api/v1/products/nonexistent')
    assert resp.status_code == 404


def test_get_categories(client):
    resp = client.get('/api/v1/categories')
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 6
    assert data[0]['name'] == '手机数码'


def test_get_product_prices(client):
    resp = client.get('/api/v1/products/p1/prices')
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) > 0
    assert 'platform' in data[0]
    assert 'price' in data[0]


def test_get_product_history(client):
    resp = client.get('/api/v1/products/p1/history')
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) > 0


def test_get_filters(client):
    resp = client.get('/api/v1/filters?category=手机数码')
    assert resp.status_code == 200
    data = resp.json()
    assert data['product_count'] >= 1
    assert data['brands'][0]['name']
    assert 'price_bins' in data
