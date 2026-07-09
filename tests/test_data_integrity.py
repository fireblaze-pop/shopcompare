"""
ShopCompare v0.3 — Data Integrity Tests (Layer 2)
Verifies semantic consistency of all data, not just HTTP status codes.
Requires backend running with data.
"""
import httpx
import asyncio
import sys
import re

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

        # ============================================================
        print("=== DATA INTEGRITY: Category Consistency ===")
        # ============================================================
        CATS = ['手机数码', '电脑办公', '家用电器', '美妆个护', '服饰鞋包', '食品生鲜']
        for cat in CATS:
            r = await c.get(f"{BASE}/products", params={"category": cat, "size": 100})
            items = r.json().get("items", [])
            mismatched = [p for p in items if p.get("category") != cat]
            log(f"D1 {cat} category match", len(mismatched) == 0,
                f"{len(mismatched)}/{len(items)} wrong" if mismatched else f"{len(items)} items")

        # ============================================================
        print("\n=== DATA INTEGRITY: Cross-Category Isolation ===")
        # ============================================================
        CROSS = [
            ("Apple", "食品生鲜", "Apple不卖食品"),
            ("茅台", "手机数码", "茅台不卖手机"),
            ("Nike", "家用电器", "Nike不卖电器"),
            ("戴森", "服饰鞋包", "戴森不卖服饰"),
            ("兰蔻", "电脑办公", "兰蔻不卖电脑"),
            ("美的", "食品生鲜", "美的家电不卖食品"),
            ("华为", "食品生鲜", "华为不卖食品"),
        ]
        for brand, cat, reason in CROSS:
            r = await c.get(f"{BASE}/products", params={"brand": brand, "category": cat, "size": 10})
            items = r.json().get("items", [])
            log(f"D2 {reason}: {brand}×{cat}", len(items) == 0,
                f"{len(items)} items leaked" if items else "OK")

        # ============================================================
        print("\n=== DATA INTEGRITY: Image URL Quality ===")
        # ============================================================
        r = await c.get(f"{BASE}/products", params={"size": 100})
        items = r.json().get("items", [])
        no_image = [p["name"][:30] for p in items if not p.get("image_url")]
        bad_format = [p["name"][:30] for p in items if p.get("image_url") and not (
            p["image_url"].startswith("http://") or p["image_url"].startswith("https://")
        )]
        log(f"D3 All {len(items)} products have image_url", len(no_image) == 0,
            f"{len(no_image)} missing" if no_image else "OK")
        log(f"D4 All image_urls are http(s) URLs", len(bad_format) == 0,
            f"{len(bad_format)} bad format" if bad_format else "OK")

        # ============================================================
        print("\n=== DATA INTEGRITY: Price Consistency ===")
        # ============================================================
        r = await c.get(f"{BASE}/products", params={"size": 100})
        all_items = r.json().get("items", [])
        price_errors = 0
        spread_errors = 0
        hist_errors = 0
        for p in all_items:
            lp = p.get("lowest_price", 0)
            hp = p.get("highest_price", 0)
            sp = p.get("price_spread", 0)
            hl = p.get("historical_low", 0)
            if lp > 0 and hp > 0 and lp > hp:
                price_errors += 1
            if abs((hp - lp) - sp) > 1.0 and sp > 0:
                spread_errors += 1
            if hl > 0 and lp > 0 and hl > lp:
                hist_errors += 1
        log(f"D5 lowest_price <= highest_price ({len(all_items)} products)", price_errors == 0,
            f"{price_errors} violations" if price_errors else "OK")
        log(f"D6 price_spread ≈ highest_price - lowest_price", spread_errors == 0,
            f"{spread_errors} mismatches" if spread_errors else "OK")
        log(f"D7 historical_low <= lowest_price", hist_errors == 0,
            f"{hist_errors} violations" if hist_errors else "OK")

        # ============================================================
        print("\n=== DATA INTEGRITY: Platform & Multi-Platform ===")
        # ============================================================
        multi_count = sum(1 for p in all_items if p.get("platform_count", 0) >= 2)
        log(f"D8 Multi-platform products exist", multi_count > 0,
            f"Items with 2+ platforms: {multi_count}/{len(all_items)}")

        r = await c.get(f"{BASE}/products", params={"size": 200})
        all_products = r.json().get("items", [])
        valid_platforms = {"京东", "淘宝", "天猫", "苏宁", "拼多多"}

        # Check detail of a subset for platform listing validity
        detail_errors = 0
        multi_sample = [p["id"] for p in all_products[:20] if p.get("platform_count", 0) >= 2]
        if not multi_sample and all_products:
            multi_sample = [all_products[0]["id"]]

        for pid in multi_sample[:5]:
            r2 = await c.get(f"{BASE}/products/{pid}")
            detail = r2.json()
            listings = detail.get("platform_listings", [])
            for l in listings:
                if l.get("platform") not in valid_platforms:
                    detail_errors += 1
                if l.get("price", 0) <= 0:
                    detail_errors += 1
            computed_lowest = min([l["price"] for l in listings]) if listings else 0
            if abs(computed_lowest - detail.get("lowest_price", 0)) > 0.01:
                detail_errors += 1
        log(f"D9 Platform names valid, prices > 0, lowest_price correct", detail_errors == 0,
            f"{detail_errors} issues in {len(multi_sample[:5])} products")

        # ============================================================
        print("\n=== DATA INTEGRITY: Semantic Checks ===")
        # ============================================================
        r = await c.get(f"{BASE}/products", params={"size": 30})
        sample = r.json().get("items", [])
        semantic_errors = 0
        for p in sample[:15]:
            name_lower = p.get("name", "").lower()
            actual_cat = p.get("category", "")
            if any(k in name_lower for k in ["手机", "iphone", "华为", "mate", "耳机", "平板", "手表"]):
                if actual_cat != "手机数码":
                    semantic_errors += 1
                    log(f"D10 Semantic [{actual_cat}→手机数码?]: {p['name'][:40]}", False, "mismatch")
        if semantic_errors == 0:
            log("D10 手机 keywords → 手机数码 category", True)

        r = await c.get(f"{BASE}/products", params={"size": 50, "category": "食品生鲜"})
        food_items = r.json().get("items", [])
        wrong_in_food = [p for p in food_items if any(
            kw in p.get("name", "").lower() for kw in ["手机", "电脑", "笔记本", "空调", "精华", "面霜", "运动鞋"]
        )]
        log(f"D11 食品生鲜 no tech/beauty/fashion items", len(wrong_in_food) == 0,
            f"{len(wrong_in_food)} suspicious items" if wrong_in_food else "OK")

        # ============================================================
        print("\n=== DATA INTEGRITY: Smart Data ===")
        # ============================================================
        r = await c.get(f"{BASE}/recommendations", params={"size": 30})
        recs = r.json().get("items", [])
        rec_ids = [p["id"] for p in recs]
        dups = len(rec_ids) - len(set(rec_ids))
        log(f"D12 Recommendations have no duplicates", dups == 0,
            f"{dups} duplicates" if dups else "OK")

        if all_products:
            pid = all_products[0]["id"]
            r = await c.get(f"{BASE}/products/{pid}/similar", params={"size": 10})
            similar = r.json().get("items", [])
            expected_cat = all_products[0]["category"]
            wrong = [s for s in similar if s.get("category") != expected_cat]
            log(f"D13 Similar products in same category", len(wrong) == 0,
                f"{len(wrong)}/{len(similar)} cross-category" if wrong else "OK")

            r = await c.get(f"{BASE}/products/{pid}/dimensions")
            dims = r.json().get("dimensions", [])
            ok = len(dims) == 6
            for d in dims:
                if d.get("value", 0) < 0 or d.get("value", 0) > 10:
                    ok = False
            log(f"D14 Radar dimensions 6-dim, values 0-10", ok)

        # ============================================================
        # FINAL
        # ============================================================
        print(f"\n{'=' * 50}")
        print(f"  Data Integrity: {PASS}/{PASS+FAIL} PASS")
        print(f"{'=' * 50}")
        return FAIL

if __name__ == "__main__":
    failed = asyncio.run(main())
    sys.exit(0 if failed == 0 else 1)
