import httpx
import time
import sys

BASE = "http://localhost:8000/api/v1"
BASE_ROOT = "http://localhost:8000"
PHONE = f"138{int(time.time()) % 100000000:08d}"
PASSWORD = "test123456"
TOKEN = ""
PRODUCT_ID = ""

class T:
    def __init__(self): self.passed = 0; self.failed = 0; self.start = time.time()
    def check(self, name, ok, ms): 
        if ok: self.passed += 1; print(f"  [PASS] {name} ({ms}ms)")
        else: self.failed += 1; print(f"  [FAIL] {name}")
    def summary(self):
        elapsed = time.time() - self.start
        print(f"\n{'='*40}\n  结果: {self.passed}/{self.passed+self.failed} PASS  耗时: {elapsed:.1f}s\n{'='*40}")
        return self.failed == 0

t = T()

async def main():
    global TOKEN, PRODUCT_ID
    async with httpx.AsyncClient(timeout=10) as c:
        # === 场景1: 完整用户旅程 ===
        print("\n=== 场景1: 完整用户旅程 ===")
        
        s = time.time()
        r = await c.get(f"{BASE_ROOT}/health")
        t.check("健康检查", r.status_code == 200, int((time.time()-s)*1000))
        
        s = time.time()
        await c.post(f"{BASE}/auth/send-code", json={"phone": PHONE})
        r = await c.post(f"{BASE}/auth/register", json={"phone": PHONE, "password": PASSWORD, "code": "123456"})
        t.check("注册用户", r.status_code == 201, int((time.time()-s)*1000))
        
        s = time.time()
        r = await c.post(f"{BASE}/auth/login", json={"phone": PHONE, "password": PASSWORD})
        ok = r.status_code == 200 and "access_token" in r.json()
        if ok: TOKEN = r.json()["access_token"]
        t.check("密码登录获取Token", ok, int((time.time()-s)*1000))
        
        h = {"Authorization": f"Bearer {TOKEN}"}
        
        s = time.time()
        r = await c.get(f"{BASE}/recommendations?size=5")
        t.check("获取推荐商品", r.status_code == 200 and len(r.json().get("items",[])) > 0, int((time.time()-s)*1000))
        
        s = time.time()
        r = await c.get(f"{BASE}/products?size=5")
        ok = r.status_code == 200
        items = r.json().get("items", [])
        if ok and items:
            PRODUCT_ID = items[0]["id"]
        t.check("获取商品列表", ok and len(items) > 0, int((time.time()-s)*1000))
        
        s = time.time()
        r = await c.get(f"{BASE}/categories")
        cats = r.json()
        t.check("获取品类列表", r.status_code == 200 and len(cats) >= 6, int((time.time()-s)*1000))
        
        s = time.time()
        r = await c.get(f"{BASE}/search", params={"q": "手机"})
        t.check("搜索商品", r.status_code == 200, int((time.time()-s)*1000))
        
        if PRODUCT_ID:
            s = time.time()
            r = await c.get(f"{BASE}/products/{PRODUCT_ID}")
            t.check("商品详情", r.status_code == 200 and r.json().get("name"), int((time.time()-s)*1000))
            
            s = time.time()
            r = await c.get(f"{BASE}/products/{PRODUCT_ID}/prices")
            t.check("多平台价格", r.status_code == 200, int((time.time()-s)*1000))
            
            s = time.time()
            r = await c.get(f"{BASE}/products/{PRODUCT_ID}/dimensions")
            dims = r.json().get("dimensions", [])
            t.check("雷达图评分(6维)", len(dims) == 6, int((time.time()-s)*1000))
            
            s = time.time()
            r = await c.get(f"{BASE}/products/{PRODUCT_ID}/similar")
            t.check("相似商品推荐", r.status_code == 200, int((time.time()-s)*1000))
            
            s = time.time()
            r = await c.post(f"{BASE}/favorites", json={"product_id": PRODUCT_ID}, headers=h)
            t.check("添加收藏", r.status_code == 201, int((time.time()-s)*1000))
            
            s = time.time()
            r = await c.get(f"{BASE}/favorites", headers=h)
            fav_items = r.json().get("items", [])
            t.check("查看收藏列表", len(fav_items) > 0, int((time.time()-s)*1000))
            
            s = time.time()
            fav_id = fav_items[0]["id"] if fav_items else 0
            if fav_id:
                r = await c.delete(f"{BASE}/favorites/{fav_id}", headers=h)
            t.check("取消收藏", r.status_code == 200, int((time.time()-s)*1000))
        
        # === 场景2: 错误与恢复 ===
        print("\n=== 场景2: 错误与恢复 ===")
        
        s = time.time()
        r = await c.post(f"{BASE}/auth/login", json={"phone": PHONE, "password": "wrong"})
        t.check("错误密码拒绝", r.status_code == 401, int((time.time()-s)*1000))
        
        s = time.time()
        r = await c.get(f"{BASE}/favorites")
        t.check("未登录访问受限", r.status_code in (401, 403), int((time.time()-s)*1000))
        
        s = time.time()
        r = await c.post(f"{BASE}/auth/register", json={"phone": PHONE, "password": PASSWORD, "code": "123456"})
        t.check("重复注册拦截", r.status_code in (409, 400), int((time.time()-s)*1000))
        
        s = time.time()
        r = await c.post(f"{BASE}/favorites", json={"product_id": "nonexistent"}, headers=h)
        t.check("收藏不存在商品", r.status_code == 404, int((time.time()-s)*1000))
        
        s = time.time()
        r = await c.get(f"{BASE}/products/nonexistent")
        t.check("不存在商品404", r.status_code == 404, int((time.time()-s)*1000))
        
        # === 场景3: 数据完整性 ===
        print("\n=== 场景3: 数据完整性 ===")
        
        s = time.time()
        r = await c.get(f"{BASE}/products?size=50")
        products = r.json().get("items", [])
        has_images = sum(1 for p in products if p.get("image_url"))
        multi_platform = sum(1 for p in products if p.get("platform_count", 0) >= 1)
        t.check(f"商品有图片({has_images}/{len(products)})", has_images == len(products), int((time.time()-s)*1000))
        t.check(f"多平台报价({multi_platform}/{len(products)})", multi_platform > 0, int((time.time()-s)*1000))
        
        s = time.time()
        r = await c.get(f"{BASE}/filters?category=手机数码")
        filters = r.json()
        t.check("动态筛选选项", len(filters.get("brands",[])) > 0, int((time.time()-s)*1000))
        
        s = time.time()
        r = await c.get(f"{BASE}/crawler/status")
        t.check("爬虫运行状态", r.status_code == 200, int((time.time()-s)*1000))
        
        s = time.time()
        r = await c.get(f"{BASE}/hot-products?size=5")
        t.check("热门商品", r.status_code == 200, int((time.time()-s)*1000))
        
        s = time.time()
        r = await c.get(f"{BASE}/brands/reputation")
        reputations = r.json().get("reputations", {})
        t.check("品牌声誉数据", len(reputations) >= 10, int((time.time()-s)*1000))
        
        s = time.time()
        r = await c.get(f"{BASE}/categories/手机数码/stats")
        stats = r.json()
        t.check("品类价格统计", stats.get("count", 0) > 0, int((time.time()-s)*1000))
        
        # === 场景4: 性能基准 ===
        print("\n=== 场景4: 性能基准 ===")
        
        s = time.time()
        r = await c.get(f"{BASE}/products?size=20")
        ms = int((time.time()-s)*1000)
        t.check(f"商品列表延迟({ms}ms < 500ms)", ms < 500, ms)
        
        s = time.time()
        r = await c.get(f"{BASE}/search", params={"q": "手机"})
        ms = int((time.time()-s)*1000)
        t.check(f"搜索延迟({ms}ms < 800ms)", ms < 800, ms)
        
        s = time.time()
        r = await c.post(f"{BASE}/auth/login", json={"phone": PHONE, "password": PASSWORD})
        ms = int((time.time()-s)*1000)
        t.check(f"登录延迟({ms}ms < 1000ms)", ms < 1000, ms)
    
    return t.summary()

if __name__ == "__main__":
    import asyncio
    ok = asyncio.run(main())
    sys.exit(0 if ok else 1)
