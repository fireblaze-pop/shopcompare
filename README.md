# ShopCompare

HarmonyOS ArkTS + Python FastAPI 的跨平台商品比价应用。

当前版本重点支持真实爬虫数据、搜索与筛选接口契约化、商品详情页、六维商品画像、收藏、推荐、历史价格和后端自动降级。

## 功能概览

| 模块 | 当前行为 |
|---|---|
| 商品列表 | 后端 `/api/v1/products` 返回去重后的商品，支持分页、分类、品牌、价格区间、排序 |
| 搜索 | `/api/v1/search?q=...` 搜索 `name/brand/category/description`，结果返回前去重；低结果搜索会触发实时爬虫队列 |
| 快捷关键词 | `/api/v1/search/keywords` 基于商品库与类目生成快捷搜索词 |
| 筛选 | `/api/v1/filters` 返回品牌、结构化价格区间、二级分类和商品数量 |
| 多级分类 | 后端统一类目目录：一级类目 + 二级类目，前端使用稳定 `category_id/sub_category_id` |
| 品牌识别 | 本地品牌别名目录从标题推断品牌，`华为/Huawei`、`Apple/苹果/iPhone` 等会归一 |
| 商品详情 | 展示价格、历史、平台报价、评价标签、商品画像、相似商品 |
| 查看商品 | 商品详情页“查看商品”按钮复制最低价平台商品链接到手机剪贴板 |
| 商品画像 | 六维图使用类目权重、价格分位、评价置信度、平台数、库存率、品牌声誉等综合计算 |
| 综合评分 | 详情页综合分为 0-5 分，由六维图按类目权重加权平均得到 |
| 爬虫 | FastAPI 启动后可自动启动后台爬虫，也可手动触发；搜索低结果时可实时入队 |
| 数据管理 | `/api/v1/admin` 提供可视化后台，支持商品和平台报价增删查改 |

## 快速启动

建议从项目根目录启动后端，避免 `No module named 'app'`：

```powershell
cd D:\huawei_code\project\shopcompare_codex
python -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
```

如果你进入了 `backend` 目录，则使用：

```powershell
cd D:\huawei_code\project\shopcompare_codex\backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

前端使用 DevEco Studio 打开项目，连接模拟器或真机后运行 `entry` 模块。

## 后端初始化

```powershell
cd D:\huawei_code\project\shopcompare_codex\backend
pip install -r requirements.txt
python -m app.init_db
```

可选：

```powershell
python -m app.init_db user
python -m app.init_db demo
```

## 爬虫

后端启动时，如果没有设置 `SHOPCOMPARE_DISABLE_CRAWLER=1` 且爬虫依赖可用，会随 FastAPI 生命周期启动后台爬虫，并在启动后延迟触发一次采集。

常用接口：

```powershell
curl http://localhost:8000/api/v1/crawler/status
curl -X POST http://localhost:8000/api/v1/crawler/run
```

搜索结果过少时，`/api/v1/search?q=关键词` 会把关键词加入后台爬虫队列。爬虫写入商品时会：

- 从商品标题匹配本地品牌别名，统一中英文商标。
- 使用规范标题 + 规范品牌 + 类目匹配已有商品，减少重复入库。
- 刷新平台报价、历史价格和 0-5 分综合评分。

## API 摘要

| Endpoint | 方法 | 说明 |
|---|---:|---|
| `/health` | GET | 健康检查 |
| `/api/v1/products` | GET | 商品列表，支持 `category_id/sub_category_id/brand/min_price/max_price/sort` |
| `/api/v1/products/{id}` | GET | 商品详情，综合评分为 0-5 分 |
| `/api/v1/products/{id}/prices` | GET | 平台报价 |
| `/api/v1/products/{id}/history` | GET | 价格历史 |
| `/api/v1/products/{id}/dimensions` | GET | 六维商品画像 |
| `/api/v1/categories` | GET | 一级类目与二级类目 |
| `/api/v1/filters` | GET | 品牌、价格区间、二级类目筛选项 |
| `/api/v1/search?q=...` | GET | 搜索商品并在低结果时入队爬虫 |
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

示例：

```powershell
curl "http://localhost:8000/api/v1/products?category_id=cat1&sub_category_id=sub1&brand=Huawei&min_price=1000&max_price=8000&sort=price_low"
curl "http://localhost:8000/api/v1/filters?category_id=cat1"
curl "http://localhost:8000/api/v1/search?q=荣耀"
```

## 项目结构

```text
backend/
  app/
    brand_catalog.py        # 品牌别名归一与商品去重
    category_catalog.py     # 一级/二级类目目录
    product_scoring.py      # 六维图与 0-5 综合评分
    routers/                # FastAPI 路由
    models/                 # SQLAlchemy 模型
    schemas/                # Pydantic 响应模型
  crawler/
    sources/                # 爬虫数据源
    pipeline/writer.py      # 爬虫写库、品牌识别、评分刷新
    bg_service.py           # 后台爬虫队列
    scheduler.py            # 定时采集

entry/src/main/ets/
  pages/
    SearchPage.ets
    CategoryFilterPage.ets
    CompareResultPage.ets
    ProductDetailPage.ets   # 商品详情、复制商品链接
  data/repository/
    ProductRepository.ets
    RemoteProductRepository.ets
  utils/
    ProductDimensionScorer.ets
    PreferenceManager.ets
```

## 验证命令

```powershell
python -m pytest backend\tests -q

$env:DEVECO_SDK_HOME='D:\huawei_code\DevEco Studio\sdk'
& 'D:\huawei_code\DevEco Studio\tools\node\node.exe' 'D:\huawei_code\DevEco Studio\tools\hvigor\bin\hvigorw.js' assembleApp --no-daemon
```

最近一次验证结果：

- 后端：`57 passed`
- 新增后台 CRUD 后端验证：`60 passed`
- 前端：`BUILD SUCCESSFUL`

## 环境变量

| 变量 | 说明 |
|---|---|
| `SHOPCOMPARE_DISABLE_CRAWLER=1` | 禁用后台爬虫 |
| `SHOPCOMPARE_ENABLE_DEMO_SEED=1` | 显式启用 demo seed |

## 常见问题

**后端启动报 `No module named 'app'`**

从项目根目录运行 `python -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000`，或者进入 `backend` 目录后运行 `python -m uvicorn app.main:app --host 0.0.0.0 --port 8000`。

**为什么启动 App 后爬虫没有启动**

先确认后端已经启动；App 本身不会启动 Python 爬虫。爬虫随 FastAPI 后端生命周期启动，并受 `SHOPCOMPARE_DISABLE_CRAWLER` 和爬虫依赖是否安装影响。

**为什么筛选“华为”会混入 OPPO 或 Apple**

已通过标题品牌识别修复。接口会按本地品牌别名目录推断规范品牌，再执行品牌过滤。

**为什么搜索或筛选会出现重复商品**

接口返回前会使用规范品牌 + 类目 + 规范标题去重；新爬取商品写库时也会尽量合并到已有商品。
