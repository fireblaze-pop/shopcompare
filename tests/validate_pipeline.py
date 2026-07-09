import httpx
import time
import sys

BASE = "http://localhost:8000/api/v1"
BASE_ROOT = "http://localhost:8000"


class T:
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.start = time.time()

    def check(self, name: str, ok: bool, ms: int):
        if ok:
            self.passed += 1
            print(f"  [PASS] {name} ({ms}ms)")
        else:
            self.failed += 1
            print(f"  [FAIL] {name}")

    def summary(self) -> bool:
        elapsed = time.time() - self.start
        total = self.passed + self.failed
        print(f"\n{'=' * 50}")
        print(f"  Results: {self.passed}/{total} PASS  Time: {elapsed:.1f}s")
        print(f"{'=' * 50}")
        return self.failed == 0


t = T()


async def main():
    print("=" * 50)
    print("  ShopCompare Pipeline Validation v0.3")
    print("=" * 50)

    async with httpx.AsyncClient(timeout=15) as c:

        print("\n--- Phase 1: Backend Connectivity ---")

        s = time.time()
        try:
            r = await c.get(f"{BASE_ROOT}/health")
            ok = r.status_code == 200
        except Exception:
            ok = False
        t.check("T1  Backend health check", ok, int((time.time() - s) * 1000))

        if not ok:
            print("\n[ABORT] Backend is not running.")
            t.summary()
            return 1

        print("\n--- Phase 2: Filters Endpoint ---")

        s = time.time()
        r = await c.get(f"{BASE}/filters?category=手机数码")
        data = r.json()
        ok = data.get("product_count", 0) > 0
        t.check(f"T2  Filters for 手机数码: count={data.get('product_count', 0)}", ok, int((time.time() - s) * 1000))

        s = time.time()
        r = await c.get(f"{BASE}/products?category=手机数码&size=50")
        items = r.json().get("items", [])
        ok = len(items) > 0
        t.check(f"T3  Products filtered by category: {len(items)} items", ok, int((time.time() - s) * 1000))

        s = time.time()
        r = await c.get(f"{BASE}/products?category=电脑办公&size=50")
        items = r.json().get("items", [])
        ok = len(items) > 0
        t.check(f"T4  Products filtered by 电脑办公: {len(items)} items", ok, int((time.time() - s) * 1000))

        s = time.time()
        r = await c.get(f"{BASE}/products?category=家用电器&size=50")
        items = r.json().get("items", [])
        ok = len(items) > 0
        t.check(f"T5  Products filtered by 家用电器: {len(items)} items", ok, int((time.time() - s) * 1000))

        s = time.time()
        r = await c.get(f"{BASE}/products?category=美妆个护&size=50")
        items = r.json().get("items", [])
        ok = len(items) > 0
        t.check(f"T6  Products filtered by 美妆个护: {len(items)} items", ok, int((time.time() - s) * 1000))

        s = time.time()
        r = await c.get(f"{BASE}/products?category=服饰鞋包&size=50")
        items = r.json().get("items", [])
        ok = len(items) > 0
        t.check(f"T7  Products filtered by 服饰鞋包: {len(items)} items", ok, int((time.time() - s) * 1000))

        s = time.time()
        r = await c.get(f"{BASE}/products?category=食品生鲜&size=50")
        items = r.json().get("items", [])
        ok = len(items) > 0
        t.check(f"T8  Products filtered by 食品生鲜: {len(items)} items", ok, int((time.time() - s) * 1000))

        print("\n--- Phase 3: Brand Reputation ---")

        s = time.time()
        r = await c.get(f"{BASE}/brands/reputation")
        reps = r.json().get("reputations", {})
        has_chinese = any(k for k in reps.keys() if isinstance(k, str) and any('\u4e00' <= ch <= '\u9fff' for ch in k))
        t.check("T9  Brand reputation includes Chinese names", has_chinese, int((time.time() - s) * 1000))

        print("\n--- Phase 4: Price Bins ---")

        s = time.time()
        r = await c.get(f"{BASE}/filters?category=电脑办公")
        data = r.json()
        bins = data.get("price_bins", [])
        has_high = any(b.get("label", "").startswith("10000") or b.get("label", "").startswith("15000") for b in bins)
        t.check("T10 Price bins cover 10000+ range", has_high, int((time.time() - s) * 1000))

        print("\n--- Phase 5: Search ---")

        s = time.time()
        r = await c.get(f"{BASE}/search", params={"q": "\u624B\u673A"})
        search_items = r.json().get("items", [])
        ok = len(search_items) > 0
        t.check(f"T11 Search returns results: {len(search_items)} items", ok, int((time.time() - s) * 1000))

    return 0 if t.summary() else 1


if __name__ == "__main__":
    import asyncio
    ok = asyncio.run(main())
    sys.exit(ok)
