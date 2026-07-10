# ShopCompare v0.3 — 跨平台商品比价助手

基于 HarmonyOS ArkTS + Python FastAPI + Scrapling 的全栈比价平台。后端爬虫从电商网站采集真实商品数据，前端通过 REST API 展示跨平台价格对比、智能推荐、六维雷达图评分和关键词搜索。

## 项目架构

```
┌─────────────────────────────────────────────────┐
│  entry/src/main/ets/   (ArkTS 前端)              │
│  pages/  components/  models/  data/  utils/     │
├─────────────────────────────────────────────────┤
│  HTTP (REST API)                                  │
├─────────────────────────────────────────────────┤
│  backend/app/          (FastAPI 后端)             │
│  routers/  models/  schemas/  services/           │
├─────────────────────────────────────────────────┤
│  backend/crawler/      (爬虫引擎)                │
│  sources/  pipeline/  base/  bg_service.py       │
├─────────────────────────────────────────────────┤
│  shopcompare.db        (SQLite 数据库)            │
└─────────────────────────────────────────────────┘
```

## 快速开始

```powershell
# 1. 安装依赖
cd backend
pip install -r requirements.txt
playwright install chromium

# 2. 初始化数据库
python -m app.init_db

# 3. 启动后端
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000

# 4. DevEco Studio 打开项目 → Run
```

## 项目文件结构

### 根目录

| 文件 | 功能说明 |
|------|----------|
| `build-profile.json5` | 项目构建配置（SDK 版本、模块声明、签名配置、构建模式） |
| `code-linter.json5` | 代码风格检查规则配置，覆盖 ATS/TypeScript 安全规则 |
| `hvigorfile.ts` | Hvigor 构建系统入口脚本（HarmonyOS 官方构建工具） |
| `oh-package.json5` | 项目级依赖声明（@ohos/hypium 测试框架等） |
| `oh-package-lock.json5` | 依赖版本锁定文件 |
| `.gitignore` | Git 忽略规则（排除构建产物、__pycache__、node_modules） |
| `README.md` | 本文档 |
| `shopcompare.db` | SQLite 数据库文件（运行时生成，含商品/用户/报价/收藏等表） |

### entry/ — HarmonyOS 前端模块

