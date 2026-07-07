# ShopCompare — 跨平台商品比价助手

## 项目简介

ShopCompare 是一款基于 **HarmonyOS ArkTS** 的跨平台商品比价工具。用户可以在一个 App 中同时浏览京东、天猫、拼多多、苏宁等多个电商平台的价格，快速找到最低价商品。

**核心价值**：不用在多个 App 之间来回切换比价 —— 一个 App 展示所有平台的价格对比。

---

## 功能特性

| 功能 | 说明 |
|------|------|
| 跨平台比价 | 同一商品展示京东/天猫/拼多多/苏宁 4 个平台的实时价格 |
| 价格走势 | 追踪商品 30 天历史价格，标注历史最低价 |
| 智能推荐 | 基于用户偏好和行为的商品推荐 |
| 六维画像 | 性价比/品质/品牌/售后/物流/外观 雷达图评分 |
| 动态筛选 | 品牌、价格区间、评分、库存状态多维度筛选 |
| 搜索历史 | 自动记录搜索关键词，支持历史回看 |
| 收藏管理 | 收藏商品 + 降价提醒 |
| 暗色模式 | 支持深色/浅色主题一键切换 |
| 隐私保护 | 密码 bcrypt 加密，隐私政策页面 |
| 离线降级 | 后端不可用时自动切换到本地数据模式 |

---

## 技术架构

```
┌─────────────────────────────────────────────────────────────┐
│                    ShopCompare App (HarmonyOS)               │
│                                                             │
│  HttpClient ──────────── HTTP ──────────────►  REST API     │
│  DataProvider (远程/本地切换)                                 │
│  UI: ArkUI 声明式 + @State/@Prop 状态管理                    │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Backend (Python FastAPI)                  │
│                                                             │
│  29 个 API 端点 │ 8 个路由模块                                │
│  PostgreSQL/SQLite │ SQLAlchemy ORM                          │
│  JWT 认证 │ bcrypt 密码哈希                                   │
│  后台爬虫线程 │ 定时价格更新                                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 项目结构

```
ShopCompare_v0.2/
│
├── backend/                          # 服务端项目（独立）
│   ├── app/
│   │   ├── main.py                   # FastAPI 入口，路由注册，后台爬虫生命周期
│   │   ├── database.py               # 数据库连接配置
│   │   ├── init_db.py                # 种子数据：15 件商品 + 平台报价 + 价格历史
│   │   ├── models/
│   │   │   └── models.py             # SQLAlchemy 模型：User/Product/PlatformListing/PriceHistory/Favorite/Alert
│   │   ├── routers/
│   │   │   ├── auth.py               # 认证：注册/登录/发送验证码/重置密码/刷新Token
│   │   │   ├── products.py           # 商品：列表/详情/价格/历史/分类
│   │   │   ├── search.py             # 搜索：关键词搜索
│   │   │   ├── prices.py             # 价格路由
│   │   │   ├── favorites.py          # 收藏：添加/列表/删除
│   │   │   ├── alerts.py             # 降价提醒：创建/列表/删除
│   │   │   ├── smart.py              # 智能功能：推荐/相似商品/雷达图评分/动态筛选/品牌声誉/热门/品类统计
│   │   │   └── behaviors.py          # 用户行为：行为上报/搜索历史
│   │   ├── schemas/
│   │   │   └── user.py               # Pydantic 请求/响应模型
│   │   └── services/
│   │       └── auth_service.py       # JWT 签发/验证 + SMS 验证码生成/校验
│   │
│   ├── crawler/                      # 爬虫模块
│   │   ├── base/
│   │   │   └── base_crawler.py       # 基类：限速/重试/UA轮换/Cookie管理
│   │   ├── sources/
│   │   │   ├── jd_search.py          # 京东搜索爬虫（API 模式下为预留）
│   │   │   └── suning_search.py      # 苏宁搜索爬虫
│   │   ├── pipeline/
│   │   │   └── writer.py             # 数据管线：去重/归一化/写入数据库
│   │   ├── bg_service.py             # 后台爬虫服务：线程管理/定时调度
│   │   ├── scheduler.py              # 全品类爬取调度器
│   │   └── cli.py                    # 命令行入口
│   │
│   ├── tests/                        # 后端测试
│   │   ├── conftest.py               # pytest fixtures
│   │   ├── api/                      # API 测试用例
│   │   └── utils/                    # 工具测试
│   │
│   ├── start_server.bat              # 一键启动脚本（Windows）
│   ├── requirements.txt              # Python 依赖清单
│   └── README.md                     # 服务端文档
│
├── tests/                            # 跨项目集成测试
│   └── run_full_test.py              # 29 个用例的完整用户行为模拟测试
│
├── entry/                            # HarmonyOS 用户端模块
│   └── src/main/
│       ├── module.json5              # 模块配置
│       ├── ets/
│       │   ├── components/           # 可复用 UI 组件（14个）
│       │   ├── data/                 # 数据层（DataProvider/Repository/MockData）
│       │   ├── entryability/         # App 入口
│       │   ├── models/               # 数据模型
│       │   ├── pages/                # 14 个页面
│       │   └── utils/                # 工具类
│       └── resources/                # 资源文件
│
├── build-profile.json5               # 项目构建配置
├── oh-package.json5                  # 项目依赖
└── README.md                         # 本文件
```

---

## 环境搭建

### 系统要求

| 组件 | 版本 |
|------|------|
| Python | 3.10+ |
| DevEco Studio | 5.0.0+ |
| HarmonyOS SDK | API 24 (6.1.1.24) |
| Node.js | 18.x+（DevEco Studio 内置） |
| 操作系统 | Windows 10+ / macOS 12+ |

### 后端环境

```bash
cd backend

