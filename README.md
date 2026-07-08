# ShopCompare

ShopCompare 是一个基于 HarmonyOS ArkTS + Python FastAPI 的跨平台商品比价项目。当前 `main` 分支保留新版 ArkTS 前端页面，并整合了爬虫版后端能力：后端通过爬虫采集商品、平台报价、价格历史和商品图片，前端通过 REST API 读取商品数据，同时保留本地 Mock 作为离线降级。

## 当前状态

- 前端：HarmonyOS ArkTS，包含首页、搜索、分类筛选、结果页、对比表、商品详情、收藏、推荐、雷达图等页面。
- 后端：FastAPI + SQLAlchemy + SQLite，提供商品、搜索、筛选、收藏、降价提醒、行为上报、后台管理和爬虫接口。
- 爬虫：已整合 Scrapling/慢慢买搜索爬虫，写入 `products`、`platform_listings`、`price_history`。
- 数据策略：运行库默认不插入静态商品 seed，商品数据以爬虫写入为准；开发演示可显式插入 demo seed。
- 测试：后端 pytest 使用独立 fixture 数据，不依赖爬虫、网络或运行库 seed。

## 目录结构

```text
shopcompare_codex/
├── entry/                         # HarmonyOS ArkTS 前端
│   └── src/main/ets/
│       ├── components/            # UI 组件
│       ├── data/                  # MockData、DataProvider、Repository
│       ├── models/                # 前端数据模型
│       ├── pages/                 # 页面
│       └── utils/                 # 工具和推荐算法
├── backend/                       # Python FastAPI 后端
│   ├── app/
│   │   ├── main.py                # FastAPI 入口、路由、爬虫生命周期
│   │   ├── init_db.py             # 建表、测试账号、可选 demo seed
│   │   ├── models/                # SQLAlchemy 模型
│   │   ├── routers/               # API 路由
│   │   ├── schemas/               # Pydantic schema
│   │   ├── services/              # 认证等服务
│   │   └── templates/             # 管理后台页面
│   ├── crawler/
│   │   ├── base/                  # Scrapling 基类
│   │   ├── sources/               # 慢慢买数据源
│   │   ├── pipeline/              # 写库和评分逻辑
│   │   ├── bg_service.py          # 后台爬虫线程
│   │   └── scheduler.py           # 全量爬取调度
│   ├── tests/                     # 后端测试
│   └── requirements.txt
├── build-profile.json5
├── oh-package.json5
└── README.md
```

## 后端快速开始

```bash
cd backend
pip install -r requirements.txt

# 默认只建表，不插入商品 seed
python -m app.init_db

# 可选：创建测试账号 13800000000 / test123456
python -m app.init_db user

# 可选：开发演示数据，显式插入少量带真实图片 URL 的 demo 商品
python -m app.init_db demo

# 启动后端
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

后端启动后：

- API 文档：`http://localhost:8000/docs`
- 健康检查：`http://localhost:8000/health`
- 前端兼容健康检查：`http://localhost:8000/api/v1/health`
- 爬虫状态：`http://localhost:8000/api/v1/crawler/status`
- 管理后台：`http://localhost:8000/api/v1/admin`

测试或调试时如需禁用后台爬虫：

```bash
set SHOPCOMPARE_DISABLE_CRAWLER=1
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## 数据策略

运行时数据库默认采用纯爬虫数据：

- `python -m app.init_db` 只创建表，不插入商品。
- 爬虫采集的商品会写入商品表、平台报价表和价格历史表。
- 测试数据由 pytest fixture 显式创建，不污染运行库。
- `python -m app.init_db demo` 仅用于空库演示和联调，不作为生产默认数据。

## 主要 API

| Endpoint | Method | Description |
|---|---:|---|
| `/health` | GET | 后端健康检查 |
| `/api/v1/health` | GET | 前端 base URL 下的健康检查 |
| `/api/v1/products` | GET | 商品列表，支持 `category`、`brand`、`min_price`、`max_price`、`sort`、`page`、`size` |
| `/api/v1/products/{id}` | GET | 商品详情，包含平台报价、价格历史、标签等 |
| `/api/v1/products/{id}/prices` | GET | 平台报价 |
| `/api/v1/products/{id}/history` | GET | 价格历史 |
| `/api/v1/categories` | GET | 分类列表 |
| `/api/v1/search?q=...` | GET | 后端商品搜索 |
| `/api/v1/filters?category=...` | GET | 动态筛选数据，返回品牌计数和固定价格区间 |
| `/api/v1/crawler/status` | GET | 爬虫状态 |
| `/api/v1/crawler/run` | POST | 手动触发同步爬取 |
| `/api/v1/admin` | GET | 后台管理页面 |

## 后端测试

```bash
pytest backend/tests -v
```

当前回归状态：

- 后端测试：`44 passed`
- 已覆盖认证、商品列表/详情、价格过滤、筛选、搜索、收藏、降价提醒和密码哈希。

## 前端运行

1. 使用 DevEco Studio 打开项目根目录。
2. 等待 `oh_modules` 同步。
3. 根据模拟器/真机环境检查 `entry/src/main/ets/utils/HttpClient.ets` 中的后端地址。
4. 运行 App。

常见后端地址：

```typescript
// 模拟器常用
http://10.0.2.2:8000/api/v1

// 真机需要使用电脑局域网 IP
http://192.168.x.x:8000/api/v1
```

## 搜索与筛选说明

- 搜索应优先走后端 `/api/v1/search`，确保能搜索到爬虫写入数据库的商品。
- 分类筛选使用 `/api/v1/filters?category=...` 获取品牌计数和价格区间。
- 商品列表使用 `/api/v1/products` 的 `brand/min_price/max_price` 参数进行远程过滤。

## Git 分支说明

当前远程主要使用 `main` 分支。历史上还存在 `master` 分支，内容与 `main` 有分叉；本项目当前整合提交已推送到 `origin/main`。
