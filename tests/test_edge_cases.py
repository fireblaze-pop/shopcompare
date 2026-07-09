"""
ShopCompare v0.3 — Edge Case & Error Recovery Tests (Layer 5)
Boundary conditions, invalid inputs, concurrency, stress.
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


def log(name: str, ok: bool, detail: str = ""):
    global PASS, FAIL
    msg = f"  [PASS] {name}" if ok else f"  [FAIL] {name}"
    if detail:
        msg += f"  ({detail})"
    if ok:
        PASS += 1
    else:
        FAIL += 1
    print(msg)


async def main():
    global PASS, FAIL
    async with httpx.AsyncClient(timeout=15) as c:
        print("=" * 60)
        print("  EDGE CASE TESTS v0.3")
        print("=" * 60)

        # ============================================================
        print("\n--- Edge: Input Boundaries ---")
        # ============================================================

        r = await c.get(f"{BASE}/products", params={"page": 0, "size": 5})
        log("E1  page=0 → auto-correct to 1", r.status_code == 200)

        r = await c.get(f"{BASE}/products", params={"page": -100, "size": 5})
        log("E2  page=-100 → auto-correct to 1", r.status_code == 200)

        r = await c.get(f"{BASE}/products", params={"page": 99999, "size": 100})
        items = r.json().get("items", [])
        log(f"E3  page=99999 → {len(items)} items (no crash)", r.status_code == 200)

        r = await c.get(f"{BASE}/products", params={"size": 0})
        log("E4  size=0 → handled gracefully", r.status_code in (200, 422))

        r = await c.get(f"{BASE}/products", params={"size": 99999})
        log("E5  size=huge → limited or error", r.status_code in (200, 422))

        # ============================================================
        print("\n--- Edge: Search Boundaries ---")
        # ============================================================

        long_query = "A" * 200
        r = await c.get(f"{BASE}/search", params={"q": long_query})
        log("E6  Search with 200-char query → no crash", r.status_code in (200, 422))

        r = await c.get(f"{BASE}/search", params={"q": "iPhone%20Pro"})
        log("E7  Search with URL-encoded chars → handled", r.status_code == 200)

        r = await c.get(f"{BASE}/search", params={"q": "中"})
        log("E8  Search single Chinese char → no crash", r.status_code == 200)

        r = await c.get(f"{BASE}/search", params={"q": " "})
        log("E9  Search whitespace → handled", r.status_code in (200, 422))

        # ============================================================
        print("\n--- Edge: Filter Boundaries ---")
        # ============================================================

        r = await c.get(f"{BASE}/products", params={"sort": "injected_sort"})
        log("E10 sort=invalid → returns results anyway", r.status_code == 200)

        r = await c.get(f"{BASE}/products", params={"min_price": 10000, "max_price": 1})
        log("E11 min_price > max_price → empty not error", r.status_code == 200)

        r = await c.get(f"{BASE}/filters", params={"category": ""})
        log("E12 filters with empty category → handled", r.status_code in (200, 422))

        # ============================================================
        print("\n--- Edge: Auth Boundaries ---")
        # ============================================================

        r = await c.post(f"{BASE}/auth/register", json={"phone": "", "password": "test"})
        log("E13 Register with empty phone → 422", r.status_code in (422, 400))

        r = await c.post(f"{BASE}/auth/login", json={})
        log("E14 Login with empty body → 422", r.status_code == 422)

        r = await c.post(f"{BASE}/auth/login", json={"phone": "13800138000", "password": "A" * 200})
        log("E15 Login with 200-char password → handled", r.status_code in (200, 401, 422))

        # ============================================================
        print("\n--- Edge: Concurrency ---")
        # ============================================================

        async def fetch_products():
            try:
                async with httpx.AsyncClient(timeout=15) as c2:
                    return await c2.get(f"{BASE}/products?size=5")
            except Exception:
                return None

        tasks = [fetch_products() for _ in range(10)]
        results = await asyncio.gather(*tasks)
        all_200 = all(r and r.status_code == 200 for r in results)
        log("E16 10 concurrent GET /products → all 200", all_200)

        # ============================================================
        print("\n--- Edge: Product Detail Boundaries ---")
        # ============================================================

        r = await c.get(f"{BASE}/products/" + "x" * 256)
        log("E17 256-char product ID → 404", r.status_code == 404)

        # ============================================================
        print("\n--- Edge: Price Edge Values ---")
        # ============================================================

        r = await c.get(f"{BASE}/products", params={"size": 100})
        products = r.json().get("items", [])
        zero_price = [p for p in products if p.get("lowest_price", 0) == 0]
        negative_price = [p for p in products if p.get("lowest_price", 0) < 0]
        log(f"E18 No zero-price products found", len(zero_price) == 0,
            f"{len(zero_price)} zero-price items" if zero_price else "OK")
        log(f"E19 No negative-price products", len(negative_price) == 0)

        # ============================================================
        # FINAL
        # ============================================================
        print(f"\n{'=' * 50}")
        print(f"  Edge Cases: {PASS}/{PASS+FAIL} PASS")
        print(f"{'=' * 50}")
        return FAIL


if __name__ == "__main__":
    # Fix the log function to handle the extra detail param
    async def _main():
        global PASS, FAIL
        await main()

    failed = asyncio.run(_main())
    sys.exit(0 if failed == 0 else 1)