# 1. 安装 Python 依赖
pip install -r requirements.txt

# 2. 初始化数据库（创建表 + 导入种子数据）
python -m app.init_db

# 3. 创建测试用户（可选）
python -m app.init_db user
```

### App 环境

1. 安装 DevEco Studio 5.0.0+
2. 打开项目目录 `ShopCompare_v0.2`
3. 等待依赖同步完成（DevEco 自动下载 `oh_modules`）

---

## 快速开始

### 启动后端

```bash
# 方式一：双击启动脚本
backend/start_server.bat

# 方式二：命令行启动
cd backend
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

启动后：
- API 地址：`http://localhost:8000`
- API 文档：`http://localhost:8000/docs`
- 健康检查：`http://localhost:8000/health`
- 爬虫状态：`http://localhost:8000/api/v1/crawler/status`
- 后台爬虫在启动 3 秒后自动运行

### 启动 App

1. DevEco Studio 中打开项目
2. 连接模拟器或真机
3. 点击 **Run** 按钮
4. App 自动安装并启动

**App 连接后端配置**：编辑 `entry/src/main/ets/utils/HttpClient.ets` 中的 `BASE_URL`：
```typescript
// 模拟器
const BASE_URL: string = 'http://localhost:8000/api/v1'

// 真机（替换为你的电脑局域网 IP）
const BASE_URL: string = 'http://192.168.1.xxx:8000/api/v1'
```

### 测试账号

| 手机号 | 密码 |
|--------|------|
| 13800000000 | test123456 |

启动后端后自动创建。也可以在 App 注册页创建新账号。

---

## API 文档

### 认证模块 `/api/v1/auth/`

| 端点 | 方法 | 认证 | 说明 |
|------|------|------|------|
| `/auth/register` | POST | 否 | 手机号 + 验证码 + 密码注册 |
| `/auth/login` | POST | 否 | 密码登录或验证码登录 |
| `/auth/send-code` | POST | 否 | 发送短信验证码（开发环境固定 123456） |
| `/auth/reset-password` | POST | 否 | 验证码重置密码 |
| `/auth/refresh-token` | POST | 否 | 刷新 JWT Token |

