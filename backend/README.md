# ShopCompare 后端 API 服务

## 技术栈

- **框架**: Python 3.10+ / FastAPI
- **数据库**: SQLite (开发期) → PostgreSQL (生产)
- **ORM**: SQLAlchemy + Alembic
- **认证**: JWT (python-jose) + bcrypt (passlib)
- **测试**: pytest + httpx + pytest-asyncio
- **API 文档**: 自动生成 Swagger UI (`/docs`)

## 数据源策略

### 当前阶段 (v0.3 MVP)
使用**内嵌种子数据**（将 MockData.ets 的 30 条商品 + RecommendationData.ets 的用户行为数据迁移到数据库），确保：
- 每个 API 端点有真实可用的响应数据
- 前后端联调可以立即进行
- 不需要外部依赖即可演示

### 下一阶段 (v0.4 生产)
| 优先级 | 方案 | 说明 |
|--------|------|------|
| P0 | 京东联盟 API / 淘宝客 API | 合法合规，有佣金收入 |
| P1 | 第三方比价 API | 快速接入，覆盖面广 |
| P2 | 定向爬虫 | 补充长尾商品数据 |

### 图片策略
- 种子数据阶段：使用占位图服务 (https://placehold.co/400x400)
- 生产阶段：从电商 API 返回的真实图片 URL，App 端加载

## 快速开始

```bash
# 安装依赖
pip install -r requirements.txt

# 初始化数据库
python -m app.init_db

# 启动服务
uvicorn app.main:app --reload --port 8000

# 运行测试
pytest tests/ -v

# 按模块测试
pytest tests/api/test_auth.py -v
pytest tests/api/test_products.py -v
pytest tests/api/test_search.py -v
pytest tests/api/test_prices.py -v
pytest tests/api/test_favorites.py -v
pytest tests/api/test_alerts.py -v
```

## API 端点

### 认证 `POST /api/v1/auth/*`
| 端点 | 方法 | 说明 |
|------|------|------|
| `/register` | POST | 手机号+验证码+密码注册 |
| `/login` | POST | 密码登录 / 验证码登录 |
| `/send-code` | POST | 发送短信验证码 |
| `/reset-password` | POST | 验证码重置密码 |
| `/refresh-token` | POST | 刷新 JWT Token |

### 商品 `GET /api/v1/products/*`
| 端点 | 方法 | 说明 |
|------|------|------|
| `/products` | GET | 商品列表（分页+筛选） |
| `/products/{id}` | GET | 商品详情 |
| `/products/{id}/prices` | GET | 各平台价格 |
| `/products/{id}/history` | GET | 价格历史 |
| `/categories` | GET | 分类列表 |
| `/search` | GET | 搜索（?q=关键字） |
| `/recommendations` | GET | 推荐（需认证） |

### 收藏 `* /api/v1/favorites/*` (需认证)
| 端点 | 方法 | 说明 |
|------|------|------|
| `/favorites` | POST | 添加收藏 |
| `/favorites` | GET | 收藏列表 |
| `/favorites/{id}` | DELETE | 取消收藏 |

### 提醒 `* /api/v1/alerts/*` (需认证)
| 端点 | 方法 | 说明 |
|------|------|------|
| `/alerts` | POST | 关注降价 |
| `/alerts` | GET | 提醒列表 |
| `/alerts/{id}` | DELETE | 取消提醒 |

## 测试覆盖

```
tests/
├── conftest.py              # 测试数据库 + 客户端 fixture
├── api/
│   ├── test_auth.py         # 12 个测试用例
│   ├── test_products.py     # 商品 CRUD
│   ├── test_search.py       # 搜索功能
│   ├── test_prices.py       # 价格数据
│   ├── test_favorites.py    # 收藏功能
│   └── test_alerts.py       # 提醒功能
└── utils/
    └── test_password.py     # 密码哈希
```
