def test_search_product(client):
    resp = client.get("/api/v1/search?q=iPhone")
    assert resp.status_code == 200
    data = resp.json()
    assert data["total"] >= 1
    items = data["items"]
    found = False
    for item in items:
        if "iPhone" in item["name"]:
            found = True
            break
    assert found


def test_search_empty_query(client):
    resp = client.get("/api/v1/search")
    assert resp.status_code == 422


def test_search_case_insensitive(client):
    resp = client.get("/api/v1/search?q=iphone")
    assert resp.status_code == 200


def test_search_by_brand(client):
    resp = client.get("/api/v1/search?q=华为")
    assert resp.status_code == 200
    data = resp.json()
    assert data["total"] >= 1
