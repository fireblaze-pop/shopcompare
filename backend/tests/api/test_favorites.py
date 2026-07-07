def test_add_favorite(client, auth_headers):
    resp = client.post("/api/v1/favorites",
        json={"product_id": "p1"},
        headers=auth_headers
    )
    assert resp.status_code == 201


def test_add_duplicate_favorite(client, auth_headers):
    client.post("/api/v1/favorites",
        json={"product_id": "p2"},
        headers=auth_headers
    )
    resp = client.post("/api/v1/favorites",
        json={"product_id": "p2"},
        headers=auth_headers
    )
    assert resp.status_code == 409


def test_get_favorites(client, auth_headers):
    client.post("/api/v1/favorites",
        json={"product_id": "p3"},
        headers=auth_headers
    )
    resp = client.get("/api/v1/favorites", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["total"] >= 1


def test_remove_favorite(client, auth_headers):
    client.post("/api/v1/favorites",
        json={"product_id": "p4"},
        headers=auth_headers
    )
    resp = client.delete("/api/v1/favorites/p4", headers=auth_headers)
    assert resp.status_code == 200

    resp = client.get("/api/v1/favorites", headers=auth_headers)
    data = resp.json()
    found = False
    for item in data["items"]:
        if item["id"] == "p4":
            found = True
    assert not found


def test_favorite_without_auth(client):
    resp = client.get("/api/v1/favorites")
    assert resp.status_code == 403