```
entry/
├── src/main/
│   ├── module.json5          # 模块配置（页面路由、权限声明、Ability 定义）
│   ├── ets/
│   │   ├── entryability/
│   │   │   └── EntryAbility.ets         # App 入口，初始化偏好/特征提取/推荐引擎
│   │   ├── entrybackupability/
│   │   │   └── EntryBackupAbility.ets   # 数据备份扩展能力
│   │   ├── pages/                        # 14 个页面
│   │   │   ├── Index.ets                 # 根页面容器
│   │   │   ├── SplashPage.ets            # 启动页，动画过渡 + 后端探测 + 数据源切换
│   │   │   ├── LoginPage.ets             # 登录页（密码/验证码双模式）
│   │   │   ├── RegisterPage.ets          # 注册页
│   │   │   ├── HomePage.ets              # 主页（4 Tab：首页/发现/收藏/我的）
│   │   │   ├── CategoryFilterPage.ets    # 品类筛选（品牌多选 + 价格区间）
│   │   │   ├── CompareResultPage.ets     # 比价结果列表（排序/筛选/最低价高亮）
│   │   │   ├── CompareTablePage.ets      # 多商品横向对比表
│   │   │   ├── ProductDetailPage.ets     # 商品详情（轮播/比价/雷达图/评价/相似推荐）
│   │   │   ├── SearchPage.ets            # 搜索页（实时搜索 + 历史 + 热门关键词）
│   │   │   ├── BrowseHistoryPage.ets     # 浏览历史时间线
│   │   │   ├── QuestionnairePage.ets     # 首次偏好问卷（4 步向导）
│   │   │   ├── PrivacyPage.ets           # 隐私政策页
│   │   │   └── AboutPage.ets             # 关于页（版本/技术栈/联系方式）
│   │   │
│   │   ├── components/                   # 29 个可复用 UI 组件
│   │   │   ├── ProductCard.ets           # 商品卡片（图片/名称/价格/平台标识）
│   │   │   ├── ProductCompareTable.ets   # 商品对比表格（规格行 × 商品列）
│   │   │   ├── PriceChart.ets            # 价格走势图（柱状图/折线图）
│   │   │   ├── CategoryIconGrid.ets      # 品类图标网格
│   │   │   ├── StarRating.ets            # 星级评分组件
│   │   │   ├── SearchBar.ets             # 搜索输入栏
│   │   │   ├── RecommendationCard.ets    # 推荐商品卡片
│   │   │   ├── RecommendationSection.ets # 推荐区域容器（水平滚动）
│   │   │   ├── RadarChart.ets            # 六维雷达图（Canvas 绘制）
│   │   │   ├── home/                     # 首页子组件
│   │   │   │   ├── HomeContent.ets       # 首页内容聚合（问候 + 推荐 + 分类）
│   │   │   │   ├── HomeGreeting.ets      # 个性化问候头部
│   │   │   │   ├── DiscoverContent.ets   # 发现 Tab—全部商品列表
│   │   │   │   ├── DiscoverProductCard.ets # 发现页商品卡片
│   │   │   │   ├── FavoritesContent.ets  # 收藏 Tab—已收藏商品列表
│   │   │   │   ├── FavoriteProductCard.ets # 收藏页商品卡片
│   │   │   │   ├── ProfileContent.ets    # 我的 Tab—菜单/设置
│   │   │   │   ├── ProfileHeaderCard.ets # 用户头像/名称信息卡
│   │   │   │   ├── ProfileMenuItem.ets   # 设置菜单单项
│   │   │   │   └── BottomTabItem.ets     # 底部导航标签项
│   │   │   ├── search/                   # 搜索子组件
│   │   │   │   ├── SearchHeader.ets      # 搜索页头部（输入框 + 返回/取消）
│   │   │   │   ├── SearchKeywordPanel.ets # 热门搜索关键词面板
│   │   │   │   ├── SearchResultList.ets  # 搜索结果列表（懒加载）
│   │   │   │   └── SearchProductItem.ets # 搜索单条结果行
│   │   │   └── filter/                   # 筛选子组件
│   │   │       ├── FilterGroupCard.ets   # 筛选组卡片（可展开/折叠）
│   │   │       ├── FilterOptionChip.ets  # 筛选选项标签（选中/未选中）
│   │   │       └── FilterResultCard.ets  # 筛选后结果卡片
│   │   │
│   │   ├── models/                       # 数据模型层（TypeScript 接口定义）
│   │   │   ├── DataModels.ets            # 核心数据模型：Product/Category/FilterGroup/
│   │   │   │                              #   PlatformListing/UserProfile/SearchHistory
│   │   │   └── RecommendationModels.ets  # 推荐模型：RatingRecord/UserVector/
│   │   │                                  #   RecommendationItem/RadarDimension
│   │   │
│   │   ├── data/                         # 数据访问层
│   │   │   ├── MockData.ets              # 离线种子数据（30 件商品 + 6 品类）
│   │   │   ├── DataProvider.ets          # 数据中心（远程/本地自动切换 + 仓库管理）
│   │   │   ├── RecommendationData.ets    # 推荐引擎种子数据（评分矩阵/用户画像）
│   │   │   └── repository/               # 仓库模式实现
│   │   │       ├── ProductRepository.ets       # 仓库接口 + Mock 实现
│   │   │       ├── RemoteProductRepository.ets # HTTP 远程仓库（snake_case→camelCase 映射）
│   │   │       └── RecommendationDataSource.ets # 推荐数据源接口 + 内嵌实现
│   │   │
│   │   └── utils/                        # 工具类
│   │       ├── HttpClient.ets            # HTTP 客户端封装（GET/POST/DELETE/PUT + JWT）
│   │       ├── FormatUtils.ets           # 格式化工具（价格千分位 ¥）
│   │       ├── PreferenceManager.ets     # 偏好存储（收藏/暗色模式/搜索历史/RouteParams）
│   │       ├── BehaviorManager.ets       # 用户行为追踪 + 隐式评分转换
│   │       ├── FeatureExtractor.ets      # 协同过滤特征提取（共现矩阵 + 物品相似度）
│   │       ├── ProductDimensionScorer.ets # 六维雷达图评分算法
│   │       └── RecommendationEngine.ets  # 推荐引擎（User-CF + Item-CF + 冷启动 + 热门降级）
│   │
│   └── resources/
│       └── base/
│           ├── element/                   # 字符串/颜色/尺寸资源
│           ├── media/                     # 图标/启动图资源
│           └── profile/
│               ├── main_pages.json       # 页面路由注册表
│               └── backup_config.json    # 备份配置
```

