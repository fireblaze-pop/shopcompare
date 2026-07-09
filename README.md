# ShopCompare — 跨平台商品比价助手

**v0.3** | HarmonyOS ArkTS + Python FastAPI | 爬虫驱动真实数据

## 项目简介

ShopCompare 是一款基于 HarmonyOS ArkTS 的全栈跨平台商品比价 App。后端爬虫自动从慢慢买采集真实电商数据（京东/天猫/拼多多），前端通过 REST API 展示商品列表、跨平台比价、六维雷达图、智能筛选和关键词搜索。

**核心价值**：真实爬虫数据驱动，不用手动造数据——后端启动后自动爬取 700+ 件商品。

---

## 快速开始（3 步）

### 1. 安装依赖

```powershell
cd backend
pip install -r requirements.txt
# 安装 Playwright 浏览器（爬虫需要）
playwright install chromium
```

### 2. 初始化数据库

```powershell
python -m app.init_db
# 输出: Demo seed inserted: 30 products / Test user created
```

### 3. 启动后端

```powershell
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

启动后爬虫 3 秒自动运行，从慢慢买抓取 42 个关键词 × 5 页商品。

### 4. 启动 App

DevEco Studio 打开项目 → 连接模拟器 → **Run**

> 首次启动：`module.json5` 已声明 `ohos.permission.INTERNET`，无需额外配置。

### 验证

| 地址 | 说明 |
|------|------|
| `http://localhost:8000/health` | 健康检查 |
| `http://localhost:8000/api/v1/products?size=10` | 商品列表（前 10 件为最新爬虫数据） |
| `http://localhost:8000/docs` | Swagger API 文档 |
| `http://localhost:8000/api/v1/crawler/status` | 爬虫运行状态 |

---

## 功能

| 功能 | 状态 | 数据来源 |
|------|:--:|------|
| 跨平台比价 | ✅ | 爬虫（京东/天猫/拼多多真实价格） |
| 筛选（品牌 + 价格区间） | ✅ | 42 关键词 × 5 页，700+ 件商品 |
| 搜索 | ✅ | 后端全文搜索 + 本地降级 |
| 商品详情 + 雷达图 | ✅ | 六维评分（性价比/品质/品牌/售后/物流/外观） |
| 收藏 | ✅ | JWT 认证 + 本地持久化 |
| 推荐引擎 | ✅ | User-CF + Item-CF + 冷启动 |
| 暗色模式 | ✅ | 一键切换，本地持久化 |
| 离线降级 | ✅ | 后端不可用自动切换 MockData（30 件） |
| 商品图片 | ✅ | 爬虫抓取真实 CDN 图片（99% 覆盖率） |

---

## 项目结构

```
ShopCompare_v0.3/
├── backend/
│   ├── app/                        # FastAPI 应用
│   │   ├── main.py                 # 入口 + 路由注册 + 爬虫生命周期
│   │   ├── database.py             # SQLAlchemy 配置
│   │   ├── init_db.py              # 30 件种子数据 + 测试用户
│   │   ├── models/models.py        # ORM 模型
│   │   ├── routers/                # 8 个路由模块
│   │   │   ├── products.py         # 商品（列表/详情/价格/历史）
│   │   │   ├── search.py           # 搜索
│   │   │   ├── smart.py            # 推荐/雷达图/筛选/品牌声誉
│   │   │   ├── auth.py             # JWT 认证
│   │   │   ├── favorites.py        # 收藏
│   │   │   ├── alerts.py           # 降价提醒
│   │   │   └── behaviors.py        # 行为上报
│   │   └── schemas/                # Pydantic 模型
│   ├── crawler/                    # 爬虫子系统
│   │   ├── base/                   # Scrapling 基类
│   │   ├── sources/                # 慢慢买搜索（42 关键词）
│   │   ├── pipeline/writer.py      # 品牌标准化 + 六维评分
│   │   ├── bg_service.py           # 定时爬虫（30 分钟间隔）
│   │   └── scheduler.py            # 全品类调度（5 页/关键词）
│   ├── requirements.txt
│   └── shopcompare.db              # SQLite 数据库
│
├── entry/src/main/ets/
│   ├── pages/                      # 14 个页面
│   │   ├── SplashPage.ets          # 启动页（探测后端 + 切换数据源）
│   │   ├── HomePage.ets            # 4 Tab 主页
│   │   ├── SearchPage.ets          # 搜索页（API+本地降级）
│   │   ├── CategoryFilterPage.ets  # 筛选页（品牌+价格）
│   │   ├── CompareResultPage.ets   # 比价结果列表
│   │   ├── CompareTablePage.ets    # 横向对比表
│   │   ├── ProductDetailPage.ets   # 商品详情 + 雷达图
│   │   ├── LoginPage.ets           # 登录
│   │   ├── RegisterPage.ets        # 注册
│   │   └── ...                     # 其他
│   ├── components/                 # 组件
│   │   ├── home/                   # 首页子组件（Discover/Favorites/Home/Profile）
│   │   ├── search/                 # 搜索子组件
│   │   ├── filter/                 # 筛选子组件
│   │   └── ...                     # 雷达图/推荐卡片等
│   ├── data/                       # 数据层
│   │   ├── DataProvider.ets        # 远程/本地自动切换
│   │   ├── MockData.ets            # 离线种子数据
│   │   └── repository/             # ProductRepository 接口 + Remote/Mock 实现
│   ├── models/                     # 数据模型
│   └── utils/                      # 推荐引擎/偏好管理/HTTP 客户端
│
└── tests/
    ├── run_full_test.py            # 29 用例集成测试
    ├── test_user_flow.py           # 用户路径复刻测试
    └── test_crawler_pipeline.py    # 爬虫管线端到端测试
```

