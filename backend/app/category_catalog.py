from sqlalchemy import or_
from sqlalchemy.orm import Query

from app.models.models import Product


CATEGORY_CATALOG: list[dict] = [
    {
        'id': 'cat1',
        'name': '\u624b\u673a\u6570\u7801',
        'aliases': [],
        'icon': 'phone',
        'sub_categories': [
            {
                'id': 'sub1',
                'name': '\u667a\u80fd\u624b\u673a',
                'keywords': [
                    '\u624b\u673a', 'iPhone', 'Mate', 'Galaxy', 'Redmi',
                    'HONOR', '\u8363\u8000', 'OPPO', 'vivo', '\u5c0f\u7c73',
                    '\u534e\u4e3a', 'Samsung'
                ]
            },
            {
                'id': 'sub2',
                'name': '\u5e73\u677f\u7535\u8111',
                'keywords': ['\u5e73\u677f', 'Pad', 'iPad']
            }
        ]
    },
    {
        'id': 'cat2',
        'name': '\u7535\u8111\u529e\u516c',
        'aliases': [],
        'icon': 'computer',
        'sub_categories': [
            {
                'id': 'sub3',
                'name': '\u7b14\u8bb0\u672c',
                'keywords': [
                    '\u7b14\u8bb0\u672c', 'MacBook', 'MateBook',
                    'ThinkPad', 'X1', 'Pro'
                ]
            },
            {
                'id': 'sub4',
                'name': '\u53f0\u5f0f\u673a',
                'keywords': ['\u53f0\u5f0f', '\u4e3b\u673a', 'Desktop']
            }
        ]
    },
    {
        'id': 'cat3',
        'name': '\u5bb6\u7528\u7535\u5668',
        'aliases': [],
        'icon': 'home',
        'sub_categories': [
            {
                'id': 'sub5',
                'name': '\u7a7a\u8c03',
                'keywords': ['\u7a7a\u8c03', 'AC', 'KFR']
            },
            {
                'id': 'sub6',
                'name': '\u51b0\u7bb1',
                'keywords': ['\u51b0\u7bb1', 'BCD']
            }
        ]
    },
    {
        'id': 'cat4',
        'name': '\u7f8e\u5986\u4e2a\u62a4',
        'aliases': [],
        'icon': 'beauty',
        'sub_categories': [
            {
                'id': 'sub7',
                'name': '\u62a4\u80a4',
                'keywords': ['\u62a4\u80a4', '\u7cbe\u534e', '\u9762\u819c', 'SK-II']
            },
            {
                'id': 'sub8',
                'name': '\u5f69\u5986',
                'keywords': ['\u5f69\u5986', '\u53e3\u7ea2', '\u7c89\u5e95']
            }
        ]
    },
    {
        'id': 'cat5',
        'name': '\u670d\u9970\u978b\u5305',
        'aliases': [],
        'icon': 'fashion',
        'sub_categories': [
            {
                'id': 'sub9',
                'name': '\u7537\u88c5',
                'keywords': ['\u7537', '\u725b\u4ed4', "Levi's", '\u94b1\u5305']
            },
            {
                'id': 'sub10',
                'name': '\u5973\u88c5',
                'keywords': ['\u5973', 'Zara', '\u98ce\u8863', '\u5305']
            }
        ]
    },
    {
        'id': 'cat6',
        'name': '\u98df\u54c1\u751f\u9c9c',
        'aliases': [],
        'icon': 'food',
        'sub_categories': [
            {
                'id': 'sub11',
                'name': '\u6c34\u679c',
                'keywords': ['\u6c34\u679c', '\u751f\u9c9c']
            },
            {
                'id': 'sub12',
                'name': '\u96f6\u98df',
                'keywords': ['\u96f6\u98df', '\u575a\u679c', '\u997c', '\u725b\u8089\u5e72']
            }
        ]
    },
]


def get_categories() -> list[dict]:
    result: list[dict] = []
    for category in CATEGORY_CATALOG:
        sub_categories: list[dict] = []
        for sub_category in category['sub_categories']:
            sub_categories.append({
                'id': sub_category['id'],
                'name': sub_category['name']
            })
        result.append({
            'id': category['id'],
            'name': category['name'],
            'icon': category['icon'],
            'sub_categories': sub_categories
        })
    return result


def find_category_by_id(category_id: str) -> dict | None:
    for category in CATEGORY_CATALOG:
        if category['id'] == category_id:
            return category
    return None


def find_category_by_name(name: str) -> dict | None:
    for category in CATEGORY_CATALOG:
        if category['name'] == name:
            return category
        aliases: list[str] = category.get('aliases', [])
        if name in aliases:
            return category
    return None


def find_sub_category(category: dict | None, sub_category_id: str) -> dict | None:
    if category is None:
        return None
    for sub_category in category['sub_categories']:
        if sub_category['id'] == sub_category_id:
            return sub_category
    return None


def resolve_category(category_id: str, category_name: str) -> dict | None:
    if category_id:
        return find_category_by_id(category_id)
    if category_name:
        return find_category_by_name(category_name)
    return None


def apply_sub_category_filter(query: Query, sub_category: dict | None) -> Query:
    if sub_category is None:
        return query

    conditions = []
    for keyword in sub_category['keywords']:
        conditions.append(Product.name.contains(keyword))
        conditions.append(Product.category.contains(keyword))
        conditions.append(Product.description.contains(keyword))

    if not conditions:
        return query.filter(Product.id == '__no_sub_category_match__')
    return query.filter(or_(*conditions))


def product_matches_sub_category(product: Product, sub_category: dict) -> bool:
    text = (
        (product.name or '') + ' ' +
        (product.category or '') + ' ' +
        (product.description or '')
    ).lower()
    for keyword in sub_category['keywords']:
        if keyword.lower() in text:
            return True
    return False
