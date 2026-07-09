from app.models.models import Product


PHONE_CATEGORY = '\u624b\u673a\u6570\u7801'
HUAWEI_BRAND = '\u534e\u4e3a'


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
    resp = client.get('/api/v1/products?category=' + PHONE_CATEGORY)
    assert resp.status_code == 200
    data = resp.json()
    for item in data['items']:
        assert item['category'] == PHONE_CATEGORY


def test_get_products_filter_brand(client):
    resp = client.get('/api/v1/products?brand=Apple')
    assert resp.status_code == 200
    data = resp.json()
    for item in data['items']:
        assert item['brand'] == 'Apple'


def test_get_products_filter_brand_uses_title_aliases(client, db_session):
    db_session.add_all([
        Product(
            id='brand-huawei-title',
            name='Huawei/\u534e\u4e3a FreeBuds SE 4 ANC\u84dd\u7259\u8033\u673a',
            brand='OPPO',
            category=PHONE_CATEGORY,
            lowest_price=727,
            highest_price=727,
            price_spread=0,
            historical_low=727
        ),
        Product(
            id='brand-oppo-title',
            name='OPPO Enco Air4 \u65b0\u58f0\u7248 \u84dd\u7259\u8033\u673a',
            brand='OPPO',
            category=PHONE_CATEGORY,
            lowest_price=199,
            highest_price=199,
            price_spread=0,
            historical_low=199
        ),
        Product(
            id='brand-apple-title',
            name='Apple \u82f9\u679c AirPods 4 \u65e0\u7ebf\u84dd\u7259\u8033\u673a',
            brand='Apple',
            category=PHONE_CATEGORY,
            lowest_price=1618,
            highest_price=1618,
            price_spread=0,
            historical_low=1618
        ),
    ])
    db_session.commit()

    resp = client.get('/api/v1/products?category_id=cat1&brand=Huawei')
    assert resp.status_code == 200
    data = resp.json()
    names = [item['name'] for item in data['items']]
    assert 'Huawei/\u534e\u4e3a FreeBuds SE 4 ANC\u84dd\u7259\u8033\u673a' in names
    assert all('OPPO Enco' not in name for name in names)
    assert all('AirPods 4' not in name for name in names)
    assert all(item['brand'] == HUAWEI_BRAND for item in data['items'])


def test_get_products_deduplicates_identical_items(client, db_session):
    duplicate_name = 'Huawei Mate 80 Pro 12GB 256GB'
    db_session.add_all([
        Product(
            id='dup-product-a',
            name=duplicate_name,
            brand='Huawei',
            category=PHONE_CATEGORY,
            lowest_price=5999,
            highest_price=5999,
            price_spread=0,
            historical_low=5999
        ),
        Product(
            id='dup-product-b',
            name=duplicate_name,
            brand=HUAWEI_BRAND,
            category=PHONE_CATEGORY,
            lowest_price=5999,
            highest_price=5999,
            price_spread=0,
            historical_low=5999
        ),
    ])
    db_session.commit()

    resp = client.get('/api/v1/products?category_id=cat1&brand=Huawei&size=100')
    assert resp.status_code == 200
    data = resp.json()
    assert [item['name'] for item in data['items']].count(duplicate_name) == 1


def test_get_products_filter_price_range(client):
    resp = client.get(
        '/api/v1/products?category=' + PHONE_CATEGORY +
        '&brand=' + HUAWEI_BRAND +
        '&min_price=1000&max_price=8000'
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data['total'] == 1
    assert data['items'][0]['brand'] == HUAWEI_BRAND


def test_get_products_filter_category_id_and_price_range(client):
    resp = client.get('/api/v1/products?category_id=cat1&min_price=1000&max_price=8000')
    assert resp.status_code == 200
    data = resp.json()
    assert data['total'] >= 1
    for item in data['items']:
        assert item['category'] == PHONE_CATEGORY
        assert 1000 <= item['lowest_price'] <= 8000


def test_get_products_filter_sub_category_id(client):
    resp = client.get('/api/v1/products?category_id=cat1&sub_category_id=sub1')
    assert resp.status_code == 200
    data = resp.json()
    assert data['total'] >= 1
    names = [item['name'] for item in data['items']]
    assert any('iPhone' in name or 'Mate' in name for name in names)


def test_get_products_unknown_category_id_returns_empty(client):
    resp = client.get('/api/v1/products?category_id=unknown')
    assert resp.status_code == 200
    data = resp.json()
    assert data['total'] == 0
    assert data['items'] == []


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


def test_get_generated_product_detail_for_sparse_crawled_product(client, db_session):
    db_session.add(Product(
        id='sparse1',
        name='Sparse Crawled Product',
        brand='CrawlerBrand',
        category=PHONE_CATEGORY,
        image_url='https://example.com/product.png',
        description='',
        lowest_price=1283,
        highest_price=1283,
        price_spread=0,
        historical_low=1283,
        aggregate_rating=4.0,
        aggregate_score=6.5,
        total_review_count=0,
        publish_date='2026-07-09'
    ))
    db_session.commit()

    resp = client.get('/api/v1/products/sparse1')
    assert resp.status_code == 200
    data = resp.json()
    assert data['id'] == 'sparse1'
    assert len(data['platform_listings']) == 1
    assert data['platform_listings'][0]['price'] == 1283
    assert len(data['price_history']) == 3
    assert len(data['specs']) >= 2
    assert len(data['review_tags']) >= 2


def test_get_product_not_found(client):
    resp = client.get('/api/v1/products/nonexistent')
    assert resp.status_code == 404


def test_get_categories(client):
    resp = client.get('/api/v1/categories')
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 6
    assert data[0]['name'] == PHONE_CATEGORY


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
    resp = client.get('/api/v1/filters?category=' + PHONE_CATEGORY)
    assert resp.status_code == 200
    data = resp.json()
    assert data['product_count'] >= 1
    assert data['brands'][0]['name']
    assert 'price_bins' in data
    assert 'sub_categories' in data


def test_get_filters_by_category_id(client):
    resp = client.get('/api/v1/filters?category_id=cat1')
    assert resp.status_code == 200
    data = resp.json()
    assert data['category_id'] == 'cat1'
    assert data['product_count'] >= 1
    assert len(data['brands']) >= 1
    assert len(data['price_bins']) >= 1
    assert any(item['id'] == 'sub1' for item in data['sub_categories'])


def test_get_filters_unknown_category_id_returns_empty(client):
    resp = client.get('/api/v1/filters?category_id=unknown')
    assert resp.status_code == 200
    data = resp.json()
    assert data['product_count'] == 0
    assert data['brands'] == []
    assert data['price_bins'] == []
    assert data['sub_categories'] == []