---

## 数据流

```
用户操作 App
    │
    ▼
DataProvider.getProductRepository()
    │
    ├── SplashPage 探测后端 /products?size=1 → 200
    │       │
    │       ├── 成功 → RemoteProductRepository (700+ 件爬虫数据)
    │       └── 失败 → MockProductRepository (30 件种子数据)
    │
    ▼
页面使用 DataProvider 获取数据
    ├── 首页: 推荐/分类/发现
    ├── 搜索: /search?q=华为
    ├── 筛选: /filters?category=手机数码
    └── 详情: /products/{id}
```

---

## API 接口

### 商品

| 端点 | 方法 | 说明 |
|------|------|------|
| `/products?size=100&sort=newest` | GET | 商品列表（默认最新排序，爬虫数据优先） |
| `/products/{id}` | GET | 商品详情（含平台报价+价格历史） |
| `/products/{id}/prices` | GET | 各平台价格 |
| `/products/{id}/history` | GET | 价格历史 |
| `/products/{id}/similar` | GET | 相似商品 |
| `/products/{id}/dimensions` | GET | 六维雷达图 |
| `/categories` | GET | 6 个品类列表 |
| `/search?q=关键词` | GET | 全文搜索 |
| `/filters?category=品类` | GET | 动态筛选选项（品牌+价格区间） |

### 认证 & 收藏

| 端点 | 方法 | 认证 |
|------|------|:--:|
| `/auth/register` | POST | — |
| `/auth/login` | POST | — |
| `/auth/send-code` | POST | — |
| `/favorites` | GET/POST/DELETE | JWT |
| `/alerts` | GET/POST/DELETE | JWT |

### 系统

| 端点 | 方法 | 说明 |
|------|------|------|
| `/health` | GET | 健康检查 |
| `/api/v1/crawler/status` | GET | 爬虫运行状态 |
| `/api/v1/crawler/run` | POST | 手动触发爬虫 |
| `/docs` | GET | Swagger UI |

---

## 爬虫

### 运行机制

- 服务器启动 3 秒后，18 个基础关键词 × 1 页 首次采集
- 定时任务每 30 分钟按 **42 个关键词 × 5 页** 全量刷新
- 首次采集约 2-3 分钟完成（取决于网络）

### 数据源

- 来源：`s.manmanbuy.com`（慢慢买，真实电商折扣聚合平台）
- 提取字段：商品名 / 品牌 / 品类 / 价格 / 图片 / 平台 / 评价数
- 品牌标准化：Huawei→华为、Dyson→戴森 等中英映射
- 六维评分：外观/物流/售后/品牌/性价比/品质 加权合成

### 关键词覆盖（42 个）

```
手机 耳机 平板 笔记本电脑 鼠标 显示器
空调 冰箱 吸尘器 精华 面霜 防晒
运动鞋 T恤 双肩包 牛奶 坚果 茶叶
充电宝 蓝牙音箱 智能手表 手机壳
打印机 U盘 路由器 投影仪
电饭煲 热水器 微波炉 扫地机器人
面膜 粉底液 眼霜 洗面奶
牛仔裤 羽绒服 连衣裙 睡衣
巧克力 咖啡 饼干 红酒
```

---

## 测试

```powershell
# 29 用例集成测试（模拟完整用户行为）
cd tests && python run_full_test.py

# 爬虫管线端到端测试（79 用例）
cd tests && python test_crawler_pipeline.py

# 用户路径复刻测试（启动→首页→搜索→发现）
cd tests && python test_user_flow.py
```

---

## 技术栈

| 层级 | 技术 |
|------|------|
| 前端 | HarmonyOS ArkTS + ArkUI (API 24) |
| 后端 | Python FastAPI + SQLAlchemy |
| 数据库 | SQLite |
| 爬虫 | Scrapling + BeautifulSoup4 + Playwright |
| 认证 | JWT + bcrypt |
| 构建 | DevEco Studio + hvigor |

---

## 常见问题

**Q: 后端启动后 App 还是 Mock 数据？**
A: 检查 3 点：① `module.json5` 确认有 `ohos.permission.INTERNET` ② 后端 `python -m uvicorn` 跑在 8000 端口 ③ 不要加 `SHOPCOMPARE_DISABLE_CRAWLER=1`

**Q: 搜索闪退？**
A: v0.3 最后一次提交已修复。确保拉取最新代码重新编译。

**Q: 商品没有图片？**
A: 爬虫数据 99% 有图片 URL（来自京东/天猫/拼多多 CDN）。如果全部无图，检查 INTERNET 权限是否已声明。

**Q: 怎么判断是爬虫数据还是种子数据？**
A: 种子数据 ID 以 `demo_` 开头，共 30 件。爬虫数据 ID 是 UUID 格式，商品名带 `【京东/天猫/拼多多】` 前缀。

**Q: 怎么触发重新爬取？**
A: `POST http://localhost:8000/api/v1/crawler/run` 或重启后端。

---

## 环境变量

| 变量 | 说明 |
|------|------|
| `SHOPCOMPARE_DISABLE_CRAWLER=1` | 禁用爬虫（仅用种子数据） |
| `SHOPCOMPARE_ENABLE_DEMO_SEED=1` | 显式启用演示种子（v0.3 已默认启用） |

---

<p align="center">
  <b>ShopCompare v0.3</b><br>
  <sub>Powered by HarmonyOS · Built with ArkTS + FastAPI</sub>
</p>
