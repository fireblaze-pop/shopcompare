# ShopCompare Backend

FastAPI + SQLAlchemy 后端服务，负责商品数据、搜索、筛选、商品详情、六维评分、收藏、提醒、用户行为、爬虫调度和后台数据管理。

## 技术栈

- Python 3.10+
- FastAPI
- SQLAlchemy
- SQLite
- Pydantic
- pytest + httpx
- Scrapling / BeautifulSoup / Playwright 相关爬虫依赖

## 启动

从项目根目录启动：

```powershell
cd D:\huawei_code\project\shopcompare_codex
python -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
```

或从 `backend` 目录启动：

```powershell
cd D:\huawei_code\project\shopcompare_codex\backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

初始化：

```powershell
pip install -r requirements.txt
python -m app.init_db
```

可选 seed：

```powershell
python -m app.init_db user
python -m app.init_db demo
```

## 数据契约

### 分类

统一类目目录位于 `app/category_catalog.py`。

- 一级类目使用 `category_id`
- 二级类目使用 `sub_category_id`
- `/categories`、`/filters`、`/products` 共用同一份目录
- 无效类目 ID 返回空结果，不回退全库

### 品牌

品牌归一位于 `app/brand_catalog.py`。

- 从标题识别品牌，优先于爬虫原始 `brand` 字段。
- 中英文别名归一，例如 `华为/Huawei/HUAWEI`、`Apple/苹果/iPhone/AirPods`。
- 搜索和筛选返回前会去重，避免同款商品重复展示。

### 商品评分

评分逻辑位于 `app/product_scoring.py`。

- 六维图：性价比、品质、品牌、售后、物流、外观。
- 六维值范围：0-100。
- 综合评分范围：0-5。
- 综合评分由六维图按类目权重加权平均得到。
- 不同类目使用不同权重：
  - 手机数码、电脑办公更重视品质和品牌。
  - 家用电器更重视售后。
  - 食品生鲜更重视物流和品质。
  - 服饰鞋包、美妆个护更重视外观和品牌。

## API

| Endpoint | Method | Description |
|---|---:|---|
| `/health` | GET | 健康检查 |
| `/api/v1/health` | GET | API 健康检查 |
| `/api/v1/products` | GET | 商品列表 |
| `/api/v1/products/{id}` | GET | 商品详情，返回 0-5 综合评分 |
| `/api/v1/products/{id}/prices` | GET | 平台报价 |
| `/api/v1/products/{id}/history` | GET | 价格历史 |
| `/api/v1/products/{id}/dimensions` | GET | 六维商品画像 |
| `/api/v1/categories` | GET | 分类目录 |
| `/api/v1/filters` | GET | 动态筛选项 |
| `/api/v1/search?q=...` | GET | 商品搜索 |
| `/api/v1/search/keywords` | GET | 快捷搜索关键词 |
| `/api/v1/recommendations` | GET | 推荐商品 |
| `/api/v1/hot-products` | GET | 热门商品 |
| `/api/v1/crawler/status` | GET | 爬虫状态 |
| `/api/v1/crawler/run` | POST | 手动触发爬虫 |
| `/api/v1/admin` | GET | 数据管理后台页面 |
| `/api/v1/admin/products` | GET/POST | 后台商品查询和新增 |
| `/api/v1/admin/products/{id}` | GET/PUT/DELETE | 后台商品详情、更新和删除 |
| `/api/v1/admin/products/{id}/listings` | POST | 新增平台报价 |
| `/api/v1/admin/listings/{id}` | PUT/DELETE | 更新或删除平台报价 |

商品列表参数：

| 参数 | 说明 |
|---|---|
| `page` / `size` | 分页 |
| `category_id` | 一级类目 ID |
| `sub_category_id` | 二级类目 ID |
| `category` | 旧兼容参数 |
| `brand` | 品牌，可传逗号分隔 |
| `min_price` / `max_price` | 价格区间 |
| `sort` | `newest`、`price_low`、`rating`、`recommend` |

示例：

```powershell
curl "http://localhost:8000/api/v1/products?category_id=cat1&sub_category_id=sub1&brand=Huawei&min_price=1000&max_price=8000"
curl "http://localhost:8000/api/v1/filters?category_id=cat1"
curl "http://localhost:8000/api/v1/search?q=MateBook"
curl "http://localhost:8000/api/v1/products/p1/dimensions"
```

## 数据管理后台

入口：

```text
http://localhost:8000/api/v1/admin
```

页面能力：

- 按关键词、类目、品牌查询商品。
- 新增商品。
- 编辑商品名称、品牌、类目、价格、图片、描述等字段。
- 删除错误商品；删除时会同步清理平台报价、价格历史、收藏和降价提醒。
- 新增、编辑、删除平台报价。
- 保存商品或报价后会重新计算价格字段和 0-5 综合评分。

当前后台页面没有登录鉴权，建议只在本地开发或可信内网环境使用。

## 爬虫

核心文件：

- `crawler/sources/manmanbuy_search.py`
- `crawler/pipeline/writer.py`
- `crawler/scheduler.py`
- `crawler/bg_service.py`

行为：

- 后端启动且未设置 `SHOPCOMPARE_DISABLE_CRAWLER=1` 时，后台爬虫服务随 FastAPI 生命周期启动。
- 启动后会延迟触发一次采集。
- `/api/v1/crawler/run` 可手动触发采集。
- `/api/v1/search?q=...` 在结果较少时会把关键词加入后台爬虫队列。
- 写库时会根据标题识别品牌、合并重复商品、刷新价格历史和综合评分。

## 测试

```powershell
cd D:\huawei_code\project\shopcompare_codex
python -m pytest backend\tests -q
```

最近一次结果：

```text
60 passed
```

测试覆盖：

- 注册、登录、验证码、刷新 token
- 商品列表、分页、分类、品牌、价格区间、排序
- 商品详情、平台报价、价格历史
- 六维商品画像和 0-5 综合评分
- 动态筛选
- 搜索、低结果爬虫入队
- 品牌别名识别和重复商品去重
- 后台商品和平台报价 CRUD
- 收藏
- 降价提醒

## 环境变量

| 变量 | 说明 |
|---|---|
| `SHOPCOMPARE_DISABLE_CRAWLER=1` | 禁用后台爬虫，测试环境默认设置 |
| `SHOPCOMPARE_ENABLE_DEMO_SEED=1` | 显式启用 demo 商品 seed |

## 注意事项

- App 不会直接启动 Python 爬虫，必须先启动 FastAPI 后端。
- 从项目根目录启动时使用 `backend.app.main:app`；从 `backend` 目录启动时使用 `app.main:app`。
- 旧参数 `category=...` 仍兼容，但新前端主路径使用 `category_id/sub_category_id`。
- 详情页“查看商品”复制的是平台报价中的最低价可用链接；如果爬虫没有拿到 URL，会提示暂无链接。
