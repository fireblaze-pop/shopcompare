# ShopCompare v0.3 — 跨平台商品比价助手

基于 HarmonyOS ArkTS + Python FastAPI + Scrapling 的全栈比价平台。后端爬虫从电商聚合网站采集真实商品数据（700+ 件），前端通过 REST API 展示跨平台价格对比、智能推荐、六维雷达图评分和多维筛选。

## 项目架构

```
App (HarmonyOS ArkTS)
    │  HTTP REST API
    ▼
Backend (Python FastAPI)
    ├── app/routers/    9 个路由模块
    ├── app/models/     SQLAlchemy ORM
    ├── app/services/   JWT + bcrypt
    └── app/schemas/    Pydantic 校验
    │
    ▼
Crawler (Scrapling + BS4)
    ├── sources/        慢慢买/京东/苏宁 爬虫源
    ├── pipeline/       清洗→去重→入库→评分
    └── bg_service.py   定时调度
    │
    ▼
SQLite (shopcompare.db)
    6 张表：products / users / platform_listings /
            price_history / favorites / alerts
```

## 快速开始

```powershell
cd backend
pip install -r requirements.txt
playwright install chromium
python -m app.init_db
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

DevEco Studio 打开项目 → Run。后端启动后爬虫 3 秒自动运行，首轮采集约 2-3 分钟。

---

## 项目文件结构详解

### 根目录

| 文件 | 说明 |
|------|------|
| `build-profile.json5` | 构建配置：targetSdkVersion 6.1.1(24)、模块声明、debug/release 构建模式 |
| `code-linter.json5` | 代码检查规则：ArkTS 安全加密算法限制、性能推荐规则 |
| `hvigorfile.ts` | Hvigor 构建系统入口，引用 `@ohos/hvigor-ohos-plugin` |
| `oh-package.json5` | 项目依赖声明（@ohos/hypium 测试框架） |
| `oh-package-lock.json5` | 依赖版本锁定 |
| `.gitignore` | Git 忽略规则（构建产物 / __pycache__ / node_modules / .hvigor） |

---

### entry/ — HarmonyOS ArkTS 前端

```
entry/
├── build-profile.json5              # 模块构建配置（stage 模式、混淆规则）
├── hvigorfile.ts                    # 模块级 hvigor 构建入口
├── obfuscation-rules.txt            # 代码混淆规则
├── oh-package.json5                 # 模块依赖
├── .gitignore
│
├── src/main/
│   ├── module.json5                 # 模块配置：页面路由、EntryAbility、INTERNET 权限、
│   │                                #   EntryBackupAbility
│   │
│   ├── ets/                         # ArkTS 源码
│   │   ├── entryability/
│   │   │   └── EntryAbility.ets     # App 生命周期入口：初始化 PreferenceManager、
│   │   │                            #   FeatureExtractor、RecommendationEngine
│   │   │
│   │   ├── entrybackupability/
│   │   │   └── EntryBackupAbility.ets  # 数据备份扩展
│   │   │
│   │   ├── pages/                   # 14 个页面（@Entry 结构体）
│   │   │   ├── Index.ets            # 根页面（模板页面）
│   │   │   ├── SplashPage.ets       # 启动页：渐入动画 + 后端探测 + 数据源切换
│   │   │   ├── LoginPage.ets        # 登录：密码模式 / 验证码模式
│   │   │   ├── RegisterPage.ets     # 注册
│   │   │   ├── HomePage.ets         # 4 Tab 主页（首页/发现/收藏/我的）
│   │   │   ├── CategoryFilterPage.ets  # 品类筛选：品牌+价格区间多选
│   │   │   ├── CompareResultPage.ets   # 比价结果：排序/筛选/商品卡片列表
│   │   │   ├── CompareTablePage.ets    # 横向对比矩阵
│   │   │   ├── ProductDetailPage.ets   # 商品详情：轮播/比价/雷达图/评价/相似推荐
│   │   │   ├── SearchPage.ets          # 搜索：实时搜索+历史+热门关键词
│   │   │   ├── BrowseHistoryPage.ets   # 浏览历史（按时间倒序）
│   │   │   ├── QuestionnairePage.ets   # 偏好问卷（4 步向导：品类/维度/预算/平台）
│   │   │   ├── PrivacyPage.ets         # 隐私政策
│   │   │   └── AboutPage.ets           # 关于页面
│   │   │
│   │   ├── components/              # 29 个可复用组件
│   │   │   ├── ProductCard.ets      # 商品卡片
│   │   │   ├── ProductCompareTable.ets  # 对比表
│   │   │   ├── PriceChart.ets       # 价格走势图
│   │   │   ├── CategoryIconGrid.ets # 分类图标网格
│   │   │   ├── StarRating.ets       # 星级评分
│   │   │   ├── SearchBar.ets        # 搜索栏
│   │   │   ├── RecommendationCard.ets    # 推荐卡片
│   │   │   ├── RecommendationSection.ets # 推荐区域（水平滚动）
│   │   │   ├── RadarChart.ets       # 六维雷达图（Canvas 绘制）
│   │   │   │
│   │   │   ├── home/                # 首页子组件
│   │   │   │   ├── HomeContent.ets       # 首页内容（问候+推荐+分类网格）
│   │   │   │   ├── HomeGreeting.ets      # 个性化问候
│   │   │   │   ├── DiscoverContent.ets   # 发现 Tab
│   │   │   │   ├── DiscoverProductCard.ets # 发现页商品卡片
│   │   │   │   ├── FavoritesContent.ets  # 收藏 Tab
│   │   │   │   ├── FavoriteProductCard.ets # 收藏商品卡片
│   │   │   │   ├── ProfileContent.ets    # 我的 Tab
│   │   │   │   ├── ProfileHeaderCard.ets # 用户信息卡
│   │   │   │   ├── ProfileMenuItem.ets   # 菜单项
│   │   │   │   └── BottomTabItem.ets     # 底部标签
│   │   │   │
│   │   │   ├── search/              # 搜索子组件
│   │   │   │   ├── SearchHeader.ets      # 搜索头部（输入框+返回）
│   │   │   │   ├── SearchKeywordPanel.ets # 热门关键词
│   │   │   │   ├── SearchResultList.ets  # 搜索结果列表
│   │   │   │   └── SearchProductItem.ets # 搜索单条结果
│   │   │   │
│   │   │   └── filter/              # 筛选子组件
│   │   │       ├── FilterGroupCard.ets   # 筛选组卡片
│   │   │       ├── FilterOptionChip.ets  # 筛选选项芯片
│   │   │       └── FilterResultCard.ets  # 筛选结果卡片
│   │   │
│   │   ├── models/                  # TypeScript 数据模型
│   │   │   ├── DataModels.ets       # Product / Category / PlatformListing /
│   │   │   │                        #   FilterGroup / UserProfile / SearchHistory
│   │   │   └── RecommendationModels.ets # RatingRecord / UserVector /
│   │   │                            #   RecommendationItem / RadarDimension
│   │   │
│   │   ├── data/                    # 数据层
│   │   │   ├── MockData.ets         # 离线种子数据（30 件 + 6 品类）
│   │   │   ├── DataProvider.ets     # 数据中心：远程/本地切换 + 仓库管理
│   │   │   ├── RecommendationData.ets # 推荐引擎种子数据
│   │   │   └── repository/          # 仓库模式
│   │   │       ├── ProductRepository.ets      # 仓库接口 + Mock 实现
│   │   │       ├── RemoteProductRepository.ets # HTTP 远程仓库（字段映射）
│   │   │       └── RecommendationDataSource.ets # 推荐数据源
│   │   │
│   │   └── utils/                   # 工具类
│   │       ├── HttpClient.ets       # HTTP 封装（GET/POST/DELETE/PUT + JWT）
│   │       ├── FormatUtils.ets      # 价格千分位格式化
│   │       ├── PreferenceManager.ets # 偏好存储 + RouteParams 路由参数
│   │       ├── BehaviorManager.ets  # 行为追踪 + 隐式评分转换
│   │       ├── FeatureExtractor.ets # 协同过滤特征（共现矩阵 + 物品相似度）
│   │       ├── ProductDimensionScorer.ets # 六维雷达图评分
│   │       └── RecommendationEngine.ets   # 推荐引擎（User-CF/Item-CF/冷启动）
│   │
│   └── resources/                   # 资源文件
│       └── base/
│           ├── element/             # 字符串/颜色/浮点数资源
│           │   ├── string.json      # 107 个 UI 字符串（中文）
│           │   ├── color.json       # 颜色定义
│           │   └── float.json       # 文本大小
│           ├── media/               # 图标资源（36 个 SVG + PNG）
│           │   ├── category_*.svg   # 品类图标（手机/电脑/家电/美妆/服饰/食品）
│           │   ├── detail_*.svg     # 详情页图标（返回/收藏/商品占位/404）
│           │   ├── empty_*.svg      # 空状态图标（收藏/筛选空）
│           │   ├── filter_*.svg     # 筛选图标（返回/空/商品占位/调音）
│           │   ├── icon_*.svg       # 通用图标（返回/右箭头/占位/搜索/取消收藏）
│           │   ├── profile_*.svg    # 我的页图标（头像/铃铛/收藏/历史/信息/月亮/偏好）
│           │   ├── tab_*.svg        # 底部Tab图标（首页/发现/收藏/我的）
│           │   ├── startIcon.png    # 启动图标
│           │   ├── background.png   # 启动背景
│           │   ├── foreground.png   # 前景图层
│           │   └── layered_image.json # 分层图标配置
│           └── profile/
│               ├── main_pages.json  # 14 个页面路由注册
│               └── backup_config.json # 备份配置
│
├── src/ohosTest/                    # 自动化测试模块
│   ├── module.json5                 # 测试模块配置
│   └── ets/test/
│       └── DataLayerFullTest.test.ets # 数据层全量测试
│
└── build-profile.json5              # 模块构建配置
```

---

### backend/ — Python FastAPI 后端 + 爬虫

```
backend/
├── app/                             # FastAPI 应用
│   ├── main.py                      # 入口：注册路由、CORS、爬虫生命周期、/health
│   ├── database.py                  # SQLAlchemy 引擎 + Session + get_db()
│   ├── init_db.py                   # 建表 + 30 件种子数据 + 测试用户
│   ├── category_catalog.py          # 品类目录：6 大类 × 子品类 × 关键词
│   │                                #   resolve_category/find_sub_category/get_categories
│   ├── brand_catalog.py             # 品牌注册：30+ 中英映射（Huawei→华为）
│   │                                #   infer_brand_from_title/normalize_brand/dedupe_products
│   ├── product_scoring.py           # 六维加权评分：外观+物流+售后+品牌+性价比+品质
│   │
│   ├── models/                      # ORM 模型
│   │   └── models.py                # User / Product / PlatformListing / PriceHistory /
│   │                                #   Favorite / Alert
│   ├── schemas/                     # Pydantic 校验
│   │   ├── user.py                  # LoginRequest / RegisterRequest / TokenResponse
│   │   └── product.py               # ProductResponse / ProductDetailResponse /
│   │                                #   ProductListResponse / CategoryResponse
│   ├── services/                    # 业务服务
│   │   └── auth_service.py          # JWT 签发/验证 (HS256 120min) + bcrypt + SMS
│   ├── routers/                     # 9 个路由模块
│   │   ├── products.py              # 商品列表(分页/筛选/排序)、详情、品类、价格统计
│   │   ├── search.py                # 全文搜索(名称/品牌/品类/描述) + 去重 + 触发爬虫
│   │   ├── smart.py                 # 推荐/热门/相似商品/雷达图/筛选选项/品牌声誉
│   │   ├── auth.py                  # 注册/登录/验证码/重置密码/刷新Token
│   │   ├── favorites.py             # 收藏 CRUD（JWT）
│   │   ├── alerts.py                # 降价提醒 CRUD（JWT）
│   │   ├── behaviors.py             # 行为上报 + 搜索历史
│   │   ├── prices.py                # 价格查询
│   │   └── admin.py                 # 后台管理（商品/用户 CRUD + 仪表盘）
│   └── templates/
│       └── admin_dashboard.html     # 后台仪表盘 HTML
│
├── crawler/                         # 爬虫子系统
│   ├── bg_service.py                # 定时服务：30 分钟间隔 × 38 关键词 × 5 页
│   ├── scheduler.py                 # 首次调度：全品类遍历
│   ├── cli.py                       # 命令行入口
│   ├── base/                        # 基类
│   │   ├── base_crawler.py          # 抽象基类
│   │   └── scrapling_base_crawler.py # Scrapling 反反爬（Fetcher/Dynamic/Stealthy + Cookie）
│   ├── sources/                     # 爬虫源
│   │   ├── manmanbuy_search.py      # 慢慢买（主力，38 关键词 × 品牌识别 × 品类映射）
│   │   ├── jd_search.py             # 京东（预留）
│   │   ├── suning_search.py         # 苏宁（预留）
│   │   └── registry.py              # 爬虫注册表
│   └── pipeline/
│       └── writer.py                # 清洗→去重→Upsert→重算价格→六维评分
│
├── tests/                           # 后端测试
│   ├── conftest.py                  # pytest fixtures
│   ├── api/                         # API 测试
│   │   ├── test_products.py         # 商品接口
│   │   ├── test_search.py           # 搜索接口
│   │   ├── test_auth.py             # 认证接口
│   │   ├── test_favorites.py        # 收藏接口
│   │   ├── test_admin.py            # 管理接口
│   │   └── test_alerts.py           # 提醒接口
│   └── utils/
│       └── test_password.py         # 密码加密测试
│
├── crawl_all.py                     # 手动全量爬取脚本
├── score_products.py                # 手动重评分脚本
├── debug_suning.py                  # 苏宁爬虫调试
├── suning_debug.html                # 苏宁调试 HTML
├── requirements.txt                 # Python 依赖
├── start_server.bat                 # Windows 启动脚本
└── README.md                        # 后端文档
```

---

### tests/ — 跨项目集成测试

| 文件 | 用例数 | 说明 |
|------|:------:|------|
| `run_full_test.py` | 29 | 4 场景集成测试（用户旅程/错误恢复/数据完整性/性能基准） |
| `test_user_flow.py` | 25 | 用户路径复刻（启动→登录→首页→筛选→搜索→发现） |
| `test_crawler_pipeline.py` | 79 | 爬虫管线端到端（7 场景：采集→清洗→API→前端模型） |
| `test_full_backend.py` | — | 后端全量 API 测试 |
| `test_api_full.py` | — | 完整 API 输入覆盖 |
| `test_e2e_journeys.py` | — | 用户端到端旅程 |
| `test_filters.py` | — | 筛选逻辑（品类/品牌/价格） |
| `test_data_integrity.py` | — | 数据完整性（FK/去重/孤记录） |
| `test_edge_cases.py` | — | 边界值（空结果/无效输入/极值） |
| `validate_pipeline.py` | — | 数据管线验证 |
| `run_all_tests.py` | — | 测试套件主控 |

---

### AppScope/ — 应用全局配置

| 文件 | 说明 |
|------|------|
| `app.json5` | bundleName: com.example.shopcompare, versionCode: 1000000 |
| `resources/base/element/string.json` | app_name: ShopCompare |
| `resources/base/media/` | 启动图标资源 |

---

## 技术栈

| 层级 | 技术 |
|------|------|
| 前端框架 | HarmonyOS ArkTS + ArkUI (API 24) |
| 后端框架 | Python FastAPI + SQLAlchemy 2.0 + Uvicorn |
| 数据库 | SQLite (shopcompare.db) |
| 爬虫 | Scrapling + BeautifulSoup4 + Playwright |
| 认证 | JWT (python-jose HS256) + bcrypt (passlib) |
| 构建工具 | DevEco Studio + hvigor |
| 前端测试 | ohosTest (DataLayerFullTest) |
| 后端测试 | pytest + httpx |
| 集成测试 | 12 个 Python 测试脚本（130+ 用例） |

## 环境变量

| 变量 | 说明 |
|------|------|
| `SHOPCOMPARE_DISABLE_CRAWLER=1` | 禁用爬虫 |
| `SHOPCOMPARE_ENABLE_DEMO_SEED=1` | 显式启用演示种子 |
