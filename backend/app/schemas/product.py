from pydantic import BaseModel


class ProductResponse(BaseModel):
    model_config = {'protected_namespaces': ()}

    id: str
    name: str
    brand: str
    category: str
    model_code: str = ''
    image_url: str
    description: str
    lowest_price: float
    highest_price: float
    price_spread: float
    historical_low: float
    aggregate_rating: float
    aggregate_score: float
    total_review_count: int
    platform_count: int
    publish_date: str

    class Config:
        from_attributes = True


class ProductDetailResponse(ProductResponse):
    model_code: str
    specs: list[dict]
    platform_listings: list[dict]
    price_history: list[dict]
    review_tags: list[dict]


class ProductListResponse(BaseModel):
    total: int
    page: int
    size: int
    items: list[ProductResponse]


class CategoryResponse(BaseModel):
    id: str
    name: str
    icon: str
    sub_categories: list[dict]
