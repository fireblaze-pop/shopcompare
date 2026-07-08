# ShopCompare Backend

ShopCompare 后端是 FastAPI + SQLAlchemy 服务，负责商品数据、搜索、动态筛选、收藏、降价提醒、用户行为和爬虫调度。当前版本已整合 Scrapling/慢慢买爬虫，运行时商品数据默认来自爬虫写库。

## 技术栈

- Python 3.10+
- FastAPI
- SQLAlchemy
- SQLite（开发默认）
- JWT：`python-jose`
- 密码哈希：`bcrypt`
- 爬虫：`scrapling[fetchers]` + BeautifulSoup
- 测试：pytest + httpx

## 数据策略

默认运行模式不插入静态商品 seed：

- `python -m app.init_db`：只创建数据库表。
- `python -m app.init_db user`：创建测试账号 `13800000000 / test123456`。
- `python -m app.init_db demo`：显式插入少量 demo 商品，仅用于空库演示和联调。
- pytest 使用独立 fixture 商品数据，不依赖运行库 seed、爬虫或网络。

爬虫写入的数据表：

- `products`
- `platform_listings`
- `price_history`

## 快速开始

```bash
cd backend
pip install -r requirements.txt

# 建表，不插商品
python -m app.init_db

# 可选：测试账号
python -m app.init_db user

# 可选：demo 商品
python -m app.init_db demo

# 启动
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

测试环境禁用后台爬虫：

```bash
set SHOPCOMPARE_DISABLE_CRAWLER=1
pytest tests -v
```

## 爬虫

核心文件：

- `crawler/base/scrapling_base_crawler.py`
- `crawler/sources/manmanbuy_search.py`
- `crawler/pipeline/writer.py`
- `crawler/scheduler.py`
- `crawler/bg_service.py`

运行方式：

```bash
# 通过 API 手动触发
curl -X POST http://localhost:8000/api/v1/crawler/run

# 查看状态
curl http://localhost:8000/api/v1/crawler/status
```

服务正常启动且未设置 `SHOPCOMPARE_DISABLE_CRAWLER=1` 时，后台爬虫服务会随 FastAPI 生命周期启动，并在启动后触发一次延迟爬取。

## API

| Endpoint | Method | Description |
|---|---:|---|
| `/health` | GET | 健康检查 |
| `/api/v1/health` | GET | 前端 base URL 健康检查 |
| `/api/v1/products` | GET | 商品列表，支持分页、分类、品牌、价格区间、排序 |
| `/api/v1/products/{id}` | GET | 商品详情 |
| `/api/v1/products/{id}/prices` | GET | 平台报价 |
| `/api/v1/products/{id}/history` | GET | 价格历史 |
| `/api/v1/categories` | GET | 分类列表 |
| `/api/v1/search?q=...` | GET | 商品搜索 |
| `/api/v1/filters?category=...` | GET | 动态筛选项 |
| `/api/v1/recommendations` | GET | 推荐商品 |
| `/api/v1/hot-products` | GET | 热门商品 |
| `/api/v1/crawler/status` | GET | 爬虫状态 |
| `/api/v1/crawler/run` | POST | 手动触发爬虫 |
| `/api/v1/admin` | GET | 管理后台页面 |

商品列表示例：

```bash
curl "http://localhost:8000/api/v1/products?category=手机数码&brand=华为&min_price=1000&max_price=8000&size=20"
```

筛选项示例：

```bash
curl "http://localhost:8000/api/v1/filters?category=手机数码"
```

搜索示例：

```bash
curl "http://localhost:8000/api/v1/search?q=MateBook"
```

## 测试

```bash
pytest tests -v
```

当前测试覆盖：

- 认证注册/登录/验证码/重置密码/刷新 token
- 商品列表、分页、分类、品牌、价格区间、排序
- 商品详情、平台报价、价格历史
- 动态筛选
- 搜索
- 收藏
- 降价提醒
- 密码哈希，包括长密码兼容

当前回归结果：`44 passed`。

## 注意事项

- 运行库默认纯爬虫数据；不要把测试 fixture 当作运行 seed。
- 如后端空库启动，商品列表为空是预期行为；需要先运行爬虫或显式执行 demo seed。
- GitHub 远程主要使用 `main` 分支，旧 `master` 分支与 `main` 有历史分叉。
