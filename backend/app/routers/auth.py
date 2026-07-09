from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.models import User
from app.schemas.user import (
    LoginRequest, RegisterRequest, SendCodeRequest,
    ResetPasswordRequest, RefreshTokenRequest, TokenResponse
)
from app.services.auth_service import (
    hash_password, verify_password,
    create_access_token, create_refresh_token,
    generate_sms_code, verify_sms_code, decode_token
)

router = APIRouter()


@router.post("/register", status_code=201)
def register(req: RegisterRequest, db: Session = Depends(get_db)):
    if len(req.phone) != 11:
        raise HTTPException(status_code=400, detail="手机号格式不正确")
    if len(req.password) < 8:
        raise HTTPException(status_code=400, detail="密码至少8位且包含数字和字母")
    if not verify_sms_code(req.phone, req.code):
        raise HTTPException(status_code=400, detail="验证码错误或已过期")

    existing = db.query(User).filter(User.phone == req.phone).first()
    if existing is not None:
        raise HTTPException(status_code=409, detail="该手机号已注册")

    user = User(
        phone=req.phone,
        password_hash=hash_password(req.password)
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)
    return TokenResponse(access_token=access_token, refresh_token=refresh_token, user_id=user.id)


@router.post("/login")
def login(req: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.phone == req.phone).first()
    if user is None:
        raise HTTPException(status_code=401, detail="手机号或密码错误")

    if req.login_type == "code":
        if not verify_sms_code(req.phone, req.code):
            raise HTTPException(status_code=401, detail="验证码错误或已过期")
    else:
        if not verify_password(req.password, user.password_hash):
            raise HTTPException(status_code=401, detail="手机号或密码错误")

    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)
    return TokenResponse(access_token=access_token, refresh_token=refresh_token, user_id=user.id)


@router.post("/send-code")
def send_code(req: SendCodeRequest):
    if len(req.phone) != 11:
        raise HTTPException(status_code=400, detail="手机号格式不正确")
    code = generate_sms_code(req.phone)
    return {"phone": req.phone, "code": code, "message": "验证码已发送（开发环境：{0}）".format(code)}


@router.post("/reset-password")
def reset_password(req: ResetPasswordRequest, db: Session = Depends(get_db)):
    if not verify_sms_code(req.phone, req.code):
        raise HTTPException(status_code=400, detail="验证码错误或已过期")
    if len(req.password) < 8:
        raise HTTPException(status_code=400, detail="密码至少8位")

    user = db.query(User).filter(User.phone == req.phone).first()
    if user is None:
        raise HTTPException(status_code=404, detail="用户不存在")

    user.password_hash = hash_password(req.password)
    db.commit()
    return {"message": "密码重置成功"}


@router.post("/refresh-token")
def refresh_token(req: RefreshTokenRequest, db: Session = Depends(get_db)):
    try:
        payload = decode_token(req.refresh_token)
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=401, detail="无效的刷新令牌")
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="无效的令牌")
    except Exception:
        raise HTTPException(status_code=401, detail="刷新令牌无效或已过期")

    user = db.query(User).filter(User.id == int(user_id)).first()
    if user is None:
        raise HTTPException(status_code=401, detail="用户不存在")

    access_token = create_access_token(user.id)
    refresh_token_new = create_refresh_token(user.id)
    return TokenResponse(access_token=access_token, refresh_token=refresh_token_new)
