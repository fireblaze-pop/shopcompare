from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from app.database import get_db
from app.models.models import Product, Favorite
from app.routers.products import product_to_response
from app.services.auth_service import get_current_user

router = APIRouter()


class FavoriteCreate(BaseModel):
    product_id: str


@router.post("/favorites", status_code=201)
def add_favorite(
    req: FavoriteCreate,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    product = db.query(Product).filter(Product.id == req.product_id).first()
    if product is None:
        raise HTTPException(status_code=404, detail="商品不存在")

    existing = db.query(Favorite).filter(
        Favorite.user_id == user_id,
        Favorite.product_id == req.product_id
    ).first()
    if existing is not None:
        raise HTTPException(status_code=409, detail="已收藏该商品")

    fav = Favorite(user_id=user_id, product_id=req.product_id)
    db.add(fav)
    db.commit()
    return {"message": "收藏成功"}


@router.get("/favorites")
def get_favorites(
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    favs = db.query(Favorite).filter(
        Favorite.user_id == user_id
    ).all()

    result = []
    for fav in favs:
        product = db.query(Product).filter(Product.id == fav.product_id).first()
        if product is not None:
            result.append(product_to_response(product))

    return {"items": result, "total": len(result)}


@router.delete("/favorites/{product_id}")
def remove_favorite(
    product_id: str,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    fav = db.query(Favorite).filter(
        Favorite.user_id == user_id,
        Favorite.product_id == product_id
    ).first()
    if fav is None:
        raise HTTPException(status_code=404, detail="未收藏该商品")

    db.delete(fav)
    db.commit()
    return {"message": "取消收藏成功"}
