from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from app.database import get_db
from app.models.models import Product, Alert
from app.services.auth_service import get_current_user

router = APIRouter()


class AlertCreate(BaseModel):
    product_id: str
    target_price: float = 0


class AlertResponse(BaseModel):
    id: int
    product_id: str
    product_name: str
    target_price: float
    triggered: bool

    class Config:
        from_attributes = True


@router.post("/alerts", status_code=201)
def create_alert(
    req: AlertCreate,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    product = db.query(Product).filter(Product.id == req.product_id).first()
    if product is None:
        raise HTTPException(status_code=404, detail="商品不存在")

    existing = db.query(Alert).filter(
        Alert.user_id == user_id,
        Alert.product_id == req.product_id
    ).first()
    if existing is not None:
        raise HTTPException(status_code=409, detail="已关注该商品降价")

    target = req.target_price if req.target_price > 0 else product.lowest_price
    alert = Alert(user_id=user_id, product_id=req.product_id, target_price=target)
    db.add(alert)
    db.commit()
    return {"message": "已关注降价提醒", "target_price": target}


@router.get("/alerts")
def get_alerts(
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    alerts = db.query(Alert).filter(
        Alert.user_id == user_id
    ).all()

    result = []
    for a in alerts:
        product = db.query(Product).filter(Product.id == a.product_id).first()
        result.append({
            "id": a.id,
            "product_id": a.product_id,
            "product_name": product.name if product else "",
            "target_price": a.target_price,
            "triggered": a.triggered
        })

    return {"items": result, "total": len(result)}


@router.delete("/alerts/{alert_id}")
def remove_alert(
    alert_id: int,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    alert = db.query(Alert).filter(
        Alert.id == alert_id,
        Alert.user_id == user_id
    ).first()
    if alert is None:
        raise HTTPException(status_code=404, detail="提醒不存在")

    db.delete(alert)
    db.commit()
    return {"message": "已取消提醒"}
