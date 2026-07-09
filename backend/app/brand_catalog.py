import re
from typing import Iterable


BRAND_CATALOG: list[dict[str, list[str] | str]] = [
    {
        'name': 'Apple',
        'aliases': ['Apple', '\u82f9\u679c', 'iPhone', 'iPad', 'AirPods', 'MacBook'],
    },
    {
        'name': '\u534e\u4e3a',
        'aliases': ['\u534e\u4e3a', 'Huawei', 'HUAWEI', 'MateBook', 'FreeBuds'],
    },
    {
        'name': '\u8363\u8000',
        'aliases': ['\u8363\u8000', 'HONOR', 'Honor'],
    },
    {
        'name': '\u5c0f\u7c73',
        'aliases': ['\u5c0f\u7c73', 'Xiaomi', 'Redmi', '\u7ea2\u7c73', 'MIJIA'],
    },
    {
        'name': 'OPPO',
        'aliases': ['OPPO', 'OnePlus', '\u4e00\u52a0', 'realme'],
    },
    {
        'name': 'vivo',
        'aliases': ['vivo', 'iQOO'],
    },
    {
        'name': '\u4e09\u661f',
        'aliases': ['\u4e09\u661f', 'Samsung', 'Galaxy'],
    },
    {
        'name': '\u8054\u60f3',
        'aliases': ['\u8054\u60f3', 'Lenovo', 'ThinkPad'],
    },
    {
        'name': '\u6234\u5c14',
        'aliases': ['\u6234\u5c14', 'Dell'],
    },
    {
        'name': '\u534e\u7855',
        'aliases': ['\u534e\u7855', 'ASUS'],
    },
    {
        'name': '\u60e0\u666e',
        'aliases': ['\u60e0\u666e', 'HP'],
    },
    {
        'name': '\u7f8e\u7684',
        'aliases': ['\u7f8e\u7684', 'Midea'],
    },
    {
        'name': '\u683c\u529b',
        'aliases': ['\u683c\u529b', 'Gree'],
    },
    {
        'name': '\u6d77\u5c14',
        'aliases': ['\u6d77\u5c14', 'Haier'],
    },
    {
        'name': '\u6234\u68ee',
        'aliases': ['\u6234\u68ee', 'Dyson'],
    },
    {
        'name': '\u98de\u5229\u6d66',
        'aliases': ['\u98de\u5229\u6d66', 'Philips'],
    },
    {
        'name': '\u8010\u514b',
        'aliases': ['\u8010\u514b', 'Nike'],
    },
    {
        'name': '\u963f\u8fea\u8fbe\u65af',
        'aliases': ['\u963f\u8fea\u8fbe\u65af', 'Adidas'],
    },
    {
        'name': '\u8305\u53f0',
        'aliases': ['\u8305\u53f0', 'Moutai', 'MOUTAI'],
    },
    {
        'name': '\u5170\u853b',
        'aliases': ['\u5170\u853b', 'Lancome'],
    },
    {
        'name': '\u6b27\u83b1\u96c5',
        'aliases': ['\u6b27\u83b1\u96c5', "L'Oreal", 'Loreal'],
    },
    {
        'name': '\u96c5\u8bd7\u5170\u9edb',
        'aliases': ['\u96c5\u8bd7\u5170\u9edb', 'Estee Lauder'],
    },
]


def _fold_text(value: str) -> str:
    return re.sub(r'[\s\u3000\-/_.]+', '', value or '').casefold()


BRAND_ALIAS_TO_CANONICAL: dict[str, str] = {}
for item in BRAND_CATALOG:
    canonical = str(item['name'])
    aliases = [canonical] + list(item['aliases'])
    for alias in aliases:
        BRAND_ALIAS_TO_CANONICAL[_fold_text(str(alias))] = canonical


def normalize_brand(brand: str) -> str:
    value = (brand or '').strip()
    if not value:
        return ''
    return BRAND_ALIAS_TO_CANONICAL.get(_fold_text(value), value)


def infer_brand_from_title(title: str, fallback: str = '') -> str:
    text = _fold_text(title)
    if text:
        for item in sorted(BRAND_CATALOG, key=lambda brand: -max(len(str(alias)) for alias in brand['aliases'])):
            canonical = str(item['name'])
            aliases = [canonical] + list(item['aliases'])
            for alias in sorted(aliases, key=len, reverse=True):
                folded = _fold_text(str(alias))
                if folded and folded in text:
                    return canonical
    return normalize_brand(fallback)


def canonical_brand_set(brands: Iterable[str]) -> set[str]:
    result: set[str] = set()
    for brand in brands:
        normalized = normalize_brand(brand)
        if normalized:
            result.add(normalized)
    return result


def product_brand(product) -> str:
    return infer_brand_from_title(product.name or '', product.brand or '')


def product_matches_brand(product, requested_brands: set[str]) -> bool:
    if not requested_brands:
        return True
    return product_brand(product) in requested_brands


def normalize_product_title(name: str) -> str:
    cleaned = re.sub(r'\([^)]*\)', '', name or '')
    cleaned = re.sub(r'[\u3010\u3011\[\]\uff08\uff09(){}]', '', cleaned)
    cleaned = re.sub(r'[^\w\u4e00-\u9fff]+', '', cleaned)
    return cleaned.casefold()


def product_identity_key(product) -> tuple[str, str, str]:
    return (
        product.category or '',
        product_brand(product),
        normalize_product_title(product.name or ''),
    )


def dedupe_products(products: Iterable) -> list:
    result: list = []
    seen: set[tuple[str, str, str]] = set()
    for product in products:
        key = product_identity_key(product)
        if not key[2]:
            key = (product.category or '', product.brand or '', product.id or '')
        if key in seen:
            continue
        seen.add(key)
        result.append(product)
    return result