**登录请求示例**：
```json
POST /api/v1/auth/login
{
  "phone": "13800000000",
  "password": "test123456"
}
```
**响应**：
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer"
}
```

### 商品模块 `/api/v1/`

| 端点 | 方法 | 参数 | 说明 |
|------|------|------|------|
| `/products` | GET | `?category=&brand=&sort=&page=&size=` | 商品列表（分页+筛选+排序） |
| `/products/{id}` | GET | | 商品详情（含平台报价+价格历史） |
| `/products/{id}/prices` | GET | | 各平台价格 |
| `/products/{id}/history` | GET | `?days=30` | 价格历史 |
| `/products/{id}/similar` | GET | `?size=6` | 相似商品推荐 |
| `/products/{id}/dimensions` | GET | | 六维雷达图评分 |
| `/categories` | GET | | 分类列表 |
| `/categories/{id}/stats` | GET | | 品类价格统计 |
| `/search` | GET | `?q=关键字` | 关键词搜索 |

**商品列表请求示例**：
```
GET /api/v1/products?category=手机数码&sort=price_low&page=1&size=20
```

**商品详情响应示例**：
```json
{
  "id": "p1",
  "name": "iPhone 16 Pro Max",
  "brand": "Apple",
  "category": "手机数码",
  "lowest_price": 8999,
  "highest_price": 9499,
  "price_spread": 500,
  "platform_count": 3,
  "aggregate_rating": 4.8,
  "listings": [
    {"platform": "京东", "price": 8999, "in_stock": true},
    {"platform": "天猫", "price": 9499, "in_stock": true},
    {"platform": "拼多多", "price": 8799, "in_stock": true}
  ],
  "price_history": [
    {"date": "2025-12-01", "price": 9299},
    {"date": "2026-01-01", "price": 8999}
  ]
}
```

### 收藏模块 `/api/v1/favorites/`（需 JWT Token）

| 端点 | 方法 | 说明 |
|------|------|------|
| `/favorites` | POST | 添加收藏 `{"product_id": "p1"}` |
| `/favorites` | GET | 收藏列表 |
| `/favorites/{id}` | DELETE | 取消收藏 |

### 提醒模块 `/api/v1/alerts/`（需 JWT Token）

| 端点 | 方法 | 说明 |
|------|------|------|
| `/alerts` | POST | 关注降价 `{"product_id": "p1", "target_price": 8500}` |
| `/alerts` | GET | 提醒列表 |
| `/alerts/{id}` | DELETE | 取消提醒 |

### 智能功能 `/api/v1/`

| 端点 | 方法 | 说明 |
|------|------|------|
| `/recommendations` | GET | 推荐商品（基于评分+热度） |
| `/hot-products` | GET | 热门商品排行 |
| `/filters` | GET | 动态筛选选项 `?category=手机数码` |
| `/brands/reputation` | GET | 品牌声誉映射表 |

### 系统接口

| 端点 | 方法 | 说明 |
|------|------|------|
| `/` | GET | API 信息 |
| `/health` | GET | 健康检查 |
| `/api/v1/crawler/status` | GET | 爬虫运行状态 |
| `/docs` | GET | Swagger UI 交互式文档 |

---

## 测试

### 集成测试（推荐）

模拟完整用户行为，29 个测试用例：

```bash
# 启动后端
cd backend && uvicorn app.main:app --port 8000

# 运行集成测试
cd tests
pip install httpx
python run_full_test.py
```

**输出示例**：
```
========================================
  ShopCompare 集成测试 — 完整用户模拟
========================================

=== 场景1: 完整用户旅程 ===
  [PASS] 健康检查 (301ms)
  [PASS] 注册用户 (426ms)
  [PASS] 密码登录获取Token (289ms)
  [PASS] 获取推荐商品 (11ms)
  [PASS] 获取商品列表 (12ms)
  [PASS] 获取品类列表 (4ms)
  [PASS] 搜索商品 (20ms)
  ... (共29个用例)

=== 场景4: 性能基准 ===
  [PASS] 商品列表延迟 41ms < 500ms
  [PASS] 搜索延迟 45ms < 800ms
  [PASS] 登录延迟 597ms < 1000ms

───────────────────────────────
  结果: 29/29 PASS   耗时: 2.5s
```

### 后端单元测试

```bash
cd backend
pytest tests/api/ -v
```

### App 编译测试

```bash
hvigorw assembleHap
```

---

## 数据流说明

### 两条数据路径

```
路径 A（App 直接连后端 — 推荐）:
  App → HttpClient → GET /api/v1/products → Backend SQLite → 返回真实数据

路径 B（后端不可用时降级 — 离线可用）:
  App → DataProvider.switchToMock() → MockData.ets → 本地假数据
```

### 种子数据

后端启动时自动加载 15 件种子商品（覆盖 6 个品类），每件商品配备：

| 品类 | 品种数 | 平台报价 |
|------|--------|---------|
| 手机数码 | 4 件 | 京东+天猫+拼多多 |
| 电脑办公 | 3 件 | 京东/天猫 |
| 家用电器 | 2 件 | 京东 |
| 美妆个护 | 1 件 | 京东 |
| 服饰鞋包 | 1 件 | 京东 |
| 食品生鲜 | 5 件 | 京东/天猫 |
| **合计** | **16 件** | |

种子数据在 `backend/app/init_db.py` 中定义，可通过 `python -m app.init_db` 重新导入。

### 后台爬虫

服务器启动后，爬虫自动运行：

```
服务器启动
  ├── 0s: 种子数据立即可用
  ├── 3s: 后台爬虫首次执行（30 个关键词 × 苏宁搜索）
  └── 60min: 定时刷新价格
```

爬虫状态可通过 `GET /api/v1/crawler/status` 查看。

---

## App 页面流程

```
SplashPage (启动页)
    │
    ▼
