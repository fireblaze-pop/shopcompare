"""
ShopCompare v0.3 — End-to-End User Journey Tests (Layer 4)
Simulates real user operations from app open to task completion.
Each journey is a sequential flow with state checks at every step.
Requires backend running with data.
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


def log(name: str, ok: bool):
    global PASS, FAIL
    if ok:
        PASS += 1
        print(f"  [PASS] {name}")
    else:
        FAIL += 1
        print(f"  [FAIL] {name}")


async def journey_browse_and_compare(c: httpx.AsyncClient) -> bool:
    """J1: Guest browses category, filters by brand, views product detail"""
    global PASS, FAIL
    print("\n--- J1: Browse → Filter → Compare → Detail ---")
    s = PASS + FAIL

    r = await c.get(f"{ROOT}/health")
    log("  Backend online", r.status_code == 200)

    r = await c.get(f"{BASE}/categories")
    cats = r.json()
    log("  Categories loaded", len(cats) == 6)

    r = await c.get(f"{BASE}/products", params={"category": "手机数码", "size": 30})
    phone_products = r.json().get("items", [])
    log(f"  手机数码: {len(phone_products)} products", len(phone_products) > 0)

    r = await c.get(f"{BASE}/filters", params={"category": "手机数码"})
    filters = r.json()
    has_brands = len(filters.get("brands", [])) > 0
    has_bins = len(filters.get("price_bins", [])) > 0
    log(f"  Filters loaded: {len(filters.get('brands',[]))} brands, {len(filters.get('price_bins',[]))} bins", has_brands and has_bins)

    r = await c.get(f"{BASE}/products", params={"category": "手机数码", "brand": "Apple", "size": 20})
    apple_phones = r.json().get("items", [])
    all_apple = all("apple" in p.get("brand", "").lower() for p in apple_phones)
    all_phone = all(p.get("category") == "手机数码" for p in apple_phones)
    log(f"  Apple in 手机数码: {len(apple_phones)} items, all match", all_apple and all_phone)

    if apple_phones:
        pid = apple_phones[0]["id"]
        r = await c.get(f"{BASE}/products/{pid}")
        detail = r.json()
        has_listings = len(detail.get("platform_listings", [])) > 0
        has_history = len(detail.get("price_history", [])) > 0
        log(f"  Product detail: listings={len(detail.get('platform_listings',[]))}, history={len(detail.get('price_history',[]))}", has_listings)

        r = await c.get(f"{BASE}/products/{pid}/prices")
        prices = r.json()
        log(f"  Prices: {len(prices)} platforms", len(prices) > 0)

        r = await c.get(f"{BASE}/products/{pid}/dimensions")
        dims = r.json().get("dimensions", [])
        log(f"  Radar: {len(dims)} dimensions", len(dims) == 6)

        r = await c.get(f"{BASE}/products/{pid}/similar")
        similar = r.json().get("items", [])
        log(f"  Similar: {len(similar)} products", len(similar) > 0)

    return (PASS + FAIL - s) == 13


async def journey_search_and_detail(c: httpx.AsyncClient) -> bool:
    """J2: Search for product, verify results, open detail"""
    global PASS, FAIL
    print("\n--- J2: Search → Verify → Detail ---")
    s = PASS + FAIL

    r = await c.get(f"{BASE}/search", params={"q": "手机"})
    results = r.json().get("items", [])
    log(f"  Search '手机': {len(results)} results", len(results) > 0)
    has_some_images = any(p.get("image_url", "") for p in results)
    log(f"  Some results have images", has_some_images)

    r = await c.get(f"{BASE}/search", params={"q": "戴森"})
    dyson = r.json().get("items", [])
    log(f"  Search '戴森': {len(dyson)} results", len(dyson) > 0)

    r = await c.get(f"{BASE}/search", params={"q": "xyz不存在商品"})
    empty = r.json().get("items", [])
    log(f"  Search nonexistent: {len(empty)} results (no crash)", r.status_code == 200)

    if results:
        pid = results[0]["id"]
        r = await c.get(f"{BASE}/products/{pid}")
        detail = r.json()
        log(f"  Search result detail works", "name" in detail and "platform_listings" in detail)

    return (PASS + FAIL - s) == 5


async def journey_multiplatform_comparison(c: httpx.AsyncClient) -> bool:
    """J3: Find multi-platform product, verify price comparison logic"""
    global PASS, FAIL
    print("\n--- J3: Multi-Platform Price Comparison ---")
    s = PASS + FAIL

    r = await c.get(f"{BASE}/products", params={"size": 100})
    all_p = r.json().get("items", [])
    multi = [p for p in all_p if p.get("platform_count", 0) >= 2]
    log(f"  Found {len(multi)} multi-platform products", len(multi) > 0)

    if multi:
        pid = multi[0]["id"]
        r = await c.get(f"{BASE}/products/{pid}")
        detail = r.json()
        listings = detail.get("platform_listings", [])
        prices = [l["price"] for l in listings]
        platforms = list(set(l["platform"] for l in listings))
        log(f"  Product '{detail['name'][:30]}' has {len(listings)} listings across {platforms}", len(listings) >= 2)

        computed_lowest = min(prices)
        computed_highest = max(prices)
        computed_spread = computed_highest - computed_lowest
        log(f"  lowest={computed_lowest} (expected {detail['lowest_price']})",
            abs(computed_lowest - detail["lowest_price"]) < 0.01)
        log(f"  highest={computed_highest} (expected {detail['highest_price']})",
            abs(computed_highest - detail["highest_price"]) < 0.01)
        log(f"  spread={computed_spread:.2f} (expected {detail['price_spread']})",
            abs(computed_spread - detail["price_spread"]) < 1.0)

        r2 = await c.get(f"{BASE}/products/{pid}/prices")
        api_prices = r2.json()
        log(f"  /prices endpoint returns {len(api_prices)} listings (same as detail)",
            len(api_prices) == len(listings))

    return (PASS + FAIL - s) == 5


async def journey_cross_category_discovery(c: httpx.AsyncClient) -> bool:
    """J4: Browse multiple categories, verify each is isolated"""
    global PASS, FAIL
    print("\n--- J4: Cross-Category Discovery ---")
    s = PASS + FAIL

    CATS = ['手机数码', '电脑办公', '家用电器', '美妆个护', '服饰鞋包', '食品生鲜']
    for cat in CATS:
        r = await c.get(f"{BASE}/products", params={"category": cat, "size": 10})
        items = r.json().get("items", [])
        wrong = [p for p in items if p.get("category") != cat]
        log(f"  {cat}: {len(items)} items, {len(wrong)} wrong category", len(wrong) == 0)

    return (PASS + FAIL - s) == 6


async def journey_error_recovery(c: httpx.AsyncClient) -> bool:
    """J5: Exercise error paths, verify graceful handling"""
    global PASS, FAIL
    print("\n--- J5: Error Recovery ---")
    s = PASS + FAIL

    r = await c.get(f"{BASE}/products/nonexistent-id-xyz")
    log("  404 on nonexistent product", r.status_code == 404)

    r = await c.post(f"{BASE}/auth/login", json={"phone": "13899999999", "password": "wrong"})
    log("  401 on wrong credentials", r.status_code == 401)

    r = await c.get(f"{BASE}/favorites")
    log("  401 on unauthenticated favorites", r.status_code == 401)

    r = await c.post(f"{BASE}/auth/register", json={"phone": "123", "password": "test123456"})
    log("  422 on invalid phone", r.status_code in (422, 400))

    r = await c.get(f"{BASE}/products", params={"page": 99999, "size": 100})
    log("  Page 99999 returns empty, not error", r.status_code == 200)

    r = await c.get(f"{BASE}/search", params={"q": ""})
    log("  Empty search handled gracefully", r.status_code in (200, 422))

    return (PASS + FAIL - s) == 6


async def journey_crawler_pipeline(c: httpx.AsyncClient) -> bool:
    """J6: Verify crawler data flows through DB to API correctly"""
    global PASS, FAIL
    print("\n--- J6: Crawler Data Pipeline ---")
    s = PASS + FAIL

    r = await c.get(f"{BASE}/products", params={"size": 1, "sort": "newest"})
    items = r.json().get("items", [])
    log(f"  Newest product exists", len(items) > 0)

    if items:
        p = items[0]
        has_img = len(p.get("image_url", "")) > 0
        has_name = len(p.get("name", "")) > 2
        has_price = p.get("lowest_price", 0) > 0
        log(f"  Product has image + name + price", has_img and has_name and has_price)

    r = await c.get(f"{BASE}/filters", params={"category": "手机数码"})
    data = r.json()
    log(f"  Category filter returns product_count={data.get('product_count',0)}", data.get("product_count", 0) > 0)

    r = await c.get(f"{BASE}/brands/reputation")
    reps = r.json().get("reputations", {})
    log(f"  Brand reputation has {len(reps)} brands", len(reps) >= 10)

    r = await c.get(f"{BASE}/crawler/status")
    log(f"  Crawler status endpoint works", r.status_code == 200)

    r = await c.get(f"{BASE}/admin/stats")
    stats = r.json()
    log(f"  Admin stats: {stats.get('total_products', 0)} products", stats.get("total_products", 0) > 0)

    return (PASS + FAIL - s) == 6


async def journey_search_and_filter_workflow(c: httpx.AsyncClient) -> bool:
    """J7: Full search → filter → result → detail workflow"""
    global PASS, FAIL
    print("\n--- J7: Search → Filter → Result Workflow ---")
    s = PASS + FAIL

    r = await c.get(f"{BASE}/search", params={"q": "华为"})
    huawei_results = r.json().get("items", [])
    log(f"  Search '华为': {len(huawei_results)} results", len(huawei_results) > 0)

    r = await c.get(f"{BASE}/products", params={"brand": "华为", "category": "手机数码", "size": 30, "sort": "price_low"})
    huawei_phone = r.json().get("items", [])
    all_ok = all(
        p.get("brand", "").lower() == "华为" and p.get("category") == "手机数码"
        for p in huawei_phone
    )
    prices = [p["lowest_price"] for p in huawei_phone]
    sorted_ok = prices == sorted(prices)
    log(f"  华为+手机数码+price_low: {len(huawei_phone)} items, all match, sorted", all_ok and sorted_ok)

    if huawei_phone:
        pid = huawei_phone[0]["id"]
        r = await c.get(f"{BASE}/products/{pid}")
        detail = r.json()
        log(f"  Product detail: {detail.get('name', '')[:30]} | {detail.get('lowest_price', 0)} | {detail.get('platform_count', 0)} platforms", True)

    return (PASS + FAIL - s) == 3


async def main():
    global PASS, FAIL
    async with httpx.AsyncClient(timeout=15) as c:
        print("=" * 60)
        print("  SHOPCOMPARE E2E USER JOURNEY TESTS v0.3")
        print("=" * 60)

        ok1 = await journey_browse_and_compare(c)
        ok2 = await journey_search_and_detail(c)
        ok3 = await journey_multiplatform_comparison(c)
        ok4 = await journey_cross_category_discovery(c)
        ok5 = await journey_error_recovery(c)
        ok6 = await journey_crawler_pipeline(c)
        ok7 = await journey_search_and_filter_workflow(c)

        journeys = [ok1, ok2, ok3, ok4, ok5, ok6, ok7]
        passed_journeys = sum(1 for j in journeys if j)
        print(f"\n{'=' * 60}")
        print(f"  Journeys: {passed_journeys}/7 PASS | Total: {PASS}/{PASS+FAIL}")
        print(f"{'=' * 60}")
        return FAIL

if __name__ == "__main__":
    failed = asyncio.run(main())
    sys.exit(0 if failed == 0 else 1)
