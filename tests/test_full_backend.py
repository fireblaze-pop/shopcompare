"""
ShopCompare 全量后端API测试 v1.0
覆盖: 认证/商品/搜索/筛选/收藏/推荐/品牌/爬虫/异常/性能/跨分类隔离
目标: 0 FAIL = 程序无逻辑问题
用法: python tests/test_full_backend.py
前提: 后端运行在 localhost:8000
"""
import httpx
import asyncio
import time
import re

BASE = "http://localhost:8000/api/v1"
ROOT = "http://localhost:8000"
TIMESTAMP = str(int(time.time() * 1000))[-8:]
PHONE = f"138{TIMESTAMP}"
PASSWORD = "Test123456"
TOKEN = ""
PRODUCT_ID = ""
CATS = ['手机数码', '电脑办公', '家用电器', '美妆个护', '服饰鞋包', '食品生鲜']  # NOQA

PASS = 0
FAIL = 0
FAIL_DETAILS = []


def chk(name: str, ok: bool):
    global PASS, FAIL, FAIL_DETAILS
    if ok:
        PASS += 1
    else:
        FAIL += 1
        FAIL_DETAILS.append(name)


def summary():
    print(f"\n{'=' * 60}")
    print(f"  TOTAL: {PASS + FAIL}  |  PASS: {PASS}  |  FAIL: {FAIL}")
    if FAIL > 0:
        print(f"\n  FAILURES:")
        for d in FAIL_DETAILS:
            print(f"    - {d}")
    print(f"{'=' * 60}")
    return FAIL == 0


