from pydantic import BaseModel


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user_id: int = 0


class LoginRequest(BaseModel):
    phone: str
    password: str = ""
    code: str = ""
    login_type: str = "password"


class RegisterRequest(BaseModel):
    phone: str
    code: str
    password: str


class SendCodeRequest(BaseModel):
    phone: str


class ResetPasswordRequest(BaseModel):
    phone: str
    code: str
    password: str


class RefreshTokenRequest(BaseModel):
    refresh_token: str
