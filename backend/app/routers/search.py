from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.models import Product
from app.schemas.product import ProductResponse
from app.routers.products import product_to_response

router = APIRouter()


@router.get("/search")
def search_products(
    q: str = Query("", min_length=1),
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    query = db.query(Product).filter(
        (Product.name.contains(q)) |
        (Product.brand.contains(q)) |
        (Product.category.contains(q)) |
        (Product.description.contains(q))
    )

    total = query.count()
    items = query.offset((page - 1) * size).limit(size).all()

    return {
        "total": total,
        "page": page,
        "size": size,
        "keyword": q,
        "items": [product_to_response(p) for p in items]
    }
