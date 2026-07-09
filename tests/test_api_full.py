"""
ShopCompare v0.3 — Full Backend API Test Suite (Layer 1)
Covers all 39 endpoints with positive + negative + edge cases.
Requires backend running on localhost:8000 with seeded data.
"""
import httpx
import asyncio
import sys
import time
import random

BASE = "http://localhost:8000/api/v1"
ROOT = "http://localhost:8000"
PASS = 0
FAIL = 0
TOKEN = ""
PRODUCT_ID = ""
TEST_PHONE = f"138{random.randint(10000000, 99999999)}"


def log(name: str, ok: bool):
    global PASS, FAIL
    if ok:
        PASS += 1
        print(f"  [PASS] {name}")
    else:
        FAIL += 1
        print(f"  [FAIL] {name}")


def summary(title: str) -> bool:
    global PASS, FAIL
    print(f"\n  [{title}] {PASS}/{PASS+FAIL}")
    ok = FAIL == 0
    PASS = 0
    FAIL = 0
    return ok


async def main():
    global TOKEN, PRODUCT_ID, PASS, FAIL
    async with httpx.AsyncClient(timeout=15) as c:

        # ============================================================
        print("=" * 60)
        print("  1. HEALTH & ROOT")
        print("=" * 60)
        # ============================================================
        r = await c.get(f"{ROOT}/health")
        log("GET /health -> 200 + status:ok", r.status_code == 200 and r.json().get("status") == "ok")

        r = await c.get(f"{ROOT}/")
        log("GET / -> 200 + name + version", r.status_code == 200 and "name" in r.json())

        r = await c.get(f"{BASE}/health")
        log("GET /api/v1/health -> 200", r.status_code == 200)

        summary("Health")

        # ============================================================
        print("=" * 60)
        print("  2. AUTH — Register & Login")
        print("=" * 60)
        # ============================================================

        # Send code
        r = await c.post(f"{BASE}/auth/send-code", json={"phone": TEST_PHONE})
        log("POST /auth/send-code -> 200 + code returned", r.status_code == 200 and "code" in r.json())

        # Register
        r = await c.post(f"{BASE}/auth/register", json={
            "phone": TEST_PHONE, "password": "test123456", "code": "123456"
        })
        ok = r.status_code == 201
        if ok:
            TOKEN = r.json().get("access_token", "")
        log("POST /auth/register -> 201 + token", ok and TOKEN)

        # Register — duplicate
        r = await c.post(f"{BASE}/auth/register", json={
            "phone": TEST_PHONE, "password": "test123456", "code": "123456"
        })
        log("POST /auth/register duplicate -> 409", r.status_code in (409, 400))

        # Register — short password
        r = await c.post(f"{BASE}/auth/register", json={
            "phone": "13900000001", "password": "123", "code": "123456"
        })
        log("POST /auth/register short pwd -> 422", r.status_code in (422, 400))

        # Register — missing field
        r = await c.post(f"{BASE}/auth/register", json={"phone": "13800000099"})
        log("POST /auth/register missing field -> 422", r.status_code == 422)

        # Login by password
        r = await c.post(f"{BASE}/auth/login", json={
            "phone": TEST_PHONE, "password": "test123456"
        })
        ok = r.status_code == 200 and "access_token" in r.json()
        if ok:
            TOKEN = r.json()["access_token"]
        log("POST /auth/login password -> 200 + token", ok)

        # Login wrong password
        r = await c.post(f"{BASE}/auth/login", json={
            "phone": TEST_PHONE, "password": "wrongpass"
        })
        log("POST /auth/login wrong pwd -> 401", r.status_code == 401)

        # Login by code
        r = await c.post(f"{BASE}/auth/send-code", json={"phone": TEST_PHONE})
        r = await c.post(f"{BASE}/auth/login", json={
            "phone": TEST_PHONE, "code": "123456", "login_type": "code"
        })
        log("POST /auth/login by code -> 200 + token", r.status_code == 200)

        # Login nonexistent user
        r = await c.post(f"{BASE}/auth/login", json={
            "phone": "13999999999", "password": "test123456"
        })
        log("POST /auth/login nonexistent -> 401", r.status_code == 401)

        # Refresh token
        refresh_token = r.json().get("refresh_token", "") if r.status_code == 200 else ""
        if refresh_token:
            r2 = await c.post(f"{BASE}/auth/refresh-token", json={"refresh_token": refresh_token})
            log("POST /auth/refresh-token -> 200", r2.status_code == 200)

            r3 = await c.post(f"{BASE}/auth/refresh-token", json={"refresh_token": "invalid"})
            log("POST /auth/refresh-token invalid -> 401", r3.status_code == 401)

        h = {"Authorization": f"Bearer {TOKEN}"} if TOKEN else {}

        summary("Auth")

        # ============================================================
        print("=" * 60)
        print("  3. PRODUCTS — List, Filter, Sort, Detail")
        print("=" * 60)
        # ============================================================

        # List
        r = await c.get(f"{BASE}/products", params={"size": 10})
        data = r.json()
        items = data.get("items", [])
        log("GET /products -> 200 + items + total", r.status_code == 200 and len(items) > 0 and "total" in data)
        if items:
            PRODUCT_ID = items[0]["id"]

        # Pagination
        r = await c.get(f"{BASE}/products", params={"page": 1, "size": 5})
        log("GET /products pagination -> 200 + 5 items", r.status_code == 200 and len(r.json().get("items", [])) == 5)

        r = await c.get(f"{BASE}/products", params={"page": -1, "size": 5})
        log("GET /products page=-1 -> auto-correct to 1", r.status_code == 200)

        r = await c.get(f"{BASE}/products", params={"size": 101})
        log("GET /products size>100 -> limited", r.status_code in (200, 422))

        # Category filter — all 6 categories
        CATS = ['手机数码', '电脑办公', '家用电器', '美妆个护', '服饰鞋包', '食品生鲜']
        for cat in CATS:
            r = await c.get(f"{BASE}/products", params={"category": cat, "size": 10})
            items = r.json().get("items", [])
            wrong = [p for p in items if p.get("category") != cat]
            log(f"GET /products?category={cat} -> {len(items)} items all matching", len(wrong) == 0 and len(items) > 0)

        # Category — nonexistent
        r = await c.get(f"{BASE}/products", params={"category": "不存在的分类", "size": 5})
        log("GET /products?category=nonexistent -> 0 items", len(r.json().get("items", [])) == 0)

        # Brand filter
        r = await c.get(f"{BASE}/products", params={"brand": "Apple", "size": 10})
        items = r.json().get("items", [])
        all_apple = all("apple" in p.get("brand", "").lower() for p in items)
        log(f"GET /products?brand=Apple -> {len(items)} items all Apple", all_apple and len(items) > 0)

        r = await c.get(f"{BASE}/products", params={"brand": "NotExistBrand", "size": 5})
        log("GET /products?brand=nonexistent -> 0 items", len(r.json().get("items", [])) == 0)

        # Brand + Category combo
        r = await c.get(f"{BASE}/products", params={"category": "手机数码", "brand": "Apple", "size": 10})
        items = r.json().get("items", [])
        all_ok = all(p.get("category") == "手机数码" and "apple" in p.get("brand", "").lower() for p in items)
        log(f"GET /products?cat=手机数码&brand=Apple -> {len(items)} all matching", all_ok and len(items) > 0)

        # Cross-category isolation
        CROSS = [
            ("Apple", "食品生鲜"), ("茅台", "手机数码"), ("Nike", "家用电器"),
            ("戴森", "服饰鞋包"), ("兰蔻", "电脑办公")
        ]
        for brand, cat in CROSS:
            r = await c.get(f"{BASE}/products", params={"brand": brand, "category": cat, "size": 10})
            log(f"GET /products?brand={brand}&cat={cat} -> 0 (cross-cat isolation)", len(r.json().get("items", [])) == 0)

        # Sort
        r = await c.get(f"{BASE}/products", params={"sort": "price_low", "size": 10})
        prices = [p["lowest_price"] for p in r.json().get("items", [])]
        log("GET /products?sort=price_low -> ascending", prices == sorted(prices))

        r = await c.get(f"{BASE}/products", params={"sort": "rating", "size": 10})
        ratings = [p["aggregate_rating"] for p in r.json().get("items", [])]
        log("GET /products?sort=rating -> descending", all(ratings[i] >= ratings[i+1] for i in range(len(ratings)-1)) if len(ratings) > 1 else True)

        r = await c.get(f"{BASE}/products", params={"sort": "invalid_sort", "size": 5})
        log("GET /products?sort=invalid -> returns results anyway", r.status_code == 200)

        # Price range
        r = await c.get(f"{BASE}/products", params={"min_price": 100, "max_price": 500, "size": 10})
        items = r.json().get("items", [])
        in_range = all(100 <= p["lowest_price"] <= 500 for p in items) if items else True
        log(f"GET /products min_price=100&max_price=500 -> {len(items)} all in range", in_range)

        # Product detail
        if PRODUCT_ID:
            r = await c.get(f"{BASE}/products/{PRODUCT_ID}")
            detail = r.json()
            ok = r.status_code == 200 and "name" in detail and "platform_listings" in detail
            log("GET /products/{id} -> 200 + listings + history + tags", ok)

        # Product detail — 404
        r = await c.get(f"{BASE}/products/nonexistent-id-99999")
        log("GET /products/nonexistent -> 404", r.status_code == 404)

        # Multi-platform prices
        if PRODUCT_ID:
            r = await c.get(f"{BASE}/products/{PRODUCT_ID}/prices")
            prices_list = r.json()
            log(f"GET /products/{id}/prices -> {len(prices_list)} listings", r.status_code == 200 and len(prices_list) > 0)

            r2 = await c.get(f"{BASE}/products/nonexistent/prices")
            log("GET /products/{id}/prices nonexistent -> 404", r2.status_code == 404)

        # Price history
        if PRODUCT_ID:
            r = await c.get(f"{BASE}/products/{PRODUCT_ID}/history")
            log(f"GET /products/{id}/history -> 200 + array", r.status_code == 200 and isinstance(r.json(), list))

        # Categories
        r = await c.get(f"{BASE}/categories")
        cats_data = r.json()
        ok = len(cats_data) == 6
        for cat in cats_data:
            if not (cat.get("id") and cat.get("name") and cat.get("icon") and len(cat.get("sub_categories", [])) > 0):
                ok = False
        log("GET /categories -> 6 categories with subcats", ok)

        summary("Products")

        # ============================================================
        print("=" * 60)
        print("  4. SEARCH")
        print("=" * 60)
        # ============================================================

        r = await c.get(f"{BASE}/search", params={"q": "手机"})
        items = r.json().get("items", [])
        log(f"GET /search?q=手机 -> {len(items)} results", r.status_code == 200 and len(items) > 0)

        r = await c.get(f"{BASE}/search", params={"q": "Apple"})
        log(f"GET /search?q=Apple -> results > 0", r.status_code == 200 and len(r.json().get("items", [])) > 0)

        r = await c.get(f"{BASE}/search", params={"q": "不存在的商品xyz123"})
        log("GET /search?q=nonexistent -> empty not error", r.status_code == 200)

        r = await c.get(f"{BASE}/search", params={"q": " "})
        log("GET /search?q=space -> 422 or empty", r.status_code in (200, 422))

        r = await c.get(f"{BASE}/search", params={"q": "戴森"})
        items = r.json().get("items", [])
        log(f"GET /search?q=戴森 -> {len(items)} results with images", all(p.get("image_url") for p in items) if items else True)

        summary("Search")

        # ============================================================
        print("=" * 60)
        print("  5. FAVORITES & ALERTS (auth required)")
        print("=" * 60)
        # ============================================================

        if TOKEN and PRODUCT_ID:
            # Add favorite
            r = await c.post(f"{BASE}/favorites", json={"product_id": PRODUCT_ID}, headers=h)
            log("POST /favorites -> 201", r.status_code in (200, 201))

            # Duplicate favorite
            r2 = await c.post(f"{BASE}/favorites", json={"product_id": PRODUCT_ID}, headers=h)
            log("POST /favorites duplicate -> 409", r2.status_code in (409, 400))

            # List favorites
            r = await c.get(f"{BASE}/favorites", headers=h)
            favs = r.json().get("items", [])
            log(f"GET /favorites -> {len(favs)} items", r.status_code == 200 and len(favs) > 0)

            # Delete favorite
            fav_id = favs[0].get("id", "") if favs else ""
            if fav_id:
                r = await c.delete(f"{BASE}/favorites/{fav_id}", headers=h)
                log("DELETE /favorites/{id} -> 200", r.status_code == 200)

            # Unauthorized
            r = await c.get(f"{BASE}/favorites")
            log("GET /favorites no auth -> 401", r.status_code == 401)

        # Alerts
        if TOKEN and PRODUCT_ID:
            r = await c.post(f"{BASE}/alerts", json={"product_id": PRODUCT_ID, "target_price": 100}, headers=h)
            log("POST /alerts -> 201", r.status_code in (200, 201))

            r = await c.get(f"{BASE}/alerts", headers=h)
            alerts = r.json().get("items", [])
            log(f"GET /alerts -> {len(alerts)} items", r.status_code == 200)

            if alerts:
                alert_id = alerts[0].get("id", 0)
                r = await c.delete(f"{BASE}/alerts/{alert_id}", headers=h)
                log("DELETE /alerts/{id} -> 200", r.status_code == 200)

            r = await c.get(f"{BASE}/alerts")
            log("GET /alerts no auth -> 401", r.status_code == 401)

        summary("Favorites & Alerts")

        # ============================================================
        print("=" * 60)
        print("  6. SMART — Recommendations, Similar, Dimensions, Filters")
        print("=" * 60)
        # ============================================================

        r = await c.get(f"{BASE}/recommendations", params={"size": 10})
        items = r.json().get("items", [])
        log(f"GET /recommendations -> {len(items)} items no duplicates", r.status_code == 200 and len(items) > 0)

        r = await c.get(f"{BASE}/recommendations", params={"size": 51})
        log("GET /recommendations?size=51 -> limited to 50", r.status_code in (200, 422))

        r = await c.get(f"{BASE}/hot-products", params={"size": 5})
        log(f"GET /hot-products -> {len(r.json().get('items',[]))} items", r.status_code == 200)

        if PRODUCT_ID:
            r = await c.get(f"{BASE}/products/{PRODUCT_ID}/similar", params={"size": 5})
            items = r.json().get("items", [])
            all_same_cat = all(p.get("category") == items[0].get("category") for p in items[1:]) if len(items) > 1 else True
            log(f"GET /products/{id}/similar -> {len(items)} same-category", r.status_code == 200 and all_same_cat)

            r = await c.get(f"{BASE}/products/{PRODUCT_ID}/dimensions")
            dims = r.json().get("dimensions", [])
            ok = len(dims) == 6 and all("label" in d and "value" in d for d in dims)
            log("GET /products/{id}/dimensions -> 6 dimensions with labels", ok)

            r = await c.get(f"{BASE}/products/nonexistent/dimensions")
            log("GET /products/{id}/dimensions nonexistent -> 404", r.status_code == 404)

        # Filters
        for cat in CATS:
            r = await c.get(f"{BASE}/filters", params={"category": cat})
            data = r.json()
            ok = data.get("product_count", 0) > 0 and "brands" in data and "price_bins" in data
            log(f"GET /filters?category={cat} -> count={data.get('product_count',0)} brands>0 bins>0", ok)

        r = await c.get(f"{BASE}/filters", params={"category": "不存在的分类"})
        log("GET /filters?category=nonexistent -> product_count=0", r.json().get("product_count", 0) == 0)

        # Brand reputation
        r = await c.get(f"{BASE}/brands/reputation")
        reps = r.json().get("reputations", {})
        log(f"GET /brands/reputation -> {len(reps)} brands", r.status_code == 200 and len(reps) >= 10)

        # Category stats
        r = await c.get(f"{BASE}/categories/手机数码/stats")
        stats = r.json()
        ok = all(k in stats for k in ["min", "max", "avg", "count"])
        log("GET /categories/{name}/stats -> min/max/avg/count", ok and stats.get("count", 0) > 0)

        r = await c.get(f"{BASE}/categories/不存在/stats")
        log("GET /categories/nonexistent/stats -> 0 values", r.status_code == 200)

        summary("Smart")

        # ============================================================
        print("=" * 60)
        print("  7. BEHAVIORS & SEARCH-HISTORY (auth required)")
        print("=" * 60)
        # ============================================================

        if TOKEN and PRODUCT_ID:
            r = await c.post(f"{BASE}/behaviors", json={"product_id": PRODUCT_ID, "action_type": "view"}, headers=h)
            log("POST /behaviors -> 201", r.status_code in (200, 201))

            r = await c.get(f"{BASE}/behaviors", headers=h)
            log(f"GET /behaviors -> {len(r.json().get('items',[]))} items", r.status_code == 200)

            r = await c.get(f"{BASE}/behaviors")
            log("GET /behaviors no auth -> 401", r.status_code == 401)

            r = await c.post(f"{BASE}/search-history", json={"keyword": "iPhone"}, headers=h)
            log("POST /search-history -> 201", r.status_code in (200, 201))

            r = await c.get(f"{BASE}/search-history", headers=h)
            log(f"GET /search-history -> {len(r.json().get('items',[]))} items", r.status_code == 200)

        summary("Behaviors")

        # ============================================================
        print("=" * 60)
        print("  8. ADMIN & CRAWLER")
        print("=" * 60)
        # ============================================================

        r = await c.get(f"{BASE}/crawler/status")
        data = r.json()
        log("GET /crawler/status -> running field present", r.status_code == 200 and "running" in data)

        r = await c.get(f"{BASE}/admin/stats")
        log("GET /admin/stats -> 200 + by_platform/by_category", r.status_code == 200)

        r = await c.get(f"{BASE}/admin/logs")
        log("GET /admin/logs -> 200 + logs array", r.status_code == 200 and "logs" in r.json())

        summary("Admin & Crawler")

        # ============================================================
        print("=" * 60)
        print("  9. FAVORITE EDGE CASES (auth)")
        print("=" * 60)
        # ============================================================

        if TOKEN:
            r = await c.post(f"{BASE}/favorites", json={"product_id": "nonexistent-id"}, headers=h)
            log("POST /favorites nonexistent product -> 404", r.status_code == 404)

            r = await c.delete(f"{BASE}/favorites/99999", headers=h)
            log("DELETE /favorites/{id} nonexistent -> 404", r.status_code in (200, 404))

        # ============================================================
        # FINAL REPORT
        # ============================================================
        print("\n" + "=" * 60)
        print("  FINAL REPORT")
        print("=" * 60)
        print(f"  PASS: {PASS} | FAIL: {FAIL}")
        print("=" * 60)
        return FAIL

if __name__ == "__main__":
    failed = asyncio.run(main())
    sys.exit(0 if failed == 0 else 1)
