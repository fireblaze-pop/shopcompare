def test_create_alert(client, auth_headers):
    resp = client.post("/api/v1/alerts",
        json={"product_id": "p1", "target_price": 8500},
        headers=auth_headers
    )
    assert resp.status_code == 201
    assert "target_price" in resp.json()


def test_create_duplicate_alert(client, auth_headers):
    client.post("/api/v1/alerts",
        json={"product_id": "p2", "target_price": 6000},
        headers=auth_headers
    )
    resp = client.post("/api/v1/alerts",
        json={"product_id": "p2", "target_price": 6000},
        headers=auth_headers
    )
    assert resp.status_code == 409


def test_get_alerts(client, auth_headers):
    client.post("/api/v1/alerts",
        json={"product_id": "p3", "target_price": 10000},
        headers=auth_headers
    )
    resp = client.get("/api/v1/alerts", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["total"] >= 1


def test_remove_alert(client, auth_headers):
    resp = client.post("/api/v1/alerts",
        json={"product_id": "p4", "target_price": 5000},
        headers=auth_headers
    )
    data = resp.json()
    alert_id = 1

    resp = client.delete(f"/api/v1/alerts/{alert_id}", headers=auth_headers)
    assert resp.status_code == 200


def test_alert_without_auth(client):
    resp = client.get("/api/v1/alerts")
    assert resp.status_code == 403
