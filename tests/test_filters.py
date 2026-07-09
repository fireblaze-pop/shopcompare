"""
ShopCompare 分类与品牌过滤严格测试
验证: 同一分类内品牌筛选不过串，不同分类间商品不交叉
"""
import httpx
import asyncio
import sys

BASE = "http://localhost:8000/api/v1"
PASS = 0
FAIL = 0


def check(name: str, ok: bool):
    global PASS, FAIL
    if ok:
        PASS += 1
        print(f"  [PASS] {name}")
    else:
        FAIL += 1
        print(f"  [FAIL] {name}")


async def main():
    global PASS, FAIL
    async with httpx.AsyncClient(timeout=15) as c:

        # ====== 测试1: 每个分类内所有商品类别一致 ======
        print("\n=== 测试1: 分类一致性 ===")
        CATS = ['手机数码', '电脑办公', '家用电器', '美妆个护', '服饰鞋包', '食品生鲜']
        for cat in CATS:
            r = await c.get(f"{BASE}/products?category={cat}&size=100")
            items = r.json().get("items", [])
            mismatches = [p['name'][:30] for p in items if p['category'] != cat]
            check(
                f"{cat}: {len(items)}件商品全部属于该分类",
                len(mismatches) == 0
            )
            if mismatches:
                print(f"         错误样本: {mismatches[:3]}")

        # ====== 测试2: 品牌筛选严格匹配 ======
        print("\n=== 测试2: 品牌筛选严格匹配 ===")
        BRAND_TESTS = [
            ("Apple", "手机数码"),
            ("华为", "手机数码"),
            ("戴尔", "电脑办公"),
            ("美的", "家用电器"),
            ("兰蔻", "美妆个护"),
            ("Nike", "服饰鞋包"),
            ("茅台", "食品生鲜"),
        ]
        for brand, cat in BRAND_TESTS:
            r = await c.get(f"{BASE}/products?brand={brand}&category={cat}&size=50")
            items = r.json().get("items", [])
            wrong_cat = [p for p in items if p['category'] != cat]
            wrong_brand = [p for p in items if brand.lower() not in p['brand'].lower()]
            check(
                f"{brand} 在 {cat}: {len(items)}件 — 分类全对 品牌全对",
                len(wrong_cat) == 0 and len(wrong_brand) == 0
            )

        # ====== 测试3: 跨分类品牌不串 ======
        print("\n=== 测试3: 跨分类隔离 ===")
        CROSS_TESTS = [
            ("Apple", "食品生鲜"),  # Apple不卖食品
            ("茅台", "手机数码"),  # 茅台不卖手机
            ("Nike", "家用电器"),  # Nike不卖电器
            ("戴森", "服饰鞋包"),  # 戴森不卖服饰
            ("兰蔻", "电脑办公"),  # 兰蔻不卖电脑
        ]
        for brand, cat in CROSS_TESTS:
            r = await c.get(f"{BASE}/products?brand={brand}&category={cat}&size=50")
            items = r.json().get("items", [])
            check(
                f"{brand} × {cat}: 应为0件",
                len(items) == 0
            )
            if len(items) > 0:
                names = [p['name'][:40] for p in items[:3]]
                print(f"         错误样本: {names}")

        # ====== 测试4: 随机抽查10个商品分类正确 ======
        print("\n=== 测试4: 随机抽查 ===")
        r = await c.get(f"{BASE}/products?size=30")
        items = r.json().get("items", [])
        sample = items[:10] if len(items) >= 10 else items
        all_ok = True
        for p in sample:
            expected_cat = None
            name = p['name'].lower()
            if any(k in name for k in ['手机', 'iphone', '苹果', '华为', 'mate']):
                expected_cat = '手机数码'
            elif any(k in name for k in ['红酒', '茶叶', '牛奶', '饼干', '坚果', '零食', '巧克力']):
                expected_cat = '食品生鲜'
            elif any(k in name for k in ['空调', '冰箱', '吸尘器', '洗衣机', '电饭煲']):
                expected_cat = '家用电器'
            if expected_cat and p['category'] != expected_cat:
                all_ok = False
                print(f"         错配: {p['name'][:50]} -> 应为{expected_cat} 实为{p['category']}")
        check("随机10件商品分类语义匹配", all_ok)

    print(f"\n{'='*40}\n  结果: {PASS}/{PASS+FAIL} PASS\n{'='*40}")
    return FAIL == 0

if __name__ == "__main__":
    ok = asyncio.run(main())
    sys.exit(0 if ok else 1)