LoginPage ←→ RegisterPage (注册)
    │
    ├── 首次登录 → QuestionnairePage (偏好问卷)
    │                   │
    └───────────────────┘
            │
            ▼
       HomePage (主页)
    ┌───┼───┬───┐
    ▼   ▼   ▼   ▼
  首页 发现 收藏 我的
    │   │   │   │
    │   │   │   ├── BrowseHistoryPage (浏览历史)
    │   │   │   ├── AboutPage (关于我们)
    │   │   │   ├── PrivacyPage (隐私政策)
    │   │   │   └── 退出登录
    │   │   │
    │   │   └── ProductDetailPage (商品详情)
    │   │         └── 收藏/降价提醒
    │   │
    │   └── CategoryFilterPage (筛选)
    │         └── CompareResultPage (比价列表)
    │               ├── ProductDetailPage
    │               └── CompareTablePage (详细对比表)
    │
    └── SearchPage (搜索)
          └── ProductDetailPage
```

---

## 常见问题

### Q: 为什么 App 登录没反应？

A: 确保后端已启动（双击 `backend/start_server.bat`）。App 的 HTTP 请求需要后端 API 响应。也可点"跳过登录"进入离线模式。

### Q: 为什么商品没有图片？

A: 种子数据使用占位图 URL。爬虫从苏宁获取真实 CDN 图片。图片加载需要网络连接，且部分型号模拟器可能不支持网络图片。

### Q: 怎么切换开发/生产环境？

A: 编辑 `entry/src/main/ets/utils/HttpClient.ets` 中的 `BASE_URL`：
- 本地开发：`http://localhost:8000/api/v1`
- 生产服务器：`https://api.shopcompare.cn/api/v1`

### Q: 爬虫不工作怎么办？

A: 检查 `http://localhost:8000/api/v1/crawler/status`。如果 `running: false`，重新启动后端。JD 搜索可能因反爬机制返回空，苏宁搜索是主要数据来源。

### Q: 数据库在哪？

A: `backend/shopcompare.db`（SQLite 文件）。删除此文件后重新 `python -m app.init_db` 可恢复初始状态。

### Q: 怎么添加新品类？

A: 在 `backend/app/init_db.py` 的 `PRODUCTS` 列表添加新商品，在 `backend/crawler/base/base_crawler.py` 的 `CATEGORY_KEYWORDS` 添加品类关键词。

---

## 部署

### 本地开发

```
1. 启动后端: backend/start_server.bat（或 uvicorn 命令）
2. DevEco 中运行 App → 连接 localhost:8000
3. 修改代码后: uvicorn --reload 自动重载后端
```

### 生产部署（后续）

当准备上架 AppGallery 时：

```
1. 购买华为云 ECS（2C4G，约 ¥91/月）
2. 部署后端: git clone → pip install → systemd 托管
3. 配置 Nginx 反向代理 + HTTPS
4. 数据库从 SQLite 迁移到 PostgreSQL
5. App HttpClient URL 指向生产服务器
```

---

## 技术栈

| 层级 | 技术 |
|------|------|
| 前端框架 | HarmonyOS ArkTS + ArkUI |
| 后端框架 | Python FastAPI |
| 数据库 | SQLite（开发）/ PostgreSQL（生产） |
| ORM | SQLAlchemy |
| 认证 | JWT (python-jose) + bcrypt |
| 测试 | pytest + httpx（后端）/ 集成测试脚本 |
| 构建 | DevEco Studio + hvigor |
| API 文档 | Swagger UI（自动生成） |

---

## 开发规范

- **ArkTS 严格模式**：不使用 `any`/`unknown`/`as` 类型断言
- **组件模式**：使用 `@Component` / `@Entry` 装饰器
- **状态管理**：使用 `@State` / `@Prop` 数据流
- **数据源隔离**：所有页面通过 `DataProvider` 获取数据，不直接 import MockData
- **离线降级**：后端不可用时自动切换到本地数据模式
- **字符串资源**：UI 文本使用 `$r('app.string.xxx')` 引用 `string.json`

---

## 后续规划

| 阶段 | 内容 |
|------|------|
| 当前 | 修复剩余页面数据流（CompareResultPage/ProductDetailPage/HomePage） |
| 短期 | 子分类浏览、筛选滑块 UI、搜索结果筛选 |
| 中期 | 京东联盟 API / 淘宝客 API 接入、真机测试 |
| 长期 | AppGallery 上架、PostgreSQL 迁移、HTTPS 部署 |
