from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.models import User
from app.services.auth_service import get_current_user

router = APIRouter()


class BehaviorRequest(BaseModel):
    product_id: str
    action_type: str


class SearchHistoryRequest(BaseModel):
    keyword: str


_behavior_store: list[dict] = []
_search_history: list[dict] = []


@router.post('/behaviors', status_code=201)
def record_behavior(
    req: BehaviorRequest,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    _behavior_store.append({
        'user_id': user_id,
        'product_id': req.product_id,
        'action_type': req.action_type,
        'timestamp': __import__('datetime').datetime.now().isoformat()
    })
    return {'message': '行为已记录'}


@router.get('/behaviors')
def get_behaviors(user_id: int = Depends(get_current_user)):
    user_behaviors = [b for b in _behavior_store if b['user_id'] == user_id]
    return {'items': user_behaviors[-50:], 'total': len(user_behaviors)}


@router.post('/search-history', status_code=201)
def add_search_history(
    req: SearchHistoryRequest,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    _search_history.insert(0, {
        'user_id': user_id,
        'keyword': req.keyword,
        'timestamp': __import__('datetime').datetime.now().isoformat()
    })
    if len(_search_history) > 50:
        _search_history.pop()
    return {'message': '已记录'}


@router.get('/search-history')
def get_search_history(user_id: int = Depends(get_current_user)):
    user_history = [h for h in _search_history if h['user_id'] == user_id]
    return {'items': user_history[:20], 'total': len(user_history)}
