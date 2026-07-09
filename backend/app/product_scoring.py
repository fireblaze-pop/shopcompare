import math
from statistics import pstdev
from typing import Iterable

from app.brand_catalog import infer_brand_from_title
from app.models.models import Product


BRAND_REPUTATION: dict[str, int] = {
    'Apple': 95, '\u534e\u4e3a': 92, 'Huawei': 92,
    'Xiaomi': 84, '\u5c0f\u7c73': 84,
    'OPPO': 78, 'vivo': 76,
    'Samsung': 85, '\u4e09\u661f': 85,
    'Lenovo': 82, '\u8054\u60f3': 82,
    'Dell': 80, '\u6234\u5c14': 80,
    'Midea': 80, '\u7f8e\u7684': 80,
    'Gree': 83, '\u683c\u529b': 83,
    'Haier': 82, '\u6d77\u5c14': 82,
    'Nike': 86, 'Adidas': 82,
    '\u6234\u68ee': 88, 'Dyson': 88,
    '\u5170\u853b': 90, 'Lancome': 90,
    '\u8305\u53f0': 95,
}

DIMENSION_KEYS: list[tuple[str, str]] = [
    ('cost', '\u6027\u4ef7\u6bd4'),
    ('quality', '\u54c1\u8d28'),
    ('brand', '\u54c1\u724c'),
    ('after_sales', '\u552e\u540e'),
    ('logistics', '\u7269\u6d41'),
    ('appearance', '\u5916\u89c2'),
]


def _clamp(value: float, low: float = 0.0, high: float = 100.0) -> float:
    return min(high, max(low, value))


def _rating_to_five(value: float) -> float:
    if value <= 0:
        return 4.0
    if value > 5:
        return min(5.0, value / 2)
    return min(5.0, value)


def _percentile(value: float, values: Iterable[float]) -> float:
    prices = sorted(price for price in values if price > 0)
    if not prices:
        return 0.5
    if len(prices) == 1 or prices[0] == prices[-1]:
        return 0.5
    lower_count = sum(1 for price in prices if price <= value)
    return _clamp((lower_count - 1) / (len(prices) - 1), 0.0, 1.0)


def _platform_count_score(count: int) -> float:
    if count <= 0:
        return 35
    return _clamp(42 + count * 16)


def _category_weights(category: str) -> dict[str, float]:
    if category == '\u624b\u673a\u6570\u7801':
        return {'cost': 0.20, 'quality': 0.28, 'brand': 0.20, 'after_sales': 0.12, 'logistics': 0.08, 'appearance': 0.12}
    if category == '\u7535\u8111\u529e\u516c':
        return {'cost': 0.18, 'quality': 0.30, 'brand': 0.18, 'after_sales': 0.14, 'logistics': 0.08, 'appearance': 0.12}
    if category == '\u5bb6\u7528\u7535\u5668':
        return {'cost': 0.18, 'quality': 0.25, 'brand': 0.15, 'after_sales': 0.24, 'logistics': 0.12, 'appearance': 0.06}
    if category == '\u7f8e\u5986\u4e2a\u62a4':
        return {'cost': 0.14, 'quality': 0.24, 'brand': 0.24, 'after_sales': 0.08, 'logistics': 0.10, 'appearance': 0.20}
    if category == '\u670d\u9970\u978b\u5305':
        return {'cost': 0.16, 'quality': 0.22, 'brand': 0.20, 'after_sales': 0.08, 'logistics': 0.10, 'appearance': 0.24}
    if category == '\u98df\u54c1\u751f\u9c9c':
        return {'cost': 0.18, 'quality': 0.28, 'brand': 0.12, 'after_sales': 0.08, 'logistics': 0.24, 'appearance': 0.10}
    return {'cost': 0.18, 'quality': 0.25, 'brand': 0.18, 'after_sales': 0.14, 'logistics': 0.12, 'appearance': 0.13}


def _dimension_map(product: Product, category_products: list[Product] | None = None, listings: list | None = None) -> dict[str, int]:
    peers = category_products if category_products is not None else [product]
    active_listings = listings if listings is not None else list(product.listings or [])
    current_price = product.lowest_price or product.highest_price or product.historical_low or 0
    peer_prices = [item.lowest_price for item in peers if item.lowest_price and item.lowest_price > 0]
    price_pct = _percentile(current_price, peer_prices)

    rating_values = [item.rating for item in active_listings if item.rating and item.rating > 0]
    raw_rating = sum(rating_values) / len(rating_values) if rating_values else product.aggregate_rating
    rating = _rating_to_five(raw_rating)
    rating_score = rating / 5 * 100
    review_count = max(product.total_review_count or 0, sum((item.review_count or 0) for item in active_listings))
    confidence = _clamp(math.log10(review_count + 1) / 5, 0.0, 1.0)

    stock_count = sum(1 for item in active_listings if item.in_stock)
    stock_rate = stock_count / len(active_listings) if active_listings else 0.75
    platform_score = _platform_count_score(len(active_listings))
    brand_name = infer_brand_from_title(product.name or '', product.brand or '')
    brand_score = BRAND_REPUTATION.get(brand_name, BRAND_REPUTATION.get(product.brand or '', 70))

    history_anchor = product.historical_low or current_price
    if current_price > 0 and history_anchor > 0:
        history_score = _clamp(100 - max(0, current_price / history_anchor - 1) * 95, 35, 100)
    else:
        history_score = 58
    price_rank_score = 96 - price_pct * 68
    spread_bonus = 0
    if current_price > 0:
        spread_bonus = min(10, max(0, (product.price_spread or 0) / current_price * 120))
    cost = price_rank_score * 0.62 + history_score * 0.25 + rating_score * 0.13 + spread_bonus

    consistency = 78
    if len(rating_values) >= 2:
        consistency = 100 - min(38, pstdev(rating_values) * 24)
    quality = rating_score * 0.72 + confidence * 100 * 0.18 + consistency * 0.10

    after_sales = brand_score * 0.38 + platform_score * 0.32 + stock_rate * 100 * 0.20 + confidence * 100 * 0.10
    logistics = stock_rate * 100 * 0.58 + platform_score * 0.25 + confidence * 100 * 0.17

    has_image = 1 if product.image_url and len(product.image_url) > 10 else 0
    title_richness = _clamp(len(product.name or '') * 2.1, 30, 100)
    image_score = 88 if has_image else 42
    appearance = image_score * 0.48 + title_richness * 0.24 + rating_score * 0.18 + confidence * 100 * 0.10

    return {
        'cost': round(_clamp(cost)),
        'quality': round(_clamp(quality)),
        'brand': round(_clamp(brand_score)),
        'after_sales': round(_clamp(after_sales)),
        'logistics': round(_clamp(logistics)),
        'appearance': round(_clamp(appearance)),
    }


def compute_dimensions(product: Product, category_products: list[Product] | None = None, listings: list | None = None) -> list[dict]:
    values = _dimension_map(product, category_products, listings)
    return [
        {'key': key, 'label': label, 'value': values[key]}
        for key, label in DIMENSION_KEYS
    ]


def compute_overall_score(product: Product, category_products: list[Product] | None = None, listings: list | None = None) -> float:
    values = _dimension_map(product, category_products, listings)
    weights = _category_weights(product.category or '')
    weighted = sum(values[key] * weights[key] for key in weights)
    return round(_clamp(weighted / 20, 0, 5), 1)