### backend/ — Python FastAPI 后端

```
backend/
├── app/                                  # 应用核心
│   ├── main.py                           # FastAPI 入口：注册 9 个路由模块、CORS、
│   │                                     #   爬虫生命周期管理、/health 端点
│   ├── database.py                       # SQLAlchemy 引擎配置（SQLite）、
│   │                                     #   SessionLocal 工厂、get_db() 依赖注入
│   ├── init_db.py                        # 数据库初始化：建表 + 30 件种子数据导入 +
│   │                                     #   测试用户创建（13800000000 / test123456）
│   ├── category_catalog.py               # 品类目录：6 大品类 × 子品类 + 关键词匹配
│   │                                     #   提供 resolve_category/apply_sub_category_filter
│   ├── brand_catalog.py                  # 品牌注册表：30+ 中英品牌别名映射（Huawei→华为）
│   │                                     #   提供 infer_brand_from_title/normalize_brand
│   ├── product_scoring.py                # 六维加权评分算法（外观×0.10+物流×0.15+
│   │                                     #   售后×0.15+品牌×0.20+性价比×0.25+品质×0.15）
│   │
│   ├── models/                           # 数据模型层
│   │   └── models.py                     # SQLAlchemy ORM 模型：User/Product/
│   │                                     #   PlatformListing/PriceHistory/Favorite/Alert
│   │
│   ├── schemas/                          # 请求/响应模式
│   │   ├── user.py                       # Pydantic 模型：LoginRequest/RegisterRequest/
│   │   │                                 #   TokenResponse/SendCodeRequest
│   │   └── product.py                    # Pydantic 模型：ProductResponse/
│   │                                     #   ProductDetailResponse/ProductListResponse
│   │
│   ├── services/                         # 业务服务层
│   │   └── auth_service.py               # JWT 签发/验证（HS256, 120min）+
│   │                                     #   bcrypt 密码哈希 + SMS 验证码生成
│   │
│   ├── routers/                          # 路由层（9 个模块）
│   │   ├── products.py                   # 商品：列表（分页/筛选/排序）、详情（含平台
│   │   │                                 #   报价+价格历史）、品类列表、价格统计
│   │   ├── search.py                     # 搜索：全文匹配（名称/品牌/品类/描述）+
│   │   │                                 #   去重 + 结果少时自动触发爬虫关键词队列
│   │   ├── smart.py                      # 智能：推荐/热门/相似商品/雷达图维度/
│   │   │                                 #   动态筛选选项/品牌声誉
│   │   ├── auth.py                       # 认证：注册/登录/验证码/重置密码/刷新Token
│   │   ├── favorites.py                  # 收藏：添加/列表/删除（JWT 鉴权）
│   │   ├── alerts.py                     # 降价提醒：创建/列表/删除（JWT 鉴权）
│   │   ├── behaviors.py                  # 行为：上报（浏览/点击/收藏/搜索）+
│   │   │                                 #   搜索历史记录
│   │   ├── prices.py                     # 价格：各平台价格查询、价格历史
│   │   └── admin.py                      # 管理：商品 CRUD、用户管理、后台仪表盘
│   │
│   └── templates/                        # HTML 模板
│       └── admin_dashboard.html          # 后台管理仪表盘页面
│
├── crawler/                              # 爬虫子系统
│   ├── bg_service.py                     # 后台定时服务：30 分钟间隔遍历关键词，
│   │                                     #   支持按需关键词队列（搜索无结果时自动加入）
│   ├── scheduler.py                      # 全品类调度器：遍历 38 个关键词 × 5 页
│   ├── cli.py                            # 命令行入口：手动触发/状态查询
│   │
│   ├── base/                             # 爬虫基类
│   │   ├── base_crawler.py               # 抽象基类（定义 search/parse 接口）
│   │   └── scrapling_base_crawler.py     # Scrapling 反反爬基类（Fetcher/
│   │                                     #   DynamicFetcher/StealthyFetcher +
│   │                                     #   Cookie 注入 + UA 轮换 + 重试）
│   │
│   ├── sources/                          # 爬虫源
│   │   ├── manmanbuy_search.py           # 慢慢买搜索爬虫（主力数据源，38 关键词）
│   │   ├── jd_search.py                  # 京东搜索爬虫（预留）
│   │   ├── suning_search.py             # 苏宁搜索爬虫（预留）
│   │   └── registry.py                   # 爬虫注册表（平台名→爬虫类映射）
│   │
│   └── pipeline/                         # 数据管线
│       └── writer.py                     # 写入管线：品牌标准化→去重检查（精确/子串/
│                                         #   关键词匹配）→Upsert 商品/平台报价/
│                                         #   价格历史→重算价格区间→六维评分合成
│
├── requirements.txt                      # Python 依赖清单
├── start_server.bat                      # Windows 一键启动脚本
└── README.md                             # 后端文档
```

