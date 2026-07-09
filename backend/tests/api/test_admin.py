from app.models.models import Alert, Favorite, PlatformListing, PriceHistory, Product


def test_admin_product_crud_flow(client, db_session):
    payload = {
        'id': 'admin-crud-1',
        'name': 'Admin CRUD Phone',
        'brand': 'Huawei',
        'category': '\u624b\u673a\u6570\u7801',
        'model_code': 'ADM-1',
        'image_url': 'https://example.com/a.png',
        'description': 'created by admin',
        'lowest_price': 2999,
        'highest_price': 3299,
        'price_spread': 300,
        'historical_low': 2799,
        'total_review_count': 10,
        'publish_date': '2026-07-09',
    }

    resp = client.post('/api/v1/admin/products', json=payload)
    assert resp.status_code == 200
    data = resp.json()
    assert data['product']['id'] == 'admin-crud-1'
    assert 0 <= data['product']['aggregate_score'] <= 5

    resp = client.get('/api/v1/admin/products?q=CRUD')
    assert resp.status_code == 200
    data = resp.json()
    assert data['total'] == 1
    assert data['items'][0]['id'] == 'admin-crud-1'

    payload['name'] = 'Admin CRUD Phone Updated'
    payload['brand'] = '\u534e\u4e3a'
    resp = client.put('/api/v1/admin/products/admin-crud-1', json=payload)
    assert resp.status_code == 200
    data = resp.json()
    assert data['product']['name'] == 'Admin CRUD Phone Updated'
    assert data['product']['brand'] == '\u534e\u4e3a'

    listing_payload = {
        'platform': 'JD',
        'price': 2888,
        'rating': 4.6,
        'review_count': 123,
        'in_stock': True,
        'url': 'https://example.com/jd'
    }
    resp = client.post('/api/v1/admin/products/admin-crud-1/listings', json=listing_payload)
    assert resp.status_code == 200
    data = resp.json()
    assert data['product']['lowest_price'] == 2888
    assert len(data['product']['listings']) == 1
    listing_id = data['product']['listings'][0]['id']

    listing_payload['price'] = 2666
    listing_payload['in_stock'] = False
    resp = client.put(f'/api/v1/admin/listings/{listing_id}', json=listing_payload)
    assert resp.status_code == 200
    data = resp.json()
    assert data['product']['lowest_price'] == 2666
    assert data['product']['listings'][0]['in_stock'] is False

    resp = client.delete(f'/api/v1/admin/listings/{listing_id}')
    assert resp.status_code == 200
    data = resp.json()
    assert data['product']['listings'] == []


def test_admin_delete_product_cleans_related_rows(client, db_session):
    product = Product(
        id='admin-delete-1',
        name='Admin Delete Product',
        brand='Brand',
        category='\u624b\u673a\u6570\u7801',
        lowest_price=100,
        highest_price=120,
        price_spread=20,
        historical_low=90,
    )
    db_session.add(product)
    db_session.flush()
    db_session.add(PlatformListing(product_id=product.id, platform='JD', price=100))
    db_session.add(PriceHistory(product_id=product.id, date='2026-07-09', price=100))
    db_session.add(Favorite(user_id=1, product_id=product.id))
    db_session.add(Alert(user_id=1, product_id=product.id, target_price=80))
    db_session.commit()
    product_id = product.id

    resp = client.delete('/api/v1/admin/products/' + product_id)
    assert resp.status_code == 200
    assert resp.json()['deleted'] is True

    assert db_session.query(Product).filter(Product.id == product_id).first() is None
    assert db_session.query(PlatformListing).filter(PlatformListing.product_id == product_id).count() == 0
    assert db_session.query(PriceHistory).filter(PriceHistory.product_id == product_id).count() == 0
    assert db_session.query(Favorite).filter(Favorite.product_id == product_id).count() == 0
    assert db_session.query(Alert).filter(Alert.product_id == product_id).count() == 0


def test_admin_dashboard_page(client):
    resp = client.get('/api/v1/admin')
    assert resp.status_code == 200
    assert 'ShopCompare 数据管理' in resp.text
    assert '/admin/products' in resp.text
