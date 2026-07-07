def test_register_success(client):
    resp = client.post("/api/v1/auth/send-code", json={"phone": "13800138000"})
    assert resp.status_code == 200

    resp = client.post("/api/v1/auth/register", json={
        "phone": "13800138000",
        "code": "123456",
        "password": "test123456"
    })
    assert resp.status_code == 201
    data = resp.json()
    assert "access_token" in data
    assert "refresh_token" in data


def test_register_duplicate_phone(client):
    client.post("/api/v1/auth/send-code", json={"phone": "13800138001"})
    client.post("/api/v1/auth/register", json={
        "phone": "13800138001", "code": "123456", "password": "test123456"
    })

    client.post("/api/v1/auth/send-code", json={"phone": "13800138001"})
    resp = client.post("/api/v1/auth/register", json={
        "phone": "13800138001", "code": "123456", "password": "test123456"
    })
    assert resp.status_code == 409


def test_register_weak_password(client):
    client.post("/api/v1/auth/send-code", json={"phone": "13800138002"})
    resp = client.post("/api/v1/auth/register", json={
        "phone": "13800138002", "code": "123456", "password": "123"
    })
    assert resp.status_code == 400


def test_register_invalid_phone(client):
    resp = client.post("/api/v1/auth/register", json={
        "phone": "123", "code": "123456", "password": "test123456"
    })
    assert resp.status_code == 400


def test_register_wrong_code(client):
    resp = client.post("/api/v1/auth/register", json={
        "phone": "13800138003", "code": "000000", "password": "test123456"
    })
    assert resp.status_code == 400


def test_login_password_correct(client):
    client.post("/api/v1/auth/send-code", json={"phone": "13800138010"})
    client.post("/api/v1/auth/register", json={
        "phone": "13800138010", "code": "123456", "password": "test123456"
    })
    resp = client.post("/api/v1/auth/login", json={
        "phone": "13800138010", "password": "test123456", "login_type": "password"
    })
    assert resp.status_code == 200
    assert "access_token" in resp.json()


def test_login_password_wrong(client):
    client.post("/api/v1/auth/send-code", json={"phone": "13800138011"})
    client.post("/api/v1/auth/register", json={
        "phone": "13800138011", "code": "123456", "password": "test123456"
    })
    resp = client.post("/api/v1/auth/login", json={
        "phone": "13800138011", "password": "wrongpassword", "login_type": "password"
    })
    assert resp.status_code == 401


def test_login_code_correct(client):
    phone = "13800138012"
    client.post("/api/v1/auth/send-code", json={"phone": phone})
    client.post("/api/v1/auth/register", json={
        "phone": phone, "code": "123456", "password": "test123456"
    })
    client.post("/api/v1/auth/send-code", json={"phone": phone})
    resp = client.post("/api/v1/auth/login", json={
        "phone": phone, "code": "123456", "login_type": "code"
    })
    assert resp.status_code == 200


def test_login_nonexistent_user(client):
    resp = client.post("/api/v1/auth/login", json={
        "phone": "13899999999", "password": "test123456", "login_type": "password"
    })
    assert resp.status_code == 401


def test_reset_password(client):
    phone = "13800138020"
    client.post("/api/v1/auth/send-code", json={"phone": phone})
    client.post("/api/v1/auth/register", json={
        "phone": phone, "code": "123456", "password": "oldpassword123"
    })
    client.post("/api/v1/auth/send-code", json={"phone": phone})
    resp = client.post("/api/v1/auth/reset-password", json={
        "phone": phone, "code": "123456", "password": "newpassword456"
    })
    assert resp.status_code == 200

    resp = client.post("/api/v1/auth/login", json={
        "phone": phone, "password": "newpassword456", "login_type": "password"
    })
    assert resp.status_code == 200


def test_refresh_token(client):
    phone = "13800138030"
    client.post("/api/v1/auth/send-code", json={"phone": phone})
    resp = client.post("/api/v1/auth/register", json={
        "phone": phone, "code": "123456", "password": "test123456"
    })
    refresh_token = resp.json()["refresh_token"]

    resp = client.post("/api/v1/auth/refresh-token", json={
        "refresh_token": refresh_token
    })
    assert resp.status_code == 200
    assert "access_token" in resp.json()


def test_access_protected_route_without_token(client):
    resp = client.get("/api/v1/favorites")
    assert resp.status_code == 403