### tests/ — 测试脚本

| 文件 | 用例数 | 功能说明 |
|------|:------:|----------|
| `run_full_test.py` | 29 | 完整集成测试：4 场景（用户旅程/错误恢复/数据完整性/性能基准） |
| `test_user_flow.py` | 25 | 用户路径复刻测试：启动→登录→首页→筛选→搜索→发现 |
| `test_crawler_pipeline.py` | 79 | 爬虫管线端到端：7 场景（采集→清洗→写入→API→前端模型） |
| `test_full_backend.py` | — | 后端全量测试（覆盖所有 API 端点） |
| `test_api_full.py` | — | API 完整测试（各种输入组合） |
| `test_e2e_journeys.py` | — | 端到端用户旅程测试（搜索→比价→收藏→提醒） |
| `test_filters.py` | — | 筛选逻辑测试（品类/品牌/价格区间） |
| `test_data_integrity.py` | — | 数据完整性测试（外键约束/孤儿记录/去重） |
| `test_edge_cases.py` | — | 边界值测试（空结果/无效输入/极端值） |
| `validate_pipeline.py` | — | 数据管线验证（爬虫→数据库→API） |
| `run_all_tests.py` | — | 测试主控（发现并执行所有测试套件） |
| `shopcompare.db` | — | 测试专用 SQLite 数据库（与生产隔离） |

## 技术栈

| 层级 | 技术 |
|------|------|
| 前端 | HarmonyOS ArkTS + ArkUI (API 24) |
| 后端 | Python FastAPI 0.115 + SQLAlchemy 2.0 |
| 数据库 | SQLite |
| 爬虫 | Scrapling 0.4 + BeautifulSoup4 + Playwright |
| 认证 | JWT (python-jose) + bcrypt |
| 构建 | DevEco Studio + hvigor |
| 测试 | pytest + httpx + 自定义集成测试 |

## 环境变量

| 变量 | 说明 |
|------|------|
| `SHOPCOMPARE_DISABLE_CRAWLER=1` | 禁用爬虫，仅使用种子数据 |
| `SHOPCOMPARE_ENABLE_DEMO_SEED=1` | 显式启用演示种子数据 |

## License

MIT