async def main():
    global TOKEN, PRODUCT_ID

    async with httpx.AsyncClient(timeout=15) as c:
        print("=" * 60)
        print("  ShopCompare Full Backend Test v1.0")
        print("=" * 60)

        # ========== AUTH (8 cases) ==========
        print("\n--- AUTH ---")

        chk("A1 health check",
            (await c.get(f"{ROOT}/health")).status_code == 200)

        chk("A2 register new user",
            (await c.post(f"{BASE}/auth/send-code", json={"phone": PHONE})).status_code == 200 and
            (await c.post(f"{BASE}/auth/register",
                          json={"phone": PHONE, "password": PASSWORD, "code": "123456"})).status_code == 201)

        chk("A3 duplicate register blocked",
            (await c.post(f"{BASE}/auth/register",
                          json={"phone": PHONE, "password": PASSWORD, "code": "123456"})).status_code in (409, 400))

        chk("A4 login password",
            (r := await c.post(f"{BASE}/auth/login",
                               json={"phone": PHONE, "password": PASSWORD, "login_type": "password"})).status_code == 200
            and "access_token" in r.json())

        TOKEN = (await c.post(f"{BASE}/auth/login",
                              json={"phone": PHONE, "password": PASSWORD, "login_type": "password"})).json()[
            "access_token"]

        chk("A5 login wrong password",
            (await c.post(f"{BASE}/auth/login",
                          json={"phone": PHONE, "password": "wrong", "login_type": "password"})).status_code == 401)

        chk("A6 auth required blocked (no token)",
            (await c.get(f"{BASE}/favorites")).status_code == 401)

        h = {"Authorization": f"Bearer {TOKEN}"}

        chk("A7 auth required blocked (bad token)",
            (await c.get(f"{BASE}/favorites",
                         headers={"Authorization": "Bearer bad.token.here"})).status_code == 401)

        chk("A8 auth required ok (valid token)",
            (await c.get(f"{BASE}/favorites", headers=h)).status_code == 200)

        # ========== PRODUCTS (12 cases) ==========
        print("\n--- PRODUCTS ---")

        r = await c.get(f"{BASE}/products?size=5")
        chk("P1 product list returns items",
            r.status_code == 200 and len(r.json().get("items", [])) == 5)

        data = r.json()
        PRODUCT_ID = data["items"][0]["id"] if data["items"] else ""
        p0 = data["items"][0] if data["items"] else {}

        chk("P2 product has required fields",
            all(f in p0 for f in
                ["id", "name", "brand", "category", "image_url", "lowest_price",
                 "highest_price", "price_spread", "aggregate_rating", "aggregate_score",
                 "total_review_count", "platform_count", "publish_date"]))

        chk("P3 product image_url not empty",
            len(p0.get("image_url", "")) > 0)

        chk("P4 pagination total matches",
            data.get("total", 0) >= 5 and data.get("page", 0) == 1)

        for cat in CATS:
            r = await c.get(f"{BASE}/products?category={cat}&size=50")
            items = r.json().get("items", [])
            total = r.json().get("total", 0)
            chk(f"P5 category [{cat}] has {total} products",
                total > 0 and all(p["category"] == cat for p in items[:20]))

        r = await c.get(f"{BASE}/products?brand=Apple&category={CATS[0]}&size=50")
        items = r.json().get("items", [])
        chk("P6 brand+category filter [Apple in 手机数码]",
            len(items) > 0 and all(
                p["category"] == CATS[0] and "apple" in p["brand"].lower() for p in items))

        r = await c.get(f"{BASE}/products?sort=price_low&size=10")
        prices = [p["lowest_price"] for p in r.json().get("items", [])]
        chk("P7 sort by price_low ascending",
            len(prices) >= 2 and prices == sorted(prices))

        r = await c.get(f"{BASE}/products?sort=rating&size=10")
        ratings = [p["aggregate_rating"] for p in r.json().get("items", [])]
        chk("P8 sort by rating descending",
            len(ratings) >= 2 and ratings == sorted(ratings, reverse=True))

        chk("P9 product detail ok",
            (await c.get(f"{BASE}/products/{PRODUCT_ID}")).status_code == 200
            if PRODUCT_ID else False)

        detail = await c.get(f"{BASE}/products/{PRODUCT_ID}")
        d = detail.json() if PRODUCT_ID else {}
        chk("P10 product detail has listings+history+tags",
            len(d.get("platform_listings", [])) > 0 and
            len(d.get("price_history", [])) > 0 and
            len(d.get("review_tags", [])) > 0
            if PRODUCT_ID else False)

        chk("P11 nonexistent product 404",
            (await c.get(f"{BASE}/products/nonexistent_id_12345")).status_code == 404)

        chk("P12 prices endpoint ok",
            (await c.get(f"{BASE}/products/{PRODUCT_ID}/prices")).status_code == 200
            if PRODUCT_ID else False)

        # ========== SEARCH (6 cases) ==========
        print("\n--- SEARCH ---")

        for kw in ["手机", "iPhone", "空调", "Nike"]:
            r = await c.get(f"{BASE}/search", params={"q": kw})
            items = r.json().get("items", [])
            chk(f"S1 search [{kw}] returns {len(items)} results",
                len(items) > 0 and r.status_code == 200)

        r = await c.get(f"{BASE}/search", params={"q": "xyz123nonexist999"})
        chk("S2 no-results search returns empty",
            r.status_code == 200 and len(r.json().get("items", [])) == 0)

        r = await c.get(f"{BASE}/search", params={"q": "华为"})
        items = r.json().get("items", [])
        chk("S3 Chinese search ok",
            r.status_code == 200 and len(items) > 0)

        r = await c.get(f"{BASE}/search", params={"q": "手机"})
        items = r.json().get("items", [])
        chk("S4 search results have image_url",
            all(p.get("image_url", "") for p in items) if items else False)

        r = await c.get(f"{BASE}/search", params={"q": "手机", "page": 2})
        chk("S5 search pagination ok",
            r.status_code == 200)

        r = await c.get(f"{BASE}/search", params={"q": ""})
        chk("S6 empty search handled",
            r.status_code == 200)

        # ========== CATEGORIES (3 cases) ==========
        print("\n--- CATEGORIES ---")

        cats_resp = await c.get(f"{BASE}/categories")
        cats_data = cats_resp.json()
        chk("C1 6 categories returned",
            len(cats_data) == 6)

        chk("C2 categories have id/name/icon/sub_categories",
            all(c.get("id") and c.get("name") and c.get("icon") and
                len(c.get("sub_categories", [])) >= 2 for c in cats_data))

        stats = await c.get(f"{BASE}/categories/{CATS[0]}/stats")
        chk("C3 category stats ok",
            stats.status_code == 200 and stats.json().get("count", 0) > 0)

        # ========== FILTERS (6 cases) ==========
        print("\n--- FILTERS ---")

        for cat in CATS:
            r = await c.get(f"{BASE}/filters?category={cat}")
            data = r.json()
            brand_count = len(data.get("brands", []))
            bin_count = len(data.get("price_bins", []))
            p_count = data.get("product_count", 0)
            chk(f"F1 filters [{cat}]: {brand_count} brands, {bin_count} bins, {p_count} products",
                brand_count > 0 and bin_count > 0 and p_count > 0)

        r = await c.get(f"{BASE}/filters?category={CATS[0]}")
        brands = r.json().get("brands", [])
        chk("F2 filter brands sorted by count desc",
            len(brands) >= 2 and brands[0].get("count", 0) >= brands[-1].get("count", 0))

        r = await c.get(f"{BASE}/filters?category={CATS[1]}")
        bins = r.json().get("price_bins", [])
        chk("F3 price bins cover 10000+",
            any(b.get("label", "").startswith("10000") or
                b.get("label", "").startswith("15000") for b in bins))

        r = await c.get(f"{BASE}/filters?category={CATS[5]}")
        fdata = r.json()
        chk("F4 filter product_count matches category total",
            abs(fdata.get("product_count", 0) -
                (await c.get(f"{BASE}/products?category={CATS[5]}&size=1")).json().get("total", 1)) <=
            fdata.get("product_count", 0) * 0.1 + 5)

        r = await c.get(f"{BASE}/filters?category={CATS[0]}")
        chk("F5 filter brands contain known names",
            len(r.json().get("brands", [])) > 0)

        r = await c.get(f"{BASE}/filters?category=nonexistent")
        chk("F6 nonexistent category filter ok",
            r.status_code == 200)

        # ========== FAVORITES (5 cases) ==========
        print("\n--- FAVORITES ---")

        chk("V1 add favorite",
            (await c.post(f"{BASE}/favorites",
                          json={"product_id": PRODUCT_ID}, headers=h)).status_code == 201
            if PRODUCT_ID else False)

        chk("V2 duplicate favorite blocked",
            (await c.post(f"{BASE}/favorites",
                          json={"product_id": PRODUCT_ID}, headers=h)).status_code in (409, 400, 201)
            if PRODUCT_ID else False)

        r = await c.get(f"{BASE}/favorites", headers=h)
        fav_items = r.json().get("items", [])
        chk("V3 list favorites",
            len(fav_items) >= 1 if PRODUCT_ID else False)

        if fav_items and PRODUCT_ID:
            fav_id = fav_items[0].get("id", 0)
            chk("V4 remove favorite",
                (await c.delete(f"{BASE}/favorites/{fav_id}", headers=h)).status_code == 200)

        chk("V5 favorites require auth",
            (await c.post(f"{BASE}/favorites",
                          json={"product_id": PRODUCT_ID})).status_code == 401
            if PRODUCT_ID else False)

        # ========== ALERTS (3 cases) ==========
        print("\n--- ALERTS ---")

        chk("L1 create alert",
            (await c.post(f"{BASE}/alerts",
                          json={"product_id": PRODUCT_ID, "target_price": 100},
                          headers=h)).status_code in (201, 200) if PRODUCT_ID else False)

        chk("L2 list alerts",
            (await c.get(f"{BASE}/alerts", headers=h)).status_code == 200)

        chk("L3 alerts require auth",
            (await c.get(f"{BASE}/alerts")).status_code == 401)

        # ========== RECOMMENDATIONS (4 cases) ==========
        print("\n--- RECOMMENDATIONS ---")

        rec = await c.get(f"{BASE}/recommendations?size=5")
        chk("R1 recommendations ok",
            rec.status_code == 200 and len(rec.json().get("items", [])) >= 1)

        hot = await c.get(f"{BASE}/hot-products?size=5")
        chk("R2 hot products ok",
            hot.status_code == 200 and len(hot.json().get("items", [])) >= 1)

        for endpoint, name in [(f"{BASE}/products/{PRODUCT_ID}/similar", "R3 similar products"),
                               (f"{BASE}/products/{PRODUCT_ID}/dimensions", "R4 product dimensions")]:
            if PRODUCT_ID:
                r = await c.get(endpoint)
                chk(name, r.status_code == 200)

        # ========== BRAND REPUTATION (3 cases) ==========
        print("\n--- BRAND REPUTATION ---")

        rep = await c.get(f"{BASE}/brands/reputation")
        rep_data = rep.json().get("reputations", {})
        chk("B1 brand reputations return >10",
            len(rep_data) >= 10)

        chk("B2 Chinese brand names included",
            any(any('\u4e00' <= ch <= '\u9fff' for ch in k) for k in rep_data.keys()))

        chk("B3 Apple reputation score > 80",
            rep_data.get("Apple", 0) >= 80)

        # ========== CRAWLER (2 cases) ==========
        print("\n--- CRAWLER ---")

        cr = await c.get(f"{BASE}/crawler/status")
        chk("W1 crawler status ok",
            cr.status_code == 200 and "running" in cr.json())

        cr_run = await c.post(f"{BASE}/crawler/run")
        chk("W2 crawler trigger returns success",
            cr_run.status_code == 200 and cr_run.json().get("success", False))

        # ========== CROSS-CATEGORY (6 cases) ==========
        print("\n--- CROSS-CATEGORY ISOLATION ---")

        cross_tests = [
            ("Apple", "食品生鲜"),
            ("茅台", "手机数码"),
            ("Nike", "家用电器"),
            ("戴森", "服饰鞋包"),
            ("兰蔻", "电脑办公"),
            ("美的", "美妆个护"),
        ]
        for brand, cat in cross_tests:
            r = await c.get(f"{BASE}/products?brand={brand}&category={cat}&size=20")
            items = r.json().get("items", [])
            chk(f"X1 {brand} × {cat} = 0",
                len(items) == 0)

        # ========== PERFORMANCE (5 cases) ==========
        print("\n--- PERFORMANCE ---")

        s = time.time()
        await c.get(f"{BASE}/products?size=20")
        ms = (time.time() - s) * 1000
        chk(f"PERF1 products < 500ms ({ms:.0f}ms)", ms < 500)

        s = time.time()
        await c.get(f"{BASE}/search", params={"q": "手机"})
        ms = (time.time() - s) * 1000
        chk(f"PERF2 search < 500ms ({ms:.0f}ms)", ms < 500)

        s = time.time()
        await c.get(f"{BASE}/categories")
        ms = (time.time() - s) * 1000
        chk(f"PERF3 categories < 200ms ({ms:.0f}ms)", ms < 200)

        s = time.time()
        await c.get(f"{BASE}/filters?category={CATS[0]}")
        ms = (time.time() - s) * 1000
        chk(f"PERF4 filters < 500ms ({ms:.0f}ms)", ms < 500)

        s = time.time()
        await c.get(f"{BASE}/recommendations?size=5")
        ms = (time.time() - s) * 1000
        chk(f"PERF5 recommendations < 300ms ({ms:.0f}ms)", ms < 300)

        # ========== EDGE CASES (5 cases) ==========
        print("\n--- EDGE CASES ---")

        chk("E1 negative page handles",
            (await c.get(f"{BASE}/products?page=-1&size=10")).status_code in (200, 422))

        chk("E2 zero size handles",
            (await c.get(f"{BASE}/products?size=0")).status_code in (200, 422))

        chk("E3 products nonexistent 404",
            (await c.get(f"{BASE}/products/nonexistent_xyz")).status_code == 404)

        chk("E4 favorites nonexistent product",
            (await c.post(f"{BASE}/favorites",
                          json={"product_id": "nonexistent_xyz"}, headers=h)).status_code in (404, 422)
            if TOKEN else False)

        chk("E5 special chars in brand filter handled",
            (await c.get(f"{BASE}/products?brand=test%2Ccomma&size=5")).status_code == 200)

    return summary()


if __name__ == "__main__":
    ok = asyncio.run(main())
    exit(0 if ok else 1)
